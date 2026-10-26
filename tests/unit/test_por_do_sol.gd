extends GutTest
## Fase "Antes que o sol beije o mar" (estrada Atenas–Olympia): o desenho do
## planalto, os tempos da corrida contra o sol, o fôlego, o vento, as muretas,
## o segredo e a chegada ao mirante.

const CENA := "res://scenes/estrada_oa/por_do_sol/por_do_sol.tscn"
const Planalto := preload("res://scripts/estrada_oa/por_do_sol/planalto.gd")
## Caracteres do caminho seguro (estrada, grama, capim e ponte) e dos atalhos.
const SEGURO := ".,=SFp"
const COM_PEDRAS := SEGURO + "o"
const COM_MURETAS := COM_PEDRAS + "m"
const COM_TRILHA := COM_MURETAS + "s"
## Rapidez de andar e a média correndo com o fôlego (corre ~44% do tempo a 1,5×).
const ANDANDO := 120.0
const CORRENDO := 146.0

var fase: FasePorDoSol


func after_each() -> void:
	if is_instance_valid(fase):
		fase.free()
	await wait_process_frames(2)
	Mundo.limpar()
	Codice.limpar()
	Input.action_release(&"correr")


func _abrir() -> FasePorDoSol:
	fase = load(CENA).instantiate()
	fase.trocar_de_cena = false
	add_child(fase)
	await wait_physics_frames(3)
	return fase


func _duracao() -> float:
	var relogio := RelogioSol.new()
	var duracao := relogio.duracao
	relogio.free()
	return duracao


# ---------- o desenho do planalto ----------

func test_o_planalto_e_retangular_com_uma_saida_e_um_mirante() -> void:
	for linha in Planalto.MAPA:
		assert_eq(linha.length(), Planalto.largura())
	assert_eq(Planalto.celulas(Planalto.SAIDA).size(), 1)
	assert_gt(Planalto.celulas(Planalto.MIRANTE).size(), 0)
	assert_true(Planalto.andavel(Planalto.celula_de_saida()))


func test_tem_caminho_seguro_sem_atalho_nenhum() -> void:
	assert_gt(Planalto.tempo_ate_o_mirante(ANDANDO, SEGURO, 0.0), 0.0)


func test_as_barreiras_so_se_atravessam_pela_ponta_ou_pelo_atalho() -> void:
	# Sem a passagem do alto, a primeira mureta e o riacho, não há caminho:
	# cada barreira atravessa o planalto inteiro.
	for x in [34, 56, 78]:
		var abertas := 0
		for y in range(1, Planalto.altura() - 1):
			if SEGURO.contains(Planalto.simbolo(Vector2i(x, y))):
				abertas += 1
		assert_lt(abertas, Planalto.altura() / 3, "barreira em x = %d" % x)
	assert_gt(Planalto.celulas(Planalto.MURETA).size(), 0)
	assert_gt(Planalto.celulas("o").size(), 0)


## A conta da fase: andando pelo caminho seguro, o sol se põe antes; correndo
## e pegando os atalhos, sobra tempo. Cada atalho ajuda.
func test_o_sol_e_calibrado_pelos_caminhos() -> void:
	var duracao := _duracao()
	var seguro_andando := Planalto.tempo_ate_o_mirante(ANDANDO, SEGURO, Planalto.VENTO_MEDIO)
	var seguro := Planalto.tempo_ate_o_mirante(CORRENDO, SEGURO, Planalto.VENTO_MEDIO)
	var pedras := Planalto.tempo_ate_o_mirante(CORRENDO, COM_PEDRAS, Planalto.VENTO_MEDIO)
	var muretas := Planalto.tempo_ate_o_mirante(CORRENDO, COM_MURETAS, Planalto.VENTO_MEDIO)
	var tudo := Planalto.tempo_ate_o_mirante(CORRENDO, COM_TRILHA, Planalto.VENTO_MEDIO)
	gut.p("andando %.1f · seguro %.1f · pedras %.1f · muretas %.1f · trilha %.1f · sol %.1f"
		% [seguro_andando, seguro, pedras, muretas, tudo, duracao])
	assert_gt(seguro_andando, duracao, "só andando pelo caminho seguro não dá")
	assert_lt(seguro, duracao, "correndo pelo caminho seguro dá, apertado")
	assert_gt(seguro, duracao * 0.8, "o caminho seguro é apertado")
	assert_lt(pedras, seguro)
	assert_lt(muretas, pedras)
	assert_lt(tudo, muretas - 5.0, "a trilha secreta poupa vários segundos")
	assert_lt(tudo, duracao * 0.75)


func test_a_trilha_escondida_e_capim_ate_ser_vista() -> void:
	var trilha: Vector2i = Planalto.celulas(Planalto.TRILHA)[0]
	assert_eq(Planalto.fator_terreno(trilha, false), Planalto.FATOR_CAPIM)
	assert_eq(Planalto.fator_terreno(trilha, true), 1.0)
	var escondida := Planalto.tempo_ate_o_mirante(CORRENDO, COM_TRILHA, Planalto.VENTO_MEDIO, false)
	var vista := Planalto.tempo_ate_o_mirante(CORRENDO, COM_TRILHA, Planalto.VENTO_MEDIO, true)
	assert_lt(vista, escondida)


