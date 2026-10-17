shader_type spatial;
// Chama de vela, tocha ou lareira: um quadrado que sempre fica de frente
// para a câmera (girando só em volta do eixo vertical) e desenha uma gota de
// fogo que dança. Use num QuadMesh com a base da chama embaixo.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 cor_miolo : source_color = vec3(1.0, 0.92, 0.7);
uniform vec3 cor_borda : source_color = vec3(1.0, 0.45, 0.1);
uniform float intensidade = 3.0;
uniform float rapidez = 1.0;

varying float semente;

void vertex() {
	vec3 cima = vec3(0.0, 1.0, 0.0);
	vec3 frente = normalize(INV_VIEW_MATRIX[2].xyz * vec3(1.0, 0.0, 1.0) + vec3(0.0001));
	vec3 lado = normalize(cross(cima, frente));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(lado, 0.0), vec4(cima, 0.0), vec4(frente, 0.0), MODEL_MATRIX[3]);
	semente = fract(sin(dot(MODEL_MATRIX[3].xyz, vec3(12.9898, 78.233, 37.719))) * 43758.5453) * 100.0;
}

void fragment() {
	float t = TIME * rapidez * 7.0 + semente;
	vec2 p = vec2(UV.x - 0.5, 1.0 - UV.y); // p.y: 0 na base, 1 no topo
	// A chama balança mais em cima do que embaixo.
	p.x += p.y * p.y * 0.12 * (sin(t * 1.3) + 0.5 * sin(t * 3.1 + 1.0));
	float altura = 0.85 + 0.12 * sin(t * 2.3) + 0.05 * sin(t * 5.7);
	float y = p.y / altura;
	float largura = 0.32 * pow(clamp(1.0 - y, 0.0, 1.0), 0.8) * smoothstep(0.0, 0.18, y);
	float d = abs(p.x) / max(largura, 0.0001);
	float forma = (1.0 - smoothstep(0.55, 1.0, d)) * step(y, 1.0);
	float miolo = (1.0 - smoothstep(0.0, 0.6, d)) * (1.0 - smoothstep(0.1, 0.55, y));
	vec3 cor = mix(cor_borda, cor_miolo, miolo);
	ALBEDO = cor * forma * intensidade;
}
