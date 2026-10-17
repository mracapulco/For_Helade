extends GutTest
## Menu inicial, opções e jogo salvo.

const CENA := preload("res://scenes/main/main.tscn")

var menu: MenuInicial
var _pasta_progresso: String
var _arquivo_config: String


func before_each() -> void:
	_pasta_progresso = Progresso.pasta
	_arquivo_config = Configuracoes.arquivo
	Progresso.pasta = "user://teste_saves_menu/"
	Configuracoes.arquivo = "user://teste_configuracoes.cfg"
	Progresso.apagar_todos()


func after_each() -> void:
	Progresso.apagar_todos()
	if FileAccess.file_exists(Configuracoes.arquivo):
		DirAccess.remove_absolute(Configuracoes.arquivo)
	Progresso.pasta = _pasta_progresso
	Mundo.limpar()
	Configuracoes.arquivo = _arquivo_config
	Configuracoes.carregar()
	Relacoes.limpar()
	Influencia.limpar()


func _abrir_menu() -> void:
	menu = CENA.instantiate()
	menu.trocar_de_cena = false
	menu.animar_entrada = false
	add_child_autofree(menu)
	await wait_process_frames(2)


func test_sem_jogo_salvo_nao_mostra_continuar() -> void:
	await _abrir_menu()
	assert_false(menu.botao_continuar.visible)
	assert_false(menu.botao_carregar.visible)
	assert_true(menu.botao_novo_jogo.has_focus(), "Enter já começa um jogo novo")


func test_novo_jogo_vai_para_o_prologo_e_zera_valores() -> void:
	Relacoes.ajustar("janet", 3)
	await _abrir_menu()
	menu.botao_novo_jogo.pressed.emit()
	assert_eq(menu.cena_pedida, "res://scenes/prologo/prologo.tscn")
	assert_eq(Relacoes.valor("janet"), 0)


func test_continuar_sem_missao_vai_para_o_mapa_no_acampamento_salvo() -> void:
	Mundo.local_no_mapa = "og_acampamento"
	Progresso.salvar("etapa_sem_missao")
	Mundo.limpar()
	await _abrir_menu()
	assert_true(menu.botao_continuar.visible)
	assert_true(menu.botao_carregar.visible)
	assert_true(menu.botao_continuar.has_focus())
	menu.botao_continuar.pressed.emit()
	assert_eq(menu.cena_pedida, "res://scenes/mapa/mapa_helade.tscn")
	assert_eq(Mundo.local_no_mapa, "og_acampamento")


func test_continuar_abre_o_espaco_salvo_por_ultimo() -> void:
	Mundo.local_no_mapa = "oa_acampamento"
	Progresso.salvar("etapa_sem_missao", 7)
	Mundo.local_no_mapa = "ot_acampamento"
	Progresso.salvar("etapa_sem_missao", 2)
	Mundo.limpar()
	await _abrir_menu()
	menu.botao_continuar.pressed.emit()
	assert_eq(Progresso.espaco_atual, 2)
	assert_eq(Mundo.local_no_mapa, "ot_acampamento")


func test_carregar_jogo_mostra_os_dez_espacos_e_abre_o_escolhido() -> void:
	Mundo.local_no_mapa = "oa_acampamento"
	Progresso.salvar("etapa_sem_missao", 3)
	Mundo.local_no_mapa = "ot_acampamento"
	Progresso.salvar("etapa_sem_missao", 5)
	Mundo.limpar()
	await _abrir_menu()
	menu.botao_carregar.pressed.emit()
	var tela := menu.tela_espacos
	assert_true(tela.aberta())
	assert_false(menu.painel_principal.visible)
	assert_false(get_tree().paused, "o menu não pausa")
	assert_eq(tela.botoes.size(), 10)
	assert_true(tela.botoes[0].disabled, "espaço vazio não carrega")
	assert_false(tela.botoes[2].disabled)
	assert_true(tela.botoes[4].has_focus(), "o mais recente fica selecionado")
	assert_eq(tela.selecionado, 5)
	tela.botoes[2].pressed.emit()
	assert_eq(menu.cena_pedida, "", "tocar no espaço só seleciona")
	assert_eq(tela.selecionado, 3)
	assert_true(tela.botoes[2].button_pressed)
	assert_false(tela.botoes[4].button_pressed, "só um selecionado")
	assert_true(tela.botao_acao.has_focus(), "Enter de novo carrega")
	tela.botao_acao.pressed.emit()
	assert_eq(Progresso.espaco_atual, 3)
	assert_eq(Mundo.local_no_mapa, "oa_acampamento")
	assert_eq(menu.cena_pedida, "res://scenes/mapa/mapa_helade.tscn")


