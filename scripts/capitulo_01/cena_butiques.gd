class_name CenaButiques
extends CenaCapitulo01
## Capítulo 01, cena 9: a Rua das Butiques e a loja de pelúcias (livro,
## l. ~367-437). Duas salas na mesma cena.
## Sequência (cada [member etapa] só avança na ordem):
## 1. rua: moradores passam pela rua até reconhecerem o brasão e se afastam.
##    A carruagem para na beira da rua, atrás de Nicholas (nunca na frente).
##    Ele conta os guardas ("Quatro guardas?…") e o jogador escolhe dois deles
##    (E em cada um: o escolhido bate continência, ganha uma marca e vem para
##    o lado de Nicholas). Com dois, "Dois comigo"; os outros dois vão para a
##    porta e os escolhidos o acompanham até lá.
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
## A rua: comprida, com lojas dos dois lados do fundo e calçada junto às
## fachadas. A carruagem para dentro da rua (a imagem dela inteira sobre o
## chão), atrás de Nicholas.
const LARGURA_RUA := 34
const PROFUNDIDADE_RUA := 12
const CASA_CARRUAGEM := Vector2i(20, 8)
## Casas que a imagem da carruagem cobre (relativas a ela): ninguém para
## nelas, para não sumir atrás dela.
const ATRAS_DA_CARRUAGEM: Array[Vector2i] = [Vector2i(-4, -1), Vector2i(-3, -1), Vector2i(-2, -1),
	Vector2i(-1, -1), Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(-3, 1), Vector2i(-2, 1),
	Vector2i(-1, 1), Vector2i(-2, 2)]
const CASA_JOGADOR_RUA := Vector2i(19, 5)
## Os quatro guardas se espalham em volta da carruagem, à vista; o jogador
## vai até eles.
const CASAS_GUARDAS_RUA: Array[Vector2i] = [Vector2i(15, 6), Vector2i(23, 5), Vector2i(24, 9), Vector2i(15, 10)]
const CASA_PORTA_LOJA := Vector2i(8, 1)
## Os que ficam de fora esperam dos dois lados da porta (casas guardadas: os
## escolhidos nunca param nelas).
const CASAS_GUARDAS_PORTA: Array[Vector2i] = [Vector2i(7, 1), Vector2i(9, 1)]
## Moradores que passam pela rua no começo (não são personagens do livro):
## [folha, de, até, onde começa (0 a 1 do caminho)]. Andam de um lado para
## o outro até reconhecerem o brasão.
const PASSANTES := [
	["moco", Vector2i(1, 3), Vector2i(33, 3), 0.1],
	["dama", Vector2i(33, 4), Vector2i(2, 4), 0.3],
	["senhor", Vector2i(3, 3), Vector2i(30, 3), 0.6],
	["moca", Vector2i(31, 4), Vector2i(3, 4), 0.8],
	["moca", Vector2i(2, 6), Vector2i(13, 6), 0.2],
	["moco", Vector2i(12, 7), Vector2i(2, 7), 0.5],
	["dama", Vector2i(2, 10), Vector2i(14, 10), 0.4],
	["senhor", Vector2i(13, 11), Vector2i(2, 11), 0.7],
	["moco", Vector2i(25, 10), Vector2i(33, 10), 0.3],
	["moca", Vector2i(33, 11), Vector2i(23, 11), 0.6],
	["dama", Vector2i(26, 6), Vector2i(33, 6), 0.5],
	["senhor", Vector2i(33, 7), Vector2i(25, 7), 0.2],
	["moca", Vector2i(5, 5), Vector2i(29, 5), 0.9],
	["moco", Vector2i(28, 5), Vector2i(6, 5), 0.4],
	["dama", Vector2i(4, 8), Vector2i(12, 8), 0.1],
	["senhor", Vector2i(30, 9), Vector2i(26, 9), 0.5],
]
## Para onde cada um se afasta, na calçada longe da carruagem, e fica olhando.
const CASAS_AFASTADAS: Array[Vector2i] = [Vector2i(31, 1), Vector2i(28, 1), Vector2i(25, 1),
	Vector2i(23, 1), Vector2i(1, 5), Vector2i(1, 9), Vector2i(1, 11), Vector2i(1, 3), Vector2i(33, 8),
	Vector2i(33, 10), Vector2i(33, 6), Vector2i(33, 1), Vector2i(16, 1), Vector2i(13, 1),
	Vector2i(1, 7), Vector2i(20, 1)]
