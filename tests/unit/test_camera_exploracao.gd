extends GutTest
## Bordas da câmera da exploração.


func test_sem_tiles_retorna_retangulo_vazio() -> void:
	assert_eq(CameraExploracao.retangulo_dos_tiles([], Vector2(128, 64)), Rect2())


func test_um_tile_cobre_o_proprio_tamanho() -> void:
	var r := CameraExploracao.retangulo_dos_tiles([Vector2(100, 50)], Vector2(128, 64))
	assert_eq(r, Rect2(36, 18, 128, 64))


func test_varios_tiles_cobrem_todos() -> void:
	var centros: Array[Vector2] = [Vector2(0, 0), Vector2(640, 320), Vector2(-640, 320)]
	var r := CameraExploracao.retangulo_dos_tiles(centros, Vector2(128, 64))
	assert_eq(r, Rect2(-704, -32, 1408, 384))


func test_sala_de_teste_limita_a_camera_ao_chao() -> void:
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	var camera: CameraExploracao = sala.get_node("Personagem/Camera")
	var chao: TileMapLayer = sala.get_node("Chao")
	var limites := CameraExploracao.limites_do_mapa(chao)
	assert_gt(limites.size.x * camera.zoom.x, 1280.0, "a sala deve ser mais larga que a tela")
	assert_eq(camera.limit_left, floori(limites.position.x))
	assert_eq(camera.limit_bottom, ceili(limites.end.y))


func test_exploracao_usa_pixel_art_ampliado() -> void:
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	var camera: CameraExploracao = sala.get_node("Personagem/Camera")
	var chao: TileMapLayer = sala.get_node("Chao")
	assert_eq(camera.zoom, Vector2(2, 2))
	assert_eq(chao.tile_set.tile_size, Vector2i(64, 32), "piso de 64×32 pixels de arte")
	assert_eq(sala.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "pixels nítidos")


func test_personagens_e_objetos_tem_no_visual() -> void:
	var sala: Node2D = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	for caminho in ["Personagem/Corpo/Visual", "ObjetoTeste/Visual", "PersonagemTeste/Visual"]:
		var visual := sala.get_node_or_null(caminho) as Node2D
		assert_not_null(visual, caminho)
		if visual is Sprite2D:
			assert_not_null(visual.texture, caminho)
		elif visual is AnimatedSprite2D:
			assert_not_null(visual.sprite_frames, caminho)
