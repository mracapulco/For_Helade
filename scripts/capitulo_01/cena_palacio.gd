class_name CenaPalacio
extends CenaCapitulo01
## Capítulo 01, cena 7: o pátio do Palácio Imperial (livro, l. ~255-315).
## O pátio é largo: a carruagem para no portão, atrás de Nicholas, e o
## caminho de mármore leva reto à fonte e, depois dela, ao Palácio.
## Sequência (cada [member etapa] só avança na ordem):
## 1. patio: Althea vê a fonte ("Nick… olha isso…") e corre até ela;
##    Nicholas a segue. No caminho passa pelos postos de guarda, quase todos
##    vazios, e nota os poucos guardas (Códice "olhar"). Ao chegar à fonte, a
##    Princesa aparece.
## 2. ophelia: a Princesa sai do Palácio, é apresentada, os olhos azuis, o
##    pedido de passar numa loja.
## 3. embarque: os guardas recuam para o anexo; Althea leva Ophelia até a
##    carruagem e Nicholas ajuda as duas a subir (E na carruagem).
## 4. ultimo_olhar: ele olha para o anexo vazio (virar-se para a porta, ir
##    até ela ou E nela), a Princesa vai sem escolta e a carruagem parte.
## Ao terminar, a etapa vira "visao_carruagem" (cena 8, de outra frente: se
## [constant SequenciaCenas01.CENAS] tiver uma cena com essa chave, ela abre
## aqui; senão o jogo segue direto para a Rua das Butiques).
## Textos: data/dialogos/capitulo_01/palacio.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/palacio.dialogue")
const LARGURA := 15
const PROFUNDIDADE := 14
## Centro da carruagem dentro da imagem dela: pés a esta altura da base.
const PE_CARRUAGEM := 88.0
## Nicholas desce da carruagem, que fica no portão, atrás dele.
const CASA_JOGADOR := Vector2i(7, 11)
const CASA_CARRUAGEM := Vector2i(7, 13)
const CASA_ALTHEA := Vector2i(6, 11)
const CASA_FONTE := Vector2i(7, 5)
## Onde Althea para, diante da fonte (do lado de quem chega).
const CASA_ALTHEA_FONTE := Vector2i(7, 6)
const CASA_PORTAL := Vector2i(7, 1)
const CASA_ANEXO := Vector2i(1, 11)
## Postos de guarda dos dois lados do caminho; só um tem guarda.
const CASAS_POSTOS: Array[Vector2i] = [Vector2i(5, 9), Vector2i(9, 9), Vector2i(5, 7), Vector2i(9, 7)]
## Guardas do pátio (poucos): um junto a um posto e dois no portal.
const CASAS_GUARDAS: Array[Vector2i] = [Vector2i(10, 7), Vector2i(6, 1), Vector2i(8, 1)]
## Passando desta linha (entre os postos), Nicholas nota os poucos guardas.
const LINHA_POSTOS := 8
## A esta distância (em casas) da fonte, ele chegou nela.
const PERTO_DA_FONTE := 2
## Althea e Ophelia esperam lado a lado, à direita da carruagem (do lado
## esquerdo, Althea ficava escondida atrás dela; Rafael, 26/10/2026), uma
## linha para dentro do pátio: em (8, 12) e (9, 12) apareciam por cima dos
## cavalos.
const CASAS_EMBARQUE: Array[Vector2i] = [Vector2i(9, 11), Vector2i(8, 11)]
## Onde cada um senta no banco da carruagem, ao longo dela (em casas, de trás
## para a frente): Althea, Ophelia e, por último, Nicholas.
const BANCO := {"althea": -0.9, "ophelia": 0.0, "nicholas": 0.9}
## Virado para o anexo por este tempo, conta como o último olhar.
const TEMPO_OLHANDO := 0.5
## Althea caminhando até a fonte (px/s).
const PASSO_DE_ALTHEA := 30.0

var fonte_vista := false
var guardas_vistos := false
var anexo_olhado := false
var guardas: Array[Node2D] = []
var _frases_dos_guardas := false
var _tempo_olhando := 0.0


