class_name FasePorDoSol
extends Node2D
## Fase "Antes que o sol beije o mar" (estrada Atenas–Olympia, oa_estrada_1):
## uma corrida contra o pôr do sol pelo planalto verde até o mirante, de onde
## Olympia se revela. Do livro (V1 P1 c03) vêm o planalto, o pôr do sol ("o
## Sol quase beijava o oceano") e a vista; a corrida é inferência (brainstorm
## das 4 fases aprovado pelo Rafael em 26/10).
##
## Como joga:
## - O sol desce no [RelogioSol], no canto da tela: é o relógio da corrida.
## - Correr (Shift) gasta [Folego]; o capim alto atrasa.
## - Atalhos: pular as muretas (Espaço) e atravessar o riacho pelas pedras; o
##   caminho longo e seguro segue a estrada e a ponte.
## - Depois da terceira barreira o vento sopra do mar e empurra Nicholas; nas
##   sombras das pedras ele não alcança.
## - Segredo: do alto da terceira mureta, a trilha entre as pedras brancas
##   aparece (nota no Códice) e deixa de ser capim.
## - Perder não volta a fase: o sol só se põe e a vista fica noturna. Chegar a
##   tempo dá a vista dourada e uma nota no Códice. No fim, seguir para
##   Olympia (o mapa, já em Olympia) ou tentar de novo.
## O planalto (desenho, abrigo do vento, tempos) fica em [PlanaltoPorDoSol].

signal chegou_ao_mirante(a_tempo: bool)
signal trilha_revelada

const Planalto := preload("res://scripts/estrada_oa/por_do_sol/planalto.gd")
const CENA_MAPA := "res://scenes/mapa/mapa_helade.tscn"
const PASTA_ARTE := "res://assets/art/placeholders/estrada_oa/por_do_sol/"
const SOM_VENTO := "res://assets/audio/sfx/estrada_oa/vento_planalto.wav"
const LOCAL_OLYMPIA := "olympia"
const BARRAMENTO_EFEITOS := &"Efeitos"

## Pisos da faixa chao_planalto.png (tools/arte/gerar_por_do_sol.py).
const PISO_GRAMA := Vector2i(0, 0)
const PISO_GRAMA_2 := Vector2i(1, 0)
const PISO_CAPIM := Vector2i(2, 0)
const PISO_ESTRADA := Vector2i(3, 0)
const PISO_RIACHO := Vector2i(4, 0) # dois quadros: colunas 4 e 5
const PISO_PEDRAS := Vector2i(6, 0)
const PISO_PONTE := Vector2i(7, 0)
const PISO_MATO := Vector2i(8, 0)
const PISO_TRILHA := Vector2i(9, 0)
const PISO_MIRANTE := Vector2i(10, 0)
const PISO_MARMORE := Vector2i(11, 0)
const PISO_MAR := Vector2i(12, 0) # dois quadros: colunas 12 e 13
const PISOS_COM_COLISAO: Array[Vector2i] = [PISO_RIACHO, PISO_MATO, PISO_MARMORE, PISO_MAR]
const PISOS_ANIMADOS: Array[Vector2i] = [PISO_RIACHO, PISO_MAR]

## Quantos pisos de desenho em volta do planalto (sem colisão), para a câmera
## nunca mostrar o vazio.
const MARGEM_FUNDO := 14
## Raio da colisão das rochas e pedras brancas: perto o bastante para não
## sobrar fresta entre duas vizinhas (o raio de Nicholas é 7).
const RAIO_PEDRA := 13.0
## Meio comprimento e meia espessura da mureta (ponta a ponta no piso).
const MEIA_MURETA := Vector2(-16, 8)
const ESPESSURA_MURETA := Vector2(3.6, 1.8)
## Pulando a esta distância de uma mureta, ela não segura Nicholas.
const ALCANCE_PULO_MURETA := 32.0
## Longe assim do meio da mureta, ele já saiu de cima dela.
const SAIU_DA_MURETA := 26.0
## Pulando perto assim da mureta da trilha, ele vê a trilha.
const ALCANCE_VER_TRILHA := 40.0

const COR_TARDE := Color(1.0, 0.96, 0.88)
const COR_SALMAO := Color(1.0, 0.82, 0.72)
const COR_CREPUSCULO := Color(0.9, 0.66, 0.66)
const COR_NOITE := Color(0.42, 0.48, 0.7)
const COR_SOMBRA := Color(0.05, 0.08, 0.16, 0.3)
const COR_TEXTO := Color(0.9255, 0.7412, 0.4588)
const COR_CONTORNO := Color(0.0196, 0.0471, 0.0784)
const COR_FOLEGO := Color(0.56, 0.82, 0.69)
const COR_CANSADO := Color(0.88, 0.48, 0.43)

