class_name AvisoNoChao
extends Node2D
## Aviso de golpe desenhado no chão (Rafael, 23/10; P3): um leque que enche
## de [member progresso] 0 a 1 até o golpe sair. Mostra exatamente a área que
## o golpe vai pegar, para o jogador sair dela ou esquivar.
## As contas são feitas "no chão": no isométrico, meia unidade na vertical da
## tela vale uma unidade do chão, então a área parece achatada na tela.

## Raio do leque, em pixels do chão.
@export var raio := 72.0
## Abertura do leque, em graus.
@export var arco := 120.0
## Para onde o leque aponta, no chão.
@export var direcao := Vector2.RIGHT
## Quanto do aviso já encheu (1 = o golpe sai agora).
@export_range(0.0, 1.0) var progresso := 0.0:
	set(valor):
		progresso = valor
		queue_redraw()
## Cor do leque.
@export var cor := COR

const COR := Color(0.85, 0.32, 0.22)
## O golpe de verdade visto no Tic. Tac. (P4): dourado, como o anel dos olhos.
const COR_DOURADA := Color(0.93, 0.74, 0.36)
const PONTOS := 20


func _ready() -> void:
	# Embaixo dos personagens, em cima do chão.
	z_index = -1


## Da tela para o chão (desfaz o achatamento do isométrico).
static func para_o_chao(na_tela: Vector2) -> Vector2:
	return Vector2(na_tela.x, na_tela.y * 2.0)


## Do chão para a tela.
static func para_a_tela(no_chao: Vector2) -> Vector2:
	return Vector2(no_chao.x, no_chao.y * 0.5)


## O golpe de quem está em [param origem] (tela), num leque [param arco] de
## [param raio] (chão) para [param direcao] (chão), pega quem está em
## [param alvo] (tela)?
static func atinge(origem: Vector2, direcao_chao: Vector2, alvo: Vector2, raio_chao: float, arco_graus: float) -> bool:
	var ate := para_o_chao(alvo - origem)
	if ate.length() > raio_chao:
		return false
	if ate.length() < 1.0:
		return true
	return direcao_chao.normalized().dot(ate.normalized()) >= cos(deg_to_rad(arco_graus / 2.0)) - 0.0001


## Pontos do leque na tela, com raio [param r] (chão).
func leque(r: float) -> PackedVector2Array:
	var pontos := PackedVector2Array([Vector2.ZERO])
	var inicio := direcao.angle() - deg_to_rad(arco / 2.0)
	for i in PONTOS + 1:
		var angulo := inicio + deg_to_rad(arco) * i / PONTOS
		pontos.append(para_a_tela(Vector2.from_angle(angulo) * r))
	return pontos


func _draw() -> void:
	var borda := leque(raio)
	draw_colored_polygon(borda, Color(cor, 0.18))
	if progresso > 0.0:
		draw_colored_polygon(leque(raio * progresso), Color(cor, 0.25 + 0.3 * progresso))
	var contorno := borda.duplicate()
	contorno.append(borda[0])
	draw_polyline(contorno, Color(cor, 0.7), 1.0)
