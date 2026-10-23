extends GutTest
## Animação da esquiva (Rafael, 23/10): abaixa, avança inclinado para o lado
## da esquiva e se endireita, deixando vultos azulados no caminho. Começou
## como cambalhota, mas "parecia um ninja".

var sala: Node2D
var personagem: PersonagemExploracao
var visual: AnimacaoPersonagem


func before_each() -> void:
	Configuracoes.movimento_em_grade = false
	Inventario.limpar()
	GradeOcupacao.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	visual = sala.get_node("Personagem/Corpo/Visual")
	for inimigo in [sala.get_node("Bandido"), sala.get_node("BandidoEscudo")]:
		inimigo.process_mode = Node.PROCESS_MODE_DISABLED
	await wait_physics_frames(2)


func after_each() -> void:
	Input.action_release("mover_direita")
	Input.action_release("mover_esquerda")


func after_all() -> void:
	Inventario.limpar()


func test_pose_abaixa_inclina_e_se_endireita() -> void:
	var abaixando := AnimacaoPersonagem.pose_da_esquiva(0.1)
	assert_lt(abaixando.escala.y, 1.0, "abaixa")
	var no_meio := AnimacaoPersonagem.pose_da_esquiva(0.5)
	assert_lt(no_meio.escala.y, 1.0, "baixo")
	assert_almost_eq(no_meio.giro, AnimacaoPersonagem.INCLINACAO, 0.001, "inclinado para a frente")
	assert_lt(absf(no_meio.giro), 0.5, "só inclina, sem cambalhota")
	var fim := AnimacaoPersonagem.pose_da_esquiva(1.0)
	assert_eq(fim.escala, Vector2.ONE)
	assert_almost_eq(fim.giro, 0.0, 0.001)


func test_inclina_para_o_lado_da_esquiva() -> void:
	assert_lt(AnimacaoPersonagem.pose_da_esquiva(0.5, -1.0).giro, 0.0, "para a esquerda, ao contrário")


func test_esquivar_inclina_e_depois_volta_ao_normal() -> void:
	Input.action_press("mover_direita")
	await wait_physics_frames(2)
	assert_true(personagem.esquivar())
	await wait_until(func() -> bool: return visual.rotation > 0.2, 0.5)
	assert_true(visual.esquivando)
	assert_gt(visual.rotation, 0.0, "para a direita, inclina para a direita")
	assert_eq(visual.position, Vector2.ZERO, "os pés ficam no chão")
	await wait_until(func() -> bool: return not personagem.esquivando, 1.0)
	await wait_process_frames(2)
	assert_false(visual.esquivando)
	assert_eq(visual.rotation, 0.0)
	assert_eq(visual.scale, Vector2.ONE)


func test_deixa_vultos_que_somem() -> void:
	Input.action_press("mover_esquerda")
	await wait_physics_frames(2)
	personagem.esquivar()
	await wait_seconds(0.12)
	var vultos := get_tree().get_nodes_in_group(AnimacaoPersonagem.GRUPO_VULTO)
	assert_gt(vultos.size(), 1, "um rastro de vultos")
	assert_lt(vultos[0].modulate.a, 1.0, "translúcidos")
	await wait_seconds(0.6)
	vultos = get_tree().get_nodes_in_group(AnimacaoPersonagem.GRUPO_VULTO)
	assert_eq(vultos.size(), 0, "somem")
