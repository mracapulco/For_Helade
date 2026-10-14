class_name MalhaCorpo
extends RefCounted
## Formas e materiais das pessoas do prólogo, montados por código.
## Nada é baixado nem modelado fora: corpo, roupa e rosto são anéis e
## elipsoides, com o linho que o cenário já usa como tecido.

const LINHO_COR := "res://assets/art/prologo/texturas/linho_cor.jpg"
const LINHO_RELEVO := "res://assets/art/prologo/texturas/linho_normal.png"
const LINHO_ASPEREZA := "res://assets/art/prologo/texturas/linho_aspereza.jpg"

## Sangue representado: escuro e fosco, sem brilho de ferida.
const COR_SANGUE := Color(0.3, 0.04, 0.04)

const LADOS := 20

static var _materiais := {}


## Tubo feito de anéis elípticos empilhados.
## Cada anel é Vector4(y, raio_x, raio_z, deslocamento_z); deslocamento
## negativo leva o anel para a frente (-Z, para onde a pessoa olha).
## `de` e `ate` (ângulos, 0 = frente) deixam fazer só parte da volta, como
## um avental na frente da saia.
static func anel(aneis: Array, de := -PI, ate := PI, lados := LADOS) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var linhas := aneis.size()
	for i in linhas:
		var a: Vector4 = aneis[i]
		for j in lados + 1:
			var angulo := lerpf(de, ate, float(j) / lados)
			st.set_uv(Vector2(float(j) / lados, float(i) / maxf(linhas - 1, 1)))
			st.add_vertex(Vector3(sin(angulo) * a.y, a.x, -cos(angulo) * a.z + a.w))
	for i in linhas - 1:
		for j in lados:
			var k0 := i * (lados + 1) + j
			var k1 := k0 + 1
			var k2 := k0 + lados + 1
			var k3 := k2 + 1
			st.add_index(k0)
			st.add_index(k1)
			st.add_index(k2)
			st.add_index(k1)
			st.add_index(k3)
			st.add_index(k2)
	st.generate_normals()
	return st.commit()


## Braço ou perna: um tubo que desce de 0 até -comprimento, afinando.
## `raios` vai da raiz até a ponta (no mínimo dois valores).
static func membro(comprimento: float, raios: Array, lados := 14) -> ArrayMesh:
	var aneis := []
	var n := raios.size()
	aneis.append(Vector4(0.02 * comprimento, 0.0, 0.0, 0.0))
	for i in n:
		var r: float = raios[i]
		aneis.append(Vector4(-comprimento * float(i) / (n - 1), r, r * 0.92, 0.0))
	aneis.append(Vector4(-comprimento * 1.02, 0.0, 0.0, 0.0))
	return anel(aneis, -PI, PI, lados)


static func elipsoide(raios: Vector3, segmentos := 16) -> SphereMesh:
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = segmentos
	esfera.rings = maxi(segmentos / 2, 6)
	# A escala fica no nó: o SphereMesh só faz esferas.
	esfera.set_meta("raios", raios)
	return esfera


## Peça de malha num nó, já com material e posição.
static func peca(pai: Node3D, nome: String, malha: Mesh, material: Material, posicao := Vector3.ZERO, escala := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = malha
	mi.material_override = material
	mi.position = posicao
	if malha.has_meta("raios"):
		escala = malha.get_meta("raios") * escala
	mi.scale = escala
	pai.add_child(mi)
	return mi


static func junta(pai: Node3D, nome: String, posicao := Vector3.ZERO) -> Node3D:
	var no := Node3D.new()
	no.name = nome
	no.position = posicao
	pai.add_child(no)
	return no


## Tecido de linho tingido. A textura acompanha a peça (não o mundo), para
## não "escorrer" pela roupa quando a pessoa se mexe.
static func tecido(cor: Color, escala_trama := 7.0) -> StandardMaterial3D:
	var chave := "tecido_%s_%s" % [cor.to_html(), escala_trama]
	if _materiais.has(chave):
		return _materiais[chave]
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.albedo_texture = load(LINHO_COR)
	m.normal_enabled = true
	m.normal_texture = load(LINHO_RELEVO)
	m.normal_scale = 0.6
	m.roughness = 1.0
	m.roughness_texture = load(LINHO_ASPEREZA)
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * escala_trama
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Saias e aventais abertos: o avesso também aparece.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materiais[chave] = m
	return m


static func liso(cor: Color, aspereza := 0.6) -> StandardMaterial3D:
	var chave := "liso_%s_%s" % [cor.to_html(), aspereza]
	if _materiais.has(chave):
		return _materiais[chave]
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = aspereza
	_materiais[chave] = m
	return m


## Pele: cada pessoa tem a sua, porque a duquesa empalidece durante a cena.
static func pele(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.55
	m.rim_enabled = true
	m.rim = 0.25
	m.rim_tint = 0.6
	return m


static func sangue() -> StandardMaterial3D:
	return liso(COR_SANGUE, 0.75)


## Mão com dedos, para quem a vê de perto (Nicholas olhando as próprias mãos).
## Pende para -Y a partir do pulso, com a palma virada para -X·lado.
static func mao(pai: Node3D, material: Material, tamanho := 1.0, detalhada := false) -> Node3D:
	var m := junta(pai, "Mao")
	var s := tamanho
	peca(m, "Palma", elipsoide(Vector3(0.042, 0.05, 0.016) * s), material, Vector3(0, -0.045 * s, 0))
	if not detalhada:
		peca(m, "Dedos", elipsoide(Vector3(0.038, 0.045, 0.012) * s), material, Vector3(0, -0.105 * s, 0.002 * s))
	else:
		var comprimentos := [0.07, 0.08, 0.075, 0.06]
		for i in 4:
			var x := lerpf(-0.03, 0.03, i / 3.0) * s
			var dedo := junta(m, "Dedo%d" % i, Vector3(x, -0.088 * s, 0))
			dedo.rotation.x = 0.25
			peca(dedo, "Falanges", membro(comprimentos[i] * s, [0.0095 * s, 0.008 * s, 0.0065 * s], 8), material)
	var polegar := junta(m, "Polegar", Vector3(0.038 * s, -0.035 * s, -0.008 * s))
	polegar.rotation = Vector3(0.5, 0.0, 0.55)
	peca(polegar, "Falanges", membro(0.055 * s, [0.011 * s, 0.009 * s, 0.007 * s], 8), material)
	return m