## Respiro antes de o sol começar a descer.
@export var espera_largada := 2.0
## Quando falso, os botões só anotam a cena pedida (testes).
@export var trocar_de_cena := true

@onready var chao: TileMapLayer = $Chao
@onready var fundo: TileMapLayer = $Fundo
@onready var sombras: Node2D = $Sombras
@onready var objetos: Node2D = $Objetos
@onready var personagem: PersonagemExploracao = $Personagem
@onready var camera: CameraExploracao = $Personagem/Camera
@onready var ambiente: CanvasModulate = $Ambiente

var folego := Folego.new()
var relogio: RelogioSol
var barra_folego: ProgressBar
var dica: Label
var interface: CanvasLayer
var botao_mapa: Button
var camada_vista: CanvasLayer
var imagem_vista: TextureRect
var frase: Label
var botao_seguir: Button
var botao_de_novo: Button
var particulas_vento: CPUParticles2D
var som_vento: AudioStreamPlayer

var muretas: Array[StaticBody2D] = []
var vento_ativo := false
var trilha_visivel := false
var terminou := false
var a_tempo := false
## Esperando o jogador escolher entre seguir e tentar de novo.
var escolhendo := false
## Cena pedida pelo último botão (os testes olham isto).
var cena_pedida := ""

var _velocidade_base := 120.0
var _corrida_base := 1.5
var _tempo := 0.0
var _largada := 0.0
## Muretas que não seguram Nicholas agora (ele pulou por cima).
var _puladas: Array[StaticBody2D] = []
var _dica_tween: Tween


func _ready() -> void:
	_velocidade_base = personagem.velocidade
	_corrida_base = personagem.multiplicador_corrida
	chao.tile_set = criar_tile_set(load(PASTA_ARTE + "chao_planalto.png"))
	fundo.tile_set = chao.tile_set
	fundo.collision_enabled = false
	_pintar_chao()
	_pintar_fundo()
	_por_objetos()
	_desenhar_sombras()
	camera.aplicar_limites(CameraExploracao.limites_do_mapa(chao))
	var inicio := chao.to_global(chao.map_to_local(Planalto.celula_de_saida()))
	personagem.global_position = inicio
	personagem.definir_ponto_de_entrada(inicio)
	personagem.direcao_olhar = Planalto.RUMO_DO_MAR.normalized()
	_criar_interface()
	_criar_vista()
	_criar_vento()
	ambiente.color = COR_TARDE
	mostrar_dica(tr("OA_SOL_DICA_INICIO") + "\n" + tr("OA_SOL_DICA_CONTROLES"), 6.0)


func _exit_tree() -> void:
	if personagem:
		personagem.velocidade = _velocidade_base
		personagem.multiplicador_corrida = _corrida_base


## Casa do chão onde fica este ponto do mundo.
func celula_de(ponto: Vector2) -> Vector2i:
	return chao.local_to_map(chao.to_local(ponto))


func centro_de(celula: Vector2i) -> Vector2:
	return chao.to_global(chao.map_to_local(celula))


func _physics_process(delta: float) -> void:
	if terminou:
		return
	_tempo += delta
	if not relogio.andando:
		_largada += delta
		if _largada >= espera_largada:
			relogio.comecar()
	relogio.avancar(delta)
	var celula := celula_de(personagem.global_position)
	_aplicar_terreno(celula)
	_aplicar_folego(delta)
	_cuidar_das_muretas()
	if not vento_ativo and celula.x >= Planalto.COLUNA_VENTO:
		ativar_vento()
	if vento_ativo:
		_soprar(celula, delta)
	_atualizar_luz()
	if Planalto.no_mirante(celula):
		chegar_ao_mirante()


## O capim alto atrasa (e a trilha das pedras brancas, até ser vista).
func _aplicar_terreno(celula: Vector2i) -> void:
	personagem.velocidade = _velocidade_base * Planalto.fator_terreno(celula, trilha_visivel)


