class_name CavalosSoltos
extends Node2D
## Estrada Atenas–Olympia, fase 1 (oa_estrada_4, a primeira saindo de
## Atenas): "Cavalos soltos". Brainstorm aprovado por Rafael em 26/10/2026
## (https://claude.ai/artifact/K9xzv8U42W7YZxy4zcEP4H); tudo aqui é
## inferência, o livro só dá o cenário (a estrada, o comboio).
## Um susto solta três cavalos do comboio entre olivais e colunas caídas, e
## Nicholas os leva ao cercado sem encostar neles ([Cavalo]):
## 1. aprende: o castanho foge dele (correr assusta mais);
## 2. aprofunda: o cinzento é teimoso e só anda se ele chegar pelo lado;
##    muretas e colunas fecham caminhos;
## 3. surpresa: o preto não foge; segue a fruta na mão de Nicholas e vai comer
##    a fruta jogada. As frutas vêm da caixa de frutas que caiu da carroça
##    (pegar a caixa põe a caixa e as frutas na bolsa; Rafael, 26/10) e da
##    macieira do pomar, que nunca deixa faltar;
## 4. fecha: com os três no cercado, o carroceiro agradece e a placa da
##    estrada leva adiante (ao mapa).
## Sem luta e sem castigo: errar só faz o cavalo correr para outro canto.
## Segredo: um marco de estrada antigo atrás das oliveiras, só como desenho
## (sem texto da autora).
## Vencida a fase, voltar aqui encontra os cavalos já no cercado (atalho).
## O cenário é montado por código numa [SalaMontada] sem paredes; os textos
## estão em data/dialogos/estrada_oa/cavalos_soltos.dialogue.

signal concluida

const ROTEIRO := preload("res://data/dialogos/estrada_oa/cavalos_soltos.dialogue")
const CENA_JOGADOR := preload("res://scenes/capitulo_01/nicholas_11.tscn")
const CENA_MAPA := "res://scenes/mapa/mapa_helade.tscn"
const ARTE := "res://assets/art/placeholders/estrada_oa/cavalos_soltos/"
const ARTE_ACAMPAMENTO := "res://assets/art/placeholders/acampamento/"
## Fase vencida (guardado no jogo salvo, com as outras coletas).
const ID_FASE := "estrada_oa_cavalos_soltos"
const ID_CAIXA := "estrada_oa_cavalos_soltos_caixa"
const ID_FRUTA := "fruta"
## Pelo trabalho, o carroceiro dá estas moedas (provisório).
const MOEDAS := 10
## Frutas que vêm na caixa.
const FRUTAS_NA_CAIXA := 6
## A macieira só dá fruta quando há menos que isto na bolsa.
const FRUTAS_BASTAM := 3
## Ao ar livre Nicholas anda mais que nas salas do Capítulo 01 (45).
const VELOCIDADE_NICHOLAS := 70.0
const TOM_MANHA := Color(1.0, 0.97, 0.9)

