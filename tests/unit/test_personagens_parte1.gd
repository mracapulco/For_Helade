extends GutTest
## Folhas dos personagens da Parte I (Nicholas 11, Althea 6, Ophelia 11):
## mesma grade e mesmas animações do Nicholas adulto, para usar o mesmo
## AnimacaoPersonagem.

const FOLHAS := [
	"res://assets/art/personagens/nicholas/nicholas_11_exploracao.tres",
	"res://assets/art/personagens/althea/althea_6_exploracao.tres",
	"res://assets/art/personagens/althea/althea_adolescente_exploracao.tres",
	"res://assets/art/personagens/althea/althea_adulta_exploracao.tres",
	"res://assets/art/personagens/ophelia/ophelia_11_exploracao.tres",
	"res://assets/art/personagens/nicholas/nicholas_adolescente_exploracao.tres",
	"res://assets/art/personagens/ophelia/ophelia_adolescente_exploracao.tres",
	"res://assets/art/personagens/ophelia/ophelia_adulta_exploracao.tres",
]
const ACOES := ["parado", "andando", "correndo", "interagindo"]
const DIRECOES := ["frente", "costas"]


func test_cada_folha_tem_todas_as_animacoes() -> void:
	for caminho in FOLHAS:
		var quadros: SpriteFrames = load(caminho)
		assert_not_null(quadros, caminho)
		for acao in ACOES:
			for direcao in DIRECOES:
				var nome := StringName("%s_%s" % [acao, direcao])
				assert_true(quadros.has_animation(nome), "%s %s" % [caminho, nome])
				assert_gt(quadros.get_frame_count(nome), 1, "%s %s" % [caminho, nome])
				var quadro: Texture2D = quadros.get_frame_texture(nome, 0)
				assert_eq(Vector2i(quadro.get_size()), Vector2i(32, 48), "%s %s" % [caminho, nome])
		assert_false(quadros.get_animation_loop(&"interagindo_frente"), caminho)


func test_criancas_menores_que_o_adulto() -> void:
	var nicholas := _altura("res://assets/art/personagens/nicholas/nicholas_11_exploracao.tres")
	var althea := _altura("res://assets/art/personagens/althea/althea_6_exploracao.tres")
	var adulto := _altura("res://assets/art/personagens/nicholas/nicholas_exploracao.tres")
	assert_lt(althea, nicholas)
	assert_lt(nicholas, adulto)


# Rafael pediu (15/10) Ophelia da altura de Nicholas em cada idade. A
# diferença de 1 pixel é a mecha espetada do cabelo dele.
func test_ophelia_da_altura_de_nicholas_em_cada_idade() -> void:
	var nicholas := _altura("res://assets/art/personagens/nicholas/nicholas_11_exploracao.tres")
	var nicholas_adolescente := _altura("res://assets/art/personagens/nicholas/nicholas_adolescente_exploracao.tres")
	var adulto := _altura("res://assets/art/personagens/nicholas/nicholas_exploracao.tres")
	var crianca := _altura("res://assets/art/personagens/ophelia/ophelia_11_exploracao.tres")
	var adolescente := _altura("res://assets/art/personagens/ophelia/ophelia_adolescente_exploracao.tres")
	var adulta := _altura("res://assets/art/personagens/ophelia/ophelia_adulta_exploracao.tres")
	assert_almost_eq(crianca, nicholas, 1)
	assert_almost_eq(adolescente, nicholas_adolescente, 1)
	assert_almost_eq(adulta, adulto, 1)
	assert_gt(nicholas_adolescente, nicholas)
	assert_lt(nicholas_adolescente, adulto)


# Althea é 5 anos mais nova: cresce a cada fase e fica um pouco mais baixa
# que o irmão em cada uma.
func test_althea_cresce_e_fica_mais_baixa_que_nicholas() -> void:
	var crianca := _altura("res://assets/art/personagens/althea/althea_6_exploracao.tres")
	var adolescente := _altura("res://assets/art/personagens/althea/althea_adolescente_exploracao.tres")
	var adulta := _altura("res://assets/art/personagens/althea/althea_adulta_exploracao.tres")
	assert_lt(crianca, adolescente)
	assert_lt(adolescente, adulta)
	assert_lt(adolescente, _altura("res://assets/art/personagens/nicholas/nicholas_adolescente_exploracao.tres"))
	assert_lt(adulta, _altura("res://assets/art/personagens/nicholas/nicholas_exploracao.tres"))


# Altura do desenho no primeiro quadro parado de frente, em pixels.
func _altura(caminho: String) -> int:
	var quadros: SpriteFrames = load(caminho)
	var atlas: AtlasTexture = quadros.get_frame_texture(&"parado_frente", 0)
	var imagem := atlas.atlas.get_image().get_region(Rect2i(atlas.region))
	return imagem.get_used_rect().size.y
