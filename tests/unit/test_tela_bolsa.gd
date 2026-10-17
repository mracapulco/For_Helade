extends GutTest
## Tela da bolsa em grade na sala de teste, com os itens provisórios.

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


func _indice_de(id: String) -> int:
	for indice in Inventario.numero_de_espacos():
		if Inventario.espaco(indice).get("id", "") == id:
			return indice
	return -1


func test_comeca_fechada_com_o_botao_a_mostra() -> void:
	assert_false(bolsa.aberta())
	assert_true(bolsa.botao_bolsa.visible)


func test_sala_de_teste_poe_itens_provisorios() -> void:
	assert_true(Inventario.tem("espada_media"))
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


func test_botoes_e_espacos_sao_grandes() -> void:
	bolsa.abrir()
	await wait_process_frames(2)
	assert_gte(bolsa.botao_bolsa.size.y, 64.0)
	assert_gte(bolsa.botao_fechar.size.y, 64.0)
	for espaco in bolsa.espacos:
		assert_gte(espaco.size.y, 64.0)


func test_um_espaco_para_cada_lugar_da_bolsa() -> void:
	bolsa.abrir()
	assert_eq(bolsa.espacos.size(), Inventario.numero_de_espacos())
	assert_eq(bolsa.grade_rapida.get_child_count(), 9)
	assert_eq(bolsa.grade.get_child_count(), Inventario.numero_de_espacos() - 9)


func test_dinheiro_e_espacos_aparecem_no_topo() -> void:
	bolsa.abrir()
	assert_eq(bolsa.rotulo_dinheiro.text, "Moedas: 20")
	assert_eq(bolsa.rotulo_espacos.text, "Espaços: 2/30")


func test_botao_de_idade_muda_o_tamanho() -> void:
	bolsa.abrir()
	assert_true(bolsa.botao_idade.visible)
	assert_eq(bolsa.botao_idade.text, "Idade: Adulto")
	bolsa.botao_idade.pressed.emit()
	assert_eq(Inventario.capacidade(), 12)
	assert_eq(bolsa.espacos.size(), 12)
	assert_eq(bolsa.botao_idade.text, "Idade: Criança")


func test_tocar_no_item_mostra_detalhe_e_acoes() -> void:
	bolsa.abrir()
	bolsa.espacos[_indice_de("pocao_teste")].pressed.emit()
	assert_eq(bolsa.item_escolhido, "pocao_teste")
	assert_eq(bolsa.nome_item.text, "Poção de teste")
	assert_true(bolsa.botao_usar.visible)
	assert_false(bolsa.botao_equipar.visible)
	assert_true(bolsa.botao_largar.visible)
	assert_true(bolsa.espacos[_indice_de("pocao_teste")].escolhido)


func test_tocar_noutro_espaco_muda_o_item_de_lugar() -> void:
	bolsa.abrir()
	var origem := _indice_de("espada_media")
	bolsa.tocar_espaco(origem)
	bolsa.tocar_espaco(15)
	assert_eq(Inventario.espaco(15).get("id", ""), "espada_media")
	assert_true(Inventario.espaco(origem).is_empty())
	assert_eq(bolsa.espaco_escolhido, -1)


func test_tocar_de_novo_desfaz_a_escolha() -> void:
	bolsa.abrir()
	var indice := _indice_de("espada_media")
	bolsa.tocar_espaco(indice)
	bolsa.tocar_espaco(indice)
	assert_eq(bolsa.espaco_escolhido, -1)
	assert_eq(bolsa.item_escolhido, "")


func test_espaco_vazio_nao_fica_escolhido() -> void:
	bolsa.abrir()
	bolsa.tocar_espaco(20)
	assert_eq(bolsa.espaco_escolhido, -1)


func test_usar_gasta_uma_pocao() -> void:
	bolsa.abrir()
	bolsa.escolher_espaco(_indice_de("pocao_teste"))
	bolsa.botao_usar.pressed.emit()
	assert_eq(Inventario.quantidade("pocao_teste"), 2)


func test_equipar_e_desequipar_a_espada() -> void:
	bolsa.abrir()
	bolsa.escolher_espaco(_indice_de("espada_media"))
	bolsa.botao_equipar.pressed.emit()
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "espada_media")
	assert_eq(bolsa.botao_equipar.text, "Desequipar")
	bolsa.botao_equipar.pressed.emit()
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "")


func test_item_da_historia_fica_no_bolso_sem_largar() -> void:
	bolsa.abrir()
	assert_eq(bolsa.bolso_historia.get_child_count(), 1)
	(bolsa.bolso_historia.get_child(0) as Button).pressed.emit()
	assert_eq(bolsa.item_escolhido, "carta_teste")
	assert_false(bolsa.botao_largar.visible)
	assert_ne(bolsa.aviso_item.text, "")


func test_largar_o_ultimo_limpa_o_detalhe() -> void:
	bolsa.abrir()
	var indice := _indice_de("espada_media")
	bolsa.escolher_espaco(indice)
	bolsa.botao_largar.pressed.emit()
	assert_false(Inventario.tem("espada_media"))
	assert_eq(bolsa.item_escolhido, "")
	assert_false(bolsa.botao_largar.visible)


func test_largar_tira_do_espaco_escolhido() -> void:
	Inventario.adicionar("pocao_teste", 10)
	bolsa.abrir()
	var primeiro := _indice_de("pocao_teste")
	bolsa.escolher_espaco(primeiro)
	bolsa.botao_largar.pressed.emit()
	assert_eq(Inventario.espaco(primeiro)["quantidade"], 9)


func test_toque_no_botao_bolsa_nao_faz_andar() -> void:
	var centro := bolsa.botao_bolsa.get_global_rect().get_center()
	assert_true(BotoesToque.toque_em_botao(get_tree(), centro))


func test_textos_vem_da_traducao() -> void:
	bolsa.abrir()
	assert_eq(tr(bolsa.botao_bolsa.text), "Bolsa")
