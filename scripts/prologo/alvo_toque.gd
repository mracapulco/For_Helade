class_name AlvoToque
extends Area3D
## Brilho dourado que o jogador toca (ou clica) para levar a câmera até o `destino`.
## Só aparece e só responde quando a câmera está no PontoDeVista pai.

signal tocado(alvo: AlvoToque)

@export var destino: PontoDeVista
## Velocidade da pulsação do brilho, em ciclos por segundo.
@export var pulsos_por_segundo := 0.8

var ativo := false:
	set = definir_ativo

var _tempo := 0.0


func _ready() -> void:
	definir_ativo(ativo)


func _process(delta: float) -> void:
	if not ativo:
		return
	_tempo += delta
	var escala := 1.0 + 0.15 * sin(_tempo * TAU * pulsos_por_segundo)
	for filho in get_children():
		if filho is MeshInstance3D:
			filho.scale = Vector3.ONE * escala


func _input_event(_camera: Camera3D, evento: InputEvent, _posicao: Vector3, _normal: Vector3, _forma: int) -> void:
	# O toque na tela chega como clique do mouse (emulação padrão do Godot).
	if not ativo:
		return
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		tocado.emit(self)


func definir_ativo(valor: bool) -> void:
	ativo = valor
	visible = valor
	input_ray_pickable = valor
	_tempo = 0.0
