extends Node
## Bolsa do grupo: espaços com itens (como no Minecraft), dinheiro e o que
## cada personagem tem equipado (autoload "Inventario").
## O número de espaços depende da idade de Nicholas ([member faixa_etaria]);
## os [constant ESPACOS_RAPIDOS] primeiros formam a barra rápida (teclas 1 a 9).
## Itens da história e dinheiro não ocupam espaço, para a história nunca travar.
## No roteiro:
##   $> Inventario.adicionar("id_do_item")
##   if Inventario.tem("id_do_item")
## Os itens vêm de res://data/itens/ (um .tres por item).

signal mudou(id: String, quantidade: int)
signal dinheiro_mudou(valor: int)
signal equipamento_mudou(personagem: String, encaixe: Item.Encaixe, id: String)
signal item_usado(id: String, personagem: String)
## Item ganho (baú, roteiro, inimigo). Só em [method adicionar], para o
## aviso "+ item" não aparecer ao carregar um jogo salvo.
signal recebeu(id: String, quantidade: int)
signal dinheiro_recebido(valor: int)
## Algum espaço mudou (item entrou, saiu ou trocou de lugar).
signal espacos_mudaram
signal capacidade_mudou(espacos: int)
## Algo não entrou por falta de espaço (aviso "Bolsa cheia").
signal bolsa_cheia
## A fase da vida mudou (bolsa, vida, ataque e o que dá para equipar).
signal faixa_etaria_mudou(faixa: FaixaEtaria)
## Tentou equipar algo pesado demais para a idade (aviso na tela).
signal pesado_demais(id: String)
## O espaço selecionado na barra rápida mudou (tecla 1 a 9 ou toque).
signal selecao_mudou(indice: int)

enum FaixaEtaria { CRIANCA, ADOLESCENTE, ADULTO }

## Espaços da bolsa em cada idade. Valores provisórios: ajustar aqui.
const CAPACIDADE: Dictionary[FaixaEtaria, int] = {
	FaixaEtaria.CRIANCA: 12,
	FaixaEtaria.ADOLESCENTE: 20,
	FaixaEtaria.ADULTO: 30,
}
## Espaços da barra rápida: os primeiros da bolsa.
const ESPACOS_RAPIDOS := 9

const PASTA_ITENS := "res://data/itens/"
## Um FaseDaVida por idade: crianca.tres, adolescente.tres, adulto.tres.
const PASTA_FASES := "res://data/fases_da_vida/"

var _catalogo: Dictionary[String, Item] = {}
var _fases: Dictionary[FaixaEtaria, FaseDaVida] = {}
## Cada espaço é {} (vazio) ou { "id": String, "quantidade": int }.
## Pode passar do limite só quando a bolsa encolheu (nada some).
var _espacos: Array[Dictionary] = []
## Itens da história: id -> quantidade, fora dos espaços.
var _historia: Dictionary[String, int] = {}
var faixa_etaria: FaixaEtaria = FaixaEtaria.CRIANCA
## Espaço da barra rápida que está na mão (0 a 8), como no Minecraft.
var espaco_selecionado := 0
var _dinheiro: int = 0
## personagem -> { Item.Encaixe -> id do item }
var _equipado: Dictionary[String, Dictionary] = {}
## Baús e outras recompensas já pegas, para não darem itens de novo.
var _coletados: Dictionary[String, bool] = {}


func _init() -> void:
	_carregar_catalogo()
	_espacos.resize(capacidade())


func _carregar_catalogo() -> void:
	if not DirAccess.dir_exists_absolute(PASTA_ITENS):
		return
	for arquivo: String in ResourceLoader.list_directory(PASTA_ITENS):
		if not arquivo.ends_with(".tres"):
			continue
		var item := load(PASTA_ITENS + arquivo) as Item
		if item == null:
			push_error("Inventario: %s não é um Item." % arquivo)
			continue
		registrar(item)


