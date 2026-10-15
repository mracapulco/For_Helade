@tool
class_name PessoaPrologo
extends Node3D
## Uma pessoa do castelo no prólogo: empregada, parteira, empregado, a babá
## Janet ou a duquesa na cama. O corpo é montado por código (MalhaCorpo) e se
## mexe por juntas: tronco, cabeça, braços e, de túnica, as pernas.
##
## Quem conduz a cena (SequenciaPrologo) só troca a `atividade`, chama
## `congelar()` e vira a cabeça com `olhar_para()`.

enum Roupa { VESTIDO, TUNICA }

## O que a pessoa está fazendo. As juntas vão aos poucos até a pose dela.
const ATIVIDADES := ["parada", "trabalhando", "carregando", "segurando_bebe", "andando", "levando_roupas", "andando_com_bebe", "correndo", "deitada_parto", "deitada_exausta", "deitada_chorando", "deitada_partiu"]

@export var roupa := Roupa.VESTIDO:
	set(valor):
		roupa = valor
		_remontar()
## Altura em metros (a de referência é 1,62 m).
@export_range(1.3, 2.0, 0.01) var altura := 1.62:
	set(valor):
		altura = valor
		_remontar()
@export var cor_roupa := Color(0.42, 0.38, 0.33):
	set(valor):
		cor_roupa = valor
		_remontar()
## Alfa zero: sem avental.
@export var cor_avental := Color(0.86, 0.83, 0.76, 1.0):
	set(valor):
		cor_avental = valor
		_remontar()
@export var touca := true:
	set(valor):
		touca = valor
		_remontar()
@export var cor_cabelo := Color(0.2, 0.13, 0.08):
	set(valor):
		cor_cabelo = valor
		_remontar()
## Cabelo solto até os ombros (a duquesa); preso, sem touca, nas outras.
@export var cabelo_solto := false:
	set(valor):
		cabelo_solto = valor
		_remontar()
@export var cor_pele := Color(0.78, 0.6, 0.48):
	set(valor):
		cor_pele = valor
		_remontar()
## Mangas dobradas até o cotovelo, como as parteiras trabalham.
@export var mangas_arregacadas := false:
	set(valor):
		mangas_arregacadas = valor
		_remontar()
## Manchas de sangue representadas no avental e nas mangas (0 a 1).
## Faz parte da história, mas nunca como ferida: só manchas escuras no tecido.
@export_range(0.0, 1.0, 0.05) var sangue := 0.0:
	set(valor):
		sangue = valor
		_remontar()
## Deitada na cama: sem saia e sem pernas (o lençol cobre), tronco recostado.
@export var deitada := false:
	set(valor):
		deitada = valor
		_remontar()
@export_enum("parada", "trabalhando", "carregando", "segurando_bebe", "andando", "levando_roupas", "andando_com_bebe", "correndo", "deitada_parto", "deitada_exausta", "deitada_chorando", "deitada_partiu") var atividade := "parada"
## Roupas dobradas nos braços: as que Janet leva para a duquesa.
@export var roupas_dobradas := false:
	set(valor):
		roupas_dobradas = valor
		_remontar()
## Rapidez com que as juntas chegam a uma pose nova (maior = mais rápido).
@export var suavidade := 5.0
## Muda o ritmo de cada pessoa, para ninguém se mexer igual.
@export var semente := 0
## Palidez da pele (0 a 1): a duquesa fica "com um semblante mais pálido e
## seus lábios mais roxos" a cada empurrão.
@export_range(0.0, 1.0, 0.01) var palidez := 0.0:
	set(valor):
		palidez = valor
		_aplicar_palidez()

## Parada no tempo, como "estátuas de pedra": nenhuma junta se mexe.
var congelada := false

var esqueleto: Node3D
var quadril: Node3D
var tronco: Node3D
var pescoco: Node3D
var cabeca: Node3D
var ombros: Array[Node3D] = []
var cotovelos: Array[Node3D] = []
var pulsos: Array[Node3D] = []
var coxas: Array[Node3D] = []
var joelhos: Array[Node3D] = []
## Onde fica o que a pessoa segura (panos, bacia, roupas ou Althea).
var colo: Node3D

