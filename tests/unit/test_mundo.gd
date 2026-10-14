extends GutTest
## Autoload Mundo: dia/noite e lugares descobertos, e o jogo salvo guarda os dois.

var _arquivo_progresso: String


func before_each() -> void:
	_arquivo_progresso = Progresso.arquivo
	Progresso.arquivo = "user://teste_progresso_mundo.cfg"
	Mundo.limpar()


func after_each() -> void:
	Progresso.apagar()
	Progresso.arquivo = _arquivo_progresso
	Mundo.limpar()


func test_alternar_periodo_avisa() -> void:
	watch_signals(Mundo)
	Mundo.alternar_periodo()
	assert_true(Mundo.noite)
	assert_signal_emitted_with_parameters(Mundo, "periodo_mudou", [true])


func test_descobrir_so_avisa_na_primeira_vez() -> void:
	watch_signals(Mundo)
	assert_true(Mundo.descobrir("atenas"))
	assert_false(Mundo.descobrir("atenas"))
	assert_signal_emit_count(Mundo, "descoberto", 1)


func test_salvar_e_carregar() -> void:
	Mundo.definir_noite(true)
	Mundo.descobrir("olympia")
	Mundo.local_no_mapa = "olympia"
	Progresso.salvar("teste")
	Mundo.limpar()
	assert_true(Progresso.carregar())
	assert_true(Mundo.noite)
	assert_true(Mundo.foi_descoberto("olympia"))
	assert_eq(Mundo.local_no_mapa, "olympia")


func test_novo_jogo_esquece_o_mapa() -> void:
	Mundo.descobrir("olympia")
	Progresso.novo_jogo()
	assert_false(Mundo.foi_descoberto("olympia"))
