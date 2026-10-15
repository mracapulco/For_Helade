class_name Vida
extends Node
## Vida de quem pode apanhar no combate: recebe golpes (o dano sai de
## Balanceamento.dano, com a defesa), cura e morre.
## Com [member id_inventario], a defesa soma o equipamento desse personagem
## no Inventario (armadura, elmo, escudo); sem ele, vale só [member defesa].

signal mudou(atual: int, maxima: int)
## Levou um golpe e perdeu [param valor] de vida.
signal machucou(valor: int)
signal morreu

@export var maxima := 30
## Defesa própria (inimigos sem inventário). Soma com a do equipamento.
@export var defesa := 0
## Id do personagem no Inventario. Vazio = não usa equipamento.
@export var id_inventario := ""
## Para bonecos de treino: ao chegar a zero, avisa [signal morreu] e volta cheio.
@export var reviver_ao_morrer := false

var atual := 0


func _ready() -> void:
	atual = maxima


func morto() -> bool:
	return atual <= 0


func defesa_total() -> int:
	var total := defesa
	if not id_inventario.is_empty():
		total += int(Inventario.atributos(id_inventario).defesa)
	return total


## Recebe um golpe com esse [param ataque]. Devolve o dano tirado.
func receber_ataque(ataque: int) -> int:
	if morto() or ataque <= 0:
		return 0
	var valor := Balanceamento.dano(ataque, defesa_total())
	perder(valor)
	return valor


## Perde vida sem passar pela defesa (queda, veneno).
func perder(valor: int) -> void:
	if morto() or valor <= 0:
		return
	atual = maxi(0, atual - valor)
	machucou.emit(valor)
	mudou.emit(atual, maxima)
	if morto():
		morreu.emit()
		if reviver_ao_morrer:
			atual = maxima
			mudou.emit(atual, maxima)


func curar(valor: int) -> void:
	if morto() or valor <= 0:
		return
	atual = mini(maxima, atual + valor)
	mudou.emit(atual, maxima)
