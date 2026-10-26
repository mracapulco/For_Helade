class_name ObraEstrada
extends RefCounted
## As regras da fase "A estrada desabou" (estrada Atenas–Olympia, trecho 3),
## sem desenho: uma grade de casas com chão, pedra fixa, buraco e as peças
## da carga. Assim os testes conferem o quebra-cabeça sem abrir a cena.
## Regras (inferência, não do livro; Rafael aprovou o desenho da fase em
## 26/10/2026):
## - Caixa: empurra e puxa, uma casa por vez.
## - Barril: só empurra; rola até bater em algo (pedra, peça, borda).
## - Tora: só anda no sentido do comprimento ([member Peca.eixo]), empurrando
##   ou puxando.
## - Peça que entra num buraco cai nele e vira ponte: a casa passa a ser chão.
## A planta vem de linhas de texto, uma por fileira (y), um caractere por casa
## (x), com a legenda de [constant LEGENDA].

enum Terreno { CHAO, PEDRA, BURACO, PONTE }
enum Tipo { CAIXA, BARRIL, TORA }

## . chão, # pedra fixa, _ buraco, C caixa, B barril, = tora no sentido de x,
## | tora no sentido de y. Peças ficam em cima do chão.
const LEGENDA := ".#_CB=|"
## Os quatro passos da grade (sem diagonal: peça só anda reto).
const PASSOS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var largura := 0
var profundidade := 0
## Casa -> Terreno.
var terreno := {}
## Nome da peça -> {"tipo": Tipo, "casa": Vector2i, "eixo": Vector2i}.
## O eixo só vale para a tora.
var pecas := {}
## Casa do buraco -> tipo da peça que caiu nele (para o desenho da ponte).
var pontes := {}


static func de_planta(linhas: Array) -> ObraEstrada:
	var obra := ObraEstrada.new()
	obra.profundidade = linhas.size()
	var contagem := {}
	for y in linhas.size():
		var linha: String = linhas[y]
		obra.largura = maxi(obra.largura, linha.length())
		for x in linha.length():
			var casa := Vector2i(x, y)
			var c := linha[x]
			obra.terreno[casa] = Terreno.CHAO
			match c:
				"#":
					obra.terreno[casa] = Terreno.PEDRA
				"_":
					obra.terreno[casa] = Terreno.BURACO
				"C", "B", "=", "|":
					var tipo: Tipo = Tipo.CAIXA if c == "C" else (Tipo.BARRIL if c == "B" else Tipo.TORA)
					var eixo := Vector2i(0, 1) if c == "|" else Vector2i(1, 0)
					var prefixo: String = ["caixa", "barril", "tora"][tipo]
					contagem[prefixo] = int(contagem.get(prefixo, 0)) + 1
					obra.pecas["%s_%d" % [prefixo, contagem[prefixo]]] = {"tipo": tipo, "casa": casa, "eixo": eixo}
	return obra


func dentro(casa: Vector2i) -> bool:
	return casa.x >= 0 and casa.y >= 0 and casa.x < largura and casa.y < profundidade


func terreno_em(casa: Vector2i) -> Terreno:
	return terreno.get(casa, Terreno.PEDRA)


## A peça nesta casa, ou "".
func peca_em(casa: Vector2i) -> String:
	for nome: String in pecas:
		if pecas[nome]["casa"] == casa:
			return nome
	return ""


## Dá para pisar (Nicholas, a carroça): chão ou ponte, sem peça.
func andavel(casa: Vector2i) -> bool:
	return dentro(casa) and terreno_em(casa) in [Terreno.CHAO, Terreno.PONTE] and peca_em(casa) == ""


## Uma peça pode entrar: chão livre, ponte livre ou buraco (onde cai).
func cabe_peca(casa: Vector2i) -> bool:
	return dentro(casa) and terreno_em(casa) != Terreno.PEDRA and peca_em(casa) == ""


func buracos() -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for casa: Vector2i in terreno:
		if terreno[casa] == Terreno.BURACO:
			lista.append(casa)
	return lista


