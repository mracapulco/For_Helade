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
	# Na altura a sala pode caber na tela: aí os limites se alargam por igual.
	assert_true(camera.limit_bottom >= ceili(limites.end.y), "o chão todo fica dentro dos limites")


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


## Numa sala menor que a tela a câmera fica parada no meio dela (antes ela
## balançava de borda a borda com o adiantamento: enjoo no restaurante).
func test_sala_menor_que_a_tela_deixa_a_camera_parada_no_meio() -> void:
	var dono := CharacterBody2D.new()
	var camera := CameraExploracao.new()
	dono.add_child(camera)
	add_child_autofree(dono)
	var tela := get_viewport().get_visible_rect().size / camera.zoom
	var sala := Rect2(Vector2(100, 50), tela * 0.5)
	camera.aplicar_limites(sala)
	assert_true(camera.parada_x and camera.parada_y)
	assert_almost_eq(float(camera.limit_right - camera.limit_left), tela.x, 1.0, "limites do tamanho da tela")
	assert_almost_eq((camera.limit_left + camera.limit_right) / 2.0, sala.get_center().x, 1.0, "sala no meio")
	dono.velocity = Vector2(100, 0)
	await wait_frames(10)
	assert_eq(camera.offset, Vector2.ZERO, "sem adiantamento numa sala que cabe na tela")
