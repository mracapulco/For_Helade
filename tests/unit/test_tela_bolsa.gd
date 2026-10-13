extends GutTest
## Tela da bolsa na sala de teste, com os itens provisórios.

var sala: Node2D
var bolsa: TelaBolsa


func before_each() -> void:
	Inventario.limpar()
	TranslationServer.set_locale("pt_BR")
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	bolsa = sala.get_node("TelaBolsa")
	await wait_process_frames(2)


func after_each() -> void:
	get_tree().paused = false
	Inventario.limpar()


func _apertar_tecla(codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = codigo
	evento.pressed = true
	Input.parse_input_event(evento)
	evento = evento.duplicate()
	evento.pressed = false
	Input.parse_input_event(evento)


func test_comeca_fechada_com_o_botao_a_mostra() -> void:
	assert_false(bolsa.aberta())
	assert_true(bolsa.botao_bolsa.visible)


func test_sala_de_teste_poe_itens_provisorios() -> void:
	assert_true(Inventario.tem("espada_teste"))
	assert_eq(Inventario.quantidade("pocao_teste"), 3)
	assert_true(Inventario.tem("carta_teste"))
	assert_eq(Inventario.dinheiro(), 20)


func test_abrir_pausa_e_fechar_despausa() -> void:
	bolsa.abrir()
	assert_true(bolsa.aberta())
	assert_true(get_tree().paused)
	bolsa.fechar()
	assert_false(bolsa.aberta())
	assert_false(get_tree().paused)


func test_tecla_i_abre_e_fecha() -> void:
	_apertar_tecla(KEY_I)
	await wait_process_frames(2)
	assert_true(bolsa.aberta())
	_apertar_tecla(KEY_I)
	await wait_process_frames(2)
	assert_false(bolsa.aberta())


func test_tab_abre_e_fecha() -> void:
	_apertar_tecla(KEY_TAB)
	await wait_process_frames(2)
	assert_true(bolsa.aberta())
	_apertar_tecla(KEY_TAB)
	await wait_process_frames(2)
	assert_false(bolsa.aberta())


func test_botoes_sao_grandes() -> void:
	bolsa.abrir()
	await wait_process_frames(2)
	assert_gte(bolsa.botao_bolsa.size.y, 64.0)
	assert_gte(bolsa.botao_fechar.size.y, 64.0)
	for botao: Button in bolsa.botoes_aba.values():
		assert_gte(botao.size.y, 64.0)


func test_dinheiro_aparece_no_topo() -> void:
	bolsa.abrir()
	assert_eq(bolsa.rotulo_dinheiro.text, "Moedas: 20")


func test_cada_aba_mostra_so_o_seu_tipo() -> void:
	bolsa.abrir()
	bolsa.mostrar_aba(Item.Tipo.ARMA)
	assert_eq(bolsa.itens_da_aba(), ["espada_teste"] as Array[String])
	assert_eq(bolsa.lista.get_child_count(), 1)
	bolsa.mostrar_aba(Item.Tipo.CONSUMIVEL)
	assert_eq(bolsa.itens_da_aba(), ["pocao_teste"] as Array[String])
	bolsa.mostrar_aba(Item.Tipo.DIVERSOS)
	assert_eq(bolsa.lista.get_child_count(), 0)
	assert_true(bolsa.rotulo_vazio.visible)


func test_tocar_no_item_mostra_detalhe_e_acoes() -> void:
	bolsa.abrir()
	bolsa.mostrar_aba(Item.Tipo.CONSUMIVEL)
	(bolsa.lista.get_child(0) as Button).pressed.emit()
	assert_eq(bolsa.item_escolhido, "pocao_teste")
	assert_eq(bolsa.nome_item.text, "Poção de teste")
	assert_true(bolsa.botao_usar.visible)
	assert_false(bolsa.botao_equipar.visible)
	assert_true(bolsa.botao_largar.visible)


func test_usar_gasta_uma_pocao() -> void:
	bolsa.abrir()
	bolsa.mostrar_aba(Item.Tipo.CONSUMIVEL)
	bolsa.escolher_item("pocao_teste")
	bolsa.botao_usar.pressed.emit()
	assert_eq(Inventario.quantidade("pocao_teste"), 2)


func test_equipar_e_desequipar_a_espada() -> void:
	bolsa.abrir()
	bolsa.escolher_item("espada_teste")
	bolsa.botao_equipar.pressed.emit()
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "espada_teste")
	assert_eq(bolsa.botao_equipar.text, "Desequipar")
	bolsa.botao_equipar.pressed.emit()
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "")


func test_item_da_historia_nao_tem_largar() -> void:
	bolsa.abrir()
	bolsa.mostrar_aba(Item.Tipo.HISTORIA)
	bolsa.escolher_item("carta_teste")
	assert_false(bolsa.botao_largar.visible)
	assert_ne(bolsa.aviso_item.text, "")


func test_largar_o_ultimo_limpa_o_detalhe() -> void:
	bolsa.abrir()
	bolsa.escolher_item("espada_teste")
	bolsa.botao_largar.pressed.emit()
	assert_false(Inventario.tem("espada_teste"))
	assert_eq(bolsa.item_escolhido, "")
	assert_false(bolsa.botao_largar.visible)


func test_toque_no_botao_bolsa_nao_faz_andar() -> void:
	var centro := bolsa.botao_bolsa.get_global_rect().get_center()
	assert_true(BotoesToque.toque_em_botao(get_tree(), centro))


func test_textos_vem_da_traducao() -> void:
	bolsa.abrir()
	assert_eq(tr(bolsa.botao_bolsa.text), "Bolsa")
	assert_eq(tr(bolsa.botoes_aba[Item.Tipo.ARMA].text), "Armas")
