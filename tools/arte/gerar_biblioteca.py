# Gera a arte provisória da biblioteca do Castelo Olympia (P5, sala de desafio).
# Base no livro: V1 P1 c05 ("dois andares, com livros até o teto, janelas
# enormes", mesas pelo ambiente, pilhas de livros no chão, mesa de xadrez
# pequena e redonda com tabuleiro de mármore e duas cadeiras estofadas) e
# V1 P1 c08 ("corredores mais estreitos, as estantes mais baixas, as mesas
# marcadas por anos de tinta"). Provisório até vir a arte de verdade.
#
# Grava em assets/art/placeholders/biblioteca/:
#   chao_madeira_iso.png  (duas casas de 64x32, tábuas claras e escuras)
#   estante_alta_iso.png  (64x128: livros até o teto)
#   estante_baixa_iso.png (64x64)
#   parede_janela_iso.png (64x128: pedra com janela grande na face da sala)
#   mesa.png, mesa_xadrez.png, pilha_livros.png (objetos soltos)
# Uso: python3 tools/arte/gerar_biblioteca.py
import os
import random
from PIL import Image, ImageDraw

PASTA = 'assets/art/placeholders/biblioteca'
H = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
CONTORNO = H('#120b08')
MADEIRA_ESCURA = H('#3b2416')
MADEIRA = H('#5a3a24')
MADEIRA_CLARA = H('#7a5234')
TAMPA = H('#8a6040')
LOMBADAS = [H('#7b2d2d'), H('#2f4a6b'), H('#3f5e3a'), H('#8a6a2a'), H('#5b3a5e'), H('#a08a64'), H('#6b3b22')]
PEDRA_ESQ = H('#55606e')
PEDRA_DIR = H('#3a4350')
PEDRA_TOPO = H('#7c8796')
VIDRO = H('#9fc3dc')
VIDRO_CLARO = H('#d6ebf5')


def bloco(altura, cor_topo, face_esq, face_dir):
    """Bloco isométrico de 64 de largura: tampa em losango e duas faces.
    face_esq/face_dir(x_local, v, altura) -> cor, com v medido do alto da face."""
    im = Image.new('RGBA', (64, 32 + altura), (0, 0, 0, 0))
    px = im.load()
    for x in range(64):
        meio = 32 - abs(x + 0.5 - 32) / 2           # onde a tampa acaba
        topo = abs(x + 0.5 - 32) / 2                # onde a tampa começa
        for y in range(int(round(topo)), int(round(meio))):
            px[x, y] = cor_topo
        for v in range(altura):
            y = int(round(meio)) + v
            px[x, y] = face_esq(x, v, altura) if x < 32 else face_dir(x - 32, v, altura)
    # contorno
    cheios = {(x, y) for x in range(64) for y in range(32 + altura) if px[x, y][3]}
    for (x, y) in cheios:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n not in cheios:
                px[x, y] = CONTORNO
                break
    return im


def escurecer(c, f):
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), c[3])


