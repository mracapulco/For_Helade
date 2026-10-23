extends GutTest
## Animação da esquiva (Rafael, 23/10): agacha, rola uma volta para o lado
## da esquiva e levanta, deixando vultos azulados no caminho.

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


func test_pose_agacha_rola_e_levanta() -> void:
	var agachado := AnimacaoPersonagem.pose_do_rolamento(0.1)
	assert_lt(agachado.escala.y, 1.0, "agacha")
	assert_eq(agachado.giro, 0.0)
	var no_meio := AnimacaoPersonagem.pose_do_rolamento(0.5)
	assert_almost_eq(no_meio.giro, PI, 0.01, "na metade, de cabeça para baixo")
	assert_gt(no_meio.altura, 0.0, "com um pulinho")
	var quase := AnimacaoPersonagem.pose_do_rolamento(AnimacaoPersonagem.LEVANTAR - 0.001)
	assert_almost_eq(quase.giro, TAU, 0.05, "uma volta inteira")
	var fim := AnimacaoPersonagem.pose_do_rolamento(1.0)
	assert_eq(fim.escala, Vector2.ONE)


func test_rola_para_o_lado_da_esquiva() -> void:
	assert_lt(AnimacaoPersonagem.pose_do_rolamento(0.5, -1.0).giro, 0.0, "para a esquerda, ao contrário")


func test_gira_em_volta_do_meio_do_corpo() -> void:
	personagem.esquivar()
	visual.rolar(0.5)
	# O meio do corpo fica no lugar (mais o pulinho); só gira em volta dele.
	var meio := visual.position + (AnimacaoPersonagem.EIXO_ROLAMENTO * visual.scale).rotated(visual.rotation)
	var pose := AnimacaoPersonagem.pose_do_rolamento(0.5)
	assert_almost_eq(meio, AnimacaoPersonagem.EIXO_ROLAMENTO + Vector2(0, -pose.altura), Vector2(0.01, 0.01))


func test_esquivar_rola_e_depois_volta_ao_normal() -> void:
	Input.action_press("mover_direita")
	await wait_physics_frames(2)
	assert_true(personagem.esquivar())
	await wait_until(func() -> bool: return absf(visual.rotation) > 1.0, 0.5)
	assert_true(visual.rolando)
	assert_gt(visual.rotation, 0.0, "para a direita, no sentido do relógio")
	await wait_until(func() -> bool: return not personagem.esquivando, 1.0)
	await wait_process_frames(2)
	assert_false(visual.rolando)
	assert_eq(visual.rotation, 0.0)
	assert_eq(visual.scale, Vector2.ONE)
	assert_eq(visual.position, Vector2.ZERO)


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
