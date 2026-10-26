extends GutTest
## Vozes do ElevenLabs: quais falas ganham voz, o que falta gerar e o
## autoload Voz que toca os áudios.

const PROLOGO := "res://data/dialogos/prologo/prologo.dialogue"
const PASTA_TESTE := "user://teste_vozes"


func after_each() -> void:
	if not DirAccess.dir_exists_absolute(PASTA_TESTE):
		Voz.carregar_indice()
		return
	for arquivo in DirAccess.get_files_at(PASTA_TESTE):
		DirAccess.remove_absolute(PASTA_TESTE.path_join(arquivo))
	Voz.carregar_indice()


func _ids(falas: Array[Dictionary]) -> Array:
	return falas.map(func(f: Dictionary) -> String: return f.id)


func test_config_tem_a_voz_do_nicholas() -> void:
	var vozes := GeradorVozes.ler_vozes()
	assert_eq(vozes[0].nome, "nicholas")
	assert_eq(vozes[0].voz_id, "ELBrtmIkk40wCZ5YnlwM", "voz nova, 17/10/2026")
	assert_has(vozes[0].falantes, "Nicholas")


func test_prologo_so_a_narracao_do_nicholas() -> void:
	var falas := GeradorVozes.falas_do_roteiro(load(PROLOGO), GeradorVozes.ler_vozes())
	var ids := _ids(falas)
	assert_has(ids, "PROLOGO_003", "Narração em primeira pessoa")
	assert_does_not_have(ids, "PROLOGO_014", "Althea? ficou sem voz (Rafael, 18/10/2026)")
	assert_does_not_have(ids, "PROLOGO_001", "Título de lugar")
	assert_eq(falas.filter(func(f: Dictionary) -> bool: return f.id == "PROLOGO_018")[0].voz, "parteira", "Fala da moça que entrega Althea")
	assert_eq(ids.size(), 22 + 1 + 3 + 4, "narração, parteira e o coro dos sussurros")
	assert_eq(falas[0].modelo, "eleven_v3")
	assert_eq(falas[0].texto, "Esta é a memória mais vívida que tenho da minha infância.")


func test_emocao_vai_na_frente_do_texto() -> void:
	var direcao := GeradorVozes.ler_direcao()
	assert_eq(direcao.get("PROLOGO_008"), "[whispers] [shocked]")
	var falas := GeradorVozes.falas_do_roteiro(load(PROLOGO), GeradorVozes.ler_vozes(), direcao)
	var eu_congelei: Dictionary = falas.filter(func(f: Dictionary) -> bool: return f.id == "PROLOGO_008")[0]
	assert_eq(eu_congelei.texto, "Eu congelei.", "O índice guarda o texto sem etiquetas")
	assert_eq(GeradorVozes.texto_para_voz(eu_congelei), "[Brazilian Portuguese accent] [whispers] [shocked] Eu congelei.")


func test_toda_fala_com_voz_tem_emocao() -> void:
	var direcao := GeradorVozes.ler_direcao()
	for fala in GeradorVozes.falas_do_roteiro(load(PROLOGO), GeradorVozes.ler_vozes(), direcao):
		assert_false(fala.direcao.is_empty(), fala.id)


func test_mudar_a_emocao_refaz_o_audio() -> void:
	var fala := {"texto": "Não.", "direcao": "[firmly]", "voz_id": "v", "modelo": "m", "estabilidade": 0.5}
	var outra := fala.duplicate()
	outra.direcao = "[angry]"
	assert_ne(GeradorVozes.assinatura(fala), GeradorVozes.assinatura(outra))


func test_sotaque_vai_antes_da_emocao() -> void:
	var fala := {"texto": "Não.", "direcao": "[firmly]", "sotaque": "[Brazilian Portuguese accent]"}
	assert_eq(GeradorVozes.texto_para_voz(fala), "[Brazilian Portuguese accent] [firmly] Não.")
	assert_eq(GeradorVozes.texto_para_voz({"texto": "Não."}), "Não.")
	assert_eq(GeradorVozes.ler_vozes()[0].sotaque, "[Brazilian Portuguese accent]")


func test_npcs_usam_a_voz_coringa() -> void:
	var vozes: Array[Dictionary] = [
		{"nome": "npcs", "voz_id": "n", "modelo": "m", "falantes": ["*"], "narracao": []},
		{"nome": "janet", "voz_id": "j", "modelo": "m", "falantes": ["Janet"], "narracao": []},
	]
	assert_eq(GeradorVozes.voz_da_fala("Janet", "X", vozes).nome, "janet", "Voz própria vence o coringa")
	assert_eq(GeradorVozes.voz_da_fala("Mercador", "X", vozes).nome, "npcs")
	assert_true(GeradorVozes.voz_da_fala("", "X", vozes).is_empty(), "Narração sem ID listado fica sem voz")


