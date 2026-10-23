class_name Inimigo
extends CharacterBody2D
## Inimigo provisório da exploração: fica parado até ver o jogador, vai atrás
## dele andando livre pelo chão (pela navegação da sala, desviando dos
## obstáculos; fora da grade desde 23/10, P3b) e, quando chega perto, avisa
## no chão e golpeia. Os inimigos se afastam uns dos outros e do jogador, para
## ninguém ficar em cima de ninguém. Usa as mesmas regras do jogador: itens do
## Inventario como equipamento (Balanceamento), Vida e ReacaoAoGolpe.
## Quando o jogador foge para longe, volta para o lugar onde estava.
## Ao morrer some aos poucos e deixa moedas.

signal golpeou
signal morreu
## Começou a preparar um golpe (o aviso apareceu no chão).
signal comecou_a_preparar

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
## Tempo do aviso antes do golpe (dá para fugir ou bater antes). 0,6 s
## (Rafael, 23/10; P3): o aviso aparece no chão e enche até o golpe.
@export var preparo := 0.6
## Descanso depois de cada golpe.
@export var intervalo := 1.0
## Começo do descanso em que ele fica "cansado" (mais escuro): a hora de
## bater nele.
@export var cansaco := 0.6
## Até onde o golpe dele pega, em pixels do chão (o leque do aviso).
@export var alcance_golpe := 72.0
## Abertura do golpe dele, em graus.
@export var arco_golpe := 120.0
## Chegando a esta distância do jogador (em pixels do chão), para e avisa o golpe.
@export var distancia_ataque := 44.0
## Protótipo do Tic. Tac. (Rafael, 23/10; P4): o aviso no chão é uma finta;
## na hora do golpe ele salta para trás do jogador e bate pelas costas, como
## Persephone em V2 c20 ("cruzou por trás, a fim de acertá-lo nas costas").
@export var golpe_pelas_costas := false
## Ao preparar o golpe, pode trazer o Tic. Tac. ao Nicholas (TicTac).
@export var provoca_tic_tac := false
## Moedas que deixa ao morrer.
@export var moedas := 0
## Experiência que dá a quem o derrota (Experiencia). Lutar é opcional:
## o nível da história vem garantido.
@export var experiencia := 0

@export var visual: Node2D
@export var vida: Vida
@export var reacao: ReacaoAoGolpe
## O chão da sala (TileMapLayer). Não é mais usado para andar (ele anda
## livre desde 23/10); fica para as cenas que já o ligam.
@export var grade: TileMapLayer

## Raio do corpo, na tela: dois inimigos não chegam mais perto que o dobro disto.
const RAIO_CORPO := 11.0
## Quanto o caminho é recalculado (segundos), ou antes, se o alvo andar muito.
const RECALCULAR_CAMINHO := 0.25
## Chegou ao ponto do caminho quando está a menos disto.
const CHEGOU := 3.0
## Distância atrás do jogador, no chão, para onde salta o golpe pelas costas.
const DISTANCIA_COSTAS := 40.0

var estado := Estado.PARADO
var alvo: PersonagemExploracao

var _itens: Array[Item] = []
var _atributos := {}
var _tempo := 0.0
var _posicao_visual := Vector2.ZERO
## O aviso (clarear e se erguer) em andamento, para poder cortar.
var _aviso: Tween
## Onde ele fica de guarda (volta para cá quando desiste).
var _posto := Vector2.ZERO
## Caminho que está seguindo (pontos no mundo) e para onde ele leva.
var _caminho := PackedVector2Array()
var _destino_caminho := Vector2.INF
var _desde_o_caminho := 0.0
## Aviso no chão do golpe que está preparando (null fora do preparo).
var aviso_no_chao: AvisoNoChao
## Para onde vai o golpe que está preparando, no chão (fica fixo no aviso).
var _direcao_golpe := Vector2.RIGHT
## Golpe pelas costas: o leque dourado da área de verdade. Escondido; só o
## Tic. Tac. mostra (null sem golpe pelas costas).
var aviso_verdadeiro: AvisoNoChao
## De onde sai o golpe pelas costas (atrás do jogador), ou INF sem ele.
var origem_golpe := Vector2.INF
var _direcao_verdadeira := Vector2.RIGHT



