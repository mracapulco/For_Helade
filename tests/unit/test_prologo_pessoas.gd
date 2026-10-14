extends GutTest
## Pessoas dos aposentos: parteiras, empregadas, a duquesa e Althea
## (planos/prologo-npcs.md, aprovado pelo Rafael em 14/10/2026).

const CENA := preload("res://scenes/prologo/prologo.tscn")

var cena: ControlePrimeiraPessoa
var seq: SequenciaPrologo


func before_each() -> void:
	cena = CENA.instantiate()
	cena.abertura = null
	cena.duracao_movimento = 0.1
	var frases: TextoSolto = cena.texto_solto
	frases.tempo_fade = 0.01
	frases.tempo_minimo = 0.02
	frases.tempo_por_letra = 0.0
	seq = cena.get_node("Sequencia")
	seq.escala_tempo = 0.02
	seq.cena_depois = ""
	seq.etapa_salva = ""
	add_child_autofree(cena)
	await wait_physics_frames(2)
	await wait_until(func() -> bool: return not cena.travado, 3.0)


func _ponto(nome: String) -> PontoDeVista:
	return cena.get_node("Pontos/" + nome)


func _ate_a_etapa(etapa: String) -> void:
	await wait_until(func() -> bool: return seq.etapa == etapa, 5.0)
	assert_eq(seq.etapa, etapa)


func _entrar_nos_aposentos() -> void:
	cena.colocar_em(_ponto("PortaAposentos"))
	cena.continuar_em(_ponto("PortaAposentos"))
	var alvo: AlvoToque = _ponto("PortaAposentos").alvos()[0]
	alvo.tocado.emit(alvo)


func _pessoas() -> Array[PessoaPrologo]:
	var lista: Array[PessoaPrologo] = []
	for filho in seq.figuras.get_children():
		if filho is PessoaPrologo:
			lista.append(filho)
	return lista


func test_so_quem_o_livro_poe_na_cena() -> void:
	var nomes: Array[String] = []
	for pessoa in _pessoas():
		nomes.append(pessoa.name)
	nomes.sort()
	assert_eq(nomes, ["Empregada1", "Empregada2", "Empregada3", "Parteira", "Parteira2"] as Array[String])
	assert_eq(_pessoas().size(), seq.figuras.get_child_count(), "nenhuma figura provisória sobrou")
	assert_true(seq.duquesa is DuquesaNaCama)
	assert_true(seq.althea is BebeAlthea)


func test_cada_pessoa_tem_corpo_com_cabeca_bracos_e_maos() -> void:
	for pessoa in _pessoas():
		assert_not_null(pessoa.cabeca, pessoa.name)
		assert_eq(pessoa.ombros.size(), 2, pessoa.name)
		assert_eq(pessoa.pulsos.size(), 2, pessoa.name)
		assert_not_null(pessoa.pulsos[0].get_node_or_null("Mao"), pessoa.name)


func test_parteiras_de_mangas_arregacadas() -> void:
	for nome in ["Parteira", "Parteira2"]:
		var parteira: PessoaPrologo = seq.figuras.get_node(nome)
		assert_true(parteira.mangas_arregacadas, nome)


func test_de_tunica_tem_pernas_que_andam() -> void:
	var empregado := PessoaPrologo.new()
	empregado.roupa = PessoaPrologo.Roupa.TUNICA
	empregado.atividade = "correndo"
	add_child_autofree(empregado)
	assert_eq(empregado.coxas.size(), 2)
	var antes := empregado.coxas[0].rotation.x
	await wait_seconds(0.15)
	assert_ne(empregado.coxas[0].rotation.x, antes, "as pernas se mexem correndo")


func test_congelada_nao_mexe_nenhuma_junta() -> void:
	var pessoa := PessoaPrologo.new()
	pessoa.atividade = "trabalhando"
	add_child_autofree(pessoa)
	await wait_seconds(0.1)
	pessoa.congelar()
	var antes := [pessoa.ombros[0].rotation, pessoa.cotovelos[1].rotation, pessoa.tronco.rotation]
	await wait_seconds(0.2)
	assert_eq([pessoa.ombros[0].rotation, pessoa.cotovelos[1].rotation, pessoa.tronco.rotation], antes)


func test_duquesa_deitada_sob_o_lencol() -> void:
	var duquesa: DuquesaNaCama = seq.duquesa
	assert_true(duquesa.pessoa.deitada)
	assert_null(duquesa.pessoa.get_node_or_null("Esqueleto/Quadril/Saia"), "o lençol cobre as pernas")
	assert_not_null(duquesa.lencol.mesh)
	assert_true(duquesa.visible)


func test_quando_althea_nasce_todos_param() -> void:
	await _entrar_nos_aposentos()
	await _ate_a_etapa("caos")
	assert_eq(seq.duquesa.pessoa.atividade, "deitada_parto")
	for pessoa in _pessoas():
		assert_false(pessoa.congelada, pessoa.name + " se mexe no caos")
	await _ate_a_etapa("muda")
	await wait_physics_frames(2)
	for pessoa in _pessoas():
		assert_true(pessoa.congelada, pessoa.name + " parou")
	assert_true(seq.duquesa.pessoa.congelada)
	assert_eq((seq.parteira as PessoaPrologo).atividade, "segurando_bebe")
	assert_true(seq.althea.visible)


func test_depois_do_nome_todos_olham_para_nicholas() -> void:
	await _entrar_nos_aposentos()
	await _ate_a_etapa("nome")
	seq.botao_nome.pressed.emit()
	await _ate_a_etapa("olhares")
	await wait_seconds(0.2)
	for pessoa in _pessoas():
		assert_false(pessoa.congelada)
		var frente := -pessoa.cabeca.global_basis.z
		var para_nicholas := cena.camera.global_position - pessoa.cabeca.global_position
		assert_gt(frente.normalized().dot(para_nicholas.normalized()), 0.85, pessoa.name + " olha para Nicholas")


func test_a_duquesa_parte_e_depois_e_levada() -> void:
	await _entrar_nos_aposentos()
	await _ate_a_etapa("nome")
	seq.botao_nome.pressed.emit()
	await _ate_a_etapa("choro")
	assert_true((seq.althea as BebeAlthea).chorando)
	await wait_until(func() -> bool: return seq.duquesa.partiu, 3.0)
	assert_eq(seq.duquesa.pessoa.atividade, "deitada_partiu")
	assert_gt(seq.duquesa.pessoa.palidez, 0.5, "mais pálida")
	await _ate_a_etapa("segurar")
	seq.alvo_althea.tocado.emit(seq.alvo_althea)
	await _ate_a_etapa("quarto_vazio")
	assert_false(seq.duquesa.visible, "a levaram de lá")
	assert_false((seq.althea as BebeAlthea).chorando)


func test_sangue_so_representado_em_manchas_escuras() -> void:
	# Decisão do Rafael (14/10/2026): sem gore; sangue só como manchas no tecido.
	var sangue := MalhaCorpo.sangue()
	assert_eq(sangue.albedo_color, MalhaCorpo.COR_SANGUE)
	assert_gt(sangue.roughness, 0.5, "fosco, sem brilho de ferida")
	assert_false(sangue.emission_enabled)
