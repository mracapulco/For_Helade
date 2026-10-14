# Músicas provisórias do prólogo, todas sobre o tema principal (tools/audio/tema_principal.py),
# originais e feitas por código como as do mapa e dos acampamentos:
#   prologo_abertura.wav - laço. Tela preta, quarto e corredor: uma nota grave longa e poucas
#                          notas de harpa (o "chamado" do tema), bem esparso e escuro.
#   prologo_althea.wav   - laço. Althea nos braços de Nicholas: o tema, delicado, na flauta e
#                          na celesta sobre harpa leve.
#   prologo_varanda.wav  - laço. Varanda: o mesmo tema mais lento, flauta grave e cordas.
#   prologo_titulo.wav   - uma vez só. Final: a segunda metade do tema crescendo até o título,
#                          repousando em Fá e deixando a cauda soar.
# Nos aposentos não há música (só os sons), como no plano.
# Uso: python3 tools/audio/compor_prologo.py   (rodar na raiz do projeto)
import os
import sys

import numpy as np

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import tema_principal as tema                                    # noqa: E402
from gerar_musicas_acampamento import (SR, CAIXINHA, Loop, filtro_fft, flauta, hz,  # noqa: E402
                                       pad, pincado, resposta_reverb, salvar, sino)
from gerar_musicas_mapa import arpejo_harpa, baixo, cordas, tocar  # noqa: E402

PASTA = 'assets/audio/music/prologo'
T = tema.TONICA
IMPORT = """[remap]

importer="wav"
type="AudioStreamWAV"

[deps]

source_file="res://{caminho}"

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode={laco}
edit/loop_begin=0
edit/loop_end=-1
compress/mode=2
"""


def celesta(f, dur, rng):
    return sino(f, max(dur, 2.5), CAIXINHA, rng)


def abertura(rng):
    """60 bpm, 12 compassos. Ré grave sustentado que respira, e a harpa lembrando o chamado."""
    lp = Loop(60, 4, 12, rng)
    # A nota grave longa: Ré e Lá bem embaixo, entrando e saindo devagar, em dois sopros.
    for c in (0, 6):
        lp.por(pad([hz(T - 24), hz(T - 17)], 6 * 4 * lp.spb + 4.0, 5.0, 6.0, 5, 5, 2.2, rng), lp.t(c), 0.30)
    # Um sopro de cordas bem grave por baixo, mudando para Si bemol no meio (o tema vai lá).
    for c, raiz in ((2, T - 24), (8, T - 28)):
        lp.por(cordas(hz(raiz), 3 * 4 * lp.spb, rng), lp.t(c), 0.10)
    # O chamado do tema (Lá Ré Mi Fá) só na harpa, longe, e depois notas soltas.
    chamado = [(1, 0, 1.5, T + 7), (1, 1.5, 0.5, T + 12), (1, 2, 1, T + 14), (1, 3, 2, T + 15)]
    for (c, b, d, m) in chamado:
        lp.por(pincado(hz(m), 4.0, 0.35, 2.2, 0.25, rng=rng), lp.t(c, b, 0.01), 0.26)
    soltas = [(4, 0, T + 7), (4, 2, T + 3), (5, 1, T + 2), (7, 0, T + 7), (7, 1.5, T + 12),
              (7, 2, T + 14), (7, 3, T + 15), (9, 0, T + 14), (9, 2, T + 10), (10, 2, T + 9)]
    for (c, b, m) in soltas:
        lp.por(pincado(hz(m), 4.0, 0.3, 2.0, 0.25, rng=rng), lp.t(c, b, 0.015), 0.18 * rng.uniform(0.8, 1.0))
    return lp.fechar(resposta_reverb(3.5, 1.3, 3200), 0.75)


def althea(rng):
    """60 bpm, 10 compassos: dois de introdução em Fá e o tema inteiro, delicado."""
    lp = Loop(60, 4, 10, rng)
    intro = [(0, 0, 4, T + 3, 'M'), (1, 0, 4, T + 3, 'M')]
    tudo = intro + [(c + 2, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()]
    arpejo_harpa(lp, tudo, 0, 1.0, 0.16, rng, brilho=0.3, padrao=[0, 2, 4, 2])
    baixo(lp, tudo, 0, 0.18, rng, batidas=(0,))
    for (c, b, d, r, tp) in tudo:
        ns = tema.notas_acorde(r, tp, T - 12)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 2.0, 1.5, 2.0, 4, 6, 2.4, rng), lp.t(c, b), 0.10)
    fl = lambda f, d: flauta(f, d, rng, 0.004, 0.06)
    ce = lambda f, d: celesta(f, d, rng)
    primeira = [n for n in tema.melodia() if n[0] < 4]
    segunda = [n for n in tema.melodia() if n[0] >= 4]
    tocar(lp, primeira, 2, ce, 0.34, 0.01)                     # a primeira frase na celesta, como caixinha de música
    tocar(lp, segunda, 2, fl, 0.36, 0.02, extra=0.12)          # a resposta na flauta
    tocar(lp, [(c, b, d, m + 12) for (c, b, d, m) in segunda if c == 7], 2, ce, 0.16, 0.01)
    return lp.fechar(resposta_reverb(3.0, 1.2, 3800), 0.6)


