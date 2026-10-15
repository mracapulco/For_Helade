class_name EspacoBolsa
extends Button
## Um espaço da bolsa (barra rápida ou grade): ícone do item, quantidade
## no canto, número da tecla (1 a 9) e moldura dourada quando o item está
## equipado ou escolhido. Botão grande, pensado para o toque.

const TAMANHO := Vector2(64, 64)
const COR_FUNDO := Color(0.0196, 0.0471, 0.0784, 0.8)     # Noite
const COR_BORDA := Color(0.4, 0.33, 0.24)                 # Dourado apagado
const COR_DESTAQUE := Color(0.9255, 0.7412, 0.4588)       # Dourado claro
const COR_FORA_DO_LIMITE := Color(0.45, 0.2, 0.2, 0.8)

## Índice do espaço no Inventario.
var indice := 0
## Item equipado por quem joga: moldura dourada grossa.
var equipado := false
## Escolhido na grade para trocar de lugar.
var escolhido := false
## Espaço além do limite da idade (bolsa que encolheu).
var fora_do_limite := false

var _icone: TextureRect
var _numero: Label
var _quantidade: Label


func _init() -> void:
	custom_minimum_size = TAMANHO
	focus_mode = Control.FOCUS_NONE
	flat = true
	clip_contents = true
	add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	# Ícone num TextureRect (e não no icon do botão) para o espaço não
	# crescer com o tamanho do desenho.
	_icone = TextureRect.new()
	_icone.name = "Icone"
	_icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["offset_left", "offset_top"]:
		_icone.set(lado, 8.0)
	for lado in ["offset_right", "offset_bottom"]:
		_icone.set(lado, -8.0)
	_icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_icone)
	_numero = _rotulo(Control.PRESET_TOP_LEFT, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	_numero.name = "Numero"
	_quantidade = _rotulo(Control.PRESET_FULL_RECT, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_BOTTOM)
	_quantidade.name = "Quantidade"


## Mostra o número da tecla (1 a 9); 0 esconde.
func mostrar_numero(numero: int) -> void:
	_numero.text = str(numero) if numero > 0 else ""


## Atualiza a partir do Inventario.
func atualizar(personagem: String) -> void:
	var conteudo := Inventario.espaco(indice)
	fora_do_limite = indice >= Inventario.capacidade()
	if conteudo.is_empty():
		_icone.texture = null
		tooltip_text = ""
		_quantidade.text = ""
		equipado = false
	else:
		var dados := Inventario.item(conteudo["id"])
		_icone.texture = dados.icone
		tooltip_text = tr(dados.chave_nome)
		var qtd := int(conteudo["quantidade"])
		_quantidade.text = str(qtd) if qtd > 1 else ""
		equipado = dados.pode_equipar() and Inventario.equipado(personagem, dados.encaixe) == dados.id
		if dados.icone == null:
			_quantidade.text = tr(dados.chave_nome).left(3) + ("\n" + str(qtd) if qtd > 1 else "")
	queue_redraw()


func vazio() -> bool:
	return Inventario.espaco(indice).is_empty()


func _draw() -> void:
	var caixa := Rect2(Vector2.ZERO, size)
	draw_rect(caixa, COR_FORA_DO_LIMITE if fora_do_limite else COR_FUNDO)
	var destaque := equipado or escolhido
	var largura := 4.0 if destaque else 2.0
	draw_rect(caixa.grow(-largura / 2.0), COR_DESTAQUE if destaque else COR_BORDA, false, largura)


func _rotulo(preset: Control.LayoutPreset, horizontal: HorizontalAlignment,
		vertical: VerticalAlignment) -> Label:
	var rotulo := Label.new()
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.set_anchors_preset(preset)
	rotulo.offset_left = 4.0
	rotulo.offset_right = -4.0 if preset == Control.PRESET_FULL_RECT else 20.0
	rotulo.offset_top = 2.0
	rotulo.offset_bottom = -2.0 if preset == Control.PRESET_FULL_RECT else 22.0
	rotulo.horizontal_alignment = horizontal
	rotulo.vertical_alignment = vertical
	rotulo.add_theme_font_size_override("font_size", 15)
	rotulo.add_theme_color_override("font_outline_color", COR_FUNDO)
	rotulo.add_theme_constant_override("outline_size", 4)
	add_child(rotulo)
	return rotulo
