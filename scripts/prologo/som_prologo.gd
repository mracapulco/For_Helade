class_name SomPrologo
extends Node
## Sons do prólogo: ambiente, coração, respiração e passos de Nicholas.
##
## Cada som é uma camada em laço que nunca para; o que muda é o volume de cada
## uma, que desliza até o alvo da etapa atual da SequenciaPrologo. Antes dos
## aposentos, o alvo depende de onde Nicholas está (quarto ou corredor).
## Tudo toca no barramento Efeitos, que respeita o volume das Opções.
## Os sons são provisórios, feitos por tools/audio/gerar_sons_prologo.py.
##
## A música vai pelo autoload Trilha (barramento Musica), trocando com fade
## conforme a etapa. Nos aposentos não há música, só os sons.

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
	"choro": EFEITOS + "choro.ogg",
}

## Volume (0 a 1) de cada camada em cada etapa; camada ausente fica muda.
## A etapa "" (antes dos aposentos) é calculada por lugar em alvos_explorando().
const ETAPAS := {
	"caos": {"caos": 0.85, "coracao": 0.8, "fogo": 0.25},
	# Debaixo do dossel tudo fica abafado: só o coração.
	"dossel": {"correria": 0.55, "coracao": 0.9},
	# Althea nasce muda: silêncio total.
	"muda": {},
	"nome": {},
	"olhares": {},
	"choro": {"choro": 0.8, "coracao": 0.3},
	# Sem a camada de sussurros: sintetizada, ela soava como alguém rabiscando
	# (retorno do Rafael, 15/10/2026). Fica a música.
	"segurar": {"choro": 0.55, "coracao": 0.3},
	"nos_bracos": {"fogo": 0.2},
	"depois": {"fogo": 0.1},
	# No quarto vazio o mar é calculado pela distância à varanda (alvos_quarto_vazio).
	"quarto_vazio": {"fogo": 0.3, "vento_mar": 0.3},
	"varanda": {"ondas": 0.98, "vento_mar": 0.46, "grilos": 0.3},
	"final": {"ondas": 0.39},
	"fim": {},
}
const MUSICA := "res://assets/audio/music/prologo/"
## Música de cada etapa ("" para o silêncio). Feitas por tools/audio/compor_prologo.py.
const MUSICAS := {
	"": MUSICA + "prologo_abertura.wav",
	"caos": "",
	"dossel": "",
	"muda": "",
	"nome": "",
	"olhares": "",
	# Depois do silêncio, a música volta devagar com o choro de Althea.
	"choro": MUSICA + "prologo_althea.wav",
	"segurar": MUSICA + "prologo_althea.wav",
	"nos_bracos": MUSICA + "prologo_althea.wav",
	"depois": MUSICA + "prologo_althea.wav",
	"quarto_vazio": MUSICA + "prologo_althea.wav",
	"varanda": MUSICA + "prologo_varanda.wav",
	"final": MUSICA + "prologo_titulo.wav",
	"fim": MUSICA + "prologo_titulo.wav",
}
## Segundos de fade ao trocar de música; a da varanda e a do título entram devagar.
const FADE_MUSICA := {"": 3.0, "caos": 0.8, "choro": 7.0, "varanda": 4.0, "final": 2.5}
const FADE_MUSICA_PADRAO := 2.0

## Batimento (velocidade do laço do coração; 1 = 100 por minuto).
## O coração não é um laço: cada batida é tocada na hora, sorteando um entre
## seis sons e variando um pouco o intervalo, como um coração de verdade.
## O volume dele segue os alvos como as camadas ("coracao").
const CORACAO := "coracao"
const BATIDAS := EFEITOS + "coracao_%d.ogg"
const VARIACOES_DE_BATIDA := 6
## Batimentos por minuto de cada etapa (uma criança assustada passa dos 150).
const BPM_CORACAO := {"caos": 145.0, "dossel": 160.0, "muda": 0.0, "nome": 0.0, "olhares": 0.0,
	"choro": 140.0, "segurar": 125.0, "nos_bracos": 105.0}