var _tempo := 0.0
var _material_pele: StandardMaterial3D
var _material_labios: StandardMaterial3D
var _olhar := Vector2.ZERO
var _olhar_tween: Tween
var _partida := 0.0
var _pescoco_parado := Vector3.ZERO


func _ready() -> void:
	_montar()
	_tempo = float(semente) * 1.37
	_posar(1.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or esqueleto == null:
		return
	_tempo += delta
	if congelada:
		_respirar_parada()
		return
	_posar(clampf(delta * suavidade, 0.0, 1.0))


## Para tudo na mesma hora, como quem viu o olhar da Medusa. Braços e corpo
## ficam onde estavam, mas a pessoa ainda respira e a cabeça mal se mexe:
## parada de todo, parecia um boneco (retorno do Rafael, 15/10/2026).
func congelar() -> void:
	congelada = true
	if pescoco:
		_pescoco_parado = pescoco.rotation


func _respirar_parada() -> void:
	if atividade == "deitada_partiu":
		return
	var p := _pose(atividade, _tempo)
	# Respiração presa, mais curta e mais rápida que a normal.
	var folego: float = maxf(float(p.get("folego", 0.008)), 0.006) * 0.8
	var respira := sin(_tempo * TAU * maxf(float(p.get("respiracao", 0.25)), 0.35)) * folego
	tronco.scale = Vector3(1.0 + respira * 0.5, 1.0 + respira, 1.0 + respira)
	var s := float(semente)
	pescoco.rotation = _pescoco_parado + Vector3(0.015 * sin(_tempo * 0.7 + s), 0.02 * sin(_tempo * 0.45 + s * 2.0), 0.0)


## Vai direto para a pose da atividade atual, sem transição.
func posar_agora() -> void:
	if esqueleto:
		_posar(1.0)


func descongelar() -> void:
	congelada = false


## Vira a cabeça (e um pouco o tronco) para um ponto do mundo.
func olhar_para(alvo: Vector3, tempo := 0.25) -> void:
	if cabeca == null:
		return
	var local := global_transform.affine_inverse() * alvo
	var origem := global_transform.affine_inverse() * cabeca.global_position
	var direcao := local - origem
	var giro := atan2(-direcao.x, -direcao.z)
	var inclinacao := atan2(direcao.y, Vector2(direcao.x, direcao.z).length())
	var alvo_olhar := Vector2(clampf(wrapf(giro, -PI, PI), -1.3, 1.3), clampf(inclinacao, -0.7, 0.5))
	if _olhar_tween:
		_olhar_tween.kill()
	_olhar_tween = create_tween()
	_olhar_tween.tween_method(func(v: Vector2) -> void:
		_olhar = v
		_posar_cabeca(), _olhar, alvo_olhar, maxf(tempo, 0.01))
	await _olhar_tween.finished


func soltar_olhar() -> void:
	_olhar = Vector2.ZERO


func _remontar() -> void:
	if is_inside_tree() and esqueleto:
		_montar()
		_posar(1.0)


func _montar() -> void:
	if esqueleto:
		esqueleto.free()
	ombros.clear()
	cotovelos.clear()
	pulsos.clear()
	coxas.clear()
	joelhos.clear()
	esqueleto = MalhaCorpo.junta(self, "Esqueleto")
	esqueleto.scale = Vector3.ONE * (altura / 1.62)

	var roupa_mat := MalhaCorpo.tecido(cor_roupa)
	_material_pele = MalhaCorpo.pele(cor_pele)
	_material_labios = MalhaCorpo.pele(cor_pele.darkened(0.25).lerp(Color(0.6, 0.3, 0.3), 0.3))
	var homem := roupa == Roupa.TUNICA

	quadril = MalhaCorpo.junta(esqueleto, "Quadril", Vector3(0, 0.95, 0))
	if deitada:
		quadril.position = Vector3.ZERO
	if not deitada:
		if homem:
			_pernas(roupa_mat)
			MalhaCorpo.peca(quadril, "Tunica", MalhaCorpo.anel([
				Vector4(0.02, 0.15, 0.105, 0), Vector4(-0.08, 0.17, 0.125, 0),
				Vector4(-0.3, 0.2, 0.15, 0), Vector4(-0.42, 0.21, 0.16, 0)]), roupa_mat)
		else:
			MalhaCorpo.peca(quadril, "Saia", MalhaCorpo.anel([
				Vector4(0.03, 0.14, 0.105, 0), Vector4(-0.06, 0.17, 0.135, 0),
				Vector4(-0.22, 0.21, 0.17, 0), Vector4(-0.5, 0.245, 0.21, 0),
				Vector4(-0.93, 0.29, 0.26, 0), Vector4(-0.93, 0.0, 0.0, 0)], -PI, PI, 24), roupa_mat)
			for lado in [-1, 1]:
				MalhaCorpo.peca(quadril, "Sapato", MalhaCorpo.elipsoide(Vector3(0.045, 0.035, 0.11)),
					MalhaCorpo.liso(Color(0.16, 0.11, 0.08), 0.8), Vector3(0.09 * lado, -0.925, -0.2))
		if cor_avental.a > 0.0:
			var avental := MalhaCorpo.tecido(cor_avental)
			var comprimento := -0.48 if homem else -0.82
			var aneis_avental := [Vector4(0.0, 0.15, 0.115, 0), Vector4(-0.06, 0.18, 0.145, 0)]
			if homem:
				aneis_avental.append_array([Vector4(-0.3, 0.212, 0.162, 0), Vector4(comprimento, 0.222, 0.172, 0)])
			else:
				aneis_avental.append_array([Vector4(-0.22, 0.222, 0.182, 0), Vector4(-0.5, 0.258, 0.222, 0), Vector4(comprimento, 0.29, 0.255, 0)])
			MalhaCorpo.peca(quadril, "Avental", MalhaCorpo.anel(aneis_avental, -1.15, 1.15, 12), avental)
			MalhaCorpo.peca(quadril, "Cinta", MalhaCorpo.anel([
				Vector4(0.03, 0.148, 0.112, 0), Vector4(-0.01, 0.15, 0.115, 0)]), avental)
			_manchas(quadril, comprimento)

	tronco = MalhaCorpo.junta(quadril, "Tronco")
	var busto := 0.0 if homem else 0.012
	var ombro := 0.19 if homem else 0.17
	MalhaCorpo.peca(tronco, "Corpete", MalhaCorpo.anel([
		Vector4(0.0, 0.135, 0.1, 0), Vector4(0.09, 0.13, 0.093, 0),
		Vector4(0.2, 0.15, 0.105 + busto, -busto), Vector4(0.28, ombro - 0.015, 0.105, 0),
		Vector4(0.345, ombro, 0.09, 0.01), Vector4(0.375, ombro - 0.02, 0.08, 0.012),
		Vector4(0.405, 0.1, 0.065, 0.012), Vector4(0.425, 0.05, 0.045, 0.012)]), roupa_mat)
	if cor_avental.a > 0.0 and not homem and not deitada:
		MalhaCorpo.peca(tronco, "Peitilho", MalhaCorpo.anel([
			Vector4(0.0, 0.137, 0.102, 0), Vector4(0.2, 0.152, 0.11 + busto, -busto)], -0.75, 0.75, 8),
			MalhaCorpo.tecido(cor_avental))

	pescoco = MalhaCorpo.junta(tronco, "Pescoco", Vector3(0, 0.405, 0.012))
	MalhaCorpo.peca(pescoco, "Pele", MalhaCorpo.membro(0.09, [0.043, 0.045]), _material_pele, Vector3(0, 0.09, 0))
	cabeca = MalhaCorpo.junta(pescoco, "Cabeca", Vector3(0, 0.035, 0))
	_cabeca()

	for lado in [-1, 1]:
		_braco(lado, roupa_mat, ombro)

	colo = MalhaCorpo.junta(tronco, "Colo", Vector3(0, 0.12, -0.3))
	if roupas_dobradas:
		_roupas_dobradas()
	_aplicar_palidez()


## Uma pilha de peças de linho dobradas, de cores claras e lisas.
func _roupas_dobradas() -> void:
	var pilha := MalhaCorpo.junta(colo, "RoupasDobradas", Vector3(0, -0.06, 0.04))
	var cores := [Color(0.82, 0.79, 0.72), Color(0.6, 0.64, 0.72), Color(0.9, 0.88, 0.84)]
	var y := 0.0
	for i in cores.size():
		var peca := MalhaCorpo.peca(pilha, "Peca%d" % i, BoxMesh.new(), MalhaCorpo.tecido(cores[i], 4.0),
			Vector3(0.01 * (i - 1), y + 0.022, 0.0), Vector3(0.34 - 0.02 * i, 0.044, 0.24))
		peca.rotation.y = 0.05 * (i - 1)
		y += 0.044


func _cabeca() -> void:
	var c := cabeca
	MalhaCorpo.peca(c, "Cranio", MalhaCorpo.elipsoide(Vector3(0.08, 0.108, 0.098), 20), _material_pele, Vector3(0, 0.1, 0))
	MalhaCorpo.peca(c, "Queixo", MalhaCorpo.elipsoide(Vector3(0.055, 0.05, 0.06)), _material_pele, Vector3(0, 0.035, -0.035))
	MalhaCorpo.peca(c, "Nariz", MalhaCorpo.elipsoide(Vector3(0.012, 0.024, 0.016)), _material_pele, Vector3(0, 0.09, -0.098))
	MalhaCorpo.peca(c, "Labios", MalhaCorpo.elipsoide(Vector3(0.021, 0.007, 0.008)), _material_labios, Vector3(0, 0.052, -0.088))
	var olho := MalhaCorpo.liso(Color(0.06, 0.05, 0.05), 0.3)
	var sobrancelha := MalhaCorpo.liso(cor_cabelo.darkened(0.2), 0.9)
	for lado in [-1, 1]:
		MalhaCorpo.peca(c, "Olho", MalhaCorpo.elipsoide(Vector3(0.011, 0.007, 0.006)), olho, Vector3(0.031 * lado, 0.112, -0.088))
		MalhaCorpo.peca(c, "Sobrancelha", MalhaCorpo.elipsoide(Vector3(0.017, 0.004, 0.006)), sobrancelha, Vector3(0.031 * lado, 0.128, -0.09))
		MalhaCorpo.peca(c, "Orelha", MalhaCorpo.elipsoide(Vector3(0.008, 0.026, 0.016)), _material_pele, Vector3(0.08 * lado, 0.1, 0.005))
	var cabelo := MalhaCorpo.tecido(cor_cabelo, 14.0)
	cabelo.cull_mode = BaseMaterial3D.CULL_BACK
	if touca:
		var linho := MalhaCorpo.tecido(Color(0.9, 0.88, 0.82))
		MalhaCorpo.peca(c, "Touca", MalhaCorpo.elipsoide(Vector3(0.092, 0.11, 0.1), 20), linho, Vector3(0, 0.125, 0.022))
	else:
		MalhaCorpo.peca(c, "Cabelo", MalhaCorpo.elipsoide(Vector3(0.087, 0.108, 0.097), 20), cabelo, Vector3(0, 0.118, 0.018))
		if cabelo_solto:
			MalhaCorpo.peca(c, "Mechas", MalhaCorpo.anel([
				Vector4(0.15, 0.085, 0.07, 0.03), Vector4(0.05, 0.1, 0.08, 0.04),
				Vector4(-0.1, 0.12, 0.07, 0.06), Vector4(-0.18, 0.12, 0.05, 0.07)], -2.2, 2.2, 14), cabelo)
		else:
			MalhaCorpo.peca(c, "Coque", MalhaCorpo.elipsoide(Vector3(0.05, 0.045, 0.04)), cabelo, Vector3(0, 0.13, 0.1))


func _braco(lado: int, roupa_mat: Material, largura: float) -> void:
	var ombro := MalhaCorpo.junta(tronco, "Ombro" + ("D" if lado > 0 else "E"), Vector3((largura - 0.03) * lado, 0.335, 0.012))
	MalhaCorpo.peca(ombro, "Deltoide", MalhaCorpo.elipsoide(Vector3(0.055, 0.05, 0.05)), roupa_mat, Vector3(0.005 * lado, -0.01, 0))
	MalhaCorpo.peca(ombro, "Manga", MalhaCorpo.membro(0.29, [0.05, 0.046, 0.042]), roupa_mat)
	var cotovelo := MalhaCorpo.junta(ombro, "Cotovelo", Vector3(0, -0.29, 0))
	if mangas_arregacadas:
		MalhaCorpo.peca(cotovelo, "Dobra", MalhaCorpo.membro(0.04, [0.046, 0.046]), roupa_mat, Vector3(0, 0.02, 0))
		MalhaCorpo.peca(cotovelo, "Antebraco", MalhaCorpo.membro(0.25, [0.036, 0.032, 0.025]), _material_pele)
	else:
		MalhaCorpo.peca(cotovelo, "Antebraco", MalhaCorpo.membro(0.24, [0.042, 0.04, 0.036]), roupa_mat)
		MalhaCorpo.peca(cotovelo, "Pulso", MalhaCorpo.membro(0.03, [0.025, 0.024]), _material_pele, Vector3(0, -0.23, 0))
	var pulso := MalhaCorpo.junta(cotovelo, "Pulso", Vector3(0, -0.25, 0))
	MalhaCorpo.mao(pulso, _material_pele, 0.95, false, 0.25, lado)
	if sangue > 0.0 and mangas_arregacadas:
		MalhaCorpo.peca(cotovelo, "Mancha", MalhaCorpo.elipsoide(Vector3(0.03, 0.04, 0.03)), MalhaCorpo.sangue(), Vector3(0, -0.2, -0.008))
	ombros.append(ombro)
	cotovelos.append(cotovelo)
	pulsos.append(pulso)


func _pernas(roupa_mat: Material) -> void:
	var calca := MalhaCorpo.tecido(cor_roupa.darkened(0.25))
	var sapato := MalhaCorpo.liso(Color(0.16, 0.11, 0.08), 0.8)
	for lado in [-1, 1]:
		var coxa := MalhaCorpo.junta(quadril, "Coxa" + ("D" if lado > 0 else "E"), Vector3(0.09 * lado, -0.06, 0))
		MalhaCorpo.peca(coxa, "Calca", MalhaCorpo.membro(0.43, [0.075, 0.062, 0.05]), calca)
		var joelho := MalhaCorpo.junta(coxa, "Joelho", Vector3(0, -0.43, 0))
		MalhaCorpo.peca(joelho, "Canela", MalhaCorpo.membro(0.42, [0.05, 0.045, 0.035]), calca)
		MalhaCorpo.peca(joelho, "Pe", MalhaCorpo.elipsoide(Vector3(0.045, 0.035, 0.115)), sapato, Vector3(0, -0.43, -0.06))
		coxas.append(coxa)
		joelhos.append(joelho)


## Manchas escuras representadas no avental, mais perto da barra.
func _manchas(pai: Node3D, comprimento: float) -> void:
	if sangue <= 0.0:
		return
	var aleatorio := RandomNumberGenerator.new()
	aleatorio.seed = 7 + semente
	var quantas := int(ceil(sangue * 5.0))
	for i in quantas:
		var y := lerpf(-0.15, comprimento + 0.06, aleatorio.randf())
		var t := inverse_lerp(-0.1, comprimento, y)
		var rx := lerpf(0.185, 0.25, clampf(t, 0, 1))
		var rz := lerpf(0.15, 0.225, clampf(t, 0, 1))
		var angulo := aleatorio.randf_range(-0.8, 0.8)
		var pos := Vector3(sin(angulo) * rx, y, -cos(angulo) * rz - 0.004)
		var tamanho := aleatorio.randf_range(0.025, 0.05) * (0.6 + sangue * 0.6)
		var mancha := MalhaCorpo.peca(pai, "Mancha", MalhaCorpo.elipsoide(Vector3(tamanho, tamanho * 1.3, 0.004)), MalhaCorpo.sangue(), pos)
		mancha.rotation.y = -angulo


func _aplicar_palidez() -> void:
	if _material_pele == null:
		return
	var palida := cor_pele.lerp(Color(0.8, 0.79, 0.76), 0.75)
	_material_pele.albedo_color = cor_pele.lerp(palida, palidez)
	var labios := cor_pele.darkened(0.25).lerp(Color(0.6, 0.3, 0.3), 0.3)
	_material_labios.albedo_color = labios.lerp(Color(0.42, 0.3, 0.48), palidez)


## Leva as juntas em direção à pose da atividade; `mistura` 1 chega na hora.
func _posar(mistura: float) -> void:
	var t := _tempo
	var p := _pose(atividade, t)
	quadril.position.y = lerpf(quadril.position.y, (0.0 if deitada else 0.95) + p.get("sobe", 0.0), mistura)
	quadril.rotation.x = lerp_angle(quadril.rotation.x, p.get("recosta", 0.0), mistura)
	tronco.rotation.x = lerp_angle(tronco.rotation.x, p.get("inclina", 0.0), mistura)
	tronco.rotation.z = lerp_angle(tronco.rotation.z, p.get("ginga", 0.0), mistura)
	var respira: float = sin(t * TAU * float(p.get("respiracao", 0.25))) * float(p.get("folego", 0.008))
	tronco.scale = Vector3(1.0 + respira * 0.5, 1.0 + respira, 1.0 + respira)
	for i in 2:
		var lado := -1 if i == 0 else 1
		var chave := "e" if i == 0 else "d"
		ombros[i].rotation.x = lerp_angle(ombros[i].rotation.x, p.get("ombro_" + chave, 0.05), mistura)
		ombros[i].rotation.z = lerp_angle(ombros[i].rotation.z, p.get("abre_" + chave, 0.08) * lado, mistura)
		cotovelos[i].rotation.x = lerp_angle(cotovelos[i].rotation.x, p.get("cotovelo_" + chave, 0.15), mistura)
		if i < coxas.size():
			coxas[i].rotation.x = lerp_angle(coxas[i].rotation.x, p.get("coxa_" + chave, 0.0), mistura)
			# O joelho dobra para trás.
			joelhos[i].rotation.x = lerp_angle(joelhos[i].rotation.x, -float(p.get("joelho_" + chave, 0.0)), mistura)
	pescoco.rotation.x = lerp_angle(pescoco.rotation.x, p.get("cabeca", 0.0), mistura)
	pescoco.rotation.y = lerp_angle(pescoco.rotation.y, p.get("vira", 0.0), mistura)
	pescoco.rotation.z = lerp_angle(pescoco.rotation.z, p.get("tomba", 0.0), mistura)
	_posar_cabeca()


func _posar_cabeca() -> void:
	if cabeca:
		cabeca.rotation = Vector3(_olhar.y, _olhar.x, 0.0)


## A pose de cada atividade no instante `t`, em ângulos (radianos).
func _pose(nome: String, t: float) -> Dictionary:
	var s := float(semente)
	match nome:
		"trabalhando":
			# Debruçada sobre a cama: mãos indo e vindo, panos, força.
			var a := sin(t * 3.1 + s)
			var b := sin(t * 2.3 + s * 2.0)
			return {"inclina": -0.38 + 0.06 * b, "ombro_e": 0.85 + 0.25 * a, "ombro_d": 0.75 - 0.25 * b,
				"cotovelo_e": 0.7 + 0.3 * b, "cotovelo_d": 0.85 + 0.3 * a, "abre_e": 0.0, "abre_d": 0.05,
				"cabeca": -0.35 + 0.08 * a, "vira": 0.15 * sin(t * 0.9 + s), "respiracao": 0.6, "folego": 0.014}
		"carregando":
			return {"inclina": 0.04, "ombro_e": 0.45, "ombro_d": 0.45, "cotovelo_e": 1.25, "cotovelo_d": 1.25,
				"abre_e": -0.28, "abre_d": -0.28, "cabeca": -0.1, "respiracao": 0.5, "folego": 0.012}
		"segurando_bebe":
			return {"inclina": -0.05, "ombro_e": 0.5, "ombro_d": 0.4, "cotovelo_e": 1.45, "cotovelo_d": 1.35,
				"abre_e": -0.3, "abre_d": -0.22, "cabeca": -0.3, "respiracao": 0.4, "folego": 0.01}
		"levando_roupas", "andando_com_bebe":
			# Andando sem soltar o que leva: as roupas dobradas junto ao peito
			# (Janet) ou Althea no colo (a parteira indo até Nicholas).
			var passo := _pose("andando", t)
			for chave in ["ombro_e", "ombro_d", "cotovelo_e", "cotovelo_d"]:
				passo.erase(chave)
			passo.merge(_pose("carregando" if nome == "levando_roupas" else "segurando_bebe", t))
			return passo
		"andando", "correndo":
			var correndo := nome == "correndo"
			var ritmo := 9.5 if correndo else 5.5
			var balanco := sin(t * ritmo)
			var amplo := 0.75 if correndo else 0.35
			return {"inclina": -0.18 if correndo else -0.04, "sobe": absf(sin(t * ritmo)) * (0.04 if correndo else 0.015),
				"ginga": 0.04 * balanco,
				"ombro_e": amplo * balanco, "ombro_d": -amplo * balanco,
				"cotovelo_e": 1.2 if correndo else 0.3, "cotovelo_d": 1.2 if correndo else 0.3,
				"coxa_e": -amplo * 0.9 * balanco, "coxa_d": amplo * 0.9 * balanco,
				"joelho_e": maxf(0.0, -sin(t * ritmo - 0.8)) * (1.3 if correndo else 0.6),
				"joelho_d": maxf(0.0, sin(t * ritmo - 0.8)) * (1.3 if correndo else 0.6),
				"respiracao": 1.2 if correndo else 0.4, "folego": 0.015}
		"deitada_parto":
			# Contrações: a cada poucos segundos, força e o corpo se arqueia.
			var ciclo := fmod(t + s, 4.2) / 4.2
			var forca := pow(sin(clampf(ciclo / 0.55, 0.0, 1.0) * PI), 1.5)
			return {"recosta": 1.0 - 0.22 * forca, "inclina": -0.15 * forca, "cabeca": 0.3 * forca - 0.05,
				"vira": 0.1 * sin(t * 0.7), "tomba": 0.12 * sin(t * 0.5),
				"ombro_e": 0.45 + 0.2 * forca, "ombro_d": 0.45 + 0.2 * forca, "abre_e": 0.5, "abre_d": 0.5,
				"cotovelo_e": 0.9 + 0.5 * forca, "cotovelo_d": 0.9 + 0.5 * forca,
				"respiracao": 0.9 + forca, "folego": 0.02 + 0.015 * forca}
		"deitada_exausta":
			return {"recosta": 1.05, "cabeca": -0.12, "tomba": 0.1, "ombro_e": 0.2, "ombro_d": 0.2,
				"abre_e": 0.45, "abre_d": 0.45, "cotovelo_e": 0.3, "cotovelo_d": 0.3,
				"respiracao": 0.5, "folego": 0.016}
		"deitada_chorando":
			var soluco := maxf(0.0, sin(t * 7.0)) * 0.03
			return {"recosta": 1.0, "cabeca": -0.25 + soluco, "vira": -0.25, "tomba": 0.1,
				"ombro_e": 0.35, "ombro_d": 0.35, "abre_e": 0.35, "abre_d": 0.35, "cotovelo_e": 0.6, "cotovelo_d": 0.6,
				"respiracao": 0.7, "folego": 0.022}
		"deitada_partiu":
			# A cabeça tomba de lado e a respiração para.
			return {"recosta": 1.08, "cabeca": -0.2, "vira": 0.5, "tomba": 0.3, "ombro_e": 0.1, "ombro_d": 0.0,
				"abre_e": 0.4, "abre_d": 0.75, "cotovelo_e": 0.15, "cotovelo_d": 0.05,
				"respiracao": 0.0, "folego": 0.0}
	return {"respiracao": 0.25, "folego": 0.008, "cotovelo_e": 0.15, "cotovelo_d": 0.15,
		"vira": 0.06 * sin(t * 0.4 + s)}
