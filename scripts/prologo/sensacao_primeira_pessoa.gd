class_name SensacaoPrimeiraPessoa
extends Node
## O que faz o jogador sentir que é o Nicholas: a respiração e os passos de
## uma criança na câmera, e a visão que escurece e desfoca nas bordas nos
## momentos de choque. Muda conforme a etapa da sequência do prólogo.

@export var controle: ControlePrimeiraPessoa
@export var sequencia: SequenciaPrologo
## Retângulo da tela inteira com o shader de vinheta, desfoque e granulação.
@export var vinheta: ColorRect

## Ritmo (vezes por segundo) e altura (m) da respiração.
const RESPIRACOES := {
	"calma": {"ritmo": 0.28, "altura": 0.006},
	"ofegante": {"ritmo": 0.9, "altura": 0.012},
	"presa": {"ritmo": 0.1, "altura": 0.0008},
}

## Para cada etapa da sequência (vazio = antes dos aposentos).
const ESTADOS := {
	"": {"respiracao": "calma", "vinheta": 0.35, "desfoque": 0.0},
	"caos": {"respiracao": "ofegante", "vinheta": 0.6, "desfoque": 0.35},
	"dossel": {"respiracao": "ofegante", "vinheta": 0.75, "desfoque": 0.7},
	"muda": {"respiracao": "presa", "vinheta": 0.85, "desfoque": 0.9},
	"nome": {"respiracao": "presa", "vinheta": 0.85, "desfoque": 0.9},
	"olhares": {"respiracao": "ofegante", "vinheta": 0.7, "desfoque": 0.5},
	"segurar": {"respiracao": "ofegante", "vinheta": 0.6, "desfoque": 0.3},
	"nos_bracos": {"respiracao": "calma", "vinheta": 0.55, "desfoque": 0.2},
	"depois": {"respiracao": "calma", "vinheta": 0.5, "desfoque": 0.2},
	"quarto_vazio": {"respiracao": "calma", "vinheta": 0.4, "desfoque": 0.0},
	"varanda": {"respiracao": "calma", "vinheta": 0.35, "desfoque": 0.0},
	"final": {"respiracao": "calma", "vinheta": 0.35, "desfoque": 0.0},
	"fim": {"respiracao": "calma", "vinheta": 0.35, "desfoque": 0.0},
}

## Comprimento de um passo de criança (m) e quanto a cabeça balança nele.
const PASSO := 0.4
const BALANCO_PASSO := 0.022
## Rapidez com que a respiração e a visão chegam ao novo estado.
const TRANSICAO := 1.5

var estado: Dictionary = ESTADOS[""]

var _ritmo: float = RESPIRACOES["calma"]["ritmo"]
var _altura: float = RESPIRACOES["calma"]["altura"]
var _fase_respiracao := 0.0
var _fase_passo := 0.0
var _forca_passo := 0.0
var _ultima_posicao := Vector3.ZERO


static func estado_para(etapa: String) -> Dictionary:
	return ESTADOS.get(etapa, ESTADOS[""])


func _ready() -> void:
	if sequencia:
		sequencia.etapa_mudou.connect(func(etapa: String) -> void: estado = estado_para(etapa))
	if controle and controle.corpo:
		_ultima_posicao = controle.corpo.global_position
	_aplicar_visao(1.0)


func _process(delta: float) -> void:
	if controle == null or controle.camera == null:
		return
	var mistura := clampf(delta * TRANSICAO, 0.0, 1.0)
	var alvo: Dictionary = RESPIRACOES[estado["respiracao"]]
	_ritmo = lerpf(_ritmo, alvo["ritmo"], mistura)
	_altura = lerpf(_altura, alvo["altura"], mistura)
	_fase_respiracao = fmod(_fase_respiracao + delta * _ritmo * TAU, TAU)

	# Passos: pelo quanto o corpo andou no chão, seja andando ou deslizando
	# até um ponto depois de um toque.
	var posicao := controle.corpo.global_position
	var andou := Vector2(posicao.x - _ultima_posicao.x, posicao.z - _ultima_posicao.z).length()
	_ultima_posicao = posicao
	var rapidez := andou / maxf(delta, 0.0001)
	if rapidez > 8.0:
		rapidez = 0.0 # teleporte (troca de ponto), não passo
	_forca_passo = lerpf(_forca_passo, clampf(rapidez / (controle.velocidade * 2.0), 0.0, 1.0), clampf(delta * 6.0, 0.0, 1.0))
	_fase_passo = fmod(_fase_passo + rapidez / PASSO * PI * delta, TAU)

	var camera := controle.camera
	camera.v_offset = sin(_fase_respiracao) * _altura - absf(sin(_fase_passo)) * BALANCO_PASSO * _forca_passo
	camera.h_offset = sin(_fase_passo) * BALANCO_PASSO * 0.5 * _forca_passo
	_aplicar_visao(mistura)


func _aplicar_visao(mistura: float) -> void:
	if vinheta == null or not (vinheta.material is ShaderMaterial):
		return
	var material := vinheta.material as ShaderMaterial
	for nome: String in ["vinheta", "desfoque"]:
		var atual: Variant = material.get_shader_parameter(nome)
		var de: float = estado[nome] if atual == null else atual
		material.set_shader_parameter(nome, lerpf(de, estado[nome], mistura))
