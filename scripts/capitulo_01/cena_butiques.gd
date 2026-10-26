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
##    segue as pistas da Thea pela sala lateral (quente ou frio; a última
##    pede o banquinho; ver [constant PISTAS]). Achadas as três, Ophelia se
##    levanta e vem até ele com a criatura longa (escolha de tom, só muda a
##    relação com Ophelia) e pede "sem títulos".
## Ao terminar a etapa vira "restaurante" e a cena do restaurante abre.
## Os guardas de Olympia usam a arte do guarda imperial com outra cor
## (provisório, até haver arte própria).
## Textos: data/dialogos/capitulo_01/butiques.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/butiques.dialogue")
const QUADROS_LOJISTA_HOMEM := preload("res://assets/art/personagens/lojista_homem/lojista_homem_exploracao.tres")
const QUADROS_LOJISTA_MULHER := preload("res://assets/art/personagens/lojista_mulher/lojista_mulher_exploracao.tres")
const PE_CARRUAGEM := 88.0
## Cor provisória dos guardas de Olympia (a arte é a do guarda imperial).
const COR_GUARDA_OLYMPIA := Color(0.62, 0.74, 1.0)
## A rua: comprida, com lojas dos dois lados do fundo e calçada junto às
## fachadas. A carruagem para dentro da rua (a imagem dela inteira sobre o
## chão), atrás de Nicholas.
const LARGURA_RUA := 34
const PROFUNDIDADE_RUA := 12
const CASA_CARRUAGEM := Vector2i(20, 8)
## Casas onde uma pessoa ficaria sobreposta à carruagem ou aos cavalos
## (relativas a ela): ninguém para nem passa nelas.
const CASAS_DA_CARRUAGEM: Array[Vector2i] = [
	Vector2i(-4, -2), Vector2i(-3, -2), Vector2i(-2, -2),
	Vector2i(-4, -1), Vector2i(-3, -1), Vector2i(-2, -1), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1),
	Vector2i(-4, 0), Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(-3, 1), Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
	Vector2i(-2, 2), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	Vector2i(-1, 3), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3)]
const CASA_JOGADOR_RUA := Vector2i(19, 5)
## Os quatro guardas se espalham em volta da carruagem, à vista; o jogador
## vai até eles.
const CASAS_GUARDAS_RUA: Array[Vector2i] = [Vector2i(15, 6), Vector2i(23, 5), Vector2i(26, 9), Vector2i(15, 10)]
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
	["moca", Vector2i(33, 11), Vector2i(26, 11), 0.6],
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
## Depois de quantas casas andadas atrás de Nicholas a Althea foge para uma
## vitrine (texto e regra do jogo, não do livro: Rafael, 21/10/2026).
const FUGAS_DE_ALTHEA: Array[int] = [5, 13]
## A que distância (em casas) de Nicholas fica a vitrine para onde ela corre.
const DISTANCIA_DA_FUGA := Vector2i(3, 6)
## Linha da rua por onde os guardas da porta vão, longe da carruagem.
const LINHA_ATE_A_PORTA := 3
## Segundos por casa andada pelos passantes e pelos guardas.
const TEMPO_POR_CASA := 0.4
const GUARDAS_COM_ELE := 2
## Salão da loja: a porta da rua, o balcão e a porta da sala lateral.
const CASA_ENTRADA_SALAO := Vector2i(2, 1)
const CASA_PORTA_SALA_LATERAL := Vector2i(10, 1)
## Sala lateral: as pistas da Thea (regra do jogo, não do livro: Rafael,
## 21/10/2026). Ela pede uma pelúcia por vez com uma pista e esquenta ou
## esfria conforme Nicholas chega perto do esconderijo (quente: ela se
## levanta); ao chegar ao lado dele, Nicholas acha a pelúcia, que ela já tem
## ("A Thea já tem um desses."). A última fica no alto da estante alta:
## Nicholas monta uma escada (banquinho, caixa) na frente dela, agarrando
## com E para empurrar e puxar, e sobe pulando um degrau por vez
## ([BlocosDaSala]). Esconderijos: [casa, arquivo].
const ESCONDERIJOS := {
	"cesta": [Vector2i(8, 6), "loja/cesta_pelucias"],
	"caixas_presente": [Vector2i(3, 7), "loja/caixas_presente"],
	"estante_alta": [Vector2i(9, 1), "loja/estante_alta_esq"],
}
## As prateleiras baixas (livro: as duas se agacham entre elas): [casa, lado].
const PRATELEIRAS_BAIXAS := [[Vector2i(3, 1), "esq"], [Vector2i(4, 1), "esq"], [Vector2i(6, 1), "esq"],
	[Vector2i(7, 1), "esq"], [Vector2i(1, 3), "dir"], [Vector2i(1, 5), "dir"], [Vector2i(1, 7), "dir"]]
