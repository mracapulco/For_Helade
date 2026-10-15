extends GutTest
## Bolsa em espaços (como no Minecraft): pilhas, limite pela idade, troca
## de lugar e barra rápida. Itens criados no próprio teste.

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
	inv.registrar(_item("escudo", Item.Tipo.EQUIPAMENTO, Item.Encaixe.ESCUDO))
	inv.registrar(_item("pocao", Item.Tipo.CONSUMIVEL))
	inv.registrar(_item("pedra", Item.Tipo.DIVERSOS))
	inv.registrar(_item("carta", Item.Tipo.HISTORIA))
	var flecha := _item("flecha", Item.Tipo.DIVERSOS)
	flecha.pilha_maxima = 30
	inv.registrar(flecha)


func _ocupados() -> int:
	var total := 0
	for indice in inv.numero_de_espacos():
		if not inv.espaco(indice).is_empty():
			total += 1
	return total


func test_tamanho_da_bolsa_pela_idade() -> void:
	assert_eq(inv.faixa_etaria, inv.FaixaEtaria.CRIANCA)
	assert_eq(inv.numero_de_espacos(), 12)
	inv.mudar_faixa_etaria(inv.FaixaEtaria.ADOLESCENTE)
	assert_eq(inv.numero_de_espacos(), 20)
	inv.mudar_faixa_etaria(inv.FaixaEtaria.ADULTO)
	assert_eq(inv.numero_de_espacos(), 30)


func test_pilhas_padrao() -> void:
	assert_eq(inv.item("espada").tamanho_pilha(), 1)
	assert_eq(inv.item("escudo").tamanho_pilha(), 1)
	assert_eq(inv.item("pocao").tamanho_pilha(), Item.PILHA_PADRAO)
	assert_eq(inv.item("flecha").tamanho_pilha(), 30)


func test_itens_iguais_dividem_o_espaco_ate_a_pilha() -> void:
	inv.adicionar("pocao", 4)
	inv.adicionar("pocao", 3)
	assert_eq(inv.espaco(0), { "id": "pocao", "quantidade": 7 })
	inv.adicionar("pocao", 5)
	assert_eq(inv.espaco(0)["quantidade"], 10)
	assert_eq(inv.espaco(1), { "id": "pocao", "quantidade": 2 })
	assert_eq(inv.quantidade("pocao"), 12)


func test_cada_arma_ocupa_um_espaco() -> void:
	inv.adicionar("espada", 2)
	assert_eq(_ocupados(), 2)


func test_bolsa_cheia_nao_aceita_mais() -> void:
	inv.adicionar("espada", 12)
	watch_signals(inv)
	assert_false(inv.cabe("pedra"))
	assert_false(inv.adicionar("pedra"))
	assert_false(inv.tem("pedra"))
	assert_signal_emitted(inv, "bolsa_cheia")


func test_pilha_incompleta_ainda_recebe_com_a_bolsa_cheia() -> void:
	inv.adicionar("pocao", 5)
	inv.adicionar("espada", 11)
	assert_true(inv.adicionar("pocao", 5))
	assert_false(inv.adicionar("pocao"))


func test_tudo_ou_nada() -> void:
	inv.adicionar("espada", 11)
	assert_false(inv.adicionar("pedra", 15))
	assert_eq(inv.quantidade("pedra"), 0)


func test_cabem_junta_o_bau_inteiro() -> void:
	inv.adicionar("espada", 10)
	assert_true(inv.cabem({ "pocao": 3, "pedra": 2 }))
	assert_false(inv.cabem({ "pocao": 3, "pedra": 2, "escudo": 1 }))


func test_itens_da_historia_nao_ocupam_espaco() -> void:
	inv.adicionar("espada", 12)
	assert_true(inv.adicionar("carta"))
	assert_true(inv.tem("carta"))
	assert_eq(_ocupados(), 12)
	assert_eq(inv.ids_do_tipo(Item.Tipo.HISTORIA), ["carta"] as Array[String])


func test_crescer_libera_espacos() -> void:
	inv.adicionar("espada", 12)
	inv.mudar_faixa_etaria(inv.FaixaEtaria.ADOLESCENTE)
	assert_true(inv.adicionar("pedra"))


func test_encolher_nao_perde_nada() -> void:
	inv.mudar_faixa_etaria(inv.FaixaEtaria.ADULTO)
	inv.adicionar("espada", 15)
	inv.mudar_faixa_etaria(inv.FaixaEtaria.CRIANCA)
	assert_eq(inv.quantidade("espada"), 15)
	assert_eq(inv.numero_de_espacos(), 15)
	assert_false(inv.adicionar("pedra"))
	# Esvaziar os de fora do limite os faz sumir; nada novo entra neles.
	inv.remover("espada", 3)
	assert_eq(inv.numero_de_espacos(), 12)
	assert_false(inv.adicionar("pedra"))
	inv.remover("espada")
	assert_true(inv.adicionar("pedra"))


