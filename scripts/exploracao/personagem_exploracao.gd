class_name PersonagemExploracao
extends CharacterBody2D
## Personagem da exploração: anda até onde o jogador toca ou clica, desviando
## dos obstáculos. Segurar e arrastar atualiza o destino. Mouse e toque passam
## pelo mesmo caminho (o projeto emula toque com o mouse).

signal destino_definido(destino: Vector2)
signal chegou

@export var velocidade := 240.0

var andando := false

@onready var agente: NavigationAgent2D = $Agente


func _unhandled_input(event: InputEvent) -> void:
	var toque: bool = event is InputEventScreenTouch and event.pressed
	if toque or event is InputEventScreenDrag:
		ir_para(tela_para_mundo(event.position))
		get_viewport().set_input_as_handled()


## Converte uma posição na tela para a posição no mundo, levando a câmera em conta.
func tela_para_mundo(posicao_tela: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * posicao_tela


## Leva o personagem ao ponto andável mais próximo de `destino`.
func ir_para(destino: Vector2) -> void:
	var mapa := agente.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(mapa) > 0:
		destino = NavigationServer2D.map_get_closest_point(mapa, destino)
	agente.target_position = destino
	andando = true
	destino_definido.emit(destino)


func _physics_process(_delta: float) -> void:
	if not andando:
		return
	if agente.is_navigation_finished():
		andando = false
		velocity = Vector2.ZERO
		chegou.emit()
		return
	velocity = global_position.direction_to(agente.get_next_path_position()) * velocidade
	move_and_slide()
