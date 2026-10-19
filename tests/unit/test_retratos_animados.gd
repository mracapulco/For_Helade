extends GutTest
## Retratos animados da caixa de diálogo: o rosto de quem fala na idade da
## fase do Nicholas e no sentimento da fala, com boca, piscada e a entrada do
## close quando muda quem fala.

const EMOCOES := ["neutro", "alegre", "triste", "raiva", "surpresa", "medo"]
const COM_RETRATO := ["Nicholas", "Althea", "Ophelia", "Apollon", "Janet", "Pany"]
const DIALOGO: DialogueResource = preload("res://data/dialogos/teste/teste.dialogue")

var _faixa_antes: Inventario.FaixaEtaria


func before_each() -> void:
	_faixa_antes = Inventario.faixa_etaria


func after_each() -> void:
	Inventario.faixa_etaria = _faixa_antes


func test_todos_tem_as_seis_emocoes_em_cada_fase() -> void:
	for nome: String in COM_RETRATO:
		var personagem := Elenco.buscar(nome)
		assert_not_null(personagem, nome)
		for fase: String in Personagem.FASES:
			for emocao: String in EMOCOES:
				var caminho := personagem.caminho_retrato(emocao, fase)
				assert_true(ResourceLoader.exists(caminho), caminho)
				assert_eq(personagem.quadros_fala(emocao, fase).size(), 3, "boca em 3 quadros: " + caminho)
				assert_not_null(personagem.retrato_piscando(emocao, fase), "piscada: " + caminho)


func test_idade_segue_a_fase_do_nicholas() -> void:
	var althea := Elenco.buscar("Althea")
	assert_eq(althea.idade_na_fase("crianca"), "6", "Nicholas com 11, Althea com 6")
	assert_eq(althea.idade_na_fase("adulto"), "11", "Nicholas com 17, Althea com 11")
	assert_eq(Elenco.buscar("Nicholas").idade_na_fase("crianca"), "11")
	assert_eq(Elenco.buscar("Nicholas").idade_na_fase("adolescente"), "17", "sem a fase, a mais próxima e mais velha")
	assert_eq(Elenco.buscar("Apollon").idade_na_fase("crianca"), "", "uma idade só")
	assert_string_ends_with(Elenco.buscar("Apollon").caminho_retrato("triste", "adulto"), "/apollon_triste.png")


func test_emocao_sem_arte_cai_no_neutro() -> void:
	var nicholas := Elenco.buscar("Nicholas")
	assert_eq(nicholas.retrato("vergonha", "crianca"), nicholas.retrato("neutro", "crianca"))
	assert_ne(nicholas.retrato("triste", "crianca"), nicholas.retrato("neutro", "crianca"))
	assert_ne(nicholas.retrato("neutro", "adulto"), nicholas.retrato("neutro", "crianca"))


func test_parado_pisca_de_vez_em_quando() -> void:
	var caixa: CaixaDialogo = load("res://scenes/ui/caixa_dialogo.tscn").instantiate()
	add_child_autofree(caixa)
	var janet := Elenco.buscar("Janet")
	caixa._retrato_parado = janet.retrato("neutro")
	caixa._retrato_piscando = janet.retrato_piscando("neutro")
	caixa._quadros_fala = janet.quadros_fala("neutro")
	caixa._ate_piscar = 0.05
	caixa.animar_boca(0.0, false)
	assert_eq(caixa.retrato.texture, caixa._retrato_parado, "olhos abertos antes da hora")
	caixa.animar_boca(0.1, false)
	assert_eq(caixa.retrato.texture, caixa._retrato_piscando, "pisca")
	caixa.animar_boca(CaixaDialogo.TEMPO_PISCANDO, false)
	assert_eq(caixa.retrato.texture, caixa._retrato_parado, "abre de novo")
	assert_gt(caixa._ate_piscar, CaixaDialogo.INTERVALO_PISCAR.x - 0.01, "próxima piscada sorteada")


func test_close_entra_so_quando_muda_quem_fala() -> void:
	Inventario.faixa_etaria = Inventario.FaixaEtaria.CRIANCA
	var caixa: CaixaDialogo = load("res://scenes/ui/caixa_dialogo.tscn").instantiate()
	add_child_autofree(caixa)
	watch_signals(caixa)
	await caixa.start(DIALOGO, "inicio")
	assert_eq(caixa.dialogue_line.character, "Nicholas")
	assert_signal_emit_count(caixa, "rosto_entrou", 1)
	assert_eq(caixa.retrato.texture.resource_path, Elenco.buscar("Nicholas").caminho_retrato("neutro", "crianca"))
	await caixa.next(caixa.dialogue_line.next_id)
	assert_eq(caixa.dialogue_line.character, "Janet")
	assert_signal_emit_count(caixa, "rosto_entrou", 2, "mudou de Nicholas para Janet")
	assert_eq(caixa.retrato.texture.resource_path, Elenco.buscar("Janet").caminho_retrato("surpresa", "crianca"))
	await caixa.next(caixa.dialogue_line.next_id)
	assert_eq(caixa.dialogue_line.character, "Janet")
	assert_signal_emit_count(caixa, "rosto_entrou", 2, "Janet continua falando: sem nova entrada")


func test_etiqueta_de_idade_troca_a_fase() -> void:
	Inventario.faixa_etaria = Inventario.FaixaEtaria.ADULTO
	var caixa: CaixaDialogo = load("res://scenes/ui/caixa_dialogo.tscn").instantiate()
	add_child_autofree(caixa)
	caixa.dialogue_line = _fala("Althea", ["idade=crianca"])
	assert_eq(caixa.fase_atual(), "crianca")
	assert_eq(caixa.retrato.texture.resource_path, Elenco.buscar("Althea").caminho_retrato("neutro", "crianca"))
	caixa.dialogue_line = _fala("Althea", [])
	assert_eq(caixa.fase_atual(), "adulto")


func _fala(personagem: String, etiquetas: Array) -> DialogueLine:
	var fala := DialogueLine.new()
	fala.character = personagem
	fala.tags = PackedStringArray(etiquetas)
	return fala
