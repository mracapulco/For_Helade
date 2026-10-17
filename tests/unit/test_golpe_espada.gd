extends GutTest
## Golpe de espada: clique esquerdo (ou botão Golpe) com uma arma equipada.

var sala: Node2D
var personagem: PersonagemExploracao
var visual: AnimacaoPersonagem
var na_mao: ItemNaMao


func before_each() -> void:
	Inventario.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	visual = sala.get_node("Personagem/Corpo/Visual")
	na_mao = sala.get_node("Personagem/Corpo/Visual/ItemNaMao")
	await wait_physics_frames(2)


func after_all() -> void:
	Inventario.limpar()


func _armar() -> void:
	Inventario.adicionar("espada_media")
	Inventario.equipar("nicholas", "espada_media")


func test_folha_tem_o_golpe_nas_duas_direcoes() -> void:
	var quadros: SpriteFrames = load("res://assets/art/personagens/nicholas/nicholas_exploracao.tres")
	for nome in [&"golpe_frente", &"golpe_costas"]:
		assert_eq(quadros.get_frame_count(nome), 3, nome)
		assert_false(quadros.get_animation_loop(nome), "o golpe toca uma vez")


func test_golpe_tem_prioridade_na_animacao() -> void:
	assert_eq(AnimacaoPersonagem.escolher_acao(200.0, 120.0, true, true), "golpe")
	assert_eq(AnimacaoPersonagem.escolher_acao(0.0, 120.0, false, false), "parado")


func test_sem_arma_nao_golpeia() -> void:
	assert_false(personagem.golpear())
	assert_false(personagem.golpeando)


func test_golpe_toca_a_animacao_e_depois_volta_a_parado() -> void:
	_armar()
	assert_true(personagem.golpear())
	await wait_process_frames(2)
	assert_eq(visual.animation, &"golpe_frente")
	await wait_seconds(personagem.duracao_golpe + 0.1)
	assert_false(personagem.golpeando)
	assert_eq(visual.animation, &"parado_frente")


func test_golpe_sai_para_onde_ele_andou_e_para_de_andar() -> void:
	_armar()
	personagem.ir_para(personagem.global_position + Vector2(-60, -30))
	await wait_physics_frames(10)
	personagem.golpear()
	await wait_physics_frames(2)
	assert_false(personagem.andando)
	assert_eq(personagem.velocity, Vector2.ZERO)
	# O golpe sai para o mesmo lado em que o desenho está virado.
	var olhar := personagem.direcao_olhar
	assert_eq(visual.flip_h, olhar.x < 0.0)
	var esperado := &"golpe_costas" if olhar.y < 0.0 else &"golpe_frente"
	assert_eq(visual.animation, esperado)


func test_clique_nao_muda_a_direcao_do_golpe() -> void:
	_armar()
	var antes := personagem.direcao_olhar
	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	clique.position = Vector2(5, 5)
	personagem._unhandled_input(clique)
	assert_true(personagem.golpeando)
	assert_eq(personagem.direcao_olhar, antes)


func test_golpe_pega_quem_esta_perto_e_na_frente() -> void:
	var olhar := Vector2(2, 1).normalized()
	assert_true(PersonagemExploracao.pega_no_golpe(Vector2.ZERO, olhar, Vector2(20, 10), 40.0))
	assert_false(PersonagemExploracao.pega_no_golpe(Vector2.ZERO, olhar, Vector2(-20, -10), 40.0), "atrás não pega")
	assert_false(PersonagemExploracao.pega_no_golpe(Vector2.ZERO, olhar, Vector2(80, 40), 40.0), "longe não pega")


