"""Sons e ambientes do prólogo, feitos por código (originais, sem direitos de terceiros).

São provisórios: dão o clima de cada momento até existirem gravações. Cada
arquivo fica num lugar fixo, então trocar por uma gravação é só substituir.

Os laços são feitos para emendar sem estalo: os filtros trabalham no espectro
(o que é circular) e o que passa do fim volta para o começo.

Uso: python3 tools/audio/gerar_sons_prologo.py           (todos)
     python3 tools/audio/gerar_sons_prologo.py coracao   (só as batidas do coração)
(precisa de numpy e do ffmpeg com libvorbis)
"""

import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

TAXA = 44100
RAIZ = Path(__file__).resolve().parents[2]
AMBIENTE = RAIZ / "assets/audio/ambiente/prologo"
EFEITOS = RAIZ / "assets/audio/sfx/prologo"
rng = np.random.default_rng(20)


# ------------------------------------------------------------ ferramentas

def amostras(segundos: float) -> int:
    return int(round(segundos * TAXA))


def tempo(n: int) -> np.ndarray:
    return np.arange(n) / TAXA


def ruido(n: int) -> np.ndarray:
    return rng.standard_normal(n)


def espectro(x: np.ndarray, ganho) -> np.ndarray:
    """Filtra no espectro: ganho(freqs) devolve o ganho de cada frequência.
    O resultado é circular, então um laço continua emendando."""
    f = np.fft.rfftfreq(len(x), 1 / TAXA)
    return np.fft.irfft(np.fft.rfft(x) * ganho(f), len(x))


def faixa(x: np.ndarray, baixo: float, alto: float, suave: float = 1.5) -> np.ndarray:
    def ganho(f):
        f = np.maximum(f, 1.0)
        sobe = 1 / (1 + (baixo / f) ** (2 * suave)) if baixo > 0 else 1.0
        desce = 1 / (1 + (f / alto) ** (2 * suave))
        return sobe * desce
    return espectro(x, ganho)


def rosa(n: int) -> np.ndarray:
    return espectro(ruido(n), lambda f: 1 / np.sqrt(np.maximum(f, 20.0)))


def formantes(x: np.ndarray, picos: list[tuple[float, float, float]]) -> np.ndarray:
    """Ressonâncias (frequência, largura, ganho), como as da voz."""
    def ganho(f):
        g = np.zeros_like(f)
        for centro, largura, alt in picos:
            g += alt / (1 + ((f - centro) / (largura / 2)) ** 2)
        return g
    return espectro(x, ganho)


def eco(x: np.ndarray, duracao: float = 1.2, mistura: float = 0.25) -> np.ndarray:
    """Reverberação de sala por convolução circular com uma cauda de ruído."""
    n = len(x)
    cauda = np.zeros(n)
    m = min(n, amostras(duracao))
    cauda[:m] = ruido(m) * np.exp(-np.linspace(0, 7, m))
    cauda[0] = 0
    molhado = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(cauda), n)
    molhado *= np.std(x) / max(np.std(molhado), 1e-9)
    return x + mistura * molhado


def colocar(trilha: np.ndarray, som: np.ndarray, inicio: int, volume: float = 1.0) -> None:
    """Soma um som na trilha; o que passa do fim volta para o começo (laço)."""
    n = len(trilha)
    idx = (inicio + np.arange(len(som))) % n
    np.add.at(trilha, idx, som * volume)


def envelope(n: int, ataque: float, queda: float) -> np.ndarray:
    a = min(n, amostras(ataque))
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a) if a else 1
    e[a:] = np.exp(-np.arange(n - a) / max(1, amostras(queda)))
    return e


def oscilacao(n: int, ciclos: list[tuple[int, float]], base: float = 1.0) -> np.ndarray:
    """Soma de senos com número inteiro de ciclos no laço (emenda sem salto)."""
    fase = np.arange(n) / n * 2 * np.pi
    s = np.full(n, base)
    for k, amp in ciclos:
        s += amp * np.sin(k * fase + rng.uniform(0, 2 * np.pi))
    return s


def normalizar(x: np.ndarray, pico: float = 0.7) -> np.ndarray:
    return x * pico / max(np.max(np.abs(x)), 1e-9)


