extends Node
## Nível dos personagens (autoload "Experiencia").
## O nível vem de dois lugares:
## - da história: um marco do livro garante um nível mínimo
##   ([method garantir_nivel]), para a força acompanhar o livro sem lutar;
## - das lutas: cada inimigo derrotado dá experiência ([method ganhar]),
##   para quem quiser ficar um pouco mais forte.
## Cada nível acima do 1 soma vida máxima e ataque ([constant VIDA_POR_NIVEL],
## [constant NIVEIS_POR_ATAQUE]), por cima do corpo da idade (FaseDaVida).
## No roteiro:
##   $> Experiencia.garantir_nivel("nicholas", 3)
## Valores provisórios, para ajustar testando.

## Ganhou experiência (total agora).
signal mudou(personagem: String, experiencia: int)
## Subiu de nível (pela luta ou pela história).
signal subiu(personagem: String, nivel: int)

const NIVEL_MAXIMO := 30
## Vida máxima a mais por nível acima do 1.
const VIDA_POR_NIVEL := 3
## A cada quantos níveis o ataque sobe 1.
const NIVEIS_POR_ATAQUE := 2
## Experiência para ir do nível 1 ao 2. Cada nível seguinte pede
## esse tanto a mais que o anterior (20, 40, 60...).
const PASSO_EXPERIENCIA := 20

## personagem -> experiência total
var _experiencia: Dictionary[String, int] = {}


## Experiência total para chegar ao [param nivel] (nível 1 = 0).
static func experiencia_para(nivel: int) -> int:
	var n := clampi(nivel, 1, NIVEL_MAXIMO) - 1
	return PASSO_EXPERIENCIA * n * (n + 1) / 2


## Nível de quem tem [param experiencia] no total.
static func nivel_com(experiencia: int) -> int:
	var nivel := 1
	while nivel < NIVEL_MAXIMO and experiencia >= experiencia_para(nivel + 1):
		nivel += 1
	return nivel


func experiencia(personagem: String) -> int:
	return _experiencia.get(personagem, 0)


func nivel(personagem: String) -> int:
	return nivel_com(experiencia(personagem))


## Quanto do caminho até o próximo nível já foi feito (0 a 1), para a barra.
func progresso(personagem: String) -> float:
	var atual := nivel(personagem)
	if atual >= NIVEL_MAXIMO:
		return 1.0
	var inicio := experiencia_para(atual)
	var fim := experiencia_para(atual + 1)
	return clampf(float(experiencia(personagem) - inicio) / (fim - inicio), 0.0, 1.0)


## Soma [param valor] de experiência (inimigo derrotado).
func ganhar(personagem: String, valor: int) -> void:
	if valor <= 0:
		return
	_definir(personagem, experiencia(personagem) + valor)


## Marco da história: garante pelo menos esse nível. Quem já passou dele
## pelas lutas não perde nada.
func garantir_nivel(personagem: String, minimo: int) -> void:
	var alvo := experiencia_para(minimo)
	if experiencia(personagem) < alvo:
		_definir(personagem, alvo)


## Vida máxima a mais pelo nível.
func bonus_vida(personagem: String) -> int:
	return (nivel(personagem) - 1) * VIDA_POR_NIVEL


## Ataque a mais pelo nível.
func bonus_ataque(personagem: String) -> int:
	return (nivel(personagem) - 1) / NIVEIS_POR_ATAQUE


## Apaga tudo (novo jogo, testes).
func limpar() -> void:
	_experiencia.clear()


func para_dados() -> Dictionary:
	return _experiencia.duplicate()


func de_dados(dados: Dictionary) -> void:
	_experiencia.clear()
	for personagem: Variant in dados:
		_experiencia[str(personagem)] = maxi(0, int(dados[personagem]))


func _definir(personagem: String, valor: int) -> void:
	var antes := nivel(personagem)
	_experiencia[personagem] = valor
	mudou.emit(personagem, valor)
	var depois := nivel(personagem)
	if depois > antes:
		subiu.emit(personagem, depois)
