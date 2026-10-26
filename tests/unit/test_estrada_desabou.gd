extends GutTest
## Fase "A estrada desabou" (estrada Atenas–Olympia, trecho 3): as regras das
## peças ([ObraEstrada]), a solução de cada trecho, recomeçar, as pedras
## rolando, o fim (a carroça passa e a fase vira atalho) e o ninho.

const CENA := "res://scenes/estrada_oa/estrada_desabou/estrada_desabou.tscn"
const T := ObraEstrada.Terreno

var fase: FaseEstradaDesabou
var _feitos: Dictionary


func before_each() -> void:
	_feitos = Mundo.feitos.duplicate()
	Mundo.feitos.clear()


func after_each() -> void:
	if is_instance_valid(fase):
		fase.free()
	await wait_process_frames(2)
	Mundo.feitos = _feitos


func _obra() -> ObraEstrada:
	return ObraEstrada.de_planta(FaseEstradaDesabou.PLANTA)


func _abrir() -> FaseEstradaDesabou:
	fase = load(CENA).instantiate()
	fase.escala_tempo = 0.0
	fase.pedras_automaticas = false
	fase.trocar_de_cena = false
	add_child(fase)
	await wait_physics_frames(2)
	return fase


## Nicholas em [param de] agarra a peça em [param peca] e empurra (ou puxa).
func _mexer(de: Vector2i, peca: Vector2i, empurra := true) -> bool:
	var nome := fase.obra.peca_em(peca)
	assert_ne(nome, "", "há peça em %s" % peca)
	fase.jogador.position = fase.sala.centro(de)
	fase.jogador.direcao_olhar = (fase.sala.centro(peca) - fase.sala.centro(de)).normalized()
	assert_true(fase.agarrar(nome), "agarra %s de %s" % [nome, de])
	var ok: bool = await fase.empurrar() if empurra else await fase.puxar()
	fase.soltar()
	return ok


# --- regras -----------------------------------------------------------------

func test_planta_tem_nove_pecas_e_seis_buracos() -> void:
	var obra := _obra()
	assert_eq(obra.largura, 41)
	assert_eq(obra.profundidade, 5)
	assert_eq(obra.pecas.size(), 9)
	assert_eq(obra.buracos().size(), 6)
	for casa: Vector2i in FaseEstradaDesabou.PONTES_PRONTAS:
		assert_eq(obra.terreno_em(casa), T.BURACO, "buraco em %s" % casa)


func test_trechos_separados_pelos_buracos() -> void:
	var obra := _obra()
	assert_true(obra.caminho(Vector2i(0, 2), Vector2i(40, 2)).is_empty())
	assert_false(obra.caminho(Vector2i(0, 2), Vector2i(6, 2)).is_empty())


func test_caixa_puxa_e_empurra_ate_o_buraco() -> void:
	var obra := _obra()
	var caixa := obra.peca_em(Vector2i(5, 4))
	assert_eq(obra.puxar(caixa, Vector2i(5, 3)), {"caminho": [Vector2i(5, 3)] as Array[Vector2i], "caiu": false})
	assert_false(obra.puxar(caixa, Vector2i(5, 2)).is_empty())
	assert_eq(obra.pecas[caixa]["casa"], Vector2i(5, 2))
	assert_false(obra.empurrar(caixa, Vector2i(4, 2), Vector2i(1, 0)).is_empty())
	var fim := obra.empurrar(caixa, Vector2i(5, 2), Vector2i(1, 0))
	assert_true(fim["caiu"])
	assert_eq(obra.terreno_em(Vector2i(7, 2)), T.PONTE)
	assert_false(obra.pecas.has(caixa))


func test_caixa_nao_entra_na_pedra() -> void:
	var obra := _obra()
	var caixa := obra.peca_em(Vector2i(5, 4))
	assert_true(obra.empurrar(caixa, Vector2i(4, 4) + Vector2i(0, 0), Vector2i(1, 0)).is_empty(), "Nicholas não está ao lado")
	assert_true(obra.empurrar(caixa, Vector2i(5, 3), Vector2i(0, 1)).is_empty(), "fora da estrada")


