class_name SomPrologo
extends Node
## Sons do prólogo: ambiente, coração, respiração e passos de Nicholas.
##
## Cada som é uma camada em laço que nunca para; o que muda é o volume de cada
## uma, que desliza até o alvo da etapa atual da SequenciaPrologo. Antes dos
## aposentos, o alvo depende de onde Nicholas está (quarto ou corredor).
## Tudo toca no barramento Efeitos, que respeita o volume das Opções.
## Os sons são provisórios, feitos por tools/audio/gerar_sons_prologo.py.

@export var controle: ControlePrimeiraPessoa
@export var sequencia: SequenciaPrologo

const AMBIENTE := "res://assets/audio/ambiente/prologo/"
const EFEITOS := "res://assets/audio/sfx/prologo/"
const BARRAMENTO := &"Efeitos"
const SILENCIO_DB := -80.0

const CAMADAS := {
	"vento_mar": AMBIENTE + "vento_mar.ogg",
	"ondas": AMBIENTE + "ondas.ogg",
	"grilos": AMBIENTE + "grilos.ogg",
	"fogo": AMBIENTE + "fogo.ogg",
	"caos": AMBIENTE + "caos.ogg",
	"correria": AMBIENTE + "correria.ogg",
	"sussurros": AMBIENTE + "sussurros.ogg",
	"coracao": EFEITOS + "coracao.ogg",
	"respiracao": EFEITOS + "respiracao.ogg",
	"choro": EFEITOS + "choro.ogg",
}

## Volume (0 a 1) de cada camada em cada etapa; camada ausente fica muda.
## A etapa "" (antes dos aposentos) é calculada por lugar em alvos_explorando().
const ETAPAS := {
	"caos": {"caos": 0.85, "coracao": 0.6, "respiracao": 0.55, "fogo": 0.25},
	# Debaixo do dossel tudo fica abafado: só o coração e a respiração.
	"dossel": {"correria": 0.55, "coracao": 0.85, "respiracao": 0.7},
	# Althea nasce muda: silêncio total.
	"muda": {},
	"nome": {},
	"olhares": {},
	"choro": {"choro": 0.8, "coracao": 0.3},
	"segurar": {"choro": 0.55, "sussurros": 0.25, "coracao": 0.3},
	# "Um mar de sussurros" em volta de Nicholas com a irmã nos braços.
	"nos_bracos": {"sussurros": 0.45, "fogo": 0.2},
	"depois": {"sussurros": 0.2},
	"quarto_vazio": {"fogo": 0.3, "vento_mar": 0.3},
	"varanda": {"ondas": 0.75, "vento_mar": 0.35, "grilos": 0.3},
	# Os sussurros crescem junto com as frases do final.
	"final": {"sussurros": 0.85, "ondas": 0.3},
	"fim": {},
}
## Batimento (velocidade do laço do coração; 1 = 100 por minuto).
const RITMO_CORACAO := {"caos": 1.4, "dossel": 1.55, "choro": 1.35, "segurar": 1.2}
## Quanto de volume por segundo cada camada anda até o alvo.
const RAPIDEZ := {"muda": 4.0, "final": 0.12, "fim": 0.5}
const RAPIDEZ_PADRAO := 0.8

## Um passo de criança, em metros, e o chão de cada lugar.
const PASSO := 0.45
const PASSOS := {
	"madeira": [EFEITOS + "passo_madeira_1.ogg", EFEITOS + "passo_madeira_2.ogg", EFEITOS + "passo_madeira_3.ogg"],
	"pedra": [EFEITOS + "passo_pedra_1.ogg", EFEITOS + "passo_pedra_2.ogg", EFEITOS + "passo_pedra_3.ogg"],
}

var etapa := ""
var _camadas := {}
var _volumes := {}
var _passos := {}
var _andado := 0.0
var _ultima_posicao := Vector3.ZERO


