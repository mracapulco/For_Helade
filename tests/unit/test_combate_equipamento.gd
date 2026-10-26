extends GutTest
## Armas e proteções no corpo do Nicholas na sala de teste: o que aparece,
## como cada arma golpeia e como o equipamento muda velocidade e dano.

var sala: Node2D
var personagem: PersonagemExploracao
var visual: AnimacaoPersonagem
var na_mao: ItemNaMao
var protecao: ItemNaMao
var armadura: CamadaEquipamento
var elmo: CamadaEquipamento


func before_each() -> void:
	Inventario.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	visual = sala.get_node("Personagem/Corpo/Visual")
	na_mao = sala.get_node("Personagem/Corpo/Visual/ItemNaMao")
	protecao = sala.get_node("Personagem/Corpo/Visual/ProtecaoNaMao")
	armadura = sala.get_node("Personagem/Corpo/Visual/CamadaArmadura")
	elmo = sala.get_node("Personagem/Corpo/Visual/CamadaElmo")
	await wait_physics_frames(2)


func after_all() -> void:
	Inventario.limpar()


func _equipar(id: String) -> void:
	Inventario.adicionar(id)
	Inventario.equipar("nicholas", id)


func test_cada_arma_aparece_na_mao() -> void:
	for id in ["espada_grande", "machado_guerra", "arco", "espada_media",
			"machado_pequeno", "punhal", "maca"]:
		_equipar(id)
		await wait_process_frames(1)
		assert_eq(na_mao.item_mostrado(), Inventario.item(id), id)
		assert_true(na_mao.visible, id)


func test_protecao_aparece_na_mao_de_tras_sem_girar() -> void:
	for id in ["escudo_olympia", "escudo_agape", "caixa_frutas", "panela"]:
		_equipar(id)
		await wait_process_frames(1)
		assert_eq(protecao.item_mostrado(), Inventario.item(id), id)
		assert_true(protecao.visible, id)
	_equipar("espada_media")
	personagem.golpear()
	await wait_process_frames(2)
	visual.frame = 1
	assert_eq(protecao.rotation_degrees, 0.0, "o escudo não gira com o golpe")
	assert_ne(protecao.position, na_mao.position, "cada um numa mão")


func test_armadura_e_elmo_acompanham_os_quadros() -> void:
	assert_false(armadura.visible)
	_equipar("armadura_pesada_agape")
	_equipar("elmo_bandidos")
	await wait_process_frames(2)
	assert_true(armadura.visible)
	assert_true(elmo.visible)
	assert_eq(armadura.animation, visual.animation)
	personagem.direcao_olhar = Vector2(-2, -1).normalized()
	await wait_process_frames(2)
	assert_eq(armadura.animation, visual.animation)
	assert_eq(armadura.flip_h, visual.flip_h)
	assert_eq(elmo.frame, visual.frame)
	Inventario.desequipar("nicholas", Item.Encaixe.ELMO)
	await wait_process_frames(1)
	assert_false(elmo.visible)


func test_camadas_tem_todas_as_animacoes_do_nicholas() -> void:
	var folha: SpriteFrames = visual.sprite_frames
	for id in ["armadura_leve_olympia", "armadura_pesada_agape", "elmo_khronosses", "elmo_bandidos"]:
		var quadros := Inventario.item(id).visual_no_corpo
		for nome in folha.get_animation_names():
			assert_eq(quadros.get_frame_count(nome), folha.get_frame_count(nome), "%s %s" % [id, nome])


func test_punhal_estoca_e_nao_deixa_arco_de_corte() -> void:
	_equipar("punhal")
	personagem.golpear()
	await wait_process_frames(2)
	visual.frame = 1
	assert_eq(na_mao.rotation_degrees, -90.0, "estoca para a frente")
	assert_false(na_mao.rastro.visible)


func test_machado_desce_pesado_com_rastro() -> void:
	_equipar("machado_pequeno")
	personagem.golpear()
	await wait_process_frames(2)
	visual.frame = 1
	assert_eq(na_mao.rotation_degrees, -60.0)
	assert_true(na_mao.rastro.visible)