## Correr gasta fôlego; cansado, o Shift não acelera.
func _aplicar_folego(delta: float) -> void:
	var correndo := Input.is_action_pressed(&"correr") and personagem.velocity.length() > 10.0 \
		and not personagem.em_dialogo
	var pode := folego.atualizar(delta, correndo)
	personagem.multiplicador_corrida = _corrida_base if pode else 1.0
	barra_folego.value = folego.fracao() * 100.0
	barra_folego.modulate = COR_CANSADO if folego.cansado else COR_FOLEGO


## Pulando perto de uma mureta, ela deixa Nicholas passar; depois que ele sai
## de cima, ela volta a segurar. Da mureta da trilha, ele vê a trilha.
func _cuidar_das_muretas() -> void:
	var pos := personagem.global_position
	if personagem.pulando:
		for mureta in muretas:
			if _puladas.has(mureta) or pos.distance_to(mureta.global_position) > ALCANCE_PULO_MURETA:
				continue
			personagem.add_collision_exception_with(mureta)
			_puladas.append(mureta)
			if not trilha_visivel and mureta.get_meta(&"da_trilha", false) \
					and pos.distance_to(mureta.global_position) <= ALCANCE_VER_TRILHA:
				revelar_trilha()
		return
	for mureta in _puladas.duplicate():
		if pos.distance_to(mureta.global_position) > SAIU_DA_MURETA:
			personagem.remove_collision_exception_with(mureta)
			_puladas.erase(mureta)


## Nicholas pode passar por esta mureta agora (está pulando ou em cima dela).
func mureta_liberada(mureta: StaticBody2D) -> bool:
	return _puladas.has(mureta)


## Do alto da mureta, a trilha entre as pedras brancas aparece no capim.
func revelar_trilha() -> void:
	if trilha_visivel:
		return
	trilha_visivel = true
	for celula in Planalto.celulas(Planalto.TRILHA):
		chao.set_cell(celula, 0, PISO_TRILHA)
	Codice.anotar("trilha_pedras_brancas")
	mostrar_dica(tr("OA_SOL_TRILHA"), 4.0)
	trilha_revelada.emit()


## Passou da terceira barreira: o vento vira e sopra do mar.
func ativar_vento() -> void:
	if vento_ativo:
		return
	vento_ativo = true
	particulas_vento.emitting = true
	if som_vento.stream:
		som_vento.play()
	mostrar_dica(tr("OA_SOL_DICA_VENTO"), 5.0)


## Empurrão do vento neste quadro (zero onde há abrigo).
func vento_em(celula: Vector2i) -> Vector2:
	if not vento_ativo or not Planalto.com_vento(celula):
		return Vector2.ZERO
	return Planalto.vento(_tempo)


func _soprar(celula: Vector2i, delta: float) -> void:
	var forca := Planalto.forca_vento(_tempo)
	particulas_vento.speed_scale = 0.6 + forca / Planalto.VENTO_MEDIO * 0.5
	som_vento.volume_db = linear_to_db(clampf(forca / (Planalto.VENTO_MEDIO * 1.6), 0.15, 1.0)) - 4.0
	var empurrao := vento_em(celula)
	if empurrao != Vector2.ZERO and not personagem.em_dialogo:
		personagem.move_and_collide(empurrao * delta)


## A luz acompanha o sol: tarde, salmão, crepúsculo e, depois, noite.
func _atualizar_luz() -> void:
	if relogio.posto():
		return
	var p := relogio.progresso()
	ambiente.color = COR_TARDE.lerp(COR_SALMAO, p / 0.7) if p < 0.7 \
		else COR_SALMAO.lerp(COR_CREPUSCULO, (p - 0.7) / 0.3)


func _ao_por_do_sol() -> void:
	if terminou:
		return
	create_tween().tween_property(ambiente, "color", COR_NOITE, 2.5)
	mostrar_dica(tr("OA_SOL_DICA_POS"), 4.0)


## Chegou ao mirante: Olympia se revela. A tempo, a vista dourada e a nota no
## Códice; tarde, a vista noturna. O mapa volta já em Olympia.
func chegar_ao_mirante() -> void:
	if terminou:
		return
	terminou = true
	a_tempo = not relogio.posto()
	personagem.em_dialogo = true
	personagem.velocity = Vector2.ZERO
	personagem.multiplicador_corrida = _corrida_base
	particulas_vento.emitting = false
	Mundo.descobrir(LOCAL_OLYMPIA)
	Mundo.local_no_mapa = LOCAL_OLYMPIA
	Mundo.definir_noite(not a_tempo)
	if a_tempo:
		Codice.anotar("vista_de_olympia")
	chegou_ao_mirante.emit(a_tempo)
	_mostrar_vista()


