extends GutTest
## Menu inicial, opções e jogo salvo.

const CENA := preload("res://scenes/main/main.tscn")

var menu: MenuInicial
var _arquivo_progresso: String
var _arquivo_config: String


func before_each() -> void:
	_arquivo_progresso = Progresso.arquivo
	_arquivo_config = Configuracoes.arquivo
	Progresso.arquivo = "user://teste_progresso.cfg"
	Configuracoes.arquivo = "user://teste_configuracoes.cfg"
	Progresso.apagar()


func after_each() -> void:
	Progresso.apagar()
	if FileAccess.file_exists(Configuracoes.arquivo):
		DirAccess.remove_absolute(Configuracoes.arquivo)
	Progresso.arquivo = _arquivo_progresso
	Configuracoes.arquivo = _arquivo_config
	Configuracoes.carregar()
	Relacoes.limpar()
	Influencia.limpar()


func _abrir_menu() -> void:
	menu = CENA.instantiate()
	menu.trocar_de_cena = false
	add_child_autofree(menu)
	await wait_process_frames(2)


func test_sem_jogo_salvo_nao_mostra_continuar() -> void:
	await _abrir_menu()
	assert_false(menu.botao_continuar.visible)
	assert_true(menu.botao_novo_jogo.has_focus(), "Enter já começa um jogo novo")


func test_novo_jogo_vai_para_o_prologo_e_zera_valores() -> void:
	Relacoes.ajustar("janet", 3)
	await _abrir_menu()
	menu.botao_novo_jogo.pressed.emit()
	assert_eq(menu.cena_pedida, "res://scenes/prologo/prologo.tscn")
	assert_eq(Relacoes.valor("janet"), 0)


func test_continuar_aparece_com_jogo_salvo_e_avisa_sem_capitulo() -> void:
	Progresso.salvar("capitulo_1")
	await _abrir_menu()
	assert_true(menu.botao_continuar.visible)
	assert_true(menu.botao_continuar.has_focus())
	menu.botao_continuar.pressed.emit()
	assert_eq(menu.cena_pedida, "", "o capítulo 1 ainda não existe")
	assert_ne(menu.aviso.text, "")


func test_continuar_abre_a_parte_salva() -> void:
	Progresso.salvar("prologo")
	await _abrir_menu()
	menu.botao_continuar.pressed.emit()
	assert_eq(menu.cena_pedida, "res://scenes/prologo/prologo.tscn")


func test_salvar_e_carregar_guarda_relacoes_e_influencia() -> void:
	Relacoes.ajustar("janet", 2)
	Influencia.ajustar("olympia", -1)
	Progresso.salvar("capitulo_1")
	Relacoes.limpar()
	Influencia.limpar()
	assert_true(Progresso.carregar())
	assert_eq(Progresso.etapa, "capitulo_1")
	assert_eq(Relacoes.valor("janet"), 2)
	assert_eq(Influencia.valor("olympia"), -1)


func test_opcoes_abrem_e_voltam() -> void:
	await _abrir_menu()
	menu.botao_opcoes.pressed.emit()
	assert_true(menu.opcoes.visible)
	assert_false(menu.painel_principal.visible)
	menu.opcoes.botao_voltar.pressed.emit()
	assert_false(menu.opcoes.visible)
	assert_true(menu.painel_principal.visible)


func test_volume_muda_o_som_e_fica_salvo() -> void:
	await _abrir_menu()
	menu.botao_opcoes.pressed.emit()
	menu.opcoes.volume_musica.value = 0.5
	var barramento := AudioServer.get_bus_index("Musica")
	assert_gt(barramento, 0, "existe o barramento de música")
	assert_almost_eq(AudioServer.get_bus_volume_db(barramento), linear_to_db(0.5), 0.01)
	Configuracoes.volume_musica = 1.0
	Configuracoes.carregar()
	assert_almost_eq(Configuracoes.volume_musica, 0.5, 0.001)


func test_idioma_lista_portugues() -> void:
	await _abrir_menu()
	menu.botao_opcoes.pressed.emit()
	assert_gt(menu.opcoes.idioma.item_count, 0)
	assert_eq(menu.opcoes.idioma.get_item_text(0), "Português (Brasil)")


func test_botoes_sao_grandes_para_o_toque() -> void:
	await _abrir_menu()
	for botao in [menu.botao_novo_jogo, menu.botao_opcoes, menu.opcoes.botao_voltar]:
		assert_gte(botao.custom_minimum_size.y, 80.0)


func test_textos_vem_da_traducao() -> void:
	await _abrir_menu()
	assert_eq(tr(menu.botao_novo_jogo.text), "Novo jogo")
	assert_eq(tr(menu.botao_opcoes.text), "Opções")
