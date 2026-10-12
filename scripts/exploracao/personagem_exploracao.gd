class_name PersonagemExploracao
extends CharacterBody2D
## Personagem da exploração.
## Toque ou clique: anda até o ponto, desviando dos obstáculos; segurar e
## arrastar atualiza o destino. Mouse e toque passam pelo mesmo caminho (o
## projeto emula toque com o mouse).
## Teclado (PC): WASD ou setas para andar, Shift para correr, Espaço para pular.

signal destino_definido(destino: Vector2)
signal chegou

@export var velocidade := 240.0
## Quanto mais rápido fica ao correr.
@export var multiplicador_corrida := 1.75
@export var altura_pulo := 40.0
@export var duracao_pulo := 0.45

var andando := false
var pulando := false

var _tempo_pulo := 0.0

@onready var agente: NavigationAgent2D = $Agente
@onready var corpo: Node2D = $Corpo
@onready var sombra: Node2D = $Sombra


func _unhandled_input(event: InputEvent) -> void:
	var toque: bool = event is InputEventScreenTouch and event.pressed
	if toque or event is InputEventScreenDrag:
		ir_para(tela_para_mundo(event.position))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pular"):
		pular()
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


## Pulo só visual: o corpo sobe e desce e a sombra diminui. Não passa por cima
## de obstáculos.
func pular() -> void:
	if pulando:
		return
	pulando = true
	_tempo_pulo = 0.0


## Converte a direção das teclas (cima = para cima na tela) para o chão
## isométrico, onde a distância vertical na tela vale metade.
static func direcao_isometrica(direcao_teclas: Vector2) -> Vector2:
	return Vector2(direcao_teclas.x, direcao_teclas.y * 0.5)


func _physics_process(delta: float) -> void:
	_atualizar_pulo(delta)
	var rapidez := velocidade
	if Input.is_action_pressed("correr"):
		rapidez *= multiplicador_corrida

	var teclas := Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
	if teclas != Vector2.ZERO:
		if andando:
			andando = false
			chegou.emit()
		velocity = direcao_isometrica(teclas) * rapidez
		move_and_slide()
		return

	if not andando:
		velocity = Vector2.ZERO
		return
	if agente.is_navigation_finished():
		andando = false
		velocity = Vector2.ZERO
		chegou.emit()
		return
	velocity = global_position.direction_to(agente.get_next_path_position()) * rapidez
	move_and_slide()


func _atualizar_pulo(delta: float) -> void:
	if not pulando:
		return
	_tempo_pulo += delta
	var t := clampf(_tempo_pulo / duracao_pulo, 0.0, 1.0)
	var altura := sin(t * PI) * altura_pulo
	corpo.position.y = -altura
	sombra.scale = Vector2.ONE * (1.0 - 0.4 * altura / altura_pulo)
	if t >= 1.0:
		pulando = false
		corpo.position.y = 0.0
		sombra.scale = Vector2.ONE
