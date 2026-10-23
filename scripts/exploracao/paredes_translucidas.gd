class_name ParedesTranslucidas
extends TileMapLayer
## Camada de blocos (paredes, muros) que fica translúcida onde cobre o
## jogador, como as paredes do Diablo: um bloco na frente dele (mais abaixo
## na tela) cujo desenho passa por cima do desenho dele fica com
## [member opacidade]. Assim ele nunca some atrás de um muro (Rafael, 23/10;
## planos/jogabilidade-isometrica.md, P1).

## Opacidade dos blocos que cobrem o jogador (1 = opaco).
@export_range(0.0, 1.0) var opacidade := 0.4
## Tamanho do desenho do jogador a partir dos pés (largura, altura), em
## pixels da arte. Um bloco que encosta nesse retângulo fica translúcido.
@export var tamanho_jogador := Vector2(24, 44)

## Casas translúcidas agora (Vector2i → true).
var _translucidas := {}
## Casas que já ficaram translúcidas alguma vez (Vector2i → true). Elas
## continuam passando pela atualização em tempo real, com opacidade cheia
## quando ele sai: se deixassem de passar, o Godot manteria o desenho
## translúcido antigo (Rafael, 23/10: alguns blocos ficavam translúcidos).
var _tocadas := {}


func _process(_delta: float) -> void:
	var jogador := get_tree().get_first_node_in_group(Interagivel.GRUPO_JOGADOR) as Node2D
	var novas := {}
	if jogador:
		for casa in casas_que_cobrem(jogador.global_position):
			novas[casa] = true
	if novas != _translucidas:
		_translucidas = novas
		_tocadas.merge(novas)
		notify_runtime_tile_data_update()


## Está translúcida agora (para os testes e para quem quiser saber).
func translucida(casa: Vector2i) -> bool:
	return _translucidas.has(casa)


## Blocos na frente de quem tem os pés em [param pes] (no mundo) e cujo
## desenho cobre o desenho dele.
func casas_que_cobrem(pes: Vector2) -> Array[Vector2i]:
	var achadas: Array[Vector2i] = []
	if tile_set == null:
		return achadas
	var local := to_local(pes)
	var jogador := Rect2(local.x - tamanho_jogador.x / 2.0, local.y - tamanho_jogador.y, tamanho_jogador.x, tamanho_jogador.y)
	var aqui := local_to_map(local)
	# Um bloco alto cobre no máximo umas poucas casas para cima: procura perto.
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			var casa := aqui + Vector2i(dx, dy)
			var centro := map_to_local(casa)
			if centro.y <= local.y:
				continue   # atrás dele (ou na mesma linha): ele é desenhado por cima
			var desenho := retangulo_do_bloco(casa)
			if desenho.has_area() and desenho.intersects(jogador):
				achadas.append(casa)
	return achadas


## Retângulo (local) onde o desenho do bloco desta casa aparece, ou vazio.
func retangulo_do_bloco(casa: Vector2i) -> Rect2:
	var fonte := tile_set.get_source(get_cell_source_id(casa)) as TileSetAtlasSource if get_cell_source_id(casa) >= 0 else null
	if fonte == null:
		return Rect2()
	var dados := get_cell_tile_data(casa)
	var tamanho := Vector2(fonte.get_tile_texture_region(get_cell_atlas_coords(casa)).size)
	var origem := Vector2(dados.texture_origin) if dados else Vector2.ZERO
	return Rect2(map_to_local(casa) - tamanho / 2.0 - origem, tamanho)


func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return _tocadas.has(coords)


func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	tile_data.modulate.a = opacidade if _translucidas.has(coords) else 1.0
