# Gera os sons provisórios da fase "A estrada desabou" (estrada Atenas–Olympia,
# trecho 3), sintetizados: agarrar a peça, arrastar, o barril rolando, a peça
# caindo no buraco, a pedra rolando ladeira abaixo, a pedra quebrando e a
# carroça passando. Saem em assets/audio/sfx/estrada_oa/estrada_desabou/.
# Uso: python3 tools/audio/gerar_sons_estrada_desabou.py   (na raiz do projeto)
import os
import wave

import numpy as np

TAXA = 44100
PASTA = 'assets/audio/sfx/estrada_oa/estrada_desabou'
rng = np.random.default_rng(7)


def t(segundos):
    return np.arange(int(TAXA * segundos)) / TAXA


def ruido(segundos):
    return rng.uniform(-1, 1, int(TAXA * segundos))


def passa_baixa(sinal, forca):
    # média móvel simples: quanto maior a força, mais grave
    nucleo = np.ones(forca) / forca
    return np.convolve(sinal, nucleo, mode='same')


def envelope(n, ataque, queda):
    e = np.ones(n)
    a = max(int(TAXA * ataque), 1)
    e[:a] = np.linspace(0, 1, a)
    e *= np.exp(-np.arange(n) / (TAXA * queda))
    return e


def baque(segundos, grave, queda):
    tt = t(segundos)
    tom = np.sin(2 * np.pi * grave * tt * (1 - 0.3 * tt / segundos))
    s = 0.7 * tom + 0.5 * passa_baixa(ruido(segundos), 30)
    return s * envelope(len(tt), 0.003, queda)


def agarrar():
    return 0.6 * baque(0.18, 140, 0.04) + 0.3 * passa_baixa(ruido(0.18), 6) * envelope(int(TAXA * 0.18), 0.001, 0.02)


def arrastar():
    n = int(TAXA * 0.5)
    raspa = passa_baixa(ruido(0.5), 12)
    tremor = 0.6 + 0.4 * np.sin(2 * np.pi * 23 * t(0.5))
    e = np.minimum(1, np.linspace(0, 6, n)) * np.minimum(1, np.linspace(6, 0, n))
    return 0.8 * raspa * tremor * e


def rolar():
    d = 0.9
    n = int(TAXA * d)
    tt = t(d)
    batidas = (np.sin(2 * np.pi * 9 * tt) > 0.85).astype(float)
    corpo = passa_baixa(ruido(d), 40) * 2.5 + 0.3 * np.sin(2 * np.pi * 70 * tt)
    e = np.minimum(1, np.linspace(0, 8, n)) * np.linspace(1, 0.2, n)
    return (0.6 * corpo + 0.4 * passa_baixa(batidas * ruido(d), 8)) * e


def encaixe():
    s = baque(0.6, 60, 0.18)
    terra = passa_baixa(ruido(0.6), 4) * envelope(int(TAXA * 0.6), 0.01, 0.12) * 0.4
    return s + terra


def pedra_rolando():
    d = 1.4
    n = int(TAXA * d)
    tt = t(d)
    ronco = passa_baixa(ruido(d), 80) * 4
    quiques = np.zeros(n)
    for inicio in np.arange(0.05, d, 0.17):
        i = int(inicio * TAXA)
        b = baque(0.12, 90 + 40 * rng.random(), 0.03)
        quiques[i:i + len(b)] += b[: n - i]
    e = np.minimum(1, np.linspace(0, 3, n)) * np.minimum(1, np.linspace(5, 0, n))
    return (0.6 * ronco + 0.5 * quiques) * e + 0 * tt


def pedra_quebra():
    s = baque(0.5, 110, 0.08)
    estalo = ruido(0.5) * envelope(int(TAXA * 0.5), 0.0005, 0.05)
    cascalho = np.zeros(int(TAXA * 0.5))
    for _ in range(14):
        i = rng.integers(int(TAXA * 0.03), int(TAXA * 0.4))
        g = passa_baixa(ruido(0.04), 3) * envelope(int(TAXA * 0.04), 0.0005, 0.01) * 0.5
        cascalho[i:i + len(g)] += g[: len(cascalho) - i]
    return 0.7 * s + 0.5 * estalo + cascalho


def carroca():
    d = 3.0
    n = int(TAXA * d)
    tt = t(d)
    rodas = passa_baixa(ruido(d), 50) * 3 * (0.7 + 0.3 * np.sin(2 * np.pi * 3 * tt))
    rangido = 0.15 * np.sin(2 * np.pi * (420 + 60 * np.sin(2 * np.pi * 0.8 * tt)) * tt) * (np.sin(2 * np.pi * 0.8 * tt) > 0.6)
    cascos = np.zeros(n)
    for inicio in np.arange(0.0, d, 0.36):
        for atraso in (0.0, 0.09):
            i = int((inicio + atraso) * TAXA)
            b = baque(0.08, 180, 0.015)
            cascos[i:i + len(b)] += b[: n - i] * 0.6
    e = np.minimum(1, np.linspace(0, 4, n)) * np.minimum(1, np.linspace(4, 0, n))
    return (0.5 * rodas + rangido + cascos) * e


def salvar(nome, sinal):
    sinal = sinal / max(np.max(np.abs(sinal)), 1e-6) * 0.8
    dados = (sinal * 32767).astype(np.int16)
    with wave.open(os.path.join(PASTA, nome + '.wav'), 'wb') as arquivo:
        arquivo.setnchannels(1)
        arquivo.setsampwidth(2)
        arquivo.setframerate(TAXA)
        arquivo.writeframes(dados.tobytes())


def main():
    os.makedirs(PASTA, exist_ok=True)
    for nome, gerar in [('agarrar', agarrar), ('arrastar', arrastar), ('rolar', rolar),
                        ('encaixe', encaixe), ('pedra_rolando', pedra_rolando),
                        ('pedra_quebra', pedra_quebra), ('carroca', carroca)]:
        salvar(nome, gerar())


if __name__ == '__main__':
    main()
