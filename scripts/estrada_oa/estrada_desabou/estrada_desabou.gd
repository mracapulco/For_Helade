class_name FaseEstradaDesabou
extends Node2D
## Estrada Atenas–Olympia, trecho 3: "A estrada desabou" (Cap. 2 da Parte I;
## o livro só diz que a estrada é traiçoeira e que o comboio leva carroças
## pesadas: tudo aqui é inferência, aprovada pelo Rafael em 26/10/2026 no
## brainstorm das quatro fases).
## Um trecho da estrada caiu na encosta. Nicholas refaz o caminho empurrando e
## puxando a carga do comboio para dentro dos buracos ([ObraEstrada]):
## 1. Aprende: a caixa (puxar para fora do canto e empurrar até o buraco).
## 2. Aprofunda: o barril rola até bater (a ordem importa) e as toras só andam
##    no sentido do comprimento.
## 3. Surpresa: pedras rolam da encosta, com a sombra no chão antes. Espaço
##    esquiva e uma caixa bem posta no alto da pista vira escudo.
## 4. Fecha: dois buracos seguidos; com a última peça, a carroça passa por
##    cima da obra dele.
## Controle (o mesmo da sala das pelúcias, Rafael 23/10): segurar o clique
## esquerdo perto de uma peça agarra; andando para ela empurra, para trás
## puxa. R ou o botão Recomeçar devolvem o trecho como estava ao chegar,
## sem castigo. Pedra que acerta Nicholas só o leva de volta ao começo do
## trecho das pedras.
## Vencida, a fase vira atalho ([method Mundo.foi_feito]): a estrada já
## aparece refeita, sem pedras, com a placa de saída no fim.
## O carroceiro e a carroça são inventados (provisórios).

signal trecho_mudou(trecho: int)
signal concluida

const ID := "estrada_desabou"
const CENA_MAPA := "res://scenes/mapa/mapa_helade.tscn"
const ARTE := "res://assets/art/estrada_oa/estrada_desabou/"
const SFX := "res://assets/audio/sfx/estrada_oa/estrada_desabou/"
const PLACA := preload("res://assets/art/placeholders/acampamento/placa_saida.png")
const CENA_JOGADOR := preload("res://scenes/capitulo_01/nicholas_11.tscn")
const BARRAMENTO := &"Efeitos"

## A estrada, fileira por fileira (y = 0 junto à encosta, y = 4 junto ao
## precipício); legenda em [constant ObraEstrada.LEGENDA].
const PLANTA := [
	".......#..#..#..#.#.#.C......#......##...",
	".......#....._......#......C.#......##...",
	"......._.....#......#.C......_..B...__...",
	".......#..B..#.=..|._........#......##...",
	"....#C##.....#....#.#........#..#C#.##...",
]
## Onde começa cada trecho (x) e onde Nicholas volta ao recomeçar.
const TRECHOS: Array[int] = [0, 8, 14, 21, 30, 38]
const ENTRADAS: Array[Vector2i] = [
	Vector2i(2, 2), Vector2i(8, 2), Vector2i(14, 1), Vector2i(21, 3), Vector2i(30, 2), Vector2i(38, 2),
]
## Dica que aparece ao chegar em cada trecho ("" = nenhuma).
const DICAS: Array[String] = ["EOA3_DICA_AGARRAR", "EOA3_DICA_BARRIL", "EOA3_DICA_TORA",
	"EOA3_DICA_PEDRAS", "EOA3_DICA_FIM", ""]