func _init() -> void:
	roteiro = ROTEIRO
	objetivos = {"patio": "OBJ_CAP1_PATIO", "embarque": "OBJ_CAP1_EMBARQUE",
		"ultimo_olhar": "OBJ_CAP1_ANEXO"}


func id_da_cena() -> String:
	return "palacio"


func comecar() -> void:
	montar_patio()
	# Althea já sai andando para a fonte assim que a cena abre, durante as
	# primeiras frases, e fala no caminho (Rafael, 26/10/2026).
	althea_corre_para_a_fonte()
	await _clarear()
	await _frases("frases_palacio_chegada")
	await _falar_travado("fonte")
	_mudar("patio")
	_travar(false)


func montar_patio() -> void:
	_nova_sala(LARGURA, PROFUNDIDADE, TOM_DIA, "patio", "marmore")
	_pendurar([["janela_alta_esq", Vector2i(2, 0)], ["janela_alta_esq", Vector2i(4, 0)],
		["estandarte_imperial_esq", Vector2i(6, 0)], ["portal_palacio_esq", Vector2i(7, 0)],
		["estandarte_imperial_esq", Vector2i(8, 0)], ["janela_alta_esq", Vector2i(10, 0)],
		["janela_alta_esq", Vector2i(12, 0)], ["portal_anexo_dir", CASA_ANEXO - Vector2i(1, 0)]])
	_objeto("fonte", "palacio/fonte", CASA_FONTE, true, 14.0)
	for x in [1, 3, 5, 9, 11, 13]:
		_objeto("coluna_%d" % x, "margem/coluna", Vector2i(x, 1))
	for casa: Vector2i in [Vector2i(3, 4), Vector2i(3, 8), Vector2i(11, 4), Vector2i(11, 8)]:
		_objeto("canteiro_%d_%d" % [casa.x, casa.y], "palacio/canteiro_flores", casa)
	for casa: Vector2i in CASAS_POSTOS:
		_objeto("posto_%d_%d" % [casa.x, casa.y], "palacio/posto_guarda", casa)
	_objeto("cipreste_esq", "margem/cipreste", Vector2i(1, 12))
	_objeto("cipreste_dir", "margem/cipreste", Vector2i(13, 12))
	# A carruagem que os trouxe fica no portão; Althea desce ao lado de Nicholas.
	_objeto("carruagem", "rua/carruagem_parada", CASA_CARRUAGEM, true, PE_CARRUAGEM)
	_pessoa("althea", QUADROS_ALTHEA, CASA_ALTHEA)
	for i in CASAS_GUARDAS.size():
		guardas.append(_pessoa("guarda_%d" % (i + 1), QUADROS_GUARDA, CASAS_GUARDAS[i]))
	_ponto("anexo", CASA_ANEXO)
	_entrar(CASA_JOGADOR)
	jogador.direcao_olhar = (sala.centro(CASA_FONTE) - jogador.position).normalized()
	_ao_interagir("fonte", ver_fonte)
	_ao_interagir("carruagem", embarcar)
	_ao_interagir("anexo", olhar_anexo)
	_ativar(objetos["carruagem"], false)
	_ativar(objetos["anexo"], false)


## No pátio, andar é o que conta: passar pelos postos e chegar à fonte.
## No fim, virar-se para o anexo (ou ir até ele) é o último olhar.
func _physics_process(delta: float) -> void:
	if etapa == "patio" and not jogador.em_dialogo:
		var casa := _casa_de(jogador)
		if casa.y <= LINHA_POSTOS:
			olhar_guardas()
		var ate_a_fonte := (casa - CASA_FONTE).abs()
		if maxi(ate_a_fonte.x, ate_a_fonte.y) <= PERTO_DA_FONTE:
			ver_fonte()
	elif etapa == "ultimo_olhar" and not anexo_olhado and not jogador.em_dialogo:
		var rumo: Vector2 = objetos["anexo"].position - jogador.position
		var casa := _casa_de(jogador)
		if (casa - CASA_ANEXO).length() <= 2.0:
			olhar_anexo()
		elif jogador.direcao_olhar.normalized().dot(rumo.normalized()) >= 0.9:
			_tempo_olhando += delta
			if _tempo_olhando >= TEMPO_OLHANDO:
				olhar_anexo()
		else:
			_tempo_olhando = 0.0


