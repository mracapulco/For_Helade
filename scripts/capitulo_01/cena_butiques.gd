class_name CenaButiques
extends CenaCapitulo01
## Capítulo 01, cena 9: a Rua das Butiques e a loja de pelúcias (livro,
## l. ~367-437). Duas salas na mesma cena.
## Sequência (cada [member etapa] só avança na ordem):
## 1. rua: a carruagem para na beira da rua, atrás de Nicholas (nunca na
##    frente). Ele conta os guardas ("Quatro guardas?…") e o jogador escolhe
##    dois deles (E em cada um: o escolhido ganha uma marca e vem para o lado
##    de Nicholas). Com dois, "Dois comigo"; os outros dois vão para a porta.
## 2. porta: E na porta da loja leva para dentro.
## 3. lojistas: os donos recebem os irmãos, Nicholas intervém, todos se
##    ajoelham e Ophelia os faz levantar.
## 4. prateleiras: as duas se agacham entre as prateleiras baixas; o jogador
##    procura nelas (E em cada uma: "A Thea já tem um desses.", texto do jogo).
##    Depois de [constant PRATELEIRAS_PARA_ACHAR] prateleiras, Ophelia se
##    levanta e vem até ele com a criatura longa (escolha de tom, só muda a
##    relação com Ophelia) e pede "sem títulos".
## Ao terminar a etapa vira "restaurante" e a cena do restaurante abre.
## Os guardas de Olympia usam a arte do guarda imperial com outra cor
## (provisório, até haver arte própria).
## Textos: data/dialogos/capitulo_01/butiques.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/butiques.dialogue")
const QUADROS_LOJISTA_HOMEM := preload("res://assets/art/personagens/lojista_homem/lojista_homem_exploracao.tres")
const QUADROS_LOJISTA_MULHER := preload("res://assets/art/personagens/lojista_mulher/lojista_mulher_exploracao.tres")
const QUADROS_COCHEIRO := preload("res://assets/art/personagens/cocheiro/cocheiro_exploracao.tres")
const PE_CARRUAGEM := 88.0
## Cor provisória dos guardas de Olympia (a arte é a do guarda imperial).
const COR_GUARDA_OLYMPIA := Color(0.62, 0.74, 1.0)
## A carruagem para na beira da rua (a borda da frente), atrás de Nicholas.
const CASA_CARRUAGEM := Vector2i(11, 7)
const CASA_JOGADOR_RUA := Vector2i(9, 5)
## Os quatro guardas se espalham pela rua; o jogador vai até eles.
const CASAS_GUARDAS_RUA: Array[Vector2i] = [Vector2i(6, 4), Vector2i(7, 2), Vector2i(11, 3), Vector2i(12, 5)]
const CASA_PORTA_LOJA := Vector2i(5, 1)
## Os que ficam de fora esperam dos dois lados da porta.
const CASAS_GUARDAS_PORTA: Array[Vector2i] = [Vector2i(4, 2), Vector2i(6, 2)]
const GUARDAS_COM_ELE := 2
## Na loja: as prateleiras onde dá para procurar (casa de cada uma) e quantas
## o jogador olha até Ophelia achar a criatura.
const PRATELEIRAS := {"prateleira_2_1": Vector2i(2, 1), "prateleira_3_1": Vector2i(3, 1),
	"prateleira_1_3": Vector2i(1, 3), "prateleira_1_5": Vector2i(1, 5)}
const PRATELEIRAS_PARA_ACHAR := 3
const CASA_ALTHEA_AGACHADA := Vector2i(2, 4)
const CASA_OPHELIA_AGACHADA := Vector2i(3, 2)

var guardas: Array[Node2D] = []
var escolhidos: Array[Node2D] = []
var prateleiras_vistas: Array[String] = []


func _init() -> void:
	roteiro = ROTEIRO
	objetivos = {"rua": "OBJ_CAP1_GUARDAS_RUA", "porta": "OBJ_CAP1_LOJA",
		"prateleiras": "OBJ_CAP1_PRESENTE"}


func id_da_cena() -> String:
	return "butiques"


func comecar() -> void:
	montar_rua()
	await _clarear()
	_travar(true)
	await _frases("frases_rua")
	await _frases("frases_quatro_guardas")
	_mudar("rua")
	for guarda in guardas:
		_ativar(guarda, true)
	_travar(false)


# --- 1. a rua ------------------------------------------------------------

