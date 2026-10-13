# Gera a folha de animação de Nicholas na exploração (pixel art, base: capa do livro).
# Uso: python3 tools/arte/gerar_nicholas.py assets/art/personagens/nicholas/nicholas_exploracao.png
# Também grava, ao lado, nicholas_maos.tres: onde fica a mão da frente em cada
# quadro, para desenhar o item equipado (a espada) na mão dele.
import sys
from PIL import Image
H = lambda h: tuple(int(h[i:i+2], 16) for i in (1, 3, 5)) + (255,)
C = dict(
    contorno=H('#050C14'),
    cab_luz=H('#F4EFE8'), cab=H('#D8CFC4'), cab_sombra=H('#A69C92'), cab_fundo=H('#7A7068'),
    pele_luz=H('#E6C6B4'), pele=H('#C8A08E'), pele_sombra=H('#9E7468'),
    olho=H('#9FB8D2'), olho_escuro=H('#2B3D55'),
    manto_luz=H('#C9CED8'), manto=H('#9AA3B3'), manto_sombra=H('#5E6673'),
    ouro_luz=H('#ECBD75'), ouro=H('#B98543'), ouro_sombra=H('#8A5E2C'),
    tunica=H('#2B3D55'), tunica_sombra=H('#13253C'),
    calca=H('#13253C'), calca_sombra=H('#0B1726'),
    bota=H('#4A3428'), bota_sombra=H('#2E2019'),
)
W, HH = 32, 48
CX = 16

class Q:
    def __init__(s): s.im = Image.new('RGBA', (W, HH), (0, 0, 0, 0)); s.px = s.im.load()
    def p(s, x, y, c):
        if 0 <= x < W and 0 <= y < HH: s.px[x, y] = C[c]
    def r(s, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1): s.p(x, y, c)
    def linha(s, y, x0, x1, c): s.r(x0, y, x1, y, c)
    def contornar(s):
        cheios = {(x, y) for x in range(W) for y in range(HH) if s.px[x, y][3]}
        for (x, y) in list(cheios):
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                n = (x+dx, y+dy)
                if n not in cheios and 0 <= n[0] < W and 0 <= n[1] < HH:
                    s.px[n] = C['contorno']
        return s.im

def perna(q, x, y_quadril, f, lift, frente):
    # f: deslocamento para a frente (direita na tela); lift: pé levantado
    xx = x + f
    topo = y_quadril
    pe = 45 - lift
    q.r(xx, topo, xx + 2, pe - 3, 'calca')
    q.r(xx, topo, xx, pe - 3, 'calca_sombra')
    q.r(xx, pe - 2, xx + 2, pe, 'bota')
    if frente: q.p(xx + 3, pe, 'bota')  # bico da bota para a frente
    else: q.p(xx - 1, pe, 'bota')
    q.linha(pe, xx, xx + (3 if frente else 2), 'bota_sombra')

def cabelo_frente(q, x, y):
    # volume ondulado prateado, mais para trás (esquerda) que para a frente
    q.r(x-6, y+1, x+5, y+6, 'cab')
    q.r(x-5, y, x+4, y, 'cab')
    q.r(x-7, y+3, x-5, y+10, 'cab_sombra')       # mecha de trás
    q.r(x-6, y+7, x-5, y+11, 'cab_fundo')
    q.p(x-7, y+11, 'cab_sombra'); q.p(x+6, y+3, 'cab'); q.p(x+6, y+4, 'cab_sombra')
    # franja em ondas caindo sobre a testa
    for i, (dx, prof) in enumerate([(-4, 8), (-3, 9), (-2, 8), (-1, 7), (0, 8), (1, 7), (2, 7), (3, 8), (4, 7)]):
        q.r(x+dx, y+6, x+dx, y+prof, 'cab' if i % 3 else 'cab_sombra')
    q.r(x+5, y+5, x+5, y+9, 'cab_sombra')        # mecha do lado do rosto
    # brilhos
    for (dx, dy) in [(-3, 1), (-2, 1), (-1, 2), (1, 1), (2, 2), (3, 2), (-4, 3), (0, 3)]:
        q.p(x+dx, y+dy, 'cab_luz')

def cabelo_costas(q, x, y):
    linhas = {0: (-4, 3), 1: (-5, 5), 2: (-6, 5), 10: (-6, 6), 11: (-5, 5), 12: (-5, 4)}
    for dy in range(13):
        x0, x1 = linhas.get(dy, (-6, 6))
        q.linha(y+dy, x+x0, x+x1, 'cab' if dy < 9 else 'cab_sombra')
    for dx in (-5, -3, 0, 2, 4): q.p(x+dx, y+13, 'cab_sombra')   # pontas onduladas
    # ondas: traços escuros com brilho logo acima
    for (dx, dy) in [(-5, 4), (-4, 5), (-3, 6), (-2, 6), (1, 4), (2, 5), (3, 6), (4, 6), (-1, 9), (0, 9), (5, 8)]:
        q.p(x+dx, y+dy, 'cab_sombra')
    for (dx, dy) in [(-4, 3), (-3, 4), (-2, 5), (1, 2), (2, 3), (3, 4), (-1, 1), (0, 2), (-5, 8), (4, 9)]:
        q.p(x+dx, y+dy, 'cab_luz')
    q.p(x-6, y+11, 'cab_fundo'); q.p(x+6, y+9, 'cab_fundo')

