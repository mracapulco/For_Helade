extends GutTest
## Capítulo 01, passos 1 e 2: a manhã do aniversário, do sonho à carruagem.

const CENA := "res://scenes/capitulo_01/capitulo_01.tscn"
const ROTEIRO: DialogueResource = preload("res://data/dialogos/capitulo_01/manha.dialogue")

var capitulo: Capitulo01
## Como estava a cena quando a etapa virou "carruagem".
var na_carruagem := {}


func before_each() -> void:
	Codice.limpar()
	Relacoes.limpar()
	capitulo = load(CENA).instantiate()
	capitulo.escala_tempo = 0.0
	capitulo.mostrar_dialogos = false
	capitulo.trocar_de_cena = false
	add_child_autofree(capitulo)
	await _esperar_etapa("sonho")


func _esperar_etapa(nome: String) -> void:
	for i in 60:
		if capitulo.etapa == nome:
			return
		await wait_physics_frames(1)
	fail_test("não chegou na etapa %s (está em %s)" % [nome, capitulo.etapa])


func after_each() -> void:
	Codice.limpar()
	Relacoes.limpar()


func _vestir() -> void:
	_interagir("armario")
	_interagir("espelho")
	for i in 60:
		if capitulo.vestido and not capitulo.jogador.em_dialogo:
			return
		await wait_physics_frames(1)
	fail_test("não terminou de se vestir")


func _interagir(nome: String) -> void:
	var area: Interagivel = capitulo.objetos[nome].get_node("Interagivel")
	area.interagir()


## Do sonho até o corredor, já vestido.
func _ate_o_corredor() -> void:
	capitulo.chegar_na_garota()
	await _esperar_etapa("quarto")
	await _vestir()
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")


## Na porta de Althea, olha as duas extremidades e o cortejo chega.
func _esperar_o_cortejo() -> void:
	_interagir("porta_althea")
	await _esperar_etapa("esperando")
	_interagir("extremidade_esq")
	_interagir("extremidade_dir")
	await _esperar_etapa("quarto_althea")


## Acorda Althea (dois toques na cama) e entrega o embrulho.
func _acordar_e_entregar() -> void:
	_interagir("cama_althea")
	_interagir("cama_althea")
	await _esperar_etapa("embrulho")
	_interagir("embrulho")
	await _esperar_etapa("a_mesa")


## Percorre um marcador do roteiro escolhendo as opções [param escolhas] na
## ordem; devolve os static_id das falas por onde passou.
func _percorrer(marcador: String, escolhas: Array[int]) -> Array[String]:
	var ids: Array[String] = []
	var fala: DialogueLine = await ROTEIRO.get_next_dialogue_line(marcador)
	var limite := 100
	while fala and limite > 0:
		limite -= 1
		ids.append(fala.static_id)
		if fala.responses.is_empty():
			fala = await ROTEIRO.get_next_dialogue_line(fala.next_id)
		else:
			var opcao: DialogueResponse = fala.responses[escolhas.pop_front()]
			ids.append(opcao.static_id)
			fala = await ROTEIRO.get_next_dialogue_line(opcao.next_id)
	return ids


func test_comeca_no_sonho_com_a_garota_e_nicholas_de_11_anos() -> void:
	assert_eq(capitulo.etapa, "sonho")
	assert_true(capitulo.objetos.has("garota"))
	var visual: AnimatedSprite2D = capitulo.jogador.get_node("Corpo/Visual")
	assert_string_contains(visual.sprite_frames.resource_path, "nicholas_11")
	assert_eq(capitulo.jogador.grade, capitulo.sala.chao)


