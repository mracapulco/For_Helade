class_name AnimacaoPersonagem
extends AnimatedSprite2D
## Escolhe a animação do personagem da exploração (parado, andando, correndo,
## interagindo, golpe) e o lado para onde ele olha, a partir do movimento.
## As animações se chamam "acao_direcao": "frente" olha para baixo e para a
## direita, "costas" para cima e para a direita; para a esquerda, espelha.

## Personagem que este desenho acompanha. Se vazio, usa o avô (Personagem/Corpo/Visual).
@export var personagem: PersonagemExploracao

var direcao := "frente"
var interagindo := false


func _ready() -> void:
	if personagem == null:
		personagem = get_parent().get_parent() as PersonagemExploracao
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	if personagem:
		personagem.golpeou.connect(_ao_golpear)
	if sprite_frames:
		play(&"parado_frente")


func _process(_delta: float) -> void:
	if personagem == null or sprite_frames == null:
		return
	var movimento := personagem.velocity
	if movimento.length() > 1.0:
		olhar_para(movimento)
	var acao := escolher_acao(movimento.length(), personagem.velocidade, interagindo,
		personagem.golpeando)
	var nome := StringName("%s_%s" % [acao, direcao])
	if animation != nome:
		play(nome)


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


func _ao_golpear(direcao: Vector2) -> void:
	if direcao != Vector2.ZERO:
		olhar_para(direcao)
	# Recomeça do primeiro quadro mesmo se o golpe anterior acabou de terminar.
	if String(animation).begins_with("golpe"):
		frame = 0
		play()


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	var alvo := personagem.interagivel_ao_alcance() if personagem else null
	if alvo:
		olhar_para(alvo.global_position - personagem.global_position)
	interagindo = true


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	interagindo = false
