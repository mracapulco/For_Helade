extends GutTest
## Capítulo 01, passo 1: a manhã do aniversário, do sonho à mesa de chá.

const CENA := "res://scenes/capitulo_01/capitulo_01.tscn"

var capitulo: Capitulo01


func before_each() -> void:
	capitulo = load(CENA).instantiate()
	capitulo.escala_tempo = 0.0
	capitulo.mostrar_dialogos = false
	capitulo.trocar_de_cena = false
	add_child_autofree(capitulo)
	await _esperar_etapa("sonho")


func _esperar_etapa(nome: String) -> void:
	for i in 60:
		if capitulo.etapa == nome:
			return
		await wait_physics_frames(1)
	fail_test("não chegou na etapa %s (está em %s)" % [nome, capitulo.etapa])


func _vestir() -> void:
	_interagir("espelho")
	for i in 60:
		if capitulo.vestido and not capitulo.jogador.em_dialogo:
			return
		await wait_physics_frames(1)
	fail_test("não terminou de se vestir")


func _interagir(nome: String) -> void:
	var area: Interagivel = capitulo.objetos[nome].get_node("Interagivel")
	area.interagir()


func test_comeca_no_sonho_com_a_garota_e_nicholas_de_11_anos() -> void:
	assert_eq(capitulo.etapa, "sonho")
	assert_true(capitulo.objetos.has("garota"))
	var visual: AnimatedSprite2D = capitulo.jogador.get_node("Corpo/Visual")
	assert_string_contains(visual.sprite_frames.resource_path, "nicholas_11")
	assert_eq(capitulo.jogador.grade, capitulo.sala.chao)


func test_a_manha_inteira_na_ordem() -> void:
	_interagir("porta_sonho")
	await _esperar_etapa("quarto")
	assert_false(capitulo.jogador.em_dialogo, "no quarto ele anda de novo")
	_interagir("porta_quarto")
	assert_eq(capitulo.etapa, "quarto", "de pijama a porta não abre")
	await _vestir()
	assert_true(capitulo.viu_espelho)
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")
	_interagir("porta_althea")
	await _esperar_etapa("quarto_althea")
	capitulo.sentar_a_mesa()
	assert_eq(capitulo.etapa, "quarto_althea", "a mesa só depois de acordar Althea")
	_interagir("cama_althea")
	await _esperar_etapa("a_mesa")
	assert_true(capitulo.objetos.has("althea"), "Althea de pé depois de acordar")
	assert_false(capitulo.objetos["embrulho"].visible)
	var na_mesa: Vector2i = capitulo.sala.chao.local_to_map(capitulo.objetos["althea"].position)
	assert_eq(na_mesa, Vector2i(3, 4), "Althea espera à mesa de chá")
	_interagir("althea")
	await _esperar_etapa("fim")
	for i in 10:
		if capitulo.cena_pedida != "":
			break
		await wait_physics_frames(1)
	assert_eq(capitulo.cena_pedida, "res://scenes/main/main.tscn")


func test_fora_de_ordem_nao_avanca() -> void:
	capitulo.olhar_espelho()
	capitulo.sair_do_quarto()
	capitulo.esperar_cortejo()
	capitulo.acordar_althea()
	capitulo.sentar_a_mesa()
	assert_eq(capitulo.etapa, "sonho")


func test_corredor_tem_oito_passos_entre_as_portas() -> void:
	_interagir("porta_sonho")
	await _esperar_etapa("quarto")
	await _vestir()
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")
	var de_nicholas: Vector2 = capitulo.objetos["porta_nicholas"].position
	var de_althea: Vector2 = capitulo.objetos["porta_althea"].position
	var casas := capitulo.sala.chao.local_to_map(de_nicholas) - capitulo.sala.chao.local_to_map(de_althea)
	assert_eq(casas, Vector2i(8, 0))


func test_falas_estao_no_elenco() -> void:
	var roteiro: DialogueResource = load("res://data/dialogos/capitulo_01/manha.dialogue")
	for marcador in ["cortejo", "acordar_althea", "espada", "duque", "planos", "carruagem"]:
		var linha: DialogueLine = await roteiro.get_next_dialogue_line(marcador)
		while linha:
			if linha.character != "":
				assert_not_null(Elenco.buscar(linha.character), linha.character)
			linha = await roteiro.get_next_dialogue_line(linha.next_id)


func test_mansao_tem_a_identidade_do_castelo_do_prologo() -> void:
	assert_true(capitulo.sala.parede_lisa, "o corredor do sonho não é da Casa Olympia")
	_interagir("porta_sonho")
	await _esperar_etapa("quarto")
	assert_false(capitulo.sala.parede_lisa)
	assert_not_null(capitulo.sala.get_node_or_null("QuadroOlympiaDir"))
	assert_not_null(capitulo.sala.get_node_or_null("Armario"))
	assert_not_null(capitulo.sala.get_node_or_null("Bau"))
	await _vestir()
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")
	assert_eq(capitulo.sala.piso, "passadeira")
	assert_eq(capitulo.sala.chao.get_cell_atlas_coords(Vector2i(3, 1)).x, SalaMontada.PASSADEIRA_CIMA)
	assert_not_null(capitulo.sala.get_node_or_null("EspadaPlacaEsq"))
	assert_not_null(capitulo.sala.get_node_or_null("TochaEsq2"))


func test_acorda_de_pijama_e_se_veste_no_espelho() -> void:
	var visual: AnimatedSprite2D = capitulo.jogador.get_node("Corpo/Visual")
	assert_string_contains(visual.sprite_frames.resource_path, "pijama")
	_interagir("porta_sonho")
	await _esperar_etapa("quarto")
	await _vestir()
	assert_string_contains(visual.sprite_frames.resource_path, "nicholas_11_exploracao")


func test_nicholas_anda_mais_devagar() -> void:
	assert_lt(capitulo.jogador.velocidade, 90.0)


func test_corredor_comprido_com_outras_portas() -> void:
	_interagir("porta_sonho")
	await _esperar_etapa("quarto")
	await _vestir()
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")
	assert_gte(capitulo.sala.largura, 24)
	var fechadas := capitulo.objetos.keys().filter(func(k: String) -> bool: return k.begins_with("porta_fechada"))
	assert_gte(fechadas.size(), 2)


func test_o_duque_entra_e_depois_a_carruagem() -> void:
	_interagir("porta_sonho")
	await _esperar_etapa("quarto")
	await _vestir()
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")
	_interagir("porta_althea")
	await _esperar_etapa("quarto_althea")
	_interagir("cama_althea")
	await _esperar_etapa("a_mesa")
	_interagir("althea")
	await _esperar_etapa("duque")
	await _esperar_etapa("carruagem")
	assert_false(capitulo.objetos.has("apollon"), "o duque já partiu")
	assert_true(capitulo.sala.parede_madeira, "por dentro da carruagem")
	assert_true(capitulo.jogador.em_dialogo, "Nicholas fica sentado")
	await _esperar_etapa("fim")
