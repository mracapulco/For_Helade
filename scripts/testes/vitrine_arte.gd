extends Node2D
## Vitrine da arte da exploração: mostra chão, bloco, personagens e objetos
## no tamanho e no zoom do jogo, para conferir uma peça nova antes de usá-la
## nas salas.
## Para testar uma arte, salve o PNG por cima do provisório (mesmo nome e
## tamanho) em assets/art/placeholders/exploracao/ e rode esta cena (F6).

const LADO := 4 # chão de LADO×LADO tiles

@onready var chao: TileMapLayer = $Chao
@onready var obstaculos: TileMapLayer = $Obstaculos


func _ready() -> void:
	for x in LADO:
		for y in LADO:
			chao.set_cell(Vector2i(x, y), 0, Vector2i((x + y) % 2, 0))
	obstaculos.set_cell(Vector2i(0, 0), 1, Vector2i.ZERO)
	obstaculos.set_cell(Vector2i(1, 0), 1, Vector2i.ZERO)
