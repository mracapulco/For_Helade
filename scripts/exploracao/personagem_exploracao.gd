class_name PersonagemExploracao
extends CharacterBody2D
## Personagem da exploração.
## Clicar ou tocar no chão não anda (Rafael, 14/10: ficou ruim; o celular
## terá outro controle depois). Clicar ou tocar num interagível ao alcance
## interage com ele. Mouse e toque passam pelo mesmo caminho (o projeto emula
## toque com o mouse).
## Teclado (PC): WASD ou setas para andar, Shift para correr, Espaço para pular,
## E para interagir com o interagível mais próximo ao alcance.
## Golpe: com uma arma equipada, o clique esquerdo (ou o botão Golpe, no
## celular) golpeia para onde ele olha. Sem arma, com um inimigo vivo
## por perto ([member raio_combate]), o mesmo clique dá um soco (ataque base). No PC o clique só golpeia e o Enter
## só interage (Rafael, 15/10): o clique nunca anda nem interage. Quem estiver
## perto, na frente dele, reage ao golpe (ReacaoAoGolpe) e perde vida se
## tiver uma.
## O equipamento muda o personagem (Balanceamento): o ataque do golpe, o
## alcance da arma e a velocidade de andar e de golpear. Poções de rapidez
## (EfeitosTemporarios) somam velocidade por um tempo.
## Derrota: quando a [member vida] chega a zero, ele volta para onde entrou
## na cena, com a vida cheia, sem perder nada.
## Tocar num Interagivel: anda até ele e interage ao chegar.
## Durante uma conversa o personagem fica parado e ignora toques e teclas.
## Na grade, cada casa tem um personagem só (GradeOcupacao): ele não entra
## na casa de um inimigo, e o golpe pega só quem está na casa da frente (a
## flecha, o primeiro da linha).
## Com uma [member grade], ele anda de casa em casa do chão e sempre para no
## centro de uma casa, pelo teclado ou pelo toque; assim fica claro quando
## está alinhado com alguém.

signal destino_definido(destino: Vector2)
signal chegou
## Começou um golpe, para onde ele está olhando.
signal golpeou
## O golpe chegou ao corte e pegou estes alvos (pode ser vazio).
signal acertou(alvos: Array[ReacaoAoGolpe])
## A vida chegou a zero; ele já voltou ao ponto de entrada.
signal derrotado

## As 8 casas vizinhas, no sistema de casas do chão.
const PASSOS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1),
]

## Velocidade de andar sem equipamento. O equipamento aumenta ou diminui
## (veja [method velocidade_andando]). 120 = cerca de 0,3 s por casa do chão
## (Rafael, 19/10: com 90 o passo parecia travado).
@export var velocidade := 120.0
## Quanto mais rápido fica ao correr.
@export var multiplicador_corrida := 1.5
## Camada do chão cujas casas o movimento segue. Sem ela, anda livre.
@export var grade: TileMapLayer
@export var altura_pulo := 20.0
@export var duracao_pulo := 0.45
## Id do personagem no Inventario, para saber se está armado.
@export var id_inventario := "nicholas"
## Quanto dura um golpe (o tempo da animação) sem bônus de velocidade.
## Enquanto isso ele não anda.
@export var duracao_golpe := 0.35
## Quando o corte acontece dentro do golpe (o quadro com o rastro).
@export var momento_do_corte := 0.12
## Até onde o golpe pega, a partir dos pés dele, em pixels, quando a arma
## não tem alcance próprio.
@export var alcance_golpe := 40.0
## Sem arma, o clique dá soco quando há um inimigo vivo a esta distância.
@export var raio_combate := 200.0
## Com [member grade], parado e em combate: apertar uma direção diferente da
## que ele olha só vira o corpo; segurando a tecla por este tempo (ou
## apertando de novo), anda. Fora de combate anda na hora (Rafael, 19/10).
## Andando, trocar de direção vira e segue sem pausa.
@export var tempo_para_andar := 0.12
## Tempo sem andar para contar como parado (e o primeiro aperto só virar).
@export var tempo_para_parar := 0.15
## Vida do personagem (opcional). Sem ela, não há derrota.
@export var vida: Vida
## A vida máxima vem da fase da vida (Inventario.fase()) mais o nível
## (Experiencia) e muda quando ele cresce ou sobe de nível. Desligado,
## vale o máximo posto na [member vida].
@export var vida_pela_idade := true
## Efeitos de poções (opcional): a rapidez soma na velocidade.
@export var efeitos: EfeitosTemporarios

