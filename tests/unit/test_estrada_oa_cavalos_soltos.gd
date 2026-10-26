extends GutTest
## Estrada Atenas–Olympia, fase 1 "Cavalos soltos": a cena entra no mapa,
## os cavalos fogem, fincam as patas ou seguem a fruta, a caixa de frutas vai
## para a bolsa com as frutas, a fruta é segurada ou jogada, e com os três no
## cercado a estrada abre.

const CENA := "res://scenes/estrada_oa/cavalos_soltos/cavalos_soltos.tscn"

var fase: CavalosSoltos


func before_each() -> void:
	Inventario.limpar()


func after_each() -> void:
	Input.action_release(&"correr")
	if is_instance_valid(fase):
		fase.free()
	await wait_process_frames(2)
	Inventario.limpar()


func _abrir() -> CavalosSoltos:
	fase = load(CENA).instantiate()
	fase.escala_tempo = 0.0
	fase.mostrar_dialogos = false
	fase.trocar_de_cena = false
	add_child(fase)
	await wait_physics_frames(3)
	return fase


func _cavalo(nome: String) -> Cavalo:
	return fase.cavalos[nome]


## Põe o cavalo parado num ponto e Nicholas a [param distancia] dele.
func _encostar(cavalo: Cavalo, distancia: Vector2) -> void:
	cavalo.velocity = Vector2.ZERO
	fase.jogador.global_position = cavalo.global_position + distancia
	fase.jogador.velocity = Vector2.ZERO


func test_a_estrada_4_abre_a_fase() -> void:
	var local: LocalMapa = load("res://data/mapa/oa_estrada_4.tres")
	assert_eq(local.cena, CENA)
	assert_true(ResourceLoader.exists(local.cena))


func test_cena_monta_cavalos_cercado_e_nicholas() -> void:
	await _abrir()
	assert_eq(fase.cavalos.size(), 3)
	assert_eq(fase.sala.chao.local_to_map(fase.jogador.position), CavalosSoltos.INICIO)
	for nome: String in fase.cavalos:
		assert_false(_cavalo(nome).esta_preso(), nome + " começa solto")
		assert_false(fase.no_cercado(_cavalo(nome).position), nome + " começa fora do cercado")
	# Cerca de segmentos: 5 + 5 + 3 + 3 lados, menos as duas casas da porteira.
	assert_eq(fase.objetos["cerca"].get_child_count(), 14)
	assert_eq(fase.jogador.get_node("FrutaNaMao").get_class(), "Sprite2D")


func test_pegar_a_caixa_poe_caixa_e_frutas_na_bolsa() -> void:
	await _abrir()
	var caixa: Node2D = fase.objetos["caixa"]
	caixa.get_node("Recompensa").entregar()
	assert_true(Inventario.tem("caixa_frutas"))
	assert_eq(Inventario.quantidade("fruta"), CavalosSoltos.FRUTAS_NA_CAIXA)
	await wait_process_frames(1)
	assert_false(is_instance_valid(caixa), "a caixa sai do chão")
	fase.free()
	await _abrir()
	assert_false(fase.objetos.has("caixa"), "não volta a aparecer")


func test_assustado_foge_de_nicholas() -> void:
	await _abrir()
	var cavalo := _cavalo("castanho")
	_encostar(cavalo, Vector2(-40, 0))
	var antes := cavalo.global_position.distance_to(fase.jogador.global_position)
	await wait_physics_frames(20)
	assert_eq(cavalo.estado, Cavalo.Estado.FUGINDO)
	assert_gt(cavalo.global_position.distance_to(fase.jogador.global_position), antes + 5.0)
	assert_gt(cavalo.global_position.x, fase.jogador.global_position.x, "para o lado oposto")


func test_correr_assusta_de_mais_longe() -> void:
	await _abrir()
	var cavalo := _cavalo("castanho")
	assert_eq(cavalo.raio_de_medo(), cavalo.raio_medo)
	Input.action_press(&"correr")
	fase.jogador.velocity = Vector2(60, 0)
	assert_true(cavalo.jogador_correndo())
	assert_eq(cavalo.raio_de_medo(), cavalo.raio_medo_correndo)
	assert_gt(cavalo.raio_medo_correndo, cavalo.raio_medo)


