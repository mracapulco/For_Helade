extends GutTest
## Trilha: troca de música com fade e volta de onde parou.

const A := "res://assets/audio/music/mapa/mapa_dia.wav"
const B := "res://assets/audio/music/acampamentos/oa_acampamento.wav"


func before_each() -> void:
	Trilha.parar(0.0)


func after_each() -> void:
	Trilha.parar(0.0)


func test_toca_e_entra_com_fade() -> void:
	Trilha.tocar(A, 0.5)
	assert_eq(Trilha.atual, A)
	var tocador := Trilha.tocador_atual()
	assert_true(tocador.playing)
	assert_lt(tocador.volume_db, Trilha.VOLUME_DB - 20.0, "começa baixinho")
	await wait_seconds(0.7)
	assert_almost_eq(tocador.volume_db, Trilha.VOLUME_DB, 0.5, "sobe até o volume normal")


func test_troca_com_fade_sem_corte() -> void:
	Trilha.tocar(A, 0.0)
	var saindo := Trilha.tocador_atual()
	Trilha.tocar(B, 0.5)
	assert_true(is_instance_valid(saindo) and saindo.playing, "a anterior continua enquanto some")
	await wait_seconds(0.25)
	assert_lt(saindo.volume_db, Trilha.VOLUME_DB, "a anterior está baixando")
	await wait_seconds(0.5)
	assert_false(is_instance_valid(saindo), "e depois sai")


func test_volta_de_onde_parou() -> void:
	Trilha.tocar(A, 0.0)
	await wait_seconds(1.0)
	Trilha.tocar(B, 0.0)
	var parou := Trilha.posicao(A)
	assert_gt(parou, 0.5, "guardou o ponto")
	Trilha.tocar(A, 0.0)
	assert_almost_eq(Trilha.tocador_atual().get_playback_position(), parou, 0.15, "continua dali")


func test_mesma_musica_nao_recomeca() -> void:
	Trilha.tocar(A, 0.0)
	var tocador := Trilha.tocador_atual()
	Trilha.tocar(A)
	assert_eq(Trilha.tocador_atual(), tocador)
