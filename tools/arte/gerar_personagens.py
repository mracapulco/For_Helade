# Gera as folhas de animação dos personagens da Parte I do livro (pixel art).
# Mesma grade do Nicholas adulto: quadros de 32×48, pés na linha 45, frente
# (olhando para baixo e para a direita) e costas (para cima e para a direita);
# para a esquerda o jogo espelha.
# Uso: python3 tools/arte/gerar_personagens.py
# Grava, para cada personagem, assets/art/personagens/<id>/<id>_exploracao.png
# e o SpriteFrames <id>_exploracao.tres ao lado. Rodar de novo recria tudo.
#
# Aparência tirada do Capítulo 01 ("A garota do corredor"). O que o livro não
# diz e foi inferido está marcado com "inferência" nos comentários.
import os
from PIL import Image

H = lambda h: tuple(int(h[i:i+2], 16) for i in (1, 3, 5)) + (255,)
W, HH = 32, 48
CX = 16
PE = 45

# Cores comuns (paleta da capa e tons derivados).
BASE = dict(
    contorno='#050C14',
    pele_luz='#E6C6B4', pele='#C8A08E', pele_sombra='#9E7468',
    olho='#C9D6E4', olho_escuro='#2B3D55',
    sapato='#4A3428', sapato_sombra='#2E2019',
    ouro_luz='#ECBD75', ouro='#B98543', ouro_sombra='#8A5E2C',
)

PERSONAGENS = {
    # Nicholas aos 11: "pequeno para a idade", cabelo loiro-pálido rebelde,
    # olhos quase brancos dos Olympia, camisa branca e colete azul escuro
    # simples, "parecidas com as usadas pelos filhos dos comerciantes".
    'nicholas_11': dict(
        topo=17, tronco=9, largura=4, cabelo='rebelde', roupa='colete',
        cores=dict(
            cab_luz='#F6EED2', cab='#E3D5AE', cab_sombra='#B9A882', cab_fundo='#8C7C5C',
            camisa_luz='#F2EFE8', camisa='#D9D4CA', camisa_sombra='#A9A398',
            colete='#2B3D55', colete_sombra='#13253C',
            calca='#3A3F4C', calca_sombra='#23262F',
        ),
    ),
    # Nicholas aos 11 de pijama, ao acordar (o jogo troca pela camisa e o
    # colete no espelho). O livro não descreve o pijama: inferência, uma
    # camisa de dormir azul-clara, calça clara e pés descalços.
    'nicholas_11_pijama': dict(
        topo=17, tronco=9, largura=4, cabelo='rebelde', roupa='colete',
        cores=dict(
            cab_luz='#F6EED2', cab='#E3D5AE', cab_sombra='#B9A882', cab_fundo='#8C7C5C',
            camisa_luz='#E4ECF4', camisa='#C9D6E4', camisa_sombra='#9FB8D2',
            colete='#C9D6E4', colete_sombra='#9FB8D2',
            calca='#B7C4D4', calca_sombra='#8A9AAE',
            sapato='#C8A08E', sapato_sombra='#9E7468',
        ),
    ),
    # Apollon, duque de Olympia e Conselheiro Imperial (Capítulo 01). O livro
    # não o descreve: o loiro-pálido dos Olympia, o colete azul escuro da
    # casa e um casaco longo de duque com botões dourados são inferência,
    # provisórios até a autora dizer como ele é.
    'apollon': dict(
        topo=4, tronco=13, largura=5, cabelo='rebelde', roupa='colete',
        cores=dict(
            cab_luz='#ECE4CC', cab='#D6CBA8', cab_sombra='#ADA07E', cab_fundo='#857857',
            camisa_luz='#F2EFE8', camisa='#13253C', camisa_sombra='#0A1626',
            colete='#2B3D55', colete_sombra='#13253C',
            calca='#23262F', calca_sombra='#15171C',
        ),
    ),
    # Althea aos 6: o mesmo loiro-pálido, curto até os ombros, "indomável";
    # bochechas rosadas; olhos azuis saturados, como os da mãe (não os
    # desbotados dos Olympia). Vestido azul simples: inferência a partir do
    # vestido que ela ganha de presente; o livro não diz o que ela veste.
    'althea_6': dict(
        topo=20, tronco=6, largura=3, cabelo='ombros', roupa='vestido_curto',
        olho='#3F7CC4', bochecha='#D98C84',
        cores=dict(
            cab_luz='#F6EED2', cab='#E3D5AE', cab_sombra='#B9A882', cab_fundo='#8C7C5C',
            vestido_luz='#A9C4E0', vestido='#7FA2C8', vestido_sombra='#55779E',
            calca='#D9D4CA', calca_sombra='#A9A398',   # meias claras
        ),
    ),
    # Ophelia aos 11: mais alta que Nicholas; pele escura "tal qual caramelo";
    # vestido simples rubro, a cor do Império; cabelo longo ondulado passando
    # da cintura, com duas tranças que saem das têmporas e se encontram atrás
    # da cabeça; olhos azul-pálidos. Cabelo escuro: inferência pela garota da
    # visão; no palácio o livro não diz a cor.
    'ophelia_11': dict(
        topo=12, tronco=10, largura=4, cabelo='longo', roupa='vestido_longo',
        pele=dict(pele_luz='#C48A5E', pele='#A06A44', pele_sombra='#76482C'),
        cores=dict(
            cab_luz='#5C4234', cab='#3A2820', cab_sombra='#24170F', cab_fundo='#170E09',
            vestido_luz='#B8343A', vestido='#8E1F25', vestido_sombra='#5E1218',
            calca='#5E1218', calca_sombra='#3E0B10',
        ),
    ),
}


