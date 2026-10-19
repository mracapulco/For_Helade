extends GutTest
## Capítulo 01: o objetivo na tela muda com a etapa (manhã e cenas 7 a 10).

var capitulo: Capitulo01
var cena: CenaCapitulo01


func before_each() -> void:
	Codice.limpar()
	Relacoes.limpar()


func after_each() -> void:
	Codice.limpar()
	Relacoes.limpar()


func _no(alvo: Node, nome: String) -> void:
	for i in 240:
		if alvo.etapa == nome:
			return
		await wait_physics_frames(1)
	fail_test("não chegou na etapa %s (está em %s)" % [nome, alvo.etapa])


func _interagir(nome: String) -> void:
	(capitulo.objetos[nome].get_node("Interagivel") as Interagivel).interagir()


func test_manha_do_quarto_a_mesa_de_cha() -> void:
	capitulo = load("res://scenes/capitulo_01/capitulo_01.tscn").instantiate()
	capitulo.escala_tempo = 0.0
	capitulo.mostrar_dialogos = false
	capitulo.trocar_de_cena = false
	add_child_autofree(capitulo)
	await _no(capitulo, "sonho")
	assert_eq(capitulo.objetivo.chave, "")
	capitulo.chegar_na_garota()
	await _no(capitulo, "quarto")
	assert_eq(capitulo.objetivo.chave, "OBJ_CAP1_ROUPA")
	_interagir("armario")
	assert_eq(capitulo.objetivo.chave, "OBJ_CAP1_ESPELHO")
	_interagir("espelho")
	for i in 60:
		if capitulo.vestido:
			break
		await wait_physics_frames(1)
	assert_eq(capitulo.objetivo.chave, "OBJ_CAP1_SAIR_QUARTO")
	await wait_physics_frames(5)
	_interagir("porta_quarto")
	await _no(capitulo, "corredor")
	assert_eq(capitulo.objetivo.chave, "OBJ_CAP1_PORTA_ALTHEA")
	_interagir("porta_althea")
	await _no(capitulo, "esperando")
	assert_eq(capitulo.objetivo.chave, "OBJ_CAP1_OLHAR_PONTAS")
	_interagir("extremidade_esq")
	_interagir("extremidade_dir")
	assert_eq(capitulo.objetivo.chave, "", "o cortejo chega: nada a fazer")
	await _no(capitulo, "quarto_althea")
	assert_eq(capitulo.objetivo.chave, "OBJ_CAP1_ACORDAR")
	_interagir("cama_althea")
	_interagir("cama_althea")
	await _no(capitulo, "embrulho")
	assert_eq(capitulo.objetivo.chave, "OBJ_CAP1_EMBRULHO")
	_interagir("embrulho")
	await _no(capitulo, "a_mesa")
	assert_eq(capitulo.objetivo.chave, "OBJ_CAP1_MESA_CHA")
	capitulo.sentar_a_mesa()
	assert_eq(capitulo.objetivo.chave, "")


func _abrir(caminho: String, etapa_inicial: String) -> void:
	cena = load(caminho).instantiate()
	cena.escala_tempo = 0.0
	cena.mostrar_dialogos = false
	cena.trocar_de_cena = false
	add_child_autofree(cena)
	await _no(cena, etapa_inicial)
	await wait_physics_frames(10)


func test_palacio() -> void:
	await _abrir("res://scenes/capitulo_01/cena_palacio.tscn", "patio")
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_PATIO")
	cena.olhar_guardas()
	await wait_physics_frames(2)
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_PATIO", "segue Althea até a fonte")
	cena.ver_fonte()
	await _no(cena, "embarque")
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_EMBARQUE")
	cena.embarcar()
	await _no(cena, "ultimo_olhar")
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_ANEXO")
	cena.olhar_anexo()
	await _no(cena, "visao_carruagem")
	assert_eq(cena.objetivo.chave, "")


func test_butiques() -> void:
	await _abrir("res://scenes/capitulo_01/cena_butiques.tscn", "rua")
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_GUARDAS_RUA")
	cena.escolher_guardas()
	await _no(cena, "porta")
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_LOJA")
	cena.entrar_na_loja()
	await _no(cena, "escolher_presente")
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_PRESENTE")
	cena.escolher_presente()
	assert_eq(cena.objetivo.chave, "")


func test_restaurante() -> void:
	await _abrir("res://scenes/capitulo_01/cena_restaurante.tscn", "mesa")
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_MESA")
	cena.sentar_a_mesa()
	assert_eq(cena.objetivo.chave, "")
	await _no(cena, "armario")
	assert_eq(cena.objetivo.chave, "OBJ_CAP1_COLHER")
