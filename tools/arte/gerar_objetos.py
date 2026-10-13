# Gera as artes provisórias em pixel art de objetos, itens e figurantes da
# exploração, na paleta de Hélade (as 12 cores da capa e tons vizinhos).
# Nada aqui é do livro: são peças genéricas para testar até a arte final.
# Uso: python3 tools/arte/gerar_objetos.py   (rodar na raiz do projeto)
import os
from PIL import Image

H = lambda h: tuple(int(h[i:i+2], 16) for i in (1, 3, 5)) + (255,)
C = dict(
    contorno=H('#050C14'), noite=H('#050C14'),
    azul=H('#13253C'), nuvem=H('#2B3D55'), azul_luz=H('#3E5470'),
    pedra_sombra=H('#3F4651'), pedra=H('#5E6673'), pedra_luz=H('#8A92A0'),
    lua=H('#C9CED8'), branco=H('#F4EFE8'),
    prata_sombra=H('#A69C92'), prata=H('#D8CFC4'),
    olho_escuro=H('#2B3D55'), olho=H('#9FB8D2'), olho_luz=H('#D4E2EF'),
    ouro_sombra=H('#8A5E2C'), ouro=H('#B98543'), ouro_luz=H('#ECBD75'),
    vela=H('#F2A65A'), vela_escura=H('#C2702F'),
    pele_luz=H('#E6C6B4'), pele=H('#C8A08E'), pele_sombra=H('#9E7468'),
    madeira_luz=H('#6B4A35'), madeira=H('#4A3428'), madeira_sombra=H('#2E2019'),
    # folhagem ao luar: os únicos tons esverdeados, puxados para o azul da noite
    folha_sombra=H('#1C3236'), folha=H('#2F4B4F'), folha_luz=H('#4A6866'),
    sombra=(5, 12, 20, 90),
)


class Q:
    def __init__(s, w, h):
        s.w, s.h = w, h
        s.im = Image.new('RGBA', (w, h), (0, 0, 0, 0)); s.px = s.im.load()

    def p(s, x, y, c):
        if 0 <= x < s.w and 0 <= y < s.h: s.px[x, y] = C[c]

    def r(s, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1): s.p(x, y, c)

    def linha(s, y, x0, x1, c): s.r(x0, y, x1, y, c)
    def coluna(s, x, y0, y1, c): s.r(x, y0, x, y1, c)

    def elipse(s, cx, cy, rx, ry, c):
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                if ((x - cx) / (rx + .5)) ** 2 + ((y - cy) / (ry + .5)) ** 2 <= 1: s.p(x, y, c)

    def contornar(s, sombra_chao=None):
        cheios = {(x, y) for x in range(s.w) for y in range(s.h) if s.px[x, y][3] == 255}
        for (x, y) in list(cheios):
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n not in cheios and 0 <= n[0] < s.w and 0 <= n[1] < s.h:
                    s.px[n] = C['contorno']
        return s.im

    def sombra_no_chao(s, cx, cy, rx, ry):
        # sombra suave nos pés, desenhada antes do objeto
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                if ((x - cx) / (rx + .5)) ** 2 + ((y - cy) / (ry + .5)) ** 2 <= 1 and 0 <= x < s.w and 0 <= y < s.h:
                    s.px[x, y] = C['sombra']


# ---------- ícones da bolsa (32×32) ----------

def icone_espada():
    q = Q(32, 32)
    # lâmina na diagonal, da guarda (embaixo, à esquerda) até a ponta
    for i in range(17):
        x, y = 10 + i, 21 - i
        q.p(x, y, 'lua'); q.p(x + 1, y, 'pedra_luz'); q.p(x, y - 1, 'branco')
        q.p(x + 1, y + 1, 'pedra')
    q.p(27, 4, 'branco'); q.p(28, 3, 'branco')
    # guarda dourada atravessada
    for i in range(-4, 5):
        q.p(9 + i, 18 + i, 'ouro'); q.p(10 + i, 18 + i, 'ouro_sombra')
    q.p(5, 14, 'ouro_luz'); q.p(13, 22, 'ouro_luz')
    # cabo de couro
    for i in range(4):
        q.p(8 - i, 23 + i, 'madeira'); q.p(7 - i, 23 + i, 'madeira_luz'); q.p(8 - i, 24 + i, 'madeira_sombra')
    # pomo
    q.r(2, 27, 4, 29, 'ouro'); q.p(2, 27, 'ouro_luz'); q.p(4, 29, 'ouro_sombra')
    return q.contornar()


