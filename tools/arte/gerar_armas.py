# Gera a arte provisória em pixel art das armas e proteções do combate, na
# paleta de Hélade: ícone da bolsa (32×32), desenho na mão do personagem e,
# para armadura e elmo, uma folha por cima do Nicholas com os mesmos quadros
# da folha dele (e o SpriteFrames .tres que o Godot usa).
# Nada aqui é do livro: são peças genéricas até a arte final.
# Uso: python3 tools/arte/gerar_armas.py   (rodar na raiz do projeto)
#      python3 tools/arte/gerar_armas.py --previa saida.png   (folha de prévia)
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_objetos import C, Q  # noqa: E402
import gerar_nicholas as nic     # noqa: E402

PASTA = 'assets/art/placeholders/combate'


def contornar_menos(q, livres=()):
    # Contorno escuro em volta do desenho, menos nos pixels de [livres]
    # (o punho, onde a mão do personagem aparece por cima do cabo).
    livres = set(livres)
    cheios = {(x, y) for x in range(q.w) for y in range(q.h) if q.px[x, y][3] == 255}
    for (x, y) in list(cheios):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n not in cheios and n not in livres and 0 <= n[0] < q.w and 0 <= n[1] < q.h:
                q.px[n] = C['contorno']
    return q.im


def punho(g):
    gx, gy = g
    return [(gx + dx, gy + dy) for dx in (0, 1) for dy in (0, 1)]


# ---------- armas na mão (ponta para baixo; o punho 2×2 fica vazio) ----------
# PEGA = pixel de cima à esquerda do punho; vai no .tres em "pega_na_mao".

PEGA = {}


