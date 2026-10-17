class_name TelaLoja
extends CanvasLayer
## Tela da loja: à esquerda o que o mercador vende, à direita o que o
## jogador pode vender da bolsa, no meio o item escolhido com preço,
## comparação com o equipado, quantidade (− e +) e o botão Comprar ou
## Vender. As regras (estoque, preço, bolsa cheia) ficam no autoload
## [code]Lojas[/code]; esta tela só mostra e chama.
## Abre por [method abrir] com o id da loja e fecha pelo botão Fechar ou Esc.
## O jogo fica pausado enquanto ela está aberta.

signal fechada

enum Lado { LOJA, BOLSA }

const ALTURA_BOTAO := 64.0
const TAMANHO_ITEM := Vector2(140, 112)
const COR_FUNDO := Color(0.0196, 0.0471, 0.0784, 0.85) # Noite, da paleta
const COR_DESTAQUE := Color(0.9255, 0.7412, 0.4588)    # Dourado claro
const COR_AVISO := Color(0.95, 0.55, 0.45)
const FONTE_TITULO := preload("res://assets/fonts/cinzel/cinzel.ttf")
const ENCAIXES_EQUIPADOS: Array[Item.Encaixe] = [
	Item.Encaixe.ARMA, Item.Encaixe.ESCUDO, Item.Encaixe.ARMADURA,
	Item.Encaixe.ELMO, Item.Encaixe.ACESSORIO,
]

## Quem compara e equipa. Por enquanto só Nicholas.
@export var personagem := "nicholas"

## Loja aberta agora; vazio quando fechada.
var id_loja := ""
var lado: Lado = Lado.LOJA
## Item mostrado no meio; vazio quando nenhum.
var item_escolhido := ""
var quantidade := 1

var tela: Control
var titulo: Label
var rotulo_dinheiro: Label
var botao_fechar: Button
var lista_loja: GridContainer
var lista_bolsa: GridContainer
var vazio_loja: Label
var vazio_bolsa: Label
var nome_item: Label
var descricao_item: Label
var comparacao_item: Label
var preco_item: Label
var linha_quantidade: HBoxContainer
var botao_menos: Button
var rotulo_quantidade: Label
var botao_mais: Button
var botao_negociar: Button
var aviso: Label

## Fecha a pausa só se foi esta tela que pausou.
var _pausou := false


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	Inventario.mudou.connect(_ao_mudar)
	Inventario.dinheiro_mudou.connect(_ao_mudar_dinheiro)
	Inventario.equipamento_mudou.connect(_ao_mudar_equipamento)
	Lojas.estoque_mudou.connect(_ao_mudar_estoque)
	tela.hide()


func _input(evento: InputEvent) -> void:
	if aberta() and evento.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func aberta() -> bool:
	return tela.visible


func abrir(loja: String) -> void:
	var dados := Lojas.loja(loja)
	if dados == null:
		push_error("TelaLoja: loja desconhecida '%s'." % loja)
		return
	id_loja = loja
	titulo.text = tr(dados.chave_nome)
	tela.show()
	_pausou = not get_tree().paused
	get_tree().paused = true
	item_escolhido = ""
	_atualizar()
	var primeiro := lista_loja.get_child(0) if lista_loja.get_child_count() > 0 else botao_fechar
	(primeiro as Control).grab_focus()


func fechar() -> void:
	if not aberta():
		return
	tela.hide()
	if _pausou:
		get_tree().paused = false
	_pausou = false
	id_loja = ""
	fechada.emit()


func escolher(novo_lado: Lado, id: String) -> void:
	lado = novo_lado
	item_escolhido = id
	quantidade = 1
	aviso.text = ""
	_atualizar()


func mudar_quantidade(passo: int) -> void:
	quantidade = clampi(quantidade + passo, 1, maxi(1, maximo()))
	_atualizar_detalhe()


## Até quanto dá para escolher: o estoque (comprar) ou o que há na bolsa (vender).
func maximo() -> int:
	if item_escolhido.is_empty():
		return 0
	if lado == Lado.LOJA:
		return Lojas.estoque(id_loja, item_escolhido)
	return Inventario.quantidade(item_escolhido)


