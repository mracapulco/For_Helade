class_name EfeitosTemporarios
extends Node
## Efeitos das poções num personagem: a cura na hora e os que duram um tempo
## (rapidez e vigor, veja Item). Ouve o Inventario: usar uma poção na bolsa
## para este personagem aplica o efeito aqui.
## Fica como filho do personagem, ao lado da Vida.

signal mudou

## Id do personagem no Inventario.
@export var id_inventario := "nicholas"
## Vida que recebe a cura e o vigor.
@export var vida: Vida

## Efeitos ativos: { "id", "velocidade", "vida_extra", "resta", "duracao" }.
var _ativos: Array[Dictionary] = []


func _ready() -> void:
	Inventario.item_usado.connect(_ao_usar_item)


func _process(delta: float) -> void:
	if _ativos.is_empty():
		return
	for efeito in _ativos.duplicate():
		efeito.resta -= delta
		if efeito.resta <= 0.0:
			_encerrar(efeito)
	mudou.emit()


## Aplica os efeitos do item (cura, rapidez, vigor).
func aplicar(item: Item) -> void:
	if item == null:
		return
	if item.cura > 0 and vida:
		vida.curar(item.cura)
	if not item.tem_efeito_temporario():
		return
	# A mesma poção de novo renova o tempo, sem somar.
	for efeito in _ativos.duplicate():
		if efeito.id == item.id:
			_encerrar(efeito)
	var novo := {
		"id": item.id,
		"velocidade": item.velocidade_temporaria,
		"vida_extra": item.vida_extra,
		"resta": item.duracao_efeito,
		"duracao": item.duracao_efeito,
	}
	_ativos.append(novo)
	if item.vida_extra > 0 and vida:
		vida.ganhar_extra(item.vida_extra)
	mudou.emit()


## Velocidade a mais (em %) somando os efeitos ativos.
func bonus_velocidade() -> int:
	var total := 0
	for efeito in _ativos:
		total += int(efeito.velocidade)
	return total


## Cópia dos efeitos ativos, para a interface.
func ativos() -> Array[Dictionary]:
	return _ativos.duplicate(true)


## Acaba com todos (derrota, troca de cena).
func limpar() -> void:
	for efeito in _ativos.duplicate():
		_encerrar(efeito)
	mudou.emit()


func _encerrar(efeito: Dictionary) -> void:
	_ativos.erase(efeito)
	if int(efeito.vida_extra) > 0 and vida:
		vida.perder_extra(int(efeito.vida_extra))


func _ao_usar_item(id: String, quem: String) -> void:
	if quem == id_inventario:
		aplicar(Inventario.item(id))
