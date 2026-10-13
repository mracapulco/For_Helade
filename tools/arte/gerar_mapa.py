# Gera o mapa de Hélade em pixel art (tela de viagem, estilo mapa do Super Mario World).
# O mapa enviado pelo Rafael serve só de referência de geografia; a arte é toda gerada aqui.
# Uso: python3 tools/arte/gerar_mapa.py assets/art/mapa/mapa_helade.png
# 1 pixel aqui = 1 pixel da arte; no jogo a câmera amplia 2x.
import math
import random
import sys

import numpy as np
from PIL import Image, ImageDraw

W, H = 1664, 1280
SEMENTE = 20  # 20º Ciclo
random.seed(SEMENTE)
rng = np.random.default_rng(SEMENTE)

hx = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
# Paleta: as 12 cores da capa (planos/direcao-de-arte.md) mais tons de terra e
# vegetação para o mapa, todos noturnos e puxados para o azul.
P = dict(
    noite=hx('#050C14'), azul_noite=hx('#13253C'), nuvem=hx('#2B3D55'), pedra=hx('#5E6673'),
    lua=hx('#C9CED8'), prata=hx('#D8CFC4'), olhos=hx('#9FB8D2'),
    ouro_escuro=hx('#8A5E2C'), ouro=hx('#B98543'), ouro_claro=hx('#ECBD75'), vela=hx('#F2A65A'),
    mar_fundo=hx('#0E2238'), mar=hx('#173452'), mar_raso=hx('#24507A'), espuma=hx('#7FA6C8'),
    areia=hx('#B8A27A'), areia_sombra=hx('#8E7A58'),
    gelo=hx('#DCE4EC'), gelo_sombra=hx('#A9B8C8'), geada=hx('#7E909A'), geada_escura=hx('#5C6E78'),
    grama_luz=hx('#6E8A52'), grama=hx('#4F6B3F'), grama_sombra=hx('#3A5232'),
    campo=hx('#8C8A4E'), campo_sombra=hx('#6F6C3C'), campo_quente=hx('#A3804A'),
    mata=hx('#2C4A33'), mata_escura=hx('#1C3226'), mata_luz=hx('#3F6545'),
    rocha_luz=hx('#9A9AA0'), rocha=hx('#6E6E78'), rocha_sombra=hx('#46465A'),
    terra=hx('#6B5238'), telhado=hx('#7A3A32'), telhado_luz=hx('#A0503E'),
    marmore=hx('#E4E0D8'), marmore_sombra=hx('#B0AAA0'),
)

# Pontos e estradas lidos de data/mapa/*.tres, para a arte e o jogo baterem.
def ler_pontos(pasta):
    import os
    import re
    pontos, estradas = {}, []
    for nome in sorted(os.listdir(pasta)):
        if not nome.endswith('.tres'):
            continue
        txt = open(os.path.join(pasta, nome), encoding='utf-8').read()
        ident = re.search(r'^id = "(.+)"', txt, re.M).group(1)
        x, y = re.search(r'^posicao = Vector2\(([-\d.]+), ([-\d.]+)\)', txt, re.M).groups()
        pontos[ident] = (int(float(x)), int(float(y)))
        viz = re.search(r'^vizinhos = Array\[String\]\(\[(.*)\]\)', txt, re.M)
        for outro in re.findall(r'"([^"]+)"', viz.group(1)) if viz else []:
            estradas.append((ident, outro))
    return pontos, estradas


PASTA_DADOS = __file__.rsplit('/tools/', 1)[0] + '/data/mapa'
PONTOS, ESTRADAS = ler_pontos(PASTA_DADOS)
# Regiões que ganham desenho próprio.
LOCAIS = {k: PONTOS[k] for k in ('norte', 'templo', 'atenas', 'agape', 'floresta_ninfas', 'olympia')}

# ---------------------------------------------------------------- terreno
COSTA = [(70, 70), (420, 40), (700, 52), (820, 100), (900, 66), (1030, 130), (1080, 250),
         (1160, 320), (1130, 450), (1170, 560), (1110, 650), (1160, 760), (1190, 880),
         (1090, 960), (1010, 1030), (970, 1140), (870, 1220), (710, 1230), (650, 1150),
         (560, 1110), (420, 1090), (300, 1050), (200, 990), (140, 890), (110, 770),
         (160, 650), (110, 570), (60, 480), (210, 440), (240, 385), (100, 330), (60, 210)]
ILHAS = [((1326, 630), (128, 104)), ((1418, 770), (52, 40)), ((1250, 790), (30, 22)),
         ((1530, 520), (24, 18))]


def ruido(escala, oitavas=3):
    """Ruído suave (value noise) do tamanho do mapa, entre -1 e 1."""
    total = np.zeros((H, W))
    amp, soma = 1.0, 0.0
    for o in range(oitavas):
        passo = max(4, int(escala / (2 ** o)))
        gh, gw = H // passo + 2, W // passo + 2
        grade = rng.uniform(-1, 1, (gh, gw))
        ys = np.arange(H) / passo
        xs = np.arange(W) / passo
        y0 = ys.astype(int); x0 = xs.astype(int)
        fy = (ys - y0)[:, None]; fx = (xs - x0)[None, :]
        fy = fy * fy * (3 - 2 * fy); fx = fx * fx * (3 - 2 * fx)
        a = grade[y0][:, x0]; b = grade[y0][:, x0 + 1]
        c = grade[y0 + 1][:, x0]; d = grade[y0 + 1][:, x0 + 1]
        total += amp * ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy)
        soma += amp
        amp *= 0.5
    return total / soma