def estante(altura, semente):
    sorte = random.Random(semente)
    cores = {}

    def face(lado):
        def cor(x, v, alt):
            if v < 3 or v % 24 < 3 or x < 2 or x > 29:
                return MADEIRA if lado == 'esq' else MADEIRA_ESCURA
            # uma lombada a cada 3 pixels, cor sorteada por prateleira e posição
            chave = (lado, x // 3, v // 24)
            if chave not in cores:
                cores[chave] = sorte.choice(LOMBADAS)
            c = cores[chave]
            if v % 24 < 6 and sorte.random() < 0.02:
                return MADEIRA_ESCURA
            return c if lado == 'esq' else escurecer(c, 0.7)
        return cor
    return bloco(altura, TAMPA, face('esq'), face('dir'))


def parede_janela():
    def esq(x, v, alt):
        # janela grande e alta, com caixilho de madeira, na face que olha a sala
        if 6 <= x <= 25 and 14 <= v <= alt - 16:
            if x in (6, 25) or v in (14, alt - 16) or x == 15 or x == 16 or (v - 14) % 22 == 0:
                return MADEIRA_ESCURA
            return VIDRO_CLARO if (x + v) % 9 < 2 else VIDRO
        return PEDRA_ESQ if (x // 8 + v // 6) % 5 else escurecer(PEDRA_ESQ, 0.9)
    def dir_(x, v, alt):
        return PEDRA_DIR if (x // 8 + v // 6) % 5 else escurecer(PEDRA_DIR, 0.9)
    return bloco(96, PEDRA_TOPO, esq, dir_)


def chao():
    im = Image.new('RGBA', (128, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for i, cor in enumerate((MADEIRA_CLARA, H('#6c4930'))):
        ox = i * 64
        d.polygon([(ox + 32, 0), (ox + 63, 16), (ox + 32, 31), (ox, 16)], fill=cor)
        # tábuas na diagonal da casa
        for k in range(-32, 64, 8):
            for t in range(64):
                x, y = ox + t, k + t // 2
                if 0 <= y < 32 and im.getpixel((x, y))[3]:
                    im.putpixel((x, y), escurecer(cor, 0.82))
    return im


def mesa():
    im = Image.new('RGBA', (64, 44), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for x in (10, 52, 31):
        d.rectangle([x, 20, x + 2, 40], fill=MADEIRA_ESCURA)
    d.polygon([(32, 4), (60, 18), (32, 32), (4, 18)], fill=TAMPA, outline=CONTORNO)
    # marcas de tinta e um livro aberto
    sorte = random.Random(8)
    for _ in range(6):
        x, y = sorte.randint(18, 44), sorte.randint(12, 24)
        d.ellipse([x, y, x + 2, y + 1], fill=H('#1d1a2a'))
    d.polygon([(26, 14), (34, 10), (40, 13), (32, 17)], fill=H('#e8dcc0'), outline=CONTORNO)
    return im


def mesa_xadrez():
    im = Image.new('RGBA', (64, 44), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    estofado = H('#7b2d2d')
    # cadeiras estofadas, uma de frente para a outra
    d.ellipse([2, 18, 16, 28], fill=estofado, outline=CONTORNO)
    d.rectangle([2, 8, 6, 22], fill=MADEIRA_ESCURA)
    d.ellipse([48, 18, 62, 28], fill=estofado, outline=CONTORNO)
    d.rectangle([58, 8, 62, 22], fill=MADEIRA_ESCURA)
    d.rectangle([30, 22, 34, 40], fill=MADEIRA_ESCURA)
    d.ellipse([14, 10, 50, 30], fill=TAMPA, outline=CONTORNO)
    # tabuleiro de mármore no centro, em losango
    for i in range(4):
        for j in range(4):
            cx, cy = 32 + (i - j) * 3, 13 + (i + j) * 1.5
            cor = H('#ece8e0') if (i + j) % 2 == 0 else H('#5e5a58')
            d.polygon([(cx, cy), (cx + 3, cy + 1.5), (cx, cy + 3), (cx - 3, cy + 1.5)], fill=cor)
    return im


def pilha_livros():
    im = Image.new('RGBA', (32, 28), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    sorte = random.Random(3)
    y = 24
    for i in range(5):
        w = sorte.randint(14, 22)
        x = 16 - w // 2 + sorte.randint(-2, 2)
        d.rectangle([x, y - 4, x + w, y], fill=sorte.choice(LOMBADAS), outline=CONTORNO)
        d.line([x + 1, y - 2, x + w - 1, y - 2], fill=H('#e8dcc0'))
        y -= 5
    return im


if __name__ == '__main__':
    os.makedirs(PASTA, exist_ok=True)
    chao().save(os.path.join(PASTA, 'chao_madeira_iso.png'))
    estante(96, 1).save(os.path.join(PASTA, 'estante_alta_iso.png'))
    estante(32, 2).save(os.path.join(PASTA, 'estante_baixa_iso.png'))
    parede_janela().save(os.path.join(PASTA, 'parede_janela_iso.png'))
    mesa().save(os.path.join(PASTA, 'mesa.png'))
    mesa_xadrez().save(os.path.join(PASTA, 'mesa_xadrez.png'))
    pilha_livros().save(os.path.join(PASTA, 'pilha_livros.png'))
    print('ok:', PASTA)
