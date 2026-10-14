class_name VidaAcampamento
extends Node2D
## O que se mexe no ar do acampamento, conforme o [BiomaAcampamento]:
## - Neve caindo nos acampamentos frios ([member BiomaAcampamento.neve]).
## - Na mata ([member BiomaAcampamento.fauna_da_mata]): insetos e pássaros de
##   dia, vaga-lumes à noite.
## Fica preso à câmera (as partículas ficam no mundo), para cobrir sempre a tela.

const PASTA := "res://assets/art/placeholders/acampamento/"
## Metade da área coberta, em pixels do mundo (a tela com zoom 2 tem 640×360).
const ALCANCE := Vector2(380, 230)

var neve: CPUParticles2D
var insetos: CPUParticles2D
var passaros: CPUParticles2D
var vagalumes: CPUParticles2D


func preparar(bioma: BiomaAcampamento) -> void:
	if bioma.neve > 0.0:
		neve = _neve(bioma.neve)
	if bioma.fauna_da_mata:
		insetos = _insetos()
		passaros = _passaros()
		vagalumes = _vagalumes()


func aplicar_periodo(noite: bool) -> void:
	if insetos:
		insetos.emitting = not noite
		insetos.visible = not noite
	if passaros:
		passaros.emitting = not noite
		passaros.visible = not noite
	if vagalumes:
		vagalumes.emitting = noite
		vagalumes.visible = noite


func _particulas(nome: String, textura: String, quantidade: int, vida: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = nome
	p.texture = load(PASTA + textura)
	p.amount = quantidade
	p.lifetime = vida
	p.preprocess = vida
	p.local_coords = false
	p.z_index = 5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = ALCANCE
	add_child(p)
	return p


func _neve(quanto: float) -> CPUParticles2D:
	var p := _particulas("Neve", "floco_neve.png", int(lerpf(30, 160, quanto)), 9.0)
	p.direction = Vector2(0.25, 1)
	p.spread = 12.0
	p.gravity = Vector2(0, 6)
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 28.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.color_ramp = _rampa(Color(1, 1, 1, 0.9))
	return p


func _insetos() -> CPUParticles2D:
	var p := _particulas("Insetos", "inseto.png", 14, 4.0)
	p.emission_rect_extents = Vector2(220, 120)
	p.position = Vector2(0, 30)
	p.direction = Vector2(1, 0)
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 16.0
	p.orbit_velocity_min = -0.2
	p.orbit_velocity_max = 0.2
	p.color_ramp = _rampa(Color(1, 1, 1, 1))
	_animar(p, 2, 8.0)
	return p


func _passaros() -> CPUParticles2D:
	var p := _particulas("Passaros", "passaro.png", 4, 16.0)
	# Saem da esquerda, no alto, e cruzam a tela.
	p.emission_rect_extents = Vector2(10, 70)
	p.position = Vector2(-ALCANCE.x - 40, -ALCANCE.y + 70)
	p.direction = Vector2(1, -0.08)
	p.spread = 8.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 45.0
	p.initial_velocity_max = 65.0
	p.z_index = 10
	_animar(p, 2, 6.0)
	return p


func _vagalumes() -> CPUParticles2D:
	var p := _particulas("Vagalumes", "vagalume.png", 26, 5.0)
	p.emission_rect_extents = Vector2(260, 150)
	p.position = Vector2(0, 20)
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 10.0
	p.orbit_velocity_min = -0.05
	p.orbit_velocity_max = 0.05
	p.color_ramp = _rampa(Color(1, 1, 1, 1), true)
	# Mais claro que 1 para continuar brilhando com o escuro da noite por cima.
	p.modulate = Color(2.4, 2.4, 1.6)
	return p


## Aparece e some aos poucos; [param piscar] acende e apaga no meio.
func _rampa(cor: Color, piscar := false) -> Gradient:
	var g := Gradient.new()
	var transparente := Color(cor, 0.0)
	if piscar:
		g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.55, 0.8, 1.0])
		g.colors = PackedColorArray([transparente, cor, Color(cor, 0.25), cor, cor, transparente])
	else:
		g.offsets = PackedFloat32Array([0.0, 0.1, 0.85, 1.0])
		g.colors = PackedColorArray([transparente, cor, cor, transparente])
	return g


## Troca os quadros da faixa (asas para cima e para baixo), [param velocidade]
## quadros por segundo.
func _animar(p: CPUParticles2D, quadros: int, velocidade: float) -> void:
	var material := CanvasItemMaterial.new()
	material.particles_animation = true
	material.particles_anim_h_frames = quadros
	material.particles_anim_v_frames = 1
	material.particles_anim_loop = true
	p.material = material
	# anim_speed = quantas vezes a faixa toda passa durante a vida da partícula.
	p.anim_speed_min = velocidade * p.lifetime / quadros
	p.anim_speed_max = p.anim_speed_min
