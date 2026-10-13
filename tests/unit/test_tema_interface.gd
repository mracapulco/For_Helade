extends GutTest
## Tema da interface com a paleta da capa (planos/direcao-de-arte.md).

const CAMINHO_TEMA := "res://assets/ui/tema_helade.tres"
const DOURADO_CLARO := Color("#ECBD75")
const PRATA := Color("#D8CFC4")


func test_tema_e_o_padrao_do_projeto() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), CAMINHO_TEMA)


func test_tema_tem_fontes_de_texto_e_de_titulo() -> void:
	var tema: Theme = load(CAMINHO_TEMA)
	assert_not_null(tema.default_font)
	assert_true(tema.has_font(&"normal_font", &"NomePersonagem"))
	assert_true(tema.has_font(&"font", &"BotaoRedondo"))


func test_cores_vem_da_paleta() -> void:
	var tema: Theme = load(CAMINHO_TEMA)
	assert_eq(tema.get_color(&"default_color", &"RichTextLabel").to_html(false), PRATA.to_html(false))
	assert_eq(tema.get_color(&"default_color", &"NomePersonagem").to_html(false), DOURADO_CLARO.to_html(false))


func test_caixa_de_dialogo_usa_o_tema() -> void:
	var caixa: CaixaDialogo = add_child_autofree(load("res://scenes/ui/caixa_dialogo.tscn").instantiate())
	var nome: RichTextLabel = caixa.get_node("%CharacterLabel")
	assert_eq(nome.theme_type_variation, &"NomePersonagem")
	assert_eq(nome.get_theme_color(&"default_color").to_html(false), DOURADO_CLARO.to_html(false))
	var fala: RichTextLabel = caixa.get_node("%DialogueLabel")
	assert_eq(fala.get_theme_color(&"default_color").to_html(false), PRATA.to_html(false))
