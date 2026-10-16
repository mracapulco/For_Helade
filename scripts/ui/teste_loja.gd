extends Node
## Cena de teste da tela da loja (rodar com F6): abre a loja de Chymeía com
## moedas e alguns itens na bolsa. Não faz parte do jogo.

@export var id_loja := "chymeia"


func _ready() -> void:
	Inventario.limpar()
	Lojas.limpar()
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADULTO)
	Inventario.ganhar_dinheiro(60)
	Inventario.adicionar("espada_media")
	Inventario.equipar("nicholas", "espada_media")
	Inventario.adicionar("punhal")
	Inventario.adicionar("pocao_vigor", 2)
	Inventario.adicionar("carta_teste")
	var tela: TelaLoja = $TelaLoja
	tela.fechada.connect(get_tree().quit)
	tela.abrir(id_loja)