func _mostrar_vista() -> void:
	interface.hide()
	imagem_vista.texture = load(PASTA_ARTE + ("vista_por_do_sol.png" if a_tempo else "vista_noite.png"))
	var frases: Array = ["OA_SOL_FRASE_SOL", "OA_SOL_FRASE_OLYMPIA", "OA_SOL_FRASE_CASTELO"] \
		if a_tempo else ["OA_SOL_FRASE_OLYMPIA", "OA_SOL_FRASE_CASTELO"]
	var t := create_tween()
	# A câmera abre para o mar, e a vista toma a tela.
	t.tween_property(camera, "zoom", Vector2.ONE * 1.2, 1.4).set_trans(Tween.TRANS_SINE)
	t.tween_callback(camada_vista.show)
	t.tween_property(imagem_vista, "modulate:a", 1.0, 1.4)
	for chave in frases:
		t.tween_callback(func() -> void: frase.text = tr(chave))
		t.tween_property(frase, "modulate:a", 1.0, 0.8)
		t.tween_interval(2.4)
		t.tween_property(frase, "modulate:a", 0.0, 0.8)
	t.tween_callback(_abrir_escolha)


func _abrir_escolha() -> void:
	escolhendo = true
	botao_seguir.get_parent().show()
	botao_seguir.grab_focus()


## Segue para o mapa, com Nicholas já em Olympia.
func seguir_para_olympia() -> void:
	_ir_para(CENA_MAPA)


## Refaz a corrida do começo.
func tentar_de_novo() -> void:
	_ir_para(scene_file_path if not scene_file_path.is_empty() else "res://scenes/estrada_oa/por_do_sol/por_do_sol.tscn")


## Volta ao mapa no meio da corrida, sem chegar (fica na estrada).
func voltar_ao_mapa() -> void:
	_ir_para(CENA_MAPA)


func _ir_para(cena: String) -> void:
	cena_pedida = cena
	if trocar_de_cena:
		TrocaCena.ir_para(cena)


func _unhandled_input(evento: InputEvent) -> void:
	if not escolhendo:
		return
	if evento.is_action_pressed(&"interagir"):
		var foco := get_viewport().gui_get_focus_owner() as Button
		(foco if foco else botao_seguir).pressed.emit()
		get_viewport().set_input_as_handled()


## Um texto curto no pé da tela que some sozinho.
func mostrar_dica(texto: String, duracao: float) -> void:
	dica.text = texto
	if _dica_tween and _dica_tween.is_valid():
		_dica_tween.kill()
	dica.modulate.a = 0.0
	_dica_tween = create_tween()
	_dica_tween.tween_property(dica, "modulate:a", 1.0, 0.4)
	_dica_tween.tween_interval(duracao)
	_dica_tween.tween_property(dica, "modulate:a", 0.0, 0.8)


# ---------- montagem do planalto ----------

## TileSet isométrico (64×32, losango para baixo) com os pisos do planalto.
## Riacho, mato, beira de mármore e mar têm colisão; riacho e mar animam.
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
	for coluna: Vector2i in [PISO_GRAMA, PISO_GRAMA_2, PISO_CAPIM, PISO_ESTRADA, PISO_RIACHO, PISO_PEDRAS,
			PISO_PONTE, PISO_MATO, PISO_TRILHA, PISO_MIRANTE, PISO_MARMORE, PISO_MAR]:
		fonte.create_tile(coluna)
	for animado in PISOS_ANIMADOS:
		fonte.set_tile_animation_frames_count(animado, 2)
		fonte.set_tile_animation_frame_duration(animado, 0, 0.8)
		fonte.set_tile_animation_frame_duration(animado, 1, 0.8)
	for bloqueado in PISOS_COM_COLISAO:
		var dados := fonte.get_tile_data(bloqueado, 0)
		dados.add_collision_polygon(0)
		dados.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-32, 0), Vector2(0, -16), Vector2(32, 0), Vector2(0, 16)]))
	return conjunto


## O piso de cada caractere do planalto.
static func piso_de(simbolo: String, celula: Vector2i, trilha_revelada := false) -> Vector2i:
	match simbolo:
		",":
			return PISO_CAPIM
		"=", "S":
			return PISO_ESTRADA
		"~":
			return PISO_RIACHO
		"o":
			return PISO_PEDRAS
		"p":
			return PISO_PONTE
		"x":
			return PISO_MATO
		"s":
			return PISO_TRILHA if trilha_revelada else PISO_CAPIM
		"F":
			return PISO_MIRANTE
		"b":
			return PISO_MARMORE
		"*":
			return PISO_MAR
	return PISO_GRAMA if (celula.x * 7 + celula.y * 3) % 5 else PISO_GRAMA_2