## O trecho das pedras rolando e as colunas (x) por onde elas descem.
const TRECHO_PEDRAS := 3
const PISTAS: Array[int] = [23, 26]
## Segundos entre duas pedras na mesma pista, o atraso da segunda pista, o
## aviso da sombra antes de a pedra aparecer e quanto ela leva por casa.
const PERIODO_PEDRA := 3.0
const ATRASO_SEGUNDA_PISTA := 1.5
const AVISO_PEDRA := 0.9
const TEMPO_PEDRA_POR_CASA := 0.22
## Distância (pixels) em que a pedra pega Nicholas.
const RAIO_PEDRA := 13.0
## De onde se vê o ninho de águia (o segredo, só cenário).
const MIRANTE := Vector2i(17, 0)
const CASA_NINHO := Vector2i(19, -2)
## A carroça e o carroceiro esperam no começo; a carroça sai pelo fim.
const CASA_CARROCA := Vector2i(-1, 2)
const CASA_CARROCEIRO := Vector2i(1, 4)
const SAIDA := Vector2i(40, 2)
## No atalho, o que ficou em cada buraco (as peças da solução).
const PONTES_PRONTAS := {
	Vector2i(7, 2): ObraEstrada.Tipo.CAIXA, Vector2i(13, 1): ObraEstrada.Tipo.BARRIL,
	Vector2i(20, 3): ObraEstrada.Tipo.TORA, Vector2i(29, 2): ObraEstrada.Tipo.CAIXA,
	Vector2i(36, 2): ObraEstrada.Tipo.BARRIL, Vector2i(37, 2): ObraEstrada.Tipo.CAIXA,
}

## Tempos de cada passo das peças (segundos por casa).
const TEMPO_ARRASTAR := 0.45
const TEMPO_ROLAR := 0.12
const TEMPO_CARROCA_POR_CASA := 0.14
## Até onde a peça agarrável pode estar (dos pés ao centro dela) e quanto ela
## precisa estar na frente, e o quanto as teclas apontam para empurrar/puxar.
const ALCANCE := 46.0
const NA_FRENTE := 0.35
const NA_DIRECAO := 0.35
## Altura do desenho de cada peça acima do centro da casa (pé da imagem).
const PE := {ObraEstrada.Tipo.CAIXA: 10.0, ObraEstrada.Tipo.BARRIL: 4.0, ObraEstrada.Tipo.TORA: 14.0}
const TOM := Color(1.0, 0.84, 0.68)
const COR_MARCA := Color(0.95, 0.8, 0.4, 0.9)

## Multiplica os tempos (os testes usam 0: tudo na hora).
@export var escala_tempo := 1.0
## Liga as pedras rolando (os testes desligam e chamam [method soltar_pedra]).
@export var pedras_automaticas := true

var obra: ObraEstrada
var sala: SalaMontada
var jogador: PersonagemExploracao
## Já vencida antes: a estrada aparece pronta.
var atalho := false
var concluido := false
## Trecho onde Nicholas está e o mais longe aonde ele já chegou.
var trecho := 0
var trecho_maximo := 0
## O estado da obra quando ele chegou em cada trecho (para recomeçar).
var fotos := {}
## A peça que ele segura ("" = nenhuma).
var segurando := ""
## Nós das peças, dos buracos e das pontes, pela peça ou pela casa.
var nos_pecas := {}
var nos_buracos := {}
## Pedras descendo agora (nós).
var pedras: Array[Node2D] = []
## Quantas vezes uma pedra pegou Nicholas (para os testes).
var acertos := 0
var cena_pedida := ""
var trocar_de_cena := true

var carroca: Node2D
var carroceiro: Node2D
var ninho: Sprite2D
var _ocupado := false
var _marca: Line2D
var _relogios := [0.0, 0.0]
var _sons := {}
var _balao: Label

@onready var texto: TextoSolto = %Texto
@onready var aviso: AvisoItens = $AvisoItens
@onready var botao_mapa: Button = %BotaoMapa
@onready var botao_recomecar: Button = %BotaoRecomecar


func _ready() -> void:
	atalho = Mundo.foi_feito(ID)
	_preparar_sons()
	montar()
	botao_mapa.pressed.connect(voltar_ao_mapa)
	botao_recomecar.pressed.connect(recomecar_trecho)
	for botao: Button in [botao_mapa, botao_recomecar]:
		botao.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	botao_recomecar.visible = not atalho
	_relogios = [0.0, -ATRASO_SEGUNDA_PISTA]
	if atalho:
		return
	# A dica vem depois das frases, para uma não cobrir a outra.
	await _frases(["EOA3_INTRO_1", "EOA3_INTRO_2"])
	if trecho == 0:
		_mostrar_dica(0)


