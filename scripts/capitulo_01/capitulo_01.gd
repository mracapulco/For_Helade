class_name Capitulo01
extends Node2D
## Capítulo 01, "A garota do corredor" (Parte I do livro), passo 1: o
## pesadelo e a manhã do aniversário de Althea na Mansão Olympia, em Atenas.
## Sequência (cada [member etapa] só avança na ordem):
## 1. sonho: corredor quente, Nicholas segue a garota até a porta (Enter ou
##    toque na porta) e ela se abre para o frio.
## 2. quarto: Nicholas acorda de pijama; no espelho ele se veste (camisa
##    branca e colete azul escuro) e só então a porta leva ao corredor.
## 3. corredor: na porta de Althea ele espera; o cortejo de Pany chega com o
##    bolo.
## 4. quarto_althea: acordar Althea (a cama); ela se senta, pula da cama e
##    abre o embrulho; depois vai para a mesa de chá, e falar com ela à mesa
##    é sentar junto.
## 5. fim: o duque é anunciado; o passo seguinte (Apollon) ainda não existe,
##    então o jogo volta ao menu.
## As salas são montadas por código ([SalaMontada]); os textos estão em
## data/dialogos/capitulo_01/manha.dialogue.

signal etapa_mudou(etapa: String)

const ROTEIRO := preload("res://data/dialogos/capitulo_01/manha.dialogue")
const CENA_JOGADOR := preload("res://scenes/capitulo_01/nicholas_11.tscn")
const QUADROS_PIJAMA := preload("res://assets/art/personagens/nicholas/nicholas_11_pijama_exploracao.tres")
const QUADROS_VESTIDO := preload("res://assets/art/personagens/nicholas/nicholas_11_exploracao.tres")
const QUADROS_ALTHEA := preload("res://assets/art/personagens/althea/althea_6_exploracao.tres")
const CRIADA := preload("res://assets/art/placeholders/exploracao/criada_provisoria.png")
const ARTE := "res://assets/art/capitulo_01/"
## Móveis em caixa isométrica (armário, baú): o centro da casa fica a esta
## altura da base da imagem (tools/arte/gerar_capitulo_01.py, PE_CAIXA).
const PE_CAIXA := 17.0

## Luz de cada momento.
const TOM_SONHO := Color(1.0, 0.7, 0.5)
const TOM_FRIO := Color(0.55, 0.72, 1.0)
const TOM_MADRUGADA := Color(0.55, 0.62, 0.88)
const TOM_AMANHECER := Color(1.0, 0.9, 0.74)

## Multiplica os tempos (os testes usam 0: tudo acontece na hora).
@export var escala_tempo := 1.0
## Falso nos testes: as conversas passam direto, sem abrir a caixa.
@export var mostrar_dialogos := true
## Para onde o jogo vai no fim deste passo.
@export var cena_depois := "res://scenes/main/main.tscn"

var etapa := ""
var sala: SalaMontada
var jogador: PersonagemExploracao
## Cena pedida no fim (para os testes); vazia até lá.
var cena_pedida := ""
## Quando falso, o fim só anota a cena pedida, sem trocar (testes).
var trocar_de_cena := true
## Nicholas já trocou o pijama pela roupa do dia, no espelho.
var viu_espelho := false
## Já está com a roupa do dia (a troca no espelho terminou).
var vestido := false

## Objetos da sala atual que a sequência usa.
var objetos := {}

@onready var texto: TextoSolto = %Texto
@onready var cortina: ColorRect = %Cortina


func _ready() -> void:
	jogador = CENA_JOGADOR.instantiate()
	jogador.name = "Nicholas"
	_vestir(QUADROS_PIJAMA)
	cortina.color.a = 1.0
	comecar()


func comecar() -> void:
	_mudar("abertura")
	await _frases("frases_abertura")
	await montar_sonho()


# --- 1. o sonho ----------------------------------------------------------