func test_barril_rola_ate_bater_e_nao_se_puxa() -> void:
	var obra := _obra()
	var barril := obra.peca_em(Vector2i(10, 3))
	assert_true(obra.puxar(barril, Vector2i(10, 4)).is_empty())
	var rolou := obra.empurrar(barril, Vector2i(10, 4), Vector2i(0, -1))
	assert_eq(rolou["caminho"], [Vector2i(10, 2), Vector2i(10, 1)] as Array[Vector2i], "para na pedra (10, 0)")
	var caiu := obra.empurrar(barril, Vector2i(9, 1), Vector2i(1, 0))
	assert_true(caiu["caiu"])
	assert_eq(obra.terreno_em(Vector2i(13, 1)), T.PONTE)


func test_barril_na_ordem_errada_nao_chega() -> void:
	var obra := _obra()
	var barril := obra.peca_em(Vector2i(10, 3))
	obra.empurrar(barril, Vector2i(9, 3), Vector2i(1, 0))
	assert_eq(obra.pecas[barril]["casa"], Vector2i(12, 3))
	obra.empurrar(barril, Vector2i(12, 4), Vector2i(0, -1))
	assert_eq(obra.pecas[barril]["casa"], Vector2i(12, 0))
	assert_eq(obra.terreno_em(Vector2i(13, 1)), T.BURACO)


func test_tora_so_anda_no_comprimento() -> void:
	var obra := _obra()
	var em_pe := obra.peca_em(Vector2i(18, 3))
	assert_true(obra.empurrar(em_pe, Vector2i(17, 3), Vector2i(1, 0)).is_empty(), "de lado não anda")
	assert_true(obra.empurrar(em_pe, Vector2i(18, 2), Vector2i(0, 1)).is_empty(), "pedra embaixo")
	assert_false(obra.puxar(em_pe, Vector2i(18, 2)).is_empty())
	assert_eq(obra.pecas[em_pe]["casa"], Vector2i(18, 2))
	var deitada := obra.peca_em(Vector2i(15, 3))
	assert_true(obra.puxar(deitada, Vector2i(15, 2)).is_empty(), "de lado não puxa")
	for x in range(14, 19):
		obra.empurrar(deitada, Vector2i(x, 3), Vector2i(1, 0))
	assert_eq(obra.terreno_em(Vector2i(20, 3)), T.PONTE)


func test_foto_e_restaurar() -> void:
	var obra := _obra()
	var foto := obra.foto()
	var caixa := obra.peca_em(Vector2i(5, 4))
	obra.puxar(caixa, Vector2i(5, 3))
	obra.restaurar(foto)
	assert_eq(obra.peca_em(Vector2i(5, 4)), caixa)


func test_trecho_de() -> void:
	assert_eq(FaseEstradaDesabou.trecho_de(0), 0)
	assert_eq(FaseEstradaDesabou.trecho_de(8), 1)
	assert_eq(FaseEstradaDesabou.trecho_de(25), FaseEstradaDesabou.TRECHO_PEDRAS)
	assert_eq(FaseEstradaDesabou.trecho_de(40), 5)


# --- a cena -----------------------------------------------------------------

func test_cena_abre_com_pecas_buracos_e_carroceiro() -> void:
	await _abrir()
	assert_eq(fase.nos_pecas.size(), 9)
	assert_eq(fase.nos_buracos.size(), 6)
	assert_not_null(fase.carroceiro)
	assert_false(fase.atalho)
	assert_eq(fase.casa_do_jogador(), FaseEstradaDesabou.ENTRADAS[0])


func test_mapa_abre_a_fase() -> void:
	var local: LocalMapa = load("res://data/mapa/oa_estrada_3.tres")
	assert_eq(local.cena, CENA)
	assert_true(ResourceLoader.exists(local.cena))


