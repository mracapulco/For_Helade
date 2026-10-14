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
	Inventario.adicionar("espada_teste")
	Inventario.equipar("nicholas", "espada_teste")


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


func test_golpe_vira_para_o_alvo_e_para_de_andar() -> void:
	_armar()
	personagem.ir_para(personagem.global_position + Vector2(80, 40))
	await wait_physics_frames(3)
	personagem.golpear(personagem.global_position + Vector2(-50, -30))
	await wait_physics_frames(2)
	assert_false(personagem.andando)
	assert_eq(personagem.velocity, Vector2.ZERO)
	assert_eq(visual.animation, &"golpe_costas")
	assert_true(visual.flip_h, "golpe para a esquerda espelha o desenho")


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


func test_clique_sem_arma_continua_andando() -> void:
	var toque := InputEventScreenTouch.new()
	toque.device = InputEvent.DEVICE_ID_EMULATION
	toque.pressed = true
	toque.position = Vector2(100, 100)
	personagem._unhandled_input(toque)
	assert_true(personagem.andando)
	assert_false(personagem.golpeando)


func test_toque_de_verdade_armado_continua_andando() -> void:
	_armar()
	var toque := InputEventScreenTouch.new()
	toque.device = 0
	toque.pressed = true
	toque.position = Vector2(100, 100)
	personagem._unhandled_input(toque)
	assert_true(personagem.andando, "no celular, tocar no chão anda; o golpe é no botão")


func test_botao_golpe_so_aparece_armado() -> void:
	var botoes: BotoesToque = sala.get_node("BotoesToque")
	assert_false(botoes.botao_golpe.visible)
	_armar()
	assert_true(botoes.botao_golpe.visible)
	Inventario.desequipar("nicholas", Item.Encaixe.ARMA)
	assert_false(botoes.botao_golpe.visible)
