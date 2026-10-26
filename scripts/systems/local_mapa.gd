class_name LocalMapa
extends Resource
## Um ponto do mapa de Hélade. Cada local é um .tres em res://data/mapa/,
## e o nome do arquivo deve ser igual ao [member id].
## As ligações valem para os dois lados: basta listar uma vez.
## Cada local tem no máximo uma ligação por direção (norte, sul, leste, oeste),
## para as setas do controle levarem sempre a um caminho só.

enum Tipo {
	REGIAO, ## Lugar grande com cena própria (Olympia, Atenas...).
	ESTRADA, ## Etapa de viagem entre regiões.
	ACAMPAMENTO, ## Parada para a noite numa viagem longa.
	PORTO, ## Onde se pega barco.
	MAR, ## Ponto de passagem no mar, numa rota de barco.
}

@export var id: String = ""
@export var tipo := Tipo.REGIAO

## Chaves de tradução do nome e da linha de baixo da placa (i18n/strings.csv).
@export var chave_nome: String = ""
@export var chave_regiao: String = ""

## Posição no desenho do mapa, em pixels da arte.
@export var posicao: Vector2 = Vector2.ZERO

## Locais ligados por estrada.
@export var vizinhos: Array[String] = []
## Locais ligados por mar (barco).
@export var vizinhos_por_mar: Array[String] = []

## Cena carregada ao entrar. Vazio = ainda não existe.
@export_file("*.tscn") var cena: String = ""
## Missão da história que acontece aqui (a pousada do Cap. 2). Quando há, entrar
## pergunta: descansar (abre [member cena]) ou fazer a missão.
@export_file("*.tscn") var cena_missao: String = ""
## Desenhado como prédio no mapa, e não como tenda (gerar_mapa.py lê isto).
@export var construcao := false

## Já descoberto num jogo novo. Os outros aparecem quando Nicholas chega a
## um vizinho (como no mapa do Super Mario World). Provisório: a ordem real
## vem do mapa de capítulos.
@export var liberado_no_inicio := false