def icone_pocao():
    q = Q(32, 32)
    q.elipse(16, 20, 9, 8, 'olho_escuro')                   # vidro
    q.elipse(16, 21, 8, 6, 'olho')                          # líquido
    q.r(9, 18, 23, 18, 'olho_luz')                          # superfície
    q.elipse(18, 23, 5, 3, 'olho_luz')
    q.r(13, 9, 19, 12, 'olho_escuro')                       # gargalo
    q.r(14, 10, 18, 12, 'nuvem')
    q.r(12, 8, 20, 9, 'pedra_luz')                          # boca
    q.r(14, 4, 18, 7, 'madeira')                            # rolha
    q.r(14, 4, 15, 7, 'madeira_luz'); q.linha(7, 14, 18, 'madeira_sombra')
    q.r(10, 15, 12, 17, 'branco'); q.p(11, 14, 'branco')    # reflexo
    q.p(10, 21, 'lua')
    q.linha(13, 12, 20, 'ouro'); q.p(16, 13, 'ouro_luz')    # cordão dourado
    return q.contornar()


def icone_carta():
    q = Q(32, 32)
    q.r(4, 8, 27, 25, 'prata')                              # papel
    q.r(4, 22, 27, 25, 'prata_sombra')
    for i in range(12):                                     # aba dobrada
        q.linha(8 + i, 4 + i, 27 - i, 'lua' if i < 10 else 'prata')
    for i in range(12):
        q.p(4 + i, 8 + i, 'prata_sombra'); q.p(27 - i, 8 + i, 'prata_sombra')
    q.r(5, 8, 26, 8, 'branco')
    q.elipse(16, 19, 3, 3, 'vela_escura')                   # lacre
    q.elipse(16, 19, 2, 2, 'ouro')
    q.p(15, 18, 'ouro_luz'); q.p(17, 21, 'ouro_sombra')
    q.r(5, 24, 26, 24, 'ouro_sombra')                       # friso dourado
    return q.contornar()


# ---------- objetos da exploração (no chão, base na linha de baixo) ----------

def bau(aberto):
    q = Q(26, 24)
    q.sombra_no_chao(13, 21, 12, 2)
    base, topo = 21, 12
    q.r(2, topo, 23, base, 'madeira')                       # corpo
    q.r(2, topo, 4, base, 'madeira_sombra')
    q.r(5, topo + 1, 22, topo + 1, 'madeira_luz')
    for y in (topo + 4, topo + 7):
        q.linha(y, 5, 22, 'madeira_sombra')                 # tábuas
    for x in (3, 21):                                       # cintas douradas
        q.r(x, topo, x + 1, base, 'ouro'); q.coluna(x, topo, base, 'ouro_sombra')
    q.linha(base, 2, 23, 'madeira_sombra')
    if aberto:
        q.r(3, 4, 22, topo - 1, 'madeira_sombra')           # tampa erguida, vista por dentro
        q.r(5, 5, 20, topo - 2, 'madeira')
        q.r(3, 4, 22, 4, 'ouro')
        q.r(3, topo - 1, 22, topo - 1, 'noite')             # boca do baú
        q.r(4, topo, 21, topo + 1, 'noite')
        q.p(9, topo, 'ouro_luz'); q.p(15, topo + 1, 'ouro_luz'); q.p(17, topo, 'ouro')
        q.r(12, topo + 2, 13, topo + 4, 'ouro_sombra')      # fecho solto
    else:
        q.r(2, 6, 23, topo - 1, 'madeira')                  # tampa abaulada
        q.linha(5, 4, 21, 'madeira')
        q.r(4, 6, 21, 7, 'madeira_luz')
        q.r(2, 6, 4, topo - 1, 'madeira_sombra')
        for x in (3, 21):
            q.r(x, 5, x + 1, topo - 1, 'ouro'); q.p(x + 1, 6, 'ouro_luz')
        q.linha(topo - 1, 2, 23, 'ouro_sombra')
        q.r(11, topo - 2, 14, topo + 2, 'ouro')             # fecho
        q.p(12, topo - 1, 'ouro_luz'); q.p(12, topo + 1, 'noite')
    return q.contornar()