const BPM_PADRAO := 100.0
## Do quarto aos aposentos: o coração já bate no quarto, baixinho e calmo, e
## cresce e acelera aos poucos pelo caminho até a porta da duquesa.
const BPM_QUARTO := 88.0
const BPM_PORTA := 135.0
const VOLUME_CORACAO_QUARTO := 0.15
const VOLUME_CORACAO_PORTA := 0.75
## A correria e os gritos dos empregados: já bem audíveis no quarto, mais
## perto no corredor.
const VOLUME_CORRERIA_QUARTO := 0.55
const VOLUME_CORRERIA_PORTA := 0.9
## O caminho de Nicholas: cama, porta do quarto, corredor e porta da duquesa.
const CAMINHO: Array[Vector2] = [Vector2(-11.2, 8.6), Vector2(-9.0, 3.9), Vector2(-9.0, 1.8),
	Vector2(9.0, 1.8), Vector2(9.0, 3.9)]
## Varanda (x, z), e as distâncias dela em que o mar começa a crescer e em
## que chega ao volume quase cheio (o arco, onde a etapa "varanda" começa).
const VARANDA := Vector2(9.0, 14.6)
const LONGE_DA_VARANDA := 5.5
const PERTO_DA_VARANDA := 2.0
## O mar ao longe, já baixinho no quarto vazio.
const ONDAS_QUARTO_VAZIO := 0.12
## Quanto de volume por segundo cada camada anda até o alvo.
const RAPIDEZ := {"muda": 4.0, "final": 0.12, "fim": 0.5}
const RAPIDEZ_PADRAO := 0.8
## No começo, a música entra primeiro; só depois dela vêm, devagar, os gritos e
## a correria do castelo (retorno do Rafael, 15/10/2026).
const ESPERA_AMBIENTE := 4.0
const RAPIDEZ_ENTRADA := 0.1
const DURACAO_ENTRADA := 8.0

## Distância entre um passo e outro (m): passos de criança sem pressa, e mais
## largos correndo. Cada passo sorteia um entre oito sons, sem repetir o último.
const PASSO := 0.7
const PASSO_CORRENDO := 1.0
const VARIACOES_DE_PASSO := 8
const PASSOS := {
	"madeira": EFEITOS + "passo_madeira_%d.ogg",
	"pedra": EFEITOS + "passo_pedra_%d.ogg",
}
const PULO := EFEITOS + "pulo.ogg"
const ATERRISSAGEM := EFEITOS + "aterrissagem_%s.ogg"
## Tempo mínimo no ar para a chegada ao chão fazer barulho (descer de um degrau não conta).
const TEMPO_NO_AR := 0.15

var etapa := ""
var _camadas := {}
var _volumes := {}
var _passos := {}
var _andado := 0.0
var _ultima_posicao := Vector3.ZERO
var _pulo: AudioStreamPlayer
var _coracao: AudioStreamPlayer
var _bpm := BPM_QUARTO
var _ate_a_batida := 0.0
var _aterrissagens := {}
var _no_chao := true
var _no_ar := 0.0
var _tempo_de_cena := 0.0


## Alvos de volume antes dos aposentos, pelo lugar onde Nicholas está:
## no quarto ouve o vento pela janela e a correria longe; no corredor, as
## tochas, a correria cada vez mais perto e o coração acelerando.
static func alvos_explorando(posicao: Vector3) -> Dictionary:
	if posicao.z > 3.9 and posicao.x > 4.0:
		return {"caos": 0.85, CORACAO: 0.8, "fogo": 0.25}
	var perto := perto_da_duquesa(posicao)
	var alvos := {
		CORACAO: lerpf(VOLUME_CORACAO_QUARTO, VOLUME_CORACAO_PORTA, perto),
		"correria": lerpf(VOLUME_CORRERIA_QUARTO, VOLUME_CORRERIA_PORTA, perto),
	}
	if posicao.z > 3.9:
		alvos["vento_mar"] = 0.3
	else:
		alvos["vento_mar"] = 0.1
		alvos["fogo"] = 0.45
	return alvos


