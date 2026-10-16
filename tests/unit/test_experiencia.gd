extends GutTest
## Nível: garantido pela história, com experiência a mais das lutas.

const X := preload("res://scripts/autoload/experiencia.gd")

var sala: Node2D
var personagem: PersonagemExploracao
var vida: Vida


func before_each() -> void:
	Inventario.limpar()
	Experiencia.limpar()
	GradeOcupacao.limpar()


func after_all() -> void:
	Inventario.limpar()
	Experiencia.limpar()


func _abrir_sala() -> void:
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	vida = sala.get_node("Personagem/Vida")
	await wait_physics_frames(2)


func test_curva_de_experiencia() -> void:
	assert_eq(X.experiencia_para(1), 0)
	assert_eq(X.experiencia_para(2), X.PASSO_EXPERIENCIA)
	assert_eq(X.experiencia_para(3), X.PASSO_EXPERIENCIA * 3)
	assert_eq(X.nivel_com(0), 1)
	assert_eq(X.nivel_com(X.experiencia_para(3) - 1), 2)
	assert_eq(X.nivel_com(X.experiencia_para(3)), 3)
	assert_eq(X.nivel_com(1 << 30), X.NIVEL_MAXIMO)


func test_comeca_no_nivel_1_sem_bonus() -> void:
	assert_eq(Experiencia.nivel("nicholas"), 1)
	assert_eq(Experiencia.bonus_vida("nicholas"), 0)
	assert_eq(Experiencia.bonus_ataque("nicholas"), 0)


func test_lutar_da_experiencia_e_sobe_de_nivel() -> void:
	watch_signals(Experiencia)
	Experiencia.ganhar("nicholas", X.PASSO_EXPERIENCIA - 1)
	assert_eq(Experiencia.nivel("nicholas"), 1)
	assert_signal_not_emitted(Experiencia, "subiu")
	Experiencia.ganhar("nicholas", 1)
	assert_eq(Experiencia.nivel("nicholas"), 2)
	assert_signal_emitted_with_parameters(Experiencia, "subiu", ["nicholas", 2])


func test_historia_garante_o_nivel_sem_tirar_o_que_foi_lutado() -> void:
	Experiencia.garantir_nivel("nicholas", 3)
	assert_eq(Experiencia.nivel("nicholas"), 3)
	Experiencia.ganhar("nicholas", X.experiencia_para(5))
	var lutado := Experiencia.experiencia("nicholas")
	Experiencia.garantir_nivel("nicholas", 4)
	assert_eq(Experiencia.experiencia("nicholas"), lutado, "quem já passou do marco não perde nada")


func test_nivel_soma_ataque_e_vida() -> void:
	var ataque_antes := int(Inventario.atributos("nicholas").ataque)
	Experiencia.garantir_nivel("nicholas", 5)
	assert_eq(Experiencia.bonus_vida("nicholas"), 4 * X.VIDA_POR_NIVEL)
	assert_eq(int(Inventario.atributos("nicholas").ataque), ataque_antes + 4 / X.NIVEIS_POR_ATAQUE)


func test_progresso_ate_o_proximo_nivel() -> void:
	assert_eq(Experiencia.progresso("nicholas"), 0.0)
	Experiencia.ganhar("nicholas", X.PASSO_EXPERIENCIA / 2)
	assert_almost_eq(Experiencia.progresso("nicholas"), 0.5, 0.01)


func test_subir_de_nivel_aumenta_a_vida_do_nicholas() -> void:
	await _abrir_sala()
	var maxima := vida.maxima
	Experiencia.garantir_nivel("nicholas", 3)
	assert_eq(vida.maxima, maxima + 2 * X.VIDA_POR_NIVEL)
	assert_eq(vida.atual, vida.maxima)


func test_bandido_derrotado_da_experiencia() -> void:
	await _abrir_sala()
	var bandido: Inimigo = sala.get_node("Bandido")
	assert_gt(bandido.experiencia, 0)
	bandido.reacao.receber_golpe(Vector2.RIGHT, 999)
	assert_eq(Experiencia.experiencia("nicholas"), bandido.experiencia)


func test_hud_mostra_o_nivel() -> void:
	await _abrir_sala()
	var hud: HudVida = sala.get_node("HudVida")
	assert_eq(hud.rotulo_nivel.text, tr("HUD_NIVEL") % 1)
	Experiencia.garantir_nivel("nicholas", 2)
	assert_eq(hud.rotulo_nivel.text, tr("HUD_NIVEL") % 2)


func test_nivel_volta_no_jogo_salvo() -> void:
	Experiencia.ganhar("nicholas", 75)
	var dados := Experiencia.para_dados()
	Experiencia.limpar()
	Experiencia.de_dados(dados)
	assert_eq(Experiencia.experiencia("nicholas"), 75)
