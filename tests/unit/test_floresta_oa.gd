extends GutTest
## Fase "Árvores e mais árvores" (estrada Atenas–Olympia, oa_estrada_2): as
## regras do labirinto, a montagem das clareiras e a fase inteira, do começo
## à saída da mata, passando pelo eco, pelo baú escondido e pela emboscada.

const LabirintoFloresta := preload("res://scripts/estrada_oa/floresta/labirinto_floresta.gd")
const CENA := "res://scenes/estrada_oa/floresta/floresta.tscn"
const S := LabirintoFloresta.Saida
const R := LabirintoFloresta.Resultado

var fase: FaseFloresta


func after_each() -> void:
	if is_instance_valid(fase):
		fase.free()
	await wait_process_frames(2)
	Inventario.limpar()
	Mundo.local_no_mapa = ""
	Trilha.parar(0.0)
	Trilha.ambientar("", 0.0)


func _abrir() -> FaseFloresta:
	fase = load(CENA).instantiate()
	fase.trocar_de_cena = false
	fase.animar = false
	add_child(fase)
	await wait_physics_frames(3)
	return fase


## Vai da entrada até a emboscada pelas saídas certas.
func _ate_a_emboscada() -> void:
	for i in LabirintoFloresta.CLAREIRAS.size() - 1:
		fase.sair_por(fase.labirinto.saida_certa())


# ---------- regras (LabirintoFloresta) ----------

func test_saidas_certas_levam_a_emboscada() -> void:
	var labirinto := LabirintoFloresta.new()
	for i in labirinto.indice_emboscada():
		var resultado := labirinto.sair(labirinto.saida_certa())
		assert_eq(labirinto.atual, i + 1)
		assert_eq(resultado, R.EMBOSCADA if i + 1 == labirinto.indice_emboscada() else R.AVANCOU)
	assert_true(labirinto.na_emboscada())


func test_lado_errado_volta_a_mesma_clareira() -> void:
	var labirinto := LabirintoFloresta.new()
	labirinto.sair(labirinto.saida_certa())
	var errada := (labirinto.saida_certa() + 1) % 4
	assert_eq(labirinto.sair(errada), R.VOLTOU)
	assert_eq(labirinto.atual, 1, "continua na mesma clareira")
	assert_eq(labirinto.entrou_por, LabirintoFloresta.oposta(errada), "entra pelo lado oposto ao que saiu")


func test_a_saida_certa_nunca_e_o_lado_de_chegada() -> void:
	var labirinto := LabirintoFloresta.new()
	while not labirinto.na_emboscada():
		labirinto.sair(labirinto.saida_certa())
		if labirinto.saida_certa() != LabirintoFloresta.NENHUMA:
			assert_ne(labirinto.saida_certa(), labirinto.entrou_por, "clareira %d" % labirinto.atual)
		assert_ne(labirinto.saida_eco(), labirinto.entrou_por, "eco da clareira %d" % labirinto.atual)


func test_aprende_sem_eco_e_aprofunda_com_eco_e_marca() -> void:
	var labirinto := LabirintoFloresta.new()
	for i in 2:
		assert_eq(labirinto.saida_eco(), LabirintoFloresta.NENHUMA, "clareira %d só tem a melodia" % i)
		assert_false(labirinto.tem_marca())
		labirinto.sair(labirinto.saida_certa())
	for i in 2:
		assert_ne(labirinto.saida_eco(), LabirintoFloresta.NENHUMA, "clareira %d tem eco" % labirinto.atual)
		assert_ne(labirinto.saida_eco(), labirinto.saida_certa())
		assert_true(labirinto.tem_marca(), "a marca desempata")
		labirinto.sair(labirinto.saida_certa())


func test_eco_da_primeira_clareira_com_eco_engana() -> void:
	var labirinto := LabirintoFloresta.new()
	labirinto.atual = 2
	assert_eq(labirinto.sair(labirinto.saida_eco()), R.VOLTOU)
	assert_eq(labirinto.atual, 2)


