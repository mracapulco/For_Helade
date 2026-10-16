@tool
class_name DuquesaNaCama
extends Node3D
## A duquesa Neola na cama, durante o parto de Althea.
## Decisão do Rafael (14/10/2026): ela aparece, sem gore e sem nada 18+; o
## sangue aparece representado (manchas escuras no lençol), porque faz parte
## da história.
##
## O nó fica no quadril dela, em cima do colchão. Para a frente (-Z) ficam os
## pés, para trás (+Z) os travesseiros.
## A SequenciaPrologo chama `mudar_etapa()` a cada batida.

## Cabelo e pele: o livro não descreve a duquesa. Provisórios até a autora dizer.
@export var cor_cabelo := Color(0.17, 0.11, 0.07)
@export var cor_pele := Color(0.8, 0.63, 0.52)
## Quanto o lençol tem de sangue representado (0 a 1).
@export_range(0.0, 1.0, 0.05) var sangue := 0.95
## Segundos entre o choro e a partida (multiplicados pela escala de tempo).
@export var tempo_ate_partir := 3.0

var pessoa: PessoaPrologo
var lencol: MeshInstance3D
## Etapa da cena em que ela está (as mesmas da SequenciaPrologo).
var etapa := ""
## Ela já partiu: não respira nem se mexe mais.
var partiu := false

## Pernas dobradas sob o lençol: segmentos (de, até, raio), em metros.
const PERNAS := [
	[Vector3(-0.1, 0.09, 0.0), Vector3(-0.15, 0.4, -0.42), 0.085],
	[Vector3(0.1, 0.09, 0.0), Vector3(0.15, 0.4, -0.42), 0.085],
	[Vector3(-0.15, 0.4, -0.42), Vector3(-0.19, 0.07, -0.82), 0.06],
	[Vector3(0.15, 0.4, -0.42), Vector3(0.19, 0.07, -0.82), 0.06],
	[Vector3(0.0, 0.1, 0.05), Vector3(0.0, 0.12, -0.1), 0.17],
]
## Lençol: de onde a onde (x de um lado ao outro, z dos pés à cintura).
const LENCOL_X := 1.2
const LENCOL_Z_PES := -1.5
const LENCOL_Z_CINTURA := 0.12
const PASSOS_X := 30
const PASSOS_Z := 36

var _escala_tempo := 1.0


func _ready() -> void:
	_montar()


func _montar() -> void:
	for filho in get_children():
		filho.free()
	_travesseiros()
	pessoa = PessoaPrologo.new()
	pessoa.name = "Neola"
	pessoa.deitada = true
	pessoa.touca = false
	pessoa.cabelo_solto = true
	pessoa.cor_cabelo = cor_cabelo
	pessoa.cor_pele = cor_pele
	pessoa.cor_roupa = Color(0.88, 0.86, 0.8)
	pessoa.cor_avental = Color(0, 0, 0, 0)
	pessoa.atividade = "deitada_parto"
	pessoa.palidez = 0.2
	pessoa.suavidade = 3.0
	add_child(pessoa)
	lencol = MeshInstance3D.new()
	lencol.name = "Lencol"
	lencol.mesh = _malha_lencol()
	var material := MalhaCorpo.tecido(Color(0.93, 0.91, 0.87), 5.0).duplicate()
	material.vertex_color_use_as_albedo = true
	lencol.material_override = material
	add_child(lencol)


## A duquesa recostada: travesseiros empilhados atrás das costas.
func _travesseiros() -> void:
	var linho := MalhaCorpo.tecido(Color(0.92, 0.9, 0.86), 5.0)
	var pilha := Node3D.new()
	pilha.name = "Travesseiros"
	add_child(pilha)
	for dados in [[Vector3(0, 0.1, 0.42), Vector3(0.42, 0.12, 0.3), 0.0], [Vector3(0, 0.25, 0.6), Vector3(0.4, 0.11, 0.26), -0.7]]:
		var t := MalhaCorpo.peca(pilha, "Travesseiro", MalhaCorpo.elipsoide(dados[1]), linho, dados[0])
		t.rotation.x = dados[2]


## O quanto a pessoa precisa ficar parada, das etapas da SequenciaPrologo.
func mudar_etapa(nova: String, escala_tempo := 1.0) -> void:
	etapa = nova
	_escala_tempo = escala_tempo
	if pessoa == null:
		return
	match nova:
		"caos":
			pessoa.atividade = "deitada_parto"
			_palidez(0.55, 8.0)
		"dossel":
			pessoa.atividade = "deitada_parto"
			_palidez(0.75, 6.0)
		"muda":
			pessoa.atividade = "deitada_exausta"
			pessoa.congelar()
		"olhares":
			pessoa.descongelar()
			pessoa.atividade = "deitada_exausta"
		"choro":
			pessoa.atividade = "deitada_chorando"
			_partir()
		"depois", "quarto_vazio":
			# "Com um grande cuidado e respeito a levaram de lá."
			visible = false


