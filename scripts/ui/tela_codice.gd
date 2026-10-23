class_name TelaCodice
extends CanvasLayer
## Tela onde se lê o que o [code]Codice[/code] anotou, em duas abas: "O olhar
## de Nicholas" (o que ele percebe nos lugares) e "Códice" (lugares, casas,
## pessoas). Lista de títulos à esquerda, na ordem em que foram anotados, e o
## texto da entrada escolhida à direita. Entrada ainda não lida tem um ponto
## dourado, que some ao abri-la (os lidos vão no jogo salvo).
## Abre pelo botão "Códice" (toque ou clique) ou pela tecla C; fecha pelo
## botão Fechar, C ou Esc. O jogo fica pausado enquanto ela está aberta.
## Plano: planos/tela-codice.md (aprovado pelo Rafael em 23/10/2026).

const ALTURA_BOTAO := 72.0
const COR_FUNDO := Color(0.0196, 0.0471, 0.0784, 0.75) # Noite, da paleta
const COR_DESTAQUE := Color(0.9255, 0.7412, 0.4588) # Dourado claro
const FONTE_TITULO := preload("res://assets/fonts/cinzel/cinzel.ttf")
const ABAS: Array[String] = [Codice.TIPO_OLHAR, Codice.TIPO_CODICE]
const CHAVES_ABAS := {
	Codice.TIPO_OLHAR: "TELA_CODICE_ABA_OLHAR",
	Codice.TIPO_CODICE: "TELA_CODICE_ABA_CODICE",
}
const NOME_PONTO := "PontoNovo"

## Aba aberta ([constant Codice.TIPO_OLHAR] ou [constant Codice.TIPO_CODICE]).
var aba := Codice.TIPO_OLHAR
## Id da entrada mostrada; vazio quando nenhuma.
var entrada_escolhida := ""

var botao_codice: Button
var tela: Control
var botao_fechar: Button
var botoes_abas := {}
var lista: VBoxContainer
var vazio: Label
var titulo_entrada: Label
var texto_entrada: Label
var _em_dialogo := false


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	Codice.anotado.connect(_ao_mudar_codice)
	Codice.lido.connect(_ao_mudar_codice)
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	tela.hide()
	_atualizar_botao()


func _input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"abrir_codice") and not evento.is_echo():
		if aberta():
			get_viewport().set_input_as_handled()
			fechar()
		elif pode_abrir():
			get_viewport().set_input_as_handled()
			abrir()
	elif aberta() and evento.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func _process(_delta: float) -> void:
	# A bolsa (ou outra tela) pausa o jogo: o botão some enquanto isso.
	botao_codice.visible = pode_abrir()


func aberta() -> bool:
	return tela.visible


## Fechada, fora de conversa e com o jogo andando (nenhuma outra tela aberta).
func pode_abrir() -> bool:
	return not aberta() and not _em_dialogo and not get_tree().paused


func abrir() -> void:
	tela.show()
	botao_codice.hide()
	get_tree().paused = true
	# Abre na aba que tem novidade, se só uma tiver.
	if not Codice.tem_novidade(aba):
		for tipo in ABAS:
			if Codice.tem_novidade(tipo):
				aba = tipo
				break
	escolher_aba(aba)
	botao_fechar.grab_focus()


func fechar() -> void:
	tela.hide()
	get_tree().paused = false
	_atualizar_botao()


func escolher_aba(tipo: String) -> void:
	aba = tipo
	entrada_escolhida = ""
	_montar_lista()
	_atualizar()


## Mostra a entrada [param id] e a marca como lida.
func escolher_entrada(id: String) -> void:
	entrada_escolhida = id
	Codice.marcar_lido(id)
	_atualizar()


func _ao_mudar_codice(_id: String) -> void:
	_atualizar_botao()
	if aberta():
		if Codice.ids(aba).size() != lista.get_child_count():
			_montar_lista()
		_atualizar()


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	_em_dialogo = true


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	_em_dialogo = false


func _atualizar() -> void:
	for tipo: String in botoes_abas:
		var botao: Button = botoes_abas[tipo]
		botao.set_pressed_no_signal(tipo == aba)
		_ponto(botao, Codice.tem_novidade(tipo))
	for botao: Button in lista.get_children():
		var id := str(botao.name)
		botao.set_pressed_no_signal(id == entrada_escolhida)
		_ponto(botao, Codice.novo(id))
	vazio.visible = lista.get_child_count() == 0
	var tem := not entrada_escolhida.is_empty()
	titulo_entrada.text = Codice.titulo(entrada_escolhida) if tem else ""
	texto_entrada.text = Codice.texto(entrada_escolhida) if tem \
		else ("" if vazio.visible else tr("TELA_CODICE_ESCOLHA"))
	_atualizar_botao()


