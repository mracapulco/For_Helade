extends GutTest
## Arma equipada aparece na mão de Nicholas e acompanha as animações.

const MAOS := "res://assets/art/personagens/nicholas/nicholas_maos.tres"
const FOLHA := "res://assets/art/personagens/nicholas/nicholas_exploracao.tres"


func before_each() -> void:
	Inventario.limpar()


func after_all() -> void:
	Inventario.limpar()


func test_toda_animacao_tem_a_mao_em_cada_quadro() -> void:
	var maos: MaosPersonagem = load(MAOS)
	var quadros: SpriteFrames = load(FOLHA)
	for nome in quadros.get_animation_names():
		for i in quadros.get_frame_count(nome):
			var mao := maos.ponto(nome, i)
			assert_true(mao.x >= 0.0 and mao.x < maos.tamanho_quadro.x, "%s %d" % [nome, i])
			assert_true(mao.y >= 0.0 and mao.y < maos.tamanho_quadro.y, "%s %d" % [nome, i])


func test_espada_tem_desenho_na_mao() -> void:
	var espada := Inventario.item("espada_teste")
	assert_not_null(espada.visual_na_mao)


func test_posicao_espelhada_fica_do_outro_lado() -> void:
	var quadro := Vector2(32, 48)
	var offset := Vector2(0, -22)
	var normal := ItemNaMao.posicao_na_mao(Vector2(21, 29), Vector2(2, 3), Vector2(8, 20), quadro, offset, false)
	var espelhada := ItemNaMao.posicao_na_mao(Vector2(21, 29), Vector2(2, 3), Vector2(8, 20), quadro, offset, true)
	assert_eq(normal, Vector2(3, -20))
	# Espelhado: o desenho inteiro reflete em torno do centro do quadro.
	assert_eq(espelhada.x, -(normal.x + 8))
	assert_eq(espelhada.y, normal.y)


func test_equipar_mostra_e_desequipar_esconde() -> void:
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	var na_mao: ItemNaMao = sala.get_node("Personagem/Corpo/Visual/ItemNaMao")
	await wait_physics_frames(2)
	assert_false(na_mao.visible, "sem arma, nada na mão")
	Inventario.adicionar("espada_teste")
	Inventario.equipar("nicholas", "espada_teste")
	await wait_process_frames(1)
	assert_true(na_mao.visible)
	assert_eq(na_mao.item_mostrado().id, "espada_teste")
	Inventario.desequipar("nicholas", Item.Encaixe.ARMA)
	assert_false(na_mao.visible)


func test_espada_acompanha_a_mao_ao_andar_e_ao_virar() -> void:
	Inventario.adicionar("espada_teste")
	Inventario.equipar("nicholas", "espada_teste")
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	var personagem: PersonagemExploracao = sala.get_node("Personagem")
	var visual: AnimacaoPersonagem = sala.get_node("Personagem/Corpo/Visual")
	var na_mao: ItemNaMao = sala.get_node("Personagem/Corpo/Visual/ItemNaMao")
	await wait_physics_frames(2)
	assert_true(na_mao.visible)
	personagem.ir_para(personagem.global_position + Vector2(-60, -30))
	await wait_physics_frames(10)
	assert_eq(visual.animation, &"andando_costas")
	assert_eq(na_mao.flip_h, visual.flip_h, "a espada espelha junto com o desenho")
	var esperado := ItemNaMao.posicao_na_mao(na_mao.maos.ponto(visual.animation, visual.frame),
		Vector2(2, 3), na_mao.texture.get_size(), Vector2(32, 48), visual.offset, visual.flip_h)
	assert_eq(na_mao.position, esperado)


func test_ao_pular_a_espada_sobe_com_o_corpo() -> void:
	Inventario.adicionar("espada_teste")
	Inventario.equipar("nicholas", "espada_teste")
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	var personagem: PersonagemExploracao = sala.get_node("Personagem")
	var na_mao: ItemNaMao = sala.get_node("Personagem/Corpo/Visual/ItemNaMao")
	await wait_physics_frames(2)
	var antes := na_mao.global_position.y
	personagem.pular()
	await wait_seconds(personagem.duracao_pulo / 2.0)
	assert_lt(na_mao.global_position.y, antes - 5.0)
