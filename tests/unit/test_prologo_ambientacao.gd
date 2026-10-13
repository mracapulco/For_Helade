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
