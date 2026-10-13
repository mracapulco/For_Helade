class_name ControlePrimeiraPessoa
extends Node3D
## Primeira pessoa de Nicholas.
## No PC: WASD (ou setas) para andar, Shift para correr, espaço para pular e
## mouse para olhar; Enter (ou clicar) com a mira no
## brilho dourado também leva até ele. Esc solta o mouse.
## No toque: tocar no brilho dourado leva a câmera até o próximo ponto.
## Chegar perto do próximo ponto, andando ou pelo toque, avança o percurso.

signal chegou(ponto: PontoDeVista)

@export var corpo: CharacterBody3D
## Fica dentro do corpo, na altura dos olhos de uma criança de 5 anos.
@export var camera: Camera3D
@export var ponto_inicial: PontoDeVista
## Texto de ajuda na parte de baixo da tela.
@export var dica: Label
## Pontinho no centro da tela, visível enquanto o mouse está preso.
@export var mira: Control
## Olhos abrindo no começo da cena. Sem ela, a cena começa com os olhos abertos.
@export var abertura: AberturaOlhos
## Roteiro do prólogo (frases do livro). Sem ele, a cena não mostra texto.
@export var roteiro: DialogueResource
## Onde as frases aparecem e somem.
@export var texto_solto: TextoSolto
## Trecho do roteiro mostrado na tela preta, antes de os olhos abrirem.
@export var cena_inicial := "abertura"
## Passo de criança, em metros por segundo.
@export var velocidade := 1.6
## Velocidade segurando Shift.
@export var velocidade_correndo := 3.2
## Impulso do pulo (m/s): uma criança pula uns 45 cm, o bastante para subir na cama.
@export var impulso_pulo := 3.0
@export var sensibilidade_mouse := 0.0025
## Tempo para deslizar até um ponto quando o jogador toca no brilho.
@export var duracao_movimento := 1.4
## Distância, no chão, em que Nicholas conta como tendo chegado a um ponto.
@export var raio_chegada := 0.8

var ponto_atual: PontoDeVista
## Deslizando até um ponto depois de um toque.
var em_movimento := false
## Nada responde ao jogador (tela preta, olhos abrindo, cenas do quarto da mãe).
var travado := false
## Trecho do roteiro na tela agora; vazio quando não há texto.
var cena_tocando := ""

var _cenas_vistas: Array[String] = []

var _gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	# Necessário para que o toque/clique chegue às Area3D.
	get_viewport().physics_object_picking = true
	for alvo in _todos_os_alvos(self):
		alvo.tocado.connect(_ao_tocar)
	if ponto_inicial == null:
		return
	_colocar_em(ponto_inicial)
	travado = true
	if dica:
		dica.text = ""
	await tocar_cena(cena_inicial)
	if abertura:
		# Nicholas acorda: nada responde até os olhos abrirem.
		await abertura.abrir()
	travado = false
	_chegar_em(ponto_inicial)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("liberar_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if travado or em_movimento:
		return
	if evento.is_action_pressed("interagir"):
		# Enter é a tecla padrão de interação do jogo.
		var mirado := _alvo_na_mira()
		if mirado:
			_ao_tocar(mirado)
		return
	var mouse_preso := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if evento is InputEventMouseMotion and mouse_preso:
		corpo.rotate_y(-evento.relative.x * sensibilidade_mouse)
		camera.rotation.x = clampf(camera.rotation.x - evento.relative.y * sensibilidade_mouse, deg_to_rad(-80), deg_to_rad(80))
	elif evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		# Toques chegam como cliques "emulados": esses nunca prendem o mouse.
		if evento.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if mouse_preso:
			var alvo := _alvo_na_mira()
			if alvo:
				_ao_tocar(alvo)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if mira:
		mira.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not travado


func _physics_process(delta: float) -> void:
	if em_movimento:
		return
	var direcao := Vector2.ZERO
	if not travado:
		direcao = Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
	var passo := corpo.global_basis * Vector3(direcao.x, 0.0, direcao.y)
	var rapidez := velocidade_correndo if not travado and Input.is_action_pressed("correr") else velocidade
	corpo.velocity.x = passo.x * rapidez
	corpo.velocity.z = passo.z * rapidez
	if corpo.is_on_floor():
		corpo.velocity.y = impulso_pulo if not travado and Input.is_action_just_pressed("pular") else 0.0
	else:
		corpo.velocity.y -= _gravidade * delta
	corpo.move_and_slide()
	_verificar_chegada()


func mover_para(destino: PontoDeVista) -> void:
	if em_movimento or travado or destino == null or destino == ponto_atual:
		return
	em_movimento = true
	_ativar_alvos(ponto_atual, false)
	var pos_de := corpo.global_position
	var giro_de := corpo.rotation.y
	var olhar_de := camera.rotation.x
	var pos_para := _posicao_do_corpo(destino)
	var giro_para := _giro(destino)
	var olhar_para := _inclinacao(destino)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float) -> void:
		corpo.global_position = pos_de.lerp(pos_para, t)
		corpo.rotation.y = lerp_angle(giro_de, giro_para, t)
		camera.rotation.x = lerpf(olhar_de, olhar_para, t), 0.0, 1.0, duracao_movimento)
	tween.finished.connect(func() -> void:
		em_movimento = false
		_chegar_em(destino))


