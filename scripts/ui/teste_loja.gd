extends Node
## Cena de teste da tela da loja (rodar com F6). A própria tela_loja.tscn,
## rodada sozinha, faz o mesmo; esta cena fica para quando ela é parte de outra.

func _ready() -> void:
	var tela: TelaLoja = $TelaLoja
	Inventario.limpar()
	Lojas.limpar()
	Inventario.mudar_faixa_etaria(Inventario.FaixaEtaria.ADULTO)
	Inventario.ganhar_dinheiro(60)
	Inventario.adicionar("espada_media")
	Inventario.equipar(tela.personagem, "espada_media")
	Inventario.adicionar("punhal")
	Inventario.adicionar("pocao_vigor", 2)
	Inventario.adicionar("carta_teste")
	tela.fechada.connect(get_tree().quit)
	tela.abrir("chymeia")
