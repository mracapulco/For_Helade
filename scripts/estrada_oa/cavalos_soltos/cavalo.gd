class_name Cavalo
extends CharacterBody2D
## Cavalo solto do comboio, na fase "Cavalos soltos" (estrada Atenas–Olympia,
## olivais da saída de Atenas). Nicholas o conduz ao cercado sem encostar
## nele. Cada cavalo tem um [member jeito] (inferência, aprovada no
## brainstorm de 26/10/2026):
## - ASSUSTADO: foge de Nicholas na direção oposta. Andando, ele assusta de
##   perto e o cavalo foge devagar; correndo (Shift), assusta de mais longe e
##   o cavalo dispara.
## - TEIMOSO: o mesmo, mas de frente ele finca as patas e bufa; só anda se
##   Nicholas der a volta e chegar pelo lado ou por trás.
## - GULOSO: não foge. Segue Nicholas enquanto ele tem uma fruta na mão
##   ([FrutaNaMao]) e vai comer a fruta que estiver no chão ([FrutaNoChao]).
## Sozinho, ele pasta e dá uns passos à toa. Dentro do cercado
## ([method prender]), fica calmo e não sai mais.
## O desenho é uma folha de 4 quadros: parado, pastando, passo A e passo B,
## virado para a direita.

signal preso

enum Jeito { ASSUSTADO, TEIMOSO, GULOSO }
enum Estado { PASTANDO, PASSEANDO, FUGINDO, FIRME, SEGUINDO, INDO_COMER, COMENDO, NO_CERCADO }

const QUADRO_PARADO := 0
const QUADRO_PASTANDO := 1
const QUADRO_PASSO := 2
const TEMPO_PASSO := 0.16
const RAIO_CORPO := 9.0

@export var jeito := Jeito.ASSUSTADO
## Folha de 4 quadros (tools/arte/gerar_estrada_oa_cavalos.py).
@export var quadros: Texture2D

@export_group("Fuga")
## Distância em que Nicholas andando assusta, e correndo.
@export var raio_medo := 70.0
@export var raio_medo_correndo := 120.0
## Velocidade da fuga quando ele chega andando, e correndo.
@export var velocidade_fuga := 50.0
@export var velocidade_fuga_correndo := 85.0
## Teimoso: metade do ângulo à frente dele em que finca as patas, em graus.
@export var angulo_firme := 60.0

@export_group("Fruta")
## Até onde o guloso sente a fruta na mão de Nicholas, e a fruta no chão.
@export var raio_cheiro := 150.0
@export var raio_fruta_no_chao := 200.0
## O guloso para a esta distância de Nicholas.
@export var distancia_seguir := 30.0
@export var velocidade_seguir := 60.0
@export var tempo_comendo := 1.5

@export_group("Sozinho")
@export var velocidade_passeio := 14.0

var estado := Estado.PASTANDO
## Para onde ele olha (só esquerda ou direita, como o desenho).
var olhar := Vector2.RIGHT
var jogador: PersonagemExploracao
var visual: Sprite2D
## Fruta que o guloso está indo comer (ou comendo).
var fruta_alvo: FrutaNoChao
## Sorteio dos passeios; os testes fixam a semente.
var sorte := RandomNumberGenerator.new()

var _tempo_estado := 0.0
var _duracao_estado := 2.0
var _rumo_passeio := Vector2.ZERO
var _tempo_quadro := 0.0
var _bufo: Tween
## No cercado, ele vai até aqui e fica (para não parar na porteira).
var _lugar_no_cercado := Vector2.INF


func _init() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	visual = Sprite2D.new()
	visual.name = "Visual"
	visual.hframes = 4
	add_child(visual)
	var colisao := CollisionShape2D.new()
	colisao.name = "Colisao"
	var forma := CircleShape2D.new()
	forma.radius = RAIO_CORPO
	colisao.shape = forma
	add_child(colisao)


