extends GutTest
## Tela do mapa: Nicholas anda entre os locais por toque, setas e Enter;
## névoa sobre o que não foi descoberto; dia e noite.

var mapa: MapaHelade


func before_each() -> void:
	TranslationServer.set_locale("pt_BR")
	Mundo.limpar()
	mapa = add_child_autofree(load("res://scenes/mapa/mapa_helade.tscn").instantiate())
	mapa.trocar_de_cena = false
	await wait_process_frames(2)


func after_each() -> void:
	Mundo.limpar()


func _descobrir_tudo() -> void:
	for id: String in mapa.grafo.locais:
		Mundo.descobrir(id)


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
	_descobrir_tudo()
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
	_descobrir_tudo()
	mapa.velocidade = 2000.0
	mapa.viajar_para("atenas")
	await wait_for_signal(mapa.chegou, 3)
	assert_eq(mapa.local_atual, "atenas")


func test_tocar_num_local_vai_ate_ele() -> void:
	_tocar_no_local("og_estrada_1")
	assert_true(mapa.andando)
	mapa.terminar_viagem()
	assert_eq(mapa.local_atual, "og_estrada_1")


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
	_descobrir_tudo()
	mapa.colocar_em("atenas")
	_apertar(&"mover_frente")
	mapa.terminar_viagem()
	assert_eq(mapa.local_atual, "an_estrada_1")


func test_nao_entra_andando() -> void:
	watch_signals(mapa)
	mapa.viajar_para("og_estrada_1")
	mapa.entrar()
	assert_signal_not_emitted(mapa, "entrada_pedida")


func test_local_na_nevoa_nao_e_destino() -> void:
	assert_false(Mundo.foi_descoberto("norte"))
	assert_false(mapa.viajar_para("norte"))
	assert_eq(mapa.local_em(mapa.grafo.local("atenas").posicao), "", "não dá para tocar no que está na névoa")
	assert_eq(mapa.local_atual, "olympia")


func test_nomes_das_regioes_escritos_no_mapa() -> void:
	_descobrir_tudo()
	var rotulos := mapa.get_node("Rotulos")
	for id in ["olympia", "atenas", "agape", "norte", "templo", "floresta_ninfas"]:
		var nome: Label = rotulos.get_node("Nome_" + id)
		assert_eq(tr(nome.text), tr(mapa.grafo.local(id).chave_nome))
	assert_null(rotulos.get_node_or_null("Nome_oa_acampamento"), "etapas não ganham nome no mapa")


func test_nome_acompanha_a_camera() -> void:
	var nome: Label = mapa.get_node("Rotulos/Nome_olympia")
	await wait_process_frames(2)
	var esperado: Vector2 = mapa.get_canvas_transform() * (mapa.grafo.local("olympia").posicao + Vector2(0, MapaHelade.DESCIDA_NOME))
	assert_almost_eq(nome.position.x + nome.size.x * 0.5, esperado.x, 1.0)
	assert_almost_eq(nome.position.y, esperado.y, 1.0)


func test_jogo_novo_mostra_so_olympia_e_os_vizinhos() -> void:
	assert_true(Mundo.foi_descoberto("olympia"))
	for vizinho in mapa.grafo.vizinhos("olympia"):
		assert_true(Mundo.foi_descoberto(vizinho), vizinho)
	assert_false(Mundo.foi_descoberto("atenas"))
	assert_false(mapa.get_node("Rotulos/Nome_atenas").visible)


func test_nevoa_cobre_o_que_nao_foi_descoberto() -> void:
	assert_lt(mapa.nevoa.densidade_em(mapa.grafo.local("olympia").posicao), 0.1)
	assert_gt(mapa.nevoa.densidade_em(mapa.grafo.local("norte").posicao), 0.9)


func test_chegar_num_lugar_descobre_os_vizinhos() -> void:
	mapa.viajar_para("oa_estrada_1")
	mapa.terminar_viagem()
	assert_true(Mundo.foi_descoberto("oa_estrada_2"))
	assert_false(Mundo.foi_descoberto("oa_acampamento"))
	assert_lt(mapa.nevoa.densidade_em(mapa.grafo.local("oa_estrada_2").posicao), 0.1)
	for proximo in ["oa_estrada_2", "oa_acampamento", "oa_estrada_3", "oa_estrada_4"]:
		mapa.viajar_para(proximo)
		mapa.terminar_viagem()
	assert_true(Mundo.foi_descoberto("atenas"))
	assert_true(mapa.get_node("Rotulos/Nome_atenas").visible)


func test_lugar_no_mapa_fica_guardado() -> void:
	mapa.viajar_para("og_estrada_1")
	mapa.terminar_viagem()
	assert_eq(Mundo.local_no_mapa, "og_estrada_1")
	var outro: MapaHelade = add_child_autofree(load("res://scenes/mapa/mapa_helade.tscn").instantiate())
	await wait_process_frames(1)
	assert_eq(outro.local_atual, "og_estrada_1")


func test_noite_troca_a_arte_e_acende_as_lamparinas() -> void:
	assert_false(mapa.fundo_noite.visible)
	assert_eq(mapa.lamparinas.acesas, 0.0)
	assert_false(mapa.lamparinas.visiveis().is_empty(), "estradas abertas têm postes")
	mapa.botao_periodo.pressed.emit()
	assert_true(Mundo.noite)
	await wait_seconds(MapaHelade.TROCA_PERIODO + 0.2)
	assert_true(mapa.fundo_noite.visible)
	assert_eq(mapa.fundo_noite.modulate.a, 1.0)
	assert_eq(mapa.lamparinas.acesas, 1.0)
	Mundo.definir_noite(false)
	await wait_seconds(MapaHelade.TROCA_PERIODO + 0.2)
	assert_false(mapa.fundo_noite.visible)


func test_mapa_abre_de_noite_se_ja_for_noite() -> void:
	Mundo.definir_noite(true)
	var outro: MapaHelade = add_child_autofree(load("res://scenes/mapa/mapa_helade.tscn").instantiate())
	await wait_process_frames(1)
	assert_eq(outro.fundo_noite.modulate.a, 1.0)


func test_lamparinas_so_nas_estradas_abertas() -> void:
	var antes := mapa.lamparinas.visiveis().size()
	_descobrir_tudo()
	assert_gt(mapa.lamparinas.visiveis().size(), antes)


func test_explorar_tudo_tira_toda_a_nevoa() -> void:
	_descobrir_tudo()
	assert_eq(mapa.nevoa.fracao_coberta(), 0.0)


func test_no_mar_vai_de_barco() -> void:
	if mapa.quadros_barco == null:
		pending("arte do barquinho ainda não ligada na cena")
		return
	_descobrir_tudo()
	mapa.colocar_em("porto_olympia")
	mapa.viajar_para("mo_mar_1")
	await wait_process_frames(2)
	assert_true(mapa.esta_de_barco())
	assert_eq(String(mapa.nicholas.animation).begins_with("barco"), true)
	mapa.terminar_viagem()
	assert_true(mapa.esta_de_barco(), "parado no mar continua no barco")
	mapa.viajar_para("porto_olympia")
	mapa.terminar_viagem()
	assert_false(mapa.esta_de_barco())
	assert_eq(String(mapa.nicholas.animation), "parado_frente")