## Quanto do caminho até a duquesa Nicholas já andou: 0 na cama, 1 na porta
## dela. Segue o caminho (e não a linha reta) para a rampa ser contínua.
static func perto_da_duquesa(posicao: Vector3) -> float:
	var ponto := Vector2(posicao.x, posicao.z)
	var total := 0.0
	for i in CAMINHO.size() - 1:
		total += CAMINHO[i].distance_to(CAMINHO[i + 1])
	var melhor := INF
	var andado := 0.0
	var resultado := 0.0
	for i in CAMINHO.size() - 1:
		var a := CAMINHO[i]
		var b := CAMINHO[i + 1]
		var trecho := a.distance_to(b)
		var t := clampf((ponto - a).dot(b - a) / (trecho * trecho), 0.0, 1.0)
		var distancia := ponto.distance_to(a.lerp(b, t))
		if distancia < melhor:
			melhor = distancia
			resultado = (andado + t * trecho) / total
		andado += trecho
	return clampf(resultado, 0.0, 1.0)


static func bpm_explorando(posicao: Vector3) -> float:
	return lerpf(BPM_QUARTO, BPM_PORTA, perto_da_duquesa(posicao))


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
		sorteio.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
		for i in range(1, VARIACOES_DE_PASSO + 1):
			sorteio.add_stream(-1, load(PASSOS[chao] % i))
		sorteio.random_pitch = 1.06
		sorteio.random_volume_offset_db = 2.5
		_passos[chao] = _novo_tocador("Passos" + chao.capitalize(), sorteio, -9.0)
		_aterrissagens[chao] = _novo_tocador("Aterrissagem" + chao.capitalize(), load(ATERRISSAGEM % chao), -6.0)
	_pulo = _novo_tocador("Pulo", load(PULO), -8.0)
	var batidas := AudioStreamRandomizer.new()
	batidas.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
	for i in range(1, VARIACOES_DE_BATIDA + 1):
		batidas.add_stream(-1, load(BATIDAS % i))
	batidas.random_pitch = 1.03
	_coracao = _novo_tocador("Coracao", batidas, SILENCIO_DB)
	_volumes[CORACAO] = 0.0
	if sequencia:
		sequencia.etapa_mudou.connect(_ao_mudar_etapa)
	_tocar_musica("")
	if controle and controle.corpo:
		_ultima_posicao = controle.corpo.global_position


