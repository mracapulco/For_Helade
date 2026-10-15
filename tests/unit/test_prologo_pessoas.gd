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
	await wait_until(func() -> bool: return seq.parteira.atividade != "segurando_bebe", 3.0)
	assert_eq(seq.parteira.atividade, "andando_com_bebe", "vem até Nicholas sem soltar Althea")
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


# --- Corpo de Nicholas em primeira pessoa (pedido do Rafael, 14/10/2026) ---

func _corpo() -> CorpoNicholas:
	return cena.get_node("Nicholas/CorpoNicholas")


func test_nicholas_tem_pernas_pes_bracos_e_maos() -> void:
	var corpo := _corpo()
	assert_eq(corpo.coxas.size(), 2)
	assert_eq(corpo.ombros.size(), 2)
	for pulso in corpo.pulsos:
		assert_not_null(pulso.get_node_or_null("Mao/Dedo0"), "mão com dedos")
	for joelho in corpo.joelhos:
		assert_not_null(joelho.get_node_or_null("Pe"))


func test_peito_aparece_e_a_cabeca_so_faz_sombra() -> void:
	# Retorno do Rafael (15/10/2026): sem o peito, os braços ficavam soltos.
	var peito: MeshInstance3D = _corpo().quadril.get_node("Peito")
	assert_ne(peito.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	# A câmera fica dentro da cabeça: ela só aparece na sombra no chão.
	var cabeca: MeshInstance3D = _corpo().quadril.get_node("Cabeca")
	assert_eq(cabeca.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)


func test_no_silencio_param_mas_ainda_respiram() -> void:
	var pessoa := PessoaPrologo.new()
	pessoa.atividade = "trabalhando"
	add_child_autofree(pessoa)
	await wait_seconds(0.1)
	pessoa.congelar()
	var escalas := {}
	for i in 12:
		await wait_seconds(0.05)
		escalas[pessoa.tronco.scale.y] = true
	assert_gt(escalas.size(), 3, "o peito sobe e desce")


func test_parado_andando_e_correndo() -> void:
	var corpo := _corpo()
	cena.colocar_em(_ponto("Corredor"))
	await wait_physics_frames(10)
	assert_eq(corpo.pose, "parado")
	var andou := false
	var correu := false
	cena.pode_correr = true
	# Vai e volta pelo corredor com as teclas, como o jogador.
	for correr in [false, true]:
		if correr:
			Input.action_press("correr")
		for ida in ["mover_frente", "mover_tras", "mover_frente"]:
			Input.action_press(ida)
			for i in 15:
				await wait_physics_frames(1)
				andou = andou or corpo.pose == "andando"
				correu = correu or corpo.pose == "correndo"
			Input.action_release(ida)
	Input.action_release("correr")
	assert_true(andou, "andando")
	assert_true(correu, "correndo")


func test_pulo_dobra_as_pernas() -> void:
	var corpo := _corpo()
	cena.colocar_em(_ponto("Corredor"))
	await wait_physics_frames(5)
	Input.action_press("pular")
	await wait_physics_frames(3)
	Input.action_release("pular")
	await wait_until(func() -> bool: return corpo.pose == "no_ar", 1.0)
	assert_eq(corpo.pose, "no_ar")
	await wait_physics_frames(6)
	assert_gt(corpo.joelhos[0].rotation.x * -1.0, 0.3, "joelho dobrado no ar")


func test_travado_nos_aposentos() -> void:
	await _entrar_nos_aposentos()
	await _ate_a_etapa("caos")
	await wait_until(func() -> bool: return _corpo().pose == "travado", 1.0)
	assert_eq(_corpo().pose, "travado")


func test_segura_althea_com_os_dois_bracos() -> void:
	await _entrar_nos_aposentos()
	await _ate_a_etapa("nome")
	seq.botao_nome.pressed.emit()
	await _ate_a_etapa("segurar")
	seq.alvo_althea.tocado.emit(seq.alvo_althea)
	await _ate_a_etapa("nos_bracos")
	var corpo := _corpo()
	assert_true(corpo.segurando)
	await _ate_a_etapa("quarto_vazio")
	assert_false(corpo.segurando, "Althea foi levada no escuro")


func test_no_colo_as_maos_ficam_junto_de_althea() -> void:
	var corpo := _corpo()
	cena.travado = true
	corpo.segurando = true
	await wait_seconds(0.6)
	assert_eq(corpo.pose, "segurando")
	# Onde a SequenciaPrologo põe Althea, na frente dos olhos.
	var althea := cena.camera.global_transform * Vector3(0.0, -0.22, -0.43)
	for pulso in corpo.pulsos:
		assert_lt(pulso.global_position.distance_to(althea), 0.3)


# --- Correria no corredor (planos/prologo-npcs.md, etapa 3) ---

func _passagens() -> PassagensPrologo:
	return cena.get_node("Passagens")


func test_empregados_so_aparecem_quando_nicholas_sai_do_quarto() -> void:
	var passagens := _passagens()
	assert_eq(passagens.pessoas().size(), 4, "três na correria e Janet")
	for pessoa in passagens.pessoas():
		assert_false(pessoa.visible, pessoa.name + " ainda não passou")
	cena.continuar_em(_ponto("PortaQuarto"))
	await wait_until(func() -> bool: return passagens.em_caminho.size() >= 2, 4.0)
	for pessoa: PessoaPrologo in passagens.em_caminho.keys():
		assert_true(pessoa.visible)
		assert_eq(pessoa.atividade, "correndo")


func test_correm_para_frente_e_somem_no_fim() -> void:
	var passagens := _passagens()
	cena.continuar_em(_ponto("PortaQuarto"))
	var correria: PessoaPrologo = passagens.get_node("Correria1")
	await wait_until(func() -> bool: return correria.visible, 2.0)
	var antes := correria.global_position
	await wait_seconds(0.3)
	var andou := correria.global_position - antes
	assert_gt(andou.length(), 0.5, "corre")
	var frente := -correria.global_basis.z
	assert_gt(frente.dot(andou.normalized()), 0.8, "olha para onde corre")
	await wait_until(func() -> bool: return not correria.visible, 10.0)
	assert_false(correria.visible, "saiu do corredor")
	assert_false(passagens.em_caminho.has(correria))


func test_ninguem_corre_mais_depois_que_nicholas_entra() -> void:
	var passagens := _passagens()
	cena.continuar_em(_ponto("Corredor"))
	await wait_until(func() -> bool: return not passagens.em_caminho.is_empty(), 2.0)
	await _entrar_nos_aposentos()
	await _ate_a_etapa("caos")
	assert_true(passagens.em_caminho.is_empty())
	for pessoa in passagens.pessoas():
		assert_false(pessoa.visible, pessoa.name)


# --- Janet no quarto vazio (planos/prologo-npcs.md, etapa 4) ---

func test_janet_so_aparece_no_quarto_vazio_e_sai_com_as_roupas() -> void:
	var janet: PessoaPrologo = _passagens().get_node("Janet")
	assert_true(janet.roupas_dobradas)
	assert_not_null(janet.colo.get_node_or_null("RoupasDobradas"))
	await _entrar_nos_aposentos()
	await _ate_a_etapa("nome")
	assert_false(janet.visible, "Janet não está no parto")
	seq.botao_nome.pressed.emit()
	await _ate_a_etapa("segurar")
	seq.alvo_althea.tocado.emit(seq.alvo_althea)
	await _ate_a_etapa("quarto_vazio")
	assert_true(janet.visible, "já no quarto quando a tela clareia")
	assert_eq(janet.atividade, "carregando", "já aparece segurando as roupas")
	await wait_until(func() -> bool: return janet.atividade == "levando_roupas", 5.0)
	var antes := janet.global_position
	await wait_seconds(0.5)
	assert_gt(janet.global_position.distance_to(antes), 0.3, "anda até a porta")
	await wait_until(func() -> bool: return not janet.visible, 15.0)
	assert_false(janet.visible, "saiu pela porta")
	assert_lt(janet.global_position.z, 3.6, "saiu para o corredor")
