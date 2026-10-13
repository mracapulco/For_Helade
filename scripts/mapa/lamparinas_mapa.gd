class_name LamparinasMapa
extends Node2D
## Postes com lamparina ao longo das estradas abertas do mapa. De dia são só
## postes; à noite acendem, com a chama tremendo.

const INTERVALO := 34.0
## Distância mínima de um lugar do mapa (para não cobrir o ponto).
const FOLGA := 16.0
const AFASTAMENTO := 6.0
const COR_POSTE := Color(0.18, 0.15, 0.13)
const COR_CHAMA := Color(0.949, 0.651, 0.353) # Vela
const COR_LUZ := Color(0.925, 0.741, 0.459) # Dourado claro

## 0 = dia (apagadas), 1 = noite (acesas).
var acesas := 0.0:
	set(valor):
		acesas = valor
		queue_redraw()
## Cada lamparina: [posição, ids das duas pontas da estrada].
var _postes: Array = []
var _liberados: Dictionary = {}
var _tempo := 0.0


func preparar(grafo: GrafoMapa, liberados: Dictionary) -> void:
	_liberados = liberados
	_postes.clear()
	for par: Array in grafo.ligacoes():
		if par[2]: # por mar: sem postes
			continue
		var a := grafo.local(par[0]).posicao
		var b := grafo.local(par[1]).posicao
		var lado := (b - a).orthogonal().normalized() * AFASTAMENTO
		var comprimento := a.distance_to(b)
		var t := FOLGA
		while t <= comprimento - FOLGA:
			_postes.append([a.lerp(b, t / comprimento) + lado, par[0], par[1]])
			t += INTERVALO
	queue_redraw()


## Postes nas estradas já abertas.
func visiveis() -> Array[Vector2]:
	var lista: Array[Vector2] = []
	for poste: Array in _postes:
		if _liberados.has(poste[1]) and _liberados.has(poste[2]):
			lista.append(poste[0])
	return lista


func _process(delta: float) -> void:
	if acesas > 0.0:
		_tempo += delta
		queue_redraw()


func _draw() -> void:
	var i := 0
	for p in visiveis():
		i += 1
		draw_rect(Rect2(p + Vector2(-0.5, -6), Vector2(1, 6)), COR_POSTE)
		draw_rect(Rect2(p + Vector2(-1.5, -8), Vector2(3, 2)), COR_POSTE)
		if acesas <= 0.0:
			continue
		var tremor := 0.85 + 0.15 * sin(_tempo * 9.0 + i * 1.7) * sin(_tempo * 3.3 + i)
		draw_circle(p + Vector2(0, -7), 9.0 * tremor, Color(COR_LUZ, 0.10 * acesas))
		draw_circle(p + Vector2(0, -7), 5.0 * tremor, Color(COR_LUZ, 0.22 * acesas))
		draw_rect(Rect2(p + Vector2(-0.5, -8), Vector2(1, 2)), Color(COR_CHAMA, acesas))
