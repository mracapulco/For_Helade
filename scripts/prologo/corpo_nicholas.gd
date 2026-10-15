class_name CorpoNicholas
extends Node3D
## O corpo de Nicholas aos 5 anos, visto por ele mesmo (pedido do Rafael,
## 14/10/2026): olhando para baixo aparecem as pernas e os pés descalços; os
## braços e as mãos entram pelas bordas da tela ao andar, correr e pular, e
## seguram Althea no colo.
##
## Fica dentro do CharacterBody3D (gira junto com ele). Os braços ficam num nó
## próprio na altura dos ombros, que acompanha parte do olhar para cima e para
## baixo, e todo o olhar quando Nicholas segura Althea.
## A roupa (camisola de dormir de linho) é provisória: o livro não a descreve.

@export var controle: ControlePrimeiraPessoa
## Com Althea nos braços (a SequenciaPrologo liga).
@export var segurando := false
@export var cor_pele := Color(0.88, 0.72, 0.62)
@export var cor_camisola := Color(0.86, 0.83, 0.77)
## Quanto os braços acompanham o olhar para cima e para baixo (0 a 1).
@export_range(0.0, 1.0, 0.05) var braco_segue_olhar := 0.35

## O que o corpo está fazendo agora: parado, andando, correndo, no_ar,
## travado (no quarto da mãe) ou segurando (Althea).
var pose := "parado"

var quadril: Node3D
## A barra da camisola, que se abre para a frente com a perna que sobe.
var camisola: Node3D
var coxas: Array[Node3D] = []
var joelhos: Array[Node3D] = []
var bracos: Node3D
var ombros: Array[Node3D] = []
var cotovelos: Array[Node3D] = []
var pulsos: Array[Node3D] = []

const ALTURA_OLHOS := 1.05

var _fase := 0.0
var _rapidez := 0.0
var _ultima := Vector3.ZERO
var _queda := 0.0
var _estava_no_ar := false
var _no_ar := false


func _ready() -> void:
	_montar()
	if controle and controle.corpo:
		_ultima = controle.corpo.global_position