# --- montagem ---------------------------------------------------------------

func montar() -> void:
	obra = ObraEstrada.de_planta(PLANTA)
	if atalho:
		for casa: Vector2i in PONTES_PRONTAS:
			obra.terreno[casa] = ObraEstrada.Terreno.PONTE
			obra.pontes[casa] = PONTES_PRONTAS[casa]
		obra.pecas.clear()
	sala = SalaMontada.new()
	sala.name = "Sala"
	sala.largura = obra.largura
	sala.profundidade = obra.profundidade
	sala.piso = "estrada"
	sala.sem_paredes = true
	sala.tom = TOM
	_cenario()
	for casa: Vector2i in obra.terreno:
		if obra.terreno[casa] == ObraEstrada.Terreno.PEDRA:
			var pedra := _corpo("Pedra_%d_%d" % [casa.x, casa.y], casa)
			_visual(pedra, load(ARTE + "pedra_fixa_%d.png" % (1 + (casa.x * 7 + casa.y * 3) % 3)), 8.0)
	add_child(sala)
	move_child(sala, 0)
	_desenhar_obra()
	jogador = CENA_JOGADOR.instantiate()
	jogador.name = "Nicholas"
	# Ele anda na física com interpolação: a câmera também (sem isso o Godot
	# troca sozinho e avisa).
	(jogador.get_node("Camera") as Camera2D).process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	sala.receber_jogador(jogador, ENTRADAS[0])
	jogador.definir_ponto_de_entrada(jogador.global_position)
	jogador.direcao_olhar = Vector2(2, 1).normalized()
	_marca = Line2D.new()
	_marca.name = "MarcaDaPeca"
	_marca.width = 1.5
	_marca.closed = true
	_marca.z_index = -1
	_marca.points = PackedVector2Array([Vector2(0, -14), Vector2(28, 0), Vector2(0, 14), Vector2(-28, 0)])
	_marca.default_color = COR_MARCA
	_marca.visible = false
	sala.add_child(_marca)
	fotos[0] = obra.foto()


## Encosta acima da estrada, a beira do precipício abaixo, a carroça, o
## carroceiro, o ninho e (no atalho) a placa de saída.
func _cenario() -> void:
	for x in range(-2, obra.largura + 2):
		var encosta := Sprite2D.new()
		encosta.name = "Encosta_%d" % (x + 2)
		encosta.texture = load(ARTE + "encosta_%d.png" % (1 + posmod(x * 5, 3)))
		encosta.position = sala.centro(Vector2i(x, -1))
		encosta.offset = Vector2(0, -encosta.texture.get_height() / 2.0 + 17.0)
		sala.add_child(encosta)
		var beira := Sprite2D.new()
		beira.name = "Beira_%d" % (x + 2)
		beira.texture = load(ARTE + "beira.png")
		beira.centered = false
		beira.offset = Vector2(-32, 0)
		beira.position = sala.centro(Vector2i(x, obra.profundidade - 1))
		beira.z_index = -1
		sala.add_child(beira)
	# Pistas das pedras: o chão raspado mostra por onde elas descem.
	for x in PISTAS:
		for y in obra.profundidade:
			var raspado := Polygon2D.new()
			raspado.name = "Pista_%d_%d" % [x, y]
			raspado.color = Color(0.25, 0.18, 0.12, 0.28)
			raspado.polygon = PackedVector2Array([Vector2(0, -14), Vector2(10, -9), Vector2(4, 13), Vector2(-8, 9)])
			raspado.position = sala.centro(Vector2i(x, y))
			raspado.z_index = -1
			raspado.visible = not atalho
			sala.add_child(raspado)
	ninho = Sprite2D.new()
	ninho.name = "Ninho"
	ninho.texture = load(ARTE + "ninho.png")
	ninho.position = sala.centro(CASA_NINHO)
	# O pico sai de trás do paredão da encosta.
	ninho.offset = Vector2(0, -44)
	ninho.modulate.a = 0.0
	sala.add_child(ninho)
	if atalho:
		var placa := sala.adicionar_objeto("Placa", PLACA, SAIDA, true, true)
		placa.get_node("Interagivel").interagido.connect(voltar_ao_mapa)
		return
	carroca = Node2D.new()
	carroca.name = "Carroca"
	carroca.position = sala.centro(CASA_CARROCA)
	sala.add_child(carroca)
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = load(ARTE + "carroca.png")
	visual.offset = Vector2(4, -visual.texture.get_height() / 2.0 + 8.0)
	carroca.add_child(visual)
	carroceiro = sala.adicionar_objeto("Carroceiro", load(ARTE + "carroceiro.png"), CASA_CARROCEIRO, true, true)
	carroceiro.get_node("Interagivel").interagido.connect(falar_com_carroceiro)