func _ready() -> void:
	if quadros:
		visual.texture = quadros
		# Os pés (a base da folha, menos a sombra) ficam na origem.
		visual.offset = Vector2(0, -quadros.get_height() / 2.0 + 3)
	if jogador == null:
		jogador = get_tree().get_first_node_in_group(Interagivel.GRUPO_JOGADOR) as PersonagemExploracao
	_duracao_estado = sorte.randf_range(1.0, 3.0)


func _physics_process(delta: float) -> void:
	_tempo_estado += delta
	var desejada := Vector2.ZERO
	if estado == Estado.NO_CERCADO:
		desejada = _ir_para_o_lugar()
	elif jogador == null:
		desejada = _sozinho()
	elif jeito == Jeito.GULOSO:
		desejada = _guloso(delta)
	else:
		desejada = _arisco()
	velocity = velocity.move_toward(desejada, 400.0 * delta)
	if velocity.length() > 0.5:
		move_and_slide()
	if absf(velocity.x) > 2.0:
		olhar = Vector2(signf(velocity.x), 0)
	_animar(delta)


## Dentro do cercado: calmo, não foge nem segue mais ninguém. Com
## [param lugar] (posição na sala), ainda anda até lá, sem pressa.
func prender(lugar := Vector2.INF) -> void:
	if estado == Estado.NO_CERCADO:
		return
	_lugar_no_cercado = lugar
	if estado == Estado.COMENDO and is_instance_valid(fruta_alvo):
		fruta_alvo.sumir()
	fruta_alvo = null
	_mudar(Estado.NO_CERCADO)
	velocity = Vector2.ZERO
	preso.emit()


func esta_preso() -> bool:
	return estado == Estado.NO_CERCADO


## Nicholas está correndo (Shift e se movendo).
func jogador_correndo() -> bool:
	return jogador != null and Input.is_action_pressed(&"correr") and jogador.velocity.length() > 5.0


## Distância em que Nicholas assusta agora.
func raio_de_medo() -> float:
	return raio_medo_correndo if jogador_correndo() else raio_medo


## O ponto [param ponto] está na frente dele (no ângulo em que o teimoso
## finca as patas).
func de_frente_para(ponto: Vector2) -> bool:
	var para_o_ponto := ponto - global_position
	if para_o_ponto.length() < 0.001:
		return false
	return absf(olhar.angle_to(para_o_ponto)) < deg_to_rad(angulo_firme)


func _ir_para_o_lugar() -> Vector2:
	if _lugar_no_cercado == Vector2.INF:
		return Vector2.ZERO
	var falta := _lugar_no_cercado - position
	if falta.length() < 3.0:
		_lugar_no_cercado = Vector2.INF
		return Vector2.ZERO
	return falta.normalized() * velocidade_passeio * 2.0


# --- assustado e teimoso ---------------------------------------------------
func _arisco() -> Vector2:
	var de_nicholas := global_position - jogador.global_position
	var distancia := de_nicholas.length()
	var raio := raio_de_medo()
	if distancia >= raio:
		return _sozinho()
	if jeito == Jeito.TEIMOSO and de_frente_para(jogador.global_position):
		if estado != Estado.FIRME:
			_mudar(Estado.FIRME)
			_bufar()
		return Vector2.ZERO
	_mudar(Estado.FUGINDO)
	var rapidez := velocidade_fuga_correndo if jogador_correndo() else velocidade_fuga
	# Quanto mais perto, mais rápido (até 50% a mais).
	rapidez *= 1.0 + 0.5 * (1.0 - distancia / raio)
	var rumo := de_nicholas.normalized() if distancia > 0.001 else olhar
	return Vector2(rumo.x, rumo.y * 0.7) * rapidez


