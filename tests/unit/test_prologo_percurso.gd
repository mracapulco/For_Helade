extends GutTest
## Percurso do prólogo: da cama à porta dos aposentos, andando ou pelo toque.

const CENA := preload("res://scenes/prologo/prologo.tscn")

var cena: ControlePrimeiraPessoa


func before_each() -> void:
	cena = CENA.instantiate()
	cena.abertura = null # sem a animação dos olhos, para o teste ser rápido
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
	await wait_physics_frames(5)
	var chao := cena.corpo.global_position.y
	Input.action_press("pular")
	await wait_physics_frames(1)
	Input.action_release("pular")
	await wait_physics_frames(10)
	assert_gt(cena.corpo.global_position.y, chao + 0.1)
	await wait_seconds(1.2)
	assert_almost_eq(cena.corpo.global_position.y, chao, 0.02)
