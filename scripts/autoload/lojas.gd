extends Node
## Compra e venda com os mercadores (autoload "Lojas").
## Cada loja tem estoque limitado, que volta a encher quando o jogador
## descansa na barraca de um acampamento ([method renovar]). Vender devolve
## metade do preço do item; itens da história não se vendem.
## As lojas vêm de res://data/lojas/ (um .tres por mercador).

signal estoque_mudou(loja: String, id: String)

const PASTA_LOJAS := "res://data/lojas/"
## Parte do preço que o mercador paga quando o jogador vende.
const FRACAO_VENDA := 0.5

## Por que uma compra ou venda não aconteceu.
enum Resultado { OK, NAO_VENDE, SEM_ESTOQUE, SEM_MOEDAS, BOLSA_CHEIA, NAO_TEM, DA_HISTORIA, SEM_VALOR }

var _catalogo: Dictionary[String, Loja] = {}
## loja -> { item -> quantidade comprada desde a última renovação }
var _comprados: Dictionary = {}


func _init() -> void:
	if not DirAccess.dir_exists_absolute(PASTA_LOJAS):
		return
	for arquivo: String in ResourceLoader.list_directory(PASTA_LOJAS):
		if arquivo.ends_with(".tres"):
			var loja := load(PASTA_LOJAS + arquivo) as Loja
			if loja == null:
				push_error("Lojas: %s não é uma Loja." % arquivo)
				continue
			registrar(loja)


## Põe uma loja no catálogo (as da pasta já entram sozinhas).
func registrar(loja: Loja) -> void:
	if loja.id.is_empty():
		push_error("Lojas: loja sem id.")
		return
	_catalogo[loja.id] = loja


func loja(id: String) -> Loja:
	return _catalogo.get(id, null)


## Ids do que a loja vende, na ordem do .tres.
func mercadorias(id_loja: String) -> Array[String]:
	var ids: Array[String] = []
	var dados := loja(id_loja)
	if dados:
		ids.assign(dados.itens.keys())
	return ids


## Quanto ainda há do item nesta loja.
func estoque(id_loja: String, id: String) -> int:
	var dados := loja(id_loja)
	if dados == null or not dados.itens.has(id):
		return 0
	return maxi(0, dados.itens[id] - int(_comprados.get(id_loja, {}).get(id, 0)))


func preco_compra(_id_loja: String, id: String) -> int:
	var dados := Inventario.item(id)
	return dados.preco if dados else 0


func preco_venda(id: String) -> int:
	var dados := Inventario.item(id)
	if dados == null or dados.preco <= 0:
		return 0
	return maxi(1, floori(dados.preco * FRACAO_VENDA))


func pode_comprar(id_loja: String, id: String, qtd := 1) -> Resultado:
	var dados := loja(id_loja)
	if dados == null or not dados.itens.has(id) or Inventario.item(id) == null or qtd <= 0:
		return Resultado.NAO_VENDE
	if estoque(id_loja, id) < qtd:
		return Resultado.SEM_ESTOQUE
	if Inventario.dinheiro() < preco_compra(id_loja, id) * qtd:
		return Resultado.SEM_MOEDAS
	if not Inventario.cabe(id, qtd):
		return Resultado.BOLSA_CHEIA
	return Resultado.OK


func comprar(id_loja: String, id: String, qtd := 1) -> Resultado:
	var resultado := pode_comprar(id_loja, id, qtd)
	if resultado != Resultado.OK:
		return resultado
	Inventario.gastar_dinheiro(preco_compra(id_loja, id) * qtd)
	Inventario.adicionar(id, qtd)
	if not _comprados.has(id_loja):
		_comprados[id_loja] = {}
	_comprados[id_loja][id] = int(_comprados[id_loja].get(id, 0)) + qtd
	estoque_mudou.emit(id_loja, id)
	return Resultado.OK


func pode_vender(id: String, qtd := 1) -> Resultado:
	var dados := Inventario.item(id)
	if dados == null or qtd <= 0 or not Inventario.tem(id, qtd):
		return Resultado.NAO_TEM
	if dados.e_da_historia():
		return Resultado.DA_HISTORIA
	if preco_venda(id) <= 0:
		return Resultado.SEM_VALOR
	return Resultado.OK


## Vende da bolsa (se estiver equipado, desequipa). O mercador não guarda
## o que compra do jogador: o estoque dele não muda.
func vender(id: String, qtd := 1) -> Resultado:
	var resultado := pode_vender(id, qtd)
	if resultado != Resultado.OK:
		return resultado
	Inventario.remover(id, qtd)
	Inventario.ganhar_dinheiro(preco_venda(id) * qtd)
	return Resultado.OK


## Todas as lojas voltam ao estoque cheio (descansar no acampamento).
func renovar() -> void:
	_comprados.clear()
	estoque_mudou.emit("", "")


func limpar() -> void:
	_comprados.clear()


func para_dados() -> Dictionary:
	return { "comprados": _comprados.duplicate(true) }


func de_dados(dados: Dictionary) -> void:
	_comprados.clear()
	var comprados = dados.get("comprados", {})
	if comprados is Dictionary:
		for id_loja in comprados:
			var por_item: Dictionary = {}
			for id in comprados[id_loja]:
				por_item[str(id)] = int(comprados[id_loja][id])
			_comprados[str(id_loja)] = por_item
