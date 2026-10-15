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
	assert_true(Inventario.tem("bordao_proskopos"))
	assert_false(Inventario.tem("racao_trilha"))
	var depois := await _conversar("rafael", [])
	assert_eq(depois.size(), 1, "depois de respondida, só cumprimenta")


func test_proskopos_erra_e_acerta_a_segunda() -> void:
	await _conversar("rafael", ["O vento", "O buraco"])
	assert_false(Inventario.tem("bordao_proskopos"))
	assert_true(Inventario.tem("racao_trilha"))


func test_proskopos_erra_as_duas_e_nao_tem_outra_chance() -> void:
	await _conversar("rafael", ["A sombra", "A trilha"])
	assert_false(Inventario.tem("bordao_proskopos"))
	assert_false(Inventario.tem("racao_trilha"))
	assert_eq((await _conversar("rafael", [])).size(), 1)


func test_chymeia_acerta_de_primeira() -> void:
	await _conversar("shara", ["O vapor"])
	assert_true(Inventario.tem("elixir_chymeia"))
	assert_false(Inventario.tem("pocao_cura"))


func test_chymeia_erra_e_acerta_a_segunda() -> void:
	await _conversar("shara", ["A névoa", "O sal"])
	assert_false(Inventario.tem("elixir_chymeia"))
	assert_true(Inventario.tem("pocao_cura"))


func test_chymeia_erra_as_duas() -> void:
	await _conversar("shara", ["A fumaça", "A espuma"])
	assert_false(Inventario.tem("elixir_chymeia"))
	assert_false(Inventario.tem("pocao_cura"))
	assert_eq((await _conversar("shara", [])).size(), 1)


func test_segunda_charada_da_mais_de_um() -> void:
	await _conversar("rafael", ["O vento", "O buraco"])
	await _conversar("shara", ["A névoa", "O sal"])
	assert_eq(Inventario.quantidade("racao_trilha"), 3)
	assert_eq(Inventario.quantidade("pocao_cura"), 2)


func test_premios_maiores_sao_raros_e_uteis() -> void:
	var bordao := Inventario.item("bordao_proskopos")
	assert_true(bordao.duas_maos())
	assert_gt(bordao.nivel, 1, "acima dos itens comuns")
	assert_gt(bordao.alcance, Balanceamento.ALCANCE_PADRAO)
	var elixir := Inventario.item("elixir_chymeia")
	assert_true(elixir.pode_usar())
	assert_true(elixir.tem_efeito_temporario())
	for id in ["pocao_cura", "pocao_rapidez", "pocao_vigor"]:
		var p := Inventario.item(id)
		assert_gt(elixir.cura, p.cura)
		assert_gte(elixir.velocidade_temporaria, p.velocidade_temporaria)
		assert_gte(elixir.vida_extra, p.vida_extra)


func test_premio_maior_vale_mais() -> void:
	assert_gt(Inventario.item("bordao_proskopos").preco, Inventario.item("racao_trilha").preco * 3)
	assert_gt(Inventario.item("elixir_chymeia").preco, Inventario.item("pocao_cura").preco * 2)
	for id in ["bordao_proskopos", "racao_trilha", "elixir_chymeia"]:
		assert_ne(tr(Inventario.item(id).chave_nome), Inventario.item(id).chave_nome, "%s sem nome traduzido" % id)


func test_bolsa_cheia_nao_gasta_a_charada() -> void:
	while Inventario.adicionar("espada_media"):
		pass
	var falas := await _conversar("rafael", [])
	assert_eq(falas.size(), 1, "só avisa que a bolsa está cheia")
	assert_false(Inventario.ja_coletado("charada_proskopos"))
