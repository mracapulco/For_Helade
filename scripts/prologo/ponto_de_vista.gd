class_name PontoDeVista
extends Marker3D
## Lugar onde a câmera de Nicholas pode parar, na altura dos olhos de uma criança.
## A posição e a rotação deste nó são exatamente as da câmera quando ela chega aqui.
## Os AlvoToque filhos são os lugares para onde dá para ir a partir deste ponto.


func alvos() -> Array[AlvoToque]:
	var lista: Array[AlvoToque] = []
	for filho in get_children():
		if filho is AlvoToque:
			lista.append(filho)
	return lista
