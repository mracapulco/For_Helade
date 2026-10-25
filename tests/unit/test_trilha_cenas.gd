extends GutTest
## Trilha por cena e etapa (data/musica/cenas.cfg): os arquivos existem, a
## música e o ambiente trocam sozinhos com o sinal etapa_mudou da cena.

const CAP1 := "res://scenes/capitulo_01/capitulo_01.tscn"
const MUSICAS := "res://assets/audio/music/capitulo_01/"
const AMBIENTES := "res://assets/audio/ambiente/capitulo_01/"


func before_each() -> void:
	Trilha.parar(0.0)
	Trilha.ambientar("", 0.0)


func after_each() -> void:
	Trilha.parar(0.0)
	Trilha.ambientar("", 0.0)


func test_todo_arquivo_da_lista_existe() -> void:
	var t := TrilhaDasCenas.carregar()
	assert_gt(t.cenas().size(), 0, "a lista abriu")
	for cena in t.cenas():
		for etapa in t.etapas(cena):
			var f := t.faixas(cena, etapa)
			assert_false(f.is_empty(), "%s/%s é [música, ambiente]" % [cena, etapa])
			for caminho: String in [f.musica, f.ambiente]:
				if caminho != "" and caminho != TrilhaDasCenas.MANTER:
					assert_true(ResourceLoader.exists(caminho), "%s/%s: %s existe" % [cena, etapa, caminho])


func test_musicas_do_capitulo_em_loop() -> void:
	for nome in ["sonho", "madrugada", "cortejo", "aniversario", "duque", "carruagem", "palacio",
			"ophelia", "butiques", "loja", "restaurante", "passeio", "danica", "antessala"]:
		var musica: AudioStreamWAV = load(MUSICAS + "cap01_%s.wav" % nome)
		assert_eq(musica.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s em loop" % nome)
	for nome in ["fonte_palacio", "rua_butiques", "restaurante", "anoitecer_mansao"]:
		var ambiente: AudioStreamOggVorbis = load(AMBIENTES + nome + ".ogg")
		assert_true(ambiente.loop, "%s em loop" % nome)


## Toda cena do capítulo tem música (as que só entram dentro de outra ficam de fora).
func test_toda_cena_do_capitulo_tem_musica() -> void:
	var t := TrilhaDasCenas.carregar()
	for arquivo in DirAccess.get_files_at("res://scenes/capitulo_01/"):
		if arquivo.ends_with(".tscn") and arquivo not in ["nicholas_11.tscn", "visao_varanda.tscn"]:
			assert_true(t.tem("res://scenes/capitulo_01/" + arquivo), "%s tem música" % arquivo)


func test_volta_troca_para_a_antessala() -> void:
	var volta := "res://scenes/capitulo_01/cena_volta.tscn"
	Trilha.na_etapa(volta, TrilhaDasCenas.INICIO)
	assert_eq(Trilha.atual, MUSICAS + "cap01_danica.wav")
	Trilha.na_etapa(volta, "antessala")
	assert_eq(Trilha.atual, MUSICAS + "cap01_antessala.wav")


func test_etapa_troca_a_musica() -> void:
	Trilha.na_etapa(CAP1, "sonho")
	assert_eq(Trilha.atual, MUSICAS + "cap01_sonho.wav")
	Trilha.na_etapa(CAP1, "porta_do_sonho")
	assert_eq(Trilha.atual, "", "o silêncio pesado da porta aberta")
	Trilha.na_etapa(CAP1, "quarto")
	assert_eq(Trilha.atual, MUSICAS + "cap01_madrugada.wav")
	Trilha.na_etapa(CAP1, "corredor")
	assert_eq(Trilha.atual, MUSICAS + "cap01_madrugada.wav", "etapa fora da lista não muda nada")


func test_ambiente_por_baixo_e_manter() -> void:
	Trilha.na_etapa("res://scenes/capitulo_01/cena_butiques.tscn", TrilhaDasCenas.INICIO)
	assert_eq(Trilha.ambiente_atual, AMBIENTES + "rua_butiques.ogg")
	assert_true(Trilha.tocador_ambiente().playing)
	assert_eq(Trilha.tocador_ambiente().bus, Trilha.BARRAMENTO_AMBIENTE)
	Trilha.na_etapa("res://scenes/capitulo_01/cena_butiques.tscn", "loja")
	assert_eq(Trilha.atual, MUSICAS + "cap01_loja.wav")
	assert_eq(Trilha.ambiente_atual, "", "dentro da loja a rua some")
	Trilha.na_etapa(CAP1, "palacio")
	Trilha.na_etapa("res://scenes/capitulo_01/cena_palacio.tscn", "ophelia")
	assert_eq(Trilha.atual, MUSICAS + "cap01_ophelia.wav")
	assert_eq(Trilha.ambiente_atual, AMBIENTES + "fonte_palacio.ogg", "\"=\" mantém a fonte")


func test_observar_segue_o_sinal_da_cena() -> void:
	var cena := Node.new()
	cena.scene_file_path = CAP1
	cena.add_user_signal("etapa_mudou", [{"name": "etapa", "type": TYPE_STRING}])
	add_child_autofree(cena)
	Trilha.observar(cena)
	cena.emit_signal("etapa_mudou", "cortejo")
	assert_eq(Trilha.atual, MUSICAS + "cap01_cortejo.wav")
	cena.emit_signal("etapa_mudou", "duque")
	assert_eq(Trilha.atual, MUSICAS + "cap01_duque.wav")


func test_cena_fora_da_lista_para_o_ambiente() -> void:
	Trilha.ambientar(AMBIENTES + "fonte_palacio.ogg", 0.0)
	Trilha.tocar(MUSICAS + "cap01_palacio.wav", 0.0)
	var outra := Node.new()
	outra.scene_file_path = "res://scenes/mapa/mapa_helade.tscn"
	add_child_autofree(outra)
	Trilha.observar(outra)
	assert_eq(Trilha.ambiente_atual, "")
	assert_eq(Trilha.atual, MUSICAS + "cap01_palacio.wav", "a música fica com a cena (o mapa troca a dele)")


func test_cena_dentro_de_outra_nao_mexe() -> void:
	var cena := Node.new()
	cena.scene_file_path = CAP1
	add_child_autofree(cena)
	assert_eq(Trilha.atual, "", "só a cena principal (filha da raiz) conta")
