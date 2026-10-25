class_name SequenciaCenas01
extends RefCounted
## Ordem das cenas do Capítulo 01 depois da manhã (cenas 7 a 10 do plano) e
## qual cena jogável abre cada etapa. Cada cena termina na etapa seguinte e
## chama a próxima cena que existir; etapas sem cena ainda (a visão da
## carruagem, a volta à mansão) são puladas. Quando não há mais cena, volta ao menu.
## Para plugar a visão da carruagem, basta pôr o caminho da cena dela em
## [constant CENAS] com a chave "visao_carruagem".

const MENU := "res://scenes/main/main.tscn"

## Etapas na ordem em que acontecem.
const ETAPAS: Array[String] = ["palacio", "visao_carruagem", "butiques", "restaurante", "passeio", "volta"]

## Etapa -> cena jogável (as que ainda não existem não aparecem aqui).
const CENAS := {
	"palacio": "res://scenes/capitulo_01/cena_palacio.tscn",
	"visao_carruagem": "res://scenes/capitulo_01/cena_visao.tscn",
	"butiques": "res://scenes/capitulo_01/cena_butiques.tscn",
	"restaurante": "res://scenes/capitulo_01/cena_restaurante.tscn",
	"passeio": "res://scenes/capitulo_01/cena_passeio.tscn",
	"volta": "res://scenes/capitulo_01/cena_volta.tscn",
}


## Cena da etapa, ou vazio se ela ainda não tem cena.
static func cena_da_etapa(etapa: String) -> String:
	return CENAS.get(etapa, "")


## Etapa que vem depois de [param etapa] (vazio se for a última ou desconhecida).
static func proxima_etapa(etapa: String) -> String:
	var i := ETAPAS.find(etapa)
	if i < 0 or i + 1 >= ETAPAS.size():
		return ""
	return ETAPAS[i + 1]


## Cena que abre depois de [param etapa] terminar: a da primeira etapa
## seguinte que tiver cena, ou o menu.
static func cena_depois(etapa: String) -> String:
	var i := ETAPAS.find(etapa)
	if i >= 0:
		for j in range(i + 1, ETAPAS.size()):
			if CENAS.has(ETAPAS[j]):
				return CENAS[ETAPAS[j]]
	return MENU
