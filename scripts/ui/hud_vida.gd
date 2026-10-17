class_name HudVida
extends CanvasLayer
## Barra de vida do jogador no canto de cima à esquerda, com os números e as
## poções que estão fazendo efeito (nome e segundos que faltam).
## A parte de vida a mais (poção de vigor) aparece dourada no fim da barra.
## Embaixo, o nível e uma barra fina da experiência até o próximo.

@export var vida: Vida
@export var efeitos: EfeitosTemporarios
## De quem é o nível mostrado (Experiencia).
@export var personagem := "nicholas"

const COR_FUNDO := Color(0.0196, 0.0471, 0.0784, 0.75)    # Noite
const COR_BORDA := Color(0.7255, 0.5216, 0.2627)          # Dourado
const COR_VIDA := Color(0.71, 0.22, 0.23)
const COR_EXTRA := Color(0.9255, 0.7412, 0.4588)          # Dourado claro
const TAMANHO_BARRA := Vector2(240, 22)
const TAMANHO_BARRA_EXPERIENCIA := Vector2(240, 6)

var barra: Control
var rotulo: Label
var rotulo_efeitos: Label
var rotulo_nivel: Label
var barra_experiencia: Control


func _ready() -> void:
	layer = 10
	_montar()
	if vida:
		vida.mudou.connect(func(_a: int, _m: int) -> void: atualizar())
	if efeitos:
		efeitos.mudou.connect(atualizar)
	Experiencia.mudou.connect(func(_p: String, _e: int) -> void: atualizar())
	atualizar()


func _montar() -> void:
	var caixa := VBoxContainer.new()
	caixa.name = "Caixa"
	caixa.position = Vector2(16, 16)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caixa)
	barra = Control.new()
	barra.name = "Barra"
	barra.custom_minimum_size = TAMANHO_BARRA
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.draw.connect(_desenhar_barra)
	caixa.add_child(barra)
	rotulo = Label.new()
	rotulo.name = "Numeros"
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotulo.add_theme_font_size_override("font_size", 15)
	rotulo.add_theme_color_override("font_outline_color", COR_FUNDO)
	rotulo.add_theme_constant_override("outline_size", 4)
	barra.add_child(rotulo)
	barra_experiencia = Control.new()
	barra_experiencia.name = "BarraExperiencia"
	barra_experiencia.custom_minimum_size = TAMANHO_BARRA_EXPERIENCIA
	barra_experiencia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_experiencia.draw.connect(_desenhar_experiencia)
	caixa.add_child(barra_experiencia)
	rotulo_nivel = Label.new()
	rotulo_nivel.name = "Nivel"
	rotulo_nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo_nivel.add_theme_font_size_override("font_size", 15)
	rotulo_nivel.add_theme_color_override("font_outline_color", COR_FUNDO)
	rotulo_nivel.add_theme_constant_override("outline_size", 4)
	caixa.add_child(rotulo_nivel)
	rotulo_efeitos = Label.new()
	rotulo_efeitos.name = "Efeitos"
	rotulo_efeitos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo_efeitos.add_theme_font_size_override("font_size", 15)
	rotulo_efeitos.add_theme_color_override("font_color", COR_EXTRA)
	rotulo_efeitos.add_theme_color_override("font_outline_color", COR_FUNDO)
	rotulo_efeitos.add_theme_constant_override("outline_size", 4)
	caixa.add_child(rotulo_efeitos)


func atualizar() -> void:
	if vida:
		rotulo.text = tr("HUD_VIDA") % [vida.atual, vida.maxima_total()]
	rotulo_efeitos.text = texto_efeitos()
	rotulo_nivel.text = tr("HUD_NIVEL") % Experiencia.nivel(personagem)
	barra.queue_redraw()
	barra_experiencia.queue_redraw()


## "Poção de rapidez 12s · Poção de vigor 25s", ou vazio.
func texto_efeitos() -> String:
	if efeitos == null:
		return ""
	var partes: PackedStringArray = []
	for efeito in efeitos.ativos():
		var item := Inventario.item(efeito.id)
		var nome: String = tr(item.chave_nome) if item else String(efeito.id)
		partes.append("%s %ds" % [nome, ceili(efeito.resta)])
	return " · ".join(partes)


func _desenhar_barra() -> void:
	var tamanho := barra.size
	barra.draw_rect(Rect2(Vector2.ZERO, tamanho), COR_BORDA)
	var dentro := Rect2(Vector2(2, 2), tamanho - Vector2(4, 4))
	barra.draw_rect(dentro, COR_FUNDO)
	if vida == null:
		return
	var total := float(maxi(1, vida.maxima_total()))
	var normal := minf(vida.atual, vida.maxima) / total
	var com_extra := vida.atual / total
	barra.draw_rect(Rect2(dentro.position, Vector2(dentro.size.x * normal, dentro.size.y)), COR_VIDA)
	if com_extra > normal:
		var inicio := dentro.position + Vector2(dentro.size.x * normal, 0)
		barra.draw_rect(Rect2(inicio, Vector2(dentro.size.x * (com_extra - normal), dentro.size.y)), COR_EXTRA)


func _desenhar_experiencia() -> void:
	var tamanho := barra_experiencia.size
	barra_experiencia.draw_rect(Rect2(Vector2.ZERO, tamanho), COR_FUNDO)
	var cheia := Experiencia.progresso(personagem)
	barra_experiencia.draw_rect(Rect2(Vector2(1, 1), Vector2((tamanho.x - 2) * cheia, tamanho.y - 2)), COR_BORDA)
