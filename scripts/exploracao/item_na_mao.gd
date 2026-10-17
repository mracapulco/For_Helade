class_name ItemNaMao
extends Sprite2D

const AparenciaNicholas := preload("res://scripts/systems/aparencia_nicholas.gd")
## Mostra na mão do personagem o que ele tem equipado (Inventario) e
## acompanha cada quadro da animação: parado, andando, correndo, pulando
## (o pulo levanta o Corpo inteiro), interagindo e golpeando. Espelha junto
## com o desenho.
## Na mão da frente vai a arma, que gira com o golpe do jeito dela
## (Item.angulos_golpe); na mão de trás vai o escudo, a caixa ou a panela
## (encaixe ESCUDO), sem girar.
## Fica como filho do desenho animado (Personagem/Corpo/Visual).

## Id do personagem no Inventario.
@export var personagem := "nicholas"

## Onde fica a mão (e o giro do item) em cada quadro da folha deste personagem.
@export var maos: MaosPersonagem
## Usa as mãos de Nicholas na idade atual da história em vez de [member maos]
## (junto com [member AnimacaoPersonagem.nicholas_pela_idade]).
@export var maos_pela_idade := false

## Encaixe do Inventario mostrado aqui: ARMA ou ESCUDO.
@export var encaixe: Item.Encaixe = Item.Encaixe.ARMA
## Segura na mão de trás (escudo) em vez da mão da frente.
@export var mao_de_tras := false

## Arco claro do golpe, mostrado no quadro em que a lâmina corta.
@export var rastro: Sprite2D
## Pixel do ombro no quadro, de onde sai o arco do rastro.
@export var ombro_rastro := Vector2(22, 20)
## Pixel do desenho do rastro que fica no ombro (centro do arco).
@export var centro_rastro := Vector2(0, 15)
## Quadro do golpe em que o rastro aparece.
@export var quadro_do_corte := 1
## Flecha que sai voando no golpe do arco (estilo TIRO). Irmã deste nó.
@export var flecha: Sprite2D
## Até onde a flecha voa no desenho, em pixels, e em quanto tempo.
@export var voo_flecha := 280.0
@export var tempo_flecha := 0.45

var _item: Item
var _desenho: AnimatedSprite2D
var _tween_flecha: Tween
## Já soltou a flecha deste golpe.
var _atirou := false


func _ready() -> void:
	centered = false
	# Depois do desenho, que vira para os lados no _process dele.
	process_priority = 10
	_desenho = get_parent() as AnimatedSprite2D
	if rastro:
		rastro.centered = false
		rastro.hide()
	if flecha:
		flecha.centered = false
		flecha.hide()
	Inventario.equipamento_mudou.connect(_ao_mudar_equipamento)
	if maos_pela_idade:
		_usar_idade(Inventario.faixa_etaria)
		Inventario.faixa_etaria_mudou.connect(_usar_idade)
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


## O golpe da arma mostrada deixa o arco claro no ar (corte e pancada).
func tem_rastro() -> bool:
	return (_item != null and encaixe == Item.Encaixe.ARMA
		and _item.estilo_golpe in [Item.Estilo.CORTE, Item.Estilo.PANCADA])


func _ao_mudar_equipamento(quem: String, qual: Item.Encaixe, _id: String) -> void:
	if quem == personagem and qual == encaixe:
		_trocar_item()


func _usar_idade(faixa: int) -> void:
	maos = AparenciaNicholas.maos(faixa)
	ombro_rastro = AparenciaNicholas.ombro(faixa)
	_acompanhar()


func _trocar_item() -> void:
	var id := Inventario.equipado(personagem, encaixe)
	var dados := Inventario.item(id) if not id.is_empty() else null
	_item = dados if dados and dados.visual_na_mao else null
	texture = _item.visual_na_mao if _item else null
	_acompanhar()


func _acompanhar() -> void:
	var golpeando := _desenho != null and String(_desenho.animation).begins_with("golpe")
	var no_corte := golpeando and _desenho.frame == quadro_do_corte
	if rastro and encaixe == Item.Encaixe.ARMA:
		rastro.visible = tem_rastro() and no_corte
		if rastro.visible:
			_posicionar_rastro()
	if not golpeando:
		_atirou = false
	elif no_corte and not _atirou and _item and _item.estilo_golpe == Item.Estilo.TIRO:
		_atirou = true
		atirar_flecha()
	if _item == null or _desenho == null or maos == null:
		visible = false
		return
	var mao := (maos.ponto_tras(_desenho.animation, _desenho.frame) if mao_de_tras
		else maos.ponto(_desenho.animation, _desenho.frame))
	if mao.x < 0.0:
		visible = false
		return
	visible = true
	var espelhado := _desenho.flip_h
	var giro := 0.0 if mao_de_tras else _giro(golpeando)
	# O giro é em volta do centro do punho: o desenho fica deslocado para
	# esse ponto cair na origem do nó.
	offset = -(Vector2(_item.pega_na_mao) + Vector2.ONE)
	position = centro_da_mao(mao, Vector2(maos.tamanho_quadro), _desenho.offset, espelhado)
	scale = Vector2(-1.0 if espelhado else 1.0, 1.0)
	rotation_degrees = -giro if espelhado else giro


## Giro do item neste quadro: o do golpe da própria arma, se ela tiver um.
func _giro(golpeando: bool) -> float:
	var angulos := _item.angulos_golpe
	if golpeando and _desenho.frame < angulos.size():
		return angulos[_desenho.frame]
	return maos.angulo(_desenho.animation, _desenho.frame)


## Solta a flecha da mão para a frente: voa reto e some.
func atirar_flecha() -> void:
	if flecha == null or _desenho == null or maos == null:
		return
	var espelhado := _desenho.flip_h
	var mao := maos.ponto(_desenho.animation, _desenho.frame)
	var inicio := centro_da_mao(mao, Vector2(maos.tamanho_quadro), _desenho.offset, espelhado)
	# "frente" olha para baixo e para a direita; "costas", para cima.
	var rumo := Vector2(2, 1) if String(_desenho.animation).ends_with("frente") else Vector2(2, -1)
	rumo = rumo.normalized()
	if espelhado:
		rumo.x = -rumo.x
	flecha.offset = -Vector2(flecha.texture.get_size()) / 2.0 if flecha.texture else Vector2.ZERO
	flecha.position = inicio
	flecha.rotation = rumo.angle()
	flecha.modulate.a = 1.0
	flecha.show()
	if _tween_flecha:
		_tween_flecha.kill()
	_tween_flecha = flecha.create_tween()
	_tween_flecha.tween_property(flecha, "position", inicio + rumo * voo_flecha, tempo_flecha)
	_tween_flecha.parallel().tween_property(flecha, "modulate:a", 0.0, tempo_flecha * 0.4).set_delay(tempo_flecha * 0.6)
	_tween_flecha.tween_callback(flecha.hide)


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