## A ordem dos pedidos da Thea: [esconderijo, pelúcia].
const PISTAS := [["cesta", "polvo"], ["caixas_presente", "dragao_marinho"], ["estante_alta", "monstro"]]
## Os blocos do jogo da escada: [casa, arquivo, altura, pixels do topo,
## móvel]. A caixa começa no canto (só sai puxando); o caixote pesado não se
## move nem se sobe e fecha a linha do banquinho. Uma solução: puxar a caixa
## para fora do canto e empurrá-la até a frente da estante; banquinho para
## cima e para a direita até encostar nela; subir no banquinho, na caixa.
const BLOCOS := {
	"banquinho": [Vector2i(5, 3), "loja/banquinho", 1, 12.0, true],
	"caixa": [Vector2i(9, 7), "loja/caixa_madeira", 2, 24.0, true],
	"caixote": [Vector2i(7, 3), "loja/caixote_pesado", 0, 40.0, false],
}
## A altura do degrau de onde Nicholas alcança o alto da estante.
const ALTURA_PARA_ALCANCAR := 2
## Distância (em casas) até o esconderijo para "quente" e "morno" (o x
## ficou sem uso: achar é pelo [constant ACHAR_A]).
const CALOR := Vector3(1.5, 2.5, 4.5)
## Até onde (pixels, dos pés ao meio do esconderijo) Nicholas acha a pelúcia:
## encostado nele (Rafael, 23/10: achava ainda um pouco longe).
const ACHAR_A := 40.0
const CASA_ENTRADA_SALA_LATERAL := Vector2i(2, 1)
## Onde cada uma se agacha, entre as prateleiras baixas.
const CASA_ALTHEA_AGACHADA := Vector2i(5, 1)
const CASA_OPHELIA_AGACHADA := Vector2i(1, 4)

var guardas: Array[Node2D] = []
var escolhidos: Array[Node2D] = []
## Quantos pedidos da Thea Nicholas já achou ([constant PISTAS]).
var achados := 0
var _calor: Label
var _procurando := false
var _avisou_alto := false
## O jogo da escada da sala lateral.
var blocos: BlocosDaSala
## Casas para onde os escolhidos já estão indo (para não pararem juntos).
var casas_reservadas: Array[Vector2i] = []
var passantes: Array[Node2D] = []
## Quem anda atrás de Nicholas depois de "Dois comigo": Althea, Ophelia e os
## dois escolhidos, nessa ordem, cada um uma casa atrás do anterior.
var seguidores: Array[Node2D] = []
## Casas por onde Nicholas passou (a última é a dele).
var _rastro: Array[Vector2i] = []
## Para onde cada seguidor está indo e o tween do passo.
var _destino_seguidor := {}
var _passo_seguidor := {}
## Casas andadas pela comitiva e quantas vezes a Althea já fugiu.
var _passos_andados := 0
var fugas := 0
var althea_fora := false
var _passeios: Array[Tween] = []


