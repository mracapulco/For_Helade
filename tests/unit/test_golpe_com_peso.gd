extends GutTest
## P2 da jogabilidade nova (Rafael, 23/10; planos/jogabilidade-isometrica.md):
## combo de três golpes, golpe guardado (buffer), arco largo, pausa de
## impacto, avanço, tremor e o terceiro golpe que interrompe o inimigo.

var sala: Node2D
var personagem: PersonagemExploracao
var guarda: Node2D


func before_each() -> void:
	Configuracoes.movimento_em_grade = false
	Inventario.limpar()
	GradeOcupacao.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	guarda = sala.get_node("GuardaTeste")
	for inimigo in [sala.get_node("Bandido"), sala.get_node("BandidoEscudo")]:
		inimigo.process_mode = Node.PROCESS_MODE_DISABLED
	Inventario.adicionar("espada_media")
	Inventario.equipar("nicholas", "espada_media")
	await wait_physics_frames(2)


func after_each() -> void:
	Engine.time_scale = 1.0
	Configuracoes.movimento_em_grade = false


func after_all() -> void:
	Inventario.limpar()


## Tempo, a partir do começo de um golpe, em que um golpe guardado emenda.
func _ponto_de_emenda() -> float:
	return personagem.momento_do_corte / personagem.ritmo() + personagem.tempo_ativo


## Espera o fim do golpe (a pausa de impacto deixa o tempo mais lento).
func _esperar_fim_do_golpe() -> void:
	await wait_until(func() -> bool: return not personagem.golpeando, 2.0)


func test_cliques_seguidos_fazem_o_combo_de_tres() -> void:
	assert_true(personagem.golpear())
	assert_eq(personagem.golpe_no_combo, 1)
	await wait_seconds(0.05)
	assert_true(personagem.golpear(), "no meio do golpe, fica guardado")
	await wait_until(func() -> bool: return personagem.golpe_no_combo == 2, 1.0)
	assert_true(personagem.golpeando, "o segundo emendou")
	await wait_seconds(0.05)
	personagem.golpear()
	await wait_until(func() -> bool: return personagem.golpe_no_combo == 3, 1.0)
	assert_eq(personagem.golpe_no_combo, 3)


func test_golpe_guardado_emenda_antes_do_fim_do_golpe() -> void:
	personagem.golpear()
	await wait_seconds(0.08)
	personagem.golpear()
	await wait_until(func() -> bool: return personagem.golpe_no_combo == 2, 1.0)
	assert_lt(_ponto_de_emenda(), personagem.duracao_do_golpe(), "emenda antes do fim do primeiro")


func test_clique_cedo_demais_se_perde() -> void:
	personagem.buffer_golpe = 0.05
	personagem.golpear()
	await wait_physics_frames(1)
	personagem.golpear()
	await _esperar_fim_do_golpe()
	await wait_physics_frames(2)
	assert_false(personagem.golpeando, "o pedido envelheceu antes de poder emendar")


func test_depois_do_terceiro_o_combo_recomeca() -> void:
	personagem.golpe_no_combo = 2
	personagem._desde_o_golpe = 0.0
	personagem.golpear()
	assert_eq(personagem.golpe_no_combo, 3)
	await wait_seconds(personagem.duracao_do_golpe() - 0.1)
	assert_eq(personagem.golpe_no_combo, 3, "o terceiro não emenda: vai até o fim")
	personagem.golpear()
	await wait_until(func() -> bool: return personagem.golpe_no_combo == 1, 1.0)
	assert_eq(personagem.golpe_no_combo, 1, "depois dele, começa outro combo")
	assert_true(personagem.golpeando)


func test_parado_um_tempo_o_combo_zera() -> void:
	personagem.golpear()
	await _esperar_fim_do_golpe()
	await wait_seconds(personagem.janela_combo + 0.1)
	assert_eq(personagem.golpe_no_combo, 0)
	personagem.golpear()
	assert_eq(personagem.golpe_no_combo, 1)


func test_arco_de_110_graus() -> void:
	var olhar := Vector2.RIGHT
	var a_50_graus := Vector2.RIGHT.rotated(deg_to_rad(50)) * 30.0
	var a_60_graus := Vector2.RIGHT.rotated(deg_to_rad(60)) * 30.0
	assert_true(PersonagemExploracao.pega_no_golpe(Vector2.ZERO, olhar, a_50_graus, 40.0, 110.0))
	assert_false(PersonagemExploracao.pega_no_golpe(Vector2.ZERO, olhar, a_60_graus, 40.0, 110.0))


