extends GutTest
## Navegação e movimento por toque na sala de teste.

var sala: Node2D


func before_each() -> void:
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	await wait_physics_frames(3)


func _celula_no_mundo(celula: Vector2i) -> Vector2:
	var chao: TileMapLayer = sala.get_node("Chao")
	return chao.to_global(chao.map_to_local(celula))


func test_contorno_cobre_os_cantos_da_sala() -> void:
	var chao: TileMapLayer = sala.get_node("Chao")
	var contorno := NavegacaoSala.contorno_do_chao(chao)
	assert_eq(contorno.size(), 4)
	assert_eq(contorno[0], chao.map_to_local(Vector2i(0, 0)) + Vector2(0, -16))
	assert_eq(contorno[2], chao.map_to_local(Vector2i(15, 15)) + Vector2(0, 16))


func test_obstaculo_nao_e_andavel() -> void:
	var regiao: NavigationRegion2D = sala.get_node("Navegacao")
	var centro_do_bloco := _celula_no_mundo(Vector2i(4, 4))
	var mais_perto := NavigationServer2D.map_get_closest_point(regiao.get_navigation_map(), centro_do_bloco)
	assert_gt(mais_perto.distance_to(centro_do_bloco), 10.0)


func test_chao_livre_e_andavel() -> void:
	var regiao: NavigationRegion2D = sala.get_node("Navegacao")
	var livre := _celula_no_mundo(Vector2i(8, 8))
	var mais_perto := NavigationServer2D.map_get_closest_point(regiao.get_navigation_map(), livre)
	assert_almost_eq(mais_perto, livre, Vector2(1, 1))


func test_personagem_anda_ate_o_destino() -> void:
	var personagem: PersonagemExploracao = sala.get_node("Personagem")
	var destino := _celula_no_mundo(Vector2i(8, 8))
	personagem.ir_para(destino)
	await wait_for_signal(personagem.chegou, 10)
	assert_lt(personagem.global_position.distance_to(destino), 6.0)
	assert_false(personagem.andando)


func test_destino_dentro_do_obstaculo_vai_para_perto_dele() -> void:
	var personagem: PersonagemExploracao = sala.get_node("Personagem")
	watch_signals(personagem)
	personagem.ir_para(_celula_no_mundo(Vector2i(4, 4)))
	var destino: Vector2 = get_signal_parameters(personagem, "destino_definido")[0]
	assert_gt(destino.distance_to(_celula_no_mundo(Vector2i(4, 4))), 10.0)
