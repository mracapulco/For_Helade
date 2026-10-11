extends GutTest
## Relacoes e Influencia usam o mesmo Medidor; testamos a base.

var medidor: Medidor


func before_each() -> void:
	medidor = autofree(Medidor.new())


func test_id_desconhecido_vale_zero() -> void:
	assert_eq(medidor.valor("ninguem"), 0)


func test_ajustar_soma_e_subtrai() -> void:
	medidor.ajustar("janet", 2)
	medidor.ajustar("janet", -1)
	assert_eq(medidor.valor("janet"), 1)


func test_ajustar_avisa_quem_ouve() -> void:
	watch_signals(medidor)
	medidor.ajustar("olympia", 3)
	assert_signal_emitted_with_parameters(medidor, "mudou", ["olympia", 3])


func test_limpar_zera_tudo() -> void:
	medidor.ajustar("janet", 1)
	medidor.limpar()
	assert_eq(medidor.valor("janet"), 0)


func test_salvar_e_restaurar() -> void:
	medidor.ajustar("janet", 2)
	medidor.ajustar("olympia", -1)
	var dados: Dictionary = medidor.para_dados()

	var outro: Medidor = autofree(Medidor.new())
	outro.de_dados(dados)
	assert_eq(outro.valor("janet"), 2)
	assert_eq(outro.valor("olympia"), -1)