# ---------- o vento ----------

func test_vento_so_depois_da_terceira_barreira() -> void:
	assert_false(Planalto.com_vento(Vector2i(Planalto.COLUNA_VENTO - 1, 5)))
	assert_true(Planalto.com_vento(Vector2i(Planalto.COLUNA_VENTO + 2, 2)))


func test_atras_da_rocha_o_vento_nao_alcanca() -> void:
	for rocha in Planalto.celulas(Planalto.ROCHA):
		if rocha.x < Planalto.COLUNA_VENTO + Planalto.ALCANCE_ABRIGO:
			continue
		var atras := rocha - Vector2i(1, 0)
		assert_true(Planalto.abrigada(atras), "atrás da rocha em %s" % rocha)
		assert_true(Planalto.sombras().has(atras) or not Planalto.andavel(atras))


func test_o_vento_sopra_do_mar_em_rajadas() -> void:
	var minimo := INF
	var maximo := 0.0
	for i in 40:
		var forca := Planalto.forca_vento(i * 0.1)
		minimo = minf(minimo, forca)
		maximo = maxf(maximo, forca)
	assert_gt(minimo, 0.0)
	assert_gt(maximo - minimo, Planalto.VENTO_MEDIO * 0.8)
	# Contra o mirante: o rumo do mar (x crescente) é para baixo e à direita.
	var vento := Planalto.vento(0.0)
	assert_lt(vento.x, 0.0)
	assert_lt(vento.y, 0.0)


# ---------- fôlego e relógio ----------

func test_folego_acaba_e_volta() -> void:
	var folego := Folego.new()
	var segundos := 0.0
	while folego.pode_correr() and segundos < 10.0:
		folego.atualizar(0.1, true)
		segundos += 0.1
	assert_almost_eq(segundos, Folego.MAXIMO / folego.gasto, 0.11)
	assert_true(folego.cansado)
	# Cansado, apertar Shift não corre nem gasta.
	assert_false(folego.atualizar(0.1, true))
	for i in 40:
		folego.atualizar(0.1, false)
	assert_false(folego.cansado)
	assert_true(folego.pode_correr())


func test_relogio_desce_o_sol_e_avisa_uma_vez() -> void:
	var relogio := RelogioSol.new()
	add_child_autofree(relogio)
	watch_signals(relogio)
	relogio.avancar(10.0)
	assert_eq(relogio.progresso(), 0.0, "parado até começar")
	relogio.comecar()
	relogio.avancar(relogio.duracao / 2.0)
	assert_almost_eq(relogio.progresso(), 0.5, 0.001)
	assert_false(relogio.posto())
	relogio.avancar(relogio.duracao)
	relogio.avancar(1.0)
	assert_true(relogio.posto())
	assert_signal_emit_count(relogio, "se_pos", 1)


# ---------- a cena ----------

func test_a_cena_monta_o_planalto() -> void:
	await _abrir()
	assert_eq(fase.muretas.size(), Planalto.celulas(Planalto.MURETA).size())
	assert_eq(fase.chao.get_used_cells().size(), Planalto.largura() * Planalto.altura())
	assert_eq(fase.celula_de(fase.personagem.global_position), Planalto.celula_de_saida())
	assert_eq(fase.sombras.get_child_count(), Planalto.sombras().size())


func test_o_capim_alto_atrasa() -> void:
	await _abrir()
	var base := fase.personagem.velocidade
	var capim: Vector2i = Planalto.celulas(Planalto.CAPIM)[0]
	fase._aplicar_terreno(capim)
	assert_almost_eq(fase.personagem.velocidade, base * Planalto.FATOR_CAPIM, 0.01)
	fase._aplicar_terreno(Planalto.celula_de_saida())
	assert_almost_eq(fase.personagem.velocidade, base, 0.01)


func test_cansado_o_shift_nao_acelera() -> void:
	await _abrir()
	fase.folego.atual = 0.0
	fase.folego.cansado = true
	fase._aplicar_folego(0.016)
	assert_eq(fase.personagem.multiplicador_corrida, 1.0)
	fase.folego.atual = Folego.MAXIMO
	fase.folego.cansado = false
	fase._aplicar_folego(0.016)
	assert_gt(fase.personagem.multiplicador_corrida, 1.0)


