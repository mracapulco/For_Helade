class_name TelaEspacos
extends CanvasLayer
## Lista dos 10 espaços de jogo salvo, para salvar (barraca do acampamento)
## ou carregar (menu inicial). Cada espaço mostra a parte da história, o
## lugar e quando foi salvo. Salvar por cima de um espaço ocupado pergunta
## antes. Funciona com toque, clique, setas e Enter; Esc ou Voltar fecham.

## O jogador escolheu um espaço (já confirmado, se era para salvar por cima).
signal escolhido(espaco: int)
signal fechou

enum Modo { SALVAR, CARREGAR }

const COR_FUNDO := Color(0.0196, 0.0471, 0.0784, 0.85) # Noite, da paleta
const COR_DESTAQUE := Color(0.9255, 0.7412, 0.4588) # Dourado claro
const FONTE_TITULO := preload("res://assets/fonts/cinzel/cinzel.ttf")
const PASTA_ACAMPAMENTOS := "res://data/acampamentos/"
const PASTA_MAPA := "res://data/mapa/"

var modo := Modo.SALVAR
## Pausa o jogo enquanto aberta (no acampamento; no menu não precisa).
var pausar := true
## Espaço esperando o "Sim" para ser substituído; 0 quando nenhum.
var espaco_a_confirmar := 0

var tela: Control
var titulo: Label
var botoes: Array[Button] = []
var botao_voltar: Button
var confirmacao: Control
var botao_sim: Button
var botao_nao: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	tela.hide()


func _unhandled_input(evento: InputEvent) -> void:
	if not aberta() or not evento.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if confirmacao.visible:
		cancelar_confirmacao()
	else:
		fechar()


func aberta() -> bool:
	return tela.visible


func abrir(novo_modo: Modo) -> void:
	modo = novo_modo
	titulo.text = "ESPACOS_TITULO_SALVAR" if modo == Modo.SALVAR else "ESPACOS_TITULO_CARREGAR"
	atualizar()
	confirmacao.hide()
	espaco_a_confirmar = 0
	tela.show()
	if pausar:
		get_tree().paused = true
	_focar_inicial()


func fechar() -> void:
	tela.hide()
	confirmacao.hide()
	espaco_a_confirmar = 0
	if pausar:
		get_tree().paused = false
	fechou.emit()


## Escolher um espaço: carregar abre na hora; salvar num espaço ocupado
## pergunta antes.
func escolher(espaco: int) -> void:
	if not Progresso.espaco_valido(espaco):
		return
	var ocupado := Progresso.espaco_ocupado(espaco)
	if modo == Modo.CARREGAR and not ocupado:
		return
	if modo == Modo.SALVAR and ocupado:
		espaco_a_confirmar = espaco
		confirmacao.show()
		botao_nao.grab_focus() # o seguro fica selecionado
		return
	_concluir(espaco)


func confirmar() -> void:
	if espaco_a_confirmar > 0:
		_concluir(espaco_a_confirmar)


func cancelar_confirmacao() -> void:
	var espaco := espaco_a_confirmar
	espaco_a_confirmar = 0
	confirmacao.hide()
	if espaco > 0:
		botoes[espaco - 1].grab_focus()


func atualizar() -> void:
	for i in botoes.size():
		var espaco := i + 1
		var botao := botoes[i]
		var dados := Progresso.resumo(espaco)
		botao.text = texto_do_espaco(espaco, dados)
		botao.disabled = modo == Modo.CARREGAR and dados.is_empty()


## "Espaço 3" e, embaixo, a parte da história, o lugar e a data.
func texto_do_espaco(espaco: int, dados: Dictionary) -> String:
	var texto := tr("ESPACOS_ESPACO") % espaco
	if dados.is_empty():
		return texto + "\n" + tr("ESPACOS_VAZIO")
	var partes: Array[String] = []
	var nome_etapa := nome_da_etapa(dados.etapa)
	if not nome_etapa.is_empty():
		partes.append(nome_etapa)
	var lugar := nome_do_lugar(dados.lugar)
	if not lugar.is_empty():
		partes.append(lugar)
	if dados.salvo_em > 0.0:
		partes.append(data_local(dados.salvo_em))
	return texto + "\n" + " · ".join(partes)


## Nome da parte da história (ETAPA_<ID> no strings.csv), ou "" se não houver.
func nome_da_etapa(etapa: String) -> String:
	if etapa.is_empty():
		return ""
	var chave := "ETAPA_" + etapa.to_upper()
	var nome := tr(chave)
	return "" if nome == chave else nome