func test_a_manha_inteira_na_ordem() -> void:
	capitulo.chegar_na_garota()
	await _esperar_etapa("quarto")
	assert_false(capitulo.jogador.em_dialogo, "no quarto ele anda de novo")
	_interagir("porta_quarto")
	assert_eq(capitulo.etapa, "quarto", "de pijama a porta não abre")
	await _vestir()
	assert_true(capitulo.viu_espelho)
	assert_true(Codice.tem("roupas_simples"))
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")
	await _esperar_o_cortejo()
	assert_true(Codice.tem("faixa_dourada"))
	capitulo.sentar_a_mesa()
	assert_eq(capitulo.etapa, "quarto_althea", "a mesa só depois de acordar Althea")
	await _acordar_e_entregar()
	assert_true(Codice.tem("monstro_marinho"))
	assert_true(Codice.tem("presentes"))
	assert_true(capitulo.objetos.has("althea"), "Althea de pé depois de acordar")
	assert_false(capitulo.objetos["embrulho"].visible)
	var na_mesa: Vector2i = capitulo.sala.chao.local_to_map(capitulo.objetos["althea"].position)
	assert_eq(na_mesa, Vector2i(3, 4), "Althea espera à mesa de chá")
	_interagir("althea")
	await _esperar_etapa("palacio")
	assert_true(Codice.tem("imperatriz_callie"))
	for i in 10:
		if capitulo.cena_pedida != "":
			break
		await wait_physics_frames(1)
	assert_eq(capitulo.cena_pedida, "res://scenes/capitulo_01/cena_palacio.tscn")


func test_fora_de_ordem_nao_avanca() -> void:
	capitulo.pegar_roupas()
	capitulo.olhar_espelho()
	capitulo.sair_do_quarto()
	capitulo.esperar_cortejo()
	capitulo.olhar_extremidade("extremidade_esq")
	capitulo.acordar_althea()
	capitulo.entregar_embrulho()
	capitulo.sentar_a_mesa()
	assert_eq(capitulo.etapa, "sonho")
	assert_false(capitulo.pegou_roupas)
	assert_eq(capitulo.toques_na_cama, 0)
	assert_true(Codice.anotados.is_empty())


func test_corredor_tem_oito_passos_entre_as_portas() -> void:
	await _ate_o_corredor()
	var de_nicholas: Vector2 = capitulo.objetos["porta_nicholas"].position
	var de_althea: Vector2 = capitulo.objetos["porta_althea"].position
	var casas := capitulo.sala.chao.local_to_map(de_nicholas) - capitulo.sala.chao.local_to_map(de_althea)
	assert_eq(casas, Vector2i(8, 0))


func test_falas_estao_no_elenco() -> void:
	# Todos os caminhos de todas as conversas (cada opção de cada escolha).
	for marcador in ["espelho_sem_roupa", "cortejo", "acordar_althea", "espada", "espada_escolha",
			"espada_fim", "anuncio_do_duque", "duque", "duque_tarefa", "planos", "janela", "carruagem"]:
		var pendentes: Array[String] = [marcador]
		var vistos := {}
		while not pendentes.is_empty():
			var id: String = pendentes.pop_back()
			if vistos.has(id):
				continue
			vistos[id] = true
			var linha: DialogueLine = await ROTEIRO.get_next_dialogue_line(id)
			if linha == null:
				continue
			if linha.character != "":
				assert_not_null(Elenco.buscar(linha.character), linha.character)
			else:
				assert_false(linha.text.contains(": "), "narração com dois-pontos: %s" % linha.text)
			for opcao: DialogueResponse in linha.responses:
				assert_eq(opcao.character, "", "dois-pontos na opção: %s" % opcao.text)
				pendentes.append(opcao.next_id)
			if linha.responses.is_empty():
				pendentes.append(linha.next_id)
	Relacoes.limpar()
	Codice.limpar()


func test_cada_escolha_volta_para_a_linha_principal() -> void:
	for opcao in 2:
		var ids := await _percorrer("cortejo", [opcao] as Array[int])
		assert_has(ids, "CAP1_040", "cortejo, opção %d" % opcao)
	# Na espada e no duque, a escolha só marca qual frase vem no alto; depois o
	# script segue para a linha principal (espada_fim, duque_tarefa).
	var marcas: Array[String] = []
	var anotar := func(marca: String) -> void: marcas.append(marca)
	DialogueManager.passed_cue.connect(anotar)
	var caminhos := {
		"espada_escolha": ["escolheu_rendicao", "escolheu_desvio"],
		"duque": ["escolheu_olhar_althea", "escolheu_encarar"],
	}
	for marcador: String in caminhos:
		for opcao in 2:
			marcas.clear()
			await _percorrer(marcador, [opcao] as Array[int])
			assert_has(marcas, caminhos[marcador][opcao], "%s, opção %d" % [marcador, opcao])
	DialogueManager.passed_cue.disconnect(anotar)
	assert_has(await _percorrer("espada_fim", [] as Array[int]), "CAP1_054")
	assert_has(await _percorrer("duque_tarefa", [] as Array[int]), "CAP1_071")
	Relacoes.limpar()