func test_remover_tira_do_fim_e_poupa_a_barra_rapida() -> void:
	inv.adicionar("pocao", 10)
	inv.adicionar("espada")
	inv.adicionar("pocao", 3)
	inv.remover("pocao", 4)
	assert_eq(inv.espaco(0), { "id": "pocao", "quantidade": 9 })
	assert_true(inv.espaco(2).is_empty())


func test_trocar_espacos() -> void:
	inv.adicionar("espada")
	inv.adicionar("pocao", 2)
	assert_true(inv.trocar_espacos(0, 1))
	assert_eq(inv.espaco(0)["id"], "pocao")
	assert_eq(inv.espaco(1)["id"], "espada")
	assert_true(inv.trocar_espacos(1, 8))
	assert_true(inv.espaco(1).is_empty())
	assert_eq(inv.espaco(8)["id"], "espada")


func test_trocar_com_o_mesmo_item_junta_a_pilha() -> void:
	inv.adicionar("pocao", 10)
	inv.adicionar("pocao", 6)
	inv.trocar_espacos(1, 4)
	inv.remover("pocao", 4)
	# Agora: 10 no espaço 0 e 2 no espaço 4.
	inv.trocar_espacos(4, 0)
	assert_eq(inv.espaco(0)["quantidade"], 10)
	inv.remover("pocao", 5)
	assert_true(inv.espaco(4).is_empty())
	assert_true(inv.trocar_espacos(0, 4))
	assert_eq(inv.espaco(4)["quantidade"], 7)
	assert_true(inv.espaco(0).is_empty())


func test_nao_troca_para_fora_do_limite() -> void:
	inv.adicionar("pedra")
	assert_false(inv.trocar_espacos(0, 12))
	assert_false(inv.trocar_espacos(3, 0))


func test_barra_rapida_equipa_e_desequipa() -> void:
	inv.adicionar("espada")
	assert_true(inv.usar_espaco(0, "nicholas"))
	assert_eq(inv.equipado("nicholas", Item.Encaixe.ARMA), "espada")
	assert_true(inv.usar_espaco(0, "nicholas"))
	assert_eq(inv.equipado("nicholas", Item.Encaixe.ARMA), "")
	assert_true(inv.tem("espada"))


func test_barra_rapida_bebe_a_pocao_do_espaco() -> void:
	inv.adicionar("pocao", 10)
	inv.adicionar("pocao", 2)
	watch_signals(inv)
	assert_true(inv.usar_espaco(0, "nicholas"))
	assert_eq(inv.espaco(0)["quantidade"], 9)
	assert_eq(inv.espaco(1)["quantidade"], 2)
	assert_signal_emitted_with_parameters(inv, "item_usado", ["pocao", "nicholas"])


func test_barra_rapida_vazia_ou_diversos_nao_faz_nada() -> void:
	inv.adicionar("pedra")
	assert_false(inv.usar_espaco(0, "nicholas"))
	assert_false(inv.usar_espaco(5, "nicholas"))
	assert_eq(inv.quantidade("pedra"), 1)


func test_salvar_guarda_lugares_e_idade() -> void:
	inv.mudar_faixa_etaria(inv.FaixaEtaria.ADOLESCENTE)
	inv.adicionar("espada")
	inv.adicionar("pocao", 3)
	inv.adicionar("carta")
	inv.trocar_espacos(0, 7)
	var dados: Dictionary = JSON.parse_string(JSON.stringify(inv.para_dados()))
	var outro: Node = autofree(InventarioScript.new())
	for id: String in ["espada", "pocao", "carta"]:
		outro.registrar(inv.item(id))
	outro.de_dados(dados)
	assert_eq(outro.faixa_etaria, inv.FaixaEtaria.ADOLESCENTE)
	assert_eq(outro.numero_de_espacos(), 20)
	assert_eq(outro.espaco(7), { "id": "espada", "quantidade": 1 })
	assert_eq(outro.espaco(1), { "id": "pocao", "quantidade": 3 })
	assert_true(outro.tem("carta"))


func test_jogo_salvo_antigo_vira_espacos() -> void:
	inv.de_dados({ "itens": { "pocao": 13, "espada": 2, "carta": 1 }, "dinheiro": 5 })
	assert_eq(inv.quantidade("pocao"), 13)
	assert_eq(inv.quantidade("espada"), 2)
	assert_true(inv.tem("carta"))
	assert_eq(_ocupados(), 4)


func test_limpar_volta_a_crianca() -> void:
	inv.mudar_faixa_etaria(inv.FaixaEtaria.ADULTO)
	inv.adicionar("pocao")
	inv.limpar()
	assert_eq(inv.faixa_etaria, inv.FaixaEtaria.CRIANCA)
	assert_eq(inv.numero_de_espacos(), 12)
	assert_eq(_ocupados(), 0)
