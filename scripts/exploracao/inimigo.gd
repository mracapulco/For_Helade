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
## O chão da sala (TileMapLayer): as casas onde ele anda.
@export var grade: TileMapLayer

## Até quantas casas ele procura um caminho.
const LIMITE_BUSCA := 800
## Sem caminho (cercado, tudo ocupado), espera isto antes de procurar de novo.
const ESPERA_SEM_CAMINHO := 0.25

var estado := Estado.PARADO
var alvo: PersonagemExploracao

var _itens: Array[Item] = []
var _atributos := {}
var _tempo := 0.0
var _posicao_visual := Vector2.ZERO
## O aviso (clarear e se erguer) em andamento, para poder cortar.
var _aviso: Tween
## Casa onde ele fica de guarda.
var _posto := Vector2i.ZERO
## Centro da casa para onde está andando, ou INF parado num centro.
var _destino := Vector2.INF
## Casa -> andável, guardado enquanto a navegação da sala não muda.
var _andaveis := {}
var _iteracao_andaveis := -1
## Quanto falta para procurar caminho de novo depois de não achar.
var _espera_caminho := 0.0
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
	return velocidade * Balanceamento.multiplicador_andar(int(_atributos.velocidade))


func casa_de(ponto: Vector2) -> Vector2i:
	return grade.local_to_map(grade.to_local(ponto))


func centro_da_casa(casa: Vector2i) -> Vector2:
	return grade.to_global(grade.map_to_local(casa))


## Chão andável (na navegação da sala) no centro da casa.
func casa_andavel(casa: Vector2i) -> bool:
	var mapa := get_world_2d().navigation_map
	var iteracao := NavigationServer2D.map_get_iteration_id(mapa)
	if iteracao == 0:
		return false
	if iteracao != _iteracao_andaveis:
		_andaveis.clear()
		_iteracao_andaveis = iteracao
	if not _andaveis.has(casa):
		var centro := centro_da_casa(casa)
		_andaveis[casa] = NavigationServer2D.map_get_closest_point(mapa, centro).distance_to(centro) < 2.0
	return _andaveis[casa]


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
				# Um atacante por vez: espera a vez enquanto outro avisa.
				if outro_atacando():
					velocity = Vector2.ZERO
				else:
					_preparar()
			else:
				_comecar_passo(_casas_em_volta_do_alvo())
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
	if _espera_caminho > 0.0:
		_espera_caminho -= get_physics_process_delta_time()
		velocity = Vector2.ZERO
		return
	var livres: Array[Vector2i] = []
	for casa in objetivos:
		if casa_andavel(casa) and GradeOcupacao.livre_para(casa, self):
			livres.append(casa)
	var passo := proximo_passo(casa_de(global_position), livres) if not livres.is_empty() else Vector2i.ZERO
	if passo == Vector2i.ZERO:
		velocity = Vector2.ZERO
		if casa_de(global_position) not in objetivos:
			_espera_caminho = ESPERA_SEM_CAMINHO
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
			# Não procura além de onde ele desistiria de perseguir.
			if centro_da_casa(vizinha).distance_to(global_position) > raio_desistir:
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


## Escolhe a casa atrás do jogador (a do outro lado, na mesma linha da grade) para o golpe pelas
## costas e prepara o leque dourado, escondido. Sem casa livre, golpe normal.
func _preparar_golpe_pelas_costas() -> void:
	var casa_alvo := casa_de(alvo.global_position)
	var passo := casa_alvo - casa_de(global_position)
	var casa := casa_alvo + Vector2i(signi(passo.x), signi(passo.y))
	if casa == casa_alvo or not casa_andavel(casa) or not GradeOcupacao.livre_para(casa, self):
		return
	origem_golpe = centro_da_casa(casa)
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
		var casa := casa_de(origem_golpe)
		if GradeOcupacao.livre_para(casa, self):
			# Salta para trás do jogador: o corpo vai na hora, o desenho chega voando.
			salto = global_position - origem_golpe
			GradeOcupacao.liberar_tudo(self)
			global_position = origem_golpe
			GradeOcupacao.ocupar(casa, self)
			direcao = AvisoNoChao.para_a_tela(_direcao_verdadeira).normalized()
		else:
			origem_golpe = Vector2.INF
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
