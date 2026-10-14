class_name MapaHelade
extends Node2D
## Tela de viagem entre os lugares de Hélade, no jeito do mapa do Super Mario
## World: Nicholas fica em cima de um local e anda pelos caminhos até outro.
## Toque/clique num local liberado para ir até ele; toque de novo (ou no botão
## Entrar, ou Enter) para entrar. Setas/WASD pulam para o vizinho naquela direção.
## O que ainda não foi descoberto fica sob a névoa: ao chegar num lugar, os
## vizinhos dele aparecem. Dia e noite vêm do autoload Mundo.

signal chegou(id: String)
signal entrada_pedida(id: String)

const ZOOM_PIXEL_ART := 2.0
## Tamanho do Nicholas no mapa (o desenho é o mesmo da exploração).
const ESCALA_NICHOLAS := 0.7
## Raio, em pixels da arte, em que um toque conta como "no local".
const RAIO_TOQUE := 24.0
const RAIO_PONTO := 7.0
const RAIO_ETAPA := 4.0
## Distância entre as bolinhas das estradas (pixels da arte).
const PASSO_PONTILHADO := 9.0
const COR_ESTRADA := Color(0.9255, 0.7412, 0.4588) # Dourado claro
const COR_MAR := Color(0.6235, 0.7216, 0.8235) # Olhos
const COR_PONTO := Color(0.0745, 0.1451, 0.2353) # Azul noite
const COR_BLOQUEADO := Color(0.3686, 0.4, 0.451) # Pedra fria
const COR_OURO_CLARO := Color(0.9255, 0.7412, 0.4588)
const COR_CONTORNO := Color(0.0196, 0.0471, 0.0784) # Noite
const FONTE_NOMES := preload("res://assets/fonts/cinzel/cinzel.ttf")
## Centro da cartela desenhada em tools/arte/gerar_mapa.py (CARTELA), onde vai o título.
const CENTRO_TITULO := Vector2(1450, 148)
## Quanto abaixo do ponto da região fica o nome (abaixo do desenho da cidade).
const DESCIDA_NOME := 30.0
## Duração da passagem entre dia e noite, em segundos.
const TROCA_PERIODO := 1.2
## Músicas do mapa (tema principal do jogo), em loop; trocam junto com o período.
const MUSICA_DIA := "res://assets/audio/music/mapa/mapa_dia.wav"
const MUSICA_NOITE := "res://assets/audio/music/mapa/mapa_noite.wav"
const VOLUME_MUSICA_DB := -6.0
## Tom de Nicholas à noite, para não brilhar mais que o mapa.
const COR_LUAR := Color(0.72, 0.76, 0.9)
const ACOES_DIRECAO := {
	&"mover_frente": Vector2.UP,
	&"mover_tras": Vector2.DOWN,
	&"mover_esquerda": Vector2.LEFT,
	&"mover_direita": Vector2.RIGHT,
}

## Pixels da arte por segundo ao andar pelo mapa.
@export var velocidade := 120.0
## Onde Nicholas começa num jogo novo (depois vale o Mundo.local_no_mapa).
@export var local_inicial := "olympia"
## Quando falso, Entrar só avisa (testes).
@export var trocar_de_cena := true

@export var fundo: Sprite2D
@export var fundo_noite: Sprite2D
@export var lamparinas: LamparinasMapa
@export var nevoa: NevoaMapa
@export var caminhos: Node2D
@export var nicholas: AnimatedSprite2D
@export var camera: Camera2D
@export var placa: Control
@export var nome_local: Label
@export var regiao_local: Label
@export var aviso: Label
@export var botao_entrar: Button
## Provisório, para testar: troca entre dia e noite.
@export var botao_periodo: Button
## Nicholas no barquinho, nas rotas por mar (animações barco_frente e barco_costas).
@export var quadros_barco: SpriteFrames

var grafo: GrafoMapa
## Locais liberados (id -> true). É o mesmo dicionário de Mundo.descobertos.
var liberados: Dictionary = Mundo.descobertos
var local_atual := ""
var andando := false

var _viagem: Tween
## Nomes escritos sobre o mapa: Label -> posição no desenho (pixels da arte).
## Ficam numa camada de tela e são reposicionados a cada quadro, para o texto
## sair nítido em vez de ampliado junto com a arte.
var _rotulos: Dictionary[Label, Vector2] = {}
var _camada_rotulos: CanvasLayer
## Nome de cada região escrito no mapa: id -> Label.
var _nomes: Dictionary[String, Label] = {}
var musica_dia: AudioStreamPlayer
var musica_noite: AudioStreamPlayer
var _troca_periodo: Tween
var _quadros_a_pe: SpriteFrames
var _de_barco := false


