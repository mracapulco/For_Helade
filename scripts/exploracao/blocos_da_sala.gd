class_name BlocosDaSala
extends Node
## Caixas e degraus numa sala de grade (sala lateral da loja de pelúcias;
## regra do jogo, não do livro: Rafael, 21/10/2026).
## Nicholas anda livre pela tela; os blocos ficam nas casas do chão.
## - Segurando o clique esquerdo perto de um bloco móvel e virado para ele
##   (Rafael, 23/10), Nicholas o agarra: encaixa no lado do bloco mais perto
##   dele. Andando na direção do bloco empurra, na contrária puxa: uma casa
##   por passo, os dois juntos. Para os lados não anda. Soltando, larga.
## - Cada bloco tem uma altura (1 = banquinho, 2 = caixa...). Com o Espaço,
##   Nicholas sobe no bloco perto à frente que seja um degrau acima de onde
##   está; em cima, as teclas levam à casa vizinha mais na direção delas:
##   blocos da mesma altura, mais baixos ou o chão livre. Bloco com altura 0
##   não se sobe (caixote alto).
## Enquanto segura ou está em cima, este nó move o jogador
## ([member PersonagemExploracao.controlado]).
## Sons: assets/audio/sfx/capitulo_01 (agarrar, arrastar, subir, descer).

## Mudou a casa ou a altura de Nicholas (depois de cada passo).
signal moveu(casa: Vector2i, altura: int)

const SFX := "res://assets/audio/sfx/capitulo_01/"
const BARRAMENTO := &"Efeitos"
## Segundos por casa empurrando ou puxando, andando em cima e no pulo.
const TEMPO_ARRASTAR := 0.55
const TEMPO_ANDAR_EM_CIMA := 0.32
const TEMPO_PULO := 0.35
## Até onde (pixels, dos pés ao centro do bloco) ele alcança um bloco.
const ALCANCE := 46.0
## Quanto o bloco precisa estar na frente dele (produto escalar com o olhar).
const NA_FRENTE := 0.35
## Quanto as teclas precisam apontar para o bloco agarrado para empurrar.
const NA_DIRECAO := 0.35
## Folga em y para Nicholas ser desenhado depois do bloco onde pisa.
const ACIMA_DO_BLOCO := Vector2(0, 1)
const COR_MARCA := Color(0.95, 0.8, 0.4, 0.9)
const COR_MARCA_SUBIR := Color(0.6, 0.85, 1.0, 0.9)

var sala: SalaMontada
var jogador: PersonagemExploracao
## Diz se uma casa do chão está livre de tudo que não é bloco (objetos,
## pessoas, bordas). Recebe a casa.
var casa_livre_no_chao: Callable
## Liga e desliga o controle (fora do jogo das caixas, nada acontece).
## Ligado, o clique esquerdo agarra em vez de golpear.
var ativo := false:
	set(valor):
		ativo = valor
		if jogador and is_instance_valid(jogador):
			jogador.sem_golpe = valor
## Multiplica a duração dos passos (0 nos testes: tudo na hora).
var escala_tempo := 1.0
## Os blocos: nome -> {"no": Node2D, "altura": int, "topo": float (pixels),
## "movel": bool}.
var blocos := {}
## Altura onde Nicholas está (0 = chão) e o bloco onde pisa.
var altura := 0
var pisando := ""
## O bloco que ele segura ("" = nenhum).
var segurando := ""

var _ocupado := false
var _marca: Line2D
var _sons := {}


func _ready() -> void:
	for nome in ["agarrar", "arrastar", "subir", "descer"]:
		var tocador := AudioStreamPlayer.new()
		tocador.name = "Som" + nome.capitalize()
		tocador.stream = load(SFX + nome + ".wav")
		tocador.bus = BARRAMENTO
		add_child(tocador)
		_sons[nome] = tocador


func configurar(nova_sala: SalaMontada, novo_jogador: PersonagemExploracao, livre: Callable) -> void:
	sala = nova_sala
	jogador = novo_jogador
	casa_livre_no_chao = livre
	blocos.clear()
	altura = 0
	pisando = ""
	segurando = ""
	_marca = Line2D.new()
	_marca.name = "MarcaDaFrente"
	_marca.width = 1.5
	_marca.closed = true
	_marca.z_index = -1
	_marca.points = PackedVector2Array([Vector2(0, -14), Vector2(28, 0), Vector2(0, 14), Vector2(-28, 0)])
	_marca.visible = false
	sala.add_child(_marca)


func adicionar(nome: String, no: Node2D, nova_altura: int, topo: float, movel: bool) -> void:
	blocos[nome] = {"no": no, "altura": nova_altura, "topo": topo, "movel": movel}


func casa_do_bloco(nome: String) -> Vector2i:
	return _casa(blocos[nome]["no"].position)


## O bloco nesta casa, ou "".
func bloco_em(casa: Vector2i) -> String:
	for nome: String in blocos:
		if casa_do_bloco(nome) == casa:
			return nome
	return ""


## A casa vizinha para onde ele olha (uma das oito).
func passo_da_frente() -> Vector2i:
	return jogador.passo_do_olhar()


## O bloco mais perto ao alcance e na frente dele (que passe no filtro, se
## houver), ou "".
func bloco_perto(filtro := Callable()) -> String:
	var melhor := ""
	var menor := INF
	for nome: String in blocos:
		var no: Node2D = blocos[nome]["no"]
		var ate := no.position - jogador.position
		var distancia := ate.length()
		if distancia > ALCANCE or (filtro.is_valid() and not filtro.call(nome)):
			continue
		if distancia > 1.0 and ate.normalized().dot(jogador.direcao_olhar) < NA_FRENTE:
			continue
		if distancia < menor:
			menor = distancia
			melhor = nome
	return melhor


## Põe Nicholas de volta no chão nesta casa (Ophelia arrumando, fim do jogo).
func por_no_chao(casa: Vector2i) -> void:
	soltar()
	altura = 0
	pisando = ""
	jogador.position = sala.centro(casa)
	_elevar(0.0)
	jogador.controlado = false
	moveu.emit(casa, 0)


func _physics_process(_delta: float) -> void:
	if not ativo or jogador == null or not is_instance_valid(jogador):
		return
	_atualizar_marca()
	if _ocupado:
		return
	var teclas := Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
	if segurando != "":
		if not Input.is_action_pressed("golpear"):
			soltar()
		elif teclas != Vector2.ZERO:
			var no: Node2D = blocos[segurando]["no"]
			var eixo := (no.position - jogador.position).normalized()
			var nota := teclas.normalized().dot(eixo)
			var frente := casa_do_bloco(segurando) - _casa(jogador.position)
			if nota >= NA_DIRECAO:
				arrastar(frente)
			elif nota <= -NA_DIRECAO:
				arrastar(-frente)
		return
	if Input.is_action_just_pressed("pular") or Input.is_action_just_pressed("esquivar"):
		subir()
		return
	if altura > 0:
		if teclas != Vector2.ZERO:
			andar_em_cima(_passo_das_teclas(teclas))
		return
	if Input.is_action_pressed("golpear"):
		agarrar()


## A casa vizinha (das oito) mais na direção das teclas, na tela.
func _passo_das_teclas(teclas: Vector2) -> Vector2i:
	var aqui := _casa(jogador.position)
	var melhor := Vector2i.ZERO
	var maior := -INF
	for passo in PersonagemExploracao.PASSOS:
		var nota := (sala.centro(aqui + passo) - sala.centro(aqui)).normalized().dot(teclas.normalized())
		if nota > maior:
			maior = nota
			melhor = passo
	return melhor


## Agarra o bloco móvel perto à frente (no chão), encaixando Nicholas no
## lado livre do bloco mais perto dele. Devolve se agarrou.
func agarrar() -> bool:
	if altura > 0 or segurando != "":
		return false
	var nome := bloco_perto(func(n: String) -> bool: return blocos[n]["movel"])
	if nome == "":
		return false
	var bloco := casa_do_bloco(nome)
	var lado := Vector2i.MAX
	var menor := INF
	var aqui := _casa(jogador.position)
	for passo: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var casa := bloco + passo
		if casa != aqui and not _chao_livre(casa):
			continue
		var distancia := sala.centro(casa).distance_to(jogador.position)
		if distancia < menor:
			menor = distancia
			lado = casa
	if lado == Vector2i.MAX:
		return false
	segurando = nome
	jogador.controlado = true
	jogador.velocity = Vector2.ZERO
	jogador.position = sala.centro(lado)
	jogador.direcao_olhar = (sala.centro(bloco) - sala.centro(lado)).normalized()
	_animar("segurando")
	_sons["agarrar"].play()
	return true


func soltar() -> void:
	if segurando == "":
		return
	segurando = ""
	_animar("")
	jogador.controlado = altura > 0


## Segurando: [param passo] igual à frente empurra, o contrário puxa.
func arrastar(passo: Vector2i) -> void:
	if segurando == "" or _ocupado:
		return
	var frente := casa_do_bloco(segurando) - _casa(jogador.position)
	if passo != frente and passo != -frente:
		return
	var no: Node2D = blocos[segurando]["no"]
	var casa_bloco := _casa(no.position)
	var casa_jogador := _casa(jogador.position)
	var livre := casa_bloco + passo if passo == frente else casa_jogador + passo
	if not _chao_livre(livre):
		return
	_ocupado = true
	_animar("empurrando" if passo == frente else "puxando")
	_sons["arrastar"].play()
	var olhar := jogador.direcao_olhar
	await _mover([[no, sala.centro(casa_bloco + passo)], [jogador, sala.centro(casa_jogador + passo)]],
		TEMPO_ARRASTAR * escala_tempo)
	jogador.direcao_olhar = olhar
	_animar("segurando" if segurando != "" else "")
	_ocupado = false
	moveu.emit(casa_jogador + passo, 0)