def poligono(pontos):
    im = Image.new('L', (W, H), 0)
    ImageDraw.Draw(im).polygon(pontos, fill=255)
    return np.array(im) > 0


def elipse(centro, raio):
    im = Image.new('L', (W, H), 0)
    (cx, cy), (rx, ry) = centro, raio
    ImageDraw.Draw(im).ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
    return np.array(im) > 0


def distancia(mascara, maximo=40):
    """Distância (em px, aproximada) até o pixel verdadeiro mais próximo."""
    d = np.where(mascara, 0, maximo).astype(np.int32)
    for _ in range(maximo):
        viz = np.minimum.reduce([np.roll(d, 1, 0), np.roll(d, -1, 0), np.roll(d, 1, 1), np.roll(d, -1, 1)]) + 1
        novo = np.minimum(d, viz)
        if (novo == d).all():
            break
        d = novo
    return d


def deformar(mascara, intensidade, escala):
    """Bordas irregulares: desloca a máscara com ruído."""
    dx = (ruido(escala, 2) * intensidade).astype(int)
    dy = (ruido(escala, 2) * intensidade).astype(int)
    yy, xx = np.mgrid[0:H, 0:W]
    return mascara[np.clip(yy + dy, 0, H - 1), np.clip(xx + dx, 0, W - 1)]


YY, XX = np.mgrid[0:H, 0:W]
terra = deformar(poligono(COSTA), 22, 90)
for centro, raio in ILHAS:
    terra |= deformar(elipse(centro, raio), 12, 50)
# Baía e lago para quebrar a linha da costa.
terra &= ~deformar(elipse((150, 500), (70, 40)), 10, 40)
lago = deformar(elipse((620, 560), (34, 22)), 6, 30)
terra &= ~lago

dist_mar = distancia(~terra, 40)        # dentro da terra: distância até a água
dist_terra = distancia(terra, 40)       # no mar: distância até a terra

n_alto = ruido(140, 4)
n_det = ruido(24, 2)

montanha = deformar(poligono([(70, 70), (820, 80), (870, 230), (760, 420), (600, 560),
                              (380, 600), (180, 560), (90, 450)]), 30, 70)
neve = montanha & (YY + n_alto * 60 < 380)
mata_ne = deformar(poligono([(700, 430), (1000, 250), (1110, 420), (1100, 600), (980, 650),
                             (800, 600)]), 34, 60)
mata_so = deformar(poligono([(200, 930), (560, 880), (640, 1000), (560, 1080), (300, 1040)]), 30, 50)
mata_ilha = elipse((1326, 630), (118, 96)) | elipse((1418, 770), (44, 32))
mata = (mata_ne | mata_so | mata_ilha) & ~montanha
frio = deformar(elipse((790, 1110), (200, 120)), 24, 60) & (YY > 960)  # costa gélida de Olympia
campos = (deformar(elipse(LOCAIS['atenas'], (190, 130)), 40, 70)
          | deformar(elipse(LOCAIS['agape'], (170, 120)), 40, 70)) & ~montanha & ~mata & ~frio
quente = elipse(LOCAIS['agape'], (230, 170))

# Rios: descem das montanhas e do lago até o mar, com curvas.
RIOS = [
    [(630, 584), (680, 650), (705, 740), (690, 830), (640, 920), (592, 1010), (560, 1100), (548, 1160)],
    [(800, 190), (880, 176), (960, 160), (1030, 120), (1060, 96)],
    [(300, 590), (240, 640), (180, 690), (110, 724)],
    [(1000, 470), (1060, 520), (1110, 560), (1180, 580)],
]


def meandro(pontos, nivel=4):
    """Divide cada trecho e desloca o meio para o lado, para o rio serpentear."""
    for _ in range(nivel):
        novo = [pontos[0]]
        for (x0, y0), (x1, y1) in zip(pontos, pontos[1:]):
            mx, my = (x0 + x1) / 2, (y0 + y1) / 2
            nx, ny = -(y1 - y0), (x1 - x0)
            tam = math.hypot(nx, ny) or 1
            desvio = random.uniform(-0.18, 0.18) * math.hypot(x1 - x0, y1 - y0)
            novo += [(mx + nx / tam * desvio, my + ny / tam * desvio), (x1, y1)]
        pontos = novo
    return pontos


img_rio = Image.new('L', (W, H), 0)
d_rio = ImageDraw.Draw(img_rio)
for curso in RIOS:
    pts = meandro(curso)
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        largura = 3 + int(4 * i / len(pts))  # mais largo perto da foz
        d_rio.line([a, b], fill=255, width=largura)
        d_rio.ellipse((b[0] - largura / 2, b[1] - largura / 2, b[0] + largura / 2, b[1] + largura / 2), fill=255)
rio = (np.array(img_rio) > 0) & terra
margem_rio = distancia(rio, 6) <= 1

# ---------------------------------------------------------------- pintura
img = np.zeros((H, W, 3), dtype=np.uint8)


def pinta(mascara, cor):
    img[mascara] = P[cor]


xadrez = ((XX + YY) % 2 == 0)
# Mar: fundo, médio e raso perto da costa, com ondinhas.
pinta(~terra, 'mar_fundo')
pinta(~terra & (dist_terra < 34 + n_det * 8), 'mar')
pinta(~terra & (dist_terra < 12 + n_det * 4), 'mar_raso')
pinta(~terra & (dist_terra == 1), 'espuma')
pinta(~terra & (dist_terra == 3) & xadrez, 'espuma')
pinta(lago & (dist_terra > 2), 'mar_raso')