## O que a bolsa tem que este mercador compra (os da história ficam de fora).
func itens_para_vender() -> Array[String]:
	var ids: Array[String] = []
	for tipo: Item.Tipo in Item.Tipo.values():
		for id in Inventario.ids_do_tipo(tipo):
			if Lojas.pode_vender(id) == Lojas.Resultado.OK:
				ids.append(id)
	return ids


## Aperta Comprar ou Vender. Devolve o resultado do Lojas.
func negociar() -> Lojas.Resultado:
	var resultado: Lojas.Resultado
	if lado == Lado.LOJA:
		resultado = Lojas.comprar(id_loja, item_escolhido, quantidade)
	else:
		resultado = Lojas.vender(item_escolhido, quantidade)
	if resultado == Lojas.Resultado.OK:
		aviso.text = tr("LOJA_COMPROU") if lado == Lado.LOJA else tr("LOJA_VENDEU")
		aviso.add_theme_color_override("font_color", COR_DESTAQUE)
		if lado == Lado.BOLSA and not Inventario.tem(item_escolhido):
			item_escolhido = ""
		quantidade = clampi(quantidade, 1, maxi(1, maximo()))
		_atualizar()
	return resultado


## Diferença para o que está equipado no mesmo encaixe, numa linha.
## Vazio para o que não se equipa.
static func texto_comparacao(dados: Item, quem: String) -> String:
	if dados == null or not dados.pode_equipar():
		return ""
	var id_equipado := Inventario.equipado(quem, dados.encaixe)
	if id_equipado == dados.id:
		return TranslationServer.translate("LOJA_COMPARA_IGUAL")
	var atual := Inventario.item(id_equipado) if not id_equipado.is_empty() else null
	var partes: PackedStringArray = []
	var diferencas := [
		["BOLSA_ATAQUE", dados.ataque - (atual.ataque if atual else 0)],
		["BOLSA_DEFESA", dados.defesa - (atual.defesa if atual else 0)],
		["BOLSA_VELOCIDADE", dados.velocidade - (atual.velocidade if atual else 0)],
	]
	for par in diferencas:
		if par[1] != 0:
			partes.append(TranslationServer.translate(par[0]) % par[1])
	if partes.is_empty():
		partes.append(TranslationServer.translate("LOJA_COMPARA_SEM_DIFERENCA"))
	var chave := "LOJA_COMPARA" if atual else "LOJA_COMPARA_NADA"
	return TranslationServer.translate(chave) % " · ".join(partes)


## Aviso de por que não dá para comprar ou vender; vazio quando dá.
static func texto_resultado(resultado: Lojas.Resultado) -> String:
	match resultado:
		Lojas.Resultado.SEM_MOEDAS:
			return TranslationServer.translate("LOJA_SEM_MOEDAS")
		Lojas.Resultado.BOLSA_CHEIA:
			return TranslationServer.translate("LOJA_BOLSA_CHEIA")
		Lojas.Resultado.SEM_ESTOQUE:
			return TranslationServer.translate("LOJA_SEM_ESTOQUE")
	return ""


func _ao_mudar(_id: String, _qtd: int) -> void:
	if aberta():
		_atualizar()


func _ao_mudar_dinheiro(_valor: int) -> void:
	if aberta():
		_atualizar()


func _ao_mudar_equipamento(_quem: String, _encaixe: Item.Encaixe, _id: String) -> void:
	if aberta():
		_atualizar()


func _ao_mudar_estoque(_loja: String, _id: String) -> void:
	if aberta():
		_atualizar()


func _atualizar() -> void:
	rotulo_dinheiro.text = tr("BOLSA_MOEDAS") % Inventario.dinheiro()
	_encher(lista_loja, Lado.LOJA, Lojas.mercadorias(id_loja))
	_encher(lista_bolsa, Lado.BOLSA, itens_para_vender())
	vazio_loja.visible = lista_loja.get_child_count() == 0
	vazio_bolsa.visible = lista_bolsa.get_child_count() == 0
	_atualizar_detalhe()


func _encher(lista: GridContainer, lado_lista: Lado, ids: Array[String]) -> void:
	var foco := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var nome_foco := foco.name if foco and foco.get_parent() == lista else &""
	for filho in lista.get_children():
		lista.remove_child(filho)
		filho.free()
	for id in ids:
		var botao := _botao_item(lado_lista, id)
		lista.add_child(botao)
		if botao.name == nome_foco:
			botao.grab_focus()