## Põe um item no catálogo. Os itens da pasta já entram sozinhos; isto
## serve para testes e itens criados por código.
func registrar(item: Item) -> void:
	if item.id.is_empty():
		push_error("Inventario: item sem id.")
		return
	_catalogo[item.id] = item


## Dados do item, ou null se o id não existir.
func item(id: String) -> Item:
	return _catalogo.get(id, null)


func quantidade(id: String) -> int:
	if id.is_empty():
		return 0
	if _historia.has(id):
		return _historia[id]
	var total := 0
	for espaco: Dictionary in _espacos:
		if espaco.get("id", "") == id:
			total += int(espaco["quantidade"])
	return total


func tem(id: String, qtd: int = 1) -> bool:
	return quantidade(id) >= qtd


## Ids de tudo o que está na bolsa, de um tipo, em ordem alfabética.
func ids_do_tipo(tipo: Item.Tipo) -> Array[String]:
	var ids: Array[String] = []
	for id: String in _historia:
		if _catalogo[id].tipo == tipo:
			ids.append(id)
	for espaco: Dictionary in _espacos:
		var id: String = espaco.get("id", "")
		if not id.is_empty() and _catalogo[id].tipo == tipo and not ids.has(id):
			ids.append(id)
	ids.sort()
	return ids


## Quantos espaços a idade atual permite.
func capacidade() -> int:
	return CAPACIDADE[faixa_etaria]


## Espaços que existem agora (a capacidade, ou mais se a bolsa encolheu
## com itens nos espaços do fim).
func numero_de_espacos() -> int:
	return _espacos.size()


## Conteúdo de um espaço: {} se vazio, senão { "id", "quantidade" }.
func espaco(indice: int) -> Dictionary:
	if indice < 0 or indice >= _espacos.size():
		return {}
	return _espacos[indice].duplicate()


## Muda a idade. A bolsa cresce na hora; se encolher, os itens que
## ficarem fora do limite continuam lá, mas nada novo entra neles.
## O que ficou pesado demais para a nova idade é desequipado (fica na bolsa).
func mudar_faixa_etaria(faixa: FaixaEtaria) -> void:
	faixa_etaria = faixa
	_ajustar_tamanho()
	_desequipar_pesados()
	capacidade_mudou.emit(numero_de_espacos())
	espacos_mudaram.emit()
	faixa_etaria_mudou.emit(faixa)


## O corpo na idade atual: vida, ataque sem arma e velocidade.
func fase() -> FaseDaVida:
	if not _fases.has(faixa_etaria):
		var nome := str(FaixaEtaria.find_key(faixa_etaria)).to_lower()
		var dados := load(PASTA_FASES + nome + ".tres") as FaseDaVida
		_fases[faixa_etaria] = dados if dados else FaseDaVida.new()
	return _fases[faixa_etaria]


## O item existe, se equipa, mas a idade atual ainda não deixa.
func pesado_para_a_idade(id: String) -> bool:
	var dados := item(id)
	return dados != null and dados.pode_equipar() and dados.fase_minima > faixa_etaria


## Cabe [param qtd] de [param id] na bolsa? Itens da história sempre cabem.
func cabe(id: String, qtd: int = 1) -> bool:
	return cabem({ id: qtd })


## Cabe tudo junto? [param itens] é id -> quantidade (um baú inteiro).
func cabem(itens: Dictionary) -> bool:
	var copia: Array[Dictionary] = []
	for espaco: Dictionary in _espacos:
		copia.append(espaco.duplicate())
	for id: Variant in itens:
		var dados := item(str(id))
		if dados == null:
			return false
		if dados.e_da_historia():
			continue
		if _guardar(copia, dados, int(itens[id]), capacidade()) > 0:
			return false
	return true


