# Gera as artes provisórias da fase "Antes que o sol beije o mar" (estrada
# Atenas–Olympia, o planalto verde antes de Olympia): os pisos isométricos
# (64×32), a mureta, as rochas, as pedras brancas, a folha que o vento leva
# e as duas vistas do mirante (pôr do sol e noite).
# Mesma paleta e contorno de gerar_objetos.py e gerar_acampamento.py.
# Da vista, vem do livro (V1 P1 c03): o planalto verde, o mar, o Castelo
# Olympia sobre a encosta de mármore branco, a pedra branca gigante com o
# Templo de Poseidon e a cachoeira que sai de baixo do Castelo, a praia e o
# céu salmão, rosa e laranja com o Sol quase beijando o oceano. O desenho em
# si é provisório, até a arte final.
# Uso: python3 tools/arte/gerar_por_do_sol.py   (rodar na raiz do projeto)
import math
import os
import random
import sys

from PIL import Image, ImageDraw

sys.dont_write_bytecode = True  # sem __pycache__ dentro de tools/
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_objetos import C, H, Q  # noqa: E402
from gerar_acampamento import L, A, agua, dentro_do_losango, piso  # noqa: E402

PASTA = 'assets/art/placeholders/estrada_oa/por_do_sol'

C.update(
    ceu_alto=H('#4E5F92'), ceu_rosa=H('#D98C9C'), ceu_salmao=H('#F2A07E'), ceu_laranja=H('#F6B866'),
    nuvem_rosa=H('#F3C1B8'), sol=H('#FFE4A0'), sol_borda=H('#FFC870'),
    marmore=H('#EDE8E0'), marmore_sombra=H('#B9B2AA'), marmore_fundo=H('#8E8780'),
    torre=H('#1E3554'), torre_luz=H('#2E4C72'), janela=H('#F2C66A'),
    noite_alto=H('#0A1426'), noite_baixo=H('#1C2E4E'), estrela=H('#E6ECF4'),
)


# ---------- pisos: uma faixa de 14 pisos de 64×32 ----------
# 0-1 grama baixa · 2 capim alto · 3 estrada de terra · 4-5 riacho (2 quadros)
# 6 pedras no riacho · 7 ponte · 8 mato da beira · 9 trilha das pedras brancas
# 10 lajes do mirante · 11 beira de mármore · 12-13 mar (2 quadros)

def capim_alto(semente):
    im = piso(('campo', 'campo_sombra', 'campo_quente'), semente, ('grama_luz',), densidade=0.12)
    px = im.load()
    rng = random.Random(semente)
    for _ in range(46):                      # folhas altas, em tufos
        x, y = rng.randrange(4, 60), rng.randrange(5, 30)
        cor = C[rng.choice(('grama_luz', 'campo_quente', 'ouro_luz'))]
        for dy in range(rng.choice((3, 4, 5))):
            xx = x + (1 if dy > 2 else 0)
            if dentro_do_losango(xx, y - dy):
                px[xx, y - dy] = cor
    return im


def pedras_no_riacho():
    im = agua(('mar_raso', 'mar', 'espuma'), 77, 0)
    q = Q(L, A); q.im = im; q.px = im.load()
    for (cx, cy) in ((14, 16), (32, 15), (50, 17)):
        q.elipse(cx, cy + 1, 7, 3, 'rocha_sombra')
        q.elipse(cx, cy, 6, 3, 'rocha')
        q.r(cx - 3, cy - 2, cx + 1, cy - 1, 'rocha_luz')
    return im


def ponte():
    im = piso(('madeira_luz', 'madeira', 'madeira_luz'), 91, densidade=0.04,
              listras=('madeira', 2))
    px = im.load()
    for y in range(A):                       # pranchas na direção da travessia
        for x in range(L):
            if dentro_do_losango(x, y) and (x + 2 * y) % 9 == 0:
                px[x, y] = C['madeira_sombra']
    return im


def trilha():
    im = piso(('areia', 'areia_sombra', 'prata'), 63, ('ouro_luz',), densidade=0.10)
    px = im.load()
    rng = random.Random(64)
    for _ in range(10):                      # brilho do olhar de Nicholas
        x, y = rng.randrange(10, 54), rng.randrange(6, 26)
        if dentro_do_losango(x, y):
            px[x, y] = C['ouro_luz']
    return im


