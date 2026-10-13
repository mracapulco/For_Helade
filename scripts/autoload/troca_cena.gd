extends CanvasLayer
## Troca de cena com a tela escurecendo e clareando (autoload "TrocaCena").

@export var tempo := 0.4

var _cortina: ColorRect
var trocando := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cortina = ColorRect.new()
	_cortina.color = Color(0, 0, 0, 0)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cortina)


func ir_para(caminho: String) -> void:
	if trocando:
		return
	trocando = true
	_cortina.mouse_filter = Control.MOUSE_FILTER_STOP # nada responde durante a troca
	var escurecer := create_tween()
	escurecer.tween_property(_cortina, "color:a", 1.0, tempo)
	await escurecer.finished
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(caminho)
	await get_tree().process_frame
	await get_tree().process_frame
	var clarear := create_tween()
	clarear.tween_property(_cortina, "color:a", 0.0, tempo)
	await clarear.finished
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trocando = false