const LARGURA := 22
const PROFUNDIDADE := 12
const INICIO := Vector2i(1, 6)
## Casas de dentro do cercado; a porteira fica no lado de cima (y = 8), de
## frente para a estrada, nas casas x 16 e 17.
const CERCADO := Rect2i(15, 8, 5, 3)
const PORTEIRA: Array[int] = [16, 17]
const CAVALOS := {
	"castanho": {"jeito": Cavalo.Jeito.ASSUSTADO, "casa": Vector2i(8, 9), "no_cercado": Vector2i(16, 9)},
	"tordilho": {"jeito": Cavalo.Jeito.TEIMOSO, "casa": Vector2i(10, 2), "no_cercado": Vector2i(18, 9)},
	"preto": {"jeito": Cavalo.Jeito.GULOSO, "casa": Vector2i(3, 2), "no_cercado": Vector2i(17, 10)},
}
const OLIVEIRAS: Array[Vector2i] = [
	Vector2i(2, 0), Vector2i(5, 1), Vector2i(7, 3), Vector2i(12, 1), Vector2i(14, 3),
	Vector2i(17, 1), Vector2i(20, 2), Vector2i(4, 10), Vector2i(6, 9), Vector2i(9, 11),
	Vector2i(11, 9), Vector2i(13, 11), Vector2i(21, 10), Vector2i(0, 3),
]
const MACIEIRA := Vector2i(1, 10)
const CARROCA := Vector2i(19, 4)
const CARROCEIRO := Vector2i(17, 3)
const CAIXA := Vector2i(16, 4)
const PLACA := Vector2i(21, 6)
const MARCO := Vector2i(1, 0)
const COLUNAS_CAIDAS: Array[Vector2i] = [Vector2i(4, 8), Vector2i(13, 4)]
const COLUNAS_QUEBRADAS: Array[Vector2i] = [Vector2i(7, 8), Vector2i(9, 4)]
## Muretas: [casa, lado da casa] ("y0" é o lado de cima à direita, "y1" o de
## baixo à esquerda, "x0" o de cima à esquerda, "x1" o de baixo à direita).
const MURETAS := [
	[Vector2i(8, 4), "y0"], [Vector2i(9, 4), "y0"], [Vector2i(10, 4), "y0"], [Vector2i(11, 4), "y0"],
	[Vector2i(12, 9), "x0"], [Vector2i(12, 10), "x0"], [Vector2i(12, 11), "x0"],
]

## Com 0, as frases soltas não esperam (testes).
@export var escala_tempo := 1.0
## Desligado nos testes: o carroceiro não abre a caixa de fala.
@export var mostrar_dialogos := true
## Quando falso, sair só anota a cena pedida, sem trocar (testes).
@export var trocar_de_cena := true

var sala: SalaMontada
var jogador: PersonagemExploracao
var fruta_na_mao: FrutaNaMao
## Cavalos pelo nome da pelagem.
var cavalos := {}
var objetos := {}
var vencida := false
## Cena aberta pela última saída (para os testes).
var cena_pedida := ""

@onready var texto: TextoSolto = %Texto
@onready var botao_mapa: Button = %BotaoMapa


func _ready() -> void:
	vencida = Inventario.ja_coletado(ID_FASE)
	jogador = CENA_JOGADOR.instantiate()
	jogador.name = "Nicholas"
	jogador.velocidade = VELOCIDADE_NICHOLAS
	# Com a interpolação de física, a câmera anda na física (sem o aviso do Godot).
	(jogador.get_node("Camera") as Camera2D).process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	fruta_na_mao = FrutaNaMao.new()
	fruta_na_mao.name = "FrutaNaMao"
	jogador.add_child(fruta_na_mao)
	montar()
	botao_mapa.pressed.connect(voltar_ao_mapa)
	botao_mapa.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	if not vencida:
		_frases("frases_inicio")


func montar() -> void:
	sala = SalaMontada.new()
	sala.name = "Sala"
	sala.largura = LARGURA
	sala.profundidade = PROFUNDIDADE
	sala.tom = TOM_MANHA
	sala.piso = "estrada"
	sala.sem_paredes = true
	var sorteio := 0
	for casa in OLIVEIRAS:
		var arquivo: String = ["oliveira", "oliveira_b", "oliveira_c"][sorteio % 3]
		sorteio += 1
		_objeto("oliveira_%d" % sorteio, arquivo, casa)
	for i in COLUNAS_CAIDAS.size():
		_objeto("coluna_caida_%d" % i, "coluna_caida", COLUNAS_CAIDAS[i])
	for i in COLUNAS_QUEBRADAS.size():
		_objeto("coluna_quebrada_%d" % i, "coluna_quebrada", COLUNAS_QUEBRADAS[i])
	_objeto("marco", "marco", MARCO)
	_objeto("macieira", "macieira", MACIEIRA, true).get_node("Interagivel").interagido.connect(colher_fruta)
	objetos["carroca"] = sala.adicionar_objeto("Carroca", load(ARTE_ACAMPAMENTO + "carroca.png"), CARROCA)
	_objeto("carroceiro", "carroceiro", CARROCEIRO, true).get_node("Interagivel").interagido.connect(falar_com_carroceiro)
	var placa := sala.adicionar_objeto("Placa", load(ARTE_ACAMPAMENTO + "placa_saida.png"), PLACA, true, true)
	placa.get_node("Interagivel").interagido.connect(usar_placa)
	objetos["placa"] = placa
	if not Inventario.ja_coletado(ID_CAIXA):
		_montar_caixa()
	_bordas("mureta", MURETAS)
	_bordas("cerca", _lados_do_cercado())
	for nome: String in CAVALOS:
		_soltar_cavalo(nome)
	add_child(sala)
	move_child(sala, 0)
	sala.receber_jogador(jogador, INICIO)


