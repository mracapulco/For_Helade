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


func _empurrar(nome: String, de: Vector2i) -> void:
	cena.jogador.position = cena.sala.centro(de)
	await cena.empurrar(nome)


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
	await _esperar_etapa("sala_lateral")
	assert_eq(cena.sala.largura, 12, "o salão da loja")
	assert_true(cena.objetos.has("lojista_homem"))
	butiques.ir_para_sala_lateral()
	await _esperar_etapa("prateleiras")
	assert_eq(cena.sala.largura, 10, "a sala lateral")
	await wait_physics_frames(3)
	for casa: Vector2i in [Vector2i(3, 2), Vector2i(4, 2)]:
		assert_true(cena.jogador.casa_andavel(cena.sala.centro(casa)),
			"onde as meninas estavam no começo não vira buraco")
	# Pistas da Thea: só o esconderijo do pedido conta.
	await butiques.procurar("caixas_presente")
	assert_eq(butiques.achados, 0, "ainda não é esse")
	await butiques.procurar("cesta")
	await butiques.procurar("caixas_presente")
	assert_eq(butiques.achados, 2)
	await butiques.procurar("estante_alta")
	assert_eq(butiques.achados, 2, "alto demais sem o banquinho")
	# Andar contra o banquinho o chuta (sem apertar E).
	cena.jogador.position = cena.sala.centro(Vector2i(3, 5))
	Input.action_press("mover_tras")
	await wait_physics_frames(40)
	Input.action_release("mover_tras")
	assert_gt(cena._casa_de(cena.objetos["banquinho"]).x, 4, "andar contra ele o chuta")
	await cena.arrumar_as_caixas()
	await wait_physics_frames(10)
	# Chutes deslizam até bater: caixa à direita, banquinho para cima, para a
	# direita (para na caixa) e para cima, até a frente da estante.
	await _empurrar("caixa", Vector2i(6, 2))
	assert_eq(cena._casa_de(cena.objetos["caixa"]), Vector2i(9, 2))
	await cena.arrumar_as_caixas()
	assert_eq(cena._casa_de(cena.objetos["caixa"]), Vector2i(7, 2), "Ophelia põe de volta")
	await _empurrar("caixa", Vector2i(6, 2))
	await _empurrar("banquinho", Vector2i(4, 6))
	assert_eq(cena._casa_de(cena.objetos["banquinho"]), Vector2i(4, 2), "para na prateleira")
	await _empurrar("banquinho", Vector2i(3, 2))
	assert_eq(cena._casa_de(cena.objetos["banquinho"]), Vector2i(8, 2), "para na caixa")
	await _empurrar("banquinho", Vector2i(8, 3))
	assert_eq(cena._casa_de(cena.objetos["banquinho"]), Vector2i(8, 1))
	butiques.procurar("estante_alta")
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


func test_butiques_althea_foge_para_a_vitrine() -> void:
	await _abrir("res://scenes/capitulo_01/cena_butiques.tscn", "rua")
	var butiques := cena as CenaButiques
	butiques.escolher_guarda(butiques.guardas[0])
	butiques.escolher_guarda(butiques.guardas[1])
	await _esperar_etapa("porta")
	var casa := cena._casa_de(cena.jogador)
	for i in CenaButiques.FUGAS_DE_ALTHEA[0]:
		casa += Vector2i(0, -1) if casa.y > 3 else Vector2i(1, 0)
		cena.jogador.position = cena.sala.centro(casa)
		await wait_physics_frames(3)
	assert_true(butiques.althea_fora, "Althea correu para uma vitrine")
	assert_false(butiques.seguidores.has(cena.objetos["althea"]))
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_BUSCAR_THEA")
	cena.entrar_na_loja()
	await wait_physics_frames(3)
	assert_eq(cena.etapa, "porta", "sem a Thea, a porta não abre")
	butiques.buscar_althea()
	assert_false(butiques.althea_fora)
	assert_eq(butiques.seguidores[0], cena.objetos["althea"], "ela volta para a frente da fila")
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_LOJA")


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
