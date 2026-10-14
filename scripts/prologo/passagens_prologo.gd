class_name PassagensPrologo
extends Node3D
## Gente que passa pela cena sem notar Nicholas ("ninguém sentiu minha
## presença"): os empregados correndo pelo corredor ("agitos dos empregados,
## uma correria") e Janet levando as roupas da duquesa no quarto vazio.
##
## Cada filho PessoaPrologo chamado X anda pelos Marker3D de um nó irmão
## "CaminhoX" quando o gatilho dele acontece, e some no fim do caminho.
## O gatilho é o nome de um PontoDeVista (Nicholas chegou lá) ou
## "etapa:nome" (uma etapa da SequenciaPrologo).

@export var controle: ControlePrimeiraPessoa
@export var sequencia: SequenciaPrologo
## Gatilho de cada pessoa, pelo nome dela.
@export var gatilhos := {}
## Metros por segundo de cada pessoa (sem valor: 2,8, correndo).
@export var velocidades := {}
## Atividade de quem anda, por pessoa (sem valor: correndo ou andando,
## pela velocidade).
@export var atividades := {}
## Quem já aparece parado no começo do caminho durante a espera (Janet
## pegando as roupas), em vez de surgir só na hora de andar.
@export var aparecem_antes: Array[String] = []
## Segundos de espera depois do gatilho, por pessoa (sem valor: parte já).
@export var atrasos := {}
## Etapas da sequência em que quem ainda está no caminho some de vez.
@export var etapas_que_encerram: Array[String] = ["caos"]

## Pessoas andando agora, com o caminho que falta.
var em_caminho := {}
var _ja_passaram: Array[String] = []
var _encerrado := false


func _ready() -> void:
	for pessoa in pessoas():
		pessoa.visible = false
	if controle:
		controle.chegou.connect(func(ponto: PontoDeVista) -> void: _gatilho(ponto.name))
	if sequencia:
		sequencia.etapa_mudou.connect(_ao_mudar_etapa)


func pessoas() -> Array[PessoaPrologo]:
	var lista: Array[PessoaPrologo] = []
	for filho in get_children():
		if filho is PessoaPrologo:
			lista.append(filho)
	return lista


func passou(nome: String) -> bool:
	return nome in _ja_passaram


func _ao_mudar_etapa(etapa: String) -> void:
	if etapa in etapas_que_encerram:
		_encerrado = true
		for pessoa: PessoaPrologo in em_caminho.keys():
			_chegou_ao_fim(pessoa)
	_gatilho("etapa:" + etapa)


func _gatilho(nome: String) -> void:
	for pessoa in pessoas():
		if gatilhos.get(String(pessoa.name), "") == nome and not passou(pessoa.name):
			_ja_passaram.append(pessoa.name)
			var atraso: float = atrasos.get(String(pessoa.name), 0.0)
			if atraso > 0.0:
				if String(pessoa.name) in aparecem_antes:
					_mostrar_no_comeco(pessoa)
				get_tree().create_timer(atraso, false).timeout.connect(_partir.bind(pessoa))
			else:
				_partir(pessoa)


func _partir(pessoa: PessoaPrologo) -> void:
	# Quem corria no corredor não aparece mais depois que Nicholas entra.
	if _encerrado and not String(gatilhos.get(String(pessoa.name), "")).begins_with("etapa:"):
		return
	var caminho := get_node_or_null("Caminho" + pessoa.name)
	if caminho == null or caminho.get_child_count() == 0:
		return
	var pontos: Array[Vector3] = []
	for marco in caminho.get_children():
		pontos.append((marco as Node3D).global_position)
	pessoa.global_position = pontos[0]
	pessoa.visible = true
	var rapidez: float = velocidades.get(String(pessoa.name), 2.8)
	pessoa.atividade = atividades.get(String(pessoa.name), "correndo" if rapidez > 2.0 else "andando")
	em_caminho[pessoa] = {"pontos": pontos.slice(1), "rapidez": rapidez}
	_virar(pessoa, pontos[1] if pontos.size() > 1 else pontos[0])


func _mostrar_no_comeco(pessoa: PessoaPrologo) -> void:
	var caminho := get_node_or_null("Caminho" + pessoa.name)
	if caminho == null or caminho.get_child_count() < 2:
		return
	pessoa.global_position = (caminho.get_child(0) as Node3D).global_position
	pessoa.visible = true
	pessoa.atividade = "parada"
	_virar(pessoa, (caminho.get_child(1) as Node3D).global_position)


func _physics_process(delta: float) -> void:
	for pessoa: PessoaPrologo in em_caminho.keys():
		var dados: Dictionary = em_caminho[pessoa]
		var pontos: Array = dados["pontos"]
		var passo: float = dados["rapidez"] * delta
		while passo > 0.0 and not pontos.is_empty():
			var alvo: Vector3 = pontos[0]
			var falta := alvo - pessoa.global_position
			falta.y = 0.0
			if falta.length() <= passo:
				pessoa.global_position = Vector3(alvo.x, pessoa.global_position.y, alvo.z)
				passo -= falta.length()
				pontos.pop_front()
				if not pontos.is_empty():
					_virar(pessoa, pontos[0])
			else:
				pessoa.global_position += falta.normalized() * passo
				passo = 0.0
		if pontos.is_empty():
			_chegou_ao_fim(pessoa)


func _chegou_ao_fim(pessoa: PessoaPrologo) -> void:
	em_caminho.erase(pessoa)
	pessoa.visible = false
	pessoa.atividade = "parada"


func _virar(pessoa: PessoaPrologo, alvo: Vector3) -> void:
	var direcao := alvo - pessoa.global_position
	if Vector2(direcao.x, direcao.z).length() < 0.01:
		return
	pessoa.rotation.y = atan2(-direcao.x, -direcao.z)
