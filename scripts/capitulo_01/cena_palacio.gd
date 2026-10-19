class_name CenaPalacio
extends CenaCapitulo01
## Capítulo 01, cena 7: o pátio do Palácio Imperial (livro, l. ~255-315).
## Sequência (cada [member etapa] só avança na ordem):
## 1. patio: Nicholas anda pelo pátio e nota o que o livro diz: a fonte de
##    Althea e os poucos guardas (os dois são necessários; cada um anota no
##    Códice "olhar" quando é o caso).
## 2. ophelia: a Princesa sai do Palácio, é apresentada, os olhos azuis, o
##    riso e o pedido de passar numa loja.
## 3. embarque: os guardas recuam para o anexo; Nicholas ajuda as duas a
##    subir (E na carruagem).
## 4. ultimo_olhar: ele olha o anexo vazio (E no anexo), a Princesa vai sem
##    escolta e a carruagem parte.
## Ao terminar, a etapa vira "visao_carruagem" (cena 8, de outra frente: se
## [constant SequenciaCenas01.CENAS] tiver uma cena com essa chave, ela abre
## aqui; senão o jogo segue direto para a Rua das Butiques).
## Textos: data/dialogos/capitulo_01/palacio.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/palacio.dialogue")
## Centro da carruagem dentro da imagem dela: pés a esta altura da base.
const PE_CARRUAGEM := 88.0
const CASA_JOGADOR := Vector2i(4, 8)
const CASA_ANEXO := Vector2i(1, 5)
## Guardas do pátio (poucos): casas onde ficam.
const CASAS_GUARDAS: Array[Vector2i] = [Vector2i(4, 2), Vector2i(6, 2), Vector2i(9, 4)]

var fonte_vista := false
var guardas_vistos := false
var guardas: Array[Node2D] = []


func _init() -> void:
	roteiro = ROTEIRO
	objetivos = {"patio": "OBJ_CAP1_PATIO", "embarque": "OBJ_CAP1_EMBARQUE",
		"ultimo_olhar": "OBJ_CAP1_ANEXO"}


func id_da_cena() -> String:
	return "palacio"


func comecar() -> void:
	montar_patio()
	await _clarear()
	await _frases("frases_palacio_chegada")


func montar_patio() -> void:
	_nova_sala(11, 10, TOM_DIA, "patio", "marmore")
	_pendurar([["janela_alta_esq", Vector2i(2, 0)], ["estandarte_imperial_esq", Vector2i(4, 0)],
		["portal_palacio_esq", Vector2i(5, 0)], ["estandarte_imperial_esq", Vector2i(6, 0)],
		["janela_alta_esq", Vector2i(8, 0)], ["portal_anexo_dir", CASA_ANEXO - Vector2i(1, 0)]])
	_objeto("fonte", "palacio/fonte", Vector2i(5, 5), true, 14.0)
	for x in [1, 3, 7, 9]:
		_objeto("coluna_%d" % x, "margem/coluna", Vector2i(x, 1))
	for casa: Vector2i in [Vector2i(2, 3), Vector2i(2, 6), Vector2i(8, 3), Vector2i(8, 6)]:
		_objeto("canteiro_%d_%d" % [casa.x, casa.y], "palacio/canteiro_flores", casa)
	_objeto("cipreste_esq", "margem/cipreste", Vector2i(1, 8))
	_objeto("cipreste_dir", "margem/cipreste", Vector2i(9, 8))
	# A carruagem que os trouxe, e Althea ao lado de Nicholas.
	_objeto("carruagem", "rua/carruagem_parada", Vector2i(7, 8), true, PE_CARRUAGEM)
	_pessoa("althea", QUADROS_ALTHEA, Vector2i(3, 8))
	for i in CASAS_GUARDAS.size():
		var guarda := _pessoa("guarda_%d" % (i + 1), QUADROS_GUARDA, CASAS_GUARDAS[i], true)
		guardas.append(guarda)
		guarda.get_node("Interagivel").interagido.connect(olhar_guardas)
	_ponto("anexo", CASA_ANEXO)
	_entrar(CASA_JOGADOR)
	_ao_interagir("fonte", ver_fonte)
	_ao_interagir("carruagem", embarcar)
	_ao_interagir("anexo", olhar_anexo)
	_ativar(objetos["carruagem"], false)
	_ativar(objetos["anexo"], false)
	_mudar("patio")


