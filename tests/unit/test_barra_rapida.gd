extends GutTest
## Barra rápida da sala de teste: teclas 1 a 9 e toque usam os espaços.

var sala: Node2D
var barra: BarraRapida


func before_each() -> void:
	Inventario.limpar()
	sala = add_child_autofree(load("res://scenes/exploracao/sala_teste.tscn").instantiate())
	barra = sala.get_node("BarraRapida")
	await wait_physics_frames(2)


func after_each() -> void:
	Inventario.limpar()


func _apertar(acao: StringName) -> void:
	var evento := InputEventAction.new()
	evento.action = acao
	evento.pressed = true
	barra._unhandled_input(evento)


func test_tem_nove_espacos_numerados() -> void:
	assert_eq(barra.espacos.size(), 9)
	assert_eq((barra.espacos[0].get_node("Numero") as Label).text, "1")
	assert_eq((barra.espacos[8].get_node("Numero") as Label).text, "9")


func test_acoes_das_teclas_existem() -> void:
	for indice in 9:
		assert_true(InputMap.has_action(BarraRapida.acao_do_espaco(indice)), str(indice))


func test_tecla_do_espaco_da_espada_equipa_e_desequipa() -> void:
	var indice := _indice_de("espada_media")
	_apertar(BarraRapida.acao_do_espaco(indice))
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "espada_media")
	assert_true(barra.espacos[indice].equipado)
	_apertar(BarraRapida.acao_do_espaco(indice))
	assert_eq(Inventario.equipado("nicholas", Item.Encaixe.ARMA), "")


func test_tocar_no_espaco_bebe_a_pocao() -> void:
	var indice := _indice_de("pocao_teste")
	var antes := Inventario.quantidade("pocao_teste")
	barra.espacos[indice].pressed.emit()
	assert_eq(Inventario.quantidade("pocao_teste"), antes - 1)


func test_mostra_a_quantidade() -> void:
	var indice := _indice_de("pocao_teste")
	var qtd := Inventario.quantidade("pocao_teste")
	assert_eq((barra.espacos[indice].get_node("Quantidade") as Label).text, str(qtd))


func _indice_de(id: String) -> int:
	for indice in Inventario.ESPACOS_RAPIDOS:
		if Inventario.espaco(indice).get("id", "") == id:
			return indice
	fail_test("%s não está na barra rápida" % id)
	return -1
