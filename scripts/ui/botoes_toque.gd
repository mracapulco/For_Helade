class_name BotoesToque
extends CanvasLayer
## Botões grandes na tela para quem joga no toque: Correr (liga e desliga) e
## Pular. Fazem o mesmo que Shift e Espaço no PC. Somem durante as conversas.
## Por padrão só aparecem em aparelhos com tela de toque.

const GRUPO_BLOQUEIA_TOQUE := &"bloqueia_toque"

## Mostra os botões mesmo sem tela de toque (útil para testar no PC).
@export var sempre_mostrar := false

@onready var painel: Control = %Painel
@onready var botao_correr: Button = %BotaoCorrer
@onready var botao_pular: Button = %BotaoPular


func _ready() -> void:
	painel.add_to_group(GRUPO_BLOQUEIA_TOQUE)
	botao_correr.toggled.connect(_ao_alternar_corrida)
	botao_pular.pressed.connect(pular)
	visible = deve_aparecer()
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)


func deve_aparecer() -> bool:
	return sempre_mostrar or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func pular() -> void:
	var evento := InputEventAction.new()
	evento.action = &"pular"
	evento.pressed = true
	Input.parse_input_event(evento)


func _ao_alternar_corrida(ligado: bool) -> void:
	if ligado:
		Input.action_press(&"correr")
	else:
		Input.action_release(&"correr")


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	botao_correr.button_pressed = false
	hide()


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	visible = deve_aparecer()


## Diz se um ponto da tela cai sobre algum botão visível. O personagem usa
## isso para não andar quando o toque era num botão.
static func toque_em_botao(arvore: SceneTree, posicao_tela: Vector2) -> bool:
	for no in arvore.get_nodes_in_group(GRUPO_BLOQUEIA_TOQUE):
		var controle := no as Control
		if controle and controle.is_visible_in_tree() and controle.get_global_rect().has_point(posicao_tela):
			return true
	return false
