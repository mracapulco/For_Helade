extends GutTest
## Barra rápida da sala de teste: teclas 1 a 9 e toque usam os espaços.

var sala: Node2D
var barra: BarraRapida


func before_each() -> void:
	Inventario.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	barra = sala.get_node("BarraRapida")
	await wait_physics_frames(2)


func after_each() -> void:
	Inventario.limpar()


func _apertar(acao: StringName) -> void:
	var evento := InputEventAction.new()
	evento.action = acao
	evento.pressed = true
	barra._unhandled_input(evento)


func test_tem_nove_espacos_numerados() -> void:
	assert_eq(barra.espacos.size(), 9)
	assert_eq((barra.espacos[0].get_node("Numero") as Label).text, "1")
	assert_eq((barra.espacos[8].get_node("Numero") as Label).text, "9")


func test_acoes_das_teclas_existem() -> void:
	for indice in 9:
		assert_true(InputMap.has_action(BarraRapida.acao_do_espaco(indice)), str(indice))


func test_tecla_so_seleciona_e_poe_a_arma_na_mao() -> void:
	var indice := _indice_de("espada_media")
	_apertar(BarraRapida.acao_do_espaco(indice))
	assert_eq(Inventario.espaco_selecionado, indice)
	assert_true(barra.espacos[indice].selecionado)
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "espada_media")


func test_selecionar_a_pocao_nao_bebe_e_tira_a_arma_da_mao() -> void:
	_apertar(BarraRapida.acao_do_espaco(_indice_de("espada_media")))
	var antes := Inventario.quantidade("pocao_teste")
	_apertar(BarraRapida.acao_do_espaco(_indice_de("pocao_teste")))
	assert_eq(Inventario.quantidade("pocao_teste"), antes)
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "")


func test_clique_bebe_a_pocao_selecionada() -> void:
	_apertar(BarraRapida.acao_do_espaco(_indice_de("pocao_teste")))
	var antes := Inventario.quantidade("pocao_teste")
	_apertar(&"golpear")
	assert_eq(Inventario.quantidade("pocao_teste"), antes - 1)


func test_clique_com_a_arma_fica_para_o_golpe() -> void:
	_apertar(BarraRapida.acao_do_espaco(_indice_de("espada_media")))
	var antes := Inventario.quantidade("pocao_teste")
	_apertar(&"golpear")
	assert_eq(Inventario.quantidade("pocao_teste"), antes)
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "espada_media")


func test_clique_veste_e_tira_a_protecao_selecionada() -> void:
	Inventario.adicionar("escudo_olympia")
	_apertar(BarraRapida.acao_do_espaco(_indice_de("escudo_olympia")))
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ESCUDO), "")
	_apertar(&"golpear")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ESCUDO), "escudo_olympia")
	_apertar(&"golpear")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ESCUDO), "")


func test_tocar_no_espaco_so_seleciona() -> void:
	var indice := _indice_de("pocao_teste")
	var antes := Inventario.quantidade("pocao_teste")
	barra.espacos[indice].pressed.emit()
	assert_eq(Inventario.espaco_selecionado, indice)
	assert_eq(Inventario.quantidade("pocao_teste"), antes)


func test_barra_fica_no_meio_embaixo() -> void:
	await wait_process_frames(2)
	var centro := barra.caixa.get_global_rect().get_center()
	var tela := barra.caixa.get_viewport_rect().size
	assert_almost_eq(centro.x, tela.x / 2.0, 2.0)
	assert_gt(centro.y, tela.y * 0.8)


func test_mostra_a_quantidade() -> void:
	var indice := _indice_de("pocao_teste")
	var qtd := Inventario.quantidade("pocao_teste")
	assert_eq((barra.espacos[indice].get_node("Quantidade") as Label).text, str(qtd))


func _indice_de(id: String) -> int:
	for indice in Inventario.ESPACOS_RAPIDOS:
		if Inventario.espaco(indice).get("id", "") == id:
			return indice
	fail_test("%s não está na barra rápida" % id)
	return -1