## Pula para o bloco da frente, se for um degrau acima.
func subir() -> bool:
	if segurando != "" or _ocupado:
		return false
	var nome := ""
	if altura == 0:
		nome = bloco_perto(func(n: String) -> bool: return blocos[n]["altura"] == 1)
	else:
		nome = bloco_em(_casa(jogador.position) + passo_da_frente())
	if nome == "" or blocos[nome]["altura"] != altura + 1:
		return false
	var destino := casa_do_bloco(nome)
	_ocupado = true
	jogador.controlado = true
	jogador.pular()
	_sons["subir"].play()
	await _passo_em_cima(destino, nome, TEMPO_PULO * escala_tempo)
	_ocupado = false
	return true


## Em cima de um bloco: anda para outro da mesma altura ou desce (para um
## mais baixo ou para o chão livre). Para cima, só pulando.
func andar_em_cima(passo: Vector2i) -> bool:
	var destino := _casa(jogador.position) + passo
	jogador.direcao_olhar = (sala.centro(destino) - sala.centro(_casa(jogador.position))).normalized()
	var nome := bloco_em(destino)
	var nova := 0 if nome == "" else int(blocos[nome]["altura"])
	if nome == "" and not _chao_livre(destino):
		return false
	if nome != "" and (nova == 0 or nova > altura):
		return false
	_ocupado = true
	if nova < altura:
		jogador.pular()
	await _passo_em_cima(destino, nome, TEMPO_ANDAR_EM_CIMA * escala_tempo)
	if nova < altura or nome == "":
		_sons["descer"].play()
	_ocupado = false
	return true


func _passo_em_cima(destino: Vector2i, nome: String, tempo: float) -> void:
	var nova := 0 if nome == "" else int(blocos[nome]["altura"])
	var topo := 0.0 if nome == "" else float(blocos[nome]["topo"])
	_animar("andando")
	var alvo := sala.centro(destino) + (ACIMA_DO_BLOCO if nome != "" else Vector2.ZERO)
	var antes := _elevacao()
	if tempo > 0.0 and is_inside_tree():
		var passo := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel()
		passo.tween_property(jogador, "position", alvo, tempo)
		passo.tween_method(_elevar, antes, topo, tempo)
		await passo.finished
	jogador.position = alvo
	_elevar(topo)
	altura = nova
	pisando = nome
	_animar("")
	jogador.controlado = altura > 0 or segurando != ""
	moveu.emit(destino, altura)


func _mover(pares: Array, tempo: float) -> void:
	if tempo > 0.0 and is_inside_tree():
		var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel()
		for par: Array in pares:
			tween.tween_property(par[0], "position", par[1], tempo)
		await tween.finished
	for par: Array in pares:
		par[0].position = par[1]


## Casa do chão livre para Nicholas ou um bloco: sem bloco, sem objeto,
## sem ninguém.
func _chao_livre(casa: Vector2i) -> bool:
	return bloco_em(casa) == "" and casa_livre_no_chao.call(casa)


## Sobe o desenho e a sombra de Nicholas (a casa dele continua a mesma).
func _elevar(pixels: float) -> void:
	jogador.get_node("Corpo/Visual").position.y = -pixels
	jogador.get_node("Sombra").position.y = -pixels


func _elevacao() -> float:
	return -jogador.get_node("Corpo/Visual").position.y


func _animar(acao: String) -> void:
	var visual := jogador.get_node_or_null("Corpo/Visual") as AnimacaoPersonagem
	if visual:
		visual.acao_forcada = acao


func _casa(ponto: Vector2) -> Vector2i:
	return jogador.casa_de(ponto)


## O bloco ao alcance marcado no chão: dourado onde dá para agarrar,
## azul onde dá para subir.
func _atualizar_marca() -> void:
	if _marca == null or not is_instance_valid(_marca):
		return
	var cor := Color.TRANSPARENT
	var nome := segurando
	if nome != "":
		cor = COR_MARCA
	elif altura == 0:
		nome = bloco_perto(func(n: String) -> bool: return blocos[n]["altura"] == 1 or blocos[n]["movel"])
		if nome != "":
			cor = COR_MARCA_SUBIR if blocos[nome]["altura"] == 1 else COR_MARCA
	else:
		nome = bloco_em(_casa(jogador.position) + passo_da_frente())
		if nome != "" and int(blocos[nome]["altura"]) == altura + 1:
			cor = COR_MARCA_SUBIR
		else:
			nome = ""
	if nome != "":
		_marca.position = sala.centro(casa_do_bloco(nome))
	_marca.default_color = cor
	_marca.visible = cor != Color.TRANSPARENT
