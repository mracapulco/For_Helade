class_name CenarioAcampamento
extends Node2D
## Monta o acampamento a partir do [BiomaAcampamento] da cena: o piso
## (chão, clareira, caminho, margem e água), o que cerca a clareira (árvores,
## pedras...), os enfeites, a saída (placa ou barco) e o companheiro.
## Precisa vir antes da Navegacao na árvore: os nós irmãos ficam prontos na
## ordem, e a navegação só enxerga os obstáculos que já existirem.
##
## O chão é um losango de [constant TAMANHO]×[constant TAMANHO] pisos com a
## fogueira no centro. O que fica perto dos nós em [member reservados]
## (barraca, mercador...) e o caminho até a saída não recebem obstáculos.
## Em volta do losango, o [member fundo] continua o cenário (só desenho, sem
## colisão) para a câmera nunca mostrar o vazio nos cantos.

const TAMANHO := 15
const CENTRO := Vector2i(7, 7)
## Distância do centro (em pisos) a partir da qual começa a borda.
const INICIO_BORDA := 6
const RAIO_CLAREIRA := 2.3
## Quantos pisos o fundo se estende para fora do losango andável.
const MARGEM_FUNDO := 8
## Até quantos pisos para fora ainda nascem árvores e pedras no fundo.
const ALCANCE_ENFEITE_FUNDO := 5

const PISOS_CHAO: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
const PISO_CLAREIRA := Vector2i(3, 0)
const PISO_MARGEM := Vector2i(4, 0)
const PISO_AGUA := Vector2i(5, 0) # dois quadros: colunas 5 e 6
const PISO_BORDA := Vector2i(7, 0)

## Onde fica a placa de saída (na borda sudeste, ponta do caminho).
const CELULA_SAIDA := Vector2i(12, 7)

const GRUPO_OBSTACULOS := &"navegacao_obstaculos"
## Fundura (em pixels de chão) da colisão de um prédio no lugar da barraca.
const LARGURA_CONSTRUCAO := 30.0

enum Terreno { CHAO, CLAREIRA, CAMINHO, BORDA, MARGEM, AGUA }

@export var chao: TileMapLayer
## Camada de desenho fora da área andável (opcional).
@export var fundo: TileMapLayer
## Nós em volta dos quais nada é posto (fogueira, barraca, mercador...).
@export var reservados: Array[Node2D] = []
@export var saida: Node2D
@export var companheiro: Node2D
## Viajante a mais (só aparece quando o bioma tem [member BiomaAcampamento.viajante]).
@export var viajante: Node2D
## Barraca, que vira o prédio quando o bioma tem [member BiomaAcampamento.construcao].
@export var barraca: Node2D
@export var textura_placa: Texture2D
@export var textura_barco: Texture2D

var bioma: BiomaAcampamento
var _ocupadas: Dictionary[Vector2i, bool] = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bioma = get_parent().get("bioma") as BiomaAcampamento
	if bioma == null:
		push_warning("Acampamento sem bioma: %s" % get_parent().name)
		return
	_rng.seed = hash(bioma.id) + bioma.semente
	chao.tile_set = criar_tile_set(bioma.pisos)
	chao.add_to_group(GRUPO_OBSTACULOS) # a água tem colisão
	if fundo:
		fundo.tile_set = chao.tile_set
		fundo.collision_enabled = false
	_posicionar_saida()
	_vestir_companheiro()
	_vestir_viajante()
	_erguer_construcao()
	_reservar()
	_por_falesias()
	_pintar_chao()
	_espalhar()
	_pintar_fundo()


## O piso de cada célula, sem sorteio (os testes usam isto).
func terreno(celula: Vector2i) -> Terreno:
	var margem := false
	for lado in bioma.lados_agua:
		var distancia := distancia_ao_lado(celula, lado)
		if distancia < bioma.largura_agua:
			return Terreno.AGUA
		if distancia == bioma.largura_agua:
			margem = true
	if no_caminho(celula):
		return Terreno.CAMINHO
	if margem:
		return Terreno.MARGEM
	if Vector2(celula - CENTRO).length() <= RAIO_CLAREIRA:
		return Terreno.CLAREIRA
	if distancia_do_centro(celula) >= INICIO_BORDA:
		return Terreno.BORDA
	return Terreno.CHAO


