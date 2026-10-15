class_name Inimigo
extends CharacterBody2D
## Inimigo provisório da exploração: fica parado até ver o jogador, vai atrás
## dele desviando dos obstáculos e, quando chega perto, avisa (pisca e se
## ergue) e golpeia. Usa as mesmas regras do jogador: itens do Inventario
## como equipamento (Balanceamento), Vida e ReacaoAoGolpe.
## Quando o jogador foge para longe, volta para o lugar onde estava.
## Ao morrer some aos poucos e deixa moedas.

signal golpeou
signal morreu

enum Estado { PARADO, PERSEGUINDO, PREPARANDO, DESCANSANDO, VOLTANDO, MORTO }

## Ids de itens (data/itens/) que ele usa: arma, escudo, armadura, elmo.
@export var equipamento: Array[String] = []
## Velocidade de andar sem equipamento.
@export var velocidade := 60.0
## Começa a perseguir quando o jogador chega a esta distância...
@export var raio_visao := 150.0
## ...e desiste quando ele passa desta.
@export var raio_desistir := 260.0
## Distância do golpe, a partir dos pés.
@export var alcance := 36.0
## Tempo do aviso antes do golpe (dá para fugir ou bater antes).
@export var preparo := 0.45
## Descanso depois de cada golpe.
@export var intervalo := 1.0
## Moedas que deixa ao morrer.
@export var moedas := 0

@export var visual: Node2D
@export var vida: Vida
@export var reacao: ReacaoAoGolpe

var estado := Estado.PARADO
var alvo: PersonagemExploracao

var _itens: Array[Item] = []
var _atributos := {}
var _tempo := 0.0
var _tempo_caminho := 0.0
var _posicao_visual := Vector2.ZERO
## Onde ele fica de guarda.
var _posto := Vector2.ZERO

@onready var agente: NavigationAgent2D = get_node_or_null("Agente")


func _ready() -> void:
	for id in equipamento:
		var item := Inventario.item(id)
		if item:
			_itens.append(item)
		else:
			push_error("Inimigo: item desconhecido '%s'." % id)
	_atributos = Balanceamento.somar(_itens)
	if vida:
		vida.defesa += int(_atributos.defesa)
		vida.morreu.connect(_morrer)
	if visual:
		_posicao_visual = visual.position
	_posto = global_position


## Ataque, defesa e velocidade do equipamento (com o ataque base).
func atributos() -> Dictionary:
	return _atributos


func velocidade_andando() -> float:
	return velocidade * Balanceamento.multiplicador_velocidade(int(_atributos.velocidade))


func _physics_process(delta: float) -> void:
	if estado == Estado.MORTO:
		return
	if alvo == null or not is_instance_valid(alvo):
		alvo = _procurar_jogador()
		if alvo == null:
			return
	var distancia := global_position.distance_to(alvo.global_position)
	if alvo.em_dialogo:
		_parar()
		return
	match estado:
		Estado.PARADO:
			if distancia <= raio_visao:
				estado = Estado.PERSEGUINDO
		Estado.VOLTANDO:
			if distancia <= raio_visao:
				estado = Estado.PERSEGUINDO
			elif global_position.distance_to(_posto) <= 4.0:
				_parar()
			else:
				_andar_ate(_posto, delta)
		Estado.PERSEGUINDO:
			if distancia > raio_desistir:
				_desistir()
			elif distancia <= alcance:
				_preparar()
			else:
				_andar_ate(alvo.global_position, delta)
		Estado.PREPARANDO:
			velocity = Vector2.ZERO
			_tempo += delta
			if _tempo >= preparo:
				_golpear()
		Estado.DESCANSANDO:
			velocity = Vector2.ZERO
			_tempo += delta
			if _tempo >= intervalo:
				estado = Estado.PERSEGUINDO
	_virar()


## Olha para onde anda ou, parado no combate, para o jogador.
func _virar() -> void:
	if not visual is Sprite2D:
		return
	var desenho := visual as Sprite2D
	if absf(velocity.x) > 1.0:
		desenho.flip_h = velocity.x < 0.0
	elif estado == Estado.PREPARANDO or estado == Estado.DESCANSANDO:
		desenho.flip_h = alvo.global_position.x < global_position.x


func _procurar_jogador() -> PersonagemExploracao:
	for no in get_tree().get_nodes_in_group(Interagivel.GRUPO_JOGADOR):
		if no is PersonagemExploracao:
			return no
	return null


func _parar() -> void:
	estado = Estado.PARADO
	velocity = Vector2.ZERO


func _desistir() -> void:
	estado = Estado.VOLTANDO
	_tempo_caminho = 0.0


func _andar_ate(destino: Vector2, delta: float) -> void:
	if agente:
		_tempo_caminho -= delta
		if _tempo_caminho <= 0.0 or agente.target_position.distance_to(destino) > 24.0:
			agente.target_position = destino
			_tempo_caminho = 0.25
		if not agente.is_navigation_finished():
			destino = agente.get_next_path_position()
	velocity = global_position.direction_to(destino) * velocidade_andando()
	move_and_slide()


func _preparar() -> void:
	estado = Estado.PREPARANDO
	_tempo = 0.0
	velocity = Vector2.ZERO
	if visual:
		# Aviso: clareia e se ergue um pouco antes de bater.
		var aviso := create_tween().set_parallel()
		aviso.tween_property(visual, "modulate", Color(1.5, 1.4, 1.2), preparo * 0.5)
		aviso.tween_property(visual, "position", _posicao_visual + Vector2(0, -3), preparo * 0.8)


func _golpear() -> void:
	estado = Estado.DESCANSANDO
	_tempo = 0.0
	golpeou.emit()
	var direcao := global_position.direction_to(alvo.global_position)
	if visual:
		var bote := create_tween()
		bote.tween_property(visual, "modulate", Color.WHITE, 0.0)
		bote.tween_property(visual, "position", _posicao_visual + direcao * 5.0, 0.06)
		bote.tween_property(visual, "position", _posicao_visual, 0.15)
	if global_position.distance_to(alvo.global_position) <= alcance * 1.2:
		var reacao_alvo := alvo.get_node_or_null("ReacaoAoGolpe") as ReacaoAoGolpe
		if reacao_alvo:
			reacao_alvo.receber_golpe(direcao, int(_atributos.ataque))


func _morrer() -> void:
	estado = Estado.MORTO
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	if reacao:
		reacao.remove_from_group(ReacaoAoGolpe.GRUPO)
	if moedas > 0:
		Inventario.ganhar_dinheiro(moedas)
	morreu.emit()
	var sumir := create_tween()
	sumir.tween_interval(0.35)
	sumir.tween_property(self, "modulate:a", 0.0, 0.5)
	sumir.tween_callback(queue_free)
