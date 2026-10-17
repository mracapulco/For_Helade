class_name AvisoItens
extends CanvasLayer
## Avisos curtos no alto da tela quando a bolsa ganha algo:
## "+ Poção de teste ×2", "+ 15 moedas". Cada um some sozinho.

## Segundos que cada aviso fica na tela antes de sumir.
@export var duracao := 2.5

var coluna: VBoxContainer


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	coluna = VBoxContainer.new()
	coluna.name = "Coluna"
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.set_anchors_preset(Control.PRESET_CENTER_TOP)
	coluna.grow_horizontal = Control.GROW_DIRECTION_BOTH
	coluna.offset_top = 32.0
	coluna.add_theme_constant_override("separation", 8)
	add_child(coluna)
	Inventario.recebeu.connect(_ao_receber)
	Inventario.dinheiro_recebido.connect(_ao_receber_dinheiro)
	Inventario.bolsa_cheia.connect(_ao_encher_bolsa)
	Inventario.pesado_demais.connect(_ao_tentar_pesado)
	Experiencia.subiu.connect(_ao_subir_de_nivel)
	Experiencia.limite_das_lutas.connect(_ao_chegar_no_limite)


## Textos dos avisos que estão na tela agora.
func textos() -> Array[String]:
	var lista: Array[String] = []
	for painel in coluna.get_children():
		if not painel.is_queued_for_deletion():
			lista.append((painel.get_child(0) as Label).text)
	return lista


func mostrar(texto: String) -> void:
	var painel := PanelContainer.new()
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	painel.add_child(rotulo)
	coluna.add_child(painel)
	var sumir := painel.create_tween()
	sumir.tween_interval(duracao)
	sumir.tween_property(painel, "modulate:a", 0.0, 0.4)
	sumir.tween_callback(painel.queue_free)


func _ao_receber(id: String, quantidade: int) -> void:
	var item := Inventario.item(id)
	var texto := "+ " + tr(item.chave_nome)
	if quantidade > 1:
		texto += " ×%d" % quantidade
	mostrar(texto)


func _ao_receber_dinheiro(valor: int) -> void:
	mostrar(tr("AVISO_MOEDAS") % valor)


func _ao_encher_bolsa() -> void:
	mostrar(tr("AVISO_BOLSA_CHEIA"))


func _ao_tentar_pesado(_id: String) -> void:
	mostrar(tr("AVISO_PESADO_DEMAIS"))


func _ao_subir_de_nivel(_personagem: String, nivel: int) -> void:
	mostrar(tr("AVISO_SUBIU_NIVEL") % nivel)


func _ao_chegar_no_limite(_personagem: String, _nivel: int) -> void:
	mostrar(tr("AVISO_LIMITE_NIVEL"))
