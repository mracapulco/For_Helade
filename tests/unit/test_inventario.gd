extends GutTest
## Lógica do inventário com itens criados no próprio teste, para não
## depender do que estiver em res://data/itens/.

const InventarioScript := preload("res://scripts/autoload/inventario.gd")

var inv: Node


func _item(id: String, tipo: Item.Tipo, encaixe := Item.Encaixe.NENHUM) -> Item:
	var item := Item.new()
	item.id = id
	item.tipo = tipo
	item.encaixe = encaixe
	return item


func before_each() -> void:
	inv = autofree(InventarioScript.new())
	inv.registrar(_item("espada", Item.Tipo.ARMA, Item.Encaixe.ARMA))
	inv.registrar(_item("lanca", Item.Tipo.ARMA, Item.Encaixe.ARMA))
	inv.registrar(_item("pocao", Item.Tipo.CONSUMIVEL))
	inv.registrar(_item("carta", Item.Tipo.HISTORIA))


func test_bolsa_comeca_vazia() -> void:
	assert_eq(inv.quantidade("pocao"), 0)
	assert_false(inv.tem("pocao"))
	assert_eq(inv.dinheiro(), 0)


func test_adicionar_acumula() -> void:
	inv.adicionar("pocao", 2)
	inv.adicionar("pocao")
	assert_eq(inv.quantidade("pocao"), 3)
	assert_true(inv.tem("pocao", 3))
	assert_false(inv.tem("pocao", 4))


func test_item_desconhecido_nao_entra() -> void:
	assert_false(inv.adicionar("nao_existe"))
	assert_push_error("item desconhecido")
	assert_eq(inv.quantidade("nao_existe"), 0)


func test_remover_so_se_houver() -> void:
	inv.adicionar("pocao", 2)
	assert_false(inv.remover("pocao", 3))
	assert_eq(inv.quantidade("pocao"), 2)
	assert_true(inv.remover("pocao", 2))
	assert_false(inv.tem("pocao"))


func test_avisa_mudanca() -> void:
	watch_signals(inv)
	inv.adicionar("pocao", 2)
	assert_signal_emitted_with_parameters(inv, "mudou", ["pocao", 2])


func test_item_da_historia_nao_se_larga() -> void:
	inv.adicionar("carta")
	assert_false(inv.largar("carta"))
	assert_true(inv.tem("carta"))


func test_roteiro_pode_tirar_item_da_historia() -> void:
	inv.adicionar("carta")
	assert_true(inv.remover("carta"))
	assert_false(inv.tem("carta"))


func test_largar_item_comum() -> void:
	inv.adicionar("pocao", 2)
	assert_true(inv.largar("pocao"))
	assert_eq(inv.quantidade("pocao"), 1)


func test_usar_consumivel_gasta_e_avisa() -> void:
	inv.adicionar("pocao")
	watch_signals(inv)
	assert_true(inv.usar("pocao", "nicholas"))
	assert_false(inv.tem("pocao"))
	assert_signal_emitted_with_parameters(inv, "item_usado", ["pocao", "nicholas"])


func test_nao_usa_o_que_nao_e_consumivel() -> void:
	inv.adicionar("espada")
	assert_false(inv.usar("espada", "nicholas"))
	assert_true(inv.tem("espada"))


func test_dinheiro() -> void:
	inv.ganhar_dinheiro(30)
	assert_false(inv.gastar_dinheiro(31))
	assert_true(inv.gastar_dinheiro(10))
	assert_eq(inv.dinheiro(), 20)


func test_equipar_e_trocar_arma() -> void:
	inv.adicionar("espada")
	inv.adicionar("lanca")
	assert_true(inv.equipar("nicholas", "espada"))
	assert_eq(inv.equipado("nicholas", Item.Encaixe.ARMA), "espada")
	assert_true(inv.equipar("nicholas", "lanca"))
	assert_eq(inv.equipado("nicholas", Item.Encaixe.ARMA), "lanca")


func test_nao_equipa_sem_ter() -> void:
	assert_false(inv.equipar("nicholas", "espada"))


func test_nao_equipa_o_que_nao_tem_encaixe() -> void:
	inv.adicionar("pocao")
	assert_false(inv.equipar("nicholas", "pocao"))


func test_uma_unidade_nao_equipa_dois_personagens() -> void:
	inv.adicionar("espada")
	assert_true(inv.equipar("nicholas", "espada"))
	assert_false(inv.equipar("tahy", "espada"))
	inv.adicionar("espada")
	assert_true(inv.equipar("tahy", "espada"))


func test_largar_item_equipado_desequipa() -> void:
	inv.adicionar("espada")
	inv.equipar("nicholas", "espada")
	inv.largar("espada")
	assert_eq(inv.equipado("nicholas", Item.Encaixe.ARMA), "")


func test_lista_por_tipo_em_ordem() -> void:
	inv.adicionar("lanca")
	inv.adicionar("espada")
	inv.adicionar("pocao")
	assert_eq(inv.ids_do_tipo(Item.Tipo.ARMA), ["espada", "lanca"] as Array[String])
	assert_eq(inv.ids_do_tipo(Item.Tipo.CONSUMIVEL), ["pocao"] as Array[String])


func test_salvar_e_restaurar() -> void:
	inv.adicionar("pocao", 3)
	inv.adicionar("espada")
	inv.equipar("nicholas", "espada")
	inv.ganhar_dinheiro(42)
	var dados: Dictionary = inv.para_dados()
	# Como ficaria depois de salvar em JSON.
	dados = JSON.parse_string(JSON.stringify(dados))

	var outro: Node = autofree(InventarioScript.new())
	outro.registrar(_item("espada", Item.Tipo.ARMA, Item.Encaixe.ARMA))
	outro.registrar(_item("pocao", Item.Tipo.CONSUMIVEL))
	outro.de_dados(dados)
	assert_eq(outro.quantidade("pocao"), 3)
	assert_eq(outro.dinheiro(), 42)
	assert_eq(outro.equipado("nicholas", Item.Encaixe.ARMA), "espada")


func test_ganhar_avisa_mas_usar_nao() -> void:
	watch_signals(inv)
	inv.adicionar("pocao", 2)
	inv.ganhar_dinheiro(5)
	assert_signal_emitted_with_parameters(inv, "recebeu", ["pocao", 2])
	assert_signal_emitted_with_parameters(inv, "dinheiro_recebido", [5])
	inv.usar("pocao", "nicholas")
	assert_signal_emit_count(inv, "recebeu", 1)


func test_coletados_ficam_salvos() -> void:
	inv.marcar_coletado("bau_1")
	var dados: Dictionary = JSON.parse_string(JSON.stringify(inv.para_dados()))
	var outro: Node = autofree(InventarioScript.new())
	outro.de_dados(dados)
	assert_true(outro.ja_coletado("bau_1"))
	outro.limpar()
	assert_false(outro.ja_coletado("bau_1"))


func test_itens_da_pasta_entram_no_catalogo() -> void:
	var com_pasta: Node = autofree(InventarioScript.new())
	assert_not_null(com_pasta.item("pocao_teste"))
	assert_true(com_pasta.item("carta_teste").e_da_historia())
