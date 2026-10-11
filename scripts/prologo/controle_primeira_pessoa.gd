class_name ControlePrimeiraPessoa
extends Node3D
## Primeira pessoa por pontos fixos: a câmera fica num PontoDeVista e, ao tocar
## num AlvoToque, desliza até o ponto de destino. Não há andar livre.

signal chegou(ponto: PontoDeVista)

@export var camera: Camera3D
@export var ponto_inicial: PontoDeVista
@export var duracao_movimento := 1.4
## Texto de ajuda na parte de baixo da tela.
@export var dica: Label
## Olhos abrindo no começo da cena. Sem ela, a cena começa com os olhos abertos.
@export var abertura: AberturaOlhos

var ponto_atual: PontoDeVista
var em_movimento := false


func _ready() -> void:
	# Necessário para que o toque/clique chegue às Area3D.
	get_viewport().physics_object_picking = true
	for alvo in _todos_os_alvos(self):
		alvo.tocado.connect(_ao_tocar)
	if ponto_inicial:
		camera.global_transform = ponto_inicial.global_transform
		if abertura:
			# Nicholas acorda: nada responde ao toque até os olhos abrirem.
			em_movimento = true
			if dica:
				dica.text = ""
			await abertura.abrir()
			em_movimento = false
		_chegar_em(ponto_inicial)


func mover_para(destino: PontoDeVista) -> void:
	if em_movimento or destino == null or destino == ponto_atual:
		return
	em_movimento = true
	_ativar_alvos(ponto_atual, false)
	var de := camera.global_transform
	var para := destino.global_transform
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float) -> void: camera.global_transform = de.interpolate_with(para, t), 0.0, 1.0, duracao_movimento)
	tween.finished.connect(func() -> void:
		em_movimento = false
		_chegar_em(destino))


func _ao_tocar(alvo: AlvoToque) -> void:
	if alvo.get_parent() == ponto_atual:
		mover_para(alvo.destino)


func _chegar_em(ponto: PontoDeVista) -> void:
	ponto_atual = ponto
	_ativar_alvos(ponto, true)
	if dica:
		# Sem mais lugares para ir, este passo acabou. O texto final é provisório
		# até o sequenciador de batidas (passo 2) assumir a cena.
		dica.text = tr("PROLOGO_DICA_TOQUE") if not ponto.alvos().is_empty() else tr("PROLOGO_PROVISORIO_FIM_PASSO1")
	chegou.emit(ponto)


func _ativar_alvos(ponto: PontoDeVista, valor: bool) -> void:
	if ponto == null:
		return
	for alvo in ponto.alvos():
		alvo.ativo = valor


func _todos_os_alvos(no: Node) -> Array[AlvoToque]:
	var lista: Array[AlvoToque] = []
	for filho in no.get_children():
		if filho is AlvoToque:
			lista.append(filho)
		lista.append_array(_todos_os_alvos(filho))
	return lista