func _atualizar_botao() -> void:
	if botao_codice:
		_ponto(botao_codice, Codice.tem_novidade())


## Liga ou desliga o ponto dourado de "novo" no canto do [param botao].
func _ponto(botao: Button, mostrar: bool) -> void:
	var ponto := botao.get_node_or_null(NOME_PONTO) as Panel
	if ponto == null:
		ponto = Panel.new()
		ponto.name = NOME_PONTO
		ponto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = COR_DESTAQUE
		estilo.set_corner_radius_all(7)
		ponto.add_theme_stylebox_override("panel", estilo)
		ponto.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		ponto.offset_left = -22.0
		ponto.offset_right = -8.0
		ponto.offset_top = 8.0
		ponto.offset_bottom = 22.0
		botao.add_child(ponto)
	ponto.visible = mostrar


func _montar_lista() -> void:
	for filho in lista.get_children():
		lista.remove_child(filho)
		filho.queue_free()
	for id in Codice.ids(aba):
		var botao := _botao(Codice.titulo(id), escolher_entrada.bind(id))
		botao.name = id
		botao.toggle_mode = true
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lista.add_child(botao)


func _botao(chave: String, ao_apertar: Callable) -> Button:
	var botao := Button.new()
	botao.text = chave
	botao.custom_minimum_size = Vector2(150, ALTURA_BOTAO)
	botao.pressed.connect(ao_apertar)
	return botao


## A tela é montada por código para ficar igual em qualquer cena que a use.
func _montar() -> void:
	botao_codice = _botao("TELA_CODICE_BOTAO", abrir)
	botao_codice.name = "BotaoCodice"
	botao_codice.focus_mode = Control.FOCUS_NONE
	# Logo abaixo do botão da bolsa.
	botao_codice.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	botao_codice.offset_left = -32.0 - 150.0
	botao_codice.offset_right = -32.0
	botao_codice.offset_top = 32.0 + ALTURA_BOTAO + 12.0
	botao_codice.offset_bottom = 32.0 + 2.0 * ALTURA_BOTAO + 12.0
	botao_codice.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	add_child(botao_codice)

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

	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 32)
	tela.add_child(margem)

	var painel := PanelContainer.new()
	margem.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)

	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 12)
	coluna.add_child(topo)
	var titulo := Label.new()
	titulo.text = "TELA_CODICE_TITULO"
	titulo.add_theme_font_override("font", FONTE_TITULO)
	titulo.add_theme_font_size_override("font_size", 36)
	titulo.add_theme_color_override("font_color", COR_DESTAQUE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	var grupo := ButtonGroup.new()
	grupo.allow_unpress = false
	for tipo in ABAS:
		var botao := _botao(CHAVES_ABAS[tipo], escolher_aba.bind(tipo))
		botao.name = "Aba_" + tipo
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.custom_minimum_size.x = 260
		topo.add_child(botao)
		botoes_abas[tipo] = botao
	botao_fechar = _botao("TELA_CODICE_FECHAR", fechar)
	botao_fechar.name = "BotaoFechar"
	topo.add_child(botao_fechar)

	var corpo := HBoxContainer.new()
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_theme_constant_override("separation", 24)
	coluna.add_child(corpo)

	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(380, 0)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corpo.add_child(rolagem)
	var area := VBoxContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(area)
	lista = VBoxContainer.new()
	lista.name = "Lista"
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 8)
	area.add_child(lista)
	vazio = Label.new()
	vazio.name = "Vazio"
	vazio.text = "TELA_CODICE_VAZIO"
	area.add_child(vazio)

	var detalhe := VBoxContainer.new()
	detalhe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detalhe.add_theme_constant_override("separation", 12)
	corpo.add_child(detalhe)
	titulo_entrada = Label.new()
	titulo_entrada.name = "TituloEntrada"
	titulo_entrada.add_theme_font_override("font", FONTE_TITULO)
	titulo_entrada.add_theme_font_size_override("font_size", 30)
	titulo_entrada.add_theme_color_override("font_color", COR_DESTAQUE)
	titulo_entrada.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe.add_child(titulo_entrada)
	texto_entrada = Label.new()
	texto_entrada.name = "TextoEntrada"
	texto_entrada.add_theme_font_size_override("font_size", 22)
	texto_entrada.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe.add_child(texto_entrada)