func montar_sonho() -> void:
	_nova_sala(12, 3, TOM_SONHO)
	# Um corredor "não familiar": sem a pedra nem os enfeites da Casa Olympia.
	sala.parede_lisa = true
	sala.abrir_vao(Vector2i(0, 1))
	_objeto("porta_sonho", "porta.png", Vector2i(0, 1), true).get_node("Interagivel") \
		.interagido.connect(abrir_porta_do_sonho)
	var garota := sala.adicionar_objeto("Garota", load(ARTE + "garota_visao.png"), Vector2i(7, 1), false)
	objetos["garota"] = garota
	_entrar(Vector2i(10, 2))
	_mudar("sonho")
	await _clarear()
	_frases("frases_sonho")
	# Ela segue pelo corredor e para diante da porta.
	_andar(garota, sala.centro(Vector2i(2, 1)), 9.0)


func abrir_porta_do_sonho() -> void:
	if etapa != "sonho":
		return
	_mudar("porta_do_sonho")
	_travar(true)
	(objetos["porta_sonho"].get_node("Visual") as Sprite2D).texture = load(ARTE + "porta_aberta.png")
	_tingir(TOM_FRIO, 0.4)
	await _frases("frases_porta_do_sonho")
	await _escurecer()
	await montar_quarto()


# --- 2. o quarto de Nicholas --------------------------------------------

func montar_quarto() -> void:
	_nova_sala(7, 6, TOM_MADRUGADA)
	sala.abrir_vao(Vector2i(6, 0))
	_objeto("cama", "cama_nicholas.png", Vector2i(2, 2))
	_movel("armario", "armario.png", Vector2i(4, 1))
	_movel("bau", "bau.png", Vector2i(1, 2))
	_objeto("espelho", "espelho.png", Vector2i(1, 4), true).get_node("Interagivel") \
		.interagido.connect(olhar_espelho)
	_objeto("porta_quarto", "porta.png", Vector2i(6, 0), true).get_node("Interagivel") \
		.interagido.connect(sair_do_quarto)
	# Como no quarto dele no castelo: o baú embaixo do quadro de Olympia.
	_pendurar({"tapecaria_esq": Vector2i(2, 0), "arandela_esq": Vector2i(5, 0),
		"quadro_olympia_dir": Vector2i(0, 2)})
	_entrar(Vector2i(3, 3))
	# A porta só depois de se vestir.
	_ativar(objetos["porta_quarto"], false)
	_mudar("quarto")
	await _clarear()
	_frases("frases_despertar")


func olhar_espelho() -> void:
	if etapa != "quarto" or viu_espelho:
		return
	viu_espelho = true
	_ativar(objetos["espelho"], false)
	_travar(true)
	# Troca o pijama pela camisa branca e o colete azul escuro.
	await _escurecer()
	_vestir(QUADROS_VESTIDO)
	vestido = true
	await _clarear()
	_travar(false)
	_ativar(objetos["porta_quarto"], true)
	await _frases("frases_espelho")


func sair_do_quarto() -> void:
	if etapa != "quarto" or not vestido:
		return
	_mudar("saindo_do_quarto")
	_travar(true)
	await _escurecer()
	await montar_corredor()


# --- 3. o corredor e o cortejo ------------------------------------------

func montar_corredor() -> void:
	# Um corredor comprido, com outras portas (fechadas); oito passos entre a
	# porta dele e a de Althea.
	_nova_sala(26, 3, TOM_MADRUGADA)
	sala.piso = "passadeira"
	# Portas fechadas ficam na própria parede; só a de Althea, o destino, é
	# um vão com a porta.
	for x in [3, 7, 20, 24]:
		var nome := "porta_nicholas" if x == 20 else "porta_fechada_%d" % x
		objetos[nome] = sala.pendurar(nome.to_pascal_case(), load(ARTE + "parede/porta_esq.png"), Vector2i(x, 0))
	sala.abrir_vao(Vector2i(12, 0))
	_objeto("porta_althea", "porta.png", Vector2i(12, 0), true).get_node("Interagivel") \
		.interagido.connect(esperar_cortejo)
	# Como o corredor do Castelo Olympia no prólogo: tochas, quadros do mapa,
	# tapeçarias e a espada sobre a placa.
	_pendurar({"tapecaria_esq": Vector2i(1, 0), "tocha_esq": Vector2i(5, 0),
		"quadro_atenas_esq": Vector2i(9, 0), "tocha_esq#2": Vector2i(10, 0),
		"espada_placa_esq": Vector2i(15, 0), "quadro_norte_esq": Vector2i(17, 0),
		"tocha_esq#3": Vector2i(18, 0), "tocha_esq#4": Vector2i(22, 0),
		"arandela_dir": Vector2i(0, 1), "tapecaria_dir": Vector2i(0, 2)})
	_entrar(Vector2i(20, 1))
	_mudar("corredor")
	await _clarear()


