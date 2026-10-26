class_name ClareiraFloresta
extends Node2D
## Monta uma clareira da mata "Árvores e mais árvores": o chão em losango,
## a parede de árvores em volta, as quatro trilhas que saem pelo meio de cada
## lado e, além da borda, o [member fundo] cheio de árvores (só desenho) para
## a câmera nunca mostrar o vazio.
##
## Todas as clareiras usam a mesma arrumação de árvores (toda clareira parece
## igual); só muda um detalhe no meio, o "marco" de cada uma (toco, pedra,
## cogumelos...), para quem presta atenção perceber que voltou ao mesmo lugar.
## [method montar] refaz tudo; a cena da fase refaz a navegação depois.
##
## Lados do losango (layout isométrico "diamond down"): NORDESTE é y = 0,
## SUDESTE é x = último, SUDOESTE é y = último e NOROESTE é x = 0.

const TAMANHO := 13
const CENTRO := Vector2i(6, 6)
## Distância do centro (em pisos) a partir da qual começa a parede de árvores.
const INICIO_BORDA := 4
## Meia largura das trilhas (1 = três pisos de largura).
const MEIA_TRILHA := 1
## Quantos pisos o fundo vai além do losango.
const MARGEM_FUNDO := 9
const SEMENTE_ARVORES := 2026

const PISOS_CHAO: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
const PISO_TRILHA := Vector2i(3, 0)
const PISO_BORDA := Vector2i(7, 0)

const GRUPO_OBSTACULOS := &"navegacao_obstaculos"
const LabirintoFloresta := preload("res://scripts/estrada_oa/floresta/labirinto_floresta.gd")

@export var chao: TileMapLayer
@export var fundo: TileMapLayer
## Faixa de 8 pisos de 64×32 (a mesma dos acampamentos).
@export var pisos: Texture2D
@export var arvores: Array[Texture2D] = []
## Árvore com a marca riscada no tronco.
@export var arvore_marcada: Texture2D
## Detalhes do chão, sem colisão (folhas, cogumelos).
@export var enfeites: Array[Texture2D] = []
## O marco de cada clareira da sequência, na mesma ordem (o último serve à
## clareira escondida e às que passarem da lista).
@export var marcos: Array[Texture2D] = []

## Peças da clareira atual (árvores, enfeites, marco), para tirar ao refazer.
var _pecas: Array[Node] = []
var _rng := RandomNumberGenerator.new()
## Árvore marcada da clareira atual (null quando não há).
var marca: Node2D
## Marco da clareira atual.
var marco: Node2D


func _ready() -> void:
	chao.tile_set = CenarioAcampamento.criar_tile_set(pisos)
	if fundo:
		fundo.tile_set = chao.tile_set
		fundo.collision_enabled = false
	_pintar_chao()


## Refaz a clareira [param indice]. [param marcada]: lado com a árvore marcada
## (LabirintoFloresta.NENHUMA quando não há).
func montar(indice: int, marcada: int) -> void:
	for peca in _pecas:
		if is_instance_valid(peca):
			peca.get_parent().remove_child(peca)
			peca.free()
	_pecas.clear()
	marca = null
	_rng.seed = SEMENTE_ARVORES
	for x in range(-MARGEM_FUNDO, TAMANHO + MARGEM_FUNDO):
		for y in range(-MARGEM_FUNDO, TAMANHO + MARGEM_FUNDO):
			var celula := Vector2i(x, y)
			if na_trilha(celula) or distancia_do_centro(celula) < INICIO_BORDA:
				continue
			# Na última fileira e fora do losango, a árvore é só desenho: as
			# bordas invisíveis da navegação já seguram o jogador ali.
			var solida := dentro(celula) and distancia_do_centro(celula) < CENTRO.x
			if _rng.randf() < (0.8 if dentro(celula) else 0.7):
				_por_arvore(celula, solida)
	_por_enfeites(indice)
	_por_marco(indice)
	if marcada != LabirintoFloresta.NENHUMA:
		_por_marca(marcada)


## O piso faz parte de uma das quatro trilhas (dentro ou fora do losango).
static func na_trilha(celula: Vector2i) -> bool:
	var no_eixo_x := absi(celula.x - CENTRO.x) <= MEIA_TRILHA
	var no_eixo_y := absi(celula.y - CENTRO.y) <= MEIA_TRILHA
	return no_eixo_x or no_eixo_y


static func dentro(celula: Vector2i) -> bool:
	return celula.x >= 0 and celula.y >= 0 and celula.x < TAMANHO and celula.y < TAMANHO


static func distancia_do_centro(celula: Vector2i) -> int:
	return maxi(absi(celula.x - CENTRO.x), absi(celula.y - CENTRO.y))


## Piso da beira do losango no fim da trilha de [param saida].
static func celula_da_saida(saida: int) -> Vector2i:
	match saida:
		LabirintoFloresta.Saida.NORDESTE:
			return Vector2i(CENTRO.x, 0)
		LabirintoFloresta.Saida.SUDESTE:
			return Vector2i(TAMANHO - 1, CENTRO.y)
		LabirintoFloresta.Saida.SUDOESTE:
			return Vector2i(CENTRO.x, TAMANHO - 1)
	return Vector2i(0, CENTRO.y)


## Um passo para fora do losango, no rumo da [param saida].
static func passo_para_fora(saida: int) -> Vector2i:
	match saida:
		LabirintoFloresta.Saida.NORDESTE:
			return Vector2i(0, -1)
		LabirintoFloresta.Saida.SUDESTE:
			return Vector2i(1, 0)
		LabirintoFloresta.Saida.SUDOESTE:
			return Vector2i(0, 1)
	return Vector2i(-1, 0)