class Q:
    def __init__(s, cores):
        s.im = Image.new('RGBA', (W, HH), (0, 0, 0, 0))
        s.px = s.im.load()
        s.c = {k: H(v) for k, v in cores.items()}

    def p(s, x, y, c):
        if 0 <= x < W and 0 <= y < HH:
            s.px[x, y] = s.c[c]

    def r(s, x0, y0, x1, y1, c):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                s.p(x, y, c)

    def contornar(s):
        cheios = {(x, y) for x in range(W) for y in range(HH) if s.px[x, y][3]}
        for (x, y) in list(cheios):
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n not in cheios and 0 <= n[0] < W and 0 <= n[1] < HH:
                    s.px[n] = s.c['contorno']
        return s.im


# --- partes -----------------------------------------------------------------

def pernas(q, x, quadril, f_esq, f_dir, lift_esq, lift_dir):
    for (xx, f, lift) in ((x - 3, f_esq, lift_esq), (x + 1, f_dir, lift_dir)):
        xx += f
        pe = PE - lift
        q.r(xx, quadril, xx + 1, pe - 2, 'calca')
        q.r(xx, quadril, xx, pe - 2, 'calca_sombra')
        q.r(xx, pe - 1, xx + 2, pe, 'sapato')
        q.r(xx, pe, xx + 2, pe, 'sapato_sombra')


def cabeca_frente(q, d, x, y, olho, bochecha):
    # rosto de 9×7 com olhos grandes (proporção de criança)
    q.r(x - 4, y + 3, x + 4, y + 9, 'pele')
    q.r(x - 4, y + 3, x - 4, y + 9, 'pele_sombra')
    q.r(x - 3, y + 9, x + 3, y + 9, 'pele_sombra')
    q.r(x + 2, y + 4, x + 3, y + 5, 'pele_luz')
    for ox in (-2, 2):
        q.p(x + ox, y + 6, 'olho_escuro')
        q.p(x + ox, y + 7, olho)
    if bochecha:
        q.p(x - 3, y + 8, bochecha); q.p(x + 3, y + 8, bochecha)
    q.p(x + 1, y + 8, 'pele_sombra')          # nariz
    q.p(x - 5, y + 6, 'pele')                  # orelha


