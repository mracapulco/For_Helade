extends Node
## Bolsa do grupo: quantidade de cada item, dinheiro e o que cada
## personagem tem equipado (autoload "Inventario").
## No roteiro:
##   $> Inventario.adicionar("id_do_item")
##   if Inventario.tem("id_do_item")
## Os itens vêm de res://data/itens/ (um .tres por item).

signal mudou(id: String, quantidade: int)
signal dinheiro_mudou(valor: int)
signal equipamento_mudou(personagem: String, encaixe: Item.Encaixe, id: String)
signal item_usado(id: String, personagem: String)
## Item ganho (baú, roteiro, inimigo). Só em [method adicionar], para o
## aviso "+ item" não aparecer ao carregar um jogo salvo.
signal recebeu(id: String, quantidade: int)
signal dinheiro_recebido(valor: int)

const PASTA_ITENS := "res://data/itens/"

var _catalogo: Dictionary[String, Item] = {}
var _quantidades: Dictionary[String, int] = {}
var _dinheiro: int = 0
## personagem -> { Item.Encaixe -> id do item }
var _equipado: Dictionary[String, Dictionary] = {}
## Baús e outras recompensas já pegas, para não darem itens de novo.
var _coletados: Dictionary[String, bool] = {}


func _init() -> void:
	_carregar_catalogo()


func _carregar_catalogo() -> void:
	if not DirAccess.dir_exists_absolute(PASTA_ITENS):
		return
	for arquivo: String in ResourceLoader.list_directory(PASTA_ITENS):
		if not arquivo.ends_with(".tres"):
			continue
		var item := load(PASTA_ITENS + arquivo) as Item
		if item == null:
			push_error("Inventario: %s não é um Item." % arquivo)
			continue
		registrar(item)


## Põe um item no catálogo. Os itens da pasta já entram sozinhos; isto
## serve para testes e itens criados por código.
func registrar(item: Item) -> void:
	if item.id.is_empty():
		push_error("Inventario: item sem id.")
		return
	_catalogo[item.id] = item


## Dados do item, ou null se o id não existir.
func item(id: String) -> Item:
	return _catalogo.get(id, null)


func quantidade(id: String) -> int:
	return _quantidades.get(id, 0)


func tem(id: String, qtd: int = 1) -> bool:
	return quantidade(id) >= qtd


## Ids de tudo o que está na bolsa, de um tipo, em ordem alfabética.
func ids_do_tipo(tipo: Item.Tipo) -> Array[String]:
	var ids: Array[String] = []
	for id: String in _quantidades:
		if _catalogo[id].tipo == tipo:
			ids.append(id)
	ids.sort()
	return ids


## Põe [param qtd] unidades na bolsa. Falha se o id não existir.
func adicionar(id: String, qtd: int = 1) -> bool:
	if item(id) == null:
		push_error("Inventario: item desconhecido '%s'." % id)
		return false
	if qtd <= 0:
		return false
	_quantidades[id] = quantidade(id) + qtd
	mudou.emit(id, _quantidades[id])
	recebeu.emit(id, qtd)
	return true


## Tira [param qtd] unidades. Falha se não houver o suficiente.
## O roteiro pode tirar itens da história; o jogador usa [method largar].
## Se sobrar menos do que está equipado, desequipa o excedente.
func remover(id: String, qtd: int = 1) -> bool:
	if qtd <= 0 or not tem(id, qtd):
		return false
	var resta := quantidade(id) - qtd
	if resta == 0:
		_quantidades.erase(id)
	else:
		_quantidades[id] = resta
	_desequipar_excedente(id)
	mudou.emit(id, resta)
	return true


## Ação do jogador: joga fora. Itens da história nunca saem assim.
func largar(id: String, qtd: int = 1) -> bool:
	var dados := item(id)
	if dados == null or dados.e_da_historia():
		return false
	return remover(id, qtd)


## Ação do jogador: usa um consumível em um personagem e gasta uma
## unidade. O efeito (cura etc.) fica com quem ouve [signal item_usado].
func usar(id: String, personagem: String) -> bool:
	var dados := item(id)
	if dados == null or not dados.pode_usar() or not tem(id):
		return false
	remover(id)
	item_usado.emit(id, personagem)
	return true


func dinheiro() -> int:
	return _dinheiro


func ganhar_dinheiro(valor: int) -> void:
	if valor <= 0:
		return
	_dinheiro += valor
	dinheiro_mudou.emit(_dinheiro)
	dinheiro_recebido.emit(valor)