func _atualizar_detalhe() -> void:
	var dados := Inventario.item(item_escolhido) if not item_escolhido.is_empty() else null
	var tem_item := dados != null
	nome_item.text = tr(dados.chave_nome) if tem_item else ""
	descricao_item.text = tr(dados.chave_descricao) if tem_item else tr("LOJA_ESCOLHA_ITEM")
	var bonus := TelaBolsa.texto_bonus(dados) if tem_item else ""
	if not bonus.is_empty():
		descricao_item.text += "\n" + bonus
	comparacao_item.text = texto_comparacao(dados, personagem) if tem_item else ""
	linha_quantidade.visible = tem_item
	botao_negociar.visible = tem_item
	if not tem_item:
		preco_item.text = ""
		return
	quantidade = clampi(quantidade, 1, maxi(1, maximo()))
	rotulo_quantidade.text = str(quantidade)
	botao_menos.disabled = quantidade <= 1
	botao_mais.disabled = quantidade >= maximo()
	var resultado: Lojas.Resultado
	if lado == Lado.LOJA:
		var preco := Lojas.preco_compra(id_loja, item_escolhido)
		preco_item.text = tr("LOJA_PRECO") % [preco, preco * quantidade]
		botao_negociar.text = tr("LOJA_COMPRAR")
		resultado = Lojas.pode_comprar(id_loja, item_escolhido, quantidade)
	else:
		var preco := Lojas.preco_venda(item_escolhido)
		preco_item.text = tr("LOJA_PAGA") % [preco, preco * quantidade]
		botao_negociar.text = tr("LOJA_VENDER")
		resultado = Lojas.pode_vender(item_escolhido, quantidade)
		if resultado == Lojas.Resultado.OK and dados.pode_equipar() \
				and Inventario.equipado(personagem, dados.encaixe) == item_escolhido \
				and quantidade >= Inventario.quantidade(item_escolhido):
			comparacao_item.text = tr("LOJA_VAI_DESEQUIPAR")
	botao_negociar.disabled = resultado != Lojas.Resultado.OK
	if resultado != Lojas.Resultado.OK:
		aviso.text = texto_resultado(resultado)
		aviso.add_theme_color_override("font_color", COR_AVISO)
	elif aviso.get_theme_color("font_color") == COR_AVISO:
		aviso.text = ""


func _botao_item(lado_lista: Lado, id: String) -> Button:
	var dados := Inventario.item(id)
	var botao := Button.new()
	botao.name = id
	botao.custom_minimum_size = TAMANHO_ITEM
	botao.toggle_mode = true
	botao.button_pressed = lado_lista == lado and id == item_escolhido
	botao.icon = TelaBolsa.icone_ampliado(dados.icone)
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	botao.expand_icon = false
	botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	botao.add_theme_font_size_override("font_size", 14)
	var linhas := PackedStringArray([tr(dados.chave_nome)])
	if lado_lista == Lado.LOJA:
		var resta := Lojas.estoque(id_loja, id)
		linhas.append(tr("LOJA_ITEM_PRECO") % [Lojas.preco_compra(id_loja, id), resta])
		botao.modulate.a = 1.0 if resta > 0 else 0.5
	else:
		var qtd := Inventario.quantidade(id)
		linhas.append(tr("LOJA_ITEM_VENDA") % [Lojas.preco_venda(id), qtd])
		for encaixe in ENCAIXES_EQUIPADOS:
			if Inventario.equipado(personagem, encaixe) == id:
				linhas.append(tr("BOLSA_EQUIPADO"))
	botao.text = "\n".join(linhas)
	botao.pressed.connect(escolher.bind(lado_lista, id))
	return botao


func _botao(chave: String, ao_apertar: Callable, largura := 150.0) -> Button:
	var botao := Button.new()
	botao.text = chave
	botao.custom_minimum_size = Vector2(largura, ALTURA_BOTAO)
	botao.pressed.connect(ao_apertar)
	return botao


