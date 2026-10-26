class_name PlanaltoPorDoSol
extends RefCounted
## O planalto verde antes de Olympia, na fase "Antes que o sol beije o mar"
## (estrada Atenas–Olympia, V1 P1 c03: "o curto planalto verde, a única via de
## entrada da cidade"). A corrida, as barreiras e os atalhos são inferência.
##
## O desenho do planalto é o [constant MAPA]: uma linha por y e um caractere
## por x, nas casas do chão isométrico (x cresce para baixo e para a direita
## na tela, rumo ao mar). Nicholas sai de S e corre até o mirante (F).
##   .  grama          ,  capim alto (atrasa)      =  estrada de terra
##   ~  riacho         o  pedras no riacho          p  ponte
##   #  rocha (abriga do vento)                     m  mureta (só pulando)
##   w  pedra branca   s  trilha escondida entre as pedras brancas
##   x  mato da beira  b  beira de mármore          *  mar
##   S  saída          F  mirante
## Três barreiras cortam o caminho, cada uma com a passagem segura numa ponta
## (a estrada serpenteia até ela) e um atalho no meio:
##   1. rochas com mureta (x = 34): pular a mureta;
##   2. o riacho (x = 56..58): a ponte embaixo ou as pedras no meio;
##   3. rochas com mureta (x = 78): depois dela, o vento sopra do mar. Do alto
##      dessa mureta Nicholas vê a trilha entre as pedras brancas (o segredo).

const MAPA: Array[String] = [
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxb************",
	"x.......................................................~~~.................................................#..................................................b************",
	"x.......................................................~~~....................................................................................................b************",
	"x.........,...................=========.................~~~...................................................#.......................#........................b************",
	"x.....,,,,,,,,,..............===========......,.........~~~.........,.....=========..........#.,.......................#,......................................b************",
	"x....,,,,,,,,,,,.............=.........=..,,,,,,,,,.....~~~.....,,,,,,,,,===========.......,,,,,,,,,...#............,,,,,,,,,...............,..#...............b************",
	"x.....,,,,,,,,,.............==....#....==,,,,,,,,,,,....~~~....,,,,,,,,,==.........==.....,,,,,,,,,,,..............,,,,,,,,,,,..#.......,,,,,,,,,..............b************",
	"x.........,................==.....#.....==,,,,,,,,,.....~~~.....,,,,,,,==.....#.....==.....,,,,,,,,,................,,,,,,,,,..........,,,,,,,,,,,.............b************",
	"x.......................,..=......#......=....,.........~~~.........,.==......#......=#........,....................#...,...............,,,,,,,,,........FFFFFFb************",
	"x.....................,,,,==......m......==.............~~~..........==.......#......==.........#...........................................#............FFFFFFb************",
	"x....................,,,,==,......m.....,.==............~~~.........==........m.......==...........................................#.....................FFFFFFb************",
	"x.....................,,,=,.......m...,,,,,=............ooo........==.........m........===================#==============================================FFFFFFb************",
	"x.S=======================........m.....,..==...........~~~.......==..........m.........==================================#=======================#======FFFFFFb************",
	"x.=======================.........m.....,,,,==,,,.......~~~......==...,.......m...........#........,,,,,,,,,,,..............,,,,,,,,,....................FFFFFFb************",
	"x.................................m....,,,,,,==,,,......~~~.....==.,,,,,,,....m.....................,,,,,,,,,....#...........,,,,,,,.....#...............FFFFFFb************",
	"x.................................m...,,,,,,,,==,,,.....~~~.....=.,,,,,,,,,...m.....................#...,.......................,........................FFFFFFb************",
	"x.............,...................m....,,,,,,,,==,......~~~....==,,,,,,,,,,,..m.............#................................#.................................b************",
	"x........,,,,,,,,,,,..............#.....,,,,,,,,==......~~~...==..,,,,,,,,,...m................................................................................b************",
	"x.......,,,,,,,,,,,,,.............#.........,....==.....~~~...=....,,,,,,,....m.wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww.............b************",
	"x........,,,,,,,,,,,..............#...............==....ppp..==.......,.......m.ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss.............b************",
	"x.............,...................#................=====ppp===................m.ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss.............b************",
	"x.................................#.................====ppp==.................m.ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss.............b************",
	"x.................................#.....................ppp...................m.ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss.............b************",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxb************",
]

