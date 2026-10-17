shader_type spatial;
// Mar visto da varanda, à noite: ondas que se mexem e o reflexo da lua.

uniform vec3 cor_fundo : source_color = vec3(0.005, 0.02, 0.045);
uniform vec3 cor_reflexo : source_color = vec3(0.05, 0.08, 0.14);
uniform float altura_ondas = 0.45;
uniform float velocidade = 0.5;

varying vec3 mundo;

// Soma de ondas: devolve a altura (x) e a inclinação (yz).
vec3 ondas(vec2 p, float t, bool detalhe) {
	vec3 soma = vec3(0.0);
	// direção x, direção y, comprimento (m), altura
	vec4 lista[8] = {
		vec4(0.0, 1.0, 38.0, 0.9), vec4(0.6, 0.8, 23.0, 0.55),
		vec4(-0.5, 0.86, 15.0, 0.35), vec4(0.95, 0.3, 9.0, 0.2),
		vec4(-0.8, 0.6, 4.1, 0.06), vec4(0.3, 0.95, 2.7, 0.04),
		vec4(0.9, -0.4, 1.6, 0.025), vec4(-0.2, 0.98, 1.1, 0.018)
	};
	int quantas = detalhe ? 8 : 4;
	for (int i = 0; i < quantas; i++) {
		vec2 dir = normalize(lista[i].xy);
		float k = 6.2831853 / lista[i].z;
		float fase = dot(p, dir) * k - t * sqrt(9.8 * k);
		soma.x += lista[i].w * sin(fase);
		soma.yz += lista[i].w * k * cos(fase) * dir;
	}
	return soma * altura_ondas;
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 o = ondas(mundo.xz, TIME * velocidade, false);
	VERTEX.y += o.x;
	mundo.y += o.x;
}

void fragment() {
	vec3 o = ondas(mundo.xz, TIME * velocidade, true);
	vec3 normal_mundo = normalize(vec3(-o.y, 1.0, -o.z));
	NORMAL = normalize((VIEW_MATRIX * vec4(normal_mundo, 0.0)).xyz);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 5.0);
	ALBEDO = cor_fundo;
	EMISSION = cor_reflexo * fresnel;
	METALLIC = 0.0;
	SPECULAR = 0.9;
	ROUGHNESS = 0.06;
}
