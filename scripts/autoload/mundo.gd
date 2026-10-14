extends Node
## Estado do mundo fora das cenas (autoload "Mundo"): se é dia ou noite e
## quais lugares do mapa de Hélade já foram descobertos.
## No roteiro:
##   $> Mundo.definir_noite(true)
##   $> Mundo.descobrir("atenas")

signal periodo_mudou(noite: bool)
signal descoberto(id: String)

var noite := false
## Lugares do mapa já descobertos (id -> true). O mapa usa este mesmo
## dicionário como lista de lugares liberados.
var descobertos: Dictionary = {}
## Onde Nicholas está no mapa; vazio = ainda não entrou no mapa.
var local_no_mapa := ""


func definir_noite(valor: bool) -> void:
	if valor == noite:
		return
	noite = valor
	periodo_mudou.emit(noite)


func alternar_periodo() -> void:
	definir_noite(not noite)


## Devolve true se o lugar ainda não era conhecido.
func descobrir(id: String) -> bool:
	if descobertos.has(id):
		return false
	descobertos[id] = true
	descoberto.emit(id)
	return true


func foi_descoberto(id: String) -> bool:
	return descobertos.has(id)


func limpar() -> void:
	noite = false
	descobertos.clear()
	local_no_mapa = ""


func para_dados() -> Dictionary:
	return {"noite": noite, "descobertos": descobertos.keys(), "local_no_mapa": local_no_mapa}


func de_dados(dados: Dictionary) -> void:
	limpar()
	noite = dados.get("noite", false)
	for id: String in dados.get("descobertos", []):
		descobertos[id] = true
	local_no_mapa = dados.get("local_no_mapa", "")
