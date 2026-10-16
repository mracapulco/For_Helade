class_name SequenciaPrologo
extends Node
## Do momento em que Nicholas entra nos aposentos da duquesa até o fim do
## prólogo (batidas 3 a 10 do plano). O texto vem todo do roteiro do prólogo.
##
## Nos aposentos o controle trava: a única ação do jogador é dizer o nome
## "Althea?" e, depois, segurá-la. Na varanda o controle volta, e o prólogo
## termina com os sussurros e o título.

signal etapa_mudou(etapa: String)
signal terminou

@export var controle: ControlePrimeiraPessoa
## Ponto logo depois da porta dos aposentos: chegar aqui começa a cena.
@export var ponto_entrada: PontoDeVista
## Onde Nicholas abre os olhos depois da tela preta, com o quarto já vazio.
@export var ponto_quarto_vazio: PontoDeVista
@export var ponto_varanda: PontoDeVista
## Para onde Nicholas olha: a cama da duquesa e o dossel azul-escuro.
@export var cama: Node3D
@export var dossel: Node3D
## Parteiras e empregadas (figuras provisórias).
@export var figuras: Node3D
## A parteira que entrega Althea a Nicholas.
@export var parteira: Node3D
@export var althea: Node3D
@export var alvo_althea: AlvoToque
@export var vela_cama: OmniLight3D
## Tela escura por cima da cena (fica abaixo das frases).
@export var escuro: ColorRect
## O único botão da cena, com o nome "Althea?".
@export var botao_nome: Button
@export var tela_final: TelaFinal
## Para onde o jogo vai depois do título: o mapa de Hélade, já no reino da
## primeira fase. Vazio: fica no título (testes).
@export var cena_depois := "res://scenes/mapa/mapa_helade.tscn"
## Parte da história salva ao terminar o prólogo.
@export var etapa_salva := "capitulo_1"
## Multiplica todos os tempos da sequência (os testes usam valores pequenos).
@export var escala_tempo := 1.0

var etapa := ""

signal _respondeu

var _esperando := ""
var _agitadas := false
var _tempo := 0.0
var _bases := {}


func _ready() -> void:
	controle.chegou.connect(_ao_chegar)
	botao_nome.pressed.connect(_responder.bind("nome"))
	alvo_althea.tocado.connect(func(_alvo: AlvoToque) -> void: _responder("segurar"))
	botao_nome.visible = false
	althea.visible = false
	escuro.color.a = 0.0
	tela_final.visible = false
	for figura: Node3D in figuras.get_children():
		_bases[figura] = figura.rotation.y


func _process(delta: float) -> void:
	if not _agitadas:
		return
	# Correria em volta da cama: as figuras se mexem sem parar.
	_tempo += delta
	var i := 0
	for figura: Node3D in figuras.get_children():
		figura.rotation.y = _bases[figura] + 0.35 * sin(_tempo * 2.3 + i * 1.7)
		i += 1


func _unhandled_input(evento: InputEvent) -> void:
	if not _esperando.is_empty() and evento.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		_responder(_esperando)


func _ao_chegar(ponto: PontoDeVista) -> void:
	if ponto == ponto_entrada and etapa.is_empty():
		_aposentos()
	elif ponto == ponto_varanda and etapa == "quarto_vazio":
		_varanda()


