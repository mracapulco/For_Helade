class_name MenuInicial
extends Control
## Primeira tela do jogo: Continuar, Novo jogo, Opções e Sair.
## Tudo funciona com toque, clique, setas e Enter.

## Cena de cada parte da história salva no Progresso. Parte sem cena ainda
## (por exemplo, o capítulo 1) mostra um aviso provisório.
const CENAS := {
	"prologo": "res://scenes/prologo/prologo.tscn",
}
const CENA_NOVO_JOGO := "res://scenes/prologo/prologo.tscn"

@export var botao_continuar: Button
@export var botao_novo_jogo: Button
@export var botao_opcoes: Button
@export var botao_sair: Button
@export var aviso: Label
@export var painel_principal: Control
@export var opcoes: TelaOpcoes

## Cena aberta pelo último botão (para os testes); vazia quando nada abriu.
var cena_pedida := ""
## Quando falso, os botões só anotam a cena pedida, sem trocar (testes).
var trocar_de_cena := true


func _ready() -> void:
	botao_continuar.pressed.connect(_continuar)
	botao_novo_jogo.pressed.connect(_novo_jogo)
	botao_opcoes.pressed.connect(_abrir_opcoes)
	botao_sair.pressed.connect(func() -> void: get_tree().quit())
	opcoes.fechou.connect(_fechar_opcoes)
	atualizar()


func _unhandled_input(evento: InputEvent) -> void:
	if opcoes.visible and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		opcoes.fechar()


## Mostra ou esconde botões conforme o que existe agora.
func atualizar() -> void:
	botao_continuar.visible = Progresso.tem_jogo_salvo()
	botao_sair.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	aviso.text = ""
	opcoes.visible = false
	painel_principal.visible = true
	_focar_primeiro()


func _continuar() -> void:
	if not Progresso.carregar():
		atualizar()
		return
	var cena: String = CENAS.get(Progresso.etapa, "")
	if cena.is_empty():
		aviso.text = tr("MENU_AVISO_SEM_CAPITULO")
		return
	_ir(cena)


func _novo_jogo() -> void:
	Progresso.novo_jogo()
	_ir(CENA_NOVO_JOGO)


func _abrir_opcoes() -> void:
	aviso.text = ""
	painel_principal.visible = false
	opcoes.abrir()


func _fechar_opcoes() -> void:
	painel_principal.visible = true
	botao_opcoes.grab_focus()


func _ir(cena: String) -> void:
	cena_pedida = cena
	if trocar_de_cena:
		TrocaCena.ir_para(cena)


func _focar_primeiro() -> void:
	for botao in [botao_continuar, botao_novo_jogo]:
		if botao.visible:
			botao.grab_focus()
			return
