extends GutTest
## Capítulo 01, passo 1: a manhã do aniversário, do sonho à mesa de chá.

const CENA := "res://scenes/capitulo_01/capitulo_01.tscn"

var capitulo: Capitulo01


func before_each() -> void:
	capitulo = load(CENA).instantiate()
	capitulo.escala_tempo = 0.0
	capitulo.mostrar_dialogos = false
	capitulo.trocar_de_cena = false
	add_child_autofree(capitulo)
	await _esperar_etapa("sonho")


func _esperar_etapa(nome: String) -> void:
	for i in 60:
		if capitulo.etapa == nome:
			return
		await wait_physics_frames(1)
	fail_test("não chegou na etapa %s (está em %s)" % [nome, capitulo.etapa])


func _interagir(nome: String) -> void:
	var area: Interagivel = capitulo.objetos[nome].get_node("Interagivel")
	area.interagir()


func test_comeca_no_sonho_com_a_garota_e_nicholas_de_11_anos() -> void:
	assert_eq(capitulo.etapa, "sonho")
	assert_true(capitulo.objetos.has("garota"))
	var visual: AnimatedSprite2D = capitulo.jogador.get_node("Corpo/Visual")
	assert_string_contains(visual.sprite_frames.resource_path, "nicholas_11")
	assert_eq(capitulo.jogador.grade, capitulo.sala.chao)


func test_a_manha_inteira_na_ordem() -> void:
	_interagir("porta_sonho")
	await _esperar_etapa("quarto")
	assert_false(capitulo.jogador.em_dialogo, "no quarto ele anda de novo")
	_interagir("espelho")
	assert_true(capitulo.viu_espelho)
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")
	_interagir("porta_althea")
	await _esperar_etapa("quarto_althea")
	_interagir("mesa")
	assert_eq(capitulo.etapa, "quarto_althea", "a mesa só depois de acordar Althea")
	_interagir("cama_althea")
	await _esperar_etapa("presentes")
	assert_true(capitulo.objetos.has("althea"), "Althea de pé depois de acordar")
	assert_false(capitulo.objetos["embrulho"].visible)
	_interagir("mesa")
	await _esperar_etapa("fim")
	for i in 10:
		if capitulo.cena_pedida != "":
			break
		await wait_physics_frames(1)
	assert_eq(capitulo.cena_pedida, "res://scenes/main/main.tscn")


func test_fora_de_ordem_nao_avanca() -> void:
	capitulo.olhar_espelho()
	capitulo.sair_do_quarto()
	capitulo.esperar_cortejo()
	capitulo.acordar_althea()
	capitulo.sentar_a_mesa()
	assert_eq(capitulo.etapa, "sonho")


func test_corredor_tem_oito_passos_entre_as_portas() -> void:
	_interagir("porta_sonho")
	await _esperar_etapa("quarto")
	_interagir("porta_quarto")
	await _esperar_etapa("corredor")
	var de_nicholas: Vector2 = capitulo.objetos["porta_nicholas"].position
	var de_althea: Vector2 = capitulo.objetos["porta_althea"].position
	var casas := capitulo.sala.chao.local_to_map(de_nicholas) - capitulo.sala.chao.local_to_map(de_althea)
	assert_eq(casas, Vector2i(8, 0))


func test_falas_estao_no_elenco() -> void:
	var roteiro: DialogueResource = load("res://data/dialogos/capitulo_01/manha.dialogue")
	for marcador in ["cortejo", "acordar_althea"]:
		var linha: DialogueLine = await roteiro.get_next_dialogue_line(marcador)
		while linha:
			if linha.character != "":
				assert_not_null(Elenco.buscar(linha.character), linha.character)
			linha = await roteiro.get_next_dialogue_line(linha.next_id)