func test_escolhas_mudam_so_o_tom() -> void:
	await _percorrer("cortejo", [0] as Array[int])
	assert_eq(Relacoes.valor("pany"), -1, "reclamar da demora")
	Relacoes.limpar()
	await _percorrer("cortejo", [1] as Array[int])
	assert_eq(Relacoes.valor("pany"), 1, "deixar para lá")
	Relacoes.limpar()
	await _percorrer("espada_escolha", [0] as Array[int])
	assert_eq(Relacoes.valor("althea"), 1, "fingir rendição")
	Relacoes.limpar()
	await _percorrer("espada_escolha", [1] as Array[int])
	assert_eq(Relacoes.valor("althea"), 0, "desviar, rindo")
	await _percorrer("duque", [0] as Array[int])
	assert_eq(Relacoes.valor("althea"), 1, "olhar para Althea")
	Relacoes.limpar()
	await _percorrer("duque", [1] as Array[int])
	assert_eq(Relacoes.valor("apollon"), -1, "encarar o duque")


func test_janela_da_carruagem_anota_atenas_e_o_palacio() -> void:
	var menu: DialogueLine = await ROTEIRO.get_next_dialogue_line("janela")
	var rotulos := menu.responses.map(func(r: DialogueResponse) -> String: return r.text)
	assert_eq(rotulos, ["[Olhar pela janela da esquerda]", "[Olhar pela janela da direita]",
		"[Voltar-se para Althea]"])
	var ids := await _percorrer("janela", [0, 1, 2] as Array[int])
	assert_true(Codice.tem("atenas"))
	assert_true(Codice.tem("palacio_imperial"))
	assert_has(ids, "CAP1_104")
	assert_has(ids, "CAP1_105")
	# Voltar-se para Althea sem olhar nada termina o menu na hora.
	Codice.limpar()
	ids = await _percorrer("janela", [2] as Array[int])
	assert_eq(ids.size(), 2, "só o menu e a opção: %s" % [ids])
	assert_false(Codice.tem("atenas"))


func test_espelho_nao_veste_antes_do_armario() -> void:
	capitulo.chegar_na_garota()
	await _esperar_etapa("quarto")
	_interagir("espelho")
	await wait_physics_frames(5)
	assert_false(capitulo.viu_espelho)
	assert_false(capitulo.vestido)
	assert_false(Codice.tem("roupas_simples"))
	_interagir("porta_quarto")
	assert_eq(capitulo.etapa, "quarto", "sem roupa a porta não abre")
	_interagir("armario")
	assert_true(capitulo.pegou_roupas)
	assert_true(Codice.tem("roupas_simples"))
	await _vestir()
	assert_true(capitulo.vestido)


func test_cortejo_espera_nicholas_olhar_as_duas_extremidades() -> void:
	await _ate_o_corredor()
	var area_esq: Interagivel = capitulo.objetos["extremidade_esq"].get_node("Interagivel")
	assert_false(area_esq.is_in_group(Interagivel.GRUPO_INTERAGIVEIS), "antes de esperar, nada a olhar")
	_interagir("porta_althea")
	await _esperar_etapa("esperando")
	assert_false(capitulo.jogador.em_dialogo, "ele pode andar pelo corredor")
	await wait_physics_frames(10)
	assert_eq(capitulo.etapa, "esperando", "o cortejo não vem sozinho")
	var area: Interagivel = capitulo.objetos["extremidade_esq"].get_node("Interagivel")
	assert_true(area.is_in_group(Interagivel.GRUPO_INTERAGIVEIS), "as extremidades se acendem")
	assert_false(capitulo.objetos.has("pany"))
	_interagir("extremidade_dir")
	assert_true(Codice.tem("faixa_dourada"))
	_interagir("extremidade_dir")
	await wait_physics_frames(10)
	assert_eq(capitulo.etapa, "esperando", "a mesma extremidade duas vezes não basta")
	_interagir("extremidade_esq")
	await _esperar_etapa("quarto_althea")


