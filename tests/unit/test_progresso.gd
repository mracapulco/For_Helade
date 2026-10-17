extends GutTest
## Os 10 espaços de jogo salvo: onde cada salvamento vai, qual é o mais
## recente, o resumo mostrado na lista e o jogo salvo antigo virando espaço 1.

const ANTIGO := "user://teste_progresso_antigo.cfg"

var _pasta_progresso: String


func before_each() -> void:
	_pasta_progresso = Progresso.pasta
	Progresso.pasta = "user://teste_saves_progresso/"
	Progresso.apagar_todos()


func after_each() -> void:
	Progresso.apagar_todos()
	Progresso.pasta = _pasta_progresso
	Mundo.limpar()
	if FileAccess.file_exists(ANTIGO):
		DirAccess.remove_absolute(ANTIGO)


func test_sao_dez_espacos() -> void:
	assert_eq(Progresso.TOTAL_ESPACOS, 10)
	assert_false(Progresso.espaco_valido(0))
	assert_true(Progresso.espaco_valido(10))
	assert_false(Progresso.espaco_valido(11))
	assert_false(Progresso.salvar("capitulo_1", 11))


func test_jogo_novo_salva_no_primeiro_espaco_livre_e_continua_nele() -> void:
	Progresso.salvar("capitulo_1", 1)
	Progresso.novo_jogo()
	assert_true(Progresso.salvar("prologo"))
	assert_eq(Progresso.espaco_atual, 2)
	assert_true(Progresso.salvar("capitulo_1"))
	assert_eq(Progresso.espaco_atual, 2, "o mesmo jogo segue no mesmo espaço")
	assert_eq(Progresso.resumo(1).etapa, "capitulo_1")


func test_com_tudo_cheio_jogo_novo_nao_salva_por_cima_sozinho() -> void:
	for espaco in range(1, 11):
		Progresso.salvar("capitulo_1", espaco)
	Progresso.novo_jogo()
	assert_false(Progresso.salvar("prologo"))
	for espaco in range(1, 11):
		assert_eq(Progresso.resumo(espaco).etapa, "capitulo_1")


func test_com_tudo_cheio_a_historia_avanca_mesmo_sem_salvar() -> void:
	for espaco in range(1, 11):
		Progresso.salvar("prologo", espaco)
	Progresso.novo_jogo()
	assert_false(Progresso.salvar("capitulo_1"))
	assert_eq(Progresso.etapa, "capitulo_1", "o mapa abre na fase certa (Atenas)")


func test_mais_recente_e_o_ultimo_salvo() -> void:
	assert_eq(Progresso.espaco_mais_recente(), 0)
	assert_false(Progresso.tem_jogo_salvo())
	Progresso.salvar("capitulo_1", 6)
	Progresso.salvar("capitulo_1", 3)
	assert_eq(Progresso.espaco_mais_recente(), 3)
	Progresso.salvar("capitulo_1", 6)
	assert_eq(Progresso.espaco_mais_recente(), 6)


func test_carregar_sem_espaco_abre_o_mais_recente() -> void:
	Mundo.local_no_mapa = "oa_acampamento"
	Progresso.salvar("prologo", 8)
	Mundo.local_no_mapa = "ag_acampamento"
	Progresso.salvar("capitulo_1", 4)
	Mundo.limpar()
	assert_true(Progresso.carregar())
	assert_eq(Progresso.espaco_atual, 4)
	assert_eq(Progresso.etapa, "capitulo_1")
	assert_eq(Mundo.local_no_mapa, "ag_acampamento")
	assert_false(Progresso.carregar(9), "espaço vazio")


func test_resumo_tem_etapa_lugar_e_data() -> void:
	Mundo.local_no_mapa = "og_acampamento"
	Progresso.salvar("capitulo_1", 5)
	var dados := Progresso.resumo(5)
	assert_eq(dados.etapa, "capitulo_1")
	assert_eq(dados.lugar, "og_acampamento")
	assert_gt(dados.salvo_em, 0.0)
	assert_eq(Progresso.resumo(6), {})


func test_texto_do_espaco_na_lista() -> void:
	TranslationServer.set_locale("pt_BR")
	Mundo.local_no_mapa = "og_acampamento"
	Progresso.salvar("capitulo_1", 5)
	var tela := TelaEspacos.new()
	add_child_autofree(tela)
	var texto := tela.texto_do_espaco(5, Progresso.resumo(5))
	assert_string_starts_with(texto, "Espaço 5\nCapítulo 1 · Acampamento nas colinas geladas · ")
	assert_eq(tela.texto_do_espaco(6, {}), "Espaço 6\nVazio")
	assert_eq(tela.nome_do_lugar("olympia"), "Olympia", "lugar do mapa (o reino, no futuro)")


func test_apagar_um_espaco() -> void:
	Progresso.salvar("capitulo_1", 2)
	Progresso.apagar(2)
	assert_false(Progresso.espaco_ocupado(2))
	assert_eq(Progresso.espaco_atual, 0)


func test_jogo_salvo_antigo_vira_o_espaco_1() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("jogo", "etapa", "capitulo_1")
	cfg.save(ANTIGO)
	# O autoload usa a constante; aqui o mesmo passo, com o arquivo de teste.
	var progresso: Node = load("res://scripts/autoload/progresso.gd").new()
	progresso.pasta = Progresso.pasta
	progresso.arquivo_antigo = ANTIGO
	progresso._trazer_jogo_antigo()
	progresso.free()
	assert_false(FileAccess.file_exists(ANTIGO))
	assert_eq(Progresso.resumo(1).etapa, "capitulo_1")
	assert_gt(Progresso.resumo(1).salvo_em, 0.0)
