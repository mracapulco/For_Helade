class_name NavegacaoSala
extends NavigationRegion2D
## Gera a área andável da sala ao abrir a cena: o losango do `chao` inteiro,
## menos a colisão dos tiles de `obstaculos` (com folga do raio do personagem).
## Também cria bordas invisíveis no contorno do chão, para quem anda pelo
## teclado não sair da sala.

const GRUPO_OBSTACULOS := &"navegacao_obstaculos"

@export var chao: TileMapLayer
@export var obstaculos: TileMapLayer
## Folga entre o personagem e os obstáculos, em pixels.
@export var raio_personagem := 16.0


func _ready() -> void:
	var poligono := NavigationPolygon.new()
	poligono.agent_radius = raio_personagem
	poligono.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	poligono.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	poligono.source_geometry_group_name = GRUPO_OBSTACULOS
	poligono.add_outline(contorno_do_chao(chao))
	if obstaculos:
		obstaculos.add_to_group(GRUPO_OBSTACULOS)
	navigation_polygon = poligono
	bake_navigation_polygon(false)
	_criar_bordas(poligono.get_outline(0))


func _criar_bordas(contorno: PackedVector2Array) -> void:
	var bordas := StaticBody2D.new()
	bordas.name = "Bordas"
	for i in contorno.size():
		var forma := CollisionShape2D.new()
		var segmento := SegmentShape2D.new()
		segmento.a = chao.to_global(contorno[i])
		segmento.b = chao.to_global(contorno[(i + 1) % contorno.size()])
		forma.shape = segmento
		bordas.add_child(forma)
	add_child(bordas)


## Os quatro cantos do losango formado pelos tiles usados de uma camada
## isométrica (layout "diamond down"), em coordenadas da camada.
static func contorno_do_chao(camada: TileMapLayer) -> PackedVector2Array:
	var area := camada.get_used_rect()
	var meio := Vector2(camada.tile_set.tile_size) / 2.0
	var ultimo := area.end - Vector2i.ONE
	return PackedVector2Array([
		camada.map_to_local(area.position) + Vector2(0, -meio.y),
		camada.map_to_local(Vector2i(ultimo.x, area.position.y)) + Vector2(meio.x, 0),
		camada.map_to_local(ultimo) + Vector2(0, meio.y),
		camada.map_to_local(Vector2i(area.position.x, ultimo.y)) + Vector2(-meio.x, 0),
	])
