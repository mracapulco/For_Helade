extends GutTest
## Confirma que o GUT roda e que os textos vêm do arquivo de tradução.

func test_titulo_vem_da_traducao() -> void:
	TranslationServer.set_locale("pt_BR")
	assert_eq(tr("JOGO_TITULO"), "Por Hélade")
