class_name CaixaDialogo
extends CanvasLayer
## Caixa de diálogo do jogo: retrato, nome, fala e escolhas.
## Adaptada do balão de exemplo do Dialogue Manager. Funciona com clique ou
## toque: tocar na caixa adianta a fala, tocar numa opção escolhe.

## Expressão usada quando a fala não tem a etiqueta [code][#retrato=...][/code].
const EXPRESSAO_PADRAO := "neutro"
## Ordem dos quadros da boca enquanto o texto aparece (índices da faixa de
## fala: 0 fechada, 1 entreaberta, 2 aberta) e o tempo de cada um.
const SEQUENCIA_FALA := [1, 2, 1, 0]
const TEMPO_QUADRO_FALA := 0.09
## Piscada do retrato parado: intervalo sorteado entre as piscadas e quanto
## tempo os olhos ficam fechados.
const INTERVALO_PISCAR := Vector2(2.5, 5.0)
const TEMPO_PISCANDO := 0.12
## Entrada do close quando muda quem fala: começa nesta escala, sem cor, e
## chega ao tamanho cheio neste tempo.
const ESCALA_ENTRADA := 0.85
const TEMPO_ENTRADA := 0.2

## Um rosto novo entrou em close (mudou quem fala).
signal rosto_entrou(nome: String)

## Recurso de diálogo (quando a caixa é colocada direto numa cena).
@export var dialogue_resource: DialogueResource

## Marcador de onde começar (quando a caixa é colocada direto numa cena).
@export var start_from_cue: String = ""

## Começa sozinha ao entrar na cena.
@export var auto_start: bool = false

## Ação que adianta a fala.
## Enter (ui_accept) passa o texto; E fica só para interagir (Rafael, 17/10).
@export var next_action: StringName = &"ui_accept"

## Ação que pula a digitação.
@export var skip_action: StringName = &"ui_cancel"

## Com true, as escolhas aparecem sempre sozinhas, embaixo, sem cobrir a
## cena (a carruagem do Capítulo 01): uma fala que vem junto com escolhas
## aparece primeiro e, depois de Enter ou de um toque, dá lugar a elas.
static var escolhas_embaixo := false

## Estados extras repassados ao Dialogue Manager.
var temporary_game_states: Array = []

## Variáveis temporárias da conversa (no roteiro: locals.alguma_coisa).
var locals: Dictionary = {}

var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false
## A fala antes das escolhas está na tela; o próximo Enter mostra as escolhas.
var _fala_antes_das_escolhas := false
var mutation_cooldown: Timer = Timer.new()
var _locale: String = TranslationServer.get_locale()
## Retrato parado da fala atual e os quadros da boca falando.
var _retrato_parado: Texture2D
var _quadros_fala: Array[Texture2D] = []
var _tempo_fala := 0.0
var _passo_fala := 0
## Retrato de olhos fechados e o tempo até a próxima piscada (negativo:
## piscando agora).
var _retrato_piscando: Texture2D
var _ate_piscar := INTERVALO_PISCAR.x
## Quem falou por último, para o close só entrar quando muda quem fala.
var _ultimo_falante := ""
var _entrada: Tween

## Fala atual. Ao receber null, a conversa acabou e a caixa fecha.
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			Voz.parar()
			_ultimo_falante = ""
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