func _init() -> void:
	roteiro = ROTEIRO
	objetivos = {"rua": "OBJ_CAP1_GUARDAS_RUA", "porta": "OBJ_CAP1_LOJA",
		"sala_lateral": "OBJ_CAP1_SALA_LATERAL",
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
	seguidores.clear()
	_passos_andados = 0
	fugas = 0
	althea_fora = false
	casas_reservadas.clear()
	passantes.clear()
	_passeios.clear()
	var enfeites: Array = []
	# Fundo: uma loja atrás da outra (vitrines com toldo, placa e porta). A de
	# pelúcias tem vitrines acesas, toldo próprio e uma placa de cada lado da
	# porta; as outras vendem outras coisas (inferência: o livro não diz).
	var portas := [8, 15, 21, 27, 32]
	var placas := {7: "pelucias", 9: "pelucias", 14: "chapeus", 20: "joias", 26: "perfumes", 31: "vestidos"}
	for x in range(1, LARGURA_RUA):
		var loja := _loja_da_fachada(x)
		if x in portas:
			enfeites.append(["porta_esq", Vector2i(x, 0)])
		elif placas.has(x):
			enfeites.append(["placa_%s_esq" % placas[x], Vector2i(x, 0)])
		else:
			enfeites.append(["vitrine_%s_esq" % loja, Vector2i(x, 0)])
			enfeites.append(["toldo_pelucias_esq" if loja == "pelucias" else "toldo_esq", Vector2i(x, 0)])
	# Lado esquerdo: uma joalheria.
	for y in range(1, PROFUNDIDADE_RUA):
		if y == 4:
			enfeites.append(["placa_joias_dir", Vector2i(0, y)])
		elif y != 7:
			enfeites.append(["vitrine_joias_dir", Vector2i(0, y)])
			enfeites.append(["toldo_dir", Vector2i(0, y)])
	_pendurar(enfeites)
	# Calçada: vasos junto às fachadas e lampiões na beira dela.
	for x in [3, 11, 19, 24, 29]:
		_objeto("vaso_flor_%d" % x, "rua/vaso_flor", Vector2i(x, 1))
	for x in [4, 12, 18, 24, 30]:
		_objeto("lampiao_%d" % x, "rua/lampiao", Vector2i(x, 2))
	_objeto("lampiao_esq", "rua/lampiao", Vector2i(2, 8))
	_objeto("caixas_presente_rua", "loja/caixas_presente", Vector2i(6, 1))
	_objeto("carruagem", "rua/carruagem_parada", CASA_CARRUAGEM, false, PE_CARRUAGEM)
	# O cocheiro já está sentado na boleia (no desenho da carruagem).
	for i in CASAS_DA_CARRUAGEM.size():
		_bloqueio("junto_da_carruagem_%d" % i, CASA_CARRUAGEM + CASAS_DA_CARRUAGEM[i])
	var althea := _pessoa("althea", QUADROS_ALTHEA, Vector2i(17, 5), true)
	_ativar(althea, false)
	_ao_interagir("althea", buscar_althea)
	_pessoa("ophelia", QUADROS_OPHELIA, Vector2i(16, 5))
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
	_comecar_a_seguir()
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
	var pontos: Array = []
	for casa in _caminho(_casa_de(guarda), _reservar_ao_lado(guarda)):
		pontos.append(sala.centro(casa))
	await _caminhar(guarda, pontos, TEMPO_POR_CASA)
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


## Os que não foram escolhidos andam (sem pressa) até a porta da loja, por
## cima da carruagem (pela linha da calçada).
func _ir_para_a_porta(guarda: Node2D, casa: Vector2i) -> void:
	var de := _casa_de(guarda)
	var pontos: Array[Vector2i] = [Vector2i(de.x, LINHA_ATE_A_PORTA), Vector2i(casa.x, LINHA_ATE_A_PORTA), casa]
	var antes := de
	for ponto in pontos:
		await _caminhar(guarda, [sala.centro(ponto)], maxf(Vector2(ponto - antes).length(), 0.5) * TEMPO_POR_CASA)
		if not is_instance_valid(guarda) or guarda.get_parent() != sala:
			return    # Nicholas já entrou na loja
		antes = ponto
	_virar(guarda, sala.centro(CASA_CARRUAGEM))


# --- a comitiva segue Nicholas ------------------------------------------------

func _comecar_a_seguir() -> void:
	seguidores.clear()
	seguidores.append(objetos["althea"])
	seguidores.append(objetos["ophelia"])
	seguidores.append_array(escolhidos)
	_rastro.clear()
	_destino_seguidor.clear()
	for i in range(seguidores.size() - 1, -1, -1):
		_rastro.append(_casa_de(seguidores[i]))
	_rastro.append(_casa_de(jogador))
	for seguidor in seguidores:
		# Seguem por onde ele anda: não podem fechar a passagem dele.
		seguidor.get_node("Colisao").set_deferred("disabled", true)
		_destino_seguidor[seguidor] = _casa_de(seguidor)


func _parar_de_seguir() -> void:
	seguidores.clear()


# --- Althea foge para as vitrines -------------------------------------------

## Que loja ocupa a fachada do fundo na coluna [param x] (a de pelúcias é a
## da porta [constant CASA_PORTA_LOJA]).
func _loja_da_fachada(x: int) -> String:
	if x <= 4:
		return "vestidos"
	if x <= 10:
		return "pelucias"
	if x <= 18:
		return "chapeus"
	if x <= 23:
		return "joias"
	if x <= 29:
		return "perfumes"
	return "vestidos"


## Althea sai da fila e corre até uma vitrine da calçada; a porta da loja só
## abre depois que Nicholas a busca.
func althea_foge() -> void:
	var althea: Node2D = objetos["althea"]
	var vitrine := _vitrine_para_fugir()
	fugas += 1
	althea_fora = true
	seguidores.erase(althea)
	var passo: Tween = _passo_seguidor.get(althea)
	if passo and passo.is_valid():
		passo.kill()
	_destino_seguidor.erase(althea)
	_ativar(objetos["porta_loja"], false)
	_objetivo("OBJ_CAP1_BUSCAR_THEA")
	_frases("frases_fuga_%d" % fugas)
	var visual: AnimatedSprite2D = althea.get_node("Visual")
	for ponto in _caminho(_casa_de(althea), vitrine):
		_virar(althea, sala.centro(ponto))
		visual.play("correndo_" + visual.animation.get_slice("_", 1))
		await _andar(althea, sala.centro(ponto), TEMPO_POR_CASA * 0.5).finished
		if not is_instance_valid(althea) or not althea_fora:
			return
	visual.play("parado_costas")
	visual.flip_h = false
	_ativar(althea, true)


## A vitrine (casa da calçada, junto à fachada do fundo) a algumas casas de
## Nicholas, livre e longe da porta da loja de pelúcias.
func _vitrine_para_fugir() -> Vector2i:
	var ocupadas := {}
	for nome: String in objetos:
		ocupadas[_casa_de(objetos[nome])] = true
	for casa in CASAS_GUARDAS_PORTA:
		ocupadas[casa] = true
	var nicholas := _casa_de(jogador)
	var melhor := Vector2i(nicholas.x, 1)
	var maior := -1.0
	for x in range(2, LARGURA_RUA - 1):
		var casa := Vector2i(x, 1)
		var longe := absi(x - nicholas.x)
		if ocupadas.has(casa) or absi(x - CASA_PORTA_LOJA.x) <= 2 \
				or longe < DISTANCIA_DA_FUGA.x or longe > DISTANCIA_DA_FUGA.y:
			continue
		var distancia := Vector2(casa - nicholas).length()
		if distancia > maior:
			maior = distancia
			melhor = casa
	return melhor


## E na Althea, na vitrine: ela volta para a frente da fila.
func buscar_althea() -> void:
	if not althea_fora:
		return
	var althea: Node2D = objetos["althea"]
	_ativar(althea, false)
	althea_fora = false
	_virar(althea, jogador.position)
	seguidores.push_front(althea)
	_rastro.clear()
	for i in range(seguidores.size() - 1, -1, -1):
		_rastro.append(_destino_seguidor.get(seguidores[i], _casa_de(seguidores[i])))
	_rastro.append(_casa_de(jogador))
	_seguir(althea, _casa_livre_perto(_casa_de(jogador), _casa_de(althea), CASAS_GUARDAS_PORTA))
	_objetivo("OBJ_CAP1_LOJA")
	_ativar(objetos["porta_loja"], true)


func _physics_process(_delta: float) -> void:
	if etapa == "prateleiras":
		_sala_lateral_quadro(_delta)
	if seguidores.is_empty() or etapa != "porta":
		return
	var casa := _casa_de(jogador)
	if casa == _rastro.back():
		return
	_rastro.append(casa)
	while _rastro.size() > seguidores.size() + 1:
		_rastro.pop_front()
	for i in seguidores.size():
		_seguir(seguidores[i], _rastro[_rastro.size() - 2 - i])
	_passos_andados += 1
	if not althea_fora and fugas < FUGAS_DE_ALTHEA.size() and _passos_andados >= FUGAS_DE_ALTHEA[fugas] \
			and Vector2(casa - CASA_PORTA_LOJA).length() > 4.0:
		althea_foge()


## Um passo do seguidor até a casa do rastro, no ritmo do andar de Nicholas.
## Longe dela (o começo), vai pelo caminho livre.
func _seguir(seguidor: Node2D, casa: Vector2i) -> void:
	if _destino_seguidor.get(seguidor) == casa:
		return
	_destino_seguidor[seguidor] = casa
	var passo: Tween = _passo_seguidor.get(seguidor)
	if passo and passo.is_valid():
		passo.kill()
	var pontos := _caminho(_casa_de(seguidor), casa)
	var tempo_por_casa := 36.0 / maxf(jogador.velocity.length(), jogador.velocidade_andando())
	passo = create_tween()
	_passo_seguidor[seguidor] = passo
	for ponto in pontos:
		passo.tween_callback(_andando_para.bind(seguidor, sala.centro(ponto)))
		passo.tween_property(seguidor, "position", sala.centro(ponto), maxf(tempo_por_casa * escala_tempo, 0.01))
	passo.tween_callback(_parar_de_andar.bind(seguidor))


func _parar_de_andar(pessoa: Node2D) -> void:
	var visual: AnimatedSprite2D = pessoa.get_node("Visual")
	visual.play(visual.animation.replace("andando", "parado"))


## Casas de [param de] até [param ate] (sem a primeira), desviando da
## carruagem, dos lampiões e dos vasos (busca em largura na grade da rua).
func _caminho(de: Vector2i, ate: Vector2i) -> Array[Vector2i]:
	var caminho: Array[Vector2i] = []
	if Vector2(ate - de).length() < 1.5:
		caminho.append(ate)
		return caminho
	var bloqueadas := {}
	for nome: String in objetos:
		if nome.begins_with("junto_da_carruagem") or nome.begins_with("lampiao") or nome.begins_with("vaso") or nome.begins_with("caixas") \
				or nome == "carruagem":
			bloqueadas[_casa_de(objetos[nome])] = true
	var veio := {de: de}
	var fila: Array[Vector2i] = [de]
	while not fila.is_empty():
		var atual: Vector2i = fila.pop_front()
		if atual == ate:
			break
		for passo: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var vizinha := atual + passo
			if veio.has(vizinha) or bloqueadas.has(vizinha) or vizinha.x < 1 or vizinha.y < 1 \
					or vizinha.x >= sala.largura or vizinha.y >= sala.profundidade:
				continue
			veio[vizinha] = atual
			fila.append(vizinha)
	if not veio.has(ate):
		caminho.append(ate)
		return caminho
	var casa := ate
	while casa != de:
		caminho.push_front(casa)
		casa = veio[casa]
	return caminho


func entrar_na_loja() -> void:
	if etapa != "porta" or althea_fora:
		return
	_ativar(objetos["porta_loja"], false)
	_travar(true)
	# A comitiva já vem atrás dele; espera o último passo antes de entrar.
	await _esperar(0.6)
	_parar_de_seguir()
	await _escurecer()
	await montar_loja()


# --- 2. a loja: o salão -------------------------------------------------------

func montar_loja() -> void:
	_nova_sala(12, 9, TOM_DENTRO, "assoalho", "reboco")
	# A porta da rua e, do outro lado, o arco da sala lateral (com a cortina
	# aberta e uma pelúcia em cima, para não confundir as duas).
	_pendurar([["porta_esq", Vector2i(2, 0)], ["arandela_esq", Vector2i(3, 0)], ["arandela_esq", Vector2i(9, 0)],
		["arco_sala_esq", Vector2i(10, 0)], ["arandela_dir", Vector2i(0, 2)], ["arandela_dir", Vector2i(0, 5)]])
	_objeto("balcao", "loja/balcao_loja", Vector2i(6, 1), false, PE_CAIXA)
	_objeto("estante_salao_1", "loja/estante_alta_esq", Vector2i(4, 1), false, PE_CAIXA)
	_objeto("estante_salao_2", "loja/estante_alta_esq", Vector2i(8, 1), false, PE_CAIXA)
	_objeto("estante_salao_3", "loja/estante_alta_dir", Vector2i(1, 8), false, PE_CAIXA)
	for y in [3, 4, 6, 7]:
		_objeto("prateleira_salao_%d" % y, "loja/prateleira_baixa_dir", Vector2i(1, y), false, PE_CAIXA)
	var tapete := _objeto("tapete", "loja/tapete_loja", Vector2i(7, 6), false, 32.0, false)
	tapete.z_index = -1
	_objeto("cavalinho", "loja/cavalinho", Vector2i(7, 6))
	_objeto("cesta_1", "loja/cesta_pelucias", Vector2i(10, 7))
	_objeto("cesta_2", "loja/cesta_pelucias", Vector2i(11, 4))
	_objeto("caixas_presente", "loja/caixas_presente", Vector2i(3, 1))
	_objeto("caixas_presente_2", "loja/caixas_presente", Vector2i(11, 1))
	_pessoa("lojista_homem", QUADROS_LOJISTA_HOMEM, Vector2i(5, 2))
	_pessoa("lojista_mulher", QUADROS_LOJISTA_MULHER, Vector2i(7, 2))
	_pessoa("althea", QUADROS_ALTHEA, Vector2i(4, 4))
	_pessoa("ophelia", QUADROS_OPHELIA, Vector2i(5, 4))
	for i in 2:
		var guarda := _pessoa("guarda_%d" % (i + 1), QUADROS_GUARDA, [Vector2i(2, 3), Vector2i(3, 2)][i])
		guarda.get_node("Visual").modulate = COR_GUARDA_OLYMPIA
	_ponto("porta_sala_lateral", CASA_PORTA_SALA_LATERAL)
	_ativar(objetos["porta_sala_lateral"], false)
	_ao_interagir("porta_sala_lateral", ir_para_sala_lateral)
	_entrar(CASA_ENTRADA_SALAO)
	_travar(true)
	_mudar("loja")
	await _clarear()
	await _frases("frases_loja")
	await receber_na_loja()


## Os donos os recebem; Nicholas intervém e a loja se ajoelha. Depois, as
## meninas vão até a porta da sala lateral e Nicholas segue para lá.
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
	_caminhar(objetos["ophelia"], [sala.centro(Vector2i(9, 3))], 0.8)
	_caminhar(objetos["althea"], [sala.centro(Vector2i(9, 2))], 0.8)
	_mudar("sala_lateral")
	_ativar(objetos["porta_sala_lateral"], true)
	_travar(false)


## E na porta da sala lateral: "Sem esperar mais, ele virou-se e seguiu para
## a sala lateral. As garotas o acompanharam."
func ir_para_sala_lateral() -> void:
	if etapa != "sala_lateral":
		return
	_ativar(objetos["porta_sala_lateral"], false)
	_travar(true)
	await _escurecer()
	await montar_sala_lateral()


# --- 3. a sala lateral: as pistas da Thea -- ----------------------------------

func montar_sala_lateral() -> void:
	_nova_sala(10, 8, TOM_DENTRO, "assoalho", "reboco")
	_pendurar([["porta_esq", Vector2i(2, 0)], ["arandela_esq", Vector2i(5, 0)], ["arandela_esq", Vector2i(8, 0)],
		["arandela_dir", Vector2i(0, 6)]])
	var tapete := _objeto("tapete", "loja/tapete_loja", Vector2i(5, 4), false, 32.0, false)
	tapete.z_index = -1
	for i in PRATELEIRAS_BAIXAS.size():
		var prateleira: Array = PRATELEIRAS_BAIXAS[i]
		_objeto("prateleira_%d" % i, "loja/prateleira_baixa_" + prateleira[1], prateleira[0], false, PE_CAIXA)
	for nome: String in ESCONDERIJOS:
		var arquivo: String = ESCONDERIJOS[nome][1]
		_objeto(nome, arquivo, ESCONDERIJOS[nome][0], false, PE_CAIXA if arquivo.contains("estante") else 3.0)
	# A pelúcia do alto fica à vista, longe do alcance.
	var no_alto := Sprite2D.new()
	no_alto.name = "Pelucia"
	no_alto.texture = load(ARTE + "loja/pelucia_monstro.png")
	no_alto.position = Vector2(0, -60)
	no_alto.scale = Vector2.ONE * 0.6
	objetos["estante_alta"].add_child(no_alto)
	_objeto("cavalinho", "loja/cavalinho", Vector2i(6, 6))
	if blocos:
		blocos.queue_free()
	blocos = BlocosDaSala.new()
	blocos.name = "Blocos"
	blocos.escala_tempo = escala_tempo
	add_child(blocos)
	blocos.configurar(sala, jogador, _casa_livre)
	for nome: String in BLOCOS:
		var bloco: Array = BLOCOS[nome]
		var coisa := _objeto(nome, bloco[1], bloco[0], false, PE_CAIXA)
		coisa.remove_from_group(NavegacaoSala.GRUPO_OBSTACULOS)
		blocos.adicionar(nome, coisa, bloco[2], bloco[3], bloco[4])
	blocos.moveu.connect(_ao_mover_na_escada)
	_pessoa("althea", QUADROS_ALTHEA, Vector2i(3, 2))
	_pessoa("ophelia", QUADROS_OPHELIA, Vector2i(4, 2), true)
	_ao_interagir("ophelia", arrumar_as_caixas)
	_ativar(objetos["ophelia"], false)
	_entrar(CASA_ENTRADA_SALA_LATERAL)
	_travar(true)
	await _clarear()
	await agachar_nas_prateleiras()


## As duas se agacham entre as prateleiras baixas, junto às paredes, e a Thea
## faz o primeiro pedido.
func agachar_nas_prateleiras() -> void:
	var althea: Node2D = objetos["althea"]
	var ophelia: Node2D = objetos["ophelia"]
	_caminhar(ophelia, [sala.centro(Vector2i(2, 4)), sala.centro(CASA_OPHELIA_AGACHADA)])
	await _caminhar(althea, [sala.centro(Vector2i(5, 2)), sala.centro(CASA_ALTHEA_AGACHADA)])
	_virar(althea, sala.centro(Vector2i(6, 1)))
	_virar(ophelia, sala.centro(Vector2i(1, 5)))
	_abaixar(althea, true)
	_abaixar(ophelia, true)
	await _frases("frases_prateleiras")
	achados = 0
	_avisou_alto = false
	_calor = Label.new()
	_calor.name = "Calor"
	_calor.position = Vector2(-40, -62)
	_calor.size = Vector2(80, 20)
	_calor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_calor.add_theme_font_size_override("font_size", 14)
	_calor.add_theme_constant_override("outline_size", 4)
	_calor.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	althea.add_child(_calor)
	await _frases("frases_pista_1")
	_mudar("prateleiras")
	_ativar(objetos["ophelia"], true)
	blocos.ativo = true
	_travar(false)


## A cada quadro, na sala lateral: o calor da Thea e achar a pelúcia ao
## chegar ao lado do esconderijo (no chão).
func _sala_lateral_quadro(_delta: float) -> void:
	if achados >= PISTAS.size() or _procurando:
		return
	var nome: String = PISTAS[achados][0]
	var distancia := Vector2(_casa_de(jogador) - ESCONDERIJOS[nome][0]).length()
	_atualizar_calor(distancia)
	var perto := jogador.position.distance_to(sala.centro(ESCONDERIJOS[nome][0])) <= ACHAR_A
	if not perto or blocos.altura > 0 or blocos.segurando != "":
		return
	if nome != "estante_alta":
		procurar(nome)
	elif not _avisou_alto:
		_avisou_alto = true
		_frases("frases_alto_demais")


## Em cima da escada, ao lado da estante e alto o bastante: alcança.
func _ao_mover_na_escada(casa: Vector2i, altura: int) -> void:
	if achados < PISTAS.size() and PISTAS[achados][0] == "estante_alta" and _alcanca_a_estante(casa, altura):
		procurar("estante_alta")


func _alcanca_a_estante(casa: Vector2i, altura: int) -> bool:
	var estante: Vector2i = ESCONDERIJOS["estante_alta"][0]
	return altura >= ALTURA_PARA_ALCANCAR and maxi(absi(casa.x - estante.x), absi(casa.y - estante.y)) == 1


## Thea esquenta ou esfria conforme Nicholas chega perto; quente, ela se
## levanta.
func _atualizar_calor(distancia: float) -> void:
	if _calor == null or not is_instance_valid(_calor):
		return
	var quente := distancia <= CALOR.y
	if quente:
		_calor.text = tr("CALOR_QUENTE")
		_calor.modulate = Color(1.0, 0.55, 0.35)
	elif distancia <= CALOR.z:
		_calor.text = tr("CALOR_MORNO")
		_calor.modulate = Color(1.0, 0.85, 0.5)
	else:
		_calor.text = tr("CALOR_FRIO")
		_calor.modulate = Color(0.6, 0.8, 1.0)
	var althea: Node2D = objetos["althea"]
	if althea.get_meta(&"quente", false) != quente:
		althea.set_meta(&"quente", quente)
		_abaixar(althea, not quente)
		_virar(althea, jogador.position if quente else sala.centro(Vector2i(6, 1)))


## Nicholas acha a pelúcia do pedido em [param nome]: ela aparece grande em
## cima do esconderijo e vai para a Thea (que já tem uma igual), e ela pede
## a próxima. A do alto da estante, só do alto da escada.
func procurar(nome: String) -> void:
	if etapa != "prateleiras" or achados >= PISTAS.size() or _procurando:
		return
	var pedido: Array = PISTAS[achados]
	if nome != pedido[0] or (nome == "estante_alta"
			and not _alcanca_a_estante(_casa_de(jogador), blocos.altura)):
		return
	_procurando = true
	blocos.ativo = false
	blocos.soltar()
	_travar(true)
	var de: Vector2 = objetos[nome].position
	if nome == "estante_alta":
		objetos["estante_alta"].get_node("Pelucia").queue_free()
		de += Vector2(0, -40)
		await _frases("frases_subir")
		# Desce para o chão, ao lado da escada.
		blocos.por_no_chao(_casa_livre_perto(_casa_de(jogador), _casa_de(objetos["althea"])))
	await _levar_para_a_thea(pedido[1], de)
	achados += 1
	await _frases("frases_prateleira_%d" % achados)
	if achados < PISTAS.size():
		await _frases("frases_pista_%d" % (achados + 1))
		_procurando = false
		blocos.ativo = true
		_travar(false)
		return
	_mudar("presente")
	_calor.queue_free()
	_ativar(objetos["ophelia"], false)
	_abaixar(objetos["althea"], true)
	_procurando = false
	await ophelia_traz_a_criatura()


## A pelúcia achada sobe grande em cima do esconderijo, com um som, e voa
## até a Thea.
func _levar_para_a_thea(pelucia: String, de: Vector2) -> void:
	var althea: Node2D = objetos["althea"]
	var bicho := Sprite2D.new()
	bicho.name = "Achada"
	bicho.texture = load(ARTE + "loja/pelucia_%s.png" % pelucia)
	bicho.position = de + Vector2(0, -24)
	bicho.scale = Vector2.ONE * 0.4
	bicho.z_index = 5
	sala.add_child(bicho)
	var som := AudioStreamPlayer.new()
	som.stream = load(BlocosDaSala.SFX + "achou.wav")
	som.bus = BlocosDaSala.BARRAMENTO
	bicho.add_child(som)
	som.play()
	if escala_tempo > 0.0:
		var voo := create_tween()
		voo.tween_property(bicho, "position", de + Vector2(0, -56), 0.35 * escala_tempo)
		voo.parallel().tween_property(bicho, "scale", Vector2.ONE * 1.3, 0.35 * escala_tempo)
		voo.tween_interval(0.9 * escala_tempo)
		voo.tween_property(bicho, "position", althea.position + Vector2(0, -24), 0.6 * escala_tempo)
		voo.parallel().tween_property(bicho, "scale", Vector2.ONE * 0.6, 0.6 * escala_tempo)
		await voo.finished
	bicho.queue_free()


func _casa_livre(casa: Vector2i) -> bool:
	if casa.x < 1 or casa.y < 1 or casa.x >= sala.largura or casa.y >= sala.profundidade:
		return false
	if casa == _casa_de(jogador):
		return false
	for nome: String in objetos:
		var objeto: Node2D = objetos[nome]
		if nome != "tapete" and is_instance_valid(objeto) and objeto.get_parent() == sala \
				and _casa_de(objeto) == casa:
			return false
	return true


## E na Ophelia: ela põe a caixa e o banquinho de volta (se travou).
## Nicholas desce, se estiver em cima, e sai de onde algum bloco volta.
func arrumar_as_caixas() -> void:
	if etapa != "prateleiras" or _procurando:
		return
	_travar(true)
	blocos.ativo = false
	var casa := _casa_de(jogador)
	var origens: Array[Vector2i] = []
	for nome: String in BLOCOS:
		origens.append(BLOCOS[nome][0])
	if blocos.altura > 0 or origens.has(casa):
		blocos.por_no_chao(CASA_ENTRADA_SALA_LATERAL + Vector2i(0, 1))
	blocos.soltar()
	for nome: String in BLOCOS:
		objetos[nome].position = sala.centro(BLOCOS[nome][0])
	await _frases("frases_arrumar")
	blocos.ativo = true
	_travar(false)


## Casa livre ao lado de Nicholas, a mais alta na tela: virada para ele,
## Ophelia fica de frente para a câmera (Rafael, 26/10/2026). Fora as caixas.
func casa_de_ophelia_com_a_criatura() -> Vector2i:
	var dele := _casa_de(jogador)
	var caixas: Array[Vector2i] = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var c := dele + Vector2i(dx, dy)
			if blocos and blocos.bloco_em(c) != "":
				caixas.append(c)
	return _casa_livre_perto(dele, dele + Vector2i(-3, -3), caixas)


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
	var casa := casa_de_ophelia_com_a_criatura()
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