def salvar(x: np.ndarray, caminho: Path) -> None:
    caminho.parent.mkdir(parents=True, exist_ok=True)
    dados = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        with wave.open(tmp.name, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(TAXA)
            w.writeframes(dados.tobytes())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name, "-c:a", "libvorbis",
                        "-q:a", "5", str(caminho)], check=True)
    Path(tmp.name).unlink()
    print(caminho.relative_to(RAIZ), f"{len(x) / TAXA:.1f}s")


# ------------------------------------------------------------ vozes

VOGAIS = {  # formantes de voz feminina, um pouco abafados
    "a": [(850, 140, 1.0), (1500, 180, 0.5), (2800, 260, 0.2)],
    "e": [(550, 120, 1.0), (2100, 200, 0.45), (2900, 260, 0.2)],
    "o": [(550, 120, 1.0), (950, 150, 0.6), (2700, 260, 0.15)],
    "i": [(330, 100, 1.0), (2500, 220, 0.4), (3200, 280, 0.2)],
    "u": [(380, 100, 1.0), (850, 140, 0.4), (2600, 260, 0.1)],
}


def silaba(f0: float, dur: float, sonora: bool = True) -> np.ndarray:
    n = amostras(dur)
    if sonora:
        contorno = f0 * (1 + 0.08 * rng.uniform(-1, 1) * np.linspace(0, 1, n))
        fase = np.cumsum(contorno) / TAXA
        fonte = 2 * (fase % 1.0) - 1  # dente de serra: o pulso das cordas vocais
        fonte += 0.08 * ruido(n)
    else:
        fonte = ruido(n)
    vogal = VOGAIS[rng.choice(list(VOGAIS))]
    som = formantes(fonte, vogal)
    if not sonora:
        som += 0.35 * faixa(ruido(n), 4000, 8000)  # o "s" do sussurro
    return som * np.hanning(n)


def conversa(n: int, f0: float, rapidez: float, sonora: bool = True) -> np.ndarray:
    """Uma pessoa falando sem parar, em frases com pausas."""
    trilha = np.zeros(n)
    t = rng.uniform(0, 1.0)
    while t < n / TAXA:
        for _ in range(rng.integers(3, 9)):  # uma frase
            dur = rng.uniform(0.11, 0.24) / rapidez
            colocar(trilha, silaba(f0 * rng.uniform(0.9, 1.15), dur, sonora), amostras(t), rng.uniform(0.5, 1.0))
            t += dur * 0.8
        t += rng.uniform(0.3, 1.2) / rapidez
    return trilha


# ------------------------------------------------------------ ruídos de corpo e casa

def passo_de(chao: str, forca: float = 1.0) -> np.ndarray:
    """Pé descalço de criança: calcanhar e depois a planta, sem salto de sapato.
    Cada chamada sai diferente (altura, tempo entre as duas partes, arrasto)."""
    n = amostras(0.32)
    t = tempo(n)
    som = np.zeros(n)
    grave = rng.uniform(85, 125) if chao == "madeira" else rng.uniform(60, 85)
    for parte, (atraso, peso) in enumerate(((0.0, 1.0), (rng.uniform(0.045, 0.09), rng.uniform(0.4, 0.75)))):
        m = n - amostras(atraso)
        tt = tempo(m)
        if chao == "madeira":
            corpo = np.sin(2 * np.pi * grave * (1 + 0.15 * parte) * tt) * np.exp(-tt / rng.uniform(0.025, 0.045))
            pele = faixa(ruido(m), rng.uniform(200, 350), rng.uniform(1000, 1800)) * np.exp(-tt / rng.uniform(0.008, 0.016))
            rangido = 0.0
            if rng.random() < 0.25:  # tábua velha cedendo um pouco
                f = rng.uniform(300, 520)
                rangido = np.sin(2 * np.pi * f * tt * (1 + 0.4 * tt)) * envelope(m, 0.02, 0.05) * 0.12
            parte_som = corpo + 0.5 * pele + rangido
        else:
            corpo = np.sin(2 * np.pi * grave * tt) * np.exp(-tt / rng.uniform(0.015, 0.025)) * 0.5
            pele = faixa(ruido(m), rng.uniform(500, 800), rng.uniform(2500, 4500)) * np.exp(-tt / rng.uniform(0.006, 0.012))
            parte_som = corpo + pele
        som[amostras(atraso):] += parte_som * peso
    if rng.random() < 0.4:  # pé arrastando de leve
        m = amostras(rng.uniform(0.06, 0.12))
        arrasto = faixa(ruido(m), 1500, 6000) * np.hanning(m) * 0.06
        colocar(som, arrasto, amostras(rng.uniform(0.03, 0.1)), 1.0)
    som *= np.minimum(1.0, np.linspace(6, 0, n))  # termina em silêncio
    return normalizar(som, 0.45 * forca)