## Onde Nicholas aparece ao entrar pelo lado [param saida]: na trilha, dois
## pisos para dentro (longe da beira, para não sair de novo na hora).
static func celula_de_entrada(saida: int) -> Vector2i:
	return celula_da_saida(saida) - passo_para_fora(saida) * 2


## Lado cuja beira de trilha contém [param celula], ou NENHUMA.
static func saida_na_celula(celula: Vector2i) -> int:
	for saida in 4:
		var beira := celula_da_saida(saida)
		var passo := passo_para_fora(saida)
		# Na beira (ou além dela) e dentro da largura da trilha.
		var ao_lado := Vector2i(absi(passo.y), absi(passo.x))
		var desvio := (celula - beira) * ao_lado
		var adiante := (celula - beira) * passo
		if adiante.x + adiante.y >= 0 and absi(desvio.x + desvio.y) <= MEIA_TRILHA:
			return saida
	return LabirintoFloresta.NENHUMA


## Ponto do mundo no fim da trilha de [param saida], [param alem] pisos para fora.
func ponto_da_saida(saida: int, alem := 0) -> Vector2:
	var celula := celula_da_saida(saida) + passo_para_fora(saida) * alem
	return chao.to_global(chao.map_to_local(celula))


func ponto_de_entrada(saida: int) -> Vector2:
	return chao.to_global(chao.map_to_local(celula_de_entrada(saida)))


func celula_de(ponto: Vector2) -> Vector2i:
	return chao.local_to_map(chao.to_local(ponto))


func _pintar_chao() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMENTE_ARVORES
	chao.clear()
	for x in TAMANHO:
		for y in TAMANHO:
			chao.set_cell(Vector2i(x, y), 0, _piso(Vector2i(x, y), rng))
	if fundo == null:
		return
	fundo.clear()
	for x in range(-MARGEM_FUNDO, TAMANHO + MARGEM_FUNDO):
		for y in range(-MARGEM_FUNDO, TAMANHO + MARGEM_FUNDO):
			if not dentro(Vector2i(x, y)):
				fundo.set_cell(Vector2i(x, y), 0, _piso(Vector2i(x, y), rng))


func _piso(celula: Vector2i, rng: RandomNumberGenerator) -> Vector2i:
	if na_trilha(celula) and distancia_do_centro(celula) >= INICIO_BORDA - 1:
		return PISO_TRILHA
	if distancia_do_centro(celula) >= INICIO_BORDA:
		return PISO_BORDA
	return PISOS_CHAO[rng.randi() % PISOS_CHAO.size()]


func _desvio() -> Vector2:
	return Vector2(_rng.randi_range(-10, 10), _rng.randi_range(-5, 5))


func _por_arvore(celula: Vector2i, solida: bool) -> void:
	if arvores.is_empty():
		return
	var textura: Texture2D = arvores[_rng.randi() % arvores.size()]
	var peca := _peca(textura, celula, solida, "Arvore")
	_guardar(peca)


## Árvore, marco... Sem [param solida], só o desenho (sem colisão).
func _peca(textura: Texture2D, celula: Vector2i, solida: bool, prefixo: String) -> Node2D:
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = textura
	visual.flip_h = _rng.randf() < 0.5
	CenarioAcampamento._apoiar_no_chao(visual)
	var posicao := chao.map_to_local(celula) + _desvio()
	if not solida:
		visual.name = "%sFundo_%d_%d" % [prefixo, celula.x, celula.y]
		visual.position = posicao
		return visual
	var corpo := StaticBody2D.new()
	corpo.name = "%s_%d_%d" % [prefixo, celula.x, celula.y]
	corpo.add_to_group(GRUPO_OBSTACULOS)
	corpo.position = posicao
	corpo.add_child(visual)
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = clampf(textura.get_width() * 0.22, 5.0, 12.0)
	forma.shape = circulo
	corpo.add_child(forma)
	return corpo


func _guardar(peca: Node) -> void:
	add_child(peca)
	_pecas.append(peca)


func _por_enfeites(indice: int) -> void:
	if enfeites.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMENTE_ARVORES + indice
	for x in TAMANHO:
		for y in TAMANHO:
			var celula := Vector2i(x, y)
			if distancia_do_centro(celula) >= INICIO_BORDA or rng.randf() > 0.16:
				continue
			var visual := Sprite2D.new()
			visual.name = "Enfeite_%d_%d" % [x, y]
			visual.texture = enfeites[rng.randi() % enfeites.size()]
			visual.position = chao.map_to_local(celula) + Vector2(rng.randi_range(-10, 10), rng.randi_range(-5, 5))
			visual.z_index = -1
			CenarioAcampamento._apoiar_no_chao(visual)
			_guardar(visual)


## O marco fica sempre no mesmo lugar, um pouco ao lado do centro (fora das trilhas).
func _por_marco(indice: int) -> void:
	marco = null
	if marcos.is_empty():
		return
	var textura: Texture2D = marcos[mini(indice, marcos.size() - 1)]
	marco = _peca(textura, CENTRO + Vector2i(-2, -2), true, "Marco")
	marco.name = "Marco"
	_guardar(marco)


## A árvore marcada fica na boca da trilha certa, do lado direito de quem sai.
func _por_marca(saida: int) -> void:
	if arvore_marcada == null:
		return
	var passo := passo_para_fora(saida)
	var ao_lado := Vector2i(absi(passo.y), absi(passo.x)) * (MEIA_TRILHA + 1)
	var celula := CENTRO + passo * (INICIO_BORDA - 1) + ao_lado
	marca = _peca(arvore_marcada, celula, true, "Marca")
	marca.name = "Marca"
	(marca.get_node("Visual") as Sprite2D).flip_h = false
	_guardar(marca)
