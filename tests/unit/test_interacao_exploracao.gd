extends GutTest
## Interação com objetos e personagens na sala de teste.

var sala: Node2D
var personagem: PersonagemExploracao
var objeto: Interagivel


func before_each() -> void:
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	objeto = sala.get_node("ObjetoTeste/Interagivel")
	await wait_physics_frames(3)


func test_toque_no_objeto_encontra_o_interagivel() -> void:
	assert_eq(personagem.interagivel_em(objeto.global_position), objeto)


func test_toque_no_chao_vazio_nao_encontra_nada() -> void:
	assert_null(personagem.interagivel_em(personagem.global_position))


func test_objeto_bloqueia_a_navegacao() -> void:
	var regiao: NavigationRegion2D = sala.get_node("Navegacao")
	var centro := objeto.get_parent().global_position as Vector2
	var mais_perto := NavigationServer2D.map_get_closest_point(regiao.get_navigation_map(), centro)
	assert_gt(mais_perto.distance_to(centro), 15.0)


func test_tocar_de_longe_anda_e_interage_ao_chegar() -> void:
	watch_signals(objeto)
	assert_false(objeto.ao_alcance(personagem.global_position))
	personagem.tocar(objeto.global_position)
	assert_eq(personagem.alvo_interacao, objeto)
	await wait_for_signal(objeto.interagido, 10)
	assert_signal_emitted(objeto, "interagido")
	assert_true(objeto.ao_alcance(personagem.global_position))


func test_tocar_de_perto_interage_na_hora() -> void:
	personagem.global_position = objeto.get_parent().global_position + Vector2(0, 50)
	watch_signals(objeto)
	personagem.tocar(objeto.global_position)
	assert_signal_emitted(objeto, "interagido")
	assert_false(personagem.andando)


func test_destaque_aparece_so_ao_alcance() -> void:
	await wait_frames(2)
	assert_false(objeto.destacado)
	personagem.global_position = objeto.get_parent().global_position + Vector2(0, 50)
	await wait_frames(2)
	assert_true(objeto.destacado)


func test_texto_vem_da_traducao() -> void:
	TranslationServer.set_locale("pt_BR")
	assert_string_starts_with(tr(objeto.chave_texto), "[Provisório]")
