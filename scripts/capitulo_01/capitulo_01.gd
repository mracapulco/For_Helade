class_name Capitulo01
extends Node2D
## Capítulo 01, "A garota do corredor" (Parte I do livro), passo 1: o
## pesadelo e a manhã do aniversário de Althea na Mansão Olympia, em Atenas.
## Sequência (cada [member etapa] só avança na ordem):
## 1. sonho: corredor quente (o ar tremendo, poeira dourada no ar), Nicholas
##    segue a garota; quando chega até ela, ela se vira e a porta se abre
##    para o frio.
## 2. quarto: Nicholas acorda de pijama; pega a roupa no armário (camisa
##    branca e colete azul escuro), se veste no espelho e só então a porta
##    leva ao corredor.
## 3. corredor: na porta de Althea ele espera ("esperando"): olha para as
##    duas extremidades do corredor e só então o cortejo de Pany chega com o
##    bolo (escolha: reclamar da demora ou não).
## 4. quarto_althea: acordar Althea (a cama, duas vezes); ela se senta e pula
##    da cama ("aniversario"); Nicholas entrega o embrulho ("embrulho",
##    depois "espada"); os presentes; ela vai para a mesa de chá, e falar com
##    ela à mesa é sentar junto.
## 5. duque: Apollon entra, discute com Nicholas e manda os dois buscarem a
##    Princesa Ophelia; depois Althea e Nicholas mudam os planos do dia.
## 6. carruagem: Nicholas olha pelas janelas (códice) e a caminho do Palácio
##    Imperial vem a conversa ("Está bravo comigo, Nick?").
## 7. palacio: a manhã termina e o jogo segue para a cena do Palácio Imperial
##    (scripts/capitulo_01/cena_palacio.gd), que encadeia as seguintes
##    (ordem em [SequenciaCenas01]).
## O que Nicholas encontra vira nota no [code]Codice[/code] ("olhar").
## As salas são montadas por código ([SalaMontada]); os textos estão em
## data/dialogos/capitulo_01/manha.dialogue.

signal etapa_mudou(etapa: String)

const ROTEIRO := preload("res://data/dialogos/capitulo_01/manha.dialogue")
const CENA_JOGADOR := preload("res://scenes/capitulo_01/nicholas_11.tscn")
const CENA_OBJETIVO := preload("res://scenes/ui/objetivo.tscn")
## Objetivo na tela de cada etapa jogável (chave de i18n/strings.csv); no
## quarto ele muda com o que Nicholas já fez ([method _objetivo_da_etapa]).
const OBJETIVOS := {
	"corredor": "OBJ_CAP1_PORTA_ALTHEA",
	"esperando": "OBJ_CAP1_OLHAR_PONTAS",
	"quarto_althea": "OBJ_CAP1_ACORDAR",
	"embrulho": "OBJ_CAP1_EMBRULHO",
	"a_mesa": "OBJ_CAP1_MESA_CHA",
}
const QUADROS_PIJAMA := preload("res://assets/art/personagens/nicholas/nicholas_11_pijama_exploracao.tres")
const QUADROS_VESTIDO := preload("res://assets/art/personagens/nicholas/nicholas_11_exploracao.tres")
const QUADROS_APOLLON := preload("res://assets/art/personagens/apollon/apollon_exploracao.tres")
const QUADROS_ALTHEA := preload("res://assets/art/personagens/althea/althea_6_exploracao.tres")
const CRIADA := preload("res://assets/art/placeholders/exploracao/criada_provisoria.png")
const ARTE := "res://assets/art/capitulo_01/"
## O ar do sonho treme de leve, como calor (só no sonho).
const TREMOR_DO_SONHO := preload("res://scripts/capitulo_01/tremor_do_sonho.gdshader")
## O relógio lento do sonho ("Tic. Tac."), em loop enquanto o sonho dura.
const TIC_TAC := preload("res://assets/audio/sfx/capitulo_01/tic_tac.wav")
## No sonho Nicholas anda devagar (e não corre): só alcança a garota perto da
## porta, depois de as frases passarem (Rafael, 17/10/2026).
const VELOCIDADE_NO_SONHO := 26.0
## Quanto a garota leva para ir até a porta (um pouco mais rápida que ele).
const TEMPO_DA_GAROTA := 5.0
## Móveis em caixa isométrica (armário, baú): o centro da casa fica a esta
## altura da base da imagem (tools/arte/gerar_capitulo_01.py, PE_CAIXA).
const PE_CAIXA := 17.0
## Onde fica o assento do banco da carruagem, acima do centro da casa, e a
## linha do quadril nas folhas dos personagens (quadros de 32×48).
const ALTURA_ASSENTO := 12.0
const LINHA_QUADRIL := 37
## Comprimento da coxa de quem está sentado, em casas.
const COXA := 0.25
## Centro da carruagem no chão, dentro das imagens dela, e a altura do piso.
const CARRO_ORIGEM := Vector2(150, 128)
const CARRO_CHAO := 18.0
## A rua e as margens andam uma casa a cada tanto (o mesmo para as duas, para
## não escorregarem uma sobre a outra); a paisagem se repete a cada tantas casas.
const SEGUNDOS_POR_CASA := 0.8
const PERIODO_MARGEM := 10

## Luz de cada momento.
const TOM_SONHO := Color(1.0, 0.7, 0.5)
const TOM_FRIO := Color(0.55, 0.72, 1.0)
const TOM_MADRUGADA := Color(0.55, 0.62, 0.88)
const TOM_AMANHECER := Color(1.0, 0.9, 0.74)

## As duas extremidades do corredor (casas do chão) para onde Nicholas olha
## enquanto espera o cortejo.
const EXTREMIDADES := {"extremidade_esq": Vector2i(1, 1), "extremidade_dir": Vector2i(16, 1)}
## Casa do chão diante da porta de Althea, onde Nicholas espera.
const PORTA_ALTHEA_CHAO := Vector2i(5, 1)
## Para onde ele olha (na tela) quando vira para cada extremidade.
const RUMO_EXTREMIDADES := {"extremidade_esq": Vector2(-2, -1), "extremidade_dir": Vector2(2, 1)}
## Quanto tempo virado para uma extremidade conta como olhar para ela.
const TEMPO_OLHANDO := 0.5

## Multiplica os tempos (os testes usam 0: tudo acontece na hora).
@export var escala_tempo := 1.0
## Falso nos testes: as conversas passam direto, sem abrir a caixa.
@export var mostrar_dialogos := true
## Para onde o jogo vai no fim deste passo.
@export var cena_depois := SequenciaCenas01.CENAS["palacio"]

