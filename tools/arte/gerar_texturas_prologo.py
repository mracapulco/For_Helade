"""Gera as texturas PBR do prólogo (primeira pessoa, visual realista).

Tudo feito por código, original e sem direitos de terceiros. Cada material tem
cor (albedo), relevo (normal, padrão OpenGL do Godot) e aspereza (roughness).
Todas se repetem sem emenda. As cores são quase neutras: o tom final vem do
albedo_color de cada material, para a mesma textura servir a mais de um objeto.

Uso: python3 tools/arte/gerar_texturas_prologo.py assets/art/prologo/texturas
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

rng = np.random.default_rng(20)


# ---------------------------------------------------------------- ruído

def ruido(n: int, beta: float = 2.0, esticar: tuple[float, float] = (1.0, 1.0), corte: float = 0.0) -> np.ndarray:
    """Ruído periódico (se repete sem emenda) com espectro 1/f^beta, em 0..1.

    esticar > 1 num eixo deixa o ruído mais comprido nesse eixo (veio da madeira).
    """
    fy = np.fft.fftfreq(n)[:, None] * esticar[0]
    fx = np.fft.fftfreq(n)[None, :] * esticar[1]
    f = np.sqrt(fx**2 + fy**2)
    f[0, 0] = 1.0
    filtro = 1.0 / f ** (beta / 2)
    filtro[0, 0] = 0.0
    if corte > 0:
        filtro *= np.exp(-((f * n / corte) ** 2))
    campo = np.real(np.fft.ifft2(np.fft.fft2(rng.normal(size=(n, n))) * filtro))
    campo -= campo.min()
    return campo / campo.max()


def suave(x: np.ndarray, a: float, b: float) -> np.ndarray:
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def normal_de(altura: np.ndarray, forca: float) -> np.ndarray:
    dx = (np.roll(altura, -1, 1) - np.roll(altura, 1, 1)) * 0.5
    dy = (np.roll(altura, -1, 0) - np.roll(altura, 1, 0)) * 0.5
    n = np.stack([-dx * forca, dy * forca, np.ones_like(altura)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def salvar(pasta: Path, nome: str, cor: np.ndarray, altura: np.ndarray, aspereza: np.ndarray, forca: float) -> None:
    Image.fromarray((np.clip(cor, 0, 1) * 255).astype(np.uint8), "RGB").save(pasta / f"{nome}_cor.jpg", quality=90)
    Image.fromarray((normal_de(altura, forca) * 255).astype(np.uint8), "RGB").save(pasta / f"{nome}_normal.png", optimize=True)
    Image.fromarray((np.clip(aspereza, 0, 1) * 255).astype(np.uint8), "L").save(pasta / f"{nome}_aspereza.jpg", quality=90)


def tingir(base: np.ndarray, rgb: tuple[float, float, float]) -> np.ndarray:
    return base[..., None] * np.array(rgb)[None, None, :]


# ---------------------------------------------------------------- blocos

def blocos(n: int, fileiras: int, larguras: tuple[float, float], junta: float) -> tuple[np.ndarray, np.ndarray]:
    """Aparelho de blocos (pedra ou tábuas) que se repete.

    Devolve, por pixel, a distância até a junta mais próxima (em pixels) e um
    número de 0 a 1 diferente para cada bloco.
    """
    dist = np.zeros((n, n))
    ident = np.zeros((n, n))
    altura_fileira = n / fileiras
    ys = np.arange(n)
    xs = np.arange(n)
    for f in range(fileiras):
        y0 = int(round(f * altura_fileira))
        y1 = int(round((f + 1) * altura_fileira))
        # Larguras aleatórias que fecham exatamente a volta (para emendar).
        cortes = [0.0]
        while cortes[-1] < n:
            cortes.append(cortes[-1] + rng.uniform(*larguras) * n)
        escala = n / cortes[-1]
        cortes = np.array(cortes) * escala + rng.uniform(0, n)
        linha_y = ys[y0:y1]
        dy = np.minimum(linha_y - y0 + 0.5, y1 - 0.5 - linha_y)
        for i in range(len(cortes) - 1):
            a, b = cortes[i], cortes[i + 1]
            pos = (xs - a) % n
            dentro = pos < (b - a)
            dx = np.minimum(pos + 0.5, (b - a) - pos - 0.5)
            d = np.minimum(dy[:, None], dx[None, :])
            bloco = dentro[None, :].repeat(len(linha_y), 0)
            dist[y0:y1][bloco] = d[bloco]
            ident[y0:y1][bloco] = rng.uniform()
    return dist - junta / 2, ident


# ---------------------------------------------------------------- materiais

def pedra(n: int, fileiras: int, larguras: tuple[float, float], base: tuple[float, float, float]):
    dist, ident = blocos(n, fileiras, larguras, junta=n * 0.012)
    grao = ruido(n, 0.8)
    medio = ruido(n, 2.0)
    manchas = ruido(n, 3.0)
    lascas = suave(ruido(n, 2.2), 0.62, 0.8)
    # Bordas gastas e irregulares: a junta "come" a pedra em alguns pontos.
    dist = dist - n * 0.004 * medio
    borda = suave(dist, 0, n * 0.012)
    altura = borda * (0.6 + 0.2 * manchas + 0.12 * medio + 0.08 * grao) - 0.25 * lascas * borda
    sujeira = 1 - 0.3 * (1 - suave(dist, 0, n * 0.015))
    claro = (0.78 + 0.22 * ident + 0.3 * (manchas - 0.5) + 0.25 * (grao - 0.5) - 0.2 * lascas) * sujeira
    argamassa = 0.45 + 0.15 * grao + 0.1 * medio
    cor = tingir(np.where(dist > 0, claro, argamassa), base)
    aspereza = np.where(dist > 0, 0.82 + 0.12 * grao, 0.95)
    return cor, altura, aspereza


def assoalho(n: int):
    # Tábuas na horizontal: comprimento no eixo x.
    dist, ident = blocos(n, 8, (0.35, 0.7), junta=n * 0.004)
    veio = ruido(n, 2.0, esticar=(1.0, 14.0))
    nos = suave(ruido(n, 3.5), 0.86, 0.95)
    aneis = 0.5 + 0.5 * np.sin(2 * np.pi * (np.arange(n)[:, None] / n * 48 + 3 * veio))
    borda = suave(dist, 0, n * 0.004)
    tom = 0.72 + 0.35 * ident + 0.25 * (veio - 0.5) + 0.12 * aneis - 0.3 * nos
    cor = tingir(np.where(dist > 0, tom, 0.15), (0.50, 0.33, 0.20))
    altura = borda * (0.9 + 0.05 * aneis + 0.05 * veio)
    aspereza = np.where(dist > 0, 0.55 + 0.15 * veio + 0.1 * aneis, 0.9)
    return cor, altura, aspereza


def madeira_movel(n: int):
    veio = ruido(n, 2.0, esticar=(1.0, 10.0))
    aneis = 0.5 + 0.5 * np.sin(2 * np.pi * (np.arange(n)[:, None] / n * 36 + 4 * veio))
    tom = 0.75 + 0.3 * (veio - 0.5) + 0.15 * aneis
    cor = tingir(tom, (0.36, 0.22, 0.13))
    altura = 0.5 * veio + 0.2 * aneis
    return cor, altura, 0.45 + 0.2 * veio


def veludo(n: int):
    fibra = ruido(n, 0.6)
    dobras = ruido(n, 3.2, esticar=(6.0, 1.0))
    tom = 0.8 + 0.12 * (dobras - 0.5) + 0.06 * (fibra - 0.5)
    altura = 0.8 * dobras + 0.08 * fibra
    return tingir(tom, (1.0, 1.0, 1.0)), altura, 0.85 + 0.1 * fibra


def linho(n: int):
    x = np.arange(n)[None, :] / n
    y = np.arange(n)[:, None] / n
    fios = 128
    trama = np.abs(np.sin(np.pi * fios * x)) ** 0.5
    urdume = np.abs(np.sin(np.pi * fios * y)) ** 0.5
    xadrez = (np.floor(fios * x) + np.floor(fios * y)) % 2
    tecido = np.where(xadrez > 0, trama, urdume)
    irreg = ruido(n, 1.5, esticar=(1.0, 20.0))
    tom = 0.86 + 0.08 * tecido + 0.06 * (irreg - 0.5)
    return tingir(tom, (1.0, 0.97, 0.92)), 0.6 * tecido + 0.2 * irreg, 0.8 + 0.1 * (1 - tecido)


def marmore(n: int):
    x = np.arange(n)[None, :] / n
    y = np.arange(n)[:, None] / n
    turb = ruido(n, 3.2)
    veias = np.abs(np.sin(2 * np.pi * (2 * x + 1 * y) + 7 * turb)) ** 0.12
    finas = np.abs(np.sin(2 * np.pi * (3 * x - 2 * y) + 6 * ruido(n, 3.0))) ** 0.08
    nuvem = ruido(n, 3.0)
    tom = 0.88 + 0.06 * (nuvem - 0.5) - 0.35 * (1 - veias) - 0.12 * (1 - finas)
    cor = tingir(tom, (0.93, 0.92, 0.90))
    # Lajes de 1 m no chão da varanda.
    dist, _ = blocos(n, 2, (0.5, 0.5), junta=n * 0.004)
    altura = suave(dist, 0, n * 0.003) * (0.95 + 0.05 * nuvem)
    cor = np.where((dist > 0)[..., None], cor, cor * 0.6)
    return cor, altura, 0.22 + 0.15 * nuvem


def reboco(n: int):
    grao = ruido(n, 1.0)
    ondas = ruido(n, 3.0)
    tom = 0.8 + 0.1 * (ondas - 0.5) + 0.05 * (grao - 0.5)
    return tingir(tom, (0.82, 0.78, 0.72)), 0.7 * ondas + 0.15 * grao, 0.92 + 0.05 * grao


# ---------------------------------------------------------------- tapetes
# Cores já na textura (o material não tinge): vermelho, azul-noite, dourado, creme.
VERMELHO = np.array([0.42, 0.07, 0.06])
AZUL = np.array([0.05, 0.08, 0.22])
DOURADO = np.array([0.72, 0.52, 0.2])
CREME = np.array([0.82, 0.75, 0.6])


def _faixa_ornamento(u: np.ndarray, v: np.ndarray, periodo: float) -> np.ndarray:
    """Faixa com losangos e quadradinhos alternados (u ao longo, v de 0 a 1 na largura)."""
    fase = (u / periodo) % 1.0
    losango = (np.abs(fase - 0.5) * 2 + np.abs(v - 0.5) * 2) < 0.75
    quadrado = (np.abs(fase - 0.0) < 0.12) | (np.abs(fase - 1.0) < 0.12)
    return (losango & ~((np.abs(fase - 0.5) * 2 + np.abs(v - 0.5) * 2) < 0.35)) | (quadrado & (np.abs(v - 0.5) < 0.18))


def _la(cor: np.ndarray, n: int) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    fibra = ruido(n, 0.5)
    gasto = ruido(n, 3.0)
    tom = (0.85 + 0.25 * (fibra - 0.5)) * (0.92 + 0.16 * gasto)
    return cor * tom[..., None], 0.5 * fibra + 0.3 * gasto, 0.9 + 0.08 * fibra


def tapete(n: int):
    """Tapete quadrado com borda dos quatro lados (para PlaneMesh de UV 0 a 1)."""
    y, x = np.mgrid[0:n, 0:n] / n
    borda = np.minimum(np.minimum(x, 1 - x), np.minimum(y, 1 - y))
    cor = np.broadcast_to(VERMELHO, (n, n, 3)).copy()
    # Treliça de losangos no campo.
    malha = (np.abs(((x - 0.5) * 8 + (y - 0.5) * 8) % 2 - 1) < 0.08) | (np.abs(((x - 0.5) * 8 - (y - 0.5) * 8) % 2 - 1) < 0.08)
    cor[malha] = DOURADO * 0.8
    centro = (np.abs(x - 0.5) + np.abs(y - 0.5)) < 0.16
    cor[centro] = AZUL
    cor[(np.abs(x - 0.5) + np.abs(y - 0.5)) < 0.08] = DOURADO
    # Bordas: azul com ornamento creme, filetes dourados.
    faixa = (borda > 0.03) & (borda < 0.13)
    cor[faixa] = AZUL
    u = np.where(np.minimum(x, 1 - x) < np.minimum(y, 1 - y), y, x)
    orn = _faixa_ornamento(u * 10, (borda - 0.03) / 0.10, 1.0) & faixa
    cor[orn] = CREME
    for limite in (0.03, 0.13):
        cor[np.abs(borda - limite) < 0.006] = DOURADO
    cor[borda < 0.03] = AZUL * 0.8
    cor[borda < 0.012] = AZUL * 0.6
    base, altura, aspereza = _la(cor, n)
    return base, altura, aspereza


def passadeira(n: int):
    """Passadeira de corredor: borda em cima e embaixo, repete no comprimento (eixo x)."""
    y, x = np.mgrid[0:n, 0:n] / n
    borda = np.minimum(y, 1 - y)
    cor = np.broadcast_to(VERMELHO, (n, n, 3)).copy()
    malha = (np.abs(((x * 4 + y * 4) % 2) - 1) < 0.06) | (np.abs(((x * 4 - y * 4) % 2) - 1) < 0.06)
    cor[malha] = DOURADO * 0.75
    faixa = (borda > 0.04) & (borda < 0.17)
    cor[faixa] = AZUL
    orn = _faixa_ornamento(x * 8, (borda - 0.04) / 0.13, 1.0) & faixa
    cor[orn] = CREME
    for limite in (0.04, 0.17):
        cor[np.abs(borda - limite) < 0.007] = DOURADO
    cor[borda < 0.04] = AZUL * 0.8
    cor[borda < 0.015] = AZUL * 0.6
    return _la(cor, n)


def main() -> None:
    pasta = Path(sys.argv[1])
    pasta.mkdir(parents=True, exist_ok=True)
    # (nome, gerador, força do relevo)
    feitos = [
        ("pedra_parede", lambda: pedra(1024, 5, (0.2, 0.35), (0.62, 0.58, 0.52)), 6.0),
        ("pedra_piso", lambda: pedra(1024, 4, (0.22, 0.4), (0.45, 0.43, 0.41)), 5.0),
        ("assoalho", lambda: assoalho(1024), 4.0),
        ("madeira_movel", lambda: madeira_movel(512), 2.0),
        ("veludo", lambda: veludo(512), 3.0),
        ("linho", lambda: linho(512), 2.0),
        ("marmore", lambda: marmore(1024), 3.0),
        ("reboco", lambda: reboco(512), 2.5),
        ("tapete", lambda: tapete(1024), 2.0),
        ("passadeira", lambda: passadeira(512), 2.0),
    ]
    for nome, gerar, forca in feitos:
        cor, altura, aspereza = gerar()
        n = altura.shape[0]
        salvar(pasta, nome, cor, altura, aspereza, forca * n / 512)
        print(nome, n)


if __name__ == "__main__":
    main()