## Põe [param qtd] unidades na bolsa: primeiro completa as pilhas do mesmo
## item, depois usa espaços vazios. Tudo ou nada: falha se o id não existir
## ou se não couber (veja [method cabe]).
func adicionar(id: String, qtd: int = 1) -> bool:
	var dados := item(id)
	if dados == null:
		push_error("Inventario: item desconhecido '%s'." % id)
		return false
	if qtd <= 0:
		return false
	if not cabe(id, qtd):
		bolsa_cheia.emit()
		return false
	if dados.e_da_historia():
		_historia[id] = quantidade(id) + qtd
	else:
		_guardar(_espacos, dados, qtd, capacidade())
		espacos_mudaram.emit()
	mudou.emit(id, quantidade(id))
	recebeu.emit(id, qtd)
	return true


## Tira [param qtd] unidades, dos últimos espaços para os primeiros (a
## barra rápida é a última a perder). Falha se não houver o suficiente.
## O roteiro pode tirar itens da história; o jogador usa [method largar].
## Se sobrar menos do que está equipado, desequipa o excedente.
func remover(id: String, qtd: int = 1) -> bool:
	if qtd <= 0 or not tem(id, qtd):
		return false
	if _historia.has(id):
		_historia[id] -= qtd
		if _historia[id] == 0:
			_historia.erase(id)
	else:
		var falta := qtd
		for indice in range(_espacos.size() - 1, -1, -1):
			if falta == 0:
				break
			if _espacos[indice].get("id", "") == id:
				falta -= _tirar_do_espaco(indice, falta)
		_ajustar_tamanho()
		espacos_mudaram.emit()
	_desequipar_excedente(id)
	mudou.emit(id, quantidade(id))
	return true


## Troca dois espaços de lugar (tocar num item e depois noutro espaço).
## Se forem do mesmo item, junta o que couber na pilha do destino.
func trocar_espacos(origem: int, destino: int) -> bool:
	if origem == destino or origem < 0 or destino < 0:
		return false
	if origem >= _espacos.size() or destino >= capacidade():
		return false
	var a := _espacos[origem]
	var b := _espacos[destino]
	if a.is_empty():
		return false
	if not b.is_empty() and a["id"] == b["id"]:
		var pilha := item(a["id"]).tamanho_pilha()
		var passa := mini(int(a["quantidade"]), pilha - int(b["quantidade"]))
		if passa <= 0:
			return false
		b["quantidade"] = int(b["quantidade"]) + passa
		a["quantidade"] = int(a["quantidade"]) - passa
		if int(a["quantidade"]) == 0:
			_espacos[origem] = {}
	else:
		_espacos[origem] = b
		_espacos[destino] = a
	_ajustar_tamanho()
	espacos_mudaram.emit()
	return true


## Tecla 1 a 9 (ou toque na barra rápida): põe o espaço na mão. Arma vai
## para a mão (equipa); qualquer outra coisa tira a arma da mão. Nada é
## usado aqui: quem usa é o clique ([method usar_selecionado]).
func selecionar_espaco(indice: int, personagem: String) -> void:
	if indice < 0 or indice >= ESPACOS_RAPIDOS:
		return
	espaco_selecionado = indice
	segurar_selecionado(personagem)
	selecao_mudou.emit(indice)


## Equipa a arma do espaço selecionado ou, se não houver arma nele,
## tira a arma da mão.
func segurar_selecionado(personagem: String) -> void:
	var dados := item_selecionado()
	if dados and dados.encaixe == Item.Encaixe.ARMA:
		equipar(personagem, dados.id)
	else:
		desequipar(personagem, Item.Encaixe.ARMA)


## Item do espaço selecionado, ou null se estiver vazio.
func item_selecionado() -> Item:
	var conteudo := espaco(espaco_selecionado)
	return item(conteudo["id"]) if not conteudo.is_empty() else null


