extends GutTest
## Nicholas no barquinho a remo, usado nas rotas de mar do mapa de Hélade.

const CAMINHO := "res://assets/art/mapa/barco/nicholas_barco.tres"


func test_folha_do_barco_tem_as_duas_direcoes() -> void:
	var quadros: SpriteFrames = load(CAMINHO)
	assert_not_null(quadros, "SpriteFrames do barco carrega")
	for nome in [&"barco_frente", &"barco_costas"]:
		assert_true(quadros.has_animation(nome), nome)
		assert_gte(quadros.get_frame_count(nome), 2, nome)
		assert_true(quadros.get_animation_loop(nome), "%s repete" % nome)
		assert_eq(quadros.get_frame_texture(nome, 0).get_size(), Vector2(48, 48), nome)