def lamina(q, gx, y0, comprimento, largura, passo):
    # Lâmina descendo e indo um pouco para a frente a cada [passo] linhas.
    for i in range(comprimento):
        x = gx + i // passo
        y = y0 + i
        q.p(x, y, 'branco' if i < 3 else 'lua')
        for k in range(1, largura):
            q.p(x + k, y, 'pedra_luz' if k < largura - 1 else 'pedra')
    xf = gx + (comprimento - 1) // passo
    q.p(xf + largura // 2, y0 + comprimento, 'lua')            # ponta


def espada_media():
    q = Q(8, 20); g = PEGA['espada_media'] = (2, 3); gx, gy = g
    q.r(gx, gy - 2, gx + 1, gy - 2, 'ouro'); q.p(gx + 1, gy - 2, 'ouro_luz')      # pomo
    q.r(gx, gy - 1, gx + 1, gy - 1, 'madeira')                                    # cabo
    q.r(gx - 2, gy + 2, gx + 3, gy + 2, 'ouro')                                   # guarda
    q.p(gx - 2, gy + 2, 'ouro_luz'); q.p(gx + 3, gy + 2, 'ouro_sombra')
    lamina(q, gx, gy + 3, 11, 2, 4)
    return contornar_menos(q, punho(g))


def espada_grande():
    q = Q(14, 34); g = PEGA['espada_grande'] = (5, 5); gx, gy = g
    q.r(gx, gy - 4, gx + 1, gy - 3, 'ouro'); q.p(gx, gy - 4, 'ouro_luz')          # pomo
    q.r(gx, gy - 2, gx + 1, gy - 1, 'madeira'); q.p(gx, gy - 2, 'madeira_luz')    # cabo longo (duas mãos)
    q.r(gx - 4, gy + 2, gx + 5, gy + 3, 'ouro')                                   # guarda larga
    q.linha(gy + 2, gx - 4, gx + 5, 'ouro_luz'); q.p(gx + 5, gy + 3, 'ouro_sombra')
    q.p(gx - 4, gy + 4, 'ouro_sombra'); q.p(gx + 5, gy + 4, 'ouro_sombra')
    lamina(q, gx - 1, gy + 4, 22, 4, 8)
    q.coluna(gx + 1, gy + 5, gy + 14, 'pedra')                                    # sulco da lâmina
    return contornar_menos(q, punho(g))


def cabo(q, gx, y0, y1):
    q.r(gx, y0, gx + 1, y1, 'madeira')
    q.coluna(gx, y0, y1, 'madeira_luz')
    q.linha(y1, gx, gx + 1, 'madeira_sombra')


def machado_pequeno():
    q = Q(12, 18); g = PEGA['machado_pequeno'] = (2, 2); gx, gy = g
    cabo(q, gx, gy - 1, gy + 13)
    # cabeça: lâmina curva para a frente, perto da ponta do cabo
    for i, (a, b) in enumerate([(2, 3), (2, 5), (2, 6), (2, 6), (2, 6), (2, 5), (2, 3)]):
        y = gy + 7 + i
        q.linha(y, gx + a, gx + b, 'pedra')
        q.p(gx + b, y, 'lua')
    q.coluna(gx + 6, gy + 9, gy + 11, 'branco')                                   # fio
    q.r(gx + 2, gy + 9, gx + 3, gy + 11, 'pedra_sombra')
    q.r(gx - 1, gy + 9, gx - 1, gy + 11, 'pedra')                                 # contrapeso
    return contornar_menos(q, punho(g))


def machado_guerra():
    q = Q(20, 30); g = PEGA['machado_guerra'] = (9, 3); gx, gy = g
    cabo(q, gx, gy - 2, gy + 24)
    q.r(gx, gy + 22, gx + 1, gy + 24, 'ouro_sombra')                              # ponteira
    # cabeça de duas lâminas, em forma de lua crescente dos dois lados
    for i, meia in enumerate([3, 5, 6, 7, 7, 7, 6, 5, 3]):
        y = gy + 12 + i
        q.linha(y, gx - meia, gx + 1 + meia, 'pedra')
        q.p(gx - meia, y, 'lua'); q.p(gx + 1 + meia, y, 'lua')
    q.coluna(gx - 7, gy + 15, gy + 17, 'branco'); q.coluna(gx + 8, gy + 15, gy + 17, 'branco')
    q.r(gx - 1, gy + 12, gx + 2, gy + 20, 'pedra_sombra')                         # alvado
    q.r(gx, gy + 12, gx + 1, gy + 20, 'madeira')
    q.linha(gy + 12, gx - 1, gx + 2, 'ouro'); q.linha(gy + 20, gx - 1, gx + 2, 'ouro')
    return contornar_menos(q, punho(g))


def punhal():
    q = Q(7, 13); g = PEGA['punhal'] = (2, 2); gx, gy = g
    q.r(gx, gy - 1, gx + 1, gy - 1, 'ouro')                                       # pomo
    q.r(gx - 1, gy + 2, gx + 2, gy + 2, 'ouro_sombra')                            # guarda curta
    for i in range(6):                                                            # lâmina fina
        q.p(gx + i // 4, gy + 3 + i, 'branco' if i < 2 else 'lua')
        if i < 4:
            q.p(gx + 1 + i // 4, gy + 3 + i, 'pedra_luz')
    q.p(gx + 1, gy + 9, 'lua')
    return contornar_menos(q, punho(g))


def maca():
    q = Q(11, 17); g = PEGA['maca'] = (3, 2); gx, gy = g
    q.r(gx, gy - 1, gx + 1, gy - 1, 'ouro_sombra')
    cabo(q, gx, gy + 2, gy + 8)
    q.elipse(gx + 1, gy + 11, 3, 3, 'pedra')                                      # cabeça
    q.elipse(gx, gy + 10, 1, 1, 'pedra_luz')
    for (dx, dy) in ((-4, 0), (4, 0), (0, 4), (-3, -3), (3, 3), (3, -3), (-3, 3)):
        q.p(gx + 1 + dx, gy + 11 + dy, 'pedra_sombra')                            # flanges
    q.linha(gy + 8, gx - 1, gx + 2, 'ouro')                                       # anel
    return contornar_menos(q, punho(g))


def arco(nome='arco', altura=31, pontas='ouro'):
    # Arco em pé, com a barriga para a frente e a corda reta atrás. A mão
    # segura no meio.
    meio = (altura - 1) / 2.0
    q = Q(9, altura); g = PEGA[nome] = (5, int(meio) - 1); gx, gy = g
    for y in range(0, altura):
        curva = round(4 * ((y - meio) / meio) ** 2)
        x = gx - curva
        q.p(x, y, 'madeira'); q.p(x + 1, y, 'madeira_luz' if abs(y - meio) > 3 else 'madeira')
    for y in (0, 1, altura - 2, altura - 1):
        q.p(gx - 4, y, pontas)                                                    # pontas
    q.coluna(gx - 4, 2, altura - 3, 'prata')                                      # corda
    for xy in punho(g):
        q.px[xy] = (0, 0, 0, 0)
    q.r(gx, gy - 1, gx + 1, gy - 1, 'ouro_sombra'); q.r(gx, gy + 2, gx + 1, gy + 2, 'ouro_sombra')
    return contornar_menos(q, punho(g))


def arco_curto():
    # Arco de criança (o livro: Althea com "um arco infantil, pequeno e
    # claro"; Nicholas treina arco aos 12): menor, pontas de madeira clara.
    return arco('arco_curto', 21, 'madeira_luz')


def flecha():
    # Deitada, apontando para a direita (o Godot gira para onde ela voa).
    q = Q(15, 5)
    q.linha(2, 3, 11, 'madeira_luz')
    q.p(12, 2, 'pedra_luz'); q.p(13, 2, 'lua'); q.p(12, 1, 'pedra'); q.p(12, 3, 'pedra')  # ponta
    for x in (1, 2, 3):
        q.p(x, 1, 'branco'); q.p(x, 3, 'prata')                                   # penas
    return contornar_menos(q)


# ---------- proteções na mão de trás (a mão fica atrás, coberta) ----------

def escudo(rx=7, ry=8):
    q = Q(2 * rx + 3, 2 * ry + 3)
    cx, cy = rx + 1, ry + 1
    q.elipse(cx, cy, rx, ry, 'ouro_sombra')                                       # aro de bronze
    q.elipse(cx, cy, rx - 1, ry - 1, 'ouro')
    q.elipse(cx, cy, rx - 2, ry - 2, 'azul')                                      # campo
    q.elipse(cx - 1, cy - 1, rx - 3, ry - 3, 'nuvem')
    anel = max(2, rx // 3)
    q.elipse(cx, cy, anel, anel, 'ouro')                                          # emblema: anel dourado
    q.elipse(cx, cy, anel - 1, anel - 1, 'azul')
    q.p(cx, cy, 'ouro_luz')
    q.p(cx - rx + 2, cy - ry // 2, 'ouro_luz'); q.p(cx - rx + 3, cy - ry // 2 - 1, 'ouro_luz')
    PEGA['escudo'] = (cx - 1, cy - 1)
    return contornar_menos(q)


FRUTAS = ((3, 3, 'vela', 'ouro_luz'), (7, 2, 'vela_escura', 'vela'), (11, 3, 'folha_luz', 'lua'),
          (5, 4, 'folha', 'folha_luz'), (9, 4, 'vela', 'ouro_luz'))


def _frutas(q, dx=0, dy=0):
    for (cx, cy, c, l) in FRUTAS:
        q.elipse(cx + dx, cy + dy, 2, 2, c); q.p(cx + dx - 1, cy + dy - 1, l)


def _caixote(q, dx=0, dy=0, vazio=True):
    if vazio:
        q.r(1 + dx, 3 + dy, 13 + dx, 4 + dy, 'madeira_sombra')                   # fundo visto por cima
        q.linha(3 + dy, 1 + dx, 13 + dx, 'madeira')                               # borda de trás
    q.r(1 + dx, 5 + dy, 13 + dx, 11 + dy, 'madeira')                              # caixote
    q.linha(5 + dy, 1 + dx, 13 + dx, 'madeira_luz')
    for y in (7, 9):
        q.linha(y + dy, 1 + dx, 13 + dx, 'madeira_sombra')                        # vãos entre ripas
    q.r(1 + dx, 5 + dy, 1 + dx, 11 + dy, 'madeira_sombra'); q.r(13 + dx, 5 + dy, 13 + dx, 11 + dy, 'madeira_sombra')
    for (x, y) in ((2, 6), (12, 6), (2, 10), (12, 10)):
        q.p(x + dx, y + dy, 'pedra_luz')                                          # pregos


def caixa_frutas():
    # Na mão é só a caixa vazia: as frutas ficam onde ela estava.
    q = Q(15, 13); PEGA['caixa_frutas'] = (6, 6)
    _caixote(q)
    return contornar_menos(q)


# ---------- no chão (ou numa bancada): a caixa cheia, e as frutas que sobram ----------

def caixa_com_frutas_chao():
    q = Q(17, 16)
    q.sombra_no_chao(8, 14, 8, 1)
    _frutas(q, 1, 1)
    _caixote(q, 1, 2, vazio=False)
    return contornar_menos(q)


def frutas_no_chao():
    q = Q(17, 16)
    q.sombra_no_chao(8, 14, 7, 1)
    for (cx, cy, c, l) in ((4, 12, 'vela', 'ouro_luz'), (8, 13, 'vela_escura', 'vela'),
                           (12, 12, 'folha_luz', 'lua'), (6, 10, 'folha', 'folha_luz'),
                           (10, 10, 'vela', 'ouro_luz')):
        q.elipse(cx, cy, 2, 2, c); q.p(cx - 1, cy - 1, l)
    return contornar_menos(q)


def panela():
    # Panela vista por baixo, segurada pelo cabo (a mão fica por cima do cabo).
    q = Q(15, 15); g = PEGA['panela'] = (1, 1); gx, gy = g
    for i in range(4):
        q.r(gx + 2 + i, gy + 2 + i, gx + 3 + i, gy + 2 + i, 'madeira')            # cabo
    q.elipse(9, 9, 5, 5, 'pedra_sombra')                                          # fundo
    q.elipse(9, 9, 4, 4, 'pedra')
    q.elipse(8, 8, 2, 2, 'pedra_luz')
    q.p(7, 7, 'lua')
    for ang in range(0, 360, 30):                                                 # borda escura
        x = round(9 + 5 * math.cos(math.radians(ang))); y = round(9 + 5 * math.sin(math.radians(ang)))
        q.p(x, y, 'pedra_sombra')
    return contornar_menos(q, punho(g))


# ---------- armadura e elmo, por cima de cada quadro do Nicholas ----------

def _quadro_vazio():
    return Q(nic.W, nic.HH)


def _contornar_camada(q, base):
    # Contorno só onde a peça sai do corpo (fundo transparente na folha),
    # para não riscar o rosto nem a roupa por baixo.
    bpx = base.load()
    cheios = {(x, y) for x in range(q.w) for y in range(q.h) if q.px[x, y][3] == 255}
    for (x, y) in list(cheios):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n in cheios or not (0 <= n[0] < q.w and 0 <= n[1] < q.h):
                continue
            if bpx[n][3] == 0 or bpx[n] == nic.C['contorno']:
                q.px[n] = C['contorno']
    return q.im


def _geometria(k):
    x = nic.CX + k.get('inclina', 0)
    dy = k.get('dy', 0)
    return x, 3 + dy, 19 + dy, 31 + dy, dy


def _pernas(k, frente):
    for base_x, f, lift in ((nic.CX - 4, k.get('f_esq', 0), k.get('lift_esq', 0)),
                            (nic.CX + 1, k.get('f_dir', 0), k.get('lift_dir', 0))):
        yield base_x + f, 45 - lift


def armadura_leve(dir, **k):
    q = _quadro_vazio()
    x, yc, yt, quadril, dy = _geometria(k)
    if dir == 'frente':
        q.r(x - 2, yt + 1, x + 4, quadril - 2, 'madeira')                        # colete de couro
        q.coluna(x + 3, yt + 2, quadril - 3, 'madeira_luz')
        q.coluna(x - 2, yt + 1, quadril - 2, 'madeira_sombra')
        for i in range(5):                                                        # faixa cruzada (cor do reino)
            q.p(x - 1 + i, yt + 1 + i, 'nuvem'); q.p(x - 1 + i, yt + 2 + i, 'azul')
        q.linha(quadril - 3, x - 2, x + 4, 'ouro_sombra')                         # cinto
        for c in range(x - 2, x + 5):                                             # saiote de tiras
            q.coluna(c, quadril - 1, quadril + 2, 'madeira' if c % 2 else 'madeira_sombra')
        if not k.get('ergue'):
            q.r(x + 4, yt, x + 6, yt + 2, 'madeira_luz')                          # ombreira de couro
            q.linha(yt + 2, x + 4, x + 6, 'madeira')
    else:
        for c in range(x - 4, x + 5):
            q.coluna(c, 36 + dy, 37 + dy, 'madeira' if c % 2 else 'madeira_sombra')
        q.r(x + 3, yt + 3, x + 6, yt + 4, 'madeira')                              # alça no ombro
    return q


def armadura_pesada(dir, **k):
    q = _quadro_vazio()
    x, yc, yt, quadril, dy = _geometria(k)
    if dir == 'frente':
        q.r(x - 2, yt, x + 4, quadril - 2, 'pedra')                               # couraça
        q.r(x + 1, yt + 1, x + 3, yt + 4, 'pedra_luz')                            # peito moldado
        q.p(x + 2, yt + 6, 'pedra_luz'); q.p(x + 2, yt + 8, 'pedra_luz')
        q.coluna(x - 2, yt, quadril - 2, 'pedra_sombra')
        q.linha(yt, x - 2, x + 4, 'ouro'); q.linha(quadril - 2, x - 2, x + 4, 'ouro')
        for c in range(x - 2, x + 5):                                             # tiras de metal
            q.coluna(c, quadril - 1, quadril + 3, 'pedra_sombra' if c % 2 else 'nuvem')
        if not k.get('ergue'):
            q.r(x + 3, yt - 1, x + 7, yt + 2, 'pedra')                            # ombreira de metal
            q.linha(yt - 1, x + 4, x + 6, 'pedra_luz'); q.linha(yt + 2, x + 3, x + 7, 'ouro_sombra')
        frente = True
    else:
        q.r(x + 2, yt - 1, x + 7, yt + 2, 'pedra')
        q.linha(yt - 1, x + 3, x + 6, 'pedra_luz'); q.linha(yt + 2, x + 2, x + 7, 'ouro_sombra')
        for c in range(x - 4, x + 5):
            q.coluna(c, 36 + dy, 38 + dy, 'pedra_sombra' if c % 2 else 'nuvem')
        frente = False
    for xx, pe in _pernas(k, frente):                                             # grevas
        q.r(xx, pe - 7, xx + 2, pe - 3, 'pedra')
        q.coluna(xx + 1, pe - 7, pe - 4, 'pedra_luz')
        q.linha(pe - 7, xx, xx + 2, 'ouro_sombra')
    return q


def elmo(dir, **k):
    q = _quadro_vazio()
    x, yc, yt, quadril, dy = _geometria(k)
    q.r(x - 4, yc - 3, x + 2, yc - 1, 'nuvem')                                    # penacho azul
    q.linha(yc - 3, x - 3, x + 1, 'azul_luz')
    if dir == 'frente':
        q.elipse(x, yc + 3, 6, 4, 'ouro')                                          # domo de bronze
        q.r(x - 6, yc + 3, x + 5, yc + 5, 'ouro')
        q.linha(yc, x - 3, x + 2, 'ouro_luz'); q.p(x + 3, yc + 1, 'ouro_luz')
        q.coluna(x - 6, yc, yc + 5, 'ouro_sombra')
        q.linha(yc + 6, x - 6, x + 5, 'ouro_sombra')                              # aba
        q.r(x - 6, yc + 6, x - 4, yc + 10, 'ouro')                                # protetor da nuca
        q.coluna(x - 6, yc + 6, yc + 10, 'ouro_sombra')
        q.coluna(x + 1, yc + 6, yc + 8, 'ouro_sombra')                            # protetor do nariz
    else:
        q.elipse(x, yc + 3, 6, 4, 'ouro')
        q.r(x - 6, yc + 3, x + 6, yc + 7, 'ouro')
        q.linha(yc, x - 3, x + 3, 'ouro_luz')
        q.coluna(x - 6, yc, yc + 7, 'ouro_sombra')
        q.r(x - 5, yc + 8, x + 5, yc + 9, 'ouro_sombra')                          # protetor da nuca
    return q


CAMADAS = {'armadura_leve': armadura_leve, 'armadura_pesada': armadura_pesada, 'elmo': elmo}


def folha_camada(desenhar):
    linhas = nic.linhas_da_folha()
    im = Image.new('RGBA', (nic.W * 4, nic.HH * len(linhas)), (0, 0, 0, 0))
    for linha, (d, a) in enumerate(linhas):
        for i, k in enumerate(nic.ANIM[a]):
            base = nic.nicholas(d, **k)
            im.paste(_contornar_camada(desenhar(d, **k), base), (i * nic.W, linha * nic.HH))
    return im


def quadros_tres(caminho_png):
    # Mesmo SpriteFrames da folha do Nicholas, só trocando a imagem.
    with open('assets/art/personagens/nicholas/nicholas_exploracao.tres') as f:
        texto = f.read()
    return texto.replace('res://assets/art/personagens/nicholas/nicholas_exploracao.png',
                         'res://' + caminho_png)


# ---------- ícones da bolsa (32×32) ----------

def _no_centro(desenho, escala=None, girar=0, encher=None):
    im = desenho.rotate(girar, expand=True) if girar else desenho
    if escala is None:
        escala = max(1, min(30 // im.width, 30 // im.height))
    im = im.resize((im.width * escala, im.height * escala), Image.NEAREST)
    icone = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    icone.alpha_composite(im, ((32 - im.width) // 2, (32 - im.height) // 2))
    return icone


def _arma_inteira(desenhar, nome):
    # O desenho da mão com o punho preenchido (cabo de couro), para o ícone.
    im = desenhar().copy()
    px = im.load()
    pontos = punho(PEGA[nome])
    for (x, y) in pontos:
        px[x, y] = C['madeira']
    for (x, y) in pontos:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if 0 <= n[0] < im.width and 0 <= n[1] < im.height and px[n][3] == 0:
                px[n] = C['contorno']
    return im


def icone_arma(desenhar, nome):
    # Ponta para cima, como nas lojas.
    return _no_centro(_arma_inteira(desenhar, nome), girar=180)


def icone_arco(desenhar=arco, nome='arco'):
    icone = _no_centro(_arma_inteira(desenhar, nome))
    seta = flecha().rotate(45, expand=True)
    icone.alpha_composite(seta, (12, 6))
    return icone


def icone_couraca(metal):
    q = Q(32, 32)
    corpo, luz, sombra = (('pedra', 'pedra_luz', 'pedra_sombra') if metal
                          else ('madeira', 'madeira_luz', 'madeira_sombra'))
    for y in range(6, 24):                                                        # tronco, mais largo no peito
        meia = 9 if y < 14 else 9 - (y - 14) // 3
        q.linha(y, 16 - meia, 15 + meia, corpo)
    q.r(5, 5, 10, 9, luz if metal else corpo); q.r(21, 5, 26, 9, luz if metal else corpo)   # ombros
    q.r(12, 4, 19, 6, 'contorno')                                                 # gola
    q.r(13, 8, 18, 13, luz)
    q.coluna(7, 10, 22, sombra)
    q.linha(22, 9, 22, 'ouro' if metal else 'ouro_sombra')
    for x in range(9, 23):                                                        # saiote de tiras
        q.coluna(x, 23, 27, (sombra if x % 2 else corpo) if metal else (corpo if x % 2 else sombra))
    if not metal:
        for i in range(8):
            q.p(11 + i, 8 + i, 'nuvem'); q.p(11 + i, 9 + i, 'azul')               # faixa cruzada
    return q.contornar()


def icone_elmo():
    q = Q(32, 32)
    q.r(8, 3, 22, 6, 'nuvem'); q.linha(3, 10, 20, 'azul_luz')                     # penacho
    q.elipse(15, 15, 9, 9, 'ouro')                                                # domo
    q.r(6, 15, 24, 26, 'ouro')
    q.r(10, 8, 17, 10, 'ouro_luz')
    q.coluna(6, 13, 26, 'ouro_sombra')
    q.r(11, 16, 14, 19, 'contorno'); q.r(17, 16, 20, 19, 'contorno')              # olhos
    q.r(15, 16, 16, 23, 'ouro_sombra')                                            # nariz
    q.r(11, 20, 14, 26, 'contorno'); q.r(17, 20, 20, 26, 'contorno')              # abertura da boca
    q.linha(26, 6, 24, 'ouro_sombra')
    return q.contornar()


ARMAS = {
    'espada_grande': espada_grande, 'machado_guerra': machado_guerra, 'arco': arco,
    'arco_curto': arco_curto,
    'espada_media': espada_media, 'machado_pequeno': machado_pequeno,
    'punhal': punhal, 'maca': maca,
}
PROTECOES = {'escudo': escudo, 'caixa_frutas': caixa_frutas, 'panela': panela}

# Cores de cada reino (e dos bandidos) em escudo, armaduras e elmo. Troca as
# cores do desenho-base: campo e penacho (azul, nuvem,
# azul_luz), aro e elmo (ouro), metal (pedra) e couro (madeira).
# Notas de cor de planos/direcao-de-arte.md: Olympia azuis frios; Ágape
# águas que brilham, tons quentes; Khronosses pedra clara e pergaminho.
REINOS = {
    'olympia': {   # costa gélida: azul frio com aro e elmo de aço claro
        'ouro_sombra': '#5E6673', 'ouro': '#8A92A0', 'ouro_luz': '#C9CED8',
    },
    'agape': {     # águas que brilham e tons quentes: campo turquesa, bronze
        'azul': '#1F5E63', 'nuvem': '#2F8A86', 'azul_luz': '#7FD1C4',
        'pedra_sombra': '#8A5E2C', 'pedra': '#B98543', 'pedra_luz': '#ECBD75', 'lua': '#F4D9A8',
        'madeira_sombra': '#5A2E1E', 'madeira': '#8A4A2C', 'madeira_luz': '#B86A3C',
    },
    'khronosses': {  # pedra clara e pergaminho, sóbrio
        'azul': '#3F4651', 'nuvem': '#5E6673', 'azul_luz': '#8A92A0',
        'ouro_sombra': '#7A7068', 'ouro': '#A69C92', 'ouro_luz': '#D8CFC4',
        'pedra_sombra': '#5E6673', 'pedra': '#8A92A0', 'pedra_luz': '#C9CED8', 'lua': '#F4EFE8',
    },
    'bandidos': {  # couro escuro, ferro velho e ferrugem
        'azul': '#2E2019', 'nuvem': '#4A3428', 'azul_luz': '#6B4A35',
        'ouro_sombra': '#1E2329', 'ouro': '#3F4651', 'ouro_luz': '#5E6673',
        'pedra_sombra': '#3A2A22', 'pedra': '#5C4535', 'pedra_luz': '#7A5A44', 'lua': '#9E7A5C',
        'madeira_sombra': '#1E1510', 'madeira': '#2E2019', 'madeira_luz': '#4A3428',
    },
}
# Peças que mudam de cor por reino: nome -> o que gerar.
POR_REINO = ['escudo', 'armadura_leve', 'armadura_pesada', 'elmo']


def recolorir(im, reino):
    troca = {C[nome]: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
             for nome, h in REINOS[reino].items()}
    if not troca:
        return im
    nova = im.copy()
    px = nova.load()
    for y in range(nova.height):
        for x in range(nova.width):
            if px[x, y] in troca:
                px[x, y] = troca[px[x, y]]
    return nova


def artes():
    saida = {}
    for nome, desenhar in {**ARMAS, **PROTECOES}.items():
        if nome not in POR_REINO:
            saida['%s/%s_na_mao.png' % (PASTA, nome)] = desenhar()
    saida['%s/flecha.png' % PASTA] = flecha()
    for nome, desenhar in ARMAS.items():
        if nome not in ('arco', 'arco_curto'):
            saida['%s/icone_%s.png' % (PASTA, nome)] = icone_arma(desenhar, nome)
    saida['%s/icone_arco.png' % PASTA] = icone_arco()
    saida['%s/icone_arco_curto.png' % PASTA] = icone_arco(arco_curto, 'arco_curto')
    saida['%s/icone_caixa_frutas.png' % PASTA] = _no_centro(caixa_frutas())
    saida['%s/icone_panela.png' % PASTA] = _no_centro(panela())
    base = {
        'icone_escudo': escudo(13, 14),
        'escudo_na_mao': None,
        'icone_armadura_leve': icone_couraca(False),
        'icone_armadura_pesada': icone_couraca(True),
        'icone_elmo': icone_elmo(),
    }
    base['escudo_na_mao'] = escudo()                                              # por último: fica a pega da mão
    for nome, desenhar in CAMADAS.items():
        base['%s_corpo' % nome] = folha_camada(desenhar)
    for reino in REINOS:
        for chave, im in base.items():
            # icone_escudo -> icone_escudo_agape; escudo_na_mao -> escudo_agape_na_mao
            for peca in POR_REINO:
                if peca in chave:
                    nome = chave.replace(peca, '%s_%s' % (peca, reino))
                    break
            saida['%s/%s.png' % (PASTA, nome)] = recolorir(im, reino)
    saida['assets/art/placeholders/exploracao/caixa_com_frutas.png'] = caixa_com_frutas_chao()
    saida['assets/art/placeholders/exploracao/frutas_no_chao.png'] = frutas_no_chao()
    return saida


# ---------- prévia: Nicholas parado e golpeando com cada item ----------

def _colar_girado(destino, item, pega, mao, giro, ox, oy):
    # Mesmo cálculo do ItemNaMao: gira em volta do centro do punho.
    lado = 2 * max(item.width, item.height) + 4
    tela = Image.new('RGBA', (lado, lado), (0, 0, 0, 0))
    c = lado // 2
    tela.alpha_composite(item, (c - pega[0] - 1, c - pega[1] - 1))
    tela = tela.rotate(-giro, resample=Image.NEAREST, center=(c, c))
    destino.alpha_composite(tela, (ox + mao[0] + 1 - c, oy + mao[1] + 1 - c))


GIROS = {'CORTE': [180, -90, 0], 'PANCADA': [160, -60, 20], 'ESTOCADA': [-120, -90, -60], 'TIRO': [0, 0, 0]}
ESTILO = {'espada_grande': 'CORTE', 'espada_media': 'CORTE', 'machado_guerra': 'PANCADA',
          'machado_pequeno': 'PANCADA', 'maca': 'PANCADA', 'punhal': 'ESTOCADA', 'arco': 'TIRO', 'arco_curto': 'TIRO'}


def previa(caminho):
    todas = artes()
    quadros = [('parado', 0)] + [('golpe', i) for i in range(3)]
    linhas = (list(ARMAS) + ['caixa_frutas', 'panela']
              + ['%s_%s' % (p, r) for p in POR_REINO for r in REINOS])
    escala = 3
    lw, lh = 60 + len(quadros) * 2 * nic.W, nic.HH + 4
    im = Image.new('RGBA', (lw, lh * len(linhas)), C['azul'])
    for li, nome in enumerate(linhas):
        oy = li * lh + 2
        im.alpha_composite(todas['%s/icone_%s.png' % (PASTA, nome)], (14, oy + 8))
        for qi, (anim, i) in enumerate(quadros):
            for di, d in enumerate(('frente', 'costas')):
                k = nic.ANIM[anim][i]
                ox = 60 + (qi * 2 + di) * nic.W
                im.alpha_composite(nic.nicholas(d, **k), (ox, oy))
                peca = next((p for p in POR_REINO if nome.startswith(p)), None)
                if peca in CAMADAS:
                    camada = todas['%s/%s_corpo.png' % (PASTA, nome)]
                    linha = nic.linhas_da_folha().index((d, anim))
                    im.alpha_composite(camada.crop((i * nic.W, linha * nic.HH, (i + 1) * nic.W,
                                                    (linha + 1) * nic.HH)), (ox, oy))
                elif nome in PROTECOES or peca:
                    _colar_girado(im, todas['%s/%s_na_mao.png' % (PASTA, nome)], PEGA[peca or nome],
                                  nic.mao_tras(d, **k), 0, ox, oy)
                else:
                    giro = GIROS[ESTILO[nome]][i] if anim == 'golpe' else 0
                    _colar_girado(im, todas['%s/%s_na_mao.png' % (PASTA, nome)], PEGA[nome],
                                  nic.mao(d, **k), giro, ox, oy)
    im = im.resize((im.width * escala, im.height * escala), Image.NEAREST)
    im.save(caminho)


if __name__ == '__main__':
    if len(sys.argv) > 2 and sys.argv[1] == '--previa':
        previa(sys.argv[2])
        print(sys.argv[2])
        sys.exit()
    os.makedirs(PASTA, exist_ok=True)
    for caminho, im in artes().items():
        im.save(caminho)
        print(caminho)
    for nome in CAMADAS:
        for reino in REINOS:
            png = '%s/%s_%s_corpo.png' % (PASTA, nome, reino)
            with open(png.replace('.png', '.tres'), 'w') as f:
                f.write(quadros_tres(png))
            print(png.replace('.png', '.tres'))
    for nome in list(ARMAS) + list(PROTECOES):
        print('pega_na_mao %s = Vector2i%s' % (nome, PEGA[nome]))
