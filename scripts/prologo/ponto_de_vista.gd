class_name PontoDeVista
extends Marker3D
## Lugar onde a câmera de Nicholas pode parar, na altura dos olhos de uma criança.
## A posição e a rotação deste nó são exatamente as da câmera quando ela chega aqui.
## Os AlvoToque filhos são os lugares para onde dá para ir a partir deste ponto.

## Trecho do roteiro (título no .dialogue) mostrado na primeira vez que
## Nicholas chega aqui. Vazio: nenhum texto.
@export var cena_ao_chegar := ""
## Distância, no chão, em que Nicholas conta como tendo chegado aqui andando.
## 0: usa a do ControlePrimeiraPessoa. Maior serve para chegar já ao passar
## por uma porta (a varanda, por exemplo).
@export var raio_chegada := 0.0


func alvos() -> Array[AlvoToque]:
	var lista: Array[AlvoToque] = []
	for filho in get_children():
		if filho is AlvoToque:
			lista.append(filho)
	return lista