func test_primeiro_trecho_na_cena() -> void:
	await _abrir()
	assert_true(await _mexer(Vector2i(5, 3), Vector2i(5, 4), false))
	assert_eq(fase.casa_do_jogador(), Vector2i(5, 2))
	assert_true(await _mexer(Vector2i(5, 2), Vector2i(5, 3), false))
	assert_true(await _mexer(Vector2i(4, 2), Vector2i(5, 2)))
	assert_true(await _mexer(Vector2i(5, 2), Vector2i(6, 2)))
	assert_eq(fase.obra.terreno_em(Vector2i(7, 2)), T.PONTE)
	assert_eq(String(fase.nos_buracos[Vector2i(7, 2)].name), "Ponte_7_2")
	assert_eq(fase.nos_pecas.size(), 8)


func test_recomecar_devolve_o_trecho() -> void:
	await _abrir()
	await _mexer(Vector2i(5, 3), Vector2i(5, 4), false)
	fase.recomecar_trecho()
	assert_ne(fase.obra.peca_em(Vector2i(5, 4)), "")
	assert_eq(fase.casa_do_jogador(), FaseEstradaDesabou.ENTRADAS[0])
	var no: Node2D = fase.nos_pecas[fase.obra.peca_em(Vector2i(5, 4))]
	assert_eq(no.position, fase.sala.centro(Vector2i(5, 4)))


func test_pedra_leva_nicholas_de_volta() -> void:
	await _abrir()
	fase.jogador.position = fase.sala.centro(Vector2i(23, 2))
	await fase.soltar_pedra(23)
	assert_eq(fase.acertos, 1)
	assert_eq(fase.casa_do_jogador(), FaseEstradaDesabou.ENTRADAS[FaseEstradaDesabou.TRECHO_PEDRAS])


func test_esquivando_a_pedra_passa() -> void:
	await _abrir()
	fase.jogador.position = fase.sala.centro(Vector2i(23, 2))
	fase.jogador.esquivando = true
	await fase.soltar_pedra(23)
	assert_eq(fase.acertos, 0)
	fase.jogador.esquivando = false


func test_caixa_no_alto_da_pista_e_escudo() -> void:
	await _abrir()
	assert_true(await _mexer(Vector2i(21, 0), Vector2i(22, 0)))
	assert_ne(fase.obra.peca_em(Vector2i(23, 0)), "")
	fase.jogador.position = fase.sala.centro(Vector2i(23, 2))
	await fase.soltar_pedra(23)
	assert_eq(fase.acertos, 0)
	assert_true(fase.pedras.is_empty())


func test_pedras_so_no_trecho_delas() -> void:
	await _abrir()
	assert_false(fase.pedras_ativas())
	fase.jogador.position = fase.sala.centro(Vector2i(24, 3))
	await wait_physics_frames(2)
	assert_true(fase.pedras_ativas())
	assert_true(fase.fotos.has(FaseEstradaDesabou.TRECHO_PEDRAS))


func test_ninho_so_do_mirante() -> void:
	await _abrir()
	assert_false(fase.ninho_visivel())
	fase.jogador.position = fase.sala.centro(FaseEstradaDesabou.MIRANTE)
	await wait_seconds(0.6)
	assert_true(fase.ninho_visivel())