## Alvos de volume antes dos aposentos, pelo lugar onde Nicholas está:
## no quarto ouve o vento pela janela e a correria longe; no corredor, as
## tochas, a correria cada vez mais perto e o coração acelerando.
static func alvos_explorando(posicao: Vector3) -> Dictionary:
	if posicao.z > 3.9 and posicao.x > 4.0:
		return {"caos": 0.85, "coracao": 0.6, "fogo": 0.25}
	if posicao.z > 3.9:
		return {"vento_mar": 0.35, "correria": 0.3}
	var perto := clampf((posicao.x + 9.0) / 18.0, 0.0, 1.0) # da porta do quarto à dos aposentos
	return {"vento_mar": 0.12, "fogo": 0.45, "correria": 0.4 + 0.4 * perto, "coracao": 0.25 + 0.35 * perto}


static func ritmo_explorando(posicao: Vector3) -> float:
	if posicao.z > 3.9:
		return 1.0
	return 1.0 + 0.35 * clampf((posicao.x + 9.0) / 18.0, 0.0, 1.0)


static func chao_em(posicao: Vector3) -> String:
	# Corredor e varanda são de pedra; os quartos, de assoalho.
	return "pedra" if posicao.z < 3.9 or posicao.z > 12.6 else "madeira"


func _ready() -> void:
	for nome: String in CAMADAS:
		var tocador := AudioStreamPlayer.new()
		tocador.name = nome.to_pascal_case()
		tocador.bus = BARRAMENTO
		var som: AudioStream = load(CAMADAS[nome])
		if som is AudioStreamOggVorbis:
			som.loop = true
		tocador.stream = som
		tocador.volume_db = SILENCIO_DB
		add_child(tocador)
		tocador.play()
		_camadas[nome] = tocador
		_volumes[nome] = 0.0
	for chao: String in PASSOS:
		var sorteio := AudioStreamRandomizer.new()
		for caminho: String in PASSOS[chao]:
			sorteio.add_stream(-1, load(caminho))
		sorteio.random_pitch = 1.12
		sorteio.random_volume_offset_db = 3.0
		var tocador := AudioStreamPlayer.new()
		tocador.name = "Passos" + chao.capitalize()
		tocador.bus = BARRAMENTO
		tocador.stream = sorteio
		tocador.volume_db = -6.0
		add_child(tocador)
		_passos[chao] = tocador
	if sequencia:
		sequencia.etapa_mudou.connect(func(nova: String) -> void: etapa = nova)
	if controle and controle.corpo:
		_ultima_posicao = controle.corpo.global_position


## Volume que cada camada busca agora.
func alvos() -> Dictionary:
	if etapa.is_empty():
		return alvos_explorando(_posicao())
	return ETAPAS.get(etapa, {})


func volume(camada: String) -> float:
	return _volumes.get(camada, 0.0)


func _process(delta: float) -> void:
	var alvo := alvos()
	var passo: float = RAPIDEZ.get(etapa, RAPIDEZ_PADRAO) * delta
	for nome: String in _camadas:
		_volumes[nome] = move_toward(_volumes[nome], alvo.get(nome, 0.0), passo)
		_camadas[nome].volume_db = maxf(SILENCIO_DB, linear_to_db(_volumes[nome]))
	var ritmo: float = ritmo_explorando(_posicao()) if etapa.is_empty() else RITMO_CORACAO.get(etapa, 1.0)
	var coracao: AudioStreamPlayer = _camadas["coracao"]
	coracao.pitch_scale = move_toward(coracao.pitch_scale, ritmo, delta * 0.2)
	_contar_passos()


func _contar_passos() -> void:
	if controle == null or controle.corpo == null:
		return
	var posicao := controle.corpo.global_position
	var andou := Vector2(posicao.x - _ultima_posicao.x, posicao.z - _ultima_posicao.z).length()
	_ultima_posicao = posicao
	if andou > 1.0:
		return # troca de ponto (teleporte), não passo
	_andado += andou
	if _andado >= PASSO:
		_andado = 0.0
		_passos[chao_em(posicao)].play()


func _posicao() -> Vector3:
	return controle.corpo.global_position if controle and controle.corpo else Vector3.ZERO
