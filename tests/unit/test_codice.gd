extends GutTest
## Autoload Codice: o olhar de Nicholas e o códice, o aviso na tela e o jogo salvo.

const CENA_AVISO := "res://scenes/ui/aviso_itens.tscn"

var _pasta_progresso: String


func before_each() -> void:
	_pasta_progresso = Progresso.pasta
	Progresso.pasta = "user://teste_saves_codice/"
	Progresso.apagar_todos()
	Codice.limpar()


func after_each() -> void:
	Progresso.apagar_todos()
	Progresso.pasta = _pasta_progresso
	Codice.limpar()


func test_anotar_so_avisa_na_primeira_vez() -> void:
	watch_signals(Codice)
	assert_true(Codice.anotar("atenas"))
	assert_false(Codice.anotar("atenas"))
	assert_true(Codice.tem("atenas"))
	assert_signal_emit_count(Codice, "anotado", 1)
	assert_signal_emitted_with_parameters(Codice, "anotado", ["atenas"])


func test_entrada_desconhecida_nao_e_anotada() -> void:
	assert_false(Codice.anotar("nao_existe"))
	assert_false(Codice.tem("nao_existe"))


func test_ids_separa_olhar_e_codice_na_ordem() -> void:
	Codice.anotar("palacio_imperial")
	Codice.anotar("roupas_simples")
	Codice.anotar("atenas")
	assert_eq(Codice.ids(Codice.TIPO_CODICE), ["palacio_imperial", "atenas"] as Array[String])
	assert_eq(Codice.ids(Codice.TIPO_OLHAR), ["roupas_simples"] as Array[String])


func test_toda_entrada_tem_titulo_e_texto() -> void:
	for id: String in Codice.ENTRADAS:
		var chave := id.to_upper()
		assert_ne(Codice.titulo(id), "CODICE_%s_TITULO" % chave, "falta o título de %s" % id)
		assert_ne(Codice.texto(id), "CODICE_%s_TEXTO" % chave, "falta o texto de %s" % id)
		assert_true(Codice.ENTRADAS[id] in [Codice.TIPO_OLHAR, Codice.TIPO_CODICE], id)


func test_salvar_e_carregar() -> void:
	Codice.anotar("roupas_simples")
	Codice.anotar("atenas")
	Progresso.salvar("capitulo_1")
	Codice.limpar()
	assert_false(Codice.tem("atenas"))
	assert_true(Progresso.carregar())
	assert_true(Codice.tem("roupas_simples"))
	assert_true(Codice.tem("atenas"))
	assert_eq(Codice.ids(Codice.TIPO_OLHAR), ["roupas_simples"] as Array[String])


func test_de_dados_ignora_entradas_desconhecidas() -> void:
	Codice.de_dados({"anotados": ["atenas", "nao_existe", "atenas"]})
	assert_eq(Codice.anotados, ["atenas"] as Array[String])


func test_novo_jogo_esquece_o_codice() -> void:
	Codice.anotar("atenas")
	Progresso.novo_jogo()
	assert_false(Codice.tem("atenas"))


func test_aviso_na_tela_ao_anotar() -> void:
	var aviso: AvisoItens = load(CENA_AVISO).instantiate()
	add_child_autofree(aviso)
	Codice.anotar("roupas_simples")
	Codice.anotar("atenas")
	assert_has(aviso.textos(), "Olhar de Nicholas: Roupas simples")
	assert_has(aviso.textos(), "Códice: Atenas")