func _pintar_chao() -> void:
	chao.clear()
	for y in Planalto.altura():
		for x in Planalto.largura():
			var celula := Vector2i(x, y)
			chao.set_cell(celula, 0, piso_de(Planalto.simbolo(celula), celula))


func _pintar_fundo() -> void:
	fundo.clear()
	for y in range(-MARGEM_FUNDO, Planalto.altura() + MARGEM_FUNDO):
		for x in range(-MARGEM_FUNDO, Planalto.largura() + MARGEM_FUNDO):
			var celula := Vector2i(x, y)
			if not Planalto.dentro(celula):
				fundo.set_cell(celula, 0, piso_de(Planalto.simbolo(celula), celula))


func _por_objetos() -> void:
	var rocha := load(PASTA_ARTE + "rocha_planalto.png") as Texture2D
	var pedra := load(PASTA_ARTE + "pedra_branca.png") as Texture2D
	var desenho_mureta := load(PASTA_ARTE + "mureta.png") as Texture2D
	for celula in Planalto.celulas(Planalto.ROCHA):
		_por_pedra(celula, rocha, "Rocha")
	for celula in Planalto.celulas(Planalto.PEDRA_BRANCA):
		_por_pedra(celula, pedra, "PedraBranca")
	for celula in Planalto.celulas(Planalto.MURETA):
		_por_mureta(celula, desenho_mureta)


func _por_pedra(celula: Vector2i, textura: Texture2D, nome: String) -> void:
	var corpo := StaticBody2D.new()
	corpo.name = "%s_%d_%d" % [nome, celula.x, celula.y]
	corpo.position = objetos.to_local(centro_de(celula))
	var visual := Sprite2D.new()
	visual.texture = textura
	visual.offset = Vector2(0, -textura.get_height() / 2.0 + 4.0)
	corpo.add_child(visual)
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RAIO_PEDRA
	forma.shape = circulo
	corpo.add_child(forma)
	objetos.add_child(corpo)


## Muro baixo que corta o piso de nordeste para sudoeste (a linha das casas
## com o mesmo x). Só deixa passar pulando.
func _por_mureta(celula: Vector2i, textura: Texture2D) -> void:
	var corpo := StaticBody2D.new()
	corpo.name = "Mureta_%d_%d" % [celula.x, celula.y]
	corpo.position = objetos.to_local(centro_de(celula))
	corpo.set_meta(&"da_trilha", celula.x == Planalto.COLUNA_MURETA_DA_TRILHA)
	var visual := Sprite2D.new()
	visual.texture = textura
	visual.offset = Vector2(0, -8)
	corpo.add_child(visual)
	var forma := CollisionPolygon2D.new()
	forma.polygon = PackedVector2Array([
		-MEIA_MURETA + ESPESSURA_MURETA, MEIA_MURETA + ESPESSURA_MURETA,
		MEIA_MURETA - ESPESSURA_MURETA, -MEIA_MURETA - ESPESSURA_MURETA])
	corpo.add_child(forma)
	objetos.add_child(corpo)
	muretas.append(corpo)


## As sombras das rochas no trecho de vento: onde o vento não alcança.
func _desenhar_sombras() -> void:
	for celula in Planalto.sombras():
		var losango := Polygon2D.new()
		losango.color = COR_SOMBRA
		losango.polygon = PackedVector2Array([Vector2(-32, 0), Vector2(0, -16), Vector2(32, 0), Vector2(0, 16)])
		losango.position = sombras.to_local(centro_de(celula))
		sombras.add_child(losango)


# ---------- interface ----------

