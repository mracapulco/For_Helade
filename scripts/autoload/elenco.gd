extends Node
## Lista dos personagens com dados de retrato (autoload "Elenco").
## Para adicionar alguém: crie o .tres em res://data/personagens/ e
## coloque-o na lista abaixo.

var personagens: Array[Personagem] = [
	preload("res://data/personagens/nicholas.tres"),
	preload("res://data/personagens/janet.tres"),
	# Capítulo 01: Althea e Pany (governanta da mansão em Atenas).
	preload("res://data/personagens/althea.tres"),
	preload("res://data/personagens/pany.tres"),
	# Capítulo 01, passo 2: o duque Apollon (aparência provisória).
	preload("res://data/personagens/apollon.tres"),
	# Provisório: só para a sala de teste da exploração.
	preload("res://data/personagens/personagem_teste.tres"),
	# Figurantes genéricos dos acampamentos (não são personagens do livro).
	preload("res://data/personagens/mercador.tres"),
	preload("res://data/personagens/viajante.tres"),
]


## Personagem pelo nome usado no roteiro, ou null se não estiver no elenco.
func buscar(nome_no_roteiro: String) -> Personagem:
	for personagem: Personagem in personagens:
		if personagem.nome_no_roteiro == nome_no_roteiro:
			return personagem
	return null
