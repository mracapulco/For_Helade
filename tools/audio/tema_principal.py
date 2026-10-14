# Tema principal de Por Hélade, guardado como dado para todas as peças reaproveitarem
# (mapa, menu, prólogo...). Melodia de 8 compassos em 4/4, nobre e um pouco melancólica:
# Ré menor (cor dórica no compasso 6, Sol maior) que repousa no relativo maior (Fá).
#
#   c1 Dm   A4.  D5  E5  F5      (o "chamado": quinta → tônica subindo)
#   c2 C    E5.  D5  C5  A4
#   c3 Bb   D5   F5  G5. F5
#   c4 Am   E5 ------    A4      (meia cadência, anacruse para a volta)
#   c5 Dm   D5.  E5  F5  A5      (o chamado de novo, agora subindo até o Lá agudo)
#   c6 G    G5.  F5  E5  D5      (Si natural no acorde: o dórico)
#   c7 Bb C D5.  C5  Bb4 C5
#   c8 F    A4 ---------         (repouso no relativo maior)
#
# Alturas em semitons acima da TONICA; tempos em batidas (semínimas).
# Para transpor, troque a tônica ao usar: midi = tonica + semitom.

TONICA = 62          # Ré4
BATIDAS = 4          # 4/4
COMPASSOS = 8

# (compasso, batida, duração, semitom acima da tônica); compasso começa em 0
MELODIA = [
    (0, 0, 1.5, 7), (0, 1.5, 0.5, 12), (0, 2, 1, 14), (0, 3, 1, 15),
    (1, 0, 1.5, 14), (1, 1.5, 0.5, 12), (1, 2, 1, 10), (1, 3, 1, 7),
    (2, 0, 1, 12), (2, 1, 1, 15), (2, 2, 1.5, 17), (2, 3.5, 0.5, 15),
    (3, 0, 3, 14), (3, 3, 1, 7),
    (4, 0, 1.5, 12), (4, 1.5, 0.5, 14), (4, 2, 1, 15), (4, 3, 1, 19),
    (5, 0, 1.5, 17), (5, 1.5, 0.5, 15), (5, 2, 1, 14), (5, 3, 1, 12),
    (6, 0, 1.5, 12), (6, 1.5, 0.5, 10), (6, 2, 1, 8), (6, 3, 1, 10),
    (7, 0, 4, 7),
]

# (compasso, batida, duração, raiz em semitons acima da tônica, tipo)
ACORDES = [
    (0, 0, 4, 0, 'm'),     # Dm
    (1, 0, 4, -2, 'M'),    # C
    (2, 0, 4, -4, 'M'),    # Bb
    (3, 0, 4, 7, 'm'),     # Am
    (4, 0, 4, 0, 'm'),     # Dm
    (5, 0, 4, 5, 'M'),     # G (dórico)
    (6, 0, 2, -4, 'M'),    # Bb
    (6, 2, 2, -2, 'M'),    # C
    (7, 0, 4, 3, 'M'),     # F
]

INTERVALOS = {'m': (0, 3, 7), 'M': (0, 4, 7)}


def notas_acorde(raiz, tipo, base):
    """MIDI das notas do acorde com a raiz na oitava a partir de 'base' (MIDI)."""
    r = base + (raiz - base) % 12
    return [r + i for i in INTERVALOS[tipo]]


def melodia(tonica=TONICA, oitava=0):
    """[(compasso, batida, dur, midi)] da melodia, já transposta."""
    return [(c, b, d, tonica + s + 12 * oitava) for (c, b, d, s) in MELODIA]


def acordes(tonica=TONICA):
    """[(compasso, batida, dur, raiz_midi_classe, tipo)] com a raiz já na tonalidade."""
    return [(c, b, d, tonica + r, t) for (c, b, d, r, t) in ACORDES]
