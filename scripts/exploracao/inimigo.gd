class_name Inimigo
extends CharacterBody2D
## Inimigo provisório da exploração: fica parado até ver o jogador, vai atrás
## dele de casa em casa do chão (como o Nicholas, nas linhas, colunas e
## diagonais da grade), desviando dos obstáculos, e, quando está numa casa
## vizinha, avisa (pisca e se ergue) e golpeia. Cada casa tem um personagem
## só (GradeOcupacao): dois inimigos nunca ficam um em cima do outro. Usa as mesmas regras do jogador: itens do Inventario
## como equipamento (Balanceamento), Vida e ReacaoAoGolpe.
## Quando o jogador foge para longe, volta para o lugar onde estava.
## Ao morrer some aos poucos e deixa moedas.

signal golpeou
signal morreu

## Grupo dos inimigos vivos (o Nicholas sabe que está em combate).
const GRUPO := &"inimigos"

enum Estado { PARADO, PERSEGUINDO, PREPARANDO, DESCANSANDO, VOLTANDO, MORTO }

## Ids de itens (data/itens/) que ele usa: arma, escudo, armadura, elmo.
@export var equipamento: Array[String] = []
## Velocidade de andar sem equipamento.
@export var velocidade := 60.0
## Começa a perseguir quando o jogador chega a esta distância...
@export var raio_visao := 150.0
## ...e desiste quando ele passa desta.
@export var raio_desistir := 260.0
## Tempo do aviso antes do golpe (dá para fugir ou bater antes).
@export var preparo := 0.45
## Descanso depois de cada golpe.
@export var intervalo := 1.0
## Moedas que deixa ao morrer.
@export var moedas := 0
## Experiência que dá a quem o derrota (Experiencia). Lutar é opcional:
## o nível da história vem garantido.
@export var experiencia := 0

@export var visual: Node2D
@export var vida: Vida
@export var reacao: ReacaoAoGolpe
## O chão da sala (TileMapLayer): as casas onde ele anda.
@export var grade: TileMapLayer

## Até quantas casas ele procura um caminho.
const LIMITE_BUSCA := 800

var estado := Estado.PARADO
var alvo: PersonagemExploracao

var _itens: Array[Item] = []
var _atributos := {}
var _tempo := 0.0
var _posicao_visual := Vector2.ZERO
## Casa onde ele fica de guarda.
var _posto := Vector2i.ZERO
## Centro da casa para onde está andando, ou INF parado num centro.
var _destino := Vector2.INF


func _ready() -> void:
	add_to_group(GRUPO)
	for id in equipamento:
		var item := Inventario.item(id)
		if item:
			_itens.append(item)
		else:
			push_error("Inimigo: item desconhecido '%s'." % id)
	_atributos = Balanceamento.somar(_itens)
	if vida:
		vida.defesa += int(_atributos.defesa)
		vida.morreu.connect(_morrer)
	if visual:
		_posicao_visual = visual.position
	# Quem separa os personagens é a grade, não a física.
	collision_layer = 0
	collision_mask = 0
	if grade == null:
		push_error("Inimigo '%s' sem grade." % name)
		return
	_posto = casa_de(global_position)
	global_position = centro_da_casa(_posto)
	GradeOcupacao.ocupar(_posto, self)


func _exit_tree() -> void:
	GradeOcupacao.liberar_tudo(self)


## Ataque, defesa e velocidade do equipamento (com o ataque base).
func atributos() -> Dictionary:
	return _atributos


func velocidade_andando() -> float:
	return velocidade * Balanceamento.multiplicador_velocidade(int(_atributos.velocidade))


func casa_de(ponto: Vector2) -> Vector2i:
	return grade.local_to_map(grade.to_local(ponto))


func centro_da_casa(casa: Vector2i) -> Vector2:
	return grade.to_global(grade.map_to_local(casa))


## Chão andável (na navegação da sala) no centro da casa.
func casa_andavel(casa: Vector2i) -> bool:
	var mapa := get_world_2d().navigation_map
	if NavigationServer2D.map_get_iteration_id(mapa) == 0:
		return false
	var centro := centro_da_casa(casa)
	return NavigationServer2D.map_get_closest_point(mapa, centro).distance_to(centro) < 2.0


## Está numa casa vizinha à do jogador (nas 8 direções).
func vizinho_do_alvo() -> bool:
	return _vizinhas(casa_de(global_position), casa_de(alvo.global_position))


func andando() -> bool:
	return _destino != Vector2.INF


func _physics_process(delta: float) -> void:
	if estado == Estado.MORTO or grade == null:
		return
	if andando():
		_dar_passo(delta)
		return
	if alvo == null or not is_instance_valid(alvo):
		alvo = _procurar_jogador()
		if alvo == null:
			return
	if alvo.em_dialogo:
		_parar()
		return
	var distancia := global_position.distance_to(alvo.global_position)
	match estado:
		Estado.PARADO:
			if distancia <= raio_visao:
				estado = Estado.PERSEGUINDO
		Estado.VOLTANDO:
			if distancia <= raio_visao:
				estado = Estado.PERSEGUINDO
			elif casa_de(global_position) == _posto:
				_parar()
			else:
				_comecar_passo([_posto])
		Estado.PERSEGUINDO:
			if distancia > raio_desistir:
				estado = Estado.VOLTANDO
			elif vizinho_do_alvo():
				_preparar()
			else:
				_comecar_passo(_casas_em_volta_do_alvo())
		Estado.PREPARANDO:
			_tempo += delta
			if _tempo >= preparo:
				_golpear()
		Estado.DESCANSANDO:
			_tempo += delta
			if _tempo >= intervalo:
				estado = Estado.PERSEGUINDO
	_virar()