func _montar() -> void:
	var pele := MalhaCorpo.pele(cor_pele)
	pele.rim_enabled = false # de perto, o brilho de borda parecia plástico
	var linho := MalhaCorpo.tecido(cor_camisola, 9.0)
	# O corpo fica um pouco atrás dos olhos, para olhar para baixo e ver o peito e os pés.
	var corpo := MalhaCorpo.junta(self, "Corpo", Vector3(0, 0, 0.08))
	quadril = MalhaCorpo.junta(corpo, "Quadril", Vector3(0, 0.55, 0))
	# Do peito para cima o corpo só faz sombra: visto de dentro, ele taparia a
	# visão das pernas e dos pés.
	var peito := MalhaCorpo.peca(quadril, "Peito", MalhaCorpo.anel([
		Vector4(0.38, 0.05, 0.045, 0), Vector4(0.36, 0.1, 0.07, 0), Vector4(0.33, 0.125, 0.08, 0),
		Vector4(0.2, 0.11, 0.065, 0.0), Vector4(0.03, 0.11, 0.07, 0.0)], -PI, PI, 22), linho)
	peito.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	# Pescoço e cabeça também só fazem sombra: a câmera fica dentro deles, mas
	# sem eles a sombra no chão saía sem cabeça.
	var so_sombra: Array[MeshInstance3D] = [
		MalhaCorpo.peca(quadril, "Pescoco", MalhaCorpo.membro(0.08, [0.04, 0.04]), pele, Vector3(0, 0.45, -0.02)),
		MalhaCorpo.peca(quadril, "Cabeca", MalhaCorpo.elipsoide(Vector3(0.085, 0.1, 0.095)), pele, Vector3(0, 0.52, -0.03)),
		MalhaCorpo.peca(quadril, "Cabelo", MalhaCorpo.elipsoide(Vector3(0.09, 0.08, 0.1)), pele, Vector3(0, 0.56, -0.015)),
	]
	for peca in so_sombra:
		peca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	camisola = MalhaCorpo.peca(quadril, "Camisola", MalhaCorpo.anel([
		Vector4(0.04, 0.0, 0.0, 0.0), Vector4(0.03, 0.11, 0.07, 0.0), Vector4(-0.05, 0.12, 0.082, -0.02),
		Vector4(-0.1, 0.13, 0.092, -0.005), Vector4(-0.115, 0.13, 0.092, -0.005)], -PI, PI, 22), linho)
	for lado in [-1, 1]:
		var coxa := MalhaCorpo.junta(quadril, "Coxa" + ("D" if lado > 0 else "E"), Vector3(0.06 * lado, -0.03, 0.0))
		MalhaCorpo.peca(coxa, "Perna", MalhaCorpo.membro(0.26, [0.05, 0.042, 0.035]), pele)
		var joelho := MalhaCorpo.junta(coxa, "Joelho", Vector3(0, -0.26, 0))
		MalhaCorpo.peca(joelho, "Canela", MalhaCorpo.membro(0.24, [0.036, 0.03, 0.024]), pele)
		var pe := MalhaCorpo.junta(joelho, "Pe", Vector3(0, -0.245, 0))
		MalhaCorpo.peca(pe, "Peito", MalhaCorpo.elipsoide(Vector3(0.035, 0.022, 0.075)), pele, Vector3(0, -0.012, -0.04))
		MalhaCorpo.peca(pe, "Calcanhar", MalhaCorpo.elipsoide(Vector3(0.026, 0.025, 0.03)), pele, Vector3(0, -0.01, 0.0))
		for i in 5:
			var r := 0.009 if i > 0 else 0.012
			# O dedão (i = 0) fica do lado de dentro do pé.
			var x: float = -(0.022 - i * 0.011) * lado
			MalhaCorpo.peca(pe, "Dedo", MalhaCorpo.elipsoide(Vector3(r, r * 0.8, r * 1.3)), pele, Vector3(x, -0.022, -0.112 + absf(i - 0.5) * 0.004))
		coxas.append(coxa)
		joelhos.append(joelho)

	bracos = MalhaCorpo.junta(self, "Bracos", Vector3(0, ALTURA_OLHOS, 0))
	for lado in [-1, 1]:
		var ombro := MalhaCorpo.junta(bracos, "Ombro" + ("D" if lado > 0 else "E"), Vector3(0.13 * lado, -0.16, 0.02))
		# A manga afina até o braço, sem borda que pareça um corte.
		MalhaCorpo.peca(ombro, "Manga", MalhaCorpo.membro(0.13, [0.045, 0.041, 0.036, 0.031]), linho)
		MalhaCorpo.peca(ombro, "Braco", MalhaCorpo.membro(0.2, [0.032, 0.028, 0.025]), pele, Vector3(0, -0.02, 0))
		# Braços um pouco mais longos que os de uma criança: na primeira pessoa,
		# senão as mãos nunca chegam à tela.
		var cotovelo := MalhaCorpo.junta(ombro, "Cotovelo", Vector3(0, -0.2, 0))
		MalhaCorpo.peca(cotovelo, "Antebraco", MalhaCorpo.membro(0.185, [0.026, 0.023, 0.02]), pele)
		var pulso := MalhaCorpo.junta(cotovelo, "Pulso", Vector3(0, -0.18, 0))
		# Dedos meio dobrados, como uma mão solta de criança.
		var mao := MalhaCorpo.mao(pulso, pele, 0.68, true, 0.6, lado)
		# Mão de criança: palma mais cheia, começando já no pulso, e o polegar
		# junto da palma (aberto, de cima ele parecia um espinho).
		var palma: Node3D = mao.get_node("Palma")
		palma.scale.z *= 1.5
		palma.position.y += 0.008
		(mao.get_node("Polegar") as Node3D).rotation = Vector3(0.35, 0.0, 0.18 * lado)
		ombros.append(ombro)
		cotovelos.append(cotovelo)
		pulsos.append(pulso)