func test_figurante_atingido_reage() -> void:
	_armar()
	var guarda: Node2D = sala.get_node("GuardaTeste")
	var reacao: ReacaoAoGolpe = sala.get_node("GuardaTeste/ReacaoAoGolpe")
	var desenho: Node2D = sala.get_node("GuardaTeste/Visual")
	var parado_em := desenho.position
	# Nicholas logo à esquerda e acima do guarda, olhando para ele.
	personagem.global_position = guarda.global_position - Vector2(24, 12)
	personagem.direcao_olhar = Vector2(2, 1).normalized()
	watch_signals(reacao)
	personagem.golpear()
	await wait_seconds(personagem.momento_do_corte + 0.05)
	assert_signal_emitted(reacao, "atingido")
	assert_true(reacao.reagindo())
	assert_ne(desenho.modulate, Color.WHITE, "pisca")
	await wait_seconds(reacao.duracao + 0.1)
	assert_false(reacao.reagindo())
	assert_eq(desenho.position, parado_em, "volta para o lugar")
	assert_eq(desenho.modulate, Color.WHITE, "volta à cor")


func test_golpe_de_costas_para_o_figurante_nao_pega() -> void:
	_armar()
	var guarda: Node2D = sala.get_node("GuardaTeste")
	var reacao: ReacaoAoGolpe = sala.get_node("GuardaTeste/ReacaoAoGolpe")
	personagem.global_position = guarda.global_position - Vector2(24, 12)
	personagem.direcao_olhar = Vector2(-2, -1).normalized()
	watch_signals(reacao)
	personagem.golpear()
	await wait_seconds(personagem.momento_do_corte + 0.05)
	assert_signal_not_emitted(reacao, "atingido")


func test_nicholas_nao_acerta_a_si_mesmo() -> void:
	_armar()
	watch_signals(personagem)
	personagem.golpear()
	await wait_seconds(personagem.momento_do_corte + 0.05)
	assert_signal_emitted(personagem, "acertou")
	var alvos: Array = get_signal_parameters(personagem, "acertou")[0]
	assert_false(alvos.has(sala.get_node("Personagem/ReacaoAoGolpe")))


func test_espada_gira_e_o_rastro_aparece_no_corte() -> void:
	_armar()
	personagem.golpear()
	await wait_process_frames(2)
	assert_eq(na_mao.rotation_degrees, 180.0, "ergue a espada de ponta para cima")
	visual.frame = 1
	assert_eq(na_mao.rotation_degrees, -90.0, "corta para a frente")
	assert_true(na_mao.rastro.visible)
	visual.frame = 2
	assert_false(na_mao.rastro.visible)


func test_clique_esquerdo_armado_golpeia_sem_andar() -> void:
	_armar()
	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	clique.position = Vector2(100, 100)
	# O Godot cria um toque a partir do mouse; armado, esse toque não anda.
	var toque := InputEventScreenTouch.new()
	toque.device = InputEvent.DEVICE_ID_EMULATION
	toque.pressed = true
	toque.position = clique.position
	personagem._unhandled_input(toque)
	personagem._unhandled_input(clique)
	assert_true(personagem.golpeando)
	assert_false(personagem.andando)


func test_clique_sem_arma_no_chao_nao_anda() -> void:
	var toque := InputEventScreenTouch.new()
	toque.device = InputEvent.DEVICE_ID_EMULATION
	toque.pressed = true
	toque.position = Vector2(100, 100)
	personagem._unhandled_input(toque)
	assert_false(personagem.andando, "clicar no chão não anda mais")
	assert_false(personagem.golpeando)


func test_toque_de_verdade_armado_nao_golpeia() -> void:
	_armar()
	var toque := InputEventScreenTouch.new()
	toque.device = 0
	toque.pressed = true
	toque.position = Vector2(100, 100)
	personagem._unhandled_input(toque)
	assert_false(personagem.golpeando, "no celular, o golpe é no botão")
	assert_false(personagem.andando, "tocar no chão não anda mais")


func test_botao_golpe_so_aparece_armado() -> void:
	var botoes: BotoesToque = sala.get_node("BotoesToque")
	assert_false(botoes.botao_golpe.visible)
	_armar()
	assert_true(botoes.botao_golpe.visible)
	Inventario.desequipar("nicholas", Item.Encaixe.ARMA)
	assert_false(botoes.botao_golpe.visible)