def cabelo_frente(q, estilo, x, y):
    if estilo == 'rebelde':
        q.r(x - 5, y, x + 5, y + 3, 'cab')
        q.r(x - 4, y - 1, x + 4, y - 1, 'cab')
        q.r(x - 5, y + 3, x - 5, y + 6, 'cab_sombra')
        q.r(x + 5, y + 3, x + 5, y + 5, 'cab_sombra')
        # mechas rebeldes espetadas no topo e caindo na testa
        for (dx, dy) in [(-3, -2), (1, -2), (4, -1), (-6, 2), (6, 1)]:
            q.p(x + dx, y + dy, 'cab')
        for dx, prof in [(-4, 5), (-3, 4), (-1, 5), (0, 4), (2, 5), (3, 4), (4, 5)]:
            q.r(x + dx, y + 4, x + dx, y + prof, 'cab' if dx % 2 else 'cab_sombra')
        for (dx, dy) in [(-3, 0), (-2, 1), (0, 0), (1, 1), (3, 1), (-4, 2)]:
            q.p(x + dx, y + dy, 'cab_luz')
    elif estilo == 'ombros':
        q.r(x - 5, y, x + 5, y + 3, 'cab')
        q.r(x - 4, y - 1, x + 4, y - 1, 'cab')
        # laterais até os ombros, pontas para fora
        q.r(x - 6, y + 2, x - 5, y + 10, 'cab')
        q.r(x + 5, y + 2, x + 6, y + 10, 'cab')
        q.r(x - 6, y + 6, x - 6, y + 10, 'cab_sombra')
        q.r(x + 6, y + 7, x + 6, y + 10, 'cab_sombra')
        q.p(x - 7, y + 10, 'cab'); q.p(x + 7, y + 10, 'cab')
        q.p(x - 2, y - 2, 'cab'); q.p(x + 3, y - 2, 'cab')       # fios soltos
        for dx, prof in [(-4, 5), (-3, 4), (-2, 5), (0, 4), (1, 5), (3, 4), (4, 4)]:
            q.r(x + dx, y + 4, x + dx, y + prof, 'cab' if dx % 2 else 'cab_sombra')
        for (dx, dy) in [(-3, 0), (-1, 1), (1, 0), (2, 1), (-5, 4), (5, 5)]:
            q.p(x + dx, y + dy, 'cab_luz')
    elif estilo == 'longo':
        q.r(x - 5, y, x + 5, y + 3, 'cab')
        q.r(x - 4, y - 1, x + 4, y - 1, 'cab')
        # risca ao meio e o cabelo emoldurando o rosto
        q.r(x - 6, y + 2, x - 5, y + 10, 'cab')
        q.r(x + 5, y + 2, x + 6, y + 9, 'cab')
        q.r(x - 4, y + 3, x - 3, y + 4, 'cab'); q.r(x + 3, y + 3, x + 4, y + 4, 'cab')
        q.p(x, y, 'cab_sombra'); q.p(x, y + 1, 'cab_sombra')
        # trança que sai da têmpora
        for (dx, dy) in [(-5, 3), (-6, 5), (5, 3), (6, 5)]:
            q.p(x + dx, y + dy, 'cab_luz')
        for (dx, dy) in [(-3, 0), (-2, 1), (2, 0), (3, 1)]:
            q.p(x + dx, y + dy, 'cab_luz')
    elif estilo == 'topete':
        # curto dos lados, volume penteado para cima e para trás; testa à mostra
        q.r(x - 5, y, x + 5, y + 2, 'cab')
        q.r(x - 4, y - 1, x + 5, y - 1, 'cab')
        q.r(x - 2, y - 2, x + 4, y - 2, 'cab')
        q.r(x - 5, y + 3, x - 5, y + 5, 'cab_sombra')   # costeletas
        q.r(x + 5, y + 3, x + 5, y + 4, 'cab_sombra')
        q.r(x - 4, y + 3, x - 3, y + 3, 'cab')
        q.r(x + 3, y + 3, x + 4, y + 3, 'cab')
        q.p(x - 5, y + 2, 'cab_sombra'); q.p(x - 4, y + 2, 'cab_sombra')
        for (dx, dy) in [(-1, -2), (0, -1), (1, -2), (2, -1), (3, 0), (-2, 0), (-3, 1)]:
            q.p(x + dx, y + dy, 'cab_luz')
    elif estilo == 'chanel':
        # liso na altura dos ombros, risca de lado e franja varrida para a direita
        q.r(x - 5, y, x + 5, y + 3, 'cab')
        q.r(x - 4, y - 1, x + 4, y - 1, 'cab')
        q.r(x - 6, y + 2, x - 5, y + 11, 'cab')
        q.r(x + 5, y + 2, x + 6, y + 11, 'cab')
        q.r(x - 5, y + 6, x - 5, y + 11, 'cab_sombra')
        q.r(x + 5, y + 6, x + 5, y + 11, 'cab_sombra')
        q.r(x - 6, y + 11, x - 5, y + 11, 'cab_sombra')
        q.r(x + 5, y + 11, x + 6, y + 11, 'cab_sombra')
        q.r(x - 4, y + 3, x - 2, y + 3, 'cab'); q.p(x - 4, y + 4, 'cab')   # mecha da risca
        q.p(x - 2, y, 'cab_sombra'); q.p(x - 2, y + 1, 'cab_sombra')   # risca
        for (dx, dy) in [(-4, 1), (-3, 2), (0, 0), (1, 1), (2, 1), (3, 2), (-6, 5), (6, 6)]:
            q.p(x + dx, y + dy, 'cab_luz')


