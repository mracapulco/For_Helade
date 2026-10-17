extends GutTest
## Balanceamento dos itens (orçamento de pontos) e as contas do combate.

const ARMAS := ["espada_grande", "machado_guerra", "arco", "arco_curto", "espada_media",
	"machado_pequeno", "punhal", "maca"]
const REINOS := ["olympia", "agape", "khronosses", "bandidos"]
const PECAS_DE_REINO := ["escudo", "armadura_leve", "armadura_pesada", "elmo"]


static func protecoes() -> Array[String]:
	var ids: Array[String] = ["caixa_frutas", "panela"]
	for peca in PECAS_DE_REINO:
		for reino in REINOS:
			ids.append("%s_%s" % [peca, reino])
	return ids


func before_each() -> void:
	# Adulto: pode equipar tudo (o que cada idade pode está em test_fase_da_vida).
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADULTO)


func after_each() -> void:
	Inventario.limpar()


func _item(encaixe: Item.Encaixe, nivel := 1, maos := 1) -> Item:
	var item := Item.new()
	item.id = "teste"
	item.encaixe = encaixe
	item.nivel = nivel
	item.maos = maos
	return item


func test_todos_os_itens_pedidos_existem() -> void:
	for id in ARMAS:
		var item := Inventario.item(id)
		assert_not_null(item, id)
		if item:
			assert_eq(item.tipo, Item.Tipo.ARMA, id)
			assert_eq(item.encaixe, Item.Encaixe.ARMA, id)
			assert_not_null(item.icone, id)
			assert_not_null(item.visual_na_mao, id)
	for id in protecoes():
		var item := Inventario.item(id)
		assert_not_null(item, id)
		if item:
			assert_eq(item.tipo, Item.Tipo.EQUIPAMENTO, id)
			assert_not_null(item.icone, id)
			assert_true(item.visual_na_mao != null or item.visual_no_corpo != null, "%s aparece no corpo" % id)


func test_duas_maos_e_uma_mao() -> void:
	for id in ["espada_grande", "machado_guerra", "arco", "arco_curto"]:
		assert_true(Inventario.item(id).duas_maos(), id)
	for id in ["espada_media", "machado_pequeno", "punhal", "maca"]:
		assert_false(Inventario.item(id).duas_maos(), id)


func test_encaixes_das_protecoes() -> void:
	for reino in REINOS:
		assert_eq(Inventario.item("escudo_" + reino).encaixe, Item.Encaixe.ESCUDO, reino)
		assert_eq(Inventario.item("armadura_leve_" + reino).encaixe, Item.Encaixe.ARMADURA, reino)
		assert_eq(Inventario.item("armadura_pesada_" + reino).encaixe, Item.Encaixe.ARMADURA, reino)
		assert_eq(Inventario.item("elmo_" + reino).encaixe, Item.Encaixe.ELMO, reino)
	for id in ["caixa_frutas", "panela"]:
		assert_eq(Inventario.item(id).encaixe, Item.Encaixe.ESCUDO, id)


func test_cada_reino_tem_cores_proprias_e_os_mesmos_bonus() -> void:
	var origens := {"olympia": Item.Origem.OLYMPIA, "agape": Item.Origem.AGAPE,
		"khronosses": Item.Origem.KHRONOSSES, "bandidos": Item.Origem.BANDIDOS}
	for peca in PECAS_DE_REINO:
		var base := Inventario.item(peca + "_olympia")
		var desenhos := {}
		for reino in REINOS:
			var item := Inventario.item("%s_%s" % [peca, reino])
			assert_eq(item.origem, origens[reino], item.id)
			assert_eq([item.ataque, item.defesa, item.velocidade],
				[base.ataque, base.defesa, base.velocidade], item.id)
			desenhos[item.icone.resource_path] = true
		assert_eq(desenhos.size(), REINOS.size(), "%s: um ícone por reino" % peca)


