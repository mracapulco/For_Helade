class_name FaseFloresta
extends Node2D
## Fase "Árvores e mais árvores" da estrada Atenas–Olympia (oa_estrada_2):
## a mata em que toda clareira parece igual. O único guia é o som e o vento:
## a melodia distante soa da saída certa e as folhas voam para ela. Nas
## clareiras com eco, a marca riscada numa árvore desempata. A última clareira
## é a emboscada dos bandidos (a única luta das quatro fases da estrada); depois
## dela a melodia leva para fora da mata e o jogo volta ao mapa.
## As regras ficam no [LabirintoFloresta]; a clareira é montada pelo
## [ClareiraFloresta], refeita (com a navegação) a cada troca.
## Depois de vencida, a primeira clareira ganha uma placa de atalho.
## Bandidos, melodia, marcas e baú são inferência (não estão no livro).

signal clareira_mudou(resultado: int)
signal terminou

const LabirintoFloresta := preload("res://scripts/estrada_oa/floresta/labirinto_floresta.gd")
const CENA_MAPA := "res://scenes/mapa/mapa_helade.tscn"
const ID_LOCAL := "oa_estrada_2"
## Marca no Inventario (vale para o jogo salvo): a fase já foi vencida.
const ID_VENCIDA := "estrada_oa:floresta_vencida"
const ID_BAU := "estrada_oa:floresta_bau"
const SOM_VENTO := "res://assets/audio/sfx/estrada_oa/floresta/vento_floresta.wav"
const MUSICA_EMBOSCADA := "res://assets/audio/music/estrada_oa/emboscada.wav"
const PASTA_ARTE := "res://assets/art/placeholders/estrada_oa/floresta/"
const BARRAMENTO_EFEITOS := &"Efeitos"
## Duração de cada metade do escurecer entre clareiras.
const TEMPO_TROCA := 0.3
## Nas clareiras com eco, o vento troca de lado a cada tanto (rajadas indecisas).
const TEMPO_RAJADA := 1.6
## Quantas vezes o "de novo aqui" aparece ao errar (depois fica só o som).
const AVISOS_DE_ERRO := 2

## Os bandidos da emboscada (aparência inventada e provisória, Rafael 26/10).
## O da mata é o traiçoeiro: finge o golpe e bate pelas costas (Tic. Tac.).
const BANDIDOS: Array[Dictionary] = [
	{"nome": "BandidoPunhal", "textura": "res://assets/art/placeholders/exploracao/bandido_provisorio.png",
		"equipamento": ["punhal", "elmo_bandidos"], "vida": 25, "moedas": 5, "experiencia": 10},
	{"nome": "BandidoEscudo", "textura": "res://assets/art/placeholders/exploracao/bandido_escudo_provisorio.png",
		"equipamento": ["maca", "escudo_bandidos", "armadura_leve_bandidos"], "vida": 35, "moedas": 8, "experiencia": 15},
	{"nome": "BandidoDaMata", "textura": PASTA_ARTE + "bandido_mata.png",
		"equipamento": ["punhal"], "vida": 30, "moedas": 10, "experiencia": 20, "traicoeiro": true},
]
const ITENS_BAU: Dictionary[String, int] = {"pocao_cura": 2, "pocao_vigor": 1}
const MOEDAS_BAU := 15

@export var clareira: ClareiraFloresta
@export var personagem: PersonagemExploracao
@export var som_certo: AudioStreamPlayer2D
@export var som_eco: AudioStreamPlayer2D
@export var som_sopro: AudioStreamPlayer
@export var folhas: CPUParticles2D
@export var texto: TextoSolto
@export var cortina: ColorRect
@export var botao_mapa: Button
@export var titulo: Label
@export var interface: CanvasLayer
@export var textura_bau: Texture2D
@export var textura_bau_aberto: Texture2D
@export var textura_placa: Texture2D

## Quando falso, sair só anota a cena pedida, sem trocar (testes).
var trocar_de_cena := true
## Quando falso, a troca de clareira é na hora, sem escurecer (testes).
var animar := true
## Cena aberta pela última saída (para os testes); vazia quando nenhuma.
var cena_pedida := ""
var labirinto := LabirintoFloresta.new()
var navegacao: NavegacaoSala
var bandidos: Array[Inimigo] = []
var trocando := false
var acabou := false
var _erros := 0
var _tempo_rajada := 0.0
var _rajada_no_eco := false
var _saida_pedida := false