def oculos_frente(q, x, y):
    # armação redonda: aro de cima e laterais em volta de cada olho, e a ponte
    for ox in (-2, 2):
        q.r(x + ox - 1, y + 5, x + ox + 1, y + 5, 'oculos')
        q.r(x + ox - 1, y + 6, x + ox - 1, y + 7, 'oculos')
        q.r(x + ox + 1, y + 6, x + ox + 1, y + 7, 'oculos')
    q.p(x, y + 6, 'oculos')


def cabelo_atras_frente(q, estilo, x, y, ate, voa):
    # parte do cabelo que fica atrás do corpo, visto de frente
    if estilo == 'longo':
        q.r(x - 7 - voa, y + 6, x + 6, ate, 'cab_sombra')
        for i, dx in enumerate(range(-7 - voa, 7)):
            if i % 2:
                q.p(x + dx, ate + 1, 'cab_sombra')   # pontas onduladas
        q.r(x - 7 - voa, y + 8, x - 7 - voa, ate, 'cab_fundo')


def cabeca_costas(q, estilo, x, y, ate, voa):
    q.r(x - 5, y, x + 5, y + 8, 'cab')
    q.r(x - 4, y - 1, x + 4, y - 1, 'cab')
    q.r(x - 3, y + 9, x + 3, y + 9, 'pele_sombra')   # nuca
    if estilo == 'rebelde':
        for (dx, dy) in [(-3, -2), (2, -2), (5, 0), (-6, 3)]:
            q.p(x + dx, y + dy, 'cab')
        for (dx, dy) in [(-4, 4), (-1, 6), (3, 5), (1, 3), (-2, 2)]:
            q.p(x + dx, y + dy, 'cab_sombra')
        for (dx, dy) in [(-3, 1), (0, 0), (2, 1), (-1, 3)]:
            q.p(x + dx, y + dy, 'cab_luz')
        q.r(x - 4, y + 8, x + 4, y + 8, 'cab_sombra')
        q.r(x - 3, y + 9, x + 3, y + 9, 'pele_sombra')
    elif estilo == 'ombros':
        q.r(x - 6, y + 2, x + 6, y + 10, 'cab')
        q.r(x - 6, y + 9, x + 6, y + 10, 'cab_sombra')
        for dx in (-6, -3, 1, 4, 7):
            q.p(x + dx, y + 11, 'cab_sombra')
        for (dx, dy) in [(-3, 1), (0, 0), (2, 2), (-1, 4), (4, 5)]:
            q.p(x + dx, y + dy, 'cab_luz')
    elif estilo == 'longo':
        # cabeça cheia; abaixo dos ombros o cabelo cai mais estreito, entre os braços
        q.r(x - 6, y + 2, x + 6, y + 10, 'cab')
        q.r(x - 4 - voa, y + 11, x + 4, ate, 'cab')
        q.r(x - 4 - voa, y + 11, x - 3 - voa, ate, 'cab_sombra')
        for i, dx in enumerate(range(-4 - voa, 5)):
            if i % 2:
                q.p(x + dx, ate + 1, 'cab')            # pontas onduladas
        # ondas: brilhos curtos na diagonal
        for yy in range(y + 12, ate - 1, 4):
            q.p(x - 1, yy, 'cab_luz'); q.p(x, yy + 1, 'cab_luz')
            q.p(x + 2, yy + 2, 'cab_sombra'); q.p(x + 3, yy + 3, 'cab_sombra')
        # as duas tranças das têmporas se encontram atrás da cabeça
        for (dx, dy) in [(-5, 4), (-4, 5), (-3, 6), (-2, 6), (-1, 7), (5, 4), (4, 5), (3, 6), (2, 6), (1, 7)]:
            q.p(x + dx, y + dy, 'cab_luz')
        q.r(x - 1, y + 7, x + 1, y + 8, 'cab_sombra')   # onde as tranças se prendem
        q.p(x, y + 7, 'cab_luz')
    elif estilo == 'topete':
        q.r(x - 4, y - 1, x + 5, y - 1, 'cab')
        q.r(x - 2, y - 2, x + 4, y - 2, 'cab')
        q.r(x - 4, y + 7, x + 4, y + 8, 'cab_sombra')   # nuca raspada
        for (dx, dy) in [(-2, 4), (1, 5), (3, 3)]:
            q.p(x + dx, y + dy, 'cab_sombra')
        for (dx, dy) in [(-1, -2), (1, -1), (3, -2), (-3, 1), (0, 1), (2, 2)]:
            q.p(x + dx, y + dy, 'cab_luz')
    elif estilo == 'chanel':
        q.r(x - 6, y + 2, x + 6, y + 9, 'cab')
        q.r(x - 5, y + 10, x + 5, y + 10, 'cab')
        q.r(x - 5, y + 11, x + 5, y + 11, 'cab_sombra')        # pontas retas
        q.r(x - 6, y + 6, x - 6, y + 9, 'cab_sombra')
        q.p(x + 2, y, 'cab_sombra'); q.p(x + 2, y + 1, 'cab_sombra')   # risca
        for (dx, dy) in [(-3, 1), (0, 2), (4, 1), (-1, 5), (3, 6), (-4, 8)]:
            q.p(x + dx, y + dy, 'cab_luz')