var andando := false
var pulando := false
var golpeando := false
## Para onde ele olha: a última direção em que andou (começa olhando para
## baixo e para a direita, como o desenho).
var direcao_olhar := Vector2(2, 1).normalized()
## Verdadeiro enquanto uma conversa está aberta.
var em_dialogo := false
## Interagível para onde o personagem está indo, se houver.
var alvo_interacao: Interagivel

var _tempo_pulo := 0.0
var _tempo_golpe := 0.0
## Centro da casa para onde está indo pelo teclado (INF = nenhuma).
var _casa_destino := Vector2.INF
var _casa_origem := Vector2.ZERO
## O passo (casa vizinha) do andar pelo teclado em andamento.
var _passo_atual := Vector2i.ZERO
## Direção apertada depois da metade do passo: vale quando ele chegar.
var _passo_guardado := Vector2i.ZERO
## Multiplica a velocidade do passo em andamento (2 = voltando de um toque curto).
var _pressa := 1.0
## O passo em andamento vai até o fim mesmo sem tecla (veio de uma direção
## guardada).
var _passo_firme := false
var _golpe_pendente := false
## Quanto falta segurar a tecla, depois de virar, para começar a andar.
var _espera_virar := 0.0
## Há quanto tempo ele não anda (sem passo em andamento).
var _tempo_parado := 1.0
## Multiplicador de velocidade do equipamento e das poções (1 = sem bônus).
var _ritmo := 1.0
## O mesmo, para andar: o peso do equipamento tem limite menor
## ([constant Balanceamento.VELOCIDADE_MINIMA_ANDAR]).
var _ritmo_andar := 1.0
## Onde ele estava no fim do último quadro de física, para notar quando foi
## levado de um lugar para outro (troca de sala, derrota, roteiro).
var _posicao_anterior := Vector2.INF
## Onde ele entrou na cena: volta para cá ao ser derrotado.
var _ponto_de_entrada := Vector2.ZERO

@onready var agente: NavigationAgent2D = $Agente
@onready var corpo: Node2D = $Corpo
@onready var sombra: Node2D = $Sombra


## Mais que isto entre dois quadros de física é um salto, não um passo.
const DISTANCIA_SALTO := 24.0
## Golpear andando: o passo termina em no máximo este tempo e o golpe sai.
const TEMPO_ATE_GOLPE := 0.08


func _ready() -> void:
	add_to_group(Interagivel.GRUPO_JOGADOR)
	# Anda na física: a imagem (e a câmera, filha dele) interpola entre os
	# quadros de física, liso em monitores de 120 ou 240 Hz (Configuracoes).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	Inventario.equipamento_mudou.connect(_ao_mudar_equipamento)
	Inventario.faixa_etaria_mudou.connect(_ao_mudar_idade)
	Experiencia.subiu.connect(_ao_subir_de_nivel)
	if efeitos:
		efeitos.mudou.connect(_atualizar_ritmo)
	if vida:
		vida.morreu.connect(_ao_ser_derrotado)
	_ponto_de_entrada = global_position
	_atualizar_vida_maxima()
	_atualizar_ritmo()


