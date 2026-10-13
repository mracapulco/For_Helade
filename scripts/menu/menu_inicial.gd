class_name MenuInicial
extends Control
## Primeira tela do jogo: Continuar, Novo jogo, Opções e Sair.
## Tudo funciona com toque, clique, setas e Enter.

## Cena de cada parte da história salva no Progresso. Parte sem cena ainda
## (por exemplo, o capítulo 1) mostra um aviso provisório.
const CENAS := {
	"prologo": "res://scenes/prologo/prologo.tscn",
}
const CENA_NOVO_JOGO := "res://scenes/prologo/prologo.tscn"
## Música do menu. Basta pôr um arquivo neste caminho para ela tocar.
const MUSICA := "res://assets/audio/music/menu.ogg"

@export var botao_continuar: Button
@export var botao_novo_jogo: Button
@export var botao_opcoes: Button
@export var botao_sair: Button
@export var aviso: Label
@export var painel_principal: Control
@export var opcoes: TelaOpcoes
## Pergunta antes de um jogo novo apagar o jogo salvo.
@export var confirmacao: Control
@export var botao_confirmar_sim: Button
@export var botao_confirmar_nao: Button
## Partes que aparecem aos poucos na entrada.
@export var titulo: Control
@export var capa: Control
@export var musica: AudioStreamPlayer
## Entrada animada; os testes desligam para ir direto ao ponto.
@export var animar_entrada := true

## Cena aberta pelo último botão (para os testes); vazia quando nada abriu.
var cena_pedida := ""
## Quando falso, os botões só anotam a cena pedida, sem trocar (testes).
var trocar_de_cena := true


func _ready() -> void:
	botao_continuar.pressed.connect(_continuar)
	botao_novo_jogo.pressed.connect(_novo_jogo)
	botao_opcoes.pressed.connect(_abrir_opcoes)
	botao_sair.pressed.connect(func() -> void: get_tree().quit())
	opcoes.fechou.connect(_fechar_opcoes)
	botao_confirmar_sim.pressed.connect(_confirmar_novo_jogo)
	botao_confirmar_nao.pressed.connect(_fechar_confirmacao)
	atualizar()
	_tocar_musica()
	if animar_entrada:
		_animar_entrada()


var _entrada: Tween


func _input(evento: InputEvent) -> void:
	# Qualquer tecla, clique ou toque pula a animação de entrada.
	if _entrada and _entrada.is_running() and evento.is_pressed() and not evento.is_echo():
		_entrada.custom_step(60.0)
		get_viewport().set_input_as_handled()


func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed("ui_cancel"):
		return
	if opcoes.visible:
		get_viewport().set_input_as_handled()
		opcoes.fechar()
	elif confirmacao.visible:
		get_viewport().set_input_as_handled()
		_fechar_confirmacao()


## Mostra ou esconde botões conforme o que existe agora.
func atualizar() -> void:
	botao_continuar.visible = Progresso.tem_jogo_salvo()
	botao_sair.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	aviso.text = ""
	opcoes.visible = false
	confirmacao.visible = false
	painel_principal.visible = true
	_focar_primeiro()


func _continuar() -> void:
	if not Progresso.carregar():
		atualizar()
		return
	var cena: String = CENAS.get(Progresso.etapa, "")
	if cena.is_empty():
		aviso.text = tr("MENU_AVISO_SEM_CAPITULO")
		return
	_ir(cena)


func _novo_jogo() -> void:
	if Progresso.tem_jogo_salvo():
		aviso.text = ""
		painel_principal.visible = false
		confirmacao.visible = true
		botao_confirmar_nao.grab_focus() # o seguro fica selecionado
		return
	_comecar()


func _confirmar_novo_jogo() -> void:
	Progresso.apagar()
	confirmacao.visible = false
	painel_principal.visible = true
	_comecar()


func _fechar_confirmacao() -> void:
	confirmacao.visible = false
	painel_principal.visible = true
	botao_novo_jogo.grab_focus()


func _comecar() -> void:
	Progresso.novo_jogo()
	_ir(CENA_NOVO_JOGO)


func _abrir_opcoes() -> void:
	aviso.text = ""
	painel_principal.visible = false
	opcoes.abrir()


func _fechar_opcoes() -> void:
	painel_principal.visible = true
	botao_opcoes.grab_focus()


func _ir(cena: String) -> void:
	cena_pedida = cena
	if trocar_de_cena:
		if musica.playing:
			create_tween().tween_property(musica, "volume_db", -40.0, TrocaCena.tempo)
		TrocaCena.ir_para(cena)


func _tocar_musica() -> void:
	if not ResourceLoader.exists(MUSICA):
		return
	var faixa: AudioStream = load(MUSICA)
	if "loop" in faixa:
		faixa.loop = true
	musica.stream = faixa
	musica.volume_db = -30.0
	musica.play()
	create_tween().tween_property(musica, "volume_db", 0.0, 2.5)


## A capa e o título surgem, depois os botões um a um.
func _animar_entrada() -> void:
	var partes: Array[CanvasItem] = [capa, titulo]
	for botao in [botao_continuar, botao_novo_jogo, botao_opcoes, botao_sair]:
		if botao.visible:
			partes.append(botao)
	for parte in partes:
		parte.modulate.a = 0.0
	_entrada = create_tween()
	_entrada.tween_property(capa, "modulate:a", 1.0, 1.2)
	_entrada.parallel().tween_property(titulo, "modulate:a", 1.0, 1.4).set_delay(0.4)
	for parte in partes.slice(2):
		_entrada.tween_property(parte, "modulate:a", 1.0, 0.3)


func _focar_primeiro() -> void:
	for botao in [botao_continuar, botao_novo_jogo]:
		if botao.visible:
			botao.grab_focus()
			return
