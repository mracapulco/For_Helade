class_name ChamaTremula
extends OmniLight3D
## Luz de vela ou tocha que tremula como chama de verdade.
## Para mudar a força da luz por código, use `brilho` (não `light_energy`,
## que é recalculado a cada quadro).

## Quanto a luz varia em volta do brilho (0,3 = até 30% para cima ou para baixo).
@export var tremor := 0.3
## Quanto maior, mais nervosa a chama.
@export var rapidez := 6.0

var brilho: float

var _ruido := FastNoiseLite.new()
var _tempo := 0.0


func _ready() -> void:
	brilho = light_energy
	_ruido.seed = randi()
	_ruido.frequency = 1.0
	_tempo = randf() * 100.0


func _process(delta: float) -> void:
	_tempo += delta * rapidez
	light_energy = brilho * (1.0 + tremor * clampf(2.0 * _ruido.get_noise_1d(_tempo), -1.0, 1.0))
