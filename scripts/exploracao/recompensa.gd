class_name Recompensa
extends Node
## Itens e moedas dados uma única vez ao interagir com um [Interagivel]
## (baú, corpo caído, alguém que entrega algo). Depois de pega, a
## interação some e o desenho muda (baú aberto) ou escurece; isso fica
## guardado no Inventario, então voltar à cena não enche o baú de novo.
## Se os itens não couberem na bolsa, nada é entregue.

signal coletada

## Interagível que entrega a recompensa.
@export var interagivel: Interagivel
## Desenho que muda depois de pego (opcional): troca para
## [member textura_vazio] se houver, senão escurece.
@export var visual: CanvasItem
## Desenho depois de pego, por exemplo o baú aberto (opcional).
@export var textura_vazio: Texture2D
## id do item -> quantidade.
@export var itens: Dictionary[String, int] = {}
@export var moedas := 0
## Id único desta recompensa no jogo. Vazio = cena + caminho do nó.
@export var id_coleta := ""

const COR_VAZIO := Color(0.55, 0.55, 0.6)


func _ready() -> void:
	if id_coleta.is_empty():
		id_coleta = _id_automatico()
	if Inventario.ja_coletado(id_coleta):
		_esvaziar()
	elif interagivel:
		interagivel.interagido.connect(entregar)


func entregar() -> void:
	if Inventario.ja_coletado(id_coleta):
		return
	# Bolsa cheia: nada sai daqui e dá para voltar depois.
	if not Inventario.cabem(itens):
		Inventario.bolsa_cheia.emit()
		return
	Inventario.marcar_coletado(id_coleta)
	for id: String in itens:
		Inventario.adicionar(id, itens[id])
	Inventario.ganhar_dinheiro(moedas)
	coletada.emit()
	_esvaziar()


func _esvaziar() -> void:
	if visual is Sprite2D and textura_vazio:
		(visual as Sprite2D).texture = textura_vazio
	elif visual:
		visual.modulate = COR_VAZIO
	if is_instance_valid(interagivel):
		interagivel.queue_free()
		interagivel = null


func _id_automatico() -> String:
	var cena := owner if owner else get_tree().current_scene
	if cena == null:
		return str(get_path())
	return "%s:%s" % [cena.scene_file_path, cena.get_path_to(self)]
