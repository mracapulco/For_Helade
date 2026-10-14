# Gera os sons provisórios dos acampamentos: bichos (cão, ovelha, cabra, burro,
# coruja, gaivota, caranguejo) e o crepitar da fogueira em loop.
# Tudo sintetizado (fonte harmônica + ruído passando por formantes), mono,
# 16 bits, 22050 Hz. Semente fixa: rodar de novo gera os mesmos arquivos.
# São só marcadores para testar até virem os sons de verdade.
# Uso: python3 tools/audio/gerar_sons_acampamento.py   (rodar na raiz do projeto)
import os
import sys
import wave

import numpy as np

sys.dont_write_bytecode = True

SR = 22050
PASTA_ANIMAIS = 'assets/audio/sfx/animais'
PASTA_SFX = 'assets/audio/sfx'


# ---------- blocos básicos ----------

def tempo(dur):
    return np.arange(int(round(dur * SR))) / SR


def curva(t, pontos):
    """Contorno por pontos (tempo, valor), interpolado em linha reta."""
    xs, ys = zip(*pontos)
    return np.interp(t, xs, ys)


def harmonicos(f0, inclinacao=1.0, maximo=60):
    """Onda rica (dente de serra limitada em banda) seguindo a altura f0[t].
    inclinacao: queda de cada harmônico (1 = dente de serra; menor = mais brilho)."""
    fase = 2 * np.pi * np.cumsum(f0) / SR
    sinal = np.zeros_like(f0)
    for k in range(1, maximo + 1):
        ativo = (k * f0) < (SR / 2 - 500)
        if not ativo.any():
            break
        sinal += np.sin(k * fase) * ativo / k ** inclinacao
    return sinal


def ressonador(x, fc, banda, ganho=1.0):
    """Filtro de dois polos (formante). fc pode variar no tempo (array)."""
    fc = np.broadcast_to(np.asarray(fc, dtype=float), x.shape)
    r = np.exp(-np.pi * banda / SR)
    y = np.zeros_like(x)
    y1 = y2 = 0.0
    a1 = g = 0.0
    a2 = r * r
    for n in range(len(x)):
        if n % 32 == 0:                       # recalcula os coeficientes a cada 32 amostras
            th = 2 * np.pi * fc[n] / SR
            a1 = -2 * r * np.cos(th)
            g = (1 - r) * abs(1 - r * np.exp(-2j * th))   # pico perto de 1
        yn = g * x[n] - a1 * y1 - a2 * y2
        y[n] = yn
        y2, y1 = y1, yn
    return y * ganho


def formantes(fonte, lista):
    """lista de (fc, banda, ganho); soma os ressonadores em paralelo."""
    return sum(ressonador(fonte, fc, bw, g) for (fc, bw, g) in lista)


def envelope(t, ataque, soltura, dur=None):
    dur = t[-1] if dur is None else dur
    e = np.ones_like(t)
    e = np.minimum(e, t / max(ataque, 1e-4))
    e = np.minimum(e, np.clip((dur - t) / max(soltura, 1e-4), 0, 1))
    return np.clip(e, 0, 1)


def colocar(destino, som, inicio):
    i = int(round(inicio * SR))
    fim = min(len(destino), i + len(som))
    destino[i:fim] += som[:fim - i]


def finalizar(x, dbfs, entrada=0.006, saida=0.03):
    """Tira o nível DC, suaviza começo e fim e normaliza o pico."""
    x = x - np.mean(x)
    n_in, n_out = int(entrada * SR), int(saida * SR)
    if n_in: x[:n_in] *= np.linspace(0, 1, n_in)
    if n_out: x[-n_out:] *= np.linspace(1, 0, n_out)
    return x * (10 ** (dbfs / 20) / np.max(np.abs(x)))