## A caixa de frutas que caiu da carroça: pegar põe a caixa e as frutas na
## bolsa, e nada fica no chão.
func _montar_caixa() -> void:
	var caixa := sala.adicionar_objeto("CaixaDeFrutas",
		load("res://assets/art/placeholders/exploracao/caixa_com_frutas.png"), CAIXA, true, true)
	var recompensa := Recompensa.new()
	recompensa.name = "Recompensa"
	recompensa.interagivel = caixa.get_node("Interagivel")
	recompensa.visual = caixa.get_node("Visual")
	recompensa.id_coleta = ID_CAIXA
	recompensa.itens = {"caixa_frutas": 1, ID_FRUTA: FRUTAS_NA_CAIXA}
	recompensa.sumir_ao_pegar = true
	caixa.add_child(recompensa)
	objetos["caixa"] = caixa


func _soltar_cavalo(nome: String) -> void:
	var dados: Dictionary = CAVALOS[nome]
	var cavalo := Cavalo.new()
	cavalo.name = "Cavalo" + nome.capitalize()
	cavalo.jeito = dados["jeito"]
	cavalo.quadros = load(ARTE + "cavalo_%s.png" % nome)
	cavalo.jogador = jogador
	cavalo.sorte.seed = hash(nome)
	var casa: Vector2i = dados["no_cercado"] if vencida else dados["casa"]
	cavalo.position = sala.centro(casa)
	sala.add_child(cavalo)
	if vencida:
		cavalo.prender()
	cavalos[nome] = cavalo


func _physics_process(_delta: float) -> void:
	if vencida:
		return
	for nome: String in cavalos:
		var cavalo: Cavalo = cavalos[nome]
		if not cavalo.esta_preso() and no_cercado(cavalo.position):
			cavalo.prender(sala.centro(CAVALOS[nome]["no_cercado"]))
	if cavalos_presos() == cavalos.size():
		concluir()


## A posição (da sala) fica dentro do cercado.
func no_cercado(posicao: Vector2) -> bool:
	return CERCADO.has_point(sala.chao.local_to_map(posicao))


func cavalos_presos() -> int:
	var presos := 0
	for nome: String in cavalos:
		if (cavalos[nome] as Cavalo).esta_preso():
			presos += 1
	return presos


## Os três no cercado: o carroceiro agradece e paga, e a estrada abre.
func concluir() -> void:
	if vencida:
		return
	vencida = true
	Inventario.marcar_coletado(ID_FASE)
	Inventario.ganhar_dinheiro(MOEDAS)
	concluida.emit()
	_frases("frases_fim")
	_falar("carroceiro_fim")


## O carroceiro dá a dica do primeiro cavalo ainda solto.
func falar_com_carroceiro() -> void:
	_falar(marcador_do_carroceiro())


func marcador_do_carroceiro() -> String:
	if vencida:
		return "carroceiro_depois"
	if not (cavalos["castanho"] as Cavalo).esta_preso():
		return "carroceiro_inicio"
	if not (cavalos["tordilho"] as Cavalo).esta_preso():
		return "carroceiro_dica_teimoso"
	return "carroceiro_dica_guloso"


## O pomar nunca deixa faltar fruta: uma por vez, até ter o bastante.
func colher_fruta() -> bool:
	if Inventario.quantidade(ID_FRUTA) >= FRUTAS_BASTAM:
		_frases("frase_macieira_cheia")
		return false
	if not Inventario.cabe(ID_FRUTA):
		Inventario.bolsa_cheia.emit()
		return false
	return Inventario.adicionar(ID_FRUTA)


