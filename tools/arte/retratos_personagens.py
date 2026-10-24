# Gera os retratos 64×64 dos personagens do livro para a caixa de diálogo,
# por idade e emoção, no mesmo jeito dos retratos dos convidados (pixel art,
# sombreado chapado com luz da esquerda, contorno escuro).
# Uso: python3 tools/arte/retratos_personagens.py [pasta_da_previa]
#
# Para cada personagem, idade e emoção saem três arquivos em
# assets/art/retratos/<id>/:
#   <id>[_<idade>]_<emocao>.png          boca fechada (o retrato parado)
#   <id>[_<idade>]_<emocao>_fala.png     3 quadros: fechada, entreaberta, aberta
#   <id>[_<idade>]_<emocao>_piscando.png olhos fechados
#
# Aparência tirada de livro/fichas-personagens.md e das folhas da exploração
# (gerar_personagens.py). O que o livro não descreve (roupas, o rosto de
# Apollon e de Pany, a cor da bandana de Janet) é inferência, provisória.
import os
import sys

from PIL import Image, ImageDraw

from retratos_convidados import Q, N

EMOCOES = ['neutro', 'alegre', 'triste', 'raiva', 'surpresa', 'medo']

# (sobrancelha, olhos, boca, rubor) de cada emoção
ROSTO_DA_EMOCAO = {
    'neutro':   ('reta', 'normal', 'neutra', False),
    'alegre':   ('alta', 'feliz', 'sorriso', True),
    'triste':   ('triste', 'baixo', 'triste', False),
    'raiva':    ('brava', 'estreito', 'cerrada', True),
    'surpresa': ('arqueada', 'arregalado', 'o', False),
    'medo':     ('triste', 'arregalado', 'tremida', False),
}

# Formato do rosto por idade: contorno, altura dos olhos (linha de cima),
# sobrancelhas, boca, nariz, pescoço, ombros, testa (onde o cabelo começa) e
# quantas linhas de branco o olho tem.
GEOMETRIA = {
    'pequena': dict(  # 6 anos: cabeça redonda, olhos grandes e baixos
        rosto=[(17, 20), (47, 20), (48, 32), (46, 40), (42, 45), (37, 48), (32, 49), (27, 48),
               (22, 45), (18, 40), (16, 32)],
        olho=30, olho_alto=3, sob=27, boca=(28, 37, 42), nariz=[(33, 35), (33, 37)], narina=(32, 38, 33),
        pescoco=(28, 46, 36, 54), ombro=54, testa=20, orelha=31),
    'crianca': dict(  # 11 anos
        rosto=[(18, 18), (46, 18), (47, 31), (45, 39), (41, 44), (36, 47), (32, 48), (28, 47),
               (23, 44), (19, 39), (17, 31)],
        olho=28, olho_alto=3, sob=25, boca=(28, 37, 41), nariz=[(33, 31), (34, 35)], narina=(31, 37, 34),
        pescoco=(28, 44, 36, 53), ombro=53, testa=18, orelha=29),
    'adulto': dict(  # rapaz de 17 e homem feito: rosto mais comprido, queixo marcado
        rosto=[(19, 14), (45, 14), (46, 28), (45, 36), (43, 42), (38, 47), (32, 49), (26, 47),
               (21, 42), (19, 36), (18, 28)],
        olho=27, olho_alto=2, sob=24, boca=(27, 37, 41), nariz=[(33, 27), (35, 35)], narina=(30, 37, 35),
        pescoco=(27, 44, 37, 54), ombro=54, testa=14, orelha=26),
    'adulta': dict(  # moça de 17 e mulher feita: queixo mais suave
        rosto=[(20, 15), (44, 15), (45, 28), (44, 36), (41, 42), (36, 47), (32, 48), (28, 47),
               (23, 42), (20, 36), (19, 28)],
        olho=27, olho_alto=2, sob=24, boca=(28, 36, 41), nariz=[(33, 29), (34, 35)], narina=(31, 37, 34),
        pescoco=(28, 44, 36, 54), ombro=54, testa=15, orelha=27),
}

PELE_CLARA = dict(luz='#FCEDE4', base='#F6DCCF', sombra='#E3B9A8', funda='#C99886', rubor='#F2A8A0')
PELE_OLYMPIA = dict(luz='#FBEBE0', base='#F3D8CA', sombra='#DDB3A2', funda='#C29482', rubor='#EE9E98')
PELE_CARAMELO = dict(luz='#D49A6C', base='#B47A50', sombra='#8C5836', funda='#6A3E24', rubor='#C46A56')
PELE_ESCURA = dict(luz='#9A6646', base='#7A4C32', sombra='#5C3622', funda='#422416', rubor='#9A4A3E')
PELE_MADURA = dict(luz='#F4DCCB', base='#E6C4AE', sombra='#C99E88', funda='#A87C68', rubor='#DE9C8C')