## Corpo que bloqueia uma casa inteira (losango), sem desenho.
func _corpo(nome: String, casa: Vector2i) -> StaticBody2D:
	var corpo := StaticBody2D.new()
	corpo.name = nome
	corpo.position = sala.centro(casa)
	var colisao := CollisionPolygon2D.new()
	colisao.name = "Colisao"
	colisao.polygon = PackedVector2Array([Vector2(0, -15), Vector2(30, 0), Vector2(0, 15), Vector2(-30, 0)])
	corpo.add_child(colisao)
	sala.add_child(corpo)
	return corpo


func _visual(no: Node2D, textura: Texture2D, pe: float) -> Sprite2D:
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = textura
	visual.offset = Vector2(0, -textura.get_height() / 2.0 + pe)
	no.add_child(visual)
	return visual


## Refaz os nós das peças, dos buracos e das pontes a partir da [member obra].
func _desenhar_obra() -> void:
	for no: Node in nos_pecas.values() + nos_buracos.values():
		if is_instance_valid(no):
			no.get_parent().remove_child(no)
			no.queue_free()
	nos_pecas.clear()
	nos_buracos.clear()
	for casa: Vector2i in obra.terreno:
		match obra.terreno[casa]:
			ObraEstrada.Terreno.BURACO:
				sala.chao.erase_cell(casa)
				var buraco := _corpo("Buraco_%d_%d" % [casa.x, casa.y], casa)
				_chapado(buraco, "buraco.png")
				nos_buracos[casa] = buraco
			ObraEstrada.Terreno.PONTE:
				sala.chao.erase_cell(casa)
				var ponte := Node2D.new()
				ponte.name = "Ponte_%d_%d" % [casa.x, casa.y]
				ponte.position = sala.centro(casa)
				sala.add_child(ponte)
				_chapado(ponte, "ponte_%s.png" % _nome_tipo(obra.pontes[casa]))
				nos_buracos[casa] = ponte
	for nome: String in obra.pecas:
		var peca: Dictionary = obra.pecas[nome]
		var no := _corpo(nome.to_pascal_case(), peca["casa"])
		var arquivo := _nome_tipo(peca["tipo"])
		if peca["tipo"] == ObraEstrada.Tipo.TORA:
			arquivo += "_x" if peca["eixo"] == Vector2i(1, 0) else "_y"
		_visual(no, load(ARTE + arquivo + ".png"), PE[peca["tipo"]])
		nos_pecas[nome] = no


## Desenho deitado no chão (buraco, ponte), por baixo de quem anda.
func _chapado(no: Node2D, arquivo: String) -> void:
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = load(ARTE + arquivo)
	visual.z_index = -1
	no.add_child(visual)


static func _nome_tipo(tipo: ObraEstrada.Tipo) -> String:
	return ["caixa", "barril", "tora"][tipo]


func _preparar_sons() -> void:
	for nome in ["agarrar", "arrastar", "rolar", "encaixe", "pedra_rolando", "pedra_quebra", "carroca"]:
		var tocador := AudioStreamPlayer.new()
		tocador.name = "Som" + nome.to_pascal_case()
		tocador.stream = load(SFX + nome + ".wav")
		tocador.bus = BARRAMENTO
		add_child(tocador)
		_sons[nome] = tocador


func _tocar(nome: String) -> void:
	if escala_tempo > 0.0 and _sons.has(nome):
		_sons[nome].play()


# --- controle ---------------------------------------------------------------