# --- 1. o pátio: seguir Althea até a fonte -------------------------------------

## "Nick… olha isso…": ela corre na frente, pelo caminho de mármore.
func althea_corre_para_a_fonte() -> void:
	var althea: Node2D = objetos["althea"]
	# Andando (não correndo), para ainda estar a caminho nas primeiras frases.
	var meio := sala.centro(Vector2i(7, 10))
	await _caminhar(althea, [meio], althea.position.distance_to(meio) / PASSO_DE_ALTHEA)
	await _caminhar(althea, [sala.centro(CASA_ALTHEA_FONTE)],
		meio.distance_to(sala.centro(CASA_ALTHEA_FONTE)) / PASSO_DE_ALTHEA)
	_virar(althea, sala.centro(CASA_FONTE))


## Passando entre os postos, quase todos vazios.
func olhar_guardas() -> void:
	if etapa != "patio" or guardas_vistos:
		return
	guardas_vistos = true
	_frases_dos_guardas = true
	await _frases("frases_poucos_guardas")
	_frases_dos_guardas = false


## Chegando à fonte (ou E nela), a Princesa aparece.
func ver_fonte() -> void:
	if etapa != "patio" or fonte_vista:
		return
	fonte_vista = true
	_ativar(objetos["fonte"], false)
	_travar(true)
	if not guardas_vistos:
		await olhar_guardas()
	while _frases_dos_guardas:
		await get_tree().process_frame
	await chegada_de_ophelia()


# --- 2. Ophelia -----------------------------------------------------------

func chegada_de_ophelia() -> void:
	_mudar("ophelia")
	_travar(true)
	var ophelia := _pessoa("ophelia", QUADROS_OPHELIA, CASA_PORTAL)
	await _aparecer(ophelia)
	var destino := _casa_livre_perto(_casa_de(jogador), Vector2i(7, 3))
	# Pelo lado da fonte, sem passar por cima dela.
	var lado := 8 if destino.x > CASA_FONTE.x else 6
	var pontos: Array = [sala.centro(Vector2i(7, 3))]
	if destino.y > CASA_FONTE.y:
		pontos.append_array([sala.centro(Vector2i(lado, 4)), sala.centro(Vector2i(lado, destino.y))])
	pontos.append(sala.centro(destino))
	await _caminhar(ophelia, pontos)
	_virar(ophelia, jogador.position)
	jogador.direcao_olhar = (ophelia.position - jogador.position).normalized()
	# Althea vem para o lado de Nicholas.
	var althea: Node2D = objetos["althea"]
	var casa_althea := _casa_livre_perto(_casa_de(jogador), _casa_de(althea))
	await _caminhar(althea, [sala.centro(casa_althea)])
	_virar(althea, ophelia.position)
	await _falar_travado("apresentacao")
	await _frases("frases_olhos_de_ophelia")
	await _falar_travado("ophelia_riu")
	await _falar_travado("pedido_loja")
	await recuo_dos_guardas()


# --- 3. os guardas recuam e o embarque -----------------------------------------

## Althea puxa Ophelia até a carruagem; os guardas recuam para o anexo.
func recuo_dos_guardas() -> void:
	_mudar("embarque")
	for guarda in guardas:
		_recuar(guarda)
	var althea: Node2D = objetos["althea"]
	var ophelia: Node2D = objetos["ophelia"]
	_ir_a_carruagem(althea, CASAS_EMBARQUE[0])
	_ir_a_carruagem(ophelia, CASAS_EMBARQUE[1])
	await _frases("frases_anexo")
	while guardas.any(func(g: Node2D) -> bool: return g.visible) \
			or _casa_de(althea) != CASAS_EMBARQUE[0] or _casa_de(ophelia) != CASAS_EMBARQUE[1]:
		await get_tree().process_frame
	_virar(althea, jogador.position)
	_virar(ophelia, jogador.position)
	# (Se o jogador já embarcou, nada a liberar.)
	if etapa == "embarque":
		_travar(false)
		_ativar(objetos["carruagem"], true)