func _ready() -> void:
	grafo = GrafoMapa.da_pasta()
	liberados = Mundo.descobertos
	_quadros_a_pe = nicholas.sprite_frames
	for id: String in grafo.locais:
		if grafo.local(id).liberado_no_inicio:
			liberar(id)
	var inicio := Mundo.local_no_mapa
	if grafo.local(inicio) == null or not liberados.has(inicio):
		inicio = local_inicial
	liberar(inicio)
	caminhos.draw.connect(_desenhar_caminhos)
	botao_entrar.pressed.connect(entrar)
	botao_periodo.pressed.connect(Mundo.alternar_periodo)
	placa.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	botao_periodo.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	camera.zoom = Vector2.ONE * ZOOM_PIXEL_ART
	# A câmera é filha do Nicholas: desfaz a escala dele para não aproximar.
	nicholas.scale = Vector2.ONE * ESCALA_NICHOLAS
	camera.scale = Vector2.ONE / ESCALA_NICHOLAS
	if fundo.texture:
		var tamanho := fundo.texture.get_size()
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(tamanho.x)
		camera.limit_bottom = int(tamanho.y)
		nevoa.preparar(tamanho, grafo)
	_revelar(liberados.keys())
	lamparinas.preparar(grafo, liberados)
	Mundo.descoberto.connect(_ao_descobrir)
	Mundo.periodo_mudou.connect(_ao_mudar_periodo)
	_criar_rotulos()
	musica_dia = _tocador_de_musica("MusicaDia", MUSICA_DIA)
	musica_noite = _tocador_de_musica("MusicaNoite", MUSICA_NOITE)
	_aplicar_periodo(1.0 if Mundo.noite else 0.0)
	colocar_em(inicio)


## Descobre um lugar e os vizinhos dele (os próximos passos da viagem).
func liberar(id: String) -> void:
	Mundo.descobrir(id)
	for vizinho in grafo.vizinhos(id):
		Mundo.descobrir(vizinho)


func _process(_delta: float) -> void:
	var tela := get_canvas_transform()
	for rotulo: Label in _rotulos:
		var ancora: Vector2 = tela * _rotulos[rotulo]
		rotulo.position = (ancora - Vector2(rotulo.size.x * 0.5, 0.0)).round()


## Rótulo do nome de cada região e o título do mapa na cartela.
func _criar_rotulos() -> void:
	_camada_rotulos = CanvasLayer.new()
	_camada_rotulos.name = "Rotulos"
	_camada_rotulos.layer = 4
	add_child(_camada_rotulos)
	var titulo := _novo_rotulo("MAPA_TITULO", 56)
	titulo.add_theme_color_override(&"font_color", COR_OURO_CLARO)
	titulo.reset_size()
	_rotulos[titulo] = CENTRO_TITULO - Vector2(0, titulo.size.y / ZOOM_PIXEL_ART * 0.5)
	for id: String in grafo.locais:
		var local := grafo.local(id)
		if local.tipo != LocalMapa.Tipo.REGIAO:
			continue
		var nome := _novo_rotulo(local.chave_nome, 26)
		nome.name = "Nome_" + id
		nome.visible = liberados.has(id)
		_rotulos[nome] = local.posicao + Vector2(0, DESCIDA_NOME)
		_nomes[id] = nome


