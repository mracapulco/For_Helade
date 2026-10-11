class_name CaixaDialogo
extends CanvasLayer
## Caixa de diálogo do jogo: retrato, nome, fala e escolhas.
## Adaptada do balão de exemplo do Dialogue Manager. Funciona com clique ou
## toque: tocar na caixa adianta a fala, tocar numa opção escolhe.

## Expressão usada quando a fala não tem a etiqueta [code][#retrato=...][/code].
const EXPRESSAO_PADRAO := "neutro"

## Recurso de diálogo (quando a caixa é colocada direto numa cena).
@export var dialogue_resource: DialogueResource

## Marcador de onde começar (quando a caixa é colocada direto numa cena).
@export var start_from_cue: String = ""

## Começa sozinha ao entrar na cena.
@export var auto_start: bool = false

## Ação que adianta a fala.
@export var next_action: StringName = &"ui_accept"

## Ação que pula a digitação.
@export var skip_action: StringName = &"ui_cancel"

## Estados extras repassados ao Dialogue Manager.
var temporary_game_states: Array = []

## Variáveis temporárias da conversa (no roteiro: locals.alguma_coisa).
var locals: Dictionary = {}

var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false
var mutation_cooldown: Timer = Timer.new()
var _locale: String = TranslationServer.get_locale()

## Fala atual. Ao receber null, a conversa acabou e a caixa fecha.
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

@onready var balloon: Control = %Balloon
@onready var retrato: TextureRect = %Retrato
@onready var retrato_provisorio: ColorRect = %RetratoProvisorio
@onready var retrato_provisorio_texto: Label = %RetratoProvisorioTexto
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var progress: Polygon2D = %Progress


func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		assert(is_instance_valid(dialogue_resource), "CaixaDialogo: auto_start sem dialogue_resource.")
		start()


func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0


func _unhandled_input(_event: InputEvent) -> void:
	# Enquanto a caixa está aberta, só ela recebe entrada.
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# Troca de idioma com a caixa aberta: recarrega a fala atual.
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		await dialogue_line.refresh()
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Começa uma conversa.
func start(with_dialogue_resource: DialogueResource = null, cue: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not cue.is_empty():
		start_from_cue = cue
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_cue, temporary_game_states)
	show()


## Mostra uma nova fala.
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")
	_mostrar_retrato()

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Vai para a próxima fala.
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


## Expressão pedida pela fala atual.
func expressao_atual() -> String:
	var expressao: String = dialogue_line.get_tag_value("retrato")
	return EXPRESSAO_PADRAO if expressao.is_empty() else expressao


# Mostra a arte do personagem ou, sem arte, um quadro provisório com o nome
# e a expressão pedida.
func _mostrar_retrato() -> void:
	var tem_personagem: bool = not dialogue_line.character.is_empty()
	var personagem: Personagem = Elenco.buscar(dialogue_line.character) if tem_personagem else null
	var expressao: String = expressao_atual()
	var textura: Texture2D = personagem.retrato(expressao) if personagem else null

	retrato.visible = textura != null
	retrato.texture = textura
	retrato_provisorio.visible = tem_personagem and textura == null
	if retrato_provisorio.visible:
		retrato_provisorio.color = personagem.cor_provisoria if personagem else Color(0.4, 0.1, 0.1)
		retrato_provisorio_texto.text = "%s\n(%s)\n%s" % [
			tr(dialogue_line.character, "dialogue"),
			expressao,
			tr("PROVISÓRIO") if personagem else tr("FORA DO ELENCO"),
		]


#region Sinais


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# Clique ou toque durante a digitação mostra a fala inteira.
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion
