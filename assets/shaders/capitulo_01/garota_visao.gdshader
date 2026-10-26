shader_type spatial;
render_mode cull_disabled;
// A garota da visão da varanda (Capítulo 01): o material das malhas dela
// (tools/arte/gerar_garota_visao.py) com pequenos movimentos de quem está
// parada olhando a noite (Rafael, 26/10/2026): a cabeça vira e inclina devagar,
// o peito respira, e as mãos deslizam um pouco pelo corrimão.
// A garota tem os pés na origem, de frente para +z, a cabeça acima de y 1,45 e
// as mãos no corrimão em z 0,43 (metros).

uniform vec3 albedo : source_color = vec3(0.5);
uniform float rugosidade = 0.8;
uniform float especular = 0.5;
uniform float borda = 0.0;
uniform float tom_borda = 0.5;
// 0 desliga os movimentos.
uniform float movimento = 1.0;

vec3 girar_y(vec3 p, float a) {
	return vec3(p.x * cos(a) + p.z * sin(a), p.y, -p.x * sin(a) + p.z * cos(a));
}

vec3 girar_z(vec3 p, float a) {
	return vec3(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a), p.z);
}

void vertex() {
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	float t = TIME * movimento;

	// Respiração: o peito (entre a cintura e o pescoço) abre e fecha de leve.
	float peito = smoothstep(1.0, 1.2, v.y) * (1.0 - smoothstep(1.4, 1.46, v.y));
	float ar = 0.007 * sin(t * 1.25) * movimento;
	v.xz *= 1.0 + ar * peito;

	// Mãos no corrimão: deslizam um pouco, cada uma no seu tempo (só os
	// braços: na frente do corpo, entre o corrimão e os ombros).
	float braco = smoothstep(0.12, 0.40, v.z) * smoothstep(0.93, 0.97, v.y) * (1.0 - smoothstep(1.3, 1.38, v.y));
	float lado = v.x >= 0.0 ? 1.0 : -1.0;
	float fase = lado > 0.0 ? 0.0 : 2.1;
	float desliza = (lado > 0.0 ? 0.05 : 0.025) * sin(t * 0.21 + fase);
	float ergue = 0.012 * max(0.0, sin(t * 0.37 + fase * 1.7));
	v.x += desliza * braco * movimento;
	v.y += ergue * braco * movimento;

	// Cabeça: vira para os lados e inclina, a partir do pescoço.
	float cabeca = smoothstep(1.43, 1.53, v.y);
	float giro = (0.2 * sin(t * 0.29) + 0.08 * sin(t * 0.13 + 1.0)) * movimento;
	float inclina = (0.07 * sin(t * 0.23 + 0.5)) * movimento;
	vec3 pescoco = vec3(0.0, 1.45, 0.0);
	vec3 r = girar_z(girar_y(v - pescoco, giro * cabeca), inclina * cabeca);
	v = pescoco + r;
	n = normalize(girar_z(girar_y(n, giro * cabeca), inclina * cabeca));

	VERTEX = v;
	NORMAL = n;
}

void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = rugosidade;
	SPECULAR = especular;
	RIM = borda;
	RIM_TINT = tom_borda;
}
