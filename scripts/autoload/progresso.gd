extends Node
## Jogos salvos (autoload "Progresso"): 10 espaços, cada um em
## user://saves/espaco_NN.cfg. Cada espaço guarda em que parte da história o
## jogador está, mais os valores de [Relacoes] e [Influencia], a bolsa
## ([code]Inventario[/code]), o mapa ([code]Mundo[/code]) e o [code]Codice[/code], com o lugar onde
## ele salvou (o acampamento; depois, o reino).

const PASTA := "user://saves/"
const TOTAL_ESPACOS := 10
## Onde ficava o jogo salvo único, antes dos espaços. Vai para o espaço 1.
const ARQUIVO_ANTIGO := "user://progresso.cfg"

## Parte da história em que o jogador parou; vazio quando não há jogo salvo.
var etapa := ""
## Espaço do jogo em andamento (1 a 10); 0 = ainda não salvou neste jogo.
var espaco_atual := 0

var pasta := PASTA
var arquivo_antigo := ARQUIVO_ANTIGO


func _ready() -> void:
	_trazer_jogo_antigo()


func caminho(espaco: int) -> String:
	return pasta + "espaco_%02d.cfg" % espaco


func espaco_valido(espaco: int) -> bool:
	return espaco >= 1 and espaco <= TOTAL_ESPACOS


func espaco_ocupado(espaco: int) -> bool:
	return espaco_valido(espaco) and FileAccess.file_exists(caminho(espaco))


func tem_jogo_salvo() -> bool:
	return espaco_mais_recente() > 0


## Espaço salvo por último (o do Continuar); 0 quando não há nenhum.
func espaco_mais_recente() -> int:
	var melhor := 0
	var quando := -1.0
	for espaco in range(1, TOTAL_ESPACOS + 1):
		var dados := resumo(espaco)
		if not dados.is_empty() and dados.salvo_em > quando:
			melhor = espaco
			quando = dados.salvo_em
	return melhor


func primeiro_espaco_livre() -> int:
	for espaco in range(1, TOTAL_ESPACOS + 1):
		if not espaco_ocupado(espaco):
			return espaco
	return 0


## O que aparece na lista de espaços: etapa, lugar e quando salvou.
## Vazio quando o espaço está livre.
func resumo(espaco: int) -> Dictionary:
	if not espaco_ocupado(espaco):
		return {}
	var cfg := ConfigFile.new()
	if cfg.load(caminho(espaco)) != OK:
		return {}
	var mundo: Dictionary = cfg.get_value("jogo", "mundo", {})
	return {
		"etapa": cfg.get_value("jogo", "etapa", ""),
		"lugar": mundo.get("local_no_mapa", ""),
		"salvo_em": float(cfg.get_value("jogo", "salvo_em", 0.0)),
	}


## Começa do zero (Novo jogo). Os espaços salvos continuam lá.
func novo_jogo() -> void:
	etapa = ""
	espaco_atual = 0
	Relacoes.limpar()
	Influencia.limpar()
	Inventario.limpar()
	Mundo.limpar()
	Codice.limpar()


## Salva em [param espaco]. Sem espaço, usa o do jogo em andamento ou, num
## jogo que ainda não salvou, o primeiro livre. Devolve false se não salvou
## (todos os espaços cheios e nenhum escolhido).
func salvar(nova_etapa: String, espaco := 0) -> bool:
	if espaco == 0:
		espaco = espaco_atual if espaco_atual > 0 else primeiro_espaco_livre()
	if not espaco_valido(espaco):
		return false
	etapa = nova_etapa
	var cfg := ConfigFile.new()
	cfg.set_value("jogo", "etapa", etapa)
	cfg.set_value("jogo", "salvo_em", Time.get_unix_time_from_system())
	cfg.set_value("jogo", "relacoes", Relacoes.para_dados())
	cfg.set_value("jogo", "influencia", Influencia.para_dados())
	cfg.set_value("jogo", "inventario", Inventario.para_dados())
	cfg.set_value("jogo", "mundo", Mundo.para_dados())
	cfg.set_value("jogo", "codice", Codice.para_dados())
	DirAccess.make_dir_recursive_absolute(pasta)
	if cfg.save(caminho(espaco)) != OK:
		return false
	espaco_atual = espaco
	return true


## Restaura um jogo salvo (sem espaço: o mais recente). Devolve false quando
## o espaço está vazio.
func carregar(espaco := 0) -> bool:
	if espaco == 0:
		espaco = espaco_mais_recente()
	var cfg := ConfigFile.new()
	if not espaco_ocupado(espaco) or cfg.load(caminho(espaco)) != OK:
		return false
	etapa = cfg.get_value("jogo", "etapa", "")
	Relacoes.de_dados(cfg.get_value("jogo", "relacoes", {}))
	Influencia.de_dados(cfg.get_value("jogo", "influencia", {}))
	Inventario.de_dados(cfg.get_value("jogo", "inventario", {}))
	Mundo.de_dados(cfg.get_value("jogo", "mundo", {}))
	Codice.de_dados(cfg.get_value("jogo", "codice", {}))
	espaco_atual = espaco
	return true


func apagar(espaco: int) -> void:
	if espaco_ocupado(espaco):
		DirAccess.remove_absolute(caminho(espaco))
	if espaco == espaco_atual:
		espaco_atual = 0


## Apaga todos os espaços (testes).
func apagar_todos() -> void:
	for espaco in range(1, TOTAL_ESPACOS + 1):
		apagar(espaco)
	etapa = ""
	espaco_atual = 0


## O jogo salvo de antes dos espaços vira o espaço 1, para ninguém perder.
func _trazer_jogo_antigo() -> void:
	if not FileAccess.file_exists(arquivo_antigo) or tem_jogo_salvo():
		return
	DirAccess.make_dir_recursive_absolute(pasta)
	if DirAccess.rename_absolute(arquivo_antigo, caminho(1)) != OK:
		return
	var cfg := ConfigFile.new()
	if cfg.load(caminho(1)) == OK and not cfg.has_section_key("jogo", "salvo_em"):
		cfg.set_value("jogo", "salvo_em", Time.get_unix_time_from_system())
		cfg.save(caminho(1))
