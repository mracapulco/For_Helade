shader_type canvas_item;
// O ar do sonho treme de leve, como o calor sobre uma estrada (Capítulo 01).

uniform sampler2D tela : hint_screen_texture, filter_nearest;
// Quanto a imagem ondula, em fração da tela.
uniform float forca = 0.002;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 38.0 + TIME * 1.7) * forca;
	uv.y += cos(uv.x * 26.0 + TIME * 1.2) * forca * 0.6;
	COLOR = texture(tela, uv);
}