def pulo() -> np.ndarray:
    """Impulso do pulo: o fôlego curto e a roupa mexendo."""
    n = amostras(0.35)
    folego = formantes(ruido(n), [(1300, 900, 1.0), (3000, 1200, 0.4)]) * envelope(n, 0.03, 0.07)
    roupa = faixa(ruido(n), 1500, 6000) * envelope(n, 0.05, 0.1) * 0.4
    pes = passo_de("madeira", 0.6)
    som = 0.5 * normalizar(folego) + 0.3 * normalizar(roupa)
    colocar(som, pes[: n], 0, 0.6)
    return normalizar(som, 0.45)


def aterrissagem(chao: str) -> np.ndarray:
    """Os dois pés chegando juntos no chão, mais pesado que um passo."""
    n = amostras(0.4)
    som = np.zeros(n)
    colocar(som, passo_de(chao, 1.0)[:n], 0, 1.0)
    colocar(som, passo_de(chao, 1.0)[:n], amostras(rng.uniform(0.012, 0.03)), 0.8)
    t = tempo(n)
    som += np.sin(2 * np.pi * 55 * t) * np.exp(-t / 0.05) * 0.3
    return normalizar(som, 0.6)


def baque(n: int, freq: float, queda: float) -> np.ndarray:
    t = tempo(n)
    return np.sin(2 * np.pi * freq * t * (1 - 0.3 * t)) * np.exp(-t / queda) + \
        faixa(ruido(n), 100, 900) * np.exp(-t / (queda / 3)) * 0.4


def pano(dur: float) -> np.ndarray:
    n = amostras(dur)
    e = np.abs(np.sin(np.linspace(0, np.pi * rng.integers(1, 3), n))) * np.hanning(n)
    return faixa(ruido(n), 1200, 6000) * e * 0.5


def agua(dur: float) -> np.ndarray:
    """Mão e pano mexendo na água da bacia."""
    n = amostras(dur)
    som = np.zeros(n)
    for _ in range(int(dur * 25)):
        m = amostras(rng.uniform(0.01, 0.04))
        t = tempo(m)
        f = rng.uniform(600, 2200)
        gota = np.sin(2 * np.pi * f * t * (1 + 6 * t)) * np.exp(-t / 0.008)
        colocar(som, gota, rng.integers(0, n), rng.uniform(0.2, 0.8))
    som += faixa(ruido(n), 800, 5000) * 0.15 * np.hanning(n)
    return som * np.hanning(n)


# ------------------------------------------------------------ sons

def vento_mar() -> np.ndarray:
    """Abertura e janela: vento leve e mar distante, lá embaixo do penhasco."""
    n = amostras(24)
    vento = faixa(rosa(n), 150, 900, 1.0) * oscilacao(n, [(3, 0.35), (7, 0.2), (13, 0.1)], 1.0)
    mar = faixa(rosa(n), 40, 350, 1.2) * oscilacao(n, [(4, 0.5), (9, 0.2)], 1.0)
    return normalizar(0.6 * normalizar(vento) + normalizar(mar), 0.6)


def ondas() -> np.ndarray:
    """Varanda: ondas quebrando no pé do penhasco."""
    n = amostras(20)
    trilha = 0.25 * normalizar(faixa(rosa(n), 40, 400))
    for i in range(5):
        inicio = amostras(i * 4.0 + rng.uniform(-0.6, 0.6))
        m = amostras(4.5)
        e = envelope(m, 1.2, 0.9)
        quebra = faixa(ruido(m), 120, 2500, 1.0) * e
        espuma = faixa(ruido(m), 2000, 9000) * np.roll(e, amostras(0.8)) * 0.25
        colocar(trilha, normalizar(quebra + espuma, 0.8), inicio, rng.uniform(0.7, 1.0))
    return normalizar(eco(trilha, 2.0, 0.3), 0.65)


