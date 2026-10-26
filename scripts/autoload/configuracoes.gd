extends Node
## Opções do jogador (autoload "Configuracoes"): idioma, controles, gráficos e
## som. Ficam salvas em user://configuracoes.cfg e valem desde a abertura.

signal mudou

const ARQUIVO := "user://configuracoes.cfg"
const BARRAMENTOS := {"volume_geral": "Master", "volume_musica": "Musica", "volume_efeitos": "Efeitos", "volume_voz": "Voz"}

var idioma := "pt_BR"
## Multiplica a sensibilidade do mouse na primeira pessoa (1 = padrão).
var sensibilidade_mouse := 1.0
var tela_cheia := false
var vsync := true
## No PC com tela de toque: mostrar os botões de toque (pausa, pular, golpe).
## No celular eles sempre aparecem.
var botoes_toque := true
## Volumes de 0 a 1.
var volume_geral := 1.0
var volume_musica := 0.8
var volume_efeitos := 0.8
var volume_voz := 1.0
## Andar antigo na exploração: de casa em casa, com as teclas nas linhas do
## quadriculado. Desligado (padrão desde 23/10), anda livre pela tela. Fica
## para comparar (F3 alterna no jogo).
var movimento_em_grade := false

var arquivo := ARQUIVO


func _ready() -> void:
	# A interpolação de física (project.godot) fica desligada no jogo todo e
	# só liga em quem anda na física: o personagem da exploração (com a
	# câmera) e os inimigos. Assim o andar fica liso em monitores acima de
	# 60 Hz sem atrapalhar o que é movido fora da física (tweens das cenas,
	# a primeira pessoa do prólogo).
	get_tree().root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	carregar()


func carregar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(arquivo) == OK:
		for chave in _chaves():
			set(chave, cfg.get_value("opcoes", chave, get(chave)))
	aplicar()


func salvar() -> void:
	var cfg := ConfigFile.new()
	for chave in _chaves():
		cfg.set_value("opcoes", chave, get(chave))
	cfg.save(arquivo)


## Muda uma opção, aplica na hora e salva.
func definir(chave: String, valor: Variant) -> void:
	set(chave, valor)
	aplicar()
	salvar()


func aplicar() -> void:
	TranslationServer.set_locale(idioma)
	for chave: String in BARRAMENTOS:
		var barramento := AudioServer.get_bus_index(BARRAMENTOS[chave])
		if barramento >= 0:
			var volume: float = get(chave)
			AudioServer.set_bus_volume_db(barramento, linear_to_db(maxf(volume, 0.0001)))
			AudioServer.set_bus_mute(barramento, volume <= 0.0)
	if not OS.has_feature("mobile") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if tela_cheia else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	mudou.emit()


## Se os botões de toque devem aparecer na tela.
func mostrar_botoes_toque() -> bool:
	return OS.has_feature("mobile") or (botoes_toque and DisplayServer.is_touchscreen_available())


## Idiomas que o jogo tem traduzidos.
func idiomas_disponiveis() -> PackedStringArray:
	var lista := TranslationServer.get_loaded_locales()
	if lista.is_empty():
		lista.append("pt_BR")
	return lista


func _chaves() -> Array[String]:
	return ["idioma", "sensibilidade_mouse", "tela_cheia", "vsync", "botoes_toque", "volume_geral", "volume_musica", "volume_efeitos", "volume_voz", "movimento_em_grade"]
