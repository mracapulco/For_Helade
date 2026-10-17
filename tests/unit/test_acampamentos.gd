extends GutTest
## Acampamentos: as nove cenas abrem, têm barraca, mercador, companheiro e
## saída ao alcance, a barraca salva e a saída volta ao mapa.

const PASTA := "res://scenes/exploracao/acampamentos/%s.tscn"
const IDS := [
	"oa_acampamento", "ot_acampamento", "og_acampamento", "ag_acampamento",
	"an_acampamento", "nt_acampamento", "at_acampamento",
	"ilha_acampamento", "ilhota_acampamento",
]
const AparenciaNicholas := preload("res://scripts/systems/aparencia_nicholas.gd")
const INTERAGIVEIS := ["Barraca", "Mercador", "Companheiro", "Saida"]
## Pontos de barco: a saída é o barco, não a placa.
const DE_BARCO := ["ilha_acampamento", "ilhota_acampamento"]

var acampamento: Acampamento
var _pasta_progresso: String
var _etapa: String


func before_each() -> void:
	_pasta_progresso = Progresso.pasta
	_etapa = Progresso.etapa
	Progresso.pasta = "user://teste_saves_acampamento/"
	Progresso.apagar_todos()


func after_each() -> void:
	if is_instance_valid(acampamento):
		acampamento.free()
	await wait_process_frames(2)
	Progresso.apagar_todos()
	Progresso.pasta = _pasta_progresso
	Progresso.etapa = _etapa
	get_tree().paused = false
	Mundo.definir_noite(false)
	Mundo.local_no_mapa = ""
	Inventario.limpar()


func _abrir(id: String) -> Acampamento:
	acampamento = load(PASTA % id).instantiate()
	acampamento.trocar_de_cena = false
	add_child(acampamento)
	await wait_physics_frames(3)
	# O mapa de navegação atualiza em segundo plano; espera o acampamento
	# entrar nele (antes disso o ponto andável mais próximo é a origem).
	var mapa := _mapa_navegacao()
	var fogueira := acampamento.get_node("Fogueira").global_position as Vector2
	await wait_until(func() -> bool:
		return NavigationServer2D.map_get_closest_point(mapa, fogueira).distance_to(fogueira) < 40.0, 2.0)
	return acampamento


func _mapa_navegacao() -> RID:
	return (acampamento.get_node("Navegacao") as NavigationRegion2D).get_navigation_map()


func test_as_nove_cenas_existem() -> void:
	for id: String in IDS:
		assert_true(ResourceLoader.exists(PASTA % id), id)