var etapa := ""
var sala: SalaMontada
var jogador: PersonagemExploracao
## Cena pedida no fim (para os testes); vazia até lá.
var cena_pedida := ""
## Quando falso, o fim só anota a cena pedida, sem trocar (testes).
var trocar_de_cena := true
## Nicholas já pegou no armário a roupa separada na noite anterior.
var pegou_roupas := false
## Nicholas já trocou o pijama pela roupa do dia, no espelho.
var viu_espelho := false
## Já está com a roupa do dia (a troca no espelho terminou).
var vestido := false
## Extremidades do corredor para onde Nicholas já olhou, esperando o cortejo.
var extremidades_vistas: Array[String] = []
## Onde fica o Corpo de Nicholas (x) antes do passo para o lado da espada.
var _corpo_x := 0.0
## Onde fica o desenho de Nicholas sentado (para ele se inclinar e voltar).
var _offset_sentado_x := 0.0
## Brilho das janelas das pontas do corredor, até ele olhar por elas.
var brilhos := {}
## Para onde ele olhava quando começou a esperar, e quanto tempo já está
## virado para cada extremidade.
var _olhar_na_porta := Vector2.ZERO
var _tempo_olhando := {}
## Quantas vezes Nicholas já tocou Althea na cama.
var toques_na_cama := 0
## A garota do sonho andando até a porta.
var _andar_garota: Tween
## O ar do sonho (poeira dourada e o tremor do calor), só no sonho.
var _ar_do_sonho: CanvasLayer
## Velocidade e corrida de Nicholas antes do sonho, para devolver ao acordar.
var _passo_fora_do_sonho := Vector2.ZERO

## Objetos da sala atual que a sequência usa.
var objetos := {}
## A linha do objetivo no alto da tela ([Objetivo]).
var objetivo: Objetivo

@onready var texto: TextoSolto = %Texto
@onready var cortina: ColorRect = %Cortina


func _ready() -> void:
	jogador = CENA_JOGADOR.instantiate()
	jogador.name = "Nicholas"
	_vestir(QUADROS_PIJAMA)
	cortina.color.a = 1.0
	objetivo = CENA_OBJETIVO.instantiate()
	add_child(objetivo)
	objetivo.observar(texto)
	comecar()


func comecar() -> void:
	_mudar("abertura")
	await _frases("frases_abertura")
	await montar_sonho()


# --- 1. o sonho ----------------------------------------------------------

func montar_sonho() -> void:
	_nova_sala(12, 3, TOM_SONHO)
	# Um corredor "não familiar": sem a pedra nem os enfeites da Casa Olympia.
	sala.parede_lisa = true
	sala.abrir_vao(Vector2i(0, 1))
	# A porta não é o ponto de ação: a cena avança quando Nicholas chega até
	# a garota e ela se vira para ele (Rafael, 17/10/2026).
	_objeto("porta_sonho", "porta.png", Vector2i(0, 1))
	var garota := sala.adicionar_objeto("Garota", load(ARTE + "garota_visao.png"), Vector2i(7, 1), false)
	# Sólida: Nicholas não passa por dentro dela. Fica fora da navegação
	# (ela anda), então o corpo é só para a colisão.
	var corpo := StaticBody2D.new()
	corpo.name = "Corpo"
	var colisao := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = SalaMontada.RAIO_CORPO
	colisao.shape = forma
	corpo.add_child(colisao)
	garota.add_child(corpo)
	objetos["garota"] = garota
	_entrar(Vector2i(10, 2))
	_mudar("sonho")
	_ligar_ar_do_sonho(true)
	_passo_fora_do_sonho = Vector2(jogador.velocidade, jogador.multiplicador_corrida)
	jogador.velocidade = VELOCIDADE_NO_SONHO
	jogador.multiplicador_corrida = 1.0
	# Ela segue pelo corredor um pouco mais rápido que ele e para diante da
	# porta: ele só a alcança ali, quando as frases já passaram.
	_andar_garota = _andar(garota, sala.centro(Vector2i(2, 1)), TEMPO_DA_GAROTA)
	await _clarear()
	_frases("frases_sonho")


## Nicholas chegou até a garota: ela se vira para ele ("À sua frente, ela
## parou. E nada disse."), a porta atrás dela se abre para o frio e o sonho
## termina.
func chegar_na_garota() -> void:
	if etapa != "sonho":
		return
	_mudar("porta_do_sonho")
	_travar(true)
	if _andar_garota:
		_andar_garota.kill()
	var garota: Node2D = objetos["garota"]
	(garota.get_node("Visual") as Sprite2D).texture = load(ARTE + "garota_visao_frente.png")
	jogador.direcao_olhar = (garota.position - jogador.position).normalized()
	await _esperar(0.6)
	(objetos["porta_sonho"].get_node("Visual") as Sprite2D).texture = load(ARTE + "porta_aberta.png")
	_tingir(TOM_FRIO, 0.4)
	await _frases("frases_porta_do_sonho")
	await _escurecer()
	_ligar_ar_do_sonho(false)
	jogador.velocidade = _passo_fora_do_sonho.x
	jogador.multiplicador_corrida = _passo_fora_do_sonho.y
	await montar_quarto()


## Garota e Nicholas em casas vizinhas (inclusive na diagonal).
func perto_da_garota() -> bool:
	if not objetos.has("garota"):
		return false
	var dela := sala.chao.local_to_map(objetos["garota"].position)
	var diferenca := _casa_de(jogador) - dela
	return maxi(absi(diferenca.x), absi(diferenca.y)) <= 1


## No sonho, poeira dourada flutua devagar, o ar treme como calor e um
## relógio lento marca "Tic. Tac.": o corredor não é real (Rafael, 17/10/2026).
func _ligar_ar_do_sonho(ligar: bool) -> void:
	if _ar_do_sonho:
		_ar_do_sonho.queue_free()
		_ar_do_sonho = null
	if not ligar:
		return
	_ar_do_sonho = CanvasLayer.new()
	_ar_do_sonho.name = "ArDoSonho"
	var tremor := ColorRect.new()
	tremor.name = "Tremor"
	tremor.set_anchors_preset(Control.PRESET_FULL_RECT)
	tremor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = TREMOR_DO_SONHO
	tremor.material = material
	_ar_do_sonho.add_child(tremor)
	var tela := get_viewport().get_visible_rect().size
	var poeira := CPUParticles2D.new()
	poeira.name = "Poeira"
	poeira.position = tela / 2.0
	poeira.amount = 90
	poeira.lifetime = 7.0
	poeira.preprocess = 7.0
	poeira.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	poeira.emission_rect_extents = tela / 2.0
	poeira.direction = Vector2(0, -1)
	poeira.spread = 60.0
	poeira.gravity = Vector2(0, -4)
	poeira.initial_velocity_min = 3.0
	poeira.initial_velocity_max = 10.0
	poeira.scale_amount_min = 2.0
	poeira.scale_amount_max = 4.0
	var brilho := Gradient.new()
	brilho.set_color(0, Color(1.0, 0.85, 0.5, 0.0))
	brilho.set_color(1, Color(1.0, 0.85, 0.5, 0.0))
	brilho.add_point(0.5, Color(1.0, 0.85, 0.5, 0.75))
	poeira.color_ramp = brilho
	_ar_do_sonho.add_child(poeira)
	var relogio := AudioStreamPlayer.new()
	relogio.name = "TicTac"
	relogio.stream = TIC_TAC
	relogio.bus = &"Efeitos"
	relogio.volume_db = -6.0
	relogio.autoplay = true
	_ar_do_sonho.add_child(relogio)
	add_child(_ar_do_sonho)
	# Abaixo da cortina, das frases e dos botões.
	move_child(_ar_do_sonho, 1)


