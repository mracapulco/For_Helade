class_name CameraExploracao
extends Camera2D
## Câmera da exploração isométrica. Fica como filha do personagem, segue com
## suavização e não mostra nada além das bordas do `mapa`. O mundo é desenhado
## em pixel art (1 unidade = 1 pixel da arte) e a câmera amplia `zoom` vezes.

## Camada de chão usada para calcular as bordas da sala.
@export var mapa: TileMapLayer

## Quantas vezes a arte é ampliada na tela (piso de 64×32 aparece com 128×64).
const ZOOM_PIXEL_ART := 2.0

## Quanto a câmera se adianta para onde o personagem anda, em pixels da arte,
## para mostrar o que vem pela frente (Rafael, 23/10; P1). 0 desliga.
@export var adiantamento := 32.0
## Na vertical a tela é mais baixa que larga: adianta só esta parte.
@export var adiantamento_vertical := 0.6
## Rapidez com que o adiantamento acompanha (maior = mais rápido).
@export var suavidade_adiantamento := 3.0


func _ready() -> void:
	zoom = Vector2.ONE * ZOOM_PIXEL_ART
	position_smoothing_enabled = true
	limit_smoothed = true
	if mapa:
		aplicar_limites(limites_do_mapa(mapa))


# A cada quadro desenhado (não na física), para o adiantamento ficar liso em
# monitores de 120 ou 240 Hz.
func _process(delta: float) -> void:
	var dono := get_parent() as CharacterBody2D
	if dono == null:
		return
	offset = offset.lerp(adiantamento_para(dono.velocity), 1.0 - exp(-suavidade_adiantamento * delta))


## Para onde a câmera se adianta com o personagem andando a [param velocidade]:
## parado, nada; andando, [member adiantamento] na direção do passo.
func adiantamento_para(velocidade: Vector2) -> Vector2:
	if velocidade.length() < 5.0 or adiantamento <= 0.0:
		return Vector2.ZERO
	var direcao := velocidade.normalized()
	return Vector2(direcao.x, direcao.y * adiantamento_vertical) * adiantamento


func aplicar_limites(limites: Rect2) -> void:
	limit_left = floori(limites.position.x)
	limit_top = floori(limites.position.y)
	limit_right = ceili(limites.end.x)
	limit_bottom = ceili(limites.end.y)


## Retângulo, em coordenadas globais, que cobre todos os tiles usados no mapa.
static func limites_do_mapa(camada: TileMapLayer) -> Rect2:
	var centros: Array[Vector2] = []
	for celula in camada.get_used_cells():
		centros.append(camada.to_global(camada.map_to_local(celula)))
	return retangulo_dos_tiles(centros, Vector2(camada.tile_set.tile_size))


## Retângulo que cobre tiles com esses centros e esse tamanho.
static func retangulo_dos_tiles(centros: Array[Vector2], tamanho_tile: Vector2) -> Rect2:
	if centros.is_empty():
		return Rect2()
	var metade := tamanho_tile / 2.0
	var retangulo := Rect2(centros[0] - metade, tamanho_tile)
	for centro in centros:
		retangulo = retangulo.merge(Rect2(centro - metade, tamanho_tile))
	return retangulo
