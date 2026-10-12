extends GutTest
## Controles de teclado do personagem (PC).

var sala: Node2D
var personagem: PersonagemExploracao


func before_each() -> void:
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	await wait_physics_frames(3)


func after_each() -> void:
	for acao in ["mover_frente", "mover_tras", "mover_esquerda", "mover_direita", "correr"]:
		Input.action_release(acao)


func _andar(acoes: Array, quadros: int) -> float:
	var inicio := personagem.global_position
	for acao in acoes:
		Input.action_press(acao)
	await wait_physics_frames(quadros)
	for acao in acoes:
		Input.action_release(acao)
	return personagem.global_position.distance_to(inicio)


func test_cada_tecla_segue_uma_linha_do_quadriculado() -> void:
	var chao: TileMapLayer = sala.get_node("Chao")
	var eixo_x := (chao.map_to_local(Vector2i(1, 0)) - chao.map_to_local(Vector2i(0, 0))).normalized()
	var eixo_y := (chao.map_to_local(Vector2i(0, 1)) - chao.map_to_local(Vector2i(0, 0))).normalized()
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(1, 0)), eixo_x, Vector2(0.001, 0.001), "D")
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(-1, 0)), -eixo_x, Vector2(0.001, 0.001), "A")
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(0, -1)), -eixo_y, Vector2(0.001, 0.001), "W")
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(0, 1)), eixo_y, Vector2(0.001, 0.001), "S")


func test_duas_teclas_fazem_a_diagonal_da_tela() -> void:
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(1, -1).normalized()), Vector2.RIGHT, Vector2(0.001, 0.001), "W+D")
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(-1, -1).normalized()), Vector2.UP, Vector2(0.001, 0.001), "W+A")


func test_d_anda_para_a_direita() -> void:
	var x_inicial := personagem.global_position.x
	await _andar(["mover_direita"], 20)
	assert_gt(personagem.global_position.x, x_inicial + 20.0)


func test_correr_vai_mais_longe() -> void:
	var andando := await _andar(["mover_direita"], 20)
	var correndo := await _andar(["mover_direita", "correr"], 20)
	assert_gt(correndo, andando * 1.5)


func test_teclado_cancela_o_clique() -> void:
	personagem.ir_para(personagem.global_position + Vector2(300, 0))
	await _andar(["mover_frente"], 3)
	assert_false(personagem.andando)


func test_pulo_sobe_e_volta_ao_chao() -> void:
	var corpo: Node2D = personagem.get_node("Corpo")
	personagem.pular()
	await wait_seconds(personagem.duracao_pulo / 2.0)
	assert_lt(corpo.position.y, -10.0, "no meio do pulo o corpo está no alto")
	await wait_seconds(personagem.duracao_pulo)
	assert_false(personagem.pulando)
	assert_eq(corpo.position.y, 0.0)


func test_bordas_impedem_sair_da_sala() -> void:
	var chao: TileMapLayer = sala.get_node("Chao")
	var contorno := NavegacaoSala.contorno_do_chao(chao)
	await _andar(["mover_tras", "correr"], 240)
	assert_true(Geometry2D.is_point_in_polygon(chao.to_local(personagem.global_position), contorno))