func test_idade_pelo_roteiro_e_excecoes_por_fala() -> void:
	var vozes: Array[Dictionary] = [
		{"nome": "adulto", "voz_id": "a", "modelo": "m", "falantes": ["Nicholas"], "narracao": ["PROLOGO_003"]},
		{"nome": "crianca", "voz_id": "c", "modelo": "m", "falantes": ["Nicholas"], "narracao": ["CAP1_045"],
			"roteiros": ["capitulo_01"], "falas": ["PROLOGO_099"]},
	]
	var cap1 := "res://data/dialogos/capitulo_01/manha.dialogue"
	assert_eq(GeradorVozes.voz_da_fala("Nicholas", "CAP1_044", vozes, cap1).nome, "crianca", "No capítulo 1 ele é criança")
	assert_eq(GeradorVozes.voz_da_fala("Nicholas", "CAP5_001", vozes, "res://data/dialogos/capitulo_05/x.dialogue").nome, "adulto", "Fora dos roteiros da criança, vale a voz geral")
	assert_eq(GeradorVozes.voz_da_fala("", "CAP1_045", vozes, cap1).nome, "crianca")
	assert_eq(GeradorVozes.voz_da_fala("", "PROLOGO_003", vozes, PROLOGO).nome, "adulto")
	assert_eq(GeradorVozes.voz_da_fala("", "PROLOGO_099", vozes, PROLOGO).nome, "crianca", "falas vence tudo")


func test_pronuncia_so_muda_o_audio() -> void:
	var pronuncia := GeradorVozes.ler_pronuncia()
	assert_eq(GeradorVozes.pronunciar("Althea? Feliz aniversário, Thea!", pronuncia), "Alfía? Feliz aniversário, Fía!")
	assert_eq(GeradorVozes.pronunciar("Theano", pronuncia), "Theano", "Só palavra inteira")


func test_apollon_tem_voz() -> void:
	var vozes := GeradorVozes.ler_vozes()
	assert_eq(GeradorVozes.voz_da_fala("Apollon", "CAP1_066", vozes, "res://data/dialogos/capitulo_01/manha.dialogue").voz_id, "GIuLCSVfgJaUuh7hYOY8")


func test_pany_tem_voz() -> void:
	var vozes := GeradorVozes.ler_vozes()
	assert_eq(GeradorVozes.voz_da_fala("Pany", "CAP1_053", vozes, "res://data/dialogos/capitulo_01/manha.dialogue").voz_id, "eBthAb30UYbt2nojGXeA")


func test_sussurros_finais_sao_um_coro_que_cresce() -> void:
	# Rafael (17/10/2026): duas vozes, depois três, depois quatro.
	var falas := GeradorVozes.falas_do_roteiro(load(PROLOGO), GeradorVozes.ler_vozes(), GeradorVozes.ler_direcao())
	var esperado := {"PROLOGO_027": 2, "PROLOGO_028": 3, "PROLOGO_029": 4}
	for id: String in esperado:
		var coro := falas.filter(func(f: Dictionary) -> bool: return f.id == id)
		assert_eq(coro.size(), esperado[id], id)
		var arquivos := coro.map(func(f: Dictionary) -> String: return f.arquivo)
		var esperados := range(1, esperado[id] + 1).map(func(n: int) -> String: return "%s_%d" % [id, n])
		assert_eq(arquivos, esperados, "um arquivo por pessoa do coro")
		var ids_de_voz := coro.map(func(f: Dictionary) -> String: return f.voz_id)
		for voz_id in ids_de_voz:
			assert_eq(ids_de_voz.count(voz_id), 1, "cada pessoa com sua voz")
		assert_string_contains(coro[0].direcao, "[whispers]")


func test_coro_gera_cada_voz_separada() -> void:
	var gerador := GeradorVozes.new()
	gerador.pasta_saida = PASTA_TESTE
	DirAccess.make_dir_recursive_absolute(PASTA_TESTE)
	var um := {"id": "S", "arquivo": "S_1", "texto": "Por Hélade.", "voz": "c", "voz_id": "a", "modelo": "m"}
	var dois := {"id": "S", "arquivo": "S_2", "texto": "Por Hélade.", "voz": "c", "voz_id": "b", "modelo": "m"}
	FileAccess.open(gerador.caminho_audio("S_1"), FileAccess.WRITE).store_string("mp3")
	var indice := {"S_1": {"assinatura": GeradorVozes.assinatura(um)}}
	var falas: Array[Dictionary] = [um, dois]
	var faltam := gerador.pendentes(falas, indice)
	assert_eq(faltam.size(), 1)
	assert_eq(faltam[0].arquivo, "S_2")