def anfora():
    q = Q(18, 26)
    q.sombra_no_chao(9, 23, 6, 2)
    q.r(7, 21, 11, 23, 'ouro_sombra')                       # pé
    q.elipse(9, 14, 6, 7, 'ouro_sombra')                    # bojo
    q.elipse(8, 13, 5, 6, 'ouro')
    q.r(6, 9, 7, 12, 'ouro_luz')
    q.r(7, 3, 11, 7, 'ouro')                                # gargalo
    q.r(7, 3, 7, 7, 'ouro_luz')
    q.r(6, 2, 12, 3, 'ouro_sombra')                         # boca
    for x in (4, 13):                                       # alças
        q.coluna(x, 5, 9, 'ouro_sombra')
    q.p(5, 4, 'ouro_sombra'); q.p(12, 4, 'ouro_sombra')
    q.linha(11, 4, 14, 'noite')                             # faixas de figura negra
    q.linha(16, 4, 14, 'noite')
    for x in range(5, 14, 2): q.p(x, 13, 'noite'); q.p(x + 1, 14, 'noite')
    return q.contornar()


def braseiro():
    q = Q(18, 30)
    q.sombra_no_chao(9, 27, 6, 2)
    q.r(5, 26, 13, 27, 'pedra_sombra')                      # base
    q.r(7, 16, 11, 25, 'pedra')                             # coluna
    q.coluna(7, 16, 25, 'pedra_luz'); q.coluna(11, 16, 25, 'pedra_sombra')
    q.r(3, 13, 15, 15, 'pedra')                             # bacia
    q.linha(13, 3, 15, 'pedra_luz'); q.linha(15, 4, 14, 'pedra_sombra')
    q.linha(16, 5, 13, 'pedra_sombra')
    # fogo
    q.elipse(9, 9, 4, 4, 'vela_escura')
    q.elipse(9, 10, 3, 3, 'vela')
    q.r(8, 4, 10, 8, 'vela'); q.p(9, 2, 'vela'); q.p(9, 3, 'vela'); q.p(6, 5, 'vela_escura'); q.p(12, 6, 'vela_escura')
    q.r(8, 8, 10, 12, 'ouro_luz'); q.p(9, 6, 'ouro_luz'); q.p(9, 11, 'branco')
    return q.contornar()


def placa():
    q = Q(22, 30)
    q.sombra_no_chao(11, 27, 4, 1)
    q.r(10, 14, 11, 27, 'madeira')                          # poste
    q.coluna(10, 14, 27, 'madeira_luz')
    q.r(2, 3, 19, 14, 'madeira')                            # tábua
    q.linha(3, 2, 19, 'madeira_luz'); q.linha(14, 2, 19, 'madeira_sombra')
    q.coluna(19, 3, 14, 'madeira_sombra')
    q.linha(8, 3, 18, 'madeira_sombra')
    for y, (a, b) in ((5, (5, 16)), (6, (5, 12)), (10, (5, 15)), (11, (5, 10))):
        q.linha(y, a, b, 'ouro')                            # letras pintadas
    q.p(3, 4, 'pedra_luz'); q.p(18, 4, 'pedra_luz'); q.p(3, 13, 'pedra_luz'); q.p(18, 13, 'pedra_luz')
    return q.contornar()


