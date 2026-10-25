class_name CenaVolta
extends CenaCapitulo01
## Capítulo 01, cenas 12 e 13: a volta à Mansão Olympia em Atenas e a
## antessala com o Duque, o fim do capítulo (livro, l. ~565-739).
## Sequência:
## 1. chegada: carruagens carregadas, criados em duas fileiras, Apollon e
##    Danica no alto da escadaria. Apollon desce, recebe Ophelia e chama
##    Nicholas; volta para dentro.
## 2. seguir: o jogador anda livre até o pé da escadaria e sobe. Opcional (olhar de
##    Nicholas): parado perto de Danica, olhando para ela, ela desvia o
##    olhar ("Nem mesmo sustentou meu olhar por muito tempo"; Códice).
##    Ao subir, Danica leva Althea pela mão, Ophelia vai atrás.
## 3. conversa: na antessala, a conversa com o Duque em sequência, duas
##    opções por vez, como em Skyrim (Rafael, 25/10/2026): o tom e o silêncio
##    mudam a relação com o Duque, nunca o rumo; as revelações anotam o
##    Códice.
## No fim, a etapa vira [constant ETAPA_DEPOIS] (salva) e abre o mapa de
## Hélade, livre, com Nicholas em Atenas: a estrada para Olympia é o
## caminho do Capítulo 2.
## Os criados usam a arte dos transeuntes e a escadaria é provisória. Textos:
## data/dialogos/capitulo_01/volta.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/volta.dialogue")
const QUADROS_APOLLON := preload("res://assets/art/personagens/apollon/apollon_exploracao.tres")
const QUADROS_DANICA := preload("res://assets/art/personagens/danica/danica_exploracao.tres")
const MAPA := "res://scenes/mapa/mapa_helade.tscn"
const ETAPA_DEPOIS := "capitulo_2"
const LOCAL_NO_MAPA := "atenas"
const LARGURA := 20
const PROFUNDIDADE := 13
## A entrada (um desenho só): o pórtico com a porta no lugar da parede
## (x 6 a 8 da linha 0) e a escadaria do patamar na linha 1 ao último degrau
## na linha 4; o desenho se apoia na casa da frente. ALTURAS: quanto cada
## linha sobe (pixels), da [constant LINHA_PATAMAR] em diante.
const CASA_PORTA := Vector2i(7, 0)
const ESCADA_X := Vector2i(6, 8)
const LINHA_PATAMAR := 1
const ALTURAS := [16.0, 12.0, 8.0, 4.0]
const CASA_DESENHO_ESCADA := Vector2i(7, 4)
const PE_ESCADA := 33.0
## Nicholas sobe a escadaria andando (Rafael, 25/10/2026): nos degraus o
## desenho dele sobe ALTURAS e passa na frente da escada; ao chegar ao
## patamar, segue o Duque (sem círculo de ação).
const LINHA_PE_DA_ESCADA := 5
## A fachada tem dois andares (Rafael: a parede comum, de um andar, era
## baixa para a escadaria): blocos mansao/fachada_alta* por cima da parede.
const ALTO_A_MAIS := 48.0
const CASA_DANICA_EMBAIXO := Vector2i(9, 5)
const CASA_APOLLON := Vector2i(6, 1)
const CASA_DANICA := Vector2i(8, 1)
const CASA_CARRUAGEM := Vector2i(14, 8)
const CASA_CARGA := Vector2i(3, 8)
const CASA_JOGADOR := Vector2i(9, 8)
const CASA_ALTHEA := Vector2i(8, 9)
const CASA_OPHELIA := Vector2i(9, 7)
## Os criados em duas fileiras dos dois lados do caminho até a escadaria.
const CRIADOS := [["moco", Vector2i(4, 5)], ["moca", Vector2i(4, 6)], ["moco", Vector2i(4, 7)],
	["moca", Vector2i(10, 5)], ["moco", Vector2i(10, 6)], ["moca", Vector2i(10, 7)]]
## O olhar para Danica: até que distância (pixels), quanto de frente para
## ela e por quanto tempo parado.
const OLHAR_DISTANCIA := 96.0
const OLHAR_DE_FRENTE := 0.8
const OLHAR_TEMPO := 1.2
## O que a conversa com o Duque anota no Códice.
const ENTRADAS_DAS_PERGUNTAS: Array[String] = ["elogio_do_duque", "decisao_do_imperador",
	"ophelia_abencoada", "tristan", "apoio_de_olympia"]