func _ready() -> void:
	add_to_group(GRUPO)
	# Anda na física: a imagem interpola entre os passos (Configuracoes).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
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
	# Quem separa os personagens é o afastamento ([method _afastamento]), não a física.
	collision_layer = 0
	collision_mask = 0
	_posto = global_position


## Ataque, defesa e velocidade do equipamento (com o ataque base).
func atributos() -> Dictionary:
	return _atributos


func velocidade_andando() -> float:
	return velocidade * Balanceamento.multiplicador_andar(int(_atributos.velocidade))


func casa_de(ponto: Vector2) -> Vector2i:
	return grade.local_to_map(grade.to_local(ponto))


func centro_da_casa(casa: Vector2i) -> Vector2:
	return grade.to_global(grade.map_to_local(casa))


## Chegou perto do jogador o bastante para avisar o golpe.
func perto_do_alvo() -> bool:
	return alvo != null and AvisoNoChao.para_o_chao(alvo.global_position - global_position).length() <= distancia_ataque


## Ponto do chão andável mais perto de [param ponto] (ou o próprio ponto, sem navegação pronta).
func ponto_andavel(ponto: Vector2) -> Vector2:
	var mapa := get_world_2d().navigation_map
	if NavigationServer2D.map_get_iteration_id(mapa) == 0:
		return ponto
	return NavigationServer2D.map_get_closest_point(mapa, ponto)


## [param ponto] cai no chão andável (fora dos obstáculos)?
func andavel(ponto: Vector2) -> bool:
	var mapa := get_world_2d().navigation_map
	return NavigationServer2D.map_get_iteration_id(mapa) != 0 \
		and NavigationServer2D.map_get_closest_point(mapa, ponto).distance_to(ponto) < 2.0


func _physics_process(delta: float) -> void:
	if estado == Estado.MORTO:
		return
	if alvo == null or not is_instance_valid(alvo):
		alvo = _procurar_jogador()
		if alvo == null:
			return
	if alvo.em_dialogo:
		_parar()
		return
	var distancia := global_position.distance_to(alvo.global_position)
	var rumo := Vector2.ZERO
	match estado:
		Estado.PARADO:
			if distancia <= raio_visao:
				estado = Estado.PERSEGUINDO
		Estado.VOLTANDO:
			if distancia <= raio_visao:
				estado = Estado.PERSEGUINDO
			elif global_position.distance_to(_posto) <= CHEGOU:
				_parar()
			else:
				rumo = _rumo_ate(_posto, delta)
		Estado.PERSEGUINDO:
			if distancia > raio_desistir:
				estado = Estado.VOLTANDO
			elif perto_do_alvo():
				# Um atacante por vez: espera a vez enquanto outro avisa.
				if not outro_atacando():
					_preparar()
			else:
				rumo = _rumo_ate(_ponto_de_ataque(), delta)
		Estado.PREPARANDO:
			_tempo += delta
			if aviso_no_chao:
				aviso_no_chao.progresso = clampf(_tempo / preparo, 0.0, 1.0)
			if aviso_verdadeiro:
				aviso_verdadeiro.progresso = clampf(_tempo / preparo, 0.0, 1.0)
			if _tempo >= preparo:
				_golpear()
		Estado.DESCANSANDO:
			_tempo += delta
			if _tempo >= intervalo:
				estado = Estado.PERSEGUINDO
	_andar(rumo, delta)
	_virar()


## Ponto onde ele quer ficar para bater: um pouco antes da distância de
## ataque, do lado de onde ele vem.
func _ponto_de_ataque() -> Vector2:
	var lado := AvisoNoChao.para_o_chao(global_position - alvo.global_position).normalized()
	if lado == Vector2.ZERO:
		lado = Vector2.RIGHT
	return alvo.global_position + AvisoNoChao.para_a_tela(lado * distancia_ataque * 0.8)


## Direção (normalizada) do próximo trecho do caminho até [param destino].
## O caminho vem da navegação da sala e é refeito de tempos em tempos.
func _rumo_ate(destino: Vector2, delta: float) -> Vector2:
	_desde_o_caminho += delta
	if _caminho.is_empty() or _desde_o_caminho >= RECALCULAR_CAMINHO \
			or _destino_caminho.distance_to(destino) > 16.0:
		_desde_o_caminho = 0.0
		_destino_caminho = destino
		var mapa := get_world_2d().navigation_map
		_caminho = NavigationServer2D.map_get_path(mapa, global_position, destino, true) \
			if NavigationServer2D.map_get_iteration_id(mapa) != 0 else PackedVector2Array([destino])
	while not _caminho.is_empty() and global_position.distance_to(_caminho[0]) <= CHEGOU:
		_caminho.remove_at(0)
	if _caminho.is_empty():
		return Vector2.ZERO
	return global_position.direction_to(_caminho[0])


