class_name ItemNaMao
extends Sprite2D
## Mostra na mão do personagem a arma que ele tem equipada (Inventario) e
## acompanha cada quadro da animação: parado, andando, correndo, pulando
## (o pulo levanta o Corpo inteiro) e interagindo. Espelha junto com o desenho.
## Fica como filho do desenho animado (Personagem/Corpo/Visual).

## Id do personagem no Inventario.
@export var personagem := "nicholas"

## Onde fica a mão em cada quadro da folha deste personagem.
@export var maos: MaosPersonagem

var _item: Item
var _desenho: AnimatedSprite2D


func _ready() -> void:
	centered = false
	# Depois do desenho, que vira para os lados no _process dele.
	process_priority = 10
	_desenho = get_parent() as AnimatedSprite2D
	Inventario.equipamento_mudou.connect(_ao_mudar_equipamento)
	if _desenho:
		_desenho.frame_changed.connect(_acompanhar)
		_desenho.animation_changed.connect(_acompanhar)
	_trocar_item()


func _process(_delta: float) -> void:
	# O espelho (flip_h) muda sem sinal; conferir a cada quadro é barato.
	if _desenho and visible and flip_h != _desenho.flip_h:
		_acompanhar()


## Item mostrado agora, ou null.
func item_mostrado() -> Item:
	return _item


func _ao_mudar_equipamento(quem: String, encaixe: Item.Encaixe, _id: String) -> void:
	if quem == personagem and encaixe == Item.Encaixe.ARMA:
		_trocar_item()


func _trocar_item() -> void:
	var id := Inventario.equipado(personagem, Item.Encaixe.ARMA)
	var dados := Inventario.item(id) if not id.is_empty() else null
	_item = dados if dados and dados.visual_na_mao else null
	texture = _item.visual_na_mao if _item else null
	_acompanhar()


func _acompanhar() -> void:
	if _item == null or _desenho == null or maos == null:
		visible = false
		return
	var mao := maos.ponto(_desenho.animation, _desenho.frame)
	if mao.x < 0.0:
		visible = false
		return
	visible = true
	flip_h = _desenho.flip_h
	position = posicao_na_mao(mao, Vector2(_item.pega_na_mao), texture.get_size(),
		Vector2(maos.tamanho_quadro), _desenho.offset, flip_h)


## Posição (canto de cima à esquerda) do desenho do item para a pega cair
## na mão. O desenho do personagem é centrado e deslocado por [param offset];
## espelhado, a mão 2×2 troca de lado e o item também.
static func posicao_na_mao(mao: Vector2, pega: Vector2, tamanho_item: Vector2,
		quadro: Vector2, offset: Vector2, espelhado: bool) -> Vector2:
	var y := mao.y - quadro.y / 2.0 + offset.y - pega.y
	var x := mao.x - quadro.x / 2.0 - pega.x
	if espelhado:
		x = quadro.x / 2.0 - mao.x - tamanho_item.x + pega.x
	return Vector2(x + offset.x, y)
