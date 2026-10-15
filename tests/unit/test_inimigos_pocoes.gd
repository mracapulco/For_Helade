extends GutTest
## Vida do Nicholas, poções (cura, rapidez, vigor), barras de vida e os
## bandidos da sala de teste.

var sala: Node2D
var personagem: PersonagemExploracao
var vida: Vida
var efeitos: EfeitosTemporarios
var hud: HudVida
var bandido: Inimigo
var bandido_escudo: Inimigo


func before_each() -> void:
	Inventario.limpar()
	GradeOcupacao.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	vida = sala.get_node("Personagem/Vida")
	efeitos = sala.get_node("Personagem/Efeitos")
	hud = sala.get_node("HudVida")
	bandido = sala.get_node("Bandido")
	bandido_escudo = sala.get_node("BandidoEscudo")
	await wait_physics_frames(2)


func after_all() -> void:
	Inventario.limpar()


# ---------- vida e poções ----------

func test_vida_extra_soma_ao_maximo_e_some_sem_matar() -> void:
	var v: Vida = autofree(Vida.new())
	v.maxima = 30
	add_child(v)
	v.ganhar_extra(10)
	assert_eq(v.maxima_total(), 40)
	assert_eq(v.atual, 40)
	v.perder(35)
	v.perder_extra(10)
	assert_eq(v.maxima_total(), 30)
	assert_eq(v.atual, 5, "Quem tinha vida abaixo do máximo normal fica como estava.")
	v.ganhar_extra(10)
	v.perder_extra(10)
	assert_eq(v.atual, 15, "Os 10 ganhos com o vigor ficam, abaixo do máximo normal.")
	v.restaurar()
	v.ganhar_extra(5)
	v.perder(3)
	v.perder_extra(5)
	assert_eq(v.atual, 30, "A vida acima do máximo normal some quando o efeito acaba.")


func test_pocoes_estao_no_catalogo_e_na_sala() -> void:
	for id in ["pocao_cura", "pocao_rapidez", "pocao_vigor"]:
		var item := Inventario.item(id)
		assert_not_null(item, id)
		assert_true(item.pode_usar(), id)
		assert_not_null(item.icone, id)
		assert_ne(tr(item.chave_nome), item.chave_nome, "Nome traduzido: " + id)
	var bau := sala.get_node("BauPocoes/Recompensa")
	assert_eq(bau.itens, {"pocao_cura": 3, "pocao_rapidez": 2, "pocao_vigor": 2})
	assert_true(Inventario.item("pocao_rapidez").tem_efeito_temporario())
	assert_false(Inventario.item("pocao_cura").tem_efeito_temporario())


func test_pocao_de_cura_pela_bolsa() -> void:
	vida.perder(25)
	Inventario.adicionar("pocao_cura")
	assert_true(Inventario.usar("pocao_cura", "nicholas"))
	assert_eq(vida.atual, vida.maxima - 25 + 20)
	assert_eq(Inventario.quantidade("pocao_cura"), 0)
	Inventario.adicionar("pocao_cura")
	Inventario.usar("pocao_cura", "nicholas")
	assert_eq(vida.atual, vida.maxima, "A cura não passa do máximo.")


func test_pocao_de_rapidez_acelera_e_acaba() -> void:
	var antes := personagem.velocidade_andando()
	var ritmo_antes := personagem.ritmo()
	efeitos.aplicar(Inventario.item("pocao_rapidez"))
	await wait_process_frames(1)
	assert_almost_eq(personagem.velocidade_andando(), antes * 1.3, 0.5)
	assert_gt(personagem.ritmo(), ritmo_antes)
	efeitos.aplicar(Inventario.item("pocao_rapidez"))
	assert_eq(efeitos.ativos().size(), 1, "A mesma poção renova o tempo, sem somar.")
	assert_eq(efeitos.bonus_velocidade(), 30)
	efeitos._ativos[0].resta = 0.05
	await wait_seconds(0.15)
	assert_eq(efeitos.ativos().size(), 0)
	assert_almost_eq(personagem.velocidade_andando(), antes, 0.5)