const ANDAVEIS := ".,=SFops"
## Pisos que já têm colisão no próprio chão.
const PISOS_BLOQUEADOS := "x~b*"
const CAPIM := ","
const TRILHA := "s"
const ROCHA := "#"
const PEDRA_BRANCA := "w"
const MURETA := "m"
const MIRANTE := "F"
const SAIDA := "S"

## A partir desta coluna, o vento sopra do mar (depois da terceira barreira).
const COLUNA_VENTO := 79
## Coluna da mureta de onde se vê a trilha das pedras brancas.
const COLUNA_MURETA_DA_TRILHA := 78
## Quantas casas atrás de uma pedra (do lado da terra) o vento não alcança.
const ALCANCE_ABRIGO := 3
## O capim alto (e a trilha, enquanto escondida no capim) deixa mais lento.
const FATOR_CAPIM := 0.6
## Força média do vento, em pixels da arte por segundo, e o período das rajadas.
const VENTO_MEDIO := 60.0
const PERIODO_RAJADA := 4.0
const VARIACAO_RAJADA := 0.6
## Rumo na tela de uma casa para a próxima em x (rumo ao mar): o piso é 64×32.
const RUMO_DO_MAR := Vector2(32, 16)
## Na tela, a subida e a descida valem menos (PersonagemExploracao.fator_vertical).
const FATOR_VERTICAL := 0.7


static func largura() -> int:
	return MAPA[0].length()


static func altura() -> int:
	return MAPA.size()


static func dentro(celula: Vector2i) -> bool:
	return celula.x >= 0 and celula.y >= 0 and celula.x < largura() and celula.y < altura()


## O caractere da casa; fora do planalto, mato (ou mar, depois da beira).
static func simbolo(celula: Vector2i) -> String:
	if dentro(celula):
		return MAPA[celula.y][celula.x]
	return "*" if celula.x >= largura() else "x"


static func andavel(celula: Vector2i) -> bool:
	return ANDAVEIS.contains(simbolo(celula)) or simbolo(celula) == TRILHA


static func celula_de_saida() -> Vector2i:
	for y in altura():
		var x := MAPA[y].find(SAIDA)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i.ZERO


static func no_mirante(celula: Vector2i) -> bool:
	return simbolo(celula) == MIRANTE


## Todas as casas com este caractere.
static func celulas(caractere: String) -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for y in altura():
		for x in largura():
			if MAPA[y][x] == caractere:
				lista.append(Vector2i(x, y))
	return lista


## Quanto da velocidade sobra nesta casa (o capim alto atrasa; a trilha,
## enquanto ninguém a viu, é capim como o resto).
static func fator_terreno(celula: Vector2i, trilha_revelada: bool) -> float:
	var s := simbolo(celula)
	if s == CAPIM or (s == TRILHA and not trilha_revelada):
		return FATOR_CAPIM
	return 1.0


## Atrás de uma rocha ou pedra branca (o vento vem do mar, de x maior), na
## trilha entre as pedras brancas ou no mirante, o vento não alcança.
static func abrigada(celula: Vector2i) -> bool:
	var s := simbolo(celula)
	if s == TRILHA or s == MIRANTE:
		return true
	for passo in range(1, ALCANCE_ABRIGO + 1):
		var adiante := simbolo(celula + Vector2i(passo, 0))
		if adiante == ROCHA or adiante == PEDRA_BRANCA:
			return true
	return false


## Casa onde o vento empurra Nicholas.
static func com_vento(celula: Vector2i) -> bool:
	return celula.x >= COLUNA_VENTO and not abrigada(celula)


## Casas abrigadas por uma rocha no trecho de vento (as sombras desenhadas).
static func sombras() -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for rocha in celulas(ROCHA):
		if rocha.x < COLUNA_VENTO:
			continue
		for passo in range(1, ALCANCE_ABRIGO + 1):
			var celula := rocha - Vector2i(passo, 0)
			if celula.x >= COLUNA_VENTO and andavel(celula) and not lista.has(celula):
				lista.append(celula)
	return lista