def salvar(caminho, x):
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    dados = np.clip(np.round(x * 32767), -32768, 32767).astype('<i2')
    with wave.open(caminho, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(dados.tobytes())
    print(caminho, f'{len(x) / SR:.2f} s', f'pico {20 * np.log10(np.max(np.abs(x))):.1f} dBFS')


# ---------- bichos ----------

def latido(rng, altura):
    t = tempo(0.15)
    f0 = curva(t, [(0, altura * 0.8), (0.025, altura * 1.25), (0.15, altura * 0.65)])
    fonte = harmonicos(f0, 0.9) + 0.35 * rng.standard_normal(len(t))
    voz = formantes(fonte, [(curva(t, [(0, 500), (0.03, 750), (0.15, 550)]), 220, 1.0),
                            (1500, 300, 0.7), (2700, 450, 0.3)])
    env = np.minimum(t / 0.006, 1) * np.exp(-np.maximum(t - 0.02, 0) / 0.045)
    return voz * env


def cao(rng):
    x = np.zeros(int(0.62 * SR))
    colocar(x, latido(rng, 420), 0.02)
    colocar(x, 0.9 * latido(rng, 390), 0.30)
    return finalizar(x, -3)


def ovelha(rng):
    dur = 0.95
    t = tempo(dur)
    vib = np.sin(2 * np.pi * 6.5 * t) * curva(t, [(0, 0.01), (0.3, 0.05), (dur, 0.07)])
    f0 = curva(t, [(0, 250), (0.12, 300), (0.6, 285), (dur, 255)]) * (1 + vib)
    fonte = harmonicos(f0, 1.0) + 0.06 * rng.standard_normal(len(t))
    f1 = curva(t, [(0, 300), (0.07, 780), (0.7, 700), (dur, 600)])   # "b" abrindo em "é"
    voz = formantes(fonte, [(f1, 130, 1.0), (curva(t, [(0, 900), (0.08, 1300), (dur, 1200)]), 160, 0.8),
                            (2600, 260, 0.35)])
    pulsa = 1 - 0.35 * (0.5 + 0.5 * np.sin(2 * np.pi * 6.5 * t)) * curva(t, [(0, 0), (0.25, 1), (dur, 1)])
    return finalizar(voz * pulsa * envelope(t, 0.04, 0.25, dur), -3)


def cabra(rng):
    dur = 0.8
    t = tempo(dur)
    trem = np.sin(2 * np.pi * 17 * t)
    f0 = curva(t, [(0, 380), (0.1, 440), (0.5, 420), (dur, 350)]) * (1 + 0.045 * trem)
    fonte = harmonicos(f0, 0.7) + 0.08 * rng.standard_normal(len(t))
    # anasalado: primeiro formante fraco e estreito, segundo e terceiro fortes
    voz = formantes(fonte, [(550, 90, 0.5), (1750, 120, 1.0), (2900, 180, 0.7), (250, 60, 0.3)])
    am = 1 - 0.6 * (0.5 + 0.5 * trem)
    return finalizar(voz * am * envelope(t, 0.03, 0.2, dur), -3)


def zurro(rng, dur, f0s, form, ruido, aspereza):
    t = tempo(dur)
    f0 = curva(t, [(dur * i / (len(f0s) - 1), v) for i, v in enumerate(f0s)])
    fonte = harmonicos(f0, 0.8) * (1 + aspereza * np.sin(2 * np.pi * f0 / 2 * t))   # sub-harmônico rouco
    fonte += ruido * rng.standard_normal(len(t))
    return formantes(fonte, form) * envelope(t, 0.025, 0.06, dur)


def burro(rng):
    x = np.zeros(int(1.2 * SR))
    hi = [(380, 120, 0.8), (2200, 220, 1.0), (3000, 300, 0.4)]   # "ii" agudo, puxando o ar
    ho = [(700, 160, 1.0), (1050, 180, 0.8), (2500, 300, 0.25)]  # "ó" grave, soltando o ar
    for k, ini in enumerate((0.02, 0.60)):
        colocar(x, 3.0 * zurro(rng, 0.24, [620, 820, 760], hi, 0.45, 0.4) * (1 - 0.1 * k), ini)
        colocar(x, 1.2 * zurro(rng, 0.30, [230, 210, 170], ho, 0.35, 0.7) * (1 - 0.1 * k), ini + 0.26)
    return finalizar(x, -3)


def pio(rng, dur, f0s):
    t = tempo(dur)
    f0 = curva(t, [(dur * i / (len(f0s) - 1), v) for i, v in enumerate(f0s)])
    fase = 2 * np.pi * np.cumsum(f0) / SR
    s = np.sin(fase) + 0.12 * np.sin(2 * fase) + 0.04 * np.sin(3 * fase)
    sopro = ressonador(rng.standard_normal(len(t)), f0, 80, 0.4)
    env = envelope(t, 0.06, 0.14, dur) ** 1.5
    return (s + sopro) * env


def coruja(rng):
    x = np.zeros(int(1.05 * SR))
    colocar(x, pio(rng, 0.26, [355, 370, 340]), 0.04)
    colocar(x, pio(rng, 0.42, [365, 380, 350, 320]), 0.48)
    return finalizar(x, -3)


def grito_gaivota(rng, escala):
    dur = 0.24
    t = tempo(dur)
    f0 = curva(t, [(0, 1050), (0.04, 1500), (0.09, 1350), (dur, 780)]) * escala
    fonte = harmonicos(f0, 0.9) * (1 + 0.3 * np.sin(2 * np.pi * 70 * t))
    fonte += 0.2 * rng.standard_normal(len(t))
    voz = formantes(fonte, [(1900 * escala, 450, 1.0), (3300, 600, 0.6)])
    return voz * envelope(t, 0.012, 0.07, dur)


def gaivota(rng):
    x = np.zeros(int(1.05 * SR))
    for i, (ini, esc, vol) in enumerate([(0.02, 1.0, 1.0), (0.34, 0.95, 0.9), (0.66, 0.88, 0.75)]):
        colocar(x, vol * grito_gaivota(rng, esc), ini)
    return finalizar(x, -3)


def estalo(rng, fc, dur=0.004):
    t = tempo(dur * 4)
    burst = rng.standard_normal(len(t)) * np.exp(-t / (dur / 3))
    return ressonador(burst, fc, fc * 0.35) + 0.4 * ressonador(burst, fc * 0.35, 300)


def caranguejo(rng):
    x = np.zeros(int(0.72 * SR))
    # pinças batendo: grupos de estalos secos, o segundo de cada par mais grave
    for ini in (0.02, 0.07, 0.11, 0.26, 0.29, 0.42, 0.46, 0.49, 0.53, 0.64):
        vol = rng.uniform(0.55, 1.0)
        colocar(x, vol * estalo(rng, rng.uniform(3200, 4200)), ini)
        colocar(x, 0.6 * vol * estalo(rng, rng.uniform(1800, 2400), 0.003), ini + 0.012)
    return finalizar(x, -3, entrada=0.002, saida=0.02)


# ---------- fogueira (loop de 4 s) ----------

def filtro_circular(x, ganho_por_freq):
    """Filtra pela FFT: o resultado é periódico, então o loop emenda sem costura."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    return np.fft.irfft(X * ganho_por_freq(f), len(x))


def fogueira(rng):
    n = 4 * SR
    t = np.arange(n) / SR
    # chiado de fundo: ruído grave e um sopro agudo bem baixo, que respiram devagar
    grave = filtro_circular(rng.standard_normal(n), lambda f: 1 / (1 + (f / 350) ** 2) / np.sqrt(1 + f / 40))
    sopro = filtro_circular(rng.standard_normal(n), lambda f: np.exp(-((f - 3500) / 1800) ** 2))
    resp = 1 + 0.3 * np.sin(2 * np.pi * t / 4) + 0.2 * np.sin(2 * np.pi * 3 * t / 4 + 1.3)  # inteiro em 4 s
    fundo = (grave / np.std(grave) * 0.10 + sopro / np.std(sopro) * 0.025) * resp
    # estalos: muitos pequenos e brilhantes, alguns maiores e mais graves (pipocos)
    est = np.zeros(n)
    for _ in range(90):
        i = rng.integers(n)
        dur = rng.uniform(0.0004, 0.0025)
        m = int(dur * 6 * SR)
        k = np.arange(m) / SR
        burst = rng.standard_normal(m) * np.exp(-k / dur) * rng.uniform(0.2, 1.0) ** 2
        idx = (i + np.arange(m)) % n                 # dá a volta no fim: loop sem emenda
        est[idx] += burst
    est = filtro_circular(est, lambda f: np.clip(f / 1500, 0, 1) * np.exp(-((f - 3000) / 4000) ** 2))
    pip = np.zeros(n)
    for _ in range(9):
        i = rng.integers(n)
        dur = rng.uniform(0.003, 0.008)
        m = int(dur * 6 * SR)
        k = np.arange(m) / SR
        pip[(i + np.arange(m)) % n] += rng.standard_normal(m) * np.exp(-k / dur) * rng.uniform(0.5, 1.0)
    pip = filtro_circular(pip, lambda f: np.exp(-((f - 700) / 600) ** 2))
    x = fundo + est / np.max(np.abs(est)) * 0.9 + pip / np.max(np.abs(pip)) * 0.6
    x = x - np.mean(x)
    return x * (10 ** (-12 / 20) / np.max(np.abs(x)))   # sem fades: é loop


SONS = {
    'cao': cao, 'ovelha': ovelha, 'cabra': cabra, 'burro': burro,
    'coruja': coruja, 'gaivota': gaivota, 'caranguejo': caranguejo,
}

if __name__ == '__main__':
    for i, (nome, gerar) in enumerate(SONS.items()):
        salvar(f'{PASTA_ANIMAIS}/{nome}.wav', gerar(np.random.default_rng(100 + i)))
    salvar(f'{PASTA_SFX}/fogueira.wav', fogueira(np.random.default_rng(7)))