## Gasta se houver o suficiente; senão não muda nada e devolve false.
func gastar_dinheiro(valor: int) -> bool:
	if valor < 0 or valor > _dinheiro:
		return false
	_dinheiro -= valor
	dinheiro_mudou.emit(_dinheiro)
	return true


## Id do item equipado pelo personagem naquele encaixe, ou "".
func equipado(personagem: String, encaixe: Item.Encaixe) -> String:
	return _equipado.get(personagem, {}).get(encaixe, "")


## Equipa o item no encaixe dele, trocando o que estava lá. Precisa
## haver uma unidade livre (não equipada por outra pessoa).
func equipar(personagem: String, id: String) -> bool:
	var dados := item(id)
	if dados == null or not dados.pode_equipar():
		return false
	if equipado(personagem, dados.encaixe) == id:
		return true
	if _vezes_equipado(id) >= quantidade(id):
		return false
	if not _equipado.has(personagem):
		_equipado[personagem] = {}
	# Arma de duas mãos e escudo não andam juntos: equipar um tira o outro.
	if dados.duas_maos():
		desequipar(personagem, Item.Encaixe.ESCUDO)
	elif dados.encaixe == Item.Encaixe.ESCUDO:
		var arma := item(equipado(personagem, Item.Encaixe.ARMA))
		if arma and arma.duas_maos():
			desequipar(personagem, Item.Encaixe.ARMA)
	_equipado[personagem][dados.encaixe] = id
	equipamento_mudou.emit(personagem, dados.encaixe, id)
	return true


## Itens que o personagem tem equipados, em todos os encaixes.
func itens_equipados(personagem: String) -> Array[Item]:
	var itens: Array[Item] = []
	for encaixe: int in _equipado.get(personagem, {}):
		var dados := item(_equipado[personagem][encaixe])
		if dados:
			itens.append(dados)
	return itens


## Ataque, defesa e velocidade do personagem com o que tem equipado
## (Balanceamento.somar): { "ataque", "defesa", "velocidade" }.
func atributos(personagem: String) -> Dictionary:
	return Balanceamento.somar(itens_equipados(personagem))


func desequipar(personagem: String, encaixe: Item.Encaixe) -> void:
	if equipado(personagem, encaixe).is_empty():
		return
	_equipado[personagem].erase(encaixe)
	equipamento_mudou.emit(personagem, encaixe, "")


func ja_coletado(id_coleta: String) -> bool:
	return _coletados.has(id_coleta)


func marcar_coletado(id_coleta: String) -> void:
	_coletados[id_coleta] = true


## Apaga tudo (novo jogo, testes). O catálogo continua.
func limpar() -> void:
	_quantidades.clear()
	_equipado.clear()
	_coletados.clear()
	_dinheiro = 0


## Cópia do estado, para salvar o jogo. Encaixes viram texto.
func para_dados() -> Dictionary:
	var equipado_dados := {}
	for personagem: String in _equipado:
		var encaixes := {}
		for encaixe: int in _equipado[personagem]:
			encaixes[Item.Encaixe.find_key(encaixe)] = _equipado[personagem][encaixe]
		equipado_dados[personagem] = encaixes
	return {
		"itens": _quantidades.duplicate(),
		"dinheiro": _dinheiro,
		"equipado": equipado_dados,
		"coletados": _coletados.keys(),
	}


## Restaura o que [method para_dados] gerou. Ids que não existem mais
## no catálogo são ignorados.
func de_dados(dados: Dictionary) -> void:
	limpar()
	var itens: Dictionary = dados.get("itens", {})
	for id: Variant in itens:
		if item(str(id)) != null and int(itens[id]) > 0:
			_quantidades[str(id)] = int(itens[id])
	_dinheiro = maxi(0, int(dados.get("dinheiro", 0)))
	for id_coleta: Variant in dados.get("coletados", []):
		_coletados[str(id_coleta)] = true
	var equipado_dados: Dictionary = dados.get("equipado", {})
	for personagem: Variant in equipado_dados:
		var encaixes: Dictionary = equipado_dados[personagem]
		for nome: Variant in encaixes:
			if Item.Encaixe.has(str(nome)):
				equipar(str(personagem), str(encaixes[nome]))


func _vezes_equipado(id: String) -> int:
	var vezes := 0
	for personagem: String in _equipado:
		for encaixe: int in _equipado[personagem]:
			if _equipado[personagem][encaixe] == id:
				vezes += 1
	return vezes


func _desequipar_excedente(id: String) -> void:
	for personagem: String in _equipado.keys():
		if _vezes_equipado(id) <= quantidade(id):
			return
		for encaixe: int in _equipado[personagem].keys():
			if _equipado[personagem][encaixe] == id:
				desequipar(personagem, encaixe)
				break
