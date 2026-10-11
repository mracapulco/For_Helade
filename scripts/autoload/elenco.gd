extends Node
## Lista dos personagens com dados de retrato (autoload "Elenco").
## Para adicionar alguém: crie o .tres em res://data/personagens/ e
## coloque-o na lista abaixo.

var personagens: Array[Personagem] = [
	preload("res://data/personagens/nicholas.tres"),
	preload("res://data/personagens/janet.tres"),
]


## Personagem pelo nome usado no roteiro, ou null se não estiver no elenco.
func buscar(nome_no_roteiro: String) -> Personagem:
	for personagem: Personagem in personagens:
		if personagem.nome_no_roteiro == nome_no_roteiro:
			return personagem
	return null
