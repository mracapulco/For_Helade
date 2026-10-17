class_name GeradorVozes
extends RefCounted
## Gera as vozes das falas com o ElevenLabs (texto para fala).
## Roda no editor, por scripts/ferramentas/gerar_vozes.gd; o jogo só toca os arquivos
## prontos (autoload Voz). Quem fala com qual voz está em data/vozes/vozes.cfg.
## Cada fala vira assets/audio/vozes/<ID da fala>.mp3. O índice guarda o texto
## de cada áudio: rodar de novo só gera o que é novo ou mudou.
## Uma voz com uma lista em voz_id é um coro (várias pessoas dizendo a mesma
## fala juntas): cada pessoa vira <ID>_1.mp3, <ID>_2.mp3... e o jogo toca
## todas ao mesmo tempo.

const CONFIG := "res://data/vozes/vozes.cfg"
## Emoção de cada fala (etiquetas do ElevenLabs v3, como "[sad]").
const DIRECAO := "res://data/vozes/direcao.cfg"
## Como dizer nomes que o modelo erra (palavra escrita = como falar).
const PRONUNCIA := "res://data/vozes/pronuncia.cfg"
const PASTA_ROTEIROS := "res://data/dialogos"
const PASTA_SAIDA := "res://assets/audio/vozes"
const NOME_INDICE := "indice.json"
## A chave fica fora do git (.gitignore) e fora do jogo exportado (.gdignore).
const CHAVE := "res://.chaves/elevenlabs.txt"
const FORMATO := "mp3_44100_128"
## Subpastas de roteiros que não ganham voz (falas de teste).
const PASTAS_IGNORADAS := ["teste"]

var servidor := "api.elevenlabs.io"
## -1 usa a porta padrão (443 com TLS).
var porta := -1
var usar_tls := true
var pasta_saida := PASTA_SAIDA
## Mensagens de cada passo (o editor mostra na saída).
var registro: Array[String] = []


## As vozes do arquivo de configuração.
static func ler_vozes(caminho := CONFIG) -> Array[Dictionary]:
	var vozes: Array[Dictionary] = []
	var cfg := ConfigFile.new()
	if cfg.load(caminho) != OK:
		return vozes
	for secao in cfg.get_sections():
		vozes.append({
			"nome": secao,
			"voz_id": cfg.get_value(secao, "voz_id", ""),
			"modelo": cfg.get_value(secao, "modelo", "eleven_v3"),
			"estabilidade": cfg.get_value(secao, "estabilidade", 0.5),
			"sotaque": cfg.get_value(secao, "sotaque", ""),
			"falantes": cfg.get_value(secao, "falantes", []),
			"narracao": cfg.get_value(secao, "narracao", []),
			"roteiros": cfg.get_value(secao, "roteiros", []),
			"falas": cfg.get_value(secao, "falas", []),
		})
	return vozes


## ID da fala -> etiquetas de emoção.
static func ler_direcao(caminho := DIRECAO) -> Dictionary:
	var direcao := {}
	var cfg := ConfigFile.new()
	if cfg.load(caminho) == OK and cfg.has_section("direcao"):
		for id in cfg.get_section_keys("direcao"):
			direcao[id] = str(cfg.get_value("direcao", id, "")).strip_edges()
	return direcao


## Palavra escrita -> como deve soar (só no áudio; a tela não muda).
static func ler_pronuncia(caminho := PRONUNCIA) -> Dictionary:
	var pronuncia := {}
	var cfg := ConfigFile.new()
	if cfg.load(caminho) == OK and cfg.has_section("pronuncia"):
		for palavra in cfg.get_section_keys("pronuncia"):
			pronuncia[palavra] = str(cfg.get_value("pronuncia", palavra, ""))
	return pronuncia