## Nome do acampamento (ou do lugar do mapa) onde o jogo foi salvo.
func nome_do_lugar(id: String) -> String:
	if id.is_empty():
		return ""
	var acampamento := PASTA_ACAMPAMENTOS + id + ".tres"
	if ResourceLoader.exists(acampamento):
		var bioma := load(acampamento) as BiomaAcampamento
		if bioma and not bioma.chave_nome.is_empty():
			return tr(bioma.chave_nome).trim_prefix("[Provisório] ")
	var local := PASTA_MAPA + id + ".tres"
	if ResourceLoader.exists(local):
		var dados := load(local) as LocalMapa
		if dados and not dados.chave_nome.is_empty():
			return tr(dados.chave_nome)
	return ""


## Data e hora no fuso do aparelho: 14/10/2026 22:10.
static func data_local(unix: float) -> String:
	var fuso: int = Time.get_time_zone_from_system().get("bias", 0)
	var d := Time.get_datetime_dict_from_unix_time(int(unix) + fuso * 60)
	return "%02d/%02d/%04d %02d:%02d" % [d.day, d.month, d.year, d.hour, d.minute]


func _concluir(espaco: int) -> void:
	fechar()
	escolhido.emit(espaco)


func _focar_inicial() -> void:
	var alvo := Progresso.espaco_atual if Progresso.espaco_atual > 0 else 0
	if modo == Modo.CARREGAR:
		alvo = Progresso.espaco_mais_recente()
	elif alvo == 0:
		alvo = maxi(Progresso.primeiro_espaco_livre(), 1)
	if alvo > 0 and not botoes[alvo - 1].disabled:
		botoes[alvo - 1].grab_focus()
	else:
		botao_voltar.grab_focus()


func _botao(texto: String, ao_apertar: Callable, largura := 300.0) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(largura, 84)
	botao.add_theme_font_size_override("font_size", 30)
	botao.pressed.connect(ao_apertar)
	return botao


## Montada por código para ficar igual no menu e no acampamento.
func _montar() -> void:
	tela = Control.new()
	tela.name = "Tela"
	tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	tela.mouse_filter = Control.MOUSE_FILTER_STOP
	tela.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	add_child(tela)

	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	tela.add_child(fundo)

	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 40)
	tela.add_child(margem)

	var painel := PanelContainer.new()
	margem.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 16)
	painel.add_child(coluna)

	titulo = Label.new()
	titulo.name = "Titulo"
	titulo.add_theme_font_override("font", FONTE_TITULO)
	titulo.add_theme_font_size_override("font_size", 36)
	titulo.add_theme_color_override("font_color", COR_DESTAQUE)
	coluna.add_child(titulo)

	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolagem)
	var grade := GridContainer.new()
	grade.name = "Espacos"
	grade.columns = 2
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 16)
	grade.add_theme_constant_override("v_separation", 12)
	rolagem.add_child(grade)
	for i in Progresso.TOTAL_ESPACOS:
		var botao := _botao("", escolher.bind(i + 1))
		botao.name = "Espaco%d" % (i + 1)
		botao.custom_minimum_size.y = 96
		botao.add_theme_font_size_override("font_size", 24)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		grade.add_child(botao)
		botoes.append(botao)

	botao_voltar = _botao("MENU_VOLTAR", fechar)
	botao_voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(botao_voltar)

	confirmacao = ColorRect.new()
	confirmacao.name = "Confirmacao"
	(confirmacao as ColorRect).color = Color(0, 0, 0, 0.6)
	confirmacao.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirmacao.mouse_filter = Control.MOUSE_FILTER_STOP
	tela.add_child(confirmacao)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirmacao.add_child(centro)
	var caixa := PanelContainer.new()
	caixa.custom_minimum_size = Vector2(720, 0)
	centro.add_child(caixa)
	var coluna_conf := VBoxContainer.new()
	coluna_conf.add_theme_constant_override("separation", 28)
	caixa.add_child(coluna_conf)
	var pergunta := Label.new()
	pergunta.text = "ESPACOS_CONFIRMAR_SUBSTITUIR"
	pergunta.add_theme_font_size_override("font_size", 30)
	pergunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pergunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna_conf.add_child(pergunta)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 24)
	coluna_conf.add_child(linha)
	botao_sim = _botao("ESPACOS_CONFIRMAR_SIM", confirmar)
	botao_nao = _botao("ESPACOS_CONFIRMAR_NAO", cancelar_confirmacao)
	linha.add_child(botao_sim)
	linha.add_child(botao_nao)
	confirmacao.hide()