func _unhandled_input(event: InputEvent) -> void:
	if em_dialogo:
		return
	var na_tela: bool = event is InputEventScreenTouch or event is InputEventScreenDrag
	if na_tela and BotoesToque.toque_em_botao(get_tree(), event.position):
		return
	# No PC o clique só golpeia e o Enter só interage (Rafael, 15/10): o
	# toque que o Godot cria a partir do mouse não anda nem interage.
	var do_mouse: bool = na_tela and event.device == InputEvent.DEVICE_ID_EMULATION
	if do_mouse:
		get_viewport().set_input_as_handled()
		return
	var toque: bool = event is InputEventScreenTouch and event.pressed
	if toque:
		tocar(tela_para_mundo(event.position))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("golpear") and pode_golpear():
		golpear()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pular"):
		pular()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interagir"):
		var alvo := interagivel_ao_alcance()
		if alvo:
			interagir_com(alvo)
			get_viewport().set_input_as_handled()


## Converte uma posição na tela para a posição no mundo, levando a câmera em conta.
func tela_para_mundo(posicao_tela: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * posicao_tela


## O jogador tocou neste ponto do mundo: interage se for um Interagivel ao
## alcance. Tocar no chão não faz nada.
func tocar(posicao_mundo: Vector2) -> void:
	var alvo := interagivel_em(posicao_mundo)
	if alvo and alvo.ao_alcance(global_position):
		interagir_com(alvo)


## O Interagivel cuja área de toque cobre esse ponto, ou null.
func interagivel_em(posicao_mundo: Vector2) -> Interagivel:
	var consulta := PhysicsPointQueryParameters2D.new()
	consulta.position = posicao_mundo
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	consulta.collision_mask = Interagivel.CAMADA_INTERAGIVEIS
	for resultado in get_world_2d().direct_space_state.intersect_point(consulta):
		if resultado.collider is Interagivel:
			return resultado.collider
	return null


## O interagível mais próximo que está ao alcance, ou null.
func interagivel_ao_alcance() -> Interagivel:
	var melhor: Interagivel = null
	var menor := INF
	for no in get_tree().get_nodes_in_group(Interagivel.GRUPO_INTERAGIVEIS):
		var alvo := no as Interagivel
		var distancia := global_position.distance_to(alvo.global_position)
		if alvo.ao_alcance(global_position) and distancia < menor:
			melhor = alvo
			menor = distancia
	return melhor


## Interage na hora se estiver ao alcance; senão anda até perto e interage ao chegar.
func interagir_com(alvo: Interagivel) -> void:
	if alvo.ao_alcance(global_position):
		alvo_interacao = null
		andando = false
		alvo.interagir()
		return
	alvo_interacao = alvo
	ir_para(alvo.global_position)


## Leva o personagem ao ponto andável mais próximo de `destino`.
func ir_para(destino: Vector2) -> void:
	var mapa := agente.get_navigation_map()
	var na_grade := Vector2.INF
	if grade:
		na_grade = casa_livre_perto(destino)
	if na_grade != Vector2.INF:
		destino = na_grade
	elif NavigationServer2D.map_get_iteration_id(mapa) > 0:
		destino = NavigationServer2D.map_get_closest_point(mapa, destino)
	_casa_destino = Vector2.INF
	agente.target_position = destino
	andando = true
	destino_definido.emit(destino)


## Pulo só visual: o corpo sobe e desce e a sombra diminui. Não passa por cima
## de obstáculos.
func pular() -> void:
	if pulando:
		return
	pulando = true
	_tempo_pulo = 0.0


## Tem uma arma equipada no Inventario.
func armado() -> bool:
	return not Inventario.equipado(id_inventario, Item.Encaixe.ARMA).is_empty()


## Está em combate: há um inimigo vivo a até [member raio_combate].
func em_combate() -> bool:
	for no in get_tree().get_nodes_in_group(Inimigo.GRUPO):
		var inimigo := no as Node2D
		if inimigo and global_position.distance_to(inimigo.global_position) <= raio_combate:
			return true
	return false


## Pode golpear agora: com arma sempre; sem arma, só em combate (soco).
func pode_golpear() -> bool:
	return armado() or em_combate()


## Arma equipada agora, ou null.
func arma() -> Item:
	return Inventario.item(Inventario.equipado(id_inventario, Item.Encaixe.ARMA))


## Multiplicador de velocidade do equipamento: 1,2 = 20% mais rápido.
func ritmo() -> float:
	return _ritmo


## Multiplicador de velocidade do andar (o peso do equipamento tem limite).
func ritmo_andar() -> float:
	return _ritmo_andar


## Velocidade de andar com o equipamento.
func velocidade_andando() -> float:
	return velocidade * _ritmo_andar


## Quanto dura o golpe com o equipamento (mais rápido, mais curto).
func duracao_do_golpe() -> float:
	return duracao_golpe / _ritmo


## Ataque do golpe: o da idade (soco) mais o do equipamento.
func ataque() -> int:
	return int(Inventario.atributos(id_inventario).ataque)


## Até onde o golpe pega: o alcance da arma, se ela tiver um.
func alcance_do_golpe() -> float:
	var dados := arma()
	return dados.alcance if dados and dados.alcance > 0.0 else alcance_golpe


## Golpe com a arma equipada (ou soco, sem arma, em combate), para onde ele
## está olhando ([member direcao_olhar]). Para de andar. Devolve false se não
## puder golpear agora (sem arma fora de combate, em conversa ou no meio de
## outro golpe).
func golpear() -> bool:
	if em_dialogo or golpeando or not pode_golpear():
		return false
	if indo_para_casa():
		# Termina o passo antes, para golpear sempre do centro de uma casa,
		# mas depressa: chega em no máximo [constant TEMPO_ATE_GOLPE].
		_golpe_pendente = true
		var falta := global_position.distance_to(_casa_destino)
		_pressa = maxf(_pressa, falta / (velocidade_andando() * TEMPO_ATE_GOLPE))
		return true
	golpeando = true
	_tempo_golpe = 0.0
	andando = false
	alvo_interacao = null
	velocity = Vector2.ZERO
	golpeou.emit()
	return true


## Quem o golpe pega agora. Na grade: quem está na casa da frente ou, com
## arma de longo alcance, o primeiro na linha para onde ele olha. Sem grade:
## quem está perto e na frente dele.
func alvos_do_golpe() -> Array[ReacaoAoGolpe]:
	var alvos: Array[ReacaoAoGolpe] = []
	if grade:
		var passo := passo_do_olhar()
		var casa := casa_de(global_position)
		for i in casas_do_golpe():
			casa += passo
			var achados := atingiveis_na_casa(casa)
			if not achados.is_empty():
				return achados
			if not casa_andavel(centro_da_casa(casa)):
				break   # parede ou objeto: a flecha para
		return alvos
	for no in get_tree().get_nodes_in_group(ReacaoAoGolpe.GRUPO):
		var alvo := no as ReacaoAoGolpe
		if alvo == null or is_ancestor_of(alvo):
			continue
		if pega_no_golpe(global_position, direcao_olhar, alvo.global_position, alcance_do_golpe()):
			alvos.append(alvo)
	return alvos


## O golpe de quem está em [param origem], olhando para [param olhar], pega
## quem está em [param alvo]? Perto o bastante e num leque à frente.
static func pega_no_golpe(origem: Vector2, olhar: Vector2, alvo: Vector2, alcance: float) -> bool:
	var ate_alvo := alvo - origem
	if ate_alvo.length() > alcance:
		return false
	if ate_alvo.length() < 1.0:
		return true
	return olhar.normalized().dot(ate_alvo.normalized()) >= 0.7


## Quantas casas o golpe alcança na grade: 1 de perto; o arco, mais.
func casas_do_golpe() -> int:
	return maxi(1, roundi(alcance_do_golpe() / Balanceamento.ALCANCE_PADRAO))


## Quem pode ser atingido nesta casa (fora ele mesmo).
func atingiveis_na_casa(casa: Vector2i) -> Array[ReacaoAoGolpe]:
	var achados: Array[ReacaoAoGolpe] = []
	for no in get_tree().get_nodes_in_group(ReacaoAoGolpe.GRUPO):
		var alvo := no as ReacaoAoGolpe
		if alvo == null or is_ancestor_of(alvo):
			continue
		var dono := alvo.get_parent() as Node2D
		var onde := dono.global_position if dono else alvo.global_position
		if casa_de(onde) == casa:
			achados.append(alvo)
	return achados


## O passo da grade (entre as 8 vizinhas) que mais combina com
## [member direcao_olhar]: a casa "da frente".
func passo_do_olhar() -> Vector2i:
	var aqui := casa_de(global_position)
	var origem := centro_da_casa(aqui)
	var melhor := Vector2i(1, 0)
	var maior := -INF
	for passo in PASSOS:
		var nota := (centro_da_casa(aqui + passo) - origem).normalized().dot(direcao_olhar)
		if nota > maior:
			maior = nota
			melhor = passo
	return melhor


## Registra a casa onde ele está parado (depois de chegar, de ser levado
## para o ponto de entrada etc.).
func _sincronizar_casa() -> void:
	var casa := casa_de(global_position)
	var minhas := GradeOcupacao.casas_de(self)
	if minhas.size() == 1 and minhas[0] == casa:
		return
	GradeOcupacao.liberar_tudo(self)
	GradeOcupacao.ocupar(casa, self)


## Está no meio de um passo de uma casa para outra (teclado).
func indo_para_casa() -> bool:
	return _casa_destino != Vector2.INF


## Casa do chão onde fica este ponto do mundo.
func casa_de(ponto: Vector2) -> Vector2i:
	return grade.local_to_map(grade.to_local(ponto))


## Centro, no mundo, de uma casa do chão.
func centro_da_casa(casa: Vector2i) -> Vector2:
	return grade.to_global(grade.map_to_local(casa))


## Quantas casas as teclas andam em cada eixo do chão: S anda +1 em x e W
## -1; A anda +1 em y e D -1. Duas teclas juntas andam na diagonal da grade
## (as direções retas da tela).
static func passo_na_grade(direcao_teclas: Vector2) -> Vector2i:
	var passo := Vector2i.ZERO
	if absf(direcao_teclas.y) > 0.3:
		passo.x = signi(roundi(signf(direcao_teclas.y)))
	if absf(direcao_teclas.x) > 0.3:
		passo.y = -signi(roundi(signf(direcao_teclas.x)))
	return passo


## O centro da casa é chão andável (na navegação da sala).
func casa_andavel(centro: Vector2) -> bool:
	var mapa := agente.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(mapa) == 0:
		return true
	return NavigationServer2D.map_get_closest_point(mapa, centro).distance_to(centro) < 2.0


## O centro de casa andável mais perto de [param destino]: a própria casa ou,
## se ela estiver ocupada (um objeto, alguém), a vizinha livre mais perto
## dela, desempatando pela mais perto do personagem. INF se não houver.
func casa_livre_perto(destino: Vector2) -> Vector2:
	var casa := casa_de(destino)
	var centro := centro_da_casa(casa)
	if casa_andavel(centro):
		return centro
	var melhor := Vector2.INF
	var melhor_nota := INF
	for passo: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, -1)]:
		var vizinha := centro_da_casa(casa + passo)
		if not casa_andavel(vizinha):
			continue
		var nota := roundf(vizinha.distance_to(destino)) * 1000.0 + vizinha.distance_to(global_position)
		if nota < melhor_nota:
			melhor = vizinha
			melhor_nota = nota
	return melhor


