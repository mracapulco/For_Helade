@tool
class_name BebeAlthea
extends Node3D
## Althea recém-nascida, enrolada num pano. Deitada ao longo de X, com a
## cabeça para -X, como fica no colo de quem a segura.
## "ela, toda suja de sangue": manchas representadas no pano.

@export_range(0.0, 1.0, 0.05) var sangue := 0.6
@export var chorando := false

const BOCA := Vector3(0.008, 0.0035, 0.003)
const BASE_CABECA := Vector3(PI / 2.0, -PI / 2.0, 0.0)

var _cabeca: Node3D
var _boca: MeshInstance3D
var _tempo := 0.0


func _ready() -> void:
	for filho in get_children():
		if filho is MeshInstance3D or filho.name == "Corpo":
			filho.free()
	var corpo := MalhaCorpo.junta(self, "Corpo")
	var pano := MalhaCorpo.tecido(Color(0.9, 0.88, 0.82), 9.0)
	var pele := MalhaCorpo.pele(Color(0.82, 0.55, 0.5))
	var enrolado := MalhaCorpo.peca(corpo, "Pano", MalhaCorpo.elipsoide(Vector3(0.17, 0.085, 0.095)), pano, Vector3(0.03, 0, 0))
	enrolado.rotation.z = 0.05
	MalhaCorpo.peca(corpo, "Capuz", MalhaCorpo.elipsoide(Vector3(0.07, 0.055, 0.075)), pano, Vector3(-0.135, -0.005, 0.0))
	_cabeca = MalhaCorpo.junta(corpo, "Cabeca", Vector3(-0.12, 0.03, -0.01))
	MalhaCorpo.peca(_cabeca, "Rosto", MalhaCorpo.elipsoide(Vector3(0.05, 0.055, 0.052)), pele, Vector3(0, 0, -0.012))
	var fechado := MalhaCorpo.liso(Color(0.5, 0.28, 0.25), 0.8)
	for lado in [-1, 1]:
		MalhaCorpo.peca(_cabeca, "Olho", MalhaCorpo.elipsoide(Vector3(0.011, 0.0018, 0.003)), fechado, Vector3(0.017 * lado, 0.01, -0.06))
	_boca = MalhaCorpo.peca(_cabeca, "Boca", MalhaCorpo.elipsoide(BOCA), MalhaCorpo.liso(Color(0.55, 0.25, 0.24), 0.6), Vector3(0.0, -0.022, -0.06))
	# Deitada de costas: o rosto para cima e o alto da cabeça para -X.
	_cabeca.rotation = BASE_CABECA
	if sangue > 0.0:
		var manchas := [[Vector3(0.05, 0.082, -0.02), 0.03], [Vector3(0.13, 0.06, -0.03), 0.022], [Vector3(-0.0, 0.084, 0.025), 0.02]]
		for i in ceili(sangue * manchas.size()):
			var tamanho: float = manchas[i][1]
			MalhaCorpo.peca(corpo, "Mancha", MalhaCorpo.elipsoide(Vector3(tamanho * 1.3, 0.006, tamanho)), MalhaCorpo.sangue(), manchas[i][0])


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _cabeca == null:
		return
	_tempo += delta
	var forca := 1.0 if chorando else 0.0
	# Chorando, a boca abre e fecha.
	_boca.scale = BOCA * Vector3(1.0 + forca * 0.2, 1.0 + forca * (1.4 + 0.5 * sin(_tempo * 9.0)), 1.0)
	_cabeca.rotation = BASE_CABECA + Vector3(0, 0, forca * 0.08 * sin(_tempo * 6.0))