## O clique faz algo com o item selecionado que não seja golpear? (poção
## bebe; proteção equipa ou desequipa). A arma golpeia pelo personagem.
func selecionado_tem_uso() -> bool:
	var dados := item_selecionado()
	if dados == null:
		return false
	return dados.pode_usar() or (dados.pode_equipar() and dados.encaixe != Item.Encaixe.ARMA)


## Clique com o item selecionado: poção é bebida, proteção é vestida ou
## tirada. Arma não faz nada aqui (o golpe é do personagem).
func usar_selecionado(personagem: String) -> bool:
	if not selecionado_tem_uso():
		return false
	return usar_espaco(espaco_selecionado, personagem)


## Arma ou proteção equipa, ou
## desequipa se já estiver equipada; consumível é usado. [param indice]
## começa em 0.
func usar_espaco(indice: int, personagem: String) -> bool:
	var conteudo := espaco(indice)
	if conteudo.is_empty():
		return false
	var dados := item(conteudo["id"])
	if dados.pode_equipar():
		if equipado(personagem, dados.encaixe) == dados.id:
			desequipar(personagem, dados.encaixe)
			return true
		return equipar(personagem, dados.id)
	if dados.pode_usar():
		_tirar_do_espaco(indice, 1)
		_ajustar_tamanho()
		espacos_mudaram.emit()
		mudou.emit(dados.id, quantidade(dados.id))
		item_usado.emit(dados.id, personagem)
		return true
	return false


## Ação do jogador: joga fora. Itens da história nunca saem assim.
func largar(id: String, qtd: int = 1) -> bool:
	var dados := item(id)
	if dados == null or dados.e_da_historia():
		return false
	return remover(id, qtd)


## Ação do jogador na grade: joga fora uma unidade daquele espaço.
func largar_espaco(indice: int) -> bool:
	var conteudo := espaco(indice)
	if conteudo.is_empty():
		return false
	var dados := item(conteudo["id"])
	_tirar_do_espaco(indice, 1)
	_ajustar_tamanho()
	_desequipar_excedente(dados.id)
	espacos_mudaram.emit()
	mudou.emit(dados.id, quantidade(dados.id))
	return true


## Ação do jogador: usa um consumível em um personagem e gasta uma
## unidade. O efeito (cura etc.) fica com quem ouve [signal item_usado].
func usar(id: String, personagem: String) -> bool:
	var dados := item(id)
	if dados == null or not dados.pode_usar() or not tem(id):
		return false
	remover(id)
	item_usado.emit(id, personagem)
	return true


func dinheiro() -> int:
	return _dinheiro


func ganhar_dinheiro(valor: int) -> void:
	if valor <= 0:
		return
	_dinheiro += valor
	dinheiro_mudou.emit(_dinheiro)
	dinheiro_recebido.emit(valor)


## Gasta se houver o suficiente; senão não muda nada e devolve false.
func gastar_dinheiro(valor: int) -> bool:
	if valor < 0 or valor > _dinheiro:
		return false
	_dinheiro -= valor
	dinheiro_mudou.emit(_dinheiro)
	return true


## Id do item equipado pelo personagem naquele encaixe, ou "".
func equipado(personagem: String, encaixe: Item.Encaixe) -> String:
	return _equipado.get(personagem, {}).get(encaixe, "")


## Equipa o item no encaixe dele, trocando o que estava lá. Precisa
## haver uma unidade livre (não equipada por outra pessoa).
func equipar(personagem: String, id: String) -> bool:
	var dados := item(id)
	if dados == null or not dados.pode_equipar():
		return false
	if pesado_para_a_idade(id):
		pesado_demais.emit(id)
		return false
	if equipado(personagem, dados.encaixe) == id:
		return true
	if _vezes_equipado(id) >= quantidade(id):
		return false
	if not _equipado.has(personagem):
		_equipado[personagem] = {}
	# Arma de duas mãos e escudo não andam juntos: equipar um tira o outro.
	if dados.duas_maos():
		desequipar(personagem, Item.Encaixe.ESCUDO)
	elif dados.encaixe == Item.Encaixe.ESCUDO:
		var arma := item(equipado(personagem, Item.Encaixe.ARMA))
		if arma and arma.duas_maos():
			desequipar(personagem, Item.Encaixe.ARMA)
	_equipado[personagem][dados.encaixe] = id
	equipamento_mudou.emit(personagem, dados.encaixe, id)
	return true


