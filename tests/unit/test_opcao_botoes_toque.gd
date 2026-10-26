extends GutTest
## Opção "Botões de toque na tela" na tela de opções.


func test_caixa_liga_e_desliga_a_opcao() -> void:
	var antes := Configuracoes.botoes_toque
	var tela: TelaOpcoes = load("res://scenes/ui/tela_opcoes.tscn").instantiate()
	add_child_autofree(tela)
	tela.abrir()
	assert_eq(tela.botoes_toque.button_pressed, antes)
	tela.botoes_toque.button_pressed = not antes
	assert_eq(Configuracoes.botoes_toque, not antes)
	Configuracoes.definir("botoes_toque", antes)
