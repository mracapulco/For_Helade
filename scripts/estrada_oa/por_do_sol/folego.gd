class_name Folego
extends RefCounted
## O fôlego de Nicholas na corrida contra o pôr do sol: correr (Shift) gasta,
## andar ou parar devolve depois de um respiro. Quando acaba, ele fica cansado
## e só volta a correr depois de recuperar [member para_voltar] do fôlego.

const MAXIMO := 100.0

## Quanto se gasta por segundo correndo (100 = 4 s de corrida seguida).
@export var gasto := 25.0
## Quanto volta por segundo sem correr.
@export var recuperacao := 20.0
## Quanto tempo sem correr antes de começar a recuperar.
@export var espera := 0.5
## Cansado, só volta a correr com este tanto.
@export var para_voltar := 35.0

var atual := MAXIMO
var cansado := false
var _sem_correr := 0.0


## Avança [param delta] segundos. [param correndo]: Shift apertado e andando.
## Devolve se ele pode correr agora.
func atualizar(delta: float, correndo: bool) -> bool:
	if correndo and not cansado:
		_sem_correr = 0.0
		atual = maxf(atual - gasto * delta, 0.0)
		if atual <= 0.0:
			cansado = true
	else:
		_sem_correr += delta
		if _sem_correr >= espera:
			atual = minf(atual + recuperacao * delta, MAXIMO)
		if cansado and atual >= para_voltar:
			cansado = false
	return pode_correr()


func pode_correr() -> bool:
	return not cansado and atual > 0.0


## Quanto resta, de 0 a 1 (a barra na tela).
func fracao() -> float:
	return atual / MAXIMO
