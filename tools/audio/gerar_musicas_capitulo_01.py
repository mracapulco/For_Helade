# Gera as músicas provisórias do Capítulo 01 ("A garota do corredor"), uma por momento
# do capítulo, todas sobre o tema principal (tools/audio/tema_principal.py):
#   cap01_sonho        - o corredor quente: "a música vinha de algum lugar, alta demais,
#                        distante demais". O tema em celesta e harpa desafinadas, muito eco,
#                        abafado, no andamento do tic-tac (1,3 s por batida).
#   cap01_madrugada    - quarto e corredor antes do amanhecer: quase silêncio, notas soltas de
#                        harpa com o chamado do tema e um colchão baixinho.
#   cap01_cortejo      - o cortejo de Pany com o bolo: marchinha em Fá maior, pizzicato,
#                        flauta e tambor de moldura (o chamado do tema em maior).
#   cap01_aniversario  - o quarto de Althea: a caixinha de música do prólogo (o tema de
#                        Althea, que nasceu no prólogo) mais clara e um pouco mais ligeira.
#   cap01_duque        - Apollon e a briga: Ré menor grave, clarinete e cordas, o chamado
#                        lento sobre um pulso surdo.
#   cap01_carruagem    - as viagens de carruagem: harpa e flauta grave sobre o trote dos
#                        cascos (também na carruagem da visão, antes e depois dela).
#   cap01_palacio      - o pátio do Palácio Imperial, "excessivo": cordas cheias, sinos e
#                        harpa brilhando como a água da fonte.
#   cap01_ophelia      - a Princesa: a segunda frase do tema (a que sobe ao Lá agudo, com o
#                        Sol maior dórico) na flauta, a celesta respondendo.
#   cap01_butiques     - a Rua das Butiques: alaúde dedilhado, tambor e flauta, movimentada.
#   cap01_loja         - a loja de pelúcias e a procura nas prateleiras: pizzicato e
#                        caixinha, brincalhão, com o chamado em maior pulando de voz em voz.
#   cap01_restaurante  - o restaurante: valsa calma (3/4) do tema na flauta, harpa.
#   cap01_passeio      - a tarde pelas lojas de Atenas, a luz ficando dourada: harpa e
#                        alaúde leves, o chamado em maior e depois a frase de Ophelia na
#                        flauta, sem pressa; sinos baixos como o sol entre os telhados.
#   cap01_danica       - a volta à mansão ao anoitecer, Danica no pátio: Ré grave parado,
#                        cordas em tremolo com Mi bemol roçando o Ré (frio), o chamado no
#                        clarinete que desce em vez de subir, um pulso surdo como sangue.
#   cap01_antessala    - a porta fechada com o duque: coral grave de cordas, o chamado lento
#                        no clarinete; na segunda metade a frase que sobe ao Lá agudo (Ophelia,
#                        uma dos Doze) aparece baixinho na flauta, sem resolver.
# Mesmos blocos de síntese das músicas dos acampamentos e do mapa; mono, 16 bits, 22050 Hz,
# ~-6 dBFS, loop sem costura (caudas e reverb voltam para o começo). Semente fixa.
# Também grava o .import de cada uma com loop ligado (edit/loop_mode=2).
# Provisório até vir a trilha de verdade; ninguém ouviu ainda: pedir retorno do Rafael.
# Uso: python3 tools/audio/gerar_musicas_capitulo_01.py   (rodar na raiz do projeto)
import os
import sys

import numpy as np

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import tema_principal as tema                                    # noqa: E402
from gerar_musicas_acampamento import (SR, CAIXINHA, SINO_ALTO, Loop, bordas, filtro_fft,  # noqa: E402
                                       flauta, hz, normal, pad, palheta, pincado,
                                       resposta_reverb, salvar, sino, tambor)
from gerar_musicas_mapa import arpejo_harpa, baixo, cordas, tocar  # noqa: E402
from compor_prologo import IMPORT, tremolo                        # noqa: E402

PASTA = 'assets/audio/music/capitulo_01'
T = tema.TONICA
FA = T + 3

# O chamado do tema (c1: Lá Ré Mi Fá) levado para Fá maior: Dó Fá Sol Lá.
CHAMADO_MAIOR = [(0, 1.5, FA + 7), (1.5, 0.5, FA + 12), (2, 1, FA + 14), (3, 1, FA + 16)]


def celesta(f, dur, rng):
    return sino(f, max(dur, 2.5), CAIXINHA, rng)


def caixinha(f, dur, rng):
    """Caixinha de música: o pente de metal, curto e brilhante."""
    return sino(f, max(dur, 1.6), CAIXINHA, rng)


def pizz(f, dur, rng):
    """Pizzicato de cordas: pinçado curto e redondo."""
    return pincado(f, 0.9, 0.35, 0.25, 0.22, rng=rng)


