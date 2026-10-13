class_name PersonagemExploracao
extends CharacterBody2D
## Personagem da exploração.
## Toque ou clique: anda até o ponto, desviando dos obstáculos; segurar e
## arrastar atualiza o destino. Mouse e toque passam pelo mesmo caminho (o
## projeto emula toque com o mouse).
## Teclado (PC): WASD ou setas para andar, Shift para correr, Espaço para pular,
## Enter para interagir com o interagível mais próximo ao alcance.
## Tocar num Interagivel: anda até ele e interage ao chegar.
## Durante uma conversa o personagem fica parado e ignora toques e teclas.

signal destino_definido(destino: Vector2)
signal chegou

@export var velocidade := 120.0
## Quanto mais rápido fica ao correr.
@export var multiplicador_corrida := 1.75
@export var altura_pulo := 20.0
@export var duracao_pulo := 0.45

var andando := false
var pulando := false
## Verdadeiro enquanto uma conversa está aberta.
var em_dialogo := false
## Interagível para onde o personagem está indo, se houver.
var alvo_interacao: Interagivel

var _tempo_pulo := 0.0

@onready var agente: NavigationAgent2D = $Agente
@onready var corpo: Node2D = $Corpo
@onready var sombra: Node2D = $Sombra


func _ready() -> void:
	add_to_group(Interagivel.GRUPO_JOGADOR)
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)


func _unhandled_input(event: InputEvent) -> void:
	if em_dialogo:
		return
	var na_tela: bool = event is InputEventScreenTouch or event is InputEventScreenDrag
	if na_tela and BotoesToque.toque_em_botao(get_tree(), event.position):
		return
	var toque: bool = event is InputEventScreenTouch and event.pressed
	if toque:
		tocar(tela_para_mundo(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		alvo_interacao = null
		ir_para(tela_para_mundo(event.position))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pular"):
		pular()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interagir"):
		var alvo := interagivel_ao_alcance()
		if alvo:
			interagir_com(alvo)
			get_viewport().set_input_as_handled()


## Converte uma posição na tela para a posição no mundo, levando a câmera em conta.
func tela_para_mundo(posicao_tela: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * posicao_tela


## O jogador tocou neste ponto do mundo: interage se for um Interagivel,
## senão anda até lá.
func tocar(posicao_mundo: Vector2) -> void:
	var alvo := interagivel_em(posicao_mundo)
	if alvo:
		interagir_com(alvo)
	else:
		alvo_interacao = null
		ir_para(posicao_mundo)


## O Interagivel cuja área de toque cobre esse ponto, ou null.
func interagivel_em(posicao_mundo: Vector2) -> Interagivel:
	var consulta := PhysicsPointQueryParameters2D.new()
	consulta.position = posicao_mundo
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	consulta.collision_mask = Interagivel.CAMADA_INTERAGIVEIS
	for resultado in get_world_2d().direct_space_state.intersect_point(consulta):
		if resultado.collider is Interagivel:
			return resultado.collider
	return null


## O interagível mais próximo que está ao alcance, ou null.
func interagivel_ao_alcance() -> Interagivel:
	var melhor: Interagivel = null
	var menor := INF
	for no in get_tree().get_nodes_in_group(Interagivel.GRUPO_INTERAGIVEIS):
		var alvo := no as Interagivel
		var distancia := global_position.distance_to(alvo.global_position)
		if alvo.ao_alcance(global_position) and distancia < menor:
			melhor = alvo
			menor = distancia
	return melhor


## Interage na hora se estiver ao alcance; senão anda até perto e interage ao chegar.
func interagir_com(alvo: Interagivel) -> void:
	if alvo.ao_alcance(global_position):
		alvo_interacao = null
		andando = false
		alvo.interagir()
		return
	alvo_interacao = alvo
	ir_para(alvo.global_position)


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


## Converte a direção das teclas para as linhas do quadriculado isométrico:
## W sobe para a esquerda, S desce para a direita, D sobe para a direita e
## A desce para a esquerda. Duas teclas juntas fazem as direções retas da
## tela (W+D para cima, S+A para baixo, W+A para a esquerda, S+D para a
## direita). O resultado tem tamanho 1, então a velocidade é a mesma em
## qualquer direção.
static func direcao_isometrica(direcao_teclas: Vector2) -> Vector2:
	var eixo_s := Vector2(2, 1).normalized()
	var eixo_d := Vector2(2, -1).normalized()
	var direcao := eixo_d * direcao_teclas.x + eixo_s * direcao_teclas.y
	return direcao.normalized()


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	em_dialogo = true
	andando = false
	alvo_interacao = null
	velocity = Vector2.ZERO
	chegou.emit()


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	# Espera um instante para o mesmo Enter ou toque que fechou a conversa
	# não abrir outra nem mandar o personagem andar.
	await get_tree().create_timer(0.2).timeout
	em_dialogo = false


func _physics_process(delta: float) -> void:
	_atualizar_pulo(delta)
	if em_dialogo:
		return
	var rapidez := velocidade
	if Input.is_action_pressed("correr"):
		rapidez *= multiplicador_corrida

	var teclas := Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
	if teclas != Vector2.ZERO:
		alvo_interacao = null
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
		if alvo_interacao and alvo_interacao.ao_alcance(global_position):
			alvo_interacao.interagir()
		alvo_interacao = null
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