## Itens que o personagem tem equipados, em todos os encaixes.
func itens_equipados(personagem: String) -> Array[Item]:
	var itens: Array[Item] = []
	for encaixe: int in _equipado.get(personagem, {}):
		var dados := item(_equipado[personagem][encaixe])
		if dados:
			itens.append(dados)
	return itens


## Ataque, defesa e velocidade do personagem: o corpo da idade ([method fase])
## e o nível (Experiencia), mais o que tem equipado (Balanceamento.somar):
## { "ataque", "defesa", "velocidade" }.
func atributos(personagem: String) -> Dictionary:
	var corpo := fase()
	var ataque := corpo.ataque_base + Experiencia.bonus_ataque(personagem)
	return Balanceamento.somar(itens_equipados(personagem), ataque, corpo.velocidade)


func desequipar(personagem: String, encaixe: Item.Encaixe) -> void:
	if equipado(personagem, encaixe).is_empty():
		return
	_equipado[personagem].erase(encaixe)
	equipamento_mudou.emit(personagem, encaixe, "")


func ja_coletado(id_coleta: String) -> bool:
	return _coletados.has(id_coleta)


func marcar_coletado(id_coleta: String) -> void:
	_coletados[id_coleta] = true


## Apaga tudo (novo jogo, testes). O catálogo continua.
func limpar() -> void:
	_espacos.clear()
	_historia.clear()
	faixa_etaria = FaixaEtaria.CRIANCA
	espaco_selecionado = 0
	_espacos.resize(capacidade())
	_equipado.clear()
	_coletados.clear()
	_dinheiro = 0


## Cópia do estado, para salvar o jogo. Encaixes viram texto.
func para_dados() -> Dictionary:
	var equipado_dados := {}
	for personagem: String in _equipado:
		var encaixes := {}
		for encaixe: int in _equipado[personagem]:
			encaixes[Item.Encaixe.find_key(encaixe)] = _equipado[personagem][encaixe]
		equipado_dados[personagem] = encaixes
	var espacos_dados := []
	for espaco: Dictionary in _espacos:
		espacos_dados.append(espaco.duplicate())
	return {
		"espacos": espacos_dados,
		"historia": _historia.duplicate(),
		"faixa_etaria": FaixaEtaria.find_key(faixa_etaria),
		"dinheiro": _dinheiro,
		"equipado": equipado_dados,
		"coletados": _coletados.keys(),
	}