# --- 1. o pátio ------------------------------------------------------------

func ver_fonte() -> void:
	if etapa != "patio" or fonte_vista:
		return
	fonte_vista = true
	_ativar(objetos["fonte"], false)
	_objetivo_do_patio()
	await _falar_travado("fonte")
	_travar(false)
	_verificar_patio()


func olhar_guardas() -> void:
	if etapa != "patio" or guardas_vistos:
		return
	guardas_vistos = true
	for guarda in guardas:
		_ativar(guarda, false)
	_objetivo_do_patio()
	await _frases("frases_poucos_guardas")
	_verificar_patio()


## No pátio, o objetivo diz o que ainda falta notar.
func _objetivo_do_patio() -> void:
	if fonte_vista and not guardas_vistos:
		_objetivo("OBJ_CAP1_PATIO_GUARDAS")
	elif guardas_vistos and not fonte_vista:
		_objetivo("OBJ_CAP1_PATIO_FONTE")


## Com a fonte e os guardas notados, a Princesa aparece.
func _verificar_patio() -> void:
	if etapa == "patio" and fonte_vista and guardas_vistos:
		await chegada_de_ophelia()


# --- 2. Ophelia -----------------------------------------------------------

func chegada_de_ophelia() -> void:
	_mudar("ophelia")
	_travar(true)
	var ophelia := _pessoa("ophelia", QUADROS_OPHELIA, Vector2i(5, 1))
	await _aparecer(ophelia)
	var destino := _casa_livre_perto(_casa_de(jogador), Vector2i(5, 3))
	await _caminhar(ophelia, [sala.centro(Vector2i(5, 3)), sala.centro(destino)])
	_virar(ophelia, jogador.position)
	jogador.direcao_olhar = (ophelia.position - jogador.position).normalized()
	# Althea vem para o lado de Nicholas.
	var althea: Node2D = objetos["althea"]
	var casa_althea := _casa_livre_perto(_casa_de(jogador), _casa_de(althea))
	await _caminhar(althea, [sala.centro(casa_althea)])
	_virar(althea, ophelia.position)
	await _falar_travado("apresentacao")
	await _frases("frases_olhos")
	await _falar_travado("ophelia_riu")
	await _falar_travado("pedido_loja")
	await recuo_dos_guardas()


# --- 3. os guardas recuam e o embarque -----------------------------------------

func recuo_dos_guardas() -> void:
	_mudar("embarque")
	for guarda in guardas:
		_recuar(guarda)
	await _frases("frases_anexo")
	while guardas.any(func(g: Node2D) -> bool: return g.visible):
		await get_tree().process_frame
	# (Se o jogador já embarcou, nada a liberar.)
	if etapa == "embarque":
		_travar(false)
		_ativar(objetos["carruagem"], true)


func _recuar(guarda: Node2D) -> void:
	await _caminhar(guarda, [sala.centro(CASA_ANEXO)], 2.5)
	await _sumir(guarda)


## "Nicholas ajuda as duas a subir na carruagem."
func embarcar() -> void:
	if etapa != "embarque":
		return
	_ativar(objetos["carruagem"], false)
	_travar(true)
	await _falar_travado("ajuda_a_subir")
	await _sumir(objetos["ophelia"])
	await _sumir(objetos["althea"])
	_mudar("ultimo_olhar")
	_travar(false)
	_ativar(objetos["anexo"], true)


# --- 4. o último olhar e a partida --------------------------------------------

func olhar_anexo() -> void:
	if etapa != "ultimo_olhar":
		return
	_ativar(objetos["anexo"], false)
	_travar(true)
	jogador.direcao_olhar = (objetos["anexo"].position - jogador.position).normalized()
	await _frases("frases_anexo_vazio")
	# Ele sobe na carruagem.
	jogador.get_node("Corpo").visible = false
	jogador.get_node("Sombra").visible = false
	await _falar_travado("escolta")
	await _frases("frases_partida")
	await terminar()