## Troca as palavras inteiras (com maiúscula ou minúscula, como estiverem
## no arquivo de pronúncia) pela forma falada.
static func pronunciar(texto: String, pronuncia: Dictionary) -> String:
	for palavra: String in pronuncia:
		var regra := RegEx.create_from_string("(?<![\\p{L}])" + palavra + "(?![\\p{L}])")
		texto = regra.sub(texto, pronuncia[palavra], true)
	return texto


## Todos os roteiros .dialogue dentro da pasta, nas subpastas também.
static func roteiros(pasta := PASTA_ROTEIROS) -> PackedStringArray:
	var achados := PackedStringArray()
	var dir := DirAccess.open(pasta)
	if dir == null:
		return achados
	for sub in dir.get_directories():
		if sub in PASTAS_IGNORADAS:
			continue
		achados.append_array(roteiros(pasta.path_join(sub)))
	for arquivo in dir.get_files():
		if arquivo.get_extension() == "dialogue":
			achados.append(pasta.path_join(arquivo))
	achados.sort()
	return achados


## As falas de um roteiro que têm voz:
## {id, arquivo, texto, direcao, voz, voz_id, modelo, estabilidade}.
## Num coro, a mesma fala aparece uma vez por pessoa, cada uma com seu arquivo.
## Opções de escolha não entram (são rótulos do jogo, não falas).
static func falas_do_roteiro(recurso: DialogueResource, vozes: Array[Dictionary], direcao := {}, pronuncia := {}) -> Array[Dictionary]:
	var falas: Array[Dictionary] = []
	for chave in recurso.lines:
		var linha: Dictionary = recurso.lines[chave]
		var id: String = linha.get("static_id", "")
		if linha.get("type") != "dialogue" or id.is_empty():
			continue
		var personagem: String = linha.get("character", "")
		var voz := voz_da_fala(personagem, id, vozes, recurso.resource_path)
		if voz.is_empty():
			continue
		var texto := limpar(linha.get("text", ""))
		var coro: bool = voz.voz_id is Array
		var ids: Array = voz.voz_id if coro else [voz.voz_id]
		for i in ids.size():
			falas.append({
				"id": id,
				"arquivo": "%s_%d" % [id, i + 1] if coro else id,
				"texto": texto,
				"falado": pronunciar(texto, pronuncia),
				"direcao": direcao.get(id, ""),
				"voz": voz.nome,
				"voz_id": ids[i],
				"modelo": voz.modelo,
				"estabilidade": voz.get("estabilidade", 0.5),
				"sotaque": voz.get("sotaque", ""),
			})
	falas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.arquivo < b.arquivo)
	return falas


## A voz de quem diz a fala, nesta ordem:
## 1. a voz que tem o ID da fala em "falas" (exceções, fala por fala);
## 2. fala sem nome: a voz que tem o ID em "narracao";
## 3. fala com nome: a voz com o nome em "falantes", preferindo a que tem em
##    "roteiros" o roteiro desta fala (ex.: o Nicholas criança no capitulo_01);
## 4. o "*" de "falantes" (NPCs), com a mesma preferência por roteiro.
## Uma voz com "roteiros" só vale nesses roteiros. Sem voz: dicionário vazio.
static func voz_da_fala(personagem: String, id: String, vozes: Array[Dictionary], roteiro := "") -> Dictionary:
	for voz in vozes:
		if id in voz.get("falas", []):
			return voz
	if personagem.is_empty():
		for voz in vozes:
			if id in voz.narracao:
				return voz
		return {}
	for nome in [personagem, "*"]:
		var geral := {}
		for voz in vozes:
			if not nome in voz.falantes:
				continue
			var roteiros: Array = voz.get("roteiros", [])
			if roteiros.is_empty():
				if geral.is_empty():
					geral = voz
			elif roteiros.any(func(r: String) -> bool: return r in roteiro):
				return voz
		if not geral.is_empty():
			return geral
	return {}


## O texto como deve ser lido: sem etiquetas entre colchetes.
static func limpar(texto: String) -> String:
	var etiquetas := RegEx.create_from_string("\\[[^\\]]*\\]")
	return etiquetas.sub(texto, "", true).strip_edges()