## Virar uma vez para cada lado basta, com qualquer tecla para aquele lado
## (antes só a diagonal exata contava e parecia preciso olhar duas vezes).
func test_virar_uma_vez_para_cada_lado_basta() -> void:
	await _ate_o_corredor()
	_interagir("porta_althea")
	await _esperar_etapa("esperando")
	capitulo.jogador.direcao_olhar = Vector2.LEFT
	await wait_physics_frames(30)
	assert_true(capitulo.extremidades_vistas.has("extremidade_esq"), "a seta para a esquerda conta")
	capitulo.jogador.direcao_olhar = Vector2.RIGHT
	await wait_physics_frames(30)
	assert_true(capitulo.extremidades_vistas.has("extremidade_dir"), "a seta para a direita conta")
	await _esperar_etapa("quarto_althea")


func test_althea_so_acorda_no_segundo_toque() -> void:
	await _ate_o_corredor()
	await _esperar_o_cortejo()
	var embrulho: Interagivel = capitulo.objetos["embrulho"].get_node("Interagivel")
	assert_false(embrulho.is_in_group(Interagivel.GRUPO_INTERAGIVEIS), "o embrulho espera Althea acordar")
	_interagir("cama_althea")
	await wait_physics_frames(5)
	assert_eq(capitulo.etapa, "quarto_althea")
	assert_eq(capitulo.toques_na_cama, 1)
	assert_true(Codice.tem("monstro_marinho"))
	assert_false(capitulo.objetos.has("althea"), "ainda dormindo")
	_interagir("cama_althea")
	await _esperar_etapa("embrulho")
	assert_true(capitulo.objetos.has("althea"))


func test_o_embrulho_entregue_abre_a_espada() -> void:
	await _ate_o_corredor()
	await _esperar_o_cortejo()
	_interagir("cama_althea")
	_interagir("cama_althea")
	await _esperar_etapa("embrulho")
	await wait_physics_frames(10)
	var area: Interagivel = capitulo.objetos["embrulho"].get_node("Interagivel")
	assert_true(area.is_in_group(Interagivel.GRUPO_INTERAGIVEIS), "o embrulho se acende")
	assert_eq(capitulo.etapa, "embrulho", "espera Nicholas entregar")
	assert_true(capitulo.objetos["embrulho"].visible)
	watch_signals(capitulo)
	_interagir("embrulho")
	await _esperar_etapa("a_mesa")
	assert_signal_emitted_with_parameters(capitulo, "etapa_mudou", ["espada"], 0)
	assert_false(capitulo.objetos["embrulho"].visible)
	assert_true(Codice.tem("presentes"))


func test_mansao_tem_a_identidade_do_castelo_do_prologo() -> void:
	assert_true(capitulo.sala.parede_lisa, "o corredor do sonho não é da Casa Olympia")
	capitulo.chegar_na_garota()
	await _esperar_etapa("quarto")
	assert_false(capitulo.sala.parede_lisa)
	assert_not_null(capitulo.sala.get_node_or_null("QuadroOlympiaDir"))
	assert_not_null(capitulo.sala.get_node_or_null("Armario"))
	assert_not_null(capitulo.sala.get_node_or_null("Bau"))
	await _vestir()
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")
	assert_eq(capitulo.sala.piso, "passadeira")
	assert_eq(capitulo.sala.chao.get_cell_atlas_coords(Vector2i(3, 1)).x, SalaMontada.PASSADEIRA_CIMA)
	assert_not_null(capitulo.sala.get_node_or_null("EspadaPlacaEsq"))
	assert_not_null(capitulo.sala.get_node_or_null("TochaEsq2"))


func test_acorda_de_pijama_e_se_veste_no_espelho() -> void:
	var visual: AnimatedSprite2D = capitulo.jogador.get_node("Corpo/Visual")
	assert_string_contains(visual.sprite_frames.resource_path, "pijama")
	capitulo.chegar_na_garota()
	await _esperar_etapa("quarto")
	await _vestir()
	assert_string_contains(visual.sprite_frames.resource_path, "nicholas_11_exploracao")


func test_nicholas_anda_mais_devagar() -> void:
	assert_lt(capitulo.jogador.velocidade, 90.0)


func test_corredor_com_outras_portas_e_nao_comprido_demais() -> void:
	# Rafael, 16/10/2026: o corredor de 26 casas era comprido demais.
	await _ate_o_corredor()
	assert_between(capitulo.sala.largura, 12, 18)
	var fechadas := capitulo.objetos.keys().filter(func(k: String) -> bool: return k.begins_with("porta_fechada"))
	assert_gte(fechadas.size(), 2)