## Converte a direção das teclas para as linhas do quadriculado isométrico:
## W sobe para a esquerda, S desce para a direita, D sobe para a direita e
## A desce para a esquerda. Duas teclas juntas fazem as direções retas da
## tela (W+D para cima, S+A para baixo, W+A para a esquerda, S+D para a
## direita). O resultado tem tamanho 1, então a velocidade é a mesma em
## qualquer direção.
static func direcao_isometrica(direcao_teclas: Vector2) -> Vector2:
	var eixo_s := Vector2(2, 1).normalized()
	var eixo_d := Vector2(2, -1).normalized()
	var direcao := eixo_d * direcao_teclas.x + eixo_s * direcao_teclas.y
	return direcao.normalized()


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	em_dialogo = true
	andando = false
	alvo_interacao = null
	velocity = Vector2.ZERO
	chegou.emit()


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	# Espera um instante para o mesmo E ou toque que fechou a conversa
	# não abrir outra nem mandar o personagem andar.
	await get_tree().create_timer(0.2).timeout
	em_dialogo = false


func _exit_tree() -> void:
	GradeOcupacao.liberar_tudo(self)


func _physics_process(delta: float) -> void:
	_notar_salto()
	if grade and not indo_para_casa():
		_sincronizar_casa()
	if indo_para_casa():
		_tempo_parado = 0.0
	else:
		_tempo_parado += delta
	_atualizar_pulo(delta)
	_atualizar_golpe(delta)
	if em_dialogo or golpeando:
		velocity = Vector2.ZERO
		return
	var rapidez := velocidade_andando()
	if Input.is_action_pressed("correr"):
		rapidez *= multiplicador_corrida

	var teclas := Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
	if teclas == Vector2.ZERO:
		# Soltou: apertar de novo na mesma direção já anda.
		_espera_virar = 0.0
	if grade and (indo_para_casa() or teclas != Vector2.ZERO or _passo_guardado != Vector2i.ZERO):
		_andar_na_grade(teclas, rapidez, delta)
		return
	if teclas != Vector2.ZERO:
		alvo_interacao = null
		if andando:
			andando = false
			chegou.emit()
		velocity = direcao_isometrica(teclas) * rapidez
		direcao_olhar = velocity.normalized()
		move_and_slide()
		return

	if not andando:
		velocity = Vector2.ZERO
		return
	if agente.is_navigation_finished():
		if grade and global_position.distance_to(agente.target_position) < 6.0:
			global_position = agente.target_position
		andando = false
		velocity = Vector2.ZERO
		chegou.emit()
		if alvo_interacao and alvo_interacao.ao_alcance(global_position):
			alvo_interacao.interagir()
		alvo_interacao = null
		return
	velocity = global_position.direction_to(agente.get_next_path_position()) * rapidez
	if velocity.length() > 1.0:
		direcao_olhar = velocity.normalized()
	move_and_slide()