CAB_OLYMPIA = dict(luz='#FBF3D6', base='#E8DBA6', sombra='#C4B07A', funda='#9C8A5A')
CAB_APOLLON = dict(luz='#F2EAD0', base='#DACFA8', sombra='#B4A67E', funda='#8E8160')
CAB_ESCURO = dict(luz='#6A4C3A', base='#3A2820', sombra='#24170F', funda='#170E09')
CAB_JANET = dict(luz='#4A3426', base='#2A1C14', sombra='#180F0A', funda='#0C0705')
CAB_LOJISTA = dict(luz='#9A8266', base='#7A6450', sombra='#554434', funda='#3A2B22')
CAB_GRISALHO = dict(luz='#E4E2DE', base='#B8B4AE', sombra='#8C8882', funda='#64605C')

LINHA = '#3A2620'
BRANCO_OLHO = '#F8F6F2'
ANEL = '#E2B448'


def deslocar(pts, dy):
    return [(x, y + dy) for x, y in pts]


def espelhar(pts):
    return [(64 - x, y) for x, y in pts]


# --- cabelos ------------------------------------------------------------------
# Cada estilo tem a parte de trás (antes do rosto) e a da frente (depois).

def cabelo_rebelde(q, c, g, camada):
    # Nicholas: loiro-pálido, rebelde, com franja
    dy = g['testa'] - 18
    if camada == 'atras':
        return
    q.poly(deslocar([(15, 30), (14, 18), (17, 10), (23, 5), (32, 3), (41, 5), (47, 10), (50, 18), (49, 30),
                     (46, 24), (44, 19), (20, 19), (18, 24)], dy), c['base'])
    q.poly(deslocar([(18, 22), (20, 15), (25, 12), (32, 11), (39, 12), (44, 15), (46, 22), (43, 19), (41, 23),
                     (38, 18), (35, 22), (32, 17), (29, 23), (26, 18), (23, 23), (21, 19)], dy), c['base'])
    q.poly(deslocar([(18, 12), (22, 7), (29, 5), (26, 9), (21, 13)], dy), c['luz'])
    q.poly(deslocar([(27, 13), (31, 12), (29, 19)], dy), c['luz'])
    q.poly(deslocar([(45, 10), (49, 16), (49, 28), (46, 22)], dy), c['sombra'])
    q.linha(deslocar([(35, 13), (38, 19)], dy), c['sombra'])
    q.linha(deslocar([(40, 14), (43, 20)], dy), c['sombra'])
    q.poly(deslocar([(22, 6), (18, 1), (25, 4)], dy), c['base'])
    q.poly(deslocar([(40, 4), (45, 0), (43, 6)], dy), c['base'])
    q.poly(deslocar([(48, 14), (53, 12), (49, 19)], dy), c['sombra'])


def cabelo_penteado(q, c, g, camada):
    # Apollon: o loiro-pálido dos Olympia, curto e penteado para trás
    if camada == 'atras':
        return
    q.poly([(17, 26), (16, 14), (19, 7), (25, 3), (32, 2), (40, 3), (46, 7), (49, 14), (48, 26),
            (46, 20), (44, 16), (38, 15), (26, 15), (21, 16), (19, 20)], c['base'])
    q.poly([(18, 13), (21, 7), (28, 4), (26, 7), (21, 11)], c['luz'])
    q.poly([(30, 4), (38, 4), (34, 6)], c['luz'])
    q.poly([(44, 6), (48, 11), (48, 24), (46, 18)], c['sombra'])
    q.linha([(24, 6), (32, 5), (41, 7)], c['sombra'])
    q.linha([(22, 10), (30, 8)], c['sombra'])
    q.linha([(36, 8), (44, 11)], c['sombra'])


def cabelo_ombros(q, c, g, camada):
    # Althea aos 6: loiro-pálido até os ombros, indomável
    t = g['testa']
    if camada == 'atras':
        q.poly([(32, t - 14), (20, t - 11), (13, t - 4), (11, t + 10), (10, t + 26), (8, t + 34), (13, t + 33),
                (15, t + 36), (49, t + 36), (51, t + 33), (56, t + 34), (54, t + 26), (53, t + 10), (51, t - 4),
                (44, t - 11)], c['sombra'])
        return
    lado = [(32, t - 13), (22, t - 10), (16, t - 4), (13, t + 6), (12, t + 18), (11, t + 28), (9, t + 33),
            (14, t + 31), (16, t + 34), (18, t + 26), (18, t + 14), (19, t + 6), (22, t + 2), (27, t + 1), (32, t - 2)]
    q.poly(lado, c['base'])
    q.poly(espelhar(lado), c['base'])
    franja = [(19, t + 6), (22, t - 3), (28, t - 7), (36, t - 7), (42, t - 3), (45, t + 6), (42, t + 3), (40, t + 7),
              (37, t + 2), (34, t + 6), (31, t + 1), (28, t + 6), (25, t + 2), (22, t + 7)]
    q.poly(franja, c['base'])
    q.poly([(15, t - 2), (20, t - 8), (27, t - 11), (24, t - 6), (18, t), (15, t + 10)], c['luz'])
    q.poly([(26, t - 4), (31, t - 6), (28, t + 2)], c['luz'])
    q.poly([(46, t - 2), (50, t + 6), (51, t + 20), (52, t + 30), (49, t + 32), (48, t + 18), (47, t + 6)], c['sombra'])
    q.linha([(36, t - 4), (39, t + 2)], c['sombra'])
    q.poly([(20, t - 9), (16, t - 14), (23, t - 11)], c['base'])
    q.poly([(41, t - 10), (46, t - 15), (45, t - 8)], c['base'])
    q.poly([(12, t + 22), (7, t + 24), (11, t + 27)], c['base'])
    q.poly([(52, t + 20), (57, t + 23), (53, t + 26)], c['sombra'])