func test_carregar_jogo_volta_sem_escolher() -> void:
	Progresso.salvar("etapa_sem_missao", 1)
	await _abrir_menu()
	menu.botao_carregar.pressed.emit()
	menu.tela_espacos.botao_voltar.pressed.emit()
	assert_false(menu.tela_espacos.aberta())
	assert_true(menu.painel_principal.visible)
	assert_eq(menu.cena_pedida, "")


func test_continuar_abre_a_parte_salva() -> void:
	Progresso.salvar("prologo")
	await _abrir_menu()
	menu.botao_continuar.pressed.emit()
	assert_eq(menu.cena_pedida, "res://scenes/prologo/prologo.tscn", "missão em andamento")


func test_salvar_e_carregar_guarda_relacoes_e_influencia() -> void:
	Relacoes.ajustar("janet", 2)
	Influencia.ajustar("olympia", -1)
	Progresso.salvar("etapa_sem_missao")
	Relacoes.limpar()
	Influencia.limpar()
	assert_true(Progresso.carregar())
	assert_eq(Progresso.etapa, "etapa_sem_missao")
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


func test_novo_jogo_nao_apaga_os_espacos() -> void:
	Progresso.salvar("etapa_sem_missao", 1)
	await _abrir_menu()
	menu.botao_novo_jogo.pressed.emit()
	assert_eq(menu.cena_pedida, "res://scenes/prologo/prologo.tscn")
	assert_true(Progresso.espaco_ocupado(1))
	assert_eq(Progresso.espaco_atual, 0, "o jogo novo ainda não tem espaço")


func test_musica_do_menu_toca_em_laco_no_barramento_de_musica() -> void:
	await _abrir_menu()
	assert_true(menu.musica.playing)
	assert_eq(menu.musica.bus, &"Musica")
	assert_true(menu.musica.stream.loop)


func test_entrada_animada_e_pulada_com_um_toque() -> void:
	menu = CENA.instantiate()
	menu.trocar_de_cena = false
	add_child_autofree(menu)
	await wait_process_frames(2)
	assert_lt(menu.botao_novo_jogo.modulate.a, 1.0, "botões ainda surgindo")
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	menu._input(toque)
	await wait_process_frames(2)
	for parte in [menu.capa, menu.titulo, menu.botao_novo_jogo, menu.botao_opcoes]:
		assert_eq(parte.modulate.a, 1.0)


func test_excluir_um_jogo_salvo_pergunta_antes() -> void:
	Progresso.salvar("capitulo_1", 1)
	Progresso.salvar("capitulo_1", 2)
	await _abrir_menu()
	menu.botao_carregar.pressed.emit()
	var tela := menu.tela_espacos
	tela.botoes[1].pressed.emit()
	assert_false(tela.botao_excluir.disabled)
	tela.botao_excluir.pressed.emit()
	assert_true(tela.confirmacao.visible, "pergunta antes de apagar")
	assert_true(Progresso.espaco_ocupado(2))
	tela.botao_nao.pressed.emit()
	assert_true(Progresso.espaco_ocupado(2), "Não deixa como estava")
	tela.botao_excluir.pressed.emit()
	tela.botao_sim.pressed.emit()
	assert_false(Progresso.espaco_ocupado(2))
	assert_true(Progresso.espaco_ocupado(1))
	assert_true(tela.aberta(), "excluir não fecha a lista")
	assert_eq(menu.cena_pedida, "", "excluir não abre o jogo")
	assert_true(tela.botoes[1].disabled, "o espaço apagado fica vazio")
	assert_eq(tela.selecionado, 1, "passa para o jogo que sobrou")


func test_excluir_o_ultimo_jogo_esconde_continuar() -> void:
	Progresso.salvar("capitulo_1", 1)
	await _abrir_menu()
	menu.botao_carregar.pressed.emit()
	var tela := menu.tela_espacos
	tela.selecionar(1)
	tela.excluir()
	tela.confirmar()
	tela.botao_voltar.pressed.emit()
	assert_false(menu.botao_continuar.visible)
	assert_false(menu.botao_carregar.visible)


func test_continuar_no_capitulo_1_abre_a_missao() -> void:
	Progresso.salvar("capitulo_1")
	await _abrir_menu()
	menu.botao_continuar.pressed.emit()
	assert_eq(menu.cena_pedida, "res://scenes/capitulo_01/capitulo_01.tscn")