func _coluna_lista(chave_titulo: String, chave_vazio: String) -> Array:
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	var rotulo := Label.new()
	rotulo.text = chave_titulo
	rotulo.add_theme_color_override("font_color", COR_DESTAQUE)
	coluna.add_child(rotulo)
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.custom_minimum_size.x = TAMANHO_ITEM.x * 2 + 8 + 12
	coluna.add_child(rolagem)
	var dentro := VBoxContainer.new()
	rolagem.add_child(dentro)
	var lista := GridContainer.new()
	lista.columns = 2
	lista.add_theme_constant_override("h_separation", 8)
	lista.add_theme_constant_override("v_separation", 8)
	dentro.add_child(lista)
	var vazio := Label.new()
	vazio.text = chave_vazio
	vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vazio.custom_minimum_size.x = TAMANHO_ITEM.x * 2
	dentro.add_child(vazio)
	return [coluna, lista, vazio]


## Montada por código, como a bolsa, para ficar igual em qualquer cena.
func _montar() -> void:
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
	for lado_margem in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado_margem, 24)
	tela.add_child(margem)
	var painel := PanelContainer.new()
	margem.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)

	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 24)
	coluna.add_child(topo)
	titulo = Label.new()
	titulo.name = "Titulo"
	titulo.add_theme_font_override("font", FONTE_TITULO)
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.add_theme_color_override("font_color", COR_DESTAQUE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	rotulo_dinheiro = Label.new()
	rotulo_dinheiro.name = "Dinheiro"
	rotulo_dinheiro.add_theme_font_size_override("font_size", 22)
	topo.add_child(rotulo_dinheiro)
	botao_fechar = _botao("BOLSA_FECHAR", fechar)
	botao_fechar.name = "Fechar"
	topo.add_child(botao_fechar)

	var corpo := HBoxContainer.new()
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_theme_constant_override("separation", 20)
	coluna.add_child(corpo)

	var parte_loja := _coluna_lista("LOJA_A_VENDA", "LOJA_NADA_A_VENDA")
	corpo.add_child(parte_loja[0])
	lista_loja = parte_loja[1]
	lista_loja.name = "ListaLoja"
	vazio_loja = parte_loja[2]

	var detalhe := VBoxContainer.new()
	detalhe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detalhe.add_theme_constant_override("separation", 10)
	corpo.add_child(detalhe)
	nome_item = Label.new()
	nome_item.add_theme_font_size_override("font_size", 26)
	nome_item.add_theme_color_override("font_color", COR_DESTAQUE)
	nome_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe.add_child(nome_item)
	descricao_item = Label.new()
	descricao_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe.add_child(descricao_item)
	comparacao_item = Label.new()
	comparacao_item.name = "Comparacao"
	comparacao_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparacao_item.add_theme_color_override("font_color", COR_DESTAQUE)
	detalhe.add_child(comparacao_item)
	var espaco := Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detalhe.add_child(espaco)
	preco_item = Label.new()
	preco_item.name = "Preco"
	preco_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe.add_child(preco_item)
	linha_quantidade = HBoxContainer.new()
	linha_quantidade.alignment = BoxContainer.ALIGNMENT_CENTER
	linha_quantidade.add_theme_constant_override("separation", 12)
	detalhe.add_child(linha_quantidade)
	botao_menos = _botao("−", mudar_quantidade.bind(-1), ALTURA_BOTAO)
	botao_menos.name = "Menos"
	linha_quantidade.add_child(botao_menos)
	rotulo_quantidade = Label.new()
	rotulo_quantidade.name = "Quantidade"
	rotulo_quantidade.custom_minimum_size.x = 48
	rotulo_quantidade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_quantidade.add_theme_font_size_override("font_size", 26)
	linha_quantidade.add_child(rotulo_quantidade)
	botao_mais = _botao("+", mudar_quantidade.bind(1), ALTURA_BOTAO)
	botao_mais.name = "Mais"
	linha_quantidade.add_child(botao_mais)
	botao_negociar = _botao("LOJA_COMPRAR", negociar)
	botao_negociar.name = "Negociar"
	detalhe.add_child(botao_negociar)
	aviso = Label.new()
	aviso.name = "Aviso"
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_color_override("font_color", COR_AVISO)
	detalhe.add_child(aviso)

	var parte_bolsa := _coluna_lista("LOJA_SUA_BOLSA", "LOJA_NADA_PARA_VENDER")
	corpo.add_child(parte_bolsa[0])
	lista_bolsa = parte_bolsa[1]
	lista_bolsa.name = "ListaBolsa"
	vazio_bolsa = parte_bolsa[2]
