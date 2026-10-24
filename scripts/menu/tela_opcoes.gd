class_name TelaOpcoes
extends Control
## Opções: idioma, controles, gráficos e som. Cada mudança vale na hora e fica
## salva em [Configuracoes].

signal fechou

@export var idioma: OptionButton
@export var sensibilidade: HSlider
@export var tela_cheia: CheckButton
@export var vsync: CheckButton
@export var botoes_toque: CheckButton
@export var volume_geral: HSlider
@export var volume_musica: HSlider
@export var volume_efeitos: HSlider
@export var volume_voz: HSlider
@export var botao_voltar: Button
## Linhas que só fazem sentido no PC (tela cheia, VSync, teclas).
@export var so_no_pc: Array[Control] = []

var _locais: PackedStringArray


func _ready() -> void:
	idioma.item_selected.connect(func(i: int) -> void: Configuracoes.definir("idioma", _locais[i]))
	sensibilidade.value_changed.connect(func(v: float) -> void: Configuracoes.definir("sensibilidade_mouse", v))
	tela_cheia.toggled.connect(func(v: bool) -> void: Configuracoes.definir("tela_cheia", v))
	vsync.toggled.connect(func(v: bool) -> void: Configuracoes.definir("vsync", v))
	botoes_toque.toggled.connect(func(v: bool) -> void: Configuracoes.definir("botoes_toque", v))
	volume_geral.value_changed.connect(func(v: float) -> void: Configuracoes.definir("volume_geral", v))
	volume_musica.value_changed.connect(func(v: float) -> void: Configuracoes.definir("volume_musica", v))
	volume_efeitos.value_changed.connect(func(v: float) -> void: Configuracoes.definir("volume_efeitos", v))
	volume_voz.value_changed.connect(func(v: float) -> void: Configuracoes.definir("volume_voz", v))
	botao_voltar.pressed.connect(fechar)
	var no_pc := not OS.has_feature("mobile")
	for linha in so_no_pc:
		linha.visible = no_pc


func abrir() -> void:
	_preencher()
	visible = true
	idioma.grab_focus()


func fechar() -> void:
	visible = false
	fechou.emit()


## Mostra os valores atuais sem disparar mudanças.
func _preencher() -> void:
	_locais = Configuracoes.idiomas_disponiveis()
	idioma.clear()
	for local in _locais:
		var chave := "IDIOMA_" + local
		var nome := tr(chave)
		idioma.add_item(nome if nome != chave else TranslationServer.get_locale_name(local))
	idioma.select(maxi(_locais.find(Configuracoes.idioma), 0))
	sensibilidade.set_value_no_signal(Configuracoes.sensibilidade_mouse)
	tela_cheia.set_pressed_no_signal(Configuracoes.tela_cheia)
	vsync.set_pressed_no_signal(Configuracoes.vsync)
	botoes_toque.set_pressed_no_signal(Configuracoes.botoes_toque)
	volume_geral.set_value_no_signal(Configuracoes.volume_geral)
	volume_musica.set_value_no_signal(Configuracoes.volume_musica)
	volume_efeitos.set_value_no_signal(Configuracoes.volume_efeitos)
	volume_voz.set_value_no_signal(Configuracoes.volume_voz)
