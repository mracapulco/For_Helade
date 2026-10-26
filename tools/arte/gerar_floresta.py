# Gera a arte provisória da fase "Árvores e mais árvores" (estrada Atenas–Olympia,
# oa_estrada_2): a árvore com a marca riscada no tronco, o bandido da mata
# (aparência inventada, provisória) e a folha que o vento leva.
# Parte dos desenhos que já existem (arvore_escura.png, bandido_provisorio.png).
# Uso: python3 tools/arte/gerar_floresta.py   (rodar na raiz do projeto)
import os
import sys

from PIL import Image

sys.dont_write_bytecode = True

ACAMP = 'assets/art/placeholders/acampamento'
EXPLO = 'assets/art/placeholders/exploracao'
PASTA = 'assets/art/placeholders/estrada_oa/floresta'

RISCO = (236, 214, 168, 255)  # madeira clara por baixo da casca
RISCO_SOMBRA = (120, 84, 50, 255)


def arvore_marcada():
    """A árvore escura com um X riscado no tronco (as marcas dos bandidos)."""
    arvore = Image.open(os.path.join(ACAMP, 'arvore_escura.png')).convert('RGBA')
    px = arvore.load()
    # Tronco: colunas 18 a 24, da copa (y=36) até perto do chão.
    cx, cy = 21, 45
    for i in range(-3, 4):
        for (x, y) in ((cx + i, cy + i), (cx + i, cy - i)):
            px[x, y + 1] = RISCO_SOMBRA
        for (x, y) in ((cx + i, cy + i), (cx + i, cy - i)):
            px[x, y] = RISCO
    arvore.save(os.path.join(PASTA, 'arvore_marcada.png'))


def bandido_da_mata():
    """O bandido de capuz troca o marrom-alaranjado por verde-musgo."""
    bandido = Image.open(os.path.join(EXPLO, 'bandido_provisorio.png')).convert('RGBA')
    px = bandido.load()
    for y in range(bandido.height):
        for x in range(bandido.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            # Olhos acesos continuam iguais (amarelo forte).
            if r > 200 and g > 140:
                continue
            if r > g + 12:  # tons de couro e tecido
                lum = (r + g + b) / 3
                px[x, y] = (int(lum * 0.62), int(lum * 0.9), int(lum * 0.58), a)
    bandido.save(os.path.join(PASTA, 'bandido_mata.png'))


def folha_voando():
    """Folha pequena (6×4) que o vento leva pela clareira."""
    folha = Image.new('RGBA', (6, 4), (0, 0, 0, 0))
    px = folha.load()
    claro = (178, 160, 72, 255)
    escuro = (112, 120, 48, 255)
    for (x, y) in ((1, 1), (2, 1), (3, 1), (2, 2), (3, 2), (4, 2)):
        px[x, y] = claro
    for (x, y) in ((0, 2), (1, 2), (4, 1), (5, 1)):
        px[x, y] = escuro
    folha.save(os.path.join(PASTA, 'folha_voando.png'))


def main():
    os.makedirs(PASTA, exist_ok=True)
    arvore_marcada()
    bandido_da_mata()
    folha_voando()


if __name__ == '__main__':
    main()
