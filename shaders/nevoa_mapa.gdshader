shader_type canvas_item;
// Névoa sobre o que ainda não foi descoberto no mapa de Hélade.
// TEXTURE é a máscara (1 = névoa, 0 = descoberto) em baixa resolução; aqui ela
// vira nuvens que andam devagar, com borda pontilhada no jeito pixel art.

uniform vec2 tamanho_mapa = vec2(1664.0, 1280.0);
uniform vec4 cor_clara : source_color = vec4(0.79, 0.81, 0.85, 1.0);
uniform vec4 cor_escura : source_color = vec4(0.55, 0.60, 0.68, 1.0);
uniform float opacidade = 0.96;
// Tamanho do "pixel" da névoa, em pixels da arte.
uniform float bloco = 2.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float nuvens(vec2 p) {
	float soma = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		soma += ruido(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return soma;
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[y * 4 + x]) + 0.5) / 16.0;
}

void fragment() {
	vec2 pixel = floor(UV * tamanho_mapa / bloco);
	vec2 uv = (pixel * bloco + bloco * 0.5) / tamanho_mapa;
	float mascara = texture(TEXTURE, uv).r;
	vec2 deriva = vec2(TIME * 0.6, TIME * 0.25);
	float n = nuvens((pixel * bloco + deriva) / 90.0);
	// Borda irregular: as nuvens avançam e recuam um pouco sobre o descoberto.
	float densidade = clamp(mascara * 1.35 - 0.35 + (n - 0.5) * 0.7, 0.0, 1.0);
	float visivel = step(bayer4(pixel), densidade);
	float tom = floor(clamp(n * 1.6 - 0.3, 0.0, 1.0) * 3.0) / 3.0;
	COLOR = vec4(mix(cor_escura.rgb, cor_clara.rgb, tom), visivel * opacidade);
}