func test_eco_da_ultima_clareira_leva_ao_segredo_e_dele_a_emboscada() -> void:
	var labirinto := LabirintoFloresta.new()
	labirinto.atual = 3
	assert_eq(labirinto.sair(labirinto.saida_eco()), R.SEGREDO)
	assert_true(labirinto.na_escondida())
	assert_eq(labirinto.saida_eco(), LabirintoFloresta.NENHUMA)
	assert_eq(labirinto.sair((labirinto.saida_certa() + 1) % 4), R.VOLTOU, "a escondida também engana")
	assert_true(labirinto.na_escondida())
	assert_eq(labirinto.sair(labirinto.saida_certa()), R.EMBOSCADA)
	assert_true(labirinto.na_emboscada())


func test_emboscada_fechada_ate_vencer() -> void:
	var labirinto := LabirintoFloresta.new()
	labirinto.atual = labirinto.indice_emboscada()
	assert_eq(labirinto.saida_certa(), LabirintoFloresta.NENHUMA, "sem melodia durante a luta")
	for saida in 4:
		assert_eq(labirinto.sair(saida), R.FECHADA)
	labirinto.bandidos_derrotados = true
	assert_ne(labirinto.saida_certa(), LabirintoFloresta.NENHUMA)
	assert_true(labirinto.tem_marca(), "as marcas acabam na saída")
	assert_eq(labirinto.sair((labirinto.saida_certa() + 1) % 4), R.VOLTOU)
	assert_eq(labirinto.sair(labirinto.saida_certa()), R.SAIU)


# ---------- montagem (ClareiraFloresta) ----------

func test_beira_de_cada_trilha_e_uma_saida() -> void:
	for saida in 4:
		var beira := ClareiraFloresta.celula_da_saida(saida)
		assert_eq(ClareiraFloresta.saida_na_celula(beira), saida)
		assert_eq(ClareiraFloresta.saida_na_celula(beira + ClareiraFloresta.passo_para_fora(saida)), saida, "além da beira também")
		assert_eq(ClareiraFloresta.saida_na_celula(ClareiraFloresta.celula_de_entrada(saida)), LabirintoFloresta.NENHUMA,
			"quem entra não sai de novo na hora")
	assert_eq(ClareiraFloresta.saida_na_celula(ClareiraFloresta.CENTRO), LabirintoFloresta.NENHUMA)
	assert_eq(ClareiraFloresta.saida_na_celula(Vector2i(0, 0)), LabirintoFloresta.NENHUMA, "canto não é trilha")


func test_trilhas_e_meio_sem_arvores() -> void:
	await _abrir()
	for no in fase.clareira.get_children():
		if not no is StaticBody2D or not no.name.begins_with("Arvore"):
			continue
		var celula := fase.clareira.celula_de((no as Node2D).global_position)
		assert_false(ClareiraFloresta.na_trilha(celula) and ClareiraFloresta.dentro(celula), "%s fecha uma trilha" % no.name)


func test_toda_clareira_parece_igual_menos_o_marco() -> void:
	await _abrir()
	var antes := _posicoes_das_arvores()
	var marco_antes: Texture2D = (fase.clareira.marco.get_node("Visual") as Sprite2D).texture
	fase.sair_por(fase.labirinto.saida_certa())
	assert_eq(_posicoes_das_arvores(), antes, "as mesmas árvores")
	assert_ne((fase.clareira.marco.get_node("Visual") as Sprite2D).texture, marco_antes, "outro marco")


func _posicoes_das_arvores() -> Array:
	var posicoes := []
	for no in fase.clareira.get_children():
		if no.name.begins_with("Arvore"):
			posicoes.append((no as Node2D).position)
	return posicoes


# ---------- a fase ----------

func test_mapa_abre_a_fase() -> void:
	var local := load("res://data/mapa/oa_estrada_2.tres") as LocalMapa
	assert_eq(local.cena, CENA)
	assert_true(ResourceLoader.exists(local.cena))