func test_todo_item_equipavel_da_pasta_esta_equilibrado() -> void:
	for arquivo: String in ResourceLoader.list_directory(Inventario.PASTA_ITENS):
		var item := load(Inventario.PASTA_ITENS + arquivo) as Item
		if item == null or not item.pode_equipar():
			continue
		assert_true(Balanceamento.equilibrado(item), "%s gasta %.1f de %.1f pontos" % [
			item.id, Balanceamento.pontos(item), Balanceamento.orcamento(item)])


func test_orcamento_por_nivel_e_encaixe() -> void:
	assert_eq(Balanceamento.orcamento(_item(Item.Encaixe.ARMA)), 10.0)
	assert_eq(Balanceamento.orcamento(_item(Item.Encaixe.ARMA, 1, 2)), 16.0)
	assert_eq(Balanceamento.orcamento(_item(Item.Encaixe.ESCUDO)), 6.0)
	assert_eq(Balanceamento.orcamento(_item(Item.Encaixe.ESCUDO, 0)), 3.0, "improvisado vale metade")
	assert_eq(Balanceamento.orcamento(_item(Item.Encaixe.ARMADURA, 2)), 15.0)
	assert_eq(Balanceamento.orcamento(_item(Item.Encaixe.ELMO)), 4.0)
	assert_eq(Balanceamento.orcamento(_item(Item.Encaixe.NENHUM)), 0.0)


func test_duas_maos_pesa_o_mesmo_que_arma_mais_escudo() -> void:
	var duas := Balanceamento.orcamento(_item(Item.Encaixe.ARMA, 1, 2))
	var uma := Balanceamento.orcamento(_item(Item.Encaixe.ARMA))
	var escudo := Balanceamento.orcamento(_item(Item.Encaixe.ESCUDO))
	assert_almost_eq(duas, uma + escudo, 0.001)


func test_pontos_contam_velocidade_e_alcance() -> void:
	var item := _item(Item.Encaixe.ARMA)
	item.ataque = 4
	item.defesa = 1
	item.velocidade = 10
	assert_almost_eq(Balanceamento.pontos(item), 7.0, 0.001)
	item.velocidade = -10
	assert_almost_eq(Balanceamento.pontos(item), 3.0, 0.001, "lentidão devolve pontos")
	item.velocidade = 0
	item.alcance = Balanceamento.ALCANCE_PADRAO + 96.0
	assert_almost_eq(Balanceamento.pontos(item), 7.0, 0.001, "96 px a mais custam 2 pontos")


func test_item_forte_demais_nao_esta_equilibrado() -> void:
	var item := _item(Item.Encaixe.ARMA)
	item.ataque = 20
	assert_false(Balanceamento.equilibrado(item))
	assert_lt(Balanceamento.sobra(item), 0.0)


func test_ninguem_e_melhor_em_tudo() -> void:
	# Comparando armas do mesmo encaixe e mãos: quem tem mais ataque perde
	# em outra coisa.
	var forte := Inventario.item("machado_guerra")
	var outra := Inventario.item("espada_grande")
	assert_gt(forte.ataque, outra.ataque)
	assert_lt(forte.defesa + forte.velocidade, outra.defesa + outra.velocidade)
	assert_gt(Inventario.item("punhal").velocidade, Inventario.item("espada_media").velocidade)
	assert_lt(Inventario.item("punhal").ataque, Inventario.item("espada_media").ataque)
	assert_gt(Inventario.item("armadura_pesada_agape").defesa, Inventario.item("armadura_leve_agape").defesa)
	assert_lt(Inventario.item("armadura_pesada_agape").velocidade, Inventario.item("armadura_leve_agape").velocidade)


func test_improvisados_protegem_menos_que_o_escudo() -> void:
	var escudo := Inventario.item("escudo_olympia").defesa
	assert_lt(Inventario.item("caixa_frutas").defesa, escudo)
	assert_lt(Inventario.item("panela").defesa, escudo)


func test_dano_cai_com_a_defesa_sem_zerar() -> void:
	assert_eq(Balanceamento.dano(10, 0), 10)
	assert_eq(Balanceamento.dano(10, 10), 5)
	assert_eq(Balanceamento.dano(12, 30), 3)
	assert_eq(Balanceamento.dano(1, 100), 1, "sempre tira pelo menos 1")
	assert_eq(Balanceamento.dano(0, 0), 0)