const TOM_FIM_DE_TARDE := Color(1.0, 0.85, 0.68)

var olhou_danica := false
var _olhando := 0.0
var _subindo := false


func _init() -> void:
	roteiro = ROTEIRO
	objetivos = {"seguir": "OBJ_CAP1_SEGUIR_DUQUE"}


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
	_travar(false)


func montar_frente() -> void:
	_nova_sala(LARGURA, PROFUNDIDADE, TOM_FIM_DE_TARDE, "pedra", "fachada")
	# A fachada de dois andares (janelas e brasões de Olympia são
	# inferência), lampiões e vasos.
	_levantar_a_fachada()
	_pendurar([["brasao_olympia_esq", Vector2i(5, 0)], ["brasao_olympia_esq", Vector2i(9, 0)]])
	for casa: Vector2i in [Vector2i(5, 5), Vector2i(9, 4)]:
		_objeto("lampiao_%d" % casa.x, "rua/lampiao", casa)
	for casa: Vector2i in [Vector2i(5, 2), Vector2i(9, 2)]:
		_objeto("vaso_%d_%d" % [casa.x, casa.y], "rua/vaso_flor", casa)
	_objeto("escadaria_desenho", "mansao/escadaria", CASA_DESENHO_ESCADA, false, PE_ESCADA, false)
	objetos["escadaria_desenho"].remove_meta(SalaMontada.META_TRANSLUCIDO)
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
	_no_alto(_pessoa("apollon", QUADROS_APOLLON, CASA_APOLLON), CASA_APOLLON)
	_no_alto(_pessoa("danica", QUADROS_DANICA, CASA_DANICA), CASA_DANICA)
	_pessoa("althea", QUADROS_ALTHEA, CASA_ALTHEA)
	_pessoa("ophelia", QUADROS_OPHELIA, CASA_OPHELIA)
	_entrar(CASA_JOGADOR)
	jogador.direcao_olhar = (sala.centro(CASA_PORTA) - jogador.position).normalized()


## O Duque desce, recebe a Princesa, chama Nicholas e volta para dentro.
func apollon_recebe() -> void:
	var apollon: Node2D = objetos["apollon"]
	await _caminhar(apollon, _descer(6), 0.3)
	apollon.z_index = 0
	await _caminhar(apollon, [sala.centro(Vector2i(8, 6))], 0.9)
	_virar(apollon, objetos["ophelia"].position)
	_virar(objetos["ophelia"], apollon.position)
	await _falar_travado("apollon_recebe")
	# Danica fica alguns passos atrás; Apollon volta para a mansão.
	_danica_desce()
	await _caminhar(apollon, [sala.centro(Vector2i(6, LINHA_PE_DA_ESCADA))], 0.9)
	apollon.z_index = 1
	var subir := _descer(6)
	subir.reverse()
	await _caminhar(apollon, subir.slice(1) + [_no_patamar(Vector2i(7, LINHA_PATAMAR))], 0.3)
	await _sumir(apollon)


func _danica_desce() -> void:
	var danica: Node2D = objetos["danica"]
	await _caminhar(danica, _descer(8), 0.35)
	danica.z_index = 0
	await _caminhar(danica, [sala.centro(CASA_DANICA_EMBAIXO)], 0.4)


## Na escadaria a pessoa fica mais alta na tela e na frente do desenho dela.
func _no_alto(pessoa: Node2D, casa: Vector2i) -> void:
	pessoa.position = _no_patamar(casa)
	pessoa.z_index = 1


## O ponto da casa [param casa] em cima do degrau (ou no chão, fora da escada).
func _no_patamar(casa: Vector2i) -> Vector2:
	var altura := 0.0
	var linha := casa.y - LINHA_PATAMAR
	if linha >= 0 and linha < ALTURAS.size() and casa.x >= ESCADA_X.x and casa.x <= ESCADA_X.y:
		altura = ALTURAS[linha]
	return sala.centro(casa) - Vector2(0, altura)


## Os pontos da escada na coluna [param x], do patamar até o chão da frente.
func _descer(x: int) -> Array:
	var pontos := []
	for y in range(LINHA_PATAMAR, LINHA_PATAMAR + ALTURAS.size() + 1):
		pontos.append(_no_patamar(Vector2i(x, y)))
	return pontos


