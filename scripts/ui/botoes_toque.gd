class_name BotoesToque
extends CanvasLayer
## Botões grandes na tela para quem joga no toque: Correr (liga e desliga),
## Pular e Golpe (só com uma arma equipada). Fazem o mesmo que Shift, Espaço
## e o clique esquerdo no PC. Somem durante as conversas.
## Por padrão só aparecem em aparelhos com tela de toque.

const GRUPO_BLOQUEIA_TOQUE := &"bloqueia_toque"

## Mostra os botões mesmo sem tela de toque (útil para testar no PC).
@export var sempre_mostrar := false
## Id do personagem no Inventario: o botão Golpe só aparece se ele estiver armado.
@export var personagem := "nicholas"

@onready var painel: Control = %Painel
@onready var botao_correr: Button = %BotaoCorrer
@onready var botao_pular: Button = %BotaoPular
@onready var botao_golpe: Button = %BotaoGolpe


func _ready() -> void:
	painel.add_to_group(GRUPO_BLOQUEIA_TOQUE)
	botao_correr.toggled.connect(_ao_alternar_corrida)
	botao_pular.pressed.connect(pular)
	botao_golpe.pressed.connect(golpear)
	Inventario.equipamento_mudou.connect(_ao_mudar_equipamento)
	_atualizar_botao_golpe()
	visible = deve_aparecer()
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)


func deve_aparecer() -> bool:
	return sempre_mostrar or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


## Aperta e solta "pular", como um toque rápido em Espaço. Sem soltar, a ação
## ficaria presa e o próximo toque não contaria como pulo novo.
func pular() -> void:
	_apertar_e_soltar(&"pular")


## Aperta e solta "golpear": golpe para onde o personagem está olhando.
func golpear() -> void:
	_apertar_e_soltar(&"golpear")


func _apertar_e_soltar(acao: StringName) -> void:
	for apertado in [true, false]:
		var evento := InputEventAction.new()
		evento.action = acao
		evento.pressed = apertado
		Input.parse_input_event(evento)


func _ao_mudar_equipamento(quem: String, _encaixe: Item.Encaixe, _id: String) -> void:
	if quem == personagem:
		_atualizar_botao_golpe()


func _atualizar_botao_golpe() -> void:
	botao_golpe.visible = not Inventario.equipado(personagem, Item.Encaixe.ARMA).is_empty()


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