func _ready() -> void:
	botao_mapa.pressed.connect(voltar_ao_mapa)
	botao_mapa.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	titulo.text = "FLORESTA_TITULO"
	personagem.derrotado.connect(_ao_ser_derrotado)
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	# Sem música: o que guia é a melodia das saídas, por cima do vento.
	Trilha.parar()
	Trilha.ambientar(SOM_VENTO)
	labirinto.entrou_por = LabirintoFloresta.Saida.SUDOESTE
	_montar()
	texto.mostrar([tr("FLORESTA_FRASE_INICIO"), tr("FLORESTA_FRASE_ESCUTE")])


func _exit_tree() -> void:
	Trilha.ambientar("")


func _physics_process(delta: float) -> void:
	_soprar(delta)
	if trocando or acabou or _saida_pedida or personagem.em_dialogo:
		return
	# Nicholas aparece dois pisos para dentro da trilha por onde entrou; voltar
	# por ela também é uma saída (errada: a mesma clareira de novo).
	var saida := ClareiraFloresta.saida_na_celula(clareira.celula_de(personagem.global_position))
	if saida != LabirintoFloresta.NENHUMA:
		# Fora da física: a troca tira e põe árvores (corpos de colisão).
		_saida_pedida = true
		_sair_pedido.call_deferred(saida)


func _sair_pedido(saida: int) -> void:
	_saida_pedida = false
	sair_por(saida)


## Sai da clareira pelo lado [param saida] (o que o jogador faz andando até
## a beira de uma trilha). Devolve o [enum LabirintoFloresta.Resultado].
func sair_por(saida: int) -> int:
	if trocando or acabou:
		return LabirintoFloresta.Resultado.FECHADA
	var resultado := labirinto.sair(saida)
	match resultado:
		LabirintoFloresta.Resultado.FECHADA:
			texto.mostrar([tr("FLORESTA_FRASE_FECHADA")])
			_empurrar_para_dentro(saida)
			return resultado
		LabirintoFloresta.Resultado.SAIU:
			sair_da_mata()
			return resultado
	clareira_mudou.emit(resultado)
	if animar:
		_trocar_com_cortina(resultado)
	else:
		_ao_chegar(resultado)
	return resultado


func _trocar_com_cortina(resultado: int) -> void:
	trocando = true
	if som_sopro.stream:
		som_sopro.play()
	var escurecer := create_tween()
	escurecer.tween_property(cortina, "color:a", 1.0, TEMPO_TROCA)
	await escurecer.finished
	_ao_chegar(resultado)
	await get_tree().physics_frame
	var clarear := create_tween()
	clarear.tween_property(cortina, "color:a", 0.0, TEMPO_TROCA)
	await clarear.finished
	trocando = false


func _ao_chegar(resultado: int) -> void:
	_montar()
	match resultado:
		LabirintoFloresta.Resultado.VOLTOU:
			_erros += 1
			if _erros <= AVISOS_DE_ERRO:
				texto.mostrar([tr("FLORESTA_FRASE_DE_NOVO")])
		LabirintoFloresta.Resultado.SEGREDO:
			texto.mostrar([tr("FLORESTA_FRASE_ESCONDIDA")])
		LabirintoFloresta.Resultado.EMBOSCADA:
			comecar_emboscada()


## Refaz a clareira atual: árvores, navegação, sons, folhas e o que for só dela.
func _montar() -> void:
	var marcada := labirinto.saida_certa() if labirinto.tem_marca() else LabirintoFloresta.NENHUMA
	clareira.montar(labirinto.atual, marcada)
	if labirinto.na_escondida():
		_por_bau()
	if labirinto.atual == 0 and Inventario.ja_coletado(ID_VENCIDA):
		_por_placa_atalho()
	_refazer_navegacao()
	if labirinto.entrou_por != LabirintoFloresta.NENHUMA:
		personagem.global_position = clareira.ponto_de_entrada(labirinto.entrou_por)
		personagem.velocity = Vector2.ZERO
		personagem.reset_physics_interpolation()
		var camera := personagem.get_node_or_null("Camera") as Camera2D
		if camera:
			camera.reset_smoothing()
	_tocar_sons()


func _refazer_navegacao() -> void:
	if navegacao:
		remove_child(navegacao)
		navegacao.free()
	navegacao = NavegacaoSala.new()
	navegacao.name = "Navegacao"
	navegacao.chao = clareira.chao
	add_child(navegacao)


## A melodia sai da saída certa e o eco da outra, um pouco além da beira
## (como se viessem da mata). Os dois começam juntos.
func _tocar_sons() -> void:
	var certa := labirinto.saida_certa()
	var eco := labirinto.saida_eco()
	_tocar_em(som_certo, certa)
	_tocar_em(som_eco, eco if certa != LabirintoFloresta.NENHUMA else LabirintoFloresta.NENHUMA)
	_rajada_no_eco = false
	_tempo_rajada = 0.0
	_apontar_folhas(certa)


