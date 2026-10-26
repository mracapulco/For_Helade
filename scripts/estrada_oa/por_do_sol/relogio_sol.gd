class_name RelogioSol
extends Control
## O relógio da corrida: o sol descendo no céu até beijar o mar (a linha do
## horizonte). Quando ele toca a água, [signal se_pos] avisa; a corrida
## continua, só que agora rumo a uma vista noturna.

signal se_pos

## Quanto dura a descida do sol, em segundos (calibrado pelos tempos do
## planalto: veja test_por_do_sol.gd).
@export var duracao := 62.0
## Parado até [method comecar] (a fase dá um respiro antes da largada).
var andando := false
var decorrido := 0.0

const COR_FUNDO := Color(0.0196, 0.0471, 0.0784, 0.78)
const COR_BORDA := Color(0.9255, 0.7412, 0.4588)
const CEU_TARDE := Color(0.55, 0.65, 0.85)
const CEU_POR := Color(0.95, 0.6, 0.48)
const CEU_NOITE := Color(0.08, 0.12, 0.24)
const COR_MAR := Color(0.09, 0.2, 0.32)
const COR_SOL := Color(1.0, 0.85, 0.5)
const COR_LUA := Color(0.79, 0.81, 0.85)


func _ready() -> void:
	custom_minimum_size = Vector2(220, 104)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func comecar() -> void:
	andando = true


func avancar(delta: float) -> void:
	if not andando or posto():
		return
	decorrido = minf(decorrido + delta, duracao)
	queue_redraw()
	if posto():
		se_pos.emit()


## Quanto do caminho do sol já passou, de 0 a 1.
func progresso() -> float:
	return clampf(decorrido / maxf(duracao, 0.001), 0.0, 1.0)


func restante() -> float:
	return maxf(duracao - decorrido, 0.0)


## O sol já beijou o mar.
func posto() -> bool:
	return decorrido >= duracao


## Onde o sol está no desenho: desce em curva até a linha do mar.
func posicao_do_sol() -> Vector2:
	var p := progresso()
	var horizonte := size.y - 26.0
	return Vector2(lerpf(34.0, size.x - 44.0, p), lerpf(22.0, horizonte, pow(p, 1.6)))


func _draw() -> void:
	var caixa := Rect2(Vector2.ZERO, size)
	draw_rect(caixa, COR_FUNDO)
	var horizonte := size.y - 26.0
	var ceu := Rect2(Vector2(6, 6), Vector2(size.x - 12, horizonte - 6))
	var cor_ceu := CEU_TARDE.lerp(CEU_POR, progresso())
	if posto():
		cor_ceu = CEU_NOITE
	draw_rect(ceu, cor_ceu)
	if posto():
		draw_circle(Vector2(size.x * 0.3, 26), 7.0, COR_LUA)
		draw_circle(Vector2(size.x * 0.3 + 4, 24), 6.0, CEU_NOITE)
	else:
		var sol := posicao_do_sol()
		draw_circle(sol, 10.0, COR_SOL)
	# O mar cobre a metade de baixo do sol quando ele chega à linha.
	draw_rect(Rect2(Vector2(6, horizonte), Vector2(size.x - 12, 20)), COR_MAR)
	draw_line(Vector2(6, horizonte), Vector2(size.x - 6, horizonte), COR_BORDA, 1.0)
	draw_rect(caixa, COR_BORDA, false, 2.0)
