class_name Personagem
extends Resource
## Dados de um personagem que fala no roteiro.

## Nome exatamente como aparece no roteiro, antes dos dois pontos.
@export var nome_no_roteiro: String = ""

## Retratos por expressão, por exemplo "neutro". A expressão vem da
## etiqueta [code][#retrato=...][/code] da fala.
@export var retratos: Dictionary[String, Texture2D] = {}

## Retratos falando, por expressão: uma faixa horizontal de quadros
## quadrados (a boca em posições diferentes). Enquanto o texto aparece, a
## caixa de diálogo alterna esses quadros; ao terminar, volta ao retrato
## parado da mesma expressão.
@export var retratos_fala: Dictionary[String, Texture2D] = {}

## Retrato em pixel art: a caixa mostra sem suavizar os pixels.
@export var pixel_art := false

## Cor do retrato provisório, usada enquanto não há arte.
@export var cor_provisoria: Color = Color(0.3, 0.3, 0.35)

## Fases da vida do Nicholas, na ordem (as chaves de [member idade_por_fase]).
const FASES: Array[String] = ["crianca", "adolescente", "adulto"]
const PASTA_RETRATOS := "res://assets/art/retratos/%s/"

## Retratos gerados por tools/arte/retratos_personagens.py, por idade e
## emoção, em res://assets/art/retratos/<id>/. Vazio: usa os dicionários acima.
@export var id_retratos := ""

## Idade do personagem em cada fase da vida do Nicholas, por exemplo Althea
## {"crianca": "6", "adulto": "11"}. Vazio: o personagem tem uma idade só.
## Fase sem idade aqui usa a fase mais próxima que tiver.
@export var idade_por_fase: Dictionary[String, String] = {}


## Retrato da expressão pedida, na idade da fase; sem ele, o "neutro"; sem
## nenhum, null.
func retrato(expressao: String, fase := "") -> Texture2D:
	if not id_retratos.is_empty():
		return _gerado(expressao, fase, "")
	return retratos.get(expressao, retratos.get("neutro", null))


## Retrato de olhos fechados (a piscada), ou null.
func retrato_piscando(expressao: String, fase := "") -> Texture2D:
	if id_retratos.is_empty():
		return null
	return _gerado(expressao, fase, "_piscando")


## Quadros da boca falando na expressão pedida (ou na "neutro"); vazio
## quando o personagem não tem animação de fala.
func quadros_fala(expressao: String, fase := "") -> Array[Texture2D]:
	var quadros: Array[Texture2D] = []
	var faixa: Texture2D
	if not id_retratos.is_empty():
		faixa = _gerado(expressao, fase, "_fala")
	else:
		faixa = retratos_fala.get(expressao, retratos_fala.get("neutro", null))
	if faixa == null:
		return quadros
	var lado := faixa.get_height()
	for i in faixa.get_width() / lado:
		var quadro := AtlasTexture.new()
		quadro.atlas = faixa
		quadro.region = Rect2(i * lado, 0, lado, lado)
		quadros.append(quadro)
	return quadros


## Idade mostrada na fase pedida: a da própria fase ou a da mais próxima
## (empate fica com a mais velha); "" quando o personagem tem uma idade só.
func idade_na_fase(fase: String) -> String:
	if idade_por_fase.is_empty():
		return ""
	if idade_por_fase.has(fase):
		return idade_por_fase[fase]
	var alvo := maxi(FASES.find(fase), 0)
	var melhor := ""
	var distancia := 99
	for chave: String in idade_por_fase:
		var d := absi(FASES.find(chave) - alvo)
		if d < distancia or (d == distancia and FASES.find(chave) > alvo):
			distancia = d
			melhor = idade_por_fase[chave]
	return melhor


## Caminho de um retrato gerado: <id>[_<idade>]_<emocao><sufixo>.png.
func caminho_retrato(expressao: String, fase: String, sufixo := "") -> String:
	var idade := idade_na_fase(fase)
	var nome := id_retratos if idade.is_empty() else "%s_%s" % [id_retratos, idade]
	return (PASTA_RETRATOS % id_retratos) + "%s_%s%s.png" % [nome, expressao, sufixo]


func _gerado(expressao: String, fase: String, sufixo: String) -> Texture2D:
	for e: String in [expressao, "neutro"]:
		var caminho := caminho_retrato(e, fase, sufixo)
		if ResourceLoader.exists(caminho):
			return load(caminho)
	return null