def abafar(lp, corte):
    """Passa-baixa no loop inteiro (a música soa de longe, atrás de portas)."""
    lp.x = filtro_fft(lp.x, lambda fr: 1 / np.sqrt(1 + (fr / corte) ** 4))


def chamado_maior(c, b0=0.0, oitava=0):
    return [(c, b0 + b, d, m + 12 * oitava) for (b, d, m) in CHAMADO_MAIOR]


def sonho(rng):
    """46 bpm (o tic-tac do sonho bate a cada 1,3 s), 10 compassos. O tema inteiro, mas
    errado: celesta em duas cópias desafinadas, harpa em arpejo e um colchão que não para,
    com eco enorme e os agudos cortados. Alto demais, distante demais."""
    lp = Loop(60 / 1.3, 4, 10, rng)
    intro = [(0, 0, 4, T, 'm'), (1, 0, 4, T - 4, 'M')]
    tudo = intro + [(c + 2, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()]
    arpejo_harpa(lp, tudo, 0, 1.0, 0.20, rng, brilho=0.3, padrao=[0, 2, 4, 2])
    for (c, b, d, r, tp) in tudo:
        ns = tema.notas_acorde(r, tp, T - 12)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 2.0, 1.0, 2.5, 6, 14, 1.4, rng), lp.t(c, b), 0.22)
    for desvio in (-0.35, 0.3):                      # duas caixinhas que não concordam
        ce = lambda f, d, k=desvio: celesta(f * 2 ** (k / 12), d, rng)
        tocar(lp, tema.melodia(), 2, ce, 0.30, 0.03)
    tocar(lp, tema.melodia(oitava=-1), 2, lambda f, d: cordas(f, d, rng), 0.14, extra=0.4)
    abafar(lp, 1600)
    return lp.fechar(resposta_reverb(5.0, 1.6, 2200), 1.1)


def madrugada(rng):
    """58 bpm, 12 compassos: a mansão antes do amanhecer, calma mas presente
    (Rafael, 26/10/2026: no quarto e no corredor "ainda não temos uma trilha").
    Dois compassos de colchão, o tema inteiro na harpa sobre um arpejo lento e
    o baixo, a flauta grave ecoando a segunda frase, e dois compassos de volta."""
    lp = Loop(58, 4, 12, rng)
    intro = [(0, 0, 4, T, 'm'), (1, 0, 4, T - 4, 'M')]
    volta = [(10, 0, 4, T - 4, 'M'), (11, 0, 4, T, 'm')]
    tudo = intro + [(c + 2, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()] + volta
    for (c, b, d, r, tp) in tudo:
        ns = tema.notas_acorde(r, tp, T - 12)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 2.0, 2.0, 2.5, 4, 6, 2.4, rng), lp.t(c, b), 0.14)
    arpejo_harpa(lp, tudo, 0, 1.0, 0.12, rng, brilho=0.25, padrao=[0, 2, 1, 3])
    baixo(lp, tudo, 0, 0.16, rng, batidas=(0,))
    harpa = lambda f, d: pincado(f, 4.0, 0.3, 2.2, 0.25, rng=rng)
    fl = lambda f, d: flauta(f, d, rng, 0.004, 0.06)
    tocar(lp, tema.melodia(), 2, harpa, 0.34, 0.03)
    tocar(lp, [n for n in tema.melodia(oitava=-1) if n[0] >= 4], 2, fl, 0.14, 0.015, extra=0.1)
    tocar(lp, chamado_maior(0), 0, harpa, 0.2, 0.03)
    return lp.fechar(resposta_reverb(3.0, 1.2, 3600), 0.6)