def braco(q, x, y, swing, comprimento, cor, cor_sombra=None, manga=None):
    # manga: linhas de tecido antes da pele (camiseta); None = manga comprida
    yy = y + swing
    q.r(x, yy, x + 1, yy + comprimento, cor)
    if cor_sombra:
        q.r(x, yy, x, yy + comprimento, cor_sombra)
    if manga is not None:
        q.r(x, yy + manga, x + 1, yy + comprimento, 'pele')
        q.r(x, yy + manga, x, yy + comprimento, 'pele_sombra' if cor_sombra else 'pele')
    q.r(x, yy + comprimento + 1, x + 1, yy + comprimento + 1, 'pele')


def braco_estendido(q, x, y, alcance, cor, manga=None):
    q.r(x, y, x + alcance, y + 1, cor)
    if manga is not None and alcance > 1:
        q.r(x + 2, y, x + alcance, y + 1, 'pele')
    q.r(x + alcance + 1, y, x + alcance + 2, y + 1, 'pele')


# Roupas do nosso mundo (convidados): 'camiseta' (manga curta), 'moletom'
# (manga comprida, capuz caído, cordões e bolso) ou 'escoteiro' (camisa de
# manga curta com bolsos, lenço no pescoço com anel e cinto). Cores:
# <roupa>_luz, <roupa>, <roupa>_sombra; 'cordao' no moletom; 'lenco',
# 'lenco_sombra', 'anel' e 'cinto' no escoteiro. Com cfg['mochila'], alças
# na frente e a mochila nas costas (cores 'alca', 'mochila*').
CASUAIS = ('camiseta', 'moletom', 'escoteiro')


def manga(cfg):
    return 3 if cfg['roupa'] in ('camiseta', 'escoteiro') else None


def casual_frente(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance):
    r = cfg['roupa']
    comp = quadril - yt - 1
    braco(q, x - larg - 2, yt + 1, b_esq, comp, r, r + '_sombra', manga(cfg))
    q.r(x - larg, yt, x + larg, quadril, r)
    q.r(x - larg, yt, x - larg, quadril, r + '_sombra')
    q.r(x + 1, yt + 2, x + 2, yt + 4, r + '_luz')
    if r == 'escoteiro':
        q.r(x - larg, quadril, x + larg, quadril, 'calca')
        q.r(x - larg, quadril - 1, x + larg, quadril - 1, 'cinto')
        q.p(x, quadril - 1, 'anel')                                    # fivela
        for bx in (x - 3, x + 2):                                      # bolsos
            q.r(bx, yt + 3, bx + 1, yt + 4, r + '_sombra')
        # lenço em V em volta do pescoço, preso pelo anel
        q.r(x - 2, yt, x + 2, yt, 'lenco')
        q.p(x - 1, yt + 1, 'lenco'); q.p(x + 1, yt + 1, 'lenco_sombra')
        q.p(x, yt + 1, 'anel')
        q.r(x, yt + 2, x, yt + 4, 'lenco'); q.p(x - 1, yt + 2, 'lenco_sombra')
    elif r == 'camiseta':
        q.r(x - larg, quadril, x + larg, quadril, 'calca')
        q.r(x - 1, yt, x + 1, yt, 'pele'); q.p(x, yt + 1, 'pele')      # gola redonda
        for dx, dy in ((-2, 0), (2, 0), (-1, 1), (1, 1)):
            q.p(x + dx, yt + dy, r + '_sombra')
    else:
        q.r(x - larg, quadril, x + larg, quadril, r + '_sombra')       # barra
        q.r(x - 3, yt, x + 3, yt, r + '_sombra')                       # capuz em volta do pescoço
        q.p(x, yt, 'pele')
        q.r(x - 1, yt + 1, x - 1, yt + 3, 'cordao'); q.r(x + 1, yt + 1, x + 1, yt + 2, 'cordao')
        q.r(x - larg + 1, quadril - 4, x + larg - 1, quadril - 4, r + '_sombra')   # bolso
        q.r(x - larg + 1, quadril - 3, x - larg + 1, quadril - 1, r + '_sombra')
        q.r(x + larg - 1, quadril - 3, x + larg - 1, quadril - 1, r + '_sombra')
    if cfg.get('mochila'):
        q.r(x - larg + 1, yt, x - larg + 1, quadril - 2, 'alca')
        q.r(x + larg - 1, yt, x + larg - 1, quadril - 2, 'alca')
        q.r(x - larg + 1, quadril - 2, x + larg - 1, quadril - 2, 'alca_sombra')   # alça da cintura
        q.p(x - larg, yt - 1, 'mochila'); q.p(x + larg, yt - 1, 'mochila')       # mochila aparece nos ombros
    if alcance:
        braco_estendido(q, x + larg + 1, yt + 2, alcance, r, manga(cfg))
    else:
        braco(q, x + larg + 1, yt + 1, b_dir, comp, r, None, manga(cfg))


