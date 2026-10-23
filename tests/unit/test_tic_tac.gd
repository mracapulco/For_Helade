extends GutTest
## P4 da jogabilidade nova (Rafael, 23/10): protótipo do Tic. Tac. num bandido
## de teste (sala_tic_tac.tscn). O bandido finge o golpe na frente e bate
## pelas costas; às vezes vem a visão: tempo quase parado, mundo cinza e o
## golpe de verdade em dourado.

var sala: Node2D
var personagem: PersonagemExploracao
var bandido: Inimigo


func before_each() -> void:
	Configuracoes.movimento_em_grade = false
	Inventario.limpar()
	Experiencia.limpar()
	GradeOcupacao.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_tic_tac.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	bandido = sala.get_node("Bandido")
	bandido.process_mode = Node.PROCESS_MODE_DISABLED
	sala.get_node("BandidoEscudo").process_mode = Node.PROCESS_MODE_DISABLED
	# A navegação da sala (casas andáveis) leva alguns quadros para ficar pronta.
	await wait_physics_frames(10)


func after_each() -> void:
	Engine.time_scale = 1.0


func after_all() -> void:
	Inventario.limpar()


## Põe o bandido numa casa vizinha do Nicholas, pronto para preparar.
func _bandido_ao_lado() -> void:
	# No meio da sala, com casas livres dos dois lados.
	personagem.global_position = personagem.centro_da_casa(personagem.casa_de(Vector2(64, 288)))
	personagem._sincronizar_casa()
	var casa := personagem.casa_de(personagem.global_position) + Vector2i(0, -1)
	bandido.global_position = personagem.centro_da_casa(casa)
	bandido.alvo = personagem


func _tic_tac(chance: float) -> TicTac:
	var tic_tac := TicTac.de(personagem)
	tic_tac.chance_base = chance
	tic_tac.chance_vida_baixa = 0.0
	return tic_tac


func test_bandido_de_teste_tem_o_golpe_pelas_costas() -> void:
	assert_true(bandido.golpe_pelas_costas)
	assert_true(bandido.provoca_tic_tac)
	var normal: Inimigo = sala.get_node("BandidoEscudo")
	assert_false(normal.golpe_pelas_costas, "o outro bandido continua normal, para comparar")


func test_golpe_pelas_costas_sai_de_tras_dele() -> void:
	_tic_tac(0.0)
	_bandido_ao_lado()
	bandido._preparar()
	assert_ne(bandido.origem_golpe, Vector2.INF)
	var lado := bandido.global_position - personagem.global_position
	var atras := bandido.origem_golpe - personagem.global_position
	assert_lt(lado.dot(atras), 0.0, "do outro lado do Nicholas")
	assert_true(bandido.golpe_pega(personagem.global_position), "o golpe de verdade pega onde ele está")
	assert_false(bandido.aviso_verdadeiro.visible, "sem visão, o leque dourado fica escondido")
	assert_not_null(bandido.aviso_no_chao, "o aviso vermelho da frente é a finta")


func test_no_golpe_ele_salta_para_tras_e_acerta() -> void:
	_tic_tac(0.0)
	_bandido_ao_lado()
	bandido._preparar()
	var destino := bandido.origem_golpe
	var vida_antes := personagem.vida.atual
	bandido._golpear()
	assert_eq(bandido.global_position, destino, "saltou para trás do Nicholas")
	assert_lt(personagem.vida.atual, vida_antes, "acertou pelas costas")


func test_sem_chance_nao_vem() -> void:
	var tic_tac := _tic_tac(0.0)
	_bandido_ao_lado()
	bandido._preparar()
	assert_false(tic_tac.ativo)
	assert_eq(Engine.time_scale, 1.0)


func test_visao_para_o_tempo_e_mostra_o_golpe_em_dourado() -> void:
	var tic_tac := _tic_tac(1.0)
	_bandido_ao_lado()
	watch_signals(tic_tac)
	bandido._preparar()
	assert_true(tic_tac.ativo, "Tic.")
	assert_signal_emitted(tic_tac, "visao_comecou")
	assert_lt(Engine.time_scale, 0.1, "o tempo quase para")
	assert_not_null(tic_tac.get_node_or_null("TicTacCinza"), "o mundo perde as cores")
	var visao := tic_tac.get_node_or_null("TicTacVisao")
	assert_not_null(visao.get_node_or_null("VultoDoGolpe"), "o vulto dourado do bandido")
	var leque := visao.get_node("LequeVisto") as AvisoNoChao
	assert_eq(leque.cor, AvisoNoChao.COR_DOURADA)
	assert_eq(leque.position, bandido.origem_golpe, "mostra de onde o golpe sai de verdade")


func test_tac_volta_o_tempo_e_deixa_o_leque_dourado() -> void:
	var tic_tac := _tic_tac(1.0)
	tic_tac.duracao = 0.2
	_bandido_ao_lado()
	bandido._preparar()
	await wait_until(func() -> bool: return not tic_tac.ativo, 3.0)
	assert_false(tic_tac.ativo, "Tac.")
	assert_eq(Engine.time_scale, 1.0)
	assert_null(tic_tac.get_node_or_null("TicTacCinza"))
	assert_true(bandido.aviso_verdadeiro.visible, "o leque dourado fica no chão até o golpe")
	var camera: CameraExploracao = sala.get_node("Personagem/Camera")
	assert_true(camera.tremendo(), "volta com tremores")


func test_pausa_de_impacto_nao_tira_da_visao() -> void:
	var tic_tac := _tic_tac(1.0)
	_bandido_ao_lado()
	bandido._preparar()
	personagem.pausar_no_impacto(0.01)
	await wait_process_frames(5)
	assert_lt(Engine.time_scale, 0.1)
	tic_tac.terminar()


func test_nao_vem_de_novo_logo_em_seguida() -> void:
	var tic_tac := _tic_tac(1.0)
	tic_tac.comecar(bandido)
	tic_tac.terminar()
	assert_eq(tic_tac.chance(), 0.0, "recarregando")
	tic_tac._desde_a_ultima = tic_tac.recarga + 0.1
	assert_eq(tic_tac.chance(), 1.0)


func test_chance_sobe_com_a_vida_baixa() -> void:
	var tic_tac := TicTac.de(personagem)
	tic_tac.chance_base = 0.3
	tic_tac.chance_vida_baixa = 0.4
	var cheia := tic_tac.chance()
	personagem.vida.perder(personagem.vida.maxima_total() / 2)
	assert_gt(tic_tac.chance(), cheia)
	assert_almost_eq(tic_tac.chance(), 0.5, 0.05)


func test_som_volta_ao_normal() -> void:
	var musica := AudioServer.get_bus_index(&"Musica")
	var antes := AudioServer.get_bus_volume_db(musica)
	var tic_tac := _tic_tac(1.0)
	tic_tac.comecar(bandido)
	assert_lt(AudioServer.get_bus_volume_db(musica), antes, "o som some")
	tic_tac.terminar()
	assert_eq(AudioServer.get_bus_volume_db(musica), antes)


func test_textos_vem_da_traducao() -> void:
	TranslationServer.set_locale("pt_BR")
	assert_eq(tr("TIC_TAC_TIC"), "Tic.")
	assert_eq(tr("TIC_TAC_TAC"), "Tac.")
