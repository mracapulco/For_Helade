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
	assert_eq(vozes[0].voz_id, "WrT2M515LQuE5m5EYh0W")
	assert_has(vozes[0].falantes, "Nicholas")


func test_prologo_so_a_narracao_do_nicholas() -> void:
	var falas := GeradorVozes.falas_do_roteiro(load(PROLOGO), GeradorVozes.ler_vozes())
	var ids := _ids(falas)
	assert_has(ids, "PROLOGO_003", "Narração em primeira pessoa")
	assert_has(ids, "PROLOGO_014", "Althea?, dito por ele")
	var althea: Dictionary = falas.filter(func(f: Dictionary) -> bool: return f.id == "PROLOGO_014")[0]
	assert_eq(althea.voz, "nicholas_crianca", "Dito pelo Nicholas de 5 anos")
	assert_does_not_have(ids, "PROLOGO_001", "Título de lugar")
	assert_eq(falas.filter(func(f: Dictionary) -> bool: return f.id == "PROLOGO_018")[0].voz, "parteira", "Fala da moça que entrega Althea")
	assert_does_not_have(ids, "PROLOGO_027", "Sussurros finais")
	assert_eq(ids.size(), 24)
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
			"roteiros": ["capitulo_01"], "falas": ["PROLOGO_014"]},
	]
	var cap1 := "res://data/dialogos/capitulo_01/manha.dialogue"
	assert_eq(GeradorVozes.voz_da_fala("Nicholas", "CAP1_044", vozes, cap1).nome, "crianca", "No capítulo 1 ele é criança")
	assert_eq(GeradorVozes.voz_da_fala("Nicholas", "CAP5_001", vozes, "res://data/dialogos/capitulo_05/x.dialogue").nome, "adulto", "Fora dos roteiros da criança, vale a voz geral")
	assert_eq(GeradorVozes.voz_da_fala("", "CAP1_045", vozes, cap1).nome, "crianca")
	assert_eq(GeradorVozes.voz_da_fala("", "PROLOGO_003", vozes, PROLOGO).nome, "adulto")
	assert_eq(GeradorVozes.voz_da_fala("", "PROLOGO_014", vozes, PROLOGO).nome, "crianca", "falas vence tudo")


func test_pronuncia_so_muda_o_audio() -> void:
	var pronuncia := GeradorVozes.ler_pronuncia()
	assert_eq(GeradorVozes.pronunciar("Althea? Feliz aniversário, Thea!", pronuncia), "Alfía? Feliz aniversário, Fía!")
	assert_eq(GeradorVozes.pronunciar("Theano", pronuncia), "Theano", "Só palavra inteira")
	var falas := GeradorVozes.falas_do_roteiro(load(PROLOGO), GeradorVozes.ler_vozes(), {}, pronuncia)
	var nome: Dictionary = falas.filter(func(f: Dictionary) -> bool: return f.id == "PROLOGO_014")[0]
	assert_eq(nome.texto, "Althea?", "O índice guarda o texto da tela")
	assert_true(GeradorVozes.texto_para_voz(nome).ends_with("Alfía?"))


func test_apollon_tem_voz() -> void:
	var vozes := GeradorVozes.ler_vozes()
	assert_eq(GeradorVozes.voz_da_fala("Apollon", "CAP1_066", vozes, "res://data/dialogos/capitulo_01/manha.dialogue").voz_id, "29Pm0vQJJRoVfMCsUKB6")


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
