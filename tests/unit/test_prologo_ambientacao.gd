extends GutTest
## Visual realista do prólogo: materiais com relevo, chamas que tremulam e a
## sensação de ser o Nicholas (respiração, passos, vinheta).

const CENA := preload("res://scenes/prologo/prologo.tscn")
const MATERIAIS := "res://assets/art/prologo/materiais/"


func test_toda_etapa_da_sequencia_tem_respiracao_e_visao() -> void:
	var fonte := FileAccess.get_file_as_string("res://scripts/prologo/sequencia_prologo.gd")
	var busca := RegEx.create_from_string("_mudar\\(\"([a-z_]+)\"\\)")
	var etapas := busca.search_all(fonte)
	assert_gt(etapas.size(), 5)
	for achado: RegExMatch in etapas:
		var etapa := achado.get_string(1)
		assert_true(SensacaoPrimeiraPessoa.ESTADOS.has(etapa), "sem estado para a etapa " + etapa)
		var estado := SensacaoPrimeiraPessoa.estado_para(etapa)
		assert_true(SensacaoPrimeiraPessoa.RESPIRACOES.has(estado["respiracao"]))


func test_quando_althea_nasce_muda_nicholas_prende_a_respiracao() -> void:
	var muda := SensacaoPrimeiraPessoa.estado_para("muda")
	var antes := SensacaoPrimeiraPessoa.estado_para("")
	assert_eq(muda["respiracao"], "presa")
	assert_gt(muda["desfoque"], antes["desfoque"])
	assert_gt(muda["vinheta"], antes["vinheta"])


func test_chama_tremula_em_volta_do_brilho() -> void:
	var luz := ChamaTremula.new()
	luz.light_energy = 2.0
	add_child_autofree(luz)
	for i in 20:
		await wait_process_frames(1)
		assert_between(luz.light_energy, 2.0 * (1.0 - luz.tremor) - 0.001, 2.0 * (1.0 + luz.tremor) + 0.001)
	luz.brilho = 0.5
	await wait_process_frames(2)
	assert_lt(luz.light_energy, 0.5 * (1.0 + luz.tremor) + 0.001, "a sequência apaga a vela pelo brilho")


func test_todas_as_luzes_do_cenario_sao_chamas() -> void:
	var cena: Node = CENA.instantiate()
	var luzes := cena.get_node("Cenario").find_children("*", "OmniLight3D", true, false)
	assert_gt(luzes.size(), 4)
	for luz in luzes:
		assert_true(luz is ChamaTremula, luz.name + " deveria tremular")
	cena.free()


func test_materiais_realistas_tem_relevo_e_nao_esticam() -> void:
	var nomes := DirAccess.get_files_at(MATERIAIS)
	var com_textura := 0
	for nome in nomes:
		if not nome.ends_with(".tres"):
			continue
		var material: StandardMaterial3D = load(MATERIAIS + nome)
		if material.albedo_texture == null:
			continue
		com_textura += 1
		assert_true(material.normal_enabled and material.normal_texture != null, nome + " sem relevo")
		assert_true(material.uv1_triplanar and material.uv1_world_triplanar, nome + " estica nas caixas")
	assert_gt(com_textura, 6)


func test_vinheta_nao_bloqueia_toques() -> void:
	var cena: Node = CENA.instantiate()
	var vinheta: ColorRect = cena.get_node("Visao/Vinheta")
	assert_eq(vinheta.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_true(vinheta.material is ShaderMaterial)
	cena.free()


func test_toda_vela_e_tocha_tem_chama_visivel() -> void:
	var cena: Node = CENA.instantiate()
	cena.abertura = null
	cena.roteiro = null
	add_child_autofree(cena)
	await wait_physics_frames(1)
	var chamas: Array[Vector3] = []
	for malha: MeshInstance3D in cena.get_node("Cenario").find_children("*", "MeshInstance3D", true, false):
		if malha.material_override and malha.material_override.resource_name == "chama":
			chamas.append(malha.global_position)
	assert_gt(chamas.size(), 10)
	for luz: OmniLight3D in cena.get_node("Cenario").find_children("*", "OmniLight3D", true, false):
		if luz.name == "LuzPorta":
			continue # claridade que sai dos aposentos pela porta
		var perto := chamas.any(func(p: Vector3) -> bool: return p.distance_to(luz.global_position) < 0.8)
		assert_true(perto, luz.name + " ilumina sem chama")
	# E o contrário: toda chama acesa ilumina (pedido do Rafael, 14/10/2026).
	var luzes: Array[Vector3] = []
	for luz: OmniLight3D in cena.get_node("Cenario").find_children("*", "OmniLight3D", true, false):
		luzes.append(luz.global_position)
	for chama in chamas:
		var perto := luzes.any(func(p: Vector3) -> bool: return p.distance_to(chama) < 0.8)
		assert_true(perto, "chama sem luz em %s" % chama)


func test_quadros_mostram_o_mapa_em_pixel_art() -> void:
	var cena: Node = CENA.instantiate()
	var quadros := cena.find_children("Quadro*", "Node3D", true, false)
	assert_gte(quadros.size(), 5, "dois no corredor e outros nos quartos")
	for quadro: Node3D in quadros:
		var tela: MeshInstance3D = quadro.get_node("Tela")
		var material: StandardMaterial3D = tela.material_override
		assert_not_null(material.albedo_texture, "quadro sem imagem")
		assert_true(material.albedo_texture.resource_path.begins_with("res://assets/art/prologo/quadros/"))
		assert_eq(material.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST, "pixel art sem borrar")
	assert_eq(cena.find_children("EspadaNaParede*", "Node3D", true, false).size(), 1)
	cena.free()


func test_nada_pendurado_no_vao_da_porta_dos_aposentos() -> void:
	# A porta dupla dos aposentos vai de x 8 a 10, na parede em z 3,6 a 3,9.
	# Os enfeites ficam direto no cômodo, e o cômodo fica na origem.
	var cena: Node = CENA.instantiate()
	var aposentos: Node3D = cena.get_node("Cenario/Aposentos")
	assert_eq(aposentos.position, Vector3.ZERO)
	for no in aposentos.get_children():
		if no.name.begins_with("Tapecaria") or no.name.begins_with("Quadro"):
			var p: Vector3 = (no as Node3D).position
			var no_vao := p.x > 7.0 and p.x < 11.0 and p.z < 4.3
			assert_false(no_vao, "%s está no vão da porta" % no.name)
	cena.free()