## O clique esquerdo perto de uma peça agarra (não golpeia); nas pedras, o
## Espaço sempre esquiva; R recomeça o trecho.
func _input(event: InputEvent) -> void:
	if concluido or jogador == null:
		return
	if event.is_action_pressed("golpear") and (segurando != "" or peca_perto() != ""):
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("esquivar") and pedras_ativas() and segurando == "" and not _ocupado:
		jogador.esquivar()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R \
			and not atalho:
		recomecar_trecho()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if jogador == null or concluido:
		return
	_acompanhar_trecho()
	_atualizar_ninho()
	_atualizar_pedras(delta)
	if "sem_golpe" in jogador:
		jogador.set("sem_golpe", segurando != "" or peca_perto() != "")
	_atualizar_marca()
	if _ocupado:
		return
	var teclas := Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
	if segurando != "":
		if not Input.is_action_pressed("golpear"):
			soltar()
		elif teclas != Vector2.ZERO:
			var no: Node2D = nos_pecas[segurando]
			var eixo := (no.position - jogador.position).normalized()
			var nota := teclas.normalized().dot(eixo)
			if nota >= NA_DIRECAO:
				empurrar()
			elif nota <= -NA_DIRECAO:
				puxar()
		return
	if Input.is_action_pressed("golpear"):
		agarrar()


func casa_do_jogador() -> Vector2i:
	return jogador.casa_de(jogador.global_position)


## A peça vizinha (nas quatro direções da grade) ao alcance e na frente de
## Nicholas, ou "".
func peca_perto() -> String:
	if obra == null or jogador == null:
		return ""
	var aqui := casa_do_jogador()
	var melhor := ""
	var maior := NA_FRENTE
	for passo in ObraEstrada.PASSOS:
		var nome := obra.peca_em(aqui + passo)
		if nome == "":
			continue
		var ate: Vector2 = sala.centro(aqui + passo) - jogador.position
		if ate.length() > ALCANCE + 20.0:
			continue
		var nota := ate.normalized().dot(jogador.direcao_olhar)
		if nota > maior:
			maior = nota
			melhor = nome
	return melhor


## Agarra a peça da frente: Nicholas encaixa no meio da casa dele, virado
## para ela. Devolve se agarrou.
func agarrar(nome := "") -> bool:
	if segurando != "" or _ocupado:
		return false
	if nome == "":
		nome = peca_perto()
	if nome == "" or not obra.pecas.has(nome):
		return false
	var aqui := casa_do_jogador()
	if not obra.pecas[nome]["casa"] - aqui in ObraEstrada.PASSOS:
		return false
	segurando = nome
	_prender(true)
	jogador.position = sala.centro(aqui)
	var no: Node2D = nos_pecas[nome]
	jogador.direcao_olhar = (no.position - jogador.position).normalized()
	_animar("segurando")
	_tocar("agarrar")
	return true


func soltar() -> void:
	if segurando == "":
		return
	segurando = ""
	_animar("")
	_prender(false)


## Segurando: empurra a peça para a frente (a caixa e a tora uma casa, com
## Nicholas atrás; o barril sai rolando e ele solta).
func empurrar() -> bool:
	if segurando == "" or _ocupado:
		return false
	var nome := segurando
	var aqui := casa_do_jogador()
	var passo: Vector2i = obra.pecas[nome]["casa"] - aqui
	var tipo: ObraEstrada.Tipo = obra.pecas[nome]["tipo"]
	var de: Vector2i = obra.pecas[nome]["casa"]
	var resultado := obra.empurrar(nome, aqui, passo)
	if resultado.is_empty():
		return false
	_ocupado = true
	var caminho: Array[Vector2i] = resultado["caminho"]
	if tipo == ObraEstrada.Tipo.BARRIL:
		soltar()
		_tocar("rolar")
		await _andar_pelas_casas(nos_pecas[nome], caminho, TEMPO_ROLAR)
	else:
		_animar("empurrando")
		_tocar("arrastar")
		await _mover([[nos_pecas[nome], sala.centro(caminho[-1])], [jogador, sala.centro(de)]], TEMPO_ARRASTAR)
		_animar("segurando")
	if resultado["caiu"]:
		await _cair(nome, caminho[-1])
	_ocupado = false
	return true


