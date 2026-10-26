# Gera os sons provisórios da fase "Árvores e mais árvores" (oa_estrada_2):
# - melodia_floresta.wav: a melodia distante que guia (lira dedilhada, em loop);
# - melodia_eco.wav: a mesma melodia como eco (abafada, atrasada, mais fraca);
# - vento_floresta.wav: vento nas copas, ambiente em loop;
# - sopro_floresta.wav: rajada curta ao trocar de clareira;
# - emboscada.wav: tambores e bordão graves da luta com os bandidos (loop).
# Tudo sintetizado, mono, 16 bits, 22050 Hz, semente fixa (rodar de novo gera
# os mesmos arquivos). São marcadores até virem os sons de verdade.
# A melodia é inferência (não está no livro); lira por causa de Apolo.
# Uso: python3 tools/audio/gerar_sons_floresta.py   (rodar na raiz do projeto)
import os
import sys
import wave

import numpy as np

sys.dont_write_bytecode = True

SR = 22050
PASTA = 'assets/audio/sfx/estrada_oa/floresta'
PASTA_MUSICA = 'assets/audio/music/estrada_oa'
rng = np.random.default_rng(2026)

# Ré dórico, cinco notas por compasso, 4 compassos (8 s a 120 bpm).
NOTAS = {
    'D4': 293.66, 'E4': 329.63, 'F4': 349.23, 'G4': 392.00, 'A4': 440.00,
    'B4': 493.88, 'C5': 523.25, 'D5': 587.33, 'E5': 659.25, 'A3': 220.00,
}
FRASE = [
    ('A4', 0.0), ('D5', 0.5), ('C5', 1.0), ('A4', 1.5), ('G4', 2.25),
    ('A4', 2.5), ('E4', 3.0),
    ('F4', 4.0), ('G4', 4.5), ('A4', 5.0), ('D5', 5.5), ('E5', 6.25),
    ('D5', 6.5), ('A4', 7.0),
]
DURACAO_MELODIA = 8.0


def salvar(caminho, sinal, pico=0.8):
    sinal = np.asarray(sinal, dtype=float)
    maximo = np.max(np.abs(sinal)) or 1.0
    dados = (sinal / maximo * pico * 32767).astype(np.int16)
    with wave.open(caminho, 'wb') as arq:
        arq.setnchannels(1)
        arq.setsampwidth(2)
        arq.setframerate(SR)
        arq.writeframes(dados.tobytes())


def corda(freq, dur, brilho=0.5):
    """Karplus-Strong: uma corda de lira dedilhada."""
    n = int(dur * SR)
    periodo = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, periodo)
    saida = np.zeros(n)
    for i in range(n):
        saida[i] = buf[i % periodo]
        prox = buf[(i + 1) % periodo]
        buf[i % periodo] = 0.996 * (brilho * buf[i % periodo] + (1 - brilho) * prox)
    return saida


def passa_baixa(x, corte):
    a = np.exp(-2 * np.pi * corte / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def em_loop(sinal, total):
    """Dobra a cauda que passa do fim por cima do começo (loop sem corte)."""
    n = int(total * SR)
    saida = np.zeros(n)
    for i in range(0, len(sinal), n):
        pedaco = sinal[i:i + n]
        saida[:len(pedaco)] += pedaco
    return saida


def melodia():
    sinal = np.zeros(int((DURACAO_MELODIA + 3) * SR))
    for nome, inicio in FRASE:
        nota = corda(NOTAS[nome], 2.5) * 0.8
        nota += corda(NOTAS[nome] / 2, 2.5, 0.4) * 0.25  # corpo mais grave
        i = int(inicio * SR)
        sinal[i:i + len(nota)] += nota
    # Bordão bem baixinho em lá, para soar distante e misterioso.
    t = np.arange(len(sinal)) / SR
    sinal += 0.05 * np.sin(2 * np.pi * NOTAS['A3'] * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.25 * t))
    return em_loop(sinal, DURACAO_MELODIA)


