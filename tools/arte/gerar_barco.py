# Gera a folha de Nicholas num barquinho a remo, para as rotas de mar no mapa de Hélade.
# Reaproveita o desenho de tools/arte/gerar_nicholas.py (cabelo prateado, manto claro
# com ombreira dourada, túnica azul-escura); só o tronco aparece acima do casco.
# Uso: python3 tools/arte/gerar_barco.py assets/art/mapa/barco/nicholas_barco.png [previa.png]
#
# Quadros de 48x48, desenhados indo para a direita (para a esquerda o jogo usa flip_h).
# Linha 0: barco_frente (proa para baixo e à direita); linha 1: barco_costas (proa
# para cima e à direita, Nicholas de costas). O fundo do casco fica perto da linha 44
# e a água chega à 46, então offset = Vector2(0, -22) põe a linha d'água no nó,
# igual ao sprite de andar.
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gerar_nicholas as gn  # noqa: E402

H = gn.H
C = dict(gn.C)
# Madeira e mar: as mesmas cores do mapa (gerar_mapa.py, dict P).
C.update(
    madeira_luz=H('#8A5E2C'), madeira=H('#6B5238'), madeira_junta=H('#4A3428'),
    madeira_fundo=H('#2E2019'),
    mar_raso=H('#24507A'), espuma=H('#7FA6C8'), lua=H('#C9CED8'),
)
W = HH = 48
POPA, PROA = 7, 42          # extremos do casco (x)
MEIO_Y = 38                 # borda de perto no meio do casco, sem balanço
NICK_X = 21                 # centro de Nicholas no barco


class Tela:
    def __init__(s):
        s.im = Image.new('RGBA', (W, HH), (0, 0, 0, 0))
        s.px = s.im.load()

    def p(s, x, y, c):
        if 0 <= x < W and 0 <= y < HH:
            s.px[x, y] = C[c]

    def linha(s, x0, y0, x1, y1, c):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            s.p(round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)

    def contornar(s):
        cheios = {(x, y) for x in range(W) for y in range(HH) if s.px[x, y][3]}
        for (x, y) in list(cheios):
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n not in cheios and 0 <= n[0] < W and 0 <= n[1] < HH:
                    s.px[n] = C['contorno']
        return s.im


def forma(t):
    """Meia largura do casco ao longo do comprimento (0 = popa, 1 = proa)."""
    if t < 0.5:   # popa larga e arredondada
        return min(1.0, math.sin(math.pi * t) ** 0.35 * 1.05)
    return math.sin(math.pi * t) ** 0.75   # proa fina


def casco(dir, dy):
    """Medidas de cada coluna: (borda de longe, borda de perto, fundo)."""
    inclina = 0.16 if dir == 'frente' else -0.16    # proa mais perto ou mais longe
    meio = (POPA + PROA) / 2
    cols = {}
    for x in range(POPA, PROA + 1):
        t = (x - POPA) / (PROA - POPA)
        yc = MEIO_Y - 3 + dy + inclina * (x - meio) - 2.5 * t ** 3   # proa sobe
        w = 3.0 * forma(t)
        longe = round(yc - w)
        perto = round(yc + w)
        fundo = perto + max(1, round(4.5 * forma(t) ** 0.6 - 2 * t ** 4))
        cols[x] = (longe, perto, fundo)
    return cols


def parte_de_tras(t, cols):
    """Borda de longe e o interior do barco (fica atrás de Nicholas)."""
    for x, (longe, perto, _) in cols.items():
        t.p(x, longe, 'madeira_luz')
        for y in range(longe + 1, perto):
            t.p(x, y, 'madeira_fundo' if y > longe + 1 else 'madeira_junta')
    # banco do remador
    for x in (NICK_X + 9,):
        if x in cols:
            longe, perto, _ = cols[x]
            for y in range(longe + 1, perto):
                t.p(x, y, 'madeira')


def parte_da_frente(t, cols):
    """Borda de perto (friso dourado) e o costado de tábuas."""
    for x, (longe, perto, fundo) in cols.items():
        t.p(x, perto, 'ouro' if POPA < x < PROA else 'madeira_luz')
        for i, y in enumerate(range(perto + 1, fundo + 1)):
            t.p(x, y, 'madeira_junta' if i == 2 else ('madeira_luz' if i == 0 else 'madeira'))
        t.p(x, fundo, 'madeira_junta')
    # brilho no friso e roda de proa levantada
    for x in range(POPA + 3, PROA - 6, 5):
        t.p(x, cols[x][1], 'ouro_luz')
    lp, pp, _ = cols[PROA]
    t.p(PROA + 1, lp - 1, 'madeira_luz'); t.p(PROA + 1, lp, 'madeira')
    # tábua da popa
    lp, pp, fp = cols[POPA]
    for y in range(lp, fp):
        t.p(POPA - 1, y, 'madeira_junta')