func _aposentos() -> void:
	_mudar("caos")
	controle.travado = true
	_dica("")
	_agitadas = true
	await controle.olhar_para(cama.global_position, _t(0.8))
	await controle.tocar_cena("aposentos_caos")

	_mudar("dossel")
	create_tween().tween_property(escuro, "color:a", 0.45, _t(2.0))
	await controle.olhar_para(dossel.global_position, _t(2.5))
	await controle.tocar_cena("dossel")

	_mudar("muda")
	await controle.olhar_para(cama.global_position, _t(1.5))
	_agitadas = false
	althea.visible = true
	await controle.tocar_cena("muda")

	_mudar("nome")
	var nome := await controle.frases_de("nome")
	botao_nome.text = nome[0] if not nome.is_empty() else "?"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	botao_nome.visible = true
	botao_nome.grab_focus()
	await _esperar("nome")
	botao_nome.visible = false
	# Nicholas diz o nome em voz alta (se houver voz gravada). A cena espera
	# a voz terminar: a narração seguinte cortaria o nome no meio.
	var voz_nome := Voz.tocar_texto(botao_nome.text)
	if voz_nome > 0.0:
		await get_tree().create_timer(voz_nome).timeout

	_mudar("olhares")
	# "tão rápido que sibilaram": todos se viram para Nicholas de uma vez.
	var giro := create_tween().set_parallel()
	for figura: Node3D in figuras.get_children():
		giro.tween_property(figura, "rotation:y", _giro_para_nicholas(figura), _t(0.25))
	await controle.tocar_cena("olhares")
	create_tween().tween_property(vela_cama, "light_energy", vela_cama.light_energy * 0.3, _t(4.0))
	await controle.tocar_cena("choro")

	var frente := -controle.corpo.global_basis.z
	var perto := controle.corpo.global_position + Vector3(frente.x, 0.0, frente.z).normalized() * 1.1
	var passo := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	passo.tween_property(parteira, "global_position", Vector3(perto.x, parteira.global_position.y, perto.z), _t(2.0))
	await passo.finished
	_mudar("segurar")
	alvo_althea.ativo = true
	_dica(tr("PROLOGO_DICA_SEGURAR_TOQUE") if OS.has_feature("mobile") else tr("PROLOGO_DICA_SEGURAR_TECLADO"))
	await _esperar("segurar")
	alvo_althea.ativo = false
	_dica("")
	# Nos braços de Nicholas, logo abaixo do olhar.
	althea.reparent(controle.camera, false)
	althea.position = Vector3(0.0, -0.3, -0.5)
	althea.rotation = Vector3.ZERO

	_mudar("nos_bracos")
	await controle.tocar_cena("parabens")
	await controle.tocar_cena("costume")

	_mudar("depois")
	var apagar := create_tween()
	apagar.tween_property(escuro, "color:a", 1.0, _t(2.0))
	await apagar.finished
	await controle.tocar_cena("depois")
	figuras.visible = false
	althea.visible = false
	vela_cama.light_energy /= 0.3
	controle.colocar_em(ponto_quarto_vazio)
	if controle.abertura:
		controle.abertura.abrir() # começa fechada, então a troca não aparece
		escuro.color.a = 0.0
		await controle.abertura.terminou
	escuro.color.a = 0.0

	_mudar("quarto_vazio")
	controle.continuar_em(ponto_quarto_vazio)


func _varanda() -> void:
	_mudar("varanda")
	await controle.tocar_cena("varanda")
	await controle.tocar_cena("desde_entao")

	_mudar("final")
	controle.travado = true
	_dica("")
	var apagar := create_tween()
	apagar.tween_property(escuro, "color:a", 1.0, _t(2.5))
	await apagar.finished
	await tela_final.mostrar(await controle.frases_de("sussurros_finais"), escala_tempo)
	_mudar("fim")
	terminou.emit()
	await get_tree().create_timer(_t(3.0)).timeout
	var progresso := get_node_or_null("/root/Progresso")
	if progresso and not etapa_salva.is_empty():
		progresso.salvar(etapa_salva)
	var troca := get_node_or_null("/root/TrocaCena")
	if troca and not cena_depois.is_empty():
		troca.ir_para(cena_depois)


func _esperar(o_que: String) -> void:
	_esperando = o_que
	await _respondeu


func _responder(o_que: String) -> void:
	if _esperando != o_que:
		return
	_esperando = ""
	_respondeu.emit()


func _giro_para_nicholas(figura: Node3D) -> float:
	var direcao := controle.corpo.global_position - figura.global_position
	var alvo := atan2(-direcao.x, -direcao.z)
	return figura.rotation.y + wrapf(alvo - figura.rotation.y, -PI, PI)


func _mudar(nova: String) -> void:
	etapa = nova
	etapa_mudou.emit(nova)


func _dica(texto: String) -> void:
	if controle.dica:
		controle.dica.text = texto


func _t(segundos: float) -> float:
	return segundos * escala_tempo
