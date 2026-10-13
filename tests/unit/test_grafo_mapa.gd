extends GutTest
## Ligações do mapa de Hélade, sem tela.

var grafo: GrafoMapa
var todos: Dictionary


func before_each() -> void:
	grafo = GrafoMapa.da_pasta()
	todos = {}
	for id: String in grafo.locais:
		todos[id] = true


func test_tem_as_seis_regioes_do_mapa() -> void:
	var regioes: Array = []
	for id: String in grafo.locais:
		if grafo.local(id).tipo == LocalMapa.Tipo.REGIAO:
			regioes.append(id)
	regioes.sort()
	assert_eq(regioes, ["agape", "atenas", "floresta_ninfas", "norte", "olympia", "templo"])


func test_regioes_vizinhas_tem_etapas_no_meio() -> void:
	for par: Array in grafo.ligacoes():
		var a := grafo.local(par[0])
		var b := grafo.local(par[1])
		assert_false(a.tipo == LocalMapa.Tipo.REGIAO and b.tipo == LocalMapa.Tipo.REGIAO,
			"%s e %s ligados direto" % [a.id, b.id])


func test_olympia_a_atenas_tem_estrada_principal_e_secundaria() -> void:
	var sem_principal := todos.duplicate()
	sem_principal.erase("oa_acampamento")
	assert_eq(grafo.caminho("olympia", "atenas", todos),
		["olympia", "oa_estrada_1", "oa_acampamento", "oa_estrada_2", "atenas"] as Array[String])
	assert_eq(grafo.caminho("olympia", "atenas", sem_principal),
		["olympia", "oa_trilha_1", "oa_trilha_2", "atenas"] as Array[String])


func test_barcos_saem_de_mais_de_um_porto() -> void:
	var portos := 0
	for vizinho in grafo.vizinhos("floresta_ninfas"):
		assert_eq(grafo.local(vizinho).tipo, LocalMapa.Tipo.PORTO)
		portos += 1
	assert_gte(portos, 2)


func test_cada_local_tem_nome_traduzido() -> void:
	TranslationServer.set_locale("pt_BR")
	for id: String in grafo.locais:
		var local := grafo.local(id)
		assert_eq(local.id, id)
		assert_ne(tr(local.chave_nome), local.chave_nome, "%s sem nome no strings.csv" % id)


func test_ligacoes_valem_para_os_dois_lados() -> void:
	assert_has(grafo.vizinhos("olympia"), "oa_estrada_1")
	assert_has(grafo.vizinhos("oa_estrada_1"), "olympia")


func test_floresta_das_ninfas_so_por_mar() -> void:
	for vizinho in grafo.vizinhos("floresta_ninfas"):
		assert_true(grafo.por_mar("floresta_ninfas", vizinho))
	assert_false(grafo.vizinhos("floresta_ninfas").is_empty())


func test_caminho_mais_curto() -> void:
	assert_eq(grafo.caminho("olympia", "norte", todos), ["olympia", "oa_estrada_1", "oa_acampamento",
		"oa_estrada_2", "atenas", "an_estrada", "an_acampamento", "norte"] as Array[String])


func test_caminho_desvia_de_local_bloqueado() -> void:
	var sem_atenas := todos.duplicate()
	sem_atenas.erase("atenas")
	assert_eq(grafo.caminho("olympia", "norte", sem_atenas), ["olympia", "og_estrada", "agape",
		"at_estrada", "templo", "nt_estrada", "norte"] as Array[String])


func test_sem_caminho_quando_destino_bloqueado() -> void:
	var sem_norte := todos.duplicate()
	sem_norte.erase("norte")
	assert_eq(grafo.caminho("olympia", "norte", sem_norte), [] as Array[String])


func test_todo_local_alcanca_todos_os_outros() -> void:
	for a: String in grafo.locais:
		for b: String in grafo.locais:
			assert_false(grafo.caminho(a, b, todos).is_empty(), "%s -> %s" % [a, b])


func test_vizinho_na_direcao() -> void:
	assert_eq(grafo.vizinho_na_direcao("atenas", Vector2.UP, todos), "an_estrada")
	assert_eq(grafo.vizinho_na_direcao("atenas", Vector2.RIGHT, todos), "ag_estrada")
	assert_eq(grafo.vizinho_na_direcao("agape", Vector2.RIGHT, todos), "porto_agape")
	assert_eq(grafo.vizinho_na_direcao("porto_agape", Vector2.RIGHT, todos), "floresta_ninfas")
	assert_eq(grafo.vizinho_na_direcao("norte", Vector2.LEFT, todos), "")