def grilos() -> np.ndarray:
    n = amostras(12)
    trilha = np.zeros(n)
    for grilo in range(3):
        f = rng.uniform(3900, 4700)
        t = rng.uniform(0, 1)
        while t < 12:
            for p in range(rng.integers(3, 5)):  # um cri-cri
                m = amostras(0.022)
                tt = tempo(m)
                pulso = np.sin(2 * np.pi * f * tt) * np.hanning(m)
                colocar(trilha, pulso, amostras(t + p * 0.035), 0.6 if grilo else 1.0)
            t += rng.uniform(0.45, 0.9)
    return normalizar(eco(trilha, 0.8, 0.4), 0.35)


def fogo() -> np.ndarray:
    """Tochas e lareira: chiado grave e estalos de lenha."""
    n = amostras(12)
    trilha = faixa(rosa(n), 60, 600, 1.0) * oscilacao(n, [(5, 0.3), (17, 0.2), (31, 0.15)], 1.0) * 0.3
    trilha = normalizar(trilha, 0.25)
    for _ in range(int(12 * 9)):
        m = amostras(rng.uniform(0.002, 0.012))
        estalo = faixa(ruido(m + 200), 900, 7000)[:m] * np.exp(-np.arange(m) / (m / 4))
        colocar(trilha, estalo, rng.integers(0, n), rng.uniform(0.05, 0.6) ** 2 * 2)
    return normalizar(trilha, 0.6)


def caos() -> np.ndarray:
    """Aposentos: parteiras e empregadas aflitas, passos, panos e água."""
    n = amostras(18)
    vozes = sum(conversa(n, f0, rapidez) for f0, rapidez in
                ((210, 1.3), (235, 1.5), (190, 1.2), (255, 1.6), (225, 1.4)))
    trilha = normalizar(faixa(vozes, 120, 3500), 0.5)
    for _ in range(int(18 * 2.5)):  # passos apressados de adulto
        colocar(trilha, baque(amostras(0.2), rng.uniform(70, 110), 0.04), rng.integers(0, n), rng.uniform(0.15, 0.35))
    for _ in range(9):
        colocar(trilha, pano(rng.uniform(0.4, 0.9)), rng.integers(0, n), rng.uniform(0.3, 0.6))
    for _ in range(5):
        colocar(trilha, agua(rng.uniform(0.8, 1.6)), rng.integers(0, n), rng.uniform(0.3, 0.5))
    return normalizar(eco(trilha, 1.0, 0.35), 0.7)


def correria(base: np.ndarray) -> np.ndarray:
    """O caos ouvido de longe, atrás das paredes: só os graves e as portas."""
    n = len(base)
    abafado = faixa(base, 0, 450, 1.5)
    for _ in range(int(n / TAXA * 3)):
        colocar(abafado, baque(amostras(0.25), rng.uniform(55, 80), 0.05), rng.integers(0, n), rng.uniform(0.2, 0.4))
    for _ in range(3):  # portas batendo longe
        colocar(abafado, baque(amostras(0.6), rng.uniform(45, 60), 0.12), rng.integers(0, n), 0.6)
    return normalizar(eco(abafado, 1.5, 0.4), 0.6)


def sussurros() -> np.ndarray:
    """"Um mar de sussurros": muitas vozes baixas, sem palavras."""
    n = amostras(14)
    vozes = sum(conversa(n, 200, rng.uniform(0.9, 1.3), sonora=False) for _ in range(7))
    return normalizar(eco(faixa(vozes, 300, 9000), 1.4, 0.45), 0.55)


