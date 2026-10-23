class_name TicTac
extends Node
## Protótipo do Tic. Tac., a Dádiva de Nicholas, como mecânica de combate
## (Rafael, 23/10; P4 em planos/jogabilidade-isometrica.md).
##
## No livro a visão vem sem pedir licença: "Tic." e ele para de sentir o
## vento e de ouvir, o mundo perde as cores; vem a visão; "Tac." e ele volta,
## com tremores (V1 P2 c04, V2 c15). Em luta, ele previu o golpe de
## Persephone pelas costas (V2 c20). Aqui: quando um inimigo com
## [member Inimigo.provoca_tic_tac] prepara o golpe, às vezes o tempo quase
## para, o mundo fica cinza e um vulto dourado mostra o golpe de verdade (de
## onde vem e onde pega). Depois do "Tac.", o leque dourado fica no chão até
## o golpe, e a tela treme.
##
## Não é um botão: a chance sobe com a vida baixa e não vem de novo logo em
## seguida. O formato (cores, chance, vulto) é leitura nossa e precisa do OK
## da Shara antes de entrar na história.

signal visao_comecou(inimigo: Inimigo)
signal visao_terminou

const SOM := preload("res://assets/audio/sfx/capitulo_01/tic_tac.wav")
## No som do relógio, o "Tac." vem 1,3 s depois do "Tic.".
const TAC_NO_SOM := 1.3

const SOMBRA := """
shader_type canvas_item;
uniform sampler2D tela : hint_screen_texture, filter_nearest;
uniform float forca : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec3 cor = texture(tela, SCREEN_UV).rgb;
	float cinza = dot(cor, vec3(0.299, 0.587, 0.114)) * 0.6;
	float borda = 1.0 - smoothstep(0.35, 0.8, length(SCREEN_UV - 0.5));
	COLOR = vec4(mix(cor, vec3(cinza) * (0.55 + 0.45 * borda), forca), 1.0);
}
"""

## Chance de vir a cada golpe preparado, com a vida cheia.
@export_range(0.0, 1.0) var chance_base := 0.5
## Quanto a chance sobe com a vida vazia (cresce aos poucos com o dano).
@export_range(0.0, 1.0) var chance_vida_baixa := 0.4
## Depois de uma visão, quanto tempo até poder vir outra.
@export var recarga := 4.0
## Quanto dura a visão, em segundos de verdade (do "Tic." ao "Tac.").
@export var duracao := TAC_NO_SOM
## Velocidade do tempo durante a visão.
@export var escala_tempo := 0.03

## A visão está acontecendo agora.
var ativo := false
var personagem: PersonagemExploracao
var _desde_a_ultima := INF
var _camadas: Array[Node] = []
var _som: AudioStreamPlayer
var _volumes := {}


## O Tic. Tac. do [param jogador] (criado na primeira vez).
static func de(jogador: PersonagemExploracao) -> TicTac:
	var existente := jogador.get_node_or_null("TicTac") as TicTac
	if existente:
		return existente
	var novo := TicTac.new()
	novo.name = "TicTac"
	novo.personagem = jogador
	jogador.add_child(novo)
	return novo


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if personagem == null:
		personagem = get_parent() as PersonagemExploracao


func _process(delta: float) -> void:
	if ativo:
		# A pausa de impacto do golpe devolve o tempo ao normal ao acabar:
		# durante a visão, o tempo fica quase parado de qualquer jeito.
		Engine.time_scale = escala_tempo
	elif Engine.time_scale > 0.0:
		_desde_a_ultima += delta / Engine.time_scale


## Chance de a visão vir agora: maior com a vida baixa; zero logo depois de outra.
func chance() -> float:
	if ativo or _desde_a_ultima < recarga:
		return 0.0
	var falta := 0.0
	if personagem and personagem.vida:
		falta = 1.0 - personagem.vida.fracao()
	return clampf(chance_base + chance_vida_baixa * falta, 0.0, 1.0)


## O [param inimigo] começou a preparar um golpe: às vezes vem a visão.
func talvez(inimigo: Inimigo) -> bool:
	if personagem == null or personagem.em_dialogo or randf() >= chance():
		return false
	comecar(inimigo)
	return true


## "Tic.": o tempo quase para, o mundo perde as cores e o vulto dourado mostra
## o golpe de verdade do [param inimigo]. Acaba sozinha em [member duracao].
func comecar(inimigo: Inimigo) -> void:
	if ativo:
		return
	ativo = true
	_desde_a_ultima = 0.0
	Engine.time_scale = escala_tempo
	_abafar_sons(true)
	_tocar_relogio()
	_mostrar_visao(inimigo)
	visao_comecou.emit(inimigo)
	await get_tree().create_timer(duracao, true, false, true).timeout
	terminar(inimigo)


