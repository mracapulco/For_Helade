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


func test_inimigo_persegue_avisa_e_golpeia() -> void:
	bandido_escudo.process_mode = Node.PROCESS_MODE_DISABLED
	bandido.preparo = 0.1
	personagem.global_position = bandido.global_position + Vector2(-96, 0)
	var vida_antes := vida.atual
	watch_signals(bandido)
	await wait_physics_frames(3)
	assert_eq(bandido.estado, Inimigo.Estado.PERSEGUINDO)
	await wait_until(func() -> bool: return bandido.estado == Inimigo.Estado.PREPARANDO, 4.0)
	assert_lt(bandido.global_position.distance_to(personagem.global_position), bandido.alcance + 1.0)
	await wait_for_signal(bandido.golpeou, 1.0)
	assert_lt(vida.atual, vida_antes, "O golpe tirou vida do Nicholas.")
	var dano := Balanceamento.dano(int(bandido.atributos().ataque), vida.defesa_total())
	assert_eq(vida.atual, vida_antes - dano)


func test_inimigo_nao_ataca_durante_dialogo() -> void:
	personagem.global_position = bandido.global_position + Vector2(-30, 0)
	personagem.em_dialogo = true
	await wait_physics_frames(5)
	assert_eq(bandido.estado, Inimigo.Estado.PARADO)
	personagem.em_dialogo = false


func test_inimigo_desiste_e_volta_ao_posto() -> void:
	bandido_escudo.process_mode = Node.PROCESS_MODE_DISABLED
	var posto := bandido.global_position
	personagem.global_position = bandido.global_position + Vector2(-96, 0)
	await wait_physics_frames(3)
	assert_eq(bandido.estado, Inimigo.Estado.PERSEGUINDO)
	await wait_seconds(0.3)
	personagem.global_position = Vector2(-128, 192)
	await wait_physics_frames(3)
	assert_eq(bandido.estado, Inimigo.Estado.VOLTANDO)
	await wait_until(func() -> bool: return bandido.estado == Inimigo.Estado.PARADO, 4.0)
	assert_lt(bandido.global_position.distance_to(posto), 5.0)


func test_inimigo_morre_some_e_deixa_moedas() -> void:
	var moedas := Inventario.dinheiro()
	watch_signals(bandido)
	bandido.reacao.receber_golpe(Vector2.RIGHT, 999)
	assert_signal_emitted(bandido, "morreu")
	assert_eq(bandido.estado, Inimigo.Estado.MORTO)
	assert_eq(Inventario.dinheiro(), moedas + bandido.moedas)
	assert_false(bandido.reacao.is_in_group(ReacaoAoGolpe.GRUPO), "Morto não é mais atingido.")
	await wait_seconds(1.0)
	assert_false(is_instance_valid(bandido), "Some da sala depois de apagar.")


func test_golpe_do_nicholas_acerta_o_bandido() -> void:
	bandido.process_mode = Node.PROCESS_MODE_DISABLED
	bandido_escudo.process_mode = Node.PROCESS_MODE_DISABLED
	Inventario.adicionar("espada_media")
	Inventario.equipar("nicholas", "espada_media")
	personagem.global_position = bandido.global_position + Vector2(-24, 0)
	personagem.direcao_olhar = Vector2.RIGHT
	assert_has(personagem.alvos_do_golpe(), bandido.reacao)


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