## Cada bloco da parede (linha 0 e coluna 0, menos o pórtico) ganha o
## andar de cima; um em cada dois da linha 0 com janela.
func _levantar_a_fachada() -> void:
	var lisa: Texture2D = load(ARTE + "mansao/fachada_alta.png")
	var com_janela: Texture2D = load(ARTE + "mansao/fachada_alta_janela.png")
	var casas: Array[Vector2i] = []
	for x in LARGURA:
		if x < ESCADA_X.x or x > ESCADA_X.y:
			casas.append(Vector2i(x, 0))
	for y in range(1, PROFUNDIDADE):
		casas.append(Vector2i(0, y))
	for casa in casas:
		var bloco := Sprite2D.new()
		bloco.name = "FachadaAlta_%d_%d" % [casa.x, casa.y]
		bloco.texture = com_janela if casa.y == 0 and casa.x % 2 == 0 else lisa
		bloco.centered = false
		# Alinhado como os enfeites da parede (SalaMontada.pendurar); os
		# brasões entram depois e ficam por cima.
		bloco.position = sala.centro(casa) + Vector2(0, 1)
		bloco.offset = Vector2(-32, -49 - ALTO_A_MAIS)
		sala.add_child(bloco)


## Altura do chão debaixo de Nicholas (0 fora da escada).
func altura_na_escada(casa: Vector2i) -> float:
	return sala.centro(casa).y - _no_patamar(casa).y


func _physics_process(delta: float) -> void:
	if not objetos.has("escadaria_desenho"):
		return
	var casa := _casa_de(jogador)
	var alvo := altura_na_escada(casa)
	var visual := jogador.get_node("Corpo/Visual") as Node2D
	var agora := -visual.position.y
	agora = move_toward(agora, alvo, 120.0 * delta)
	visual.position.y = -agora
	jogador.get_node("Sombra").position.y = -agora
	jogador.z_index = 1 if alvo > 0.0 or agora > 0.0 else 0
	if etapa != "seguir" or _subindo:
		return
	if casa.y <= LINHA_PATAMAR and casa.x >= ESCADA_X.x and casa.x <= ESCADA_X.y:
		subir_a_escadaria()
		return
	if olhou_danica:
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


## No pé da escadaria: Danica leva Althea, Ophelia vai atrás, e a antessala.
func subir_a_escadaria() -> void:
	if etapa != "seguir" or _subindo:
		return
	_subindo = true
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
	_mudar("conversa")
	await _falar_travado("conversa")
	# A narração vai no texto de cima, não na caixa (Rafael, 25/10/2026).
	await _frases("frases_doze")
	await _falar_travado("conversa_fim")
	await fim_do_capitulo()


func montar_antessala() -> void:
	# "Antessala de ornamentos dourados com grande janela para o Palácio"
	# (livro/descricao-lugares.md); a escrivaninha, a poltrona, o tapete e o
	# armário são inferência (Rafael pediu algo como um escritório, 25/10).
	jogador.z_index = 0
	jogador.get_node("Corpo/Visual").position.y = 0.0
	jogador.get_node("Sombra").position.y = 0.0
	_nova_sala(8, 6, TOM_DENTRO, "assoalho", "reboco")
	_pendurar([["arandela_esq", Vector2i(2, 0)], ["janela_alta_esq", Vector2i(3, 0)],
		["janela_alta_esq", Vector2i(5, 0)], ["arandela_esq", Vector2i(6, 0)],
		["quadro_olympia_dir", Vector2i(0, 2)], ["brasao_olympia_dir", Vector2i(0, 3)],
		["arandela_dir", Vector2i(0, 4)]])
	var tapete := _objeto("tapete", "mansao/tapete_antessala", Vector2i(4, 3), false, 32.0, false)
	tapete.z_index = -1
	# A primeira casa livre é a linha/coluna 1 (a 0 é a parede).
	_objeto("poltrona", "mansao/poltrona", Vector2i(4, 1), false, PE_CAIXA)
	_objeto("escrivaninha", "mansao/escrivaninha", Vector2i(4, 2), false, PE_CAIXA)
	_objeto("armario", "armario", Vector2i(7, 1), false, PE_CAIXA)
	_pessoa("apollon", QUADROS_APOLLON, Vector2i(5, 3))
	_entrar(Vector2i(2, 4))
	jogador.direcao_olhar = (objetos["apollon"].position - jogador.position).normalized()
	_virar(objetos["apollon"], jogador.position)


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
