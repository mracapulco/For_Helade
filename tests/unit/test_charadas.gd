extends GutTest
## Charadas dos convidados (Próskopos e Chymeía) nos acampamentos: acertar a
## primeira dá o prêmio maior; errar dá uma segunda charada com prêmio menor;
## errar as duas não dá nada. Depois disso, a charada não volta.

const ROTEIRO := preload("res://data/dialogos/acampamentos/acampamento.dialogue")


func before_each() -> void:
	Inventario.limpar()


func after_all() -> void:
	Inventario.limpar()


## Percorre o diálogo a partir de [param cue], escolhendo as respostas pelo
## texto, na ordem. Devolve os textos das falas.
func _conversar(cue: String, escolhas: Array[String]) -> Array[String]:
	var falas: Array[String] = []
	var linha: DialogueLine = await ROTEIRO.get_next_dialogue_line(cue)
	while linha != null:
		if not linha.responses.is_empty():
			var escolha: String = escolhas.pop_front()
			var proxima := ""
			for resposta: DialogueResponse in linha.responses:
				if resposta.text == escolha:
					proxima = resposta.next_id
			assert_ne(proxima, "", "resposta '%s' não existe" % escolha)
			falas.append(linha.text)
			linha = await ROTEIRO.get_next_dialogue_line(proxima)
			continue
		falas.append(linha.text)
		linha = await ROTEIRO.get_next_dialogue_line(linha.next_id)
	return falas


func test_proskopos_acerta_de_primeira() -> void:
	await _conversar("rafael", ["O fogo"])
	assert_true(Inventario.tem("pederneira_viajante"))
	assert_false(Inventario.tem("corda_trancada"))
	var depois := await _conversar("rafael", [])
	assert_eq(depois.size(), 1, "depois de respondida, só cumprimenta")


func test_proskopos_erra_e_acerta_a_segunda() -> void:
	await _conversar("rafael", ["O vento", "O buraco"])
	assert_false(Inventario.tem("pederneira_viajante"))
	assert_true(Inventario.tem("corda_trancada"))


func test_proskopos_erra_as_duas_e_nao_tem_outra_chance() -> void:
	await _conversar("rafael", ["A sombra", "A trilha"])
	assert_false(Inventario.tem("pederneira_viajante"))
	assert_false(Inventario.tem("corda_trancada"))
	assert_eq((await _conversar("rafael", [])).size(), 1)


func test_chymeia_acerta_de_primeira() -> void:
	await _conversar("shara", ["O vapor"])
	assert_true(Inventario.tem("agua_luminosa_agape"))
	assert_false(Inventario.tem("sal_do_mar"))


func test_chymeia_erra_e_acerta_a_segunda() -> void:
	await _conversar("shara", ["A névoa", "O sal"])
	assert_false(Inventario.tem("agua_luminosa_agape"))
	assert_true(Inventario.tem("sal_do_mar"))


func test_chymeia_erra_as_duas() -> void:
	await _conversar("shara", ["A fumaça", "A espuma"])
	assert_false(Inventario.tem("agua_luminosa_agape"))
	assert_false(Inventario.tem("sal_do_mar"))
	assert_eq((await _conversar("shara", [])).size(), 1)


func test_premio_maior_vale_mais() -> void:
	assert_gt(Inventario.item("pederneira_viajante").preco, Inventario.item("corda_trancada").preco)
	assert_gt(Inventario.item("agua_luminosa_agape").preco, Inventario.item("sal_do_mar").preco)
	for id in ["pederneira_viajante", "corda_trancada", "agua_luminosa_agape", "sal_do_mar"]:
		assert_ne(tr(Inventario.item(id).chave_nome), Inventario.item(id).chave_nome, "%s sem nome traduzido" % id)