# --- 2. o quarto de Nicholas --------------------------------------------

func montar_quarto() -> void:
	_nova_sala(7, 6, TOM_MADRUGADA)
	sala.abrir_vao(Vector2i(6, 0))
	_objeto("cama", "cama_nicholas.png", Vector2i(2, 2))
	_movel("armario", "armario.png", Vector2i(4, 1), true).get_node("Interagivel") \
		.interagido.connect(pegar_roupas)
	_movel("bau", "bau.png", Vector2i(1, 2))
	_objeto("espelho", "espelho.png", Vector2i(1, 4), true).get_node("Interagivel") \
		.interagido.connect(olhar_espelho)
	_objeto("porta_quarto", "porta.png", Vector2i(6, 0), true).get_node("Interagivel") \
		.interagido.connect(sair_do_quarto)
	# Como no quarto dele no castelo: o baú embaixo do quadro de Olympia.
	_pendurar({"tapecaria_esq": Vector2i(2, 0), "arandela_esq": Vector2i(5, 0),
		"quadro_olympia_dir": Vector2i(0, 2)})
	_entrar(Vector2i(3, 3))
	# A porta só depois de se vestir.
	_ativar(objetos["porta_quarto"], false)
	_mudar("quarto")
	await _clarear()
	_frases("frases_despertar")


## "Vestiu uma camisa branca e o colete azul escuro que havia separado na
## noite anterior": a roupa sai do armário.
func pegar_roupas() -> void:
	if etapa != "quarto" or pegou_roupas:
		return
	pegou_roupas = true
	_ativar(objetos["armario"], false)
	_objetivo_da_etapa()
	Codice.anotar("roupas_simples")


func olhar_espelho() -> void:
	if etapa != "quarto" or viu_espelho:
		return
	if not pegou_roupas:
		# Sem a roupa, o espelho só mostra o quarto (e ele, pequeno diante dele).
		_frases("frases_espelho_sem_roupa")
		return
	viu_espelho = true
	_ativar(objetos["espelho"], false)
	_travar(true)
	# Troca o pijama pela camisa branca e o colete azul escuro.
	await _escurecer()
	_vestir(QUADROS_VESTIDO)
	vestido = true
	_objetivo_da_etapa()
	await _clarear()
	_travar(false)
	_ativar(objetos["porta_quarto"], true)
	await _frases("frases_espelho")


func sair_do_quarto() -> void:
	if etapa != "quarto" or not vestido:
		return
	_mudar("saindo_do_quarto")
	_travar(true)
	await _escurecer()
	await montar_corredor()


# --- 3. o corredor e o cortejo ------------------------------------------

func montar_corredor() -> void:
	# Um corredor com outras portas (fechadas); oito passos entre a porta dele
	# e a de Althea.
	_nova_sala(17, 3, TOM_MADRUGADA)
	sala.piso = "passadeira"
	# Portas fechadas ficam na própria parede; só a de Althea, o destino, é
	# um vão com a porta.
	for x in [2, 9, 13]:
		var nome := "porta_nicholas" if x == 13 else "porta_fechada_%d" % x
		objetos[nome] = sala.pendurar(nome.to_pascal_case(), load(ARTE + "parede/porta_esq.png"), Vector2i(x, 0))
	sala.abrir_vao(Vector2i(5, 0))
	_objeto("porta_althea", "porta.png", Vector2i(5, 0), true).get_node("Interagivel") \
		.interagido.connect(esperar_cortejo)
	# Como o corredor do Castelo Olympia no prólogo: tochas, quadros do mapa,
	# tapeçarias e a espada sobre a placa.
	_pendurar({"tapecaria_esq": Vector2i(1, 0), "tocha_esq": Vector2i(4, 0),
		"quadro_atenas_esq": Vector2i(7, 0), "tocha_esq#2": Vector2i(8, 0),
		"espada_placa_esq": Vector2i(11, 0), "tocha_esq#3": Vector2i(12, 0),
		"quadro_norte_esq": Vector2i(14, 0), "tocha_esq#4": Vector2i(15, 0),
		"tapecaria_dir": Vector2i(0, 2)})
	# As duas pontas do corredor terminam numa janela, para onde ele olha
	# enquanto espera (a faixa dourada do amanhecer entra por elas).
	objetos["janela_esq"] = sala.pendurar("JanelaEsq", load(ARTE + "parede/janela_alta_dir.png"), Vector2i(0, 1))
	objetos["janela_dir"] = sala.pendurar("JanelaDir", load(ARTE + "parede/janela_alta_esq.png"), Vector2i(16, 0))
	# Para onde ele olha enquanto espera: as duas extremidades do corredor.
	for nome: String in EXTREMIDADES:
		_ponto(nome, EXTREMIDADES[nome]).get_node("Interagivel").interagido \
			.connect(olhar_extremidade.bind(nome))
	_entrar(Vector2i(13, 1))
	# Só depois de entrar na árvore (o _ready do Interagivel o liga de novo).
	for nome: String in EXTREMIDADES:
		_ativar(objetos[nome], false)
	_mudar("corredor")
	await _clarear()


## Esperando na porta, virar para uma das pontas do corredor (ou andar até
## ela) por um instante conta como olhar para aquela extremidade.
func _physics_process(delta: float) -> void:
	if etapa == "sonho" and perto_da_garota():
		chegar_na_garota()
		return
	if etapa != "esperando" or jogador.direcao_olhar.is_equal_approx(_olhar_na_porta):
		return
	_olhar_na_porta = Vector2.INF
	for nome: String in RUMO_EXTREMIDADES:
		if extremidades_vistas.has(nome):
			continue
		var rumo: Vector2 = RUMO_EXTREMIDADES[nome].normalized()
		if jogador.direcao_olhar.normalized().dot(rumo) < 0.95:
			_tempo_olhando[nome] = 0.0
			continue
		_tempo_olhando[nome] = _tempo_olhando.get(nome, 0.0) + delta
		if _tempo_olhando[nome] >= TEMPO_OLHANDO:
			olhar_extremidade(nome)


