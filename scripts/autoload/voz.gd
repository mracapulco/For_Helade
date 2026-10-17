extends Node
## Vozes gravadas das falas (autoload "Voz"). Cada fala com áudio tem o
## arquivo assets/audio/vozes/<ID da fala>.mp3, feito por
## scripts/ferramentas/gerar_vozes.gd. Sem áudio, a fala segue em silêncio.
## Toca no barramento "Voz" (volume nas Configurações).

const BARRAMENTO := &"Voz"
const PASTA := "res://assets/audio/vozes"

var _tocador: AudioStreamPlayer
## Texto da fala -> ID, para as frases que chegam só com o texto.
var _por_texto: Dictionary[String, String] = {}


func _ready() -> void:
	_tocador = AudioStreamPlayer.new()
	_tocador.name = "Voz"
	_tocador.bus = BARRAMENTO
	add_child(_tocador)
	carregar_indice()


## Lê o índice das falas gravadas (o gerador o atualiza).
func carregar_indice(caminho := PASTA.path_join("indice.json")) -> void:
	_por_texto.clear()
	if not FileAccess.file_exists(caminho):
		return
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if dados is Dictionary:
		for id: String in dados:
			_por_texto[_normalizar(dados[id].get("texto", ""))] = id


func caminho_de(id: String) -> String:
	return PASTA.path_join(id + ".mp3")


func tem(id: String) -> bool:
	return not id.is_empty() and ResourceLoader.exists(caminho_de(id))


## Toca a fala [param id]. Devolve a duração em segundos (0 sem áudio).
func tocar(id: String) -> float:
	parar()
	if not tem(id):
		return 0.0
	_tocador.stream = load(caminho_de(id))
	_tocador.play()
	return _tocador.stream.get_length()


## Toca a fala pelo texto, para quem só tem o texto (frases soltas).
func tocar_texto(texto: String) -> float:
	return tocar(id_do_texto(texto))


func id_do_texto(texto: String) -> String:
	return _por_texto.get(_normalizar(texto), "")


func parar() -> void:
	if _tocador:
		_tocador.stop()


func tocando() -> bool:
	return _tocador != null and _tocador.playing


static func _normalizar(texto: String) -> String:
	return " ".join(texto.strip_edges().split(" ", false))
