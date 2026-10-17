extends GutTest
## Na sala de teste, o desenho de Nicholas, a arma na mão e o elmo seguem a idade.

const AparenciaNicholas := preload("res://scripts/systems/aparencia_nicholas.gd")


func before_each() -> void:
	Inventario.limpar()


func after_all() -> void:
	Inventario.limpar()


func test_cada_idade_tem_mao_em_todo_quadro_da_sua_folha() -> void:
	for faixa in 3:
		var maos := AparenciaNicholas.maos(faixa)
		var quadros := AparenciaNicholas.quadros(faixa)
		for nome in quadros.get_animation_names():
			for i in quadros.get_frame_count(nome):
				var mao := maos.ponto(nome, i)
				var tras := maos.ponto_tras(nome, i)
				assert_true(mao.x >= 0.0 and mao.y >= 0.0, "faixa %d %s %d" % [faixa, nome, i])
				assert_true(tras.x >= 0.0 and tras.y >= 0.0, "faixa %d %s %d (trás)" % [faixa, nome, i])


func test_menino_e_adolescente_tem_golpe() -> void:
	for faixa in 3:
		var quadros := AparenciaNicholas.quadros(faixa)
		for dir in ["frente", "costas"]:
			var nome := StringName("golpe_" + dir)
			assert_true(quadros.has_animation(nome), "faixa %d %s" % [faixa, nome])
			assert_eq(quadros.get_frame_count(nome), 3)
			assert_false(quadros.get_animation_loop(nome))


func test_menino_tem_a_mao_mais_baixa_que_o_adulto() -> void:
	var crianca := AparenciaNicholas.maos(Inventario.FaixaEtaria.CRIANCA).ponto(&"parado_frente", 0)
	var adulto := AparenciaNicholas.maos(Inventario.FaixaEtaria.ADULTO).ponto(&"parado_frente", 0)
	assert_gt(crianca.y, adulto.y)


func test_elmo_desce_com_a_cabeca_e_armadura_com_o_tronco() -> void:
	assert_eq(AparenciaNicholas.descida(Inventario.FaixaEtaria.ADULTO, Item.Encaixe.ELMO), 0)
	assert_eq(AparenciaNicholas.descida(Inventario.FaixaEtaria.CRIANCA, Item.Encaixe.ELMO), 14)
	assert_eq(AparenciaNicholas.descida(Inventario.FaixaEtaria.ADOLESCENTE, Item.Encaixe.ARMADURA), 1)


func test_na_sala_o_boneco_e_a_mao_mudam_com_a_idade() -> void:
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	var visual: AnimacaoPersonagem = sala.get_node("Personagem/Corpo/Visual")
	var na_mao: ItemNaMao = sala.get_node("Personagem/Corpo/Visual/ItemNaMao")
	var escudo: ItemNaMao = sala.get_node("Personagem/Corpo/Visual/ProtecaoNaMao")
	await wait_process_frames(1)
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.CRIANCA)
	assert_eq(visual.sprite_frames, AparenciaNicholas.quadros(Inventario.FaixaEtaria.CRIANCA))
	assert_eq(na_mao.maos, AparenciaNicholas.maos(Inventario.FaixaEtaria.CRIANCA))
	assert_eq(escudo.maos, AparenciaNicholas.maos(Inventario.FaixaEtaria.CRIANCA))
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADULTO)
	assert_eq(visual.sprite_frames, AparenciaNicholas.quadros(Inventario.FaixaEtaria.ADULTO))
	assert_eq(na_mao.maos, AparenciaNicholas.maos(Inventario.FaixaEtaria.ADULTO))


func test_menino_com_punhal_segura_na_mao_dele() -> void:
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	var visual: AnimacaoPersonagem = sala.get_node("Personagem/Corpo/Visual")
	var na_mao: ItemNaMao = sala.get_node("Personagem/Corpo/Visual/ItemNaMao")
	await wait_process_frames(1)
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.CRIANCA)
	Inventario.adicionar("punhal")
	assert_true(Inventario.equipar("nicholas", "punhal"))
	await wait_process_frames(2)
	assert_true(na_mao.visible)
	var esperado := ItemNaMao.centro_da_mao(
		AparenciaNicholas.maos(Inventario.FaixaEtaria.CRIANCA).ponto(visual.animation, visual.frame),
		Vector2(32, 48), visual.offset, visual.flip_h)
	assert_eq(na_mao.position, esperado)


func test_elmo_do_menino_desce_ate_a_cabeca() -> void:
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	var visual: AnimacaoPersonagem = sala.get_node("Personagem/Corpo/Visual")
	var elmo: CamadaEquipamento = sala.get_node("Personagem/Corpo/Visual/CamadaElmo")
	await wait_process_frames(1)
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.CRIANCA)
	var id := "elmo_olympia"
	Inventario.adicionar(id)
	assert_true(Inventario.equipar("nicholas", id))
	await wait_process_frames(2)
	assert_eq(elmo.offset, visual.offset + Vector2(0, 14))