def cabelo_trancinhas(q, c, g, camada, fita='#6E9CCC'):
    # Althea aos 11: o mesmo cabelo rebelde, com tranças laterais de fita
    # imitando Ophelia
    cabelo_ombros(q, c, g, camada)
    if camada == 'atras':
        return
    t = g['testa']
    for x in (13, 48):
        for i, y in enumerate(range(t + 14, t + 38, 3)):
            q.r(x, y, x + 3, y + 2, c['base'] if i % 2 == 0 else c['luz'])
            q.p(x + (3 if i % 2 == 0 else 0), y + 2, c['sombra'])
        q.r(x - 1, t + 38, x + 4, t + 39, fita)
        q.p(x - 1, t + 40, fita); q.p(x + 4, t + 40, fita)


def cabelo_ondulado_trancas(q, c, g, camada):
    # Ophelia aos 11: escuro, longo e ondulado, duas tranças das têmporas
    # presas atrás
    t = g['testa']
    if camada == 'atras':
        q.poly([(32, t - 12), (20, t - 9), (13, t - 2), (11, t + 12), (9, t + 30), (7, 63), (57, 63), (55, t + 30),
                (53, t + 12), (51, t - 2), (44, t - 9)], c['sombra'])
        for y in range(t + 14, 63, 6):
            q.linha([(9, y), (11, y + 3), (9, y + 5)], c['funda'])
            q.linha([(55, y), (53, y + 3), (55, y + 5)], c['funda'])
        return
    lado = [(32, t - 11), (23, t - 9), (17, t - 3), (15, t + 8), (14, t + 22), (13, t + 34), (17, t + 34),
            (17, t + 20), (18, t + 8), (21, t + 2), (26, t - 1), (32, t - 3)]
    q.poly(lado, c['base'])
    q.poly(espelhar(lado), c['base'])
    q.poly([(29, t - 9), (23, t - 7), (18, t - 1), (16, t + 10), (18, t + 10), (19, t + 2), (24, t - 4)], c['luz'])
    q.poly([(35, t - 9), (41, t - 7), (45, t - 3), (40, t - 5)], c['luz'])
    q.linha([(32, t - 10), (32, t - 4)], c['funda'])                 # risca ao meio
    # tranças que saem das têmporas e vão para trás
    for lado_x, passo in ((17, 1), (47, -1)):
        for i in range(5):
            x = lado_x + passo * i * 2
            y = t + 3 - i * 2
            q.r(min(x, x + passo), y, max(x, x + passo), y + 1, c['luz'] if i % 2 else c['base'])
            q.p(x, y + 2, c['funda'])


def cabelo_cachos_franja(q, c, g, camada):
    # Ophelia aos 17: escuro até a cintura, com cachos e franja
    t = g['testa']
    if camada == 'atras':
        q.poly([(32, t - 12), (19, t - 9), (12, t - 1), (10, t + 14), (8, t + 30), (6, 63), (58, 63), (56, t + 30),
                (54, t + 14), (52, t - 1), (45, t - 9)], c['sombra'])
        for y in range(t + 10, 63, 5):
            for x in (8, 11, 53, 56):
                q.p(x, y, c['luz']); q.p(x + 1, y + 1, c['base'])
        return
    lado = [(32, t - 11), (22, t - 9), (16, t - 2), (14, t + 10), (13, t + 26), (12, t + 40), (17, t + 40),
            (17, t + 24), (18, t + 10), (20, t + 3)]
    q.poly(lado, c['base'])
    q.poly(espelhar(lado), c['base'])
    franja = [(19, t + 4), (21, t - 4), (27, t - 8), (37, t - 8), (43, t - 4), (45, t + 4), (42, t + 6), (39, t + 3),
              (36, t + 7), (33, t + 3), (30, t + 7), (27, t + 3), (24, t + 7), (21, t + 4)]
    q.poly(franja, c['base'])
    q.poly([(22, t - 5), (28, t - 7), (25, t - 2), (21, t + 2)], c['luz'])
    q.poly([(16, t + 2), (18, t - 2), (17, t + 14)], c['luz'])
    for y in range(t + 14, t + 40, 5):
        q.p(14, y, c['luz']); q.p(15, y + 1, c['luz'])
        q.p(49, y + 2, c['sombra']); q.p(48, y + 3, c['sombra'])


