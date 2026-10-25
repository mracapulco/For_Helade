"""Ambientes do Capítulo 01, feitos por código (provisórios, como os do prólogo).

Tocam por baixo da música, no barramento Efeitos, pelo autoload Trilha (canal de
ambiente), conforme data/musica/cenas.cfg:
  fonte_palacio.ogg  - o pátio do Palácio Imperial: a fonte central jorrando, gotas
                       caindo na bacia, um vento leve.
  rua_butiques.ogg   - a Rua das Butiques: burburinho de gente, passos no calçamento,
                       cascos e rodas passando ao longe.
  restaurante.ogg    - o restaurante: conversa baixa nas outras mesas e talheres na louça.

Laços sem emenda (filtros no espectro e sons que passam do fim voltam ao começo).
Reaproveita as ferramentas de tools/audio/gerar_sons_prologo.py.
Uso: python3 tools/audio/gerar_ambientes_capitulo_01.py   (precisa de numpy e ffmpeg)
"""

import sys
from pathlib import Path

import numpy as np

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import gerar_sons_prologo as s  # noqa: E402

PASTA = s.RAIZ / "assets/audio/ambiente/capitulo_01"
IMPORT = """[remap]

importer="oggvorbisstr"
type="AudioStreamOggVorbis"

[deps]

source_file="res://assets/audio/ambiente/capitulo_01/{nome}"

[params]

loop=true
loop_offset=0
bpm=0
beat_count=0
bar_beats=4
"""


def gota(volume: float = 1.0) -> np.ndarray:
    m = s.amostras(s.rng.uniform(0.02, 0.06))
    t = s.tempo(m)
    f = s.rng.uniform(500, 1800)
    return np.sin(2 * np.pi * f * t * (1 + 8 * t)) * np.exp(-t / 0.01) * volume


def fonte_palacio() -> np.ndarray:
    n = s.amostras(20)
    jorro = s.faixa(s.rosa(n), 300, 6000, 1.0) * s.oscilacao(n, [(7, 0.08), (19, 0.05)], 1.0)
    bacia = s.faixa(s.rosa(n), 80, 900, 1.2) * s.oscilacao(n, [(5, 0.15)], 1.0)
    trilha = 0.6 * s.normalizar(jorro) + 0.5 * s.normalizar(bacia)
    gotas = np.zeros(n)
    for _ in range(20 * 30):
        s.colocar(gotas, gota(), s.rng.integers(0, n), s.rng.uniform(0.05, 0.4))
    trilha += 0.5 * s.normalizar(gotas)
    vento = s.faixa(s.rosa(n), 150, 800, 1.0) * s.oscilacao(n, [(2, 0.4), (5, 0.2)], 1.0)
    trilha += 0.15 * s.normalizar(vento)
    return s.normalizar(s.eco(trilha, 1.0, 0.2), 0.55)


def cascos_passando(n: int) -> np.ndarray:
    """Uma carruagem passando ao longe: trote que cresce e some, com o rodar por baixo."""
    trilha = np.zeros(n)
    dur = s.rng.uniform(4.0, 6.0)
    m = s.amostras(dur)
    perto = np.sin(np.linspace(0, np.pi, m)) ** 2
    t = 0.0
    while t < dur - 0.3:
        for k, atraso in enumerate((0.0, 0.11)):
            i = s.amostras(t + atraso)
            if i < m:
                casco = s.baque(s.amostras(0.08), s.rng.uniform(500, 700), 0.012)
                s.colocar(trilha, casco, i, perto[i] * (0.8 if k else 1.0))
        t += s.rng.uniform(0.34, 0.4)
    rodas = s.faixa(s.ruido(m), 60, 400) * perto * 0.25
    s.colocar(trilha, rodas, 0, 1.0)
    return trilha[:n]


def rua_butiques() -> np.ndarray:
    n = s.amostras(30)
    vozes = sum(s.conversa(n, f0, rapidez) for f0, rapidez in
                ((120, 1.0), (135, 1.2), (110, 0.9), (210, 1.3), (230, 1.1), (195, 1.2),
                 (145, 1.0), (250, 1.4), (125, 1.1), (220, 1.0)))
    burburinho = s.faixa(vozes, 150, 3000) * s.oscilacao(n, [(3, 0.2), (7, 0.1)], 1.0)
    trilha = s.normalizar(burburinho, 0.5)
    trilha += 0.25 * s.normalizar(s.faixa(s.rosa(n), 100, 2000, 1.0))   # a cidade ao fundo
    for _ in range(int(30 * 3)):                                        # passos de sapato
        passo = s.baque(s.amostras(0.12), s.rng.uniform(150, 260), 0.02)
        s.colocar(trilha, passo, s.rng.integers(0, n), s.rng.uniform(0.04, 0.12))
    for inicio in (2.0, 17.0):                                          # duas carruagens passando
        carro = cascos_passando(s.amostras(7))
        s.colocar(trilha, carro, s.amostras(inicio + s.rng.uniform(-1, 1)), 0.18)
    return s.normalizar(s.eco(trilha, 1.4, 0.25), 0.55)


def talher() -> np.ndarray:
    """Garfo ou colher batendo na louça: dois parciais de metal e um de porcelana."""
    m = s.amostras(0.35)
    t = s.tempo(m)
    f = s.rng.uniform(2200, 3600)
    x = (np.sin(2 * np.pi * f * t) + 0.6 * np.sin(2 * np.pi * f * 1.48 * t)) * np.exp(-t / 0.05)
    x += 0.5 * np.sin(2 * np.pi * s.rng.uniform(900, 1300) * t) * np.exp(-t / 0.09)
    return x * np.exp(-t / 0.15)


def restaurante() -> np.ndarray:
    n = s.amostras(24)
    vozes = sum(s.conversa(n, f0, rapidez) for f0, rapidez in
                ((115, 0.8), (200, 0.9), (130, 0.85), (220, 0.8), (180, 0.9)))
    trilha = s.normalizar(s.faixa(vozes, 150, 2200), 0.35)
    for _ in range(int(24 * 1.6)):
        tique = talher()
        s.colocar(trilha, tique, s.rng.integers(0, n), s.rng.uniform(0.04, 0.14))
    return s.normalizar(s.eco(trilha, 1.0, 0.3), 0.45)


def gravar(x: np.ndarray, nome: str) -> None:
    s.salvar(x, PASTA / nome)
    (PASTA / (nome + ".import")).write_text(IMPORT.format(nome=nome))


if __name__ == "__main__":
    gravar(fonte_palacio(), "fonte_palacio.ogg")
    gravar(rua_butiques(), "rua_butiques.ogg")
    gravar(restaurante(), "restaurante.ogg")
