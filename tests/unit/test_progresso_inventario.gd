extends GutTest
## O jogo salvo guarda a bolsa, e Novo jogo a esvazia.

var _pasta_progresso: String


func before_each() -> void:
	_pasta_progresso = Progresso.pasta
	Progresso.pasta = "user://teste_saves_inventario/"
	Progresso.apagar_todos()
	Inventario.limpar()


func after_each() -> void:
	Progresso.apagar_todos()
	Progresso.pasta = _pasta_progresso
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
