class_name BiomaAcampamento
extends Resource
## Como é um acampamento: piso, água, o que cerca a clareira e quem faz
## companhia. Cada acampamento é um .tres em res://data/acampamentos/, com o
## mesmo id do ponto no mapa de Hélade. A cena base
## (scenes/exploracao/acampamentos/acampamento_base.tscn) monta tudo a partir
## daqui; os nove acampamentos só escolhem o seu bioma.

## Lados do losango do chão, para a água (rio ou mar).
enum Lado {
	NORDESTE, ## Beira de cima à direita.
	SUDESTE, ## Beira de baixo à direita (onde fica a saída).
	SUDOESTE, ## Beira de baixo à esquerda.
	NOROESTE, ## Beira de cima à esquerda.
}

## Igual ao id do ponto no mapa (por exemplo "oa_acampamento").
@export var id := ""
## Chave de tradução do nome mostrado no alto da tela.
@export var chave_nome := ""

@export_group("Chão")
## Faixa de 8 pisos de 64×32: 0-2 chão, 3 clareira, 4 margem, 5-6 água
## (animação), 7 borda. Gerada por tools/arte/gerar_acampamento.py.
@export var pisos: Texture2D
## Lados que viram água. A saída vira um barco quando o lado SUDESTE é água.
@export var lados_agua: Array[Lado] = []
## Quantos pisos de água em cada lado com água (a margem vem logo depois).
@export_range(1, 4) var largura_agua := 2
## Cor por cima de tudo durante o dia (a noite usa [member cor_noite]).
@export var cor_dia := Color(1, 1, 1)
@export var cor_noite := Color(0.45, 0.5, 0.7)

@export_group("Cenário")
## Árvores, pedras e afins na borda (com colisão).
@export var obstaculos: Array[Texture2D] = []
## Chance (0 a 1) de cada piso da borda ganhar um obstáculo.
@export_range(0.0, 1.0) var densidade_borda := 0.55
## Detalhes no chão, sem colisão (tufos, neve, conchas...).
@export var enfeites: Array[Texture2D] = []
@export_range(0.0, 1.0) var densidade_enfeites := 0.18
## Detalhes só na beira da água (juncos, conchas).
@export var enfeites_margem: Array[Texture2D] = []
## Muda a arrumação dos enfeites sem mudar o resto.
@export var semente := 1
## Falésias ao longo da praia (só nos lados com água).
@export var falesias: Array[Texture2D] = []

@export_group("Clima e bichos")
## Quanta neve cai (0 = nenhuma, 1 = nevasca leve).
@export_range(0.0, 1.0) var neve := 0.0
## Mata fechada: insetos e pássaros de dia, vaga-lumes à noite.
@export var fauna_da_mata := false

@export_group("Companhia")
## Mercador do acampamento: faixa de 4 quadros de 32×48 (parado, respirando).
@export var mercador: Texture2D
## Loja do mercador (id em res://data/lojas/); vazio = ele não vende nada.
@export var loja := ""
## Animal ou viajante que fica perto da fogueira.
@export var companheiro: Texture2D
## Marcador (~ nome) em data/dialogos/acampamentos/acampamento.dialogue.
@export var marcador_companheiro := "viajante"
## Um viajante a mais, além do [member companheiro] (quando o companheiro é um
## animal e o lugar também tem gente de passagem). Vazio = não aparece.
@export var viajante: Texture2D
@export var marcador_viajante := "viajante"

@export_group("Construção")
## Prédio no lugar da barraca (a pousada da estrada Atenas–Olympia). Vazio =
## barraca. Interagir na porta abre os espaços para salvar, como na barraca.
@export var construcao: Texture2D


func tem_agua(lado: Lado) -> bool:
	return lados_agua.has(lado)
