class_name CenaPasseio
extends CenaCapitulo01
## Capítulo 01, cena 11: a tarde em Atenas (livro, l. ~555-563: "Althea os
## arrastou para mais duas lojas de brinquedos, uma livraria e uma
## confeitaria"). Uma rua curta com as quatro lojas, sem cenário por dentro
## (Rafael, 24/10/2026).
## Sequência:
## 1. passeio: Althea corre na frente até a porta de uma loja ainda não
##    visitada e espera ali; E em qualquer porta (a ordem é do jogador) leva
##    para dentro: a tela escurece, uma frase curta, e os três saem pela
##    mesma porta. A luz da rua vai ficando dourada a cada loja. Na
##    livraria, Nicholas folheia um livro: entrada do Códice "Ano Dourado".
##    E na Ophelia (uma vez): as frases do livro sobre a conversa ficar mais
##    natural e +1 de relação com ela (regra do jogo).
## 2. Depois das quatro, "o Sol já descia entre os telhados" e a etapa vira
##    "volta" (a volta à mansão; sem cena ainda: volta ao menu).
## Textos: data/dialogos/capitulo_01/passeio.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/passeio.dialogue")
const LARGURA_RUA := 20
const PROFUNDIDADE_RUA := 8
## As lojas: porta (casa na parede do fundo), mercadoria da fachada e frase
## ao entrar ("" = nenhuma). As duas de brinquedos usam a mesma frase do
## livro, só na primeira em que entrar.
const LOJAS := {
	"brinquedos_1": [Vector2i(3, 0), "brinquedos", "frases_brinquedos"],
	"livraria": [Vector2i(8, 0), "livros", ""],
	"brinquedos_2": [Vector2i(13, 0), "brinquedos", "frases_brinquedos"],
	"confeitaria": [Vector2i(17, 0), "doces", "frases_confeitaria"],
}
const CASA_JOGADOR := Vector2i(10, 5)
const CASA_ALTHEA := Vector2i(11, 4)
const CASA_OPHELIA := Vector2i(9, 4)
## A luz da rua do começo da tarde até o pôr do sol, uma etapa por loja.
const TOM_POR_DO_SOL := Color(1.0, 0.78, 0.55)

## Lojas já visitadas, na ordem.
var visitadas: Array[String] = []
var conversou_com_ophelia := false
var _ocupado := false


func _init() -> void:
	roteiro = ROTEIRO
	objetivos = {"passeio": "OBJ_CAP1_PASSEIO"}


func id_da_cena() -> String:
	return "passeio"


func comecar() -> void:
	montar_rua()
	await _clarear()
	await _frases("frases_passeio")
	_mudar("passeio")
	for loja: String in LOJAS:
		_ativar(objetos["porta_" + loja], true)
	_ativar(objetos["ophelia"], true)
	await althea_vai_na_frente()


func montar_rua() -> void:
	_nova_sala(LARGURA_RUA, PROFUNDIDADE_RUA, TOM_DIA, "rua", "fachada")
	visitadas.clear()
	var enfeites: Array = []
	var portas := {}
	for loja: String in LOJAS:
		portas[LOJAS[loja][0].x] = loja
	for x in range(1, LARGURA_RUA):
		var loja := _loja_da_fachada(x)
		var mercadoria: String = LOJAS[loja][1]
		if portas.has(x):
			enfeites.append(["porta_esq", Vector2i(x, 0)])
		elif absi(x - LOJAS[loja][0].x) == 1 and x < LOJAS[loja][0].x:
			enfeites.append(["placa_%s_esq" % mercadoria, Vector2i(x, 0)])
		else:
			enfeites.append(["vitrine_%s_esq" % mercadoria, Vector2i(x, 0)])
			enfeites.append(["toldo_pelucias_esq" if loja == "brinquedos_2" else "toldo_esq", Vector2i(x, 0)])
	for y in range(1, PROFUNDIDADE_RUA):
		enfeites.append(["vitrine_dir", Vector2i(0, y)])
		enfeites.append(["toldo_dir", Vector2i(0, y)])
	_pendurar(enfeites)
	for x in [5, 11, 15]:
		_objeto("lampiao_%d" % x, "rua/lampiao", Vector2i(x, 2))
	for x in [6, 19]:
		_objeto("vaso_flor_%d" % x, "rua/vaso_flor", Vector2i(x, 1))
	_pessoa("althea", QUADROS_ALTHEA, CASA_ALTHEA)
	var ophelia := _pessoa("ophelia", QUADROS_OPHELIA, CASA_OPHELIA, true)
	_ativar(ophelia, false)
	_ao_interagir("ophelia", conversar_com_ophelia)
	for loja: String in LOJAS:
		_ponto("porta_" + loja, LOJAS[loja][0] + Vector2i(0, 1))
		_ativar(objetos["porta_" + loja], false)
		_ao_interagir("porta_" + loja, entrar.bind(loja))
	_entrar(CASA_JOGADOR)
	jogador.direcao_olhar = Vector2(0, -1)


