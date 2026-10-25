class_name CenaVolta
extends CenaCapitulo01
## Capítulo 01, cenas 12 e 13: a volta à Mansão Olympia em Atenas e a
## antessala com o Duque, o fim do capítulo (livro, l. ~565-739).
## Sequência:
## 1. chegada: carruagens carregadas, criados em duas fileiras, Apollon e
##    Danica no alto da escadaria. Apollon desce, recebe Ophelia e chama
##    Nicholas; volta para dentro.
## 2. seguir: o jogador anda livre até a escadaria (E). Opcional (olhar de
##    Nicholas): parado perto de Danica, olhando para ela, ela desvia o
##    olhar ("Nem mesmo sustentou meu olhar por muito tempo"; Códice).
##    Ao subir, Danica leva Althea pela mão, Ophelia vai atrás.
## 3. perguntas: na antessala, o pedido do Duque e o duelo de perguntas
##    (o jogador escolhe a ordem; cada resposta anota o Códice; Rafael,
##    25/10/2026); depois, o fim da conversa.
## No fim, a etapa vira [constant ETAPA_DEPOIS] (salva) e abre o mapa de
## Hélade, livre, com Nicholas em Atenas: a estrada para Olympia é o
## caminho do Capítulo 2.
## Os criados usam a arte dos transeuntes (provisório). Textos:
## data/dialogos/capitulo_01/volta.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/volta.dialogue")
const QUADROS_APOLLON := preload("res://assets/art/personagens/apollon/apollon_exploracao.tres")
const QUADROS_DANICA := preload("res://assets/art/personagens/danica/danica_exploracao.tres")
const MAPA := "res://scenes/mapa/mapa_helade.tscn"
const ETAPA_DEPOIS := "capitulo_2"
const LOCAL_NO_MAPA := "atenas"
const LARGURA := 20
const PROFUNDIDADE := 13
## A porta da mansão e a escadaria na frente dela (do alto para baixo).
const CASA_PORTA := Vector2i(7, 0)
const DEGRAUS := [[Vector2i(7, 1), "mansao/degrau_3"], [Vector2i(7, 2), "mansao/degrau_2"],
	[Vector2i(7, 3), "mansao/degrau_1"]]
const CASA_ESCADARIA := Vector2i(7, 4)
const CASA_APOLLON := Vector2i(6, 1)
const CASA_DANICA := Vector2i(8, 1)
const CASA_CARRUAGEM := Vector2i(14, 8)
const CASA_CARGA := Vector2i(3, 8)
const CASA_JOGADOR := Vector2i(9, 8)
const CASA_ALTHEA := Vector2i(8, 9)
const CASA_OPHELIA := Vector2i(9, 7)
## Os criados em duas fileiras dos dois lados do caminho até a escadaria.
const CRIADOS := [["moco", Vector2i(5, 3)], ["moca", Vector2i(5, 4)], ["moco", Vector2i(5, 5)],
	["moca", Vector2i(9, 3)], ["moco", Vector2i(9, 4)], ["moca", Vector2i(9, 5)]]
## O olhar para Danica: até que distância (pixels), quanto de frente para
## ela e por quanto tempo parado.
const OLHAR_DISTANCIA := 96.0
const OLHAR_DE_FRENTE := 0.8
const OLHAR_TEMPO := 1.2
## Cada pergunta anota uma entrada; a última fecha o duelo.
const ENTRADAS_DAS_PERGUNTAS: Array[String] = ["elogio_do_duque", "decisao_do_imperador",
	"ophelia_abencoada", "tristan", "apoio_de_olympia"]
const TOM_FIM_DE_TARDE := Color(1.0, 0.85, 0.68)

var olhou_danica := false
var _olhando := 0.0
var _subindo := false


func _init() -> void:
	roteiro = ROTEIRO
	objetivos = {"seguir": "OBJ_CAP1_SEGUIR_DUQUE", "perguntas": "OBJ_CAP1_PERGUNTAS"}


func id_da_cena() -> String:
	return "volta"


func comecar() -> void:
	montar_frente()
	await _clarear()
	_mudar("chegada")
	_travar(true)
	await _frases("frases_chegada")
	await apollon_recebe()
	_mudar("seguir")
	_ativar(objetos["escadaria"], true)
	_travar(false)


func montar_frente() -> void:
	_nova_sala(LARGURA, PROFUNDIDADE, TOM_FIM_DE_TARDE, "pedra", "fachada")
	_pendurar([["porta_esq", CASA_PORTA]])
	for degrau: Array in DEGRAUS:
		_objeto("degrau_%d" % degrau[0].y, degrau[1], degrau[0], false, PE_CAIXA)
	_objeto("carruagem", "rua/carruagem_parada", CASA_CARRUAGEM, false, CenaButiques.PE_CARRUAGEM)
	for i in CenaButiques.CASAS_DA_CARRUAGEM.size():
		_bloqueio("junto_da_carruagem_%d" % i, CASA_CARRUAGEM + CenaButiques.CASAS_DA_CARRUAGEM[i])
	# A carga: baús e caixas junto da carroça (inferência: o livro não a descreve).
	for casa: Vector2i in [CASA_CARGA, CASA_CARGA + Vector2i(1, 0), CASA_CARGA + Vector2i(0, 1)]:
		_objeto("carga_%d_%d" % [casa.x, casa.y], "loja/caixa_madeira", casa, false, PE_CAIXA)
	for i in CRIADOS.size():
		var quadros: SpriteFrames = load("res://assets/art/personagens/transeuntes/transeunte_%s_exploracao.tres"
			% CRIADOS[i][0])
		var criado := _pessoa("criado_%d" % (i + 1), quadros, CRIADOS[i][1])
		_virar(criado, sala.centro(Vector2i(7, CRIADOS[i][1].y)))
	_pessoa("apollon", QUADROS_APOLLON, CASA_APOLLON)
	_pessoa("danica", QUADROS_DANICA, CASA_DANICA)
	_pessoa("althea", QUADROS_ALTHEA, CASA_ALTHEA)
	_pessoa("ophelia", QUADROS_OPHELIA, CASA_OPHELIA)
	_ponto("escadaria", CASA_ESCADARIA)
	_ativar(objetos["escadaria"], false)
	_ao_interagir("escadaria", subir_a_escadaria)
	_entrar(CASA_JOGADOR)
	jogador.direcao_olhar = (sala.centro(CASA_PORTA) - jogador.position).normalized()


