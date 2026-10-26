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
// Tamanho da lua no céu, em graus (a lua de verdade tem uns 0,5).
uniform float raio_lua_graus = 2.0;
uniform float brilho_lua = 3.0;
// Estrelas cadentes (0 = nenhuma): cada uma cruza o céu de tempos em tempos,
// num lugar diferente a cada vez, perto de centro_cadentes.
uniform int cadentes = 0;
uniform vec3 centro_cadentes = vec3(0.0, 0.3, 1.0);

float acaso(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// Brilho das estrelas cadentes na direção d.
float cadente(vec3 d) {
	vec3 frente = normalize(centro_cadentes);
	float de_frente = dot(d, frente);
	if (cadentes <= 0 || de_frente <= 0.2) {
		return 0.0;
	}
	vec3 direita = normalize(cross(vec3(0.0, 1.0, 0.0), frente));
	vec3 cima = cross(frente, direita);
	// Ponto do céu num plano diante de quem olha.
	vec2 q = vec2(dot(d, direita), dot(d, cima)) / de_frente;
	float luz = 0.0;
	for (int i = 0; i < cadentes; i++) {
		float periodo = 9.0 + 5.0 * float(i);
		float tempo = TIME + 3.0 + 4.3 * float(i);
		float volta = floor(tempo / periodo);
		float t = mod(tempo, periodo);
		float dura = 0.9;
		if (t > dura) {
			continue;
		}
		vec3 semente = vec3(volta, float(i), 7.0);
		vec2 inicio = vec2(-0.6 + 1.2 * acaso(semente), 0.14 + 0.16 * acaso(semente + 2.3));
		float para_onde = acaso(semente + 4.1) > 0.5 ? 1.0 : -1.0;
		vec2 rumo = normalize(vec2(para_onde, -0.45));
		vec2 cabeca = inicio + rumo * 0.3 * (t / dura);
		vec2 cauda = cabeca - rumo * 0.12;
		// Distância ao risco entre a cauda e a cabeça.
		vec2 ab = cabeca - cauda;
		float k = clamp(dot(q - cauda, ab) / dot(ab, ab), 0.0, 1.0);
		float dist = length(q - (cauda + ab * k));
		float acende = smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(dura - 0.3, dura, t));
		luz += (1.0 - smoothstep(0.0, 0.0025, dist)) * k * k * acende;
	}
	return luz;
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

	cor += vec3(0.95, 0.96, 1.0) * cadente(d) * 2.5;

	// A lua e o halo saem da mesma direção, então ficam sempre juntos.
	float alinhado = max(dot(d, normalize(direcao_lua)), 0.0);
	cor += cor_lua * (pow(alinhado, 400.0) * 0.6 + pow(alinhado, 24.0) * 0.06);
	float angulo = degrees(acos(clamp(alinhado, -1.0, 1.0)));
	float disco = 1.0 - smoothstep(raio_lua_graus - 0.08, raio_lua_graus, angulo);
	// Manchas suaves na superfície.
	float manchas = 0.85 + 0.15 * sin(d.x * 160.0) * sin(d.y * 140.0 + 1.3) * sin(d.z * 150.0);
	cor = mix(cor, vec3(0.92, 0.94, 1.0) * brilho_lua * manchas, disco);

	COLOR = cor;
}