func esperar_cortejo() -> void:
	if etapa != "corredor":
		return
	_mudar("esperando")
	_travar(true)
	_tingir(TOM_AMANHECER, 6.0)
	await _frases("frases_esperando")
	# O pequeno cortejo surge ao longe e vem até a porta.
	var chegadas := {
		"pany": [Vector2i(1, 2), Vector2i(11, 2)],
		"carrinho": [Vector2i(1, 1), Vector2i(10, 2)],
		"criada_1": [Vector2i(1, 2), Vector2i(10, 1)],
		"criada_2": [Vector2i(1, 1), Vector2i(9, 2)],
	}
	var texturas := {
		"pany": load(ARTE + "pany_provisoria.png"),
		"carrinho": load(ARTE + "carrinho_bolo.png"),
		"criada_1": CRIADA,
		"criada_2": CRIADA,
	}
	var ultimo: Tween
	for nome: String in chegadas:
		var objeto := sala.adicionar_objeto(nome.capitalize(), texturas[nome], chegadas[nome][0], false)
		objetos[nome] = objeto
		ultimo = _andar(objeto, sala.centro(chegadas[nome][1]), 5.0)
	if ultimo and ultimo.is_running():
		await ultimo.finished
	await _falar("cortejo")
	await _escurecer()
	await montar_quarto_althea()


# --- 4. o quarto de Althea ----------------------------------------------

func montar_quarto_althea() -> void:
	_nova_sala(7, 6, TOM_AMANHECER)
	objetos["porta"] = sala.pendurar("Porta", load(ARTE + "parede/porta_esq.png"), Vector2i(5, 0))
	_objeto("cama_althea", "cama_althea.png", Vector2i(2, 2), true).get_node("Interagivel") \
		.interagido.connect(acordar_althea)
	_movel("armario", "armario.png", Vector2i(3, 1))
	_movel("bau", "bau.png", Vector2i(1, 1))
	_objeto("embrulho", "embrulho.png", Vector2i(1, 3))
	_objeto("mesa", "mesa_cha.png", Vector2i(4, 4))
	# Pany acende as seis velas enquanto as criadas arrumam o café.
	_objeto("carrinho", "carrinho_bolo_aceso.png", Vector2i(5, 4))
	_objeto("pany", "pany_provisoria.png", Vector2i(5, 2))
	sala.adicionar_objeto("Criada1", CRIADA, Vector2i(6, 3))
	sala.adicionar_objeto("Criada2", CRIADA, Vector2i(6, 2))
	_pendurar({"arandela_esq": Vector2i(2, 0), "quadro_olympia_esq": Vector2i(4, 0),
		"arandela_esq#2": Vector2i(6, 0), "tapecaria_dir": Vector2i(0, 4)})
	_entrar(Vector2i(3, 3))
	_mudar("quarto_althea")
	await _clarear()
	_frases("frases_quarto_althea")


func acordar_althea() -> void:
	if etapa != "quarto_althea":
		return
	_mudar("aniversario")
	_ativar(objetos["cama_althea"], false)
	await _falar("acordar_althea")
	await _levantar_althea()
	await _falar("espada")
	objetos["embrulho"].visible = false
	_mudar("presentes")
	await _frases("frases_presentes")
	# Quando a agitação diminui, Althea vai para a mesa de chá; falar com ela
	# é sentar junto.
	var althea: Node2D = objetos["althea"]
	await _caminhar(althea, sala.centro(Vector2i(3, 4)), 1.6)
	_virar(althea, sala.centro(Vector2i(4, 4)))
	_ativar(althea, true)
	_mudar("a_mesa")


