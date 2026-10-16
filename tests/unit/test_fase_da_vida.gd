extends GutTest
## Fase da vida (criança, adolescente, adulto): vida, ataque sem arma,
## velocidade e o que dá para equipar.

const F := Inventario.FaixaEtaria

var sala: Node2D
var personagem: PersonagemExploracao
var vida: Vida


func before_each() -> void:
	Inventario.limpar()
	GradeOcupacao.limpar()


func after_all() -> void:
	Inventario.limpar()


func _abrir_sala() -> void:
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	vida = sala.get_node("Personagem/Vida")
	await wait_physics_frames(2)


func test_cada_idade_tem_seu_arquivo() -> void:
	for faixa in F.values():
		Inventario.mudar_faixa_etaria(faixa)
		var nome := str(F.find_key(faixa)).to_lower()
		assert_true(ResourceLoader.exists(Inventario.PASTA_FASES + nome + ".tres"), nome)
		assert_gt(Inventario.fase().vida_base, 0, nome)


func test_crescer_deixa_mais_forte() -> void:
	var anterior: FaseDaVida = null
	for faixa in [F.CRIANCA, F.ADOLESCENTE, F.ADULTO]:
		Inventario.mudar_faixa_etaria(faixa)
		var atual := Inventario.fase()
		if anterior:
			assert_gt(atual.vida_base, anterior.vida_base)
			assert_gt(atual.ataque_base, anterior.ataque_base)
		anterior = atual


func test_atributos_somam_o_corpo_da_idade() -> void:
	var crianca := Inventario.atributos("nicholas")
	assert_eq(crianca.ataque, Inventario.fase().ataque_base)
	assert_eq(crianca.velocidade, Inventario.fase().velocidade)
	Inventario.adicionar("punhal")
	Inventario.equipar("nicholas", "punhal")
	var armada := Inventario.atributos("nicholas")
	assert_eq(armada.ataque, Inventario.fase().ataque_base + Inventario.item("punhal").ataque)
	assert_eq(armada.velocidade, Inventario.fase().velocidade + Inventario.item("punhal").velocidade)


func test_crianca_so_equipa_o_que_e_leve() -> void:
	for id in ["punhal", "maca", "caixa_frutas", "panela", "elmo_olympia"]:
		Inventario.adicionar(id)
		assert_false(Inventario.pesado_para_a_idade(id), id)
	for id in ["espada_media", "escudo_olympia", "armadura_leve_olympia",
			"espada_grande", "arco", "armadura_pesada_olympia"]:
		Inventario.adicionar(id)
		assert_true(Inventario.pesado_para_a_idade(id), id)
	watch_signals(Inventario)
	assert_false(Inventario.equipar("nicholas", "espada_media"))
	assert_signal_emitted_with_parameters(Inventario, "pesado_demais", ["espada_media"])
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "")


func test_adolescente_nao_usa_duas_maos_nem_armadura_pesada() -> void:
	Inventario.mudar_faixa_etaria(F.ADOLESCENTE)
	for id in ["espada_media", "machado_pequeno", "escudo_agape", "armadura_leve_agape"]:
		assert_false(Inventario.pesado_para_a_idade(id), id)
	for id in ["espada_grande", "machado_guerra", "arco", "armadura_pesada_agape"]:
		assert_true(Inventario.pesado_para_a_idade(id), id)


func test_adulto_equipa_tudo() -> void:
	Inventario.mudar_faixa_etaria(F.ADULTO)
	for arquivo in DirAccess.get_files_at(Inventario.PASTA_ITENS):
		var id := arquivo.get_basename().trim_suffix(".tres")
		assert_false(Inventario.pesado_para_a_idade(id), id)


func test_voltar_a_ser_crianca_desequipa_o_pesado() -> void:
	Inventario.mudar_faixa_etaria(F.ADULTO)
	for id in ["espada_grande", "elmo_bandidos"]:
		Inventario.adicionar(id)
		Inventario.equipar("nicholas", id)
	Inventario.mudar_faixa_etaria(F.CRIANCA)
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "", "a espada grande sai da mão")
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ELMO), "elmo_bandidos", "o elmo fica")
	assert_true(Inventario.tem("espada_grande"), "e continua na bolsa")


func test_vida_de_nicholas_vem_da_idade() -> void:
	await _abrir_sala()
	assert_eq(vida.maxima, Inventario.fase().vida_base)
	assert_eq(vida.atual, vida.maxima)


func test_crescer_soma_a_diferenca_na_vida() -> void:
	await _abrir_sala()
	Inventario.mudar_faixa_etaria(F.CRIANCA)
	vida.restaurar()
	vida.perder(10)
	var antes := vida.atual
	var max_crianca := vida.maxima
	Inventario.mudar_faixa_etaria(F.ADULTO)
	assert_eq(vida.maxima, Inventario.fase().vida_base)
	assert_eq(vida.atual, antes + vida.maxima - max_crianca)


func test_crianca_e_um_pouco_mais_rapida() -> void:
	await _abrir_sala()
	# A sala de teste começa com Nicholas adulto (bolsa grande).
	Inventario.mudar_faixa_etaria(F.CRIANCA)
	var ritmo_crianca := personagem.ritmo()
	Inventario.mudar_faixa_etaria(F.ADULTO)
	assert_gt(ritmo_crianca, personagem.ritmo())


func test_bolsa_mostra_pesado_demais() -> void:
	var texto := TelaBolsa.texto_bonus(Inventario.item("espada_grande"))
	assert_string_contains(texto, tr("BOLSA_PESADO_DEMAIS"))
	Inventario.mudar_faixa_etaria(F.ADULTO)
	texto = TelaBolsa.texto_bonus(Inventario.item("espada_grande"))
	assert_false(texto.contains(tr("BOLSA_PESADO_DEMAIS")))


func test_idade_volta_no_jogo_salvo_com_o_equipamento() -> void:
	Inventario.mudar_faixa_etaria(F.ADULTO)
	Inventario.adicionar("arco")
	Inventario.equipar("nicholas", "arco")
	var dados := Inventario.para_dados()
	Inventario.limpar()
	Inventario.de_dados(dados)
	assert_eq(Inventario.faixa_etaria, F.ADULTO)
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "arco")