## O Duque desce, recebe a Princesa, chama Nicholas e volta para dentro.
func apollon_recebe() -> void:
	var apollon: Node2D = objetos["apollon"]
	await _caminhar(apollon, [sala.centro(Vector2i(6, 5)), sala.centro(Vector2i(8, 6))], 0.9)
	_virar(apollon, objetos["ophelia"].position)
	_virar(objetos["ophelia"], apollon.position)
	await _falar_travado("apollon_recebe")
	# Danica fica alguns passos atrás; Apollon volta para a mansão.
	_caminhar(objetos["danica"], [sala.centro(Vector2i(8, 2)), sala.centro(Vector2i(8, 5))], 0.9)
	await _caminhar(apollon, [sala.centro(Vector2i(6, 5)), sala.centro(CASA_APOLLON)], 0.9)
	await _sumir(apollon)


func _physics_process(delta: float) -> void:
	if etapa != "seguir" or olhou_danica or _subindo or not objetos.has("danica"):
		return
	if olhando_para_danica():
		_olhando += delta
		if _olhando >= OLHAR_TEMPO:
			danica_desvia_o_olhar()
	else:
		_olhando = 0.0


## Nicholas parado perto de Danica, de frente para ela.
func olhando_para_danica() -> bool:
	var ate: Vector2 = objetos["danica"].position - jogador.position
	return ate.length() <= OLHAR_DISTANCIA and jogador.velocity.length() < 1.0 \
		and ate.normalized().dot(jogador.direcao_olhar) >= OLHAR_DE_FRENTE


## "Nem mesmo sustentou meu olhar por muito tempo."
func danica_desvia_o_olhar() -> void:
	if olhou_danica:
		return
	olhou_danica = true
	var danica: Node2D = objetos["danica"]
	_virar(danica, danica.position * 2.0 - jogador.position)
	Codice.anotar("danica_desvia_o_olhar")
	await _frases("frases_olhar_danica")


## E na escadaria: Danica leva Althea, Ophelia vai atrás, e a antessala.
func subir_a_escadaria() -> void:
	if etapa != "seguir" or _subindo:
		return
	_subindo = true
	_ativar(objetos["escadaria"], false)
	_travar(true)
	var danica: Node2D = objetos["danica"]
	var althea: Node2D = objetos["althea"]
	var ophelia: Node2D = objetos["ophelia"]
	await _caminhar(danica, [althea.position + Vector2(-20, -10)], 0.6)
	_virar(danica, althea.position)
	await _frases("frases_danica")
	var ate_a_carruagem := sala.centro(CASA_CARRUAGEM + Vector2i(-4, 2))
	_caminhar(danica, [ate_a_carruagem], 1.2)
	await _caminhar(althea, [ate_a_carruagem + Vector2(12, 6)], 1.2)
	# Ophelia segue as duas, mas antes lança um olhar breve para Nicholas.
	_virar(ophelia, jogador.position)
	await _esperar(0.6)
	await _caminhar(ophelia, [ate_a_carruagem + Vector2(-12, 6)], 1.2)
	await _escurecer()
	montar_antessala()
	await _clarear()
	await _frases("frases_antessala")
	await _falar_travado("ensinar")
	_mudar("perguntas")
	await duelo_de_perguntas()
	await _falar_travado("fim_da_conversa")
	await fim_do_capitulo()


func montar_antessala() -> void:
	_nova_sala(5, 4, TOM_DENTRO, "assoalho", "")
	_pendurar([["quadro_atenas_esq", Vector2i(2, 0)], ["arandela_esq", Vector2i(3, 0)],
		["arandela_dir", Vector2i(0, 2)]])
	_pessoa("apollon", QUADROS_APOLLON, Vector2i(3, 2))
	_entrar(Vector2i(1, 2))
	jogador.direcao_olhar = (objetos["apollon"].position - jogador.position).normalized()
	_virar(objetos["apollon"], jogador.position)


## O jogador escolhe a próxima pergunta até fazer todas.
func duelo_de_perguntas() -> void:
	for i in ENTRADAS_DAS_PERGUNTAS.size() * 2:
		if perguntas_feitas() >= ENTRADAS_DAS_PERGUNTAS.size():
			return
		await _falar_travado("perguntas")


func perguntas_feitas() -> int:
	var feitas := 0
	for entrada in ENTRADAS_DAS_PERGUNTAS:
		if Codice.tem(entrada):
			feitas += 1
	return feitas


## Fim do capítulo: salva a etapa seguinte e abre o mapa, com Nicholas em
## Atenas.
func fim_do_capitulo() -> void:
	_mudar(ETAPA_DEPOIS)
	await _escurecer()
	Mundo.local_no_mapa = LOCAL_NO_MAPA
	cena_pedida = MAPA
	if trocar_de_cena:
		Progresso.salvar(ETAPA_DEPOIS)
		TrocaCena.ir_para(MAPA)
	else:
		Progresso.etapa = ETAPA_DEPOIS