## Teclado com grade: anda uma casa por vez e só para no centro de uma casa.
## Responde na hora (Rafael, 19/10; planos/navegacao-fluida.md, passo 2):
## - soltar antes da metade do passo volta, rápido, para a casa de onde saiu;
##   depois da metade, termina o passo;
## - a direção contrária volta na hora; outra direção, antes da metade, troca
##   a casa de destino (assim duas teclas quase juntas fazem a diagonal da
##   tela) e, depois da metade, fica guardada para quando ele chegar;
## - parado e em combate, numa direção nova o primeiro aperto só vira (veja
##   [member tempo_para_andar]).
func _andar_na_grade(teclas: Vector2, rapidez: float, delta: float) -> void:
	if indo_para_casa():
		_ajustar_passo(teclas)
	if not indo_para_casa():
		var passo := passo_na_grade(teclas)
		var guardado := passo == Vector2i.ZERO and _passo_guardado != Vector2i.ZERO
		if guardado:
			passo = _passo_guardado
		_passo_guardado = Vector2i.ZERO
		if passo == Vector2i.ZERO:
			velocity = Vector2.ZERO
			return
		alvo_interacao = null
		if andando:
			andando = false
			chegou.emit()
		var rumo := _rumo_do_passo(passo)
		if (not guardado and rumo.dot(direcao_olhar) < 0.99 and _tempo_parado >= tempo_para_parar
				and em_combate()):
			direcao_olhar = rumo
			_espera_virar = tempo_para_andar
			velocity = Vector2.ZERO
			return
		if _espera_virar > 0.0:
			_espera_virar -= delta
			velocity = Vector2.ZERO
			return
		direcao_olhar = rumo
		var aqui := casa_de(global_position)
		var proxima := _reservar_vizinha(aqui, passo)
		if proxima == Vector2i.MAX:
			velocity = Vector2.ZERO
			return
		_casa_origem = centro_da_casa(aqui)
		_casa_destino = centro_da_casa(proxima)
		_passo_atual = proxima - aqui
		_pressa = 1.0
		_passo_firme = guardado
	rapidez *= _pressa
	var falta := _casa_destino - global_position
	var anda := rapidez * delta
	velocity = falta.normalized() * rapidez
	if falta.length() <= anda:
		global_position = _casa_destino
		_casa_destino = Vector2.INF
		_pressa = 1.0
		_sincronizar_casa()
		if _golpe_pendente:
			_golpe_pendente = false
			golpear()
		return
	var antes := global_position
	move_and_slide()
	if global_position.distance_to(antes) < anda * 0.1:
		# Algo entrou no caminho: volta para a casa de onde saiu.
		_voltar_para_origem()


