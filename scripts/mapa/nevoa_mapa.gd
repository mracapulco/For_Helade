class_name NevoaMapa
extends Sprite2D
## Névoa por cima do que ainda não foi descoberto no mapa. Guarda uma máscara
## em baixa resolução (1 = névoa) e o shader nevoa_mapa.gdshader a desenha
## como nuvens pixeladas que andam devagar.

## Pixels da arte por pixel da máscara.
const ESCALA := 8
## Raio aberto em volta de cada lugar descoberto, em pixels da arte.
const RAIO_REGIAO := 150.0
const RAIO_PONTO := 85.0
## Largura da borda suave da clareira.
const BORDA := 40.0
const CORES_DIA := [Color(0.79, 0.81, 0.85), Color(0.55, 0.60, 0.68)]
const CORES_NOITE := [Color(0.17, 0.24, 0.33), Color(0.07, 0.11, 0.18)]

var _mascara: Image
var _textura: ImageTexture
var _noite := 0.0


## Cobre o mapa inteiro de névoa. [param tamanho] em pixels da arte.
func preparar(tamanho: Vector2) -> void:
	_mascara = Image.create_empty(ceili(tamanho.x / ESCALA), ceili(tamanho.y / ESCALA), false, Image.FORMAT_L8)
	_mascara.fill(Color.WHITE)
	_textura = ImageTexture.create_from_image(_mascara)
	texture = _textura
	centered = false
	scale = Vector2.ONE * ESCALA
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	(material as ShaderMaterial).set_shader_parameter(&"tamanho_mapa", tamanho)
	definir_noite(0.0)


## Abre a névoa em volta de cada lugar da lista.
func revelar(locais: Array[LocalMapa]) -> void:
	for local in locais:
		var raio := RAIO_REGIAO if local.tipo == LocalMapa.Tipo.REGIAO else RAIO_PONTO
		_abrir(local.posicao, raio)
	_textura.update(_mascara)


## Quanto de névoa (0 a 1) há num ponto do mapa (pixels da arte).
func densidade_em(posicao: Vector2) -> float:
	var p := Vector2i(posicao / ESCALA)
	if p.x < 0 or p.y < 0 or p.x >= _mascara.get_width() or p.y >= _mascara.get_height():
		return 1.0
	return _mascara.get_pixelv(p).r


## 0 = dia, 1 = noite (valores do meio na transição).
func definir_noite(quanto: float) -> void:
	_noite = quanto
	var shader := material as ShaderMaterial
	shader.set_shader_parameter(&"cor_clara", CORES_DIA[0].lerp(CORES_NOITE[0], quanto))
	shader.set_shader_parameter(&"cor_escura", CORES_DIA[1].lerp(CORES_NOITE[1], quanto))


func _abrir(centro: Vector2, raio: float) -> void:
	var c := centro / ESCALA
	var r := raio / ESCALA
	var borda := BORDA / ESCALA
	var de := Vector2i((c - Vector2.ONE * r).floor()).max(Vector2i.ZERO)
	var ate := Vector2i((c + Vector2.ONE * r).ceil()).min(_mascara.get_size() - Vector2i.ONE)
	for y in range(de.y, ate.y + 1):
		for x in range(de.x, ate.x + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var nevoa := clampf((d - (r - borda)) / borda, 0.0, 1.0)
			if nevoa < _mascara.get_pixel(x, y).r:
				_mascara.set_pixel(x, y, Color(nevoa, nevoa, nevoa))
