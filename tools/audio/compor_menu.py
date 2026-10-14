"""Compõe a música provisória do menu (original, sem direitos de terceiros).

Ré menor, 72 BPM, harpa em arpejos, fundo suave e uma melodia de flauta na
segunda metade. Gera um laço contínuo: o fim emenda no começo.

Uso: python3 tools/audio/compor_menu.py saida.wav
"""
import sys
import wave

import numpy as np

TAXA = 44100
BPM = 72
COLCHEIA = 60 / BPM / 2
COMPASSO = COLCHEIA * 8  # 4/4
rng = np.random.default_rng(7)


def nota(nome: str) -> float:
    semitons = {"C": 0, "C#": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "A": 9, "Bb": 10, "B": 11}
    altura, oitava = nome[:-1], int(nome[-1])
    return 440.0 * 2 ** ((semitons[altura] + 12 * (oitava - 4) - 9) / 12)


def harpa(freq: float, dur: float) -> np.ndarray:
    """Corda dedilhada (Karplus-Strong)."""
    n = int(dur * TAXA)
    periodo = max(2, int(TAXA / freq))
    buf = rng.uniform(-1, 1, periodo)
    saida = np.empty(n)
    for i in range(n):
        saida[i] = buf[i % periodo]
        buf[i % periodo] = 0.4985 * (buf[i % periodo] + buf[(i + 1) % periodo])
    return saida * np.exp(-np.linspace(0, 3.0, n))


def fundo(freqs: list[float], dur: float) -> np.ndarray:
    t = np.arange(int(dur * TAXA)) / TAXA
    som = sum(np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * t + 0.5) for f in freqs)
    env = np.minimum(1, t / 1.5) * np.minimum(1, (dur - t) / 1.5)
    return som * env / len(freqs)


def flauta(freq: float, dur: float) -> np.ndarray:
    t = np.arange(int(dur * TAXA)) / TAXA
    vibrato = 1 + 0.004 * np.sin(2 * np.pi * 5 * t) * np.minimum(1, t / 0.6)
    fase = 2 * np.pi * freq * np.cumsum(vibrato) / TAXA
    som = np.sin(fase) + 0.15 * np.sin(2 * fase) + 0.02 * rng.normal(size=t.size)
    env = np.minimum(1, t / 0.12) * np.minimum(1, (dur - t) / 0.3)
    return som * np.clip(env, 0, 1)


def misturar(trilha: np.ndarray, som: np.ndarray, inicio: float, volume: float) -> None:
    i = int(inicio * TAXA)
    fim = min(trilha.size, i + som.size)
    trilha[i:fim] += som[: fim - i] * volume


# i - VI - III - VII, dois compassos cada, duas voltas.
ACORDES = [
    (["D3", "A3", "D4", "F4", "A4", "F4", "D4", "A3"], ["D2", "A2", "F3"]),
    (["Bb2", "F3", "Bb3", "D4", "F4", "D4", "Bb3", "F3"], ["Bb1", "F2", "D3"]),
    (["F3", "C4", "F4", "A4", "C5", "A4", "F4", "C4"], ["F2", "C3", "A3"]),
    (["C3", "G3", "C4", "E4", "G4", "E4", "C4", "G3"], ["C2", "G2", "E3"]),
]
MELODIA = [  # (nota, colcheias) na segunda volta
    ("A4", 6), ("F4", 2), ("D5", 8),
    ("D5", 4), ("C5", 2), ("Bb4", 2), ("A4", 8),
    ("C5", 6), ("A4", 2), ("F4", 8),
    ("G4", 4), ("A4", 2), ("E4", 2), ("D4", 8),
    ("A4", 6), ("F4", 2), ("D5", 8),
    ("F5", 4), ("E5", 2), ("D5", 2), ("Bb4", 8),
    ("A4", 4), ("C5", 4), ("F5", 8),
    ("E5", 4), ("C5", 2), ("G4", 2), ("A4", 8),
]

voltas = 2
duracao = len(ACORDES) * 2 * COMPASSO * voltas
cauda = 4.0
trilha = np.zeros(int((duracao + cauda) * TAXA))

t = 0.0
for _ in range(voltas):
    for arpejo, base in ACORDES:
        misturar(trilha, fundo([nota(n) for n in base], 2 * COMPASSO + 1.0), t, 0.16)
        for c in range(2):
            for i, n in enumerate(arpejo):
                misturar(trilha, harpa(nota(n), 2.5), t + c * COMPASSO + i * COLCHEIA, 0.33 if i else 0.42)
        t += 2 * COMPASSO

t = len(ACORDES) * 2 * COMPASSO  # melodia na segunda volta
for n, colcheias in MELODIA:
    misturar(trilha, flauta(nota(n), colcheias * COLCHEIA * 0.95), t, 0.11)
    t += colcheias * COLCHEIA

# Reverberação simples (ecos amortecidos), em estéreo levemente diferente.
def reverb(x: np.ndarray, atrasos: list[float]) -> np.ndarray:
    saida = x.copy()
    for atraso, ganho in atrasos:
        d = int(atraso * TAXA)
        eco = np.zeros_like(x)
        eco[d:] = x[:-d] * ganho
        for _ in range(3):
            eco[d:] += eco[:-d] * ganho * 0.5
        saida += eco
    return saida

esq = reverb(trilha, [(0.083, 0.28), (0.217, 0.2), (0.391, 0.14)])
dir_ = reverb(trilha, [(0.097, 0.28), (0.239, 0.2), (0.43, 0.14)])

# Laço: a cauda do fim volta para o começo.
n = int(duracao * TAXA)
estereo = np.stack([esq, dir_], axis=1)
laco = estereo[:n].copy()
laco[: estereo.shape[0] - n] += estereo[n:]
laco *= 0.8 / np.max(np.abs(laco))

with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(TAXA)
    w.writeframes((laco * 32767).astype("<i2").tobytes())
print(f"{duracao:.1f} s")