## A casa vizinha de [param casa] no rumo de [param passo], já reservada para
## ele, ou MAX se não der. Na diagonal da grade, se a casa estiver fechada
## (parede de um lado, como num corredor), escorrega pelo eixo livre.
func _reservar_vizinha(casa: Vector2i, passo: Vector2i) -> Vector2i:
	var tentativas: Array[Vector2i] = [passo]
	if passo.x != 0 and passo.y != 0:
		tentativas.append_array([Vector2i(passo.x, 0), Vector2i(0, passo.y)])
	for tentativa in tentativas:
		var vizinha := casa + tentativa
		var centro := centro_da_casa(vizinha)
		if (not test_move(global_transform, centro - global_position) and casa_andavel(centro)
				and GradeOcupacao.ocupar(vizinha, self)):
			return vizinha
	return Vector2i.MAX


## Para onde ele olha andando esse passo da grade.
func _rumo_do_passo(passo: Vector2i) -> Vector2:
	var aqui := casa_de(global_position)
	return (centro_da_casa(aqui + passo) - centro_da_casa(aqui)).normalized()


## Quanto do passo em andamento já foi feito, de 0 a 1.
func _progresso_do_passo() -> float:
	var total := _casa_origem.distance_to(_casa_destino)
	if total < 0.5:
		return 1.0
	return clampf(1.0 - global_position.distance_to(_casa_destino) / total, 0.0, 1.0)