## O que vai para o ElevenLabs: sotaque e emoção na frente do texto.
static func texto_para_voz(fala: Dictionary) -> String:
	var partes := PackedStringArray()
	for parte: String in [fala.get("sotaque", ""), fala.get("direcao", ""), fala.get("falado", fala.texto)]:
		if not parte.is_empty():
			partes.append(parte)
	return " ".join(partes)


## Muda quando o texto, a emoção, a voz ou o modelo mudam: aí o áudio é refeito.
static func assinatura(fala: Dictionary) -> String:
	return ("%s|%s|%s|%s" % [texto_para_voz(fala), fala.voz_id, fala.modelo, fala.get("estabilidade", 0.5)]).md5_text()


## As falas sem áudio ou com áudio de um texto antigo.
func pendentes(falas: Array[Dictionary], indice: Dictionary) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for fala in falas:
		var arquivo: String = fala.get("arquivo", fala.id)
		var feito: Dictionary = indice.get(arquivo, {})
		if feito.get("assinatura", "") != assinatura(fala) or not FileAccess.file_exists(caminho_audio(arquivo)):
			lista.append(fala)
	return lista


func caminho_audio(id: String) -> String:
	return pasta_saida.path_join(id + ".mp3")


func caminho_indice() -> String:
	return pasta_saida.path_join(NOME_INDICE)


func ler_indice() -> Dictionary:
	if not FileAccess.file_exists(caminho_indice()):
		return {}
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(caminho_indice()))
	return dados if dados is Dictionary else {}


func salvar_indice(indice: Dictionary) -> void:
	var arquivo := FileAccess.open(caminho_indice(), FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(indice, "\t", true))


## A chave da API. Sem ela, cria o arquivo vazio para colar a chave.
static func ler_chave(caminho := CHAVE) -> String:
	if FileAccess.file_exists(caminho):
		return FileAccess.get_file_as_string(caminho).strip_edges()
	var pasta := caminho.get_base_dir()
	DirAccess.make_dir_recursive_absolute(pasta)
	# .gdignore: o Godot não importa nem exporta esta pasta.
	FileAccess.open(pasta.path_join(".gdignore"), FileAccess.WRITE)
	FileAccess.open(caminho, FileAccess.WRITE)
	return ""


## Gera o que falta. Devolve {geradas, prontas, erros}.
func rodar(chave: String, vozes: Array[Dictionary] = ler_vozes(), arquivos := roteiros(), direcao := ler_direcao(), pronuncia := ler_pronuncia()) -> Dictionary:
	var falas: Array[Dictionary] = []
	for arquivo in arquivos:
		var recurso: DialogueResource = load(arquivo)
		if recurso:
			falas.append_array(falas_do_roteiro(recurso, vozes, direcao, pronuncia))
	DirAccess.make_dir_recursive_absolute(pasta_saida)
	var indice := ler_indice()
	var fazer := pendentes(falas, indice)
	var resultado := {"geradas": 0, "prontas": falas.size() - fazer.size(), "erros": []}
	_anotar("%d falas com voz; %d já prontas, %d para gerar." % [falas.size(), resultado.prontas, fazer.size()])
	for fala in fazer:
		var resposta := pedir_com_novas_tentativas(fala, chave)
		if resposta.erro.is_empty():
			var nome: String = fala.get("arquivo", fala.id)
			var arquivo := FileAccess.open(caminho_audio(nome), FileAccess.WRITE)
			arquivo.store_buffer(resposta.audio)
			arquivo.close()
			indice[nome] = {"fala": fala.id, "texto": fala.texto, "voz": fala.voz, "assinatura": assinatura(fala)}
			salvar_indice(indice)
			resultado.geradas += 1
			_anotar("Gerada %s: %s" % [nome, texto_para_voz(fala)])
		else:
			resultado.erros.append("%s: %s" % [fala.get("arquivo", fala.id), resposta.erro])
			_anotar("ERRO %s: %s" % [fala.get("arquivo", fala.id), resposta.erro])
			# Chave errada ou sem créditos: não adianta tentar as outras.
			if resposta.codigo in [401, 402, 403]:
				break
	salvar_indice(indice)
	return resultado


