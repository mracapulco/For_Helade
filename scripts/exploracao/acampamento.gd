class_name Acampamento
extends Node2D
## Acampamento numa rota entre os reinos: o ponto de descanso (e de salvar)
## da exploração. A cena base é scenes/exploracao/acampamentos/acampamento_base.tscn;
## cada acampamento é uma cena herdada dela que só troca o [member bioma].
## - Barraca: salva o jogo (fica na mesma etapa da história).
## - Mercador: conversa provisória até existir a loja.
## - Companheiro: animal ou viajante, conforme o bioma.
## - Saída (placa ou barco) e o botão "Voltar ao mapa": voltam ao mapa de Hélade.
## O cenário em volta é montado pelo [CenarioAcampamento].

signal salvo

const CENA_MAPA := "res://scenes/mapa/mapa_helade.tscn"

@export var bioma: BiomaAcampamento

## Cena aberta pela última saída (para os testes); vazia quando nenhuma.
var cena_pedida := ""
## Quando falso, sair só anota a cena pedida, sem trocar (testes).
var trocar_de_cena := true

@onready var barraca: Interagivel = $Barraca/Interagivel
@onready var mercador: Interagivel = $Mercador/Interagivel
@onready var companheiro: Interagivel = $Companheiro/Interagivel
@onready var saida: Interagivel = $Saida/Interagivel
@onready var aviso: AvisoItens = $AvisoItens
@onready var ambiente: CanvasModulate = $Ambiente
@onready var luz_fogueira: PointLight2D = $Fogueira/Luz
@onready var interface: CanvasLayer = $Interface
@onready var titulo: Label = %Titulo
@onready var botao_mapa: Button = %BotaoMapa


func _ready() -> void:
	barraca.interagido.connect(descansar)
	saida.interagido.connect(voltar_ao_mapa)
	botao_mapa.pressed.connect(voltar_ao_mapa)
	botao_mapa.add_to_group(BotoesToque.GRUPO_BLOQUEIA_TOQUE)
	if bioma:
		titulo.text = bioma.chave_nome
	_aplicar_periodo(Mundo.noite)
	Mundo.periodo_mudou.connect(_aplicar_periodo)
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)
	DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	_animar_fogo()


## Descansar na barraca: salva o jogo sem mudar a etapa da história.
func descansar() -> void:
	Progresso.salvar(Progresso.etapa)
	aviso.mostrar(tr("ACAMP_SALVO"))
	salvo.emit()


func voltar_ao_mapa() -> void:
	cena_pedida = CENA_MAPA
	if trocar_de_cena:
		TrocaCena.ir_para(CENA_MAPA)


func _aplicar_periodo(noite: bool) -> void:
	if bioma:
		ambiente.color = bioma.cor_noite if noite else bioma.cor_dia
	luz_fogueira.enabled = noite


## A luz da fogueira tremula de leve (só aparece à noite).
func _animar_fogo() -> void:
	var tremor := luz_fogueira.create_tween().set_loops()
	tremor.tween_property(luz_fogueira, "energy", 0.85, 0.35).set_trans(Tween.TRANS_SINE)
	tremor.tween_property(luz_fogueira, "energy", 1.1, 0.45).set_trans(Tween.TRANS_SINE)


func _ao_comecar_dialogo(_recurso: DialogueResource) -> void:
	interface.hide()


func _ao_terminar_dialogo(_recurso: DialogueResource) -> void:
	interface.show()