def cortejo(rng):
    """112 bpm, 16 compassos: marchinha em Fá maior para o bolo que chega. Pizzicato no
    tempo, flauta com o chamado em maior, tambor de moldura e um sino em cada frase."""
    lp = Loop(112, 4, 16, rng)
    prog = [(0, 'M'), (7, 'M'), (5, 'M'), (7, 'M'), (0, 'M'), (5, 'M'), (7, 'M'), (0, 'M')]
    acs = [(c + 8 * v, 0, 4, FA + r, tp) for v in range(2) for c, (r, tp) in enumerate(prog)]
    baixo(lp, acs, 0, 0.30, rng, batidas=(0, 2))
    for (c, b, d, r, tp) in acs:                     # pizzicato nos contratempos
        ns = tema.notas_acorde(r, tp, T - 2)
        for bb in (1, 3):
            for n in ns:
                lp.por(pizz(hz(n), 0.4, rng), lp.t(c, bb, 0.006), 0.07)
    mel = []
    for v in range(2):
        o = 8 * v
        mel += chamado_maior(o + 0)
        mel += [(o + 1, 0, 1, FA + 14), (o + 1, 1, 1, FA + 12), (o + 1, 2, 2, FA + 11)]
        mel += [(o + 2, 0, 1, FA + 9), (o + 2, 1, 1, FA + 12), (o + 2, 2, 1, FA + 14), (o + 2, 3, 1, FA + 16)]
        mel += [(o + 3, 0, 3, FA + 14), (o + 3, 3, 1, FA + 7)]
        mel += chamado_maior(o + 4)
        mel += [(o + 5, 0, 1.5, FA + 17), (o + 5, 1.5, 0.5, FA + 16), (o + 5, 2, 1, FA + 14), (o + 5, 3, 1, FA + 12)]
        mel += [(o + 6, 0, 1, FA + 11), (o + 6, 1, 1, FA + 14), (o + 6, 2, 2, FA + 16)]
        mel += [(o + 7, 0, 3, FA + 12)]
    fl = lambda f, d: flauta(f, d, rng, 0.003, 0.04)
    tocar(lp, mel, 0, fl, 0.36, 0.006, extra=0.03)
    tocar(lp, [(c, b, d, m + 12) for (c, b, d, m) in mel if c >= 8], 0, fl, 0.12, 0.006)
    for c in range(16):                              # dum . tek . dum tek tek .
        lp.por(tambor(0.5, 115, 70, 0.15, 0.2, rng), lp.t(c, 0, 0.003), 0.28)
        lp.por(tambor(0.25, 330, 260, 0.04, 0.9, rng), lp.t(c, 1, 0.003), 0.10)
        lp.por(tambor(0.5, 110, 70, 0.14, 0.2, rng), lp.t(c, 2, 0.003), 0.22)
        lp.por(tambor(0.25, 330, 260, 0.04, 0.9, rng), lp.t(c, 2.5, 0.003), 0.08)
        lp.por(tambor(0.25, 330, 260, 0.04, 0.9, rng), lp.t(c, 3, 0.003), 0.10)
    for c in (0, 4, 8, 12):
        lp.por(sino(hz(FA + 24), 3.0, SINO_ALTO, rng), lp.t(c), 0.10)
    return lp.fechar(resposta_reverb(1.8, 0.9, 4500), 0.35)


def aniversario(rng):
    """72 bpm, 10 compassos: a caixinha de música do prólogo (o tema de Althea) em Fá,
    agora no quarto dela, clara e ligeira. Harpa em arpejo, flauta na resposta."""
    lp = Loop(72, 4, 10, rng)
    intro = [(0, 0, 4, FA, 'M'), (1, 0, 4, T - 4, 'M')]
    tudo = intro + [(c + 2, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()]
    arpejo_harpa(lp, tudo, 0, 0.5, 0.15, rng, brilho=0.4, padrao=[0, 1, 2, 4, 3, 2])
    baixo(lp, tudo, 0, 0.18, rng, batidas=(0,))
    for (c, b, d, r, tp) in tudo:
        ns = tema.notas_acorde(r, tp, T - 12)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 1.5, 1.2, 1.8, 4, 6, 2.4, rng), lp.t(c, b), 0.08)
    cx = lambda f, d: caixinha(f, d, rng)
    fl = lambda f, d: flauta(f, d, rng, 0.004, 0.05)
    primeira = [n for n in tema.melodia(oitava=1) if n[0] < 4]
    segunda = [n for n in tema.melodia() if n[0] >= 4]
    tocar(lp, primeira, 2, cx, 0.36, 0.008)                  # a caixinha, uma oitava acima
    tocar(lp, segunda, 2, fl, 0.34, 0.015, extra=0.08)      # a flauta responde
    tocar(lp, [(c, b, d, m + 12) for (c, b, d, m) in segunda if c >= 6], 2, cx, 0.16, 0.008)
    tocar(lp, chamado_maior(1, oitava=1), 0, cx, 0.20, 0.008)  # o chamado em maior na introdução
    return lp.fechar(resposta_reverb(2.4, 1.0, 4200), 0.45)