func _novo_rotulo(chave: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.text = chave
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_font_override(&"font", FONTE_NOMES)
	rotulo.add_theme_font_size_override(&"font_size", tamanho)
	rotulo.add_theme_color_override(&"font_color", COR_ESTRADA.lightened(0.35))
	rotulo.add_theme_color_override(&"font_outline_color", COR_CONTORNO)
	rotulo.add_theme_constant_override(&"outline_size", 8)
	rotulo.add_theme_color_override(&"font_shadow_color", Color(COR_CONTORNO, 0.6))
	rotulo.add_theme_constant_override(&"shadow_offset_y", 3)
	_camada_rotulos.add_child(rotulo)
	return rotulo


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch and evento.pressed:
		if BotoesToque.toque_em_botao(get_tree(), evento.position):
			return
		var id := local_em(get_canvas_transform().affine_inverse() * evento.position)
		if id.is_empty():
			return
		get_viewport().set_input_as_handled()
		if id == local_atual and not andando:
			entrar()
		else:
			viajar_para(id)
		return
	if evento.is_action_pressed(&"interagir"):
		get_viewport().set_input_as_handled()
		entrar()
		return
	for acao: StringName in ACOES_DIRECAO:
		if evento.is_action_pressed(acao) and not andando:
			var vizinho := grafo.vizinho_na_direcao(local_atual, ACOES_DIRECAO[acao], liberados)
			if not vizinho.is_empty():
				get_viewport().set_input_as_handled()
				viajar_para(vizinho)
			return


## Põe Nicholas direto num local, sem andar.
func colocar_em(id: String) -> void:
	var local := grafo.local(id)
	if local == null:
		push_error("MapaHelade: local desconhecido '%s'." % id)
		return
	local_atual = id
	Mundo.local_no_mapa = id
	nicholas.position = local.posicao
	camera.reset_smoothing()
	_parar()


## Local cujo ponto está perto de [param posicao] (pixels da arte), ou "".
func local_em(posicao: Vector2) -> String:
	for id: String in grafo.locais:
		if liberados.has(id) and grafo.local(id).posicao.distance_to(posicao) <= RAIO_TOQUE:
			return id
	return ""


## Anda pelos caminhos até [param destino]. Devolve false se não houver
## caminho por locais liberados.
func viajar_para(destino: String) -> bool:
	if andando or destino == local_atual:
		return false
	var trechos := grafo.caminho(local_atual, destino, liberados)
	if trechos.size() < 2:
		return false
	andando = true
	aviso.text = ""
	placa.hide()
	_viagem = create_tween()
	var anterior := grafo.local(local_atual).posicao
	for i in range(1, trechos.size()):
		var proximo := grafo.local(trechos[i])
		var tempo := anterior.distance_to(proximo.posicao) / velocidade
		var por_mar := grafo.por_mar(trechos[i - 1], trechos[i])
		_viagem.tween_callback(_olhar_para.bind(proximo.posicao - anterior, por_mar))
		_viagem.tween_property(nicholas, "position", proximo.posicao, tempo)
		_viagem.tween_callback(_passar_por.bind(trechos[i]))
		anterior = proximo.posicao
	_viagem.tween_callback(_chegar)
	return true


## Termina a viagem na hora (testes, e futuramente "pular animação").
func terminar_viagem() -> void:
	if _viagem and _viagem.is_running():
		_viagem.custom_step(INF)


func entrar() -> void:
	if andando or local_atual.is_empty():
		return
	entrada_pedida.emit(local_atual)
	var cena := grafo.local(local_atual).cena
	if cena.is_empty():
		aviso.text = tr("MAPA_SEM_CENA")
		return
	if trocar_de_cena:
		TrocaCena.ir_para(cena)


func _passar_por(id: String) -> void:
	local_atual = id
	Mundo.local_no_mapa = id
	liberar(id)


func _ao_descobrir(id: String) -> void:
	_revelar([id])
	if _nomes.has(id):
		_nomes[id].show()
	caminhos.queue_redraw()
	lamparinas.queue_redraw()


func _revelar(ids: Array) -> void:
	var locais: Array[LocalMapa] = []
	for id: String in ids:
		if grafo.local(id):
			locais.append(grafo.local(id))
	nevoa.revelar(locais)


func _ao_mudar_periodo(noite: bool) -> void:
	if _troca_periodo:
		_troca_periodo.kill()
	_troca_periodo = create_tween()
	var atual := fundo_noite.modulate.a
	_troca_periodo.tween_method(_aplicar_periodo, atual, 1.0 if noite else 0.0, TROCA_PERIODO)


## 0 = dia, 1 = noite.
func _aplicar_periodo(quanto: float) -> void:
	fundo_noite.modulate.a = quanto
	fundo_noite.visible = quanto > 0.0
	lamparinas.acesas = quanto
	nevoa.definir_noite(quanto)
	nicholas.modulate = Color.WHITE.lerp(COR_LUAR, quanto)
	# As duas tocam sempre; o período só cruza os volumes.
	musica_dia.volume_db = VOLUME_MUSICA_DB + linear_to_db(maxf(1.0 - quanto, 0.0001))
	musica_noite.volume_db = VOLUME_MUSICA_DB + linear_to_db(maxf(quanto, 0.0001))


func _tocador_de_musica(nome: String, caminho: String) -> AudioStreamPlayer:
	var tocador := AudioStreamPlayer.new()
	tocador.name = nome
	tocador.bus = &"Musica"
	add_child(tocador)
	if ResourceLoader.exists(caminho):
		tocador.stream = load(caminho)
		tocador.play()
	return tocador


func _chegar() -> void:
	andando = false
	_parar()
	chegou.emit(local_atual)


func _parar() -> void:
	var local := grafo.local(local_atual)
	nome_local.text = tr(local.chave_nome)
	regiao_local.text = tr(local.chave_regiao)
	aviso.text = ""
	placa.show()
	var costas := String(nicholas.animation).ends_with("costas")
	_trocar_quadros(local.tipo == LocalMapa.Tipo.MAR)
	if _de_barco:
		nicholas.play(&"barco_costas" if costas else &"barco_frente")
	else:
		nicholas.play(&"parado_costas" if costas else &"parado_frente")


func _olhar_para(rumo: Vector2, por_mar := false) -> void:
	if rumo.x != 0.0:
		nicholas.flip_h = rumo.x < 0.0
	_trocar_quadros(por_mar)
	if _de_barco:
		nicholas.play(&"barco_costas" if rumo.y < 0.0 else &"barco_frente")
	else:
		nicholas.play(&"andando_costas" if rumo.y < 0.0 else &"andando_frente")


## No mar Nicholas vai no barquinho; em terra, a pé.
func _trocar_quadros(barco: bool) -> void:
	_de_barco = barco and quadros_barco != null
	var quadros := quadros_barco if _de_barco else _quadros_a_pe
	if nicholas.sprite_frames != quadros:
		nicholas.sprite_frames = quadros


func esta_de_barco() -> bool:
	return _de_barco


func _desenhar_caminhos() -> void:
	for par: Array in grafo.ligacoes():
		var a := grafo.local(par[0]).posicao
		var b := grafo.local(par[1]).posicao
		if not (liberados.has(par[0]) and liberados.has(par[1])):
			continue # ainda na névoa
		var cor: Color = COR_MAR if par[2] else COR_ESTRADA
		if par[2]:
			caminhos.draw_dashed_line(a, b, cor, 2.0, 6.0)
		else:
			_pontilhado(a, b, cor)
	for id: String in grafo.locais:
		if liberados.has(id):
			_desenhar_local(grafo.local(id))


## Estrada de bolinhas, como no mapa do Super Mario World.
func _pontilhado(a: Vector2, b: Vector2, cor: Color) -> void:
	var comprimento := a.distance_to(b)
	var passos := int(comprimento / PASSO_PONTILHADO)
	for i in range(1, passos):
		var ponto := a.lerp(b, float(i) / passos)
		caminhos.draw_circle(ponto, 2.0, COR_PONTO)
		caminhos.draw_circle(ponto, 1.0, cor)


func _desenhar_local(local: LocalMapa) -> void:
	var p := local.posicao
	var contorno := COR_ESTRADA if liberados.has(local.id) else COR_BLOQUEADO
	match local.tipo:
		LocalMapa.Tipo.ESTRADA:
			caminhos.draw_circle(p, RAIO_ETAPA + 1.0, COR_PONTO)
			caminhos.draw_circle(p, RAIO_ETAPA, contorno)
		LocalMapa.Tipo.ACAMPAMENTO:
			var tenda := PackedVector2Array([p + Vector2(0, -8), p + Vector2(7, 3), p + Vector2(-7, 3)])
			caminhos.draw_colored_polygon(tenda, contorno)
			caminhos.draw_polyline(tenda + PackedVector2Array([tenda[0]]), COR_PONTO, 1.0)
			caminhos.draw_line(p + Vector2(0, -8), p + Vector2(0, 3), COR_PONTO, 1.0)
		LocalMapa.Tipo.MAR:
			caminhos.draw_circle(p, RAIO_ETAPA, COR_PONTO, false, 3.0)
			caminhos.draw_circle(p, RAIO_ETAPA, COR_MAR, false, 1.0)
		LocalMapa.Tipo.PORTO:
			caminhos.draw_circle(p, RAIO_ETAPA + 2.0, COR_PONTO)
			caminhos.draw_circle(p, RAIO_ETAPA + 1.0, COR_MAR if liberados.has(local.id) else COR_BLOQUEADO)
			caminhos.draw_circle(p, 2.0, COR_PONTO)
		_:
			# Só o anel, para não cobrir o desenho da cidade.
			caminhos.draw_circle(p, RAIO_PONTO + 1.0, COR_PONTO, false, 4.0)
			caminhos.draw_circle(p, RAIO_PONTO, contorno, false, 2.0)