func test_longe_o_cavalo_nao_foge() -> void:
	await _abrir()
	var cavalo := _cavalo("castanho")
	_encostar(cavalo, Vector2(-(cavalo.raio_medo + 40.0), 0))
	await wait_physics_frames(10)
	assert_ne(cavalo.estado, Cavalo.Estado.FUGINDO)


func test_teimoso_finca_as_patas_de_frente() -> void:
	await _abrir()
	var cavalo := _cavalo("tordilho")
	cavalo.olhar = Vector2.RIGHT
	var lugar := cavalo.global_position
	_encostar(cavalo, Vector2(40, 0))
	await wait_physics_frames(15)
	assert_eq(cavalo.estado, Cavalo.Estado.FIRME)
	assert_lt(cavalo.global_position.distance_to(lugar), 1.0, "não sai do lugar")


func test_teimoso_anda_quando_nicholas_chega_por_tras() -> void:
	await _abrir()
	var cavalo := _cavalo("tordilho")
	cavalo.olhar = Vector2.RIGHT
	var lugar := cavalo.global_position
	_encostar(cavalo, Vector2(-40, 0))
	await wait_physics_frames(20)
	assert_eq(cavalo.estado, Cavalo.Estado.FUGINDO)
	assert_gt(cavalo.global_position.x, lugar.x + 3.0)


func test_teimoso_anda_quando_nicholas_chega_pelo_lado() -> void:
	await _abrir()
	var cavalo := _cavalo("tordilho")
	cavalo.olhar = Vector2.RIGHT
	assert_false(cavalo.de_frente_para(cavalo.global_position + Vector2(0, 40)))
	assert_true(cavalo.de_frente_para(cavalo.global_position + Vector2(40, 10)))


func test_guloso_nao_foge_e_segue_a_fruta_na_mao() -> void:
	await _abrir()
	var cavalo := _cavalo("preto")
	_encostar(cavalo, Vector2(-30, 0))
	await wait_physics_frames(15)
	assert_ne(cavalo.estado, Cavalo.Estado.FUGINDO, "sem fruta, não foge")
	_encostar(cavalo, Vector2(-100, 0))
	Inventario.adicionar("fruta", 2)
	Inventario.selecionar_espaco(0, "nicholas")
	assert_true(FrutaNaMao.segurando_fruta())
	var antes := cavalo.global_position.distance_to(fase.jogador.global_position)
	await wait_physics_frames(30)
	assert_eq(cavalo.estado, Cavalo.Estado.SEGUINDO)
	assert_lt(cavalo.global_position.distance_to(fase.jogador.global_position), antes - 10.0)


func test_fruta_aparece_na_mao_so_selecionada() -> void:
	await _abrir()
	var mao: FrutaNaMao = fase.fruta_na_mao
	Inventario.adicionar("fruta", 1)
	Inventario.adicionar("caixa_frutas", 1)
	Inventario.selecionar_espaco(1, "nicholas")
	await wait_process_frames(1)
	assert_false(mao.visible)
	Inventario.selecionar_espaco(0, "nicholas")
	await wait_process_frames(1)
	assert_true(mao.visible)


func test_jogar_a_fruta_gasta_uma_e_ela_cai_no_chao() -> void:
	await _abrir()
	Inventario.adicionar("fruta", 2)
	Inventario.selecionar_espaco(0, "nicholas")
	var fruta := fase.fruta_na_mao.jogar(Vector2.RIGHT)
	assert_not_null(fruta)
	assert_eq(Inventario.quantidade("fruta"), 1)
	assert_false(fruta.pousada, "em voo")
	await wait_seconds(fase.fruta_na_mao.tempo_voo + 0.1)
	assert_true(fruta.pousada)
	assert_gt(fruta.global_position.x, fase.jogador.global_position.x + 30.0, "voou para a direita")
	fruta.pegar()
	assert_eq(Inventario.quantidade("fruta"), 2, "pegou de volta")


func test_sem_fruta_nao_joga() -> void:
	await _abrir()
	assert_null(fase.fruta_na_mao.jogar(Vector2.RIGHT))


