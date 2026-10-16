class_name Acampamento
extends Node2D
## Acampamento numa rota entre os reinos: o ponto de descanso (e de salvar)
## da exploração. A cena base é scenes/exploracao/acampamentos/acampamento_base.tscn;
## cada acampamento é uma cena herdada dela que só troca o [member bioma].
## - Barraca: abre a lista dos 10 espaços para salvar (fica na mesma etapa da
##   história).
## - Mercador: conversa provisória até existir a loja.
## - Companheiro: animal ou viajante, conforme o bioma. O animal faz o seu som
##   e um movimento próprio quando o jogador interage ([method reagir]).
## - Fogueira e mercador animados; neve, insetos, pássaros e vaga-lumes vêm do
##   [VidaAcampamento], conforme o bioma.
## - Saída (placa ou barco) e o botão "Voltar ao mapa": voltam ao mapa de Hélade.
## O cenário em volta é montado pelo [CenarioAcampamento].

signal salvo

const CENA_MAPA := "res://scenes/mapa/mapa_helade.tscn"
## Som de cada animal: <marcador>.wav (cao, ovelha, cabra...).
const PASTA_SONS_ANIMAIS := "res://assets/audio/sfx/animais/"
const SOM_FOGUEIRA := "res://assets/audio/sfx/fogueira.wav"
## Música de fundo de cada acampamento: <id do bioma>.wav (em loop).
const PASTA_MUSICAS := "res://assets/audio/music/acampamentos/"
const BARRAMENTO_EFEITOS := &"Efeitos"
## Quadros da fogueira e do mercador parado (faixas de 4 quadros).
const QUADROS_FOGO := 4
const QUADROS_MERCADOR := 4
const TEMPO_QUADRO_FOGO := 0.12
const TEMPO_QUADRO_MERCADOR := 0.35

@export var bioma: BiomaAcampamento

## Cena aberta pela última saída (para os testes); vazia quando nenhuma.
var cena_pedida := ""
## Quando falso, sair só anota a cena pedida, sem trocar (testes).
var trocar_de_cena := true

@onready var barraca: Interagivel = $Barraca/Interagivel
@onready var mercador: Interagivel = $Mercador/Interagivel
@onready var companheiro: Interagivel = $Companheiro/Interagivel
@onready var saida: Interagivel = $Saida/Interagivel
@onready var aviso: AvisoItens = $AvisoItens
@onready var ambiente: CanvasModulate = $Ambiente
@onready var luz_fogueira: PointLight2D = $Fogueira/Luz
@onready var interface: CanvasLayer = $Interface
@onready var titulo: Label = %Titulo
@onready var botao_mapa: Button = %BotaoMapa
@onready var fogo: Sprite2D = $Fogueira/Visual
@onready var visual_mercador: Sprite2D = $Mercador/Visual
@onready var visual_companheiro: Sprite2D = $Companheiro/Visual

var vida: VidaAcampamento
## Lista de espaços aberta pela barraca.
var tela_espacos: TelaEspacos
var som_companheiro: AudioStreamPlayer2D
var som_fogueira: AudioStreamPlayer2D
## Movimento do companheiro em andamento (para não sobrepor dois).
var _reacao: Tween
var _tempo_fogo := 0.0
var _tempo_mercador := 0.0


func _ready() -> void:
	barraca.interagido.connect(descansar)
	tela_espacos = TelaEspacos.new()
	tela_espacos.name = "TelaEspacos"
	add_child(tela_espacos)
	tela_espacos.escolhido.connect(salvar_no_espaco)
	companheiro.interagido.connect(reagir)
	saida.interagido.connect(voltar_ao_mapa)
	botao_mapa.pressed.connect(voltar_ao_mapa)
	botao_mapa.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	if bioma:
		titulo.text = bioma.chave_nome
		if bioma.mercador:
			visual_mercador.texture = bioma.mercador
			visual_mercador.hframes = QUADROS_MERCADOR
		vida = VidaAcampamento.new()
		vida.name = "Vida"
		$Personagem/Camera.add_child(vida)
		vida.preparar(bioma)
	_preparar_sons()
	_aplicar_periodo(Mundo.noite)
	Mundo.periodo_mudou.connect(_aplicar_periodo)
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	_animar_fogo()


## Descansar na barraca: o jogador escolhe em qual espaço salvar.
func descansar() -> void:
	tela_espacos.abrir(TelaEspacos.Modo.SALVAR)


## Salva sem mudar a etapa da história. O lugar salvo é este acampamento:
## o Continuar põe Nicholas aqui no mapa (o id do bioma é o mesmo do mapa).
## Dormir na barraca também renova o estoque dos mercadores.
func salvar_no_espaco(espaco: int) -> void:
	Lojas.renovar()
	if bioma and not bioma.id.is_empty():
		Mundo.local_no_mapa = bioma.id
	if not Progresso.salvar(Progresso.etapa, espaco):
		return
	aviso.mostrar(tr("ACAMP_SALVO"))
	salvo.emit()


## O animal (ou o viajante) responde ao jogador: som e um movimento próprio.
func reagir() -> void:
	if som_companheiro.stream:
		som_companheiro.play()
	if _reacao and _reacao.is_valid():
		_reacao.kill()
	_descansar_companheiro()
	_reacao = movimento_do_companheiro(bioma.marcador_companheiro if bioma else "")