static func distancia_ao_lado(celula: Vector2i, lado: BiomaAcampamento.Lado) -> int:
	match lado:
		BiomaAcampamento.Lado.NORDESTE:
			return celula.y
		BiomaAcampamento.Lado.SUDESTE:
			return TAMANHO - 1 - celula.x
		BiomaAcampamento.Lado.SUDOESTE:
			return TAMANHO - 1 - celula.y
		_:
			return celula.x


static func distancia_do_centro(celula: Vector2i) -> int:
	return maxi(absi(celula.x - CENTRO.x), absi(celula.y - CENTRO.y))


## Trilha de terra batida da fogueira até a beira sudeste.
static func no_caminho(celula: Vector2i) -> bool:
	return celula.y == CENTRO.y and celula.x > CENTRO.x


func saida_de_barco() -> bool:
	return bioma.tem_agua(BiomaAcampamento.Lado.SUDESTE)


## Onde fica a saída: a placa na ponta do caminho ou, quando o sudeste é
## água, o barco no primeiro piso de água depois da margem.
func celula_da_saida() -> Vector2i:
	if saida_de_barco():
		return Vector2i(TAMANHO - bioma.largura_agua, CENTRO.y)
	return CELULA_SAIDA


## TileSet isométrico (64×32, losango para baixo) com os 8 pisos do bioma.
## A água tem colisão e anima entre dois quadros.
static func criar_tile_set(pisos: Texture2D) -> TileSet:
	var conjunto := TileSet.new()
	conjunto.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	conjunto.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	conjunto.tile_size = Vector2i(64, 32)
	conjunto.add_physics_layer()
	conjunto.set_physics_layer_collision_layer(0, 1)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = pisos
	fonte.texture_region_size = Vector2i(64, 32)
	conjunto.add_source(fonte, 0)
	for coluna: Vector2i in PISOS_CHAO + [PISO_CLAREIRA, PISO_MARGEM, PISO_AGUA, PISO_BORDA]:
		fonte.create_tile(coluna)
	fonte.set_tile_animation_frames_count(PISO_AGUA, 2)
	fonte.set_tile_animation_frame_duration(PISO_AGUA, 0, 0.8)
	fonte.set_tile_animation_frame_duration(PISO_AGUA, 1, 0.8)
	var dados := fonte.get_tile_data(PISO_AGUA, 0)
	dados.add_collision_polygon(0)
	dados.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-32, 0), Vector2(0, -16), Vector2(32, 0), Vector2(0, 16)]))
	return conjunto


func _posicionar_saida() -> void:
	if saida == null:
		return
	var visual := saida.get_node_or_null("Visual") as Sprite2D
	saida.position = chao.map_to_local(celula_da_saida())
	if saida_de_barco():
		if visual and textura_barco:
			visual.texture = textura_barco
	else:
		if visual and textura_placa:
			visual.texture = textura_placa
	if visual:
		_apoiar_no_chao(visual)


func _vestir_companheiro() -> void:
	if companheiro == null:
		return
	var visual := companheiro.get_node_or_null("Visual") as Sprite2D
	if visual and bioma.companheiro:
		visual.texture = bioma.companheiro
		_apoiar_no_chao(visual)
	var interagivel := companheiro.get_node_or_null("Interagivel") as Interagivel
	if interagivel:
		interagivel.marcador = bioma.marcador_companheiro


## Sem viajante no bioma, o nó some do jogo: sem desenho nem colisão (a
## conversa sai no [Acampamento], depois que ela fica pronta).
## Precisa ser antes da Navegacao, que só conta os obstáculos que existirem.
func _vestir_viajante() -> void:
	if viajante == null:
		return
	if bioma.viajante == null:
		viajante.remove_from_group(GRUPO_OBSTACULOS)
		viajante.hide()
		viajante.process_mode = Node.PROCESS_MODE_DISABLED
		return
	var visual := viajante.get_node_or_null("Visual") as Sprite2D
	if visual:
		visual.texture = bioma.viajante
		_apoiar_no_chao(visual)
	var interagivel := viajante.get_node_or_null("Interagivel") as Interagivel
	if interagivel:
		interagivel.marcador = bioma.marcador_viajante


## O prédio toma o lugar da barraca: o desenho e uma colisão larga como ele.
func _erguer_construcao() -> void:
	if barraca == null or bioma.construcao == null:
		return
	var visual := barraca.get_node_or_null("Visual") as Sprite2D
	if visual:
		visual.texture = bioma.construcao
		_apoiar_no_chao(visual)
	var forma := barraca.get_node_or_null("Colisao") as CollisionShape2D
	if forma:
		var retangulo := RectangleShape2D.new()
		retangulo.size = Vector2(bioma.construcao.get_width() * 0.85, LARGURA_CONSTRUCAO)
		forma.shape = retangulo
		forma.position = Vector2(0, -LARGURA_CONSTRUCAO / 2.0 + 2.0)


func _reservar() -> void:
	var nos := reservados.duplicate()
	if viajante and bioma.viajante:
		nos.append(viajante)
	if saida:
		nos.append(saida)
	for no in nos:
		if no == null:
			continue
		var celula := chao.local_to_map(chao.to_local(no.global_position))
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				_ocupadas[celula + Vector2i(dx, dy)] = true


func _pintar_chao() -> void:
	chao.clear()
	for x in TAMANHO:
		for y in TAMANHO:
			var celula := Vector2i(x, y)
			chao.set_cell(celula, 0, _piso(celula))


func _pintar_fundo() -> void:
	if fundo == null:
		return
	fundo.clear()
	for x in range(-MARGEM_FUNDO, TAMANHO + MARGEM_FUNDO):
		for y in range(-MARGEM_FUNDO, TAMANHO + MARGEM_FUNDO):
			var celula := Vector2i(x, y)
			if dentro(celula):
				continue
			fundo.set_cell(celula, 0, _piso(celula))
			var fora := distancia_para_fora(celula)
			if terreno(celula) == Terreno.BORDA and fora <= ALCANCE_ENFEITE_FUNDO and not _ocupadas.has(celula) \
					and _rng.randf() < minf(bioma.densidade_borda + 0.2, 0.9):
				_por_obstaculo(celula, false)


static func dentro(celula: Vector2i) -> bool:
	return celula.x >= 0 and celula.y >= 0 and celula.x < TAMANHO and celula.y < TAMANHO


## Quantos pisos uma célula de fora está além do losango (0 = dentro).
static func distancia_para_fora(celula: Vector2i) -> int:
	return maxi(maxi(-celula.x, -celula.y), maxi(celula.x - TAMANHO + 1, celula.y - TAMANHO + 1))


func _piso(celula: Vector2i) -> Vector2i:
	match terreno(celula):
		Terreno.AGUA:
			return PISO_AGUA
		Terreno.MARGEM:
			return PISO_MARGEM
		Terreno.CLAREIRA, Terreno.CAMINHO:
			return PISO_CLAREIRA
		Terreno.BORDA:
			return PISO_BORDA
	# Mistura a borda no chão perto dela, para a passagem não ser uma linha reta.
	if distancia_do_centro(celula) == INICIO_BORDA - 1 and _rng.randf() < 0.4:
		return PISO_BORDA
	return PISOS_CHAO[_rng.randi() % PISOS_CHAO.size()]


