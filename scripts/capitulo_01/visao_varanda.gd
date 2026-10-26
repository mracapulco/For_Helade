class_name VisaoVaranda
extends CanvasLayer
## Capítulo 01, cena 8: a visão de Nicholas na carruagem (livro, l. ~317-365).
##
## Curta (20 a 30 s) e sem andar livre. Os cascos crescem, "Tic.", a tela
## escurece e pisca, e vem a varanda fria à noite: céu limpo salpicado de luzes,
## ar imóvel, uma garota de costas e a única palavra, "Lia.", numa voz mais
## grave. O retorno é uma queda brusca, de volta à carruagem.
##
## A cena é montada por tools/cena/gerar_visao_varanda.py (não editar o .tscn
## à mão). O texto vem de data/dialogos/capitulo_01/visao_carruagem.dialogue
## (frases_cascos, frases_visao, frases_lia, frases_retorno). Por cima da cena
## 2D do capítulo: o mundo 3D fica num viewport próprio e a cena some sozinha.
##
## Uso, vindo da cena do capítulo:
##     await VisaoVaranda.tocar(self)
## ou instanciar visao_varanda.tscn, ligar `terminou` e adicioná-la à árvore:
## a visão começa sozinha ao entrar.

signal terminou

const CENA := "res://scenes/capitulo_01/visao_varanda.tscn"
const ROTEIRO := preload("res://data/dialogos/capitulo_01/visao_carruagem.dialogue")
const SFX := "res://assets/audio/sfx/capitulo_01/"
const BARRAMENTO := &"Efeitos"
const SILENCIO_DB := -60.0
## O tic-tac do sonho (tic_tac.wav): o "tic" está em 0 s e o "tac" a 1,3 s.
const POSICAO_TAC := 1.3
## Olhar com o mouse na varanda: radianos por pixel (bem menos que no prólogo)
## e até onde dá para virar (x = para cima e para baixo, y = para os lados).
const SENSIBILIDADE_MOUSE := 0.0008
const LIMITE_OLHAR := Vector2(0.18, 0.35)

## Multiplica todos os tempos (os testes usam valores pequenos). 0 ou menos:
## a visão passa sem texto e quase sem espera.
@export var escala_tempo := 1.0

@onready var _mundo: SubViewportContainer = %Mundo
@onready var _camera: Camera3D = %Camera
@onready var _tremor: ColorRect = %Tremor
@onready var _escuro: ColorRect = %Escuro
@onready var _texto: TextoSolto = %Texto

var _cascos: AudioStreamPlayer
var _vento: AudioStreamPlayer
var _relogio: AudioStreamPlayer
var _queda: AudioStreamPlayer
var _fonte_texto := 0
var _camera_inicio := Vector3.ZERO
var _material_tremor: ShaderMaterial
## Giro da câmera sem o mouse (os tweens da cena mexem aqui).
var _rotacao_base := Vector3.ZERO
## O quanto o mouse virou a câmera (x = para cima, y = para os lados), em radianos.
var _olhar := Vector2.ZERO
## Na varanda: o mouse vira a câmera devagar.
var _olhando := false
var _modo_mouse_antes := Input.MOUSE_MODE_VISIBLE
var _mouse_preso := false


## Toca a visão por cima de [param pai] e volta quando ela termina (a cena é
## removida). [param escala] é o escala_tempo.
static func tocar(pai: Node, escala := 1.0) -> void:
	var visao: VisaoVaranda = load(CENA).instantiate()
	visao.escala_tempo = escala
	pai.add_child(visao)
	await visao.terminou
	visao.queue_free()


func _ready() -> void:
	_preparar()
	_executar()


## Na varanda o jogador pode olhar em volta com o mouse, bem devagar e só um
## pouco (Rafael, 26/10/2026).
func _input(evento: InputEvent) -> void:
	if not _olhando or not evento is InputEventMouseMotion:
		return
	if not _mouse_preso:
		_prender_mouse()
	var sensibilidade := SENSIBILIDADE_MOUSE * Configuracoes.sensibilidade_mouse
	_olhar.y = clampf(_olhar.y - evento.relative.x * sensibilidade, -LIMITE_OLHAR.y, LIMITE_OLHAR.y)
	_olhar.x = clampf(_olhar.x - evento.relative.y * sensibilidade, -LIMITE_OLHAR.x, LIMITE_OLHAR.x)


