extends GutTest
## Lógica da loja: estoque limitado, compra, venda pela metade, renovação
## ao descansar e o jogo salvo.

const CHYMEIA := "chymeia"


func before_each() -> void:
	Inventario.limpar()
	Lojas.limpar()


func after_all() -> void:
	Inventario.limpar()
	Lojas.limpar()


func test_a_loja_de_chymeia_vem_da_pasta() -> void:
	var loja := Lojas.loja(CHYMEIA)
	assert_not_null(loja)
	assert_eq(loja.origem, Item.Origem.AGAPE)
	assert_eq(Lojas.mercadorias(CHYMEIA), ["pocao_cura", "pocao_rapidez", "pocao_vigor", "racao_trilha"] as Array[String])
	assert_ne(tr(loja.chave_nome), loja.chave_nome, "nome traduzido")


func test_todo_item_vendido_existe_e_tem_preco() -> void:
	for id_loja in ["chymeia"]:
		for id in Lojas.mercadorias(id_loja):
			var item := Inventario.item(id)
			assert_not_null(item, "%s em %s" % [id, id_loja])
			if item:
				assert_gt(item.preco, 0, id)
				assert_false(item.e_da_historia(), id)
				assert_gt(Lojas.estoque(id_loja, id), 0, id)


func test_o_elixir_nao_esta_a_venda() -> void:
	assert_eq(Lojas.estoque(CHYMEIA, "elixir_chymeia"), 0)
	Inventario.ganhar_dinheiro(1000)
	assert_eq(Lojas.comprar(CHYMEIA, "elixir_chymeia"), Lojas.Resultado.NAO_VENDE)


func test_comprar_gasta_moedas_e_tira_do_estoque() -> void:
	Inventario.ganhar_dinheiro(100)
	var antes := Lojas.estoque(CHYMEIA, "pocao_cura")
	assert_eq(Lojas.comprar(CHYMEIA, "pocao_cura", 2), Lojas.Resultado.OK)
	assert_eq(Inventario.quantidade("pocao_cura"), 2)
	assert_eq(Inventario.dinheiro(), 100 - 2 * Inventario.item("pocao_cura").preco)
	assert_eq(Lojas.estoque(CHYMEIA, "pocao_cura"), antes - 2)


func test_sem_moedas_nao_compra() -> void:
	Inventario.ganhar_dinheiro(Inventario.item("pocao_vigor").preco - 1)
	assert_eq(Lojas.comprar(CHYMEIA, "pocao_vigor"), Lojas.Resultado.SEM_MOEDAS)
	assert_eq(Inventario.quantidade("pocao_vigor"), 0)
	assert_eq(Inventario.dinheiro(), Inventario.item("pocao_vigor").preco - 1)


func test_estoque_acaba() -> void:
	Inventario.ganhar_dinheiro(10000)
	var total := Lojas.estoque(CHYMEIA, "pocao_rapidez")
	assert_eq(Lojas.comprar(CHYMEIA, "pocao_rapidez", total + 1), Lojas.Resultado.SEM_ESTOQUE)
	assert_eq(Lojas.comprar(CHYMEIA, "pocao_rapidez", total), Lojas.Resultado.OK)
	assert_eq(Lojas.estoque(CHYMEIA, "pocao_rapidez"), 0)
	assert_eq(Lojas.comprar(CHYMEIA, "pocao_rapidez"), Lojas.Resultado.SEM_ESTOQUE)


func test_bolsa_cheia_nao_compra_nem_cobra() -> void:
	Inventario.ganhar_dinheiro(10000)
	while Inventario.cabe("punhal"):
		Inventario.adicionar("punhal")
	var moedas := Inventario.dinheiro()
	assert_false(Inventario.cabe("pocao_cura"), "bolsa cheia de punhais")
	assert_eq(Lojas.comprar(CHYMEIA, "pocao_cura"), Lojas.Resultado.BOLSA_CHEIA)
	assert_eq(Inventario.dinheiro(), moedas)
	assert_eq(Lojas.estoque(CHYMEIA, "pocao_cura"), Lojas.loja(CHYMEIA).itens["pocao_cura"])


func test_vender_paga_metade_do_preco() -> void:
	Inventario.adicionar("pocao_vigor", 2)
	assert_eq(Lojas.preco_venda("pocao_vigor"), Inventario.item("pocao_vigor").preco / 2)
	assert_eq(Lojas.vender("pocao_vigor"), Lojas.Resultado.OK)
	assert_eq(Inventario.quantidade("pocao_vigor"), 1)
	assert_eq(Inventario.dinheiro(), Lojas.preco_venda("pocao_vigor"))


func test_vender_arma_equipada_desequipa() -> void:
	Inventario.adicionar("punhal")
	Inventario.equipar("nicholas", "punhal")
	assert_eq(Lojas.vender("punhal"), Lojas.Resultado.OK)
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "")
	assert_eq(Inventario.quantidade("punhal"), 0)


func test_nao_vende_o_que_nao_tem() -> void:
	assert_eq(Lojas.vender("pocao_cura"), Lojas.Resultado.NAO_TEM)
	Inventario.adicionar("pocao_cura")
	assert_eq(Lojas.vender("pocao_cura", 2), Lojas.Resultado.NAO_TEM)
	assert_eq(Inventario.dinheiro(), 0)


func test_item_da_historia_nao_se_vende() -> void:
	Inventario.adicionar("carta_teste")
	assert_eq(Lojas.vender("carta_teste"), Lojas.Resultado.DA_HISTORIA)
	assert_true(Inventario.tem("carta_teste"))


func test_descansar_renova_o_estoque() -> void:
	Inventario.ganhar_dinheiro(10000)
	Lojas.comprar(CHYMEIA, "racao_trilha", 4)
	assert_eq(Lojas.estoque(CHYMEIA, "racao_trilha"), 2)
	Lojas.renovar()
	assert_eq(Lojas.estoque(CHYMEIA, "racao_trilha"), 6)


func test_o_estoque_vai_no_jogo_salvo() -> void:
	Inventario.ganhar_dinheiro(10000)
	Lojas.comprar(CHYMEIA, "pocao_cura", 3)
	var dados := Lojas.para_dados()
	Lojas.limpar()
	assert_eq(Lojas.estoque(CHYMEIA, "pocao_cura"), 5)
	Lojas.de_dados(dados)
	assert_eq(Lojas.estoque(CHYMEIA, "pocao_cura"), 2)


func test_dados_estranhos_nao_quebram() -> void:
	Lojas.de_dados({ "comprados": "lixo" })
	assert_eq(Lojas.estoque(CHYMEIA, "pocao_cura"), 5)
	Lojas.de_dados({})
	assert_eq(Lojas.estoque(CHYMEIA, "pocao_cura"), 5)


func test_loja_com_item_especifico_de_um_npc() -> void:
	var loja := Loja.new()
	loja.id = "teste_especial"
	loja.itens = { "bordao_proskopos": 1 }
	Lojas.registrar(loja)
	Inventario.ganhar_dinheiro(1000)
	assert_eq(Lojas.comprar("teste_especial", "bordao_proskopos"), Lojas.Resultado.OK)
	assert_eq(Lojas.comprar("teste_especial", "bordao_proskopos"), Lojas.Resultado.SEM_ESTOQUE)
	assert_eq(Lojas.estoque(CHYMEIA, "bordao_proskopos"), 0, "outra loja não vende")
	Lojas._catalogo.erase("teste_especial")
