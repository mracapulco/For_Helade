class_name AnimacaoPersonagem
extends AnimatedSprite2D
## Escolhe a animação do personagem da exploração (parado, andando, correndo,
## interagindo, golpe) e o lado para onde ele olha, a partir do movimento.
## Na esquiva, um passo rápido e baixo: agacha, avança inclinado para o lado
## da esquiva e se endireita, deixando um rastro de vultos (Rafael, 23/10: a
## cambalhota "parecia um ninja"). Uma animação "esquiva_direcao" na folha,
## quando houver arte própria, toca no lugar do quadro de correr.
## As animações se chamam "acao_direcao": "frente" olha para baixo e para a
## direita, "costas" para cima e para a direita; para a esquerda, espelha.

const AparenciaNicholas := preload("res://scripts/systems/aparencia_nicholas.gd")

## Personagem que este desenho acompanha. Se vazio, usa o avô (Personagem/Corpo/Visual).
@export var personagem: PersonagemExploracao
## Desenha Nicholas na idade atual da história ([member Inventario.faixa_etaria])
## em vez dos quadros postos na cena, e acompanha quando ela muda.
@export var nicholas_pela_idade := false

## Fração da esquiva em que ele abaixa, antes de avançar.
const AGACHAR := 0.15
## Fração da esquiva a partir da qual ele já está se endireitando.
const LEVANTAR := 0.8
## Quanto ele se inclina para a frente no passo, em radianos (uns 14°).
const INCLINACAO := 0.25
## Tempo entre um vulto e outro do rastro.
const INTERVALO_VULTO := 0.04
## Quanto um vulto leva para sumir.
const DURACAO_VULTO := 0.2
## Cor dos vultos: azul claro, como os olhos dos Abençoados.
const COR_VULTO := Color(0.7, 0.85, 1.0, 0.5)
const GRUPO_VULTO := &"vulto_esquiva"

var direcao := "frente"
var interagindo := false
## Ação posta por fora (ex.: "empurrando", "puxando"): vale no lugar da que
## viria do movimento enquanto não for vazia e a folha tiver a animação.
var acao_forcada := ""
## Na pose da esquiva agora (o desenho está inclinado ou abaixado).
var esquivando := false
var _ate_o_vulto := 0.0


func _ready() -> void:
	if personagem == null:
		personagem = get_parent().get_parent() as PersonagemExploracao
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	if personagem:
		personagem.golpeou.connect(_ao_golpear)
		personagem.esquivou.connect(_ao_esquivar)
	if nicholas_pela_idade:
		sprite_frames = AparenciaNicholas.quadros_atuais()
		Inventario.faixa_etaria_mudou.connect(_ao_mudar_idade)
	if sprite_frames:
		play(&"parado_frente")


func _process(delta: float) -> void:
	if personagem == null or sprite_frames == null:
		return
	var movimento := personagem.velocity
	# Vira para onde o personagem olha (a última direção em que andou), que
	# é também para onde o golpe sai.
	olhar_para(personagem.direcao_olhar)
	# Subindo na tela ele anda mais devagar (fator_vertical): compara com a
	# velocidade daquela direção para saber se está correndo.
	var rapidez := movimento.length() / personagem.fator_da_direcao(movimento)
	var acao := escolher_acao(rapidez, personagem.velocidade_andando(), interagindo,
		personagem.golpeando)
	var progresso := personagem.progresso_esquiva()
	if progresso >= 0.0:
		acao = "esquiva" if sprite_frames.has_animation(StringName("esquiva_%s" % direcao)) else "correndo"
	# O equipamento acelera ou atrasa o passo e o golpe.
	speed_scale = personagem.ritmo() if personagem.golpeando else personagem.ritmo_andar()
	if acao_forcada != "" and sprite_frames.has_animation(StringName("%s_%s" % [acao_forcada, direcao])):
		acao = acao_forcada
		speed_scale = 1.0
	var nome := StringName("%s_%s" % [acao, direcao])
	if not sprite_frames.has_animation(nome):
		# Desenhos sem golpe (os outros personagens) usam o de interagir.
		nome = StringName("interagindo_%s" % direcao)
	if animation != nome:
		play(nome)
	if progresso >= 0.0:
		pose_esquiva(progresso)
		_ate_o_vulto -= delta
		if _ate_o_vulto <= 0.0:
			_ate_o_vulto = INTERVALO_VULTO
			deixar_vulto()
	elif esquivando:
		_sair_da_esquiva()


