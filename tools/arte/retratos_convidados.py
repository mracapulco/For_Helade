# Gera os retratos 64×64 dos convidados (Rafael e Shara) para a caixa de
# diálogo. Desenhados à mão, pixel a pixel, com sombreamento chapado (luz da
# esquerda), olhando fotos deles como referência. As fotos NÃO ficam no
# repositório e o script não as lê.
# Uso: python3 tools/arte/retratos_convidados.py
#
# A boca tem 3 posições (fechada, entreaberta, aberta): <id>_retrato.png é a
# fechada; <id>_retrato_fala.png tem as 3 lado a lado.
import os

from PIL import Image, ImageDraw

N = 64
H = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
CONTORNO = '#140E10'


class Q:
    def __init__(self):
        self.im = Image.new('RGBA', (N, N), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def p(self, x, y, c):
        if 0 <= x < N and 0 <= y < N:
            self.im.putpixel((x, y), H(c))

    def r(self, x0, y0, x1, y1, c):
        self.d.rectangle((x0, y0, x1, y1), fill=H(c))

    def poly(self, pts, c):
        self.d.polygon(pts, fill=H(c))

    def elipse(self, caixa, c, borda=None):
        self.d.ellipse(caixa, fill=H(c) if c else None,
                       outline=H(borda) if borda else None)

    def linha(self, pts, c):
        self.d.line(pts, fill=H(c), width=1)

    def contornar(self):
        px = self.im.load()
        cheios = {(x, y) for x in range(N) for y in range(N) if px[x, y][3]}
        for (x, y) in cheios:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n not in cheios and 0 <= n[0] < N and 0 <= n[1] < N:
                    px[n] = H(CONTORNO)
        return self.im


def espelho(pts):
    return [(64 - x, y) for x, y in pts]


# --- Rafael -------------------------------------------------------------------
# Rosto fino e jovem, cabelo castanho-escuro penteado para trás com volume em
# cima e laterais curtas, olhos verdes, sorriso leve, chapéu de abas largas. Camisa caqui de
# escoteiro com lenço verde.

R_PELE = dict(luz='#F8DFCC', base='#EFC6AC', sombra='#D9A288', funda='#B97E66')
R_CAB = dict(luz='#6B4630', base='#46291A', sombra='#2B170D')
R_CHAPEU = dict(luz='#B0905E', base='#8C6E44', sombra='#644C2C', fita='#3A2A1C')
R_OLHO = dict(iris='#5E9A5C', iris_escura='#2F5E34', brilho='#E6F4E0')


def rafael(boca):
    q = Q()
    # ombros e camisa caqui com gola e dragonas
    q.poly([(1, 63), (4, 57), (14, 53), (24, 51), (40, 51), (50, 53), (60, 57), (63, 63)], '#BCA576')
    q.poly([(1, 63), (4, 57), (14, 53), (16, 63)], '#9A8458')
    q.poly([(48, 53), (60, 57), (63, 63), (54, 63)], '#D8C696')
    q.poly([(6, 56), (14, 53), (16, 55), (8, 58)], '#8E7A52')
    q.poly([(58, 56), (50, 53), (48, 55), (56, 58)], '#8E7A52')
    # pescoço
    q.r(26, 44, 38, 54, R_PELE['base'])
    q.r(26, 44, 38, 48, R_PELE['sombra'])
    q.poly([(35, 46), (38, 44), (38, 54), (35, 54)], R_PELE['sombra'])
    # orelhas
    q.elipse((14, 25, 19, 35), R_PELE['base'])
    q.elipse((45, 25, 50, 35), R_PELE['sombra'])
    q.p(16, 29, R_PELE['funda']); q.p(16, 30, R_PELE['funda']); q.p(48, 29, R_PELE['funda']); q.p(48, 30, R_PELE['funda'])
    # rosto (oval estreito, queixo fino)
    rosto = [(18, 16), (46, 16), (47, 30), (45, 38), (41, 44), (36, 48), (32, 49), (28, 48), (23, 44), (19, 38), (17, 30)]
    q.poly(rosto, R_PELE['base'])
    # lado da sombra (direita) e luz na testa/bochecha esquerda
    q.poly([(42, 16), (46, 16), (47, 30), (45, 38), (41, 44), (36, 48), (37, 44), (41, 38), (43, 30)], R_PELE['sombra'])
    q.poly([(22, 15), (30, 15), (28, 20), (23, 22)], R_PELE['luz'])
    # cabelo: volume em cima, penteado para trás, risca do lado esquerdo
    q.poly([(16, 26), (15, 16), (17, 9), (22, 4), (30, 2), (38, 2), (44, 4), (48, 9), (49, 16), (48, 26),
            (46, 24), (45, 17), (40, 14), (33, 13), (26, 13), (21, 15), (19, 18), (18, 26)], R_CAB['base'])
    q.poly([(17, 12), (21, 6), (28, 3), (27, 6), (22, 9), (19, 14)], R_CAB['luz'])
    q.poly([(30, 4), (38, 3), (44, 6), (36, 6)], R_CAB['luz'])
    q.linha([(24, 8), (33, 6), (42, 8)], R_CAB['sombra'])
    q.linha([(21, 11), (29, 9)], R_CAB['sombra'])
    q.poly([(44, 6), (48, 10), (49, 18), (48, 26), (46, 24), (45, 15)], R_CAB['sombra'])
    q.linha([(23, 5), (21, 13)], R_CAB['sombra'])  # risca
    # chapéu de abas largas, copa em ponta vincada em quatro (o de Baden-Powell)
    q.r(19, 16, 45, 17, R_PELE['sombra'])                      # sombra da aba na testa
    q.poly([(3, 15), (9, 12), (55, 12), (61, 15), (57, 17), (7, 17)], R_CHAPEU['base'])
    q.poly([(3, 15), (9, 12), (26, 12), (24, 14), (8, 15)], R_CHAPEU['luz'])
    q.poly([(57, 17), (61, 15), (55, 12), (50, 14), (52, 16)], R_CHAPEU['sombra'])
    q.linha([(8, 17), (56, 17)], R_CHAPEU['sombra'])
    q.poly([(19, 12), (22, 4), (28, 0), (32, 3), (36, 0), (42, 4), (45, 12)], R_CHAPEU['base'])
    q.poly([(19, 12), (22, 4), (28, 0), (29, 2), (25, 6), (24, 12)], R_CHAPEU['luz'])
    q.poly([(36, 0), (42, 4), (45, 12), (40, 12), (39, 5)], R_CHAPEU['sombra'])
    q.linha([(32, 3), (32, 9)], R_CHAPEU['sombra'])              # vinco do meio
    q.linha([(27, 3), (26, 8)], R_CHAPEU['sombra']); q.linha([(37, 3), (38, 8)], R_CHAPEU['sombra'])
    q.r(20, 9, 44, 11, R_CHAPEU['fita'])
    # sobrancelhas retas
    q.r(21, 24, 28, 25, R_CAB['base']); q.p(21, 24, R_PELE['base'])
    q.r(36, 24, 43, 25, R_CAB['base']); q.p(43, 24, R_PELE['sombra'])
    # olhos verdes amendoados
    for cx in (25, 39):
        q.r(cx - 3, 28, cx + 3, 28, '#2A1A12')
        q.r(cx - 3, 29, cx + 3, 30, '#F4F0EA')
        q.r(cx - 1, 29, cx + 1, 30, R_OLHO['iris'])
        q.r(cx - 1, 29, cx + 1, 29, R_OLHO['iris_escura'])
        q.p(cx, 30, '#1A2A1C'); q.p(cx - 1, 29, R_OLHO['brilho'])
        q.r(cx - 2, 31, cx + 2, 31, R_PELE['sombra'])
        q.p(cx + 4, 28, '#2A1A12')
    # nariz: só a sombra do lado direito e a ponta
    q.linha([(33, 28), (34, 34), (35, 37)], R_PELE['sombra'])
    q.r(30, 38, 35, 38, R_PELE['sombra']); q.p(31, 37, R_PELE['luz']); q.p(32, 37, R_PELE['luz'])
    # boca
    _boca(q, boca, 27, 37, 42, labio='#C9807A', linha='#8A4640', dente='#F6F2EC', luz=R_PELE['luz'])
    # gola branca da camisa e lenço verde com anel dourado
    q.poly([(24, 51), (28, 50), (32, 56), (27, 58)], '#E6D8B0')
    q.poly([(40, 51), (36, 50), (32, 56), (37, 58)], '#CDBB8A')
    q.poly([(26, 51), (29, 50), (32, 54), (35, 50), (38, 51), (35, 58), (32, 63), (29, 58)], '#2A6B3E')
    q.poly([(33, 55), (37, 51), (35, 58)], '#1C4E2C')
    q.r(30, 56, 34, 57, '#E4B45C'); q.p(31, 56, '#FFF0C0')
    return q.contornar()


# --- Shara --------------------------------------------------------------------
# Rosto jovem e oval, cabelo castanho liso e comprido repartido ao meio,
# óculos redondos de armação escura, olhos verdes, sorriso aberto. Vestido
# escuro com blusa clara de gola rendada (roupa da época).

S_PELE = dict(luz='#FBE6D8', base='#F3D1BE', sombra='#DFAE98', funda='#C38C78')
S_CAB = dict(luz='#A87A52', base='#7C5434', sombra='#583A22', funda='#3C2614')
S_OLHO = dict(iris='#5FA070', iris_escura='#2F6040', brilho='#E8F6EC')


def shara(boca):
    q = Q()
    # cabelo de trás, comprido até abaixo dos ombros
    q.poly([(32, 4), (22, 6), (16, 12), (13, 22), (12, 38), (10, 54), (11, 63), (53, 63), (54, 54),
            (52, 38), (51, 22), (48, 12), (42, 6)], S_CAB['sombra'])
    # ombros: vestido escuro e blusa clara com gola rendada
    q.poly([(2, 63), (6, 57), (16, 53), (48, 53), (58, 57), (62, 63)], '#2C2C36')
    q.poly([(2, 63), (6, 57), (13, 54), (12, 63)], '#1C1C24')
    q.poly([(50, 54), (58, 57), (61, 62), (54, 60)], '#46465A')
    q.poly([(22, 53), (42, 53), (40, 59), (32, 61), (24, 59)], '#F2ECE2')
    for x in range(23, 42, 2):
        q.p(x, 59 if 26 <= x <= 38 else 58, '#D6CCBE')
    q.p(32, 61, '#E4B45C')
    # pescoço
    q.r(27, 44, 37, 54, S_PELE['base'])
    q.r(27, 44, 37, 48, S_PELE['sombra'])
    q.poly([(34, 46), (37, 44), (37, 54), (34, 54)], S_PELE['sombra'])
    q.r(27, 53, 37, 54, S_PELE['base'])
    # rosto oval, queixo suave
    rosto = [(20, 16), (44, 16), (45, 30), (43, 38), (40, 43), (36, 47), (32, 48), (28, 47), (24, 43), (21, 38), (19, 30)]
    q.poly(rosto, S_PELE['base'])
    q.poly([(41, 16), (44, 16), (45, 30), (43, 38), (40, 43), (36, 47), (37, 43), (40, 38), (42, 30)], S_PELE['sombra'])
    q.poly([(25, 17), (29, 17), (28, 19), (26, 20)], S_PELE['luz'])
    # bochechas rosadas do sorriso
    q.r(22, 36, 25, 37, '#F0B8A8'); q.r(39, 36, 42, 37, '#E2A494')
    # cabelo da frente: repartido ao meio, caindo dos dois lados do rosto
    esquerda = [(32, 6), (25, 7), (19, 12), (16, 20), (15, 32), (14, 46), (13, 58), (16, 63), (19, 63),
                (19, 50), (20, 38), (21, 24), (24, 16), (29, 11), (32, 10)]
    q.poly(esquerda, S_CAB['base'])
    q.poly(espelho(esquerda), S_CAB['base'])
    q.poly([(30, 7), (24, 9), (19, 14), (17, 22), (16, 34), (18, 34), (19, 22), (22, 15), (27, 10)], S_CAB['luz'])
    q.poly([(34, 7), (40, 8), (45, 14), (44, 15), (39, 11)], S_CAB['luz'])
    q.poly([(46, 20), (48, 32), (49, 46), (50, 58), (47, 63), (45, 63), (45, 50), (44, 38), (43, 24)], S_CAB['sombra'])
    q.linha([(17, 40), (16, 56)], S_CAB['sombra'])
    q.linha([(32, 6), (32, 10)], S_CAB['funda'])  # risca do meio
    # sobrancelhas finas
    q.linha([(22, 23), (24, 22), (29, 22)], S_CAB['base'])
    q.linha([(35, 22), (40, 22), (42, 23)], S_CAB['base'])
    # olhos verdes, um pouco maiores, com cílios
    for cx in (26, 38):
        q.r(cx - 3, 27, cx + 3, 27, '#24161A')
        q.p(cx - 4, 27, '#24161A') if cx < 32 else q.p(cx + 4, 27, '#24161A')
        q.r(cx - 3, 28, cx + 3, 30, '#F6F2EE')
        q.r(cx - 1, 28, cx + 1, 30, S_OLHO['iris'])
        q.r(cx - 1, 28, cx + 1, 28, S_OLHO['iris_escura'])
        q.p(cx, 29, '#1A2A20'); q.p(cx - 1, 28, S_OLHO['brilho'])
        q.r(cx - 2, 31, cx + 2, 31, S_PELE['sombra'])
    # óculos redondos de armação escura
    q.elipse((20, 24, 31, 34), None, borda='#2A2630')
    q.elipse((33, 24, 44, 34), None, borda='#2A2630')
    q.r(31, 27, 33, 27, '#2A2630')
    q.p(22, 26, '#FFFFFF'); q.p(35, 26, '#FFFFFF')
    # nariz pequeno
    q.linha([(33, 31), (34, 35)], S_PELE['sombra'])
    q.r(30, 37, 34, 37, S_PELE['sombra']); q.p(31, 36, S_PELE['luz'])
    # boca
    _boca(q, boca, 26, 38, 41, labio='#E0928E', linha='#9A4E52', dente='#FAF6F0', luz=S_PELE['luz'])
    return q.contornar()


def _boca(q, boca, x0, x1, y, labio, linha, dente, luz):
    # sorriso: cantos sobem um pixel; 0 = fechada, 1 = entreaberta, 2 = aberta
    q.p(x0, y - 1, linha); q.p(x1, y - 1, linha)
    if boca == 0:
        q.r(x0 + 1, y, x1 - 1, y, linha)
        q.r(x0 + 3, y + 1, x1 - 3, y + 1, labio)
        q.r(x0 + 4, y + 2, x1 - 4, y + 2, luz)
    else:
        aberta = 1 if boca == 1 else 2
        q.r(x0 + 1, y, x1 - 1, y, linha)
        q.r(x0 + 2, y + 1, x1 - 2, y + aberta, dente)
        q.r(x0 + 3, y + aberta + 1, x1 - 3, y + aberta + 1, linha)
        q.r(x0 + 4, y + aberta + 2, x1 - 4, y + aberta + 2, labio)


BOCAS = 3
DESENHOS = {'rafael': rafael, 'shara': shara}

if __name__ == '__main__':
    raiz = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'art', 'convidados')
    for id, desenho in DESENHOS.items():
        pasta = os.path.join(raiz, id)
        os.makedirs(pasta, exist_ok=True)
        quadros = [desenho(i) for i in range(BOCAS)]
        quadros[0].save(os.path.join(pasta, '%s_retrato.png' % id))
        faixa = Image.new('RGBA', (N * BOCAS, N), (0, 0, 0, 0))
        for i, q in enumerate(quadros):
            faixa.paste(q, (i * N, 0))
        faixa.save(os.path.join(pasta, '%s_retrato_fala.png' % id))
        print(id, faixa.size)