func _process(_delta: float) -> void:
	if _olhando:
		_camera.rotation = _rotacao_base + Vector3(_olhar.x, _olhar.y, 0.0)


func _prender_mouse() -> void:
	_modo_mouse_antes = Input.mouse_mode
	_mouse_preso = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _soltar_mouse() -> void:
	if _mouse_preso:
		_mouse_preso = false
		Input.mouse_mode = _modo_mouse_antes


func _exit_tree() -> void:
	_soltar_mouse()


func _executar() -> void:
	await _cascos_e_escuro()
	await _varanda()
	await _retorno()
	terminou.emit()


# ------------------------------------------------------------ preparo

func _preparar() -> void:
	_camera_inicio = _camera.position
	_rotacao_base = _camera.rotation
	_material_tremor = _tremor.material as ShaderMaterial
	_escuro.color.a = 0.0
	_fonte_texto = _texto.get_theme_font_size("font_size")
	# Os testes encurtam as pausas do texto junto com o resto.
	var escala := maxf(escala_tempo, 0.01)
	_texto.tempo_fade *= escala
	_texto.tempo_minimo *= escala
	_texto.tempo_por_letra *= escala
	_cascos = _tocador("Cascos", "cascos_crescendo.wav", -14.0)
	_relogio = _tocador("Relogio", "tic_tac.wav", -6.0)
	_queda = _tocador("Queda", "queda.wav", -4.0)
	_vento = _tocador("Vento", "vento_leve.wav", SILENCIO_DB)
	# O vento é um laço (o arquivo foi feito para emendar sem estalo).
	var laco := _vento.stream as AudioStreamWAV
	if laco:
		laco = laco.duplicate()
		laco.loop_mode = AudioStreamWAV.LOOP_FORWARD
		laco.loop_begin = 0
		laco.loop_end = int(laco.data.size() / 2.0)
		_vento.stream = laco


func _tocador(nome: String, arquivo: String, volume: float) -> AudioStreamPlayer:
	var tocador := AudioStreamPlayer.new()
	tocador.name = nome
	tocador.stream = load(SFX + arquivo)
	tocador.bus = BARRAMENTO
	tocador.volume_db = volume
	add_child(tocador)
	return tocador


# ------------------------------------------------------------ 1. cascos e escuro

func _cascos_e_escuro() -> void:
	var frases := await _frases("frases_cascos")
	_cascos.play()
	# Os cascos já crescem no próprio arquivo; o volume sobe junto.
	_tween_volume(_cascos, 0.0, _t(7.0))
	# O ar treme cada vez mais, como no sonho.
	_tween_tremor(0.007, _t(8.0))

	await _dizer(_frase(frases, 0))                 # O som dos cascos foi ficando...
	_tween_escuro(0.35, _t(1.2))
	_golpe_do_relogio(0.0, 1.2)
	await _dizer(_frase(frases, 1))                 # Tic.
	_tween_escuro(0.7, _t(1.2))
	await _dizer(_frase(frases, 2))                 # E, de repente, as vozes se afastaram.
	# Sem o lampejo da varanda aqui (Rafael, 26/10/2026: a piscada no início
	# incomodava): ela só aparece quando o escuro se abre.
	_escuro.color.a = 1.0
	await _esperar(1.0)
	_tween_volume(_cascos, SILENCIO_DB, _t(0.5))
	_golpe_do_relogio(POSICAO_TAC, 1.2)
	await _dizer(_frase(frases, 3))                 # Tac.
	_cascos.stop()
	_tremor.visible = false


## Toca um pedaço do tic-tac e o apaga antes de o próximo golpe chegar.
func _golpe_do_relogio(desde: float, duracao: float) -> void:
	_relogio.volume_db = -6.0
	_relogio.play(desde)
	var fim := create_tween()
	fim.tween_interval(_t(maxf(duracao - 0.3, 0.0)))
	fim.tween_property(_relogio, "volume_db", SILENCIO_DB, _t(0.3))
	fim.tween_callback(_relogio.stop)


# ------------------------------------------------------------ 2. a varanda