static func _vizinhas(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1


func _casas_em_volta_do_alvo() -> Array[Vector2i]:
	var centro := casa_de(alvo.global_position)
	var casas: Array[Vector2i] = []
	for passo in PersonagemExploracao.PASSOS:
		casas.append(centro + passo)
	return casas


## Dá o primeiro passo do caminho mais curto até uma das [param objetivos].
## Sem caminho (tudo ocupado), espera.
func _comecar_passo(objetivos: Array[Vector2i]) -> void:
	var passo := proximo_passo(casa_de(global_position), objetivos)
	if passo == Vector2i.ZERO:
		velocity = Vector2.ZERO
		return
	var proxima := casa_de(global_position) + passo
	if not GradeOcupacao.ocupar(proxima, self):
		return
	_destino = centro_da_casa(proxima)
	velocity = global_position.direction_to(_destino) * velocidade_andando()


func _dar_passo(delta: float) -> void:
	global_position = global_position.move_toward(_destino, velocidade_andando() * delta)
	_virar()
	if global_position == _destino:
		_destino = Vector2.INF
		velocity = Vector2.ZERO
		GradeOcupacao.liberar_tudo(self)
		GradeOcupacao.ocupar(casa_de(global_position), self)


## Busca em largura pelas casas livres e andáveis: o passo (uma das 8
## vizinhas) que leva mais rápido a uma das [param objetivos]. ZERO se já
## estiver numa delas ou se não houver caminho.
func proximo_passo(inicio: Vector2i, objetivos: Array[Vector2i]) -> Vector2i:
	if inicio in objetivos:
		return Vector2i.ZERO
	var de_onde := {inicio: inicio}
	var fila: Array[Vector2i] = [inicio]
	var lidas := 0
	while not fila.is_empty() and lidas < LIMITE_BUSCA:
		var casa: Vector2i = fila.pop_front()
		lidas += 1
		for passo in PersonagemExploracao.PASSOS:
			var vizinha: Vector2i = casa + passo
			if de_onde.has(vizinha) or not _pode_entrar(casa, passo):
				continue
			de_onde[vizinha] = casa
			if vizinha in objetivos:
				while de_onde[vizinha] != inicio:
					vizinha = de_onde[vizinha]
				return vizinha - inicio
			fila.append(vizinha)
	return Vector2i.ZERO


## Pode ir de [param casa] para a vizinha em [param passo]: ela é chão livre
## e, na diagonal da grade, não corta o canto de um obstáculo.
func _pode_entrar(casa: Vector2i, passo: Vector2i) -> bool:
	var vizinha := casa + passo
	if not casa_andavel(vizinha) or not GradeOcupacao.livre_para(vizinha, self):
		return false
	if passo.x != 0 and passo.y != 0:
		return casa_andavel(casa + Vector2i(passo.x, 0)) and casa_andavel(casa + Vector2i(0, passo.y))
	return true


## Olha para onde anda ou, parado no combate, para o jogador.
func _virar() -> void:
	if not visual is Sprite2D:
		return
	var desenho := visual as Sprite2D
	if absf(velocity.x) > 1.0:
		desenho.flip_h = velocity.x < 0.0
	elif alvo and (estado == Estado.PREPARANDO or estado == Estado.DESCANSANDO):
		desenho.flip_h = alvo.global_position.x < global_position.x


func _procurar_jogador() -> PersonagemExploracao:
	for no in get_tree().get_nodes_in_group(Interagivel.GRUPO_JOGADOR):
		if no is PersonagemExploracao:
			return no
	return null


func _parar() -> void:
	estado = Estado.PARADO
	velocity = Vector2.ZERO


func _preparar() -> void:
	estado = Estado.PREPARANDO
	_tempo = 0.0
	velocity = Vector2.ZERO
	if visual:
		# Aviso: clareia e se ergue um pouco antes de bater.
		var aviso := create_tween().set_parallel()
		aviso.tween_property(visual, "modulate", Color(1.5, 1.4, 1.2), preparo * 0.5)
		aviso.tween_property(visual, "position", _posicao_visual + Vector2(0, -3), preparo * 0.8)


func _golpear() -> void:
	estado = Estado.DESCANSANDO
	_tempo = 0.0
	golpeou.emit()
	var direcao := global_position.direction_to(alvo.global_position)
	if visual:
		var bote := create_tween()
		bote.tween_property(visual, "modulate", Color.WHITE, 0.0)
		bote.tween_property(visual, "position", _posicao_visual + direcao * 5.0, 0.06)
		bote.tween_property(visual, "position", _posicao_visual, 0.15)
	if vizinho_do_alvo():
		var reacao_alvo := alvo.get_node_or_null("ReacaoAoGolpe") as ReacaoAoGolpe
		if reacao_alvo:
			reacao_alvo.receber_golpe(direcao, int(_atributos.ataque))


func _morrer() -> void:
	estado = Estado.MORTO
	velocity = Vector2.ZERO
	remove_from_group(GRUPO)
	GradeOcupacao.liberar_tudo(self)
	if reacao:
		reacao.remove_from_group(ReacaoAoGolpe.GRUPO)
	if moedas > 0:
		Inventario.ganhar_dinheiro(moedas)
	if experiencia > 0:
		Experiencia.ganhar(_quem_ganha(), experiencia)
	morreu.emit()
	var sumir := create_tween()
	sumir.tween_interval(0.35)
	sumir.tween_property(self, "modulate:a", 0.0, 0.5)
	sumir.tween_callback(queue_free)


## Quem leva a experiência: o jogador (Nicholas, por padrão).
func _quem_ganha() -> String:
	var jogador := get_tree().get_first_node_in_group(Interagivel.GRUPO_JOGADOR)
	if jogador and "id_inventario" in jogador:
		return str(jogador.id_inventario)
	return "nicholas"