func _tocar_em(som: AudioStreamPlayer2D, saida: int) -> void:
	if saida == LabirintoFloresta.NENHUMA:
		som.stop()
		return
	som.global_position = clareira.ponto_da_saida(saida, 2)
	if som.stream:
		som.play()


## Folhas levadas para o lado [param saida]; sem saída, giram sem rumo.
func _apontar_folhas(saida: int) -> void:
	if saida == LabirintoFloresta.NENHUMA:
		folhas.direction = Vector2.RIGHT
		folhas.spread = 180.0
		folhas.gravity = Vector2.ZERO
		return
	var rumo := direcao_da_saida(saida)
	folhas.direction = rumo
	folhas.spread = 12.0
	folhas.gravity = rumo * 30.0


## Direção, na tela, do centro da clareira para a saída [param saida].
func direcao_da_saida(saida: int) -> Vector2:
	var centro := clareira.chao.to_global(clareira.chao.map_to_local(ClareiraFloresta.CENTRO))
	return centro.direction_to(clareira.ponto_da_saida(saida))


## Nas clareiras com eco, o vento sopra uma hora para cada lado: só pelas
## folhas não dá para saber, e a marca na árvore desempata.
func _soprar(delta: float) -> void:
	var eco := labirinto.saida_eco()
	if eco == LabirintoFloresta.NENHUMA or labirinto.saida_certa() == LabirintoFloresta.NENHUMA:
		return
	_tempo_rajada += delta
	if _tempo_rajada < TEMPO_RAJADA:
		return
	_tempo_rajada = 0.0
	_rajada_no_eco = not _rajada_no_eco
	_apontar_folhas(eco if _rajada_no_eco else labirinto.saida_certa())


## Chegou na beira de uma saída fechada: volta um passo para dentro.
func _empurrar_para_dentro(saida: int) -> void:
	var passo := ClareiraFloresta.passo_para_fora(saida)
	var celula := ClareiraFloresta.celula_da_saida(saida) - passo * 2
	personagem.global_position = clareira.chao.to_global(clareira.chao.map_to_local(celula))
	personagem.velocity = Vector2.ZERO


# ---------- emboscada ----------

## As marcas eram dos bandidos: eles saem da mata pelas trilhas, menos pela
## que Nicholas usou, e as saídas só abrem depois da luta.
func comecar_emboscada() -> void:
	if not bandidos.is_empty() or labirinto.bandidos_derrotados:
		return
	Trilha.tocar(MUSICA_EMBOSCADA, 0.5)
	texto.mostrar([tr("FLORESTA_FRASE_EMBOSCADA"), tr("FLORESTA_FRASE_MARCAS")])
	var lados: Array[int] = []
	for saida in 4:
		if saida != labirinto.entrou_por:
			lados.append(saida)
	for i in BANDIDOS.size():
		var bandido := criar_bandido(BANDIDOS[i])
		add_child(bandido)
		bandido.global_position = clareira.ponto_da_saida(lados[i % lados.size()])
		bandido.morreu.connect(_ao_derrotar_bandido.bind(bandido))
		bandidos.append(bandido)


## Monta um bandido como os da sala de teste (Inimigo com Vida, reação ao
## golpe e barrinha de vida). Vê de longe: a emboscada é para lutar.
func criar_bandido(dados: Dictionary) -> Inimigo:
	var bandido := Inimigo.new()
	bandido.name = dados.nome
	bandido.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	bandido.equipamento.assign(dados.equipamento)
	bandido.moedas = dados.moedas
	bandido.experiencia = dados.experiencia
	bandido.raio_visao = 600.0
	bandido.raio_desistir = 900.0
	if dados.get("traicoeiro", false):
		bandido.preparo = 0.9
		bandido.golpe_pelas_costas = true
		bandido.provoca_tic_tac = true
	bandido.grade = clareira.chao
	var sombra := Polygon2D.new()
	sombra.name = "Sombra"
	sombra.color = Color(0, 0, 0, 0.35)
	sombra.polygon = PackedVector2Array([Vector2(9, 0), Vector2(6, 3), Vector2(0, 4), Vector2(-6, 3),
		Vector2(-9, 0), Vector2(-6, -3), Vector2(0, -4), Vector2(6, -3)])
	bandido.add_child(sombra)
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = load(dados.textura)
	visual.offset = Vector2(0, -22)
	bandido.add_child(visual)
	var vida := Vida.new()
	vida.name = "Vida"
	vida.maxima = dados.vida
	bandido.add_child(vida)
	var reacao := ReacaoAoGolpe.new()
	reacao.name = "ReacaoAoGolpe"
	reacao.visual = visual
	reacao.vida = vida
	bandido.add_child(reacao)
	var barra := BarraVidaMundo.new()
	barra.name = "BarraVida"
	barra.position = Vector2(0, -50)
	barra.vida = vida
	bandido.add_child(barra)
	var forma := CollisionShape2D.new()
	forma.name = "Colisao"
	var circulo := CircleShape2D.new()
	circulo.radius = 9.0
	forma.shape = circulo
	bandido.add_child(forma)
	bandido.visual = visual
	bandido.vida = vida
	bandido.reacao = reacao
	return bandido


