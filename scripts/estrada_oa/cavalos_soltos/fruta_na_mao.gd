class_name FrutaNaMao
extends Sprite2D
## A fruta na mão de Nicholas (Rafael, 26/10: "as frutas ele pode segurar ou
## jogar"). Selecionar a fruta na barra rápida é segurar: ela aparece na mão.
## Com ela na mão, o clique (ação "golpear") a joga para o cursor (ou, sem
## mouse, para onde ele olha); a fruta cai no chão como [FrutaNoChao] e dá
## para pegá-la de volta. Cada jogada gasta uma fruta da bolsa.
## Fica como filho do personagem ([PersonagemExploracao]).

signal jogou(fruta: FrutaNoChao)

const ID_FRUTA := "fruta"
const TEXTURA := preload("res://assets/art/placeholders/combate/fruta_na_mao.png")
## Onde fica a mão, a partir dos pés, com o desenho virado para a direita.
const MAO := Vector2(7, -15)

## Até onde a fruta vai, em pixels do chão.
@export var alcance_jogada := 110.0
@export var tempo_voo := 0.45
@export var altura_voo := 22.0

var jogador: PersonagemExploracao
var _desenho: AnimatedSprite2D


## A fruta está selecionada na barra rápida (na mão de quem está jogando).
static func segurando_fruta() -> bool:
	var item := Inventario.item_selecionado()
	return item != null and item.id == ID_FRUTA


func _ready() -> void:
	texture = TEXTURA
	jogador = get_parent() as PersonagemExploracao
	if jogador:
		_desenho = jogador.get_node_or_null("Corpo/Visual") as AnimatedSprite2D
	_acompanhar()


func _process(_delta: float) -> void:
	_acompanhar()


## Segurando agora (selecionada e fora de conversa).
func segurando() -> bool:
	return segurando_fruta() and jogador != null and not jogador.em_dialogo


func _acompanhar() -> void:
	visible = segurando()
	var espelhado := _desenho != null and _desenho.flip_h
	position = Vector2(-MAO.x if espelhado else MAO.x, MAO.y)
	if jogador:
		position.y += jogador.get_node("Corpo").position.y


func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed(&"golpear") or not segurando():
		return
	var mira := Vector2.ZERO
	if evento is InputEventMouseButton:
		mira = jogador.get_global_mouse_position() - jogador.global_position
	if jogar(mira):
		get_viewport().set_input_as_handled()


## Joga uma fruta na direção [param mira] (zero = para onde ele olha).
## Devolve a fruta que voa, ou null se não havia fruta para jogar.
func jogar(mira := Vector2.ZERO) -> FrutaNoChao:
	if jogador == null or not Inventario.remover(ID_FRUTA):
		return null
	var rumo := mira.normalized() if mira.length() > 0.001 else jogador.direcao_olhar
	var destino := jogador.global_position + Vector2(rumo.x, rumo.y * jogador.fator_vertical) * alcance_jogada
	var mapa := jogador.agente.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(mapa) > 0:
		# Não cai fora do chão (atrás da borda). Antes de o mapa de navegação
		# ficar pronto, o ponto mais perto é a origem: aí fica o destino.
		var no_chao := NavigationServer2D.map_get_closest_point(mapa, destino)
		if no_chao.distance_to(destino) < alcance_jogada:
			destino = no_chao
	var fruta := FrutaNoChao.new()
	fruta.name = "Fruta"
	jogador.get_parent().add_child(fruta, true)
	fruta.global_position = jogador.global_position
	fruta.voar(destino, tempo_voo, altura_voo)
	jogou.emit(fruta)
	return fruta
