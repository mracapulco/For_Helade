extends GutTest
## Móveis da SalaMontada na frente do jogador ficam translúcidos (Rafael, 23/10).


func test_caixote_na_frente_cobre_e_atras_nao() -> void:
	var sala := SalaMontada.new()
	sala.largura = 6
	sala.profundidade = 6
	var textura := load("res://assets/art/capitulo_01/loja/caixote_pesado.png") as Texture2D
	var caixote := sala.adicionar_objeto("caixote", textura, Vector2i(3, 3), true, false, 17.0)
	add_child_autofree(sala)
	var jogador := Node2D.new()
	sala.add_child(jogador)
	jogador.position = sala.centro(Vector2i(2, 2))
	assert_true(sala.cobre(caixote, jogador), "atrás do caixote, o caixote cobre")
	jogador.position = sala.centro(Vector2i(4, 4))
	assert_false(sala.cobre(caixote, jogador), "na frente, não")
	jogador.position = sala.centro(Vector2i(0, 5))
	assert_false(sala.cobre(caixote, jogador), "longe, não")
	var pessoa := sala.adicionar_pessoa("thea", textura, Vector2i(1, 1))
	assert_true(pessoa.has_meta(SalaMontada.META_TRANSLUCIDO), "desenho simples")


func test_banquinho_baixo_ao_lado_nao_some() -> void:
	var sala := SalaMontada.new()
	var textura := load("res://assets/art/capitulo_01/loja/banquinho.png") as Texture2D
	var banquinho := sala.adicionar_objeto("banquinho", textura, Vector2i(3, 3), true, false, 17.0)
	add_child_autofree(sala)
	var jogador := Node2D.new()
	sala.add_child(jogador)
	jogador.position = sala.centro(Vector2i(2, 3))
	assert_false(sala.cobre(banquinho, jogador))
