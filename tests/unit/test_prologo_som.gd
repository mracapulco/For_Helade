extends GutTest
## Sons do prólogo: cada etapa tem o seu ambiente, a muda é silêncio total e
## tudo toca no barramento Efeitos (que respeita o volume das Opções).

const CENA := preload("res://scenes/prologo/prologo.tscn")


func test_toda_etapa_da_sequencia_tem_sons() -> void:
	var fonte := FileAccess.get_file_as_string("res://scripts/prologo/sequencia_prologo.gd")
	var etapas := RegEx.create_from_string("_mudar\\(\"([a-z_]+)\"\\)").search_all(fonte)
	assert_gt(etapas.size(), 5)
	for achado: RegExMatch in etapas:
		assert_true(SomPrologo.ETAPAS.has(achado.get_string(1)), "sem sons para a etapa " + achado.get_string(1))


func test_camadas_das_etapas_existem() -> void:
	for etapa: String in SomPrologo.ETAPAS:
		for camada: String in SomPrologo.ETAPAS[etapa]:
			assert_true(SomPrologo.CAMADAS.has(camada), "%s em %s" % [camada, etapa])


func test_quando_althea_nasce_muda_tudo_fica_em_silencio() -> void:
	assert_true(SomPrologo.ETAPAS["muda"].is_empty())
	assert_true(SomPrologo.ETAPAS["nome"].is_empty())


func test_todos_os_sons_carregam_e_os_ambientes_repetem() -> void:
	for caminho: String in SomPrologo.CAMADAS.values():
		var som: AudioStream = load(caminho)
		assert_not_null(som, caminho)
	for modelo: String in SomPrologo.PASSOS.values():
		for i in range(1, SomPrologo.VARIACOES_DE_PASSO + 1):
			assert_not_null(load(modelo % i), modelo % i)
	assert_not_null(load(SomPrologo.PULO))
	for chao in ["madeira", "pedra"]:
		assert_not_null(load(SomPrologo.ATERRISSAGEM % chao))


func test_tudo_toca_no_barramento_efeitos() -> void:
	var cena: Node = add_child_autofree(_cena_rapida())
	await wait_process_frames(2)
	var som: SomPrologo = cena.get_node("Som")
	var tocadores := som.find_children("*", "AudioStreamPlayer", false, false)
	# camadas + passos, aterrissagem por chão + pulo
	assert_eq(tocadores.size(), SomPrologo.CAMADAS.size() + 2 * SomPrologo.PASSOS.size() + 1)
	for tocador: AudioStreamPlayer in tocadores:
		assert_eq(tocador.bus, &"Efeitos", tocador.name)
	assert_true((som.get_node("Caos") as AudioStreamPlayer).stream.loop, "ambiente em laço")


func test_no_corredor_a_correria_e_o_coracao_crescem_perto_da_mae() -> void:
	var longe := SomPrologo.alvos_explorando(Vector3(-9, 1, 1.8))
	var perto := SomPrologo.alvos_explorando(Vector3(8, 1, 1.8))
	assert_gt(perto["correria"], longe["correria"])
	assert_gt(perto["coracao"], longe["coracao"])
	assert_gt(SomPrologo.ritmo_explorando(Vector3(8, 1, 1.8)), SomPrologo.ritmo_explorando(Vector3(-9, 1, 1.8)))
	assert_false(SomPrologo.alvos_explorando(Vector3(-11, 1, 8.6)).has("coracao"), "no quarto o coração ainda está calmo")


func test_pes_descalcos_soam_diferente_na_pedra_e_no_assoalho() -> void:
	assert_eq(SomPrologo.chao_em(Vector3(-11, 0, 8.6)), "madeira")
	assert_eq(SomPrologo.chao_em(Vector3(0, 0, 1.8)), "pedra")
	assert_eq(SomPrologo.chao_em(Vector3(9, 0, 14.6)), "pedra")


func test_volume_desliza_ate_o_silencio_da_muda() -> void:
	var cena: Node = add_child_autofree(_cena_rapida())
	await wait_process_frames(2)
	var som: SomPrologo = cena.get_node("Som")
	som.etapa = "caos"
	await wait_seconds(1.3)
	assert_gt(som.volume("caos"), 0.5)
	som.etapa = "muda"
	await wait_seconds(0.4)
	for camada: String in SomPrologo.CAMADAS:
		assert_eq(som.volume(camada), 0.0, camada)


func test_pulo_tem_som() -> void:
	var cena: ControlePrimeiraPessoa = add_child_autofree(_cena_rapida())
	await wait_physics_frames(10)
	var pulo: AudioStreamPlayer = cena.get_node("Som/Pulo")
	Input.action_press("pular")
	await wait_physics_frames(1)
	Input.action_release("pular")
	await wait_process_frames(3)
	assert_true(pulo.playing, "o impulso do pulo faz barulho")


func test_passos_de_crianca_sem_pressa() -> void:
	assert_gte(SomPrologo.PASSO, 0.6, "passos curtos demais soam apressados")
	assert_gte(SomPrologo.VARIACOES_DE_PASSO, 6, "poucos sons de passo soam repetidos")


func _cena_rapida() -> Node:
	var cena: ControlePrimeiraPessoa = CENA.instantiate()
	cena.abertura = null
	cena.roteiro = null
	return cena
