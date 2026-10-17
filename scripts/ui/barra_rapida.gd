class_name BarraRapida
extends CanvasLayer
## Barra rápida embaixo da tela: os 9 primeiros espaços da bolsa, como no
## Minecraft. Tecla 1 a 9 (ou toque no espaço): arma ou proteção equipa (de
## novo, desequipa); poção é bebida na hora. Some durante as conversas.

## Id do personagem no Inventario.
@export var personagem := "nicholas"

const MARGEM := 16.0
const SEPARACAO := 6

var caixa: HBoxContainer
var espacos: Array[EspacoBolsa] = []


func _ready() -> void:
	layer = 10
	_montar()
	Inventario.espacos_mudaram.connect(atualizar)
	Inventario.equipamento_mudou.connect(_ao_mudar_equipamento)
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	atualizar()


func _unhandled_input(evento: InputEvent) -> void:
	if not visible or evento.is_echo():
		return
	for indice in Inventario.ESPACOS_RAPIDOS:
		if evento.is_action_pressed(acao_do_espaco(indice)):
			get_viewport().set_input_as_handled()
			usar(indice)
			return


static func acao_do_espaco(indice: int) -> StringName:
	return StringName("atalho_%d" % (indice + 1))


## Usa o espaço [param indice] (0 a 8), como a tecla ou o toque.
func usar(indice: int) -> bool:
	return Inventario.usar_espaco(indice, personagem)


func atualizar() -> void:
	for espaco in espacos:
		espaco.atualizar(personagem)


func _ao_mudar_equipamento(quem: String, _encaixe: Item.Encaixe, _id: String) -> void:
	if quem == personagem:
		atualizar()


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	hide()


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	show()


func _montar() -> void:
	caixa = HBoxContainer.new()
	caixa.name = "Caixa"
	caixa.add_theme_constant_override("separation", SEPARACAO)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# No toque os botões Correr/Pular/Golpe ficam embaixo à direita; a barra
	# vai para a esquerda. No PC fica no meio, como no Minecraft.
	var toque := _botoes_de_toque_aparecem()
	caixa.set_anchors_preset(Control.PRESET_CENTER_BOTTOM if not toque else Control.PRESET_BOTTOM_LEFT)
	caixa.grow_horizontal = Control.GROW_DIRECTION_BOTH if not toque else Control.GROW_DIRECTION_END
	caixa.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caixa.offset_bottom = -MARGEM
	caixa.offset_top = -MARGEM
	if toque:
		caixa.offset_left = MARGEM
		caixa.offset_right = MARGEM
	add_child(caixa)
	for indice in Inventario.ESPACOS_RAPIDOS:
		var espaco := EspacoBolsa.new()
		espaco.name = "Espaco%d" % (indice + 1)
		espaco.indice = indice
		espaco.mostrar_numero(indice + 1)
		espaco.pressed.connect(usar.bind(indice))
		caixa.add_child(espaco)
		espacos.append(espaco)


func _botoes_de_toque_aparecem() -> bool:
	for irmao in get_parent().get_children() if get_parent() else []:
		if irmao is BotoesToque and (irmao as BotoesToque).deve_aparecer():
			return true
	return false
