class_name TelaBolsa
extends CanvasLayer
## Tela da bolsa: abas por tipo, lista de itens, detalhe do item e botões
## grandes de Usar, Equipar e Largar. Abre pelo botão "Bolsa" (toque ou
## clique) ou pelas teclas I e Tab; fecha pelo botão Fechar, I, Tab ou Esc.
## O jogo fica pausado enquanto ela está aberta.

const ABAS: Array[Item.Tipo] = [
	Item.Tipo.ARMA, Item.Tipo.EQUIPAMENTO, Item.Tipo.CONSUMIVEL,
	Item.Tipo.HISTORIA, Item.Tipo.DIVERSOS,
]
const CHAVES_ABA := {
	Item.Tipo.ARMA: "BOLSA_ABA_ARMAS",
	Item.Tipo.EQUIPAMENTO: "BOLSA_ABA_EQUIPAMENTO",
	Item.Tipo.CONSUMIVEL: "BOLSA_ABA_CONSUMIVEIS",
	Item.Tipo.HISTORIA: "BOLSA_ABA_HISTORIA",
	Item.Tipo.DIVERSOS: "BOLSA_ABA_DIVERSOS",
}
const ALTURA_BOTAO := 72.0
## Quantas vezes o ícone em pixel art aparece ampliado na bolsa (como o
## zoom 2 da exploração).
const ESCALA_ICONE := 2
const COR_FUNDO := Color(0.0196, 0.0471, 0.0784, 0.75) # Noite, da paleta
const COR_DESTAQUE := Color(0.9255, 0.7412, 0.4588) # Dourado claro
const FONTE_TITULO := preload("res://assets/fonts/cinzel/cinzel.ttf")

## Quem usa e equipa. Por enquanto só Nicholas; a escolha entre os
## personagens do grupo entra quando existir o grupo.
@export var personagem := "nicholas"

## Provisório: põe itens de teste na bolsa vazia ao abrir a cena.
@export var itens_de_teste := false

var aba_atual: Item.Tipo = Item.Tipo.ARMA
## Id do item mostrado no detalhe; vazio quando nenhum.
var item_escolhido := ""

var botao_bolsa: Button
var tela: Control
var rotulo_dinheiro: Label
var botao_fechar: Button
var botoes_aba: Dictionary[Item.Tipo, Button] = {}
var lista: GridContainer
var rotulo_vazio: Label
var nome_item: Label
var descricao_item: Label
var aviso_item: Label
var botao_usar: Button
var botao_equipar: Button
var botao_largar: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	# Métodos (e não funções soltas) para a ligação cair sozinha quando a
	# tela sai de cena; os sinais são de autoloads, que continuam vivos.
	Inventario.mudou.connect(_ao_mudar_item)
	Inventario.dinheiro_mudou.connect(_ao_mudar_dinheiro)
	Inventario.equipamento_mudou.connect(_ao_mudar_equipamento)
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	if itens_de_teste:
		_por_itens_de_teste()
	tela.hide()


func _input(evento: InputEvent) -> void:
	# Em _input, antes da interface: Tab também troca o foco entre botões,
	# e aqui ele precisa fechar a bolsa.
	if evento.is_action_pressed(&"abrir_bolsa") and not evento.is_echo():
		get_viewport().set_input_as_handled()
		if aberta():
			fechar()
		elif botao_bolsa.visible:
			abrir()
	elif aberta() and evento.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func aberta() -> bool:
	return tela.visible


func abrir() -> void:
	tela.show()
	botao_bolsa.hide()
	get_tree().paused = true
	mostrar_aba(aba_atual)
	_atualizar_dinheiro()
	botoes_aba[aba_atual].grab_focus()


func fechar() -> void:
	tela.hide()
	botao_bolsa.show()
	get_tree().paused = false


func mostrar_aba(tipo: Item.Tipo) -> void:
	aba_atual = tipo
	for outro: Item.Tipo in botoes_aba:
		botoes_aba[outro].set_pressed_no_signal(outro == tipo)
	escolher_item("")
	_atualizar()


func escolher_item(id: String) -> void:
	item_escolhido = id
	_atualizar_detalhe()


