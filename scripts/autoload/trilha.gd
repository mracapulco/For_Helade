extends Node
## Música de fundo do jogo inteiro (autoload "Trilha"). Fica fora das cenas,
## então continua tocando enquanto a cena troca:
## - [method tocar] troca de música com fade (sai uma, entra a outra).
## - Cada música lembra onde parou: voltar a ela continua daquele ponto.
## - Um segundo canal, o ambiente ([method ambientar]), toca por baixo da
##   música (rua, fonte, restaurante), com o mesmo fade.
## - Cenas listadas em data/musica/cenas.cfg ([TrilhaDasCenas]) não precisam
##   chamar nada: quando abrem, e a cada etapa_mudou(etapa) delas, a música e o
##   ambiente trocam sozinhos. Cena fora da lista cuida da própria música, e o
##   ambiente para quando ela abre.
## Música no barramento "Musica", ambiente em "Efeitos" (volumes nas Configurações).

const BARRAMENTO := &"Musica"
const BARRAMENTO_AMBIENTE := &"Efeitos"
const VOLUME_DB := -6.0
const VOLUME_AMBIENTE_DB := -10.0
const FADE_PADRAO := 1.5
const SILENCIO_DB := -60.0

## Caminho da música tocando agora ("" quando nenhuma).
var atual := ""
## Caminho do ambiente tocando agora ("" quando nenhum).
var ambiente_atual := ""

var _musica := Canal.new(self, "Musica", BARRAMENTO, VOLUME_DB)
var _ambiente := Canal.new(self, "Ambiente", BARRAMENTO_AMBIENTE, VOLUME_AMBIENTE_DB)
var _cenas: TrilhaDasCenas


func _ready() -> void:
	_cenas = TrilhaDasCenas.carregar()
	get_tree().node_added.connect(_ao_entrar)
	# Rodando uma cena direto no editor (F6), ela entra na árvore e começa
	# antes deste _ready, e o node_added não a pega: segue a que já está lá.
	_seguir_a_cena_atual.call_deferred()


func _seguir_a_cena_atual() -> void:
	var cena := get_tree().current_scene
	if cena and cena.get_parent() == get_tree().root and not cena.scene_file_path.is_empty():
		observar(cena)
		# A etapa em que ela já está (o etapa_mudou dela veio antes de nós).
		if "etapa" in cena:
			na_etapa(cena.scene_file_path, str(cena.etapa))


## Troca para a música em [param caminho] com fade. Se ela já está tocando,
## nada muda. Volta do ponto onde ela tinha parado.
func tocar(caminho: String, fade := FADE_PADRAO) -> void:
	if _musica.tocar(caminho, fade):
		atual = caminho


## Para a música com fade (lembrando onde parou).
func parar(fade := FADE_PADRAO) -> void:
	_musica.parar(fade)
	atual = ""


## Troca o ambiente com fade ("" para o ambiente).
func ambientar(caminho: String, fade := FADE_PADRAO) -> void:
	if caminho.is_empty():
		_ambiente.parar(fade)
		ambiente_atual = ""
	elif _ambiente.tocar(caminho, fade):
		ambiente_atual = caminho


## Onde a música parou (ou está agora, se for a atual), em segundos.
func posicao(caminho: String) -> float:
	return _musica.posicao(caminho)


func tocador_atual() -> AudioStreamPlayer:
	return _musica.tocador


func tocador_ambiente() -> AudioStreamPlayer:
	return _ambiente.tocador


## Passa a seguir a cena [param no] pelo que diz data/musica/cenas.cfg: toca o
## início dela e escuta o sinal etapa_mudou. Cenas abertas com troca de cena
## já são seguidas sozinhas.
func observar(no: Node) -> void:
	var cena := no.scene_file_path
	if not _cenas.tem(cena):
		ambientar("")
		return
	na_etapa(cena, TrilhaDasCenas.INICIO)
	if no.has_signal("etapa_mudou") and not no.is_connected("etapa_mudou", _ao_mudar_etapa):
		no.connect("etapa_mudou", _ao_mudar_etapa.bind(cena))


## Toca o que a [param etapa] da [param cena] pede (nada, se ela não está na lista).
func na_etapa(cena: String, etapa: String) -> void:
	var f := _cenas.faixas(cena, etapa)
	if f.is_empty():
		return
	var fade: float = f.fade if f.fade >= 0.0 else FADE_PADRAO
	if f.musica == "":
		parar(fade)
	elif f.musica != TrilhaDasCenas.MANTER:
		tocar(f.musica, fade)
	if f.ambiente != TrilhaDasCenas.MANTER:
		ambientar(f.ambiente, fade)


func _ao_mudar_etapa(etapa: String, cena: String) -> void:
	na_etapa(cena, etapa)


## Só a cena principal (filha direta da raiz) conta; as cenas montadas dentro
## de outras (e as dos testes) não mexem na música.
func _ao_entrar(no: Node) -> void:
	if no.get_parent() == get_tree().root and not no.scene_file_path.is_empty():
		observar(no)


## Um canal de som com fade e memória de onde cada faixa parou.
class Canal:
	var tocador: AudioStreamPlayer
	var _dono: Node
	var _nome: String
	var _barramento: StringName
	var _volume: float
	var _caminho := ""
	## caminho -> segundos onde a faixa parou.
	var _posicoes: Dictionary[String, float] = {}

	func _init(dono: Node, nome: String, barramento: StringName, volume: float) -> void:
		_dono = dono
		_nome = nome
		_barramento = barramento
		_volume = volume

	## Devolve falso quando nada mudou (já tocando ou arquivo inexistente).
	func tocar(caminho: String, fade: float) -> bool:
		if caminho == _caminho or not ResourceLoader.exists(caminho):
			return false
		parar(fade)
		_caminho = caminho
		tocador = AudioStreamPlayer.new()
		tocador.name = _nome
		tocador.bus = _barramento
		tocador.stream = load(caminho)
		tocador.volume_db = SILENCIO_DB if fade > 0.0 else _volume
		_dono.add_child(tocador)
		tocador.play(_posicoes.get(caminho, 0.0))
		if fade > 0.0:
			tocador.create_tween().tween_property(tocador, "volume_db", _volume, fade) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		return true

	func parar(fade: float) -> void:
		if tocador == null:
			_caminho = ""
			return
		var saindo := tocador
		tocador = null
		_posicoes[_caminho] = saindo.get_playback_position()
		_caminho = ""
		if fade <= 0.0:
			saindo.queue_free()
			return
		var t := saindo.create_tween()
		t.tween_property(saindo, "volume_db", SILENCIO_DB, fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_callback(saindo.queue_free)

	func posicao(caminho: String) -> float:
		if caminho == _caminho and tocador:
			return tocador.get_playback_position()
		return _posicoes.get(caminho, 0.0)