func _varanda() -> void:
	var frases := await _frases("frases_visao")
	_mundo.visible = true
	_olhando = true
	_vento.play()
	_tween_volume(_vento, -20.0, _t(3.0))
	# Aproximação lenta e uma leve virada: Nicholas não anda, só olha.
	var movimento := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movimento.tween_property(_camera, "position:z", _camera_inicio.z + 1.1, _t(15.0))
	# Relativo ao giro do .tscn (a câmera olha para +z: 180°), senão ela vira
	# para a parede de trás e a garota some. O giro vai na base; o mouse soma
	# um pouco por cima ([method _input]).
	var giro := _rotacao_base.y
	movimento.tween_property(self, "_rotacao_base:y", giro + deg_to_rad(-3.0), _t(15.0)).from(giro + deg_to_rad(3.5))
	# Começa olhando um pouco para baixo (o banco de pedra no centro) e ergue os olhos para ela.
	movimento.tween_property(self, "_rotacao_base:x", _rotacao_base.x + deg_to_rad(5.0), _t(15.0))
	_tween_escuro(0.0, _t(2.5))

	await _esperar(0.6)
	for i in 5:
		await _dizer(_frase(frases, i))             # A garota... salpicado... não conseguia...
	await _esperar(0.5)

	# "Lia.": a única palavra, maior, na voz mais grave (a fala já a traz).
	var lia := await _frases("frases_lia")
	_texto.add_theme_font_size_override("font_size", int(_fonte_texto * 1.4))
	await _dizer(_frase(lia, 0))
	_texto.add_theme_font_size_override("font_size", _fonte_texto)
	await _esperar(0.4)


# ------------------------------------------------------------ 3. a queda

func _retorno() -> void:
	var frases := await _frases("frases_retorno")
	_olhando = false
	_soltar_mouse()
	# Queda: a câmera despenca, inclina, e tudo apaga de uma vez.
	_queda.play()
	var cai := create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	cai.tween_property(_camera, "position:y", 0.25, _t(0.4))
	cai.tween_property(_camera, "rotation:x", deg_to_rad(-38.0), _t(0.4))
	cai.tween_property(_escuro, "color:a", 1.0, _t(0.35))
	await cai.finished
	_mundo.visible = false
	_tween_volume(_vento, SILENCIO_DB, _t(0.4))
	# Ainda sacudido, o ar da carruagem volta a tremer e vai assentando.
	_tremor.visible = true
	_material_tremor.set_shader_parameter("forca", 0.01)
	_tween_tremor(0.0, _t(4.0))

	await _dizer(_frase(frases, 0))                 # Sem entender, voltei. Como uma queda.
	_tween_escuro(0.0, _t(1.5))
	await _dizer(_frase(frases, 1))                 # As duas estavam ali, me encarando.
	_vento.stop()
	_tremor.visible = false


# ------------------------------------------------------------ apoio

## Os tempos de espera também respeitam o escala_tempo.
func _t(segundos: float) -> float:
	return maxf(segundos * escala_tempo, 0.0)


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(maxf(_t(segundos), 0.001)).timeout


func _dizer(frase: String) -> void:
	if escala_tempo <= 0.0 or frase.is_empty():
		await get_tree().process_frame
		return
	await _texto.mostrar([frase])


func _frase(frases: Array[String], indice: int) -> String:
	return frases[indice] if indice < frases.size() else ""


func _frases(marcador: String) -> Array[String]:
	var frases: Array[String] = []
	var linha: DialogueLine = await ROTEIRO.get_next_dialogue_line(marcador)
	while linha:
		frases.append(linha.text)
		linha = await ROTEIRO.get_next_dialogue_line(linha.next_id)
	return frases


func _tween_escuro(alfa: float, tempo: float) -> void:
	create_tween().tween_property(_escuro, "color:a", alfa, tempo)


func _tween_volume(tocador: AudioStreamPlayer, db: float, tempo: float) -> void:
	create_tween().tween_property(tocador, "volume_db", db, tempo)


func _tween_tremor(forca: float, tempo: float) -> void:
	create_tween().tween_method(func(valor: float) -> void:
		_material_tremor.set_shader_parameter("forca", valor),
		float(_material_tremor.get_shader_parameter("forca")), forca, tempo)
