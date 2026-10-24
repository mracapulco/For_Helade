extends GutTest
## A sopa do restaurante no ritmo: acerta quando o anel encontra o círculo.

var sopa: SopaNoRitmo


func before_each() -> void:
	sopa = SopaNoRitmo.new()
	add_child_autofree(sopa)


func test_cinco_passos_no_tempo_certo() -> void:
	sopa.comecar()
	for i in SopaNoRitmo.PASSOS.size():
		sopa._pausa = 0.0
		sopa.raio = SopaNoRitmo.ALVO
		assert_true(sopa.tentar())
	assert_eq(sopa.passo, SopaNoRitmo.PASSOS.size())
	assert_false(sopa.tentar(), "acabou")


func test_fora_do_tempo_nao_avanca_nem_pune() -> void:
	sopa.comecar()
	sopa.raio = SopaNoRitmo.RAIO_INICIAL
	assert_false(sopa.tentar())
	assert_eq(sopa.passo, 0)
	sopa._pausa = 0.0
	sopa.raio = SopaNoRitmo.ALVO + SopaNoRitmo.FOLGA - 0.5
	assert_true(sopa.tentar())
	assert_eq(sopa.passo, 1)


func test_sem_tempo_termina_na_hora() -> void:
	sopa.escala_tempo = 0.0
	await sopa.comecar()
	assert_eq(sopa.passo, SopaNoRitmo.PASSOS.size())
