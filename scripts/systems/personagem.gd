class_name Personagem
extends Resource
## Dados de um personagem que fala no roteiro.

## Nome exatamente como aparece no roteiro, antes dos dois pontos.
@export var nome_no_roteiro: String = ""

## Retratos por expressão, por exemplo "neutro". A expressão vem da
## etiqueta [code][#retrato=...][/code] da fala.
@export var retratos: Dictionary[String, Texture2D] = {}

## Cor do retrato provisório, usada enquanto não há arte.
@export var cor_provisoria: Color = Color(0.3, 0.3, 0.35)


## Retrato da expressão pedida; sem ele, o "neutro"; sem nenhum, null.
func retrato(expressao: String) -> Texture2D:
	return retratos.get(expressao, retratos.get("neutro", null))
