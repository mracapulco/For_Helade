extends GutTest
## Passo 1 do plano de navegação fluida (planos/navegacao-fluida.md):
## ritmo de uma casa, peso do equipamento no andar e interpolação de física;
## e do passo 3: golpe na hora e busca de caminho leve dos inimigos.

var sala: Node2D
var personagem: PersonagemExploracao


func after_each() -> void:
	Configuracoes.movimento_em_grade = false


func before_each() -> void:
	# Testes do andar antigo, de casa em casa (opção F3 desde 23/10).
	Configuracoes.movimento_em_grade = true
	Inventario.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	await wait_physics_frames(3)


func after_all() -> void:
	Inventario.limpar()


func test_uma_casa_leva_cerca_de_0_3_s_sem_equipamento() -> void:
	var chao: TileMapLayer = sala.get_node("Chao")
	var casa := chao.map_to_local(Vector2i(1, 0)).distance_to(chao.map_to_local(Vector2i.ZERO))
	assert_lte(casa / personagem.velocidade, 0.31, "adulto sem bônus")
	assert_lte(casa / personagem.velocidade_andando(), 0.31, "com a idade atual")


func test_equipamento_pesa_no_maximo_15_por_cento_no_andar() -> void:
	assert_almost_eq(Balanceamento.multiplicador_andar(-40), 0.85, 0.001)
	assert_almost_eq(Balanceamento.multiplicador_andar(-10), 0.9, 0.001)
	assert_almost_eq(Balanceamento.multiplicador_andar(25), 1.25, 0.001)
	assert_almost_eq(Balanceamento.multiplicador_velocidade(-40), 0.6, 0.001, "o golpe usa o limite cheio")


func test_armadura_pesada_deixa_o_golpe_lento_mas_nao_tanto_o_andar() -> void:
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADULTO)
	Inventario.adicionar("armadura_pesada_olympia")
	assert_true(Inventario.equipar("nicholas", "armadura_pesada_olympia"))
	var bonus := int(Inventario.atributos("nicholas").velocidade)
	assert_almost_eq(personagem.ritmo(), Balanceamento.multiplicador_velocidade(bonus), 0.001)
	assert_almost_eq(personagem.ritmo_andar(), Balanceamento.multiplicador_andar(bonus), 0.001)
	assert_gte(personagem.ritmo_andar(), 0.85)


func test_interpolacao_so_em_quem_anda_na_fisica() -> void:
	assert_true(ProjectSettings.get_setting("physics/common/physics_interpolation"))
	assert_eq(get_tree().root.physics_interpolation_mode, Node.PHYSICS_INTERPOLATION_MODE_OFF,
		"desligada no resto do jogo")
	assert_true(personagem.is_physics_interpolated(), "personagem")
	assert_true(personagem.get_node("Camera").is_physics_interpolated(), "câmera, filha dele")
	var inimigo := get_tree().get_first_node_in_group(Inimigo.GRUPO) as Node
	assert_true(inimigo.is_physics_interpolated(), "inimigo")
	assert_false(sala.get_node("Chao").is_physics_interpolated(), "o cenário não")


func test_salto_vai_direto_sem_deslizar() -> void:
	var destino := personagem.global_position + Vector2(200, 0)
	personagem.global_position = destino
	await wait_physics_frames(1)
	assert_eq(personagem._posicao_anterior, personagem.global_position)
	assert_almost_eq(personagem.global_position.distance_to(destino), 0.0, 4.0)


# ---------- passo 3: combate ----------

func test_golpear_andando_sai_quase_na_hora() -> void:
	Inventario.adicionar("espada_media")
	Inventario.equipar("nicholas", "espada_media")
	personagem.raio_combate = 0.0
	Input.action_press("mover_tras")
	await wait_physics_frames(3)
	Input.action_release("mover_tras")
	assert_true(personagem.indo_para_casa(), "ainda no começo do passo")
	assert_true(personagem.golpear())
	var quadros := 0
	while not personagem.golpeando and quadros < 30:
		await wait_physics_frames(1)
		quadros += 1
	assert_true(personagem.golpeando)
	assert_lte(quadros, 7, "o golpe sai em uns 0,1 s, não no fim do passo normal")
	assert_eq(personagem.global_position, personagem.centro_da_casa(personagem.casa_de(personagem.global_position)),
		"golpeia do centro de uma casa")


func _inimigo() -> Inimigo:
	return get_tree().get_first_node_in_group(Inimigo.GRUPO) as Inimigo


func test_busca_sem_caminho_e_rapida() -> void:
	await wait_seconds(0.5)
	var inimigo := _inimigo()
	var casa := inimigo.casa_de(inimigo.global_position)
	var longe: Array[Vector2i] = [Vector2i(9999, 9999)]
	inimigo.proximo_passo(casa, longe)   # monta o mapa de casas andáveis
	var inicio := Time.get_ticks_usec()
	for i in 10:
		inimigo.proximo_passo(casa, longe)
	var cada := (Time.get_ticks_usec() - inicio) / 10.0
	gut.p("busca sem caminho: %.0f us" % cada)
	assert_lt(cada, 1000.0, "antes: 2.600 us nesta sala")


func test_inimigo_sem_caminho_espera_antes_de_procurar_de_novo() -> void:
	await wait_seconds(0.5)
	var inimigo := _inimigo()
	var casa := inimigo.casa_de(inimigo.global_position)
	var cercado: Array[Vector2i] = [casa + Vector2i(50, 50)]
	inimigo._comecar_passo(cercado)
	assert_gt(inimigo._espera_caminho, 0.0, "não achou caminho: espera")
	assert_false(inimigo.andando())