## Ids na ordem em que aparecem na aba atual.
func itens_da_aba() -> Array[String]:
	return Inventario.ids_do_tipo(aba_atual)


func _ao_mudar_item(_id: String, _quantidade: int) -> void:
	_atualizar()


func _ao_mudar_dinheiro(_valor: int) -> void:
	_atualizar_dinheiro()


func _ao_mudar_equipamento(_personagem: String, _encaixe: Item.Encaixe, _id: String) -> void:
	_atualizar()


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	botao_bolsa.hide()


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	botao_bolsa.visible = not aberta()


func _usar() -> void:
	Inventario.usar(item_escolhido, personagem)


func _equipar() -> void:
	var dados := Inventario.item(item_escolhido)
	if Inventario.equipado(personagem, dados.encaixe) == item_escolhido:
		Inventario.desequipar(personagem, dados.encaixe)
	else:
		Inventario.equipar(personagem, item_escolhido)


func _largar() -> void:
	Inventario.largar(item_escolhido)


func _atualizar() -> void:
	for filho in lista.get_children():
		lista.remove_child(filho)
		filho.free()
	var ids := itens_da_aba()
	for id in ids:
		lista.add_child(_botao_item(id))
	rotulo_vazio.visible = ids.is_empty()
	if not Inventario.tem(item_escolhido):
		item_escolhido = ""
	_atualizar_detalhe()


func _atualizar_dinheiro() -> void:
	rotulo_dinheiro.text = tr("BOLSA_MOEDAS") % Inventario.dinheiro()


func _atualizar_detalhe() -> void:
	var dados := Inventario.item(item_escolhido) if not item_escolhido.is_empty() else null
	var tem_item := dados != null
	nome_item.text = tr(dados.chave_nome) if tem_item else ""
	descricao_item.text = tr(dados.chave_descricao) if tem_item else tr("BOLSA_ESCOLHA_ITEM")
	aviso_item.text = tr("BOLSA_ITEM_DA_HISTORIA") if tem_item and dados.e_da_historia() else ""
	botao_usar.visible = tem_item and dados.pode_usar()
	botao_equipar.visible = tem_item and dados.pode_equipar()
	botao_largar.visible = tem_item and not dados.e_da_historia()
	if tem_item and dados.pode_equipar():
		var equipado := Inventario.equipado(personagem, dados.encaixe) == item_escolhido
		botao_equipar.text = tr("BOLSA_DESEQUIPAR") if equipado else tr("BOLSA_EQUIPAR")