## Segundos por casa andada pelos passantes.
const TEMPO_POR_CASA := 0.4
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
## Casas para onde os escolhidos já estão indo (para não pararem juntos).
var casas_reservadas: Array[Vector2i] = []
var passantes: Array[Node2D] = []
var _passeios: Array[Tween] = []


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
	afastar_passantes()
	await _frases("frases_rua_brasao")
	await _frases("frases_quatro_guardas")
	_mudar("rua")
	for guarda in guardas:
		_ativar(guarda, true)
	_travar(false)


# --- 1. a rua ------------------------------------------------------------

func montar_rua() -> void:
	_nova_sala(LARGURA_RUA, PROFUNDIDADE_RUA, TOM_DIA, "rua", "fachada")
	guardas.clear()
	escolhidos.clear()
	casas_reservadas.clear()
	passantes.clear()
	_passeios.clear()
	var enfeites: Array = []
	# Fundo: uma loja atrás da outra (vitrines com toldo, placa e porta).
	var portas := [8, 15, 21, 27, 32]
	var placas := [7, 14, 26]
	for x in range(1, LARGURA_RUA):
		if x in portas:
			enfeites.append(["porta_esq", Vector2i(x, 0)])
		elif x in placas:
			enfeites.append(["placa_butique_esq", Vector2i(x, 0)])
		else:
			enfeites.append(["vitrine_esq", Vector2i(x, 0)])
			enfeites.append(["toldo_esq", Vector2i(x, 0)])
	# Lado esquerdo: mais vitrines.
	for y in range(1, PROFUNDIDADE_RUA):
		if y == 4:
			enfeites.append(["placa_butique_dir", Vector2i(0, y)])
		elif y != 7:
			enfeites.append(["vitrine_dir", Vector2i(0, y)])
			enfeites.append(["toldo_dir", Vector2i(0, y)])
	_pendurar(enfeites)
	# Calçada: vasos junto às fachadas e lampiões na beira dela.
	for x in [3, 11, 19, 24, 29]:
		_objeto("vaso_flor_%d" % x, "rua/vaso_flor", Vector2i(x, 1))
	for x in [4, 12, 18, 24, 30]:
		_objeto("lampiao_%d" % x, "rua/lampiao", Vector2i(x, 2))
	_objeto("lampiao_esq", "rua/lampiao", Vector2i(2, 8))
	_objeto("carruagem", "rua/carruagem_parada", CASA_CARRUAGEM, false, PE_CARRUAGEM)
	for i in ATRAS_DA_CARRUAGEM.size():
		_bloqueio("atras_carruagem_%d" % i, CASA_CARRUAGEM + ATRAS_DA_CARRUAGEM[i])
	_pessoa("cocheiro", QUADROS_COCHEIRO, Vector2i(22, 7))
	_pessoa("althea", QUADROS_ALTHEA, Vector2i(17, 5))
	_pessoa("ophelia", QUADROS_OPHELIA, Vector2i(17, 6))
	for i in CASAS_GUARDAS_RUA.size():
		var guarda := _pessoa("guarda_%d" % (i + 1), QUADROS_GUARDA, CASAS_GUARDAS_RUA[i], true)
		guarda.get_node("Visual").modulate = COR_GUARDA_OLYMPIA
		guarda.get_node("Interagivel").interagido.connect(escolher_guarda.bind(guarda))
		_ativar(guarda, false)
		guardas.append(guarda)
	for i in PASSANTES.size():
		var quadros: SpriteFrames = load("res://assets/art/personagens/transeuntes/transeunte_%s_exploracao.tres"
			% PASSANTES[i][0])
		var de: Vector2i = PASSANTES[i][1]
		var ate: Vector2i = PASSANTES[i][2]
		var passante := _pessoa("passante_%d" % (i + 1), quadros, de)
		passante.position = sala.centro(de).lerp(sala.centro(ate), PASSANTES[i][3])
		passantes.append(passante)
	_ponto("porta_loja", CASA_PORTA_LOJA)
	_entrar(CASA_JOGADOR_RUA)
	jogador.direcao_olhar = (sala.centro(CASA_PORTA_LOJA) - jogador.position).normalized()
	_ativar(objetos["porta_loja"], false)
	_ao_interagir("porta_loja", entrar_na_loja)
	for i in passantes.size():
		_passear(passantes[i], PASSANTES[i][1], PASSANTES[i][2])


## Um passante segue até o fim do caminho e depois vai e volta pela rua até
## [method afastar_passantes]. Sem tempo (testes), fica parado.
func _passear(passante: Node2D, de: Vector2i, ate: Vector2i) -> void:
	if escala_tempo <= 0.0:
		return
	var casas := (sala.centro(ate) - passante.position).length() / (sala.centro(de) - sala.centro(ate)).length() \
		* Vector2(ate - de).length()
	var ida := create_tween()
	_andando_para(passante, sala.centro(ate))
	ida.tween_property(passante, "position", sala.centro(ate), casas * TEMPO_POR_CASA * escala_tempo)
	ida.tween_callback(_ir_e_voltar.bind(passante, ate, de))
	_passeios.append(ida)


