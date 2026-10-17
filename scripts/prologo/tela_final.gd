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
	for i in mini(frases.size(), linhas.size()):
		linhas[i].text = frases[i]
		# Os sussurros com voz: cada frase espera o coro terminar.
		var voz := Voz.tocar_texto(frases[i])
		var surgir := create_tween()
		surgir.tween_property(linhas[i], "modulate:a", 1.0, 1.5 * escala)
		surgir.tween_interval(1.0 * escala)
		await surgir.finished
		var falta := voz - 2.5 * escala
		if falta > 0.0:
			await get_tree().create_timer(falta).timeout
	var tween := create_tween()
	tween.tween_interval(2.5 * escala)
	tween.set_parallel()
	for linha in linhas:
		tween.tween_property(linha, "modulate:a", 0.0, 1.5 * escala)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void: titulo.text = tr("JOGO_TITULO"))
	tween.tween_property(titulo, "modulate:a", 1.0, 2.0 * escala)
	await tween.finished
