class_name Balanceamento
extends RefCounted
## Regras de balanceamento dos itens e as contas do combate.
##
## Cada item tem um orçamento de pontos, que depende do nível e do encaixe,
## e gasta esses pontos em bônus de ataque, defesa e velocidade (e alcance,
## no arco). Assim nenhum item é melhor em tudo: quem bate forte é lento,
## quem é rápido protege pouco. Um item está equilibrado quando gasta o
## orçamento inteiro (com uma pequena folga).
##
##   orçamento = PONTOS_POR_NIVEL × (1 + nível) × peso do encaixe
##   pontos    = ataque × CUSTO_ATAQUE + defesa × CUSTO_DEFESA
##             + velocidade × CUSTO_VELOCIDADE + alcance extra × CUSTO_ALCANCE
##
## Velocidade negativa devolve pontos: a armadura pesada protege muito
## porque deixa o personagem lento.
## Arma de duas mãos pesa o mesmo que arma de uma mão + escudo, então
## trocar uma coisa pela outra é uma escolha, não uma vantagem.

## Metade dos pontos de um item comum (nível 1) de peso 1.
const PONTOS_POR_NIVEL := 5.0

## Quanto cada encaixe pesa no orçamento.
const PESO_ENCAIXE := {
	Item.Encaixe.ARMA: 1.0,
	Item.Encaixe.ESCUDO: 0.6,
	Item.Encaixe.ARMADURA: 1.0,
	Item.Encaixe.ELMO: 0.4,
	Item.Encaixe.ACESSORIO: 0.4,
}
## Peso da arma de duas mãos: arma (1,0) + escudo (0,6).
const PESO_DUAS_MAOS := 1.6

const CUSTO_ATAQUE := 1.0
const CUSTO_DEFESA := 1.0
## Por ponto de porcentagem: 5% de velocidade custam 1 ponto.
const CUSTO_VELOCIDADE := 0.2
## Por pixel de alcance acima de [constant ALCANCE_PADRAO]: 48 px custam 1 ponto.
const CUSTO_ALCANCE := 1.0 / 48.0
## Alcance de quem golpeia de perto (a casa da frente).
const ALCANCE_PADRAO := 40.0
## Diferença aceita entre o orçamento e os pontos gastos.
const FOLGA := 0.5

## Ataque de quem está sem arma (inimigos). O do Nicholas vem da fase da
## vida (FaseDaVida). Somado ao da arma.
const ATAQUE_BASE := 3
## Limites da velocidade somada de todo o equipamento.
const VELOCIDADE_MINIMA := -40
const VELOCIDADE_MAXIMA := 40


## Pontos que o item pode gastar em bônus.
static func orcamento(item: Item) -> float:
	if item == null or not item.pode_equipar():
		return 0.0
	var peso: float = PESO_DUAS_MAOS if item.duas_maos() else PESO_ENCAIXE.get(item.encaixe, 0.0)
	return PONTOS_POR_NIVEL * (1 + item.nivel) * peso


## Pontos que os bônus do item gastam.
static func pontos(item: Item) -> float:
	if item == null:
		return 0.0
	var alcance_extra := maxf(0.0, item.alcance - ALCANCE_PADRAO) if item.alcance > 0.0 else 0.0
	return (item.ataque * CUSTO_ATAQUE + item.defesa * CUSTO_DEFESA
		+ item.velocidade * CUSTO_VELOCIDADE + alcance_extra * CUSTO_ALCANCE)


## Quanto do orçamento sobra (positivo) ou passa (negativo).
static func sobra(item: Item) -> float:
	return orcamento(item) - pontos(item)


static func equilibrado(item: Item) -> bool:
	return absf(sobra(item)) <= FOLGA


## Soma os bônus de vários itens: { "ataque", "defesa", "velocidade" }.
## A velocidade fica entre [constant VELOCIDADE_MINIMA] e
## [constant VELOCIDADE_MAXIMA]; o ataque já inclui o [param ataque_base]
## (o de quem está sem arma) e a velocidade, a [param velocidade_base]
## (a da fase da vida, por exemplo).
static func somar(itens: Array[Item], ataque_base := ATAQUE_BASE, velocidade_base := 0) -> Dictionary:
	var ataque := ataque_base
	var defesa := 0
	var velocidade := velocidade_base
	for item in itens:
		if item == null:
			continue
		ataque += item.ataque
		defesa += item.defesa
		velocidade += item.velocidade
	return {
		"ataque": ataque,
		"defesa": defesa,
		"velocidade": clampi(velocidade, VELOCIDADE_MINIMA, VELOCIDADE_MAXIMA),
	}


## Dano de um golpe. A defesa reduz o dano aos poucos, sem nunca zerar:
## defesa 10 corta o dano pela metade, defesa 30 deixa um quarto.
static func dano(ataque: int, defesa: int) -> int:
	if ataque <= 0:
		return 0
	return maxi(1, roundi(ataque * 10.0 / (10.0 + maxi(0, defesa))))


## Multiplicador do tempo de andar e de golpear: +20 → 1,2 (mais rápido).
static func multiplicador_velocidade(velocidade: int) -> float:
	return 1.0 + clampi(velocidade, VELOCIDADE_MINIMA, VELOCIDADE_MAXIMA) / 100.0
