# Gera as músicas provisórias do mapa de Hélade, as duas sobre o tema principal
# (tools/audio/tema_principal.py):
#   mapa_dia.wav   - viagem/aventura, 100 bpm: flauta e cordas sobre harpa e tambor de moldura,
#                    forma intro + A + A' + B (desenvolvimento) + A.
#   mapa_noite.wav - noturno/canção de ninar, 66 bpm: flauta grave, depois celesta, com harpa
#                    e colchão quente, bem esparso.
# Mesmos blocos de síntese das músicas dos acampamentos; mono, 16 bits, 22050 Hz, ~-6 dBFS,
# loop sem costura (caudas e reverb voltam para o começo). Semente fixa.
# Uso: python3 tools/audio/gerar_musicas_mapa.py   (rodar na raiz do projeto)
import os
import sys

import numpy as np

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import tema_principal as tema                                    # noqa: E402
from gerar_musicas_acampamento import (SR, CAIXINHA, Loop, bordas, filtro_fft, flauta,  # noqa: E402
                                       hz, normal, pad, pincado, resposta_reverb, salvar,
                                       sino, tambor, tempo)

PASTA = 'assets/audio/music/mapa'
T = tema.TONICA


def cordas(f, dur, rng):
    """Naipe de cordas com arco: três vozes de dente de serra suave, vibrato, ataque lento."""
    t = tempo(dur)
    x = np.zeros_like(t)
    for d in (-5, 0, 6):
        vib = 1 + 0.003 * np.sin(2 * np.pi * rng.uniform(4.8, 5.8) * t + rng.uniform(0, 6))
        fase = 2 * np.pi * np.cumsum(f * 2 ** (d / 1200) * vib) / SR
        for k in range(1, 20):
            if k * f > 4500:
                break
            x += np.sin(k * fase) / k * np.exp(-k * f / 2200)
    arco = filtro_fft(rng.standard_normal(len(t)), lambda fr: np.exp(-((fr - 2.5 * f) / (2 * f)) ** 2))
    x = normal(x) + 0.02 * normal(arco)
    return bordas(x, min(0.22, dur / 3), min(0.35, dur / 2))


def celesta(f, dur, rng):
    return sino(f, max(dur, 2.5), CAIXINHA, rng)


def arpejo_harpa(lp, acordes, compasso0, passo, gain, rng, base=T - 24, brilho=0.45, padrao=None):
    """Harpa em arpejo sobre cada acorde (compasso, batida, dur, raiz, tipo)."""
    for (c, b, d, r, tp) in acordes:
        n0 = tema.notas_acorde(r, tp, base)
        voz = [n0[0], n0[2], n0[0] + 12, n0[1] + 12, n0[2] + 12, n0[0] + 24]
        ordem = padrao or [0, 1, 2, 3, 4, 3, 2, 1]
        k = 0
        x = 0.0
        while x < d - 1e-6:
            m = voz[ordem[k % len(ordem)]]
            v = gain * (1.25 if k == 0 else 1.0) * rng.uniform(0.85, 1.0)
            lp.por(pincado(hz(m), 3.0, brilho, 1.5, 0.3, rng=rng), lp.t(compasso0 + c, b + x, 0.006), v)
            x += passo
            k += 1


def baixo(lp, acordes, compasso0, gain, rng, batidas=(0, 2)):
    for (c, b, d, r, tp) in acordes:
        m = tema.notas_acorde(r, tp, T - 26)[0]
        for bb in batidas:
            if bb < d:
                lp.por(pincado(hz(m), 3.5, 0.2, 2.0, 0.22, rng=rng), lp.t(compasso0 + c, b + bb), gain)


def tocar(lp, notas, compasso0, instr, gain, solto=0.01, extra=0.0):
    for (c, b, d, m) in notas:
        lp.por(instr(hz(m), d * lp.spb + extra), lp.t(compasso0 + c, b, solto),
               gain * lp.rng.uniform(0.88, 1.0))


# desenvolvimento (seção B do mapa de dia): o "chamado" do c1 passeia por outros acordes
B_ACORDES = [(0, 0, 4, T - 4, 'M'), (1, 0, 4, T - 2, 'M'), (2, 0, 4, T + 3, 'M'), (3, 0, 4, T, 'm'),
             (4, 0, 4, T - 4, 'M'), (5, 0, 4, T - 2, 'M'), (6, 0, 4, T + 7, 'M'), (7, 0, 4, T + 7, 'M')]
B_MELODIA = [(c, b, d, T + s) for (c, b, d, s) in [
    (0, 0, 1.5, 3), (0, 1.5, 0.5, 8), (0, 2, 1, 10), (0, 3, 1, 12),       # Bb: F Bb C D
    (1, 0, 1.5, 14), (1, 1.5, 0.5, 12), (1, 2, 1, 10), (1, 3, 1, 5),      # C:  E D C G
    (2, 0, 1.5, 7), (2, 1.5, 0.5, 10), (2, 2, 1, 12), (2, 3, 1, 15),      # F:  A C D F
    (3, 0, 2, 14), (3, 2, 2, 12),                                         # Dm: E D
    (4, 0, 1.5, 12), (4, 1.5, 0.5, 15), (4, 2, 1, 17), (4, 3, 1, 19),     # Bb: D F G A
    (5, 0, 1.5, 17), (5, 1.5, 0.5, 15), (5, 2, 1, 14), (5, 3, 1, 10),     # C:  G F E C
    (6, 0, 2, 11), (6, 2, 2, 14),                                         # A:  C# E
    (7, 0, 3, 7),                                                         # A:  A
]]


