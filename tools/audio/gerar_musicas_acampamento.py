# Gera as músicas provisórias dos acampamentos: um loop calmo por acampamento,
# cada um com escala/modo, andamento, timbre e textura próprios.
# Tudo sintetizado (aditiva + ruído filtrado), mono, 16 bits, 22050 Hz, ~-6 dBFS.
# O loop emenda sem costura: a peça é escrita em compassos inteiros, o que soa
# depois do fim (caudas de notas, reverb) volta para o começo, e as camadas
# contínuas (ruído, drone) são periódicas no tamanho exato do loop.
# Semente fixa: rodar de novo gera os mesmos arquivos.
# São só marcadores para testar até vir a música de verdade.
# Uso: python3 tools/audio/gerar_musicas_acampamento.py   (rodar na raiz do projeto)
import os
import sys
import wave

import numpy as np

sys.dont_write_bytecode = True

SR = 22050
PASTA = 'assets/audio/music/acampamentos'
PICO_DBFS = -6.0

MODOS = {
    'jonio':      [0, 2, 4, 5, 7, 9, 11],
    'dorico':     [0, 2, 3, 5, 7, 9, 10],
    'frigio':     [0, 1, 3, 5, 7, 8, 10],
    'lidio':      [0, 2, 4, 6, 7, 9, 11],
    'mixolidio':  [0, 2, 4, 5, 7, 9, 10],
    'eolio':      [0, 2, 3, 5, 7, 8, 10],
    'menor_harm': [0, 2, 3, 5, 7, 8, 11],
    'penta_maior': [0, 2, 4, 7, 9],
}


# ---------- teoria ----------

def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def grau(raiz, modo, g):
    """MIDI do grau g (0 = tônica; passa da oitava sozinho) no modo."""
    passos = MODOS[modo]
    o, i = divmod(g, len(passos))
    return raiz + 12 * o + passos[i]


def acorde(raiz, modo, g, extras=(0, 2, 4)):
    return [grau(raiz, modo, g + e) for e in extras]


def classes(notas):
    return {n % 12 for n in notas}


def escala_faixa(raiz, modo, lo, hi):
    passos = MODOS[modo]
    return [m for m in range(lo, hi + 1) if (m - raiz) % 12 in passos]


# ---------- blocos básicos ----------

def tempo(dur):
    return np.arange(int(round(dur * SR))) / SR