def varanda(rng):
    """46 bpm, 10 compassos: o tema de Althea mais lento, flauta grave e cordas, de frente para o mar."""
    lp = Loop(46, 4, 10, rng)
    intro = [(0, 0, 4, T, 'm'), (1, 0, 4, T + 3, 'M')]
    tudo = intro + [(c + 2, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()]
    arpejo_harpa(lp, tudo, 0, 2.0, 0.15, rng, brilho=0.28, padrao=[0, 2])
    baixo(lp, tudo, 0, 0.20, rng, batidas=(0,))
    for (c, b, d, r, tp) in tudo:
        ns = tema.notas_acorde(r, tp, T - 12)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 2.5, 2.5, 3.0, 4, 7, 2.2, rng), lp.t(c, b), 0.13)
    fl = lambda f, d: flauta(f, d, rng, 0.005, 0.07)
    co = lambda f, d: cordas(f, d, rng)
    tocar(lp, tema.melodia(oitava=-1), 2, fl, 0.44, 0.02, extra=0.2)
    tocar(lp, [(c, b, d, m - 12) for (c, b, d, m) in tema.melodia() if c >= 4], 2, co, 0.20, extra=0.3)
    return lp.fechar(resposta_reverb(3.5, 1.3, 3500), 0.65)


def titulo(rng):
    """Uma vez só, 52 bpm: a segunda metade do tema crescendo, e o acorde de Fá até sumir."""
    compassos_tema = 4
    lp = Loop(52, 4, compassos_tema + 5, rng)                  # sobra espaço: a cauda não dá a volta
    acs = [(c - 4, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes() if c >= 4]
    arpejo_harpa(lp, acs, 0, 1.0, 0.18, rng, brilho=0.4, padrao=[0, 1, 2, 3, 4, 3])
    baixo(lp, acs, 0, 0.26, rng, batidas=(0, 2))
    for (c, b, d, r, tp) in acs:
        ns = tema.notas_acorde(r, tp, T - 12)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 1.5, 1.0 + c * 0.2, 1.5, 5, 6, 1.8, rng),
               lp.t(c, b), 0.12 + 0.03 * c)
    segunda = [(c - 4, b, d, m) for (c, b, d, m) in tema.melodia() if c >= 4]
    tocar(lp, segunda, 0, lambda f, d: flauta(f, d, rng, 0.004, 0.05), 0.40, extra=0.1)
    tocar(lp, segunda, 0, lambda f, d: cordas(f, d, rng), 0.26, extra=0.2)
    # O título: Fá maior em toda a orquestra, a harpa subindo em arpejo e a celesta no alto.
    final = compassos_tema
    fa = [T + 3 - 24, T + 3 - 12, T + 7 - 12, T + 10 - 12, T + 3, T + 7]
    lp.por(pad([hz(m) for m in fa], 5 * 4 * lp.spb, 1.2, 9.0, 6, 6, 1.8, rng), lp.t(final), 0.32)
    for i, m in enumerate([T + 3 - 12, T + 7 - 12, T + 10 - 12, T + 3, T + 7, T + 10, T + 15]):
        lp.por(pincado(hz(m), 5.0, 0.4, 2.5, 0.25, rng=rng), lp.t(final, i * 0.25), 0.22)
    lp.por(celesta(hz(T + 15), 4.0, rng), lp.t(final, 2), 0.2)
    lp.por(flauta(hz(T + 7), 4 * lp.spb * 2, rng, 0.004, 0.05), lp.t(final), 0.3)
    x = lp.fechar(resposta_reverb(4.0, 1.4, 3800), 0.7)
    fim = len(x)
    x[-int(0.5 * SR):] *= np.linspace(1, 0, int(0.5 * SR))   # termina em silêncio
    return x[:fim]


def gravar(nome, x, laco):
    caminho = f'{PASTA}/{nome}.wav'
    salvar(caminho, x)
    with open(caminho + '.import', 'w') as f:
        f.write(IMPORT.format(caminho=caminho, laco=2 if laco else 0))


if __name__ == '__main__':
    gravar('prologo_abertura', abertura(np.random.default_rng(700)), True)
    gravar('prologo_althea', althea(np.random.default_rng(701)), True)
    gravar('prologo_varanda', varanda(np.random.default_rng(702)), True)
    gravar('prologo_titulo', titulo(np.random.default_rng(703)), False)
