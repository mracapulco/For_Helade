extends GutTest
## Aposentos da duquesa, varanda e tela final (batidas 3 a 10 do plano).

const FasesHistoria := preload("res://scripts/systems/fases_historia.gd")

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


func _apertar_e() -> void:
	var tecla_e := InputEventAction.new()
	tecla_e.action = "interagir"
	tecla_e.pressed = true
	Input.parse_input_event(tecla_e)
	await wait_physics_frames(2)


func test_nos_aposentos_o_controle_trava_ate_dizer_o_nome() -> void:
	await _entrar_nos_aposentos()
	await _ate_a_etapa("caos")
	assert_true(cena.travado)
	await _ate_a_etapa("nome")
	assert_true(seq.botao_nome.visible)
	assert_eq(seq.botao_nome.text, "Althea?")
	await wait_seconds(0.3)
	assert_eq(seq.etapa, "nome", "nada acontece sem o jogador dizer o nome")
	seq.botao_nome.pressed.emit()
	await _ate_a_etapa("olhares")
	assert_false(seq.botao_nome.visible)


func test_e_diz_o_nome_e_segura_althea() -> void:
	await _entrar_nos_aposentos()
	await _ate_a_etapa("nome")
	await _apertar_e()
	await _ate_a_etapa("segurar")
	assert_true(seq.alvo_althea.ativo)
	await _apertar_e()
	await _ate_a_etapa("nos_bracos")
	assert_eq(seq.althea.get_parent(), cena.camera, "Althea nos braços de Nicholas")


func test_percorre_tudo_ate_o_titulo() -> void:
	watch_signals(seq)
	await _entrar_nos_aposentos()
	await _ate_a_etapa("nome")
	seq.botao_nome.pressed.emit()
	await _ate_a_etapa("segurar")
	seq.alvo_althea.tocado.emit(seq.alvo_althea)
	await _ate_a_etapa("quarto_vazio")
	assert_false(cena.travado, "o controle volta no quarto vazio")
	assert_false(seq.figuras.visible)
	assert_eq(cena.ponto_atual, _ponto("QuartoVazio"))
	var alvo: AlvoToque = _ponto("QuartoVazio").alvos()[0]
	alvo.tocado.emit(alvo)
	await _ate_a_etapa("final")
	await wait_until(func() -> bool: return seq.etapa == "fim", 5.0)
	assert_signal_emitted(seq, "terminou")
	var linhas: Array[String] = []
	for l in seq.tela_final.linhas:
		linhas.append(l.text)
	assert_eq(linhas, ["Por Hélade.", "Pelo Ano Dourado.", "Nicholas, um verdadeiro Filho dos Deuses."] as Array[String])
	assert_eq(seq.tela_final.titulo.text, tr("JOGO_TITULO"))


func test_roteiro_tem_todos_os_trechos_da_sequencia() -> void:
	var roteiro: DialogueResource = cena.roteiro
	for titulo in ["aposentos_caos", "dossel", "muda", "nome", "olhares", "choro", "parabens",
			"costume", "depois", "quarto_vazio", "varanda", "desde_entao", "sussurros_finais"]:
		assert_has(roteiro.get_cues(), titulo)
	var desde: Array[String] = await cena.frases_de("desde_entao")
	assert_true(desde[0].ends_with("sussurravam:"), desde[0])
	var parabens: Array[String] = await cena.frases_de("parabens")
	assert_eq(parabens[0], "— Parabéns Jovem Mestre, é uma menina.")


func test_ao_terminar_vai_para_o_mapa_no_capitulo_1() -> void:
	var nova: SequenciaPrologo = CENA.instantiate().get_node("Sequencia")
	assert_eq(nova.cena_depois, "res://scenes/mapa/mapa_helade.tscn")
	assert_eq(nova.etapa_salva, "capitulo_1")
	assert_eq(FasesHistoria.da_etapa(nova.etapa_salva).local, "atenas")
	nova.get_parent().free()
