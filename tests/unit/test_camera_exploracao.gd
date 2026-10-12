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
	assert_gt(limites.size.x, 1280.0, "a sala deve ser mais larga que a tela")
	assert_eq(camera.limit_left, floori(limites.position.x))
	assert_eq(camera.limit_bottom, ceili(limites.end.y))
