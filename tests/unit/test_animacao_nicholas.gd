extends GutTest
## Animações de Nicholas na exploração: parado, andando, correndo e interagindo.

const ACOES := ["parado", "andando", "correndo", "interagindo"]
const DIRECOES := ["frente", "costas"]


func test_folha_tem_todas_as_animacoes() -> void:
	var quadros: SpriteFrames = load("res://assets/art/personagens/nicholas/nicholas_exploracao.tres")
	for acao in ACOES:
		for direcao in DIRECOES:
			var nome := StringName("%s_%s" % [acao, direcao])
			assert_true(quadros.has_animation(nome), nome)
			assert_gt(quadros.get_frame_count(nome), 1, nome)
	assert_false(quadros.get_animation_loop(&"interagindo_frente"), "interagir toca uma vez e fica no gesto")


func test_escolhe_a_acao_pela_rapidez() -> void:
	assert_eq(AnimacaoPersonagem.escolher_acao(0.0, 120.0, false), "parado")
	assert_eq(AnimacaoPersonagem.escolher_acao(120.0, 120.0, false), "andando")
	assert_eq(AnimacaoPersonagem.escolher_acao(210.0, 120.0, false), "correndo")
	assert_eq(AnimacaoPersonagem.escolher_acao(120.0, 120.0, true), "interagindo")


func test_olha_para_cima_de_costas() -> void:
	assert_eq(AnimacaoPersonagem.nome_direcao(Vector2(2, -1)), "costas")
	assert_eq(AnimacaoPersonagem.nome_direcao(Vector2(2, 1)), "frente")
	assert_eq(AnimacaoPersonagem.nome_direcao(Vector2(-1, 0)), "frente")


func test_andando_na_sala_troca_a_animacao() -> void:
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	var personagem: PersonagemExploracao = sala.get_node("Personagem")
	var visual: AnimacaoPersonagem = sala.get_node("Personagem/Corpo/Visual")
	await wait_physics_frames(3)
	assert_eq(visual.animation, &"parado_frente")
	personagem.ir_para(personagem.global_position + Vector2(-60, -30))
	await wait_physics_frames(10)
	assert_eq(visual.animation, &"andando_costas")


func test_para_a_esquerda_o_desenho_espelha() -> void:
	var visual: AnimacaoPersonagem = add_child_autofree(AnimacaoPersonagem.new())
	visual.olhar_para(Vector2(-2, 1))
	assert_true(visual.flip_h)
	assert_eq(visual.direcao, "frente")
	visual.olhar_para(Vector2(2, -1))
	assert_false(visual.flip_h)
	assert_eq(visual.direcao, "costas")
