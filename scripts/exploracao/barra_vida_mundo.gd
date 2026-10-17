class_name BarraVidaMundo
extends Node2D
## Barrinha de vida acima de um inimigo. Aparece quando ele já levou dano.

@export var vida: Vida
@export var largura := 20.0
@export var altura := 3.0

const COR_FUNDO := Color(0.0196, 0.0471, 0.0784, 0.85)   # Noite
const COR_VIDA := Color(0.71, 0.22, 0.23)                 # vermelho das poções de cura
const COR_BORDA := Color(0.7255, 0.5216, 0.2627)          # Dourado


func _ready() -> void:
	z_index = 10
	if vida:
		vida.mudou.connect(func(_a: int, _m: int) -> void: _atualizar())
	_atualizar()


func _atualizar() -> void:
	visible = vida != null and not vida.morto() and vida.atual < vida.maxima_total()
	queue_redraw()


func _draw() -> void:
	if vida == null:
		return
	var canto := Vector2(-largura / 2.0, 0.0)
	draw_rect(Rect2(canto - Vector2.ONE, Vector2(largura, altura) + Vector2(2, 2)), COR_BORDA)
	draw_rect(Rect2(canto, Vector2(largura, altura)), COR_FUNDO)
	draw_rect(Rect2(canto, Vector2(roundf(largura * vida.fracao()), altura)), COR_VIDA)
