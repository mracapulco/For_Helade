extends GutTest
## Menu de pausa: Esc pausa o jogo fora do menu inicial; Voltar ao jogo,
## Opções, e Menu inicial e Sair perguntam antes.

const SALA := preload("res://scenes/exploracao/sala_teste.tscn")
const MENU := preload("res://scenes/main/main.tscn")

var cena: Node
var _cena_atual: Node


func before_each() -> void:
	_cena_atual = get_tree().current_scene
	Pausa.agir = false


func after_each() -> void:
	if Pausa.aberta():
		Pausa.retomar()
	get_tree().paused = false
	Pausa.agir = true
	get_tree().current_scene = _cena_atual
	if is_instance_valid(cena):
		cena.free()
	await wait_process_frames(2)


func _abrir(modelo: PackedScene) -> void:
	cena = modelo.instantiate()
	if cena is MenuInicial:
		cena.trocar_de_cena = false
		cena.animar_entrada = false
	get_tree().root.add_child(cena)
	get_tree().current_scene = cena
	await wait_process_frames(2)


func _esc() -> void:
	var tecla := InputEventAction.new()
	tecla.action = &"ui_cancel"
	tecla.pressed = true
	Pausa._unhandled_input(tecla)


func test_esc_no_jogo_pausa_e_esc_de_novo_volta() -> void:
	await _abrir(SALA)
	_esc()
	assert_true(Pausa.aberta())
	assert_true(get_tree().paused)
	assert_true(Pausa.botao_voltar.has_focus())
	_esc()
	assert_false(Pausa.aberta())
	assert_false(get_tree().paused)


func test_voltar_ao_jogo() -> void:
	await _abrir(SALA)
	Pausa.abrir()
	Pausa.botao_voltar.pressed.emit()
	assert_false(Pausa.aberta())
	assert_false(get_tree().paused)


func test_nao_abre_no_menu_inicial() -> void:
	await _abrir(MENU)
	_esc()
	assert_false(Pausa.aberta())
	assert_false(get_tree().paused)


func test_nao_abre_com_outra_tela_pausando() -> void:
	await _abrir(SALA)
	get_tree().paused = true # bolsa ou lista de espaços aberta
	_esc()
	assert_false(Pausa.aberta())


func test_menu_inicial_pergunta_antes() -> void:
	await _abrir(SALA)
	Pausa.abrir()
	Pausa.botao_menu.pressed.emit()
	assert_true(Pausa.confirmacao.visible)
	assert_false(Pausa.principal.visible)
	assert_true(Pausa.botao_nao.has_focus(), "o seguro fica selecionado")
	Pausa.botao_nao.pressed.emit()
	assert_false(Pausa.confirmacao.visible)
	assert_true(Pausa.aberta())
	assert_eq(Pausa.pedido, Pausa.Pedido.NADA)
	Pausa.botao_menu.pressed.emit()
	Pausa.botao_sim.pressed.emit()
	assert_false(Pausa.aberta())
	assert_false(get_tree().paused)
	assert_eq(Pausa.pedido, Pausa.Pedido.MENU)


func test_sair_pergunta_antes() -> void:
	await _abrir(SALA)
	Pausa.abrir()
	Pausa.perguntar(Pausa.Pedido.SAIR)
	TranslationServer.set_locale("pt_BR")
	assert_string_contains(tr(Pausa.pergunta.text), "não foi salvo")
	_esc()
	assert_false(Pausa.confirmacao.visible, "Esc fecha só a pergunta")
	assert_true(Pausa.aberta())


func test_opcoes_abrem_e_esc_volta_a_pausa() -> void:
	await _abrir(SALA)
	Pausa.abrir()
	Pausa.botao_opcoes.pressed.emit()
	assert_true(Pausa.opcoes.visible)
	assert_false(Pausa.principal.visible)
	_esc()
	assert_false(Pausa.opcoes.visible)
	assert_true(Pausa.principal.visible)
	assert_true(Pausa.aberta())


func test_botoes_grandes_e_traduzidos() -> void:
	TranslationServer.set_locale("pt_BR")
	for botao in [Pausa.botao_voltar, Pausa.botao_opcoes, Pausa.botao_menu, Pausa.botao_sair]:
		assert_gte(botao.custom_minimum_size.y, 80.0)
		assert_ne(tr(botao.text), botao.text, botao.text)
