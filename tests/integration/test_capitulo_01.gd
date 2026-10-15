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
	_interagir("porta_sonho")
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
	_interagir("porta_sonho")
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
	await _esperar_etapa("fim")
	assert_true(Codice.tem("imperatriz_callie"))
	for i in 10:
		if capitulo.cena_pedida != "":
			break
		await wait_physics_frames(1)
	assert_eq(capitulo.cena_pedida, "res://scenes/main/main.tscn")


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
	for marcador in ["cortejo", "acordar_althea", "espada", "duque", "planos", "janela", "carruagem"]:
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
	var caminhos := {
		"cortejo": "CAP1_040",
		"espada": "CAP1_054",
		"duque": "CAP1_071",
	}
	for marcador: String in caminhos:
		for opcao in 2:
			var ids := await _percorrer(marcador, [opcao] as Array[int])
			assert_has(ids, caminhos[marcador], "%s, opção %d" % [marcador, opcao])


func test_escolhas_mudam_so_o_tom() -> void:
	await _percorrer("cortejo", [0] as Array[int])
	assert_eq(Relacoes.valor("pany"), -1, "reclamar da demora")
	Relacoes.limpar()
	await _percorrer("cortejo", [1] as Array[int])
	assert_eq(Relacoes.valor("pany"), 1, "deixar para lá")
	Relacoes.limpar()
	await _percorrer("espada", [0] as Array[int])
	assert_eq(Relacoes.valor("althea"), 1, "fingir rendição")
	Relacoes.limpar()
	await _percorrer("espada", [1] as Array[int])
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
	_interagir("porta_sonho")
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
	_interagir("porta_sonho")
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
	_interagir("porta_sonho")
	await _esperar_etapa("quarto")
	await _vestir()
	assert_string_contains(visual.sprite_frames.resource_path, "nicholas_11_exploracao")


func test_nicholas_anda_mais_devagar() -> void:
	assert_lt(capitulo.jogador.velocidade, 90.0)


func test_corredor_comprido_com_outras_portas() -> void:
	await _ate_o_corredor()
	assert_gte(capitulo.sala.largura, 24)
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
	await _esperar_etapa("fim")
	assert_false(na_carruagem.is_empty(), "passou pela carruagem")
	assert_false(na_carruagem.get("apollon", true), "o duque já partiu")
	assert_true(na_carruagem.get("carro", false), "a carruagem na rua")
	assert_true(na_carruagem.get("sentado", false), "Nicholas fica sentado")