## Segurando: dá um passo para trás trazendo a peça (não vale para o barril).
func puxar() -> bool:
	if segurando == "" or _ocupado:
		return false
	var nome := segurando
	var aqui := casa_do_jogador()
	var passo: Vector2i = aqui - obra.pecas[nome]["casa"]
	var resultado := obra.puxar(nome, aqui)
	if resultado.is_empty():
		return false
	_ocupado = true
	_animar("puxando")
	_tocar("arrastar")
	await _mover([[nos_pecas[nome], sala.centro(aqui)], [jogador, sala.centro(aqui + passo)]], TEMPO_ARRASTAR)
	_animar("segurando")
	_ocupado = false
	return true


## A peça caiu no buraco: vira ponte e a casa abre.
func _cair(nome: String, casa: Vector2i) -> void:
	if segurando == nome:
		soltar()
	var no: Node2D = nos_pecas[nome]
	nos_pecas.erase(nome)
	no.queue_free()
	var buraco: Node2D = nos_buracos.get(casa)
	if buraco:
		buraco.queue_free()
	var ponte := Node2D.new()
	ponte.name = "Ponte_%d_%d" % [casa.x, casa.y]
	ponte.position = sala.centro(casa)
	sala.add_child(ponte)
	_chapado(ponte, "ponte_%s.png" % _nome_tipo(obra.pontes[casa]))
	nos_buracos[casa] = ponte
	_tocar("encaixe")
	_tremer(2.0, 0.15)
	if obra.buracos().is_empty():
		await concluir()


func _andar_pelas_casas(no: Node2D, caminho: Array[Vector2i], tempo: float) -> void:
	for casa in caminho:
		await _mover([[no, sala.centro(casa)]], tempo)


func _mover(pares: Array, tempo: float) -> void:
	var duracao := tempo * escala_tempo
	if duracao > 0.0 and is_inside_tree():
		var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel()
		for par: Array in pares:
			tween.tween_property(par[0], "position", par[1], duracao)
		await tween.finished
	for par: Array in pares:
		par[0].position = par[1]


## Enquanto segura, as teclas mexem a peça e não Nicholas.
func _prender(preso: bool) -> void:
	jogador.em_dialogo = preso
	if "controlado" in jogador:
		jogador.set("controlado", preso)
	jogador.velocity = Vector2.ZERO
	jogador.andando = false


func _animar(acao: String) -> void:
	var visual := jogador.get_node_or_null("Corpo/Visual")
	if visual and "acao_forcada" in visual:
		visual.set("acao_forcada", acao)


func _atualizar_marca() -> void:
	var nome := segurando if segurando != "" else peca_perto()
	_marca.visible = nome != "" and nos_pecas.has(nome)
	if _marca.visible:
		var no: Node2D = nos_pecas[nome]
		_marca.position = no.position


# --- trechos ----------------------------------------------------------------

static func trecho_de(x: int) -> int:
	var achado := 0
	for i in TRECHOS.size():
		if x >= TRECHOS[i]:
			achado = i
	return achado


func _acompanhar_trecho() -> void:
	var novo := trecho_de(casa_do_jogador().x)
	if novo == trecho:
		return
	trecho = novo
	if trecho > trecho_maximo:
		trecho_maximo = trecho
		if not fotos.has(trecho):
			fotos[trecho] = obra.foto()
		jogador.definir_ponto_de_entrada(sala.centro(ENTRADAS[trecho]))
		if not atalho:
			_mostrar_dica(trecho)
	trecho_mudou.emit(trecho)


## Devolve o trecho atual como estava quando Nicholas chegou nele.
func recomecar_trecho() -> void:
	if atalho or concluido or _ocupado or not fotos.has(trecho):
		return
	soltar()
	obra.restaurar(fotos[trecho])
	_limpar_pedras()
	_desenhar_obra()
	_levar_jogador(ENTRADAS[trecho])


