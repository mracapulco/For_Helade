# Gera os sons provisórios do Capítulo 01.
# tic_tac.wav: o relógio lento do sonho de Nicholas ("Tic. Tac."), em loop.
# Um tic agudo e um tac mais grave, 1,3 s entre eles, com eco longo para soar
# distante e irreal (Rafael, 17/10/2026: "um tic tac, mais lento").
# cascos_crescendo.wav: cascos que se aproximam e crescem (visão da carruagem).
# vento_leve.wav: ar frio e quase parado da varanda da visão, em loop.
# queda.wav: o tranco do retorno da visão ("Foi queda. Brusca.").
# Sala lateral da loja de pelúcias (caixas e banquinho):
# agarrar.wav: as mãos batem na madeira e seguram (um toque surdo curto).
# arrastar.wav: madeira raspando no assoalho por um passo (meio segundo).
# subir.wav: o pé que pisa em cima da caixa (toque de madeira oca).
# descer.wav: o pulo de volta para o chão (baque abafado).
# achou.wav: três notas suaves subindo, quando acha uma pelúcia.
# Restaurante, a sopa no ritmo:
# colher.wav: a colher tilinta na tigela de louça (mexer e provar).
# soprar.wav: um sopro curto de ar sobre a sopa.
# tigela.wav: a tigela desliza na toalha de volta para Ophelia.
# fora_do_ritmo.wav: um toque abafado e baixo quando erra o tempo.
# Sintetizado, mono, 16 bits, 22050 Hz. Semente fixa: rodar de novo gera o
# mesmo arquivo. Provisório até vir o som de verdade.
# Uso: python3 tools/audio/gerar_sons_capitulo_01.py   (rodar na raiz do projeto)
import os
import sys
import wave

import numpy as np

sys.dont_write_bytecode = True

SR = 22050
PASTA = 'assets/audio/sfx/capitulo_01'
INTERVALO = 1.3          # segundos entre o tic e o tac


def batida(freq, dur=0.09, brilho=1.0, sorte=None):
    """Estalo de madeira e metal: ruído curto filtrado mais dois modos."""
    t = np.arange(int(dur * SR)) / SR
    env = np.exp(-t * 55)
    ruido = sorte.standard_normal(len(t)) * np.exp(-t * 220) * 0.5
    modos = (np.sin(2 * np.pi * freq * t) + 0.5 * brilho * np.sin(2 * np.pi * freq * 2.76 * t)) * env
    return ruido + modos


def eco(sinal, atrasos, ganhos, total):
    saida = np.zeros(total)
    saida[:len(sinal)] += sinal
    for atraso, ganho in zip(atrasos, ganhos):
        n = int(atraso * SR)
        fim = min(total, n + len(sinal))
        if n < total:
            saida[n:fim] += sinal[:fim - n] * ganho
    return saida


def tic_tac():
    sorte = np.random.default_rng(1701)
    total = int(2 * INTERVALO * SR)
    som = np.zeros(total)
    tic = batida(2100, brilho=1.0, sorte=sorte)
    tac = batida(1250, brilho=0.6, sorte=sorte)
    # o eco dá a volta no loop: soma também a cauda que passa do fim
    for inicio, golpe in ((0.0, tic), (INTERVALO, tac)):
        cauda = eco(golpe, [0.21, 0.43, 0.67, 0.92], [0.45, 0.3, 0.18, 0.1], total)
        n = int(inicio * SR)
        som += np.roll(cauda, n)
    # zumbido baixo e quente por baixo, como o ar do corredor
    t = np.arange(total) / SR
    som += 0.03 * np.sin(2 * np.pi * 55 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * t / (2 * INTERVALO)))
    som /= np.max(np.abs(som)) / 0.7
    return som


def cascos_crescendo():
    """Pares de passos (clop-clop) que aceleram e crescem do longe ao muito alto."""
    sorte = np.random.default_rng(1702)
    dur = 7.0
    total = int(dur * SR)
    som = np.zeros(total)
    t_golpe = 0.0
    intervalo = 0.52
    i = 0
    while t_golpe < dur - 0.3:
        progresso = t_golpe / dur
        ganho = 0.04 + 1.0 * progresso ** 2.2
        # corpo grave do casco no chão duro e um estalo de ferradura
        t = np.arange(int(0.16 * SR)) / SR
        grave = np.sin(2 * np.pi * (95 + 25 * (i % 2)) * t) * np.exp(-t * 28)
        estalo = sorte.standard_normal(len(t)) * np.exp(-t * 170)
        # filtro simples (média móvel) tira o chiado quando está longe
        k = max(1, int(7 - 6 * progresso))
        estalo = np.convolve(estalo, np.ones(k) / k, mode='same')
        golpe = (0.9 * grave + 0.7 * estalo) * ganho
        n = int(t_golpe * SR)
        fim = min(total, n + len(golpe))
        som[n:fim] += golpe[:fim - n]
        # o segundo casco do par vem logo depois (clop-clop ... clop-clop)
        t_golpe += 0.17 if i % 2 == 0 else intervalo
        intervalo = max(0.3, intervalo * 0.985)
        i += 1
    # eco de pedra, mais forte quanto mais perto
    som = eco(som, [0.11, 0.27], [0.3, 0.15], total)
    som[-int(0.25 * SR):] *= np.linspace(1, 0, int(0.25 * SR))
    som /= np.max(np.abs(som)) / 0.85
    return som