func test_pocao_de_vigor_da_vida_a_mais_por_um_tempo() -> void:
	efeitos.aplicar(Inventario.item("pocao_vigor"))
	assert_eq(vida.maxima_total(), vida.maxima + 20)
	assert_eq(vida.atual, vida.maxima + 20)
	efeitos._ativos[0].resta = 0.05
	await wait_seconds(0.15)
	assert_eq(vida.maxima_total(), vida.maxima)
	assert_eq(vida.atual, vida.maxima)


func test_bolsa_mostra_o_efeito_da_pocao() -> void:
	assert_string_contains(TelaBolsa.texto_bonus(Inventario.item("pocao_cura")), "20")
	assert_string_contains(TelaBolsa.texto_bonus(Inventario.item("pocao_rapidez")), "20s")
	assert_string_contains(TelaBolsa.texto_bonus(Inventario.item("pocao_vigor")), "30s")


# ---------- barras ----------

func test_hud_mostra_vida_e_efeitos() -> void:
	assert_eq(hud.rotulo.text, tr("HUD_VIDA") % [vida.maxima, vida.maxima])
	vida.perder(7)
	assert_eq(hud.rotulo.text, tr("HUD_VIDA") % [vida.maxima - 7, vida.maxima])
	assert_eq(hud.rotulo_efeitos.text, "")
	efeitos.aplicar(Inventario.item("pocao_rapidez"))
	await wait_process_frames(2)
	assert_string_contains(hud.rotulo_efeitos.text, tr("ITEM_POCAO_RAPIDEZ_NOME"))
	assert_string_contains(hud.rotulo_efeitos.text, "20s")


func test_barra_do_inimigo_aparece_depois_do_dano() -> void:
	var barra: BarraVidaMundo = bandido.get_node("BarraVida")
	assert_false(barra.visible, "Com a vida cheia, a barra fica escondida.")
	bandido.vida.perder(5)
	assert_true(barra.visible)
	assert_almost_eq(bandido.vida.fracao(), 20.0 / 25.0, 0.001)


# ---------- inimigos ----------

func test_bandidos_ficam_em_casas_andaveis_e_tem_equipamento() -> void:
	await wait_seconds(0.5)   # a malha de navegação fica pronta depois de alguns quadros
	for inimigo: Inimigo in [bandido, bandido_escudo]:
		assert_true(personagem.casa_andavel(inimigo.global_position), inimigo.name)
		assert_gt(inimigo.global_position.distance_to(personagem.global_position), inimigo.raio_visao,
			"Começa longe o bastante para não atacar logo na entrada.")
	assert_eq(int(bandido.atributos().ataque), Balanceamento.ATAQUE_BASE + Inventario.item("punhal").ataque)
	var defesa_escudo := 0
	for id in bandido_escudo.equipamento:
		defesa_escudo += Inventario.item(id).defesa
	assert_gt(defesa_escudo, 0)
	assert_eq(bandido_escudo.vida.defesa_total(), defesa_escudo)
	assert_lt(bandido_escudo.velocidade_andando(), bandido.velocidade_andando(),
		"Com escudo e armadura ele anda mais devagar.")


func test_inimigo_parado_ate_ver_o_jogador() -> void:
	await wait_physics_frames(5)
	assert_eq(bandido.estado, Inimigo.Estado.PARADO)


## Espera a malha de navegação da sala ficar pronta.
func _esperar_navegacao() -> void:
	await wait_seconds(0.5)


func _casa(no: Node2D) -> Vector2i:
	return personagem.casa_de(no.global_position)


## Leva alguém para uma casa, acertando a ocupação da grade.
func _levar(no: Node2D, casa: Vector2i) -> void:
	GradeOcupacao.liberar_tudo(no)
	no.global_position = personagem.centro_da_casa(casa)
	GradeOcupacao.ocupar(casa, no)


