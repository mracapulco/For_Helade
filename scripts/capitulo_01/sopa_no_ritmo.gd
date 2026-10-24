class_name SopaNoRitmo
extends Node2D
## A sopa do restaurante como ação (Capítulo 01, livro l. ~496: "Mexeu a sopa
## com a colher, soprou algumas vezes e levou uma pequena porção à boca...
## Empurrou a tigela de volta para Ophelia"). Em cima da tigela, um anel
## fecha sobre um círculo dourado; apertar a tecla de interação (ou tocar a
## tela) quando os dois se encontram faz o passo da vez. Errar o tempo não
## pune: o anel só recomeça. Cinco passos: mexer, soprar, soprar, provar e
## devolver a tigela; o vapor diminui a cada um.
## Com [member escala_tempo] 0 (testes), termina na hora.

signal terminou

const SFX := "res://assets/audio/sfx/capitulo_01/"
const BARRAMENTO := &"Efeitos"
## Texto da vez (i18n/strings.csv) e som de cada passo.
const PASSOS := [["SOPA_MEXER", "colher"], ["SOPA_SOPRAR", "soprar"], ["SOPA_SOPRAR", "soprar"],
	["SOPA_PROVAR", "colher"], ["SOPA_DEVOLVER", "tigela"]]
## O anel fecha de RAIO_INICIAL até 0 em CICLO segundos.
const RAIO_INICIAL := 30.0
const CICLO := 1.1
## Raio do círculo dourado e a folga (pixels) para acertar.
const ALVO := 9.0
const FOLGA := 4.5
## Pausa depois de um acerto ou erro, antes do anel voltar.
const PAUSA := 0.3
const COR_ALVO := Color(0.95, 0.78, 0.35)
const COR_ANEL := Color(1, 1, 1, 0.9)
const COR_ERRO := Color(0.85, 0.3, 0.25)
const COR_LOUCA := Color(0.93, 0.92, 0.88)
const COR_SOPA := Color(0.78, 0.5, 0.25)

var escala_tempo := 1.0
## Quantos passos já foram feitos.
var passo := 0
## Raio do anel agora (0 = esperando a pausa).
var raio := RAIO_INICIAL

var _pausa := 0.0
var _cor_anel := COR_ANEL
var _texto: Label
var _dica: Label
var _sons := {}
var _rodando := false


func _ready() -> void:
	z_index = 5
	for nome in ["colher", "soprar", "tigela", "fora_do_ritmo"]:
		var tocador := AudioStreamPlayer.new()
		tocador.stream = load(SFX + nome + ".wav")
		tocador.bus = BARRAMENTO
		add_child(tocador)
		_sons[nome] = tocador
	_texto = Label.new()
	_texto.name = "Texto"
	_texto.position = Vector2(-60, -RAIO_INICIAL - 26)
	_texto.size = Vector2(120, 20)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.add_theme_font_size_override("font_size", 14)
	_texto.add_theme_constant_override("outline_size", 4)
	_texto.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	add_child(_texto)
	_dica = _texto.duplicate() as Label
	_dica.name = "Dica"
	_dica.position = Vector2(-110, 14)
	_dica.size = Vector2(220, 20)
	_dica.add_theme_font_size_override("font_size", 11)
	_dica.text = tr("SOPA_DICA")
	add_child(_dica)


## Começa e espera os cinco passos.
func comecar() -> void:
	passo = 0
	if escala_tempo <= 0.0:
		passo = PASSOS.size()
		return
	_rodando = true
	_recomecar_anel()
	await terminou


func _process(delta: float) -> void:
	if not _rodando:
		return
	if _pausa > 0.0:
		_pausa -= delta
		if _pausa <= 0.0:
			_recomecar_anel()
	else:
		raio -= RAIO_INICIAL / CICLO * delta
		if raio < 0.0:
			raio = RAIO_INICIAL
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _rodando:
		return
	var toque: bool = event is InputEventScreenTouch and event.pressed
	if event.is_action_pressed("interagir") or toque:
		get_viewport().set_input_as_handled()
		tentar()


## Aperta agora: acerta se o anel está sobre o círculo dourado.
func tentar() -> bool:
	if not _rodando or _pausa > 0.0:
		return false
	if absf(raio - ALVO) > FOLGA:
		_sons["fora_do_ritmo"].play()
		_cor_anel = COR_ERRO
		_pausa = PAUSA
		return false
	_sons[PASSOS[passo][1]].play()
	passo += 1
	_dica.visible = false
	_cor_anel = COR_ALVO
	_pausa = PAUSA
	if passo >= PASSOS.size():
		_rodando = false
		_texto.text = ""
		queue_redraw()
		terminou.emit()
	return true


func _recomecar_anel() -> void:
	raio = RAIO_INICIAL
	_cor_anel = COR_ANEL
	_texto.text = tr(PASSOS[passo][0]) if passo < PASSOS.size() else ""


func _draw() -> void:
	# A tigela (louça) com a sopa, e o vapor que ainda falta esfriar.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 8.0, COR_LOUCA)
	draw_circle(Vector2.ZERO, 6.0, COR_SOPA)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var vapor := PASSOS.size() - passo
	for i in mini(vapor, 3):
		var x := -4.0 + i * 4.0
		draw_polyline(PackedVector2Array([Vector2(x, -3), Vector2(x - 2, -8), Vector2(x + 1, -13), Vector2(x - 1, -18)]),
			Color(1, 1, 1, 0.25 + 0.1 * vapor), 1.0)
	if not _rodando:
		return
	var centro := Vector2(0, -10)
	draw_arc(centro, ALVO, 0, TAU, 32, COR_ALVO, 2.0)
	if _pausa <= 0.0 or _cor_anel != COR_ANEL:
		draw_arc(centro, maxf(raio, 1.0), 0, TAU, 40, _cor_anel, 1.5)
