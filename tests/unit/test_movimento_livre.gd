extends GutTest
## P1 da jogabilidade nova (Rafael, 23/10; planos/jogabilidade-isometrica.md):
## movimento livre pela tela, com aceleração e freio, a opção F3 de voltar ao
## andar em casas, o adiantamento da câmera e as paredes translúcidas.

const ACOES := ["mover_frente", "mover_tras", "mover_esquerda", "mover_direita", "correr"]

var sala: Node2D
var personagem: PersonagemExploracao
var _arquivo_original := ""


func before_each() -> void:
	Configuracoes.movimento_em_grade = false
	Inventario.limpar()
	GradeOcupacao.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	# Os bandidos ficam parados para não atrapalhar.
	for inimigo in [sala.get_node("Bandido"), sala.get_node("BandidoEscudo")]:
		inimigo.process_mode = Node.PROCESS_MODE_DISABLED
	await wait_physics_frames(3)


func after_each() -> void:
	for acao in ACOES:
		Input.action_release(acao)
	Configuracoes.movimento_em_grade = false
	if _arquivo_original != "":
		Configuracoes.arquivo = _arquivo_original
		_arquivo_original = ""


func after_all() -> void:
	Inventario.limpar()


func _apertar(acoes: Array, quadros: int) -> Vector2:
	var inicio := personagem.global_position
	for acao in acoes:
		Input.action_press(acao)
	await wait_physics_frames(quadros)
	return personagem.global_position - inicio


func test_comeca_no_andar_livre() -> void:
	assert_false(Configuracoes.movimento_em_grade, "o padrão desde 23/10 é andar livre")
	assert_false(personagem.anda_em_casas())


func test_w_sobe_reto_na_tela() -> void:
	var andou: Vector2 = await _apertar(["mover_frente"], 20)
	assert_lt(andou.y, -10.0, "subiu")
	assert_almost_eq(andou.x, 0.0, 0.5, "sem ir para os lados")


func test_d_vai_reto_para_a_direita() -> void:
	var andou: Vector2 = await _apertar(["mover_direita"], 20)
	assert_gt(andou.x, 10.0)
	assert_almost_eq(andou.y, 0.0, 0.5)


func test_subir_vale_o_fator_vertical_da_velocidade() -> void:
	await _apertar(["mover_frente"], 20)
	assert_almost_eq(personagem.velocity.length(), personagem.velocidade_andando() * personagem.fator_vertical, 1.0)
	Input.action_release("mover_frente")
	await wait_physics_frames(15)
	await _apertar(["mover_direita"], 20)
	assert_almost_eq(personagem.velocity.length(), personagem.velocidade_andando(), 1.0)


func test_duas_teclas_nao_correm_mais_que_uma() -> void:
	await _apertar(["mover_direita", "mover_tras"], 20)
	assert_lt(personagem.velocity.length(), personagem.velocidade_andando() + 0.5)
	assert_gt(personagem.velocity.x, 0.0)
	assert_gt(personagem.velocity.y, 0.0, "a diagonal da tela, para baixo e para a direita")


func test_acelera_rapido_mas_nao_na_hora() -> void:
	await _apertar(["mover_direita"], 1)
	var no_primeiro_quadro := personagem.velocity.length()
	assert_gt(no_primeiro_quadro, 0.0, "responde no primeiro quadro")
	assert_lt(no_primeiro_quadro, personagem.velocidade_andando(), "ainda acelerando")
	await wait_seconds(personagem.tempo_acelerar + 0.05)
	assert_almost_eq(personagem.velocity.length(), personagem.velocidade_andando(), 1.0, "velocidade toda")


func test_freia_rapido_ao_soltar() -> void:
	await _apertar(["mover_direita"], 20)
	Input.action_release("mover_direita")
	await wait_physics_frames(1)
	assert_gt(personagem.velocity.length(), 0.0, "não para seco")
	await wait_seconds(personagem.tempo_frear + 0.05)
	assert_eq(personagem.velocity, Vector2.ZERO, "parou")


func test_olha_para_onde_anda() -> void:
	await _apertar(["mover_esquerda"], 10)
	assert_almost_eq(personagem.direcao_olhar, Vector2.LEFT, Vector2(0.001, 0.001))


func test_nao_para_no_centro_da_casa() -> void:
	await _apertar(["mover_direita"], 7)
	Input.action_release("mover_direita")
	await wait_seconds(0.3)
	var casa := personagem.casa_de(personagem.global_position)
	assert_ne(personagem.global_position, personagem.centro_da_casa(casa), "livre, para onde soltou")


func test_ainda_ocupa_a_casa_onde_esta() -> void:
	await _apertar(["mover_direita"], 20)
	Input.action_release("mover_direita")
	await wait_seconds(0.2)
	var casa := personagem.casa_de(personagem.global_position)
	assert_eq(GradeOcupacao.ocupante(casa), personagem, "para os inimigos, que andam em casas, não entrarem nele")


func test_correr_subindo_mostra_a_animacao_de_correr() -> void:
	assert_almost_eq(personagem.fator_da_direcao(Vector2.RIGHT), 1.0, 0.001)
	assert_almost_eq(personagem.fator_da_direcao(Vector2.UP * 50.0), personagem.fator_vertical, 0.001)
	Input.action_press("correr")
	await _apertar(["mover_frente"], 30)
	var visual := sala.get_node("Personagem/Corpo/Visual") as AnimatedSprite2D
	await wait_process_frames(2)
	assert_true(String(visual.animation).begins_with("correndo"), "subindo devagar na tela, mas correndo")


func test_f3_troca_para_o_andar_em_casas_e_volta() -> void:
	_arquivo_original = Configuracoes.arquivo
	Configuracoes.arquivo = "user://teste_movimento_livre.cfg"
	var tecla := InputEventAction.new()
	tecla.action = "alternar_movimento"
	tecla.pressed = true
	Input.parse_input_event(tecla)
	await wait_process_frames(2)
	assert_true(Configuracoes.movimento_em_grade, "F3: andar em casas")
	assert_true(personagem.anda_em_casas())
	assert_not_null(personagem.get_node_or_null("AvisoMovimento"), "avisa acima da cabeça")
	Input.parse_input_event(tecla)
	await wait_process_frames(2)
	assert_false(Configuracoes.movimento_em_grade, "F3 de novo: andar livre")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://teste_movimento_livre.cfg"))


func test_f3_e_so_dessa_acao() -> void:
	assert_true(InputMap.has_action("alternar_movimento"))
	var eventos := InputMap.action_get_events("alternar_movimento")
	assert_eq(eventos.size(), 1)
	assert_eq((eventos[0] as InputEventKey).physical_keycode, KEY_F3)


func test_camera_se_adianta_para_onde_ele_anda() -> void:
	var camera: CameraExploracao = sala.get_node("Personagem/Camera")
	assert_eq(camera.adiantamento_para(Vector2.ZERO), Vector2.ZERO, "parado, centrada")
	var para_direita := camera.adiantamento_para(Vector2(120, 0))
	assert_almost_eq(para_direita, Vector2(camera.adiantamento, 0), Vector2(0.01, 0.01))
	var para_cima := camera.adiantamento_para(Vector2(0, -80))
	assert_almost_eq(para_cima.y, -camera.adiantamento * camera.adiantamento_vertical, 0.01, "na vertical, menos")
	await _apertar(["mover_direita"], 40)
	await wait_process_frames(2)
	assert_gt(camera.offset.x, 5.0, "andando para a direita, a câmera mostra mais da direita")
	Input.action_release("mover_direita")
	await wait_seconds(2.0)
	assert_lt(camera.offset.length(), 2.0, "parado, volta ao centro")


func test_bloco_na_frente_fica_translucido() -> void:
	var paredes: ParedesTranslucidas = sala.get_node("Obstaculos")
	var bloco := paredes.get_used_cells()[0]
	var centro := paredes.to_global(paredes.map_to_local(bloco))
	assert_has(paredes.casas_que_cobrem(centro + Vector2(0, -20)), bloco, "atrás do bloco: ele cobre o desenho")
	assert_does_not_have(paredes.casas_que_cobrem(centro + Vector2(0, 20)), bloco, "na frente: ele é que cobre o bloco")
	assert_does_not_have(paredes.casas_que_cobrem(centro + Vector2(200, -20)), bloco, "longe: nada")


func test_paredes_mudam_quando_ele_passa_atras() -> void:
	var paredes: ParedesTranslucidas = sala.get_node("Obstaculos")
	var bloco := paredes.get_used_cells()[0]
	var centro := paredes.to_global(paredes.map_to_local(bloco))
	personagem.global_position = centro + Vector2(0, -20)
	await wait_process_frames(2)
	assert_true(paredes.translucida(bloco))
	personagem.global_position = centro + Vector2(0, 60)
	await wait_process_frames(2)
	assert_false(paredes.translucida(bloco))