def batida_coracao() -> np.ndarray:
    """Uma batida ("tum-tá") como Nicholas ouve o próprio coração, por dentro:
    grave, abafada e macia, sem estalo. O ritmo não está no arquivo: o jogo toca
    cada batida na hora, com pequenas variações, para não soar como relógio.
    Um pouco de saturação dá harmônicos para a batida aparecer até em alto-falante pequeno."""
    n = amostras(0.75)
    t = tempo(n)
    som = np.zeros(n)
    for inicio, f, queda, peso in ((0.0, rng.uniform(42, 52), rng.uniform(0.07, 0.09), 1.0),
                                   (rng.uniform(0.26, 0.31), rng.uniform(55, 68), rng.uniform(0.05, 0.065),
                                    rng.uniform(0.5, 0.7))):
        m = n - amostras(inicio)
        tt = tempo(m)
        ataque = np.clip(tt / rng.uniform(0.012, 0.02), 0, 1) ** 2
        corpo = np.sin(2 * np.pi * f * tt * (1 - 0.6 * tt)) * ataque * np.exp(-tt / queda)
        corpo += 0.5 * np.sin(2 * np.pi * f * 1.9 * tt) * ataque * np.exp(-tt / (queda * 0.6))
        massa = faixa(ruido(m), 15, 110, 2.0) * ataque * np.exp(-tt / (queda * 1.3))
        som[amostras(inicio):] += peso * (corpo + 0.6 * massa / max(np.std(massa), 1e-9) * np.std(corpo))
    # o sangue empurrado depois da batida: um sopro bem grave
    sopro = faixa(ruido(n), 20, 90, 2.0) * np.exp(-((t - 0.18) / 0.12) ** 2)
    som += 0.25 * sopro / max(np.max(np.abs(sopro)), 1e-9) * np.max(np.abs(som))
    som = np.tanh(2.2 * som / max(np.max(np.abs(som)), 1e-9))
    som = faixa(som, 18, 260, 2.0)
    som *= np.minimum(1.0, np.linspace(8, 0, n))
    return normalizar(som, 0.85)


def respiracao() -> np.ndarray:
    """Criança ofegante: entra e sai rápido, pela boca."""
    n = amostras(0.9 * 4)
    trilha = np.zeros(n)
    for i in range(4):
        dentro = amostras(rng.uniform(0.3, 0.36))
        fora = amostras(rng.uniform(0.36, 0.42))
        entra = formantes(ruido(dentro), [(1400, 900, 1.0), (3200, 1200, 0.4)]) * np.hanning(dentro)
        sai = formantes(ruido(fora), [(900, 700, 1.0), (2400, 1000, 0.3)]) * envelope(fora, 0.05, 0.12)
        colocar(trilha, entra, amostras(i * 0.9), 0.6)
        colocar(trilha, sai, amostras(i * 0.9 + 0.38), 1.0)
    return normalizar(trilha, 0.5)


def choro() -> np.ndarray:
    """Recém-nascida chorando. A voz de bebê é áspera e instável: a altura
    treme (jitter), o volume oscila (shimmer), às vezes a voz quebra para
    cima, e a boca abre e fecha mudando a vogal ("uéé-aa"). O laço é longo e
    nenhum choro se repete, para não soar como um som em loop."""
    total = 26.0
    n = amostras(total)
    trilha = np.zeros(n)
    t = 0.4
    while t < total - 0.3:
        intensidade = rng.uniform(0.55, 1.0)
        for _ in range(rng.integers(1, 4)):  # uma série de choros num fôlego só
            dur = rng.uniform(0.55, 1.6)
            colocar(trilha, um_choro(dur, intensidade), amostras(t), intensidade)
            t += dur + rng.uniform(0.05, 0.18)
        # puxando o ar: um "hh" curto e agudo, às vezes com voz
        fol = amostras(rng.uniform(0.2, 0.4))
        puxar = formantes(ruido(fol), [(1800, 1000, 1.0), (3600, 1500, 0.5)]) * np.hanning(fol)
        if rng.random() < 0.4:
            tt = tempo(fol)
            puxar += 0.3 * np.sin(2 * np.pi * np.cumsum(np.linspace(700, 900, fol)) / TAXA) * np.hanning(fol) * np.std(puxar)
        colocar(trilha, puxar, amostras(t), 0.12)
        t += fol / TAXA + rng.uniform(0.15, 0.6)
        if rng.random() < 0.2:
            t += rng.uniform(0.8, 1.8)  # uma pausa maior, como quem perde o fôlego
    return normalizar(eco(faixa(trilha, 250, 9000), 0.9, 0.3), 0.6)


