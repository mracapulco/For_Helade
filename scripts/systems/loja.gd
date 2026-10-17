class_name Loja
extends Resource
## Dados de um mercador: o que ele vende e quanto tem de cada coisa.
## Cada loja é um .tres em res://data/lojas/, e o nome do arquivo deve ser
## igual ao [member id]. O que já foi comprado e a renovação do estoque
## ficam no autoload [code]Lojas[/code].

## Id sem acento, igual ao nome do arquivo, por exemplo "chymeia".
@export var id: String = ""
## Chave de tradução do nome do mercador (título da tela da loja).
@export var chave_nome: String = ""
## Reino ou grupo do mercador. Serve, mais tarde, para o preço pela
## influência com a casa dele.
@export var origem: Item.Origem = Item.Origem.NENHUMA
## id do item -> estoque cheio (quanto tem depois de renovar).
@export var itens: Dictionary[String, int] = {}
