class_name CenaCapitulo01
extends Node2D
## Base das cenas jogáveis do Capítulo 01 depois da manhã (Palácio, Rua das
## Butiques e loja, restaurante): monta salas por código ([SalaMontada]),
## mostra frases e conversas do roteiro da cena e, ao terminar, chama a
## próxima cena ([SequenciaCenas01]). Cada cena tem seu próprio .dialogue,
## seu script e sua .tscn (a mesma estrutura de capitulo_01.tscn).
## Teclas: E interage; Enter só avança a conversa.

signal etapa_mudou(etapa: String)

const CENA_JOGADOR := preload("res://scenes/capitulo_01/nicholas_11.tscn")
const CENA_OBJETIVO := preload("res://scenes/ui/objetivo.tscn")
const QUADROS_NICHOLAS := preload("res://assets/art/personagens/nicholas/nicholas_11_exploracao.tres")
const QUADROS_ALTHEA := preload("res://assets/art/personagens/althea/althea_6_exploracao.tres")
const QUADROS_OPHELIA := preload("res://assets/art/personagens/ophelia/ophelia_11_exploracao.tres")
const QUADROS_GUARDA := preload("res://assets/art/personagens/guarda_imperial/guarda_imperial_exploracao.tres")
const ARTE := "res://assets/art/capitulo_01/"
## Móveis em caixa isométrica: o centro da casa fica a esta altura da base.
const PE_CAIXA := 17.0
## Luz de cada lugar (dia em Atenas; dentro das casas, mais quente).
const TOM_DIA := Color(1.0, 0.97, 0.9)
const TOM_DENTRO := Color(1.0, 0.93, 0.82)

## Multiplica os tempos (os testes usam 0: tudo acontece na hora).
@export var escala_tempo := 1.0
## Falso nos testes: as conversas passam direto, sem abrir a caixa.
@export var mostrar_dialogos := true

## Roteiro (.dialogue) da cena; cada subclasse define o seu em [method _init].
var roteiro: DialogueResource
var etapa := ""
var sala: SalaMontada
var jogador: PersonagemExploracao
## Objetos da sala atual que a cena usa, pelo nome.
var objetos := {}
## Cena pedida no fim (para os testes); vazia até lá.
var cena_pedida := ""
## Quando falso, o fim só anota a cena pedida, sem trocar (testes).
var trocar_de_cena := true
## Objetivo de cada etapa (chave de i18n/strings.csv); etapa sem chave não
## mostra objetivo. Cada subclasse preenche o seu em [method _init].
var objetivos := {}
## A linha do objetivo no alto da tela ([Objetivo]).
var objetivo: Objetivo

@onready var texto: TextoSolto = %Texto
@onready var cortina: ColorRect = %Cortina


func _ready() -> void:
	jogador = CENA_JOGADOR.instantiate()
	jogador.name = "Nicholas"
	cortina.color.a = 1.0
	objetivo = CENA_OBJETIVO.instantiate()
	add_child(objetivo)
	objetivo.observar(texto)
	comecar()


## Cada cena monta a primeira sala e conduz a sequência.
func comecar() -> void:
	pass


## Id da etapa desta cena em [SequenciaCenas01].
func id_da_cena() -> String:
	return ""


## Fim da cena: a etapa vira a seguinte e a próxima cena abre (ou o menu).
func terminar() -> void:
	_mudar(SequenciaCenas01.proxima_etapa(id_da_cena()))
	await _escurecer()
	cena_pedida = SequenciaCenas01.cena_depois(id_da_cena())
	if trocar_de_cena:
		TrocaCena.ir_para(cena_pedida)


# --- montagem -------------------------------------------------------------

func _mudar(nova: String) -> void:
	etapa = nova
	_objetivo(objetivos.get(nova, ""))
	etapa_mudou.emit(nova)


## Troca o objetivo na tela (chave de i18n/strings.csv; vazia esconde).
func _objetivo(chave: String) -> void:
	if objetivo:
		objetivo.definir(chave)


func _nova_sala(largura: int, profundidade: int, tom: Color, piso: String, parede: String) -> void:
	if sala:
		if jogador.get_parent() == sala:
			sala.remove_child(jogador)
		if sala.get_parent():
			sala.get_parent().remove_child(sala)
		sala.queue_free()
	objetos.clear()
	sala = SalaMontada.new()
	sala.name = "Sala"
	sala.largura = largura
	sala.profundidade = profundidade
	sala.tom = tom
	sala.piso = piso
	sala.parede_estilo = parede


## Põe a sala pronta na cena e Nicholas na casa.
func _entrar(casa: Vector2i) -> void:
	add_child(sala)
	move_child(sala, 0)
	sala.receber_jogador(jogador, casa)
	_travar(false)


## Enfeites da parede: pares [arquivo sem .png, casa].
func _pendurar(enfeites: Array) -> void:
	var n := 0
	for par: Array in enfeites:
		n += 1
		sala.pendurar("Parede%d" % n, load(ARTE + "parede/%s.png" % par[0]), par[1])


## Objeto da sala com a arte de assets/art/capitulo_01/ ([param arquivo] sem
## .png, ex.: "palacio/fonte"), guardado em [member objetos] pelo nome.
func _objeto(nome: String, arquivo: String, casa: Vector2i, interagivel := false,
		pe := 3.0, bloqueia := true) -> Node2D:
	var objeto := sala.adicionar_objeto(nome.to_pascal_case(), load(ARTE + arquivo + ".png"), casa,
		bloqueia, interagivel, pe)
	objetos[nome] = objeto
	return objeto


