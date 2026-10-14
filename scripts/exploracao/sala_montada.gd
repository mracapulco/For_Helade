class_name SalaMontada
extends Node2D
## Sala retangular da exploração montada por código: chão de [member largura]
## × [member profundidade] pisos, paredes no fundo (linha y = 0 e coluna
## x = 0, como na sala de teste), navegação e a cor da luz do lugar.
## Uso: crie com [method new], ponha os objetos ([method adicionar_objeto])
## e só depois adicione à árvore; a navegação é feita no [method _ready] e só
## enxerga os obstáculos que já estiverem na sala.
## Portas ficam num vão da parede ([method abrir_vao]); tochas, quadros e
## tapeçarias, na face de um bloco da parede ([method pendurar]).
## O chão e a parede seguem o Castelo Olympia do prólogo (pedra clara,
## assoalho, passadeira); o sonho usa a parede lisa ([member parede_lisa]).

const TILESET := preload("res://scenes/exploracao/tileset_mansao.tres")
const FONTE_PISO := 0
const FONTE_PAREDE := 1
## Quadros do chão no atlas (tools/arte/gerar_capitulo_01.py).
const PISO_ASSOALHO := 0
const PISO_PEDRA := 2
const PASSADEIRA_CIMA := 4
const PASSADEIRA_BAIXO := 5
const PASSADEIRA_MEIO := 6
const RAIO_CORPO := 9.0
const RAIO_TOQUE := 28.0

@export var largura := 6
@export var profundidade := 6
## Cor da luz (CanvasModulate): noite azulada, amanhecer dourado, sonho quente...
@export var tom := Color.WHITE
## Chão: "assoalho" (quartos), "pedra" ou "passadeira" (pedra com a passadeira
## vermelha de ponta a ponta, como o corredor do prólogo).
@export var piso := "assoalho"
## Parede lisa, sem a pedra da Casa Olympia (o corredor estranho do sonho).
@export var parede_lisa := false
## Madeira e veludo, por dentro da carruagem.
@export var parede_madeira := false

var chao: TileMapLayer
var obstaculos: TileMapLayer
var navegacao: NavegacaoSala
var ambiente: CanvasModulate
var _vaos: Array[Vector2i] = []


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	y_sort_enabled = true
	chao = TileMapLayer.new()
	chao.name = "Chao"
	chao.z_index = -1
	chao.tile_set = TILESET
	add_child(chao)
	obstaculos = TileMapLayer.new()
	obstaculos.name = "Obstaculos"
	obstaculos.y_sort_enabled = true
	obstaculos.tile_set = TILESET
	add_child(obstaculos)


func _ready() -> void:
	for x in largura:
		for y in profundidade:
			chao.set_cell(Vector2i(x, y), FONTE_PISO, Vector2i(_quadro_do_piso(x, y), 0))
			var parede := x == 0 or y == 0
			if parede and not _vaos.has(Vector2i(x, y)):
				obstaculos.set_cell(Vector2i(x, y), FONTE_PAREDE, Vector2i(_quadro_da_parede(), 0))
	ambiente = CanvasModulate.new()
	ambiente.name = "Ambiente"
	ambiente.color = tom
	add_child(ambiente)
	navegacao = NavegacaoSala.new()
	navegacao.name = "Navegacao"
	navegacao.chao = chao
	navegacao.obstaculos = obstaculos
	add_child(navegacao)


func _quadro_da_parede() -> int:
	if parede_madeira:
		return 2
	return 1 if parede_lisa else 0


func _quadro_do_piso(x: int, y: int) -> int:
	match piso:
		"pedra":
			return PISO_PEDRA + (x + y) % 2
		"passadeira":
			if y <= 1:
				return PASSADEIRA_CIMA
			if y == profundidade - 1:
				return PASSADEIRA_BAIXO
			return PASSADEIRA_MEIO
	return PISO_ASSOALHO + (x + y) % 2


## Deixa uma casa da parede sem bloco, para pôr uma porta nela.
func abrir_vao(casa: Vector2i) -> void:
	_vaos.append(casa)


