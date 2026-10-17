"""Quadros do prólogo: recortes em pixel art do mapa de Hélade.

Os quadros pendurados no castelo são pequenos "easter eggs" do mapa do jogo.
Cada um é um recorte da arte do mapa (gerada por tools/arte/gerar_mapa.py),
sem nada novo desenhado, para não inventar lugares.

Uso: python3 tools/arte/gerar_quadros_prologo.py [caminho/do/mapa_helade.png]
"""

import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
MAPA = RAIZ / "assets/art/mapa/mapa_helade.png"
SAIDA = RAIZ / "assets/art/prologo/quadros"

# Nome do quadro: retângulo (x0, y0, x1, y1) no mapa de 1664 x 1280.
# Os centros vêm de data/mapa/<lugar>.tres.
RECORTES = {
    "olympia": (600, 900, 960, 1170),
    "atenas": (250, 565, 610, 835),
    "norte": (230, 150, 710, 510),
    "agape": (730, 635, 1090, 905),
    "helade": (0, 0, 1664, 1280),
}
# Moldura vazia do título no canto do mapa: some no quadro do mapa inteiro.
TITULO = (1290, 76, 1610, 212)


def main() -> None:
    mapa = Image.open(sys.argv[1] if len(sys.argv) > 1 else MAPA).convert("RGB")
    SAIDA.mkdir(parents=True, exist_ok=True)
    for nome, caixa in RECORTES.items():
        quadro = mapa.crop(caixa)
        if nome == "helade":
            mar = mapa.getpixel((TITULO[0] - 20, TITULO[3] + 20))
            x0, y0, x1, y1 = TITULO
            quadro.paste(mar, (x0, y0, x1, y1))
            quadro = quadro.resize((quadro.width // 2, quadro.height // 2), Image.NEAREST)
        quadro.save(SAIDA / f"{nome}.png")
        print(nome, quadro.size)


if __name__ == "__main__":
    main()