## Inverte o passo em andamento: volta para a casa de onde saiu.
func _voltar_para_origem() -> void:
	var saiu_de := _casa_origem
	_casa_origem = _casa_destino
	_casa_destino = saiu_de
	_passo_atual = -_passo_atual


## No meio de um passo pelo teclado, as teclas podem mudar o destino.
func _ajustar_passo(teclas: Vector2) -> void:
	if _golpe_pendente:
		return
	var passo := passo_na_grade(teclas)
	var feito := _progresso_do_passo()
	if passo == Vector2i.ZERO:
		# Toque curto: soltou antes da metade, volta (rápido) de onde saiu.
		if feito < 0.5 and not _passo_firme:
			GradeOcupacao.liberar(casa_de(_casa_destino), self)
			_voltar_para_origem()
			_pressa = 2.0
		return
	if passo == _passo_atual:
		return
	_passo_guardado = Vector2i.ZERO
	if passo == -_passo_atual:
		_voltar_para_origem()
		direcao_olhar = _rumo_do_passo(_passo_atual)
		return
	if feito >= 0.5:
		_passo_guardado = passo
		return
	# Antes da metade: troca a casa de destino, a partir da casa de onde saiu.
	var origem := casa_de(_casa_origem)
	var antiga := casa_de(_casa_destino)
	var nova := _reservar_vizinha(origem, passo)
	if nova == Vector2i.MAX or nova == antiga:
		return
	GradeOcupacao.liberar(antiga, self)
	_casa_destino = centro_da_casa(nova)
	_passo_atual = nova - origem
	direcao_olhar = (_casa_destino - _casa_origem).normalized()


