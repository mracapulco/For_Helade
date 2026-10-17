@tool
extends EditorScript
## Gera as vozes das falas com o ElevenLabs.
## Como usar: abra este arquivo no editor de scripts do Godot e use
## Arquivo > Executar (Ctrl+Shift+X). Na primeira vez ele cria
## .chaves/elevenlabs.txt na pasta do projeto: cole a chave da API lá dentro,
## salve e execute de novo. O andamento aparece na aba Saída.
## Só gera o que é novo ou mudou; o resto fica como está.


func _run() -> void:
	var chave := GeradorVozes.ler_chave()
	if chave.is_empty():
		push_warning("Falta a chave do ElevenLabs. Cole a chave em %s e execute de novo." % ProjectSettings.globalize_path(GeradorVozes.CHAVE))
		return
	var gerador := GeradorVozes.new()
	var resultado := gerador.rodar(chave)
	print("Vozes: %d geradas, %d já estavam prontas, %d com erro." % [resultado.geradas, resultado.prontas, resultado.erros.size()])
	for erro in resultado.erros:
		push_error(erro)
	EditorInterface.get_resource_filesystem().scan()