# Terra: grama com manchas.
pinta(terra, 'grama')
pinta(terra & (n_det > 0.25), 'grama_luz')
pinta(terra & (n_det < -0.35), 'grama_sombra')
# Campos cultivados em lotes (Atenas e Ágape), com cercas de grama escura.
lote_y = YY // 12
largura = 14 + ((lote_y * 37 + 11) % 4) * 6  # cada faixa com lotes de largura própria
deslocado = XX + lote_y * 23
lote_x = deslocado // largura
sorteio = (lote_x * 7919 + lote_y * 104729 + SEMENTE) % 5
for n, cor in enumerate(['campo', 'campo_sombra', 'grama_luz', 'campo', 'campo_quente']):
    pinta(campos & (sorteio == n) & (quente | (n != 4)), cor)
    if n == 4:
        pinta(campos & (sorteio == n) & ~quente, 'campo_sombra')
cerca = (deslocado % largura == 0) | (YY % 12 == 0)
pinta(campos & cerca, 'grama_sombra')
# Costa gélida: geada e gelo.
pinta(terra & frio, 'gelo_sombra')
pinta(terra & frio & (n_det > 0.1), 'gelo')
pinta(terra & frio & (n_det < -0.35), 'geada')
# Areia na beira (menos no frio, onde vira gelo).
praia = terra & (dist_mar <= 4 + (n_det > 0).astype(int) * 2)
pinta(praia & ~frio, 'areia')
pinta(praia & ~frio & (dist_mar == 1), 'areia_sombra')
pinta(praia & frio, 'gelo')
# Chão de montanha e neve.
pinta(montanha & terra, 'rocha')
pinta(montanha & terra & (n_det > 0.15), 'rocha_luz')
pinta(neve & terra, 'gelo_sombra')
pinta(neve & terra & (n_det > -0.1), 'gelo')
# Chão da mata.
pinta(mata & terra & ~praia, 'mata_escura')

# Clareiras em volta dos locais, para os desenhos não ficarem no meio da mata.
for (lx, ly) in LOCAIS.values():
    clareira = terra & (((XX - lx) / 1.4) ** 2 + (YY - ly + 12) ** 2 < (40 + n_det * 6) ** 2)
    pinta(clareira & ~frio & ~neve, 'grama')
    pinta(clareira & ~frio & ~neve & (n_det > 0.3), 'grama_luz')

# Rios (antes das trilhas, que passam por cima como pontes).
pinta(margem_rio & ~rio & terra, 'noite')
pinta(rio, 'mar_raso')
pinta(rio & (n_det > 0.2) & xadrez, 'espuma')

# Trilhas de terra batida por baixo das estradas (o jogo desenha os pontos por cima).
img_estrada = Image.new('L', (W, H), 0)
d_estrada = ImageDraw.Draw(img_estrada)
for a, b in ESTRADAS:
    d_estrada.line([PONTOS[a], PONTOS[b]], fill=255, width=26)
perto_estrada = np.array(img_estrada) > 0
img_trilha = Image.new('L', (W, H), 0)
d_trilha = ImageDraw.Draw(img_trilha)
for a, b in ESTRADAS:
    d_trilha.line([PONTOS[a], PONTOS[b]], fill=255, width=7)
for (px, py) in PONTOS.values():
    d_trilha.ellipse((px - 11, py - 7, px + 11, py + 7), fill=255)
trilha = (np.array(img_trilha) > 0) & terra
pinta(trilha & ~frio & ~neve, 'terra')
pinta(trilha & (frio | neve), 'geada')
# Pontes de madeira onde a estrada cruza um rio.
ponte = trilha & (distancia(rio, 4) <= 1)
pinta(ponte, 'ouro_escuro')
pinta(ponte & (XX % 2 == 0), 'terra')

# Flores e tufos na grama: detalhe que aparece com o zoom.
grama_livre = terra & ~montanha & ~mata & ~campos & ~frio & ~trilha & ~rio & ~praia
sorteio_px = rng.random((H, W))
pinta(grama_livre & (sorteio_px < 0.004), 'ouro_claro')
pinta(grama_livre & (sorteio_px > 0.9965), 'lua')
pinta(grama_livre & (sorteio_px > 0.4) & (sorteio_px < 0.403), 'telhado_luz')
tufo = grama_livre & (sorteio_px > 0.6) & (sorteio_px < 0.615)
pinta(tufo, 'grama_sombra')
pinta(np.roll(tufo, -1, axis=0) & grama_livre, 'grama_luz')
# Lotes com fileiras (vinhas e plantações).
fileira = campos & (sorteio % 2 == 0) & (XX % 3 == 0) & ~cerca
pinta(fileira & ~trilha, 'grama_sombra')

# Contorno escuro da terra (estilo Mario World: tudo tem borda).
pinta(terra & (dist_mar == 1), 'noite')
# Penhascos na costa sul: faixa de pedra abaixo da borda.
penhasco = ~terra & (YY > 900) & np.roll(terra, 3, axis=0) & (dist_terra <= 3)
pinta(penhasco, 'pedra')
pinta(penhasco & np.roll(terra, 1, axis=0), 'rocha_sombra')

base = Image.fromarray(img, 'RGB').convert('RGBA')
px = base.load()


def ponto(x, y, cor):
    if 0 <= x < W and 0 <= y < H:
        px[x, y] = P[cor] + (255,)


def ret(x0, y0, x1, y1, cor):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            ponto(x, y, cor)


def ocupado(x, y, r, usados):
    return any((x - a) ** 2 + (y - b) ** 2 < r * r for a, b in usados)


