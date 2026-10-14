class_name ReacaoAoGolpe
extends Node2D
## Faz um personagem ou figurante reagir quando leva um golpe: pisca em
## vermelho e claro, é empurrado um pouco para trás e treme. Só a reação
## visual; vida e dano entram com o combate.
## Fica como filho do corpo do personagem (na origem dele, nos pés).

const GRUPO := &"atingiveis"

signal atingido(direcao: Vector2)

## Desenho que pisca e é empurrado (normalmente o "Visual" ao lado).
@export var visual: Node2D
## Quanto o desenho recua, em pixels.
@export var recuo := 4.0
@export var duracao := 0.3
@export var cor_do_golpe := Color(1.0, 0.35, 0.3)

var _tween: Tween
var _posicao_original := Vector2.ZERO
var _cor_original := Color.WHITE


func _ready() -> void:
	add_to_group(GRUPO)
	if visual:
		_posicao_original = visual.position
		_cor_original = visual.modulate


## Levou um golpe vindo na [param direcao] (de quem bateu para quem apanhou).
func receber_golpe(direcao: Vector2) -> void:
	atingido.emit(direcao)
	if visual == null:
		return
	if _tween:
		_tween.kill()
	visual.position = _posicao_original
	visual.modulate = _cor_original
	var empurrao := direcao.normalized() * recuo
	var passo := duracao / 6.0
	_tween = create_tween().set_parallel(false)
	_tween.tween_property(visual, "position", _posicao_original + empurrao, passo)
	_tween.tween_property(visual, "position", _posicao_original + empurrao + Vector2(0, -1), passo)
	_tween.tween_property(visual, "position", _posicao_original + empurrao * 0.5 + Vector2(1, 0), passo)
	_tween.tween_property(visual, "position", _posicao_original + empurrao * 0.5 - Vector2(1, 0), passo)
	_tween.tween_property(visual, "position", _posicao_original, passo * 2.0)
	var cores := create_tween()
	_tween.finished.connect(func() -> void: visual.modulate = _cor_original)
	cores.tween_property(visual, "modulate", cor_do_golpe, 0.0)
	cores.tween_interval(passo)
	cores.tween_property(visual, "modulate", Color(1.6, 1.6, 1.6), 0.0)
	cores.tween_interval(passo)
	cores.tween_property(visual, "modulate", cor_do_golpe, 0.0)
	cores.tween_interval(passo)
	cores.tween_property(visual, "modulate", _cor_original, passo * 2.0)


## Está no meio da reação.
func reagindo() -> bool:
	return _tween != null and _tween.is_running()
