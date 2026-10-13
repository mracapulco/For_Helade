shader_type sky;
// Céu noturno do prólogo: degradê azul-escuro, estrelas e o halo da lua.

uniform vec3 cor_alto : source_color = vec3(0.006, 0.01, 0.03);
uniform vec3 cor_horizonte : source_color = vec3(0.035, 0.05, 0.1);
// Quanto maior, mais estrelas (0 a 1).
uniform float quantidade_estrelas : hint_range(0.0, 1.0) = 0.35;
uniform float brilho_estrelas = 2.5;
// Direção até a lua (a mesma da luz "Lua" da cena).
uniform vec3 direcao_lua = vec3(0.149, 0.419, 0.896);
uniform vec3 cor_lua : source_color = vec3(0.75, 0.82, 1.0);

float acaso(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float alto = clamp(d.y, 0.0, 1.0);
	vec3 cor = mix(cor_horizonte, cor_alto, sqrt(alto));

	// Estrelas: uma por célula sorteada, pequenas e de brilho variado.
	vec3 grade = d * 260.0;
	vec3 celula = floor(grade);
	float sorte = acaso(celula);
	float limite = 1.0 - 0.012 * quantidade_estrelas;
	if (sorte > limite) {
		vec3 centro = celula + 0.5 + 0.3 * (vec3(acaso(celula + 1.7), acaso(celula + 3.1), acaso(celula + 5.3)) - 0.5);
		float perto = 1.0 - smoothstep(0.0, 0.45, length(grade - centro));
		float forca = (sorte - limite) / (1.0 - limite);
		cor += vec3(0.9, 0.93, 1.0) * perto * forca * brilho_estrelas * smoothstep(0.0, 0.15, d.y);
	}

	// Halo em volta da lua.
	float alinhado = max(dot(d, normalize(direcao_lua)), 0.0);
	cor += cor_lua * (pow(alinhado, 400.0) * 0.6 + pow(alinhado, 24.0) * 0.06);

	COLOR = cor;
}