## A rapidez é medida no passo da física, que é quando o corpo anda: medida a
## cada quadro, num monitor rápido ela pularia entre zero e o dobro.
func _physics_process(delta: float) -> void:
	if controle == null or controle.corpo == null:
		return
	var corpo := controle.corpo
	var posicao := corpo.global_position
	var andou := Vector2(posicao.x - _ultima.x, posicao.z - _ultima.z).length()
	_ultima = posicao
	var rapidez := andou / maxf(delta, 0.0001)
	if rapidez > 8.0:
		rapidez = 0.0 # troca de ponto, não passo
	_rapidez = lerpf(_rapidez, rapidez, clampf(delta * 8.0, 0.0, 1.0))
	_no_ar = not corpo.is_on_floor() and absf(corpo.velocity.y) > 0.3


func _process(delta: float) -> void:
	if controle == null or controle.corpo == null:
		return
	_fase = fmod(_fase + _rapidez / 0.32 * PI * delta, TAU)
	if _estava_no_ar and not _no_ar:
		_queda = 1.0 # aterrissou: dobra os joelhos um instante
	_estava_no_ar = _no_ar
	_queda = maxf(_queda - delta * 4.0, 0.0)
	pose = _escolher_pose(_no_ar)
	_posar(clampf(delta * 10.0, 0.0, 1.0))


## Onde ficam cotovelo e pulso segurando Althea (no espaço dos ombros, que
## segue o olhar): os antebraços passam por baixo do pano, um sob a cabeça.
const COLO := [
	{"cotovelo": Vector3(-0.22, -0.32, -0.16), "pulso": Vector3(-0.17, -0.27, -0.42)},
	{"cotovelo": Vector3(0.23, -0.33, -0.14), "pulso": Vector3(0.2, -0.28, -0.4)},
]


## Aponta braço e antebraço de um lado para segurar Althea no colo.
func _aninhar(i: int, mistura: float) -> void:
	var ombro := ombros[i]
	var alvo: Dictionary = COLO[i]
	var para_cotovelo: Vector3 = alvo["cotovelo"] - ombro.position
	ombro.basis = ombro.basis.slerp(_apontando(para_cotovelo), mistura).orthonormalized()
	var cotovelo := cotovelos[i]
	var pulso_no_ombro: Vector3 = ombro.basis.inverse() * (alvo["pulso"] - ombro.position)
	cotovelo.basis = cotovelo.basis.slerp(_apontando(pulso_no_ombro - cotovelo.position), mistura).orthonormalized()


## Uma base cujo -Y (o osso) aponta para `direcao`, com a palma para dentro.
static func _apontando(direcao: Vector3) -> Basis:
	var y := -direcao.normalized()
	var referencia := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.UP
	var x := y.cross(referencia).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


func _escolher_pose(no_ar: bool) -> String:
	if segurando:
		return "segurando"
	if no_ar:
		return "no_ar"
	if controle.travado and _rapidez < 0.2:
		return "travado"
	if _rapidez > controle.velocidade * 1.3:
		return "correndo"
	if _rapidez > 0.2:
		return "andando"
	return "parado"


