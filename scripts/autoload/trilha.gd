extends Node
## Música de fundo do jogo inteiro (autoload "Trilha"). Fica fora das cenas,
## então continua tocando enquanto a cena troca:
## - [method tocar] troca de música com fade (sai uma, entra a outra).
## - Cada música lembra onde parou: voltar a ela continua daquele ponto.
## Toca no barramento "Musica" (volume nas Configurações).

const BARRAMENTO := &"Musica"
const VOLUME_DB := -6.0
const FADE_PADRAO := 1.5
const SILENCIO_DB := -60.0

## Caminho da música tocando agora ("" quando nenhuma).
var atual := ""
## caminho -> segundos onde a música parou.
var _posicoes: Dictionary[String, float] = {}
var _tocador: AudioStreamPlayer


## Troca para a música em [param caminho] com fade. Se ela já está tocando,
## nada muda. Volta do ponto onde ela tinha parado.
func tocar(caminho: String, fade := FADE_PADRAO) -> void:
	if caminho == atual or not ResourceLoader.exists(caminho):
		return
	_soltar_atual(fade)
	atual = caminho
	_tocador = AudioStreamPlayer.new()
	_tocador.name = "Musica"
	_tocador.bus = BARRAMENTO
	_tocador.stream = load(caminho)
	_tocador.volume_db = SILENCIO_DB if fade > 0.0 else VOLUME_DB
	add_child(_tocador)
	_tocador.play(_posicoes.get(caminho, 0.0))
	if fade > 0.0:
		_tocador.create_tween().tween_property(_tocador, "volume_db", VOLUME_DB, fade) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Para a música com fade (lembrando onde parou).
func parar(fade := FADE_PADRAO) -> void:
	_soltar_atual(fade)
	atual = ""


## Onde a música parou (ou está agora, se for a atual), em segundos.
func posicao(caminho: String) -> float:
	if caminho == atual and _tocador:
		return _tocador.get_playback_position()
	return _posicoes.get(caminho, 0.0)


func tocador_atual() -> AudioStreamPlayer:
	return _tocador


func _soltar_atual(fade: float) -> void:
	if _tocador == null:
		return
	var saindo := _tocador
	_tocador = null
	_posicoes[atual] = saindo.get_playback_position()
	if fade <= 0.0:
		saindo.queue_free()
		return
	var t := saindo.create_tween()
	t.tween_property(saindo, "volume_db", SILENCIO_DB, fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(saindo.queue_free)
