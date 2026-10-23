extends SceneTree
## Monta a biblioteca do Castelo Olympia como sala de desafio do P5 (Rafael,
## 23/10; planos/jogabilidade-isometrica.md), a partir da sala de teste: mesmo
## personagem, câmera e telas, chão e móveis novos e uma ideia só: um canto
## escondido atrás das estantes altas, onde está a mesa de xadrez.
##
## Do livro (V1 P1 c05 e c08): "dois andares, com livros até o teto, janelas
## enormes", mesas pelo ambiente, pilhas de livros no chão, "corredores mais
## estreitos, as estantes mais baixas", e a mesa de xadrez "pequena, redonda e
## levemente empoeirada" perto da janela. Esconder a mesa atrás das estantes é
## escolha de jogo, não do livro.
##
## Planta (casas da grade; x desce para a direita na tela, y desce para a
## esquerda; o fundo da sala é o alto da tela):
##   y 0        parede com janelas enormes
##   x 0        estantes altas (livros até o teto) no outro fundo
##   y 1 e 2    canto escondido, com a mesa de xadrez no fim (x = FIM_CANTO), junto à janela
##   y 3        estantes altas, inteiras menos a falha em x = FALHA
##   y 4        estante alta solta em x = FALHA + 1: na tela fica bem na frente
##              da falha e a esconde; a falha só aparece com as estantes translúcidas
##   resto      salão com estantes baixas (corredores estreitos), mesas e
##              pilhas de livros; uma pilha aponta para o canto
##
## Uso (na raiz do projeto):
##   godot --headless -s tools/cena/gerar_biblioteca_olympia.gd
## Grava scenes/exploracao/biblioteca_olympia.tscn. Rodar de novo refaz a sala.

const ORIGEM := "res://scenes/exploracao/sala_teste.tscn"
const DESTINO := "res://scenes/exploracao/biblioteca_olympia.tscn"
const TILESET := "res://scenes/exploracao/tileset_biblioteca.tres"
const PASTA_ARTE := "res://assets/art/placeholders/biblioteca/"

const LADO := 14
const ESTANTES := 3
const FALHA := 3
const FIM_CANTO := 10
const INICIO := Vector2i(7, 12)
## Fontes do tileset.
const CHAO := 0
const BAIXA := 1
const ALTA := 2
const JANELA := 3
## Fileiras de estantes baixas: [y, x inicial, x final].
const FILEIRAS := [[6, 6, 9], [6, 11, 12], [9, 2, 5], [9, 8, 11]]
const MESAS := [Vector2i(10, 11), Vector2i(3, 11), Vector2i(11, 8)]
## Pilhas de livros no chão; a primeira dá a pista (fica perto da falha).
const PILHAS := [Vector2i(6, 5), Vector2i(9, 12)]
const MESA_XADREZ := Vector2i(FIM_CANTO, 1)

## Nós da sala de teste que ficam (o resto sai).
const FICAM := ["Chao", "Obstaculos", "Navegacao", "MarcadorDestino", "Personagem",
	"PlacaTeste", "Braseiro", "BotoesToque", "TelaBolsa", "AvisoItens", "BarraRapida", "HudVida", "TelaCodice"]


