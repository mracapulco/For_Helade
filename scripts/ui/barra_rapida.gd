class_name BarraRapida
extends CanvasLayer
## Barra rápida no meio, embaixo da tela: os 9 primeiros espaços da bolsa,
## como no Minecraft. Tecla 1 a 9 (ou toque no espaço) só seleciona o item,
## que fica na mão; o clique (ação "golpear") usa o selecionado: arma golpeia,
## poção é bebida, proteção é vestida ou tirada. Some durante as conversas.

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
	Inventario.selecao_mudou.connect(_ao_mudar_selecao)
	_selecionar_arma_na_mao()
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	atualizar()


func _unhandled_input(evento: InputEvent) -> void:
	if not visible or evento.is_echo():
		return
	for indice in Inventario.ESPACOS_RAPIDOS:
		if evento.is_action_pressed(acao_do_espaco(indice)):
			get_viewport().set_input_as_handled()
			selecionar(indice)
			return
	# Arma selecionada: o clique segue para o personagem golpear.
	if evento.is_action_pressed(&"golpear") and Inventario.selecionado_tem_uso():
		get_viewport().set_input_as_handled()
		usar_selecionado()


static func acao_do_espaco(indice: int) -> StringName:
	return StringName("atalho_%d" % (indice + 1))


## Põe o espaço [param indice] (0 a 8) na mão, como a tecla ou o toque.
func selecionar(indice: int) -> void:
	Inventario.selecionar_espaco(indice, personagem)


## Clique com o item selecionado (poção, proteção).
func usar_selecionado() -> bool:
	return Inventario.usar_selecionado(personagem)


func atualizar() -> void:
	for espaco in espacos:
		espaco.selecionado = espaco.indice == Inventario.espaco_selecionado
		espaco.atualizar(personagem)


func _ao_mudar_equipamento(quem: String, _encaixe: Item.Encaixe, _id: String) -> void:
	if quem == personagem:
		atualizar()


func _ao_mudar_selecao(_indice: int) -> void:
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
	caixa.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caixa.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caixa.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caixa.offset_bottom = -MARGEM
	caixa.offset_top = -MARGEM
	add_child(caixa)
	for indice in Inventario.ESPACOS_RAPIDOS:
		var espaco := EspacoBolsa.new()
		espaco.name = "Espaco%d" % (indice + 1)
		espaco.indice = indice
		espaco.mostrar_numero(indice + 1)
		espaco.pressed.connect(selecionar.bind(indice))
		caixa.add_child(espaco)
		espacos.append(espaco)



## Ao abrir a cena, a seleção começa no espaço da arma que já está na mão.
func _selecionar_arma_na_mao() -> void:
	var arma := Inventario.equipado(personagem, Item.Encaixe.ARMA)
	if arma.is_empty():
		return
	for indice in Inventario.ESPACOS_RAPIDOS:
		if Inventario.espaco(indice).get("id", "") == arma:
			Inventario.espaco_selecionado = indice
			return