func _atualizar_golpe(delta: float) -> void:
	if not golpeando:
		return
	var antes := _tempo_golpe
	_tempo_golpe += delta
	var corte := momento_do_corte / _ritmo
	if antes < corte and _tempo_golpe >= corte:
		var alvos := alvos_do_golpe()
		var forca := ataque()
		for alvo in alvos:
			alvo.receber_golpe(global_position.direction_to(alvo.global_position), forca)
		acertou.emit(alvos)
	if _tempo_golpe >= duracao_do_golpe():
		golpeando = false


func _atualizar_pulo(delta: float) -> void:
	if not pulando:
		return
	_tempo_pulo += delta
	var t := clampf(_tempo_pulo / duracao_pulo, 0.0, 1.0)
	var altura := sin(t * PI) * altura_pulo
	corpo.position.y = -altura
	sombra.scale = Vector2.ONE * (1.0 - 0.4 * altura / altura_pulo)
	if t >= 1.0:
		pulando = false
		corpo.position.y = 0.0
		sombra.scale = Vector2.ONE


func _ao_mudar_equipamento(quem: String, _encaixe: Item.Encaixe, _id: String) -> void:
	if quem == id_inventario:
		_atualizar_ritmo()


func _ao_mudar_idade(_faixa: Inventario.FaixaEtaria) -> void:
	_atualizar_vida_maxima()
	_atualizar_ritmo()


func _ao_subir_de_nivel(quem: String, _nivel: int) -> void:
	if quem == id_inventario:
		_atualizar_vida_maxima()


func _atualizar_vida_maxima() -> void:
	if vida and vida_pela_idade:
		vida.mudar_maxima(Inventario.fase().vida_base + Experiencia.bonus_vida(id_inventario))


func _atualizar_ritmo() -> void:
	var bonus := int(Inventario.atributos(id_inventario).velocidade)
	if efeitos:
		bonus += efeitos.bonus_velocidade()
	_ritmo = Balanceamento.multiplicador_velocidade(bonus)
	_ritmo_andar = Balanceamento.multiplicador_andar(bonus)


## Foi levado de um lugar para outro desde o último quadro: a imagem e a
## câmera vão direto para lá, sem deslizar pelo caminho.
func _notar_salto() -> void:
	if (_posicao_anterior != Vector2.INF
			and global_position.distance_to(_posicao_anterior) > DISTANCIA_SALTO):
		reset_physics_interpolation()
		var camera := get_node_or_null("Camera") as Camera2D
		if camera:
			camera.reset_smoothing()
	_posicao_anterior = global_position


## Ponto de entrada novo (troca de sala, acampamento).
func definir_ponto_de_entrada(ponto: Vector2) -> void:
	_ponto_de_entrada = ponto


func _ao_ser_derrotado() -> void:
	golpeando = false
	andando = false
	pulando = false
	alvo_interacao = null
	_casa_destino = Vector2.INF
	_passo_guardado = Vector2i.ZERO
	_pressa = 1.0
	_golpe_pendente = false
	velocity = Vector2.ZERO
	corpo.position.y = 0.0
	global_position = _ponto_de_entrada
	if efeitos:
		efeitos.limpar()
	vida.restaurar()
	# Pisca um instante para mostrar que voltou.
	corpo.modulate.a = 0.0
	create_tween().tween_property(corpo, "modulate:a", 1.0, 0.6)
	derrotado.emit()
