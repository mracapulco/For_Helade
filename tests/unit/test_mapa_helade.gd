extends GutTest
## Tela do mapa: Nicholas anda entre os locais por toque, setas e E;
## névoa sobre o que não foi descoberto; dia e noite.

const FasesHistoria := preload("res://scripts/systems/fases_historia.gd")
const AparenciaNicholas := preload("res://scripts/systems/aparencia_nicholas.gd")

var mapa: MapaHelade


func before_each() -> void:
	TranslationServer.set_locale("pt_BR")
	Mundo.limpar()
	Inventario.limpar()
	Progresso.etapa = ""
	mapa = add_child_autofree(load("res://scenes/mapa/mapa_helade.tscn").instantiate())
	mapa.trocar_de_cena = false
	await wait_process_frames(2)


func after_each() -> void:
	Mundo.limpar()
	Progresso.etapa = ""
	Inventario.limpar()


## Abre o mapa de novo, como depois do prólogo (etapa capitulo_1).
func _abrir_na_fase(etapa := "capitulo_1") -> void:
	mapa.queue_free()
	Mundo.limpar()
	Progresso.etapa = etapa
	mapa = add_child_autofree(load("res://scenes/mapa/mapa_helade.tscn").instantiate())
	mapa.trocar_de_cena = false
	await wait_process_frames(2)


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


func test_e_entra_e_avisa_sem_cena() -> void:
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


func test_nicholas_menor_no_mapa_sem_mudar_a_camera() -> void:
	assert_almost_eq(mapa.nicholas.scale.x, MapaHelade.ESCALA_NICHOLAS, 0.001)
	var camera := mapa.nicholas.get_node("Camera") as Camera2D
	assert_almost_eq(camera.global_scale.x, 1.0, 0.001, "a câmera não aproxima nem afasta")


func test_musica_do_mapa_troca_com_o_periodo() -> void:
	assert_eq(Trilha.atual, MapaHelade.MUSICA_DIA, "de dia toca a do dia")
	Mundo.definir_noite(true)
	assert_eq(Trilha.atual, MapaHelade.MUSICA_NOITE, "de noite toca a da noite")
	for caminho: String in [MapaHelade.MUSICA_DIA, MapaHelade.MUSICA_NOITE]:
		var musica: AudioStreamWAV = load(caminho)
		assert_eq(musica.loop_mode, AudioStreamWAV.LOOP_FORWARD, caminho)


func test_anda_a_70_por_cento_da_velocidade_antiga() -> void:
	assert_almost_eq(mapa.velocidade, 120.0 * 0.7, 0.01)


func test_depois_do_prologo_comeca_em_atenas() -> void:
	await _abrir_na_fase()
	assert_true(mapa.preso_na_fase())
	assert_eq(mapa.local_atual, "atenas")
	assert_eq(Mundo.local_no_mapa, "atenas")
	assert_true(Mundo.foi_descoberto("atenas"))
	assert_eq(mapa.nome_local.text, "Atenas")


func test_na_fase_nao_anda_pelo_mapa() -> void:
	await _abrir_na_fase()
	_descobrir_tudo()
	assert_false(mapa.viajar_para("an_estrada_1"))
	_apertar(&"mover_frente")
	_tocar_no_local("ag_estrada_1")
	assert_false(mapa.andando)
	assert_eq(mapa.local_atual, "atenas")


func test_na_fase_e_abre_a_cidade() -> void:
	await _abrir_na_fase()
	watch_signals(mapa)
	_apertar(&"interagir")
	assert_signal_emitted_with_parameters(mapa, "entrada_pedida", ["atenas"])
	var cena: String = FasesHistoria.da_etapa("capitulo_1").cena
	if ResourceLoader.exists(cena):
		assert_eq(mapa.cena_ao_entrar("atenas"), cena)
		assert_eq(mapa.aviso.text, "")
	else:
		assert_eq(mapa.aviso.text, tr("MAPA_SEM_CENA"), "sem a cena do capítulo, só avisa")