func _ir_e_voltar(passante: Node2D, de: Vector2i, ate: Vector2i) -> void:
	var tempo := Vector2(ate - de).length() * TEMPO_POR_CASA * escala_tempo
	var passeio := create_tween().set_loops()
	passeio.tween_callback(_andando_para.bind(passante, sala.centro(ate)))
	passeio.tween_property(passante, "position", sala.centro(ate), tempo)
	passeio.tween_callback(_andando_para.bind(passante, sala.centro(de)))
	passeio.tween_property(passante, "position", sala.centro(de), tempo)
	_passeios.append(passeio)


func _andando_para(pessoa: Node2D, alvo: Vector2) -> void:
	_virar(pessoa, alvo)
	var visual: AnimatedSprite2D = pessoa.get_node("Visual")
	visual.play(visual.animation.replace("parado", "andando"))


## "As pessoas se afastavam, abrindo espaço. Observavam de longe": cada
## passante para, vai para a calçada longe da carruagem e fica olhando.
func afastar_passantes() -> void:
	for passeio in _passeios:
		if passeio.is_valid():
			passeio.kill()
	_passeios.clear()
	for i in passantes.size():
		_afastar(passantes[i], CASAS_AFASTADAS[i])


func _afastar(passante: Node2D, casa: Vector2i) -> void:
	var casas := Vector2(casa - _casa_de(passante)).length()
	await _caminhar(passante, [sala.centro(casa)], maxf(casas, 1.0) * TEMPO_POR_CASA * 0.8)
	_virar(passante, sala.centro(CASA_CARRUAGEM))


## E num guarda: ele bate continência, ganha uma marca e vem para o lado
## de Nicholas (nunca para as casas da porta). Com dois, "Dois comigo."
func escolher_guarda(guarda: Node2D) -> void:
	if etapa != "rua" or escolhidos.has(guarda) or escolhidos.size() >= GUARDAS_COM_ELE:
		return
	escolhidos.append(guarda)
	_ativar(guarda, false)
	_marcar(guarda)
	var ultimo := escolhidos.size() == GUARDAS_COM_ELE
	if ultimo:
		_objetivo("")
		_travar(true)
		for outro in guardas:
			_ativar(outro, false)
	else:
		_objetivo("OBJ_CAP1_GUARDAS_MAIS_UM")
	_virar(guarda, jogador.position)
	await _continencia(guarda)
	await _vir_para_o_lado(guarda)
	if not ultimo:
		return
	await _falar_travado("guardas_dois")
	var fora := guardas.filter(func(g: Node2D) -> bool: return not escolhidos.has(g))
	for i in fora.size():
		_ir_para_a_porta(fora[i], CASAS_GUARDAS_PORTA[i])
	await _frases("frases_guardas_porta")
	_mudar("porta")
	_travar(false)
	_ativar(objetos["porta_loja"], true)


## Continência: a mão na têmpora por um instante, de frente para Nicholas.
func _continencia(guarda: Node2D) -> void:
	var visual: AnimatedSprite2D = guarda.get_node("Visual")
	var lado := visual.animation.get_slice("_", 1)
	visual.play("continencia_%s" % lado)
	await _esperar(0.9)
	visual.play("parado_%s" % lado)


## O escolhido para numa casa livre ao lado de Nicholas, fora das da porta.
func _vir_para_o_lado(guarda: Node2D) -> void:
	await _caminhar(guarda, [sala.centro(_reservar_ao_lado(guarda))], 0.6)
	_virar(guarda, sala.centro(CASA_PORTA_LOJA))


## Casa livre ao lado de Nicholas para um escolhido, fora das casas da porta
## e das já reservadas.
func _reservar_ao_lado(guarda: Node2D) -> Vector2i:
	var evitar: Array[Vector2i] = CASAS_GUARDAS_PORTA.duplicate()
	evitar.append_array(casas_reservadas)
	var casa := _casa_livre_perto(_casa_de(jogador), _casa_de(guarda), evitar)
	casas_reservadas.append(casa)
	return casa


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
	# Os dois escolhidos acompanham Nicholas até a porta.
	casas_reservadas.clear()
	for guarda in escolhidos:
		_caminhar(guarda, [sala.centro(_reservar_ao_lado(guarda))], 0.6)
	await _esperar(0.6)
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
