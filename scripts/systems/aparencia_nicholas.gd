extends RefCounted
## O desenho de Nicholas na idade atual ([member Inventario.faixa_etaria]):
## criança no começo da história (11 anos, Parte I), depois adolescente e adulto.
##
## Usado no mapa de Hélade e nos acampamentos, que antes mostravam sempre o adulto.

## Um por faixa, na ordem de [enum Inventario.FaixaEtaria] (CRIANCA, ADOLESCENTE, ADULTO).
const POR_FAIXA: Array[SpriteFrames] = [
	preload("res://assets/art/personagens/nicholas/nicholas_11_exploracao.tres"),
	preload("res://assets/art/personagens/nicholas/nicholas_adolescente_exploracao.tres"),
	preload("res://assets/art/personagens/nicholas/nicholas_exploracao.tres"),
]


## Os quadros de Nicholas na [param faixa] (um valor de [enum Inventario.FaixaEtaria]).
static func quadros(faixa: int) -> SpriteFrames:
	return POR_FAIXA[clampi(faixa, 0, POR_FAIXA.size() - 1)]


## Os quadros de Nicholas na idade em que ele está agora no jogo.
static func quadros_atuais() -> SpriteFrames:
	return quadros(Inventario.faixa_etaria)