def eco(seco):
    """A mesma melodia vinda de longe: abafada, com repetições e atrasada."""
    abafado = passa_baixa(seco, 900)
    n = len(abafado)
    saida = np.zeros(n)
    for atraso, ganho in ((0.33, 0.7), (0.66, 0.45), (1.0, 0.28), (1.33, 0.16)):
        k = int(atraso * SR)
        saida += np.roll(abafado, k) * ganho
    return saida * 0.6


def vento(total=12.0):
    k = int(0.5 * SR)  # meio segundo de transição cruzada nas pontas
    n = int(total * SR)
    t = np.arange(n + k) / SR
    ruido = rng.normal(0, 1, n + k)
    grave = passa_baixa(ruido, 380)
    medio = passa_baixa(ruido, 1400) - passa_baixa(ruido, 500)
    # Rajadas lentas que fecham o ciclo em 12 s (2 e 3 ciclos).
    rajada = 0.55 + 0.3 * np.sin(2 * np.pi * t * 2 / total) + 0.15 * np.sin(2 * np.pi * t * 3 / total + 1.0)
    farfalhar = 0.5 + 0.5 * np.sin(2 * np.pi * t * 5 / total) ** 2
    sinal = grave * rajada + medio * 0.6 * rajada * farfalhar
    # O que passa do fim entra por baixo do começo, sumindo aos poucos.
    sinal[:k] = sinal[:k] * np.linspace(0, 1, k) + sinal[n:] * np.linspace(1, 0, k)
    return sinal[:n]


def sopro():
    dur = 1.1
    n = int(dur * SR)
    t = np.arange(n) / SR
    ruido = rng.normal(0, 1, n)
    envelope = np.sin(np.pi * t / dur) ** 2
    claro = passa_baixa(ruido, 2400) - passa_baixa(ruido, 300)
    return claro * envelope


def tambor(freq, dur=0.5):
    n = int(dur * SR)
    t = np.arange(n) / SR
    altura = freq * (1 + 1.5 * np.exp(-t * 30))
    fase = 2 * np.pi * np.cumsum(altura) / SR
    corpo = np.sin(fase) * np.exp(-t * 9)
    batida = rng.normal(0, 1, n) * np.exp(-t * 60) * 0.4
    return corpo + batida


def emboscada():
    total = 8.0  # 4 compassos a 120 bpm
    sinal = np.zeros(int((total + 1) * SR))
    batidas = [0, 0.75, 1.0, 1.5, 2.0, 2.75, 3.0, 3.25, 3.5]
    for compasso in range(4):
        for b in batidas:
            inicio = compasso * 2.0 + b * 0.5
            som = tambor(70 if b in (0, 2.0) else 95)
            i = int(inicio * SR)
            sinal[i:i + len(som)] += som * (1.0 if b in (0, 2.0) else 0.6)
    t = np.arange(len(sinal)) / SR
    bordao = np.sin(2 * np.pi * 73.4 * t) + 0.5 * np.sin(2 * np.pi * 110 * t)
    sinal += 0.18 * bordao * (0.7 + 0.3 * np.sin(2 * np.pi * t / 2))
    return em_loop(sinal, total)


def main():
    os.makedirs(PASTA, exist_ok=True)
    os.makedirs(PASTA_MUSICA, exist_ok=True)
    seca = melodia()
    salvar(os.path.join(PASTA, 'melodia_floresta.wav'), seca)
    salvar(os.path.join(PASTA, 'melodia_eco.wav'), eco(seca), pico=0.55)
    salvar(os.path.join(PASTA, 'vento_floresta.wav'), vento(), pico=0.6)
    salvar(os.path.join(PASTA, 'sopro_floresta.wav'), sopro(), pico=0.7)
    salvar(os.path.join(PASTA_MUSICA, 'emboscada.wav'), emboscada(), pico=0.75)


if __name__ == '__main__':
    main()
