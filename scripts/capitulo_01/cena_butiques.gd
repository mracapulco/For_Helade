class_name CenaButiques
extends CenaCapitulo01
## Capítulo 01, cena 9: a Rua das Butiques e a loja de pelúcias (livro,
## l. ~367-437). Duas salas na mesma cena.
## Sequência (cada [member etapa] só avança na ordem):
## 1. rua: a carruagem para; falar com um dos quatro guardas (E) para
##    escolher "dois comigo".
## 2. porta: E na porta da loja leva para dentro.
## 3. lojistas: os donos recebem os irmãos, Nicholas intervém, todos se
##    ajoelham e Ophelia os faz levantar.
## 4. escolher_presente: as duas se agacham entre as prateleiras; E no
##    expositor da criatura longa (escolha de tom, só muda a relação com
##    Ophelia); o pedido "sem títulos".
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
const CASAS_GUARDAS_RUA: Array[Vector2i] = [Vector2i(7, 3), Vector2i(10, 4), Vector2i(10, 6), Vector2i(7, 7)]
const CASA_PORTA_LOJA := Vector2i(5, 1)

var guardas: Array[Node2D] = []
var guardas_escolhidos := false


func _init() -> void:
	roteiro = ROTEIRO
	objetivos = {"rua": "OBJ_CAP1_GUARDAS_RUA", "porta": "OBJ_CAP1_LOJA",
		"escolher_presente": "OBJ_CAP1_PRESENTE"}


func id_da_cena() -> String:
	return "butiques"


func comecar() -> void:
	montar_rua()
	await _clarear()
	await _frases("frases_rua")


# --- 1. a rua ------------------------------------------------------------

func montar_rua() -> void:
	_nova_sala(14, 8, TOM_DIA, "rua", "fachada")
	guardas.clear()
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
	_objeto("carruagem", "rua/carruagem_parada", Vector2i(8, 5), true, PE_CARRUAGEM)
	_pessoa("cocheiro", QUADROS_COCHEIRO, Vector2i(9, 6))
	_pessoa("althea", QUADROS_ALTHEA, Vector2i(4, 5))
	_pessoa("ophelia", QUADROS_OPHELIA, Vector2i(4, 6))
	for i in CASAS_GUARDAS_RUA.size():
		var guarda := _pessoa("guarda_%d" % (i + 1), QUADROS_GUARDA, CASAS_GUARDAS_RUA[i], true)
		guarda.get_node("Visual").modulate = COR_GUARDA_OLYMPIA
		guarda.get_node("Interagivel").interagido.connect(escolher_guardas)
		guardas.append(guarda)
	_ponto("porta_loja", CASA_PORTA_LOJA)
	_entrar(Vector2i(5, 5))
	_ativar(objetos["carruagem"], false)
	_ativar(objetos["porta_loja"], false)
	_ao_interagir("porta_loja", entrar_na_loja)
	_mudar("rua")


## "Dois comigo."
func escolher_guardas() -> void:
	if etapa != "rua" or guardas_escolhidos:
		return
	guardas_escolhidos = true
	for guarda in guardas:
		_ativar(guarda, false)
	await _falar_travado("guardas_dois")
	_travar(false)
	_mudar("porta")
	_ativar(objetos["porta_loja"], true)


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
	for x in [2, 3]:
		_objeto("prateleira_%d" % x, "loja/prateleira_baixa_esq", Vector2i(x, 1), false, PE_CAIXA)
	_objeto("balcao", "loja/balcao_loja", Vector2i(6, 1), false, PE_CAIXA)
	for y in [3, 5]:
		_objeto("prateleira_dir_%d" % y, "loja/prateleira_baixa_dir", Vector2i(1, y), false, PE_CAIXA)
	_objeto("expositor_enguia", "loja/expositor_enguia", Vector2i(4, 3), true, 5.0)
	_objeto("cesta", "loja/cesta_pelucias", Vector2i(6, 4))
	_objeto("pelucia_dragao", "loja/pelucia_dragao_marinho", Vector2i(3, 5))
	_objeto("pelucia_polvo", "loja/pelucia_polvo", Vector2i(5, 5))
	_objeto("pelucia_monstro", "loja/pelucia_monstro", Vector2i(6, 3))
	_pessoa("lojista_homem", QUADROS_LOJISTA_HOMEM, Vector2i(5, 1))
	_pessoa("lojista_mulher", QUADROS_LOJISTA_MULHER, Vector2i(7, 2))
	_pessoa("althea", QUADROS_ALTHEA, Vector2i(3, 2))
	_pessoa("ophelia", QUADROS_OPHELIA, Vector2i(5, 2))
	for i in 2:
		var guarda := _pessoa("guarda_%d" % (i + 1), QUADROS_GUARDA, [Vector2i(3, 3), Vector2i(5, 3)][i])
		guarda.get_node("Visual").modulate = COR_GUARDA_OLYMPIA
	_entrar(Vector2i(4, 1))
	_travar(true)
	_ativar(objetos["expositor_enguia"], false)
	_ao_interagir("expositor_enguia", escolher_presente)
	_mudar("loja")
	await _clarear()
	await _frases("frases_loja")
	await receber_na_loja()


## Os donos os recebem; Nicholas intervém e a loja se ajoelha.
func receber_na_loja() -> void:
	_mudar("lojistas")
	await _falar_travado("lojistas")
	_abaixar(objetos["lojista_homem"], true)
	_abaixar(objetos["lojista_mulher"], true)
	await _falar_travado("nicholas_intervem")
	await _falar_travado("ophelia_levanta")
	_abaixar(objetos["lojista_homem"], false)
	_abaixar(objetos["lojista_mulher"], false)
	await procurar_presente()


## As duas se agacham entre as prateleiras; Nicholas escolhe o momento.
func procurar_presente() -> void:
	await _caminhar(objetos["althea"], [sala.centro(Vector2i(3, 4))])
	await _caminhar(objetos["ophelia"], [sala.centro(Vector2i(5, 4))])
	_virar(objetos["althea"], objetos["expositor_enguia"].position)
	_virar(objetos["ophelia"], objetos["expositor_enguia"].position)
	_abaixar(objetos["althea"], true)
	_abaixar(objetos["ophelia"], true)
	await _frases("frases_prateleiras")
	_mudar("escolher_presente")
	_travar(false)
	_ativar(objetos["expositor_enguia"], true)


## A criatura longa, entre cobra e enguia: a escolha de tom e o pedido de
## Ophelia ("sem títulos").
func escolher_presente() -> void:
	if etapa != "escolher_presente":
		return
	_mudar("presente")
	_ativar(objetos["expositor_enguia"], false)
	await _falar_travado("presente")
	await _falar_travado("sem_titulos")
	_abaixar(objetos["althea"], false)
	_abaixar(objetos["ophelia"], false)
	await _frases("frases_saida")
	await terminar()