func test_arco_solta_flecha() -> void:
	_equipar("arco")
	assert_eq(personagem.alcance_do_golpe(), 320.0)
	personagem.golpear()
	await wait_process_frames(2)
	visual.frame = 1
	assert_true(na_mao.flecha.visible, "a flecha sai no corte")
	assert_false(na_mao.rastro.visible)
	await wait_seconds(na_mao.tempo_flecha + 0.1)
	assert_false(na_mao.flecha.visible, "e some depois do voo")


func test_arco_acerta_de_longe() -> void:
	_equipar("arco")
	var guarda: Node2D = sala.get_node("GuardaTeste")
	var reacao: ReacaoAoGolpe = sala.get_node("GuardaTeste/ReacaoAoGolpe")
	personagem.global_position = guarda.global_position - Vector2(128, 64)
	personagem.direcao_olhar = Vector2(2, 1).normalized()
	watch_signals(reacao)
	personagem.golpear()
	await wait_seconds(personagem.momento_do_corte / personagem.ritmo() + 0.05)
	assert_signal_emitted(reacao, "atingido")


func test_armadura_pesada_deixa_mais_lento_e_punhal_mais_rapido() -> void:
	var normal := personagem.velocidade_andando()
	_equipar("armadura_pesada_bandidos")
	assert_lt(personagem.velocidade_andando(), normal)
	assert_gt(personagem.duracao_do_golpe(), personagem.duracao_golpe)
	Inventario.desequipar("nicholas", Item.Encaixe.ARMADURA)
	_equipar("punhal")
	assert_gt(personagem.velocidade_andando(), normal)
	assert_lt(personagem.duracao_do_golpe(), personagem.duracao_golpe)


func test_golpe_tira_vida_do_guarda_e_mostra_o_dano() -> void:
	_equipar("espada_media")
	var guarda: Node2D = sala.get_node("GuardaTeste")
	var vida: Vida = sala.get_node("GuardaTeste/Vida")
	var reacao: ReacaoAoGolpe = sala.get_node("GuardaTeste/ReacaoAoGolpe")
	personagem.global_position = guarda.global_position - Vector2(24, 12)
	personagem.direcao_olhar = Vector2(2, 1).normalized()
	var antes := vida.atual
	personagem.golpear()
	await wait_seconds(personagem.momento_do_corte / personagem.ritmo() + 0.05)
	var esperado := Balanceamento.dano(personagem.ataque(), vida.defesa_total())
	assert_eq(vida.atual, antes - esperado)
	assert_not_null(reacao.get_node_or_null("Dano"), "número do dano sobe")


func test_bau_de_armas_entrega_tudo() -> void:
	var recompensa: Recompensa = sala.get_node("BauArmas/Recompensa")
	recompensa.entregar()
	var ids: Array[String] = ["espada_grande", "machado_guerra", "arco", "arco_curto", "espada_media",
		"machado_pequeno", "punhal", "maca", "panela"]
	for peca in ["escudo", "armadura_leve", "armadura_pesada", "elmo"]:
		for reino in ["olympia", "agape", "khronosses", "bandidos"]:
			ids.append("%s_%s" % [peca, reino])
	for id in ids:
		assert_true(Inventario.tem(id), id)


func test_pegar_a_caixa_leva_a_caixa_e_as_frutas() -> void:
	var recompensa: Recompensa = sala.get_node("CaixaDeFrutas/Recompensa")
	recompensa.entregar()
	assert_true(Inventario.tem("caixa_frutas"), "fica com a caixa")
	assert_true(Inventario.tem("fruta", 5), "e com as frutas (Rafael, 26/10)")
	await get_tree().process_frame
	assert_null(sala.get_node_or_null("CaixaDeFrutas"), "nada fica no chão")


func test_bolsa_mostra_os_bonus() -> void:
	var texto := TelaBolsa.texto_bonus(Inventario.item("espada_grande"))
	assert_string_contains(texto, "Duas mãos")
	assert_string_contains(texto, "Ataque +14")
	assert_string_contains(texto, "Velocidade -5%")
	assert_string_contains(TelaBolsa.texto_bonus(Inventario.item("arco")), "Longo alcance")
