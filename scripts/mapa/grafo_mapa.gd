class_name GrafoMapa
extends RefCounted
## Locais do mapa e suas ligações, sem nada de tela: quem é vizinho de quem,
## o caminho entre dois locais e o vizinho numa direção (setas do teclado).

const PASTA_LOCAIS := "res://data/mapa/"

var locais: Dictionary[String, LocalMapa] = {}
## id -> { id do vizinho -> true se a ligação é por mar }
var _ligacoes: Dictionary[String, Dictionary] = {}


## Lê todos os .tres de res://data/mapa/.
static func da_pasta(pasta := PASTA_LOCAIS) -> GrafoMapa:
	var grafo := GrafoMapa.new()
	for arquivo: String in ResourceLoader.list_directory(pasta):
		if arquivo.ends_with(".tres"):
			var local := load(pasta + arquivo) as LocalMapa
			if local:
				grafo.adicionar(local)
	return grafo


func adicionar(local: LocalMapa) -> void:
	locais[local.id] = local
	if not _ligacoes.has(local.id):
		_ligacoes[local.id] = {}
	for outro in local.vizinhos:
		_ligar(local.id, outro, false)
	for outro in local.vizinhos_por_mar:
		_ligar(local.id, outro, true)


func local(id: String) -> LocalMapa:
	return locais.get(id, null)


## Vizinhos de um local, em ordem alfabética.
func vizinhos(id: String) -> Array[String]:
	var lista: Array[String] = []
	lista.assign(_ligacoes.get(id, {}).keys())
	lista.sort()
	return lista


func por_mar(a: String, b: String) -> bool:
	return _ligacoes.get(a, {}).get(b, false)


## Pares ligados, cada um uma vez: [[a, b, por_mar], ...]. Para desenhar.
func ligacoes() -> Array:
	var pares := []
	for a: String in _ligacoes:
		for b: String in _ligacoes[a]:
			if a < b:
				pares.append([a, b, _ligacoes[a][b]])
	return pares


## Caminho mais curto (em distância no mapa) de [param origem] a
## [param destino], passando só por locais liberados. Inclui os dois extremos;
## vazio se não houver caminho.
func caminho(origem: String, destino: String, liberados: Dictionary) -> Array[String]:
	var vazio: Array[String] = []
	if not liberados.has(origem) or not liberados.has(destino):
		return vazio
	var distancia := {origem: 0.0}
	var veio_de := {origem: ""}
	var abertos: Array[String] = [origem]
	while not abertos.is_empty():
		var atual: String = abertos[0]
		for candidato in abertos:
			if distancia[candidato] < distancia[atual]:
				atual = candidato
		abertos.erase(atual)
		if atual == destino:
			break
		for proximo in vizinhos(atual):
			if not liberados.has(proximo):
				continue
			var nova: float = distancia[atual] + local(atual).posicao.distance_to(local(proximo).posicao)
			if nova < distancia.get(proximo, INF):
				distancia[proximo] = nova
				veio_de[proximo] = atual
				if not abertos.has(proximo):
					abertos.append(proximo)
	if not veio_de.has(destino):
		return vazio
	var volta: Array[String] = []
	var passo := destino
	while passo != "":
		volta.push_front(passo)
		passo = veio_de[passo]
	return volta


## Vizinho liberado que fica mais na [param direcao] (na tela), ou "" se
## nenhum estiver a menos de 60° dela.
func vizinho_na_direcao(id: String, direcao: Vector2, liberados: Dictionary) -> String:
	var origem := local(id)
	if origem == null or direcao == Vector2.ZERO:
		return ""
	var melhor := ""
	var melhor_alinhamento := 0.5 # cos(60°)
	for outro in vizinhos(id):
		if not liberados.has(outro):
			continue
		var rumo := (local(outro).posicao - origem.posicao).normalized()
		var alinhamento := rumo.dot(direcao.normalized())
		if alinhamento > melhor_alinhamento:
			melhor_alinhamento = alinhamento
			melhor = outro
	return melhor


func _ligar(a: String, b: String, mar: bool) -> void:
	if not _ligacoes.has(a):
		_ligacoes[a] = {}
	if not _ligacoes.has(b):
		_ligacoes[b] = {}
	_ligacoes[a][b] = mar
	_ligacoes[b][a] = mar