func test_bioma_tem_o_mesmo_id_da_cena(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	assert_not_null(acampamento.bioma, id)
	assert_eq(acampamento.bioma.id, id)
	assert_not_null(acampamento.bioma.pisos, id)
	assert_false(acampamento.bioma.obstaculos.is_empty(), id)


func test_tem_barraca_mercador_companheiro_e_saida(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	for nome: String in INTERAGIVEIS:
		assert_is(acampamento.get_node_or_null(nome + "/Interagivel"), Interagivel, "%s: %s" % [id, nome])


func test_tudo_fica_ao_alcance_andando(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	var mapa := _mapa_navegacao()
	var inicio := acampamento.get_node("Personagem").global_position as Vector2
	for nome: String in INTERAGIVEIS:
		var alvo := acampamento.get_node(nome + "/Interagivel") as Interagivel
		var caminho := NavigationServer2D.map_get_path(mapa, inicio, alvo.global_position, true)
		assert_false(caminho.is_empty(), "%s: sem caminho até %s" % [id, nome])
		if caminho.is_empty():
			continue
		assert_true(alvo.ao_alcance(caminho[caminho.size() - 1]), "%s: %s fora de alcance" % [id, nome])


func test_companheiro_tem_fala_provisoria(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	var companheiro := acampamento.companheiro
	assert_has(companheiro.dialogo.get_cues(), companheiro.marcador, id)
	var fala: DialogueLine = await companheiro.dialogo.get_next_dialogue_line(companheiro.marcador)
	# Convidados (Rafael) têm falas próprias, não provisórias.
	if companheiro.marcador == "rafael":
		assert_eq(fala.character, "Próskopos")
	else:
		assert_string_contains(fala.text, "[Provisório]")
	if not fala.character.is_empty():
		assert_not_null(Elenco.buscar(fala.character), "%s precisa estar no Elenco" % fala.character)


func test_saida_e_placa_ou_barco(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	var cenario := acampamento.get_node("Cenario") as CenarioAcampamento
	assert_eq(cenario.saida_de_barco(), DE_BARCO.has(id), id)
	var visual := acampamento.get_node("Saida/Visual") as Sprite2D
	var esperado := cenario.textura_barco if DE_BARCO.has(id) else cenario.textura_placa
	assert_eq(visual.texture, esperado, id)


func test_mercador_oferece_as_mercadorias() -> void:
	await _abrir("oa_acampamento")
	TranslationServer.set_locale("pt_BR")
	var mercador := acampamento.mercador
	var fala: DialogueLine = await mercador.dialogo.get_next_dialogue_line(mercador.marcador)
	assert_eq(fala.character, "Mercador")
	assert_not_null(Elenco.buscar("Mercador"))
	assert_string_starts_with(fala.text, "[Provisório]")
	fala = await mercador.dialogo.get_next_dialogue_line(fala.next_id)
	var opcoes := fala.responses.map(func(r: DialogueResponse) -> String: return r.text)
	assert_has(opcoes, "Ver mercadorias")


func test_cada_acampamento_tem_loja(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	var loja := Lojas.loja(acampamento.bioma.loja)
	assert_not_null(loja, id)
	assert_eq(Lojas.loja_do_lugar, acampamento.bioma.loja, "o acampamento avisa qual é a loja")
	for item_id in Lojas.mercadorias(loja.id):
		var item := Inventario.item(item_id)
		assert_not_null(item, "%s em %s" % [item_id, loja.id])
		if item:
			assert_ne(item.origem, Item.Origem.BANDIDOS, "itens dos bandidos não se vendem")
			assert_true(item.origem == Item.Origem.NENHUMA or item.origem == loja.origem,
				"%s é de outro reino (%s)" % [item_id, loja.id])


func test_sair_do_acampamento_tira_a_loja_do_lugar() -> void:
	await _abrir("og_acampamento")
	acampamento.queue_free()
	await wait_process_frames(2)
	assert_eq(Lojas.loja_do_lugar, "")


func test_ver_mercadorias_abre_a_tela_e_espera_fechar() -> void:
	await _abrir("og_acampamento")
	var terminou := [false]
	var ver := func() -> void:
		await Lojas.ver_mercadorias()
		terminou[0] = true
	ver.call()
	assert_not_null(Lojas.tela)
	assert_true(Lojas.tela.aberta())
	assert_eq(Lojas.tela.id_loja, "acampamento_og")
	assert_false(terminou[0])
	Lojas.tela.fechar()
	await wait_process_frames(1)
	assert_true(terminou[0], "a conversa continua depois de fechar")
	assert_null(Lojas.tela)
	assert_false(get_tree().paused)


func test_barraca_abre_os_espacos_e_pausa() -> void:
	await _abrir("og_acampamento")
	acampamento.barraca.interagir()
	assert_true(acampamento.tela_espacos.aberta())
	assert_eq(acampamento.tela_espacos.modo, TelaEspacos.Modo.SALVAR)
	assert_true(get_tree().paused)
	acampamento.tela_espacos.fechar()
	assert_false(get_tree().paused)
	assert_false(Progresso.tem_jogo_salvo(), "fechar sem escolher não salva")


func test_barraca_salva_no_espaco_escolhido_sem_mudar_a_etapa() -> void:
	await _abrir("og_acampamento")
	Progresso.etapa = "etapa_de_teste"
	watch_signals(acampamento)
	acampamento.barraca.interagir()
	acampamento.tela_espacos.botoes[3].pressed.emit()
	assert_false(Progresso.espaco_ocupado(4), "tocar no espaço só seleciona")
	assert_eq(acampamento.tela_espacos.botao_acao.text, "ESPACOS_SALVAR")
	acampamento.tela_espacos.botao_acao.pressed.emit()
	assert_signal_emitted(acampamento, "salvo")
	assert_false(acampamento.tela_espacos.aberta())
	assert_false(get_tree().paused)
	assert_true(Progresso.espaco_ocupado(4))
	Progresso.etapa = ""
	assert_true(Progresso.carregar(4))
	assert_eq(Progresso.etapa, "etapa_de_teste")
	assert_eq(Mundo.local_no_mapa, "og_acampamento", "volta para este acampamento")


func test_barraca_pergunta_antes_de_salvar_por_cima() -> void:
	await _abrir("oa_acampamento")
	Progresso.salvar("capitulo_1", 2)
	var tela := acampamento.tela_espacos
	acampamento.barraca.interagir()
	tela.escolher(2)
	assert_true(tela.confirmacao.visible)
	assert_true(tela.botao_nao.has_focus(), "o seguro fica selecionado")
	tela.botao_nao.pressed.emit()
	assert_false(tela.confirmacao.visible)
	assert_true(tela.aberta())
	Progresso.etapa = "etapa_de_teste"
	tela.escolher(2)
	tela.botao_sim.pressed.emit()
	assert_eq(Progresso.resumo(2).etapa, "etapa_de_teste")
	assert_false(tela.aberta())


func test_barraca_mostra_aviso_de_salvo() -> void:
	await _abrir("oa_acampamento")
	TranslationServer.set_locale("pt_BR")
	acampamento.barraca.interagir()
	acampamento.tela_espacos.escolher(1)
	assert_has(acampamento.aviso.textos(), "Progresso salvo.")


func test_saida_volta_ao_mapa() -> void:
	await _abrir("an_acampamento")
	acampamento.saida.interagir()
	assert_eq(acampamento.cena_pedida, Acampamento.CENA_MAPA)
	assert_true(ResourceLoader.exists(Acampamento.CENA_MAPA))


func test_botao_volta_ao_mapa() -> void:
	await _abrir("ilha_acampamento")
	acampamento.botao_mapa.pressed.emit()
	assert_eq(acampamento.cena_pedida, Acampamento.CENA_MAPA)


func test_botao_do_mapa_e_grande_e_bloqueia_o_toque() -> void:
	await _abrir("oa_acampamento")
	var botao := acampamento.botao_mapa
	assert_gte(botao.custom_minimum_size.y, 64.0)
	assert_true(botao.is_in_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE))


func test_noite_acende_a_fogueira() -> void:
	await _abrir("nt_acampamento")
	assert_false(acampamento.luz_fogueira.enabled)
	Mundo.definir_noite(true)
	assert_true(acampamento.luz_fogueira.enabled)
	assert_eq(acampamento.ambiente.color, acampamento.bioma.cor_noite)


func test_agua_tem_colisao_e_saida_fica_fora_dela() -> void:
	await _abrir("ilhota_acampamento")
	var cenario := acampamento.get_node("Cenario") as CenarioAcampamento
	assert_eq(cenario.terreno(Vector2i(14, 7)), CenarioAcampamento.Terreno.AGUA)
	assert_eq(cenario.terreno(Vector2i(7, 7)), CenarioAcampamento.Terreno.CLAREIRA)
	var mapa := _mapa_navegacao()
	var agua := acampamento.get_node("Chao").to_global((acampamento.get_node("Chao") as TileMapLayer).map_to_local(Vector2i(7, 14))) as Vector2
	assert_gt(NavigationServer2D.map_get_closest_point(mapa, agua).distance_to(agua), 10.0,
		"não dá para andar na água")


const ANIMAIS := ["cao", "ovelha", "cabra", "burro", "coruja", "gaivota", "caranguejo"]
const COM_NEVE := ["an_acampamento", "nt_acampamento", "og_acampamento"]


func test_fogueira_tem_chama_animada() -> void:
	await _abrir("oa_acampamento")
	assert_eq(acampamento.fogo.hframes, Acampamento.QUADROS_FOGO)
	var antes := acampamento.fogo.frame
	await wait_seconds(Acampamento.TEMPO_QUADRO_FOGO * 2.5)
	assert_ne(acampamento.fogo.frame, antes, "a chama troca de quadro")
	assert_not_null(acampamento.som_fogueira.stream, "estalo da fogueira")


func test_cada_mercador_tem_roupa_propria_e_anima(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	assert_not_null(acampamento.bioma.mercador, id)
	assert_eq(acampamento.visual_mercador.texture, acampamento.bioma.mercador)
	assert_eq(acampamento.visual_mercador.hframes, Acampamento.QUADROS_MERCADOR)


func test_mercadores_com_roupas_diferentes() -> void:
	var roupas := {}
	for id: String in IDS:
		var bioma: BiomaAcampamento = load("res://data/acampamentos/%s.tres" % id)
		roupas[bioma.mercador.resource_path] = true
	assert_eq(roupas.size(), IDS.size())


func test_animal_faz_som_e_se_mexe(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	var marcador := acampamento.bioma.marcador_companheiro
	if not ANIMAIS.has(marcador):
		assert_null(acampamento.som_companheiro.stream, "%s: gente não faz som de bicho" % id)
		return
	assert_not_null(acampamento.som_companheiro.stream, "%s: som do %s" % [id, marcador])
	acampamento.companheiro.interagido.emit()
	assert_true(acampamento.som_companheiro.playing, id)
	await wait_seconds(0.15)
	var v := acampamento.visual_companheiro
	var mexeu := v.position != Vector2.ZERO or v.rotation != 0.0 or v.scale != Vector2.ONE or v.flip_h
	assert_true(mexeu, "%s: o %s se mexe" % [id, marcador])
	await wait_for_signal(acampamento._reacao.finished, 3)
	assert_eq(v.position, Vector2.ZERO, "volta ao lugar")
	assert_eq(v.rotation, 0.0)


func test_cada_animal_tem_som() -> void:
	for animal: String in ANIMAIS:
		assert_true(ResourceLoader.exists(Acampamento.PASTA_SONS_ANIMAIS + animal + ".wav"), animal)


func test_neve_so_nos_acampamentos_frios(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	if COM_NEVE.has(id):
		assert_not_null(acampamento.vida.neve, id)
		assert_true(acampamento.vida.neve.emitting, id)
	else:
		assert_null(acampamento.vida.neve, id)


func test_mata_tem_bichos_de_dia_e_vagalumes_de_noite() -> void:
	await _abrir("at_acampamento")
	var vida := acampamento.vida
	assert_true(vida.insetos.emitting)
	assert_true(vida.passaros.emitting)
	assert_false(vida.vagalumes.emitting)
	Mundo.definir_noite(true)
	assert_false(vida.insetos.emitting)
	assert_false(vida.passaros.emitting)
	assert_true(vida.vagalumes.emitting)


func test_falesias_perto_da_praia() -> void:
	await _abrir("ot_acampamento")
	var cenario := acampamento.get_node("Cenario") as CenarioAcampamento
	var falesias := cenario.get_children().filter(func(n: Node) -> bool: return n.name.begins_with("Falesia"))
	assert_gt(falesias.size(), 2, "falésias na cena")
	for lado in acampamento.bioma.lados_agua:
		for celula in cenario.celulas_de_falesia(lado):
			var distancia := CenarioAcampamento.distancia_ao_lado(celula, lado)
			assert_between(distancia, acampamento.bioma.largura_agua, acampamento.bioma.largura_agua + 1, "colada na praia")
	# O caminho até a água continua livre.
	var mapa := _mapa_navegacao()
	var chao := acampamento.get_node("Chao") as TileMapLayer
	var praia := chao.to_global(chao.map_to_local(Vector2i(acampamento.bioma.largura_agua, 7)))
	var inicio := acampamento.get_node("Personagem").global_position as Vector2
	var caminho := NavigationServer2D.map_get_path(mapa, inicio, praia, true)
	assert_lt(caminho[caminho.size() - 1].distance_to(praia), 20.0, "dá para chegar na praia")


func test_cada_acampamento_tem_sua_musica(id: String = use_parameters(IDS)) -> void:
	await _abrir(id)
	var caminho := Acampamento.PASTA_MUSICAS + id + ".wav"
	assert_eq(acampamento.musica_do_acampamento(), caminho)
	assert_true(ResourceLoader.exists(caminho), id)
	assert_eq(Trilha.atual, caminho, "%s: a Trilha toca a música do acampamento" % id)
	var tocador := Trilha.tocador_atual()
	assert_eq(tocador.bus, Trilha.BARRAMENTO)
	assert_eq((tocador.stream as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s: em loop" % id)


func test_anda_de_casa_em_casa_como_na_sala() -> void:
	await _abrir("oa_acampamento")
	var personagem := acampamento.get_node("Personagem") as PersonagemExploracao
	assert_eq(personagem.grade, acampamento.get_node("Chao"))
	var inicio := personagem.casa_de(personagem.global_position)
	assert_eq(personagem.global_position, personagem.centro_da_casa(inicio), "começa no centro de uma casa")
	Input.action_press("mover_tras")
	await wait_physics_frames(5)
	Input.action_release("mover_tras")
	await wait_seconds(1.0)
	assert_eq(personagem.casa_de(personagem.global_position), inicio + Vector2i(1, 0), "S anda uma casa")
	assert_eq(personagem.global_position, personagem.centro_da_casa(inicio + Vector2i(1, 0)))
	personagem.ir_para(personagem.global_position + Vector2(70, -20))
	await wait_for_signal(personagem.chegou, 5)
	var casa := personagem.casa_de(personagem.global_position)
	assert_eq(personagem.global_position, personagem.centro_da_casa(casa), "o toque também para no centro")


func test_nicholas_no_acampamento_tem_a_idade_da_historia() -> void:
	Inventario.limpar()
	await _abrir("oa_acampamento")
	var visual := acampamento.get_node("Personagem/Corpo/Visual") as AnimatedSprite2D
	assert_eq(visual.sprite_frames, AparenciaNicholas.quadros(Inventario.FaixaEtaria.CRIANCA),
		"no começo do jogo ele é criança")
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADULTO)
	assert_eq(visual.sprite_frames, AparenciaNicholas.quadros(Inventario.FaixaEtaria.ADULTO))


func test_desenho_sem_golpe_usa_o_de_interagir() -> void:
	Inventario.limpar()
	await _abrir("oa_acampamento")
	var personagem := acampamento.get_node("Personagem") as PersonagemExploracao
	var visual := acampamento.get_node("Personagem/Corpo/Visual") as AnimatedSprite2D
	personagem.golpeando = true
	visual._process(0.0)
	assert_true(String(visual.animation).begins_with("interagindo"))
	personagem.golpeando = false


func test_rafael_na_mata_costeira_e_shara_no_rio_de_agape() -> void:
	await _abrir("ot_acampamento")
	var companheiro := acampamento.get_node("Companheiro/Interagivel") as Interagivel
	assert_eq(companheiro.marcador, "rafael")
	var linha: DialogueLine = await companheiro.dialogo.get_next_dialogue_line("rafael")
	assert_eq(linha.character, "Próskopos")
	assert_eq((acampamento.get_node("Mercador/Interagivel") as Interagivel).marcador, "mercador")
	# A barraca com toldo é só dele, ao lado, e o cenário não a cobre.
	var barraca := acampamento.get_node("BarracaRafael") as Node2D
	assert_lt(barraca.global_position.distance_to(acampamento.get_node("Companheiro").global_position), 96.0)
	assert_has((acampamento.get_node("Cenario") as CenarioAcampamento).reservados, barraca)
	acampamento.free()
	await _abrir("ag_acampamento")
	var mercador := acampamento.get_node("Mercador/Interagivel") as Interagivel
	assert_eq(mercador.marcador, "shara")
	linha = await mercador.dialogo.get_next_dialogue_line("shara")
	assert_eq(linha.character, "Chymeía")
	assert_false(acampamento.has_node("BarracaRafael"))
	# Os outros acampamentos continuam com o mercador genérico.
	acampamento.free()
	await _abrir("oa_acampamento")
	assert_eq((acampamento.get_node("Mercador/Interagivel") as Interagivel).marcador, "mercador")
