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


## Onde ficam as mãos em cada quadro da folha de cada faixa (arma e escudo na mão).
const MAOS_POR_FAIXA: Array[MaosPersonagem] = [
	preload("res://assets/art/personagens/nicholas/nicholas_11_maos.tres"),
	preload("res://assets/art/personagens/nicholas/nicholas_adolescente_maos.tres"),
	preload("res://assets/art/personagens/nicholas/nicholas_maos.tres"),
]

## Pixel do ombro da frente no quadro parado, de onde sai o rastro do golpe.
const OMBRO_POR_FAIXA: Array[Vector2] = [Vector2(22, 28), Vector2(22, 21), Vector2(22, 20)]

## Quantos pixels a cabeça e o tronco ficam mais baixos que os do adulto,
## para o elmo e a armadura (desenhados no corpo do adulto) caírem no lugar.
## Provisório até haver desenhos de proteção para cada idade.
const DESCIDA_CABECA: Array[int] = [14, 7, 0]
const DESCIDA_TRONCO: Array[int] = [8, 1, 0]


static func _faixa_valida(faixa: int) -> int:
	return clampi(faixa, 0, POR_FAIXA.size() - 1)


## As mãos de Nicholas na [param faixa].
static func maos(faixa: int) -> MaosPersonagem:
	return MAOS_POR_FAIXA[_faixa_valida(faixa)]


static func ombro(faixa: int) -> Vector2:
	return OMBRO_POR_FAIXA[_faixa_valida(faixa)]


## Quanto descer o desenho de uma proteção do [param encaixe] (ELMO desce com
## a cabeça; o resto, com o tronco) na [param faixa].
static func descida(faixa: int, encaixe: Item.Encaixe) -> int:
	var lista := DESCIDA_CABECA if encaixe == Item.Encaixe.ELMO else DESCIDA_TRONCO
	return lista[_faixa_valida(faixa)]