def cabelo_bandana(q, c, g, camada, bandana='#3E6A9E', bandana_sombra='#2B4C74'):
    # Janet: cachos presos por uma bandana (cor provisória: azul, a do colete)
    t = g['testa']
    if camada == 'atras':
        q.elipse((12, t - 12, 52, t + 22), c['base'])
        for (x, y) in ((14, t + 2), (16, t + 12), (48, t + 4), (46, t + 14), (20, t - 8), (42, t - 8)):
            q.elipse((x - 3, y - 3, x + 3, y + 3), c['luz'] if x < 32 else c['sombra'])
        return
    q.poly([(18, t + 6), (19, t - 2), (24, t - 6), (32, t - 7), (40, t - 6), (45, t - 2), (46, t + 6),
            (42, t + 3), (32, t + 2), (22, t + 3)], c['base'])
    q.p(24, t, c['luz']); q.p(28, t - 2, c['luz']); q.p(36, t - 1, c['luz'])
    # bandana: faixa larga em cima da cabeça e o nó do lado
    q.poly([(17, t - 1), (20, t - 9), (28, t - 13), (36, t - 13), (44, t - 9), (47, t - 1), (44, t - 4),
            (36, t - 7), (28, t - 7), (20, t - 4)], bandana)
    q.poly([(36, t - 7), (44, t - 4), (47, t - 1), (44, t - 9), (36, t - 13)], bandana_sombra)
    q.poly([(46, t - 4), (52, t - 9), (53, t - 4), (50, t - 2)], bandana)
    q.poly([(48, t - 2), (53, t + 3), (50, t + 4)], bandana_sombra)
    q.linha([(22, t - 6), (32, t - 9), (42, t - 6)], '#6A92C0')


def cabelo_coque(q, c, g, camada):
    # Pany: grisalho, preso num coque (aparência provisória, não descrita)
    t = g['testa']
    if camada == 'atras':
        q.elipse((24, t - 20, 40, t - 7), c['base'])
        q.elipse((26, t - 18, 32, t - 12), c['luz'])
        return
    q.poly([(18, t + 10), (17, t + 1), (20, t - 6), (26, t - 10), (32, t - 11), (38, t - 10), (44, t - 6),
            (47, t + 1), (46, t + 10), (44, t + 3), (40, t + 1), (32, t), (24, t + 1), (20, t + 3)], c['base'])
    q.poly([(19, t), (22, t - 6), (28, t - 9), (25, t - 4), (20, t + 4)], c['luz'])
    q.poly([(42, t - 6), (46, t), (46, t + 8), (44, t + 2)], c['sombra'])
    q.linha([(24, t - 6), (32, t - 8), (40, t - 6)], c['sombra'])
    q.linha([(22, t - 2), (30, t - 5)], c['sombra'])


CABELOS = dict(rebelde=cabelo_rebelde, penteado=cabelo_penteado, ombros=cabelo_ombros,
               trancinhas=cabelo_trancinhas, ondulado_trancas=cabelo_ondulado_trancas,
               cachos_franja=cabelo_cachos_franja, bandana=cabelo_bandana, coque=cabelo_coque)


# --- roupas -------------------------------------------------------------------