def faixa_de_pisos():
    pecas = [
        piso(('grama', 'grama_sombra', 'grama_luz'), 11, ('ouro_luz',), 'grama_luz'),
        piso(('grama', 'grama_sombra', 'grama_luz'), 12, ('ouro_luz',), 'grama_luz'),
        capim_alto(13),
        piso(('terra', 'madeira', 'areia_sombra'), 14, densidade=0.12),
        agua(('mar_raso', 'mar', 'espuma'), 15, 0),
        agua(('mar_raso', 'mar', 'espuma'), 15, 1),
        pedras_no_riacho(),
        ponte(),
        piso(('mata', 'mata_escura', 'mata_luz'), 18, riscos='mata_luz', densidade=0.14),
        trilha(),
        piso(('prata', 'prata_sombra', 'branco'), 20, densidade=0.08, listras=('prata_sombra', 4)),
        piso(('marmore', 'marmore_sombra', 'branco'), 21, densidade=0.06),
        agua(('mar', 'mar_fundo', 'ouro_luz'), 22, 0),
        agua(('mar', 'mar_fundo', 'ouro_luz'), 22, 1),
    ]
    faixa = Image.new('RGBA', (L * len(pecas), A), (0, 0, 0, 0))
    for i, peca in enumerate(pecas):
        faixa.paste(peca, (i * L, 0))
    return faixa


# ---------- peças em pé ----------

def mureta():
    # Muro baixo de pedra solta que corta o piso de nordeste para sudoeste (a
    # linha das casas com o mesmo x). O centro do piso fica em (32, 32).
    q = Q(64, 48)
    d = ImageDraw.Draw(q.im)
    a, b = (49, 23), (15, 40)               # pontas, um pouco além da beira do piso
    esp = (3, 2)                            # espessura (para o lado do mar)
    alt = 9
    frente = [(a[0] + esp[0], a[1] + esp[1]), (b[0] + esp[0], b[1] + esp[1]),
              (b[0] + esp[0], b[1] + esp[1] - alt), (a[0] + esp[0], a[1] + esp[1] - alt)]
    topo = [(a[0], a[1] - alt), (b[0], b[1] - alt),
            (b[0] + esp[0], b[1] + esp[1] - alt), (a[0] + esp[0], a[1] + esp[1] - alt)]
    d.polygon(frente, fill=C['pedra'])
    d.polygon(topo, fill=C['pedra_luz'])
    rng = random.Random(5)
    for _ in range(26):                     # juntas entre as pedras
        t = rng.random()
        x = round(a[0] + esp[0] + (b[0] - a[0]) * t)
        y = round(a[1] + esp[1] + (b[1] - a[1]) * t) - rng.randrange(1, alt)
        q.p(x, y, 'pedra_sombra')
    for _ in range(6):
        t = rng.random()
        q.p(round(a[0] + (b[0] - a[0]) * t) + 1, round(a[1] + (b[1] - a[1]) * t) - alt, 'lua')
    return q.contornar()