func _levar_jogador(casa: Vector2i) -> void:
	jogador.velocity = Vector2.ZERO
	jogador.andando = false
	jogador.esquivando = false
	jogador.position = sala.centro(casa)
	jogador.reset_physics_interpolation()
	var camera := jogador.get_node_or_null("Camera") as Camera2D
	if camera:
		camera.reset_smoothing()


func _mostrar_dica(i: int) -> void:
	if i < DICAS.size() and DICAS[i] != "" and escala_tempo > 0.0:
		aviso.mostrar(tr(DICAS[i]))


# --- pedras rolando ---------------------------------------------------------

## As pedras descem enquanto Nicholas está no trecho delas.
func pedras_ativas() -> bool:
	return not atalho and not concluido and trecho == TRECHO_PEDRAS


func _atualizar_pedras(delta: float) -> void:
	if not pedras_automaticas or not pedras_ativas():
		return
	for i in PISTAS.size():
		_relogios[i] += delta
		if _relogios[i] >= PERIODO_PEDRA:
			_relogios[i] = 0.0
			soltar_pedra(PISTAS[i])


## Uma pedra desce pela coluna [param x]: primeiro a sombra cresce no alto
## da pista, depois ela rola casa por casa até a beira. Quebra no que estiver
## no caminho (uma peça, a pedra fixa); em Nicholas, leva-o de volta ao
## começo do trecho (a não ser que ele esteja esquivando).
func soltar_pedra(x: int) -> void:
	var pedra := Node2D.new()
	pedra.name = "PedraRolando"
	pedra.position = sala.centro(Vector2i(x, -1))
	var sombra := Polygon2D.new()
	sombra.name = "Sombra"
	sombra.color = Color(0, 0, 0, 0.55)
	var pontos := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pontos.append(Vector2(cos(a) * 13.0, sin(a) * 6.5))
	sombra.polygon = pontos
	sombra.z_index = -1
	sombra.scale = Vector2.ONE * 0.2
	# Durante o aviso a sombra fica na primeira casa da estrada (o alto da
	# encosta fica atrás do paredão e não se vê).
	sombra.position = sala.centro(Vector2i(x, 0)) - pedra.position
	pedra.add_child(sombra)
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = load(ARTE + "pedra_rolando.png")
	visual.hframes = 4
	visual.offset = Vector2(0, -9)
	visual.visible = false
	pedra.add_child(visual)
	sala.add_child(pedra)
	pedras.append(pedra)
	_tocar("pedra_rolando")
	# O aviso: a sombra cresce antes de a pedra aparecer.
	if escala_tempo > 0.0:
		var aviso_tween := create_tween()
		aviso_tween.tween_property(sombra, "scale", Vector2.ONE, AVISO_PEDRA * escala_tempo)
		await aviso_tween.finished
	if not is_instance_valid(pedra):
		return
	sombra.scale = Vector2.ONE
	sombra.position = Vector2.ZERO
	visual.visible = true
	for y in range(0, obra.profundidade + 1):
		var casa := Vector2i(x, y)
		if obra.dentro(casa) and (obra.peca_em(casa) != "" or obra.terreno_em(casa) == ObraEstrada.Terreno.PEDRA):
			_quebrar(pedra)
			return
		await _mover([[pedra, sala.centro(casa)]], TEMPO_PEDRA_POR_CASA)
		if not is_instance_valid(pedra):
			return
		visual.frame = (visual.frame + 1) % 4
		if _pega_jogador(pedra):
			_acertar_jogador()
			_quebrar(pedra)
			return
	# Passou da beira: cai no precipício.
	pedras.erase(pedra)
	pedra.queue_free()


func _pega_jogador(pedra: Node2D) -> bool:
	if jogador.invulneravel():
		return false
	return pedra.position.distance_to(jogador.position) <= RAIO_PEDRA \
		or casa_do_jogador() == jogador.casa_de(pedra.global_position)


func _acertar_jogador() -> void:
	acertos += 1
	soltar()
	_tremer(4.0, 0.25)
	_levar_jogador(ENTRADAS[TRECHO_PEDRAS])
	var corpo := jogador.get_node("Corpo") as CanvasItem
	corpo.modulate.a = 0.0
	create_tween().tween_property(corpo, "modulate:a", 1.0, maxf(0.6 * escala_tempo, 0.01))