func _partir() -> void:
	await get_tree().create_timer(tempo_ate_partir * _escala_tempo).timeout
	if etapa != "choro" or partiu:
		return
	partiu = true
	pessoa.suavidade = 0.8
	pessoa.atividade = "deitada_partiu"
	_palidez(1.0, 4.0)


func _palidez(alvo: float, segundos: float) -> void:
	var tween := create_tween()
	tween.tween_property(pessoa, "palidez", maxf(alvo, pessoa.palidez), maxf(segundos * _escala_tempo, 0.01))


## Altura do corpo sob o lençol em (x, z), sem contar o caimento do pano.
func _altura_corpo(x: float, z: float) -> float:
	var topo := 0.0
	for perna: Array in PERNAS:
		var a: Vector3 = perna[0]
		var b: Vector3 = perna[1]
		var raio: float = perna[2]
		for i in 13:
			var c := a.lerp(b, i / 12.0)
			var d2 := (x - c.x) * (x - c.x) + (z - c.z) * (z - c.z)
			if d2 < raio * raio:
				topo = maxf(topo, c.y + sqrt(raio * raio - d2))
	return topo


func _malha_lencol() -> ArrayMesh:
	var alturas := []
	var largura := LENCOL_X * 2.0
	var fundo := LENCOL_Z_CINTURA - LENCOL_Z_PES
	for iz in PASSOS_Z + 1:
		var linha := []
		for ix in PASSOS_X + 1:
			var x := -LENCOL_X + largura * ix / PASSOS_X
			var z := LENCOL_Z_PES + fundo * iz / PASSOS_Z
			linha.append(_altura_corpo(x, z))
		alturas.append(linha)
	# O pano cai a partir dos joelhos e da barriga, em vez de grudar no corpo.
	var caido := []
	var alcance := 7
	var passo := largura / PASSOS_X
	for iz in PASSOS_Z + 1:
		var linha := []
		for ix in PASSOS_X + 1:
			var h := 0.0
			for dz in range(-alcance, alcance + 1):
				for dx in range(-alcance, alcance + 1):
					var jz: int = iz + dz
					var jx: int = ix + dx
					if jz < 0 or jz > PASSOS_Z or jx < 0 or jx > PASSOS_X:
						continue
					var bruto: float = alturas[jz][jx]
					if bruto <= 0.0:
						continue
					h = maxf(h, bruto - 1.1 * passo * sqrt(dx * dx + dz * dz))
			linha.append(h + 0.025)
		caido.append(linha)

	var ruido := FastNoiseLite.new()
	ruido.seed = 11
	ruido.frequency = 6.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in PASSOS_Z + 1:
		for ix in PASSOS_X + 1:
			var x := -LENCOL_X + largura * ix / PASSOS_X
			var z := LENCOL_Z_PES + fundo * iz / PASSOS_Z
			var y: float = caido[iz][ix]
			# Bordas descem um pouco pela lateral do colchão.
			var borda := maxf(absf(x) - (LENCOL_X - 0.08), 0.0) / 0.08
			y -= borda * 0.12
			st.set_color(_cor_lencol(x, z, ruido))
			st.set_uv(Vector2(float(ix) / PASSOS_X, float(iz) / PASSOS_Z))
			st.add_vertex(Vector3(x, y, z))
	for iz in PASSOS_Z:
		for ix in PASSOS_X:
			var k0 := iz * (PASSOS_X + 1) + ix
			var k1 := k0 + 1
			var k2 := k0 + PASSOS_X + 1
			var k3 := k2 + 1
			st.add_index(k0)
			st.add_index(k2)
			st.add_index(k1)
			st.add_index(k1)
			st.add_index(k2)
			st.add_index(k3)
	st.generate_normals()
	return st.commit()


## Manchas representadas entre os joelhos e aos pés da cama, nunca ferida.
func _cor_lencol(x: float, z: float, ruido: FastNoiseLite) -> Color:
	var branco := Color(1, 1, 1)
	if sangue <= 0.0:
		return branco
	var centro := Vector2(0.0, -0.75)
	var d := Vector2(x / 0.4, (z - centro.y) / 0.6).length()
	var forma := 1.0 - d + 0.35 * ruido.get_noise_2d(x, z)
	var mancha := smoothstep(0.0, 0.25, forma) * sangue
	return branco.lerp(MalhaCorpo.COR_SANGUE / Color(0.93, 0.91, 0.87, 1.0), clampf(mancha, 0.0, 0.97))