def filtro_fft(x, ganho_por_freq):
    """Filtra pela FFT (circular): com x periódico, o resultado também é."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    return np.fft.irfft(X * ganho_por_freq(f), len(x))


def bordas(x, ataque, soltura):
    n = len(x)
    a, s = min(int(ataque * SR), n), min(int(soltura * SR), n)
    if a: x[:a] *= np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    if s: x[-s:] *= np.cos(np.linspace(0, np.pi / 2, s)) ** 2
    return x


def normal(x):
    m = np.max(np.abs(x))
    return x / m if m > 0 else x


# ---------- instrumentos ----------

def pincado(f, dur, brilho=0.5, tau=1.2, pos=0.18, inarm=0.0, amort=0.35, rng=None):
    """Corda pinçada por síntese aditiva: cada harmônico decai mais rápido que o anterior.
    brilho 0..1 (lira escura → aço), pos = ponto onde a corda é tocada, inarm = rigidez."""
    t = tempo(dur)
    x = np.zeros_like(t)
    fase0 = rng.uniform(0, 2 * np.pi, 40) if rng is not None else np.zeros(40)
    for k in range(1, 40):
        fk = k * f * np.sqrt(1 + inarm * k * k)
        if fk > 8500:
            break
        a = (abs(np.sin(np.pi * k * pos)) + 0.05) / k ** (1.7 - brilho)
        tk = tau / (1 + amort * (k - 1))
        x += a * np.sin(2 * np.pi * fk * t + fase0[k]) * np.exp(-t / tk)
    if rng is not None:                                    # o “toque” da unha/plectro
        ruido = rng.standard_normal(len(t)) * np.exp(-t / 0.004) * 0.15 * brilho
        x += filtro_fft(ruido, lambda fr: np.exp(-((fr - 3 * f) / (4 * f)) ** 2))
    return bordas(normal(x), 0.002, 0.05)


def sino(f, dur, parciais, rng=None):
    """Sino/vidro: parciais inarmônicos (razão, amplitude, decaimento em s)."""
    t = tempo(dur)
    x = np.zeros_like(t)
    for (r, a, tau) in parciais:
        fr = f * r
        if fr > 9500:
            continue
        ph = rng.uniform(0, 2 * np.pi) if rng is not None else 0.0
        x += a * np.sin(2 * np.pi * fr * t + ph) * np.exp(-t / tau)
    return bordas(normal(x), 0.003, 0.08)


SINO_FRIO = [(1.0, 1.0, 4.5), (2.0, 0.35, 3.0), (2.76, 0.45, 2.2), (4.07, 0.2, 1.4),
             (5.40, 0.18, 0.9), (8.93, 0.06, 0.5)]
SINO_ALTO = [(1.0, 1.0, 3.5), (2.0, 0.25, 2.5), (2.76, 0.3, 1.8), (5.40, 0.15, 0.8)]
CAIXINHA = [(1.0, 1.0, 1.6), (2.0, 0.08, 0.9), (4.2, 0.22, 0.35), (9.8, 0.08, 0.12)]


def flauta(f, dur, rng, vib=0.004, sopro=0.05):
    t = tempo(dur)
    vibrato = 1 + vib * np.sin(2 * np.pi * 5.0 * t + rng.uniform(0, 6)) * np.clip((t - 0.3) / 0.5, 0, 1)
    fase = 2 * np.pi * np.cumsum(f * vibrato) / SR
    x = np.sin(fase) + 0.22 * np.sin(2 * fase) + 0.09 * np.sin(3 * fase) + 0.03 * np.sin(4 * fase)
    ar = filtro_fft(rng.standard_normal(len(t)), lambda fr: np.exp(-((fr - 2 * f) / (2.5 * f)) ** 2))
    x = x + sopro * normal(ar) * (1 + 2 * np.exp(-t / 0.06))
    x *= 1 + 0.06 * np.sin(2 * np.pi * 0.7 * t)          # o fôlego oscila um pouco
    return bordas(x / 1.3, min(0.09, dur / 3), min(0.3, dur / 2))


def palheta(f, dur, rng):
    """Clarinete grave: harmônicos ímpares, escurecido."""
    t = tempo(dur)
    vibrato = 1 + 0.002 * np.sin(2 * np.pi * 4.3 * t) * np.clip((t - 0.5) / 0.8, 0, 1)
    fase = 2 * np.pi * np.cumsum(f * vibrato) / SR
    x = np.zeros_like(t)
    for k in range(1, 16):
        if k * f > 5000:
            break
        a = (1.0 / k if k % 2 else 0.08 / k) * np.exp(-k * f / 1400)
        x += a * np.sin(k * fase)
    brilho = np.clip(t / 0.25, 0, 1)                       # abre devagar, como sopro
    x = x * (0.85 + 0.15 * brilho)
    ar = filtro_fft(rng.standard_normal(len(t)), lambda fr: np.exp(-((fr - 3 * f) / (3 * f)) ** 2))
    x = normal(x) + 0.025 * normal(ar)
    return bordas(x, min(0.15, dur / 3), min(0.4, dur / 2))


def pad(freqs, dur, ataque, soltura, harm=6, desafino=6, incl=1.8, rng=None):
    """Colchão: cada nota vira três vozes levemente desafinadas, harmônicos suaves."""
    t = tempo(dur)
    x = np.zeros_like(t)
    for f in freqs:
        for d in (-desafino, 0, desafino):
            fv = f * 2 ** (d / 1200)
            for k in range(1, harm + 1):
                if k * fv > 6000:
                    break
                ph = rng.uniform(0, 2 * np.pi) if rng is not None else 0.0
                x += np.sin(2 * np.pi * k * fv * t + ph) / k ** incl
    return bordas(normal(x), ataque, soltura)


def tambor(dur=0.6, f0=110, f1=60, tau=0.18, estalo=0.3, rng=None):
    """Tambor de moldura: grave com queda de altura + estalo de pele."""
    t = tempo(dur)
    f = f1 + (f0 - f1) * np.exp(-t / 0.04)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / tau)
    if rng is not None and estalo:
        ruido = rng.standard_normal(len(t)) * np.exp(-t / 0.012)
        x += estalo * normal(filtro_fft(ruido, lambda fr: np.exp(-((fr - 900) / 900) ** 2)))
    return bordas(normal(x), 0.001, 0.05)


def coracao(rng):
    """Batida dupla, bem grave (tum-tum)."""
    x = np.zeros(int(0.9 * SR))
    a = tambor(0.5, 62, 42, 0.11, 0.0)
    b = tambor(0.5, 58, 40, 0.09, 0.0) * 0.65
    x[:len(a)] += a
    i = int(0.27 * SR)
    x[i:i + len(b)] += b[:len(x) - i]
    return x


def ruido_periodico(n, rng, ganho_por_freq):
    return normal(filtro_fft(rng.standard_normal(n), ganho_por_freq))


def onda_lenta(n, ciclos, fase=0.0):
    """0..1, periódica no loop: 'ciclos' voltas inteiras em n amostras."""
    t = np.arange(n) / n
    return 0.5 - 0.5 * np.cos(2 * np.pi * ciclos * t + fase)


def drone(n, freqs, mod_ciclos=3, rng=None):
    """Tons contínuos ajustados para dar ciclos inteiros no loop (emenda perfeita)."""
    dur = n / SR
    t = np.arange(n) / SR
    x = np.zeros(n)
    for i, (f, a) in enumerate(freqs):
        f = round(f * dur) / dur
        ph = rng.uniform(0, 2 * np.pi) if rng is not None else 0.0
        mod = 0.75 + 0.25 * onda_lenta(n, mod_ciclos + i, ph)
        x += a * np.sin(2 * np.pi * f * t + ph) * mod
    return x


# ---------- reverb (pente + passa-tudo, aplicada como convolução circular) ----------

def _pente(x, d, g):
    y = x.copy()
    for i in range(d, len(y), d):
        seg = y[i:i + d]
        seg += g * y[i - d:i - d + len(seg)]
    return y


def _passa_tudo(x, d, g):
    y = np.empty_like(x)
    y[:d] = -g * x[:d]
    for i in range(d, len(x), d):
        m = len(x[i:i + d])
        y[i:i + m] = -g * x[i:i + m] + x[i - d:i - d + m] + g * y[i - d:i - d + m]
    return y


def resposta_reverb(t60=2.5, escala=1.0, escuro=3500):
    """Reverb de Schroeder (4 pentes em paralelo + 2 passa-tudo), tirada como resposta
    ao impulso. Depois é aplicada por convolução circular: a cauda do fim cai no começo."""
    n = int((t60 + 0.5) * SR)
    imp = np.zeros(n)
    imp[0] = 1.0
    atrasos = [int(d * escala) for d in (743, 827, 911, 997)]
    y = np.zeros(n)
    for d in atrasos:
        g = 10 ** (-3 * d / (t60 * SR))
        y += _pente(imp, d, g)
    for d in (113, 37):
        y = _passa_tudo(y, int(d * escala) or 1, 0.6)
    t = np.arange(n) / SR
    agudos = filtro_fft(y, lambda f: f / np.sqrt(f * f + escuro ** 2))   # agudos morrem antes
    y = filtro_fft(y, lambda f: 1 / np.sqrt(1 + (f / escuro) ** 2)) + agudos * np.exp(-t / 0.35) * 0.3
    y[:int(0.012 * SR)] = 0                                # pré-atraso
    y *= np.clip((n / SR - t) / 0.5, 0, 1)
    return y / np.sqrt(np.sum(y * y))


def reverb_circular(x, ir):
    h = np.zeros(len(x))
    h[:len(ir)] = ir
    return np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(h), len(x))


# ---------- montagem ----------

class Loop:
    def __init__(self, bpm, tempos, compassos, rng):
        self.spb = 60.0 / bpm
        self.tempos = tempos
        self.compassos = compassos
        self.n = int(round(compassos * tempos * self.spb * SR))
        self.x = np.zeros(self.n)
        self.rng = rng

    def t(self, compasso, batida=0.0, solto=0.0):
        """Tempo em s do compasso/batida, com um pouco de folga humana (solto, em s)."""
        j = self.rng.uniform(-solto, solto) if solto else 0.0
        return (compasso * self.tempos + batida) * self.spb + j

    def por(self, som, t, ganho):
        """Soma 'som' a partir de t; o que passa do fim dá a volta para o começo."""
        pos = int(round(t * SR)) % self.n
        som = som * ganho
        while len(som):
            m = min(len(som), self.n - pos)
            self.x[pos:pos + m] += som[:m]
            som = som[m:]
            pos = 0

    def camada(self, sinal, ganho):
        self.x += sinal * ganho

    def fechar(self, ir, molhado):
        x = self.x - np.mean(self.x)
        wet = reverb_circular(x, ir)
        y = x + molhado * wet * (np.max(np.abs(x)) / max(np.max(np.abs(wet)), 1e-9))
        y = y - np.mean(y)
        return y * (10 ** (PICO_DBFS / 20) / np.max(np.abs(y)))


def frase(rng, escala, acordes_pcs, ritmos, atual, fortes=(0, 2)):
    """Melodia de um trecho: tempo forte cai em nota do acorde perto da anterior,
    o resto anda por grau conjunto. Devolve [(compasso, batida, dur, midi)], última nota."""
    notas = []
    for c, pcs in enumerate(acordes_pcs):
        for (b, d) in ritmos[rng.integers(len(ritmos))]:
            if b in fortes:
                cands = sorted((m for m in escala if m % 12 in pcs), key=lambda m: abs(m - atual))
                if not cands:
                    cands = [atual]
                atual = cands[0] if rng.random() < 0.65 or len(cands) == 1 else cands[1]
            else:
                i = escala.index(min(escala, key=lambda m: abs(m - atual)))
                i = int(np.clip(i + rng.choice([-2, -1, -1, 1, 1, 2]), 0, len(escala) - 1))
                atual = escala[i]
            notas.append((c, b, d, atual))
    return notas, atual


def tocar_frase(lp, notas, compasso0, instrumento, ganho, solto=0.012):
    for (c, b, d, m) in notas:
        v = ganho * lp.rng.uniform(0.85, 1.0)
        lp.por(instrumento(hz(m), d * lp.spb), lp.t(compasso0 + c, b, solto), v)


def seq_melodia(rng, escala, prog_pcs, ritmos, inicio, plano, fortes=(0, 2)):
    """plano: lista de letras por bloco de 4 compassos (ex. 'AABA'); A repete igual."""
    feitas = {}
    saida = []
    atual = inicio
    for bloco, letra in enumerate(plano):
        trecho = prog_pcs[bloco * 4:(bloco + 1) * 4]
        if letra in feitas:
            notas = feitas[letra]
        else:
            notas, atual = frase(rng, escala, trecho, ritmos, atual, fortes)
            feitas[letra] = notas
        saida += [(bloco * 4 + c, b, d, m) for (c, b, d, m) in notas]
    return saida


# ---------- as peças ----------

def oa_acampamento(rng):
    """Campina à beira do rio: harpa em pentatônica maior, flauta leve, 84 bpm."""
    raiz, modo = 62, 'jonio'                               # Ré maior
    lp = Loop(84, 4, 16, rng)
    prog = [0, 3, 0, 4, 5, 3, 0, 4, 0, 3, 0, 4, 5, 3, 4, 4]
    harpa = lambda f, d: pincado(f, 3.2, brilho=0.45, tau=1.4, pos=0.3, rng=rng)
    for c, g in enumerate(prog):
        ac = acorde(raiz - 12, modo, g, (0, 4, 7, 9, 11))   # arpejo aberto, sobe e desce
        ordem = [0, 1, 2, 3, 4, 3, 2, 1]
        for i, k in enumerate(ordem):
            lp.por(harpa(hz(ac[k]), 0), lp.t(c, i * 0.5, 0.006), 0.32 if i else 0.42)
        lp.por(pincado(hz(grau(raiz - 24, modo, g)), 4.0, 0.25, 2.0, 0.25, rng=rng), lp.t(c), 0.45)
    escala = escala_faixa(raiz, 'penta_maior', 69, 88)
    ritmos = [[(0, 1.5), (1.5, 0.5), (2, 2)], [(0, 2), (2, 1), (3, 1)],
              [(0, 1), (1, 1), (2, 2)], [(0, 3), (3, 1)], [(0, 4)]]
    pcs = [classes(acorde(raiz, modo, g)) for g in prog]
    mel = seq_melodia(rng, escala, pcs, ritmos, 74, 'ABAB')
    tocar_frase(lp, mel, 0, lambda f, d: flauta(f, d * 0.95 + 0.1, rng), 0.42)
    return lp.fechar(resposta_reverb(2.2, 1.0, 4000), 0.45)


def ot_acampamento(rng):
    """Mata costeira perto das falésias: dórico, cordas pinçadas suaves, colchão que vem e vai
    como onda (a cada 2 compassos), 72 bpm."""
    raiz, modo = 52, 'dorico'                              # Mi dórico
    lp = Loop(72, 4, 16, rng)
    prog = [0, 3, 0, 3, 6, 3, 4, 0, 0, 3, 0, 3, 2, 6, 3, 3]
    for c, g in enumerate(prog):
        ac = acorde(raiz, modo, g, (0, 4, 7, 9))
        for i, k in enumerate([0, 1, 2, 3, 2, 1, 2, 1]):
            lp.por(pincado(hz(ac[k]), 3.0, 0.3, 1.5, 0.22, rng=rng), lp.t(c, i * 0.5, 0.01),
                   0.30 if i else 0.38)
        lp.por(pincado(hz(grau(raiz - 12, modo, g)), 4.0, 0.2, 2.2, 0.2, rng=rng), lp.t(c), 0.38)
    for c in range(0, 16, 2):                              # o colchão incha como onda
        freqs = [hz(m) for m in acorde(raiz + 12, modo, prog[c], (0, 2, 4, 6))]
        lp.por(pad(freqs, 2 * 4 * lp.spb + 1.5, 3.2, 3.0, 5, 7, 2.0, rng), lp.t(c), 0.30)
    escala = escala_faixa(raiz, modo, 71, 88)
    ritmos = [[(0, 2), (2, 2)], [(0, 3), (3, 1)], [(0, 4)], [(1, 1), (2, 2)]]
    pcs = [classes(acorde(raiz, modo, g)) for g in prog]
    mel = seq_melodia(rng, escala, pcs, ritmos, 76, 'ABAB')
    tocar_frase(lp, mel, 0, lambda f, d: pincado(f, 3.5, 0.5, 1.8, 0.15, rng=rng), 0.38)
    n = lp.n
    mar = ruido_periodico(n, rng, lambda f: 1 / (1 + (f / 500) ** 2) * np.clip(f / 60, 0, 1))
    lp.camada(mar * (0.15 + 0.85 * onda_lenta(n, 8) ** 2), 0.07)
    return lp.fechar(resposta_reverb(2.6, 1.1, 3000), 0.5)


def og_acampamento(rng):
    """Colinas geladas: eólio, sinos/vidro de cauda longa, poucas notas, 54 bpm."""
    raiz, modo = 57, 'eolio'                               # Lá eólio
    lp = Loop(54, 4, 12, rng)
    prog = [0, 0, 5, 5, 3, 3, 4, 4, 0, 0, 5, 6]
    for c in range(0, 12, 2):                              # pad frio e fino, quase só senos
        freqs = [hz(m) for m in acorde(raiz, modo, prog[c], (0, 4, 9))]
        lp.por(pad(freqs, 2 * 4 * lp.spb + 3, 4.0, 4.0, 2, 4, 2.5, rng), lp.t(c), 0.22)
        lp.por(sino(hz(grau(raiz - 24, modo, prog[c])), 9.0, [(1, 1, 5), (2, 0.2, 3)], rng),
               lp.t(c), 0.35)
    escala = escala_faixa(raiz, modo, 76, 93)
    pcs = [classes(acorde(raiz, modo, g)) for g in prog]
    ritmos = [[(0, 4)], [(0, 2), (2.5, 1.5)], [(1, 3)], [(0, 3), (3, 1)], []]
    mel = seq_melodia(rng, escala, pcs, ritmos, 81, 'ABC')
    tocar_frase(lp, mel, 0, lambda f, d: sino(f, 7.0, SINO_FRIO, rng), 0.42, 0.02)
    for c in (1, 5, 9):                                    # brilho de vidro, bem alto e baixinho
        m = grau(raiz + 24, modo, prog[c] + 4)
        lp.por(sino(hz(m), 5.0, SINO_ALTO, rng), lp.t(c, 3.5), 0.12)
    n = lp.n
    vento = ruido_periodico(n, rng, lambda f: np.exp(-((f - 2500) / 1500) ** 2))
    lp.camada(vento * (0.2 + 0.8 * onda_lenta(n, 3)), 0.025)
    return lp.fechar(resposta_reverb(3.5, 1.3, 3500), 0.7)


def ag_acampamento(rng):
    """Vinhedos à beira do rio (Ágape): mixolídio, alaúde dedilhado + tambor de moldura, 96 bpm."""
    raiz, modo = 55, 'mixolidio'                           # Sol mixolídio
    lp = Loop(96, 4, 20, rng)
    prog = [0, 6, 0, 3, 0, 6, 3, 0, 3, 3, 0, 6, 4, 3, 6, 0, 0, 6, 3, 4]
    alaude = lambda f: pincado(f, 2.2, 0.55, 0.9, 0.12, rng=rng)
    batidas = [(0, 1.0, 1), (1.5, 0.55, -1), (2, 0.8, 1), (3, 0.7, 1), (3.5, 0.5, -1)]
    for c, g in enumerate(prog):
        ac = acorde(raiz, modo, g, (0, 2, 4, 7))
        for (b, v, sentido) in batidas:                   # dedilhado: cordas entram em sequência
            ordem = ac if sentido > 0 else ac[::-1]
            t0 = lp.t(c, b, 0.008)
            for j, m in enumerate(ordem):
                lp.por(alaude(hz(m)), t0 + j * 0.018, 0.17 * v)
        lp.por(pincado(hz(grau(raiz - 12, modo, g)), 2.5, 0.3, 1.2, 0.2, rng=rng), lp.t(c), 0.32)
        lp.por(tambor(0.6, 105, 62, 0.2, 0.15, rng), lp.t(c, 0, 0.004), 0.40)      # dum
        lp.por(tambor(0.3, 300, 240, 0.05, 0.9, rng), lp.t(c, 1.5, 0.004), 0.16)   # tek
        lp.por(tambor(0.6, 100, 60, 0.18, 0.15, rng), lp.t(c, 2, 0.004), 0.30)
        lp.por(tambor(0.3, 300, 240, 0.05, 0.9, rng), lp.t(c, 3, 0.004), 0.13)
        lp.por(tambor(0.3, 300, 240, 0.05, 0.9, rng), lp.t(c, 3.5, 0.004), 0.10)
    escala = escala_faixa(raiz, modo, 67, 86)
    ritmos = [[(0, 1), (1, 0.5), (1.5, 0.5), (2, 2)], [(0, 2), (2, 1), (3, 1)],
              [(0, 1.5), (1.5, 0.5), (2, 1), (3, 1)], [(0, 3), (3, 1)]]
    pcs = [classes(acorde(raiz, modo, g)) for g in prog]
    mel = seq_melodia(rng, escala, pcs, ritmos, 74, 'ABACA')
    tocar_frase(lp, mel, 0, lambda f, d: flauta(f, d * 0.9 + 0.08, rng, 0.005, 0.07), 0.36)
    return lp.fechar(resposta_reverb(1.8, 0.9, 4500), 0.35)


def an_acampamento(rng):
    """Passo de montanha nevado: drone grave, vento (ruído filtrado), um sino de vez em quando,
    sabor frígio (o meio-tom acima da tônica). Quase sem pulso, 50 bpm."""
    raiz = 40                                              # Mi
    lp = Loop(50, 4, 10, rng)
    n = lp.n
    lp.camada(drone(n, [(hz(raiz), 1.0), (hz(raiz + 7), 0.45), (hz(raiz + 12), 0.3),
                        (hz(raiz + 19), 0.08)], 2, rng), 0.5)
    for c in (3, 8):                                       # sombra frígia: Fá por cima do Mi
        lp.por(pad([hz(raiz + 13), hz(raiz + 20)], 4 * lp.spb * 1.5, 3.0, 3.5, 3, 5, 2.2, rng),
               lp.t(c, 1), 0.28)
    grave = ruido_periodico(n, rng, lambda f: np.exp(-((f - 400) / 300) ** 2))
    agudo = ruido_periodico(n, rng, lambda f: np.exp(-((f - 1400) / 700) ** 2))
    rajada = onda_lenta(n, 4, 0.7) ** 1.5
    lp.camada(grave * (0.3 + 0.7 * onda_lenta(n, 3)) * 0.6 + agudo * rajada * 0.5, 0.22)
    sinos = [(1, 0, 76), (2, 2.5, 77), (4, 1, 83), (6, 0, 76), (7, 3, 79), (9, 1.5, 77)]
    for (c, b, m) in sinos:
        lp.por(sino(hz(m), 8.0, SINO_FRIO, rng), lp.t(c, b, 0.05), 0.22)
    return lp.fechar(resposta_reverb(4.0, 1.4, 3000), 0.8)


def nt_acampamento(rng):
    """Pinheiral nevado: canção de ninar de caixinha de música/celesta, menor, 3/4 lento."""
    raiz, modo = 59, 'menor_harm'                          # Si menor
    lp = Loop(66, 3, 16, rng)
    prog = [0, 3, 4, 0, 5, 3, 4, 4, 0, 3, 4, 0, 5, 3, 4, 0]
    caixa = lambda f: sino(f, 3.0, CAIXINHA, rng)
    for c, g in enumerate(prog):
        ac = acorde(raiz - 12, 'eolio' if g != 4 else modo, g)
        lp.por(caixa(hz(ac[0])), lp.t(c, 0, 0.01), 0.30)
        lp.por(caixa(hz(ac[1] + 12)), lp.t(c, 1, 0.01), 0.16)
        lp.por(caixa(hz(ac[2] + 12)), lp.t(c, 2, 0.01), 0.16)
    for c in range(0, 16, 4):                              # colchão quase inaudível de cordas
        freqs = [hz(grau(raiz - 12, 'eolio', prog[c]))]
        lp.por(pad(freqs, 4 * 3 * lp.spb + 2, 2.5, 3.0, 3, 5, 2.0, rng), lp.t(c), 0.18)
    escala = escala_faixa(raiz, modo, 71, 90)
    ritmos = [[(0, 2), (2, 1)], [(0, 1), (1, 1), (2, 1)], [(0, 3)], [(0, 1.5), (1.5, 0.5), (2, 1)]]
    pcs = [classes(acorde(raiz, 'eolio' if g != 4 else modo, g)) for g in prog]
    mel = seq_melodia(rng, escala, pcs, ritmos, 78, 'ABAC', fortes=(0,))
    tocar_frase(lp, mel, 0, lambda f, d: caixa(f), 0.42, 0.008)
    return lp.fechar(resposta_reverb(2.4, 1.0, 5000), 0.45)


def at_acampamento(rng):
    """Floresta escura: clarinete grave em menor harmônico, pulso de coração, 60 bpm."""
    raiz, modo = 50, 'menor_harm'                          # Ré menor harmônico
    lp = Loop(60, 4, 12, rng)
    prog = [0, 0, 5, 4, 0, 3, 5, 4, 0, 5, 3, 4]
    for c in range(12):
        lp.por(coracao(rng), lp.t(c, 0, 0.005), 0.55)
        lp.por(coracao(rng), lp.t(c, 2, 0.005), 0.40)
    for c in range(0, 12, 2):
        freqs = [hz(m) for m in acorde(raiz - 12, modo, prog[c], (0, 4))]
        freqs += [hz(m) for m in acorde(raiz, modo, prog[c + 1], (2,))]
        lp.por(pad(freqs, 2 * 4 * lp.spb + 2, 3.0, 3.0, 4, 8, 2.2, rng), lp.t(c), 0.30)
    escala = escala_faixa(raiz, modo, 57, 74)
    ritmos = [[(0, 3), (3, 1)], [(0, 4)], [(0, 2), (2, 2)], [(1, 3)], [(0, 1.5), (1.5, 2.5)]]
    pcs = [classes(acorde(raiz, modo, g)) for g in prog]
    mel = seq_melodia(rng, escala, pcs, ritmos, 62, 'ABC')
    tocar_frase(lp, mel, 0, lambda f, d: palheta(f, d * 0.95 + 0.25, rng), 0.40, 0.02)
    for (c, b) in ((2, 3), (7, 1.5), (10, 3)):              # um brilho estranho no escuro
        lp.por(sino(hz(grau(raiz + 24, modo, 6)), 5.0, SINO_ALTO, rng), lp.t(c, b), 0.09)
    n = lp.n
    folhas = ruido_periodico(n, rng, lambda f: np.exp(-((f - 900) / 600) ** 2))
    lp.camada(folhas * (0.3 + 0.7 * onda_lenta(n, 5)), 0.02)
    return lp.fechar(resposta_reverb(3.2, 1.2, 2500), 0.6)


def ilha_acampamento(rng):
    """Praia da ilha: jônio, arpejos de corda de aço brilhantes, mar respirando, 88 bpm."""
    raiz, modo = 57, 'jonio'                               # Lá maior
    lp = Loop(88, 4, 20, rng)
    prog = [0, 4, 5, 3, 0, 4, 3, 4, 5, 3, 0, 4, 5, 3, 1, 4, 0, 4, 3, 4]
    aco = lambda f: pincado(f, 3.0, 0.8, 1.6, 0.13, 1.5e-4, 0.25, rng)
    for c, g in enumerate(prog):
        ac = acorde(raiz, modo, g, (0, 2, 4, 7, 9, 11))
        for i, k in enumerate([0, 2, 1, 3, 4, 3, 5, 3]):
            lp.por(aco(hz(ac[k])), lp.t(c, i * 0.5, 0.006), 0.22 if i % 2 else 0.27)
        lp.por(pincado(hz(grau(raiz - 12, modo, g)), 3.0, 0.4, 1.6, 0.2, rng=rng), lp.t(c), 0.35)
    for c in range(0, 20, 2):                              # ar: pad alto e leve
        freqs = [hz(m) for m in acorde(raiz + 12, modo, prog[c], (2, 4, 7))]
        lp.por(pad(freqs, 2 * 4 * lp.spb + 1.5, 2.0, 2.0, 2, 6, 2.5, rng), lp.t(c), 0.12)
    escala = escala_faixa(raiz, modo, 73, 93)
    ritmos = [[(0, 2), (2, 1), (3, 1)], [(0, 3), (3, 1)], [(0, 1), (1, 1), (2, 2)], [(0, 4)]]
    pcs = [classes(acorde(raiz, modo, g)) for g in prog]
    mel = seq_melodia(rng, escala, pcs, ritmos, 81, 'ABACB')
    tocar_frase(lp, mel, 0, lambda f, d: pincado(f, 3.5, 0.75, 2.0, 0.2, 1e-4, 0.2, rng), 0.36)
    n = lp.n
    mar = ruido_periodico(n, rng, lambda f: np.clip(f / 150, 0, 1) / (1 + (f / 1800) ** 2))
    espuma = ruido_periodico(n, rng, lambda f: np.exp(-((f - 4000) / 2500) ** 2))
    onda = onda_lenta(n, 10) ** 2
    lp.camada(mar * (0.1 + 0.9 * onda) + 0.4 * espuma * np.roll(onda, int(0.6 * SR)) ** 2, 0.10)
    return lp.fechar(resposta_reverb(2.0, 1.0, 5000), 0.35)


def ilhota_acampamento(rng):
    """Ilhota de pedra: eólio, flauta solitária e lenta sobre o drone do mar, 60 bpm."""
    raiz, modo = 54, 'eolio'                               # Fá# eólio
    lp = Loop(60, 4, 12, rng)
    n = lp.n
    prog = [0, 0, 5, 5, 3, 3, 4, 4, 0, 0, 5, 4]
    lp.camada(drone(n, [(hz(raiz - 12), 1.0), (hz(raiz - 5), 0.5), (hz(raiz), 0.25)], 2, rng), 0.35)
    for c in range(0, 12, 2):
        freqs = [hz(m) for m in acorde(raiz, modo, prog[c], (0, 2, 4))]
        lp.por(pad(freqs, 2 * 4 * lp.spb + 2.5, 3.5, 3.5, 3, 5, 2.4, rng), lp.t(c), 0.22)
    escala = escala_faixa(raiz, modo, 66, 83)
    ritmos = [[(0, 3)], [(0, 2), (2, 1.5)], [(1, 2.5)], [], [(0, 1.5), (1.5, 0.5), (2, 2)]]
    pcs = [classes(acorde(raiz, modo, g)) for g in prog]
    mel = seq_melodia(rng, escala, pcs, ritmos, 73, 'ABC')
    tocar_frase(lp, mel, 0, lambda f, d: flauta(f, d + 0.2, rng, 0.006, 0.08), 0.48, 0.03)
    mar = ruido_periodico(n, rng, lambda f: np.clip(f / 80, 0, 1) / (1 + (f / 700) ** 2))
    lp.camada(mar * (0.15 + 0.85 * onda_lenta(n, 6, 1.0) ** 2), 0.12)
    return lp.fechar(resposta_reverb(3.0, 1.2, 3500), 0.6)


PECAS = [oa_acampamento, ot_acampamento, og_acampamento, ag_acampamento, an_acampamento,
         nt_acampamento, at_acampamento, ilha_acampamento, ilhota_acampamento]


def salvar(caminho, x):
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    dados = np.clip(np.round(x * 32767), -32768, 32767).astype('<i2')
    with wave.open(caminho, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(dados.tobytes())
    emenda = abs(float(x[0]) - float(x[-1]))
    print(f'{caminho}  {len(x) / SR:.2f} s  pico {20 * np.log10(np.max(np.abs(x))):.1f} dBFS'
          f'  salto na emenda {emenda:.4f}')


if __name__ == '__main__':
    for i, peca in enumerate(PECAS):
        salvar(f'{PASTA}/{peca.__name__}.wav', peca(np.random.default_rng(300 + i)))