def duque(rng):
    """58 bpm, 8 compassos: o duque no quarto. Ré grave sem descanso, tremolo que cresce,
    o chamado no clarinete grave e um pulso surdo de tambor, como passos firmes."""
    lp = Loop(58, 4, 8, rng)
    lp.por(pad([hz(T - 24), hz(T - 17)], 8 * 4 * lp.spb + 3.0, 4.0, 4.0, 5, 5, 2.0, rng), lp.t(0), 0.28)
    acs = [(0, 0, 4, T, 'm'), (1, 0, 4, T - 4, 'M'), (2, 0, 4, T, 'm'), (3, 0, 4, T + 7, 'M'),
           (4, 0, 4, T, 'm'), (5, 0, 4, T - 4, 'M'), (6, 0, 4, T - 5, 'm'), (7, 0, 4, T + 7, 'M')]
    for (c, b, d, r, tp) in acs:
        ns = tema.notas_acorde(r, tp, T - 12)
        for n in ns:
            lp.por(bordas(tremolo(hz(n), d * lp.spb, rng, 6.0), 1.2, 1.2), lp.t(c, b), 0.06)
    pa = lambda f, d: palheta(f, d, rng)
    mel = [(0, 0, 1.5, T - 5), (0, 1.5, 0.5, T), (0, 2, 1, T + 2), (0, 3, 1, T + 3),
           (1, 0, 3, T + 2), (1, 3, 1, T - 2),
           (2, 0, 1.5, T - 5), (2, 1.5, 0.5, T), (2, 2, 1, T + 2), (2, 3, 1, T + 3),
           (3, 0, 2, T + 1), (3, 2, 2, T - 1)]
    tocar(lp, mel, 0, pa, 0.40, 0.02, extra=0.1)
    tocar(lp, [(c + 4, b, d, m - 12) for (c, b, d, m) in mel], 0, lambda f, d: cordas(f, d, rng), 0.26, extra=0.2)
    for c in range(8):
        for bb in (0, 2):
            lp.por(tambor(0.8, 70, 45, 0.25, 0.05, rng), lp.t(c, bb, 0.004), 0.30 if bb == 0 else 0.18)
    return lp.fechar(resposta_reverb(2.8, 1.1, 2800), 0.55)


def carruagem(rng):
    """80 bpm, 10 compassos: o balanço da carruagem. Trote de cascos (dois toques secos),
    harpa em arpejo e o tema na flauta grave, sem pressa."""
    lp = Loop(80, 4, 10, rng)
    intro = [(0, 0, 4, T, 'm'), (1, 0, 4, T - 4, 'M')]
    tudo = intro + [(c + 2, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()]
    arpejo_harpa(lp, tudo, 0, 1.0, 0.17, rng, brilho=0.35, padrao=[0, 2, 3, 2])
    baixo(lp, tudo, 0, 0.22, rng, batidas=(0, 2))
    for (c, b, d, r, tp) in tudo:
        ns = tema.notas_acorde(r, tp, T - 12)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 1.5, 1.2, 1.8, 4, 6, 2.2, rng), lp.t(c, b), 0.10)
    for c in range(10):                              # tlo-toc . tlo-toc .
        for bb in (0, 1, 2, 3):
            lp.por(tambor(0.15, 640, 520, 0.025, 0.6, rng), lp.t(c, bb, 0.012), 0.07)
            lp.por(tambor(0.15, 560, 470, 0.025, 0.6, rng), lp.t(c, bb + 0.33, 0.012), 0.05)
    fl = lambda f, d: flauta(f, d, rng, 0.005, 0.06)
    tocar(lp, tema.melodia(oitava=-1), 2, fl, 0.42, 0.015, extra=0.12)
    return lp.fechar(resposta_reverb(2.2, 1.0, 4000), 0.45)


def palacio(rng):
    """70 bpm, 10 compassos: tudo alto demais, amplo demais, ornamentado demais. Cordas
    cheias com o tema, sino grave em cada acorde e a harpa brilhando rápido no agudo,
    como a fonte que Althea viu em diamantes líquidos."""
    lp = Loop(70, 4, 10, rng)
    intro = [(0, 0, 4, T - 4, 'M'), (1, 0, 4, T - 2, 'M')]
    tudo = intro + [(c + 2, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()]
    arpejo_harpa(lp, tudo, 0, 0.25, 0.10, rng, base=T - 12, brilho=0.6, padrao=[0, 1, 2, 3, 4, 5, 4, 3])
    baixo(lp, tudo, 0, 0.30, rng, batidas=(0,))
    for (c, b, d, r, tp) in tudo:
        ns = tema.notas_acorde(r, tp, T - 12) + tema.notas_acorde(r, tp, T)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 1.0, 0.8, 1.2, 6, 7, 1.5, rng), lp.t(c, b), 0.16)
        lp.por(sino(hz(tema.notas_acorde(r, tp, T - 12)[0]), 4.0, SINO_ALTO, rng), lp.t(c, b), 0.10)
    co = lambda f, d: cordas(f, d, rng)
    fl = lambda f, d: flauta(f, d, rng, 0.004, 0.04)
    tocar(lp, tema.melodia(), 2, co, 0.40, 0.01, extra=0.15)
    tocar(lp, tema.melodia(oitava=1), 2, fl, 0.14, 0.01, extra=0.08)
    tocar(lp, chamado_maior(0) + chamado_maior(1, oitava=-1), 0, co, 0.22, extra=0.15)
    return lp.fechar(resposta_reverb(3.2, 1.3, 4200), 0.6)