def roupa(q, cfg, g):
    r = cfg['roupa']
    y = g['ombro']
    estilo = r['estilo']
    q.poly([(3, 63), (7, y + 4), (17, y), (47, y), (57, y + 4), (61, 63)], r['base'])
    q.poly([(3, 63), (7, y + 4), (14, y + 1), (13, 63)], r['sombra'])
    q.poly([(51, y + 1), (57, y + 4), (60, 62), (53, 60)], r['luz'])
    if estilo == 'colete':          # camisa branca e colete azul-escuro (Nicholas aos 11)
        q.poly([(24, y - 1), (40, y - 1), (37, 63), (27, 63)], '#F2EEE6')
        q.poly([(24, y - 1), (29, y - 2), (32, y + 4), (27, y + 5)], '#FFFFFF')
        q.poly([(40, y - 1), (35, y - 2), (32, y + 4), (37, y + 5)], '#DCD6CC')
    elif estilo == 'tunica':        # túnica de Olympia com debrum dourado e manto escuro
        q.poly([(25, y - 1), (39, y - 1), (32, y + 7)], cfg['pele']['sombra'])
        q.linha([(25, y - 1), (32, y + 7), (39, y - 1)], ANEL)
        q.linha([(26, y + 1), (32, y + 8)], '#B98543')
        q.poly([(3, 63), (6, y + 5), (14, y + 1), (18, y + 2), (12, 63)], '#0B1726')
        q.poly([(61, 63), (58, y + 5), (50, y + 1), (46, y + 2), (52, 63)], '#13253C')
        q.r(15, y + 2, 17, y + 4, ANEL)
    elif estilo == 'casaco':        # casaco de duque, gola alta, lenço branco e botões dourados
        q.poly([(25, y - 2), (39, y - 2), (36, y + 6), (32, y + 9), (28, y + 6)], '#F2EFE8')
        q.poly([(20, y - 1), (26, y - 3), (30, y + 8), (24, y + 9)], r['luz'])
        q.poly([(44, y - 1), (38, y - 3), (34, y + 8), (40, y + 9)], r['sombra'])
        for yy in (y + 4, y + 8):
            q.p(28, yy, ANEL); q.p(36, yy, ANEL)
    elif estilo == 'vestido':       # gola redonda simples
        q.poly([(25, y - 1), (39, y - 1), (37, y + 3), (32, y + 4), (27, y + 3)], cfg['pele']['base'])
        if r.get('gola'):
            q.linha([(24, y), (27, y + 4), (32, y + 5), (37, y + 4), (40, y)], r['gola'])
    elif estilo == 'imperial':      # decote com gola de ouro e manto claro nos ombros
        q.poly([(24, y - 1), (40, y - 1), (37, y + 5), (32, y + 6), (27, y + 5)], cfg['pele']['base'])
        q.linha([(23, y), (27, y + 6), (32, y + 7), (37, y + 6), (41, y)], ANEL)
        q.poly([(3, 63), (6, y + 5), (16, y + 1), (12, 63)], '#E8E1D4')
        q.poly([(61, 63), (58, y + 5), (48, y + 1), (52, 63)], '#B8AE9C')
    elif estilo == 'colete_janet':  # vestido claro e colete azul
        q.poly([(22, y - 1), (42, y - 1), (39, 63), (25, 63)], '#E8DCC4')
        q.poly([(25, y - 1), (39, y - 1), (36, y + 3), (32, y + 4), (28, y + 3)], cfg['pele']['base'])
    elif estilo == 'uniforme':      # guarda imperial: casaco vermelho, faixa central e colar dourados, ombreiras
        q.poly([(25, y - 2), (39, y - 2), (37, y + 2), (27, y + 2)], r['luz'])           # gola alta
        q.r(29, y + 2, 35, 63, '#B98543')                                                 # faixa central
        q.r(29, y + 2, 29, 63, '#8A5E2C')
        for yy in range(y + 4, 63, 3):
            q.p(32, yy, '#ECBD75')                                                        # botões
        q.linha([(24, y + 1), (28, y + 4), (32, y + 5), (36, y + 4), (40, y + 1)], ANEL)  # colar dourado
        q.poly([(5, y + 6), (9, y + 2), (17, y), (18, y + 3), (8, y + 7)], '#B98543')     # ombreiras
        q.poly([(59, y + 6), (55, y + 2), (47, y), (46, y + 3), (56, y + 7)], '#8A5E2C')
    elif estilo == 'governanta':    # vestido escuro fechado com gola branca
        q.poly([(25, y - 1), (39, y - 1), (37, y + 3), (27, y + 3)], '#E4E2DE')
        q.poly([(24, y + 1), (28, y + 4), (32, y + 2), (36, y + 4), (40, y + 1), (38, y + 5), (32, y + 4),
                (26, y + 5)], '#C8C6C2')
        q.r(31, y + 5, 33, y + 6, '#B98543')
    if r.get('perolas'):
        for i, x in enumerate(range(25, 40, 2)):
            yy = y + 4 + (1 if 27 <= x <= 37 else 0) + (1 if 29 <= x <= 35 else 0)
            q.p(x, yy, '#F4F0EA')


# --- rosto --------------------------------------------------------------------

def sobrancelhas(q, g, tipo, cor):
    y = g['sob']
    for lado in (-1, 1):
        x_dentro, x_fora = 32 + lado * 4, 32 + lado * 10
        if tipo == 'reta':
            q.linha([(x_fora, y), (x_dentro, y)], cor)
        elif tipo == 'alta':
            q.linha([(x_fora, y), (32 + lado * 7, y - 1), (x_dentro, y - 1)], cor)
        elif tipo == 'arqueada':
            q.linha([(x_fora, y), (32 + lado * 7, y - 2), (x_dentro, y - 1)], cor)
        elif tipo == 'triste':
            q.linha([(x_fora, y + 1), (x_dentro, y - 1)], cor)
        elif tipo == 'brava':
            q.linha([(x_fora, y - 1), (x_dentro, y + 1)], cor)
            q.p(x_dentro, y + 2, cor)


