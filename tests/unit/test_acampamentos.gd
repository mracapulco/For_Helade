extends GutTest
## Acampamentos: as nove cenas abrem, têm barraca, mercador, companheiro e
## saída ao alcance, a barraca salva e a saída volta ao mapa.

const PASTA := "res://scenes/exploracao/acampamentos/%s.tscn"
const IDS := [
	"oa_acampamento", "ot_acampamento", "og_acampamento", "ag_acampamento",
	"an_acampamento", "nt_acampamento", "at_acampamento",
	"ilha_acampamento", "ilhota_acampamento",
]
const INTERAGIVEIS := ["Barraca", "Mercador", "Companheiro", "Saida"]
## Pontos de barco: a saída é o barco, não a placa.
const DE_BARCO := ["ilha_acampamento", "ilhota_acampamento"]

var acampamento: Acampamento
var _arquivo_progresso: String
var _etapa: String


func before_each() -> void:
	_arquivo_progresso = Progresso.arquivo
	_etapa = Progresso.etapa
	Progresso.arquivo = "user://teste_acampamento.cfg"


func after_each() -> void:
	if is_instance_valid(acampamento):
		acampamento.free()
	await wait_process_frames(2)
	Progresso.apagar()
	Progresso.arquivo = _arquivo_progresso
	Progresso.etapa = _etapa
	Mundo.definir_noite(false)


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


func test_mercador_avisa_que_a_loja_vem_depois() -> void:
	await _abrir("oa_acampamento")
	TranslationServer.set_locale("pt_BR")
	var mercador := acampamento.mercador
	var fala: DialogueLine = await mercador.dialogo.get_next_dialogue_line(mercador.marcador)
	assert_eq(fala.character, "Mercador")
	assert_not_null(Elenco.buscar("Mercador"))
	assert_string_starts_with(fala.text, "[Provisório]")


func test_barraca_salva_sem_mudar_a_etapa() -> void:
	await _abrir("og_acampamento")
	Progresso.etapa = "etapa_de_teste"
	assert_false(Progresso.tem_jogo_salvo())
	watch_signals(acampamento)
	acampamento.barraca.interagir()
	assert_signal_emitted(acampamento, "salvo")
	assert_true(Progresso.tem_jogo_salvo())
	Progresso.etapa = ""
	assert_true(Progresso.carregar())
	assert_eq(Progresso.etapa, "etapa_de_teste")


func test_barraca_mostra_aviso_de_salvo() -> void:
	await _abrir("oa_acampamento")
	TranslationServer.set_locale("pt_BR")
	acampamento.barraca.interagir()
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
