extends GutTest
## Artes provisórias em pixel art ligadas ao jogo: ícones dos itens,
## objetos e figurantes da sala de teste (tools/arte/gerar_objetos.py).

const PASTA := "res://assets/art/placeholders/"
const FIGURANTES := {
	"GuardaTeste": "guarda_teste",
	"CriadaTeste": "criada_teste",
	"PlacaTeste": "placa_teste",
}
const ENFEITES := ["Arvore", "Anfora", "Anfora2", "Braseiro", "Braseiro2"]

var sala: Node2D


func before_each() -> void:
	Inventario.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	await wait_physics_frames(2)


func after_each() -> void:
	Inventario.limpar()


func test_itens_de_teste_tem_icone() -> void:
	for id in ["espada_teste", "pocao_teste", "carta_teste"]:
		var item := Inventario.item(id)
		assert_not_null(item, id)
		assert_not_null(item.icone, "%s sem ícone" % id)
		assert_eq(item.icone.get_size(), Vector2(32, 32), id)


func test_figurantes_tem_tamanho_do_nicholas() -> void:
	for arquivo in ["guarda_provisorio", "criada_provisoria"]:
		var textura: Texture2D = load(PASTA + "exploracao/%s.png" % arquivo)
		assert_eq(textura.get_size(), Vector2(32, 48), arquivo)


func test_bau_comeca_fechado() -> void:
	var visual: Sprite2D = sala.get_node("BauTeste/Visual")
	assert_eq(visual.texture.resource_path, PASTA + "exploracao/bau_fechado.png")


func test_figurantes_e_placa_abrem_o_proprio_dialogo() -> void:
	for nome: String in FIGURANTES:
		var interagivel: Interagivel = sala.get_node("%s/Interagivel" % nome)
		assert_eq(interagivel.marcador, FIGURANTES[nome], nome)
		assert_has(interagivel.dialogo.get_cues(), FIGURANTES[nome], nome)


func test_enfeites_tem_desenho_e_bloqueiam_a_passagem() -> void:
	for nome: String in ENFEITES:
		var enfeite := sala.get_node(nome) as StaticBody2D
		assert_not_null(enfeite, nome)
		assert_not_null((enfeite.get_node("Visual") as Sprite2D).texture, nome)
		assert_true(enfeite.is_in_group(NavegacaoSala.GRUPO_OBSTACULOS), nome)


func test_nada_nasce_em_cima_de_parede() -> void:
	var chao: TileMapLayer = sala.get_node("Chao")
	var obstaculos: TileMapLayer = sala.get_node("Obstaculos")
	for nome: String in ENFEITES + FIGURANTES.keys():
		var celula := chao.local_to_map((sala.get_node(nome) as Node2D).position)
		assert_eq(obstaculos.get_cell_source_id(celula), -1, nome)
		assert_ne(chao.get_cell_source_id(celula), -1, nome)


func test_bolsa_mostra_o_icone_em_dobro() -> void:
	var icone := Inventario.item("pocao_teste").icone
	var ampliado := TelaBolsa.icone_ampliado(icone)
	assert_eq(ampliado.get_size(), icone.get_size() * TelaBolsa.ESCALA_ICONE)
	assert_null(TelaBolsa.icone_ampliado(null))