def olhos(q, cfg, g, tipo, piscando, emocao):
    y0 = g['olho']
    alto = g['olho_alto']
    pele = cfg['pele']
    cor_olho = cfg['olhos']
    for cx in (25, 39):
        if piscando or tipo == 'feliz':
            if tipo == 'feliz' and not piscando:
                q.linha([(cx - 3, y0 + 2), (cx, y0), (cx + 3, y0 + 2)], LINHA)
            else:
                q.r(cx - 3, y0 + alto, cx + 3, y0 + alto, LINHA)
            if cfg.get('cilios'):
                q.p(cx - 4 if cx < 32 else cx + 4, y0 + (1 if tipo == 'feliz' and not piscando else alto - 1), LINHA)
            continue
        topo = y0 + {'normal': 0, 'baixo': 1, 'estreito': 1, 'arregalado': -1}[tipo]
        fundo = max(topo + 1, y0 + alto + {'normal': 0, 'baixo': 0, 'estreito': -1, 'arregalado': 1}[tipo])
        q.r(cx - 3, topo, cx + 3, topo, LINHA)
        if cfg.get('cilios'):
            q.p(cx - 4 if cx < 32 else cx + 4, topo, LINHA)
        q.r(cx - 3, topo + 1, cx + 3, fundo, BRANCO_OLHO)
        meio = (topo + 1 + fundo) // 2
        if cor_olho == 'abencoado':
            # azul-pálido com o anel dourado; no Nicholas de 17 o dourado
            # "avança" com a emoção (V2 c17)
            avanca = cfg.get('anel_avanca') and emocao in ('raiva', 'surpresa', 'medo')
            q.r(cx - 2, topo + 1, cx + 2, fundo, ANEL)
            if not avanca:
                q.r(cx - 1, topo + 1, cx + 1, fundo, '#DCEAF4')
            q.p(cx, meio, '#3A4A5A')
        else:
            iris, escura = cor_olho
            q.r(cx - 2, topo + 1, cx + 2, fundo, escura)
            q.r(cx - 1, topo + 1, cx + 1, fundo, iris)
            q.p(cx, meio, '#1E1A1C')
        q.p(cx - 1, topo + 1, '#FFFFFF')
        if tipo == 'baixo':
            q.r(cx - 3, topo + 1, cx + 3, topo + 1, pele['sombra'])
        q.r(cx - 2, fundo + 1, cx + 2, fundo + 1, pele['sombra'])


def boca(q, cfg, g, forma, aberta):
    x0, x1, y = g['boca']
    ln = cfg.get('boca_linha', '#9A5048')
    dente, fundo = '#FAF6F0', '#5A2A2A'
    if aberta > 0:
        ab = aberta + (1 if forma == 'o' else 0)
        if forma == 'o':
            x0, x1 = x0 + 1, x1 - 1
        q.r(x0 + 1, y, x1 - 1, y, ln)
        q.r(x0 + 2, y + 1, x1 - 2, y + ab, fundo)
        if forma != 'o':
            q.r(x0 + 2, y + 1, x1 - 2, y + 1, dente)
        q.r(x0 + 3, y + ab + 1, x1 - 3, y + ab + 1, ln)
        if forma == 'sorriso':
            q.p(x0, y - 1, ln); q.p(x1, y - 1, ln)
        elif forma in ('triste', 'tremida'):
            q.p(x0 + 1, y + 1, ln); q.p(x1 - 1, y + 1, ln)
        return
    if forma == 'neutra':
        q.r(x0 + 2, y, x1 - 2, y, ln)
        if cfg.get('sorriso_torto'):
            q.p(x1 - 1, y - 1, ln)
    elif forma == 'sorriso':
        q.p(x0, y - 1, ln); q.r(x0 + 1, y, x1 - 1, y, ln); q.p(x1, y - 1, ln)
        q.r(x0 + 2, y + 1, x1 - 2, y + 1, dente)
        q.r(x0 + 3, y + 2, x1 - 3, y + 2, ln)
    elif forma == 'triste':
        q.p(x0 + 1, y + 1, ln); q.r(x0 + 2, y, x1 - 2, y, ln); q.p(x1 - 1, y + 1, ln)
    elif forma == 'cerrada':
        q.r(x0 + 1, y, x1 - 1, y, ln); q.r(x0 + 2, y + 1, x1 - 2, y + 1, dente); q.r(x0 + 1, y + 2, x1 - 1, y + 2, ln)
    elif forma == 'o':
        m = (x0 + x1) // 2
        q.r(m - 1, y, m + 2, y, ln); q.r(m - 2, y + 1, m + 3, y + 2, fundo); q.r(m - 1, y + 3, m + 2, y + 3, ln)
    elif forma == 'tremida':
        q.linha([(x0 + 1, y + 1), (x0 + 3, y), (x0 + 5, y + 1), (x0 + 7, y), (x1 - 1, y + 1)], ln)
    if cfg.get('labio') and forma in ('neutra', 'triste'):
        q.r(x0 + 3, y + 1, x1 - 3, y + 1, cfg['labio'])