func esperar_cortejo() -> void:
	if etapa != "corredor":
		return
	_mudar("esperando")
	_ativar(objetos["porta_althea"], false)
	_tingir(TOM_AMANHECER, 6.0)
	_frases("frases_esperando")
	for nome: String in EXTREMIDADES:
		_ativar(objetos[nome], true)
	# Basta virar para uma ponta (sem ir até lá) para olhar para ela.
	_olhar_na_porta = jogador.direcao_olhar
	_tempo_olhando.clear()
	# As janelas das pontas brilham até ele olhar por elas.
	for janela: String in ["janela_esq", "janela_dir"]:
		var brilho := create_tween().set_loops()
		brilho.tween_property(objetos[janela], "modulate", Color(1.6, 1.4, 1.0), 0.6)
		brilho.tween_property(objetos[janela], "modulate", Color.WHITE, 0.6)
		brilhos[janela] = brilho


## "Ele olhou para uma das extremidades do corredor. Depois para a outra.
## Nada." Depois das duas, o cortejo chega.
func olhar_extremidade(nome: String) -> void:
	if etapa != "esperando" or extremidades_vistas.has(nome):
		return
	extremidades_vistas.append(nome)
	_ativar(objetos[nome], false)
	var janela := "janela_esq" if nome == "extremidade_esq" else "janela_dir"
	if brilhos.has(janela):
		brilhos[janela].kill()
		brilhos.erase(janela)
		objetos[janela].modulate = Color.WHITE
	jogador.direcao_olhar = (objetos[janela].position - jogador.position).normalized()
	if extremidades_vistas.size() == 1:
		Codice.anotar("faixa_dourada")
	if extremidades_vistas.size() < EXTREMIDADES.size():
		_frases("frases_nada")
		return
	_mudar("cortejo")
	_travar(true)
	await _frases("frases_nada")
	await _frases("frases_cortejo_chega")
	# Se ele ficou longe, volta para a porta de Althea (num piscar de olhos)
	# antes de o cortejo chegar.
	if _casa_de(jogador).distance_to(PORTA_ALTHEA_CHAO) > 2.0:
		await _escurecer()
		jogador.position = sala.centro(PORTA_ALTHEA_CHAO)
		jogador.direcao_olhar = Vector2(-2, 1).normalized()
		await _clarear()
	await _chegada_do_cortejo()


func _chegada_do_cortejo() -> void:
	# O pequeno cortejo surge ao longe e vem até a porta.
	var chegadas := {
		"pany": [Vector2i(1, 2), Vector2i(4, 2)],
		"carrinho": [Vector2i(1, 1), Vector2i(3, 2)],
		"criada_1": [Vector2i(1, 2), Vector2i(3, 1)],
		"criada_2": [Vector2i(1, 1), Vector2i(2, 2)],
	}
	var texturas := {
		"pany": load(ARTE + "pany_provisoria.png"),
		"carrinho": load(ARTE + "carrinho_bolo.png"),
		"criada_1": CRIADA,
		"criada_2": CRIADA,
	}
	var ultimo: Tween
	for nome: String in chegadas:
		var objeto := sala.adicionar_objeto(nome.capitalize(), texturas[nome], chegadas[nome][0], false)
		objetos[nome] = objeto
		ultimo = _andar(objeto, sala.centro(chegadas[nome][1]), 5.0)
	if ultimo and ultimo.is_running():
		await ultimo.finished
	await _falar("cortejo")
	await _escurecer()
	await montar_quarto_althea()


# --- 4. o quarto de Althea ----------------------------------------------

func montar_quarto_althea() -> void:
	_nova_sala(7, 6, TOM_AMANHECER)
	objetos["porta"] = sala.pendurar("Porta", load(ARTE + "parede/porta_esq.png"), Vector2i(5, 0))
	_objeto("cama_althea", "cama_althea.png", Vector2i(2, 2), true).get_node("Interagivel") \
		.interagido.connect(acordar_althea)
	_movel("armario", "armario.png", Vector2i(3, 1))
	_movel("bau", "bau.png", Vector2i(1, 1))
	_objeto("embrulho", "embrulho.png", Vector2i(1, 3), true).get_node("Interagivel") \
		.interagido.connect(entregar_embrulho)
	_objeto("mesa", "mesa_cha.png", Vector2i(4, 4))
	# Pany acende as seis velas enquanto as criadas arrumam o café.
	_objeto("carrinho", "carrinho_bolo_aceso.png", Vector2i(5, 4))
	_objeto("pany", "pany_provisoria.png", Vector2i(5, 2))
	objetos["criada_1"] = sala.adicionar_objeto("Criada1", CRIADA, Vector2i(6, 3))
	objetos["criada_2"] = sala.adicionar_objeto("Criada2", CRIADA, Vector2i(6, 2))
	_pendurar({"arandela_esq": Vector2i(2, 0), "quadro_olympia_esq": Vector2i(4, 0),
		"arandela_esq#2": Vector2i(6, 0), "tapecaria_dir": Vector2i(0, 4)})
	_entrar(Vector2i(3, 3))
	# O embrulho só depois de Althea sair da cama.
	_ativar(objetos["embrulho"], false)
	_mudar("quarto_althea")
	await _clarear()
	_frases("frases_quarto_althea")


## Primeiro toque: "Ela resmungou e apertou a pelúcia." No segundo, Nicholas
## puxa o monstro marinho e ela acorda.
func acordar_althea() -> void:
	if etapa != "quarto_althea":
		return
	toques_na_cama += 1
	if toques_na_cama == 1:
		Codice.anotar("monstro_marinho")
		_frases("frases_resmungou")
		return
	_mudar("aniversario")
	_ativar(objetos["cama_althea"], false)
	_travar(true)
	await _frases("frases_puxou")
	await _falar("acordar_althea")
	await _levantar_althea()
	# "O embrulho comprido apoiado ao lado da cama": Nicholas o entrega.
	_travar(false)
	_ativar(objetos["embrulho"], true)
	_mudar("embrulho")


func entregar_embrulho() -> void:
	if etapa != "embrulho":
		return
	_mudar("espada")
	_ativar(objetos["embrulho"], false)
	_corpo_x = jogador.get_node("Corpo").position.x
	DialogueManager.got_dialogue.connect(_ao_ver_fala_da_espada)
	await _falar("espada")
	DialogueManager.got_dialogue.disconnect(_ao_ver_fala_da_espada)
	_fim_da_espada()
	objetos["embrulho"].visible = false
	_mudar("presentes")
	Codice.anotar("presentes")
	await _frases("frases_presentes")
	# Quando a agitação diminui, Althea vai para a mesa de chá; falar com ela
	# é sentar junto.
	var althea: Node2D = objetos["althea"]
	await _caminhar(althea, sala.centro(Vector2i(3, 4)), 1.6)
	_virar(althea, sala.centro(Vector2i(4, 4)))
	_ativar(althea, true)
	_mudar("a_mesa")


