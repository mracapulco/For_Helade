extends Control
## Tela provisória para testar o sistema de diálogo no editor.

const DIALOGO_TESTE: DialogueResource = preload("res://data/dialogos/teste/teste.dialogue")

@onready var _valores: Label = %Valores
@onready var _iniciar: Button = %Iniciar


func _ready() -> void:
	Relacoes.mudou.connect(_atualizar_valores.unbind(2))
	Influencia.mudou.connect(_atualizar_valores.unbind(2))
	DialogueManager.dialogue_ended.connect(_on_dialogo_terminou)
	_atualizar_valores()


func _atualizar_valores() -> void:
	_valores.text = tr("TESTE_DIALOGO_VALORES") % [
		Relacoes.valor("janet"),
		Influencia.valor("olympia"),
	]


func _on_iniciar_pressed() -> void:
	_iniciar.disabled = true
	DialogueManager.show_dialogue_balloon(DIALOGO_TESTE, "inicio")


func _on_zerar_pressed() -> void:
	Relacoes.limpar()
	Influencia.limpar()
	_atualizar_valores()


func _on_dialogo_terminou(_recurso: DialogueResource) -> void:
	_iniciar.disabled = false