def um_choro(dur: float, intensidade: float) -> np.ndarray:
    m = amostras(dur)
    quadro = 220  # amostras por quadro (5 ms) para as mudanças lentas
    q = m // quadro + 2
    x = np.linspace(0, 1, q)
    # altura: sobe no começo, segura com tremor, cai no fim
    base = rng.uniform(400, 520) * (0.9 + 0.1 * intensidade)
    contorno = base * (1 + 0.15 * np.sin(np.pi * np.minimum(x * 1.3, 1)) - 0.25 * x ** 4)
    jitter = np.convolve(rng.standard_normal(q), np.ones(4) / 4, mode="same") * 0.025
    f0q = contorno * (1 + jitter)
    if rng.random() < 0.35:  # quebra de voz: salta para cima por um instante
        i = rng.integers(q // 4, 3 * q // 4)
        f0q[i:i + rng.integers(6, 20)] *= rng.uniform(1.5, 1.9)
    f0 = np.interp(np.arange(m), np.arange(q) * quadro, f0q)
    fase = np.cumsum(f0) / TAXA
    # vogal: a boca abre ("u" -> "é" -> "a") e fecha no fim
    abertura = np.sin(np.pi * np.minimum(x * rng.uniform(1.0, 1.4), 1)) ** 0.7
    f1 = 650 + 650 * abertura
    f2 = 1500 + 800 * abertura
    shimmer = 1 + np.convolve(rng.standard_normal(q), np.ones(3) / 3, mode="same") * 0.12
    voz = np.zeros(m)
    for k in range(1, 22):
        fk = k * f0q
        peso = 1 / (1 + ((fk - f1) / 300) ** 2) + 0.6 / (1 + ((fk - f2) / 400) ** 2) + \
            0.25 / (1 + ((fk - 3800) / 600) ** 2)
        peso *= shimmer / k ** 0.35
        voz += np.interp(np.arange(m), np.arange(q) * quadro, peso) * np.sin(2 * np.pi * k * fase + rng.uniform(0, 6.28))
    # aspereza: ruído de ar junto da voz, mais forte quando o choro é mais forte
    ar = formantes(ruido(m), [(1300, 600, 1.0), (2300, 800, 0.6)]) * (0.15 + 0.2 * intensidade)
    voz = voz / max(np.std(voz), 1e-9) + ar / max(np.std(ar), 1e-9) * 0.35
    ataque = min(m, amostras(rng.uniform(0.04, 0.1)))
    env = np.ones(m)
    env[:ataque] = np.linspace(0, 1, ataque)
    env *= np.minimum(1.0, np.linspace(1.0, 0.0, m) * rng.uniform(4, 8))
    return voz * env


def main() -> None:
    import sys
    if sys.argv[1:] == ["coracao"]:  # refaz só as batidas, sem mexer nos outros sons
        for i in range(1, 7):
            salvar(batida_coracao(), EFEITOS / f"coracao_{i}.ogg")
        return
    salvar(vento_mar(), AMBIENTE / "vento_mar.ogg")
    salvar(ondas(), AMBIENTE / "ondas.ogg")
    salvar(grilos(), AMBIENTE / "grilos.ogg")
    salvar(fogo(), AMBIENTE / "fogo.ogg")
    base = caos()
    salvar(base, AMBIENTE / "caos.ogg")
    salvar(correria(base), AMBIENTE / "correria.ogg")
    salvar(sussurros(), AMBIENTE / "sussurros.ogg")
    for i in range(1, 7):
        salvar(batida_coracao(), EFEITOS / f"coracao_{i}.ogg")
    salvar(respiracao(), EFEITOS / "respiracao.ogg")
    salvar(choro(), EFEITOS / "choro.ogg")
    for chao in ("madeira", "pedra"):
        for i in range(1, 9):
            salvar(passo_de(chao), EFEITOS / f"passo_{chao}_{i}.ogg")
        salvar(aterrissagem(chao), EFEITOS / f"aterrissagem_{chao}.ogg")
    salvar(pulo(), EFEITOS / "pulo.ogg")


if __name__ == "__main__":
    main()