## "Tac.": o tempo volta, o leque dourado fica no chão até o golpe e a tela treme.
func terminar(inimigo: Inimigo = null) -> void:
	if not ativo:
		return
	ativo = false
	Engine.time_scale = 1.0
	_abafar_sons(false)
	for camada in _camadas:
		if is_instance_valid(camada):
			camada.queue_free()
	_camadas.clear()
	if is_instance_valid(inimigo) and inimigo.aviso_verdadeiro:
		inimigo.aviso_verdadeiro.visible = true
	_mostrar_palavra(tr("TIC_TAC_TAC"), 0.6)
	# Volta com tremores, como no livro.
	var camera := personagem.get_node_or_null("Camera") as CameraExploracao if personagem else null
	if camera:
		camera.tremer(1.5, 0.35)
	visao_terminou.emit()


func _exit_tree() -> void:
	if ativo:
		ativo = false
		Engine.time_scale = 1.0
		_abafar_sons(false)


func _mostrar_visao(inimigo: Inimigo) -> void:
	# O mundo cinza por baixo...
	var cinza := CanvasLayer.new()
	cinza.name = "TicTacCinza"
	cinza.layer = 50
	var tela := ColorRect.new()
	tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.code = SOMBRA
	tela.material = material
	cinza.add_child(tela)
	add_child(cinza)
	_camadas.append(cinza)
	var entrada := create_tween().set_ignore_time_scale(true)
	entrada.tween_method(func(f: float) -> void: material.set_shader_parameter("forca", f), 0.0, 1.0, 0.12)
	# ...e por cima, em cores, o golpe que vem.
	var visao := CanvasLayer.new()
	visao.name = "TicTacVisao"
	visao.layer = 51
	visao.follow_viewport_enabled = true
	add_child(visao)
	_camadas.append(visao)
	if is_instance_valid(inimigo):
		_desenhar_golpe(visao, inimigo)
	_mostrar_palavra(tr("TIC_TAC_TIC"), duracao)


## O vulto dourado do inimigo indo de onde está até de onde o golpe sai, em
## repetição, e o leque da área que o golpe pega.
func _desenhar_golpe(visao: CanvasLayer, inimigo: Inimigo) -> void:
	var de_onde := inimigo.global_position
	var origem := inimigo.origem_golpe if inimigo.origem_golpe != Vector2.INF else de_onde
	var leque := AvisoNoChao.new()
	leque.name = "LequeVisto"
	var modelo: AvisoNoChao = inimigo.aviso_verdadeiro if inimigo.aviso_verdadeiro else inimigo.aviso_no_chao
	if modelo:
		leque.raio = modelo.raio
		leque.arco = modelo.arco
		leque.direcao = modelo.direcao
	leque.cor = AvisoNoChao.COR_DOURADA
	leque.progresso = 1.0
	leque.position = origem
	visao.add_child(leque)
	var desenho := inimigo.visual as Sprite2D
	if desenho == null:
		return
	var vulto := Sprite2D.new()
	vulto.name = "VultoDoGolpe"
	vulto.texture = desenho.texture
	vulto.offset = desenho.offset
	vulto.flip_h = (personagem.global_position.x < origem.x) if personagem else desenho.flip_h
	vulto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vulto.modulate = Color(1.0, 0.85, 0.45, 0.75)
	vulto.position = de_onde
	visao.add_child(vulto)
	var caminho := vulto.create_tween().set_ignore_time_scale(true).set_loops()
	caminho.tween_property(vulto, "position", origem, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	caminho.tween_interval(0.3)
	caminho.tween_callback(func() -> void: vulto.position = de_onde)


## "Tic." ou "Tac." escrito no alto da tela, sumindo aos poucos.
func _mostrar_palavra(texto: String, tempo: float) -> void:
	var camada := CanvasLayer.new()
	camada.name = "TicTacPalavra"
	camada.layer = 52
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	rotulo.position.y = 90.0
	rotulo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", 44)
	rotulo.add_theme_color_override("font_color", AvisoNoChao.COR_DOURADA)
	rotulo.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.08))
	rotulo.add_theme_constant_override("outline_size", 8)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(rotulo)
	add_child(camada)
	var some := camada.create_tween().set_ignore_time_scale(true)
	some.tween_interval(tempo * 0.6)
	some.tween_property(rotulo, "modulate:a", 0.0, tempo * 0.4)
	some.tween_callback(camada.queue_free)


func _tocar_relogio() -> void:
	if _som == null:
		_som = AudioStreamPlayer.new()
		_som.name = "Relogio"
		_som.stream = SOM
		_som.bus = &"Master"
		add_child(_som)
	_som.play()
	# Só um tic e um tac: corta antes do próximo tic do som em loop.
	var corte := get_tree().create_timer(TAC_NO_SOM + 0.6, true, false, true)
	corte.timeout.connect(func() -> void:
		if is_instance_valid(_som) and not ativo:
			_som.stop())


## O som some (música e efeitos baixam), como no livro: "parou de ouvir".
func _abafar_sons(abafar: bool) -> void:
	for nome in [&"Musica", &"Efeitos"]:
		var barramento := AudioServer.get_bus_index(nome)
		if barramento < 0:
			continue
		if abafar:
			_volumes[nome] = AudioServer.get_bus_volume_db(barramento)
			AudioServer.set_bus_volume_db(barramento, _volumes[nome] - 24.0)
		elif _volumes.has(nome):
			AudioServer.set_bus_volume_db(barramento, _volumes[nome])
	if not abafar:
		_volumes.clear()