func _process(delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0
	# A boca mexe enquanto o texto aparece e enquanto a voz gravada toca.
	animar_boca(delta, (is_instance_valid(dialogue_label) and dialogue_label.is_typing) or Voz.falando())


## Mexe a boca do retrato enquanto o texto aparece; parado, mostra o retrato
## de boca fechada, piscando de vez em quando.
func animar_boca(delta: float, falando: bool) -> void:
	if _quadros_fala.is_empty() or not falando:
		_tempo_fala = 0.0
		_passo_fala = 0
		if _retrato_parado != null:
			retrato.texture = _retrato_parado if not _piscando(delta) else _retrato_piscando
		return
	_tempo_fala += delta
	if _tempo_fala >= TEMPO_QUADRO_FALA:
		_tempo_fala = 0.0
		_passo_fala = (_passo_fala + 1) % SEQUENCIA_FALA.size()
	var quadro: int = mini(SEQUENCIA_FALA[_passo_fala], _quadros_fala.size() - 1)
	retrato.texture = _quadros_fala[quadro]


# Conta o tempo da piscada; true enquanto os olhos estão fechados.
func _piscando(delta: float) -> bool:
	if _retrato_piscando == null:
		return false
	_ate_piscar -= delta
	if _ate_piscar < -TEMPO_PISCANDO:
		_ate_piscar = randf_range(INTERVALO_PISCAR.x, INTERVALO_PISCAR.y)
	return _ate_piscar < 0.0


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
	_ultimo_falante = ""
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
	# Escolha sem fala antes: só os botões, embaixo, no lugar da caixa de texto
	# (sem a caixa vazia e sem cobrir a cena).
	var so_escolhas := dialogue_line.text.is_empty() and dialogue_line.character.is_empty() \
			and dialogue_line.responses.size() > 0
	_escolhas_embaixo(so_escolhas)
	_fala_antes_das_escolhas = false

	dialogue_label.show()
	# Voz gravada da fala, se houver (assets/audio/vozes/<ID>.mp3).
	Voz.tocar(dialogue_line.static_id)
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	if dialogue_line.responses.size() > 0 and escolhas_embaixo and not so_escolhas:
		_fala_antes_das_escolhas = true
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()
	elif dialogue_line.responses.size() > 0:
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


## Só os botões, embaixo, no lugar da caixa de texto; ou a caixa de texto
## com as escolhas no meio da tela.
func _escolhas_embaixo(sim: bool) -> void:
	$Balloon/Margem/Painel.visible = not sim
	var area_escolhas: Control = $Balloon/AreaEscolhas
	area_escolhas.offset_top = 380.0 if sim else 0.0
	area_escolhas.offset_bottom = 0.0 if sim else -260.0


func _mostrar_escolhas_embaixo() -> void:
	_fala_antes_das_escolhas = false
	is_waiting_for_input = false
	_escolhas_embaixo(true)
	balloon.focus_mode = Control.FOCUS_NONE
	responses_menu.show()


## Vai para a próxima fala.
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


## Expressão pedida pela fala atual.
func expressao_atual() -> String:
	var expressao: String = dialogue_line.get_tag_value("retrato")
	return EXPRESSAO_PADRAO if expressao.is_empty() else expressao


## Fase da vida que decide a idade dos rostos: a da etiqueta
## [code][#idade=crianca][/code] da fala (memórias, sonhos) ou a do Nicholas
## agora ("crianca", "adolescente" ou "adulto").
func fase_atual() -> String:
	var idade: String = dialogue_line.get_tag_value("idade")
	if not idade.is_empty():
		return idade
	return str(Inventario.FaixaEtaria.find_key(Inventario.faixa_etaria)).to_lower()


# Mostra a arte do personagem ou, sem arte, um quadro provisório com o nome
# e a expressão pedida.
func _mostrar_retrato() -> void:
	var tem_personagem: bool = not dialogue_line.character.is_empty()
	var personagem: Personagem = Elenco.buscar(dialogue_line.character) if tem_personagem else null
	var expressao: String = expressao_atual()
	var fase: String = fase_atual()
	var textura: Texture2D = personagem.retrato(expressao, fase) if personagem else null

	# Falas sem nome (narração, pensamentos de Nicholas) não reservam espaço de retrato.
	retrato.get_parent().visible = tem_personagem
	retrato.visible = textura != null
	retrato.texture = textura
	_retrato_parado = textura
	_quadros_fala = personagem.quadros_fala(expressao, fase) if personagem and textura else ([] as Array[Texture2D])
	_retrato_piscando = personagem.retrato_piscando(expressao, fase) if personagem and textura else null
	_passo_fala = 0
	_tempo_fala = 0.0
	_ate_piscar = randf_range(INTERVALO_PISCAR.x, INTERVALO_PISCAR.y)
	if textura != null and dialogue_line.character != _ultimo_falante:
		_entrar_close()
	_ultimo_falante = dialogue_line.character if textura != null else ""
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if personagem and personagem.pixel_art else CanvasItem.TEXTURE_FILTER_PARENT_NODE
	retrato_provisorio.visible = tem_personagem and textura == null
	if retrato_provisorio.visible:
		retrato_provisorio.color = personagem.cor_provisoria if personagem else Color(0.4, 0.1, 0.1)
		retrato_provisorio_texto.text = "%s\n(%s)\n%s" % [
			tr(dialogue_line.character, "dialogue"),
			expressao,
			tr("RETRATO_PROVISORIO") if personagem else tr("RETRATO_FORA_DO_ELENCO"),
		]


# O rosto de quem passa a falar cresce um pouco e aparece, como um close.
func _entrar_close() -> void:
	if _entrada:
		_entrada.kill()
	retrato.pivot_offset = retrato.size / 2.0
	retrato.scale = Vector2.ONE * ESCALA_ENTRADA
	retrato.modulate.a = 0.0
	_entrada = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_entrada.tween_property(retrato, "scale", Vector2.ONE, TEMPO_ENTRADA)
	_entrada.tween_property(retrato, "modulate:a", 1.0, TEMPO_ENTRADA)
	rosto_entrou.emit(dialogue_line.character)


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
	if _fala_antes_das_escolhas:
		var clique: bool = event is InputEventMouseButton and event.is_pressed() \
				and event.button_index == MOUSE_BUTTON_LEFT
		if clique or event.is_action_pressed(next_action):
			get_viewport().set_input_as_handled()
			_mostrar_escolhas_embaixo()
		return
	if dialogue_line.responses.size() > 0: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion
