extends GutTest
## Capítulo 01, cenas 7 a 10 jogadas de ponta a ponta (sem tempos nem caixa
## de diálogo): cada cena termina e pede a próxima.

var cena: CenaCapitulo01


func before_each() -> void:
	Codice.limpar()
	Relacoes.limpar()


func after_each() -> void:
	Codice.limpar()
	Relacoes.limpar()


func _abrir(caminho: String, etapa_inicial: String) -> void:
	cena = load(caminho).instantiate()
	cena.escala_tempo = 0.0
	cena.mostrar_dialogos = false
	cena.trocar_de_cena = false
	add_child_autofree(cena)
	await _esperar_etapa(etapa_inicial)
	# Deixa as frases de abertura (e as notas do códice delas) terminarem.
	await wait_physics_frames(10)


func _esperar_etapa(nome: String) -> void:
	for i in 240:
		if cena.etapa == nome:
			return
		await wait_physics_frames(1)
	fail_test("não chegou na etapa %s (está em %s)" % [nome, cena.etapa])


func _esperar_pedido() -> void:
	for i in 240:
		if cena.cena_pedida != "":
			return
		await wait_physics_frames(1)
	fail_test("a cena não pediu a próxima (etapa %s)" % cena.etapa)


func test_palacio_do_patio_a_partida() -> void:
	await _abrir("res://scenes/capitulo_01/cena_palacio.tscn", "patio")
	assert_eq(cena.sala.largura, 15)
	assert_eq(cena.sala.profundidade, 14)
	assert_eq(cena.sala.piso, "patio")
	cena.olhar_guardas()
	await wait_physics_frames(2)
	assert_eq(cena.etapa, "patio", "só os guardas não bastam: falta chegar à fonte")
	cena.ver_fonte()
	await _esperar_etapa("embarque")
	assert_true(Codice.tem("poucos_guardas"))
	assert_true(Codice.tem("olhos_de_ophelia"))
	cena.embarcar()
	await _esperar_etapa("ultimo_olhar")
	var carruagem: Node2D = cena.objetos["carruagem"]
	for nome: String in ["althea", "ophelia"]:
		assert_false(cena.objetos[nome].visible, "%s saiu do lado da carruagem" % nome)
		var sentada: Sprite2D = cena.objetos[nome + "_sentado"]
		assert_true(sentada.visible and is_equal_approx(sentada.modulate.a, 1.0), "%s sentada e visível" % nome)
		assert_eq(sentada.get_parent(), carruagem, "%s está dentro da carruagem" % nome)
	assert_lt(cena.objetos["althea_sentado"].position.x, cena.objetos["ophelia_sentado"].position.x,
		"lado a lado: Althea à esquerda, Ophelia à direita")
	assert_eq(carruagem.get_child(-1).name, "Frente", "a borda da frente cobre o quadril delas")
	cena.olhar_anexo()
	await _esperar_etapa("visao_carruagem")
	assert_true(cena.objetos["nicholas_sentado"].visible, "Nicholas também sobe e senta")
	assert_eq(carruagem.get_child(-1).name, "Frente")
	assert_true(Codice.tem("anexo_vazio"))
	await _esperar_pedido()
	assert_eq(cena.cena_pedida, SequenciaCenas01.CENAS["visao_carruagem"])


func test_palacio_carruagem_atras_e_althea_na_fonte() -> void:
	await _abrir("res://scenes/capitulo_01/cena_palacio.tscn", "patio")
	var casa_jogador: Vector2i = cena._casa_de(cena.jogador)
	var casa_carruagem: Vector2i = cena._casa_de(cena.objetos["carruagem"])
	assert_gt(casa_carruagem.y, casa_jogador.y, "a carruagem fica atrás de Nicholas, no portão")
	await wait_seconds(0.2)
	assert_eq(cena._casa_de(cena.objetos["althea"]), CenaPalacio.CASA_ALTHEA_FONTE, "Althea corre até a fonte")


func test_palacio_andar_pelo_caminho_ve_os_guardas_e_chega_a_fonte() -> void:
	await _abrir("res://scenes/capitulo_01/cena_palacio.tscn", "patio")
	cena.jogador.position = cena.sala.centro(Vector2i(7, CenaPalacio.LINHA_POSTOS))
	await wait_physics_frames(3)
	assert_true(cena.guardas_vistos, "passar entre os postos mostra os poucos guardas")
	assert_eq(cena.etapa, "patio")
	cena.jogador.position = cena.sala.centro(Vector2i(7, 7))
	await _esperar_etapa("embarque")
	assert_true(Codice.tem("poucos_guardas"))


func test_palacio_fora_de_ordem_nao_avanca() -> void:
	await _abrir("res://scenes/capitulo_01/cena_palacio.tscn", "patio")
	cena.embarcar()
	cena.olhar_anexo()
	assert_eq(cena.etapa, "patio")


