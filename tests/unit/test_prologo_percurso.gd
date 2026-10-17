extends GutTest
## Percurso do prólogo: da cama à porta dos aposentos, andando ou pelo toque.

const CENA := preload("res://scenes/prologo/prologo.tscn")

var cena: ControlePrimeiraPessoa


func before_each() -> void:
	cena = CENA.instantiate()
	cena.abertura = null # sem a animação dos olhos, para o teste ser rápido
	cena.roteiro = null # sem texto; o roteiro tem testes próprios abaixo
	cena.duracao_movimento = 0.2
	add_child_autofree(cena)
	await wait_physics_frames(2)


func _ponto(nome: String) -> PontoDeVista:
	return cena.get_node("Pontos/" + nome)


func _tocar_proximo() -> void:
	var alvo: AlvoToque = cena.ponto_atual.alvos()[0]
	alvo.tocado.emit(alvo)
	await wait_seconds(0.4)


func test_comeca_na_cama_com_so_o_primeiro_brilho_ativo() -> void:
	assert_eq(cena.ponto_atual, _ponto("Cama"))
	assert_true(_ponto("Cama").alvos()[0].ativo)
	assert_false(_ponto("PortaQuarto").alvos()[0].ativo)


func test_tocar_nos_brilhos_percorre_os_pontos_em_ordem() -> void:
	watch_signals(cena)
	await _tocar_proximo()
	await _tocar_proximo()
	await _tocar_proximo()
	assert_signal_emit_count(cena, "chegou", 3)
	assert_eq(cena.ponto_atual, _ponto("PortaAposentos"))
	assert_almost_eq(cena.camera.global_position, _ponto("PortaAposentos").global_position, Vector3.ONE * 0.01)


func test_toque_em_brilho_de_outro_ponto_e_ignorado() -> void:
	var alvo: AlvoToque = _ponto("Corredor").alvos()[0]
	alvo.tocado.emit(alvo)
	await wait_seconds(0.3)
	assert_eq(cena.ponto_atual, _ponto("Cama"))


func test_andar_ate_o_ponto_tambem_avanca() -> void:
	# Simula ter andado até a porta do quarto.
	cena.corpo.global_position = cena._posicao_do_corpo(_ponto("PortaQuarto")) + Vector3(-0.3, 0, 0)
	await wait_physics_frames(3)
	assert_eq(cena.ponto_atual, _ponto("PortaQuarto"))
	assert_true(_ponto("PortaQuarto").alvos()[0].ativo)
	assert_false(_ponto("Cama").alvos()[0].ativo)


func test_travado_nao_avanca_andando() -> void:
	cena.travado = true
	cena.corpo.global_position = cena._posicao_do_corpo(_ponto("PortaQuarto"))
	await wait_physics_frames(3)
	assert_eq(cena.ponto_atual, _ponto("Cama"))


func test_mira_no_brilho_encontra_o_alvo() -> void:
	var alvo: AlvoToque = _ponto("Cama").alvos()[0]
	cena.camera.look_at(alvo.global_position)
	await wait_physics_frames(2)
	assert_eq(cena._alvo_na_mira(), alvo)
	cena.camera.rotation.x = deg_to_rad(-60) # olhando para o chão
	await wait_physics_frames(2)
	assert_null(cena._alvo_na_mira())


func test_shift_corre_mais_rapido_que_andar() -> void:
	var inicio := cena.corpo.global_position
	Input.action_press("mover_frente")
	await wait_physics_frames(20)
	var andando := cena.corpo.global_position.distance_to(inicio)
	inicio = cena.corpo.global_position
	Input.action_press("correr")
	await wait_physics_frames(20)
	var correndo := cena.corpo.global_position.distance_to(inicio)
	Input.action_release("correr")
	Input.action_release("mover_frente")
	assert_gt(correndo, andando * 1.5)