func _anotar_carruagem(etapa: String) -> void:
	if etapa == "carruagem":
		na_carruagem = {"apollon": capitulo.objetos.has("apollon"),
			"carro": capitulo.sala.has_node("Carruagem"), "sentado": capitulo.jogador.em_dialogo}


func test_o_duque_entra_e_depois_a_carruagem() -> void:
	await _ate_o_corredor()
	await _esperar_o_cortejo()
	await _acordar_e_entregar()
	# Sem tempos (escala 0) a carruagem pode passar entre dois quadros: o
	# estado é anotado no instante em que a etapa muda.
	na_carruagem = {}
	capitulo.etapa_mudou.connect(_anotar_carruagem)
	_interagir("althea")
	await _esperar_etapa("duque")
	await _esperar_etapa("palacio")
	assert_false(na_carruagem.is_empty(), "passou pela carruagem")
	assert_false(na_carruagem.get("apollon", true), "o duque já partiu")
	assert_true(na_carruagem.get("carro", false), "a carruagem na rua")
	assert_true(na_carruagem.get("sentado", false), "Nicholas fica sentado")


func test_o_duque_fala_de_frente_para_a_camera() -> void:
	await _ate_o_corredor()
	await _esperar_o_cortejo()
	await _acordar_e_entregar()
	var casa: Vector2i = capitulo.casa_do_duque()
	assert_lt(capitulo.sala.centro(casa).y, capitulo.jogador.position.y, "o duque fica acima de Nicholas na tela")


func test_moveis_do_quarto_nao_fecham_casas_do_corredor() -> void:
	# Antes, a navegação do corredor contava os móveis do quarto que ainda
	# não tinha saído da árvore: a casa (4, 1) ficava fechada.
	await _ate_o_corredor()
	await wait_physics_frames(5)
	for x in range(1, capitulo.sala.largura):
		for y in [1, 2]:
			var centro: Vector2 = capitulo.sala.centro(Vector2i(x, y))
			assert_true(capitulo.jogador.casa_andavel(centro), "casa %s livre" % Vector2i(x, y))


func test_virar_para_a_ponta_conta_como_olhar() -> void:
	await _ate_o_corredor()
	_interagir("porta_althea")
	await _esperar_etapa("esperando")
	capitulo.jogador.direcao_olhar = Vector2(-2, -1).normalized()
	await wait_seconds(Capitulo01.TEMPO_OLHANDO + 0.3)
	assert_true(capitulo.extremidades_vistas.has("extremidade_esq"))
	assert_false(capitulo.extremidades_vistas.has("extremidade_dir"))


func test_no_sonho_a_garota_e_solida() -> void:
	var garota: Node2D = capitulo.objetos["garota"]
	assert_true(garota.has_node("Corpo"), "a garota tem corpo")
	var jogador: PersonagemExploracao = capitulo.jogador
	var ate_ela := garota.global_position - jogador.global_position
	assert_true(jogador.test_move(jogador.global_transform, ate_ela), "não dá para atravessá-la")


func test_no_sonho_a_porta_nao_e_o_ponto_de_acao() -> void:
	assert_false(capitulo.objetos["porta_sonho"].has_node("Interagivel"))


func test_chegar_perto_da_garota_faz_ela_se_virar() -> void:
	await wait_physics_frames(5)   # ela já chegou na porta
	var garota: Node2D = capitulo.objetos["garota"]
	var casa: Vector2i = capitulo.sala.chao.local_to_map(garota.position)
	capitulo.jogador.position = capitulo.sala.centro(casa + Vector2i(1, 0))
	await _esperar_etapa("quarto")
	assert_false(capitulo.has_node("ArDoSonho"), "o ar do sonho some ao acordar")


func test_o_ar_do_sonho_mostra_que_nao_e_real() -> void:
	assert_true(capitulo.has_node("ArDoSonho"))
	assert_true(capitulo.get_node("ArDoSonho").has_node("Poeira"))


func test_no_sonho_nicholas_anda_devagar_ao_som_do_relogio() -> void:
	assert_eq(capitulo.jogador.velocidade, Capitulo01.VELOCIDADE_NO_SONHO)
	assert_eq(capitulo.jogador.multiplicador_corrida, 1.0, "no sonho ele não corre")
	assert_true(capitulo.get_node("ArDoSonho").has_node("TicTac"))
	capitulo.chegar_na_garota()
	await _esperar_etapa("quarto")
	assert_gt(capitulo.jogador.velocidade, Capitulo01.VELOCIDADE_NO_SONHO, "acordado, volta ao passo normal")


