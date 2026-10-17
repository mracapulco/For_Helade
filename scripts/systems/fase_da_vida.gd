class_name FaseDaVida
extends Resource
## O corpo do personagem em cada fase da vida (criança, adolescente,
## adulto): vida, ataque sem arma e velocidade. Um .tres por fase em
## res://data/fases_da_vida/, com o nome da fase em minúsculas
## (crianca.tres, adolescente.tres, adulto.tres). Valores provisórios,
## para ajustar testando.
## O que cada fase pode equipar fica no próprio item ([member Item.fase_minima]).

## Vida máxima base, antes de níveis e poções.
@export var vida_base := 30
## Ataque sem arma (soco). A arma soma por cima.
@export var ataque_base := 3
## Em porcentagem, como nos itens: +10 = 10% mais rápido.
@export var velocidade := 0