## Centro de uma casa do chão, em coordenadas da sala.
func centro(casa: Vector2i) -> Vector2:
	return chao.map_to_local(casa)


## Põe um objeto parado na casa: o desenho com os pés na base, um corpo que
## bloqueia a passagem (se [param bloqueia]) e, com [param interagivel], uma
## área de interação. [param pe]: quantos pixels acima da base da imagem
## fica o centro da casa (3 para desenhos de frente; os móveis em caixa
## isométrica usam mais). Devolve o nó do objeto.
func adicionar_objeto(nome: String, textura: Texture2D, casa: Vector2i,
		bloqueia := true, interagivel := false, pe := 3.0) -> Node2D:
	var objeto: Node2D = StaticBody2D.new() if bloqueia else Node2D.new()
	objeto.name = nome
	objeto.position = centro(casa)
	if bloqueia:
		objeto.add_to_group(NavegacaoSala.GRUPO_OBSTACULOS)
		var colisao := CollisionShape2D.new()
		colisao.name = "Colisao"
		var forma := CircleShape2D.new()
		forma.radius = RAIO_CORPO
		colisao.shape = forma
		objeto.add_child(colisao)
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = textura
	visual.offset = Vector2(0, -textura.get_height() / 2.0 + pe)
	objeto.add_child(visual)
	if interagivel:
		var area := Interagivel.new()
		area.name = "Interagivel"
		var toque := CollisionShape2D.new()
		toque.name = "AreaDeToque"
		toque.position = Vector2(0, -12)
		var forma_toque := CircleShape2D.new()
		forma_toque.radius = RAIO_TOQUE
		toque.shape = forma_toque
		area.add_child(toque)
		objeto.add_child(area)
	add_child(objeto)
	return objeto


## Pendura algo na face de um bloco da parede ([param casa] na linha y = 0
## ou na coluna x = 0): a textura tem o tamanho do bloco (64×64) e o desenho
## já inclinado como a face (assets/art/capitulo_01/parede/).
func pendurar(nome: String, textura: Texture2D, casa: Vector2i) -> Sprite2D:
	var enfeite := Sprite2D.new()
	enfeite.name = nome
	enfeite.texture = textura
	enfeite.centered = false
	# Um pixel abaixo do bloco na ordem de desenho: fica por cima da parede e
	# por trás de quem anda na frente dela.
	enfeite.position = centro(casa) + Vector2(0, 1)
	enfeite.offset = Vector2(-32, -49)
	add_child(enfeite)
	return enfeite


## Uma pessoa parada (figurante ou personagem com folha animada).
func adicionar_pessoa(nome: String, quadros: Variant, casa: Vector2i,
		interagivel := false) -> Node2D:
	if quadros is SpriteFrames:
		var objeto := adicionar_objeto(nome, (quadros as SpriteFrames).get_frame_texture(&"parado_frente", 0),
			casa, true, interagivel)
		var visual: Sprite2D = objeto.get_node("Visual")
		var animado := AnimatedSprite2D.new()
		animado.name = "Visual"
		animado.sprite_frames = quadros
		animado.offset = Vector2(0, -22)
		animado.play(&"parado_frente")
		objeto.remove_child(visual)
		visual.free()
		objeto.add_child(animado)
		objeto.move_child(animado, 0)
		return objeto
	return adicionar_objeto(nome, quadros, casa, true, interagivel)


## Leva o jogador para a casa desta sala: ele passa a andar na grade dela e
## a câmera respeita as bordas dela.
func receber_jogador(jogador: PersonagemExploracao, casa: Vector2i) -> void:
	if jogador.get_parent():
		jogador.get_parent().remove_child(jogador)
	jogador.position = centro(casa)
	jogador.grade = chao
	jogador.velocity = Vector2.ZERO
	add_child(jogador)
	var camera := jogador.get_node_or_null("Camera") as CameraExploracao
	if camera:
		camera.mapa = chao
		camera.aplicar_limites(CameraExploracao.limites_do_mapa(chao))
		camera.reset_smoothing()
