extends GutTest
## Tela da loja: listas, quantidade, comprar e vender pelos botões, avisos e
## comparação com o equipado.

const CENA := preload("res://scenes/ui/tela_loja.tscn")

var tela: TelaLoja


func before_each() -> void:
	Inventario.limpar()
	Lojas.limpar()
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADULTO)
	tela = CENA.instantiate()
	add_child_autofree(tela)


func after_each() -> void:
	get_tree().paused = false


func after_all() -> void:
	Inventario.limpar()
	Lojas.limpar()


func _nomes(lista: GridContainer) -> Array[String]:
	var nomes: Array[String] = []
	for filho in lista.get_children():
		nomes.append(str(filho.name))
	return nomes


func test_abrir_mostra_mercadorias_e_pausa() -> void:
	tela.abrir("chymeia")
	assert_true(tela.aberta())
	assert_true(get_tree().paused)
	assert_eq(_nomes(tela.lista_loja), Lojas.mercadorias("chymeia"))
	assert_eq(tela.titulo.text, tr("LOJA_CHYMEIA_NOME"))


func test_fechar_despausa_e_avisa() -> void:
	watch_signals(tela)
	tela.abrir("chymeia")
	tela.fechar()
	assert_false(tela.aberta())
	assert_false(get_tree().paused)
	assert_signal_emitted(tela, "fechada")


func test_loja_desconhecida_nao_abre() -> void:
	tela.abrir("nao_existe")
	assert_push_error("loja desconhecida")
	assert_false(tela.aberta())


func test_bolsa_mostra_so_o_que_se_vende() -> void:
	Inventario.adicionar("punhal")
	Inventario.adicionar("carta_teste")
	tela.abrir("chymeia")
	assert_eq(_nomes(tela.lista_bolsa), ["punhal"] as Array[String])


func test_comprar_pelo_botao_com_quantidade() -> void:
	Inventario.ganhar_dinheiro(100)
	tela.abrir("chymeia")
	tela.escolher(TelaLoja.Lado.LOJA, "pocao_cura")
	tela.mudar_quantidade(1)
	assert_eq(tela.quantidade, 2)
	assert_false(tela.botao_negociar.disabled)
	tela.botao_negociar.pressed.emit()
	assert_eq(Inventario.quantidade("pocao_cura"), 2)
	assert_eq(Inventario.dinheiro(), 100 - 2 * Inventario.item("pocao_cura").preco)
	assert_eq(tela.aviso.text, tr("LOJA_COMPROU"))
	assert_true(tela.lista_bolsa.has_node("pocao_cura"), "aparece na bolsa para vender")


func test_quantidade_nao_passa_do_estoque() -> void:
	tela.abrir("chymeia")
	tela.escolher(TelaLoja.Lado.LOJA, "pocao_rapidez")
	for i in 10:
		tela.mudar_quantidade(1)
	assert_eq(tela.quantidade, Lojas.estoque("chymeia", "pocao_rapidez"))
	assert_true(tela.botao_mais.disabled)
	for i in 10:
		tela.mudar_quantidade(-1)
	assert_eq(tela.quantidade, 1)
	assert_true(tela.botao_menos.disabled)


func test_sem_moedas_avisa_e_bloqueia() -> void:
	tela.abrir("chymeia")
	tela.escolher(TelaLoja.Lado.LOJA, "pocao_vigor")
	assert_true(tela.botao_negociar.disabled)
	assert_eq(tela.aviso.text, tr("LOJA_SEM_MOEDAS"))


func test_vender_arma_equipada_avisa_e_vende() -> void:
	Inventario.adicionar("espada_media")
	Inventario.equipar("nicholas", "espada_media")
	tela.abrir("chymeia")
	tela.escolher(TelaLoja.Lado.BOLSA, "espada_media")
	assert_eq(tela.comparacao_item.text, tr("LOJA_VAI_DESEQUIPAR"))
	assert_eq(tela.botao_negociar.text, tr("LOJA_VENDER"))
	tela.botao_negociar.pressed.emit()
	assert_eq(Inventario.dinheiro(), Lojas.preco_venda("espada_media"))
	assert_eq(tela.item_escolhido, "", "vendeu tudo: nada escolhido")
	assert_false(tela.lista_bolsa.has_node("espada_media"))


func test_comparacao_com_o_equipado() -> void:
	var punhal := Inventario.item("punhal")
	var espada := Inventario.item("espada_media")
	assert_eq(TelaLoja.texto_comparacao(punhal, "nicholas"),
		tr("LOJA_COMPARA_NADA") % "Ataque +5 · Velocidade +25%")
	Inventario.adicionar("espada_media")
	Inventario.equipar("nicholas", "espada_media")
	assert_eq(TelaLoja.texto_comparacao(punhal, "nicholas"),
		tr("LOJA_COMPARA") % "Ataque -2 · Defesa -2 · Velocidade +20%")
	assert_eq(TelaLoja.texto_comparacao(espada, "nicholas"), tr("LOJA_COMPARA_IGUAL"))
	assert_eq(TelaLoja.texto_comparacao(Inventario.item("pocao_cura"), "nicholas"), "")
