extends GutTest
## Interação com objetos e personagens na sala de teste.

var sala: Node2D
var personagem: PersonagemExploracao
var objeto: Interagivel


func before_each() -> void:
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	objeto = sala.get_node("ObjetoTeste/Interagivel")
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
	Input.action_release(&"mover_frente")


func _caixas_abertas() -> Array[Node]:
	var caixas: Array[Node] = []
	var pendentes: Array[Node] = [get_tree().root]
	while not pendentes.is_empty():
		var no: Node = pendentes.pop_back()
		if no is CaixaDialogo:
			caixas.append(no)
		pendentes.append_array(no.get_children())
	return caixas


# Um ponto ao alcance do objeto, logo abaixo dele (vale em qualquer escala).
func _perto_do_objeto() -> Vector2:
	return objeto.get_parent().global_position + Vector2(0, objeto.alcance * 0.55)


func test_toque_no_objeto_encontra_o_interagivel() -> void:
	assert_eq(personagem.interagivel_em(objeto.global_position), objeto)


func test_toque_no_chao_vazio_nao_encontra_nada() -> void:
	assert_null(personagem.interagivel_em(personagem.global_position))


func test_objeto_bloqueia_a_navegacao() -> void:
	var regiao: NavigationRegion2D = sala.get_node("Navegacao")
	var centro := objeto.get_parent().global_position as Vector2
	var mais_perto := NavigationServer2D.map_get_closest_point(regiao.get_navigation_map(), centro)
	assert_gt(mais_perto.distance_to(centro), 15.0)


func test_tocar_de_longe_anda_e_interage_ao_chegar() -> void:
	watch_signals(objeto)
	assert_false(objeto.ao_alcance(personagem.global_position))
	personagem.tocar(objeto.global_position)
	assert_eq(personagem.alvo_interacao, objeto)
	await wait_for_signal(objeto.interagido, 10)
	assert_signal_emitted(objeto, "interagido")
	assert_true(objeto.ao_alcance(personagem.global_position))


func test_tocar_de_perto_interage_na_hora() -> void:
	personagem.global_position = _perto_do_objeto()
	watch_signals(objeto)
	personagem.tocar(objeto.global_position)
	assert_signal_emitted(objeto, "interagido")
	assert_false(personagem.andando)


func test_destaque_aparece_so_ao_alcance() -> void:
	await wait_process_frames(2)
	assert_false(objeto.destacado)
	personagem.global_position = _perto_do_objeto()
	await wait_process_frames(2)
	assert_true(objeto.destacado)


func test_interagir_abre_a_caixa_de_dialogo() -> void:
	TranslationServer.set_locale("pt_BR")
	objeto.interagir()
	await wait_process_frames(3)
	var caixas := _caixas_abertas()
	assert_eq(caixas.size(), 1)
	var caixa := caixas[0] as CaixaDialogo
	assert_eq(caixa.dialogue_line.static_id, "EXPLORACAO_TESTE_001")
	assert_string_starts_with(caixa.dialogue_line.text, "[Provisório]")


func test_personagem_de_teste_tem_nome_e_retrato_provisorio() -> void:
	var outro: Interagivel = sala.get_node("PersonagemTeste/Interagivel")
	var fala: DialogueLine = await outro.dialogo.get_next_dialogue_line(outro.marcador)
	assert_eq(fala.character, "Personagem de teste")
	assert_not_null(Elenco.buscar(fala.character), "o personagem precisa estar no Elenco")


func test_personagem_fica_parado_durante_a_conversa() -> void:
	objeto.interagir()
	await wait_process_frames(3)
	assert_true(personagem.em_dialogo)
	var antes := personagem.global_position
	Input.action_press(&"mover_frente")
	await wait_physics_frames(5)
	Input.action_release(&"mover_frente")
	assert_eq(personagem.global_position, antes)
	personagem.tocar(antes) # chamada direta ainda funciona; o bloqueio é na entrada
	var toque := InputEventScreenTouch.new()
	toque.pressed = true
	toque.position = Vector2(100, 100)
	personagem.andando = false
	personagem._unhandled_input(toque)
	assert_false(personagem.andando, "toque não deve mover o personagem com a caixa aberta")


func test_personagem_volta_a_andar_quando_a_conversa_acaba() -> void:
	objeto.interagir()
	await wait_process_frames(3)
	DialogueManager.dialogue_ended.emit(objeto.dialogo)
	await wait_seconds(0.3)
	assert_false(personagem.em_dialogo)


func _apertar_e() -> void:
	var tecla := InputEventAction.new()
	tecla.action = "interagir"
	tecla.pressed = true
	Input.parse_input_event(tecla)
	await wait_process_frames(2)


func test_e_interage_com_o_que_esta_perto() -> void:
	personagem.global_position = _perto_do_objeto()
	watch_signals(objeto)
	await _apertar_e()
	assert_signal_emitted(objeto, "interagido")


func test_e_longe_de_tudo_nao_faz_nada() -> void:
	watch_signals(objeto)
	await _apertar_e()
	assert_signal_not_emitted(objeto, "interagido")
	assert_null(personagem.interagivel_ao_alcance())
