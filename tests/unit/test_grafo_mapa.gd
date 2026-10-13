extends GutTest
## Ligações do mapa de Hélade, sem tela.

var grafo: GrafoMapa
var todos: Dictionary


func before_each() -> void:
	grafo = GrafoMapa.da_pasta()
	todos = {}
	for id: String in grafo.locais:
		todos[id] = true


func test_tem_os_seis_locais_do_mapa() -> void:
	var ids: Array = grafo.locais.keys()
	ids.sort()
	assert_eq(ids, ["agape", "atenas", "floresta_ninfas", "norte", "olympia", "templo"])


func test_cada_local_tem_nome_traduzido() -> void:
	TranslationServer.set_locale("pt_BR")
	for id: String in grafo.locais:
		var local := grafo.local(id)
		assert_eq(local.id, id)
		assert_ne(tr(local.chave_nome), local.chave_nome, "%s sem nome no strings.csv" % id)


func test_ligacoes_valem_para_os_dois_lados() -> void:
	assert_has(grafo.vizinhos("olympia"), "atenas")
	assert_has(grafo.vizinhos("atenas"), "olympia")


func test_floresta_das_ninfas_so_por_mar() -> void:
	for vizinho in grafo.vizinhos("floresta_ninfas"):
		assert_true(grafo.por_mar("floresta_ninfas", vizinho))
	assert_false(grafo.vizinhos("floresta_ninfas").is_empty())


func test_caminho_mais_curto() -> void:
	assert_eq(grafo.caminho("olympia", "norte", todos), ["olympia", "atenas", "norte"] as Array[String])


func test_caminho_desvia_de_local_bloqueado() -> void:
	var sem_atenas := todos.duplicate()
	sem_atenas.erase("atenas")
	assert_eq(grafo.caminho("olympia", "norte", sem_atenas), ["olympia", "agape", "templo", "norte"] as Array[String])


func test_sem_caminho_quando_destino_bloqueado() -> void:
	var sem_norte := todos.duplicate()
	sem_norte.erase("norte")
	assert_eq(grafo.caminho("olympia", "norte", sem_norte), [] as Array[String])


func test_todo_local_alcanca_todos_os_outros() -> void:
	for a: String in grafo.locais:
		for b: String in grafo.locais:
			assert_false(grafo.caminho(a, b, todos).is_empty(), "%s -> %s" % [a, b])


func test_vizinho_na_direcao() -> void:
	assert_eq(grafo.vizinho_na_direcao("atenas", Vector2.UP, todos), "norte")
	assert_eq(grafo.vizinho_na_direcao("atenas", Vector2.RIGHT, todos), "agape")
	assert_eq(grafo.vizinho_na_direcao("agape", Vector2.RIGHT, todos), "floresta_ninfas")
	assert_eq(grafo.vizinho_na_direcao("norte", Vector2.LEFT, todos), "")