func _olhar_para(passo: Vector2i) -> void:
	var aqui := _casa(personagem)
	personagem.direcao_olhar = (personagem.centro_da_casa(aqui + passo) - personagem.centro_da_casa(aqui)).normalized()


func test_inimigo_fica_no_centro_de_uma_casa_e_ocupa_ela() -> void:
	for inimigo: Inimigo in [bandido, bandido_escudo]:
		assert_eq(inimigo.global_position, personagem.centro_da_casa(_casa(inimigo)))
		assert_eq(GradeOcupacao.ocupante(_casa(inimigo)), inimigo)
	assert_eq(GradeOcupacao.casas_de(personagem), [_casa(personagem)] as Array[Vector2i])


func test_inimigo_persegue_pela_grade_avisa_e_golpeia() -> void:
	await _esperar_navegacao()
	bandido_escudo.process_mode = Node.PROCESS_MODE_DISABLED
	bandido.preparo = 0.1
	_levar(personagem, _casa(bandido) + Vector2i(-3, 0))
	var vida_antes := vida.atual
	await wait_physics_frames(3)
	assert_eq(bandido.estado, Inimigo.Estado.PERSEGUINDO)
	await wait_until(func() -> bool: return bandido.estado == Inimigo.Estado.PREPARANDO, 4.0)
	assert_true(bandido.vizinho_do_alvo())
	assert_eq(bandido.global_position, personagem.centro_da_casa(_casa(bandido)), "Para no centro de uma casa.")
	await wait_for_signal(bandido.golpeou, 1.0)
	var dano := Balanceamento.dano(int(bandido.atributos().ataque), vida.defesa_total())
	assert_eq(vida.atual, vida_antes - dano, "O golpe tirou vida do Nicholas.")


func test_dois_inimigos_nunca_dividem_uma_casa() -> void:
	await _esperar_navegacao()
	bandido.preparo = 5.0
	bandido_escudo.preparo = 5.0
	_levar(personagem, _casa(bandido) + Vector2i(-2, 0))
	for i in 40:
		await wait_physics_frames(3)
		assert_ne(_casa(bandido), _casa(bandido_escudo))
		assert_ne(_casa(bandido), _casa(personagem))
		assert_ne(_casa(bandido_escudo), _casa(personagem))
		for inimigo: Inimigo in [bandido, bandido_escudo]:
			for casa in GradeOcupacao.casas_de(inimigo):
				assert_ne(GradeOcupacao.ocupante(casa), bandido if inimigo == bandido_escudo else bandido_escudo)
	assert_true(bandido.vizinho_do_alvo() and bandido_escudo.vizinho_do_alvo(), "Os dois chegaram perto, cada um na sua casa.")


func test_nicholas_nao_entra_na_casa_de_um_inimigo() -> void:
	await _esperar_navegacao()
	bandido.process_mode = Node.PROCESS_MODE_DISABLED
	bandido_escudo.process_mode = Node.PROCESS_MODE_DISABLED
	_levar(personagem, _casa(bandido) + Vector2i(-1, 0))
	personagem.direcao_olhar = PersonagemExploracao.direcao_isometrica(Vector2(0, 1))
	var antes := _casa(personagem)
	Input.action_press("mover_tras")
	await wait_seconds(0.5)
	Input.action_release("mover_tras")
	await wait_seconds(0.3)
	assert_eq(_casa(personagem), antes, "A casa da frente é do bandido.")


func test_inimigo_nao_ataca_durante_dialogo() -> void:
	await _esperar_navegacao()
	_levar(personagem, _casa(bandido) + Vector2i(-1, 0))
	personagem.em_dialogo = true
	await wait_physics_frames(5)
	assert_eq(bandido.estado, Inimigo.Estado.PARADO)
	personagem.em_dialogo = false