func montar_rua() -> void:
	_nova_sala(14, 8, TOM_DIA, "rua", "fachada")
	guardas.clear()
	escolhidos.clear()
	var enfeites: Array = []
	for x in [2, 3, 7, 8, 11, 12]:
		enfeites.append(["vitrine_esq", Vector2i(x, 0)])
		enfeites.append(["toldo_esq", Vector2i(x, 0)])
	enfeites.append(["placa_butique_esq", Vector2i(4, 0)])
	enfeites.append(["porta_esq", Vector2i(5, 0)])
	enfeites.append(["porta_esq", Vector2i(10, 0)])
	for y in [3, 5]:
		enfeites.append(["vitrine_dir", Vector2i(0, y)])
		enfeites.append(["toldo_dir", Vector2i(0, y)])
	_pendurar(enfeites)
	for x in [3, 9, 12]:
		_objeto("lampiao_%d" % x, "rua/lampiao", Vector2i(x, 3))
	for x in [4, 6, 9, 11]:
		_objeto("vaso_flor_%d" % x, "rua/vaso_flor", Vector2i(x, 1))
	_objeto("carruagem", "rua/carruagem_parada", CASA_CARRUAGEM, false, PE_CARRUAGEM)
	_pessoa("cocheiro", QUADROS_COCHEIRO, Vector2i(13, 6))
	_pessoa("althea", QUADROS_ALTHEA, Vector2i(8, 5))
	_pessoa("ophelia", QUADROS_OPHELIA, Vector2i(8, 6))
	for i in CASAS_GUARDAS_RUA.size():
		var guarda := _pessoa("guarda_%d" % (i + 1), QUADROS_GUARDA, CASAS_GUARDAS_RUA[i], true)
		guarda.get_node("Visual").modulate = COR_GUARDA_OLYMPIA
		guarda.get_node("Interagivel").interagido.connect(escolher_guarda.bind(guarda))
		_ativar(guarda, false)
		guardas.append(guarda)
	_ponto("porta_loja", CASA_PORTA_LOJA)
	_entrar(CASA_JOGADOR_RUA)
	jogador.direcao_olhar = (sala.centro(CASA_PORTA_LOJA) - jogador.position).normalized()
	_ativar(objetos["porta_loja"], false)
	_ao_interagir("porta_loja", entrar_na_loja)


## E num guarda: ele vem para o lado de Nicholas, com uma marca. Com dois,
## "Dois comigo."
func escolher_guarda(guarda: Node2D) -> void:
	if etapa != "rua" or escolhidos.has(guarda) or escolhidos.size() >= GUARDAS_COM_ELE:
		return
	escolhidos.append(guarda)
	_ativar(guarda, false)
	_marcar(guarda)
	_virar(guarda, jogador.position)
	if escolhidos.size() < GUARDAS_COM_ELE:
		_objetivo("OBJ_CAP1_GUARDAS_MAIS_UM")
		await _caminhar(guarda, [sala.centro(_casa_livre_perto(_casa_de(jogador), _casa_de(guarda)))], 0.6)
		_virar(guarda, sala.centro(CASA_PORTA_LOJA))
		return
	_objetivo("")
	_travar(true)
	for outro in guardas:
		_ativar(outro, false)
	await _caminhar(guarda, [sala.centro(_casa_livre_perto(_casa_de(jogador), _casa_de(guarda)))], 0.6)
	_virar(guarda, sala.centro(CASA_PORTA_LOJA))
	await _falar_travado("guardas_dois")
	var fora := guardas.filter(func(g: Node2D) -> bool: return not escolhidos.has(g))
	for i in fora.size():
		_ir_para_a_porta(fora[i], CASAS_GUARDAS_PORTA[i])
	await _frases("frases_guardas_porta")
	_mudar("porta")
	_travar(false)
	_ativar(objetos["porta_loja"], true)


## Marca provisória sobre a cabeça do guarda escolhido (um losango dourado).
func _marcar(guarda: Node2D) -> void:
	var marca := Polygon2D.new()
	marca.name = "Marca"
	marca.polygon = PackedVector2Array([Vector2(0, -4), Vector2(3, 0), Vector2(0, 4), Vector2(-3, 0)])
	marca.position = Vector2(0, -54)
	marca.color = Color(1.0, 0.82, 0.35)
	guarda.add_child(marca)


func _ir_para_a_porta(guarda: Node2D, casa: Vector2i) -> void:
	await _caminhar(guarda, [sala.centro(Vector2i(casa.x, _casa_de(guarda).y)), sala.centro(casa)], 0.9)
	_virar(guarda, sala.centro(CASA_JOGADOR_RUA))


func entrar_na_loja() -> void:
	if etapa != "porta":
		return
	_ativar(objetos["porta_loja"], false)
	_travar(true)
	await _escurecer()
	await montar_loja()


# --- 2. a loja -------------------------------------------------------------