# ---------------------------------------------------------------- sprites
def montanha_sprite(x, y, alt, nevada):
    """Pico triangular: lado iluminado à esquerda (lua), sombra à direita."""
    for dy in range(alt):
        meia = int((dy + 1) * 0.9)
        for dx in range(-meia, meia + 1):
            lado = 'rocha_luz' if dx < 0 else 'rocha_sombra'
            if nevada and dy < alt * 0.45:
                lado = 'gelo' if dx < 0 else 'gelo_sombra'
            elif not nevada and dy < alt * 0.25:
                lado = 'lua' if dx < 0 else 'rocha'
            ponto(x + dx, y - alt + dy, lado)
        ponto(x - meia - 1, y - alt + dy, 'noite')
        ponto(x + meia + 1, y - alt + dy, 'noite')
    ponto(x, y - alt - 1, 'noite')
    for dx in range(-int(alt * 0.9) - 1, int(alt * 0.9) + 2):
        ponto(x + dx, y, 'noite')


def arvore(x, y, escura=False):
    copa = 'mata_escura' if escura else 'mata'
    for dy in range(-7, 1):
        meia = 3 if dy > -6 else 2 if dy > -7 else 1
        if dy == 0:
            meia = 2
        for dx in range(-meia, meia + 1):
            cor = 'mata_luz' if dx < 0 and dy < -2 else copa
            ponto(x + dx, y - 3 + dy, cor)
        ponto(x - meia - 1, y - 3 + dy, 'noite')
        ponto(x + meia + 1, y - 3 + dy, 'noite')
    ponto(x, y - 11, 'noite')
    ret(x, y - 2, x, y, 'terra')
    ponto(x - 1, y, 'noite'); ponto(x + 1, y, 'noite')


