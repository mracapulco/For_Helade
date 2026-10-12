class_name Interagivel
extends Area2D
## Algo na exploração com que o jogador pode interagir (objeto ou personagem).
## A área de toque é maior que o desenho, pensando em dedo. Quando o jogador
## está ao alcance, um anel dourado aparece (não depende de hover).

signal interagido

const CAMADA_INTERAGIVEIS := 4 # camada 3 de física
const GRUPO_JOGADOR := &"jogador"
const GRUPO_INTERAGIVEIS := &"interagiveis"

## Chave de tradução do texto mostrado ao interagir (provisório até o passo 5).
@export var chave_texto := ""
## Distância, em pixels, a partir da qual dá para interagir.
@export var alcance := 90.0
@export var cor_destaque := Color(1.0, 0.85, 0.3, 0.9)
## Quanto tempo o texto fica na tela, em segundos.
@export var duracao_texto := 2.5

var destacado := false

var _texto: Label


func _ready() -> void:
	add_to_group(GRUPO_INTERAGIVEIS)
	collision_layer = CAMADA_INTERAGIVEIS
	collision_mask = 0
	monitoring = false
	_texto = Label.new()
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.add_theme_font_size_override("font_size", 22)
	_texto.add_theme_constant_override("outline_size", 6)
	_texto.add_theme_color_override("font_outline_color", Color.BLACK)
	_texto.size = Vector2(360, 0)
	_texto.position = Vector2(-180, -130)
	_texto.hide()
	add_child(_texto)


func _process(_delta: float) -> void:
	var jogador := get_tree().get_first_node_in_group(GRUPO_JOGADOR) as Node2D
	var perto := jogador != null and ao_alcance(jogador.global_position)
	if perto != destacado:
		destacado = perto
		queue_redraw()


func ao_alcance(posicao: Vector2) -> bool:
	return global_position.distance_to(posicao) <= alcance


func interagir() -> void:
	interagido.emit()
	if chave_texto.is_empty():
		return
	_texto.text = tr(chave_texto)
	_texto.show()
	get_tree().create_timer(duracao_texto).timeout.connect(_texto.hide)


func _draw() -> void:
	if not destacado:
		return
	var pontos := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pontos.append(Vector2(cos(a) * 40.0, sin(a) * 20.0))
	draw_polyline(pontos, cor_destaque, 4.0, true)