def mapa_dia(rng):
    lp = Loop(100, 4, 34, rng)
    intro = [(0, 0, 4, T, 'm'), (1, 0, 4, T, 'm')]
    secoes = [(0, intro, None), (2, tema.acordes(), 'A1'), (10, tema.acordes(), 'A2'),
              (18, B_ACORDES, 'B'), (26, tema.acordes(), 'A3')]
    for (c0, acs, nome) in secoes:
        arpejo_harpa(lp, acs, c0, 0.5, 0.20, rng)
        baixo(lp, acs, c0, 0.34, rng)
        for (c, b, d, r, tp) in acs:                       # cordas graves sustentando o acorde
            if nome in ('A2', 'B', 'A3'):
                ns = tema.notas_acorde(r, tp, T - 12)
                lp.por(pad([hz(n) for n in ns], d * lp.spb + 1.0, 0.6, 0.8, 5, 7, 1.6, rng),
                       lp.t(c0 + c, b), 0.16)
    # marcha leve no tambor de moldura: dum . tek . dum . tek tek
    for c in range(34):
        forte = 1.0 if 2 <= c < 18 or c >= 26 else 0.7
        lp.por(tambor(0.6, 105, 60, 0.2, 0.15, rng), lp.t(c, 0, 0.004), 0.34 * forte)
        lp.por(tambor(0.3, 320, 250, 0.05, 0.9, rng), lp.t(c, 1, 0.004), 0.11 * forte)
        lp.por(tambor(0.6, 100, 60, 0.18, 0.15, rng), lp.t(c, 2, 0.004), 0.26 * forte)
        lp.por(tambor(0.3, 320, 250, 0.05, 0.9, rng), lp.t(c, 3, 0.004), 0.11 * forte)
        lp.por(tambor(0.3, 320, 250, 0.05, 0.9, rng), lp.t(c, 3.5, 0.004), 0.08 * forte)
    fl = lambda f, d: flauta(f, d, rng, 0.004, 0.05)
    co = lambda f, d: cordas(f, d, rng)
    tocar(lp, tema.melodia(), 2, fl, 0.40, extra=0.08)              # A1: flauta sozinha
    tocar(lp, tema.melodia(), 10, co, 0.38, extra=0.15)             # A2: cordas com o tema...
    tocar(lp, tema.melodia(oitava=1), 10, fl, 0.16, extra=0.08)     # ...e a flauta uma oitava acima
    tocar(lp, B_MELODIA, 18, fl, 0.38, extra=0.08)                  # B: desenvolvimento na flauta
    tocar(lp, [(c, b, d, m - 12) for (c, b, d, m) in B_MELODIA if c >= 4], 18, co, 0.22, extra=0.15)
    tocar(lp, tema.melodia(), 26, fl, 0.36, extra=0.08)             # A3: tudo junto
    tocar(lp, tema.melodia(), 26, co, 0.30, extra=0.15)
    return lp.fechar(resposta_reverb(2.2, 1.0, 4500), 0.4)


def mapa_noite(rng):
    lp = Loop(66, 4, 20, rng)
    intro = [(0, 0, 4, T, 'm'), (1, 0, 4, T, 'm')]
    ponte = [(18, 0, 4, T - 4, 'M'), (19, 0, 4, T - 2, 'M')]
    tudo = intro + [(c + 2, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()] \
        + [(c + 10, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()] + ponte
    arpejo_harpa(lp, tudo, 0, 1.0, 0.20, rng, brilho=0.35, padrao=[0, 1, 2, 4])
    baixo(lp, tudo, 0, 0.30, rng, batidas=(0,))
    for (c, b, d, r, tp) in tudo:                            # colchão quente
        ns = tema.notas_acorde(r, tp, T - 12)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 2.0, 1.5, 2.0, 4, 6, 2.2, rng), lp.t(c, b), 0.17)
    fl = lambda f, d: flauta(f, d, rng, 0.005, 0.07)
    ce = lambda f, d: celesta(f, d, rng)
    tocar(lp, tema.melodia(oitava=-1), 2, fl, 0.46, 0.02, extra=0.15)   # flauta grave
    tocar(lp, tema.melodia(), 10, ce, 0.36, 0.01)                         # celesta
    eco = [(0, 0, 1.5, T + 3), (0, 1.5, 0.5, T + 8), (0, 2, 1, T + 10), (0, 3, 1, T + 12),
           (1, 0, 4, T + 14)]                                             # o chamado, de leve, na ponte
    tocar(lp, eco, 18, ce, 0.20, 0.01)
    return lp.fechar(resposta_reverb(3.0, 1.2, 3800), 0.6)


if __name__ == '__main__':
    salvar(f'{PASTA}/mapa_dia.wav', mapa_dia(np.random.default_rng(500)))
    salvar(f'{PASTA}/mapa_noite.wav', mapa_noite(np.random.default_rng(501)))