## Força do vento (pixels da arte por segundo) no instante [param t]: rajadas
## que sobem e descem em volta de [constant VENTO_MEDIO].
static func forca_vento(t: float) -> float:
	return VENTO_MEDIO * (1.0 + VARIACAO_RAJADA * sin(TAU * t / PERIODO_RAJADA))


## O vento na tela, soprando do mar (contra o caminho do mirante).
static func vento(t: float) -> Vector2:
	return -RUMO_DO_MAR.normalized() * forca_vento(t)


## Quantos segundos leva o melhor caminho de S ao mirante andando a
## [param rapidez] (pixels da arte por segundo), passando só pelos caracteres
## em [param permitidos], com um vento constante de [param forca_do_vento].
## Serve para conferir o desenho da fase (testes): o caminho seguro e os
## atalhos contra a duração do pôr do sol. -1 se não houver caminho.
static func tempo_ate_o_mirante(rapidez: float, permitidos: String, forca_do_vento: float,
		trilha_revelada := true) -> float:
	var inicio := celula_de_saida()
	var custos := {inicio: 0.0}
	var fila := [[0.0, inicio]]
	while not fila.is_empty():
		var atual: Array = _tirar_menor(fila)
		var tempo: float = atual[0]
		var celula: Vector2i = atual[1]
		if no_mirante(celula):
			return tempo
		if tempo > custos[celula]:
			continue
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var vizinha := celula + Vector2i(dx, dy)
				if not permitidos.contains(simbolo(vizinha)):
					continue
				if dx != 0 and dy != 0 and (not permitidos.contains(simbolo(celula + Vector2i(dx, 0)))
						or not permitidos.contains(simbolo(celula + Vector2i(0, dy)))):
					continue
				var novo := tempo + _tempo_do_passo(Vector2i(dx, dy), vizinha, rapidez,
					forca_do_vento, trilha_revelada)
				if novo < custos.get(vizinha, INF):
					custos[vizinha] = novo
					_por(fila, [novo, vizinha])
	return -1.0


static func _tempo_do_passo(passo: Vector2i, destino: Vector2i, rapidez: float,
		forca_do_vento: float, trilha_revelada: bool) -> float:
	var na_tela := Vector2((passo.x - passo.y) * 32, (passo.x + passo.y) * 16)
	var rumo := Vector2(na_tela.x, na_tela.y / FATOR_VERTICAL).normalized()
	var veloz := rapidez * Vector2(rumo.x, rumo.y * FATOR_VERTICAL).length()
	if forca_do_vento > 0.0 and com_vento(destino):
		veloz += na_tela.normalized().dot(-RUMO_DO_MAR.normalized()) * forca_do_vento
	veloz *= fator_terreno(destino, trilha_revelada)
	return na_tela.length() / maxf(veloz, 10.0)


# Fila de prioridade simples (heap binário em Array) para o caminho mais curto.
static func _por(fila: Array, item: Array) -> void:
	fila.append(item)
	var i := fila.size() - 1
	while i > 0:
		var pai := (i - 1) >> 1
		if fila[pai][0] <= fila[i][0]:
			break
		var troca: Array = fila[pai]
		fila[pai] = fila[i]
		fila[i] = troca
		i = pai


static func _tirar_menor(fila: Array) -> Array:
	var menor: Array = fila[0]
	var ultimo: Array = fila.pop_back()
	if fila.is_empty():
		return menor
	fila[0] = ultimo
	var i := 0
	while true:
		var esq := 2 * i + 1
		var dir := esq + 1
		var m := i
		if esq < fila.size() and fila[esq][0] < fila[m][0]:
			m = esq
		if dir < fila.size() and fila[dir][0] < fila[m][0]:
			m = dir
		if m == i:
			break
		var troca: Array = fila[m]
		fila[m] = fila[i]
		fila[i] = troca
		i = m
	return menor