func test_alcance_tem_folga() -> void:
	var alcance := personagem.alcance_do_golpe()
	personagem.global_position = guarda.global_position - Vector2(alcance * 1.1, 0)
	personagem.direcao_olhar = Vector2.RIGHT
	assert_has(personagem.alvos_do_golpe(), guarda.get_node("ReacaoAoGolpe"), "um pouco além do alcance ainda pega")


func test_acertar_da_uma_pausa_de_impacto() -> void:
	personagem.global_position = guarda.global_position - Vector2(24, 12)
	personagem.direcao_olhar = Vector2(2, 1).normalized()
	personagem.golpear()
	await wait_until(func() -> bool: return Engine.time_scale < 1.0, 1.0)
	assert_true(personagem.em_pausa_de_impacto(), "acertou: o jogo para um instante")
	await wait_until(func() -> bool: return Engine.time_scale == 1.0, 1.0)
	assert_eq(Engine.time_scale, 1.0, "e volta")


func test_errar_nao_pausa() -> void:
	personagem.direcao_olhar = Vector2.UP
	personagem.golpear()
	await wait_seconds(personagem.momento_do_corte + 0.05)
	assert_eq(Engine.time_scale, 1.0)


func test_golpe_avanca_um_pouco() -> void:
	personagem.direcao_olhar = Vector2.LEFT
	var antes := personagem.global_position
	personagem.golpear()
	await _esperar_fim_do_golpe()
	var andou := personagem.global_position - antes
	assert_lt(andou.x, -personagem.avanco_golpe * 0.6, "avançou para onde olha")
	assert_lt(andou.length(), personagem.avanco_golpe * 1.5, "só um pouco")


func test_no_andar_em_casas_o_golpe_nao_avanca() -> void:
	Configuracoes.movimento_em_grade = true
	await wait_physics_frames(2)
	var antes := personagem.global_position
	personagem.golpear()
	await _esperar_fim_do_golpe()
	assert_eq(personagem.global_position, antes, "fica no centro da casa")


func test_terceiro_golpe_empurra_mais_e_treme_a_tela() -> void:
	var camera: CameraExploracao = sala.get_node("Personagem/Camera")
	var desenho: Node2D = guarda.get_node("Visual")
	var parado_em := desenho.position
	personagem.global_position = guarda.global_position - Vector2(24, 12)
	personagem.direcao_olhar = Vector2(2, 1).normalized()
	personagem.golpe_no_combo = 2
	personagem._desde_o_golpe = 0.0
	personagem.golpear()
	assert_eq(personagem.golpe_no_combo, 3)
	await wait_until(func() -> bool: return camera.tremendo(), 1.0)
	assert_true(camera.tremendo(), "o terceiro treme a tela")
	await wait_until(func() -> bool: return desenho.position.distance_to(parado_em) > 6.0, 1.0)
	assert_gt(desenho.position.distance_to(parado_em), 6.0, "empurrou mais que o recuo normal (4 px)")


func test_terceiro_golpe_interrompe_o_aviso_do_inimigo() -> void:
	var bandido: Inimigo = sala.get_node("Bandido")
	bandido.process_mode = Node.PROCESS_MODE_INHERIT
	bandido.preparo = 5.0
	personagem.global_position = bandido.global_position - Vector2(24, 12)
	personagem.direcao_olhar = Vector2(2, 1).normalized()
	bandido.alvo = personagem
	bandido.estado = Inimigo.Estado.PREPARANDO
	personagem.golpe_no_combo = 2
	personagem._desde_o_golpe = 0.0
	personagem.golpear()
	await wait_until(func() -> bool: return bandido.estado != Inimigo.Estado.PREPARANDO, 1.0)
	assert_eq(bandido.estado, Inimigo.Estado.DESCANSANDO, "perdeu o golpe")


func test_primeiro_golpe_nao_interrompe() -> void:
	var bandido: Inimigo = sala.get_node("Bandido")
	bandido.estado = Inimigo.Estado.PREPARANDO
	personagem.global_position = bandido.global_position - Vector2(24, 12)
	personagem.direcao_olhar = Vector2(2, 1).normalized()
	personagem.golpear()
	await wait_seconds(personagem.momento_do_corte + 0.1)
	assert_eq(bandido.estado, Inimigo.Estado.PREPARANDO)