func _ao_tocar(alvo: AlvoToque) -> void:
	if alvo.get_parent() == ponto_atual:
		mover_para(alvo.destino)


func _verificar_chegada() -> void:
	if ponto_atual == null or travado:
		return
	for alvo in ponto_atual.alvos():
		var destino := alvo.destino
		var diferenca := destino.global_position - corpo.global_position
		if Vector2(diferenca.x, diferenca.z).length() <= raio_chegada:
			_ativar_alvos(ponto_atual, false)
			_chegar_em(destino)
			return


## Mostra as frases de um trecho do roteiro, que aparecem e somem sozinhas.
## Nicholas continua andando. Cada trecho só aparece uma vez.
func tocar_cena(titulo: String) -> void:
	if roteiro == null or texto_solto == null or titulo.is_empty() or titulo in _cenas_vistas:
		return
	_cenas_vistas.append(titulo)
	cena_tocando = titulo
	await texto_solto.mostrar(await frases_de(titulo))
	if cena_tocando == titulo:
		cena_tocando = ""


## As frases de um trecho do roteiro, na ordem.
func frases_de(titulo: String) -> Array[String]:
	var frases: Array[String] = []
	if roteiro == null:
		return frases
	var linha: DialogueLine = await roteiro.get_next_dialogue_line(titulo)
	while linha:
		frases.append(linha.text)
		linha = await roteiro.get_next_dialogue_line(linha.next_id)
	return frases


## Vira a cabeça de Nicholas, devagar, para um ponto do mundo.
func olhar_para(alvo: Vector3, tempo: float) -> void:
	var direcao := alvo - camera.global_position
	var giro_de := corpo.rotation.y
	var giro_para := atan2(-direcao.x, -direcao.z)
	var olhar_de := camera.rotation.x
	var olhar_para_ := clampf(atan2(direcao.y, Vector2(direcao.x, direcao.z).length()), deg_to_rad(-80), deg_to_rad(80))
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float) -> void:
		corpo.rotation.y = lerp_angle(giro_de, giro_para, t)
		camera.rotation.x = lerpf(olhar_de, olhar_para_, t), 0.0, 1.0, maxf(tempo, 0.01))
	await tween.finished


## Põe Nicholas num ponto sem animação (por exemplo, depois de uma tela preta).
func colocar_em(ponto: PontoDeVista) -> void:
	_colocar_em(ponto)


## Devolve o controle ao jogador a partir de um ponto.
func continuar_em(ponto: PontoDeVista) -> void:
	travado = false
	_chegar_em(ponto)


func _chegar_em(ponto: PontoDeVista) -> void:
	ponto_atual = ponto
	_atualizar_dica(ponto)
	tocar_cena(ponto.cena_ao_chegar)
	_ativar_alvos(ponto, true)
	chegou.emit(ponto)


func _atualizar_dica(ponto: PontoDeVista) -> void:
	if dica:
		# Sem brilho para seguir, quem conduz é a SequenciaPrologo.
		if ponto.alvos().is_empty():
			dica.text = ""
		else:
			dica.text = tr("PROLOGO_DICA_TOQUE") if OS.has_feature("mobile") else tr("PROLOGO_DICA_TECLADO")


func _alvo_na_mira() -> AlvoToque:
	var centro := get_viewport().get_visible_rect().size / 2.0
	var origem := camera.project_ray_origin(centro)
	var consulta := PhysicsRayQueryParameters3D.create(origem, origem + camera.project_ray_normal(centro) * 20.0)
	consulta.collide_with_areas = true
	consulta.exclude = [corpo.get_rid()]
	var acerto := get_world_3d().direct_space_state.intersect_ray(consulta)
	if acerto and acerto.collider is AlvoToque and acerto.collider.ativo:
		return acerto.collider
	return null


func _colocar_em(ponto: PontoDeVista) -> void:
	corpo.global_position = _posicao_do_corpo(ponto)
	corpo.rotation.y = _giro(ponto)
	camera.rotation.x = _inclinacao(ponto)


## O PontoDeVista marca onde ficam os olhos; o corpo fica abaixo dele.
func _posicao_do_corpo(ponto: PontoDeVista) -> Vector3:
	return ponto.global_position - Vector3(0.0, camera.position.y, 0.0)


func _giro(ponto: PontoDeVista) -> float:
	var frente := -ponto.global_basis.z
	return atan2(-frente.x, -frente.z)


func _inclinacao(ponto: PontoDeVista) -> float:
	var frente := -ponto.global_basis.z
	return asin(clampf(frente.y, -1.0, 1.0))


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