func test_textos_traduzidos() -> void:
	for chave in ["FLORESTA_TITULO", "FLORESTA_FRASE_INICIO", "FLORESTA_FRASE_ESCUTE", "FLORESTA_FRASE_DE_NOVO",
			"FLORESTA_FRASE_ESCONDIDA", "FLORESTA_FRASE_EMBOSCADA", "FLORESTA_FRASE_MARCAS",
			"FLORESTA_FRASE_FECHADA", "FLORESTA_FRASE_VITORIA", "FLORESTA_FRASE_SAIDA"]:
		assert_ne(tr(chave), chave, chave)


func test_comeca_na_primeira_clareira_com_a_melodia_e_o_vento() -> void:
	await _abrir()
	assert_eq(fase.labirinto.atual, 0)
	assert_true(fase.som_certo.playing, "a melodia toca")
	assert_false(fase.som_eco.playing, "sem eco no começo")
	assert_eq(Trilha.ambiente_atual, FaseFloresta.SOM_VENTO)
	var saida := fase.clareira.ponto_da_saida(fase.labirinto.saida_certa(), 2)
	assert_almost_eq(fase.som_certo.global_position, saida, Vector2.ONE)
	var celula := fase.clareira.celula_de(fase.personagem.global_position)
	assert_eq(celula, ClareiraFloresta.celula_de_entrada(S.SUDOESTE), "chega pela estrada, no sudoeste")


func test_folhas_voam_para_a_saida_certa() -> void:
	await _abrir()
	var rumo := fase.direcao_da_saida(fase.labirinto.saida_certa())
	assert_almost_eq(fase.folhas.direction, rumo, Vector2.ONE * 0.01)
	assert_gt(fase.folhas.gravity.dot(rumo), 0.0)


func test_nas_clareiras_com_eco_o_vento_fica_indeciso() -> void:
	await _abrir()
	fase.sair_por(fase.labirinto.saida_certa())
	fase.sair_por(fase.labirinto.saida_certa())
	assert_true(fase.som_eco.playing, "o eco toca")
	var eco := fase.direcao_da_saida(fase.labirinto.saida_eco())
	fase._soprar(FaseFloresta.TEMPO_RAJADA)
	assert_almost_eq(fase.folhas.direction, eco, Vector2.ONE * 0.01, "uma rajada vai para o eco")
	fase._soprar(FaseFloresta.TEMPO_RAJADA)
	assert_almost_eq(fase.folhas.direction, fase.direcao_da_saida(fase.labirinto.saida_certa()), Vector2.ONE * 0.01)
	assert_not_null(fase.clareira.marca, "a árvore marcada desempata")
	var celula := fase.clareira.celula_de(fase.clareira.marca.global_position)
	var certa := ClareiraFloresta.celula_da_saida(fase.labirinto.saida_certa())
	assert_lt(Vector2(celula - certa).length(), 5.0, "a marca fica na boca da trilha certa")


func test_andar_ate_a_beira_troca_de_clareira() -> void:
	await _abrir()
	var certa := fase.labirinto.saida_certa()
	fase.personagem.global_position = fase.clareira.ponto_da_saida(certa)
	await wait_physics_frames(3)
	assert_eq(fase.labirinto.atual, 1)
	var celula := fase.clareira.celula_de(fase.personagem.global_position)
	assert_eq(celula, ClareiraFloresta.celula_de_entrada(LabirintoFloresta.oposta(certa)), "entra pelo lado oposto")


func test_errar_volta_ao_mesmo_lugar() -> void:
	await _abrir()
	var errada := (fase.labirinto.saida_certa() + 1) % 4
	assert_eq(fase.sair_por(errada), R.VOLTOU)
	assert_eq(fase.labirinto.atual, 0)
	assert_eq(fase.clareira.celula_de(fase.personagem.global_position),
		ClareiraFloresta.celula_de_entrada(LabirintoFloresta.oposta(errada)))


func test_navegacao_refeita_a_cada_clareira() -> void:
	await _abrir()
	var primeira := fase.navegacao
	fase.sair_por(fase.labirinto.saida_certa())
	assert_false(is_instance_valid(primeira), "a navegação antiga sai")
	assert_eq(fase.get_children().filter(func(no: Node) -> bool: return no is NavegacaoSala).size(), 1)