func test_na_porta_de_althea_nicholas_cruza_os_bracos_ate_se_mexer() -> void:
	var quadros: SpriteFrames = load("res://assets/art/personagens/nicholas/nicholas_11_exploracao.tres")
	for lado in ["frente", "costas"]:
		assert_true(quadros.has_animation("bracos_cruzados_%s" % lado), "bracos_cruzados_%s" % lado)
	await _ate_o_corredor()
	_interagir("porta_althea")
	await _esperar_etapa("esperando")
	var visual: AnimatedSprite2D = capitulo.jogador.get_node("Corpo/Visual")
	assert_string_starts_with(visual.animation, "bracos_cruzados_", "\"Cruzei os braços e esperei.\"")
	await wait_physics_frames(3)
	assert_string_starts_with(visual.animation, "bracos_cruzados_", "parado, continua de braços cruzados")
	capitulo.jogador.direcao_olhar = Vector2(1, -1).normalized()
	await wait_physics_frames(3)
	assert_true(visual.is_processing(), "ao se mexer, o desenho volta a seguir o movimento")
	assert_false(String(visual.animation).begins_with("bracos_cruzados_"), "e descruza os braços")


func test_com_o_duque_althea_segura_a_espada_e_a_aperta_no_peito() -> void:
	var quadros: SpriteFrames = load("res://assets/art/personagens/althea/althea_6_exploracao.tres")
	for pose in ["espada_colo", "abraca_espada"]:
		for lado in ["frente", "costas"]:
			assert_true(quadros.has_animation("%s_%s" % [pose, lado]), "%s_%s" % [pose, lado])
	await _ate_o_corredor()
	await _esperar_o_cortejo()
	await _acordar_e_entregar()
	var visual: AnimatedSprite2D = capitulo.objetos["althea"].get_node("Visual")
	capitulo._pose_de_althea(&"espada_colo")
	assert_string_starts_with(visual.animation, "espada_colo_", "no colo enquanto o duque fala")
	var linha := DialogueLine.new()
	linha.static_id = "CAP1_070"
	capitulo._ao_ver_fala_do_duque(linha)
	assert_string_starts_with(visual.animation, "abraca_espada_", "\"P-parem de brigar...\"")


## A espada: Althea golpeia de uma casa acima e ao lado de Nicholas na tela,
## nunca bem em cima (o desenho golpearia para o lado, contra a parede).
func test_althea_golpeia_na_direcao_de_nicholas() -> void:
	await _ate_o_corredor()
	await _esperar_o_cortejo()
	_interagir("cama_althea")
	_interagir("cama_althea")
	await _esperar_etapa("embrulho")
	for casa: Vector2i in [Vector2i(2, 3), Vector2i(1, 4), Vector2i(3, 3), Vector2i(4, 2)]:
		capitulo.jogador.position = capitulo.sala.centro(casa)
		await capitulo._althea_de_frente()
		var ate_ela: Vector2 = capitulo.objetos["althea"].position - capitulo.jogador.position
		assert_true(absf(ate_ela.x) > 8.0, "ao lado dele na tela (%s)" % casa)
		assert_true(ate_ela.y <= 1.0, "não abaixo dele (%s)" % casa)


## Até a escolha, Althea vai atrás de Nicholas golpeando quando ele se afasta.
func test_althea_segue_nicholas_golpeando() -> void:
	await _ate_o_corredor()
	await _esperar_o_cortejo()
	_interagir("cama_althea")
	_interagir("cama_althea")
	await _esperar_etapa("embrulho")
	capitulo.jogador.position = capitulo.sala.centro(Vector2i(2, 3))
	await capitulo._althea_de_frente()
	capitulo.escala_tempo = 1.0
	capitulo._golpeando = true
	capitulo._golpe_de_althea(0)
	capitulo.jogador.position = capitulo.sala.centro(Vector2i(4, 2))
	await wait_seconds(3.0)
	capitulo._golpeando = false
	capitulo.escala_tempo = 0.0
	var althea: Node2D = capitulo.objetos["althea"]
	assert_almost_eq(althea.position.distance_to(capitulo.jogador.position), 0.0,
		capitulo.DISTANCIA_DO_GOLPE, "ela foi atrás dele")