## Anda na direção [param rumo] (ou fica, com ZERO), afastado dos outros, e
## nunca sai do chão andável.
func _andar(rumo: Vector2, delta: float) -> void:
	var rapidez := velocidade_andando()
	velocity = rumo * rapidez
	if estado != Estado.PREPARANDO:
		velocity += _afastamento() * rapidez
	velocity = _sem_encostar(velocity).limit_length(rapidez)
	if velocity.length() < 1.0:
		velocity = Vector2.ZERO
		return
	global_position = ponto_andavel(global_position + velocity * delta)


## Empurrão para longe de outros inimigos e do jogador quando chegam perto
## demais (0 longe; até 1 encostado).
func _afastamento() -> Vector2:
	var soma := Vector2.ZERO
	var outros: Array = get_tree().get_nodes_in_group(GRUPO)
	if alvo:
		outros.append(alvo)
	for no in outros:
		var outro := no as Node2D
		if outro == null or outro == self:
			continue
		var de_la := global_position - outro.global_position
		var perto := RAIO_CORPO * 2.0
		if de_la.length() < perto:
			var direcao := de_la.normalized() if de_la.length() > 0.01 else Vector2.RIGHT.rotated(get_instance_id() % 628 / 100.0)
			soma += direcao * (1.0 - de_la.length() / perto)
	return soma


## Tira de [param rumo] a parte que vai na direção de quem já está encostado
## (outro inimigo ou o jogador): ninguém entra no corpo de ninguém.
func _sem_encostar(rumo: Vector2) -> Vector2:
	var outros: Array = get_tree().get_nodes_in_group(GRUPO)
	if alvo:
		outros.append(alvo)
	for no in outros:
		var outro := no as Node2D
		if outro == null or outro == self:
			continue
		var ate_la := outro.global_position - global_position
		if ate_la.length() < RAIO_CORPO * 2.0 and ate_la.length() > 0.01:
			var direcao := ate_la.normalized()
			var indo := rumo.dot(direcao)
			if indo > 0.0:
				rumo -= direcao * indo
	return rumo


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
	_tirar_aviso()


## Outro inimigo está avisando um golpe agora (um atacante por vez).
func outro_atacando() -> bool:
	for no in get_tree().get_nodes_in_group(GRUPO):
		if no != self and no is Inimigo and (no as Inimigo).estado == Estado.PREPARANDO:
			return true
	return false


## O golpe que ele prepara agora pega quem está em [param ponto]?
func golpe_pega(ponto: Vector2) -> bool:
	if origem_golpe != Vector2.INF:
		return AvisoNoChao.atinge(origem_golpe, _direcao_verdadeira, ponto, alcance_golpe, arco_golpe)
	return AvisoNoChao.atinge(global_position, _direcao_golpe, ponto, alcance_golpe, arco_golpe)


func _tirar_aviso() -> void:
	if aviso_no_chao:
		aviso_no_chao.queue_free()
		aviso_no_chao = null
	if aviso_verdadeiro:
		aviso_verdadeiro.queue_free()
		aviso_verdadeiro = null


func _preparar() -> void:
	estado = Estado.PREPARANDO
	_tempo = 0.0
	velocity = Vector2.ZERO
	# O golpe vai para onde o jogador está agora e fica fixo: dá para sair.
	_direcao_golpe = AvisoNoChao.para_o_chao(alvo.global_position - global_position).normalized()
	if _direcao_golpe == Vector2.ZERO:
		_direcao_golpe = Vector2.RIGHT
	_tirar_aviso()
	aviso_no_chao = AvisoNoChao.new()
	aviso_no_chao.name = "AvisoNoChao"
	aviso_no_chao.raio = alcance_golpe
	aviso_no_chao.arco = arco_golpe
	aviso_no_chao.direcao = _direcao_golpe
	add_child(aviso_no_chao)
	origem_golpe = Vector2.INF
	if golpe_pelas_costas:
		_preparar_golpe_pelas_costas()
	if visual:
		# Aviso: clareia e se ergue um pouco antes de bater.
		_aviso = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel()
		_aviso.tween_property(visual, "modulate", Color(1.5, 1.4, 1.2), preparo * 0.5)
		_aviso.tween_property(visual, "position", _posicao_visual + Vector2(0, -3), preparo * 0.8)
	comecou_a_preparar.emit()
	if provoca_tic_tac:
		TicTac.de(alvo).talvez(self)


