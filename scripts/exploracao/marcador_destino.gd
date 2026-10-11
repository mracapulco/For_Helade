class_name MarcadorDestino
extends Node2D
## Anel provisório que mostra para onde o personagem está indo.

@export var personagem: PersonagemExploracao
@export var cor := Color(1.0, 0.85, 0.3, 0.9)


func _ready() -> void:
	visible = false
	if personagem:
		personagem.destino_definido.connect(_mostrar)
		personagem.chegou.connect(hide)


func _mostrar(destino: Vector2) -> void:
	global_position = destino
	show()


func _draw() -> void:
	var pontos := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pontos.append(Vector2(cos(a) * 22.0, sin(a) * 11.0))
	draw_polyline(pontos, cor, 3.0, true)