## Vira o desenho para a direção `vetor` (em coordenadas do mundo).
func olhar_para(vetor: Vector2) -> void:
	direcao = nome_direcao(vetor)
	flip_h = vetor.x < 0.0


static func nome_direcao(vetor: Vector2) -> String:
	return "costas" if vetor.y < 0.0 else "frente"


## Correr é andar mais rápido que a velocidade normal (com folga).
static func escolher_acao(rapidez: float, velocidade_normal: float, em_interacao: bool,
		golpeando := false) -> String:
	if golpeando:
		return "golpe"
	if em_interacao:
		return "interagindo"
	if rapidez > velocidade_normal * 1.2:
		return "correndo"
	if rapidez > 1.0:
		return "andando"
	return "parado"


func _ao_golpear() -> void:
	# Recomeça do primeiro quadro mesmo se o golpe anterior acabou de terminar.
	if String(animation).begins_with("golpe"):
		frame = 0
		play()


## Escala e inclinação do desenho no ponto [param progresso] (0 a 1) da
## esquiva: abaixa, avança inclinado e se endireita. [param lado] é 1 indo
## para a direita (inclina para a direita) e -1 para a esquerda.
static func pose_da_esquiva(progresso: float, lado := 1.0) -> Dictionary:
	var baixo := Vector2(1.1, 0.8)
	if progresso < AGACHAR:
		var a := progresso / AGACHAR
		return {"escala": Vector2.ONE.lerp(baixo, a), "giro": INCLINACAO * lado * a}
	if progresso < LEVANTAR:
		return {"escala": baixo, "giro": INCLINACAO * lado}
	var b := ease((progresso - LEVANTAR) / (1.0 - LEVANTAR), 0.5)
	return {"escala": baixo.lerp(Vector2.ONE, b), "giro": INCLINACAO * lado * (1.0 - b)}


## Põe o desenho na pose da esquiva. Inclina e abaixa a partir dos pés, que
## ficam no chão, e leva junto a espada e o escudo (filhos do desenho).
func pose_esquiva(progresso: float) -> void:
	var rumo := personagem.rumo_esquiva()
	var lado := 1.0 if (rumo.x > 0.01 or (absf(rumo.x) <= 0.01 and not flip_h)) else -1.0
	var pose := pose_da_esquiva(progresso, lado)
	esquivando = true
	rotation = pose.giro
	scale = pose.escala


func _sair_da_esquiva() -> void:
	esquivando = false
	rotation = 0.0
	scale = Vector2.ONE
	_ate_o_vulto = 0.0


## Deixa no chão um vulto azulado do quadro de agora, que some logo.
func deixar_vulto() -> Sprite2D:
	var lugar := personagem.get_parent() if personagem else null
	if lugar == null or sprite_frames == null:
		return null
	var vulto := Sprite2D.new()
	vulto.add_to_group(GRUPO_VULTO)
	vulto.texture = sprite_frames.get_frame_texture(animation, frame)
	vulto.offset = offset
	vulto.flip_h = flip_h
	vulto.centered = centered
	vulto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vulto.modulate = COR_VULTO
	lugar.add_child(vulto)
	vulto.global_transform = global_transform
	var tween := vulto.create_tween()
	tween.tween_property(vulto, "modulate:a", 0.0, DURACAO_VULTO)
	tween.tween_callback(vulto.queue_free)
	return vulto


func _ao_esquivar() -> void:
	_ate_o_vulto = 0.0


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	var alvo := personagem.interagivel_ao_alcance() if personagem else null
	if alvo:
		olhar_para(alvo.global_position - personagem.global_position)
		personagem.direcao_olhar = personagem.global_position.direction_to(alvo.global_position)
	interagindo = true


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	interagindo = false


func _ao_mudar_idade(faixa: int) -> void:
	sprite_frames = AparenciaNicholas.quadros(faixa)
