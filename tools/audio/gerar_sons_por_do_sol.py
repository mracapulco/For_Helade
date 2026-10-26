# Gera o som provisório do vento do planalto (fase "Antes que o sol beije o
# mar"): ruído filtrado que sobe e desce como rajadas, em loop de 8 s.
# Mono, 16 bits, 22050 Hz, semente fixa. É só um marcador até o som de verdade.
# Uso: python3 tools/audio/gerar_sons_por_do_sol.py   (rodar na raiz do projeto)
import os
import sys
import wave

import numpy as np

sys.dont_write_bytecode = True

SR = 22050
PASTA = 'assets/audio/sfx/estrada_oa'


def passa_baixa(sinal, corte):
    """Filtro de um polo, com o corte (Hz) podendo variar no tempo."""
    corte = np.broadcast_to(corte, sinal.shape)
    saida = np.zeros_like(sinal)
    y = 0.0
    for i, (x, c) in enumerate(zip(sinal, corte)):
        a = 1.0 - np.exp(-2 * np.pi * c / SR)
        y += a * (x - y)
        saida[i] = y
    return saida


def vento(dur=8.0):
    rng = np.random.default_rng(31)
    n = int(dur * SR)
    t = np.arange(n) / SR
    ruido = rng.standard_normal(n)
    # rajadas: duas ondas lentas que fecham o loop (períodos que dividem dur)
    rajada = 0.55 + 0.3 * np.sin(2 * np.pi * t / 4.0) + 0.15 * np.sin(2 * np.pi * t / 2.0 + 1.0)
    sopro = passa_baixa(ruido, 300 + 700 * rajada)
    assobio = passa_baixa(ruido, 1800) - passa_baixa(ruido, 1200)
    sinal = sopro * rajada + 0.25 * assobio * rajada ** 2
    sinal /= np.max(np.abs(sinal)) + 1e-9
    return (sinal * 0.7 * 32767).astype(np.int16)


def salvar(caminho, amostras):
    with wave.open(caminho, 'wb') as arquivo:
        arquivo.setnchannels(1)
        arquivo.setsampwidth(2)
        arquivo.setframerate(SR)
        arquivo.writeframes(amostras.tobytes())
    print(caminho)


if __name__ == '__main__':
    os.makedirs(PASTA, exist_ok=True)
    salvar(f'{PASTA}/vento_planalto.wav', vento())