## Escolhe o ponto atrás do jogador (do outro lado dele) para o golpe pelas
## costas e prepara o leque dourado, escondido. Sem chão ali, golpe normal.
func _preparar_golpe_pelas_costas() -> void:
	var ponto := alvo.global_position + AvisoNoChao.para_a_tela(_direcao_golpe * DISTANCIA_COSTAS)
	if not andavel(ponto):
		return
	origem_golpe = ponto
	_direcao_verdadeira = AvisoNoChao.para_o_chao(alvo.global_position - origem_golpe).normalized()
	aviso_verdadeiro = AvisoNoChao.new()
	aviso_verdadeiro.name = "AvisoVerdadeiro"
	aviso_verdadeiro.raio = alcance_golpe
	aviso_verdadeiro.arco = arco_golpe
	aviso_verdadeiro.direcao = _direcao_verdadeira
	aviso_verdadeiro.cor = AvisoNoChao.COR_DOURADA
	aviso_verdadeiro.visible = false
	add_child(aviso_verdadeiro)
	aviso_verdadeiro.top_level = true
	aviso_verdadeiro.global_position = origem_golpe


## Levou o golpe forte (o terceiro do combo do Nicholas): se estava se
## preparando para bater, perde o golpe e descansa (Rafael, 23/10; P2).
func interromper() -> void:
	if estado != Estado.PREPARANDO:
		return
	estado = Estado.DESCANSANDO
	_tempo = 0.0
	_tirar_aviso()
	origem_golpe = Vector2.INF
	if _aviso:
		_aviso.kill()
	if visual:
		visual.modulate = Color.WHITE
		visual.position = _posicao_visual


func _golpear() -> void:
	estado = Estado.DESCANSANDO
	_tempo = 0.0
	golpeou.emit()
	_tirar_aviso()
	var direcao := AvisoNoChao.para_a_tela(_direcao_golpe).normalized()
	var salto := Vector2.ZERO
	if origem_golpe != Vector2.INF:
		# Salta para trás do jogador: o corpo vai na hora, o desenho chega voando.
		salto = global_position - origem_golpe
		global_position = origem_golpe
		direcao = AvisoNoChao.para_a_tela(_direcao_verdadeira).normalized()
	if visual:
		var bote := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		bote.tween_property(visual, "modulate", Color.WHITE, 0.0)
		if salto != Vector2.ZERO:
			visual.position = _posicao_visual + salto
			bote.tween_property(visual, "position", _posicao_visual, 0.08)
		bote.tween_property(visual, "position", _posicao_visual + direcao * 5.0, 0.06)
		bote.tween_property(visual, "position", _posicao_visual, 0.15)
		# Cansado: mais escuro por um instante, a hora de bater nele.
		bote.tween_property(visual, "modulate", Color(0.65, 0.7, 0.85), 0.05)
		bote.tween_interval(maxf(cansaco - 0.26, 0.0))
		bote.tween_property(visual, "modulate", Color.WHITE, 0.15)
	# O dano só existe agora, na área que o aviso mostrou (Rafael, 23/10; P3).
	if golpe_pega(alvo.global_position) and not _esquivando(alvo):
		var reacao_alvo := alvo.get_node_or_null("ReacaoAoGolpe") as ReacaoAoGolpe
		if reacao_alvo:
			reacao_alvo.receber_golpe(global_position.direction_to(alvo.global_position), int(_atributos.ataque))
	origem_golpe = Vector2.INF


## O jogador está invulnerável (no começo da esquiva).
static func _esquivando(quem: Node) -> bool:
	return quem.has_method("invulneravel") and quem.invulneravel()


func _morrer() -> void:
	estado = Estado.MORTO
	velocity = Vector2.ZERO
	remove_from_group(GRUPO)
	_tirar_aviso()
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