func test_guloso_come_a_fruta_jogada() -> void:
	await _abrir()
	var cavalo := _cavalo("preto")
	cavalo.tempo_comendo = 0.2
	Inventario.adicionar("fruta", 1)
	Inventario.selecionar_espaco(0, "nicholas")
	# No meio da estrada, sem nada no caminho.
	cavalo.position = fase.sala.centro(Vector2i(6, 6))
	_encostar(cavalo, Vector2(60, 0))
	var fruta := fase.fruta_na_mao.jogar(Vector2.LEFT)
	await wait_seconds(0.6)
	assert_true(fruta.pousada)
	var ref: WeakRef = weakref(fruta)
	await wait_until(func() -> bool: return ref.get_ref() == null, 6.0)
	assert_null(ref.get_ref(), "o cavalo comeu")
	assert_eq(Inventario.quantidade("fruta"), 0)


func test_tres_no_cercado_vencem_a_fase() -> void:
	await _abrir()
	watch_signals(fase)
	var moedas := Inventario.dinheiro()
	fase.usar_placa()
	assert_eq(fase.cena_pedida, "", "a placa não leva adiante com cavalos soltos")
	var nomes := ["castanho", "tordilho", "preto"]
	for i in nomes.size():
		var cavalo := _cavalo(nomes[i])
		cavalo.position = fase.sala.centro(CavalosSoltos.CAVALOS[nomes[i]]["no_cercado"])
		await wait_physics_frames(2)
		assert_true(cavalo.esta_preso(), nomes[i])
		assert_eq(fase.cavalos_presos(), i + 1)
	assert_true(fase.vencida)
	assert_signal_emit_count(fase, "concluida", 1)
	assert_true(Inventario.ja_coletado(CavalosSoltos.ID_FASE))
	assert_eq(Inventario.dinheiro(), moedas + CavalosSoltos.MOEDAS)
	assert_eq(fase.marcador_do_carroceiro(), "carroceiro_depois")
	fase.usar_placa()
	assert_eq(fase.cena_pedida, CavalosSoltos.CENA_MAPA)


func test_no_cercado_o_cavalo_fica_calmo() -> void:
	await _abrir()
	var cavalo := _cavalo("castanho")
	cavalo.position = fase.sala.centro(Vector2i(16, 9))
	await wait_physics_frames(2)
	var lugar := cavalo.global_position
	_encostar(cavalo, Vector2(-20, 0))
	await wait_physics_frames(20)
	assert_eq(cavalo.estado, Cavalo.Estado.NO_CERCADO)
	assert_lt(cavalo.global_position.distance_to(lugar), 2.0)


func test_voltar_depois_de_vencida_acha_os_cavalos_no_cercado() -> void:
	Inventario.marcar_coletado(CavalosSoltos.ID_FASE)
	await _abrir()
	assert_true(fase.vencida)
	for nome: String in fase.cavalos:
		assert_true(_cavalo(nome).esta_preso(), nome)
		assert_true(fase.no_cercado(_cavalo(nome).position), nome)
	fase.usar_placa()
	assert_eq(fase.cena_pedida, CavalosSoltos.CENA_MAPA)


func test_carroceiro_da_a_dica_do_primeiro_cavalo_solto() -> void:
	await _abrir()
	assert_eq(fase.marcador_do_carroceiro(), "carroceiro_inicio")
	_cavalo("castanho").prender()
	assert_eq(fase.marcador_do_carroceiro(), "carroceiro_dica_teimoso")
	_cavalo("tordilho").prender()
	assert_eq(fase.marcador_do_carroceiro(), "carroceiro_dica_guloso")


func test_macieira_nao_deixa_faltar_fruta() -> void:
	await _abrir()
	assert_true(fase.colher_fruta())
	assert_eq(Inventario.quantidade("fruta"), 1)
	Inventario.adicionar("fruta", CavalosSoltos.FRUTAS_BASTAM - 1)
	assert_false(fase.colher_fruta(), "com frutas que bastem, não dá mais")
	assert_eq(Inventario.quantidade("fruta"), CavalosSoltos.FRUTAS_BASTAM)


func test_roteiro_tem_todos_os_marcadores() -> void:
	var roteiro: DialogueResource = load("res://data/dialogos/estrada_oa/cavalos_soltos.dialogue")
	for marcador in ["frases_inicio", "frases_fim", "frase_placa_fechada", "frase_macieira_cheia",
			"carroceiro_inicio", "carroceiro_dica_teimoso", "carroceiro_dica_guloso",
			"carroceiro_fim", "carroceiro_depois"]:
		assert_true(roteiro.get_cues().has(marcador), marcador)
	assert_not_null(Elenco.buscar("Carroceiro"))