def rocha_planalto():
    q = Q(34, 30)
    q.sombra_no_chao(17, 26, 15, 3)
    q.elipse(17, 17, 14, 10, 'rocha_sombra')
    q.elipse(15, 15, 11, 8, 'rocha')
    q.elipse(12, 11, 6, 4, 'rocha_luz')
    for i in range(6):
        q.p(19 + i // 2, 10 + i, 'rocha_sombra')
    q.r(6, 22, 27, 23, 'rocha_sombra')
    q.p(11, 9, 'lua')
    return q.contornar()


def pedra_branca():
    q = Q(32, 30)
    q.sombra_no_chao(16, 26, 14, 3)
    q.elipse(16, 17, 13, 10, 'marmore_sombra')
    q.elipse(14, 15, 10, 8, 'marmore')
    q.elipse(11, 11, 5, 4, 'branco')
    q.r(6, 22, 25, 23, 'marmore_fundo')
    q.p(20, 13, 'marmore_sombra'); q.p(21, 14, 'marmore_sombra')
    return q.contornar()


def folha_vento():
    q = Q(4, 3)
    q.r(0, 1, 2, 1, 'grama_luz'); q.p(3, 0, 'grama_luz'); q.p(1, 2, 'grama')
    return q.im


# ---------- a vista do mirante (320×180) ----------

def _misturar(c1, c2, t):
    return tuple(round(c1[i] + (c2[i] - c1[i]) * t) for i in range(3)) + (255,)


def vista(noite=False):
    w, h = 320, 180
    horizonte = 104
    im = Image.new('RGBA', (w, h), (0, 0, 0, 255))
    px = im.load()
    d = ImageDraw.Draw(im)
    rng = random.Random(3 if noite else 4)
    # céu
    paradas = ([C['noite_alto'], C['noite_baixo'], C['torre_luz']] if noite else
               [C['ceu_alto'], C['ceu_rosa'], C['ceu_salmao'], C['ceu_laranja']])
    for y in range(horizonte):
        t = y / (horizonte - 1) * (len(paradas) - 1)
        i = min(int(t), len(paradas) - 2)
        cor = _misturar(paradas[i], paradas[i + 1], t - i)
        for x in range(w):
            px[x, y] = cor
    sol_x = 236
    if noite:
        for _ in range(70):
            px[rng.randrange(w), rng.randrange(horizonte - 20)] = C['estrela']
        d.ellipse((200, 18, 214, 32), fill=C['lua'])          # lua
        d.ellipse((204, 16, 218, 30), fill=C['noite_alto'])
    else:
        for _ in range(9):                                   # nuvens sem forma definida
            cx, cy = rng.randrange(120, 320), rng.randrange(18, 80)
            for k in range(rng.randrange(3, 6)):
                ex = cx + rng.randrange(-14, 14)
                d.ellipse((ex - 12, cy - 2 + k, ex + 12, cy + 2 + k), fill=C['nuvem_rosa'])
        d.ellipse((sol_x - 15, horizonte - 15, sol_x + 15, horizonte + 15), fill=C['sol_borda'])
        d.ellipse((sol_x - 12, horizonte - 12, sol_x + 12, horizonte + 12), fill=C['sol'])
    # mar
    for y in range(horizonte, h):
        t = (y - horizonte) / (h - horizonte)
        cor = _misturar(C['noite_baixo'] if noite else C['mar_raso'], C['mar_fundo'], t)
        for x in range(w):
            px[x, y] = cor
    reflexo = C['lua'] if noite else C['ouro_luz']
    centro = 207 if noite else sol_x
    for y in range(horizonte + 2, h, 3):                     # reflexo na água
        largura = 4 + (y - horizonte) // 3
        for _ in range(3):
            x0 = centro + rng.randrange(-largura, largura)
            d.line((x0, y, x0 + rng.randrange(3, 9), y), fill=reflexo)
    # encosta de mármore branco com o Castelo Olympia em cima
    marmore = C['marmore_fundo'] if noite else C['marmore']
    sombra = C['torre'] if noite else C['marmore_sombra']
    d.polygon([(0, 180), (0, 70), (22, 64), (60, 60), (120, 66), (150, 96), (168, 132), (176, 180)], fill=marmore)
    d.polygon([(110, 66), (120, 66), (150, 96), (168, 132), (176, 180), (150, 180), (140, 120)], fill=sombra)
    # a pedra branca gigante e a fenda do Templo de Poseidon embaixo dela
    d.ellipse((88, 96, 150, 140), fill=marmore)
    d.polygon([(112, 140), (118, 116), (126, 140)], fill=C['noite'])
    # a cachoeira que sai de baixo do Castelo e cobre a entrada da fenda
    for x in range(114, 124):
        for y in range(70, 142):
            if (x + y) % 3:
                px[x, y] = C['espuma'] if (y // 2 + x) % 4 else C['branco']
    # muralha e torres
    torre, torre_luz = C['torre'], C['torre_luz']
    d.rectangle((18, 46, 112, 62), fill=C['pedra_luz'] if not noite else C['pedra'])
    for x in range(18, 113, 6):
        d.rectangle((x, 43, x + 3, 46), fill=C['pedra_luz'] if not noite else C['pedra'])
    for (x, topo, larg) in ((22, 24, 10), (48, 14, 12), (76, 20, 10), (100, 28, 9)):
        d.rectangle((x, topo, x + larg, 62), fill=C['lua'] if not noite else C['pedra_luz'])
        d.polygon([(x - 2, topo), (x + larg // 2, topo - 12), (x + larg + 2, topo)], fill=torre)
        d.line((x + larg // 2, topo - 12, x + larg // 2, topo - 18), fill=torre_luz)
        d.rectangle((x + larg // 2, topo - 18, x + larg // 2 + 4, topo - 15), fill=C['ouro'])
        for jy in range(topo + 6, 58, 9):
            janela = C['janela'] if noite else C['torre_luz']
            d.rectangle((x + larg // 2 - 1, jy, x + larg // 2, jy + 2), fill=janela)
    # a praia, à direita da encosta
    areia = C['areia_sombra'] if noite else C['areia']
    d.polygon([(168, 150), (230, 146), (290, 156), (300, 168), (176, 172)], fill=areia)
    for x in range(170, 296, 4):
        px[x, 150 + (x * 7) % 5] = C['espuma']
    # a beira do planalto verde, em primeiro plano
    verde = C['mata_escura'] if noite else C['grama']
    d.polygon([(0, 180), (0, 166), (60, 160), (150, 164), (240, 170), (320, 162), (320, 180)], fill=verde)
    for x in range(0, 320, 3):
        y = 165 + (x * 13) % 6
        d.line((x, y, x, y - 3), fill=C['mata'] if noite else C['grama_luz'])
    return im


ARTES = {
    'chao_planalto': faixa_de_pisos,
    'mureta': mureta,
    'rocha_planalto': rocha_planalto,
    'pedra_branca': pedra_branca,
    'folha_vento': folha_vento,
    'vista_por_do_sol': lambda: vista(False),
    'vista_noite': lambda: vista(True),
}


if __name__ == '__main__':
    os.makedirs(PASTA, exist_ok=True)
    filtro = set(sys.argv[1:])
    for nome, desenhar in ARTES.items():
        if filtro and nome not in filtro:
            continue
        caminho = f'{PASTA}/{nome}.png'
        desenhar().save(caminho)
        print(caminho)