def arvore():
    q = Q(44, 60)
    q.sombra_no_chao(22, 56, 13, 3)
    q.r(19, 36, 24, 56, 'madeira')                          # tronco
    q.r(19, 36, 20, 56, 'madeira_luz'); q.coluna(24, 36, 56, 'madeira_sombra')
    q.p(18, 56, 'madeira'); q.p(25, 56, 'madeira'); q.p(17, 56, 'madeira_sombra')
    q.r(21, 44, 22, 45, 'madeira_sombra')
    q.r(24, 32, 27, 34, 'madeira')                          # galho
    # copa em tufos, do fundo para a frente
    for (cx, cy, rx, ry, c) in [(22, 18, 17, 14, 'folha_sombra'), (12, 26, 9, 8, 'folha_sombra'),
                                (32, 26, 9, 8, 'folha_sombra'), (22, 32, 12, 6, 'folha_sombra'),
                                (20, 15, 13, 10, 'folha'), (11, 24, 7, 6, 'folha'), (30, 23, 8, 6, 'folha'),
                                (22, 28, 9, 5, 'folha')]:
        q.elipse(cx, cy, rx, ry, c)
    for (cx, cy, rx, ry) in [(16, 10, 5, 3), (25, 12, 4, 3), (10, 21, 3, 2), (28, 20, 4, 2), (19, 24, 4, 2)]:
        q.elipse(cx, cy, rx, ry, 'folha_luz')
    for (x, y) in [(14, 8), (17, 9), (24, 10), (9, 20), (27, 19), (18, 23)]:
        q.p(x, y, 'lua')                                    # luar nas folhas
    return q.contornar()


# ---------- figurantes (32×48, pés na linha 45, como o Nicholas) ----------

def guarda():
    q = Q(32, 48)
    q.sombra_no_chao(16, 45, 8, 2)
    x = 16
    # lança à direita, de pé
    q.coluna(x + 8, 4, 45, 'madeira'); q.coluna(x + 9, 6, 45, 'madeira_sombra')
    q.r(x + 8, 1, x + 9, 5, 'lua'); q.p(x + 8, 0, 'branco'); q.p(x + 9, 3, 'pedra')
    # pernas e grevas
    for px in (x - 4, x + 1):
        q.r(px, 32, px + 2, 41, 'pele_sombra')
        q.r(px, 36, px + 2, 42, 'pedra'); q.coluna(px, 36, 42, 'pedra_luz')
        q.r(px, 43, px + 3, 45, 'madeira'); q.linha(45, px, px + 3, 'madeira_sombra')
    # saiote de tiras
    q.r(x - 6, 28, x + 5, 33, 'azul')
    for px in range(x - 6, x + 6, 2): q.coluna(px, 29, 33, 'nuvem')
    # couraça
    q.r(x - 6, 17, x + 5, 28, 'pedra')
    q.r(x - 5, 18, x - 3, 27, 'pedra_luz'); q.coluna(x + 5, 17, 28, 'pedra_sombra')
    q.linha(28, x - 6, x + 5, 'ouro')
    q.r(x - 1, 20, x, 23, 'pedra_sombra')
    # capa curta azul atrás do ombro esquerdo
    q.r(x - 8, 17, x - 7, 30, 'nuvem'); q.coluna(x - 8, 20, 30, 'azul')
    # braços
    q.r(x - 7, 18, x - 6, 27, 'pele'); q.r(x - 7, 28, x - 6, 29, 'pele_sombra')
    q.r(x + 6, 18, x + 7, 24, 'pele'); q.r(x + 6, 25, x + 8, 26, 'pele_sombra')   # mão na lança
    q.r(x - 7, 17, x - 5, 19, 'ouro'); q.r(x + 4, 17, x + 7, 19, 'ouro')          # ombreiras
    # cabeça com elmo
    q.r(x - 3, 9, x + 3, 15, 'pele'); q.coluna(x - 3, 9, 15, 'pele_sombra')
    q.p(x - 1, 11, 'olho_escuro'); q.p(x + 2, 11, 'olho_escuro')
    q.r(x - 4, 3, x + 4, 9, 'pedra'); q.r(x - 3, 3, x - 1, 6, 'pedra_luz')
    q.coluna(x - 4, 9, 14, 'pedra'); q.coluna(x + 4, 9, 14, 'pedra_sombra')    # abas
    q.linha(9, x - 4, x + 4, 'ouro_sombra')
    q.r(x - 1, 0, x + 1, 3, 'azul'); q.r(x - 4, 1, x - 2, 2, 'azul_luz')          # penacho
    q.p(x + 2, 1, 'azul')
    return q.contornar()


