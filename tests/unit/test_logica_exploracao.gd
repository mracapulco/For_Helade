extends GutTest
## Regras de lógica da exploração: alcance, escolha do alvo do toque e avanço
## da caixa de diálogo.

const ROTEIRO: DialogueResource = preload("res://data/dialogos/teste/exploracao.dialogue")

var sala: Node2D
var personagem: PersonagemExploracao
var objeto: Interagivel
var outro: Interagivel


func before_each() -> void:
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	objeto = sala.get_node("ObjetoTeste/Interagivel")
	outro = sala.get_node("PersonagemTeste/Interagivel")
	await wait_physics_frames(3)
	# O mapa de navegação atualiza em segundo plano; espera a sala nova entrar
	# nele (antes disso o ponto andável mais próximo de tudo é a origem).
	var mapa := personagem.agente.get_navigation_map()
	var centro_objeto := objeto.get_parent().global_position as Vector2
	await wait_until(func() -> bool:
		return NavigationServer2D.map_get_closest_point(mapa, centro_objeto).distance_to(centro_objeto) < 64.0, 2.0)


func after_each() -> void:
	# A caixa entra na cena um quadro depois (call_deferred). Tira a sala antes
	# de esperar, para ela não seguir rodando junto com a sala do próximo teste.
	sala.free()
	await wait_process_frames(2)
	for caixa in _caixas_abertas():
		caixa.free()


func _caixas_abertas() -> Array[Node]:
	var caixas: Array[Node] = []
	var pendentes: Array[Node] = [get_tree().root]
	while not pendentes.is_empty():
		var no: Node = pendentes.pop_back()
		if no is CaixaDialogo:
			caixas.append(no)
		pendentes.append_array(no.get_children())
	return caixas


func _clique() -> InputEventMouseButton:
	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	return clique


# --- Alcance ---

func test_alcance_inclui_a_borda() -> void:
	var centro := objeto.global_position
	assert_true(objeto.ao_alcance(centro + Vector2(objeto.alcance, 0)))
	assert_false(objeto.ao_alcance(centro + Vector2(objeto.alcance + 1.0, 0)))


func test_alcance_e_igual_em_todas_as_direcoes() -> void:
	var centro := objeto.global_position
	for direcao in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2(1, 1).normalized()]:
		assert_true(objeto.ao_alcance(centro + direcao * (objeto.alcance - 1.0)))


func test_enter_escolhe_o_mais_perto_quando_dois_estao_ao_alcance() -> void:
	outro.alcance = 10000.0
	objeto.alcance = 10000.0
	personagem.global_position = objeto.global_position + Vector2(0, 40)
	assert_eq(personagem.interagivel_ao_alcance(), objeto)
	personagem.global_position = outro.global_position + Vector2(0, 40)
	assert_eq(personagem.interagivel_ao_alcance(), outro)


# --- Alvo do toque ---

func test_toque_no_chao_nao_anda() -> void:
	var destino := personagem.global_position + Vector2(64, 32)
	personagem.tocar(destino)
	assert_false(personagem.andando)
	assert_null(personagem.alvo_interacao)


func test_toque_na_area_do_interagivel_fora_do_desenho_ainda_conta() -> void:
	# A área de toque é maior que o desenho, pensando em dedo.
	var area := objeto.get_node("AreaDeToque") as CollisionShape2D
	var raio := (area.shape as CircleShape2D).radius
	var ponto := area.global_position + Vector2(raio * 0.8, 0)
	assert_eq(personagem.interagivel_em(ponto), objeto)


func test_toque_em_interagivel_longe_nao_anda() -> void:
	watch_signals(objeto)
	personagem.tocar(objeto.global_position)
	assert_false(personagem.andando)
	assert_null(personagem.alvo_interacao)
	assert_signal_not_emitted(objeto, "interagido")


# --- Caixa de diálogo ---

func test_todas_as_falas_tem_id_de_traducao() -> void:
	for marcador in ["objeto_teste", "personagem_teste"]:
		var fala: DialogueLine = await ROTEIRO.get_next_dialogue_line(marcador)
		while fala != null:
			assert_string_starts_with(fala.static_id, "EXPLORACAO_TESTE_")
			fala = await ROTEIRO.get_next_dialogue_line(fala.next_id)


func test_clique_durante_a_digitacao_mostra_a_fala_inteira() -> void:
	outro.interagir()
	await wait_process_frames(3)
	var caixa := _caixas_abertas()[0] as CaixaDialogo
	assert_true(caixa.dialogue_label.is_typing)
	caixa._on_balloon_gui_input(_clique())
	assert_false(caixa.dialogue_label.is_typing)
	assert_eq(caixa.dialogue_line.static_id, "EXPLORACAO_TESTE_002", "não deve pular a fala")


func test_clique_avanca_ate_fechar_e_libera_o_personagem() -> void:
	watch_signals(DialogueManager)
	outro.interagir()
	await wait_process_frames(3)
	var caixa := _caixas_abertas()[0] as CaixaDialogo
	assert_true(personagem.em_dialogo)

	await wait_until(func() -> bool: return caixa.is_waiting_for_input, 5.0)
	caixa._on_balloon_gui_input(_clique())
	await wait_process_frames(2)
	assert_eq(caixa.dialogue_line.static_id, "EXPLORACAO_TESTE_003")

	await wait_until(func() -> bool: return caixa.is_waiting_for_input, 5.0)
	caixa._on_balloon_gui_input(_clique())
	await wait_process_frames(3)
	assert_signal_emitted(DialogueManager, "dialogue_ended")
	assert_true(_caixas_abertas().is_empty(), "a caixa deve fechar no fim")
	await wait_seconds(0.3)
	assert_false(personagem.em_dialogo)


func test_enter_logo_ao_fechar_nao_reabre_a_conversa() -> void:
	personagem.global_position = objeto.global_position + Vector2(0, objeto.alcance * 0.55)
	objeto.interagir()
	await wait_process_frames(3)
	DialogueManager.dialogue_ended.emit(ROTEIRO)
	watch_signals(objeto)
	var tecla := InputEventAction.new()
	tecla.action = &"interagir"
	tecla.pressed = true
	personagem._unhandled_input(tecla)
	assert_signal_not_emitted(objeto, "interagido")