def vento_leve():
    """Ruído filtrado, bem baixo, com ondulação lenta; emenda sem estalo (filtra no espectro)."""
    sorte = np.random.default_rng(1703)
    dur = 8.0
    n = int(dur * SR)
    ruido = sorte.standard_normal(n)
    espectro = np.fft.rfft(ruido)
    freq = np.fft.rfftfreq(n, 1 / SR)
    espectro *= 1.0 / (1.0 + (freq / 380.0) ** 2) * (freq > 40)
    som = np.fft.irfft(espectro, n)
    t = np.arange(n) / SR
    som *= 0.6 + 0.4 * np.sin(2 * np.pi * t / dur * 2 + 0.7)   # inteiro de ciclos: emenda
    som /= np.max(np.abs(som)) / 0.35
    return som


def queda():
    """Tranco surdo e um sopro de ar: o corpo volta de uma vez."""
    sorte = np.random.default_rng(1704)
    n = int(1.4 * SR)
    t = np.arange(n) / SR
    baque = np.sin(2 * np.pi * (70 - 25 * t) * t) * np.exp(-t * 9)
    sopro = sorte.standard_normal(n) * np.exp(-t * 14)
    sopro = np.convolve(sopro, np.ones(12) / 12, mode='same')
    som = baque + 0.35 * sopro
    som[:int(0.004 * SR)] *= np.linspace(0, 1, int(0.004 * SR))
    som /= np.max(np.abs(som)) / 0.85
    return som


def agarrar():
    sorte = np.random.default_rng(1705)
    som = batida(180, dur=0.14, brilho=0.4, sorte=sorte)
    som = np.convolve(som, np.ones(6) / 6, mode='same')
    som /= np.max(np.abs(som)) / 0.6
    return som


def arrastar():
    """Raspar de madeira: ruído com aspereza que treme e um ronco grave."""
    sorte = np.random.default_rng(1706)
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    ruido = sorte.standard_normal(n)
    ruido = np.convolve(ruido, np.ones(5) / 5, mode='same')
    tremor = 0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 23 * t + sorte.standard_normal(n).cumsum() * 0.01))
    ronco = np.sin(2 * np.pi * 85 * t) * 0.5
    env = np.minimum(1, t / 0.05) * np.minimum(1, (0.5 - t) / 0.12)
    som = (ruido * tremor * 0.7 + ronco) * env
    som /= np.max(np.abs(som)) / 0.45
    return som


def subir():
    sorte = np.random.default_rng(1707)
    som = batida(240, dur=0.18, brilho=0.8, sorte=sorte)
    som = eco(som, [0.03], [0.3], len(som) + int(0.03 * SR))
    som /= np.max(np.abs(som)) / 0.6
    return som


def descer():
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    som = np.sin(2 * np.pi * (95 - 40 * t) * t) * np.exp(-t * 18)
    som[:int(0.003 * SR)] *= np.linspace(0, 1, int(0.003 * SR))
    som /= np.max(np.abs(som)) / 0.7
    return som


def achou():
    notas = (659.3, 784.0, 987.8)      # mi, sol, si
    n = int(1.1 * SR)
    som = np.zeros(n)
    for i, f in enumerate(notas):
        ini = int(i * 0.12 * SR)
        t = np.arange(n - ini) / SR
        som[ini:] += (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)) * np.exp(-t * 4.5)
    som /= np.max(np.abs(som)) / 0.4
    return som


def colher():
    sorte = np.random.default_rng(1710)
    som = batida(2100, dur=0.35, brilho=0.6, sorte=sorte) * 0.6
    t = np.arange(len(som)) / SR
    som += np.sin(2 * np.pi * 3150 * t) * np.exp(-t * 14) * 0.25
    som /= np.max(np.abs(som)) / 0.4
    return som


def soprar():
    sorte = np.random.default_rng(1711)
    n = int(0.4 * SR)
    t = np.arange(n) / SR
    ar = np.convolve(sorte.standard_normal(n), np.ones(9) / 9, mode='same')
    env = np.sin(np.pi * t / 0.4) ** 2
    som = ar * env
    som /= np.max(np.abs(som)) / 0.35
    return som


def tigela():
    sorte = np.random.default_rng(1712)
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    raspa = np.convolve(sorte.standard_normal(n), np.ones(3) / 3, mode='same')
    env = np.minimum(1, t / 0.03) * np.minimum(1, (0.3 - t) / 0.1)
    som = raspa * env * 0.5 + batida(900, dur=0.3, brilho=0.3, sorte=sorte)[:n] * 0.4
    som /= np.max(np.abs(som)) / 0.35
    return som


def fora_do_ritmo():
    n = int(0.15 * SR)
    t = np.arange(n) / SR
    som = np.sin(2 * np.pi * 140 * t) * np.exp(-t * 30)
    som /= np.max(np.abs(som)) / 0.3
    return som


def salvar(nome, som):
    os.makedirs(PASTA, exist_ok=True)
    dados = (np.clip(som, -1, 1) * 32767).astype('<i2')
    with wave.open(os.path.join(PASTA, nome), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(dados.tobytes())


if __name__ == '__main__':
    salvar('tic_tac.wav', tic_tac())
    salvar('cascos_crescendo.wav', cascos_crescendo())
    salvar('vento_leve.wav', vento_leve())
    salvar('queda.wav', queda())
    for nome, gerar in (('agarrar', agarrar), ('arrastar', arrastar), ('subir', subir), ('descer', descer),
                        ('achou', achou), ('colher', colher), ('soprar', soprar), ('tigela', tigela),
                        ('fora_do_ritmo', fora_do_ritmo)):
        salvar(nome + '.wav', gerar())
    print('ok:', PASTA)