## Com a espada de madeira: Althea golpeia o ar na direção de Nicholas
## (enquanto Nicholas adulto narra o presente); ele finge rendição (as mãos para cima) ou desvia com um
## passo curto para o lado enquanto ela golpeia de novo.
func _ao_ver_fala_da_espada(linha: DialogueLine) -> void:
	match linha.static_id:
		"CAP1_051":
			_golpe_de_althea()
		"CAP1_099":
			_pose_de_nicholas(&"rendicao")
		"CAP1_100":
			_golpe_de_althea()
			# o passo é para o lado contrário ao dela
			var lado := 1.0 if jogador.position.x >= objetos["althea"].position.x else -1.0
			_mover_suave(jogador.get_node("Corpo"), "position:x", _corpo_x + lado * 6.0)


func _golpe_de_althea() -> void:
	var althea: Node2D = objetos.get("althea")
	if althea == null:
		return
	var visual: AnimatedSprite2D = althea.get_node("Visual")
	visual.play(&"golpe_frente")
	_virar(althea, jogador.position)
	visual.frame = 0
	visual.play()


## Nicholas numa pose fora das que o desenho escolhe sozinho (a animação do
## jogador fica parada até [method _fim_da_espada]).
func _pose_de_nicholas(acao: StringName) -> void:
	var visual: AnimatedSprite2D = jogador.get_node("Corpo/Visual")
	visual.set_process(false)
	visual.play("%s_%s" % [acao, visual.animation.get_slice("_", 1)])


## Fim da conversa: todos voltam ao parado (e Nicholas ao lugar).
func _fim_da_espada() -> void:
	var visual: AnimatedSprite2D = jogador.get_node("Corpo/Visual")
	visual.set_process(true)
	visual.play("parado_%s" % visual.animation.get_slice("_", 1))
	_mover_suave(jogador.get_node("Corpo"), "position:x", _corpo_x)
	var althea: Node2D = objetos.get("althea")
	if althea:
		var dela: AnimatedSprite2D = althea.get_node("Visual")
		dela.play("parado_%s" % dela.animation.get_slice("_", 1))


## Althea se senta na cama, pula para o chão e vai até o embrulho.
func _levantar_althea() -> void:
	var cama: Sprite2D = objetos["cama_althea"].get_node("Visual")
	cama.texture = load(ARTE + "cama_althea_sentada.png")
	await _esperar(0.6)
	cama.texture = load(ARTE + "cama_althea_vazia.png")
	var althea := sala.adicionar_pessoa("Althea", QUADROS_ALTHEA, Vector2i(2, 2), true)
	objetos["althea"] = althea
	_ativar(althea, false)
	althea.get_node("Interagivel").interagido.connect(sentar_a_mesa)
	# O pulo: sobe e desce enquanto vai da cama para o chão, do lado onde
	# Nicholas está.
	var visual: AnimatedSprite2D = althea.get_node("Visual")
	var destino := sala.centro(lado_da_cama_perto_de_nicholas())
	_virar(althea, destino)
	var tempo := maxf(0.45 * escala_tempo, 0.01)
	var pulo := create_tween().set_parallel()
	pulo.tween_property(althea, "position", destino, tempo)
	pulo.tween_method(func(t: float) -> void: visual.offset.y = -22.0 - sin(t * PI) * 10.0, 0.0, 1.0, tempo)
	await pulo.finished
	visual.offset.y = -22.0
	_virar(althea, jogador.position)


## Casa livre ao lado da cama de Althea mais perto de Nicholas (nunca a dele).
func lado_da_cama_perto_de_nicholas() -> Vector2i:
	var cama := Vector2i(2, 2)
	var dele := sala.chao.local_to_map(jogador.position)
	var ocupadas := [dele, Vector2i(1, 3), Vector2i(3, 1), Vector2i(1, 1)]   # Nicholas, embrulho, armário, baú
	var melhor := Vector2i(3, 2)
	var menor := INF
	for passo: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(-1, 1)]:
		var casa := cama + passo
		if ocupadas.has(casa):
			continue
		var distancia := sala.centro(casa).distance_to(jogador.position)
		if distancia < menor:
			menor = distancia
			melhor = casa
	return melhor