func test_bau_da_clareira_escondida() -> void:
	await _abrir()
	for i in 3:
		fase.sair_por(fase.labirinto.saida_certa())
	assert_eq(fase.sair_por(fase.labirinto.saida_eco()), R.SEGREDO)
	var bau := fase.clareira.get_node_or_null("Bau")
	assert_not_null(bau, "o baú está na escondida")
	var moedas := Inventario.dinheiro()
	(bau.get_node("Interagivel") as Interagivel).interagir()
	assert_eq(Inventario.quantidade("pocao_cura"), 2)
	assert_eq(Inventario.dinheiro(), moedas + FaseFloresta.MOEDAS_BAU)
	assert_true(Inventario.ja_coletado(FaseFloresta.ID_BAU))
	fase.sair_por(fase.labirinto.saida_certa())
	assert_null(fase.clareira.get_node_or_null("Bau"), "o baú some fora da escondida")


func test_emboscada_tres_bandidos_e_saidas_fechadas() -> void:
	await _abrir()
	_ate_a_emboscada()
	assert_true(fase.labirinto.na_emboscada())
	assert_eq(fase.bandidos.size(), 3)
	assert_eq(Trilha.atual, FaseFloresta.MUSICA_EMBOSCADA)
	assert_false(fase.som_certo.playing, "sem melodia na luta")
	var traicoeiros := fase.bandidos.filter(func(b: Inimigo) -> bool: return b.golpe_pelas_costas and b.provoca_tic_tac)
	assert_eq(traicoeiros.size(), 1, "um bandido traiçoeiro (Tic. Tac.)")
	for bandido in fase.bandidos:
		assert_not_null(bandido.vida)
		assert_gt(bandido.atributos().ataque, 0, "%s está armado" % bandido.name)
	assert_eq(fase.sair_por(S.NORDESTE), R.FECHADA)
	assert_true(fase.labirinto.na_emboscada())


func test_vencer_os_bandidos_abre_a_saida_da_mata() -> void:
	await _abrir()
	_ate_a_emboscada()
	for bandido in fase.bandidos.duplicate():
		bandido.vida.perder(999)
	await wait_process_frames(2)
	assert_true(fase.labirinto.bandidos_derrotados)
	assert_true(fase.som_certo.playing, "a melodia volta")
	assert_not_null(fase.clareira.marca)
	assert_eq(fase.sair_por(fase.labirinto.saida_certa()), R.SAIU)
	assert_eq(fase.cena_pedida, FaseFloresta.CENA_MAPA)
	assert_true(Inventario.ja_coletado(FaseFloresta.ID_VENCIDA))
	assert_eq(Mundo.local_no_mapa, "oa_estrada_2")


func test_derrotado_volta_para_a_entrada_da_clareira() -> void:
	await _abrir()
	_ate_a_emboscada()
	fase.personagem.global_position = fase.clareira.chao.to_global(fase.clareira.chao.map_to_local(ClareiraFloresta.CENTRO))
	fase.personagem.vida.perder(999)
	await wait_process_frames(1)
	assert_eq(fase.clareira.celula_de(fase.personagem.global_position),
		ClareiraFloresta.celula_de_entrada(fase.labirinto.entrou_por))
	assert_true(fase.labirinto.na_emboscada(), "continua na emboscada")


func test_depois_de_vencida_tem_atalho() -> void:
	await _abrir()
	assert_null(fase.clareira.get_node_or_null("PlacaAtalho"), "sem atalho na primeira vez")
	fase.free()
	Inventario.marcar_coletado(FaseFloresta.ID_VENCIDA)
	await _abrir()
	var placa := fase.clareira.get_node_or_null("PlacaAtalho")
	assert_not_null(placa)
	(placa.get_node("Interagivel") as Interagivel).interagir()
	assert_eq(fase.cena_pedida, FaseFloresta.CENA_MAPA)
