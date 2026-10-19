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
	assert_eq(cena.sala.largura, 11)
	assert_eq(cena.sala.profundidade, 10)
	assert_eq(cena.sala.piso, "patio")
	cena.olhar_guardas()
	await wait_physics_frames(2)
	assert_eq(cena.etapa, "patio", "só os guardas não bastam: falta a fonte")
	cena.ver_fonte()
	await _esperar_etapa("embarque")
	assert_true(Codice.tem("poucos_guardas"))
	assert_true(Codice.tem("olhos_de_ophelia"))
	cena.embarcar()
	await _esperar_etapa("ultimo_olhar")
	cena.olhar_anexo()
	await _esperar_etapa("visao_carruagem")
	assert_true(Codice.tem("anexo_vazio"))
	await _esperar_pedido()
	assert_eq(cena.cena_pedida, SequenciaCenas01.CENAS["visao_carruagem"])


func test_palacio_fora_de_ordem_nao_avanca() -> void:
	await _abrir("res://scenes/capitulo_01/cena_palacio.tscn", "patio")
	cena.embarcar()
	cena.olhar_anexo()
	assert_eq(cena.etapa, "patio")


func test_butiques_da_rua_a_loja_e_ao_restaurante() -> void:
	await _abrir("res://scenes/capitulo_01/cena_butiques.tscn", "rua")
	assert_eq(cena.sala.largura, 14)
	cena.entrar_na_loja()
	assert_eq(cena.etapa, "rua", "a porta só abre depois de escolher os guardas")
	cena.escolher_guardas()
	await _esperar_etapa("porta")
	assert_true(Codice.tem("rua_das_butiques"))
	cena.entrar_na_loja()
	await _esperar_etapa("escolher_presente")
	assert_eq(cena.sala.largura, 8)
	assert_true(cena.objetos.has("lojista_homem"))
	cena.escolher_presente()
	await _esperar_pedido()
	assert_eq(cena.etapa, "restaurante")
	assert_eq(cena.cena_pedida, SequenciaCenas01.CENAS["restaurante"])
	assert_eq(Relacoes.valor("ophelia"), 1)


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
	await _esperar_pedido()
	assert_eq(cena.etapa, "butiques")
	assert_eq(cena.cena_pedida, SequenciaCenas01.CENAS["butiques"])