func montar_loja() -> void:
	_nova_sala(8, 7, TOM_DENTRO, "assoalho", "reboco")
	_pendurar([["arandela_esq", Vector2i(2, 0)], ["porta_esq", Vector2i(4, 0)],
		["arandela_esq", Vector2i(6, 0)], ["arandela_dir", Vector2i(0, 4)]])
	for nome: String in PRATELEIRAS:
		var casa: Vector2i = PRATELEIRAS[nome]
		var lado := "esq" if casa.y == 1 else "dir"
		_objeto(nome, "loja/prateleira_baixa_" + lado, casa, true, PE_CAIXA)
		_ao_interagir(nome, procurar_na_prateleira.bind(nome))
		_ativar(objetos[nome], false)
	_objeto("prateleira_1_6", "loja/prateleira_baixa_dir", Vector2i(1, 6), false, PE_CAIXA)
	_objeto("balcao", "loja/balcao_loja", Vector2i(6, 1), false, PE_CAIXA)
	_objeto("cesta", "loja/cesta_pelucias", Vector2i(6, 5))
	_objeto("pelucia_dragao", "loja/pelucia_dragao_marinho", Vector2i(4, 6))
	_objeto("pelucia_polvo", "loja/pelucia_polvo", Vector2i(7, 4))
	_objeto("pelucia_monstro", "loja/pelucia_monstro", Vector2i(7, 5))
	_pessoa("lojista_homem", QUADROS_LOJISTA_HOMEM, Vector2i(5, 1))
	_pessoa("lojista_mulher", QUADROS_LOJISTA_MULHER, Vector2i(7, 2))
	_pessoa("althea", QUADROS_ALTHEA, Vector2i(3, 3))
	_pessoa("ophelia", QUADROS_OPHELIA, Vector2i(4, 3))
	for i in 2:
		var guarda := _pessoa("guarda_%d" % (i + 1), QUADROS_GUARDA, [Vector2i(5, 2), Vector2i(6, 3)][i])
		guarda.get_node("Visual").modulate = COR_GUARDA_OLYMPIA
	_entrar(Vector2i(4, 1))
	_travar(true)
	_mudar("loja")
	await _clarear()
	await _frases("frases_loja")
	await receber_na_loja()


## Os donos os recebem; Nicholas intervém e a loja se ajoelha.
func receber_na_loja() -> void:
	_mudar("lojistas")
	await _falar_travado("lojistas")
	await _frases("frases_lojistas_silencio")
	_abaixar(objetos["lojista_homem"], true)
	_abaixar(objetos["lojista_mulher"], true)
	await _falar_travado("nicholas_intervem")
	await _falar_travado("ophelia_levanta")
	_abaixar(objetos["lojista_homem"], false)
	_abaixar(objetos["lojista_mulher"], false)
	await agachar_nas_prateleiras()


## As duas se agacham entre as prateleiras baixas; Nicholas procura também.
func agachar_nas_prateleiras() -> void:
	var althea: Node2D = objetos["althea"]
	var ophelia: Node2D = objetos["ophelia"]
	_caminhar(ophelia, [sala.centro(CASA_OPHELIA_AGACHADA)])
	await _caminhar(althea, [sala.centro(Vector2i(3, 4)), sala.centro(CASA_ALTHEA_AGACHADA)])
	_virar(althea, sala.centro(PRATELEIRAS["prateleira_1_5"]))
	_virar(ophelia, sala.centro(PRATELEIRAS["prateleira_3_1"]))
	_abaixar(althea, true)
	_abaixar(ophelia, true)
	await _frases("frases_prateleiras")
	_mudar("prateleiras")
	for nome: String in PRATELEIRAS:
		_ativar(objetos[nome], true)
	_travar(false)


## E numa prateleira: a Thea já tem aquilo. Depois de algumas, Ophelia acha.
func procurar_na_prateleira(nome: String) -> void:
	if etapa != "prateleiras" or prateleiras_vistas.has(nome):
		return
	prateleiras_vistas.append(nome)
	_ativar(objetos[nome], false)
	var vistas := prateleiras_vistas.size()
	if vistas < PRATELEIRAS_PARA_ACHAR:
		await _frases("frases_prateleira_%d" % vistas)
		return
	_mudar("presente")
	_travar(true)
	for outra: String in PRATELEIRAS:
		_ativar(objetos[outra], false)
	await _frases("frases_prateleira_%d" % vistas)
	await ophelia_traz_a_criatura()


## Ophelia se levanta e vem até ele com a criatura longa, entre cobra e enguia:
## a escolha de tom e o pedido dela ("sem títulos").
func ophelia_traz_a_criatura() -> void:
	var ophelia: Node2D = objetos["ophelia"]
	_abaixar(ophelia, false)
	var criatura := Sprite2D.new()
	criatura.name = "Criatura"
	criatura.texture = load(ARTE + "loja/pelucia_enguia.png")
	criatura.position = Vector2(0, -12)
	criatura.scale = Vector2(0.5, 0.5)
	ophelia.add_child(criatura)
	var casa := _casa_livre_perto(_casa_de(jogador), _casa_de(ophelia))
	await _caminhar(ophelia, [sala.centro(casa)], 0.8)
	_virar(ophelia, jogador.position)
	jogador.direcao_olhar = (ophelia.position - jogador.position).normalized()
	await _falar_travado("presente")
	_virar(ophelia, objetos["althea"].position)
	await _frases("frases_presente")
	_virar(ophelia, jogador.position)
	await _falar_travado("sem_titulos")
	_abaixar(objetos["althea"], false)
	await _frases("frases_saida")
	await terminar()
