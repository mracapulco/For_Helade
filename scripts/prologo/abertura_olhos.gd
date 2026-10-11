class_name AberturaOlhos
extends CanvasLayer
## Pálpebras de Nicholas: começa com a tela fechada e abre como quem acorda
## no meio da noite (abre um pouco, fecha, abre de vez).

signal terminou

## Pálpebras de cima e de baixo; cada uma cobre metade da tela quando fechada.
@export var palpebra_cima: ColorRect
@export var palpebra_baixo: ColorRect
## Tempo de tela totalmente escura antes de começar a abrir.
@export var espera_inicial := 0.8


func _ready() -> void:
	_posicionar(0.0)


func abrir() -> void:
	visible = true
	_posicionar(0.0)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(espera_inicial)
	tween.tween_method(_posicionar, 0.0, 0.35, 0.9)
	tween.tween_method(_posicionar, 0.35, 0.05, 0.35)
	tween.tween_interval(0.25)
	tween.tween_method(_posicionar, 0.05, 1.0, 1.3)
	await tween.finished
	visible = false
	terminou.emit()


## 0 = olhos fechados, 1 = totalmente abertos.
func _posicionar(abertura: float) -> void:
	var metade := get_viewport().get_visible_rect().size.y / 2.0
	var deslocamento := metade * abertura
	palpebra_cima.offset_bottom = metade - deslocamento
	palpebra_cima.offset_top = -deslocamento
	palpebra_baixo.offset_top = -metade + deslocamento
	palpebra_baixo.offset_bottom = deslocamento