func test_resolver_tudo_passa_a_carroca_e_vira_atalho() -> void:
	await _abrir()
	# 1
	await _mexer(Vector2i(5, 3), Vector2i(5, 4), false)
	await _mexer(Vector2i(5, 2), Vector2i(5, 3), false)
	await _mexer(Vector2i(4, 2), Vector2i(5, 2))
	await _mexer(Vector2i(5, 2), Vector2i(6, 2))
	# 2: barril e toras
	await _mexer(Vector2i(10, 4), Vector2i(10, 3))
	await _mexer(Vector2i(9, 1), Vector2i(10, 1))
	await _mexer(Vector2i(18, 2), Vector2i(18, 3), false)
	for x in range(14, 19):
		await _mexer(Vector2i(x, 3), Vector2i(x + 1, 3))
	# 3: a caixa pela fileira do meio
	for x in range(21, 28):
		await _mexer(Vector2i(x, 2), Vector2i(x + 1, 2))
	# 4: barril e depois a caixa por cima da ponte
	await _mexer(Vector2i(31, 2), Vector2i(32, 2))
	assert_eq(fase.obra.terreno_em(Vector2i(36, 2)), T.PONTE)
	assert_false(fase.concluido)
	await _mexer(Vector2i(33, 3), Vector2i(33, 4), false)
	await _mexer(Vector2i(33, 2), Vector2i(33, 3), false)
	for x in range(32, 36):
		await _mexer(Vector2i(x, 2), Vector2i(x + 1, 2))
	assert_true(fase.obra.buracos().is_empty())
	assert_true(fase.concluido)
	assert_true(Mundo.foi_feito(FaseEstradaDesabou.ID))
	assert_eq(fase.carroca.position, fase.sala.centro(Vector2i(42, 2)))
	assert_eq(fase.cena_pedida, FaseEstradaDesabou.CENA_MAPA)


func test_vencida_vira_atalho() -> void:
	Mundo.marcar_feito(FaseEstradaDesabou.ID)
	await _abrir()
	assert_true(fase.atalho)
	assert_true(fase.nos_pecas.is_empty())
	assert_true(fase.obra.buracos().is_empty())
	assert_false(fase.obra.caminho(Vector2i(0, 2), FaseEstradaDesabou.SAIDA).is_empty())
	assert_null(fase.carroca)
	assert_not_null(fase.sala.get_node_or_null("Placa"))
	fase.jogador.position = fase.sala.centro(Vector2i(24, 2))
	await wait_physics_frames(2)
	assert_false(fase.pedras_ativas())


func test_mundo_guarda_as_fases_feitas() -> void:
	Mundo.marcar_feito("estrada_desabou")
	var dados := Mundo.para_dados()
	Mundo.feitos.clear()
	var noite := Mundo.noite
	var descobertos := Mundo.descobertos.duplicate()
	var local := Mundo.local_no_mapa
	Mundo.de_dados(dados)
	assert_true(Mundo.foi_feito("estrada_desabou"))
	Mundo.de_dados({"noite": noite, "descobertos": descobertos.keys(), "local_no_mapa": local})
	assert_false(Mundo.foi_feito("estrada_desabou"), "jogo salvo antigo, sem fases feitas")


func test_agarrar_e_puxar_pelo_controle() -> void:
	await _abrir()
	fase.jogador.position = fase.sala.centro(Vector2i(5, 3))
	fase.jogador.direcao_olhar = (fase.sala.centro(Vector2i(5, 4)) - fase.jogador.position).normalized()
	Input.action_press("golpear")
	await wait_physics_frames(2)
	assert_ne(fase.segurando, "", "segurar o clique agarra")
	assert_true(fase.jogador.em_dialogo, "segurando, as teclas não andam")
	# A caixa está para baixo e à esquerda na tela: para cima e à direita puxa.
	# Com o tempo de verdade, um toque nas teclas puxa uma casa só.
	fase.escala_tempo = 1.0
	Input.action_press("mover_frente")
	Input.action_press("mover_direita")
	await wait_physics_frames(2)
	Input.action_release("mover_frente")
	Input.action_release("mover_direita")
	await wait_seconds(FaseEstradaDesabou.TEMPO_ARRASTAR + 0.15)
	assert_ne(fase.obra.peca_em(Vector2i(5, 3)), "")
	assert_eq(fase.nos_pecas[fase.obra.peca_em(Vector2i(5, 3))].position, fase.sala.centro(Vector2i(5, 3)))
	assert_eq(fase.casa_do_jogador(), Vector2i(5, 2))
	Input.action_release("golpear")
	await wait_physics_frames(1)
	assert_eq(fase.segurando, "")
	assert_false(fase.jogador.em_dialogo)