def retrato(cfg, emocao, aberta=0, piscando=False):
    g = GEOMETRIA[cfg['geometria']]
    pele, cab = cfg['pele'], cfg['cabelo_cores']
    estilo = CABELOS[cfg['cabelo']]
    sob, tipo_olho, forma_boca, rubor = ROSTO_DA_EMOCAO[emocao]
    q = Q()
    estilo(q, cab, g, 'atras')
    roupa(q, cfg, g)
    x0, y0, x1, y1 = g['pescoco']
    q.r(x0, y0, x1, y1, pele['base'])
    q.r(x0, y0, x1, y0 + 3, pele['sombra'])
    q.poly([(x1 - 3, y0 + 2), (x1, y0), (x1, y1), (x1 - 3, y1)], pele['sombra'])
    o = g['orelha']
    q.elipse((15, o - 2, 20, o + 7), pele['base'])
    q.elipse((44, o - 2, 49, o + 7), pele['sombra'])
    q.poly(g['rosto'], pele['base'])
    r = g['rosto']
    q.poly([(r[1][0] - 3, r[1][1]), r[1], r[2], r[3], r[4], r[5], (r[5][0] + 1, r[5][1] - 4),
            (r[4][0] - 3, r[4][1] - 5), (r[3][0] - 3, r[3][1] - 1), (r[2][0] - 4, r[2][1])], pele['sombra'])
    q.poly([(r[0][0] + 4, r[0][1] + 1), (r[0][0] + 9, r[0][1] + 1), (r[0][0] + 7, r[0][1] + 4)], pele['luz'])
    if cfg.get('bochecha'):
        q.r(20, g['olho'] + 7, 23, g['olho'] + 7, cfg['bochecha'])
        q.r(41, g['olho'] + 7, 44, g['olho'] + 7, cfg['bochecha'])
    if rubor or cfg.get('cora_facil') and emocao in ('triste', 'medo'):
        q.r(20, g['olho'] + 6, 24, g['olho'] + 7, pele['rubor'])
        q.r(40, g['olho'] + 6, 44, g['olho'] + 7, pele['rubor'])
    estilo(q, cab, g, 'frente')
    sobrancelhas(q, g, sob, cfg.get('cor_sobrancelha', cab['funda']))
    olhos(q, cfg, g, tipo_olho, piscando, emocao)
    if emocao == 'triste':
        y = g['olho'] + g['olho_alto'] + 2
        q.p(23, y, '#BFE0F4'); q.p(23, y + 1, '#9CCBEA')
    q.linha(g['nariz'], pele['sombra'])
    nx0, ny, nx1 = g['narina']
    q.r(nx0, ny, nx1, ny, pele['sombra'])
    if cfg.get('ruga'):
        q.p(20, g['olho'] + 1, pele['sombra']); q.p(44, g['olho'] + 1, pele['sombra'])
        q.linha([(27, g['boca'][2] - 3), (26, g['boca'][2])], pele['sombra'])
        q.linha([(37, g['boca'][2] - 3), (38, g['boca'][2])], pele['sombra'])
    boca(q, cfg, g, forma_boca, aberta)
    return q.contornar()


# --- elenco -------------------------------------------------------------------

AZUL_ALTHEA = ('#5E9AE0', '#2F5E9E')     # azul saturado, os olhos de Neola
CASTANHO = ('#8A5A3A', '#4E301E')

NICHOLAS = dict(pele=PELE_CLARA, cabelo='rebelde', cabelo_cores=CAB_OLYMPIA, olhos='abencoado',
                sorriso_torto=True, cora_facil=True)
OPHELIA = dict(pele=PELE_CARAMELO, cabelo_cores=CAB_ESCURO, olhos='abencoado', cilios=True,
               boca_linha='#6A2E26', labio='#A85A4E')
ALTHEA = dict(pele=PELE_CLARA, cabelo_cores=CAB_OLYMPIA, olhos=AZUL_ALTHEA, cilios=True, bochecha='#F4BCB2')