## Cópia do ícone [constant ESCALA_ICONE] vezes maior, sem borrar os pixels.
## Sem ícone, devolve null (o botão fica só com o nome).
static func icone_ampliado(icone: Texture2D) -> Texture2D:
	if icone == null:
		return null
	var original := icone.get_image()
	if original == null:
		return icone
	# Cópia: em alguns renderizadores get_image() devolve a imagem guardada
	# na própria textura, e redimensioná-la estragaria o ícone.
	var imagem := Image.new()
	imagem.copy_from(original)
	imagem.resize(imagem.get_width() * ESCALA_ICONE, imagem.get_height() * ESCALA_ICONE,
		Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(imagem)


func _botao_item(id: String) -> Button:
	var dados := Inventario.item(id)
	var botao := Button.new()
	botao.name = id
	botao.custom_minimum_size = Vector2(170, 120)
	botao.toggle_mode = true
	botao.button_pressed = id == item_escolhido
	botao.icon = icone_ampliado(dados.icone)
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	botao.expand_icon = false
	botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var texto := tr(dados.chave_nome)
	if Inventario.quantidade(id) > 1:
		texto += "\n×%d" % Inventario.quantidade(id)
	for encaixe: Item.Encaixe in [Item.Encaixe.ARMA, Item.Encaixe.ARMADURA, Item.Encaixe.ACESSORIO]:
		if Inventario.equipado(personagem, encaixe) == id:
			texto += "\n" + tr("BOLSA_EQUIPADO")
	botao.text = texto
	botao.pressed.connect(func() -> void:
		escolher_item(id)
		for outro in lista.get_children():
			(outro as Button).set_pressed_no_signal(outro == botao))
	return botao


func _por_itens_de_teste() -> void:
	if Inventario.dinheiro() > 0 or not Inventario.ids_do_tipo(Item.Tipo.ARMA).is_empty():
		return
	Inventario.adicionar("espada_teste")
	Inventario.adicionar("pocao_teste", 3)
	Inventario.adicionar("carta_teste")
	Inventario.ganhar_dinheiro(20)


func _botao(chave: String, ao_apertar: Callable) -> Button:
	var botao := Button.new()
	botao.text = chave
	botao.custom_minimum_size = Vector2(150, ALTURA_BOTAO)
	botao.pressed.connect(ao_apertar)
	return botao


## A tela é montada por código para ficar igual em qualquer cena que a use.
func _montar() -> void:
	botao_bolsa = _botao("BOLSA_BOTAO", abrir)
	botao_bolsa.name = "BotaoBolsa"
	botao_bolsa.focus_mode = Control.FOCUS_NONE
	botao_bolsa.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	botao_bolsa.offset_left = -32.0 - 150.0
	botao_bolsa.offset_right = -32.0
	botao_bolsa.offset_top = 32.0
	botao_bolsa.offset_bottom = 32.0 + ALTURA_BOTAO
	botao_bolsa.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	add_child(botao_bolsa)

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
		margem.add_theme_constant_override("margin_" + lado, 40)
	tela.add_child(margem)

	var painel := PanelContainer.new()
	margem.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 16)
	painel.add_child(coluna)

	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 24)
	coluna.add_child(topo)
	var titulo := Label.new()
	titulo.text = "BOLSA_TITULO"
	titulo.add_theme_font_override("font", FONTE_TITULO)
	titulo.add_theme_font_size_override("font_size", 36)
	titulo.add_theme_color_override("font_color", COR_DESTAQUE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	rotulo_dinheiro = Label.new()
	rotulo_dinheiro.name = "Dinheiro"
	topo.add_child(rotulo_dinheiro)
	botao_fechar = _botao("BOLSA_FECHAR", fechar)
	topo.add_child(botao_fechar)

	var abas := HBoxContainer.new()
	abas.add_theme_constant_override("separation", 8)
	coluna.add_child(abas)
	for tipo in ABAS:
		var botao := _botao(CHAVES_ABA[tipo], mostrar_aba.bind(tipo))
		botao.toggle_mode = true
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		abas.add_child(botao)
		botoes_aba[tipo] = botao

	var corpo := HBoxContainer.new()
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_theme_constant_override("separation", 24)
	coluna.add_child(corpo)

	var rolagem := ScrollContainer.new()
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corpo.add_child(rolagem)
	var area_lista := VBoxContainer.new()
	area_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(area_lista)
	lista = GridContainer.new()
	lista.name = "Lista"
	lista.columns = 4
	lista.add_theme_constant_override("h_separation", 12)
	lista.add_theme_constant_override("v_separation", 12)
	area_lista.add_child(lista)
	rotulo_vazio = Label.new()
	rotulo_vazio.text = "BOLSA_VAZIA"
	area_lista.add_child(rotulo_vazio)

	var detalhe := VBoxContainer.new()
	detalhe.custom_minimum_size = Vector2(360, 0)
	detalhe.add_theme_constant_override("separation", 12)
	corpo.add_child(detalhe)
	nome_item = Label.new()
	nome_item.add_theme_font_size_override("font_size", 30)
	nome_item.add_theme_color_override("font_color", COR_DESTAQUE)
	nome_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe.add_child(nome_item)
	descricao_item = Label.new()
	descricao_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe.add_child(descricao_item)
	aviso_item = Label.new()
	aviso_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso_item.add_theme_color_override("font_color", COR_DESTAQUE)
	detalhe.add_child(aviso_item)
	var espaco := Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detalhe.add_child(espaco)
	botao_usar = _botao("BOLSA_USAR", _usar)
	botao_equipar = _botao("BOLSA_EQUIPAR", _equipar)
	botao_largar = _botao("BOLSA_LARGAR", _largar)
	for botao in [botao_usar, botao_equipar, botao_largar]:
		detalhe.add_child(botao)