## Personagem sentado no banco: o quadro parado, de frente, cortado no quadril.
func _sentado_em(nome: String, quadros: SpriteFrames, pai: Node2D, posicao: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = nome
	sprite.texture = imagem_sentada(quadros)
	sprite.centered = false
	sprite.position = posicao
	# Os pés no meio da largura do quadro em pé, à esquerda da imagem.
	var meio := (sprite.texture.get_width() - 2 * roundi(16.0 * COXA)) / 2.0
	sprite.offset = Vector2(-meio, -sprite.texture.get_height())
	pai.add_child(sprite)
	return sprite


## A pessoa sentada, montada do quadro em pé: o tronco até o quadril, as coxas
## indo para a frente (para +b, que na tela é para baixo e à esquerda) e as
## canelas descendo até o chão. A base da imagem é o chão sob os pés, no meio
## dos pés; o quadril fica [constant COXA] casa para trás e
## [constant ALTURA_ASSENTO] pixels acima do chão.
## [param tronco]: de qual animação vem o tronco (de costas, para olhar pela
## janela de trás); [param espelhar] vira só o tronco para a esquerda (as
## pernas continuam para a frente, como quem gira no banco).
static func imagem_sentada(quadros: SpriteFrames, tronco := &"parado_frente", espelhar := false) -> ImageTexture:
	var corpo := _quadro_parado(quadros, &"parado_frente")
	var de_cima := _quadro_parado(quadros, tronco)
	if espelhar:
		de_cima.flip_x()
	var largura := corpo.get_width()
	var pe := corpo.get_used_rect().end.y - 1
	# A coxa, em pixels da tela: anda COXA casa em +b (2 px para a esquerda a
	# cada 1 para baixo).
	var desce := int(round(16.0 * COXA))
	var recua := 2 * desce
	var canela := int(ALTURA_ASSENTO)
	var altura := LINHA_QUADRIL + desce + canela
	var sentada := Image.create(largura + recua, altura, false, Image.FORMAT_RGBA8)
	sentada.blit_rect(de_cima, Rect2i(0, 0, largura, LINHA_QUADRIL), Vector2i(recua, 0))
	# Coxas: a linha do quadril, deslizando para baixo e para a esquerda.
	for k in desce:
		var linha := LINHA_QUADRIL + mini(k, 1)
		sentada.blit_rect(corpo, Rect2i(0, linha, largura, 1), Vector2i(recua - 2 * (k + 1), LINHA_QUADRIL + k))
	# Canelas e pés: o resto das pernas, esticado até o chão.
	var origem := LINHA_QUADRIL + 2
	var fonte := pe - origem + 1
	for i in canela:
		var linha := origem + int(float(i) * fonte / canela)
		sentada.blit_rect(corpo, Rect2i(0, linha, largura, 1), Vector2i(0, LINHA_QUADRIL + desce + i))
	return ImageTexture.create_from_image(sentada)


static func _quadro_parado(quadros: SpriteFrames, animacao: StringName) -> Image:
	var quadro := quadros.get_frame_texture(animacao, 0) as AtlasTexture
	var folha := quadro.atlas.get_image()
	if folha.is_compressed():
		folha.decompress()
	folha.convert(Image.FORMAT_RGBA8)
	return folha.get_region(Rect2i(quadro.region))


## Muda a pose de quem está sentado na carruagem.
func _pose(nome: String, quadros: SpriteFrames, tronco: StringName, espelhar: bool) -> void:
	var sprite: Sprite2D = objetos.get(nome)
	if sprite:
		sprite.texture = imagem_sentada(quadros, tronco, espelhar)


## Na carruagem, cada fala do menu da janela move a cena: Nicholas gira no
## banco para a janela escolhida e a câmera vai junto; de volta ao menu, ele
## volta a olhar para a frente.
func _ao_ver_fala_na_carruagem(linha: DialogueLine) -> void:
	match linha.static_id:
		"CAP1_104":
			_olhar_janela(true)
		"CAP1_105":
			_olhar_janela(false)
		_:
			if not linha.responses.is_empty():
				_olhar_janela_fim()


func _olhar_janela(esquerda: bool) -> void:
	# A janela da esquerda fica na parede da esquerda (acima e à esquerda na
	# tela); a da direita, na parede do fundo, atrás do banco.
	_pose("nicholas_sentado", QUADROS_VESTIDO, &"parado_costas", esquerda)
	var lado := Vector2(-1, -0.5) if esquerda else Vector2(1, -0.5)
	_mover_suave(objetos["nicholas_sentado"], "offset:x", _offset_sentado_x + lado.x * 2.0)
	_mover_suave(jogador.get_node("Camera"), "offset", lado * 28.0)


func _olhar_janela_fim() -> void:
	_pose("nicholas_sentado", QUADROS_VESTIDO, &"parado_frente", false)
	_mover_suave(objetos["nicholas_sentado"], "offset:x", _offset_sentado_x)
	_mover_suave(jogador.get_node("Camera"), "offset", Vector2.ZERO)


## "Voltar-se para Althea": os dois se viram um para o outro.
func _voltar_para_althea() -> void:
	_olhar_janela_fim()
	_pose("nicholas_sentado", QUADROS_VESTIDO, &"parado_frente", true)
	_pose("althea", QUADROS_ALTHEA, &"parado_frente", false)
	await _esperar(0.4)


func _mover_suave(no: Node, propriedade: String, valor: Variant) -> void:
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(no, propriedade, valor, 0.35)


## Conversa na caixa e, quando ela fecha, Nicholas continua parado (a caixa
## o solta sozinha um instante depois de fechar).
func _falar_travado(marcador: String) -> void:
	await _falar(marcador)
	if mostrar_dialogos:
		await get_tree().create_timer(0.25).timeout
	_travar(true)


func _casa_de(no: Node2D) -> Vector2i:
	return sala.chao.local_to_map(no.position)


## Casa do chão ao lado de [param casa] que ninguém ocupa, a mais perto de
## [param de_onde].
func _casa_livre_perto(casa: Vector2i, de_onde: Vector2i) -> Vector2i:
	var ocupadas: Array[Vector2i] = [_casa_de(jogador)]
	for nome: String in objetos:
		var objeto: Node2D = objetos[nome]
		if is_instance_valid(objeto) and objeto.get_parent() == sala and not objeto is Sprite2D:
			ocupadas.append(_casa_de(objeto))
	var melhor := casa
	var menor := INF
	for passo: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		var vizinha := casa + passo
		if vizinha.x < 1 or vizinha.y < 1 or vizinha.x >= sala.largura or vizinha.y >= sala.profundidade:
			continue
		if ocupadas.has(vizinha):
			continue
		var distancia := Vector2(vizinha - de_onde).length()
		if distancia < menor:
			menor = distancia
			melhor = vizinha
	return melhor


## Uma pessoa anda até [param destino], com a animação de andar virada para lá.
func _caminhar(pessoa: Node2D, destino: Vector2, tempo: float) -> void:
	var visual: AnimatedSprite2D = pessoa.get_node("Visual")
	_virar(pessoa, destino)
	visual.play(visual.animation.replace("parado", "andando"))
	await _andar(pessoa, destino, tempo).finished
	visual.play(visual.animation.replace("andando", "parado"))


## Vira a pessoa para o ponto: frente (para baixo) ou costas, espelhada para a esquerda.
func _virar(pessoa: Node2D, alvo: Vector2) -> void:
	var visual := pessoa.get_node("Visual") as AnimatedSprite2D
	if visual == null:
		return
	var direcao := alvo - pessoa.position
	var acao := visual.animation.get_slice("_", 0)
	visual.play("%s_%s" % [acao, "frente" if direcao.y >= 0.0 else "costas"])
	visual.flip_h = direcao.x < 0.0


func _esperar(segundos: float) -> void:
	if escala_tempo > 0.0:
		await get_tree().create_timer(segundos * escala_tempo).timeout


func sentar_a_mesa() -> void:
	if etapa != "a_mesa":
		return
	_ativar(objetos["althea"], false)
	_mudar("mesa")
	_travar(true)
	await _frases("frases_mesa")
	await _frases("frases_duque")
	await chegada_do_duque()


# --- 5. o duque ------------------------------------------------------------

func chegada_do_duque() -> void:
	_mudar("duque")
	# Apollon entra pela porta e vai até Nicholas.
	var apollon := sala.adicionar_pessoa("Apollon", QUADROS_APOLLON, Vector2i(5, 1))
	objetos["apollon"] = apollon
	apollon.modulate.a = 0.0
	await create_tween().tween_property(apollon, "modulate:a", 1.0, maxf(0.4 * escala_tempo, 0.01)).finished
	await _caminhar(apollon, sala.centro(_casa_livre_perto(_casa_de(jogador), Vector2i(5, 1))), 1.4)
	_virar(apollon, jogador.position)
	_pose_de_althea(&"espada_colo")
	DialogueManager.got_dialogue.connect(_ao_ver_fala_do_duque)
	await _falar_travado("duque")
	DialogueManager.got_dialogue.disconnect(_ao_ver_fala_do_duque)
	_pose_de_althea(&"parado")
	# O duque parte quase tão depressa quanto chegou.
	await _caminhar(apollon, sala.centro(Vector2i(5, 1)), 1.4)
	await create_tween().tween_property(apollon, "modulate:a", 0.0, maxf(0.4 * escala_tempo, 0.01)).finished
	objetos.erase("apollon")
	apollon.queue_free()
	await _falar_travado("planos")
	await _frases("frases_por_que")
	await _escurecer()
	await montar_carruagem()


## À mesa, Althea segura a espada de madeira no colo enquanto o duque fala;
## no "P-parem de brigar...", aperta o punho da espada contra o peito.
func _ao_ver_fala_do_duque(linha: DialogueLine) -> void:
	if linha.static_id == "CAP1_070":
		_pose_de_althea(&"abraca_espada")


## Althea numa pose, virada para o mesmo lado (frente ou costas).
func _pose_de_althea(acao: StringName) -> void:
	var althea: Node2D = objetos.get("althea")
	if althea == null or not althea.has_node("Visual"):
		return
	var visual: AnimatedSprite2D = althea.get_node("Visual")
	var lado := "costas" if visual.animation.ends_with("costas") else "frente"
	visual.play("%s_%s" % [acao, lado])


# --- 6. a carruagem ----------------------------------------------------------

func montar_carruagem() -> void:
	# A rua de pedra, sem paredes, e a carruagem por fora, em corte: as rodas
	# giram e a rua corre para trás (Rafael, 15/10: a sala de paredes grossas
	# não parecia um veículo).
	_nova_sala(30, 17, TOM_AMANHECER)
	sala.piso = "estrada"
	sala.sem_paredes = true
	var casa := Vector2i(15, 8)
	var carro := Node2D.new()
	carro.name = "Carruagem"
	carro.z_index = 1
	carro.position = sala.centro(casa)
	sala.add_child(carro)
	carro.add_child(_parte_do_carro("Fundo", "carruagem_fundo.png", 1))
	# Os dois lado a lado no banco, sentados, com os pés no chão da carruagem
	# rente à beira do assento.
	objetos["althea"] = _sentado_em("Althea", QUADROS_ALTHEA, carro, ponto_carruagem(-0.7, -0.38 + COXA, CARRO_CHAO))
	objetos["nicholas_sentado"] = _sentado_em("NicholasSentado", QUADROS_VESTIDO, carro,
		ponto_carruagem(0.3, -0.38 + COXA, CARRO_CHAO))
	var frente := _parte_do_carro("Frente", "carruagem_frente.png", 3)
	carro.add_child(frente)
	_entrar(casa)
	_travar(true)
	jogador.get_node("Corpo").visible = false
	jogador.get_node("Sombra").visible = false
	# Mais perto, para ver os dois dentro da carruagem.
	var camera: Camera2D = jogador.get_node("Camera")
	var zoom_antes := camera.zoom
	camera.zoom = zoom_antes * 1.2
	_mudar("carruagem")
	var balanco := create_tween().set_loops()
	balanco.tween_property(carro, "position:y", carro.position.y + 1.0, 0.35)
	balanco.tween_property(carro, "position:y", carro.position.y, 0.35)
	var rodas := create_tween().set_loops()
	rodas.tween_callback(func() -> void: frente.frame = (frente.frame + 1) % 3).set_delay(0.12)
	# Duas casas por volta, para o desenho alternado das lajes emendar.
	var rua := create_tween().set_loops()
	rua.tween_property(sala.chao, "position", Vector2(-64, -32), 2 * SEGUNDOS_POR_CASA).from(Vector2.ZERO)
	var margens := _margens_da_rua()
	var paisagem := create_tween().set_loops()
	for margem in margens:
		paisagem.parallel().tween_property(margem, "position", -PERIODO_MARGEM * Vector2(32, 16),
			PERIODO_MARGEM * SEGUNDOS_POR_CASA).from(Vector2.ZERO)
	await _clarear()
	Codice.anotar("imperatriz_callie")
	await _frases("frases_carruagem")
	# Antes da conversa, Nicholas olha pelas janelas (até se voltar para Althea).
	_offset_sentado_x = objetos["nicholas_sentado"].offset.x
	DialogueManager.got_dialogue.connect(_ao_ver_fala_na_carruagem)
	await _falar_travado("janela")
	DialogueManager.got_dialogue.disconnect(_ao_ver_fala_na_carruagem)
	await _voltar_para_althea()
	await _falar_travado("carruagem")
	await _escurecer()
	balanco.kill()
	rodas.kill()
	rua.kill()
	paisagem.kill()
	camera.zoom = zoom_antes
	jogador.get_node("Corpo").visible = true
	jogador.get_node("Sombra").visible = true
	# Encadeia: a manhã termina e o Palácio Imperial (cena_palacio.gd) começa.
	_mudar("palacio")
	cena_pedida = cena_depois
	if trocar_de_cena:
		TrocaCena.ir_para(cena_depois)


# --- ajudas ---------------------------------------------------------------

## Ponto da carruagem em pixels, a partir do centro dela no chão: [param a] e
## [param b] em casas, [param h] em pixels de altura. É a mesma conta de
## tools/arte/gerar_capitulo_01.py (_carro_t), que desenha a carruagem.
static func ponto_carruagem(a: float, b: float, h: float) -> Vector2:
	return Vector2(32.0 * (a - b), 16.0 * (a + b) - h)


## As margens da rua passando: do outro lado, ciprestes, oliveiras e colunas
## (atrás da carruagem); do lado de cá, só coisas baixas (canteiros e uma
## coluna ou outra), para não esconder Nicholas e Althea. O desenho se repete a
## cada [constant PERIODO_MARGEM] casas, e o laço volta sem emenda.
func _margens_da_rua() -> Array[Node2D]:
	var longe := Node2D.new()
	longe.name = "MargemLonge"
	longe.y_sort_enabled = true
	var perto := Node2D.new()
	perto.name = "MargemPerto"
	perto.y_sort_enabled = true
	perto.z_index = 2
	sala.add_child(longe)
	sala.add_child(perto)
	var sorte := RandomNumberGenerator.new()
	sorte.seed = 1012
	var meio := sala.profundidade / 2
	var altas := ["cipreste", "cipreste", "cipreste", "oliveira", "oliveira", "oliveira", "coluna",
		"canteiro", "canteiro"]
	var baixas := ["canteiro", "canteiro", "canteiro", "canteiro", "coluna"]
	for x0 in PERIODO_MARGEM:
		for y in range(meio - 8, meio - 1):
			if sorte.randf() < 0.3:
				_enfeite_da_margem(longe, altas[sorte.randi() % altas.size()], x0, y, sorte)
		for y in range(meio + 2, meio + 9):
			if sorte.randf() < 0.14:
				_enfeite_da_margem(perto, baixas[sorte.randi() % baixas.size()], x0, y, sorte)
	return [longe, perto]


## Põe o mesmo enfeite em x0, x0 + período, x0 + 2 períodos..., ao longo da
## rua inteira, para a paisagem se repetir enquanto corre.
func _enfeite_da_margem(margem: Node2D, nome: String, x0: int, y: int, sorte: RandomNumberGenerator) -> void:
	var textura: Texture2D = load(ARTE + "margem/%s.png" % nome)
	var desvio := Vector2(sorte.randf_range(-8, 8), sorte.randf_range(-3, 3))
	var x := x0
	while x < sala.largura + PERIODO_MARGEM:
		var enfeite := Sprite2D.new()
		enfeite.texture = textura
		enfeite.centered = false
		enfeite.offset = Vector2(-textura.get_width() / 2.0, -textura.get_height() + 3)
		enfeite.position = sala.centro(Vector2i(x, y)) + desvio
		margem.add_child(enfeite)
		x += PERIODO_MARGEM


## Uma das duas imagens da carruagem (mesma origem: o centro no chão).
func _parte_do_carro(nome: String, arquivo: String, quadros: int) -> Sprite2D:
	var parte := Sprite2D.new()
	parte.name = nome
	parte.texture = load(ARTE + arquivo)
	parte.hframes = quadros
	parte.centered = false
	parte.offset = -CARRO_ORIGEM
	return parte


func _mudar(nova: String) -> void:
	etapa = nova
	_objetivo_da_etapa()
	etapa_mudou.emit(nova)


## Chave do objetivo agora ("" quando não há o que fazer: cenas e conversas).
func chave_do_objetivo() -> String:
	if etapa == "quarto":
		if vestido:
			return "OBJ_CAP1_SAIR_QUARTO"
		return "OBJ_CAP1_ESPELHO" if pegou_roupas else "OBJ_CAP1_ROUPA"
	return OBJETIVOS.get(etapa, "")


func _objetivo_da_etapa() -> void:
	if objetivo:
		objetivo.definir(chave_do_objetivo())


func _nova_sala(largura: int, profundidade: int, tom: Color) -> void:
	if sala:
		if jogador.get_parent() == sala:
			sala.remove_child(jogador)
		# Sai da árvore já: senão os móveis da sala velha entram na navegação
		# da nova (o mesmo grupo de obstáculos) e fecham casas que estão livres.
		if sala.get_parent():
			sala.get_parent().remove_child(sala)
		sala.queue_free()
	objetos.clear()
	sala = SalaMontada.new()
	sala.name = "Sala"
	sala.largura = largura
	sala.profundidade = profundidade
	sala.tom = tom


## Um objeto da sala com a arte de assets/art/capitulo_01/, guardado em
## [member objetos] pelo nome.
func _objeto(nome: String, arquivo: String, casa: Vector2i, interagivel := false) -> Node2D:
	var objeto := sala.adicionar_objeto(nome.to_pascal_case(), load(ARTE + arquivo), casa, true, interagivel)
	objetos[nome] = objeto
	return objeto


## Troca a folha de animação de Nicholas (pijama ou roupa do dia).
func _vestir(quadros: SpriteFrames) -> void:
	var visual: AnimatedSprite2D = jogador.get_node("Corpo/Visual")
	var animacao := visual.animation
	visual.sprite_frames = quadros
	visual.play(animacao)


## Enfeites da parede (assets/art/capitulo_01/parede/<nome>.png); "#2" no
## fim do nome repete o mesmo desenho em outra casa.
func _pendurar(enfeites: Dictionary) -> void:
	for chave: String in enfeites:
		var arquivo := chave.get_slice("#", 0)
		sala.pendurar(chave.replace("#", "").to_pascal_case(), load(ARTE + "parede/" + arquivo + ".png"),
			enfeites[chave])


## Móvel em caixa isométrica, alinhado com as paredes.
func _movel(nome: String, arquivo: String, casa: Vector2i, interagivel := false) -> Node2D:
	var objeto := sala.adicionar_objeto(nome.to_pascal_case(), load(ARTE + arquivo), casa, true,
		interagivel, PE_CAIXA)
	objetos[nome] = objeto
	return objeto


## Ponto invisível do chão com que dá para interagir (para onde olhar),
## guardado em [member objetos] pelo nome. Não bloqueia a passagem.
func _ponto(nome: String, casa: Vector2i) -> Node2D:
	var ponto := Node2D.new()
	ponto.name = nome.to_pascal_case()
	ponto.position = sala.centro(casa)
	var area := Interagivel.new()
	area.name = "Interagivel"
	var toque := CollisionShape2D.new()
	toque.name = "AreaDeToque"
	var forma := CircleShape2D.new()
	forma.radius = SalaMontada.RAIO_TOQUE
	toque.shape = forma
	area.add_child(toque)
	ponto.add_child(area)
	sala.add_child(ponto)
	objetos[nome] = ponto
	return ponto


## Põe a sala pronta na cena e Nicholas na casa.
func _entrar(casa: Vector2i) -> void:
	add_child(sala)
	move_child(sala, 0)
	sala.receber_jogador(jogador, casa)
	_travar(false)


func _travar(travado: bool) -> void:
	jogador.em_dialogo = travado
	jogador.andando = false
	jogador.alvo_interacao = null
	jogador.velocity = Vector2.ZERO


## Liga ou desliga a interação de um objeto (o anel dourado some junto).
func _ativar(objeto: Node2D, ativo: bool) -> void:
	var area := objeto.get_node_or_null("Interagivel") as Interagivel
	if area == null:
		return
	if ativo:
		area.add_to_group(Interagivel.GRUPO_INTERAGIVEIS)
		area.collision_layer = Interagivel.CAMADA_INTERAGIVEIS
	else:
		area.remove_from_group(Interagivel.GRUPO_INTERAGIVEIS)
		area.collision_layer = 0
	area.set_process(ativo)
	area.destacado = false
	area.queue_redraw()


func _andar(objeto: Node2D, destino: Vector2, tempo: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(objeto, "position", destino, maxf(tempo * escala_tempo, 0.01))
	return tween


func _tingir(cor: Color, tempo: float) -> void:
	if sala and sala.ambiente:
		create_tween().tween_property(sala.ambiente, "color", cor, maxf(tempo * escala_tempo, 0.01))


func _escurecer() -> void:
	var tween := create_tween()
	tween.tween_property(cortina, "color:a", 1.0, maxf(0.8 * escala_tempo, 0.01))
	await tween.finished


func _clarear() -> void:
	var tween := create_tween()
	tween.tween_property(cortina, "color:a", 0.0, maxf(0.8 * escala_tempo, 0.01))
	await tween.finished


## Frases do roteiro que aparecem e somem sozinhas.
func _frases(marcador: String) -> void:
	var frases: Array[String] = []
	var linha: DialogueLine = await ROTEIRO.get_next_dialogue_line(marcador)
	while linha:
		frases.append(linha.text)
		linha = await ROTEIRO.get_next_dialogue_line(linha.next_id)
	await _frases_soltas(frases)


func _frases_soltas(frases: Array[String]) -> void:
	if escala_tempo <= 0.0:
		return
	await texto.mostrar(frases)


## Conversa na caixa de diálogo; volta quando ela fecha.
func _falar(marcador: String) -> void:
	if not mostrar_dialogos:
		return
	DialogueManager.show_dialogue_balloon(ROTEIRO, marcador)
	await DialogueManager.dialogue_ended