## A mureta segura quem anda e deixa passar quem pula.
func test_a_mureta_so_deixa_passar_pulando() -> void:
	await _abrir()
	var mureta: StaticBody2D = fase.muretas[0]
	var pessoa := fase.personagem
	var rumo := Planalto.RUMO_DO_MAR.normalized()
	pessoa.global_position = mureta.global_position - rumo * 20.0
	await wait_physics_frames(1)
	assert_true(pessoa.test_move(pessoa.global_transform, rumo * 40.0), "andando, bate na mureta")
	pessoa.pular()
	fase._cuidar_das_muretas()
	assert_true(fase.mureta_liberada(mureta))
	assert_false(pessoa.test_move(pessoa.global_transform, rumo * 40.0), "pulando, passa")
	# Terminou o pulo longe da mureta: ela volta a segurar.
	pessoa.pulando = false
	pessoa.global_position = mureta.global_position + rumo * 30.0
	fase._cuidar_das_muretas()
	assert_false(fase.mureta_liberada(mureta))


func test_do_alto_da_mureta_da_trilha_ve_a_trilha() -> void:
	await _abrir()
	watch_signals(fase)
	var comum: StaticBody2D = fase.muretas.filter(func(m: StaticBody2D) -> bool:
		return not m.get_meta(&"da_trilha"))[0]
	fase.personagem.global_position = comum.global_position
	fase.personagem.pular()
	fase._cuidar_das_muretas()
	assert_false(fase.trilha_visivel, "outra mureta não mostra a trilha")
	fase.personagem.pulando = false
	var da_trilha: StaticBody2D = fase.muretas.filter(func(m: StaticBody2D) -> bool:
		return m.get_meta(&"da_trilha"))[0]
	fase.personagem.global_position = da_trilha.global_position
	fase.personagem.pular()
	fase._cuidar_das_muretas()
	assert_true(fase.trilha_visivel)
	assert_signal_emitted(fase, "trilha_revelada")
	assert_true(Codice.tem("trilha_pedras_brancas"))
	var trilha: Vector2i = Planalto.celulas(Planalto.TRILHA)[0]
	assert_eq(fase.chao.get_cell_atlas_coords(trilha), FasePorDoSol.PISO_TRILHA)


func test_o_vento_empurra_fora_do_abrigo() -> void:
	await _abrir()
	var exposta := Vector2i(Planalto.COLUNA_VENTO + 2, 2)
	assert_eq(fase.vento_em(exposta), Vector2.ZERO, "antes de o vento virar")
	fase.ativar_vento()
	assert_ne(fase.vento_em(exposta), Vector2.ZERO)
	var abrigo: Vector2i = Planalto.sombras()[0]
	assert_eq(fase.vento_em(abrigo), Vector2.ZERO)


func test_chegar_a_tempo_da_a_vista_dourada_e_olympia() -> void:
	await _abrir()
	watch_signals(fase)
	Mundo.definir_noite(true)
	fase.chegar_ao_mirante()
	assert_true(fase.a_tempo)
	assert_signal_emitted_with_parameters(fase, "chegou_ao_mirante", [true])
	assert_true(Codice.tem("vista_de_olympia"))
	assert_true(Mundo.foi_descoberto("olympia"))
	assert_eq(Mundo.local_no_mapa, "olympia")
	assert_false(Mundo.noite)
	assert_true(fase.personagem.em_dialogo, "Nicholas para no mirante")
	assert_string_contains(fase.imagem_vista.texture.resource_path, "vista_por_do_sol")


func test_chegar_depois_do_sol_da_a_vista_noturna() -> void:
	await _abrir()
	fase.relogio.comecar()
	fase.relogio.avancar(fase.relogio.duracao + 1.0)
	fase.chegar_ao_mirante()
	assert_false(fase.a_tempo)
	assert_false(Codice.tem("vista_de_olympia"))
	assert_eq(Mundo.local_no_mapa, "olympia")
	assert_true(Mundo.noite)
	assert_string_contains(fase.imagem_vista.texture.resource_path, "vista_noite")


func test_botoes_do_fim_e_voltar_ao_mapa() -> void:
	await _abrir()
	fase.voltar_ao_mapa()
	assert_eq(fase.cena_pedida, FasePorDoSol.CENA_MAPA)
	fase.tentar_de_novo()
	assert_eq(fase.cena_pedida, CENA)
	fase.seguir_para_olympia()
	assert_eq(fase.cena_pedida, FasePorDoSol.CENA_MAPA)


func test_a_estrada_do_mapa_abre_a_fase() -> void:
	var local := load("res://data/mapa/oa_estrada_1.tres") as LocalMapa
	assert_eq(local.cena, CENA)
	assert_true(ResourceLoader.exists(local.cena))


func test_textos_existem() -> void:
	for chave in ["OA_SOL_DICA_INICIO", "OA_SOL_DICA_CONTROLES", "OA_SOL_DICA_VENTO", "OA_SOL_DICA_POS",
			"OA_SOL_TRILHA", "OA_SOL_FOLEGO", "OA_SOL_SEGUIR", "OA_SOL_DE_NOVO", "OA_SOL_FRASE_SOL",
			"OA_SOL_FRASE_OLYMPIA", "OA_SOL_FRASE_CASTELO"]:
		assert_ne(tr(chave), chave, chave)
	for id in ["vista_de_olympia", "trilha_pedras_brancas"]:
		assert_ne(Codice.titulo(id), "CODICE_%s_TITULO" % id.to_upper())