## Restaura o que [method para_dados] gerou. Ids que não existem mais
## no catálogo são ignorados. Jogos salvos antes dos espaços ("itens":
## id -> quantidade) viram espaços na ordem do arquivo, sem perder nada.
func de_dados(dados: Dictionary) -> void:
	limpar()
	var faixa := str(dados.get("faixa_etaria", ""))
	if FaixaEtaria.has(faixa):
		faixa_etaria = FaixaEtaria[faixa]
	_espacos.resize(capacidade())
	var lidos: Array = dados.get("espacos", [])
	for indice in lidos.size():
		var espaco: Variant = lidos[indice]
		if not espaco is Dictionary or (espaco as Dictionary).is_empty():
			continue
		var dados_item := item(str(espaco.get("id", "")))
		var qtd := int(espaco.get("quantidade", 0))
		if dados_item == null or qtd <= 0:
			continue
		if dados_item.e_da_historia():
			_historia[dados_item.id] = quantidade(dados_item.id) + qtd
			continue
		if indice >= _espacos.size():
			_espacos.resize(indice + 1)
		_espacos[indice] = { "id": dados_item.id, "quantidade": qtd }
	var historia: Dictionary = dados.get("historia", {})
	for id: Variant in historia:
		if item(str(id)) != null and int(historia[id]) > 0:
			_historia[str(id)] = int(historia[id])
	var antigos: Dictionary = dados.get("itens", {})
	for id: Variant in antigos:
		var dados_item := item(str(id))
		if dados_item == null or int(antigos[id]) <= 0:
			continue
		if dados_item.e_da_historia():
			_historia[dados_item.id] = int(antigos[id])
		else:
			# Sem limite aqui: o que não couber abre espaços no fim.
			_guardar(_espacos, dados_item, int(antigos[id]), 1 << 20)
	_ajustar_tamanho()
	_dinheiro = maxi(0, int(dados.get("dinheiro", 0)))
	for id_coleta: Variant in dados.get("coletados", []):
		_coletados[str(id_coleta)] = true
	var equipado_dados: Dictionary = dados.get("equipado", {})
	for personagem: Variant in equipado_dados:
		var encaixes: Dictionary = equipado_dados[personagem]
		for nome: Variant in encaixes:
			if Item.Encaixe.has(str(nome)):
				equipar(str(personagem), str(encaixes[nome]))


func _vezes_equipado(id: String) -> int:
	var vezes := 0
	for personagem: String in _equipado:
		for encaixe: int in _equipado[personagem]:
			if _equipado[personagem][encaixe] == id:
				vezes += 1
	return vezes


func _desequipar_pesados() -> void:
	for personagem: String in _equipado.keys():
		for encaixe: int in _equipado[personagem].keys():
			if pesado_para_a_idade(_equipado[personagem][encaixe]):
				desequipar(personagem, encaixe)


func _desequipar_excedente(id: String) -> void:
	for personagem: String in _equipado.keys():
		if _vezes_equipado(id) <= quantidade(id):
			return
		for encaixe: int in _equipado[personagem].keys():
			if _equipado[personagem][encaixe] == id:
				desequipar(personagem, encaixe)
				break


## Põe até [param qtd] de [param dados] em [param espacos], usando só os
## [param limite] primeiros. Devolve quanto sobrou (0 = coube tudo).
func _guardar(espacos: Array[Dictionary], dados: Item, qtd: int, limite: int) -> int:
	var pilha := dados.tamanho_pilha()
	var falta := qtd
	for indice in mini(espacos.size(), limite):
		if falta == 0:
			return 0
		var espaco := espacos[indice]
		if espaco.get("id", "") == dados.id and int(espaco["quantidade"]) < pilha:
			var entra := mini(falta, pilha - int(espaco["quantidade"]))
			espaco["quantidade"] = int(espaco["quantidade"]) + entra
			falta -= entra
	var indice := 0
	while falta > 0 and indice < limite:
		if indice >= espacos.size():
			espacos.append({})
		if espacos[indice].is_empty():
			var entra := mini(falta, pilha)
			espacos[indice] = { "id": dados.id, "quantidade": entra }
			falta -= entra
		indice += 1
	return falta


## Tira até [param qtd] do espaço; devolve quanto tirou.
func _tirar_do_espaco(indice: int, qtd: int) -> int:
	var espaco := _espacos[indice]
	var sai := mini(qtd, int(espaco["quantidade"]))
	espaco["quantidade"] = int(espaco["quantidade"]) - sai
	if int(espaco["quantidade"]) == 0:
		_espacos[indice] = {}
	return sai


## Deixa a bolsa com a capacidade da idade; espaços além dela só ficam
## enquanto tiverem algo (bolsa que encolheu).
func _ajustar_tamanho() -> void:
	if _espacos.size() < capacidade():
		_espacos.resize(capacidade())
		return
	while _espacos.size() > capacidade() and _espacos.back().is_empty():
		_espacos.pop_back()
