class_name ItemNaMao
extends Sprite2D
## Mostra na mão do personagem a arma que ele tem equipada (Inventario) e
## acompanha cada quadro da animação: parado, andando, correndo, pulando
## (o pulo levanta o Corpo inteiro), interagindo e golpeando. Gira com o
## golpe e espelha junto com o desenho.
## Fica como filho do desenho animado (Personagem/Corpo/Visual).

## Id do personagem no Inventario.
@export var personagem := "nicholas"

## Onde fica a mão (e o giro do item) em cada quadro da folha deste personagem.
@export var maos: MaosPersonagem

## Arco claro do golpe, mostrado no quadro em que a lâmina corta.
@export var rastro: Sprite2D
## Pixel do ombro no quadro, de onde sai o arco do rastro.
@export var ombro_rastro := Vector2(22, 20)
## Pixel do desenho do rastro que fica no ombro (centro do arco).
@export var centro_rastro := Vector2(0, 15)
## Quadro do golpe em que o rastro aparece.
@export var quadro_do_corte := 1

var _item: Item
var _desenho: AnimatedSprite2D


func _ready() -> void:
	centered = false
	# Depois do desenho, que vira para os lados no _process dele.
	process_priority = 10
	_desenho = get_parent() as AnimatedSprite2D
	if rastro:
		rastro.centered = false
		rastro.hide()
	Inventario.equipamento_mudou.connect(_ao_mudar_equipamento)
	if _desenho:
		_desenho.frame_changed.connect(_acompanhar)
		_desenho.animation_changed.connect(_acompanhar)
	_trocar_item()


func _process(_delta: float) -> void:
	# O espelho (flip_h) muda sem sinal; conferir a cada quadro é barato.
	if _desenho and visible and _espelhado() != _desenho.flip_h:
		_acompanhar()


## Item mostrado agora, ou null.
func item_mostrado() -> Item:
	return _item


func _espelhado() -> bool:
	return scale.x < 0.0


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
	var golpeando := _desenho != null and String(_desenho.animation).begins_with("golpe")
	if rastro:
		rastro.visible = _item != null and golpeando and _desenho.frame == quadro_do_corte
		if rastro.visible:
			_posicionar_rastro()
	if _item == null or _desenho == null or maos == null:
		visible = false
		return
	var mao := maos.ponto(_desenho.animation, _desenho.frame)
	if mao.x < 0.0:
		visible = false
		return
	visible = true
	var espelhado := _desenho.flip_h
	var giro := maos.angulo(_desenho.animation, _desenho.frame)
	# O giro é em volta do centro do punho: o desenho fica deslocado para
	# esse ponto cair na origem do nó.
	offset = -(Vector2(_item.pega_na_mao) + Vector2.ONE)
	position = centro_da_mao(mao, Vector2(maos.tamanho_quadro), _desenho.offset, espelhado)
	scale = Vector2(-1.0 if espelhado else 1.0, 1.0)
	rotation_degrees = -giro if espelhado else giro


func _posicionar_rastro() -> void:
	var quadro := Vector2(maos.tamanho_quadro) if maos else Vector2(32, 48)
	var espelhado := _desenho.flip_h
	# O rastro é irmão do item (filho do desenho), então não herda o giro.
	rastro.offset = -centro_rastro
	rastro.position = centro_da_mao(ombro_rastro - Vector2.ONE, quadro, _desenho.offset, espelhado)
	rastro.scale = Vector2(-1.0 if espelhado else 1.0, 1.0)


## Centro da mão 2×2 (cujo canto de cima à esquerda é o pixel [param mao]
## do quadro) nas coordenadas do desenho do personagem, que é centrado e
## deslocado por [param offset]. Espelhado, a mão troca de lado.
static func centro_da_mao(mao: Vector2, quadro: Vector2, offset: Vector2, espelhado: bool) -> Vector2:
	var centro := mao + Vector2.ONE - quadro / 2.0
	if espelhado:
		centro.x = -centro.x
	return centro + offset
