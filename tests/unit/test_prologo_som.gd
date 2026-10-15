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
			assert_true(SomPrologo.CAMADAS.has(camada) or camada == SomPrologo.CORACAO, "%s em %s" % [camada, etapa])


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
	# camadas + passos, aterrissagem por chão + pulo + coração
	assert_eq(tocadores.size(), SomPrologo.CAMADAS.size() + 2 * SomPrologo.PASSOS.size() + 2)
	for tocador: AudioStreamPlayer in tocadores:
		assert_eq(tocador.bus, &"Efeitos", tocador.name)
	assert_true((som.get_node("Caos") as AudioStreamPlayer).stream.loop, "ambiente em laço")


func test_no_corredor_a_correria_e_o_coracao_crescem_perto_da_mae() -> void:
	var longe := SomPrologo.alvos_explorando(Vector3(-9, 1, 1.8))
	var perto := SomPrologo.alvos_explorando(Vector3(8, 1, 1.8))
	assert_gt(perto["correria"], longe["correria"])
	assert_gt(perto["coracao"], longe["coracao"])
	assert_gt(SomPrologo.bpm_explorando(Vector3(8, 1, 1.8)), SomPrologo.bpm_explorando(Vector3(-9, 1, 1.8)))


func test_coracao_ja_bate_baixinho_no_quarto() -> void:
	var cama := SomPrologo.alvos_explorando(Vector3(-11.2, 1, 8.6))
	var porta_do_quarto := SomPrologo.alvos_explorando(Vector3(-9, 1, 4.5))
	var corredor := SomPrologo.alvos_explorando(Vector3(0, 1, 1.8))
	assert_gt(cama["coracao"], 0.0, "o coração já bate no quarto")
	assert_lt(cama["coracao"], 0.2, "baixinho")
	assert_gt(porta_do_quarto["coracao"], cama["coracao"])
	assert_gt(corredor["coracao"], porta_do_quarto["coracao"])
	assert_lt(SomPrologo.bpm_explorando(Vector3(-11.2, 1, 8.6)), 95.0, "calmo na cama")


func test_batidas_variam_e_existem() -> void:
	assert_gte(SomPrologo.VARIACOES_DE_BATIDA, 4)
	for i in range(1, SomPrologo.VARIACOES_DE_BATIDA + 1):
		assert_not_null(load(SomPrologo.BATIDAS % i))


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
	assert_eq(som.volume(SomPrologo.CORACAO), 0.0, "nem o coração")


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


func test_toda_etapa_tem_musica_ou_silencio() -> void:
	for etapa: String in SomPrologo.ETAPAS:
		assert_true(SomPrologo.MUSICAS.has(etapa), "sem música definida para " + etapa)
	assert_true(SomPrologo.MUSICAS.has(""), "a abertura tem música")


func test_nos_aposentos_a_musica_so_volta_depois_do_silencio() -> void:
	for etapa in ["caos", "dossel", "muda", "nome", "olhares"]:
		assert_eq(SomPrologo.MUSICAS[etapa], "", etapa)
	# Retorno do Rafael (15/10/2026): depois do silêncio, a música volta com fade.
	assert_ne(SomPrologo.MUSICAS["choro"], "")
	assert_gte(SomPrologo.FADE_MUSICA["choro"], 4.0, "volta devagar")


func test_no_comeco_a_musica_vem_antes_dos_gritos() -> void:
	var cena := _cena_rapida()
	add_child_autofree(cena)
	var som: SomPrologo = cena.get_node("Som")
	await wait_seconds(1.0)
	assert_eq(som.volume("correria"), 0.0, "ainda só a música")
	assert_gt(SomPrologo.ESPERA_AMBIENTE, SomPrologo.FADE_MUSICA[""], "os gritos entram depois do fade da música")


func test_musicas_existem_e_as_de_fundo_repetem() -> void:
	for caminho: String in SomPrologo.MUSICAS.values():
		if caminho.is_empty():
			continue
		var musica: AudioStreamWAV = load(caminho)
		assert_not_null(musica, caminho)
		var laco := musica.loop_mode != AudioStreamWAV.LOOP_DISABLED
		assert_eq(laco, not caminho.ends_with("prologo_titulo.wav"), "%s: só o título toca uma vez" % caminho)


func test_coracao_sobe_em_rampa_continua_pelo_caminho() -> void:
	var anterior := -1.0
	for i in SomPrologo.CAMINHO.size() - 1:
		var a: Vector2 = SomPrologo.CAMINHO[i]
		var b: Vector2 = SomPrologo.CAMINHO[i + 1]
		for k in 10:
			var p := a.lerp(b, k / 10.0)
			var volume: float = SomPrologo.alvos_explorando(Vector3(p.x, 1, p.y))["coracao"]
			if anterior >= 0.0:
				assert_true(volume >= anterior - 0.001, "o coração não pode baixar indo para a duquesa")
				assert_lt(volume - anterior, 0.06, "sem saltos de volume")
			anterior = volume


func test_vozes_dos_empregados_ja_se_ouvem_no_quarto() -> void:
	var cama := SomPrologo.alvos_explorando(Vector3(-11.2, 1, 8.6))
	assert_gte(cama["correria"], 0.5)


func test_sem_respiracao_falsa() -> void:
	assert_false(SomPrologo.CAMADAS.has("respiracao"))
