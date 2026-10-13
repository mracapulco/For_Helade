extends GutTest
## Baú de teste na sala: dá itens e moedas uma vez e mostra o aviso.

var sala: Node2D
var personagem: PersonagemExploracao
var aviso: AvisoItens


func _abrir_sala() -> void:
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	personagem = sala.get_node("Personagem")
	aviso = sala.get_node("AvisoItens")
	await wait_physics_frames(3)
	# O chão só entra no mapa de navegação alguns quadros depois; antes disso o
	# ponto andável mais próximo é (0, 0) e o personagem não chega ao baú.
	var mapa_nav := personagem.agente.get_navigation_map()
	var bau: Vector2 = sala.get_node("BauTeste").global_position
	await wait_until(func(): return NavigationServer2D.map_get_closest_point(mapa_nav, bau).distance_to(bau) < 40.0, 5)


func before_each() -> void:
	Inventario.limpar()
	TranslationServer.set_locale("pt_BR")
	await _abrir_sala()


func after_each() -> void:
	Inventario.limpar()


func _bau_interagivel() -> Interagivel:
	return sala.get_node_or_null("BauTeste/Interagivel")


func test_bau_tem_interagivel() -> void:
	assert_not_null(_bau_interagivel())


func test_abrir_o_bau_da_itens_e_moedas() -> void:
	var pocoes := Inventario.quantidade("pocao_teste")
	var moedas := Inventario.dinheiro()
	_bau_interagivel().interagir()
	assert_eq(Inventario.quantidade("pocao_teste"), pocoes + 2)
	assert_eq(Inventario.dinheiro(), moedas + 15)


func test_mostra_o_aviso_do_que_ganhou() -> void:
	_bau_interagivel().interagir()
	assert_has(aviso.textos(), "+ Poção de teste ×2")
	assert_has(aviso.textos(), "+ 15 moedas")


func test_bau_so_da_uma_vez() -> void:
	var recompensa: Recompensa = sala.get_node("BauTeste/Recompensa")
	recompensa.entregar()
	var pocoes := Inventario.quantidade("pocao_teste")
	recompensa.entregar()
	assert_eq(Inventario.quantidade("pocao_teste"), pocoes)


func test_bau_vazio_perde_a_interacao() -> void:
	_bau_interagivel().interagir()
	await wait_process_frames(2)
	assert_null(_bau_interagivel())


func test_voltar_a_sala_nao_enche_o_bau_de_novo() -> void:
	_bau_interagivel().interagir()
	sala.queue_free()
	await wait_process_frames(2)
	await _abrir_sala()
	assert_null(_bau_interagivel())


func test_tocar_no_bau_de_longe_anda_e_abre() -> void:
	var bau := _bau_interagivel()
	var pocoes := Inventario.quantidade("pocao_teste")
	personagem.interagir_com(bau)
	await wait_for_signal(bau.interagido, 10)
	assert_eq(Inventario.quantidade("pocao_teste"), pocoes + 2)


func test_itens_de_teste_da_sala_nao_geram_aviso() -> void:
	assert_eq(aviso.textos(), [] as Array[String])


func test_bau_pego_mostra_o_desenho_aberto() -> void:
	var visual: Sprite2D = sala.get_node("BauTeste/Visual")
	var aberto: Texture2D = sala.get_node("BauTeste/Recompensa").textura_vazio
	assert_not_null(aberto)
	_bau_interagivel().interagir()
	assert_eq(visual.texture, aberto)
	assert_eq(visual.modulate, Color.WHITE, "com desenho aberto, não escurece")