func _initialize() -> void:
	var sala: Node2D = (load(ORIGEM) as PackedScene).instantiate()
	sala.name = "BibliotecaOlympia"
	for filho in sala.get_children():
		if not FICAM.has(String(filho.name)):
			sala.remove_child(filho)
			filho.free()
	var tileset: TileSet = load(TILESET)
	var chao: TileMapLayer = sala.get_node("Chao")
	var obstaculos: TileMapLayer = sala.get_node("Obstaculos")
	chao.tile_set = tileset
	obstaculos.tile_set = tileset
	chao.clear()
	obstaculos.clear()
	for x in LADO:
		for y in LADO:
			chao.set_cell(Vector2i(x, y), CHAO, Vector2i((x + y) % 2, 0))
	for x in LADO:
		obstaculos.set_cell(Vector2i(x, 0), JANELA, Vector2i.ZERO)
	for y in range(1, LADO):
		obstaculos.set_cell(Vector2i(0, y), ALTA, Vector2i.ZERO)
	for x in range(1, LADO):
		if x != FALHA:
			obstaculos.set_cell(Vector2i(x, ESTANTES), ALTA, Vector2i.ZERO)
	# O canto acaba na mesa de xadrez: depois dela, estantes (senão o fim do
	# canto apareceria além da ponta das estantes).
	for x in range(FIM_CANTO + 1, LADO):
		for y in range(1, ESTANTES):
			obstaculos.set_cell(Vector2i(x, y), ALTA, Vector2i.ZERO)
	obstaculos.set_cell(Vector2i(FALHA + 1, ESTANTES + 1), ALTA, Vector2i.ZERO)
	for fileira in FILEIRAS:
		for x in range(fileira[1], fileira[2] + 1):
			obstaculos.set_cell(Vector2i(x, fileira[0]), BAIXA, Vector2i.ZERO)

	var no_mundo := func(casa: Vector2i) -> Vector2: return chao.to_global(chao.map_to_local(casa))
	sala.get_node("Personagem").position = no_mundo.call(INICIO)

	# Mesas (marcadas de tinta), feitas a partir do braseiro da sala de teste.
	var modelo_mesa: Node2D = sala.get_node("Braseiro")
	var forma_mesa := CircleShape2D.new()
	forma_mesa.radius = 14.0
	for i in MESAS.size():
		var mesa: Node2D = modelo_mesa.duplicate()
		mesa.name = "Mesa%d" % (i + 1)
		mesa.position = no_mundo.call(MESAS[i])
		_desenho(mesa, "mesa.png", Vector2(0, -14))
		(mesa.get_node("Colisao") as CollisionShape2D).shape = forma_mesa
		sala.add_child(mesa)
	sala.remove_child(modelo_mesa)
	modelo_mesa.free()

	# Pilhas de livros e a mesa de xadrez, feitas a partir da placa (interagível).
	var modelo: Node2D = sala.get_node("PlacaTeste")
	for i in PILHAS.size():
		var pilha: Node2D = modelo.duplicate()
		pilha.name = "PilhaDeLivros" if i == 0 else "PilhaDeLivros%d" % (i + 1)
		pilha.position = no_mundo.call(PILHAS[i])
		_desenho(pilha, "pilha_livros.png", Vector2(0, -12))
		if i == 0:
			pilha.get_node("Interagivel").set("marcador", "pilha_de_livros")
		else:
			# Só a primeira tem algo a dizer; as outras são cenário.
			pilha.get_node("Interagivel").free()
		sala.add_child(pilha)
	var xadrez: Node2D = modelo.duplicate()
	xadrez.name = "MesaDeXadrez"
	xadrez.position = no_mundo.call(MESA_XADREZ)
	_desenho(xadrez, "mesa_xadrez.png", Vector2(0, -14))
	xadrez.get_node("Interagivel").set("marcador", "mesa_de_xadrez")
	sala.add_child(xadrez)
	sala.remove_child(modelo)
	modelo.free()

	_dono(sala, sala)
	var cena := PackedScene.new()
	var erro := cena.pack(sala)
	if erro == OK:
		erro = ResourceSaver.save(cena, DESTINO)
	print("biblioteca_olympia: ", error_string(erro))
	sala.free()
	quit(0 if erro == OK else 1)


func _desenho(objeto: Node2D, arquivo: String, deslocamento: Vector2) -> void:
	var visual := objeto.get_node("Visual") as Sprite2D
	visual.texture = load(PASTA_ARTE + arquivo)
	visual.offset = deslocamento


## Todos os nós (menos o que está dentro de cenas instanciadas) pertencem à sala.
func _dono(no: Node, sala: Node) -> void:
	for filho in no.get_children():
		if filho.owner != sala:
			filho.owner = sala
		if filho.scene_file_path.is_empty():
			_dono(filho, sala)
