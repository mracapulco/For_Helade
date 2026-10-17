extends Node
## Nível dos personagens (autoload "Experiencia").
## O nível vem de dois lugares:
## - da história: um marco do livro garante um nível mínimo
##   ([method garantir_nivel]), para a força acompanhar o livro sem lutar;
## - das lutas: cada inimigo derrotado dá experiência ([method ganhar]),
##   para quem quiser ficar um pouco mais forte, até
##   [constant NIVEIS_ACIMA_DA_HISTORIA] níveis acima do nível da história.
## Os marcos do livro ficam em [constant ARQUIVO_MARCOS] (um por capítulo,
## com o nível e, quando muda, a fase da vida); o capítulo chama
## [method concluir_marco] ao terminar.
## Cada nível acima do 1 soma vida máxima e ataque ([constant VIDA_POR_NIVEL],
## [constant NIVEIS_POR_ATAQUE]), por cima do corpo da idade (FaseDaVida).
## No roteiro:
##   $> Experiencia.concluir_marco("v1_p2_c02")
## Valores provisórios, para ajustar testando.

## Ganhou experiência (total agora).
signal mudou(personagem: String, experiencia: int)
## Subiu de nível (pela luta ou pela história).
signal subiu(personagem: String, nivel: int)
## Chegou ao máximo que as lutas dão antes do próximo marco da história.
signal limite_das_lutas(personagem: String, nivel: int)

const NIVEL_MAXIMO := 30
## Vida máxima a mais por nível acima do 1.
const VIDA_POR_NIVEL := 3
## A cada quantos níveis o ataque sobe 1.
const NIVEIS_POR_ATAQUE := 2
## Experiência para ir do nível 1 ao 2. Cada nível seguinte pede
## esse tanto a mais que o anterior (20, 40, 60...).
const PASSO_EXPERIENCIA := 20
## Quantos níveis as lutas podem dar acima do nível garantido pela história.
const NIVEIS_ACIMA_DA_HISTORIA := 3
## Marcos do livro: [id] com nivel = N e, se a idade muda, faixa = "ADULTO".
const ARQUIVO_MARCOS := "res://data/marcos_historia.cfg"

## personagem -> experiência total
var _experiencia: Dictionary[String, int] = {}
## personagem -> nível garantido pela história (1 se nenhum marco ainda)
var _nivel_historia: Dictionary[String, int] = {}
var _marcos := ConfigFile.new()


func _init() -> void:
	_marcos.load(ARQUIVO_MARCOS)


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


## Nível garantido pela história até agora.
func nivel_da_historia(personagem: String) -> int:
	return _nivel_historia.get(personagem, 1)


## Nível mais alto que as lutas dão agora (até o próximo marco).
func nivel_limite(personagem: String) -> int:
	return mini(NIVEL_MAXIMO, nivel_da_historia(personagem) + NIVEIS_ACIMA_DA_HISTORIA)


## Soma [param valor] de experiência (inimigo derrotado), sem passar do
## [method nivel_limite]: no limite, a barra para logo antes do próximo nível.
func ganhar(personagem: String, valor: int) -> void:
	if valor <= 0:
		return
	var atual := experiencia(personagem)
	var limite := nivel_limite(personagem)
	var teto := experiencia_para(limite + 1) - 1 if limite < NIVEL_MAXIMO else 1 << 30
	if atual >= teto:
		return
	_definir(personagem, mini(atual + valor, teto))
	if atual + valor >= teto:
		limite_das_lutas.emit(personagem, limite)


## Marco da história: garante pelo menos esse nível e abre espaço para as
## lutas irem além. Quem já passou dele pelas lutas não perde nada.
func garantir_nivel(personagem: String, minimo: int) -> void:
	minimo = clampi(minimo, 1, NIVEL_MAXIMO)
	_nivel_historia[personagem] = maxi(nivel_da_historia(personagem), minimo)
	var alvo := experiencia_para(minimo)
	if experiencia(personagem) < alvo:
		_definir(personagem, alvo)


func tem_marco(id: String) -> bool:
	return _marcos.has_section(id)


## O capítulo [param id] terminou: aplica o marco dele (nível e, se tiver,
## a nova fase da vida). Sem marco com esse id, não faz nada.
func concluir_marco(id: String, personagem := "nicholas") -> void:
	if not tem_marco(id):
		return
	var faixa := str(_marcos.get_value(id, "faixa", ""))
	if Inventario.FaixaEtaria.has(faixa):
		Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria[faixa])
	garantir_nivel(personagem, int(_marcos.get_value(id, "nivel", 1)))


## Vida máxima a mais pelo nível.
func bonus_vida(personagem: String) -> int:
	return (nivel(personagem) - 1) * VIDA_POR_NIVEL


## Ataque a mais pelo nível.
func bonus_ataque(personagem: String) -> int:
	return (nivel(personagem) - 1) / NIVEIS_POR_ATAQUE


## Apaga tudo (novo jogo, testes).
func limpar() -> void:
	_experiencia.clear()
	_nivel_historia.clear()


func para_dados() -> Dictionary:
	return { "experiencia": _experiencia.duplicate(), "historia": _nivel_historia.duplicate() }


func de_dados(dados: Dictionary) -> void:
	limpar()
	var experiencia_dados: Variant = dados.get("experiencia", {})
	if experiencia_dados is Dictionary:
		for personagem: Variant in experiencia_dados:
			_experiencia[str(personagem)] = maxi(0, int(experiencia_dados[personagem]))
	var historia_dados: Variant = dados.get("historia", {})
	if historia_dados is Dictionary:
		for personagem: Variant in historia_dados:
			_nivel_historia[str(personagem)] = clampi(int(historia_dados[personagem]), 1, NIVEL_MAXIMO)


func _definir(personagem: String, valor: int) -> void:
	var antes := nivel(personagem)
	_experiencia[personagem] = valor
	mudou.emit(personagem, valor)
	var depois := nivel(personagem)
	if depois > antes:
		subiu.emit(personagem, depois)