func test_voz_acha_o_coro_pelo_texto() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA_TESTE)
	var caminho := PASTA_TESTE.path_join("indice.json")
	var indice := {"PROLOGO_027_1": {"fala": "PROLOGO_027", "texto": "Por Hélade."}, "PROLOGO_027_2": {"fala": "PROLOGO_027", "texto": "Por Hélade."}}
	FileAccess.open(caminho, FileAccess.WRITE).store_string(JSON.stringify(indice))
	Voz.carregar_indice(caminho)
	assert_eq(Voz.id_do_texto("Por Hélade."), "PROLOGO_027")


func test_falas_com_nome_usam_o_falante() -> void:
	var vozes: Array[Dictionary] = [{"nome": "x", "voz_id": "v", "modelo": "m", "falantes": ["Janet"], "narracao": []}]
	var falas := GeradorVozes.falas_do_roteiro(load("res://data/dialogos/teste/teste.dialogue"), vozes)
	assert_eq(_ids(falas), ["TESTE_002", "TESTE_003", "TESTE_006"])


func test_roteiros_de_teste_ficam_de_fora() -> void:
	var lista := GeradorVozes.roteiros()
	assert_has(lista, PROLOGO)
	for caminho in lista:
		assert_false("/teste/" in caminho, caminho)


func test_limpar_tira_etiquetas() -> void:
	assert_eq(GeradorVozes.limpar("[Provisório] Olá, [b]Thea[/b]. "), "Olá, Thea.")


func test_pendentes_so_o_que_falta_ou_mudou() -> void:
	var gerador := GeradorVozes.new()
	gerador.pasta_saida = PASTA_TESTE
	DirAccess.make_dir_recursive_absolute(PASTA_TESTE)
	var pronta := {"id": "A", "texto": "Um.", "voz": "n", "voz_id": "v", "modelo": "m"}
	var mudou := {"id": "B", "texto": "Dois, novo.", "voz": "n", "voz_id": "v", "modelo": "m"}
	var nova := {"id": "C", "texto": "Três.", "voz": "n", "voz_id": "v", "modelo": "m"}
	for id in ["A", "B"]:
		FileAccess.open(gerador.caminho_audio(id), FileAccess.WRITE).store_string("mp3")
	var indice := {
		"A": {"assinatura": GeradorVozes.assinatura(pronta)},
		"B": {"assinatura": GeradorVozes.assinatura({"texto": "Dois.", "voz_id": "v", "modelo": "m"})},
	}
	var falas: Array[Dictionary] = [pronta, mudou, nova]
	assert_eq(_ids(gerador.pendentes(falas, indice)), ["B", "C"])


func test_sem_chave_cria_o_arquivo_para_colar() -> void:
	var caminho := PASTA_TESTE.path_join("chave.txt")
	assert_eq(GeradorVozes.ler_chave(caminho), "")
	assert_true(FileAccess.file_exists(caminho))
	assert_true(FileAccess.file_exists(PASTA_TESTE.path_join(".gdignore")))
	FileAccess.open(caminho, FileAccess.WRITE).store_string("abc123\n")
	assert_eq(GeradorVozes.ler_chave(caminho), "abc123")


func test_voz_acha_a_fala_pelo_texto() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA_TESTE)
	var caminho := PASTA_TESTE.path_join("indice.json")
	FileAccess.open(caminho, FileAccess.WRITE).store_string(JSON.stringify({"CAP1_080": {"texto": "Não."}}))
	Voz.carregar_indice(caminho)
	assert_eq(Voz.id_do_texto("Não."), "CAP1_080")
	assert_eq(Voz.id_do_texto("  Não. "), "CAP1_080")
	assert_eq(Voz.id_do_texto("Sim."), "")


func test_sem_audio_a_fala_segue_em_silencio() -> void:
	assert_eq(Voz.tocar("NAO_EXISTE"), 0.0)
	assert_eq(Voz.tocar(""), 0.0)
	assert_false(Voz.tocando())


func test_volume_da_voz_nas_opcoes() -> void:
	assert_true(AudioServer.get_bus_index(&"Voz") >= 0)
	assert_eq(Configuracoes.BARRAMENTOS.get("volume_voz"), "Voz")


# --- Capítulo 01: sons, narração adulta e os guardas (Rafael, 17/10/2026) ---

const MANHA := "res://data/dialogos/capitulo_01/manha.dialogue"


func _da_manha() -> Array[Dictionary]:
	return GeradorVozes.falas_do_roteiro(load(MANHA), GeradorVozes.ler_vozes(), GeradorVozes.ler_direcao(), {}, GeradorVozes.ler_sons())


func _arquivo(falas: Array[Dictionary], arquivo: String) -> Dictionary:
	var achadas := falas.filter(func(f: Dictionary) -> bool: return f.arquivo == arquivo)
	return achadas[0] if not achadas.is_empty() else {}


