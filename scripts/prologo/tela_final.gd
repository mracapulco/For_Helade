class_name TelaFinal
extends CanvasLayer
## Fim do prólogo: as frases aparecem uma por vez, como sussurros, e depois o
## título do jogo.

@export var linhas: Array[Label] = []
@export var titulo: Label


func _ready() -> void:
	for linha in linhas:
		linha.modulate.a = 0.0
	titulo.modulate.a = 0.0


## `escala` encurta ou alonga todos os tempos (os testes usam valores pequenos).
func mostrar(frases: Array[String], escala := 1.0) -> void:
	visible = true
	var tween := create_tween()
	for i in mini(frases.size(), linhas.size()):
		linhas[i].text = frases[i]
		tween.tween_property(linhas[i], "modulate:a", 1.0, 1.5 * escala)
		tween.tween_interval(1.0 * escala)
	tween.tween_interval(2.5 * escala)
	tween.set_parallel()
	for linha in linhas:
		tween.tween_property(linha, "modulate:a", 0.0, 1.5 * escala)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void: titulo.text = tr("JOGO_TITULO"))
	tween.tween_property(titulo, "modulate:a", 1.0, 2.0 * escala)
	await tween.finished