## Cada bicho se mexe do seu jeito. O desenho tem os pés na origem do nó,
## então girar o Visual gira em volta dos pés.
func movimento_do_companheiro(marcador: String) -> Tween:
	var v := visual_companheiro
	var t := create_tween()
	match marcador:
		"cao": # pula de alegria e abana
			for i in 3:
				t.tween_property(v, "position:y", -6.0, 0.09).set_ease(Tween.EASE_OUT)
				t.tween_property(v, "position:y", 0.0, 0.09).set_ease(Tween.EASE_IN)
				t.tween_callback(func() -> void: v.flip_h = not v.flip_h)
		"ovelha": # um pulinho e encolhe
			t.tween_property(v, "scale", Vector2(1.15, 0.85), 0.1)
			t.tween_property(v, "position:y", -5.0, 0.12)
			t.parallel().tween_property(v, "scale", Vector2(0.9, 1.1), 0.12)
			t.tween_property(v, "position:y", 0.0, 0.12)
			t.parallel().tween_property(v, "scale", Vector2.ONE, 0.12)
		"cabra": # empina nas patas de trás
			t.tween_property(v, "rotation", -0.4, 0.18).set_trans(Tween.TRANS_BACK)
			t.parallel().tween_property(v, "position:y", -3.0, 0.18)
			t.tween_interval(0.25)
			t.tween_property(v, "rotation", 0.0, 0.15)
			t.parallel().tween_property(v, "position:y", 0.0, 0.15)
		"burro": # escoiceia duas vezes
			for i in 2:
				t.tween_property(v, "rotation", 0.3, 0.1)
				t.tween_property(v, "rotation", 0.0, 0.14).set_trans(Tween.TRANS_BOUNCE)
		"coruja": # arrepia as penas e vira a cabeça
			t.tween_property(v, "scale", Vector2(1.2, 1.08), 0.15)
			t.tween_callback(func() -> void: v.flip_h = not v.flip_h)
			t.tween_interval(0.3)
			t.tween_callback(func() -> void: v.flip_h = not v.flip_h)
			t.tween_property(v, "scale", Vector2.ONE, 0.2)
		"gaivota": # levanta voo batendo as asas e volta
			t.tween_property(v, "position", Vector2(10, -28), 0.5).set_ease(Tween.EASE_OUT)
			for i in 4:
				t.parallel().tween_property(v, "scale:y", 0.7 if i % 2 == 0 else 1.0, 0.12).set_delay(i * 0.12)
			t.tween_property(v, "position", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN)
			t.parallel().tween_property(v, "scale:y", 1.0, 0.1)
		"caranguejo": # corre de lado e volta
			t.tween_property(v, "position:x", -10.0, 0.18)
			t.tween_property(v, "position:x", 10.0, 0.3)
			t.tween_property(v, "position:x", 0.0, 0.18)
		_: # gente: acena com a cabeça
			t.tween_property(v, "scale:y", 0.94, 0.12)
			t.tween_property(v, "scale:y", 1.0, 0.12)
	t.tween_callback(_descansar_companheiro)
	return t


func _descansar_companheiro() -> void:
	visual_companheiro.position = Vector2.ZERO
	visual_companheiro.rotation = 0.0
	visual_companheiro.scale = Vector2.ONE
	visual_companheiro.flip_h = false


func _preparar_sons() -> void:
	som_companheiro = AudioStreamPlayer2D.new()
	som_companheiro.name = "Som"
	som_companheiro.bus = BARRAMENTO_EFEITOS
	$Companheiro.add_child(som_companheiro)
	var marcador := bioma.marcador_companheiro if bioma else ""
	var caminho := PASTA_SONS_ANIMAIS + marcador + ".wav"
	if not marcador.is_empty() and ResourceLoader.exists(caminho):
		som_companheiro.stream = load(caminho)
	som_fogueira = AudioStreamPlayer2D.new()
	som_fogueira.name = "Som"
	som_fogueira.volume_db = -8.0
	som_fogueira.bus = BARRAMENTO_EFEITOS
	som_fogueira.max_distance = 500.0
	$Fogueira.add_child(som_fogueira)
	if ResourceLoader.exists(SOM_FOGUEIRA):
		som_fogueira.stream = load(SOM_FOGUEIRA)
		som_fogueira.play()
	# O autoload Trilha faz o fade com a música do mapa.
	if bioma:
		Trilha.tocar(musica_do_acampamento())


func musica_do_acampamento() -> String:
	return PASTA_MUSICAS + bioma.id + ".wav"


func _process(delta: float) -> void:
	_tempo_fogo += delta
	if _tempo_fogo >= TEMPO_QUADRO_FOGO and fogo.hframes > 1:
		_tempo_fogo = 0.0
		fogo.frame = (fogo.frame + 1) % fogo.hframes
	_tempo_mercador += delta
	if _tempo_mercador >= TEMPO_QUADRO_MERCADOR and visual_mercador.hframes > 1:
		_tempo_mercador = 0.0
		visual_mercador.frame = (visual_mercador.frame + 1) % visual_mercador.hframes


func voltar_ao_mapa() -> void:
	cena_pedida = CENA_MAPA
	if trocar_de_cena:
		TrocaCena.ir_para(CENA_MAPA)


func _aplicar_periodo(noite: bool) -> void:
	if bioma:
		ambiente.color = bioma.cor_noite if noite else bioma.cor_dia
	luz_fogueira.enabled = noite
	if vida:
		vida.aplicar_periodo(noite)


## A luz da fogueira tremula de leve (só aparece à noite).
func _animar_fogo() -> void:
	var tremor := luz_fogueira.create_tween().set_loops()
	tremor.tween_property(luz_fogueira, "energy", 0.85, 0.35).set_trans(Tween.TRANS_SINE)
	tremor.tween_property(luz_fogueira, "energy", 1.1, 0.45).set_trans(Tween.TRANS_SINE)


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	interface.hide()


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	interface.show()