func test_pe_no_chao_e_cochichos_sao_efeitos() -> void:
	var falas := _da_manha()
	for id in ["CAP1_093", "CAP1_034"]:
		var som := _arquivo(falas, id + "_som")
		assert_eq(som.get("tipo"), "efeito", id)
		assert_false(str(som.falado).is_empty())
		# Rafael, 21/10/2026: a frase também é narrada pelo Nicholas criança.
		assert_eq(_arquivo(falas, id).get("voz"), "nicholas_crianca", id)


func test_althea_resmunga_com_a_voz_dela() -> void:
	var som := _arquivo(_da_manha(), "CAP1_094_som")
	assert_eq(som.voz, "althea_crianca")
	assert_string_contains(GeradorVozes.texto_para_voz(som), "[grumbles]")
	assert_eq(som.texto, "Althea resmungou e apertou a pelúcia.", "o índice guarda o texto da tela")


## Rafael, 21/10/2026: a narração do Capítulo 01 é do Nicholas criança.
func test_nicholas_crianca_narra_no_capitulo_01() -> void:
	var falas := _da_manha()
	for id in ["CAP1_016", "CAP1_030", "CAP1_061", "CAP1_083", "CAP1_084", "CAP1_103", "CAP1_104", "CAP1_105"]:
		assert_eq(_arquivo(falas, id).get("voz"), "nicholas_crianca", id)


## Rafael, 21/10/2026: um guarda só anuncia o duque, com voz firme.
func test_um_guarda_anuncia_o_duque() -> void:
	var fala := _arquivo(_da_manha(), "CAP1_064")
	assert_eq(fala.get("voz"), "guarda_imperial")
	assert_eq(fala.get("voz_id"), "Ey5AWb48tVX1IOcikcht")


func test_efeito_muda_de_assinatura_com_a_duracao() -> void:
	var curto := {"texto": "x", "falado": "steps", "voz_id": "efeito", "modelo": "sound-generation", "duracao": 2.0}
	var longo := curto.duplicate()
	longo.duracao = 4.0
	assert_ne(GeradorVozes.assinatura(curto), GeradorVozes.assinatura(longo))


func test_voz_acha_o_som_pelo_texto() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA_TESTE)
	var caminho := PASTA_TESTE.path_join("indice.json")
	FileAccess.open(caminho, FileAccess.WRITE).store_string(JSON.stringify({"CAP1_093_som": {"fala": "CAP1_093", "texto": "Bateu o pé no chão."}}))
	Voz.carregar_indice(caminho)
	assert_eq(Voz.id_do_texto("Bateu o pé no chão."), "CAP1_093")


func test_estabilidade_por_fala_vence_a_da_voz() -> void:
	var vozes := GeradorVozes.ler_vozes()
	var base := GeradorVozes.falas_do_roteiro(load(MANHA), vozes)
	var id: String = base[0].id
	var com := GeradorVozes.falas_do_roteiro(load(MANHA), vozes, {}, {}, {}, {id: 0.9})
	assert_eq(com[0].estabilidade, 0.9)
	assert_eq(com[1].estabilidade, base[1].estabilidade, "as outras seguem a voz")


func test_podar_tira_do_indice_o_que_nao_tem_mais_voz() -> void:
	var falas: Array[Dictionary] = [{"id": "A"}, {"id": "S", "arquivo": "S_1"}]
	var indice := {"A": {"fala": "A"}, "S_1": {"fala": "S"}, "CAP1_107": {"fala": "CAP1_107"}, "S_2": {"fala": "S"}}
	var podado := GeradorVozes.podar(falas, indice)
	assert_eq_deep(podado.keys(), ["A", "S_1"])


func test_mp3_antigo_fora_do_indice_nao_toca() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA_TESTE)
	var caminho := PASTA_TESTE.path_join("indice.json")
	FileAccess.open(caminho, FileAccess.WRITE).store_string(JSON.stringify({"CAP1_080": {"fala": "CAP1_080", "texto": "Não."}}))
	Voz.carregar_indice(caminho)
	assert_true(Voz.indexado("CAP1_080"))
	assert_false(Voz.indexado("CAP1_107"), "Fala que virou só texto: o mp3 antigo não toca")
	assert_false(Voz.disponivel("CAP1_107"))
	assert_false(Voz.tem("CAP1_107"))
	assert_eq(Voz.tocar("CAP1_107"), 0.0)


func test_sem_indice_toca_o_que_existir() -> void:
	Voz.carregar_indice(PASTA_TESTE.path_join("nao_existe.json"))
	assert_true(Voz.indexado("CAP1_107"), "Sem índice nada fica mudo por engano")
