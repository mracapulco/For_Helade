class_name Objetivo
extends CanvasLayer
## Uma linha curta no alto da tela com o que o jogador deve fazer agora
## (ex.: "Vista-se diante do espelho"). Recebe a chave do texto em
## i18n/strings.csv; vazia, a linha some. Ao trocar, o texto antigo some e o
## novo aparece (fade). Fica escondida enquanto há conversa na caixa de
## diálogo ou frase solta na tela ([method observar]).
## Fica abaixo da cortina (camada 10): some junto nas passagens ao escuro.

## Tempo do fade (para sumir ou aparecer).
@export var tempo_fade := 0.35

## Altura da linha e distância do alto quando nada a cobre.
const ALTURA := 40.0
const TOPO_LIVRE := 18.0

## Chave atual (vazia quando não há objetivo).
var chave := ""
## Frases soltas que, enquanto aparecem, escondem o objetivo.
var _textos: Array[CanvasItem] = []
var _em_dialogo := false

@onready var rotulo: Label = %Rotulo


func _ready() -> void:
	rotulo.modulate.a = 0.0
	rotulo.text = ""
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)


## Troca o objetivo pela chave (vazia esconde).
func definir(nova: String) -> void:
	chave = nova


## Texto do objetivo atual, já traduzido ("" sem objetivo).
func texto() -> String:
	return tr(chave) if chave != "" else ""


## Esconde o objetivo enquanto [param item] estiver visível na tela.
func observar(item: CanvasItem) -> void:
	if item and not _textos.has(item):
		_textos.append(item)


## Se a linha deve aparecer agora (há objetivo e nada a cobre).
func deve_aparecer() -> bool:
	if chave == "" or _em_dialogo:
		return false
	for item in _textos:
		if is_instance_valid(item) and item.visible and item.modulate.a > 0.01:
			return false
	return true


func _process(delta: float) -> void:
	_desviar_da_pausa()
	var passo := delta / maxf(tempo_fade, 0.01)
	var novo := texto()
	if rotulo.text != novo:
		# Some primeiro; o texto novo entra quando a linha já está apagada.
		rotulo.modulate.a = move_toward(rotulo.modulate.a, 0.0, passo)
		if rotulo.modulate.a <= 0.0:
			rotulo.text = novo
		return
	rotulo.modulate.a = move_toward(rotulo.modulate.a, 1.0 if deve_aparecer() else 0.0, passo)


## Em tela de toque o botão de pausa fica no alto, no centro: a linha desce
## para baixo dele em vez de ficar escondida atrás.
func _desviar_da_pausa() -> void:
	var botao: Control = Pausa.botao_pausa if is_instance_valid(Pausa.botao_pausa) else null
	var topo := TOPO_LIVRE
	if botao and botao.visible:
		topo = botao.offset_bottom + 8.0
	rotulo.offset_top = topo
	rotulo.offset_bottom = topo + ALTURA


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	_em_dialogo = true


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	_em_dialogo = false