def casual_costas(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance):
    r = cfg['roupa']
    comp = quadril - yt - 1
    if alcance:
        braco_estendido(q, x + larg + 1, yt + 2, alcance, r, manga(cfg))
    else:
        braco(q, x + larg + 1, yt + 1, b_dir, comp, r, None, manga(cfg))
    q.r(x - larg, yt, x + larg, quadril, r)
    q.r(x - larg, yt, x - larg, quadril, r + '_sombra')
    if r in ('camiseta', 'escoteiro'):
        q.r(x - larg, quadril, x + larg, quadril, 'calca')
        if r == 'escoteiro':
            q.r(x - larg, quadril - 1, x + larg, quadril - 1, 'cinto')
    else:
        q.r(x - larg, quadril, x + larg, quadril, r + '_sombra')
        q.r(x - 3, yt, x + 3, yt + 3, r + '_sombra')                    # capuz caído
        q.r(x - 2, yt, x + 2, yt, r + '_luz')
    if cfg.get('mochila'):
        q.r(x - larg + 1, yt, x + larg - 1, quadril - 2, 'mochila')
        q.r(x - larg + 1, yt, x - larg + 1, quadril - 2, 'mochila_sombra')
        q.r(x - larg + 2, yt, x + larg - 2, yt, 'mochila_luz')
        q.r(x - larg + 2, yt + 6, x + larg - 2, yt + 6, 'mochila_sombra')   # bolso da frente
        q.r(x - larg + 2, yt + 7, x + larg - 2, quadril - 3, 'mochila_luz')
        q.r(x - larg + 2, quadril - 3, x + larg - 2, quadril - 3, 'mochila_sombra')
        q.p(x + 1, yt + 2, 'alca'); q.p(x + 1, yt + 7, 'alca')            # puxadores
    if r == 'escoteiro':   # a ponta do lenço cai nas costas
        q.r(x - 3, yt, x + 3, yt, 'lenco')
        q.r(x - 2, yt + 1, x + 2, yt + 1, 'lenco')
        q.r(x - 1, yt + 2, x + 1, yt + 2, 'lenco_sombra')
        q.p(x, yt + 3, 'lenco_sombra')
    braco(q, x - larg - 2, yt + 1, b_esq, comp, r, r + '_sombra', manga(cfg))