func test_inimigo_desiste_e_volta_ao_posto() -> void:
	await _esperar_navegacao()
	bandido_escudo.process_mode = Node.PROCESS_MODE_DISABLED
	var posto := _casa(bandido)
	var inicio := _casa(personagem)
	_levar(personagem, posto + Vector2i(-3, 0))
	await wait_physics_frames(3)
	assert_eq(bandido.estado, Inimigo.Estado.PERSEGUINDO)
	await wait_seconds(0.4)
	_levar(personagem, inicio)
	await wait_until(func() -> bool: return bandido.estado == Inimigo.Estado.VOLTANDO, 2.0)
	await wait_until(func() -> bool: return bandido.estado == Inimigo.Estado.PARADO, 5.0)
	assert_eq(_casa(bandido), posto)


func test_inimigo_morre_some_e_deixa_moedas() -> void:
	var moedas := Inventario.dinheiro()
	var casa := _casa(bandido)
	watch_signals(bandido)
	bandido.reacao.receber_golpe(Vector2.RIGHT, 999)
	assert_signal_emitted(bandido, "morreu")
	assert_eq(bandido.estado, Inimigo.Estado.MORTO)
	assert_eq(Inventario.dinheiro(), moedas + bandido.moedas)
	assert_false(bandido.reacao.is_in_group(ReacaoAoGolpe.GRUPO), "Morto não é mais atingido.")
	assert_null(GradeOcupacao.ocupante(casa), "A casa fica livre.")
	await wait_seconds(1.0)
	assert_false(is_instance_valid(bandido), "Some da sala depois de apagar.")


func test_golpe_pega_so_a_casa_da_frente() -> void:
	bandido.process_mode = Node.PROCESS_MODE_DISABLED
	bandido_escudo.process_mode = Node.PROCESS_MODE_DISABLED
	Inventario.adicionar("espada_media")
	Inventario.equipar("nicholas", "espada_media")
	var aqui := _casa(bandido) + Vector2i(-1, 0)
	_levar(personagem, aqui)
	_levar(bandido_escudo, aqui + Vector2i(2, 0))
	_olhar_para(Vector2i(1, 0))
	assert_eq(personagem.passo_do_olhar(), Vector2i(1, 0))
	assert_eq(personagem.alvos_do_golpe(), [bandido.reacao] as Array[ReacaoAoGolpe])
	_levar(bandido_escudo, aqui + Vector2i(1, 1))
	assert_eq(personagem.alvos_do_golpe(), [bandido.reacao] as Array[ReacaoAoGolpe],
		"Quem está na casa ao lado da frente não é atingido.")
	_olhar_para(Vector2i(0, 1))
	assert_eq(personagem.alvos_do_golpe(), [] as Array[ReacaoAoGolpe])


func test_flecha_para_no_primeiro_da_linha() -> void:
	await _esperar_navegacao()
	bandido.process_mode = Node.PROCESS_MODE_DISABLED
	bandido_escudo.process_mode = Node.PROCESS_MODE_DISABLED
	Inventario.adicionar("arco")
	Inventario.equipar("nicholas", "arco")
	assert_eq(personagem.casas_do_golpe(), 8)
	var aqui := _casa(bandido) + Vector2i(-4, 0)
	_levar(personagem, aqui)
	_levar(bandido_escudo, _casa(bandido) + Vector2i(1, 0))
	_olhar_para(Vector2i(1, 0))
	assert_eq(personagem.alvos_do_golpe(), [bandido.reacao] as Array[ReacaoAoGolpe])


# ---------- derrota ----------

func test_derrota_volta_ao_inicio_com_vida_cheia() -> void:
	var inicio := personagem.global_position
	efeitos.aplicar(Inventario.item("pocao_vigor"))
	personagem.global_position = Vector2(200, 300)
	watch_signals(personagem)
	vida.perder(999)
	assert_signal_emitted(personagem, "derrotado")
	assert_eq(personagem.global_position, inicio)
	assert_eq(vida.atual, vida.maxima)
	assert_eq(vida.maxima_total(), vida.maxima, "Os efeitos acabam na derrota.")
	assert_eq(efeitos.ativos().size(), 0)