def nicholas(t, dir, dy, alcance, cols):
    corpo = gn.nicholas(dir, alcance=alcance, dy=0)
    perto = cols[NICK_X][1]
    # quadril (linha ~30 do sprite) fica atrás da borda de perto: o barco o esconde
    topo = perto - 29
    recorte = corpo.crop((0, 0, gn.W, 30))
    t.im.alpha_composite(recorte, (NICK_X - gn.CX, topo))
    return topo


def remo(t, dir, topo, alcance, fase, cols):
    """Remo seguro pela mão da frente; a pá entra na água à frente e sai atrás."""
    yt = topo + 19
    mx, my = NICK_X + 6 + alcance, yt + 3 + (1 if dir == 'costas' else 0)
    # fase: 0 pá entra à frente, 1 puxando (pá submersa), 2 pá sai atrás, 3 pá no ar voltando
    pa = {0: (mx + 8, 43), 1: (mx + 3, 44), 2: (mx - 1, 42), 3: (mx + 6, 39)}[fase]
    cabo = (mx - (pa[0] - mx) * 0.2, my - (pa[1] - my) * 0.2)
    t.linha(round(cabo[0]), round(cabo[1]), pa[0], pa[1] - 1, 'madeira_luz')
    t.p(mx, my, 'pele'); t.p(mx + 1, my, 'pele')
    if fase in (2, 3):   # pá fora d'água
        t.p(pa[0], pa[1], 'madeira'); t.p(pa[0], pa[1] + 1, 'madeira')
        t.p(pa[0] + 1, pa[1], 'madeira_luz'); t.p(pa[0] - 1, pa[1] + 1, 'madeira')
    return pa


def agua(dir, dy, fase, pa, cols):
    """Espuma, esteira e o anel de água em volta do casco (sem contorno)."""
    a = Tela()
    for x, (_, _, fundo) in cols.items():
        y = fundo + 1
        if (x + fase) % 4 != 0:
            a.p(x, y, 'mar_raso')
        if (x + fase) % 6 == 0:
            a.p(x, y + 1, 'espuma')
    # esteira atrás da popa (ondinhas que andam com a fase)
    _, perto, fundo = cols[POPA]
    for i in range(3):
        x = POPA - 3 - i * 3 - (fase % 2)
        y = fundo - 1 + i
        a.p(x, y, 'espuma'); a.p(x - 1, y, 'mar_raso')
    # marola na proa
    _, perto, fundo = cols[PROA]
    a.p(PROA + 2, fundo + 1, 'espuma'); a.p(PROA + 3, fundo + 1 + fase % 2, 'lua')
    # respingo onde a pá toca a água
    x, y = pa
    if fase in (0, 1):
        a.p(x - 1, y + 1, 'espuma'); a.p(x + 1, y + 1, 'espuma'); a.p(x, y + 2, 'lua')
    elif fase == 2:
        a.p(x - 1, y + 3, 'espuma'); a.p(x, y + 3, 'lua'); a.p(x + 1, y + 4, 'espuma')
    return a.im


def quadro(dir, fase):
    dy = (0, 1, 1, 0)[fase]
    alcance = (3, 2, 1, 2)[fase]
    cols = casco(dir, dy)
    t = Tela()
    parte_de_tras(t, cols)
    topo = nicholas(t, dir, dy, alcance, cols)
    parte_da_frente(t, cols)
    pa = remo(t, dir, topo, alcance, fase, cols)
    barco = t.contornar()
    final = agua(dir, dy, fase, pa, cols)
    final.alpha_composite(barco)
    return final


DIRS = ['frente', 'costas']
FASES = 4


def folha():
    im = Image.new('RGBA', (W * FASES, HH * len(DIRS)), (0, 0, 0, 0))
    for li, d in enumerate(DIRS):
        for f in range(FASES):
            im.paste(quadro(d, f), (f * W, li * HH))
    return im


def previa(im, escala=4):
    """Folha ampliada sobre o azul do mar, para conferir a leitura."""
    fundo = Image.new('RGBA', im.size, C['mar_raso'][:3] + (255,))
    fundo.paste((23, 52, 82, 255), (0, 0) + im.size)   # mar #173452
    fundo.alpha_composite(im)
    return fundo.resize((im.width * escala, im.height * escala), Image.NEAREST)


if __name__ == '__main__':
    f = folha()
    f.save(sys.argv[1])
    if len(sys.argv) > 2:
        previa(f).save(sys.argv[2])
