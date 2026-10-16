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


func test_comeca_na_cama_com_so_a_primeira_passagem_ativa() -> void:
	assert_eq(cena.ponto_atual, _ponto("Cama"))
	assert_true(_ponto("Cama").alvos()[0].ativo)
	assert_false(_ponto("PortaQuarto").alvos()[0].ativo)


func test_tocar_nas_passagens_percorre_os_pontos_em_ordem() -> void:
	watch_signals(cena)
	await _tocar_proximo()
	await _tocar_proximo()
	await _tocar_proximo()
	assert_signal_emit_count(cena, "chegou", 3)
	assert_eq(cena.ponto_atual, _ponto("PortaAposentos"))
	assert_almost_eq(cena.camera.global_position, _ponto("PortaAposentos").global_position, Vector3.ONE * 0.01)


func test_toque_em_passagem_de_outro_ponto_e_ignorado() -> void:
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


func test_mira_na_passagem_encontra_o_alvo() -> void:
	var alvo: AlvoToque = _ponto("Cama").alvos()[0]
	cena.camera.look_at(alvo.global_position)
	await wait_physics_frames(2)
	assert_eq(cena._alvo_na_mira(), alvo)
	cena.camera.rotation.x = deg_to_rad(-60) # olhando para o chão
	await wait_physics_frames(2)
	assert_null(cena._alvo_na_mira())


func test_shift_nao_corre_no_prologo() -> void:
	var inicio := cena.corpo.global_position
	Input.action_press("mover_frente")
	await wait_physics_frames(20)
	var andando := cena.corpo.global_position.distance_to(inicio)
	inicio = cena.corpo.global_position
	Input.action_press("correr")
	await wait_physics_frames(20)
	var com_shift := cena.corpo.global_position.distance_to(inicio)
	Input.action_release("correr")
	Input.action_release("mover_frente")
	assert_gt(andando, 0.1)
	assert_almost_eq(com_shift, andando, andando * 0.15)


func test_shift_corre_depois_de_segurar_althea() -> void:
	cena.pode_correr = true
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
	var fonte := FileAccess.get_file_as_string("res://scripts/prologo/sequencia_prologo.gd")
	var liberar := fonte.find("controle.pode_correr = true")
	assert_between(liberar, fonte.find("await _esperar(\"segurar\")"), fonte.find("_mudar(\"depois\")"),
		"correr volta depois de segurar Althea")


func test_texto_dos_controles_some_e_nao_volta() -> void:
	assert_ne(cena.dica.text, "", "começa mostrando os controles")
	cena._sumir_dica_controles()
	await wait_seconds(1.2)
	assert_eq(cena.dica.text, "")
	assert_eq(cena.dica.modulate.a, 1.0)
	await _tocar_proximo()
	assert_eq(cena.dica.text, "", "não volta no ponto seguinte")


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


func test_enter_com_a_mira_na_passagem_vai_ate_ela() -> void:
	var alvo: AlvoToque = _ponto("Cama").alvos()[0]
	cena.camera.look_at(alvo.global_position)
	await wait_physics_frames(2)
	var enter := InputEventAction.new()
	enter.action = "interagir"
	enter.pressed = true
	cena._unhandled_input(enter)
	await wait_seconds(0.4)
	assert_eq(cena.ponto_atual, _ponto("PortaQuarto"))


## Ponta da cama de Nicholas (o lado dos pés, em x).
func _pe_da_cama() -> float:
	var cama: CSGBox3D = cena.get_node("Cenario/QuartoNicholas/Cama")
	return cama.global_position.x + cama.size.x / 2.0


func _de_frente_para_a_cama() -> void:
	# No chão, meio metro depois dos pés da cama, olhando para ela.
	var cama: CSGBox3D = cena.get_node("Cenario/QuartoNicholas/Cama")
	cena.corpo.global_position = Vector3(_pe_da_cama() + 0.5, 0.0, cama.global_position.z)
	cena.corpo.rotation.y = PI / 2.0
	Input.action_release("pular")
	await wait_physics_frames(5)


