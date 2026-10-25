extends GutTest
## Visão da varanda (Capítulo 01, cena 8): a cena monta, roda curta e avisa o fim.

const CENA := preload("res://scenes/capitulo_01/visao_varanda.tscn")


func test_cena_tem_o_necessario() -> void:
	var visao: VisaoVaranda = CENA.instantiate()
	assert_not_null(visao.get_node_or_null("%Mundo"))
	assert_not_null(visao.get_node_or_null("%Camera"))
	assert_not_null(visao.get_node_or_null("%Escuro"))
	assert_not_null(visao.get_node_or_null("%Texto"))
	assert_not_null(visao.get_node_or_null("Mundo/Viewport/Cenario/Garota"))
	visao.free()


func test_termina_com_tempos_curtos() -> void:
	var visao: VisaoVaranda = CENA.instantiate()
	visao.escala_tempo = 0.02
	watch_signals(visao)
	add_child_autofree(visao)
	await wait_for_signal(visao.terminou, 5.0)
	assert_signal_emitted(visao, "terminou")


func test_tocar_remove_a_cena_no_fim() -> void:
	await VisaoVaranda.tocar(self, 0.02)
	await wait_frames(2)
	for filho in get_children():
		assert_false(filho is VisaoVaranda)


func test_sons_existem() -> void:
	for arquivo in ["cascos_crescendo", "vento_leve", "queda", "tic_tac"]:
		assert_true(FileAccess.file_exists("res://assets/audio/sfx/capitulo_01/%s.wav" % arquivo), arquivo)


## A câmera olha para a garota (antes ela olhava para a parede de trás e a
## varanda não aparecia).
func test_camera_olha_para_a_garota() -> void:
	var visao: VisaoVaranda = CENA.instantiate()
	var camera: Camera3D = visao.get_node("%Camera")
	var garota: Node3D = visao.get_node("Mundo/Viewport/Cenario/Garota")
	var frente := -camera.transform.basis.z
	var para_ela := (garota.position + Vector3(0, 1.4, 0) - camera.position).normalized()
	assert_gt(frente.dot(para_ela), 0.95, "a garota está no meio da tela")
	visao.free()
