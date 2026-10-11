extends GutTest
## Percorre a cena de teste como o jogador faria, sem interface.

const DIALOGO: DialogueResource = preload("res://dialogos/teste/teste.dialogue")
const FALA_DE_RETORNO := "TESTE_006"


func before_each() -> void:
	Relacoes.limpar()
	Influencia.limpar()


# Avança até a primeira fala com escolhas.
func _ate_as_escolhas() -> DialogueLine:
	var fala: DialogueLine = await DIALOGO.get_next_dialogue_line("inicio")
	while fala != null and fala.responses.is_empty():
		fala = await DIALOGO.get_next_dialogue_line(fala.next_id)
	return fala


# Escolhe a opção [param indice] e avança até a fala com [param static_id].
func _escolher_ate(indice: int, static_id: String) -> DialogueLine:
	var fala: DialogueLine = await _ate_as_escolhas()
	fala = await DIALOGO.get_next_dialogue_line(fala.responses[indice].next_id)
	while fala != null and fala.static_id != static_id:
		fala = await DIALOGO.get_next_dialogue_line(fala.next_id)
	return fala


func test_tem_tres_escolhas() -> void:
	var fala: DialogueLine = await _ate_as_escolhas()
	assert_eq(fala.responses.size(), 3)
	for opcao: DialogueResponse in fala.responses:
		assert_eq(opcao.character, "", "dois-pontos na opção vira nome de personagem: %s" % opcao.text)


func test_opcao_a_aumenta_relacao() -> void:
	var fala: DialogueLine = await _escolher_ate(0, FALA_DE_RETORNO)
	assert_not_null(fala, "a opção A deveria voltar para a fala de retorno")
	assert_eq(Relacoes.valor("janet"), 1)
	assert_eq(Influencia.valor("olympia"), 0)


func test_opcao_b_aumenta_influencia() -> void:
	var fala: DialogueLine = await _escolher_ate(1, FALA_DE_RETORNO)
	assert_not_null(fala, "a opção B deveria voltar para a fala de retorno")
	assert_eq(Relacoes.valor("janet"), 0)
	assert_eq(Influencia.valor("olympia"), 1)


func test_opcao_c_nao_muda_nada() -> void:
	var fala: DialogueLine = await _escolher_ate(2, FALA_DE_RETORNO)
	assert_not_null(fala, "a opção C deveria voltar para a fala de retorno")
	assert_eq(Relacoes.valor("janet"), 0)
	assert_eq(Influencia.valor("olympia"), 0)


func test_retrato_vem_da_etiqueta() -> void:
	var fala: DialogueLine = await DIALOGO.get_next_dialogue_line("inicio")
	assert_eq(fala.character, "Nicholas")
	assert_eq(fala.get_tag_value("retrato"), "neutro")


func test_quem_fala_esta_no_elenco() -> void:
	var fala: DialogueLine = await DIALOGO.get_next_dialogue_line("inicio")
	while fala != null:
		if not fala.character.is_empty():
			assert_not_null(Elenco.buscar(fala.character), "%s não está no Elenco" % fala.character)
		var proxima: String = fala.responses[0].next_id if not fala.responses.is_empty() else fala.next_id
		fala = await DIALOGO.get_next_dialogue_line(proxima)
