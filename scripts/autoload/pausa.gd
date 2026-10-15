extends CanvasLayer
## Menu de pausa (autoload "Pausa"): Esc em qualquer parte do jogo (mapa,
## prólogo, acampamento, reino, missão) pausa e mostra Voltar ao jogo, Opções,
## Menu inicial e Sair do jogo. No menu inicial não abre.
## No celular, o botão "Pausa" no alto da tela faz o mesmo.
## Menu inicial e Sair perguntam antes: o que não foi salvo se perde.

const CENA_MENU := "res://scenes/main/main.tscn"
const CENA_OPCOES := preload("res://scenes/ui/tela_opcoes.tscn")
const COR_FUNDO := Color(0.0196, 0.0471, 0.0784, 0.8) # Noite, da paleta
const COR_DESTAQUE := Color(0.9255, 0.7412, 0.4588) # Dourado claro
const FONTE_TITULO := preload("res://assets/fonts/cinzel/cinzel.ttf")

enum Pedido { NADA, MENU, SAIR }

## Quando falso, Menu inicial e Sair só anotam o pedido (testes).
var agir := true
## O que a confirmação vai fazer, ou o último pedido confirmado (testes).
var pedido := Pedido.NADA

var tela: Control
var principal: Control
var botao_voltar: Button
var botao_opcoes: Button
var botao_menu: Button
var botao_sair: Button
var opcoes: TelaOpcoes
var confirmacao: Control
var pergunta: Label
var botao_sim: Button
var botao_nao: Button
var botao_pausa: Button


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	tela.hide()


func _process(_delta: float) -> void:
	botao_pausa.visible = _tem_toque() and not aberta() and pode_pausar()


func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed(&"ui_cancel") or evento.is_echo():
		return
	if aberta():
		get_viewport().set_input_as_handled()
		voltar_um_passo()
	elif pode_pausar():
		get_viewport().set_input_as_handled()
		abrir()


## Pausa só durante o jogo: fora do menu inicial, sem troca de cena em
## andamento e sem outra tela já pausando (bolsa, lista de espaços).
func pode_pausar() -> bool:
	var cena := get_tree().current_scene
	if cena == null or cena is MenuInicial or TrocaCena.trocando:
		return false
	return not get_tree().paused


func aberta() -> bool:
	return tela.visible


func abrir() -> void:
	pedido = Pedido.NADA
	tela.show()
	principal.show()
	opcoes.visible = false
	confirmacao.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	botao_voltar.grab_focus()


## Voltar ao jogo.
func retomar() -> void:
	tela.hide()
	get_tree().paused = false


## Esc: fecha a parte de cima (opções, pergunta) ou volta ao jogo.
func voltar_um_passo() -> void:
	if opcoes.visible:
		opcoes.fechar()
	elif confirmacao.visible:
		cancelar()
	else:
		retomar()


func perguntar(qual: Pedido) -> void:
	pedido = qual
	pergunta.text = "PAUSA_CONFIRMAR_MENU" if qual == Pedido.MENU else "PAUSA_CONFIRMAR_SAIR"
	principal.hide()
	confirmacao.show()
	botao_nao.grab_focus() # o seguro fica selecionado


func cancelar() -> void:
	var anterior := pedido
	pedido = Pedido.NADA
	confirmacao.hide()
	principal.show()
	(botao_menu if anterior == Pedido.MENU else botao_sair).grab_focus()


func confirmar() -> void:
	var qual := pedido
	retomar()
	if not agir:
		return
	match qual:
		Pedido.MENU:
			TrocaCena.ir_para(CENA_MENU)
		Pedido.SAIR:
			get_tree().quit()


func _abrir_opcoes() -> void:
	principal.hide()
	opcoes.abrir()


func _fechar_opcoes() -> void:
	principal.show()
	botao_opcoes.grab_focus()


func _tem_toque() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _botao(chave: String, ao_apertar: Callable) -> Button:
	var botao := Button.new()
	botao.text = chave
	botao.custom_minimum_size = Vector2(420, 84)
	botao.add_theme_font_size_override("font_size", 34)
	botao.pressed.connect(ao_apertar)
	return botao


## Montado por código: é o mesmo em todas as cenas do jogo.
func _montar() -> void:
	botao_pausa = Button.new()
	botao_pausa.name = "BotaoPausa"
	botao_pausa.text = "PAUSA_BOTAO"
	botao_pausa.focus_mode = Control.FOCUS_NONE
	botao_pausa.set_anchors_preset(Control.PRESET_CENTER_TOP)
	botao_pausa.offset_left = -75.0
	botao_pausa.offset_right = 75.0
	botao_pausa.offset_top = 32.0
	botao_pausa.offset_bottom = 32.0 + 72.0
	botao_pausa.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	botao_pausa.pressed.connect(abrir)
	botao_pausa.hide()
	add_child(botao_pausa)

	tela = Control.new()
	tela.name = "Tela"
	tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	tela.mouse_filter = Control.MOUSE_FILTER_STOP
	tela.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	add_child(tela)

	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	tela.add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	tela.add_child(centro)

	principal = VBoxContainer.new()
	principal.name = "Principal"
	principal.add_theme_constant_override("separation", 16)
	centro.add_child(principal)
	var titulo := Label.new()
	titulo.text = "PAUSA_TITULO"
	titulo.add_theme_font_override("font", FONTE_TITULO)
	titulo.add_theme_font_size_override("font_size", 48)
	titulo.add_theme_color_override("font_color", COR_DESTAQUE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	principal.add_child(titulo)
	botao_voltar = _botao("PAUSA_VOLTAR_AO_JOGO", retomar)
	botao_opcoes = _botao("MENU_OPCOES", _abrir_opcoes)
	botao_menu = _botao("PAUSA_MENU_INICIAL", perguntar.bind(Pedido.MENU))
	botao_sair = _botao("PAUSA_SAIR", perguntar.bind(Pedido.SAIR))
	botao_sair.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	for botao in [botao_voltar, botao_opcoes, botao_menu, botao_sair]:
		principal.add_child(botao)

	confirmacao = PanelContainer.new()
	confirmacao.name = "Confirmacao"
	confirmacao.custom_minimum_size = Vector2(760, 0)
	centro.add_child(confirmacao)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 28)
	confirmacao.add_child(coluna)
	pergunta = Label.new()
	pergunta.add_theme_font_size_override("font_size", 30)
	pergunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pergunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(pergunta)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 24)
	coluna.add_child(linha)
	botao_sim = _botao("PAUSA_CONFIRMAR_SIM", confirmar)
	botao_nao = _botao("PAUSA_CONFIRMAR_NAO", cancelar)
	for botao in [botao_sim, botao_nao]:
		botao.custom_minimum_size.x = 300
		linha.add_child(botao)
	confirmacao.hide()

	opcoes = CENA_OPCOES.instantiate()
	tela.add_child(opcoes)
	opcoes.fechou.connect(_fechar_opcoes)
