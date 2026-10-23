extends GutTest
## P3 da jogabilidade nova (Rafael, 23/10; planos/jogabilidade-isometrica.md):
## esquiva no Espaço e inimigo que avisa no chão; o dano só existe no
## instante do golpe, na área avisada; um inimigo avisa por vez.

var sala: Node2D
var personagem: PersonagemExploracao
var bandido: Inimigo
var bandido_escudo: Inimigo


func before_each() -> void:
	Configuracoes.movimento_em_grade = false
	Inventario.limpar()
	Experiencia.limpar()
	GradeOcupacao.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	bandido = sala.get_node("Bandido")
	bandido_escudo = sala.get_node("BandidoEscudo")
	bandido.process_mode = Node.PROCESS_MODE_DISABLED
	bandido_escudo.process_mode = Node.PROCESS_MODE_DISABLED
	await wait_physics_frames(2)


func after_each() -> void:
	Engine.time_scale = 1.0
	Configuracoes.movimento_em_grade = false
	for acao in ["mover_frente", "mover_tras", "mover_esquerda", "mover_direita"]:
		Input.action_release(acao)


func after_all() -> void:
	Inventario.limpar()


func _apertar_espaco() -> void:
	var tecla := InputEventAction.new()
	tecla.action = "esquivar"
	tecla.pressed = true
	Input.parse_input_event(tecla)
	await wait_process_frames(1)
	tecla = tecla.duplicate()
	tecla.pressed = false
	Input.parse_input_event(tecla)


func test_em_combate_espaco_esquiva() -> void:
	assert_true(InputMap.has_action("esquivar"))
	assert_eq((InputMap.action_get_events("esquivar")[0] as InputEventKey).physical_keycode, KEY_SPACE)
	bandido.global_position = personagem.global_position + Vector2(60, 0)
	assert_true(personagem.em_combate())
	await _apertar_espaco()
	assert_true(personagem.esquivando)
	assert_false(personagem.pulando, "em combate, Espaço não pula")


func test_fora_de_combate_espaco_pula() -> void:
	# Rafael, 23/10: a esquiva é só para confrontos; fora deles, Espaço pula.
	for inimigo in [bandido, bandido_escudo]:
		inimigo.global_position = personagem.global_position + Vector2(2000, 0)
	assert_false(personagem.em_combate())
	await _apertar_espaco()
	assert_true(personagem.pulando)
	assert_false(personagem.esquivando)


func test_no_andar_em_casas_espaco_pula() -> void:
	Configuracoes.movimento_em_grade = true
	await _apertar_espaco()
	assert_true(personagem.pulando)
	assert_false(personagem.esquivando)


func test_esquiva_leva_para_as_teclas() -> void:
	var antes := personagem.global_position
	Input.action_press("mover_direita")
	personagem.esquivar()
	Input.action_release("mover_direita")
	await wait_seconds(personagem.duracao_esquiva + 0.05)
	var andou := personagem.global_position - antes
	assert_almost_eq(andou.x, personagem.distancia_esquiva, 12.0, "cerca de 56 px para a direita")
	assert_almost_eq(andou.y, 0.0, 1.0)


func test_sem_tecla_esquiva_para_onde_olha() -> void:
	personagem.direcao_olhar = Vector2.LEFT
	var antes := personagem.global_position
	personagem.esquivar()
	await wait_seconds(personagem.duracao_esquiva + 0.05)
	assert_lt(personagem.global_position.x, antes.x - 30.0)


func test_invulneravel_so_no_comeco() -> void:
	personagem.esquivar()
	assert_true(personagem.invulneravel())
	await wait_seconds(personagem.tempo_invulneravel + 0.03)
	assert_false(personagem.invulneravel(), "o fim da esquiva já pode levar golpe")


func test_duas_cargas_que_voltam() -> void:
	assert_true(personagem.esquivar())
	await wait_until(func() -> bool: return not personagem.esquivando, 1.0)
	assert_true(personagem.esquivar(), "segunda carga")
	await wait_until(func() -> bool: return not personagem.esquivando, 1.0)
	assert_false(personagem.esquivar(), "sem carga")
	await wait_seconds(personagem.recarga_esquiva + 0.05)
	assert_true(personagem.esquivar(), "uma carga voltou")


func test_esquiva_corta_o_golpe() -> void:
	Inventario.adicionar("espada_media")
	Inventario.equipar("nicholas", "espada_media")
	personagem.golpear()
	assert_true(personagem.golpeando)
	personagem.esquivar()
	assert_false(personagem.golpeando)
	assert_true(personagem.esquivando)


func test_leque_do_golpe_no_chao() -> void:
	var direita := Vector2.RIGHT
	assert_true(AvisoNoChao.atinge(Vector2.ZERO, direita, Vector2(50, 0), 72.0, 120.0))
	assert_false(AvisoNoChao.atinge(Vector2.ZERO, direita, Vector2(-50, 0), 72.0, 120.0), "atrás não pega")
	assert_false(AvisoNoChao.atinge(Vector2.ZERO, direita, Vector2(90, 0), 72.0, 120.0), "longe não pega")
	assert_false(AvisoNoChao.atinge(Vector2.ZERO, direita, Vector2(20, 40), 72.0, 120.0),
		"40 px abaixo na tela são 80 px no chão: fora")


func _bandido_prepara() -> void:
	bandido.process_mode = Node.PROCESS_MODE_INHERIT
	var casa := bandido.casa_de(bandido.global_position)
	personagem.global_position = bandido.centro_da_casa(casa + Vector2i(-1, 0))
	await wait_until(func() -> bool: return bandido.estado == Inimigo.Estado.PREPARANDO, 2.0)


func test_aviso_aparece_no_chao_e_enche() -> void:
	await _bandido_prepara()
	assert_eq(bandido.estado, Inimigo.Estado.PREPARANDO)
	var aviso := bandido.aviso_no_chao
	assert_not_null(aviso, "o aviso está no chão")
	assert_almost_eq(bandido.preparo, 0.6, 0.001)
	var antes := aviso.progresso
	await wait_seconds(0.2)
	assert_gt(aviso.progresso, antes, "enche até o golpe")


func test_golpe_pega_quem_ficou_na_area() -> void:
	var vida: Vida = sala.get_node("Personagem/Vida")
	var cheia := vida.atual
	await _bandido_prepara()
	await wait_until(func() -> bool: return bandido.estado == Inimigo.Estado.DESCANSANDO, 2.0)
	assert_lt(vida.atual, cheia, "ficou parado na área: levou o golpe")
	assert_null(bandido.aviso_no_chao, "o aviso some no golpe")


func test_sair_da_area_escapa_do_golpe() -> void:
	var vida: Vida = sala.get_node("Personagem/Vida")
	var cheia := vida.atual
	await _bandido_prepara()
	# Sai para trás, para longe do leque, antes de o aviso encher.
	var para_longe := personagem.global_position + (personagem.global_position - bandido.global_position).normalized() * 70.0
	personagem.global_position = para_longe
	await wait_until(func() -> bool: return bandido.estado != Inimigo.Estado.PREPARANDO, 2.0)
	assert_eq(vida.atual, cheia, "fora da área avisada, o golpe não pega")


func test_esquivar_no_golpe_escapa() -> void:
	var vida: Vida = sala.get_node("Personagem/Vida")
	var cheia := vida.atual
	await _bandido_prepara()
	await wait_until(func() -> bool: return bandido.aviso_no_chao.progresso > 0.85, 2.0)
	personagem.direcao_olhar = Vector2.ZERO
	personagem._rumo_esquiva = Vector2.ZERO
	# Esquiva sem sair do lugar: só a invulnerabilidade.
	personagem.distancia_esquiva = 0.0
	personagem.esquivar()
	await wait_until(func() -> bool: return bandido.estado != Inimigo.Estado.PREPARANDO, 1.0)
	assert_eq(vida.atual, cheia, "invulnerável no começo da esquiva")


func test_um_inimigo_avisa_por_vez() -> void:
	await _bandido_prepara()
	bandido_escudo.process_mode = Node.PROCESS_MODE_INHERIT
	bandido_escudo.alvo = personagem
	bandido_escudo.estado = Inimigo.Estado.PERSEGUINDO
	assert_true(bandido_escudo.outro_atacando())
	for i in 10:
		await wait_physics_frames(1)
		if bandido.estado == Inimigo.Estado.PREPARANDO:
			assert_ne(bandido_escudo.estado, Inimigo.Estado.PREPARANDO, "espera a vez")