## Pessoa com folha animada (assets/art/personagens/), guardada em [member objetos].
func _pessoa(nome: String, quadros: SpriteFrames, casa: Vector2i, interagivel := false) -> Node2D:
	var pessoa := sala.adicionar_pessoa(nome.to_pascal_case(), quadros, casa, interagivel)
	objetos[nome] = pessoa
	return pessoa


## Liga a interação de [param nome] ao método.
func _ao_interagir(nome: String, metodo: Callable) -> void:
	objetos[nome].get_node("Interagivel").interagido.connect(metodo)


## Ponto invisível do chão com que dá para interagir. Não bloqueia a passagem.
func _ponto(nome: String, casa: Vector2i) -> Node2D:
	var ponto := Node2D.new()
	ponto.name = nome.to_pascal_case()
	ponto.position = sala.centro(casa)
	var area := Interagivel.new()
	area.name = "Interagivel"
	var toque := CollisionShape2D.new()
	toque.name = "AreaDeToque"
	var forma := CircleShape2D.new()
	forma.radius = SalaMontada.RAIO_TOQUE
	toque.shape = forma
	area.add_child(toque)
	ponto.add_child(area)
	sala.add_child(ponto)
	objetos[nome] = ponto
	return ponto


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


func _casa_de(no: Node2D) -> Vector2i:
	return sala.chao.local_to_map(no.position)


## Casa do chão ao lado de [param casa] que ninguém ocupa, a mais perto de
## [param de_onde].
func _casa_livre_perto(casa: Vector2i, de_onde: Vector2i) -> Vector2i:
	var ocupadas: Array[Vector2i] = [_casa_de(jogador)]
	for nome: String in objetos:
		var objeto: Node2D = objetos[nome]
		if is_instance_valid(objeto) and objeto.get_parent() == sala:
			ocupadas.append(_casa_de(objeto))
	var melhor := casa
	var menor := INF
	for passo: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		var vizinha := casa + passo
		if vizinha.x < 1 or vizinha.y < 1 or vizinha.x >= sala.largura or vizinha.y >= sala.profundidade:
			continue
		if ocupadas.has(vizinha):
			continue
		var distancia := Vector2(vizinha - de_onde).length()
		if distancia < menor:
			menor = distancia
			melhor = vizinha
	return melhor


# --- movimento ------------------------------------------------------------

func _andar(objeto: Node2D, destino: Vector2, tempo: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(objeto, "position", destino, maxf(tempo * escala_tempo, 0.01))
	return tween


## Uma pessoa anda por [param pontos] (centros de casa), com a animação de andar.
func _caminhar(pessoa: Node2D, pontos: Array, tempo_por_trecho := 1.2) -> void:
	var visual: AnimatedSprite2D = pessoa.get_node("Visual")
	for destino: Vector2 in pontos:
		_virar(pessoa, destino)
		visual.play(visual.animation.replace("parado", "andando"))
		await _andar(pessoa, destino, tempo_por_trecho).finished
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


## Ajoelhar ou agachar (e levantar): o desenho abaixa um pouco.
func _abaixar(pessoa: Node2D, abaixada: bool) -> void:
	var visual := pessoa.get_node("Visual") as AnimatedSprite2D
	var escala := 0.78 if abaixada else 1.0
	visual.scale = Vector2(1.0, escala)
	visual.offset.y = -22.0 + 24.0 * (1.0 - escala)


func _sumir(pessoa: Node2D) -> void:
	await create_tween().tween_property(pessoa, "modulate:a", 0.0, maxf(0.4 * escala_tempo, 0.01)).finished
	pessoa.visible = false


func _aparecer(pessoa: Node2D) -> void:
	pessoa.visible = true
	pessoa.modulate.a = 0.0
	await create_tween().tween_property(pessoa, "modulate:a", 1.0, maxf(0.4 * escala_tempo, 0.01)).finished


func _esperar(segundos: float) -> void:
	if escala_tempo > 0.0:
		await get_tree().create_timer(segundos * escala_tempo).timeout


func _escurecer() -> void:
	var tween := create_tween()
	tween.tween_property(cortina, "color:a", 1.0, maxf(0.8 * escala_tempo, 0.01))
	await tween.finished


func _clarear() -> void:
	var tween := create_tween()
	tween.tween_property(cortina, "color:a", 0.0, maxf(0.8 * escala_tempo, 0.01))
	await tween.finished


# --- roteiro --------------------------------------------------------------

## Frases do roteiro que aparecem e somem sozinhas.
func _frases(marcador: String) -> void:
	var frases: Array[String] = []
	var linha: DialogueLine = await roteiro.get_next_dialogue_line(marcador)
	while linha:
		frases.append(linha.text)
		linha = await roteiro.get_next_dialogue_line(linha.next_id)
	if escala_tempo <= 0.0:
		return
	await texto.mostrar(frases)


## Conversa na caixa de diálogo; volta quando ela fecha. Sem caixa (testes),
## percorre o marcador pela linha principal (a primeira opção) para valer
## os ajustes de relação e as notas do códice.
func _falar(marcador: String) -> void:
	if not mostrar_dialogos:
		var linha: DialogueLine = await roteiro.get_next_dialogue_line(marcador)
		while linha:
			if linha.responses.is_empty():
				linha = await roteiro.get_next_dialogue_line(linha.next_id)
			else:
				linha = await roteiro.get_next_dialogue_line(linha.responses[0].next_id)
		return
	DialogueManager.show_dialogue_balloon(roteiro, marcador)
	await DialogueManager.dialogue_ended


## Conversa e, quando a caixa fecha, Nicholas continua parado (a caixa o
## solta sozinha um instante depois de fechar).
func _falar_travado(marcador: String) -> void:
	_travar(true)
	await _falar(marcador)
	if mostrar_dialogos:
		await get_tree().create_timer(0.25).timeout
	_travar(true)
