class_name LabirintoFloresta
extends RefCounted
## As regras da mata "Árvores e mais árvores" (estrada Atenas–Olympia,
## oa_estrada_2), sem nada de cena: em que clareira Nicholas está e aonde leva
## cada saída. Toda clareira parece igual (o livro: "árvores e mais árvores
## que forravam o caminho"); quem sai pelo lado errado volta ao mesmo lugar.
##
## O ritmo segue o design aprovado (brainstorm de 26/10):
## - Aprende (clareiras 0 e 1): só a saída certa toca a melodia, e as folhas
##   voam para ela.
## - Aprofunda (2 e 3): duas saídas têm som, uma é eco. As folhas ficam
##   indecisas; a marca riscada numa árvore desempata. O eco da clareira 3
##   leva à clareira escondida, com um baú (o segredo da fase).
## - Surpresa (4): as marcas eram dos bandidos. A clareira é uma emboscada e
##   as saídas só abrem depois da luta.
## - Fecha: derrotados os bandidos, a melodia leva para fora da mata.
## Tudo isso é inferência (não está no livro) e não muda a história.

enum Saida { NORDESTE, SUDESTE, SUDOESTE, NOROESTE }

## O que aconteceu ao sair por um lado ([method sair]).
enum Resultado {
	AVANCOU, ## Foi para a próxima clareira.
	VOLTOU, ## Lado errado: a mesma clareira de novo.
	SEGREDO, ## Seguiu o eco certo: a clareira escondida.
	EMBOSCADA, ## Chegou à clareira dos bandidos.
	FECHADA, ## Saída fechada (no meio da luta): nada acontece.
	SAIU, ## Saiu da mata: a fase acabou.
}

const NENHUMA := -1
## Índice da clareira escondida (fora da sequência).
const ESCONDIDA := 100

## Uma entrada por clareira da sequência. certa: a saída da melodia; eco: a
## saída com o eco (NENHUMA quando não há); eco_leva_ao_segredo: o eco desta
## clareira abre a clareira escondida em vez de voltar.
## A clareira de entrada nunca tem a saída certa do lado por onde se chega
## (o oposto da certa da anterior).
const CLAREIRAS: Array[Dictionary] = [
	{"certa": Saida.NORDESTE, "eco": NENHUMA, "eco_leva_ao_segredo": false},
	{"certa": Saida.NOROESTE, "eco": NENHUMA, "eco_leva_ao_segredo": false},
	{"certa": Saida.SUDOESTE, "eco": Saida.NORDESTE, "eco_leva_ao_segredo": false},
	{"certa": Saida.NOROESTE, "eco": Saida.SUDESTE, "eco_leva_ao_segredo": true},
	# A emboscada: a saída certa só toca depois da luta.
	{"certa": Saida.NORDESTE, "eco": NENHUMA, "eco_leva_ao_segredo": false},
]
## A clareira escondida tem uma saída só, que segue para a emboscada.
const SAIDA_DA_ESCONDIDA := Saida.NORDESTE

## Clareira atual (índice em [constant CLAREIRAS] ou [constant ESCONDIDA]).
var atual := 0
## Lado por onde Nicholas entrou na clareira atual (NENHUMA no começo).
var entrou_por := NENHUMA
## Os bandidos da emboscada já foram derrotados.
var bandidos_derrotados := false


static func oposta(saida: int) -> int:
	return (saida + 2) % 4


func indice_emboscada() -> int:
	return CLAREIRAS.size() - 1


func na_emboscada() -> bool:
	return atual == indice_emboscada()


func na_escondida() -> bool:
	return atual == ESCONDIDA


## Saída que toca a melodia aqui (NENHUMA na emboscada antes da luta).
func saida_certa() -> int:
	if na_escondida():
		return SAIDA_DA_ESCONDIDA
	if na_emboscada() and not bandidos_derrotados:
		return NENHUMA
	return CLAREIRAS[atual].certa


## Saída que toca o eco aqui (NENHUMA quando não há eco).
func saida_eco() -> int:
	if na_escondida():
		return NENHUMA
	return CLAREIRAS[atual].eco


## Tem marca riscada na árvore da saída certa (nas clareiras com eco e na
## emboscada, onde as marcas acabam).
func tem_marca() -> bool:
	return saida_eco() != NENHUMA or (na_emboscada() and bandidos_derrotados)


## Sai pelo lado [param saida] e devolve o que aconteceu ([enum Resultado]).
func sair(saida: int) -> Resultado:
	if na_emboscada() and not bandidos_derrotados:
		return Resultado.FECHADA
	if saida == saida_certa():
		if na_emboscada():
			return Resultado.SAIU
		_entrar(indice_emboscada() if na_escondida() else atual + 1, saida)
		return Resultado.EMBOSCADA if na_emboscada() else Resultado.AVANCOU
	if saida == saida_eco() and CLAREIRAS[atual].eco_leva_ao_segredo:
		_entrar(ESCONDIDA, saida)
		return Resultado.SEGREDO
	# Errou: a mesma clareira, entrando pelo lado oposto ao que saiu.
	entrou_por = oposta(saida)
	return Resultado.VOLTOU


func _entrar(clareira: int, saiu_por: int) -> void:
	atual = clareira
	entrou_por = oposta(saiu_por)