func _novo_tocador(nome: String, som: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var tocador := AudioStreamPlayer.new()
	tocador.name = nome
	tocador.bus = BARRAMENTO
	tocador.stream = som
	tocador.volume_db = volume_db
	add_child(tocador)
	return tocador


func _ao_mudar_etapa(nova: String) -> void:
	etapa = nova
	_tocar_musica(nova)


func _tocar_musica(de_etapa: String) -> void:
	var trilha := get_node_or_null("/root/Trilha")
	if trilha == null or not MUSICAS.has(de_etapa):
		return
	var caminho: String = MUSICAS[de_etapa]
	var fade: float = FADE_MUSICA.get(de_etapa, FADE_MUSICA_PADRAO)
	if caminho.is_empty():
		trilha.parar(fade)
	else:
		trilha.tocar(caminho, fade)


## Volume que cada camada busca agora.
func alvos() -> Dictionary:
	if etapa.is_empty():
		return alvos_explorando(_posicao())
	if etapa == "quarto_vazio":
		return alvos_quarto_vazio(_posicao())
	return ETAPAS.get(etapa, {})


## No quarto vazio, as ondas, o vento e os grilos crescem conforme Nicholas
## chega perto da varanda, para já estarem quase no volume dela ao passar pelo arco.
static func alvos_quarto_vazio(posicao: Vector3) -> Dictionary:
	var perto := perto_da_varanda(posicao)
	var alvos: Dictionary = ETAPAS["quarto_vazio"].duplicate()
	var varanda: Dictionary = ETAPAS["varanda"]
	alvos["fogo"] = lerpf(alvos["fogo"], 0.1, perto)
	alvos["ondas"] = lerpf(ONDAS_QUARTO_VAZIO, varanda["ondas"] * 0.9, perto)
	alvos["vento_mar"] = lerpf(alvos["vento_mar"], varanda["vento_mar"], perto)
	alvos["grilos"] = varanda["grilos"] * perto
	return alvos


## 0 no meio do quarto vazio, 1 no arco da varanda.
static func perto_da_varanda(posicao: Vector3) -> float:
	var distancia := Vector2(posicao.x - VARANDA.x, posicao.z - VARANDA.y).distance_to(Vector2.ZERO)
	return clampf((LONGE_DA_VARANDA - distancia) / (LONGE_DA_VARANDA - PERTO_DA_VARANDA), 0.0, 1.0)


func volume(camada: String) -> float:
	return _volumes.get(camada, 0.0)


func _process(delta: float) -> void:
	_tempo_de_cena += delta
	var alvo := alvos()
	var passo: float = RAPIDEZ.get(etapa, RAPIDEZ_PADRAO) * delta
	if etapa.is_empty() and _tempo_de_cena < ESPERA_AMBIENTE + DURACAO_ENTRADA:
		alvo = {} if _tempo_de_cena < ESPERA_AMBIENTE else alvo
		passo = RAPIDEZ_ENTRADA * delta
	for nome: String in _camadas:
		_volumes[nome] = move_toward(_volumes[nome], alvo.get(nome, 0.0), passo)
		_camadas[nome].volume_db = maxf(SILENCIO_DB, linear_to_db(_volumes[nome]))
	_volumes[CORACAO] = move_toward(_volumes[CORACAO], alvo.get(CORACAO, 0.0), passo)
	_bater_coracao(delta)
	_contar_passos()


## Toca a próxima batida quando chega a hora. O ritmo muda aos poucos e cada
## intervalo varia um pouco, como num coração de verdade.
func _bater_coracao(delta: float) -> void:
	var bpm: float = bpm_explorando(_posicao()) if etapa.is_empty() else BPM_CORACAO.get(etapa, BPM_PADRAO)
	_bpm = move_toward(_bpm, bpm, delta * 12.0)
	_ate_a_batida -= delta
	if _ate_a_batida > 0.0:
		return
	_ate_a_batida = 60.0 / maxf(_bpm, 40.0) * randf_range(0.96, 1.04)
	var volume := _volumes[CORACAO] as float
	if volume <= 0.001 or _bpm <= 0.0:
		return
	_coracao.volume_db = linear_to_db(volume * randf_range(0.85, 1.0))
	_coracao.play()


func _contar_passos() -> void:
	if controle == null or controle.corpo == null:
		return
	var corpo := controle.corpo
	var posicao := corpo.global_position
	var andou := Vector2(posicao.x - _ultima_posicao.x, posicao.z - _ultima_posicao.z).length()
	_ultima_posicao = posicao
	_ouvir_pulo(corpo, posicao)
	if andou > 1.0 or not _no_chao:
		return # troca de ponto (teleporte) ou no ar: não é passo
	_andado += andou
	var rapidez := andou / maxf(get_process_delta_time(), 0.0001)
	var passo := PASSO_CORRENDO if rapidez > (controle.velocidade + controle.velocidade_correndo) / 2.0 else PASSO
	if _andado >= passo:
		_andado = 0.0
		_passos[chao_em(posicao)].play()


## Som no impulso do pulo e quando os pés voltam ao chão.
func _ouvir_pulo(corpo: CharacterBody3D, posicao: Vector3) -> void:
	var no_chao := corpo.is_on_floor()
	if _no_chao and not no_chao and corpo.velocity.y > 0.5:
		_pulo.play()
	if not no_chao:
		_no_ar += get_process_delta_time()
	elif not _no_chao:
		if _no_ar >= TEMPO_NO_AR:
			_aterrissagens[chao_em(posicao)].play()
		_andado = 0.0
	if no_chao:
		_no_ar = 0.0
	_no_chao = no_chao


func _posicao() -> Vector3:
	return controle.corpo.global_position if controle and controle.corpo else Vector3.ZERO