func test_continuar_num_acampamento_volta_para_a_fase() -> void:
	Mundo.limpar()
	Progresso.etapa = "capitulo_1"
	Mundo.local_no_mapa = "og_acampamento"
	Mundo.descobrir("og_acampamento")
	mapa.queue_free()
	mapa = add_child_autofree(load("res://scenes/mapa/mapa_helade.tscn").instantiate())
	mapa.trocar_de_cena = false
	await wait_process_frames(2)
	assert_eq(mapa.local_atual, "atenas")


func test_etapa_sem_fase_deixa_o_mapa_livre() -> void:
	await _abrir_na_fase("etapa_sem_fase")
	assert_false(mapa.preso_na_fase())
	assert_eq(mapa.local_atual, "olympia")


func test_no_comeco_do_jogo_nicholas_e_crianca_no_mapa() -> void:
	await _abrir_na_fase()
	assert_eq(mapa.nicholas.sprite_frames, AparenciaNicholas.quadros(Inventario.FaixaEtaria.CRIANCA),
		"no Capítulo 01 ele tem 11 anos")
	assert_ne(mapa.nicholas.sprite_frames, AparenciaNicholas.quadros(Inventario.FaixaEtaria.ADULTO))


func test_nicholas_no_mapa_cresce_com_a_idade() -> void:
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADOLESCENTE)
	assert_eq(mapa.nicholas.sprite_frames, AparenciaNicholas.quadros(Inventario.FaixaEtaria.ADOLESCENTE))
	assert_true(mapa.nicholas.is_playing())
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADULTO)
	assert_eq(mapa.nicholas.sprite_frames, AparenciaNicholas.quadros(Inventario.FaixaEtaria.ADULTO))


func test_mapa_aberto_ja_adulto_mostra_o_adulto() -> void:
	mapa.queue_free()
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADULTO)
	mapa = add_child_autofree(load("res://scenes/mapa/mapa_helade.tscn").instantiate())
	mapa.trocar_de_cena = false
	await wait_process_frames(2)
	assert_eq(mapa.nicholas.sprite_frames, AparenciaNicholas.quadros(Inventario.FaixaEtaria.ADULTO))


func test_pousada_pergunta_descansar_ou_missao() -> void:
	_descobrir_tudo()
	mapa.colocar_em("oa_acampamento")
	assert_eq(mapa.nome_local.text, "Pousada")
	_apertar(&"interagir")
	assert_true(mapa.escolhendo)
	assert_false(mapa.botao_entrar.visible)
	assert_true(mapa.botao_descansar.visible and mapa.botao_missao.visible and mapa.botao_voltar.visible)
	assert_eq(mapa.cena_pedida, "", "ainda não saiu do mapa")


func test_pousada_descansar_abre_o_patio() -> void:
	_descobrir_tudo()
	mapa.colocar_em("oa_acampamento")
	mapa.entrar()
	_apertar(&"interagir") # Descansar começa selecionado
	assert_false(mapa.escolhendo)
	assert_eq(mapa.cena_pedida, mapa.grafo.local("oa_acampamento").cena)


func test_pousada_missao_avisa_enquanto_nao_existe() -> void:
	_descobrir_tudo()
	mapa.colocar_em("oa_acampamento")
	mapa.entrar()
	_apertar(&"mover_tras")
	assert_eq(get_viewport().gui_get_focus_owner(), mapa.botao_missao)
	_apertar(&"interagir")
	if ResourceLoader.exists(mapa.grafo.local("oa_acampamento").cena_missao):
		assert_eq(mapa.cena_pedida, mapa.grafo.local("oa_acampamento").cena_missao)
	else:
		assert_eq(mapa.aviso.text, tr("MAPA_MISSAO_EM_BREVE"))
		assert_eq(mapa.cena_pedida, "")


func test_pousada_esc_fecha_a_escolha() -> void:
	_descobrir_tudo()
	mapa.colocar_em("oa_acampamento")
	mapa.entrar()
	_apertar(&"ui_cancel")
	assert_false(mapa.escolhendo)
	assert_true(mapa.botao_entrar.visible)


func test_so_a_pousada_e_desenhada_como_predio() -> void:
	for id: String in mapa.grafo.locais:
		assert_eq(mapa.grafo.local(id).construcao, id == "oa_acampamento", id)
