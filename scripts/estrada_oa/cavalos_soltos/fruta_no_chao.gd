class_name FrutaNoChao
extends Node2D
## Fruta jogada por Nicholas ([FrutaNaMao]): voa num arco curto, cai no chão e
## fica ali até alguém pegá-la de volta (E, ou tocar nela) ou um cavalo guloso
## vir comê-la ([Cavalo]).

## Frutas que já caíram no chão (os cavalos procuram por este grupo).
const GRUPO := &"frutas_no_chao"
const TEXTURA := preload("res://assets/art/placeholders/estrada_oa/cavalos_soltos/fruta_no_chao.png")
const ID_FRUTA := "fruta"
const RAIO_TOQUE := 20.0

## Já está no chão (em voo ninguém pega nem come).
var pousada := false

var visual: Sprite2D
var interagivel: Interagivel


func _init() -> void:
	visual = Sprite2D.new()
	visual.name = "Visual"
	visual.texture = TEXTURA
	visual.offset = Vector2(0, -3)
	add_child(visual)
	interagivel = Interagivel.new()
	interagivel.name = "Interagivel"
	interagivel.alcance = 32.0
	var toque := CollisionShape2D.new()
	toque.name = "AreaDeToque"
	var forma := CircleShape2D.new()
	forma.radius = RAIO_TOQUE
	toque.shape = forma
	interagivel.add_child(toque)
	add_child(interagivel)


func _ready() -> void:
	interagivel.interagido.connect(pegar)
	if pousada:
		add_to_group(GRUPO)
	else:
		_ativar(false)


## Voa até [param destino] (posição global) num arco; ao cair, fica pegável.
func voar(destino: Vector2, tempo: float, altura: float) -> Tween:
	var inicio := global_position
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		global_position = inicio.lerp(destino, t)
		visual.position.y = -sin(t * PI) * altura, 0.0, 1.0, maxf(tempo, 0.01))
	tween.tween_callback(pousar)
	return tween


func pousar() -> void:
	pousada = true
	visual.position = Vector2.ZERO
	add_to_group(GRUPO)
	_ativar(true)


## Nicholas pega a fruta de volta (se couber na bolsa).
func pegar() -> void:
	if not pousada:
		return
	if not Inventario.cabe(ID_FRUTA):
		Inventario.bolsa_cheia.emit()
		return
	Inventario.adicionar(ID_FRUTA)
	sumir()


## Comida por um cavalo, ou pega: sai do chão.
func sumir() -> void:
	pousada = false
	remove_from_group(GRUPO)
	_ativar(false)
	queue_free()


func _ativar(ativa: bool) -> void:
	if ativa:
		interagivel.add_to_group(Interagivel.GRUPO_INTERAGIVEIS)
		interagivel.collision_layer = Interagivel.CAMADA_INTERAGIVEIS
	else:
		interagivel.remove_from_group(Interagivel.GRUPO_INTERAGIVEIS)
		interagivel.collision_layer = 0
	interagivel.set_process(ativa)