ELENCO = {
    # id: {idade ('' = uma só): configuração}
    'nicholas': {
        '11': dict(NICHOLAS, geometria='crianca',
                   roupa=dict(estilo='colete', base='#1E2A4A', sombra='#141C34', luz='#2B3D55')),
        '17': dict(NICHOLAS, geometria='adulto', anel_avanca=True,
                   roupa=dict(estilo='tunica', base='#2B3D55', sombra='#13253C', luz='#3E5A7A')),
    },
    'althea': {
        '6': dict(ALTHEA, geometria='pequena', cabelo='ombros',
                  roupa=dict(estilo='vestido', base='#7FA2C8', sombra='#55779E', luz='#A9C4E0', gola='#F2EEE6')),
        '11': dict(ALTHEA, geometria='crianca', cabelo='trancinhas', bochecha=None,
                   roupa=dict(estilo='vestido', base='#86A8CE', sombra='#5E86B4', luz='#A9C4E0', gola='#ECBD75')),
    },
    'ophelia': {
        '11': dict(OPHELIA, geometria='crianca', cabelo='ondulado_trancas',
                   roupa=dict(estilo='vestido', base='#8E1F25', sombra='#5E1218', luz='#B8343A')),
        '17': dict(OPHELIA, geometria='adulta', cabelo='cachos_franja',
                   roupa=dict(estilo='imperial', base='#74141C', sombra='#4A0C12', luz='#9E2630', perolas=True)),
    },
    'apollon': {
        '': dict(pele=PELE_OLYMPIA, geometria='adulto', cabelo='penteado', cabelo_cores=CAB_APOLLON,
                 olhos=('#DCEAF4', '#9FB4C8'), ruga=True,
                 roupa=dict(estilo='casaco', base='#13253C', sombra='#0A1626', luz='#2B3D55')),
    },
    # Guarda imperial do Capítulo 01 (falante "Guarda"). DO LIVRO (V2 c31):
    # "uniforme dourado e vermelho" e o colar dourado do uniforme. INFERÊNCIA,
    # como na folha da exploração: cabelo escuro curto, sem elmo, adulto.
    'guarda': {
        '': dict(pele=PELE_MADURA, geometria='adulto', cabelo='penteado', cabelo_cores=CAB_ESCURO,
                 olhos=CASTANHO,
                 roupa=dict(estilo='uniforme', base='#A8232B', sombra='#6E1219', luz='#C83A40')),
    },
    # Dono da loja de pelúcias (falante "Lojista" do Capítulo 01). DO LIVRO: só
    # "o homem do casal" de donos. INFERÊNCIA, como na folha da exploração:
    # artesão maduro, cabelo castanho, camisa clara e colete marrom.
    'lojista': {
        '': dict(pele=PELE_MADURA, geometria='adulto', cabelo='penteado', cabelo_cores=CAB_LOJISTA,
                 olhos=CASTANHO, ruga=True,
                 roupa=dict(estilo='colete', base='#6B5A3A', sombra='#4A3E28', luz='#8A7650')),
    },
    'janet': {
        '': dict(pele=PELE_ESCURA, geometria='adulta', cabelo='bandana', cabelo_cores=CAB_JANET,
                 olhos=CASTANHO, cilios=True, boca_linha='#4A2018', labio='#7A3A30',
                 roupa=dict(estilo='colete_janet', base='#3E6A9E', sombra='#2B4C74', luz='#5A86B8')),
    },
    'pany': {
        '': dict(pele=PELE_MADURA, geometria='adulta', cabelo='coque', cabelo_cores=CAB_GRISALHO,
                 olhos=CASTANHO, cilios=True, ruga=True, cor_sobrancelha='#8C8882',
                 roupa=dict(estilo='governanta', base='#3A2F3C', sombra='#261E28', luz='#544458')),
    },
}

BOCAS = 3


def gerar(raiz):
    folhas = []
    for id, idades in ELENCO.items():
        pasta = os.path.join(raiz, id)
        os.makedirs(pasta, exist_ok=True)
        for idade, cfg in idades.items():
            nome = id if not idade else '%s_%s' % (id, idade)
            linha = []
            for emocao in EMOCOES:
                quadros = [retrato(cfg, emocao, i) for i in range(BOCAS)]
                piscando = retrato(cfg, emocao, 0, True)
                base = os.path.join(pasta, '%s_%s' % (nome, emocao))
                quadros[0].save(base + '.png')
                piscando.save(base + '_piscando.png')
                faixa = Image.new('RGBA', (N * BOCAS, N), (0, 0, 0, 0))
                for i, im in enumerate(quadros):
                    faixa.paste(im, (i * N, 0))
                faixa.save(base + '_fala.png')
                linha.append(quadros[0])
            folhas.append((nome, linha))
    return folhas


def previa(folhas, caminho, escala=3):
    rot = 90
    lado = N * escala
    im = Image.new('RGBA', (rot + lado * len(EMOCOES), 24 + lado * len(folhas)), (24, 22, 40, 255))
    d = ImageDraw.Draw(im)
    for j, e in enumerate(EMOCOES):
        d.text((rot + j * lado + 8, 6), e, fill=(240, 220, 150))
    for i, (nome, linha) in enumerate(folhas):
        d.text((8, 24 + i * lado + lado // 2), nome, fill=(240, 220, 150))
        for j, q in enumerate(linha):
            grande = q.resize((lado, lado), Image.NEAREST)
            im.paste(grande, (rot + j * lado, 24 + i * lado), grande)
    im.save(caminho)


if __name__ == '__main__':
    raiz = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'art', 'retratos')
    folhas = gerar(raiz)
    if len(sys.argv) > 1:
        previa(folhas, sys.argv[1])
    print(len(folhas), 'idades,', len(folhas) * len(EMOCOES), 'retratos')
