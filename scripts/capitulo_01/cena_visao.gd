class_name CenaVisao
extends CenaCapitulo01
## Capítulo 01, cena 8: a visão da varanda na carruagem e o apelido "Lia"
## (livro, l. ~317-365). A visão em 3D é a [VisaoVaranda]; depois dela vem a
## conversa dos três. Textos: data/dialogos/capitulo_01/visao_carruagem.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/visao_carruagem.dialogue")


func _init() -> void:
	roteiro = ROTEIRO


func id_da_cena() -> String:
	return "visao_carruagem"


func comecar() -> void:
	_mudar("visao")
	await VisaoVaranda.tocar(self, escala_tempo)
	_mudar("apelido")
	await _clarear()
	await _falar("apelido")
	await terminar()
