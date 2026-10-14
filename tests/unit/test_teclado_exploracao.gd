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
	var erro := Vector2(0.001, 0.001)
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(0, -1)), -eixo_x, erro, "W sobe à esquerda")
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(0, 1)), eixo_x, erro, "S desce à direita")
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(1, 0)), -eixo_y, erro, "D sobe à direita")
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(-1, 0)), eixo_y, erro, "A desce à esquerda")


func test_duas_teclas_fazem_as_direcoes_retas_da_tela() -> void:
	var erro := Vector2(0.001, 0.001)
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(1, -1).normalized()), Vector2.UP, erro, "W+D")
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(-1, -1).normalized()), Vector2.LEFT, erro, "W+A")
	assert_almost_eq(PersonagemExploracao.direcao_isometrica(Vector2(1, 1).normalized()), Vector2.RIGHT, erro, "S+D")


func test_d_anda_para_a_direita() -> void:
	var x_inicial := personagem.global_position.x
	await _andar(["mover_direita"], 20)
	assert_gt(personagem.global_position.x, x_inicial + 10.0)


func test_correr_e_mais_rapido_que_andar() -> void:
	Input.action_press("mover_direita")
	await wait_physics_frames(4)
	var andando := personagem.velocity.length()
	Input.action_press("correr")
	await wait_physics_frames(30)
	var correndo := personagem.velocity.length()
	assert_almost_eq(andando, personagem.velocidade, 1.0)
	assert_almost_eq(correndo, personagem.velocidade * personagem.multiplicador_corrida, 1.0)


func _centro_da_casa_mais_perto() -> Vector2:
	return personagem.centro_da_casa(personagem.casa_de(personagem.global_position))


func test_soltar_a_tecla_termina_o_passo_no_centro_da_casa() -> void:
	var inicio := personagem.casa_de(personagem.global_position)
	await _andar(["mover_tras"], 5)
	assert_true(personagem.indo_para_casa(), "soltou no meio do passo")
	await wait_seconds(1.0)
	assert_false(personagem.indo_para_casa())
	assert_eq(personagem.casa_de(personagem.global_position), inicio + Vector2i(1, 0), "S anda uma casa em x")
	assert_eq(personagem.global_position, _centro_da_casa_mais_perto())


func test_cada_tecla_anda_uma_casa_na_sua_linha() -> void:
	assert_eq(PersonagemExploracao.passo_na_grade(Vector2(0, -1)), Vector2i(-1, 0), "W")
	assert_eq(PersonagemExploracao.passo_na_grade(Vector2(0, 1)), Vector2i(1, 0), "S")
	assert_eq(PersonagemExploracao.passo_na_grade(Vector2(1, 0)), Vector2i(0, -1), "D")
	assert_eq(PersonagemExploracao.passo_na_grade(Vector2(-1, 0)), Vector2i(0, 1), "A")
	assert_eq(PersonagemExploracao.passo_na_grade(Vector2(1, -1).normalized()), Vector2i(-1, -1), "W+D sobe reto")


func test_nao_entra_na_casa_de_um_figurante() -> void:
	var guarda: Node2D = sala.get_node("GuardaTeste")
	var casa_guarda := personagem.casa_de(guarda.global_position)
	# Na casa logo acima e à esquerda do guarda: S o levaria para a casa dele.
	personagem.global_position = personagem.centro_da_casa(casa_guarda + Vector2i(-1, 0))
	await wait_physics_frames(2)
	await _andar(["mover_tras"], 30)
	await wait_seconds(0.5)
	assert_eq(personagem.casa_de(personagem.global_position), casa_guarda + Vector2i(-1, 0), "fica na casa vizinha")
	assert_eq(personagem.global_position, _centro_da_casa_mais_perto())


func test_toque_para_no_centro_de_uma_casa() -> void:
	personagem.ir_para(personagem.global_position + Vector2(70, 20))
	await wait_for_signal(personagem.chegou, 5)
	assert_eq(personagem.global_position, _centro_da_casa_mais_perto())


func test_teclado_cancela_o_clique() -> void:
	personagem.ir_para(personagem.global_position + Vector2(150, 0))
	await _andar(["mover_frente"], 3)
	assert_false(personagem.andando)


func test_pulo_sobe_e_volta_ao_chao() -> void:
	var corpo: Node2D = personagem.get_node("Corpo")
	personagem.pular()
	await wait_seconds(personagem.duracao_pulo / 2.0)
	assert_lt(corpo.position.y, -5.0, "no meio do pulo o corpo está no alto")
	await wait_seconds(personagem.duracao_pulo)
	assert_false(personagem.pulando)
	assert_eq(corpo.position.y, 0.0)


func test_bordas_impedem_sair_da_sala() -> void:
	var chao: TileMapLayer = sala.get_node("Chao")
	var contorno := NavegacaoSala.contorno_do_chao(chao)
	await _andar(["mover_tras", "correr"], 240)
	assert_true(Geometry2D.is_point_in_polygon(chao.to_local(personagem.global_position), contorno))
