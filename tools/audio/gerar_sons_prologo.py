"""Sons e ambientes do prólogo, feitos por código (originais, sem direitos de terceiros).

São provisórios: dão o clima de cada momento até existirem gravações. Cada
arquivo fica num lugar fixo, então trocar por uma gravação é só substituir.

Os laços são feitos para emendar sem estalo: os filtros trabalham no espectro
(o que é circular) e o que passa do fim volta para o começo.

Uso: python3 tools/audio/gerar_sons_prologo.py
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

def passo_de(chao: str) -> np.ndarray:
    """Pé descalço de criança: um toque curto, sem salto de sapato."""
    n = amostras(0.18)
    t = tempo(n)
    if chao == "madeira":
        corpo = np.sin(2 * np.pi * rng.uniform(95, 130) * t) * np.exp(-t / 0.035)
        estalo = faixa(ruido(n), 250, 1400) * np.exp(-t / 0.012) * 0.6
    else:
        corpo = np.sin(2 * np.pi * rng.uniform(70, 90) * t) * np.exp(-t / 0.02) * 0.6
        estalo = faixa(ruido(n), 600, 3500) * np.exp(-t / 0.008)
    return normalizar(corpo + estalo, 0.5)


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


def coracao() -> np.ndarray:
    """Seis batidas a 100 por minuto; a velocidade sobe pelo pitch_scale."""
    batida = 0.6
    n = amostras(batida * 6)
    trilha = np.zeros(n)
    for i in range(6):
        colocar(trilha, baque(amostras(0.2), 52, 0.045), amostras(i * batida), 1.0)
        colocar(trilha, baque(amostras(0.2), 64, 0.035), amostras(i * batida + 0.24), 0.65)
    return normalizar(faixa(trilha, 0, 250), 0.8)


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
    """Recém-nascida chorando: "uéé" com tremor, e o fôlego entre um e outro."""
    n = amostras(7.5)
    trilha = np.zeros(n)
    t = 0.0
    while t < 7.5:
        dur = rng.uniform(0.8, 1.3)
        m = amostras(dur)
        tt = np.linspace(0, 1, m)
        f0 = rng.uniform(430, 500) * (1 + 0.12 * np.sin(np.pi * tt) - 0.18 * tt ** 3)
        f0 *= 1 + 0.025 * np.sin(2 * np.pi * 6.5 * tempo(m))
        fase = np.cumsum(f0) / TAXA
        voz = np.zeros(m)
        for k in range(1, 16):
            fk = k * f0.mean()
            # formantes de um choro de bebê, mais agudos que os de um adulto
            peso = sum(a / (1 + ((fk - c) / 350) ** 2) for c, a in ((1100, 1.0), (2100, 0.6), (3800, 0.25)))
            voz += peso / k ** 0.5 * np.sin(2 * np.pi * k * fase)
        voz *= envelope(m, 0.08, dur / 2.5) ** 0.5 * np.hanning(m) ** 0.3
        colocar(trilha, voz, amostras(t), 1.0)
        t += dur
        fol = amostras(0.28)
        colocar(trilha, formantes(ruido(fol), [(1500, 1200, 1.0)]) * np.hanning(fol), amostras(t), 0.08)
        t += rng.uniform(0.3, 0.45)
    return normalizar(eco(trilha, 0.9, 0.3), 0.6)


def main() -> None:
    salvar(vento_mar(), AMBIENTE / "vento_mar.ogg")
    salvar(ondas(), AMBIENTE / "ondas.ogg")
    salvar(grilos(), AMBIENTE / "grilos.ogg")
    salvar(fogo(), AMBIENTE / "fogo.ogg")
    base = caos()
    salvar(base, AMBIENTE / "caos.ogg")
    salvar(correria(base), AMBIENTE / "correria.ogg")
    salvar(sussurros(), AMBIENTE / "sussurros.ogg")
    salvar(coracao(), EFEITOS / "coracao.ogg")
    salvar(respiracao(), EFEITOS / "respiracao.ogg")
    salvar(choro(), EFEITOS / "choro.ogg")
    for chao in ("madeira", "pedra"):
        for i in range(1, 4):
            salvar(passo_de(chao), EFEITOS / f"passo_{chao}_{i}.ogg")


if __name__ == "__main__":
    main()