func test_espaco_pula_e_volta_ao_chao() -> void:
	Input.action_release("pular") # outro teste pode ter deixado a tecla "apertada"
	await wait_physics_frames(5)
	var chao := cena.corpo.global_position.y
	Input.action_press("pular")
	await wait_physics_frames(1)
	Input.action_release("pular")
	await wait_physics_frames(10)
	assert_gt(cena.corpo.global_position.y, chao + 0.1)
	await wait_seconds(1.2)
	assert_almost_eq(cena.corpo.global_position.y, chao, 0.02)


func _todos_os_pontos() -> Array:
	return cena.get_node("Pontos").get_children()


func test_roteiro_tem_todos_os_trechos_usados_na_cena() -> void:
	var roteiro: DialogueResource = load("res://data/dialogos/prologo/prologo.dialogue")
	assert_has(roteiro.get_cues(), "abertura")
	for ponto: PontoDeVista in _todos_os_pontos():
		if not ponto.cena_ao_chegar.is_empty():
			assert_has(roteiro.get_cues(), ponto.cena_ao_chegar, "trecho de " + ponto.name)


func test_frases_nao_travam_nicholas_e_cada_trecho_aparece_uma_vez() -> void:
	var outra: ControlePrimeiraPessoa = CENA.instantiate()
	outra.abertura = null
	var frases: TextoSolto = outra.texto_solto
	frases.tempo_fade = 0.05
	frases.tempo_minimo = 0.1
	frases.tempo_por_letra = 0.0
	add_child_autofree(outra)
	await wait_physics_frames(2)
	assert_eq(outra.cena_tocando, "abertura")
	assert_true(outra.travado, "na tela preta, antes de abrir os olhos")
	await wait_until(func() -> bool: return outra.cena_tocando != "abertura", 3.0)
	assert_eq(outra.cena_tocando, "acordar", "ao abrir os olhos, na cama")
	assert_false(outra.travado, "as frases não travam Nicholas")
	assert_true(_ponto_de(outra, "Cama").alvos()[0].ativo)
	await wait_until(func() -> bool: return outra.cena_tocando.is_empty(), 3.0)
	assert_eq(outra.cena_tocando, "")
	outra.tocar_cena("acordar")
	assert_eq(outra.cena_tocando, "", "trecho já visto não repete")


func _ponto_de(no: Node, nome: String) -> PontoDeVista:
	return no.get_node("Pontos/" + nome)


func test_e_com_a_mira_no_brilho_vai_ate_ele() -> void:
	var alvo: AlvoToque = _ponto("Cama").alvos()[0]
	cena.camera.look_at(alvo.global_position)
	await wait_physics_frames(2)
	var tecla_e := InputEventAction.new()
	tecla_e.action = "interagir"
	tecla_e.pressed = true
	cena._unhandled_input(tecla_e)
	await wait_seconds(0.4)
	assert_eq(cena.ponto_atual, _ponto("PortaQuarto"))


func _de_frente_para_a_cama() -> void:
	# No chão, ao lado da cama (x -3,8..-2,6), olhando para ela.
	cena.corpo.global_position = Vector3(-2.1, 0.0, 2.3)
	cena.corpo.rotation.y = PI / 2.0
	Input.action_release("pular")
	await wait_physics_frames(5)


func test_cama_e_solida() -> void:
	await _de_frente_para_a_cama()
	Input.action_press("mover_frente")
	await wait_physics_frames(60)
	Input.action_release("mover_frente")
	assert_gt(cena.corpo.global_position.x, -2.65, "não entra na cama")
	assert_lt(cena.corpo.global_position.y, 0.05)


func test_pula_em_cima_da_cama() -> void:
	await _de_frente_para_a_cama()
	Input.action_press("mover_frente")
	await wait_physics_frames(10)
	Input.action_press("pular")
	await wait_physics_frames(1)
	Input.action_release("pular")
	await wait_physics_frames(50)
	Input.action_release("mover_frente")
	await wait_physics_frames(20)
	assert_lt(cena.corpo.global_position.x, -2.65, "subiu na cama")
	assert_almost_eq(cena.corpo.global_position.y, 0.36, 0.03, "em cima do colchão")


func test_acorda_em_pe_sobre_a_cama() -> void:
	await wait_physics_frames(10)
	assert_almost_eq(cena.corpo.global_position.y, 0.36, 0.03)
