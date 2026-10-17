class_name MaosPersonagem
extends Resource
## Onde ficam as mãos do personagem em cada quadro de cada animação, para
## desenhar o que ele tem equipado: a arma na mão da frente e o escudo (ou
## a caixa, a panela) na mão de trás.
## Gerado junto com a folha de animação (tools/arte/gerar_nicholas.py).

## Tamanho de um quadro da folha, em pixels.
@export var tamanho_quadro := Vector2i(32, 48)

## Animação -> um ponto por quadro: o pixel de cima à esquerda da mão,
## contado a partir do canto de cima à esquerda do quadro.
@export var pontos: Dictionary[StringName, PackedVector2Array] = {}


## Pixel da mão no quadro, ou (-1, -1) se a animação não tiver esse quadro.
func ponto(animacao: StringName, quadro: int) -> Vector2:
	var lista: PackedVector2Array = pontos.get(animacao, PackedVector2Array())
	if quadro < 0 or quadro >= lista.size():
		return Vector2(-1, -1)
	return lista[quadro]


## Animação -> giro do item na mão em cada quadro, em graus (0 = como o
## desenho do item, ponta para baixo; 180 = para cima; -90 = para a frente).
## Animações fora daqui não giram o item.
@export var angulos: Dictionary[StringName, PackedFloat32Array] = {}


func angulo(animacao: StringName, quadro: int) -> float:
	var lista: PackedFloat32Array = angulos.get(animacao, PackedFloat32Array())
	if quadro < 0 or quadro >= lista.size():
		return 0.0
	return lista[quadro]


## Animação -> um ponto por quadro da mão de trás (escudo), como [member pontos].
@export var pontos_tras: Dictionary[StringName, PackedVector2Array] = {}


## Pixel da mão de trás no quadro, ou (-1, -1) se não houver.
func ponto_tras(animacao: StringName, quadro: int) -> Vector2:
	var lista: PackedVector2Array = pontos_tras.get(animacao, PackedVector2Array())
	if quadro < 0 or quadro >= lista.size():
		return Vector2(-1, -1)
	return lista[quadro]