# --- guloso -----------------------------------------------------------------
func _guloso(_delta: float) -> Vector2:
	if estado == Estado.COMENDO:
		if not is_instance_valid(fruta_alvo):
			fruta_alvo = null
			_mudar(Estado.PASTANDO)
		elif _tempo_estado >= tempo_comendo:
			fruta_alvo.sumir()
			fruta_alvo = null
			_mudar(Estado.PASTANDO)
		return Vector2.ZERO
	var fruta := fruta_mais_perto()
	if fruta:
		fruta_alvo = fruta
		var ate_a_fruta := fruta.global_position - global_position
		if ate_a_fruta.length() <= 8.0:
			_mudar(Estado.COMENDO)
			return Vector2.ZERO
		_mudar(Estado.INDO_COMER)
		return ate_a_fruta.normalized() * velocidade_seguir
	fruta_alvo = null
	var ate_nicholas := jogador.global_position - global_position
	if FrutaNaMao.segurando_fruta() and not jogador.em_dialogo and ate_nicholas.length() < raio_cheiro:
		_mudar(Estado.SEGUINDO)
		var sobra := ate_nicholas.length() - distancia_seguir
		if sobra <= 0.0:
			return Vector2.ZERO
		return ate_nicholas.normalized() * velocidade_seguir * clampf(sobra / 40.0, 0.3, 1.0)
	return _sozinho()


## A fruta no chão mais perto, ao alcance do faro, ou null.
func fruta_mais_perto() -> FrutaNoChao:
	var melhor: FrutaNoChao = null
	var menor := raio_fruta_no_chao
	for no in get_tree().get_nodes_in_group(FrutaNoChao.GRUPO):
		var fruta := no as FrutaNoChao
		if fruta == null or not fruta.pousada:
			continue
		var distancia := global_position.distance_to(fruta.global_position)
		if distancia < menor:
			melhor = fruta
			menor = distancia
	return melhor


# --- sozinho: pasta e passeia ---------------------------------------------
func _sozinho() -> Vector2:
	if estado != Estado.PASTANDO and estado != Estado.PASSEANDO:
		_mudar(Estado.PASTANDO)
		_duracao_estado = sorte.randf_range(1.0, 2.5)
	if _tempo_estado >= _duracao_estado:
		if estado == Estado.PASTANDO:
			_mudar(Estado.PASSEANDO)
			_rumo_passeio = Vector2.from_angle(sorte.randf() * TAU)
			_duracao_estado = sorte.randf_range(0.8, 1.6)
		else:
			_mudar(Estado.PASTANDO)
			_duracao_estado = sorte.randf_range(1.5, 3.5)
	if estado == Estado.PASSEANDO:
		return Vector2(_rumo_passeio.x, _rumo_passeio.y * 0.7) * velocidade_passeio
	return Vector2.ZERO


func _mudar(novo: Estado) -> void:
	if novo == estado:
		return
	estado = novo
	_tempo_estado = 0.0


## Teimoso de frente: bufa e bate a pata (uma tremidinha no desenho).
func _bufar() -> void:
	if _bufo and _bufo.is_valid():
		return
	_bufo = create_tween()
	for i in 3:
		_bufo.tween_property(visual, "position:x", 1.5 if i % 2 == 0 else -1.5, 0.05)
	_bufo.tween_property(visual, "position:x", 0.0, 0.05)


func _animar(delta: float) -> void:
	visual.flip_h = olhar.x < 0.0
	if velocity.length() > 3.0:
		_tempo_quadro += delta * clampf(velocity.length() / 40.0, 0.5, 2.0)
		if _tempo_quadro >= TEMPO_PASSO:
			_tempo_quadro = 0.0
			visual.frame = QUADRO_PASSO + 1 if visual.frame == QUADRO_PASSO else QUADRO_PASSO
		return
	var pastando := estado in [Estado.PASTANDO, Estado.COMENDO, Estado.NO_CERCADO]
	visual.frame = QUADRO_PASTANDO if pastando else QUADRO_PARADO