## Althea se senta na cama, pula para o chão e vai até o embrulho.
func _levantar_althea() -> void:
	var cama: Sprite2D = objetos["cama_althea"].get_node("Visual")
	cama.texture = load(ARTE + "cama_althea_sentada.png")
	await _esperar(0.6)
	cama.texture = load(ARTE + "cama_althea_vazia.png")
	var althea := sala.adicionar_pessoa("Althea", QUADROS_ALTHEA, Vector2i(2, 2), true)
	objetos["althea"] = althea
	_ativar(althea, false)
	althea.get_node("Interagivel").interagido.connect(sentar_a_mesa)
	# O pulo: sobe e desce enquanto vai da cama para o chão, do lado onde
	# Nicholas está.
	var visual: AnimatedSprite2D = althea.get_node("Visual")
	var destino := sala.centro(lado_da_cama_perto_de_nicholas())
	_virar(althea, destino)
	var tempo := maxf(0.45 * escala_tempo, 0.01)
	var pulo := create_tween().set_parallel()
	pulo.tween_property(althea, "position", destino, tempo)
	pulo.tween_method(func(t: float) -> void: visual.offset.y = -22.0 - sin(t * PI) * 10.0, 0.0, 1.0, tempo)
	await pulo.finished
	visual.offset.y = -22.0
	_virar(althea, jogador.position)


## Casa livre ao lado da cama de Althea mais perto de Nicholas (nunca a dele).
func lado_da_cama_perto_de_nicholas() -> Vector2i:
	var cama := Vector2i(2, 2)
	var dele := sala.chao.local_to_map(jogador.position)
	var ocupadas := [dele, Vector2i(1, 3), Vector2i(3, 1), Vector2i(1, 1)]   # Nicholas, embrulho, armário, baú
	var melhor := Vector2i(3, 2)
	var menor := INF
	for passo: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(-1, 1)]:
		var casa := cama + passo
		if ocupadas.has(casa):
			continue
		var distancia := sala.centro(casa).distance_to(jogador.position)
		if distancia < menor:
			menor = distancia
			melhor = casa
	return melhor


## Uma pessoa anda até [param destino], com a animação de andar virada para lá.
func _caminhar(pessoa: Node2D, destino: Vector2, tempo: float) -> void:
	var visual: AnimatedSprite2D = pessoa.get_node("Visual")
	_virar(pessoa, destino)
	visual.play(visual.animation.replace("parado", "andando"))
	await _andar(pessoa, destino, tempo).finished
	visual.play(visual.animation.replace("andando", "parado"))


## Vira a pessoa para o ponto: frente (para baixo) ou costas, espelhada para a esquerda.
func _virar(pessoa: Node2D, alvo: Vector2) -> void:
	var visual := pessoa.get_node("Visual") as AnimatedSprite2D
	if visual == null:
		return
	var direcao := alvo - pessoa.position
	var acao := visual.animation.get_slice("_", 0)
	visual.play("%s_%s" % [acao, "frente" if direcao.y >= 0.0 else "costas"])
	visual.flip_h = direcao.x < 0.0


func _esperar(segundos: float) -> void:
	if escala_tempo > 0.0:
		await get_tree().create_timer(segundos * escala_tempo).timeout


func sentar_a_mesa() -> void:
	if etapa != "a_mesa":
		return
	_ativar(objetos["althea"], false)
	_mudar("mesa")
	_travar(true)
	await _frases("frases_mesa")
	await _frases("frases_duque")
	await _escurecer()
	_mudar("fim")
	await _frases_soltas([tr("CAP1_PROVISORIO_CONTINUA")])
	cena_pedida = cena_depois
	if trocar_de_cena:
		TrocaCena.ir_para(cena_depois)


# --- ajudas ---------------------------------------------------------------

func _mudar(nova: String) -> void:
	etapa = nova
	etapa_mudou.emit(nova)


func _nova_sala(largura: int, profundidade: int, tom: Color) -> void:
	if sala:
		if jogador.get_parent() == sala:
			sala.remove_child(jogador)
		sala.queue_free()
	objetos.clear()
	sala = SalaMontada.new()
	sala.name = "Sala"
	sala.largura = largura
	sala.profundidade = profundidade
	sala.tom = tom


