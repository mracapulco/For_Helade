extends GutTest
## Ligações do mapa de Hélade, sem tela.

const ACAMPAMENTOS := ["ag_acampamento", "an_acampamento", "at_acampamento", "ilha_acampamento",
	"ilhota_acampamento", "nt_acampamento", "oa_acampamento", "og_acampamento", "ot_acampamento"]

var grafo: GrafoMapa
var todos: Dictionary


func before_each() -> void:
	grafo = GrafoMapa.da_pasta()
	todos = {}
	for id: String in grafo.locais:
		todos[id] = true


func _do_tipo(tipo: LocalMapa.Tipo) -> Array:
	var lista: Array = []
	for id: String in grafo.locais:
		if grafo.local(id).tipo == tipo:
			lista.append(id)
	lista.sort()
	return lista


func test_tem_as_seis_regioes_do_mapa() -> void:
	assert_eq(_do_tipo(LocalMapa.Tipo.REGIAO), ["agape", "atenas", "floresta_ninfas", "norte", "olympia", "templo"])


func test_cada_local_tem_nome_traduzido() -> void:
	TranslationServer.set_locale("pt_BR")
	for id: String in grafo.locais:
		var local := grafo.local(id)
		assert_eq(local.id, id)
		assert_ne(tr(local.chave_nome), local.chave_nome, "%s sem nome no strings.csv" % id)
		assert_ne(tr(local.chave_regiao), local.chave_regiao, "%s sem linha de baixo no strings.csv" % id)


func test_no_maximo_uma_saida_por_direcao() -> void:
	for id: String in grafo.locais:
		var usadas := {}
		for vizinho in grafo.vizinhos(id):
			var direcao := grafo.direcao(id, vizinho)
			assert_false(usadas.has(direcao), "%s tem duas saídas para %s" % [id, direcao])
			usadas[direcao] = vizinho


func test_regioes_vizinhas_tem_etapas_no_meio() -> void:
	for par: Array in grafo.ligacoes():
		var a := grafo.local(par[0])
		var b := grafo.local(par[1])
		assert_false(a.tipo == LocalMapa.Tipo.REGIAO and b.tipo == LocalMapa.Tipo.REGIAO,
			"%s e %s ligados direto" % [a.id, b.id])


func test_um_acampamento_em_cada_caminho_com_cena() -> void:
	assert_eq(_do_tipo(LocalMapa.Tipo.ACAMPAMENTO), ACAMPAMENTOS)
	for id in ACAMPAMENTOS:
		assert_eq(grafo.local(id).cena, "res://scenes/exploracao/acampamentos/%s.tscn" % id)


func test_cada_caminho_entre_reinos_passa_por_um_acampamento() -> void:
	var sem_acampamentos := todos.duplicate()
	for id in ACAMPAMENTOS:
		sem_acampamentos.erase(id)
	for a in ["olympia", "atenas", "agape", "norte", "templo", "floresta_ninfas"]:
		for b in ["olympia", "atenas", "agape", "norte", "templo", "floresta_ninfas"]:
			if a != b:
				assert_eq(grafo.caminho(a, b, sem_acampamentos), [] as Array[String], "%s -> %s sem parar" % [a, b])


func test_olympia_a_atenas_tem_estrada_principal_e_trilha() -> void:
	var principal := grafo.caminho("olympia", "atenas", todos)
	assert_has(principal, "oa_acampamento")
	assert_gte(principal.size(), 7, "pelo menos o dobro de pontos de antes")
	var sem_principal := todos.duplicate()
	sem_principal.erase("oa_acampamento")
	sem_principal.erase("agape")
	var trilha := grafo.caminho("olympia", "atenas", sem_principal)
	assert_has(trilha, "ot_acampamento")
	assert_gt(trilha.size(), principal.size(), "a trilha é mais longa")


func test_floresta_das_ninfas_so_por_mar_saindo_de_dois_portos() -> void:
	for vizinho in grafo.vizinhos("floresta_ninfas"):
		assert_true(grafo.por_mar("floresta_ninfas", vizinho))
	var portos := _do_tipo(LocalMapa.Tipo.PORTO)
	assert_eq(portos, ["porto_agape", "porto_olympia"])
	for porto in portos:
		var outros := todos.duplicate()
		outros.erase(portos[0] if porto == portos[1] else portos[1])
		assert_false(grafo.caminho(porto, "floresta_ninfas", outros).is_empty(), porto)


func test_todo_local_alcanca_todos_os_outros() -> void:
	for a: String in grafo.locais:
		for b: String in grafo.locais:
			assert_false(grafo.caminho(a, b, todos).is_empty(), "%s -> %s" % [a, b])


func test_caminho_desvia_de_local_bloqueado() -> void:
	var sem_atenas := todos.duplicate()
	sem_atenas.erase("atenas")
	var volta := grafo.caminho("olympia", "norte", sem_atenas)
	assert_has(volta, "agape")
	assert_has(volta, "templo")


func test_saidas_de_olympia_e_atenas_pelas_setas() -> void:
	assert_eq(grafo.vizinho_na_direcao("olympia", Vector2.UP, todos), "og_estrada_1")
	assert_eq(grafo.vizinho_na_direcao("olympia", Vector2.LEFT, todos), "oa_estrada_1")
	assert_eq(grafo.vizinho_na_direcao("olympia", Vector2.DOWN, todos), "ot_trilha_1")
	assert_eq(grafo.vizinho_na_direcao("olympia", Vector2.RIGHT, todos), "po_estrada")
	assert_eq(grafo.vizinho_na_direcao("atenas", Vector2.UP, todos), "an_estrada_1")
	assert_eq(grafo.vizinho_na_direcao("atenas", Vector2.RIGHT, todos), "ag_estrada_1")
	assert_eq(grafo.vizinho_na_direcao("atenas", Vector2.DOWN, todos), "oa_estrada_4")
	assert_eq(grafo.vizinho_na_direcao("atenas", Vector2.LEFT, todos), "ot_trilha_8")
	assert_eq(grafo.vizinho_na_direcao("norte", Vector2.LEFT, todos), "")


func test_seta_nao_vai_para_local_na_nevoa() -> void:
	assert_eq(grafo.vizinho_na_direcao("olympia", Vector2.UP, {"olympia": true}), "")
