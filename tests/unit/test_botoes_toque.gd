extends GutTest
## Botões grandes de Correr e Pular para quem joga no toque.

var sala: Node2D
var personagem: PersonagemExploracao
var botoes: BotoesToque


func before_each() -> void:
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	botoes = sala.get_node("BotoesToque")
	await wait_physics_frames(3)


func after_each() -> void:
	Input.action_release(&"correr")


func test_aparecem_na_sala_de_teste() -> void:
	assert_true(botoes.visible)


func test_sem_toque_e_sem_sempre_mostrar_ficam_escondidos() -> void:
	botoes.sempre_mostrar = false
	var esperado := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	assert_eq(botoes.deve_aparecer(), esperado)


func test_botoes_sao_grandes() -> void:
	assert_gte(botoes.botao_correr.size.x, 120.0)
	assert_gte(botoes.botao_pular.size.y, 120.0)


func test_textos_vem_da_traducao() -> void:
	TranslationServer.set_locale("pt_BR")
	assert_eq(tr(botoes.botao_correr.text), "Correr")
	assert_eq(tr(botoes.botao_pular.text), "Pular")


func test_pular_faz_o_personagem_pular() -> void:
	botoes.botao_pular.pressed.emit()
	await wait_process_frames(2)
	assert_true(personagem.pulando)


func test_pular_nao_deixa_a_tecla_presa() -> void:
	botoes.botao_pular.pressed.emit()
	await wait_process_frames(2)
	assert_false(Input.is_action_pressed(&"pular"))


func test_correr_liga_e_desliga() -> void:
	botoes.botao_correr.button_pressed = true
	assert_true(Input.is_action_pressed(&"correr"))
	botoes.botao_correr.button_pressed = false
	assert_false(Input.is_action_pressed(&"correr"))


func test_toque_no_botao_nao_faz_o_personagem_andar() -> void:
	var centro := botoes.botao_pular.get_global_rect().get_center()
	assert_true(BotoesToque.toque_em_botao(get_tree(), centro))
	var toque := InputEventScreenTouch.new()
	toque.pressed = true
	toque.position = centro
	personagem._unhandled_input(toque)
	assert_false(personagem.andando)


func test_toque_fora_dos_botoes_anda() -> void:
	assert_false(BotoesToque.toque_em_botao(get_tree(), Vector2(200, 200)))


func test_somem_durante_a_conversa() -> void:
	botoes.botao_correr.button_pressed = true
	DialogueManager.dialogue_started.emit(null)
	assert_false(botoes.visible)
	assert_false(Input.is_action_pressed(&"correr"))
	DialogueManager.dialogue_ended.emit(null)
	assert_true(botoes.visible)