def corpo_frente(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance, saia_voa):
    roupa = cfg['roupa']
    comp = quadril - yt - 1
    if roupa in CASUAIS:
        casual_frente(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance)
    elif roupa == 'colete':
        braco(q, x - larg - 2, yt + 1, b_esq, comp, 'camisa', 'camisa_sombra')
        q.r(x - larg, yt, x + larg, quadril, 'colete')
        q.r(x - larg, yt, x - larg + 1, quadril, 'colete_sombra')
        q.r(x, yt, x, quadril - 1, 'camisa')                       # camisa na abertura
        q.r(x - 1, yt, x + 1, yt, 'camisa_luz')                    # gola
        q.r(x - larg, quadril, x + larg, quadril, 'calca')
        for yy in (yt + 3, yt + 6):
            q.p(x + 1, yy, 'camisa_sombra')                        # botões simples
        if alcance:
            braco_estendido(q, x + larg + 1, yt + 2, alcance, 'camisa')
        else:
            braco(q, x + larg + 1, yt + 1, b_dir, comp, 'camisa')
    else:
        hem = PE - (3 if roupa == 'vestido_longo' else 5)
        braco(q, x - larg - 2, yt + 1, b_esq, comp, 'vestido', 'vestido_sombra')
        q.r(x - larg, yt, x + larg, quadril, 'vestido')
        # saia em A até a barra
        for i, yy in enumerate(range(quadril, hem + 1)):
            a = larg + 1 + i // 3
            q.r(x - a - saia_voa, yy, x + a, yy, 'vestido')
            q.p(x - a - saia_voa, yy, 'vestido_sombra')
        q.r(x - larg, yt, x - larg, quadril, 'vestido_sombra')
        q.r(x + 1, yt + 1, x + 2, yt + 3, 'vestido_luz')
        q.r(x - 1, yt, x + 1, yt, 'pele')                          # decote
        if alcance:
            braco_estendido(q, x + larg + 1, yt + 2, alcance, 'vestido')
        else:
            braco(q, x + larg + 1, yt + 1, b_dir, comp, 'vestido')


def corpo_costas(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance, saia_voa):
    roupa = cfg['roupa']
    comp = quadril - yt - 1
    if roupa in CASUAIS:
        casual_costas(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance)
        return
    if alcance:
        braco_estendido(q, x + larg + 1, yt + 2, alcance, 'camisa' if roupa == 'colete' else 'vestido')
    else:
        braco(q, x + larg + 1, yt + 1, b_dir, comp, 'camisa' if roupa == 'colete' else 'vestido')
    if roupa == 'colete':
        q.r(x - larg, yt, x + larg, quadril, 'colete')
        q.r(x - larg, yt, x - larg + 1, quadril, 'colete_sombra')
        q.r(x - 1, yt + 2, x + 1, yt + 2, 'colete_sombra')        # costura das costas
        q.r(x - larg, quadril, x + larg, quadril, 'calca')
        braco(q, x - larg - 2, yt + 1, b_esq, comp, 'camisa', 'camisa_sombra')
    else:
        hem = PE - (3 if roupa == 'vestido_longo' else 5)
        q.r(x - larg, yt, x + larg, quadril, 'vestido')
        for i, yy in enumerate(range(quadril, hem + 1)):
            a = larg + 1 + i // 3
            q.r(x - a - saia_voa, yy, x + a, yy, 'vestido')
            q.p(x - a - saia_voa, yy, 'vestido_sombra')
        q.r(x - larg, yt, x - larg, quadril, 'vestido_sombra')
        q.r(x, yt + 1, x, quadril - 1, 'vestido_sombra')          # laço/costura
        braco(q, x - larg - 2, yt + 1, b_esq, comp, 'vestido', 'vestido_sombra')


def braco_costas(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance):
    cor = 'camisa' if cfg['roupa'] == 'colete' else 'vestido'
    comp = quadril - yt - 1
    if alcance:
        braco_estendido(q, x + larg + 1, yt + 2, alcance, cor)
    else:
        braco(q, x + larg + 1, yt + 1, b_dir, comp, cor)
    braco(q, x - larg - 2, yt + 1, b_esq, comp, cor, cor + '_sombra')


