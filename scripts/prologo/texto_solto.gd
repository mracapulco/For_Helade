class_name TextoSolto
extends Label
## Frases do livro que aparecem e somem sozinhas na tela, sem travar o jogador.

## Tempo para aparecer e para sumir.
@export var tempo_fade := 0.5
## Tempo mínimo de cada frase na tela.
@export var tempo_minimo := 1.0
## Tempo extra por letra, para frases maiores ficarem mais tempo.
@export var tempo_por_letra := 0.03

var _geracao := 0


func _ready() -> void:
	modulate.a = 0.0


## Mostra as frases uma depois da outra. Uma chamada nova interrompe a anterior.
func mostrar(frases: Array[String]) -> void:
	_geracao += 1
	var minha := _geracao
	for frase in frases:
		text = frase
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 1.0, tempo_fade)
		tween.tween_interval(tempo_minimo + frase.length() * tempo_por_letra)
		tween.tween_property(self, "modulate:a", 0.0, tempo_fade)
		await tween.finished
		if minha != _geracao:
			return
