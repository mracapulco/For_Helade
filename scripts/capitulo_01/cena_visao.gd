class_name CenaVisao
extends CenaCapitulo01
## Capítulo 01, cena 8: a visão da varanda na carruagem e o apelido "Lia"
## (livro, l. ~317-365). Nicholas, Althea e Ophelia sentados na carruagem que
## anda (o mesmo corte da carruagem da manhã, em capitulo_01.gd); a visão em
## 3D é a [VisaoVaranda], por cima, e volta para a carruagem, onde vem a
## conversa dos três (Rafael, 20/10: no fundo preto ficava estranho).
## Textos: data/dialogos/capitulo_01/visao_carruagem.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/visao_carruagem.dialogue")
## Onde cada um senta no banco, ao longo da carruagem (em casas, de trás para
## a frente), como no embarque do Palácio (cena_palacio.gd).
const BANCO := {"althea": -0.9, "ophelia": 0.0, "nicholas": 0.9}
const CASA_CARRO := Vector2i(15, 8)

## As animações da viagem (balanço, rodas, rua, margens), paradas no fim.
var _viagem: Array[Tween] = []


func _init() -> void:
	roteiro = ROTEIRO


func id_da_cena() -> String:
	return "visao_carruagem"


func comecar() -> void:
	montar_carruagem()
	await _clarear()
	_mudar("visao")
	await VisaoVaranda.tocar(self, escala_tempo)
	_mudar("apelido")
	await _falar("apelido")
	await terminar()
	for tween in _viagem:
		tween.kill()


# --- a carruagem andando ----------------------------------------------------

func montar_carruagem() -> void:
	_nova_sala(30, 17, Capitulo01.TOM_AMANHECER, "estrada", "")
	sala.sem_paredes = true
	var carro := Node2D.new()
	carro.name = "Carruagem"
	carro.z_index = 1
	carro.position = sala.centro(CASA_CARRO)
	sala.add_child(carro)
	carro.add_child(_parte_do_carro("Fundo", "carruagem_fundo.png", 1))
	_sentar(carro, "althea", QUADROS_ALTHEA)
	_sentar(carro, "ophelia", QUADROS_OPHELIA)
	_sentar(carro, "nicholas", QUADROS_NICHOLAS)
	var frente := _parte_do_carro("Frente", "carruagem_frente.png", 3)
	carro.add_child(frente)
	objetos["carruagem"] = carro
	_entrar(CASA_CARRO)
	_travar(true)
	jogador.get_node("Corpo").visible = false
	jogador.get_node("Sombra").visible = false
	var camera: Camera2D = jogador.get_node("Camera")
	camera.zoom *= 1.2
	var balanco := create_tween().set_loops()
	balanco.tween_property(carro, "position:y", carro.position.y + 1.0, 0.35)
	balanco.tween_property(carro, "position:y", carro.position.y, 0.35)
	var rodas := create_tween().set_loops()
	rodas.tween_callback(func() -> void: frente.frame = (frente.frame + 1) % 3).set_delay(0.12)
	var rua := create_tween().set_loops()
	rua.tween_property(sala.chao, "position", Vector2(-64, -32), 2 * Capitulo01.SEGUNDOS_POR_CASA) \
		.from(Vector2.ZERO)
	var paisagem := create_tween().set_loops()
	for margem in _margens_da_rua():
		paisagem.parallel().tween_property(margem, "position", -Capitulo01.PERIODO_MARGEM * Vector2(32, 16),
			Capitulo01.PERIODO_MARGEM * Capitulo01.SEGUNDOS_POR_CASA).from(Vector2.ZERO)
	_viagem = [balanco, rodas, rua, paisagem]


## Sentado no banco (como Capitulo01._sentado_em), guardado como "<nome>_sentado".
func _sentar(carro: Node2D, nome: String, quadros: SpriteFrames) -> void:
	var sprite := Sprite2D.new()
	sprite.name = (nome + "_sentado").to_pascal_case()
	sprite.texture = Capitulo01.imagem_sentada(quadros)
	sprite.centered = false
	sprite.position = Capitulo01.ponto_carruagem(BANCO[nome], -0.38 + Capitulo01.COXA, Capitulo01.CARRO_CHAO)
	var meio := (sprite.texture.get_width() - 2 * roundi(16.0 * Capitulo01.COXA)) / 2.0
	sprite.offset = Vector2(-meio, -sprite.texture.get_height())
	carro.add_child(sprite)
	objetos[nome + "_sentado"] = sprite


## Uma das duas imagens da carruagem (mesma origem: o centro no chão).
func _parte_do_carro(nome: String, arquivo: String, quadros: int) -> Sprite2D:
	var parte := Sprite2D.new()
	parte.name = nome
	parte.texture = load(ARTE + arquivo)
	parte.hframes = quadros
	parte.centered = false
	parte.offset = -Capitulo01.CARRO_ORIGEM
	return parte


## As margens passando, como em Capitulo01._margens_da_rua: do outro lado
## ciprestes, oliveiras e colunas; do lado de cá, só coisas baixas. O desenho
## se repete a cada PERIODO_MARGEM casas, para o laço voltar sem emenda.
func _margens_da_rua() -> Array[Node2D]:
	var longe := Node2D.new()
	longe.name = "MargemLonge"
	longe.y_sort_enabled = true
	var perto := Node2D.new()
	perto.name = "MargemPerto"
	perto.y_sort_enabled = true
	perto.z_index = 2
	sala.add_child(longe)
	sala.add_child(perto)
	var sorte := RandomNumberGenerator.new()
	sorte.seed = 1012
	var meio := sala.profundidade / 2
	var altas := ["cipreste", "cipreste", "cipreste", "oliveira", "oliveira", "oliveira", "coluna",
		"canteiro", "canteiro"]
	var baixas := ["canteiro", "canteiro", "canteiro", "canteiro", "coluna"]
	for x0 in Capitulo01.PERIODO_MARGEM:
		for y in range(meio - 8, meio - 1):
			if sorte.randf() < 0.3:
				_enfeite(longe, altas[sorte.randi() % altas.size()], x0, y, sorte)
		for y in range(meio + 2, meio + 9):
			if sorte.randf() < 0.14:
				_enfeite(perto, baixas[sorte.randi() % baixas.size()], x0, y, sorte)
	return [longe, perto]


func _enfeite(margem: Node2D, nome: String, x0: int, y: int, sorte: RandomNumberGenerator) -> void:
	var textura: Texture2D = load(ARTE + "margem/%s.png" % nome)
	var desvio := Vector2(sorte.randf_range(-8, 8), sorte.randf_range(-3, 3))
	var x := x0
	while x < sala.largura + Capitulo01.PERIODO_MARGEM:
		var enfeite := Sprite2D.new()
		enfeite.texture = textura
		enfeite.centered = false
		enfeite.offset = Vector2(-textura.get_width() / 2.0, -textura.get_height() + 3)
		enfeite.position = sala.centro(Vector2i(x, y)) + desvio
		margem.add_child(enfeite)
		x += Capitulo01.PERIODO_MARGEM
