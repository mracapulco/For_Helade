class_name FasesHistoria
extends RefCounted
## Onde cada parte da história acontece no mapa de Hélade.
##
## Enquanto o mapa não é livre, ao chegar nele o jogador fica parado no reino
## da fase em que está: Enter (ou o botão Entrar) abre a cidade e a fase começa.
## Etapas que não estão aqui deixam o mapa como antes (livre).
##
## O capítulo 1 se passa em Atenas, na Mansão Olympia (Parte I do livro).

const FASES := {
	"capitulo_1": {
		"local": "atenas",
		"cena": "res://scenes/capitulo_01/capitulo_01.tscn",
	},
}


## A fase da [param etapa] ({local, cena}), ou vazio se ela não tem fase no mapa.
static func da_etapa(etapa: String) -> Dictionary:
	return FASES.get(etapa, {})
