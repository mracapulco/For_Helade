# Gera os sons provisórios do Capítulo 01.
# tic_tac.wav: o relógio lento do sonho de Nicholas ("Tic. Tac."), em loop.
# Um tic agudo e um tac mais grave, 1,3 s entre eles, com eco longo para soar
# distante e irreal (Rafael, 17/10/2026: "um tic tac, mais lento").
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
    print('ok:', PASTA)
