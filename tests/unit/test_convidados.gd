extends GutTest
## Folhas dos convidados (pessoas reais como easter egg: Rafael e Shara):
## mesma grade e mesmas animações dos personagens, para usar o mesmo
## AnimacaoPersonagem quando entrarem nas cenas.

const FOLHAS := [
	"res://assets/art/convidados/rafael/rafael_exploracao.tres",
	"res://assets/art/convidados/shara/shara_exploracao.tres",
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


func test_rafael_mais_alto_que_shara_e_ambos_adultos() -> void:
	var rafael := _altura(FOLHAS[0])
	var shara := _altura(FOLHAS[1])
	var ophelia := _altura("res://assets/art/personagens/ophelia/ophelia_11_exploracao.tres")
	assert_lt(shara, rafael)
	assert_lt(ophelia, shara)


# Altura do desenho no primeiro quadro parado de frente, em pixels.
func _altura(caminho: String) -> int:
	var quadros: SpriteFrames = load(caminho)
	var atlas: AtlasTexture = quadros.get_frame_texture(&"parado_frente", 0)
	var imagem := atlas.atlas.get_image().get_region(Rect2i(atlas.region))
	return imagem.get_used_rect().size.y