func _posar(mistura: float) -> void:
	var balanco := sin(_fase)
	var p := {}
	match pose:
		"andando", "correndo":
			var forte := pose == "correndo"
			# Balanço contido: em primeira pessoa, braços altos demais passavam
			# na frente do rosto e as pernas subiam até a câmera.
			var amplo := 0.55 if forte else 0.35
			p = {"coxa_e": -amplo * balanco, "coxa_d": amplo * balanco,
				"joelho_e": maxf(0.0, -sin(_fase - 0.8)) * (0.95 if forte else 0.55),
				"joelho_d": maxf(0.0, sin(_fase - 0.8)) * (0.95 if forte else 0.55),
				"ombro_e": (0.5 if forte else 0.3) * balanco + (0.1 if forte else 0.05),
				"ombro_d": -(0.5 if forte else 0.3) * balanco + (0.1 if forte else 0.05),
				"cotovelo_e": 0.95 if forte else 0.4, "cotovelo_d": 0.95 if forte else 0.4,
				"abre_e": 0.12, "abre_d": 0.12}
		"no_ar":
			# Braços abertos para os lados, para o equilíbrio, e joelhos dobrados.
			p = {"coxa_e": 0.45, "coxa_d": 0.3, "joelho_e": 0.85, "joelho_d": 0.7,
				"ombro_e": 0.45, "ombro_d": 0.4, "abre_e": 0.75, "abre_d": 0.75, "cotovelo_e": 0.45, "cotovelo_d": 0.5}
		"travado":
			# "Eu congelei": braços colados ao corpo, mãos fechadas.
			p = {"ombro_e": 0.02, "ombro_d": 0.02, "abre_e": 0.03, "abre_d": 0.03, "cotovelo_e": 0.2, "cotovelo_d": 0.2}
		"segurando":
			p = {}
			if _rapidez > 0.2:
				p["coxa_e"] = -0.5 * balanco
				p["coxa_d"] = 0.5 * balanco
				p["joelho_e"] = maxf(0.0, -sin(_fase - 0.8)) * 0.9
				p["joelho_d"] = maxf(0.0, sin(_fase - 0.8)) * 0.9
		_:
			# Pés um pouco à frente, para aparecerem além da barra da camisola.
			p = {"coxa_e": 0.16, "coxa_d": 0.16, "joelho_e": 0.1, "joelho_d": 0.1,
				"ombro_e": 0.06, "ombro_d": 0.06, "abre_e": 0.08, "abre_d": 0.08, "cotovelo_e": 0.15, "cotovelo_d": 0.15}
	quadril.position.y = 0.55 - 0.06 * _queda
	# A perna da frente empurra o pano: sem isso, a coxa atravessava a camisola.
	var perna_a_frente := maxf(maxf(float(p.get("coxa_e", 0.0)), float(p.get("coxa_d", 0.0))) + 0.5 * _queda, 0.0)
	camisola.rotation.x = lerp_angle(camisola.rotation.x, perna_a_frente * 0.75, mistura)
	for i in 2:
		var lado := -1 if i == 0 else 1
		var chave := "e" if i == 0 else "d"
		coxas[i].rotation.x = lerp_angle(coxas[i].rotation.x, float(p.get("coxa_" + chave, 0.0)) + 0.5 * _queda, mistura)
		joelhos[i].rotation.x = lerp_angle(joelhos[i].rotation.x, -float(p.get("joelho_" + chave, 0.0)) - 1.0 * _queda, mistura)
		if pose == "segurando":
			_aninhar(i, mistura)
			continue
		var alvo_ombro := Basis.from_euler(Vector3(float(p.get("ombro_" + chave, 0.06)), 0.0, float(p.get("abre_" + chave, 0.08)) * lado))
		ombros[i].basis = ombros[i].basis.slerp(alvo_ombro, mistura)
		var alvo_cotovelo := Basis.from_euler(Vector3(float(p.get("cotovelo_" + chave, 0.15)), 0.0, 0.0))
		cotovelos[i].basis = cotovelos[i].basis.slerp(alvo_cotovelo, mistura)
	# Olhando para baixo, os braços seguirem o olhar os jogava para trás do corpo.
	var segue := 1.0 if pose == "segurando" else (braco_segue_olhar if controle.camera and controle.camera.rotation.x > 0.0 else 0.0)
	if controle.camera:
		bracos.rotation.x = lerp_angle(bracos.rotation.x, controle.camera.rotation.x * segue, mistura)
		bracos.position.y = controle.camera.position.y
