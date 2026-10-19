extends GutTest
## A linha do objetivo no alto da tela ([Objetivo]).

const CENA := preload("res://scenes/ui/objetivo.tscn")

var objetivo: Objetivo


func before_each() -> void:
	objetivo = CENA.instantiate()
	add_child_autofree(objetivo)


func test_vazio_nao_aparece() -> void:
	assert_eq(objetivo.texto(), "")
	assert_false(objetivo.deve_aparecer())


func test_chave_vira_texto_traduzido() -> void:
	objetivo.definir("OBJ_CAP1_ACORDAR")
	assert_eq(objetivo.texto(), "Acorde Althea")
	assert_true(objetivo.deve_aparecer())
	objetivo.definir("")
	assert_false(objetivo.deve_aparecer())


func test_some_com_frase_solta_na_tela() -> void:
	var frase := Label.new()
	add_child_autofree(frase)
	objetivo.observar(frase)
	objetivo.definir("OBJ_CAP1_MESA")
	frase.modulate.a = 1.0
	assert_false(objetivo.deve_aparecer())
	frase.modulate.a = 0.0
	assert_true(objetivo.deve_aparecer())


func test_some_durante_o_dialogo() -> void:
	objetivo.definir("OBJ_CAP1_MESA")
	DialogueManager.dialogue_started.emit(null)
	assert_false(objetivo.deve_aparecer())
	DialogueManager.dialogue_ended.emit(null)
	assert_true(objetivo.deve_aparecer())


func test_todas_as_chaves_do_capitulo_tem_texto() -> void:
	var chaves: Array = Capitulo01.OBJETIVOS.values()
	chaves.append_array(["OBJ_CAP1_ROUPA", "OBJ_CAP1_ESPELHO", "OBJ_CAP1_SAIR_QUARTO"])
	for cena: CenaCapitulo01 in [CenaPalacio.new(), CenaButiques.new(), CenaRestaurante.new()]:
		chaves.append_array(cena.objetivos.values())
		cena.free()
	chaves.append_array(["OBJ_CAP1_PATIO_FONTE", "OBJ_CAP1_PATIO_GUARDAS"])
	for chave: String in chaves:
		assert_ne(tr(chave), chave, chave)