func test_butiques_da_rua_a_loja_e_ao_restaurante() -> void:
	await _abrir("res://scenes/capitulo_01/cena_butiques.tscn", "rua")
	var butiques := cena as CenaButiques
	assert_eq(cena.sala.largura, CenaButiques.LARGURA_RUA)
	cena.entrar_na_loja()
	assert_eq(cena.etapa, "rua", "a porta só abre depois de escolher os guardas")
	butiques.escolher_guarda(butiques.guardas[0])
	butiques.escolher_guarda(butiques.guardas[0])
	await wait_physics_frames(5)
	assert_eq(cena.etapa, "rua", "um guarda só (escolhido duas vezes) não basta")
	assert_eq(butiques.escolhidos.size(), 1)
	assert_not_null(butiques.guardas[0].get_node_or_null("Marca"))
	butiques.escolher_guarda(butiques.guardas[2])
	await _esperar_etapa("porta")
	assert_true(Codice.tem("rua_das_butiques"))
	cena.entrar_na_loja()
	await _esperar_etapa("prateleiras")
	assert_eq(cena.sala.largura, 8)
	assert_true(cena.objetos.has("lojista_homem"))
	var nomes: Array = CenaButiques.PRATELEIRAS.keys()
	butiques.procurar_na_prateleira(nomes[0])
	butiques.procurar_na_prateleira(nomes[0])
	butiques.procurar_na_prateleira(nomes[1])
	await wait_physics_frames(5)
	assert_eq(cena.etapa, "prateleiras", "duas prateleiras ainda não bastam")
	butiques.procurar_na_prateleira(nomes[2])
	await _esperar_pedido()
	assert_eq(cena.etapa, "restaurante")
	assert_eq(cena.cena_pedida, SequenciaCenas01.CENAS["restaurante"])
	assert_eq(Relacoes.valor("ophelia"), 1)


func test_butiques_comitiva_segue_nicholas() -> void:
	await _abrir("res://scenes/capitulo_01/cena_butiques.tscn", "rua")
	var butiques := cena as CenaButiques
	butiques.escolher_guarda(butiques.guardas[0])
	butiques.escolher_guarda(butiques.guardas[1])
	await _esperar_etapa("porta")
	assert_eq(butiques.seguidores.size(), 4, "Althea, Ophelia e os dois escolhidos")
	var casa := cena._casa_de(cena.jogador)
	var passos: Array[Vector2i] = [casa + Vector2i(0, -1), casa + Vector2i(-1, -1), casa + Vector2i(-2, -1)]
	for passo in passos:
		cena.jogador.position = cena.sala.centro(passo)
		await wait_physics_frames(4)
	assert_eq(cena._casa_de(cena.objetos["althea"]), passos[1], "Althea vem uma casa atrás")
	assert_eq(cena._casa_de(cena.objetos["ophelia"]), passos[0], "Ophelia logo atrás dela")
	for casa_da_carruagem in CenaButiques.CASAS_DA_CARRUAGEM:
		for guarda in butiques.guardas:
			assert_ne(cena._casa_de(guarda), CenaButiques.CASA_CARRUAGEM + casa_da_carruagem)


func test_butiques_carruagem_fora_do_caminho() -> void:
	await _abrir("res://scenes/capitulo_01/cena_butiques.tscn", "rua")
	var carruagem: Vector2i = cena._casa_de(cena.objetos["carruagem"])
	var nicholas: Vector2i = cena._casa_de(cena.jogador)
	var porta := CenaButiques.CASA_PORTA_LOJA
	# A carruagem fica atrás de Nicholas: mais longe da porta do que ele.
	assert_gt(carruagem.y, nicholas.y)
	assert_gt((carruagem - porta).length(), (nicholas - porta).length())


func test_restaurante_da_mesa_ao_passeio() -> void:
	await _abrir("res://scenes/capitulo_01/cena_restaurante.tscn", "mesa")
	cena.pegar_colher_limpa()
	assert_eq(cena.etapa, "mesa", "o armário só depois do almoço")
	cena.sentar_a_mesa()
	await _esperar_etapa("armario")
	assert_false(cena.jogador.em_dialogo)
	cena.pegar_colher_limpa()
	await _esperar_pedido()
	assert_eq(cena.etapa, "passeio")
	assert_eq(cena.cena_pedida, SequenciaCenas01.MENU)
	assert_eq(Relacoes.valor("ophelia"), 1)


func test_visao_da_varanda_leva_as_butiques() -> void:
	await _abrir("res://scenes/capitulo_01/cena_visao.tscn", "visao")
	# Os três sentados na carruagem andando, antes e depois da visão.
	var carruagem: Node2D = cena.objetos["carruagem"]
	for nome in ["althea_sentado", "ophelia_sentado", "nicholas_sentado"]:
		assert_eq(cena.objetos[nome].get_parent(), carruagem, nome)
	assert_eq(carruagem.get_child(-1).name, "Frente")
	assert_false(cena.jogador.get_node("Corpo").visible, "Nicholas só aparece sentado")
	await _esperar_pedido()
	assert_eq(cena.etapa, "butiques")
	assert_eq(cena.cena_pedida, SequenciaCenas01.CENAS["butiques"])
