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
## Vida a mais por um tempo (poção de vigor). Soma ao máximo.
var extra := 0


func _ready() -> void:
	atual = maxima


## Máximo agora, com a vida a mais de efeitos.
func maxima_total() -> int:
	return maxima + extra


## Fração da vida (0 a 1), para as barras.
func fracao() -> float:
	return clampf(float(atual) / maxf(1.0, maxima_total()), 0.0, 1.0)


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
	mudou.emit(atual, maxima_total())
	if morto():
		morreu.emit()
		if reviver_ao_morrer:
			restaurar()


func curar(valor: int) -> void:
	if morto() or valor <= 0:
		return
	atual = mini(maxima_total(), atual + valor)
	mudou.emit(atual, maxima_total())


## Volta com a vida cheia (também depois de morrer).
func restaurar() -> void:
	atual = maxima_total()
	mudou.emit(atual, maxima_total())


## Novo máximo (o personagem cresceu, subiu de nível). Ganha ou perde a
## diferença na vida atual, sem matar.
func mudar_maxima(nova: int) -> void:
	nova = maxi(1, nova)
	var diferenca := nova - maxima
	maxima = nova
	if not morto():
		atual = clampi(atual + diferenca, 1, maxima_total())
	mudou.emit(atual, maxima_total())


## Ganha [param valor] de vida a mais, já cheia (poção de vigor).
func ganhar_extra(valor: int) -> void:
	if morto() or valor <= 0:
		return
	extra += valor
	atual += valor
	mudou.emit(atual, maxima_total())


## O efeito acabou: o máximo volta, e a vida acima dele some (sem matar).
func perder_extra(valor: int) -> void:
	if valor <= 0:
		return
	extra = maxi(0, extra - valor)
	if not morto():
		atual = clampi(atual, 1, maxima_total())
	mudou.emit(atual, maxima_total())
