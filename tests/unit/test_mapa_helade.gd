extends GutTest
## Tela do mapa: Nicholas anda entre os locais por toque, setas e Enter.

var mapa: MapaHelade


func before_each() -> void:
	TranslationServer.set_locale("pt_BR")
	mapa = add_child_autofree(load("res://scenes/mapa/mapa_helade.tscn").instantiate())
	mapa.trocar_de_cena = false
	await wait_process_frames(2)


func _tocar_no_local(id: String) -> void:
	var tela: Vector2 = mapa.get_canvas_transform() * mapa.grafo.local(id).posicao
	var evento := InputEventScreenTouch.new()
	evento.position = tela
	evento.pressed = true
	mapa._unhandled_input(evento)


func _apertar(acao: StringName) -> void:
	var evento := InputEventAction.new()
	evento.action = acao
	evento.pressed = true
	mapa._unhandled_input(evento)


func test_comeca_em_olympia_com_a_placa() -> void:
	assert_eq(mapa.local_atual, "olympia")
	assert_eq(mapa.nicholas.position, mapa.grafo.local("olympia").posicao)
	assert_true(mapa.placa.visible)
	assert_eq(mapa.nome_local.text, "Olympia")


func test_viajar_passa_pelos_locais_e_chega() -> void:
	watch_signals(mapa)
	assert_true(mapa.viajar_para("norte"))
	assert_true(mapa.andando)
	assert_false(mapa.placa.visible)
	mapa.terminar_viagem()
	assert_eq(mapa.local_atual, "norte")
	assert_false(mapa.andando)
	assert_eq(mapa.nicholas.position, mapa.grafo.local("norte").posicao)
	assert_signal_emitted_with_parameters(mapa, "chegou", ["norte"])
	assert_eq(mapa.nome_local.text, "Norte")


func test_anda_de_verdade_com_o_tempo() -> void:
	mapa.velocidade = 2000.0
	mapa.viajar_para("atenas")
	await wait_for_signal(mapa.chegou, 3)
	assert_eq(mapa.local_atual, "atenas")


func test_tocar_num_local_vai_ate_ele() -> void:
	_tocar_no_local("agape")
	assert_true(mapa.andando)
	mapa.terminar_viagem()
	assert_eq(mapa.local_atual, "agape")


func test_tocar_no_local_atual_entra() -> void:
	watch_signals(mapa)
	_tocar_no_local("olympia")
	assert_signal_emitted_with_parameters(mapa, "entrada_pedida", ["olympia"])


func test_enter_entra_e_avisa_sem_cena() -> void:
	watch_signals(mapa)
	_apertar(&"interagir")
	assert_signal_emitted_with_parameters(mapa, "entrada_pedida", ["olympia"])
	assert_eq(mapa.aviso.text, tr("MAPA_SEM_CENA"))


func test_botao_entrar_e_grande() -> void:
	assert_gte(mapa.botao_entrar.size.y, 64.0)
	assert_eq(tr(mapa.botao_entrar.text), "Entrar")


func test_seta_para_cima_vai_ao_vizinho_de_cima() -> void:
	mapa.colocar_em("atenas")
	_apertar(&"mover_frente")
	mapa.terminar_viagem()
	assert_eq(mapa.local_atual, "an_estrada")


func test_nao_entra_andando() -> void:
	watch_signals(mapa)
	mapa.viajar_para("atenas")
	mapa.entrar()
	assert_signal_not_emitted(mapa, "entrada_pedida")


func test_local_bloqueado_nao_e_destino() -> void:
	mapa.liberados.erase("norte")
	assert_false(mapa.viajar_para("norte"))
	assert_eq(mapa.local_atual, "olympia")
