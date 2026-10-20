extends GutTest
## Capítulo 01, cenas 7 a 10 (Palácio, Rua das Butiques e loja, restaurante):
## ordem das etapas, encadeamento, menu, códice, elenco e ajustes de relação.

const PALACIO: DialogueResource = preload("res://data/dialogos/capitulo_01/palacio.dialogue")
const BUTIQUES: DialogueResource = preload("res://data/dialogos/capitulo_01/butiques.dialogue")
const RESTAURANTE: DialogueResource = preload("res://data/dialogos/capitulo_01/restaurante.dialogue")


func before_each() -> void:
	Codice.limpar()
	Relacoes.limpar()


func after_each() -> void:
	Codice.limpar()
	Relacoes.limpar()


# --- ordem e encadeamento -------------------------------------------------

func test_ordem_das_etapas() -> void:
	assert_eq(SequenciaCenas01.ETAPAS,
		["palacio", "visao_carruagem", "butiques", "restaurante", "passeio"] as Array[String])
	assert_eq(SequenciaCenas01.proxima_etapa("palacio"), "visao_carruagem")
	assert_eq(SequenciaCenas01.proxima_etapa("butiques"), "restaurante")
	assert_eq(SequenciaCenas01.proxima_etapa("restaurante"), "passeio")
	assert_eq(SequenciaCenas01.proxima_etapa("passeio"), "")
	assert_eq(SequenciaCenas01.proxima_etapa("nao_existe"), "")


func test_cada_cena_chama_a_proxima_pulando_etapas_sem_cena() -> void:
	assert_eq(SequenciaCenas01.cena_depois("palacio"), SequenciaCenas01.CENAS["visao_carruagem"])
	assert_eq(SequenciaCenas01.cena_depois("visao_carruagem"), SequenciaCenas01.CENAS["butiques"])
	assert_eq(SequenciaCenas01.cena_depois("butiques"), SequenciaCenas01.CENAS["restaurante"])


func test_o_restaurante_volta_ao_menu_por_enquanto() -> void:
	assert_eq(SequenciaCenas01.cena_depois("restaurante"), SequenciaCenas01.MENU)
	assert_eq(SequenciaCenas01.cena_depois("desconhecida"), SequenciaCenas01.MENU)


func test_as_cenas_existem_e_a_manha_chama_o_palacio() -> void:
	for etapa: String in SequenciaCenas01.CENAS:
		assert_true(ResourceLoader.exists(SequenciaCenas01.CENAS[etapa]), etapa)
		assert_true(SequenciaCenas01.ETAPAS.has(etapa), etapa)
	assert_eq(SequenciaCenas01.cena_da_etapa("passeio"), "")
	var manha := Capitulo01.new()
	assert_eq(manha.cena_depois, SequenciaCenas01.CENAS["palacio"])
	manha.free()


func test_menu_tem_um_ponto_de_entrada_por_etapa() -> void:
	for etapa: String in SequenciaCenas01.CENAS:
		assert_eq(MenuInicial.cena_para_continuar(etapa), SequenciaCenas01.CENAS[etapa], etapa)
	assert_eq(MenuInicial.etapa_da_linha_de_comando(PackedStringArray(["--etapa=butiques"])), "butiques")
	assert_eq(MenuInicial.etapa_da_linha_de_comando(PackedStringArray(["--outra"])), "")


# --- códice ------------------------------------------------------------------

func test_entradas_novas_do_codice() -> void:
	var esperadas := {"olhos_de_ophelia": Codice.TIPO_OLHAR, "poucos_guardas": Codice.TIPO_OLHAR,
		"anexo_vazio": Codice.TIPO_OLHAR, "rua_das_butiques": Codice.TIPO_CODICE}
	for id: String in esperadas:
		assert_eq(Codice.tipo(id), esperadas[id], id)
		assert_ne(Codice.titulo(id), "CODICE_%s_TITULO" % id.to_upper(), id)
		assert_ne(Codice.texto(id), "CODICE_%s_TEXTO" % id.to_upper(), id)


func test_marcadores_anotam_o_codice() -> void:
	await _percorrer(PALACIO, "frases_poucos_guardas", [])
	await _percorrer(PALACIO, "apresentacao", [])
	await _percorrer(PALACIO, "frases_anexo_vazio", [])
	await _percorrer(BUTIQUES, "frases_rua", [])
	for id in ["poucos_guardas", "olhos_de_ophelia", "anexo_vazio", "rua_das_butiques"]:
		assert_true(Codice.tem(id), id)


# --- relações -----------------------------------------------------------------

func test_presente_ajusta_a_relacao_com_ophelia() -> void:
	var atencao := await _percorrer(BUTIQUES, "presente", [0] as Array[int])
	assert_eq(Relacoes.valor("ophelia"), 1)
	Relacoes.limpar()
	var seco := await _percorrer(BUTIQUES, "presente", [1] as Array[int])
	assert_eq(Relacoes.valor("ophelia"), -1)
	# As duas opções voltam para a mesma linha do livro.
	assert_has(atencao, "CAP1_175")
	assert_has(seco, "CAP1_175")


func test_sopa_ajusta_a_relacao_com_ophelia() -> void:
	var calma := await _percorrer(RESTAURANTE, "insistir", [0] as Array[int])
	assert_eq(Relacoes.valor("ophelia"), 1)
	Relacoes.limpar()
	var firme := await _percorrer(RESTAURANTE, "insistir", [1] as Array[int])
	assert_eq(Relacoes.valor("ophelia"), -1)
	assert_has(calma, "CAP1_193")
	assert_has(firme, "CAP1_193")


# --- elenco -------------------------------------------------------------------

func test_quem_fala_esta_no_elenco() -> void:
	for roteiro: DialogueResource in [PALACIO, BUTIQUES, RESTAURANTE]:
		for marcador: String in _marcadores(roteiro):
			var pendentes: Array[String] = [marcador]
			var vistos := {}
			while not pendentes.is_empty():
				var id: String = pendentes.pop_back()
				if vistos.has(id):
					continue
				vistos[id] = true
				var linha: DialogueLine = await roteiro.get_next_dialogue_line(id)
				if linha == null:
					continue
				if linha.character != "":
					assert_not_null(Elenco.buscar(linha.character), linha.character)
				for opcao: DialogueResponse in linha.responses:
					pendentes.append(opcao.next_id)
				if linha.responses.is_empty():
					pendentes.append(linha.next_id)


## Marcadores (`~ nome`) do arquivo .dialogue do roteiro.
func _marcadores(roteiro: DialogueResource) -> Array[String]:
	var nomes: Array[String] = []
	for linha in FileAccess.get_file_as_string(roteiro.resource_path).split("\n"):
		if linha.begins_with("~ "):
			nomes.append(linha.substr(2).strip_edges())
	return nomes


## Percorre o marcador (escolhendo [param escolhas] nas opções) e devolve os
## static_id por onde passou.
func _percorrer(roteiro: DialogueResource, marcador: String, escolhas: Array[int]) -> Array[String]:
	var ids: Array[String] = []
	var fala: DialogueLine = await roteiro.get_next_dialogue_line(marcador)
	var limite := 100
	while fala and limite > 0:
		limite -= 1
		ids.append(fala.static_id)
		if fala.responses.is_empty():
			fala = await roteiro.get_next_dialogue_line(fala.next_id)
		else:
			var opcao: DialogueResponse = fala.responses[escolhas.pop_front()]
			ids.append(opcao.static_id)
			fala = await roteiro.get_next_dialogue_line(opcao.next_id)
	return ids
