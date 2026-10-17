class_name Personagem
extends Resource
## Dados de um personagem que fala no roteiro.

## Nome exatamente como aparece no roteiro, antes dos dois pontos.
@export var nome_no_roteiro: String = ""

## Retratos por expressão, por exemplo "neutro". A expressão vem da
## etiqueta [code][#retrato=...][/code] da fala.
@export var retratos: Dictionary[String, Texture2D] = {}

## Retratos falando, por expressão: uma faixa horizontal de quadros
## quadrados (a boca em posições diferentes). Enquanto o texto aparece, a
## caixa de diálogo alterna esses quadros; ao terminar, volta ao retrato
## parado da mesma expressão.
@export var retratos_fala: Dictionary[String, Texture2D] = {}

## Retrato em pixel art: a caixa mostra sem suavizar os pixels.
@export var pixel_art := false

## Cor do retrato provisório, usada enquanto não há arte.
@export var cor_provisoria: Color = Color(0.3, 0.3, 0.35)


## Retrato da expressão pedida; sem ele, o "neutro"; sem nenhum, null.
func retrato(expressao: String) -> Texture2D:
	return retratos.get(expressao, retratos.get("neutro", null))


## Quadros da boca falando na expressão pedida (ou na "neutro"); vazio
## quando o personagem não tem animação de fala.
func quadros_fala(expressao: String) -> Array[Texture2D]:
	var quadros: Array[Texture2D] = []
	var faixa: Texture2D = retratos_fala.get(expressao, retratos_fala.get("neutro", null))
	if faixa == null:
		return quadros
	var lado := faixa.get_height()
	for i in faixa.get_width() / lado:
		var quadro := AtlasTexture.new()
		quadro.atlas = faixa
		quadro.region = Rect2(i * lado, 0, lado, lado)
		quadros.append(quadro)
	return quadros
