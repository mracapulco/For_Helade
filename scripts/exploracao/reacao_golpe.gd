class_name ReacaoAoGolpe
extends Node2D
## Faz um personagem ou figurante reagir quando leva um golpe: pisca em
## vermelho e claro, é empurrado um pouco para trás e treme. Com uma
## [member vida], o golpe também tira vida e o dano sobe num número.
## Fica como filho do corpo do personagem (na origem dele, nos pés).

const GRUPO := &"atingiveis"

signal atingido(direcao: Vector2)

## Desenho que pisca e é empurrado (normalmente o "Visual" ao lado).
@export var visual: Node2D
## Quanto o desenho recua, em pixels.
@export var recuo := 4.0
@export var duracao := 0.3
@export var cor_do_golpe := Color(1.0, 0.35, 0.3)
## Vida que o golpe tira (opcional). Sem ela, só a reação visual.
@export var vida: Vida
## Altura do número de dano acima dos pés, em pixels.
@export var altura_numero := 46.0

var _tween: Tween
var _posicao_original := Vector2.ZERO
var _cor_original := Color.WHITE


func _ready() -> void:
	add_to_group(GRUPO)
	if visual:
		_posicao_original = visual.position
		_cor_original = visual.modulate


## Levou um golpe vindo na [param direcao] (de quem bateu para quem apanhou),
## com esse [param ataque] (0 = só a reação). [param empurrao] multiplica o
## [member recuo] (o terceiro golpe do combo empurra mais). Devolve o dano tirado.
func receber_golpe(direcao: Vector2, ataque: int = 0, empurrao: float = 1.0) -> int:
	atingido.emit(direcao)
	var dano := 0
	if vida and ataque > 0:
		dano = vida.receber_ataque(ataque)
		if dano > 0:
			mostrar_dano(dano)
	_reagir(direcao, empurrao)
	return dano


## Número do dano que sobe e some acima da cabeça.
func mostrar_dano(valor: int) -> Label:
	var numero := Label.new()
	numero.name = "Dano"
	numero.text = "-%d" % valor
	numero.add_theme_font_size_override("font_size", 10)
	numero.add_theme_color_override("font_color", Color(0.9255, 0.7412, 0.4588))
	numero.add_theme_color_override("font_outline_color", Color(0.0196, 0.0471, 0.0784))
	numero.add_theme_constant_override("outline_size", 3)
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.size = Vector2(32, 14)
	numero.position = Vector2(-16, -altura_numero)
	numero.z_index = 10
	add_child(numero)
	var subir := numero.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel()
	subir.tween_property(numero, "position:y", numero.position.y - 14.0, 0.6)
	subir.tween_property(numero, "modulate:a", 0.0, 0.6).set_delay(0.25)
	subir.chain().tween_callback(numero.queue_free)
	return numero


func _reagir(direcao: Vector2, forca: float = 1.0) -> void:
	if visual == null:
		return
	if _tween:
		_tween.kill()
	visual.position = _posicao_original
	visual.modulate = _cor_original
	var empurrao := direcao.normalized() * recuo * forca
	var passo := duracao / 6.0
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel(false)
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
