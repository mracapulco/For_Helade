class_name MapaHelade
extends Node2D
## Tela de viagem entre os lugares de Hélade, no jeito do mapa do Super Mario
## World: Nicholas fica em cima de um local e anda pelos caminhos até outro.
## Toque/clique num local liberado para ir até ele; toque de novo (ou no botão
## Entrar, ou Enter) para entrar. Setas/WASD pulam para o vizinho naquela direção.

signal chegou(id: String)
signal entrada_pedida(id: String)

const ZOOM_PIXEL_ART := 2.0
## Raio, em pixels da arte, em que um toque conta como "no local".
const RAIO_TOQUE := 24.0
const RAIO_PONTO := 7.0
const COR_ESTRADA := Color(0.9255, 0.7412, 0.4588) # Dourado claro
const COR_MAR := Color(0.6235, 0.7216, 0.8235) # Olhos
const COR_PONTO := Color(0.0745, 0.1451, 0.2353) # Azul noite
const COR_BLOQUEADO := Color(0.3686, 0.4, 0.451) # Pedra fria
const ACOES_DIRECAO := {
	&"mover_frente": Vector2.UP,
	&"mover_tras": Vector2.DOWN,
	&"mover_esquerda": Vector2.LEFT,
	&"mover_direita": Vector2.RIGHT,
}

## Pixels da arte por segundo ao andar pelo mapa.
@export var velocidade := 120.0
## Onde Nicholas começa. Provisório: o jogo salvo ainda não guarda o local.
@export var local_inicial := "olympia"
## Quando falso, Entrar só avisa (testes).
@export var trocar_de_cena := true

@export var fundo: Sprite2D
@export var caminhos: Node2D
@export var nicholas: AnimatedSprite2D
@export var camera: Camera2D
@export var placa: Control
@export var nome_local: Label
@export var regiao_local: Label
@export var aviso: Label
@export var botao_entrar: Button

var grafo: GrafoMapa
## Locais liberados (id -> true).
var liberados: Dictionary = {}
var local_atual := ""
var andando := false

var _viagem: Tween


func _ready() -> void:
	grafo = GrafoMapa.da_pasta()
	for id: String in grafo.locais:
		if grafo.local(id).liberado_no_inicio:
			liberados[id] = true
	caminhos.draw.connect(_desenhar_caminhos)
	botao_entrar.pressed.connect(entrar)
	placa.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	camera.zoom = Vector2.ONE * ZOOM_PIXEL_ART
	if fundo.texture:
		var tamanho := fundo.texture.get_size()
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(tamanho.x)
		camera.limit_bottom = int(tamanho.y)
	colocar_em(local_inicial)


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch and evento.pressed:
		if BotoesToque.toque_em_botao(get_tree(), evento.position):
			return
		var id := local_em(get_canvas_transform().affine_inverse() * evento.position)
		if id.is_empty():
			return
		get_viewport().set_input_as_handled()
		if id == local_atual and not andando:
			entrar()
		else:
			viajar_para(id)
		return
	if evento.is_action_pressed(&"interagir"):
		get_viewport().set_input_as_handled()
		entrar()
		return
	for acao: StringName in ACOES_DIRECAO:
		if evento.is_action_pressed(acao) and not andando:
			var vizinho := grafo.vizinho_na_direcao(local_atual, ACOES_DIRECAO[acao], liberados)
			if not vizinho.is_empty():
				get_viewport().set_input_as_handled()
				viajar_para(vizinho)
			return


## Põe Nicholas direto num local, sem andar.
func colocar_em(id: String) -> void:
	var local := grafo.local(id)
	if local == null:
		push_error("MapaHelade: local desconhecido '%s'." % id)
		return
	local_atual = id
	nicholas.position = local.posicao
	camera.reset_smoothing()
	_parar()


## Local cujo ponto está perto de [param posicao] (pixels da arte), ou "".
func local_em(posicao: Vector2) -> String:
	for id: String in grafo.locais:
		if grafo.local(id).posicao.distance_to(posicao) <= RAIO_TOQUE:
			return id
	return ""


## Anda pelos caminhos até [param destino]. Devolve false se não houver
## caminho por locais liberados.
func viajar_para(destino: String) -> bool:
	if andando or destino == local_atual:
		return false
	var trechos := grafo.caminho(local_atual, destino, liberados)
	if trechos.size() < 2:
		return false
	andando = true
	aviso.text = ""
	placa.hide()
	_viagem = create_tween()
	var anterior := grafo.local(local_atual).posicao
	for i in range(1, trechos.size()):
		var proximo := grafo.local(trechos[i])
		var tempo := anterior.distance_to(proximo.posicao) / velocidade
		_viagem.tween_callback(_olhar_para.bind(proximo.posicao - anterior))
		_viagem.tween_property(nicholas, "position", proximo.posicao, tempo)
		_viagem.tween_callback(_passar_por.bind(trechos[i]))
		anterior = proximo.posicao
	_viagem.tween_callback(_chegar)
	return true


## Termina a viagem na hora (testes, e futuramente "pular animação").
func terminar_viagem() -> void:
	if _viagem and _viagem.is_running():
		_viagem.custom_step(INF)


func entrar() -> void:
	if andando or local_atual.is_empty():
		return
	entrada_pedida.emit(local_atual)
	var cena := grafo.local(local_atual).cena
	if cena.is_empty():
		aviso.text = tr("MAPA_SEM_CENA")
		return
	if trocar_de_cena:
		TrocaCena.ir_para(cena)


func _passar_por(id: String) -> void:
	local_atual = id


func _chegar() -> void:
	andando = false
	_parar()
	chegou.emit(local_atual)


func _parar() -> void:
	var local := grafo.local(local_atual)
	nome_local.text = tr(local.chave_nome)
	regiao_local.text = tr(local.chave_regiao)
	aviso.text = ""
	placa.show()
	var costas := String(nicholas.animation).ends_with("costas")
	nicholas.play(&"parado_costas" if costas else &"parado_frente")


func _olhar_para(rumo: Vector2) -> void:
	if rumo.x != 0.0:
		nicholas.flip_h = rumo.x < 0.0
	nicholas.play(&"andando_costas" if rumo.y < 0.0 else &"andando_frente")


func _desenhar_caminhos() -> void:
	for par: Array in grafo.ligacoes():
		var a := grafo.local(par[0]).posicao
		var b := grafo.local(par[1]).posicao
		var aberto := liberados.has(par[0]) and liberados.has(par[1])
		var cor: Color = COR_MAR if par[2] else COR_ESTRADA
		if not aberto:
			cor = COR_BLOQUEADO
		if par[2]:
			caminhos.draw_dashed_line(a, b, cor, 2.0, 6.0)
		else:
			caminhos.draw_line(a, b, cor, 2.0)
	for id: String in grafo.locais:
		var local := grafo.local(id)
		var contorno := COR_ESTRADA if liberados.has(id) else COR_BLOQUEADO
		caminhos.draw_circle(local.posicao, RAIO_PONTO, COR_PONTO)
		caminhos.draw_circle(local.posicao, RAIO_PONTO, contorno, false, 2.0)