## A peça anda neste sentido? (a tora, só no comprimento)
func sentido_permitido(nome: String, passo: Vector2i) -> bool:
	var peca: Dictionary = pecas[nome]
	if peca["tipo"] != Tipo.TORA:
		return true
	return passo == peca["eixo"] or passo == -peca["eixo"]


## Nicholas, em [param de], empurra a peça vizinha no sentido [param passo]
## (de onde ele está para a peça). Devolve {} se não anda; senão
## {"caminho": casas por onde a peça passou (sem a de partida), "caiu": bool}.
func empurrar(nome: String, de: Vector2i, passo: Vector2i) -> Dictionary:
	if not pecas.has(nome) or pecas[nome]["casa"] != de + passo or not sentido_permitido(nome, passo):
		return {}
	var peca: Dictionary = pecas[nome]
	var caminho: Array[Vector2i] = []
	var casa: Vector2i = peca["casa"]
	while true:
		var proxima := casa + passo
		if not cabe_peca(proxima):
			break
		caminho.append(proxima)
		casa = proxima
		if terreno_em(casa) == Terreno.BURACO:
			break
		# Só o barril continua rolando.
		if peca["tipo"] != Tipo.BARRIL:
			break
	if caminho.is_empty():
		return {}
	return _assentar(nome, caminho)


## Nicholas, em [param de], segura a peça vizinha e dá um passo para trás
## (no sentido oposto ao da peça), trazendo-a. Barril não se puxa (rola).
## Devolve {} se não dá; senão {"caminho": [casa nova], "caiu": false}.
func puxar(nome: String, de: Vector2i) -> Dictionary:
	if not pecas.has(nome):
		return {}
	var peca: Dictionary = pecas[nome]
	var frente: Vector2i = peca["casa"] - de
	if not frente in PASSOS or peca["tipo"] == Tipo.BARRIL or not sentido_permitido(nome, -frente):
		return {}
	if not andavel(de - frente):
		return {}
	return _assentar(nome, [de] as Array[Vector2i])


func _assentar(nome: String, caminho: Array[Vector2i]) -> Dictionary:
	var fim: Vector2i = caminho[-1]
	var caiu := terreno_em(fim) == Terreno.BURACO
	if caiu:
		terreno[fim] = Terreno.PONTE
		pontes[fim] = pecas[nome]["tipo"]
		pecas.erase(nome)
	else:
		pecas[nome]["casa"] = fim
	return {"caminho": caminho, "caiu": caiu}


## Caminho mais curto (quatro direções) por casas andáveis, de [param de]
## até [param ate], incluindo as duas; vazio se não houver. Com
## [param ignorar_pecas], peças não bloqueiam (a carroça passa por cima).
func caminho(de: Vector2i, ate: Vector2i, ignorar_pecas := false) -> Array[Vector2i]:
	var veio := {de: de}
	var fila: Array[Vector2i] = [de]
	while not fila.is_empty():
		var casa: Vector2i = fila.pop_front()
		if casa == ate:
			break
		for passo in PASSOS:
			var vizinha := casa + passo
			if veio.has(vizinha) or not dentro(vizinha):
				continue
			var pisavel := terreno_em(vizinha) in [Terreno.CHAO, Terreno.PONTE]
			if not pisavel or (not ignorar_pecas and peca_em(vizinha) != ""):
				continue
			veio[vizinha] = casa
			fila.append(vizinha)
	var volta: Array[Vector2i] = []
	if not veio.has(ate):
		return volta
	var casa := ate
	while casa != de:
		volta.push_front(casa)
		casa = veio[casa]
	volta.push_front(de)
	return volta


## Cópia do estado (para recomeçar um trecho).
func foto() -> Dictionary:
	return {"terreno": terreno.duplicate(), "pecas": pecas.duplicate(true), "pontes": pontes.duplicate()}


func restaurar(dados: Dictionary) -> void:
	terreno = dados["terreno"].duplicate()
	pecas = dados["pecas"].duplicate(true)
	pontes = dados["pontes"].duplicate()