def colina(x, y):
    r = 7
    for dy in range(r + 1):
        meia = int(math.sqrt(max(0, r * r - (r - dy) ** 2)) * 1.5)
        for dx in range(-meia, meia + 1):
            ponto(x + dx, y - r + dy, 'grama_luz' if dx < -meia // 3 else 'grama_sombra' if dx > meia // 3 else 'grama')
        ponto(x - meia - 1, y - r + dy, 'noite'); ponto(x + meia + 1, y - r + dy, 'noite')
    ponto(x, y - r - 1, 'noite'); ponto(x - 1, y - r - 1, 'noite'); ponto(x + 1, y - r - 1, 'noite')


def casa(x, y, telhado='telhado'):
    ret(x - 3, y - 3, x + 3, y, 'marmore_sombra')
    ret(x - 3, y - 3, x - 1, y, 'marmore')
    for i in range(4):
        ret(x - 4 + i, y - 4 - i, x + 4 - i, y - 4 - i, telhado if i else 'telhado_luz')
    ponto(x, y - 1, 'vela')


def torre(x, y, alt, cor='marmore', sombra='marmore_sombra', teto='azul_noite'):
    ret(x - 3, y - alt, x + 3, y, sombra)
    ret(x - 3, y - alt, x - 1, y, cor)
    for i in range(-3, 4, 2):
        ponto(x + i, y - alt - 1, cor)
    for i in range(5):
        ret(x - 4 + i, y - alt - 2 - i, x + 4 - i, y - alt - 2 - i, teto)
    ponto(x + 1, y - alt // 2, 'vela')
    for yy_ in range(y - alt - 6, y + 1):
        ponto(x - 5, yy_, 'noite') if yy_ > y - alt - 2 else None


def muralha(x0, x1, y, alt=6, cor='rocha_luz', sombra='rocha'):
    ret(x0, y - alt, x1, y, sombra)
    ret(x0, y - alt, x1, y - alt + 1, cor)
    for x in range(x0, x1 + 1, 3):
        ponto(x, y - alt - 1, cor)
    ret(x0, y + 1, x1, y + 1, 'noite')


def castelo_olympia(x, y):
    # Castelo à beira-mar, pedra fria e telhados azul-noite (como a capa),
    # com o casario coberto de geada em volta.
    for i in range(40):
        cx = x + random.randint(-58, 58); cy = y + random.randint(2, 30)
        if abs(cx - x) > 30 or cy > y + 14:
            casa(cx, cy, random.choice(['azul_noite', 'azul_noite', 'gelo']))
    muralha(x - 26, x + 26, y + 6, 10, 'lua', 'pedra')
    for dx, alt in ((-24, 22), (24, 22), (-10, 30), (10, 30), (0, 40)):
        torre(x + dx, y + 6, alt, 'lua', 'pedra', 'azul_noite')
    ret(x - 3, y, x + 3, y + 6, 'noite')
    ponto(x, y - 40, 'ouro_claro'); ponto(x, y - 41, 'ouro_claro')


def cidade_atenas(x, y):
    # Capital: casario, muralha e uma grande cúpula dourada no centro.
    for i in range(90):
        cx = x + random.randint(-64, 64); cy = y + random.randint(-20, 26)
        casa(cx, cy, random.choice(['telhado', 'azul_noite']))
    muralha(x - 70, x + 70, y + 34, 8, 'marmore', 'marmore_sombra')
    for dx in (-70, -35, 35, 70):
        torre(x + dx, y + 34, 14, 'marmore', 'marmore_sombra', 'azul_noite')
    ret(x - 17, y - 18, x + 17, y + 6, 'marmore_sombra')
    ret(x - 17, y - 18, x - 4, y + 6, 'marmore')
    for i in range(17):
        meia = int(math.sqrt(289 - i * i))
        ret(x - meia - 1, y - 19 - i, x + meia + 1, y - 19 - i, 'noite')
        ret(x - meia, y - 19 - i, x + meia, y - 19 - i, 'ouro_claro' if i > 12 or (i > 4 and -meia < 0 and False) else 'ouro')
        ret(x - meia, y - 19 - i, x - meia // 2, y - 19 - i, 'ouro_claro')
    for c in range(-15, 16, 5):
        ret(x + c, y - 16, x + c, y + 5, 'marmore')
    ret(x, y - 40, x, y - 36, 'ouro_claro'); ponto(x, y - 41, 'vela')


def cidade_agape(x, y):
    # Leste mercantil: telhados quentes, torres e canais que brilham.
    for i in range(34):
        cx = x + random.randint(-40, 40); cy = y + random.randint(-12, 20)
        casa(cx, cy, random.choice(['telhado', 'telhado_luz', 'ouro_escuro']))
    for dx in (-20, 0, 20):
        torre(x + dx, y + 2, 18 if dx else 26, 'prata', 'marmore_sombra', 'telhado')
    # Águas quentes que brilham à noite: canais claros com reflexos dourados.
    for cx in range(x - 52, x + 53):
        cy_ = int(y + 27 + math.sin(cx / 7.0) * 2)
        ret(cx, cy_ - 1, cx, cy_ + 1, 'olhos')
        ponto(cx, cy_ + 2, 'noite')
        if cx % 5 == 0:
            ponto(cx, cy_, 'ouro_claro')
    # Pequenas fontes que brilham entre as casas.
    for fx, fy in ((x - 34, y + 12), (x + 36, y + 14), (x - 6, y + 20)):
        ret(fx - 3, fy - 1, fx + 3, fy + 1, 'olhos'); ponto(fx, fy, 'ouro_claro')
        ret(fx - 4, fy + 2, fx + 4, fy + 2, 'noite')


def fortaleza_norte(x, y):
    # Fortaleza de pedra clara no meio das montanhas nevadas, com casas nevadas.
    for i in range(34):
        cx = x + random.randint(-56, 56); cy = y + random.randint(-6, 30)
        if abs(cx - x) > 34 or cy > y + 16:
            casa(cx, cy, 'gelo')
    muralha(x - 30, x + 30, y + 8, 12, 'prata', 'rocha')
    for dx, alt in ((-28, 20), (28, 20), (-12, 32), (12, 32), (0, 44)):
        torre(x + dx, y + 8, alt, 'prata', 'rocha', 'nuvem')
    for dx in range(-26, 27, 6):
        ponto(x + dx, y - 2, 'vela')


def templo(x, y):
    # Templo de colunas, como no mapa de referência.
    ret(x - 22, y + 2, x + 22, y + 5, 'marmore_sombra')
    ret(x - 20, y, x + 20, y + 1, 'marmore')
    for c in range(-18, 19, 6):
        ret(x + c, y - 18, x + c + 1, y - 1, 'marmore')
        ponto(x + c + 2, y - 10, 'marmore_sombra')
    ret(x - 22, y - 21, x + 22, y - 19, 'marmore')
    for i in range(9):
        ret(x - 22 + i * 2, y - 22 - i, x + 22 - i * 2, y - 22 - i, 'marmore' if i % 3 else 'ouro')
    ret(x - 23, y + 6, x + 23, y + 6, 'noite')


def bosque_ninfas(x, y):
    # Árvore grande e antiga no meio da ilha, com luzinhas.
    for r in range(22, 0, -1):
        for a in range(0, 360, 3):
            px_ = int(x + math.cos(math.radians(a)) * r * 1.3)
            py_ = int(y - 26 + math.sin(math.radians(a)) * r)
            ponto(px_, py_, 'mata_luz' if (px_ < x and py_ < y - 26) else 'mata')
    for a in range(0, 360, 2):
        ponto(int(x + math.cos(math.radians(a)) * 23 * 1.3), int(y - 26 + math.sin(math.radians(a)) * 23), 'noite')
    ret(x - 3, y - 6, x + 3, y + 4, 'terra')
    ret(x - 5, y + 3, x + 5, y + 4, 'terra')
    for _ in range(14):
        ponto(x + random.randint(-24, 24), y - 26 + random.randint(-16, 16), 'ouro_claro')


def navio(x, y):
    ret(x - 7, y - 1, x + 7, y + 1, 'terra')
    ret(x - 6, y + 2, x + 6, y + 2, 'noite')
    ret(x, y - 12, x, y - 2, 'terra')
    for i in range(8):
        ret(x - 5 + i // 2, y - 11 + i, x - 1, y - 11 + i, 'prata')
        ret(x + 1, y - 11 + i, x + 5 - i // 2, y - 11 + i, 'lua')
    ponto(x, y - 13, 'vela')


def pinheiro(x, y, nevado=False):
    """Pinheiro em três camadas; com neve nas pontas quando nevado."""
    for camada, (topo, base_meia) in enumerate(((-13, 2), (-9, 3), (-5, 4))):
        for dy in range(5):
            meia = max(0, base_meia * dy // 4)
            for dx in range(-meia, meia + 1):
                cor = 'mata_luz' if dx < 0 else 'mata_escura'
                if nevado and dy < 2:
                    cor = 'gelo' if dx <= 0 else 'gelo_sombra'
                ponto(x + dx, y + topo + dy, cor)
            ponto(x - meia - 1, y + topo + dy, 'noite'); ponto(x + meia + 1, y + topo + dy, 'noite')
    ponto(x, y - 14, 'noite')
    ret(x - 4, y, x + 4, y, 'noite')
    ret(x, y - 1, x, y, 'terra')


def pedra(x, y, cor='rocha_luz'):
    ret(x - 2, y - 2, x + 2, y, 'rocha')
    ret(x - 2, y - 2, x, y - 1, cor)
    ret(x - 3, y - 1, x - 3, y, 'noite'); ret(x + 3, y - 1, x + 3, y, 'noite')
    ret(x - 2, y - 3, x + 2, y - 3, 'noite'); ret(x - 2, y + 1, x + 2, y + 1, 'noite')


def moinho(x, y):
    ret(x - 3, y - 11, x + 3, y, 'marmore_sombra')
    ret(x - 3, y - 11, x - 1, y, 'marmore')
    for i in range(4):
        ret(x - 4 + i, y - 12 - i, x + 4 - i, y - 12 - i, 'telhado')
    ret(x - 4, y, x + 4, y, 'noite')
    for i in range(-7, 8):
        ponto(x + i, y - 13 + i, 'prata'); ponto(x + i, y - 13 - i, 'prata')
    ponto(x, y - 13, 'noite'); ponto(x, y - 5, 'noite')


def palheiro(x, y):
    ret(x - 2, y - 3, x + 2, y, 'campo_quente')
    ret(x - 1, y - 4, x + 1, y - 4, 'ouro_claro')
    ret(x - 2, y + 1, x + 2, y + 1, 'noite')


def tenda(x, y, cor='prata'):
    for i in range(7):
        ret(x - i, y - 7 + i, x + i, y - 7 + i, cor if i < 3 or True else cor)
        ret(x, y - 7 + i, x + i, y - 7 + i, 'marmore_sombra')
        ponto(x - i - 1, y - 7 + i, 'noite'); ponto(x + i + 1, y - 7 + i, 'noite')
    ret(x - 7, y, x + 7, y, 'noite')
    ret(x, y - 4, x, y - 1, 'noite')


def fogueira(x, y):
    ret(x - 2, y, x + 2, y, 'terra')
    ret(x - 1, y - 3, x + 1, y - 1, 'vela')
    ponto(x, y - 4, 'ouro_claro'); ponto(x, y - 2, 'ouro_claro')


def navio_grande(x, y):
    """Navio de dois mastros, maior que o barquinho."""
    for i in range(4):
        ret(x - 12 + i, y + i, x + 12 - i, y + i, 'terra' if i < 3 else 'noite')
    ret(x - 13, y - 1, x + 13, y - 1, 'ouro_escuro')
    for mx, alt in ((-5, 18), (5, 22)):
        ret(x + mx, y - alt, x + mx, y - 1, 'terra')
        for j in range(3):
            topo = y - alt + 2 + j * 6
            ret(x + mx - 5 + j, topo, x + mx + 5 - j, topo + 4, 'lua' if j % 2 == 0 else 'prata')
            ret(x + mx + 1, topo, x + mx + 5 - j, topo + 4, 'marmore_sombra')
        ponto(x + mx, y - alt - 1, 'vela'); ponto(x + mx + 1, y - alt - 1, 'vela')
    for dx in range(-14, 15, 2):
        ponto(x + dx, y + 5, 'espuma')


def farol(x, y):
    ret(x - 2, y - 16, x + 2, y, 'lua')
    for yy_ in range(y - 14, y, 4):
        ret(x - 2, yy_, x + 2, yy_ + 1, 'telhado')
    ret(x - 3, y - 19, x + 3, y - 17, 'noite')
    ret(x - 2, y - 21, x + 2, y - 19, 'vela'); ponto(x, y - 22, 'ouro_claro')
    ret(x - 3, y + 1, x + 3, y + 1, 'noite')


def aldeia(x, y, telhados, neve_no_telhado=False):
    n = random.randint(3, 7)
    casas = sorted((y + random.randint(-8, 8), x + random.randint(-14, 14)) for _ in range(n))
    for cy, cx in casas:
        casa(cx, cy, 'gelo' if neve_no_telhado else random.choice(telhados))
    if random.random() < 0.3:
        torre(x + random.choice((-18, 18)), y + 4, 12, 'marmore', 'marmore_sombra', random.choice(telhados))


def rosa_dos_ventos(x, y, r):
    """Rosa dos ventos dourada, com 8 pontas e anel."""
    for a in range(0, 360, 1):
        for rr in (r * 0.62, r * 0.62 + 1):
            ponto(int(x + math.cos(math.radians(a)) * rr), int(y + math.sin(math.radians(a)) * rr), 'ouro_escuro')
    for k in range(8):
        ang = math.radians(k * 45 - 90)
        comp = r if k % 2 == 0 else r * 0.55
        larg = r * 0.16 if k % 2 == 0 else r * 0.12
        for t in np.linspace(0, 1, int(comp * 2)):
            meia = larg * (1 - t)
            cx, cy = x + math.cos(ang) * comp * t, y + math.sin(ang) * comp * t
            for sgn in (-1, 1):
                for u in np.linspace(0, meia, max(2, int(meia * 2))):
                    px_ = int(cx + math.cos(ang + math.pi / 2) * u * sgn)
                    py_ = int(cy + math.sin(ang + math.pi / 2) * u * sgn)
                    ponto(px_, py_, ('ouro_claro' if sgn < 0 else 'ouro') if k % 2 == 0 else ('prata' if sgn < 0 else 'pedra'))
    for rr in range(3):
        for a in range(0, 360, 6):
            ponto(int(x + math.cos(math.radians(a)) * rr), int(y + math.sin(math.radians(a)) * rr), 'vela')
    # Flor-de-lis simples no norte.
    ret(x - 1, y - r - 6, x + 1, y - r - 2, 'ouro_claro')
    ponto(x - 3, y - r - 4, 'ouro_claro'); ponto(x + 3, y - r - 4, 'ouro_claro')


def cartela(x0, y0, x1, y1):
    """Moldura de pergaminho para o título (o texto vem do jogo, traduzível)."""
    ret(x0 + 4, y0 + 4, x1 + 4, y1 + 4, 'noite')
    ret(x0, y0, x1, y1, 'azul_noite')
    ret(x0 + 3, y0 + 3, x1 - 3, y1 - 3, 'nuvem')
    ret(x0 + 5, y0 + 5, x1 - 5, y1 - 5, 'azul_noite')
    for i, cor in enumerate(['noite', 'ouro_escuro', 'ouro', 'ouro_claro', 'ouro']):
        ret(x0 + i, y0 + i, x1 - i, y0 + i, cor); ret(x0 + i, y1 - i, x1 - i, y1 - i, cor)
        ret(x0 + i, y0 + i, x0 + i, y1 - i, cor); ret(x1 - i, y0 + i, x1 - i, y1 - i, cor)
    # Volutas nos cantos e sol no alto, como no mapa de referência.
    for cx, cy in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        for a in range(0, 360, 4):
            for rr in (6, 7):
                ponto(int(cx + math.cos(math.radians(a)) * rr), int(cy + math.sin(math.radians(a)) * rr), 'ouro')
        ret(cx - 2, cy - 2, cx + 2, cy + 2, 'ouro_claro')
    mx = (x0 + x1) // 2
    for a in range(0, 360, 15):
        for rr in range(8, 15):
            ponto(int(mx + math.cos(math.radians(a)) * rr), int(y0 - 2 + math.sin(math.radians(a)) * rr * 0.8), 'ouro')
    for rr in range(9):
        for a in range(0, 360, 5):
            ponto(int(mx + math.cos(math.radians(a)) * rr), int(y0 - 2 + math.sin(math.radians(a)) * rr * 0.8), 'ouro_claro' if rr < 6 else 'ouro_escuro')


usados = [(x, y) for x, y in LOCAIS.values()]
usados_pequenos = [p for k, p in PONTOS.items() if k not in LOCAIS]
RAIO_LIVRE = 70


def livre(x, y, r=RAIO_LIVRE):
    if 0 <= x < W and 0 <= y < H and perto_estrada[y, x]:
        return False
    return not ocupado(x, y, r, usados) and not ocupado(x, y, 22, usados_pequenos)


def no_mar(x, y, folga=6):
    return 0 <= x < W and 0 <= y < H and not terra[y, x] and dist_terra[y, x] > folga


# Linhas de rumo saindo das rosas dos ventos, só no mar (mapa antigo).
ROSAS = [((150, 1170), 46), ((1520, 1040), 34)]
for (rx, ry), _ in ROSAS:
    for k in range(16):
        ang = math.radians(k * 22.5)
        for t in range(50, 1900, 1):
            x, y = int(rx + math.cos(ang) * t), int(ry + math.sin(ang) * t)
            if not (0 <= x < W and 0 <= y < H):
                break
            if no_mar(x, y, 4) and t % 4 != 0:
                ponto(x, y, 'nuvem')

# Ondas: pequenos "~" no mar fundo e cristas perto da costa.
for _ in range(1400):
    x, y = random.randrange(W), random.randrange(H)
    if no_mar(x, y, 14):
        for dx in range(-3, 4):
            ponto(x + dx, y - (1 if abs(dx) in (1, 2) else 0), 'mar_raso')
        ponto(x - 1, y - 1, 'espuma')
for _ in range(500):
    x, y = random.randrange(W), random.randrange(H)
    if 0 <= x < W and 0 <= y < H and not terra[y, x] and 5 < dist_terra[y, x] < 12:
        ret(x - 1, y, x + 1, y, 'espuma')

# Recifes e rochedos soltos no mar.
for _ in range(60):
    x, y = random.randrange(W), random.randrange(H)
    if no_mar(x, y, 10) and dist_terra[y, x] < 40:
        pedra(x, y, 'lua')
        for dx in range(-4, 5):
            ponto(x + dx, y + 2, 'espuma')

for (rx, ry), r in ROSAS:
    rosa_dos_ventos(rx, ry, r)
CARTELA = (1300, 92, 1600, 204)  # o jogo escreve o título aqui dentro
cartela(*CARTELA)

# Montanhas, de cima para baixo (as de baixo cobrem as de trás).
picos = []
for y in range(60, 620, 22):
    for x in range(60, 900, 28):
        jx, jy = x + random.randint(-9, 9) + (14 if (y // 22) % 2 else 0), y + random.randint(-6, 6)
        if not (0 < jx < W and 0 < jy < H):
            continue
        vale = abs(n_alto[jy, jx]) < 0.1  # vales sem picos
        if montanha[jy, jx] and terra[jy, jx] and dist_mar[jy, jx] > 10 and livre(jx, jy, 64) \
                and not lago[jy, jx] and not vale and not margem_rio[jy, jx]:
            alto = 30 if neve[jy, jx] and random.random() < 0.3 else 0
            picos.append((jy, jx, random.randint(16, 26) + alto))
for jy, jx, alt in sorted(picos):
    montanha_sprite(jx, jy, alt, neve[jy, jx])

# Objetos pequenos, todos desenhados juntos de cima para baixo.
objetos = []


def perto_de_agua(x, y):
    return dist_mar[y, x] < 7 or margem_rio[y, x] or rio[y, x]


for y in range(40, H, 7):
    for x in range(30, W, 7):
        jx, jy = x + random.randint(-3, 3), y + random.randint(-2, 2)
        if not (0 < jx < W and 0 < jy < H) or not terra[jy, jx] or perto_de_agua(jx, jy):
            continue
        if not livre(jx, jy, 46 if mata[jy, jx] else 60):
            continue
        sorte = random.random()
        if montanha[jy, jx]:
            if abs(n_alto[jy, jx]) < 0.1 and sorte < 0.25:  # pinheiros nos vales
                objetos.append((jy, jx, pinheiro, (bool(neve[jy, jx]),)))
            elif sorte < 0.04:
                objetos.append((jy, jx, pedra, ()))
        elif mata[jy, jx]:
            if jy < 560 and sorte < 0.35:  # mata do norte mistura pinheiros
                objetos.append((jy, jx, pinheiro, (False,)))
            else:
                objetos.append((jy, jx, arvore, (False,)))
        elif frio[jy, jx]:
            if sorte < 0.05:
                objetos.append((jy, jx, pinheiro, (True,)))
            elif sorte < 0.07:
                objetos.append((jy, jx, pedra, ('lua',)))
        elif campos[jy, jx]:
            if sorte < 0.012:
                objetos.append((jy, jx, palheiro, ()))
        elif sorte < 0.05:
            objetos.append((jy, jx, arvore, (False,)))
        elif sorte < 0.058:
            objetos.append((jy, jx, pedra, ()))

# Aldeias espalhadas pelas planícies, campos e costa gélida.
aldeias = []
tentativas = 0
while len(aldeias) < 46 and tentativas < 20000:
    tentativas += 1
    x, y = random.randrange(60, W - 60), random.randrange(60, H - 60)
    if not terra[y, x] or montanha[y, x] or mata[y, x] or dist_mar[y, x] < 16 or margem_rio[y, x]:
        continue
    if not livre(x, y, 90) or ocupado(x, y, 70, aldeias):
        continue
    aldeias.append((x, y))
    if frio[y, x]:
        objetos.append((y, x, aldeia, (['azul_noite'], True)))
    elif quente[y, x]:
        objetos.append((y, x, aldeia, (['telhado', 'telhado_luz', 'ouro_escuro'],)))
    else:
        objetos.append((y, x, aldeia, (['telhado', 'azul_noite', 'telhado_luz'],)))
    if campos[y, x] and random.random() < 0.6:
        objetos.append((y + 6, x + random.choice((-26, 26)), moinho, ()))

# Colinas soltas nas planícies.
for _ in range(80):
    x, y = random.randrange(W), random.randrange(H)
    if terra[y, x] and not montanha[y, x] and not mata[y, x] and not campos[y, x] and not frio[y, x] \
            and dist_mar[y, x] > 14 and livre(x, y, 60) and not ocupado(x, y, 40, aldeias):
        objetos.append((y, x, colina, ()))

# Acampamentos: tendas e fogueira ao lado do ponto do mapa.
for ident, (x, y) in PONTOS.items():
    if 'acampamento' in ident:
        objetos.append((y - 10, x - 18, tenda, ('prata',)))
        objetos.append((y - 14, x + 16, tenda, ('olhos',)))
        objetos.append((y - 12, x - 2, fogueira, ()))

for jy, jx, funcao, extra in sorted(objetos, key=lambda o: (o[0], o[1])):
    funcao(jx, jy, *extra)

# Portos: píer de madeira para o mar, farol e barco atracado.
for ident, (x, y) in PONTOS.items():
    if not ident.startswith('porto_'):
        continue
    melhor = None
    for a in range(0, 360, 10):
        for t in range(4, 60):
            qx, qy = int(x + math.cos(math.radians(a)) * t), int(y + math.sin(math.radians(a)) * t)
            if 0 <= qx < W and 0 <= qy < H and not terra[qy, qx]:
                if melhor is None or t < melhor[0]:
                    melhor = (t, a)
                break
    t, a = melhor
    dx, dy = math.cos(math.radians(a)), math.sin(math.radians(a))
    for k in range(6, t + 26):
        cx, cy = x + dx * k, y + dy * k
        for u in (-2, -1, 0, 1, 2):
            ponto(int(cx - dy * u), int(cy + dx * u), 'ouro_escuro' if abs(u) < 2 else 'noite')
        if k % 3 == 0:
            ponto(int(cx), int(cy), 'terra')
    fim_x, fim_y = int(x + dx * (t + 26)), int(y + dy * (t + 26))
    navio(fim_x + int(-dy * 12), fim_y + int(dx * 12))
    farol(x - int(dy * 18) - 4, y + int(dx * 18) - 6)

# Frota perto de Olympia (o mapa de referência mostra navios ali) e barcos pelo mar.
for x, y in ((1090, 1080), (1150, 1120), (1060, 1160), (1200, 1190), (1130, 1230), (1240, 1100),
             (1010, 1210)):
    if no_mar(x, y, 8):
        navio_grande(x, y)
for x, y in ((1220, 880), (1230, 700), (1440, 880), (260, 1150), (60, 640), (1180, 260), (1500, 640)):
    if no_mar(x, y, 8):
        navio(x, y)

x, y = LOCAIS['olympia']; castelo_olympia(x, y - 8)
x, y = LOCAIS['atenas']; cidade_atenas(x, y - 10)
x, y = LOCAIS['agape']; cidade_agape(x, y - 10)
x, y = LOCAIS['norte']; fortaleza_norte(x, y - 10)
x, y = LOCAIS['templo']; templo(x, y - 6)
x, y = LOCAIS['floresta_ninfas']; bosque_ninfas(x, y - 4)

# Moldura dourada fina, como um mapa antigo.
for i, cor in enumerate(['noite', 'ouro_escuro', 'ouro', 'ouro_escuro', 'noite']):
    ret(i, i, W - 1 - i, i, cor); ret(i, H - 1 - i, W - 1 - i, H - 1 - i, cor)
    ret(i, i, i, H - 1 - i, cor); ret(W - 1 - i, i, W - 1 - i, H - 1 - i, cor)

saida = sys.argv[1] if len(sys.argv) > 1 else 'mapa_helade.png'
base.save(saida)
print(saida, base.size)
