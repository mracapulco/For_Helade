extends GutTest
## Tela do Códice na sala de teste: abas, leitura, ponto de "novo" e teclas.

var sala: Node2D
var tela: TelaCodice
var bolsa: TelaBolsa


func before_each() -> void:
	Codice.limpar()
	TranslationServer.set_locale("pt_BR")
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	tela = sala.get_node("TelaCodice")
	bolsa = sala.get_node("TelaBolsa")
	await wait_process_frames(2)


func after_each() -> void:
	get_tree().paused = false
	Codice.limpar()


func _apertar_tecla(codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = codigo
	evento.keycode = codigo
	evento.pressed = true
	Input.parse_input_event(evento)
	evento = evento.duplicate()
	evento.pressed = false
	Input.parse_input_event(evento)


func _ponto(botao: Button) -> bool:
	var ponto := botao.get_node_or_null(TelaCodice.NOME_PONTO) as Control
	return ponto != null and ponto.visible


func _titulos() -> Array[String]:
	var lista: Array[String] = []
	for botao: Button in tela.lista.get_children():
		if not botao.is_queued_for_deletion():
			lista.append(botao.text)
	return lista


func test_comeca_fechada_com_o_botao_a_mostra() -> void:
	assert_false(tela.aberta())
	assert_true(tela.botao_codice.visible)
	assert_eq(tr(tela.botao_codice.text), "Códice")


func test_tecla_c_abre_pausa_e_fecha() -> void:
	_apertar_tecla(KEY_C)
	await wait_process_frames(2)
	assert_true(tela.aberta())
	assert_true(get_tree().paused)
	assert_false(tela.botao_codice.visible)
	_apertar_tecla(KEY_C)
	await wait_process_frames(2)
	assert_false(tela.aberta())
	assert_false(get_tree().paused)


func test_esc_fecha() -> void:
	tela.abrir()
	_apertar_tecla(KEY_ESCAPE)
	await wait_process_frames(2)
	assert_false(tela.aberta())


func test_aba_vazia_diz_que_nada_foi_anotado() -> void:
	tela.abrir()
	assert_true(tela.vazio.visible)
	assert_eq(tr(tela.vazio.text), "Nada anotado ainda.")


func test_abas_separam_olhar_e_codice_na_ordem() -> void:
	Codice.anotar("roupas_simples")
	Codice.anotar("palacio_imperial")
	Codice.anotar("atenas")
	tela.abrir()
	tela.escolher_aba(Codice.TIPO_OLHAR)
	assert_eq(_titulos(), ["Roupas simples"] as Array[String])
	tela.escolher_aba(Codice.TIPO_CODICE)
	assert_eq(_titulos(), ["Palácio Imperial", "Atenas"] as Array[String])
	assert_false(tela.vazio.visible)
	assert_eq(tela.texto_entrada.text, "Escolha uma anotação para ler.")


func test_escolher_mostra_o_texto_e_tira_o_ponto() -> void:
	Codice.anotar("atenas")
	assert_true(_ponto(tela.botao_codice), "O botão avisa que há novidade.")
	tela.abrir()
	assert_eq(tela.aba, Codice.TIPO_CODICE, "Abre na aba que tem novidade.")
	var botao: Button = tela.lista.get_node("atenas")
	assert_true(_ponto(botao))
	assert_true(_ponto(tela.botoes_abas[Codice.TIPO_CODICE]))
	botao.pressed.emit()
	assert_eq(tela.titulo_entrada.text, "Atenas")
	assert_eq(tela.texto_entrada.text, Codice.texto("atenas"))
	assert_false(Codice.novo("atenas"))
	assert_false(_ponto(botao))
	assert_false(_ponto(tela.botoes_abas[Codice.TIPO_CODICE]))
	tela.fechar()
	assert_false(_ponto(tela.botao_codice))


func test_nao_abre_com_a_bolsa_aberta_nem_a_bolsa_com_ele() -> void:
	bolsa.abrir()
	await wait_process_frames(2)
	assert_false(tela.botao_codice.visible)
	_apertar_tecla(KEY_C)
	await wait_process_frames(2)
	assert_false(tela.aberta())
	bolsa.fechar()
	tela.abrir()
	_apertar_tecla(KEY_I)
	await wait_process_frames(2)
	assert_false(bolsa.aberta())
	assert_true(tela.aberta())


func test_esta_nas_cenas_de_exploracao() -> void:
	for caminho in ["res://scenes/exploracao/biblioteca_olympia.tscn",
			"res://scenes/exploracao/acampamentos/acampamento_base.tscn",
			"res://scenes/capitulo_01/capitulo_01.tscn"]:
		var estado := (load(caminho) as PackedScene).get_state()
		var achou := false
		for i in estado.get_node_count():
			if estado.get_node_name(i) == &"TelaCodice":
				achou = true
		assert_true(achou, caminho)
