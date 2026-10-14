extends GutTest
## O jogo salvo guarda a bolsa, e Novo jogo a esvazia.

var _arquivo_progresso: String


func before_each() -> void:
	_arquivo_progresso = Progresso.arquivo
	Progresso.arquivo = "user://teste_progresso_inventario.cfg"
	Inventario.limpar()


func after_each() -> void:
	Progresso.apagar()
	Progresso.arquivo = _arquivo_progresso
	Inventario.limpar()


func test_salvar_e_carregar_guarda_a_bolsa() -> void:
	Inventario.adicionar("pocao_teste", 2)
	Inventario.ganhar_dinheiro(7)
	Inventario.marcar_coletado("bau_x")
	Progresso.salvar("capitulo_1")
	Inventario.limpar()
	assert_true(Progresso.carregar())
	assert_eq(Inventario.quantidade("pocao_teste"), 2)
	assert_eq(Inventario.dinheiro(), 7)
	assert_true(Inventario.ja_coletado("bau_x"))


func test_novo_jogo_esvazia_a_bolsa() -> void:
	Inventario.adicionar("pocao_teste")
	Progresso.novo_jogo()
	assert_false(Inventario.tem("pocao_teste"))