## A placa leva adiante só com os cavalos no cercado.
func usar_placa() -> void:
	if vencida:
		voltar_ao_mapa()
	else:
		_frases("frase_placa_fechada")


func voltar_ao_mapa() -> void:
	cena_pedida = CENA_MAPA
	if trocar_de_cena:
		TrocaCena.ir_para(CENA_MAPA)


# --- muretas e cerca ----------------------------------------------------------
## Os lados de fora das casas do cercado, menos a porteira.
func _lados_do_cercado() -> Array:
	var lados := []
	for x in range(CERCADO.position.x, CERCADO.end.x):
		if not PORTEIRA.has(x):
			lados.append([Vector2i(x, CERCADO.position.y), "y0"])
		lados.append([Vector2i(x, CERCADO.end.y - 1), "y1"])
	for y in range(CERCADO.position.y, CERCADO.end.y):
		lados.append([Vector2i(CERCADO.position.x, y), "x0"])
		lados.append([Vector2i(CERCADO.end.x - 1, y), "x1"])
	return lados


## Os dois cantos (na sala) de um lado de uma casa.
func canto_do_lado(casa: Vector2i, lado: String) -> PackedVector2Array:
	var centro := sala.centro(casa)
	var meio := Vector2(sala.chao.tile_set.tile_size) / 2.0
	var cima := centro + Vector2(0, -meio.y)
	var direita := centro + Vector2(meio.x, 0)
	var baixo := centro + Vector2(0, meio.y)
	var esquerda := centro + Vector2(-meio.x, 0)
	match lado:
		"y0":
			return PackedVector2Array([cima, direita])
		"y1":
			return PackedVector2Array([esquerda, baixo])
		"x0":
			return PackedVector2Array([esquerda, cima])
	return PackedVector2Array([direita, baixo])


## Peças em diagonal ao longo dos lados das casas: o desenho de cada uma e
## um corpo só, de segmentos, que fecha a passagem (sem vãos entre postes).
func _bordas(tipo: String, lados: Array) -> void:
	var corpo := StaticBody2D.new()
	corpo.name = tipo.capitalize() + "s"
	var altura := 14.0 if tipo == "cerca" else 8.0
	for lado: Array in lados:
		var cantos := canto_do_lado(lado[0], lado[1])
		var desce_para_direita: bool = lado[1] in ["y0", "y1"]
		var peca := Sprite2D.new()
		peca.texture = load(ARTE + "%s_%s.png" % [tipo, "a" if desce_para_direita else "b"])
		peca.position = (cantos[0] + cantos[1]) / 2.0
		peca.offset = Vector2(0, -(altura / 2.0 - 1.0))
		sala.add_child(peca)
		var forma := CollisionShape2D.new()
		var segmento := SegmentShape2D.new()
		segmento.a = cantos[0]
		segmento.b = cantos[1]
		forma.shape = segmento
		corpo.add_child(forma)
	sala.add_child(corpo)
	objetos[tipo] = corpo


# --- apoio --------------------------------------------------------------------
func _objeto(nome: String, arquivo: String, casa: Vector2i, interagivel := false) -> Node2D:
	var objeto := sala.adicionar_objeto(nome.to_pascal_case(), load(ARTE + arquivo + ".png"), casa, true, interagivel)
	objetos[nome] = objeto
	return objeto


## Frases soltas do roteiro, no alto da tela (nunca na caixa de fala).
func _frases(marcador: String) -> void:
	var frases: Array[String] = []
	var linha: DialogueLine = await ROTEIRO.get_next_dialogue_line(marcador)
	while linha:
		frases.append(linha.text)
		linha = await ROTEIRO.get_next_dialogue_line(linha.next_id)
	if escala_tempo <= 0.0:
		texto.text = "\n".join(frases)
		return
	await texto.mostrar(frases)


func _falar(marcador: String) -> void:
	if mostrar_dialogos:
		DialogueManager.show_dialogue_balloon(ROTEIRO, marcador)
