class_name GradeOcupacao
extends RefCounted
## Quem está em cada casa do chão na exploração: uma casa, um personagem.
## O jogador e os inimigos ocupam a casa onde estão e reservam a próxima
## antes de dar um passo; ninguém entra numa casa ocupada ou reservada.
## Vale para a sala aberta agora (uma por vez). Quem sai da árvore de cenas
## perde as casas sozinho.

## Casa (Vector2i) -> id da instância de quem ocupa.
static var _casas := {}


## Quem ocupa ou reservou a [param casa], ou null.
static func ocupante(casa: Vector2i) -> Node:
	if not _casas.has(casa):
		return null
	var quem := instance_from_id(_casas[casa]) as Node
	if quem == null or not quem.is_inside_tree():
		_casas.erase(casa)
		return null
	return quem


## A [param casa] está livre para [param quem] (vazia ou já dele).
static func livre_para(casa: Vector2i, quem: Node) -> bool:
	var dono := ocupante(casa)
	return dono == null or dono == quem


## Ocupa ou reserva a casa. Devolve false se já for de outro.
static func ocupar(casa: Vector2i, quem: Node) -> bool:
	if not livre_para(casa, quem):
		return false
	_casas[casa] = quem.get_instance_id()
	return true


static func liberar(casa: Vector2i, quem: Node) -> void:
	if _casas.get(casa, 0) == quem.get_instance_id():
		_casas.erase(casa)


## Solta todas as casas de [param quem] (morreu, foi levado para outro lugar).
static func liberar_tudo(quem: Node) -> void:
	for casa: Vector2i in _casas.keys():
		if _casas[casa] == quem.get_instance_id():
			_casas.erase(casa)


## Casas de [param quem], para os testes e a depuração.
static func casas_de(quem: Node) -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for casa: Vector2i in _casas.keys():
		if _casas[casa] == quem.get_instance_id():
			lista.append(casa)
	return lista


static func limpar() -> void:
	_casas.clear()
