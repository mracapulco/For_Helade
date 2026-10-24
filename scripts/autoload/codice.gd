extends Node
## O que Nicholas já notou e aprendeu (autoload "Codice"). Dois tipos de
## entrada: "olhar" (o olhar de Nicholas, coisas que ele encontra ou percebe
## nos lugares) e "codice" (a enciclopédia de Hélade: lugares, casas,
## pessoas). Os textos ficam em i18n/strings.csv:
## CODICE_<ID>_TITULO e CODICE_<ID>_TEXTO (id em maiúsculas).
## No roteiro:
##   $> Codice.anotar("atenas")

signal anotado(id: String)
## Uma entrada foi lida na tela do Códice.
signal lido(id: String)

const TIPO_OLHAR := "olhar"
const TIPO_CODICE := "codice"

## Todas as entradas que existem (id -> tipo).
const ENTRADAS := {
	# Capítulo 01, a manhã do aniversário.
	"roupas_simples": TIPO_OLHAR,
	"faixa_dourada": TIPO_OLHAR,
	"monstro_marinho": TIPO_OLHAR,
	"presentes": TIPO_OLHAR,
	# Capítulo 01, a carruagem.
	"imperatriz_callie": TIPO_CODICE,
	"atenas": TIPO_CODICE,
	"palacio_imperial": TIPO_CODICE,
	# Capítulo 01, cenas 7 a 10: o Palácio, a Rua das Butiques.
	"poucos_guardas": TIPO_OLHAR,
	"olhos_de_ophelia": TIPO_OLHAR,
	"anexo_vazio": TIPO_OLHAR,
	"rua_das_butiques": TIPO_CODICE,
	# Capítulo 01, cena 11: o passeio (livraria; texto do pré-textual do V1).
	"ano_dourado": TIPO_CODICE,
	# Biblioteca do Castelo Olympia (sala de desafio, P5; V1 P1 c05).
	"pilhas_de_livros": TIPO_OLHAR,
	"mesa_de_xadrez": TIPO_OLHAR,
}

## Ids já anotados, na ordem em que foram anotados.
var anotados: Array[String] = []
## Ids já abertos na tela do Códice (os outros aparecem como novos).
var lidos: Array[String] = []


## Anota a entrada. Devolve true se ela ainda não estava anotada.
func anotar(id: String) -> bool:
	if not ENTRADAS.has(id):
		push_warning("Códice: entrada desconhecida \"%s\"" % id)
		return false
	if anotados.has(id):
		return false
	anotados.append(id)
	anotado.emit(id)
	return true


func tem(id: String) -> bool:
	return anotados.has(id)


## Anotada e ainda não aberta na tela do Códice.
func novo(id: String) -> bool:
	return anotados.has(id) and not lidos.has(id)


## Alguma entrada anotada ainda não foi lida (de um tipo, ou de qualquer um).
func tem_novidade(tipo_da_entrada := "") -> bool:
	for id in anotados:
		if novo(id) and (tipo_da_entrada.is_empty() or ENTRADAS[id] == tipo_da_entrada):
			return true
	return false


## A entrada foi aberta na tela do Códice.
func marcar_lido(id: String) -> void:
	if novo(id):
		lidos.append(id)
		lido.emit(id)


## Ids anotados de um tipo ("olhar" ou "codice"), na ordem em que foram anotados.
func ids(tipo: String) -> Array[String]:
	var lista: Array[String] = []
	for id in anotados:
		if ENTRADAS[id] == tipo:
			lista.append(id)
	return lista


func tipo(id: String) -> String:
	return ENTRADAS.get(id, "")


func titulo(id: String) -> String:
	return tr("CODICE_%s_TITULO" % id.to_upper())


func texto(id: String) -> String:
	return tr("CODICE_%s_TEXTO" % id.to_upper())


func limpar() -> void:
	anotados.clear()
	lidos.clear()


func para_dados() -> Dictionary:
	return {"anotados": anotados.duplicate(), "lidos": lidos.duplicate()}


func de_dados(dados: Dictionary) -> void:
	limpar()
	for id: String in dados.get("anotados", []):
		if ENTRADAS.has(id) and not anotados.has(id):
			anotados.append(id)
	for id: String in dados.get("lidos", []):
		if anotados.has(id) and not lidos.has(id):
			lidos.append(id)