func test_multiplicador_de_velocidade_tem_limites() -> void:
	assert_almost_eq(Balanceamento.multiplicador_velocidade(0), 1.0, 0.001)
	assert_almost_eq(Balanceamento.multiplicador_velocidade(25), 1.25, 0.001)
	assert_almost_eq(Balanceamento.multiplicador_velocidade(-90), 0.6, 0.001)
	assert_almost_eq(Balanceamento.multiplicador_velocidade(90), 1.4, 0.001)


func test_atributos_somam_o_equipamento() -> void:
	for id in ["espada_media", "escudo_olympia", "armadura_leve_agape", "elmo_khronosses"]:
		Inventario.adicionar(id)
		Inventario.equipar("nicholas", id)
	var a := Inventario.atributos("nicholas")
	assert_eq(a.ataque, Inventario.fase().ataque_base + 7)
	assert_eq(a.defesa, 2 + 7 + 9 + 5)
	assert_eq(a.velocidade, 5 - 5 + 5 - 5)


func test_sem_nada_equipado_so_o_ataque_base() -> void:
	var a := Inventario.atributos("nicholas")
	assert_eq(a.ataque, Inventario.fase().ataque_base)
	assert_eq(a.defesa, 0)
	assert_eq(a.velocidade, 0)


func test_arma_de_duas_maos_tira_o_escudo() -> void:
	for id in ["escudo_bandidos", "espada_grande", "espada_media"]:
		Inventario.adicionar(id)
	Inventario.equipar("nicholas", "escudo_bandidos")
	Inventario.equipar("nicholas", "espada_grande")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ESCUDO), "")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "espada_grande")
	# Pegar o escudo de volta larga a arma de duas mãos.
	Inventario.equipar("nicholas", "escudo_bandidos")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ESCUDO), "escudo_bandidos")
	# Arma de uma mão e escudo andam juntos.
	Inventario.equipar("nicholas", "espada_media")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ESCUDO), "escudo_bandidos")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "espada_media")


func test_equipamento_novo_volta_no_jogo_salvo() -> void:
	for id in ["arco", "armadura_pesada_olympia", "elmo_bandidos"]:
		Inventario.adicionar(id)
		Inventario.equipar("nicholas", id)
	var dados := Inventario.para_dados()
	Inventario.limpar()
	Inventario.de_dados(dados)
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "arco")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMADURA), "armadura_pesada_olympia")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ELMO), "elmo_bandidos")


func test_vida_recebe_ataque_com_a_defesa_do_equipamento() -> void:
	var vida: Vida = autofree(Vida.new())
	vida.maxima = 30
	vida.id_inventario = "nicholas"
	vida._ready()
	assert_eq(vida.receber_ataque(10), 10)
	assert_eq(vida.atual, 20)
	Inventario.adicionar("armadura_pesada_khronosses")
	Inventario.equipar("nicholas", "armadura_pesada_khronosses")
	assert_eq(vida.defesa_total(), 20)
	assert_eq(vida.receber_ataque(10), 3)
	assert_eq(vida.atual, 17)


func test_vida_morre_cura_e_revive() -> void:
	var vida: Vida = autofree(Vida.new())
	vida.maxima = 10
	vida._ready()
	watch_signals(vida)
	vida.curar(5)
	assert_eq(vida.atual, 10, "não passa do máximo")
	vida.perder(15)
	assert_true(vida.morto())
	assert_signal_emitted(vida, "morreu")
	assert_eq(vida.receber_ataque(5), 0, "morto não apanha mais")
	vida.curar(5)
	assert_eq(vida.atual, 0, "morto não se cura")
	var boneco: Vida = autofree(Vida.new())
	boneco.maxima = 10
	boneco.reviver_ao_morrer = true
	boneco._ready()
	boneco.perder(50)
	assert_eq(boneco.atual, 10, "boneco de treino volta cheio")