## A loja da fachada na coluna [param x] (cada uma vai até a metade do
## caminho para a porta da próxima).
func _loja_da_fachada(x: int) -> String:
	var perto := ""
	var menor := 999
	for loja: String in LOJAS:
		var distancia := absi(x - LOJAS[loja][0].x)
		if distancia < menor:
			menor = distancia
			perto = loja
	return perto


## A loja ainda não visitada mais perto de Nicholas, onde a Althea espera.
func proxima_da_althea() -> String:
	var melhor := ""
	var menor := INF
	for loja: String in LOJAS:
		if loja in visitadas:
			continue
		var distancia := jogador.position.distance_to(sala.centro(LOJAS[loja][0]))
		if distancia < menor:
			menor = distancia
			melhor = loja
	return melhor


## Althea corre até a porta da próxima loja e espera ao lado dela.
func althea_vai_na_frente() -> void:
	var loja := proxima_da_althea()
	if loja == "":
		return
	var porta: Vector2i = LOJAS[loja][0]
	var casa := _casa_livre_perto(porta + Vector2i(1, 1), _casa_de(objetos["althea"]))
	await _caminhar(objetos["althea"], [sala.centro(casa)], 0.5)
	_virar(objetos["althea"], sala.centro(porta))


## E na porta: entra (a tela escurece), a frase da loja e os três saem.
func entrar(loja: String) -> void:
	if etapa != "passeio" or _ocupado or loja in visitadas:
		return
	_ocupado = true
	_ativar(objetos["porta_" + loja], false)
	_travar(true)
	var frase: String = LOJAS[loja][2]
	if frase == "frases_brinquedos" and ("brinquedos_1" in visitadas or "brinquedos_2" in visitadas):
		frase = ""
	visitadas.append(loja)
	await _escurecer()
	_dourar_a_luz()
	var porta: Vector2i = LOJAS[loja][0]
	jogador.position = sala.centro(porta + Vector2i(0, 1))
	objetos["althea"].position = sala.centro(_casa_livre_perto(porta + Vector2i(1, 1), porta))
	objetos["ophelia"].position = sala.centro(_casa_livre_perto(porta + Vector2i(-1, 1), porta))
	await _clarear()
	if frase != "":
		await _frases(frase)
	if loja == "livraria":
		Codice.anotar("ano_dourado")
	_ocupado = false
	if visitadas.size() >= LOJAS.size():
		await fim_da_tarde()
		return
	_travar(false)
	await althea_vai_na_frente()


## A cada loja a luz fica mais dourada (a tarde passa).
func _dourar_a_luz() -> void:
	var parte := float(visitadas.size()) / LOJAS.size()
	sala.ambiente.color = TOM_DIA.lerp(TOM_POR_DO_SOL, parte)


## E na Ophelia, uma vez: a conversa fica mais natural (+1 de relação).
func conversar_com_ophelia() -> void:
	if etapa != "passeio" or _ocupado or conversou_com_ophelia:
		return
	conversou_com_ophelia = true
	_ocupado = true
	_ativar(objetos["ophelia"], false)
	_travar(true)
	_virar(objetos["ophelia"], jogador.position)
	jogador.direcao_olhar = (objetos["ophelia"].position - jogador.position).normalized()
	Relacoes.ajustar("ophelia", 1)
	await _frases("frases_ophelia")
	_travar(false)
	_ocupado = false


func fim_da_tarde() -> void:
	_travar(true)
	await _frases("frases_sol")
	await terminar()
