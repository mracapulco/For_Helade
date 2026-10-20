extends Node
## Vozes gravadas das falas (autoload "Voz"). Cada fala com áudio tem o
## arquivo assets/audio/vozes/<ID da fala>.mp3, feito por
## scripts/ferramentas/gerar_vozes.gd. Sem áudio, a fala segue em silêncio.
## Toca no barramento "Voz" (volume nas Configurações).
## Fala de coro (várias pessoas juntas, como os sussurros do fim do prólogo):
## <ID>_1.mp3, <ID>_2.mp3... tocam todas ao mesmo tempo, cada uma um pouco
## atrasada, para soar como gente de verdade e não em uníssono.
## Som da fala (data/vozes/sons.cfg): <ID>_som.mp3 toca junto com a voz, ou
## sozinho quando a fala não tem voz (passos, cochichos, um resmungo).

const BARRAMENTO := &"Voz"
const PASTA := "res://assets/audio/vozes"
## Quantas vozes um coro pode ter.
const MAXIMO_CORO := 8
## Atraso entre uma voz do coro e a seguinte (segundos).
const ATRASO_CORO := 0.12

var _tocador: AudioStreamPlayer
var _coro: Array[AudioStreamPlayer] = []
var _som: AudioStreamPlayer
## Texto da fala -> ID, para as frases que chegam só com o texto.
var _por_texto: Dictionary[String, String] = {}


func _ready() -> void:
	_tocador = AudioStreamPlayer.new()
	_tocador.name = "Voz"
	_tocador.bus = BARRAMENTO
	add_child(_tocador)
	_som = AudioStreamPlayer.new()
	_som.name = "Som"
	_som.bus = BARRAMENTO
	add_child(_som)
	for i in MAXIMO_CORO:
		var tocador := AudioStreamPlayer.new()
		tocador.name = "Coro%d" % (i + 1)
		tocador.bus = BARRAMENTO
		add_child(tocador)
		_coro.append(tocador)
	carregar_indice()


## Lê o índice das falas gravadas (o gerador o atualiza).
func carregar_indice(caminho := PASTA.path_join("indice.json")) -> void:
	_por_texto.clear()
	if not FileAccess.file_exists(caminho):
		return
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if dados is Dictionary:
		for arquivo: String in dados:
			# Nas vozes de coro o arquivo é <ID>_1, <ID>_2...: guarda o ID da fala.
			_por_texto[_normalizar(dados[arquivo].get("texto", ""))] = dados[arquivo].get("fala", arquivo)


func caminho_de(id: String) -> String:
	return PASTA.path_join(id + ".mp3")


func tem(id: String) -> bool:
	return not id.is_empty() and (ResourceLoader.exists(caminho_de(id)) or not vozes_do_coro(id).is_empty() or ResourceLoader.exists(caminho_de(id + "_som")))


## Os arquivos de uma fala de coro, em ordem (vazio se não for coro).
func vozes_do_coro(id: String) -> PackedStringArray:
	var arquivos := PackedStringArray()
	for i in MAXIMO_CORO:
		var arquivo := "%s_%d" % [id, i + 1]
		if not ResourceLoader.exists(caminho_de(arquivo)):
			break
		arquivos.append(arquivo)
	return arquivos


## Toca a fala [param id]. Devolve a duração em segundos (0 sem áudio).
func tocar(id: String) -> float:
	parar()
	if id.is_empty():
		return 0.0
	var som := 0.0
	if ResourceLoader.exists(caminho_de(id + "_som")):
		_som.stream = load(caminho_de(id + "_som"))
		_som.play()
		som = _som.stream.get_length()
	return maxf(som, _tocar_voz(id))


func _tocar_voz(id: String) -> float:
	if ResourceLoader.exists(caminho_de(id)):
		_tocador.stream = load(caminho_de(id))
		_tocador.play()
		return _tocador.stream.get_length()
	var duracao := 0.0
	var arquivos := vozes_do_coro(id)
	for i in arquivos.size():
		var tocador := _coro[i]
		tocador.stream = load(caminho_de(arquivos[i]))
		var atraso := ATRASO_CORO * i
		if atraso > 0.0:
			get_tree().create_timer(atraso).timeout.connect(func() -> void:
				if tocador.stream:
					tocador.play())
		else:
			tocador.play()
		duracao = maxf(duracao, atraso + tocador.stream.get_length())
	return duracao


## Toca a fala pelo texto, para quem só tem o texto (frases soltas).
func tocar_texto(texto: String) -> float:
	return tocar(id_do_texto(texto))


func id_do_texto(texto: String) -> String:
	return _por_texto.get(_normalizar(texto), "")


func parar() -> void:
	if _tocador:
		_tocador.stop()
	if _som:
		_som.stop()
	for tocador in _coro:
		tocador.stop()
		tocador.stream = null


func tocando() -> bool:
	return _tocador != null and (_tocador.playing or _som.playing or _coro.any(func(t: AudioStreamPlayer) -> bool: return t.playing))


## Alguém está falando agora (a voz ou o coro; o som da fala não conta).
func falando() -> bool:
	return _tocador != null and (_tocador.playing or _coro.any(func(t: AudioStreamPlayer) -> bool: return t.playing))


static func _normalizar(texto: String) -> String:
	return " ".join(texto.strip_edges().split(" ", false))
