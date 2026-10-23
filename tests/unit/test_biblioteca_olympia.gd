extends GutTest
## P5 da jogabilidade nova (Rafael, 23/10): sala de desafio na biblioteca do
## Castelo Olympia (V1 P1 c05 e c08). Uma ideia só: a mesa de xadrez fica num
## canto atrás das estantes altas, e a falha nas estantes se esconde atrás de
## uma estante solta; só aparece quando as estantes ficam translúcidas.

const Gerador := preload("res://tools/cena/gerar_biblioteca_olympia.gd")

var sala: Node2D
var personagem: PersonagemExploracao
var estantes: ParedesTranslucidas
var chao: TileMapLayer


func before_each() -> void:
	Configuracoes.movimento_em_grade = false
	Inventario.limpar()
	Codice.limpar()
	GradeOcupacao.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/biblioteca_olympia.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	estantes = sala.get_node("Obstaculos")
	chao = sala.get_node("Chao")
	# A navegação da sala leva alguns quadros para ficar pronta.
	await wait_physics_frames(10)


func after_all() -> void:
	Codice.limpar()


func _no_mundo(casa: Vector2i) -> Vector2:
	return chao.to_global(chao.map_to_local(casa))


func _falha() -> Vector2i:
	return Vector2i(Gerador.FALHA, Gerador.ESTANTES)


func _estante_solta() -> Vector2i:
	return Vector2i(Gerador.FALHA + 1, Gerador.ESTANTES + 1)


func test_a_falha_esta_aberta_e_a_estante_solta_na_frente() -> void:
	assert_eq(estantes.get_cell_source_id(_falha()), -1, "dá para passar pela falha")
	assert_eq(estantes.get_cell_source_id(_falha() + Vector2i(1, 0)), Gerador.ALTA)
	assert_eq(estantes.get_cell_source_id(_estante_solta()), Gerador.ALTA)


func test_a_estante_solta_esconde_a_falha() -> void:
	var desenho := estantes.retangulo_do_bloco(_estante_solta())
	assert_true(desenho.has_point(estantes.to_local(_no_mundo(_falha()))), "na tela, a estante cobre a falha")


func test_o_canto_fica_escondido_atras_das_estantes() -> void:
	var mesa := _no_mundo(Gerador.MESA_XADREZ)
	var cobre := false
	for casa in estantes.get_used_cells():
		if estantes.retangulo_do_bloco(casa).has_point(estantes.to_local(mesa)) \
				and estantes.map_to_local(casa).y > estantes.to_local(mesa).y:
			cobre = true
	assert_true(cobre, "alguma estante na frente cobre a mesa de xadrez")


func test_perto_da_falha_as_estantes_ficam_translucidas() -> void:
	personagem.global_position = _no_mundo(_falha())
	await wait_process_frames(2)
	assert_true(estantes.translucida(_estante_solta()), "a estante solta deixa ver a falha")


func test_o_caminho_ate_a_mesa_passa_pela_falha() -> void:
	var mapa := sala.get_world_2d().navigation_map
	var caminho := NavigationServer2D.map_get_path(mapa, personagem.global_position, _no_mundo(Gerador.MESA_XADREZ + Vector2i(0, 1)), true)
	assert_gt(caminho.size(), 1, "dá para chegar")
	var perto := INF
	for ponto in caminho:
		perto = minf(perto, ponto.distance_to(_no_mundo(_falha())))
	# O caminho pode cortar perto do centro da casa; a falha tem 64 px de largura.
	assert_lt(perto, 24.0, "o único jeito é pela falha")
	assert_almost_eq(caminho[caminho.size() - 1], _no_mundo(Gerador.MESA_XADREZ + Vector2i(0, 1)), Vector2(4, 4))


func test_pilha_de_livros_da_a_pista_e_anota_no_codice() -> void:
	var pilha: Interagivel = sala.get_node("PilhaDeLivros/Interagivel")
	assert_eq(pilha.marcador, "pilha_de_livros")
	var fala: DialogueLine = await pilha.dialogo.get_next_dialogue_line(pilha.marcador)
	assert_string_contains(fala.text, "estante alta")
	await pilha.dialogo.get_next_dialogue_line(fala.next_id)
	assert_true(Codice.tem("pilhas_de_livros"))


func test_mesa_de_xadrez_anota_no_codice() -> void:
	var mesa: Interagivel = sala.get_node("MesaDeXadrez/Interagivel")
	var fala: DialogueLine = await mesa.dialogo.get_next_dialogue_line(mesa.marcador)
	assert_string_contains(fala.text, "Pequena, redonda e levemente empoeirada", "frase do livro (V1 P1 c05)")
	fala = await mesa.dialogo.get_next_dialogue_line(fala.next_id)
	await mesa.dialogo.get_next_dialogue_line(fala.next_id)
	assert_true(Codice.tem("mesa_de_xadrez"))


func test_textos_do_codice_vem_da_traducao() -> void:
	TranslationServer.set_locale("pt_BR")
	assert_eq(Codice.titulo("mesa_de_xadrez"), "A mesa de xadrez")
	assert_eq(Codice.titulo("pilhas_de_livros"), "Pilhas de livros")
	assert_string_contains(Codice.texto("mesa_de_xadrez"), "tabuleiro de mármore")