def rosto(q, x, y):
    q.r(x-3, y+5, x+4, y+12, 'pele')
    q.r(x-3, y+5, x-3, y+12, 'pele_sombra')
    q.r(x-2, y+12, x+3, y+12, 'pele_sombra')     # queixo
    q.p(x+4, y+12, 'contorno')
    q.r(x+2, y+6, x+3, y+7, 'pele_luz')
    # olhos azul-claros
    q.p(x-1, y+9, 'olho'); q.p(x+2, y+9, 'olho')
    q.p(x-1, y+8, 'olho_escuro'); q.p(x+2, y+8, 'olho_escuro')
    q.p(x+1, y+10, 'pele_sombra')               # nariz
    q.p(x+1, y+11, 'pele_sombra')
    q.p(x-4, y+8, 'pele_sombra'); q.p(x-4, y+9, 'pele')  # orelha

def braco(q, x, y, swing, cor, mao=True, comprimento=9):
    yy = y + swing
    q.r(x, yy, x + 1, yy + comprimento, cor)
    if mao: q.r(x, yy + comprimento + 1, x + 1, yy + comprimento + 2, 'pele')

def nicholas(dir, f_esq=0, f_dir=0, lift_esq=0, lift_dir=0, dy=0, inclina=0,
             braco_esq=0, braco_dir=0, alcance=0, manto_voa=0, curvo=False):
    q = Q()
    x = CX + inclina
    yc = 3 + dy           # topo do cabelo
    yt = 19 + dy          # topo do tronco
    quadril = 31 + dy
    if dir == 'frente':
        # capa por trás do corpo
        q.r(x-7 - manto_voa, yt, x+4, 36 + dy - (1 if manto_voa else 0), 'manto_sombra')
        q.r(x-8 - manto_voa, yt + 6, x-7 - manto_voa, 34 + dy, 'manto_sombra')
        # pernas (a de trás primeiro)
        perna(q, CX - 4, quadril, f_esq, lift_esq, True)
        perna(q, CX + 1, quadril, f_dir, lift_dir, True)
        # braço de trás (esquerda na tela), meio coberto pela capa
        braco(q, x-7, yt + 2, braco_esq, 'manto', comprimento=7 if curvo else 8)
        # túnica
        q.r(x-5, yt, x+4, quadril, 'tunica')
        q.r(x-5, yt, x-3, quadril, 'tunica_sombra')
        q.linha(quadril - 3, x-5, x+4, 'ouro_sombra')       # cinto
        q.p(x+1, quadril - 3, 'ouro_luz')
        q.r(x-1, yt + 1, x, quadril - 4, 'ouro_sombra')     # abertura bordada
        # manto claro sobre o ombro esquerdo, caindo pela frente
        q.r(x-6, yt - 1, x-3, quadril + 2, 'manto')
        q.r(x-6, yt - 1, x-6, quadril + 2, 'manto_sombra')
        q.r(x-4, yt, x-3, yt + 5, 'manto_luz')
        q.linha(quadril + 2, x-6, x-3, 'ouro')
        # ombreira dourada ornamentada
        q.r(x-7, yt, x-3, yt + 3, 'ouro')
        q.r(x-6, yt, x-4, yt, 'ouro_luz'); q.p(x-5, yt + 1, 'ouro_luz')
        q.linha(yt + 3, x-7, x-3, 'ouro_sombra'); q.p(x-6, yt + 2, 'ouro_sombra')
        # gola alta clara com friso dourado
        q.r(x-3, yt - 2, x+3, yt, 'manto_luz')
        q.linha(yt, x-2, x+3, 'ouro')
        # braço da frente (direita)
        if alcance:
            ay = yt + 3
            q.r(x+5, ay, x+5 + alcance, ay + 1, 'tunica')
            q.r(x+5, ay + 1, x+5 + alcance, ay + 1, 'tunica_sombra')
            q.r(x+6 + alcance, ay, x+7 + alcance, ay + 1, 'pele')
        else:
            braco(q, x+5, yt + 1, braco_dir, 'tunica', comprimento=6 if curvo else 8)
        # cabeça
        rosto(q, x, yc)
        cabelo_frente(q, x, yc)
    else:  # costas: de costas, indo para cima e para a direita
        perna(q, CX - 4, quadril, f_esq, lift_esq, False)
        perna(q, CX + 1, quadril, f_dir, lift_dir, False)
        if alcance:
            ay = yt + 2
            q.r(x+5, ay, x+5 + alcance, ay + 1, 'tunica')
            q.r(x+6 + alcance, ay, x+7 + alcance, ay + 1, 'pele')
        else:
            braco(q, x+5, yt + 1, braco_dir, 'tunica', comprimento=6 if curvo else 8)
        # capa grande nas costas
        q.r(x-5 - manto_voa, yt, x+4, 35 + dy, 'manto')
        q.r(x-5 - manto_voa, yt, x-3 - manto_voa, 35 + dy, 'manto_sombra')
        q.r(x+1, yt + 1, x+3, yt + 9, 'manto_luz')
        q.linha(35 + dy, x-5 - manto_voa, x+4, 'ouro')
        q.linha(34 + dy, x-5 - manto_voa, x+4, 'ouro_sombra')
        # ombreira dourada no ombro direito da tela (o mesmo ombro, visto de trás)
        q.r(x+2, yt - 1, x+6, yt + 2, 'ouro')
        q.r(x+3, yt - 1, x+5, yt - 1, 'ouro_luz'); q.linha(yt + 2, x+2, x+6, 'ouro_sombra')
        braco(q, x-7, yt + 2, braco_esq, 'manto', comprimento=7 if curvo else 8)
        q.r(x-3, yt - 2, x+3, yt, 'manto_luz')
        q.linha(yt - 3, x-2, x+2, 'pele_sombra')           # nuca
        cabelo_costas(q, x, yc)
    return q.contornar()