def ophelia(rng):
    """63 bpm, 10 compassos: a Princesa. A segunda frase do tema (a que sobe ao Lá agudo,
    com o Sol maior dórico) na flauta, sozinha e contida; a celesta responde com a primeira.
    Harpa leve e um colchão claro."""
    lp = Loop(63, 4, 10, rng)
    seg = [(c - 4, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes() if c >= 4]
    pri = [(c, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes() if c < 4]
    tudo = [(0, 0, 4, T + 5, 'M'), (1, 0, 4, T, 'm')] + [(c + 2, b, d, r, tp) for (c, b, d, r, tp) in seg] \
        + [(c + 6, b, d, r, tp) for (c, b, d, r, tp) in pri]
    arpejo_harpa(lp, tudo, 0, 1.0, 0.13, rng, brilho=0.3, padrao=[0, 2, 4, 2])
    baixo(lp, tudo, 0, 0.16, rng, batidas=(0,))
    for (c, b, d, r, tp) in tudo:
        ns = tema.notas_acorde(r, tp, T - 12)
        lp.por(pad([hz(n) for n in ns], d * lp.spb + 2.0, 1.5, 2.0, 4, 5, 2.4, rng), lp.t(c, b), 0.10)
    fl = lambda f, d: flauta(f, d, rng, 0.003, 0.05)
    ce = lambda f, d: celesta(f, d, rng)
    segunda = [(c - 4 + 2, b, d, m) for (c, b, d, m) in tema.melodia() if c >= 4]
    primeira = [(c + 6, b, d, m) for (c, b, d, m) in tema.melodia(oitava=1) if c < 4]
    tocar(lp, segunda, 0, fl, 0.40, 0.015, extra=0.12)
    tocar(lp, primeira, 0, ce, 0.28, 0.008)
    lp.por(celesta(hz(T + 19), 3.0, rng), lp.t(1, 2), 0.12)       # um brilho no alto, na entrada
    return lp.fechar(resposta_reverb(3.0, 1.2, 4200), 0.6)


def butiques(rng):
    """108 bpm, 16 compassos: a Rua das Butiques cheia. Alaúde dedilhando em colcheias,
    tambor de moldura, flauta com o tema e depois com o chamado em maior."""
    lp = Loop(108, 4, 16, rng)
    a = [(c, b, d, r, tp) for (c, b, d, r, tp) in tema.acordes()]
    bm = [(0, 0, 4, FA, 'M'), (1, 0, 4, T - 4, 'M'), (2, 0, 4, FA + 7, 'M'), (3, 0, 4, FA, 'M'),
          (4, 0, 4, T - 4, 'M'), (5, 0, 4, T, 'm'), (6, 0, 4, FA + 7, 'M'), (7, 0, 4, FA, 'M')]
    acs = a + [(c + 8, b, d, r, tp) for (c, b, d, r, tp) in bm]
    baixo(lp, acs, 0, 0.30, rng, batidas=(0, 2))
    for (c, b, d, r, tp) in acs:                     # alaúde: dedilhado em colcheias
        ns = tema.notas_acorde(r, tp, T - 12)
        voz = [ns[0], ns[1], ns[2], ns[1] + 12, ns[2], ns[1], ns[0] + 12, ns[2]]
        for k in range(8):
            lp.por(pincado(hz(voz[k]), 1.2, 0.55, 0.6, 0.15, rng=rng), lp.t(c, b + 0.5 * k, 0.008),
                   0.11 * (1.3 if k in (0, 4) else 1.0))
    fl = lambda f, d: flauta(f, d, rng, 0.004, 0.05)
    tocar(lp, tema.melodia(oitava=1), 0, fl, 0.32, 0.008, extra=0.04)
    mel = chamado_maior(8) + [(9, 0, 2, FA + 14), (9, 2, 2, FA + 10)] + chamado_maior(10) \
        + [(11, 0, 4, FA + 12)] + chamado_maior(12, oitava=0) \
        + [(13, 0, 1.5, FA + 17), (13, 1.5, 0.5, FA + 16), (13, 2, 2, FA + 14),
           (14, 0, 1, FA + 11), (14, 1, 1, FA + 14), (14, 2, 2, FA + 16), (15, 0, 4, FA + 12)]
    tocar(lp, mel, 0, fl, 0.32, 0.008, extra=0.04)
    for c in range(16):
        lp.por(tambor(0.5, 110, 65, 0.16, 0.2, rng), lp.t(c, 0, 0.004), 0.26)
        lp.por(tambor(0.25, 320, 250, 0.04, 0.9, rng), lp.t(c, 1.5, 0.004), 0.09)
        lp.por(tambor(0.5, 105, 65, 0.15, 0.2, rng), lp.t(c, 2, 0.004), 0.20)
        lp.por(tambor(0.25, 320, 250, 0.04, 0.9, rng), lp.t(c, 3, 0.004), 0.10)
        lp.por(tambor(0.25, 320, 250, 0.04, 0.9, rng), lp.t(c, 3.5, 0.004), 0.07)
    return lp.fechar(resposta_reverb(1.8, 0.9, 4500), 0.35)


def loja(rng):
    """96 bpm, 8 compassos: a loja de pelúcias e a procura entre as prateleiras baixas.
    Pizzicato saltitante, a caixinha com o chamado em maior aparecendo em lugares
    diferentes (ora no grave, ora no agudo), como quem se esconde."""
    lp = Loop(96, 4, 8, rng)
    prog = [(FA, 'M'), (T - 4, 'M'), (FA + 7, 'M'), (FA, 'M'), (T, 'm'), (T - 4, 'M'), (FA + 7, 'M'), (FA, 'M')]
    acs = [(c, 0, 4, r, tp) for c, (r, tp) in enumerate(prog)]
    for (c, b, d, r, tp) in acs:
        ns = tema.notas_acorde(r, tp, T - 14)
        for k, bb in enumerate((0, 1, 2, 3)):
            n = ns[0] - 12 if k % 2 == 0 else ns[2]
            lp.por(pizz(hz(n), 0.4, rng), lp.t(c, bb, 0.006), 0.18 if k % 2 == 0 else 0.10)
        for bb in (0.5, 2.5):
            for n in ns:
                lp.por(pizz(hz(n + 12), 0.3, rng), lp.t(c, bb, 0.006), 0.05)
    cx = lambda f, d: caixinha(f, d, rng)
    fl = lambda f, d: flauta(f, d, rng, 0.003, 0.04)
    tocar(lp, chamado_maior(0, oitava=1), 0, cx, 0.30, 0.006)
    tocar(lp, [(1, 0, 1, FA + 26), (1, 1, 1, FA + 24), (1, 2, 2, FA + 21)], 0, cx, 0.24, 0.006)
    tocar(lp, chamado_maior(2, oitava=-1), 0, lambda f, d: pizz(f, d, rng), 0.30, 0.006)
    tocar(lp, [(3, 0, 1, FA + 2), (3, 1, 1, FA + 4), (3, 2, 2, FA)], 0, lambda f, d: pizz(f, d, rng), 0.26)
    tocar(lp, chamado_maior(4), 0, fl, 0.30, 0.006, extra=0.03)
    tocar(lp, [(5, 0, 1.5, FA + 17), (5, 1.5, 0.5, FA + 16), (5, 2, 2, FA + 14)], 0, fl, 0.28, 0.006)
    tocar(lp, chamado_maior(6, oitava=1), 0, cx, 0.28, 0.006)
    tocar(lp, [(7, 0, 0.5, FA + 24), (7, 0.5, 0.5, FA + 26), (7, 1, 3, FA + 24)], 0, cx, 0.24, 0.006)
    for c in range(8):
        lp.por(tambor(0.2, 380, 300, 0.03, 0.8, rng), lp.t(c, 1, 0.004), 0.06)
        lp.por(tambor(0.2, 380, 300, 0.03, 0.8, rng), lp.t(c, 3, 0.004), 0.06)
    return lp.fechar(resposta_reverb(1.6, 0.8, 4800), 0.3)


# O tema em 3/4 para a valsa do restaurante (compasso, batida, duração, semitom).
VALSA = [(0, 0, 2, 7), (0, 2, 1, 12),
         (1, 0, 1.5, 14), (1, 1.5, 0.5, 12), (1, 2, 1, 10),
         (2, 0, 1, 12), (2, 1, 1, 15), (2, 2, 1, 17),
         (3, 0, 3, 14),
         (4, 0, 1, 12), (4, 1, 1, 15), (4, 2, 1, 19),
         (5, 0, 1.5, 17), (5, 1.5, 0.5, 15), (5, 2, 1, 14),
         (6, 0, 1.5, 12), (6, 1.5, 0.5, 10), (6, 2, 1, 8),
         (7, 0, 3, 7)]
VALSA_ACORDES = [(0, 'm'), (-2, 'M'), (-4, 'M'), (7, 'm'), (0, 'm'), (5, 'M'), (-4, 'M'), (3, 'M')]


def restaurante(rng):
    """90 bpm em 3/4, 16 compassos: valsa calma para o almoço. Baixo no um, harpa no dois
    e no três, o tema na flauta e, na volta, nas cordas com a flauta por cima."""
    lp = Loop(90, 3, 16, rng)
    for v in range(2):
        for c, (r, tp) in enumerate(VALSA_ACORDES):
            cc = c + 8 * v
            m = tema.notas_acorde(T + r, tp, T - 26)[0]
            lp.por(pincado(hz(m), 2.5, 0.2, 1.6, 0.22, rng=rng), lp.t(cc, 0), 0.26)
            ns = tema.notas_acorde(T + r, tp, T - 12)
            for bb in (1, 2):
                for n in ns:
                    lp.por(pincado(hz(n), 1.4, 0.35, 0.8, 0.25, rng=rng), lp.t(cc, bb, 0.008), 0.06)
            if v == 1:
                lp.por(pad([hz(n) for n in ns], 3 * lp.spb + 1.0, 0.8, 1.2, 4, 6, 2.2, rng), lp.t(cc), 0.08)
    mel = [(c, b, d, T + s) for (c, b, d, s) in VALSA]
    fl = lambda f, d: flauta(f, d, rng, 0.004, 0.05)
    tocar(lp, mel, 0, fl, 0.36, 0.01, extra=0.06)
    tocar(lp, mel, 8, lambda f, d: cordas(f, d, rng), 0.28, extra=0.12)
    tocar(lp, [(c, b, d, m + 12) for (c, b, d, m) in mel if c >= 4], 8, fl, 0.14, 0.01)
    return lp.fechar(resposta_reverb(2.2, 1.0, 4300), 0.4)


def passeio(rng):
    """84 bpm, 16 compassos: a tarde pelas lojas. Harpa em arpejo largo, alaúde nos
    contratempos, o chamado em maior na flauta e depois a frase do tema que sobe ao Lá
    agudo (a de Ophelia), como a conversa ficando mais natural. Sino baixo a cada frase."""
    lp = Loop(84, 4, 16, rng)
    a = [(0, 0, 4, FA, 'M'), (1, 0, 4, T - 4, 'M'), (2, 0, 4, FA + 7, 'M'), (3, 0, 4, FA, 'M')]
    b = [(c, bb, d, r, tp) for (c, bb, d, r, tp) in tema.acordes() if c >= 4]
    acs = []
    for v in range(2):
        acs += [(c + 8 * v, bb, d, r, tp) for (c, bb, d, r, tp) in a + b]
    arpejo_harpa(lp, acs, 0, 0.5, 0.13, rng, brilho=0.35, padrao=[0, 2, 4, 5, 4, 2])
    baixo(lp, acs, 0, 0.20, rng, batidas=(0,))
    for (c, bb, d, r, tp) in acs:                    # alaúde nos contratempos, bem leve
        ns = tema.notas_acorde(r, tp, T - 2)
        for k in range(int(d)):
            lp.por(pincado(hz(ns[k % 3]), 1.0, 0.5, 0.5, 0.15, rng=rng), lp.t(c, bb + k + 0.5, 0.008), 0.06)
        if v_segunda(c):
            ps = tema.notas_acorde(r, tp, T - 12)
            lp.por(pad([hz(n) for n in ps], d * lp.spb + 1.2, 1.0, 1.6, 4, 6, 2.4, rng), lp.t(c, bb), 0.08)
    fl = lambda f, d: flauta(f, d, rng, 0.004, 0.05)
    ce = lambda f, d: celesta(f, d, rng)
    mel = chamado_maior(0) + [(1, 0, 1, FA + 14), (1, 1, 1, FA + 12), (1, 2, 2, FA + 9)] \
        + chamado_maior(2) + [(3, 0, 4, FA + 12)]
    ophelia_frase = [n for n in tema.melodia() if n[0] >= 4]
    tocar(lp, mel, 0, fl, 0.34, 0.012, extra=0.06)
    tocar(lp, ophelia_frase, 0, fl, 0.34, 0.012, extra=0.08)
    tocar(lp, [(c, bb, d, m + 12) for (c, bb, d, m) in mel], 8, ce, 0.26, 0.008)
    tocar(lp, ophelia_frase, 8, lambda f, d: cordas(f, d, rng), 0.26, extra=0.15)
    tocar(lp, [(c, bb, d, m + 12) for (c, bb, d, m) in ophelia_frase], 8, fl, 0.14, 0.012)
    for c in (0, 4, 8, 12):
        lp.por(sino(hz(FA - 12 if c % 8 else FA), 4.0, SINO_ALTO, rng), lp.t(c), 0.07)
    return lp.fechar(resposta_reverb(2.6, 1.1, 4200), 0.5)


def v_segunda(c):
    """Na segunda volta do passeio entra um colchão de cordas por baixo."""
    return c >= 8


def danica(rng):
    """50 bpm, 8 compassos: o pátio ao anoitecer e Danica ali. Ré grave parado, cordas em
    tremolo com o Mi bemol roçando o Ré, o chamado no clarinete que, em vez de subir ao Fá,
    afunda (Lá Ré Mi Mi bemol Ré). Um fio agudo frio e um pulso surdo, como o sangue."""
    lp = Loop(50, 4, 8, rng)
    total = 8 * 4 * lp.spb
    lp.por(pad([hz(T - 24), hz(T - 17)], total + 3.0, 4.0, 4.0, 5, 5, 2.2, rng), lp.t(0), 0.26)
    lp.por(pad([hz(T + 19), hz(T + 24)], total + 3.0, 6.0, 6.0, 2, 9, 3.0, rng), lp.t(0), 0.04)
    acs = [(0, T, 'm'), (1, T + 1, 'M'), (2, T, 'm'), (3, T - 4, 'M'),
           (4, T, 'm'), (5, T + 1, 'M'), (6, T - 5, 'm'), (7, T + 7, 'M')]
    for (c, r, tp) in acs:
        for n in tema.notas_acorde(r, tp, T - 12):
            lp.por(bordas(tremolo(hz(n), 4 * lp.spb, rng, 7.0), 1.5, 1.5), lp.t(c), 0.05)
    pa = lambda f, d: palheta(f, d, rng)
    mel = [(0, 0, 1.5, T - 5), (0, 1.5, 0.5, T), (0, 2, 1, T + 2), (0, 3, 1, T + 1),
           (1, 0, 4, T),
           (2, 0, 1.5, T - 5), (2, 1.5, 0.5, T), (2, 2, 1, T + 2), (2, 3, 1, T + 3),
           (3, 0, 2, T + 2), (3, 2, 2, T + 1)]
    tocar(lp, mel, 0, pa, 0.36, 0.02, extra=0.15)
    tocar(lp, [(c + 4, bb, d, m - 12) for (c, bb, d, m) in mel], 0, lambda f, d: cordas(f, d, rng),
          0.38, extra=0.25)
    for c in range(8):                               # tum-tum . . (como o coração)
        lp.por(tambor(0.6, 62, 42, 0.18, 0.03, rng), lp.t(c, 0, 0.003), 0.26)
        lp.por(tambor(0.5, 58, 40, 0.14, 0.03, rng), lp.t(c, 0.45, 0.003), 0.16)
    for c in (0, 4):
        lp.por(sino(hz(T - 12), 6.0, SINO_ALTO, rng), lp.t(c, 2), 0.05)
    return lp.fechar(resposta_reverb(3.4, 1.4, 2600), 0.6)


def antessala(rng):
    """56 bpm, 12 compassos: a porta fechada com o duque. Coral grave de cordas em Ré
    menor, o chamado lento no clarinete; na segunda metade a frase do tema que sobe ao
    Lá agudo (Ophelia, uma dos Doze) na flauta, baixinho, e o fim fica no Lá, sem resolver."""
    lp = Loop(56, 4, 12, rng)
    acs = [(0, T, 'm'), (1, T - 4, 'M'), (2, T + 5, 'm'), (3, T + 7, 'M'),
           (4, T, 'm'), (5, T + 3, 'M'), (6, T - 4, 'M'), (7, T + 7, 'M'),
           (8, T, 'm'), (9, T + 5, 'M'), (10, T - 4, 'M'), (11, T + 7, 'M')]
    for (c, r, tp) in acs:
        ns = tema.notas_acorde(r, tp, T - 19)
        lp.por(pad([hz(n) for n in ns], 4 * lp.spb + 2.0, 1.6, 2.2, 6, 4, 1.8, rng), lp.t(c), 0.18)
        lp.por(pincado(hz(tema.notas_acorde(r, tp, T - 29)[0]), 4.0, 0.12, 2.8, 0.25, rng=rng), lp.t(c), 0.18)
    pa = lambda f, d: palheta(f, d, rng)
    fl = lambda f, d: flauta(f, d, rng, 0.003, 0.06)
    chamado = [(0, 0, 2, T - 5), (0, 2, 1, T), (0, 3, 1, T + 2), (1, 0, 3, T + 3), (1, 3, 1, T + 2),
               (2, 0, 2, T), (2, 2, 2, T - 2), (3, 0, 4, T + 1)]
    tocar(lp, chamado, 0, pa, 0.34, 0.03, extra=0.2)
    tocar(lp, chamado, 4, lambda f, d: cordas(f, d, rng), 0.34, extra=0.25)
    subida = [(8, 0, 1.5, T + 12), (8, 1.5, 0.5, T + 14), (8, 2, 1, T + 15), (8, 3, 1, T + 19),
              (9, 0, 1.5, T + 17), (9, 1.5, 0.5, T + 15), (9, 2, 2, T + 14),
              (10, 0, 2, T + 12), (10, 2, 2, T + 10), (11, 0, 4, T + 7)]
    tocar(lp, subida, 0, fl, 0.30, 0.02, extra=0.15)
    for c in range(0, 12, 2):
        lp.por(tambor(0.9, 58, 38, 0.3, 0.02, rng), lp.t(c, 0, 0.003), 0.14)
    return lp.fechar(resposta_reverb(1.8, 0.9, 2600), 0.5)


PECAS = [sonho, madrugada, cortejo, aniversario, duque, carruagem, palacio, ophelia,
         butiques, loja, restaurante, passeio, danica, antessala]


def gravar(nome, x):
    caminho = f'{PASTA}/cap01_{nome}.wav'
    salvar(caminho, x)
    with open(caminho + '.import', 'w') as f:
        f.write(IMPORT.format(caminho=caminho, laco=2))


if __name__ == '__main__':
    so = sys.argv[1:]
    for i, peca in enumerate(PECAS):
        if not so or peca.__name__ in so:
            gravar(peca.__name__, peca(np.random.default_rng(900 + i)))
