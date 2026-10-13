extends Node
## Jogo salvo (autoload "Progresso"): em que parte da história o jogador está,
## mais os valores de [Relacoes] e [Influencia]. Fica em user://progresso.cfg.

const ARQUIVO := "user://progresso.cfg"

## Parte da história em que o jogador parou; vazio quando não há jogo salvo.
var etapa := ""

var arquivo := ARQUIVO


func tem_jogo_salvo() -> bool:
	return FileAccess.file_exists(arquivo)


## Começa do zero (Novo jogo).
func novo_jogo() -> void:
	etapa = ""
	Relacoes.limpar()
	Influencia.limpar()


func salvar(nova_etapa: String) -> void:
	etapa = nova_etapa
	var cfg := ConfigFile.new()
	cfg.set_value("jogo", "etapa", etapa)
	cfg.set_value("jogo", "relacoes", Relacoes.para_dados())
	cfg.set_value("jogo", "influencia", Influencia.para_dados())
	cfg.save(arquivo)


## Restaura o jogo salvo. Devolve false quando não há.
func carregar() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(arquivo) != OK:
		return false
	etapa = cfg.get_value("jogo", "etapa", "")
	Relacoes.de_dados(cfg.get_value("jogo", "relacoes", {}))
	Influencia.de_dados(cfg.get_value("jogo", "influencia", {}))
	return true


func apagar() -> void:
	if tem_jogo_salvo():
		DirAccess.remove_absolute(arquivo)
	etapa = ""