func _ao_derrotar_bandido(bandido: Inimigo) -> void:
	bandidos.erase(bandido)
	if bandidos.is_empty():
		# Fora da física: a vitória refaz a clareira (corpos de colisão).
		vencer_emboscada.call_deferred()


## Derrotados os bandidos, a melodia volta e mostra a saída da mata.
func vencer_emboscada() -> void:
	labirinto.bandidos_derrotados = true
	Trilha.parar(1.0)
	texto.mostrar([tr("FLORESTA_FRASE_VITORIA")])
	# A marca riscada aparece na saída: as marcas acabam aqui.
	clareira.montar(labirinto.atual, labirinto.saida_certa())
	_refazer_navegacao()
	_tocar_sons()


## Saiu pela última trilha (ou pela placa de atalho): a fase acaba e o jogo
## volta ao mapa, com Nicholas neste trecho da estrada.
func sair_da_mata() -> void:
	if acabou:
		return
	acabou = true
	Inventario.marcar_coletado(ID_VENCIDA)
	Mundo.local_no_mapa = ID_LOCAL
	som_certo.stop()
	som_eco.stop()
	texto.mostrar([tr("FLORESTA_FRASE_SAIDA")])
	terminou.emit()
	if animar:
		await get_tree().create_timer(1.6).timeout
	voltar_ao_mapa()


func voltar_ao_mapa() -> void:
	cena_pedida = CENA_MAPA
	if trocar_de_cena:
		TrocaCena.ir_para(CENA_MAPA)


# ---------- peças de uma clareira só ----------

## O segredo: um baú na clareira escondida (dá uma vez por jogo).
func _por_bau() -> void:
	var bau := _objeto("Bau", textura_bau, ClareiraFloresta.CENTRO + Vector2i(1, -1))
	var recompensa := Recompensa.new()
	recompensa.name = "Recompensa"
	recompensa.id_coleta = ID_BAU
	recompensa.itens = ITENS_BAU
	recompensa.moedas = MOEDAS_BAU
	recompensa.textura_vazio = textura_bau_aberto
	recompensa.visual = bau.get_node("Visual")
	recompensa.interagivel = bau.get_node("Interagivel")
	bau.add_child(recompensa)


## Depois de vencida, uma placa no começo leva direto para fora da mata.
func _por_placa_atalho() -> void:
	var placa := _objeto("PlacaAtalho", textura_placa, ClareiraFloresta.CENTRO + Vector2i(1, 2))
	(placa.get_node("Interagivel") as Interagivel).interagido.connect(sair_da_mata)


## Objeto com que se interage (baú, placa), guardado nas peças da clareira
## para sumir na próxima troca.
func _objeto(nome: String, textura: Texture2D, celula: Vector2i) -> StaticBody2D:
	var corpo := StaticBody2D.new()
	corpo.name = nome
	corpo.add_to_group(ClareiraFloresta.GRUPO_OBSTACULOS)
	corpo.position = clareira.chao.map_to_local(celula)
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = textura
	CenarioAcampamento._apoiar_no_chao(visual)
	corpo.add_child(visual)
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 9.0
	forma.shape = circulo
	corpo.add_child(forma)
	var interagivel := Interagivel.new()
	interagivel.name = "Interagivel"
	var toque := CollisionShape2D.new()
	toque.name = "AreaDeToque"
	var area := CircleShape2D.new()
	area.radius = 28.0
	toque.shape = area
	toque.position = Vector2(0, -12)
	interagivel.add_child(toque)
	corpo.add_child(interagivel)
	clareira._guardar(corpo)
	return corpo


func _ao_ser_derrotado() -> void:
	# Volta para a entrada da clareira em que está (não para o começo da mata).
	var entrada := labirinto.entrou_por if labirinto.entrou_por != LabirintoFloresta.NENHUMA \
		else LabirintoFloresta.Saida.SUDOESTE
	personagem.global_position = clareira.ponto_de_entrada(entrada)


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	interface.hide()


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	interface.show()