func test_cama_e_solida() -> void:
	await _de_frente_para_a_cama()
	Input.action_press("mover_frente")
	await wait_physics_frames(60)
	Input.action_release("mover_frente")
	assert_gt(cena.corpo.global_position.x, _pe_da_cama() - 0.05, "não entra na cama")
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
	assert_lt(cena.corpo.global_position.x, _pe_da_cama() - 0.05, "subiu na cama")
	assert_almost_eq(cena.corpo.global_position.y, 0.36, 0.03, "em cima do colchão")


func test_acorda_em_pe_sobre_a_cama() -> void:
	await wait_physics_frames(10)
	assert_almost_eq(cena.corpo.global_position.y, 0.36, 0.03)


func test_passagens_nao_tem_nada_desenhado() -> void:
	for ponto: PontoDeVista in _todos_os_pontos():
		for alvo in ponto.alvos():
			assert_eq(alvo.find_children("*", "MeshInstance3D").size(), 0, "círculo em " + alvo.name)


func test_varanda_comeca_ao_passar_pela_porta() -> void:
	cena.continuar_em(_ponto("QuartoVazio"))
	var varanda := _ponto("Varanda")
	assert_gt(varanda.raio_chegada, 1.0)
	# Logo depois do arco, ainda longe do ponto da varanda.
	cena.corpo.global_position = Vector3(varanda.global_position.x, 0.0, varanda.global_position.z - varanda.raio_chegada + 0.1)
	await wait_physics_frames(3)
	assert_eq(cena.ponto_atual, varanda)


func test_aposentos_comecam_ao_passar_pela_porta_mesmo_sem_parar_antes() -> void:
	# Do meio do corredor direto para dentro dos aposentos, sem passar perto
	# do ponto em frente à porta.
	cena.continuar_em(_ponto("Corredor"))
	var entrada := _ponto("Entrada")
	cena.corpo.global_position = Vector3(entrada.global_position.x, 0.0, entrada.global_position.z - entrada.raio_chegada + 0.1)
	await wait_physics_frames(3)
	assert_eq(cena.ponto_atual, entrada)


func test_portas_abertas_dos_aposentos_tem_colisao() -> void:
	var folhas := cena.get_node("Cenario/Aposentos").find_children("FolhaAberta*", "Node3D", false, false)
	assert_eq(folhas.size(), 2)
	for folha: Node3D in folhas:
		var corpo := folha.get_node("Folha") as CSGBox3D
		assert_not_null(corpo, "a folha da porta precisa ser sólida")
		assert_true(corpo.use_collision)


func test_ctrl_agacha_enquanto_segurado_e_levanta_ao_soltar() -> void:
	var em_pe := cena.camera.position.y
	Input.action_press("agachar")
	await wait_physics_frames(30)
	assert_almost_eq(cena.agachamento, 1.0, 0.01)
	assert_almost_eq(cena.camera.position.y, em_pe - cena.descida_agachado, 0.01, "os olhos descem")
	var corpo: CorpoNicholas = cena.get_node("Nicholas/CorpoNicholas")
	await wait_frames(20)
	assert_lt(corpo.quadril.position.y, 0.4, "o quadril desce com as pernas dobradas")
	Input.action_press("pular")
	await wait_physics_frames(3)
	Input.action_release("pular")
	assert_almost_eq(cena.corpo.velocity.y, 0.0, 0.01, "agachado não pula")
	Input.action_release("agachar")
	await wait_physics_frames(30)
	assert_almost_eq(cena.agachamento, 0.0, 0.01)
	assert_almost_eq(cena.camera.position.y, em_pe, 0.01, "levanta ao soltar")


func test_agachado_nao_levanta_debaixo_de_algo_baixo() -> void:
	Input.action_press("agachar")
	await wait_physics_frames(30)
	var teto := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(2.0, 0.1, 2.0)
	forma.shape = caixa
	teto.add_child(forma)
	add_child_autofree(teto)
	teto.global_position = cena.corpo.global_position + Vector3(0.0, 1.0, 0.0)
	await wait_physics_frames(2)
	Input.action_release("agachar")
	await wait_physics_frames(30)
	assert_gt(cena.agachamento, 0.9, "fica agachado enquanto há algo em cima")
	teto.queue_free()
	await wait_physics_frames(30)
	assert_almost_eq(cena.agachamento, 0.0, 0.01)