def personagem(cfg, dir, f_esq=0, f_dir=0, lift_esq=0, lift_dir=0, dy=0, inclina=0,
               braco_esq=0, braco_dir=0, alcance=0, voa=0):
    cores = dict(BASE)
    cores.update(cfg.get('pele', {}))
    cores.update(cfg['cores'])
    olho = 'olho'
    bochecha = None
    if 'olho' in cfg:
        cores['olho_proprio'] = cfg['olho']; olho = 'olho_proprio'
    if 'bochecha' in cfg:
        cores['bochecha'] = cfg['bochecha']; bochecha = 'bochecha'
    if 'oculos' in cfg:
        cores['oculos'] = cfg['oculos']
    q = Q(cores)
    x = CX + inclina
    yc = cfg['topo'] + dy           # topo da cabeça
    yt = yc + 10                    # topo do tronco
    quadril = yt + cfg['tronco']
    larg = cfg['largura']
    estilo = cfg['cabelo']
    ate = quadril + 3               # o cabelo longo passa da cintura
    if dir == 'frente':
        cabelo_atras_frente(q, estilo, x, yc, ate, voa)
        pernas(q, CX, quadril, f_esq, f_dir, lift_esq, lift_dir)
        corpo_frente(q, cfg, x, yt, quadril, larg, braco_esq, braco_dir, alcance, voa // 2)
        cabeca_frente(q, dir, x, yc, olho, bochecha)
        cabelo_frente(q, estilo, x, yc)
        if 'oculos' in cfg:
            oculos_frente(q, x, yc)
    else:
        pernas(q, CX, quadril, f_esq, f_dir, lift_esq, lift_dir)
        corpo_costas(q, cfg, x, yt, quadril, larg, braco_esq, braco_dir, alcance, voa // 2)
        cabeca_costas(q, estilo, x, yc, ate, voa)
        if estilo == 'longo':   # braços por cima do cabelo comprido
            braco_costas(q, cfg, x, yt, quadril, larg, braco_esq, braco_dir, alcance)
    return q.contornar()


ANIM = {
    'parado':      [dict(), dict(dy=1)],
    'andando':     [dict(f_dir=2, f_esq=-2, dy=1, braco_dir=-1, braco_esq=1),
                    dict(lift_esq=1),
                    dict(f_dir=-2, f_esq=2, dy=1, braco_dir=1, braco_esq=-1),
                    dict(lift_dir=1)],
    'correndo':    [dict(f_dir=3, f_esq=-3, dy=1, inclina=1, braco_dir=-2, braco_esq=2, voa=1),
                    dict(lift_esq=2, inclina=1, dy=-1, voa=2),
                    dict(f_dir=-3, f_esq=3, dy=1, inclina=1, braco_dir=2, braco_esq=-2, voa=1),
                    dict(lift_dir=2, inclina=1, dy=-1, voa=2)],
    'interagindo': [dict(), dict(alcance=2), dict(alcance=4)],
}
ORDEM = ['parado', 'andando', 'correndo', 'interagindo']
VELOCIDADE = {'parado': 2.0, 'andando': 8.0, 'correndo': 12.0, 'interagindo': 10.0}
DIRS = ['frente', 'costas']


def folha(cfg):
    linhas = [(d, a) for d in DIRS for a in ORDEM]
    im = Image.new('RGBA', (W * 4, HH * len(linhas)), (0, 0, 0, 0))
    for linha, (d, a) in enumerate(linhas):
        for i, k in enumerate(ANIM[a]):
            im.paste(personagem(cfg, d, **k), (i * W, linha * HH))
    return im, linhas


def sprite_frames(id, linhas, caminho=None):
    if caminho is None:
        caminho = 'res://assets/art/personagens/%s/%s_exploracao.png' % (id.split('_')[0], id)
    partes = ['[gd_resource type="SpriteFrames" format=3]\n',
              '[ext_resource type="Texture2D" path="%s" id="1_folha"]\n' % caminho]
    animacoes = []
    n = 0
    for linha, (d, a) in enumerate(linhas):
        quadros = []
        for i in range(len(ANIM[a])):
            n += 1
            partes.append('[sub_resource type="AtlasTexture" id="Atlas_%d"]\natlas = ExtResource("1_folha")\n'
                          'region = Rect2(%d, %d, %d, %d)\n' % (n, i * W, linha * HH, W, HH))
            quadros.append('{\n"duration": 1.0,\n"texture": SubResource("Atlas_%d")\n}' % n)
        animacoes.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s_%s",\n"speed": %.1f\n}' % (
            ', '.join(quadros), 'false' if a == 'interagindo' else 'true', a, d, VELOCIDADE[a]))
    partes.append('[resource]\nanimations = [%s]\n' % ', '.join(animacoes))
    return '\n'.join(partes)


if __name__ == '__main__':
    raiz = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'art', 'personagens')
    for id, cfg in PERSONAGENS.items():
        pasta = os.path.join(raiz, id.split('_')[0])
        os.makedirs(pasta, exist_ok=True)
        im, linhas = folha(cfg)
        im.save(os.path.join(pasta, '%s_exploracao.png' % id))
        with open(os.path.join(pasta, '%s_exploracao.tres' % id), 'w') as f:
            f.write(sprite_frames(id, linhas))
        print(id, im.size)
