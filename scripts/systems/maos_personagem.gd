class_name MaosPersonagem
extends Resource
## Onde fica a mão da frente do personagem em cada quadro de cada animação,
## para desenhar o item equipado (a espada) na mão dele.
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
