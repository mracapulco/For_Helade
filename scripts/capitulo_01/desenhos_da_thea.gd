class_name DesenhosDaThea
extends CanvasLayer
## Jogo dos desenhos da Thea, na sala lateral da loja de pelúcias (Capítulo
## 01; regra do jogo, não do livro: Rafael, 21/10/2026).
## - Ao lado da tela ficam os desenhos das pelúcias que a Thea já tem; os
##   achados ganham um visto.
## - [method comparar] mostra a pelúcia de uma prateleira, grande, e pergunta
##   a qual desenho ela é igual (ou nenhum). A resposta sai em [signal respondido].
## Botões grandes, para toque; teclado: setas e Enter.
## Textos: i18n/strings.csv (DESENHOS_*).

## Resposta do jogador: o id do desenho ou "" para "Nenhum desses".
signal respondido(resposta: String)

const ARTE := "res://assets/art/capitulo_01/loja/"
## Quanto a pelúcia e os desenhos crescem na tela (pixel art).
const ESCALA_PELUCIA := 6.0
const LADO_DESENHO := 150.0
const LADO_DESENHO_PAINEL := 72.0
const COR_FUNDO := Color(0.06, 0.07, 0.12, 0.92)
const COR_OURO := Color(0.93, 0.78, 0.45)

var desenhos: Array[String] = []
var achados: Array[String] = []
var _painel: VBoxContainer
var _vistos := {}
var _janela: Control


func _init() -> void:
	layer = 8


## Mostra o painel com os desenhos (ids como "polvo": loja/desenho_polvo.png).
func mostrar(ids: Array[String]) -> void:
	desenhos = ids
	_painel = VBoxContainer.new()
	_painel.name = "Painel"
	_painel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_painel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_painel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_painel.offset_left = -20.0
	_painel.offset_right = -20.0
	_painel.offset_top = 0.0
	_painel.offset_bottom = 0.0
	_painel.add_theme_constant_override("separation", 8)
	var titulo := Label.new()
	titulo.text = tr("DESENHOS_TITULO")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", COR_OURO)
	_painel.add_child(titulo)
	for id in desenhos:
		var quadro := TextureRect.new()
		quadro.texture = load(ARTE + "desenho_%s.png" % id)
		quadro.custom_minimum_size = Vector2.ONE * LADO_DESENHO_PAINEL
		quadro.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		quadro.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		quadro.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		quadro.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var visto := Label.new()
		visto.text = "✓"
		visto.add_theme_font_size_override("font_size", 40)
		visto.add_theme_color_override("font_color", Color(0.45, 0.85, 0.45))
		visto.position = Vector2(LADO_DESENHO_PAINEL - 30.0, LADO_DESENHO_PAINEL - 50.0)
		visto.visible = false
		quadro.add_child(visto)
		_vistos[id] = visto
		_painel.add_child(quadro)
	add_child(_painel)


## Marca o desenho como achado (a pelúcia dele já está com a Thea).
func marcar(id: String) -> void:
	if not achados.has(id):
		achados.append(id)
	if _vistos.has(id):
		_vistos[id].visible = true


## Abre a comparação com a pelúcia [param pelucia] (loja/pelucia_<id>.png).
func comparar(pelucia: String) -> void:
	fechar()
	_janela = Control.new()
	_janela.name = "Comparar"
	_janela.set_anchors_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_janela.add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_janela.add_child(centro)
	var caixa := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_FUNDO
	estilo.border_color = COR_OURO
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(20)
	caixa.add_theme_stylebox_override("panel", estilo)
	centro.add_child(caixa)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 14)
	caixa.add_child(coluna)
	var imagem := TextureRect.new()
	imagem.texture = load(ARTE + "pelucia_%s.png" % pelucia)
	imagem.custom_minimum_size = imagem.texture.get_size() * ESCALA_PELUCIA
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(imagem)
	var pergunta := Label.new()
	pergunta.text = tr("DESENHOS_PERGUNTA")
	pergunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(pergunta)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 12)
	coluna.add_child(linha)
	var primeiro: Button = null
	for id in desenhos:
		var botao := Button.new()
		botao.name = "Desenho_" + id
		botao.icon = load(ARTE + "desenho_%s.png" % id)
		botao.expand_icon = true
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.custom_minimum_size = Vector2.ONE * LADO_DESENHO
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.disabled = achados.has(id)
		botao.pressed.connect(_responder.bind(id))
		linha.add_child(botao)
		if primeiro == null and not botao.disabled:
			primeiro = botao
	var nenhum := Button.new()
	nenhum.name = "Nenhum"
	nenhum.text = tr("DESENHOS_NENHUM")
	nenhum.custom_minimum_size = Vector2(0, 56)
	nenhum.pressed.connect(_responder.bind(""))
	coluna.add_child(nenhum)
	add_child(_janela)
	(primeiro if primeiro else nenhum).grab_focus.call_deferred()


func fechar() -> void:
	if _janela:
		_janela.queue_free()
		_janela = null


func aberto() -> bool:
	return _janela != null


func _responder(resposta: String) -> void:
	fechar()
	respondido.emit(resposta)