ANIM = {
    'parado':     [dict(), dict(dy=1)],
    'andando':    [dict(f_dir=2, f_esq=-2, dy=1, braco_dir=-1, braco_esq=1),
                   dict(f_esq=0, lift_esq=1, braco_dir=0, braco_esq=0),
                   dict(f_dir=-2, f_esq=2, dy=1, braco_dir=1, braco_esq=-1),
                   dict(f_dir=0, lift_dir=1)],
    'correndo':   [dict(f_dir=3, f_esq=-3, dy=1, inclina=1, braco_dir=-2, braco_esq=2, manto_voa=1, curvo=True),
                   dict(lift_esq=2, inclina=1, dy=-1, manto_voa=2, curvo=True),
                   dict(f_dir=-3, f_esq=3, dy=1, inclina=1, braco_dir=2, braco_esq=-2, manto_voa=1, curvo=True),
                   dict(lift_dir=2, inclina=1, dy=-1, manto_voa=2, curvo=True)],
    'interagindo': [dict(), dict(alcance=2), dict(alcance=4)],
}
ORDEM = ['parado', 'andando', 'correndo', 'interagindo']
DIRS = ['frente', 'costas']

def folha():
    im = Image.new('RGBA', (W * 4, HH * len(ORDEM) * len(DIRS)), (0, 0, 0, 0))
    linha = 0
    for d in DIRS:
        for a in ORDEM:
            for i, k in enumerate(ANIM[a]):
                im.paste(nicholas(d, **k), (i * W, linha * HH))
            linha += 1
    return im

def mao(dir, f_esq=0, f_dir=0, lift_esq=0, lift_dir=0, dy=0, inclina=0,
        braco_esq=0, braco_dir=0, alcance=0, manto_voa=0, curvo=False):
    # Canto de cima à esquerda da mão 2×2 do braço da frente (o da direita
    # na tela), com as mesmas contas de nicholas().
    x = CX + inclina
    yt = 19 + dy
    if alcance:
        return (x + 6 + alcance, yt + (3 if dir == 'frente' else 2))
    comprimento = 6 if curvo else 8
    return (x + 5, yt + 1 + braco_dir + comprimento + 1)

def maos_tres():
    linhas = []
    for d in DIRS:
        for a in ORDEM:
            pontos = ', '.join('%d, %d' % mao(d, **k) for k in ANIM[a])
            linhas.append('&"%s_%s": PackedVector2Array(%s)' % (a, d, pontos))
    return ('[gd_resource type="Resource" script_class="MaosPersonagem" format=3]\n\n'
            '[ext_resource type="Script" path="res://scripts/systems/maos_personagem.gd" id="1_maos"]\n\n'
            '[resource]\nscript = ExtResource("1_maos")\n'
            'tamanho_quadro = Vector2i(%d, %d)\n'
            'pontos = {\n%s\n}\n' % (W, HH, ',\n'.join(linhas)))

if __name__ == '__main__':
    folha().save(sys.argv[1])
    import os
    with open(os.path.join(os.path.dirname(sys.argv[1]), 'nicholas_maos.tres'), 'w') as f:
        f.write(maos_tres())
