class_name Medidor
extends Node
## Guarda um valor inteiro por id. É a base de [Relacoes] (por personagem)
## e [Influencia] (por casa). Os ids são texto simples, sem acento, como
## "janet" ou "olympia".

signal mudou(id: String, valor: int)

var _valores: Dictionary[String, int] = {}


## Valor atual de um id. Quem nunca foi ajustado vale 0.
func valor(id: String) -> int:
	return _valores.get(id, 0)


## Soma [param delta] ao valor de [param id] (use negativo para diminuir).
func ajustar(id: String, delta: int) -> void:
	_valores[id] = valor(id) + delta
	mudou.emit(id, _valores[id])


## Apaga todos os valores (novo jogo, testes).
func limpar() -> void:
	_valores.clear()


## Cópia dos valores, para salvar o jogo.
func para_dados() -> Dictionary:
	return _valores.duplicate()


## Restaura valores salvos com [method para_dados].
func de_dados(dados: Dictionary) -> void:
	_valores.clear()
	for id: Variant in dados:
		_valores[str(id)] = int(dados[id])