## Pede o áudio e, se a conexão cair ou o servidor estiver ocupado (429,
## 5xx), tenta de novo até [param tentativas] vezes, esperando um pouco mais
## a cada vez. Chave errada ou texto recusado (4xx) não se repete.
func pedir_com_novas_tentativas(fala: Dictionary, chave: String, tentativas := 3, espera_ms := 3000) -> Dictionary:
	var resposta := {}
	for tentativa in tentativas:
		resposta = pedir_audio(fala, chave)
		var passageiro: bool = resposta.codigo == 0 or resposta.codigo == 429 or resposta.codigo >= 500
		if resposta.erro.is_empty() or not passageiro:
			return resposta
		if tentativa < tentativas - 1:
			_anotar("Falhou %s (%s); tentando de novo..." % [fala.id, resposta.erro])
			OS.delay_msec(espera_ms * (tentativa + 1))
	return resposta


## Pede o áudio de uma fala ao ElevenLabs. Devolve {audio, erro, codigo}.
func pedir_audio(fala: Dictionary, chave: String) -> Dictionary:
	var cliente := HTTPClient.new()
	var tls := TLSOptions.client() if usar_tls else null
	if cliente.connect_to_host(servidor, porta, tls) != OK:
		return {"audio": PackedByteArray(), "erro": "sem conexão com %s" % servidor, "codigo": 0}
	if not _esperar(cliente, [HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING], HTTPClient.STATUS_CONNECTED):
		return {"audio": PackedByteArray(), "erro": "sem conexão com %s" % servidor, "codigo": 0}
	var corpo := JSON.stringify({
		"text": texto_para_voz(fala),
		"model_id": fala.modelo,
		"voice_settings": {"stability": fala.get("estabilidade", 0.5)},
	})
	var caminho := "/v1/text-to-speech/%s?output_format=%s" % [fala.voz_id, FORMATO]
	var cabecalhos := ["xi-api-key: " + chave, "Content-Type: application/json", "Accept: audio/mpeg"]
	cliente.request(HTTPClient.METHOD_POST, caminho, cabecalhos, corpo)
	# O v3 pode demorar para começar a responder: espera até 2 minutos.
	if not _esperar(cliente, [HTTPClient.STATUS_REQUESTING], HTTPClient.STATUS_BODY, 120000) and cliente.get_status() != HTTPClient.STATUS_CONNECTED:
		return {"audio": PackedByteArray(), "erro": "o servidor não respondeu (estado %d)" % cliente.get_status(), "codigo": 0}
	var codigo := cliente.get_response_code()
	var dados := PackedByteArray()
	while cliente.get_status() == HTTPClient.STATUS_BODY:
		cliente.poll()
		var pedaco := cliente.read_response_body_chunk()
		if pedaco.is_empty():
			OS.delay_msec(10)
		else:
			dados.append_array(pedaco)
	cliente.close()
	if codigo != 200:
		return {"audio": PackedByteArray(), "erro": "HTTP %d %s" % [codigo, dados.get_string_from_utf8().left(300)], "codigo": codigo}
	return {"audio": dados, "erro": "", "codigo": codigo}


func _esperar(cliente: HTTPClient, enquanto: Array, alvo: int, limite_ms := 60000) -> bool:
	var inicio := Time.get_ticks_msec()
	while cliente.get_status() in enquanto and Time.get_ticks_msec() - inicio < limite_ms:
		cliente.poll()
		OS.delay_msec(10)
	return cliente.get_status() == alvo


func _anotar(texto: String) -> void:
	registro.append(texto)
	print(texto)
