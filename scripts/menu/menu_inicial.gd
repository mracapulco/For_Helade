class_name MenuInicial
extends Control
## Primeira tela do jogo: Continuar, Carregar jogo, Novo jogo, Opções e Sair.
## Tudo funciona com toque, clique, setas e Enter.
## Continuar abre o jogo salvo por último; Carregar jogo mostra os 10 espaços.

## Missões com cena própria: quem salvou numa delas volta direto para ela.
## Qualquer outra parte da história volta para o mapa, no lugar onde salvou:
## o último acampamento ou, quando existir, o reino.
const CENAS := {
	"prologo": "res://scenes/prologo/prologo.tscn",
	"capitulo_1": "res://scenes/capitulo_01/capitulo_01.tscn",
	# Cenas 7 a 13 do Capítulo 1 (as mesmas de SequenciaCenas01.CENAS): um jogo
	# salvo com uma destas etapas, ou `--etapa=<nome>` (ver abrir_etapa), abre
	# a cena sozinha para testar.
	"palacio": "res://scenes/capitulo_01/cena_palacio.tscn",
	"visao_carruagem": "res://scenes/capitulo_01/cena_visao.tscn",
	"butiques": "res://scenes/capitulo_01/cena_butiques.tscn",
	"restaurante": "res://scenes/capitulo_01/cena_restaurante.tscn",
	"passeio": "res://scenes/capitulo_01/cena_passeio.tscn",
	"volta": "res://scenes/capitulo_01/cena_volta.tscn",
}
const CENA_MAPA := "res://scenes/mapa/mapa_helade.tscn"
const CENA_NOVO_JOGO := "res://scenes/prologo/prologo.tscn"
## Música do menu. Basta pôr um arquivo neste caminho para ela tocar.
const MUSICA := "res://assets/audio/music/menu.ogg"

@export var botao_continuar: Button
@export var botao_carregar: Button
@export var botao_novo_jogo: Button
@export var botao_opcoes: Button
@export var botao_sair: Button
@export var aviso: Label
@export var painel_principal: Control
@export var opcoes: TelaOpcoes
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
## Lista dos 10 espaços, aberta por Carregar jogo.
var tela_espacos: TelaEspacos


func _ready() -> void:
	botao_continuar.pressed.connect(_continuar)
	botao_carregar.pressed.connect(_abrir_espacos)
	botao_novo_jogo.pressed.connect(_novo_jogo)
	botao_opcoes.pressed.connect(_abrir_opcoes)
	botao_sair.pressed.connect(func() -> void: get_tree().quit())
	opcoes.fechou.connect(_fechar_opcoes)
	tela_espacos = TelaEspacos.new()
	tela_espacos.name = "TelaEspacos"
	tela_espacos.pausar = false
	add_child(tela_espacos)
	tela_espacos.escolhido.connect(carregar_espaco)
	tela_espacos.fechou.connect(_fechar_espacos)
	atualizar()
	_tocar_musica()
	if animar_entrada:
		_animar_entrada()
	# Atalho de teste: godot --path . -- --etapa=butiques (só em build de debug).
	if OS.is_debug_build():
		abrir_etapa(etapa_da_linha_de_comando(OS.get_cmdline_user_args()))


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


## Mostra ou esconde botões conforme o que existe agora.
func atualizar() -> void:
	botao_continuar.visible = Progresso.tem_jogo_salvo()
	botao_carregar.visible = botao_continuar.visible
	botao_sair.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	aviso.text = ""
	opcoes.visible = false
	painel_principal.visible = true
	_focar_primeiro()


func _continuar() -> void:
	carregar_espaco(Progresso.espaco_mais_recente())


## Abre o jogo do espaço: a missão em que salvou ou, sem missão, o mapa.
func carregar_espaco(espaco: int) -> void:
	if not Progresso.carregar(espaco):
		atualizar()
		return
	_ir(cena_para_continuar(Progresso.etapa))


## Abre direto a cena de uma etapa (ponto de entrada de teste). Devolve falso
## se a etapa não tem cena.
func abrir_etapa(etapa: String) -> bool:
	if not CENAS.has(etapa):
		return false
	_ir(CENAS[etapa])
	return true


## O valor de `--etapa=<nome>` nos argumentos, ou vazio.
static func etapa_da_linha_de_comando(argumentos: PackedStringArray) -> String:
	for argumento in argumentos:
		if argumento.begins_with("--etapa="):
			return argumento.trim_prefix("--etapa=")
	return ""


static func cena_para_continuar(etapa: String) -> String:
	return CENAS.get(etapa, CENA_MAPA)


func _abrir_espacos() -> void:
	aviso.text = ""
	painel_principal.visible = false
	tela_espacos.abrir(TelaEspacos.Modo.CARREGAR)


func _fechar_espacos() -> void:
	painel_principal.visible = true
	# Algum jogo pode ter sido apagado: sem nenhum, Continuar e Carregar somem.
	atualizar()
	if botao_carregar.visible:
		botao_carregar.grab_focus()


## Novo jogo não apaga nada: os espaços salvos continuam lá, e o primeiro
## salvamento do jogo novo vai para um espaço livre (ou o escolhido na barraca).
func _novo_jogo() -> void:
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
	for botao in [botao_continuar, botao_carregar, botao_novo_jogo, botao_opcoes, botao_sair]:
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