func _criar_interface() -> void:
	interface = CanvasLayer.new()
	interface.name = "Interface"
	interface.layer = 5
	add_child(interface)
	botao_mapa = Button.new()
	botao_mapa.name = "BotaoMapa"
	botao_mapa.text = "ACAMP_BOTAO_MAPA"
	botao_mapa.focus_mode = Control.FOCUS_NONE
	botao_mapa.custom_minimum_size = Vector2(240, 72)
	botao_mapa.position = Vector2(32, 32)
	botao_mapa.pressed.connect(voltar_ao_mapa)
	botao_mapa.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	interface.add_child(botao_mapa)
	var coluna := VBoxContainer.new()
	coluna.name = "Relogio"
	# Embaixo do Voltar ao mapa (à direita ficam a Bolsa e o Códice).
	coluna.position = Vector2(32, 124)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(coluna)
	relogio = RelogioSol.new()
	relogio.name = "RelogioSol"
	relogio.se_pos.connect(_ao_por_do_sol)
	coluna.add_child(relogio)
	barra_folego = ProgressBar.new()
	barra_folego.name = "Folego"
	barra_folego.custom_minimum_size = Vector2(220, 14)
	barra_folego.show_percentage = false
	barra_folego.value = 100.0
	barra_folego.tooltip_text = "OA_SOL_FOLEGO"
	barra_folego.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(barra_folego)
	var rotulo := _rotulo(16)
	rotulo.text = "OA_SOL_FOLEGO"
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coluna.add_child(rotulo)
	dica = _rotulo(22)
	dica.name = "Dica"
	# No alto, abaixo dos avisos do Códice (embaixo ficam os botões de toque).
	dica.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	dica.offset_left = -400
	dica.offset_right = 400
	dica.offset_top = 124
	dica.offset_bottom = 204
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dica.modulate.a = 0.0
	interface.add_child(dica)


func _criar_vista() -> void:
	camada_vista = CanvasLayer.new()
	camada_vista.name = "Vista"
	# Por cima de tudo (bolsa, Códice, barra rápida e botões de toque).
	camada_vista.layer = 50
	camada_vista.hide()
	add_child(camada_vista)
	imagem_vista = TextureRect.new()
	imagem_vista.name = "Imagem"
	imagem_vista.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	imagem_vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem_vista.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	imagem_vista.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagem_vista.modulate.a = 0.0
	camada_vista.add_child(imagem_vista)
	frase = _rotulo(30)
	frase.name = "Frase"
	frase.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	frase.offset_left = -600
	frase.offset_right = 600
	frase.offset_top = 48
	frase.offset_bottom = 140
	frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frase.modulate.a = 0.0
	camada_vista.add_child(frase)
	var botoes := VBoxContainer.new()
	botoes.name = "Botoes"
	botoes.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	botoes.offset_left = -170
	botoes.offset_right = 170
	botoes.offset_top = -220
	botoes.offset_bottom = -48
	botoes.add_theme_constant_override("separation", 16)
	botoes.hide()
	camada_vista.add_child(botoes)
	botao_seguir = _botao("OA_SOL_SEGUIR", seguir_para_olympia)
	botoes.add_child(botao_seguir)
	botao_de_novo = _botao("OA_SOL_DE_NOVO", tentar_de_novo)
	botoes.add_child(botao_de_novo)


func _criar_vento() -> void:
	particulas_vento = CPUParticles2D.new()
	particulas_vento.name = "Vento"
	particulas_vento.emitting = false
	particulas_vento.amount = 70
	particulas_vento.lifetime = 2.2
	particulas_vento.local_coords = false
	particulas_vento.texture = load(PASTA_ARTE + "folha_vento.png")
	particulas_vento.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas_vento.emission_rect_extents = Vector2(360, 200)
	particulas_vento.direction = -Planalto.RUMO_DO_MAR.normalized()
	particulas_vento.spread = 8.0
	particulas_vento.gravity = Vector2.ZERO
	particulas_vento.initial_velocity_min = 140.0
	particulas_vento.initial_velocity_max = 220.0
	particulas_vento.angular_velocity_min = -180.0
	particulas_vento.angular_velocity_max = 180.0
	particulas_vento.scale_amount_min = 1.5
	particulas_vento.scale_amount_max = 2.5
	particulas_vento.z_index = 10
	camera.add_child(particulas_vento)
	som_vento = AudioStreamPlayer.new()
	som_vento.name = "SomVento"
	som_vento.bus = BARRAMENTO_EFEITOS
	if ResourceLoader.exists(SOM_VENTO):
		som_vento.stream = load(SOM_VENTO)
	add_child(som_vento)


func _rotulo(tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", COR_TEXTO)
	rotulo.add_theme_color_override("font_outline_color", COR_CONTORNO)
	rotulo.add_theme_constant_override("outline_size", 6)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo


func _botao(chave: String, ao_apertar: Callable) -> Button:
	var botao := Button.new()
	botao.text = chave
	botao.custom_minimum_size = Vector2(340, 72)
	botao.pressed.connect(ao_apertar)
	botao.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	return botao