func _recuar(guarda: Node2D) -> void:
	await _caminhar(guarda, [sala.centro(CASA_ANEXO)], 2.5)
	await _sumir(guarda)


## Pelo caminho de mármore até o lado da carruagem.
func _ir_a_carruagem(pessoa: Node2D, casa: Vector2i) -> void:
	await _caminhar(pessoa, [sala.centro(Vector2i(casa.x, _casa_de(pessoa).y)), sala.centro(casa)], 1.4)


## "Nicholas ajuda as duas a subir na carruagem."
func embarcar() -> void:
	if etapa != "embarque":
		return
	_ativar(objetos["carruagem"], false)
	_travar(true)
	# (O "Obrigada." de Ophelia saiu a pedido do Rafael, 26/10/2026.)
	# As duas somem do lado da carruagem e aparecem sentadas lado a lado.
	_sumir(objetos["ophelia"])
	await _sumir(objetos["althea"])
	_aparecer(_sentar("althea", QUADROS_ALTHEA))
	await _aparecer(_sentar("ophelia", QUADROS_OPHELIA))
	_tempo_olhando = 0.0
	_mudar("ultimo_olhar")
	_travar(false)
	_ativar(objetos["anexo"], true)


# --- 4. o último olhar e a partida --------------------------------------------

func olhar_anexo() -> void:
	if etapa != "ultimo_olhar" or anexo_olhado:
		return
	anexo_olhado = true
	_ativar(objetos["anexo"], false)
	_travar(true)
	jogador.direcao_olhar = (objetos["anexo"].position - jogador.position).normalized()
	await _frases("frases_anexo_vazio")
	# Ele volta à porta da carruagem e sobe.
	await _andar(jogador, sala.centro(CASA_CARRUAGEM - Vector2i(0, 1)), 0.8).finished
	jogador.get_node("Corpo").visible = false
	jogador.get_node("Sombra").visible = false
	var quadros: SpriteFrames = jogador.get_node("Corpo/Visual").sprite_frames
	await _aparecer(_sentar("nicholas", quadros))
	await _falar_travado("escolta")
	await _frases("frases_partida")
	await terminar()


## Senta [param nome] no banco da carruagem parada (fica em
## [member objetos] como "<nome>_sentado"). A imagem parada é o fundo; quem
## senta fica por cima dela, e a frente (borda baixa, rodas, cavalos) é
## redesenhada por cima de todos, cobrindo o quadril.
func _sentar(nome: String, quadros: SpriteFrames) -> Sprite2D:
	var carruagem: Node2D = objetos["carruagem"]
	var visual: Sprite2D = carruagem.get_node("Visual")
	var frente: Sprite2D = carruagem.get_node_or_null("Frente")
	if frente == null:
		frente = Sprite2D.new()
		frente.name = "Frente"
		frente.texture = load(ARTE + "rua/carruagem_parada_frente.png")
		frente.offset = visual.offset
		carruagem.add_child(frente)
	# O centro da carruagem no chão, dentro do nó (a imagem é centrada).
	var origem := visual.offset - visual.texture.get_size() / 2.0 + Capitulo01.CARRO_ORIGEM
	var sprite := Sprite2D.new()
	sprite.name = (nome + "_sentado").to_pascal_case()
	sprite.texture = Capitulo01.imagem_sentada(quadros)
	sprite.centered = false
	sprite.position = origem + Capitulo01.ponto_carruagem(BANCO[nome], -0.38 + Capitulo01.COXA,
		Capitulo01.CARRO_CHAO)
	# Os pés no meio da largura do quadro em pé (como Capitulo01._sentado_em).
	var meio := (sprite.texture.get_width() - 2 * roundi(16.0 * Capitulo01.COXA)) / 2.0
	sprite.offset = Vector2(-meio, -sprite.texture.get_height())
	carruagem.add_child(sprite)
	carruagem.move_child(frente, -1)
	objetos[nome + "_sentado"] = sprite
	return sprite