func _quebrar(pedra: Node2D) -> void:
	pedras.erase(pedra)
	_tocar("pedra_quebra")
	if escala_tempo > 0.0:
		var some := create_tween()
		some.tween_property(pedra, "scale", Vector2(1.4, 0.4), 0.12)
		some.parallel().tween_property(pedra, "modulate:a", 0.0, 0.12)
		some.tween_callback(pedra.queue_free)
	else:
		pedra.queue_free()


func _limpar_pedras() -> void:
	for pedra in pedras:
		if is_instance_valid(pedra):
			pedra.queue_free()
	pedras.clear()
	_relogios = [0.0, -ATRASO_SEGUNDA_PISTA]


# --- segredo, carroceiro, fim -----------------------------------------------

## O ninho só aparece de um ponto da encosta (sem texto: só cenário).
func _atualizar_ninho() -> void:
	var alvo := 1.0 if casa_do_jogador() == MIRANTE else 0.0
	ninho.modulate.a = move_toward(ninho.modulate.a, alvo, get_physics_process_delta_time() * 1.5)


func ninho_visivel() -> bool:
	return ninho.modulate.a > 0.5


func falar_com_carroceiro() -> void:
	_balao_em(carroceiro, "EOA3_CARROCEIRO_1" if not concluido else "EOA3_CARROCEIRO_FIM")


## Fala curta num balão sobre a cabeça de quem fala (sem caixa de diálogo).
func _balao_em(quem: Node2D, chave: String) -> void:
	if is_instance_valid(_balao):
		_balao.queue_free()
	_balao = Label.new()
	_balao.name = "Balao"
	_balao.text = tr(chave)
	_balao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_balao.autowrap_mode = TextServer.AUTOWRAP_WORD
	_balao.custom_minimum_size = Vector2(150, 0)
	_balao.position = Vector2(-75, -96)
	_balao.add_theme_font_size_override("font_size", 9)
	_balao.add_theme_color_override("font_color", Color(0.98, 0.94, 0.84))
	_balao.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_balao.add_theme_constant_override("outline_size", 3)
	_balao.z_index = 10
	quem.add_child(_balao)
	if escala_tempo > 0.0:
		var t := create_tween()
		t.tween_interval(3.5)
		t.tween_property(_balao, "modulate:a", 0.0, 0.5)
		t.tween_callback(_balao.queue_free)


## A última peça encaixou: a carroça passa por cima da obra e a fase acaba.
func concluir() -> void:
	if concluido:
		return
	concluido = true
	soltar()
	_limpar_pedras()
	_prender(true)
	Mundo.marcar_feito(ID)
	if carroceiro:
		carroceiro.hide()
		carroceiro.process_mode = Node.PROCESS_MODE_DISABLED
	_tocar("carroca")
	var caminho := obra.caminho(Vector2i(0, CASA_CARROCA.y), Vector2i(obra.largura - 1, SAIDA.y), true)
	caminho.push_front(CASA_CARROCA)
	caminho.append(Vector2i(obra.largura + 1, SAIDA.y))
	if carroca:
		await _andar_pelas_casas(carroca, caminho, TEMPO_CARROCA_POR_CASA)
		_balao_em(carroca, "EOA3_CARROCEIRO_FIM")
	await _frases(["EOA3_FIM_1"])
	concluida.emit()
	voltar_ao_mapa()


func voltar_ao_mapa() -> void:
	cena_pedida = CENA_MAPA
	if trocar_de_cena:
		TrocaCena.ir_para(CENA_MAPA)


func _frases(chaves: Array) -> void:
	if escala_tempo <= 0.0:
		return
	var frases: Array[String] = []
	for chave: String in chaves:
		frases.append(tr(chave))
	await texto.mostrar(frases)


func _tremer(forca: float, duracao: float) -> void:
	var camera := jogador.get_node_or_null("Camera") as CameraExploracao
	if camera and escala_tempo > 0.0:
		camera.tremer(forca, duracao)
