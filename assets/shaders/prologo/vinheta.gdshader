shader_type canvas_item;
// Visão de Nicholas: bordas escuras, desfoque nas bordas nos momentos de
// choque e uma granulação leve de filme. Fica por cima da cena 3D.

uniform sampler2D tela : hint_screen_texture, filter_linear;
uniform float vinheta : hint_range(0.0, 1.0) = 0.35;
uniform float desfoque : hint_range(0.0, 1.0) = 0.0;
uniform float granulacao : hint_range(0.0, 0.2) = 0.03;

void fragment() {
	vec2 uv = SCREEN_UV;
	float proporcao = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float distancia = length((uv - 0.5) * vec2(proporcao, 1.0));
	vec3 cor = texture(tela, uv).rgb;

	float raio = desfoque * smoothstep(0.1, 0.7, distancia) * 0.014;
	if (raio > 0.0002) {
		vec3 soma = cor;
		for (int i = 0; i < 12; i++) {
			float angulo = float(i) * 2.39996;
			float r = raio * sqrt(float(i + 1) / 12.0);
			soma += texture(tela, uv + vec2(cos(angulo) / proporcao, sin(angulo)) * r).rgb;
		}
		cor = soma / 13.0;
	}

	cor *= 1.0 - vinheta * smoothstep(0.25, 0.95, distancia);
	float acaso = fract(sin(dot(uv * 437.0 + fract(TIME * 7.13), vec2(12.9898, 78.233))) * 43758.5453);
	cor += (acaso - 0.5) * granulacao;
	COLOR = vec4(cor, 1.0);
}
