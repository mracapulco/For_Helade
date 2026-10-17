class_name CamadaEquipamento
extends AnimatedSprite2D

const AparenciaNicholas := preload("res://scripts/systems/aparencia_nicholas.gd")
## Desenha por cima do personagem a armadura ou o elmo que ele tem
## equipado (Item.visual_no_corpo). Copia do desenho do personagem a
## animação, o quadro, o espelho e o deslocamento, então acompanha
## parado, andando, correndo, pulando, interagindo e golpeando.
## Fica como filho do desenho animado (Personagem/Corpo/Visual).

## Id do personagem no Inventario.
@export var personagem := "nicholas"
## Encaixe do Inventario mostrado: ARMADURA ou ELMO.
@export var encaixe: Item.Encaixe = Item.Encaixe.ARMADURA
## O desenho é Nicholas na idade atual (AnimacaoPersonagem.nicholas_pela_idade):
## desce a proteção, feita no corpo do adulto, até a cabeça ou o tronco dele.
@export var nicholas_pela_idade := false

var _desenho: AnimatedSprite2D


func _ready() -> void:
	# Depois do desenho, que troca de animação e vira no _process dele.
	process_priority = 10
	_desenho = get_parent() as AnimatedSprite2D
	Inventario.equipamento_mudou.connect(_ao_mudar_equipamento)
	_trocar_item()


func _process(_delta: float) -> void:
	_acompanhar()


## Item mostrado agora, ou null.
func item_mostrado() -> Item:
	var id := Inventario.equipado(personagem, encaixe)
	var dados := Inventario.item(id) if not id.is_empty() else null
	return dados if dados and dados.visual_no_corpo else null


func _ao_mudar_equipamento(quem: String, qual: Item.Encaixe, _id: String) -> void:
	if quem == personagem and qual == encaixe:
		_trocar_item()


func _trocar_item() -> void:
	var dados := item_mostrado()
	sprite_frames = dados.visual_no_corpo if dados else null
	_acompanhar()


func _acompanhar() -> void:
	if sprite_frames == null or _desenho == null:
		visible = false
		return
	if not sprite_frames.has_animation(_desenho.animation):
		visible = false
		return
	visible = true
	if animation != _desenho.animation:
		animation = _desenho.animation
	frame = _desenho.frame
	flip_h = _desenho.flip_h
	offset = _desenho.offset
	if nicholas_pela_idade:
		offset.y += AparenciaNicholas.descida(Inventario.faixa_etaria, encaixe)
	centered = _desenho.centered
