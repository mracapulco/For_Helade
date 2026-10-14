class_name Item
extends Resource
## Dados de um item do inventário. Cada item é um .tres em
## res://data/itens/, e o nome do arquivo deve ser igual ao [member id].

enum Tipo { ARMA, EQUIPAMENTO, CONSUMIVEL, HISTORIA, DIVERSOS }
enum Encaixe { NENHUM, ARMA, ARMADURA, ACESSORIO }

## Id sem acento, igual ao nome do arquivo, por exemplo "pocao_teste".
@export var id: String = ""

## Chaves de tradução do nome e da descrição (i18n/strings.csv).
@export var chave_nome: String = ""
@export var chave_descricao: String = ""

## Ícone da bolsa. Sem arte, a interface mostra um quadro provisório.
@export var icone: Texture2D

## Aba da bolsa onde o item aparece.
@export var tipo: Tipo = Tipo.DIVERSOS

## Onde o item é equipado. NENHUM = não se equipa.
@export var encaixe: Encaixe = Encaixe.NENHUM

## Preço base em moedas, para lojas.
@export var preco: int = 0

## Efeitos simples. Dano vale para armas, defesa para armadura e
## acessório, cura para consumíveis.
@export var dano: int = 0
@export var defesa: int = 0
@export var cura: int = 0


## Itens da história não podem ser largados nem vendidos pelo jogador.
func e_da_historia() -> bool:
	return tipo == Tipo.HISTORIA


func pode_equipar() -> bool:
	return encaixe != Encaixe.NENHUM


func pode_usar() -> bool:
	return tipo == Tipo.CONSUMIVEL