func _espalhar() -> void:
	for x in TAMANHO:
		for y in TAMANHO:
			var celula := Vector2i(x, y)
			if _ocupadas.has(celula):
				continue
			match terreno(celula):
				Terreno.BORDA:
					if _rng.randf() < bioma.densidade_borda:
						# Na última fileira as bordas invisíveis já seguram o
						# jogador; ali a árvore é só desenho (colisão demais
						# colada no contorno estraga a malha de navegação).
						_por_obstaculo(celula, distancia_do_centro(celula) < CENTRO.x)
					elif _rng.randf() < bioma.densidade_enfeites:
						_por_enfeite(celula, bioma.enfeites)
				Terreno.CHAO:
					if distancia_do_centro(celula) == INICIO_BORDA - 1 and _rng.randf() < bioma.densidade_borda * 0.3:
						_por_obstaculo(celula)
					elif _rng.randf() < bioma.densidade_enfeites:
						_por_enfeite(celula, bioma.enfeites)
				Terreno.MARGEM:
					if _rng.randf() < 0.45:
						_por_enfeite(celula, bioma.enfeites_margem)
				Terreno.CLAREIRA:
					if _rng.randf() < bioma.densidade_enfeites * 0.5:
						_por_enfeite(celula, bioma.enfeites)


## Onde ficam as falésias de um lado com água: nas duas pontas da praia, onde
## a areia encontra a borda (e continuando para fora do losango), sem fechar
## o caminho até a água.
func celulas_de_falesia(lado: BiomaAcampamento.Lado) -> Array[Vector2i]:
	var celulas: Array[Vector2i] = []
	for x in range(-ALCANCE_ENFEITE_FUNDO, TAMANHO + ALCANCE_ENFEITE_FUNDO):
		for y in range(-ALCANCE_ENFEITE_FUNDO, TAMANHO + ALCANCE_ENFEITE_FUNDO):
			var celula := Vector2i(x, y)
			var distancia := distancia_ao_lado(celula, lado)
			if distancia < bioma.largura_agua or distancia > bioma.largura_agua + 1:
				continue
			if dentro(celula) and terreno(celula) != Terreno.BORDA:
				continue
			if (x + y) % 2 == 0 and not _ocupadas.has(celula):
				celulas.append(celula)
	return celulas


func _por_falesias() -> void:
	if bioma.falesias.is_empty():
		return
	var i := 0
	for lado in bioma.lados_agua:
		for celula in celulas_de_falesia(lado):
			var textura: Texture2D = bioma.falesias[i % bioma.falesias.size()]
			i += 1
			_por_peca(celula, textura, dentro(celula), "Falesia")
			_ocupadas[celula] = true


func _desvio() -> Vector2:
	return Vector2(_rng.randi_range(-10, 10), _rng.randi_range(-5, 5))


## Árvore, pedra... Fora da área andável ([param solido] falso) é só desenho.
func _por_obstaculo(celula: Vector2i, solido := true) -> void:
	if bioma.obstaculos.is_empty():
		return
	var textura: Texture2D = bioma.obstaculos[_rng.randi() % bioma.obstaculos.size()]
	_por_peca(celula, textura, solido, "Obstaculo")


func _por_peca(celula: Vector2i, textura: Texture2D, solido: bool, prefixo: String) -> void:
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = textura
	visual.flip_h = _rng.randf() < 0.5
	_apoiar_no_chao(visual)
	var posicao := chao.map_to_local(celula) + _desvio()
	if not solido:
		visual.name = "%sFundo_%d_%d" % [prefixo, celula.x, celula.y]
		visual.position = posicao
		add_child(visual)
		return
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
	add_child(corpo)


func _por_enfeite(celula: Vector2i, opcoes: Array[Texture2D]) -> void:
	if opcoes.is_empty():
		return
	var visual := Sprite2D.new()
	visual.name = "Enfeite_%d_%d" % [celula.x, celula.y]
	visual.texture = opcoes[_rng.randi() % opcoes.size()]
	visual.flip_h = _rng.randf() < 0.5
	visual.position = chao.map_to_local(celula) + _desvio()
	visual.z_index = -1 # sempre por baixo de quem anda
	_apoiar_no_chao(visual)
	add_child(visual)


## Põe a base do desenho (os pés, com a sombra) na posição do nó.
static func _apoiar_no_chao(visual: Sprite2D) -> void:
	if visual.texture:
		visual.centered = true
		visual.offset = Vector2(0, -floorf(visual.texture.get_height() / 2.0) + 3)