## Um objeto da sala com a arte de assets/art/capitulo_01/, guardado em
## [member objetos] pelo nome.
func _objeto(nome: String, arquivo: String, casa: Vector2i, interagivel := false) -> Node2D:
	var objeto := sala.adicionar_objeto(nome.to_pascal_case(), load(ARTE + arquivo), casa, true, interagivel)
	objetos[nome] = objeto
	return objeto


## Troca a folha de animação de Nicholas (pijama ou roupa do dia).
func _vestir(quadros: SpriteFrames) -> void:
	var visual: AnimatedSprite2D = jogador.get_node("Corpo/Visual")
	var animacao := visual.animation
	visual.sprite_frames = quadros
	visual.play(animacao)


## Enfeites da parede (assets/art/capitulo_01/parede/<nome>.png); "#2" no
## fim do nome repete o mesmo desenho em outra casa.
func _pendurar(enfeites: Dictionary) -> void:
	for chave: String in enfeites:
		var arquivo := chave.get_slice("#", 0)
		sala.pendurar(chave.replace("#", "").to_pascal_case(), load(ARTE + "parede/" + arquivo + ".png"),
			enfeites[chave])


## Móvel em caixa isométrica, alinhado com as paredes.
func _movel(nome: String, arquivo: String, casa: Vector2i) -> Node2D:
	var objeto := sala.adicionar_objeto(nome.to_pascal_case(), load(ARTE + arquivo), casa, true, false, PE_CAIXA)
	objetos[nome] = objeto
	return objeto


## Põe a sala pronta na cena e Nicholas na casa.
func _entrar(casa: Vector2i) -> void:
	add_child(sala)
	move_child(sala, 0)
	sala.receber_jogador(jogador, casa)
	_travar(false)


func _travar(travado: bool) -> void:
	jogador.em_dialogo = travado
	jogador.andando = false
	jogador.alvo_interacao = null
	jogador.velocity = Vector2.ZERO


## Liga ou desliga a interação de um objeto (o anel dourado some junto).
func _ativar(objeto: Node2D, ativo: bool) -> void:
	var area := objeto.get_node_or_null("Interagivel") as Interagivel
	if area == null:
		return
	if ativo:
		area.add_to_group(Interagivel.GRUPO_INTERAGIVEIS)
		area.collision_layer = Interagivel.CAMADA_INTERAGIVEIS
	else:
		area.remove_from_group(Interagivel.GRUPO_INTERAGIVEIS)
		area.collision_layer = 0
	area.set_process(ativo)
	area.destacado = false
	area.queue_redraw()


func _andar(objeto: Node2D, destino: Vector2, tempo: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(objeto, "position", destino, maxf(tempo * escala_tempo, 0.01))
	return tween


func _tingir(cor: Color, tempo: float) -> void:
	if sala and sala.ambiente:
		create_tween().tween_property(sala.ambiente, "color", cor, maxf(tempo * escala_tempo, 0.01))


func _escurecer() -> void:
	var tween := create_tween()
	tween.tween_property(cortina, "color:a", 1.0, maxf(0.8 * escala_tempo, 0.01))
	await tween.finished


func _clarear() -> void:
	var tween := create_tween()
	tween.tween_property(cortina, "color:a", 0.0, maxf(0.8 * escala_tempo, 0.01))
	await tween.finished


## Frases do roteiro que aparecem e somem sozinhas.
func _frases(marcador: String) -> void:
	var frases: Array[String] = []
	var linha: DialogueLine = await ROTEIRO.get_next_dialogue_line(marcador)
	while linha:
		frases.append(linha.text)
		linha = await ROTEIRO.get_next_dialogue_line(linha.next_id)
	await _frases_soltas(frases)


func _frases_soltas(frases: Array[String]) -> void:
	if escala_tempo <= 0.0:
		return
	await texto.mostrar(frases)


## Conversa na caixa de diálogo; volta quando ela fecha.
func _falar(marcador: String) -> void:
	if not mostrar_dialogos:
		return
	DialogueManager.show_dialogue_balloon(ROTEIRO, marcador)
	await DialogueManager.dialogue_ended