def criada():
    q = Q(32, 48)
    q.sombra_no_chao(16, 45, 8, 2)
    x = 16
    # vestido longo
    for y in range(18, 45):
        meia = 5 + (y - 18) // 5
        q.linha(y, x - meia, x + meia - 1, 'nuvem')
        q.p(x - meia, y, 'azul')
    q.linha(44, x - 10, x + 9, 'azul')
    # avental claro
    q.r(x - 4, 26, x + 3, 42, 'prata'); q.coluna(x - 4, 26, 42, 'prata_sombra')
    q.linha(25, x - 5, x + 4, 'prata_sombra')
    q.r(x + 7, 41, x + 8, 44, 'madeira_sombra')               # sapato aparecendo
    # corpete e braços
    q.r(x - 5, 17, x + 4, 25, 'nuvem'); q.r(x - 5, 17, x - 4, 25, 'azul')
    q.r(x - 7, 18, x - 6, 27, 'nuvem'); q.r(x - 7, 28, x - 6, 29, 'pele')
    q.r(x + 5, 18, x + 6, 27, 'nuvem'); q.r(x + 5, 28, x + 6, 29, 'pele')
    q.r(x - 2, 16, x + 2, 17, 'prata')                        # gola
    # cabeça
    q.r(x - 3, 8, x + 3, 15, 'pele'); q.coluna(x - 3, 8, 15, 'pele_sombra')
    q.r(x + 2, 9, x + 3, 10, 'pele_luz')
    q.p(x - 1, 11, 'olho_escuro'); q.p(x + 2, 11, 'olho_escuro'); q.p(x + 1, 13, 'pele_sombra')
    q.r(x - 4, 4, x + 4, 8, 'madeira'); q.r(x - 4, 8, x - 4, 13, 'madeira')    # cabelo castanho
    q.r(x - 2, 4, x + 1, 5, 'madeira_luz')
    q.elipse(x - 4, 4, 2, 2, 'madeira_sombra')                # coque
    q.linha(7, x - 3, x + 4, 'prata')                         # lenço
    return q.contornar()


ARTES = {
    'assets/art/placeholders/itens/icone_espada.png': icone_espada,
    'assets/art/placeholders/itens/icone_pocao.png': icone_pocao,
    'assets/art/placeholders/itens/icone_carta.png': icone_carta,
    'assets/art/placeholders/exploracao/bau_fechado.png': lambda: bau(False),
    'assets/art/placeholders/exploracao/bau_aberto.png': lambda: bau(True),
    'assets/art/placeholders/exploracao/anfora.png': anfora,
    'assets/art/placeholders/exploracao/braseiro.png': braseiro,
    'assets/art/placeholders/exploracao/placa.png': placa,
    'assets/art/placeholders/exploracao/arvore.png': arvore,
    'assets/art/placeholders/exploracao/guarda_provisorio.png': guarda,
    'assets/art/placeholders/exploracao/criada_provisoria.png': criada,
}

if __name__ == '__main__':
    for caminho, desenhar in ARTES.items():
        os.makedirs(os.path.dirname(caminho), exist_ok=True)
        desenhar().save(caminho)
        print(caminho)
