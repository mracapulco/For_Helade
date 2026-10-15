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
    # Nicholas adolescente, entre o menino de colete e o adulto da capa. O
    # livro ainda não chegou a essa idade: roupa e altura são inferência,
    # provisórias. Túnica azul de Olympia até o meio das coxas, mangas
    # cinza-claras, cinto de couro com fivela dourada, calça escura e botas.
    'nicholas_adolescente': dict(
        topo=10, tronco=11, largura=4, cabelo='rebelde', roupa='colete', aba=3,
        enfeites=('cinto',),
        cores=dict(
            cab_luz='#F6EED2', cab='#E3D5AE', cab_sombra='#B9A882', cab_fundo='#8C7C5C',
            camisa_luz='#E4E7EC', camisa='#C9CED8', camisa_sombra='#9AA3B3',
            manga='#C9CED8', manga_sombra='#9AA3B3',
            colete='#3E5A7A', colete_sombra='#2B3D55',
            cinto='#4A3428',
            calca='#23262F', calca_sombra='#15171C',
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
    # Althea adolescente e adulta: a mesma Althea crescida (o loiro-pálido
    # curto e rebelde e os olhos azuis da mãe), cada fase com outra roupa, a
    # pedido do Rafael (15/10). O livro ainda não mostrou essas idades: roupas
    # e alturas são inferência, provisórias. Ela é 5 anos mais nova que
    # Nicholas; adulta, fica um pouco mais baixa que ele e Ophelia.
    # Adolescente: vestido longo azul com mangas claras e gola dourada.
    'althea_adolescente': dict(
        topo=13, tronco=10, largura=3, cabelo='ombros', roupa='vestido_longo', saia_passo=4,
        olho='#3F7CC4', bochecha='#D98C84', enfeites=('gola',),
        cores=dict(
            cab_luz='#F6EED2', cab='#E3D5AE', cab_sombra='#B9A882', cab_fundo='#8C7C5C',
            vestido_luz='#86A8CE', vestido='#5E86B4', vestido_sombra='#3E5F88',
            manga='#E4ECF4', manga_sombra='#B7C4D4',
            calca='#3E5F88', calca_sombra='#2B3D55',
        ),
    ),
    # Adulta: vestido azul-escuro de Olympia, faixa e barra douradas.
    'althea_adulta': dict(
        topo=8, tronco=11, largura=4, cabelo='ombros', roupa='vestido_longo', saia_passo=5,
        olho='#3F7CC4', enfeites=('faixa', 'barra'),
        cores=dict(
            cab_luz='#F6EED2', cab='#E3D5AE', cab_sombra='#B9A882', cab_fundo='#8C7C5C',
            vestido_luz='#3E5A7A', vestido='#2B3D55', vestido_sombra='#13253C',
            calca='#13253C', calca_sombra='#0B1726',
        ),
    ),
    # Ophelia aos 11: pele escura "tal qual caramelo"; vestido simples rubro,
    # a cor do Império; cabelo longo ondulado passando da cintura, com duas
    # tranças que saem das têmporas e se encontram atrás da cabeça; olhos
    # azul-pálidos. Cabelo escuro: inferência pela garota da visão; no palácio
    # o livro não diz a cor. O livro diz que ela é mais alta que Nicholas, mas
    # Rafael pediu (15/10) os dois da mesma altura em cada idade.
    'ophelia_11': dict(
        topo=17, tronco=9, largura=4, cabelo='longo', roupa='vestido_longo',
        pele=dict(pele_luz='#C48A5E', pele='#A06A44', pele_sombra='#76482C'),
        cores=dict(
            cab_luz='#5C4234', cab='#3A2820', cab_sombra='#24170F', cab_fundo='#170E09',
            vestido_luz='#B8343A', vestido='#8E1F25', vestido_sombra='#5E1218',
            calca='#5E1218', calca_sombra='#3E0B10',
        ),
    ),
    # Ophelia adolescente e adulta: a mesma Ophelia crescida (cabelo, tranças
    # e o rubro do Império), cada fase com outra roupa, a pedido do Rafael
    # (15/10). O livro ainda não mostrou como ela é nessas idades: roupas e
    # alturas são inferência, provisórias. A adolescente tem a altura do
    # Nicholas adolescente; a adulta, a do Nicholas adulto (gerar_nicholas.py).
    # Adolescente: vestido rubro com mangas claras e faixa dourada na cintura.
    'ophelia_adolescente': dict(
        topo=10, tronco=11, largura=4, cabelo='longo', roupa='vestido_longo', saia_passo=4,
        enfeites=('faixa',),
        pele=dict(pele_luz='#C48A5E', pele='#A06A44', pele_sombra='#76482C'),
        cores=dict(
            cab_luz='#5C4234', cab='#3A2820', cab_sombra='#24170F', cab_fundo='#170E09',
            vestido_luz='#B8343A', vestido='#8E1F25', vestido_sombra='#5E1218',
            manga='#EDE3D2', manga_sombra='#C9B79C',
            calca='#5E1218', calca_sombra='#3E0B10',
        ),
    ),
    # Adulta: vestido de corte imperial, rubro mais escuro, gola e barra
    # bordadas de ouro e um manto claro preso nos ombros.
    'ophelia_adulta': dict(
        topo=4, tronco=12, largura=4, cabelo='longo', roupa='vestido_longo', saia_passo=5,
        enfeites=('gola', 'barra'),
        pele=dict(pele_luz='#C48A5E', pele='#A06A44', pele_sombra='#76482C'),
        cores=dict(
            cab_luz='#5C4234', cab='#3A2820', cab_sombra='#24170F', cab_fundo='#170E09',
            vestido_luz='#9E2630', vestido='#74141C', vestido_sombra='#4A0C12',
            capa='#E8E1D4', capa_sombra='#B8AE9C',
            calca='#4A0C12', calca_sombra='#2E070B',
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


def braco(q, x, y, swing, comprimento, cor, cor_sombra=None):
    yy = y + swing
    q.r(x, yy, x + 1, yy + comprimento, cor)
    if cor_sombra:
        q.r(x, yy, x, yy + comprimento, cor_sombra)
    q.r(x, yy + comprimento + 1, x + 1, yy + comprimento + 1, 'pele')


def braco_estendido(q, x, y, alcance, cor):
    q.r(x, y, x + alcance, y + 1, cor)
    q.r(x + alcance + 1, y, x + alcance + 2, y + 1, 'pele')


def cor_braco(cfg):
    # mangas de outra cor (cores 'manga' e 'manga_sombra') ou da própria roupa
    if 'manga' in cfg['cores']:
        return 'manga'
    return 'camisa' if cfg['roupa'] == 'colete' else 'vestido'


def corpo_frente(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance, saia_voa):
    roupa = cfg['roupa']
    comp = quadril - yt - 1
    cor_manga = cor_braco(cfg)
    aba = cfg.get('aba', 0)          # túnica que desce por cima das coxas
    if roupa == 'colete':
        braco(q, x - larg - 2, yt + 1, b_esq, comp, cor_manga, cor_manga + '_sombra')
        q.r(x - larg, yt, x + larg, quadril + aba, 'colete')
        q.r(x - larg, yt, x - larg + 1, quadril + aba, 'colete_sombra')
        q.r(x, yt, x, quadril - 1, 'camisa')                       # camisa na abertura
        q.r(x - 1, yt, x + 1, yt, 'camisa_luz')                    # gola
        if aba:
            q.r(x, quadril, x, quadril + aba, 'colete_sombra')     # abertura da túnica
        else:
            q.r(x - larg, quadril, x + larg, quadril, 'calca')
        for yy in (yt + 3, yt + 6):
            q.p(x + 1, yy, 'camisa_sombra')                        # botões simples
        if alcance:
            braco_estendido(q, x + larg + 1, yt + 2, alcance, cor_manga)
        else:
            braco(q, x + larg + 1, yt + 1, b_dir, comp, cor_manga)
    else:
        hem = PE - (3 if roupa == 'vestido_longo' else 5)
        braco(q, x - larg - 2, yt + 1, b_esq, comp, cor_manga, cor_manga + '_sombra')
        q.r(x - larg, yt, x + larg, quadril, 'vestido')
        # saia em A até a barra (abre 1 pixel a cada saia_passo linhas)
        for i, yy in enumerate(range(quadril, hem + 1)):
            a = larg + 1 + i // cfg.get('saia_passo', 3)
            q.r(x - a - saia_voa, yy, x + a, yy, 'vestido')
            q.p(x - a - saia_voa, yy, 'vestido_sombra')
        q.r(x - larg, yt, x - larg, quadril, 'vestido_sombra')
        q.r(x + 1, yt + 1, x + 2, yt + 3, 'vestido_luz')
        q.r(x - 1, yt, x + 1, yt, 'pele')                          # decote
        if alcance:
            braco_estendido(q, x + larg + 1, yt + 2, alcance, cor_manga)
        else:
            braco(q, x + larg + 1, yt + 1, b_dir, comp, cor_manga)


def corpo_costas(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance, saia_voa):
    roupa = cfg['roupa']
    comp = quadril - yt - 1
    cor_manga = cor_braco(cfg)
    aba = cfg.get('aba', 0)
    if alcance:
        braco_estendido(q, x + larg + 1, yt + 2, alcance, cor_manga)
    else:
        braco(q, x + larg + 1, yt + 1, b_dir, comp, cor_manga)
    if roupa == 'colete':
        q.r(x - larg, yt, x + larg, quadril + aba, 'colete')
        q.r(x - larg, yt, x - larg + 1, quadril + aba, 'colete_sombra')
        q.r(x - 1, yt + 2, x + 1, yt + 2, 'colete_sombra')        # costura das costas
        if not aba:
            q.r(x - larg, quadril, x + larg, quadril, 'calca')
        braco(q, x - larg - 2, yt + 1, b_esq, comp, cor_manga, cor_manga + '_sombra')
    else:
        hem = PE - (3 if roupa == 'vestido_longo' else 5)
        q.r(x - larg, yt, x + larg, quadril, 'vestido')
        for i, yy in enumerate(range(quadril, hem + 1)):
            a = larg + 1 + i // cfg.get('saia_passo', 3)
            q.r(x - a - saia_voa, yy, x + a, yy, 'vestido')
            q.p(x - a - saia_voa, yy, 'vestido_sombra')
        q.r(x - larg, yt, x - larg, quadril, 'vestido_sombra')
        q.r(x, yt + 1, x, quadril - 1, 'vestido_sombra')          # laço/costura
        braco(q, x - larg - 2, yt + 1, b_esq, comp, cor_manga, cor_manga + '_sombra')


def braco_costas(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance):
    cor = cor_braco(cfg)
    comp = quadril - yt - 1
    if alcance:
        braco_estendido(q, x + larg + 1, yt + 2, alcance, cor)
    else:
        braco(q, x + larg + 1, yt + 1, b_dir, comp, cor)
    braco(q, x - larg - 2, yt + 1, b_esq, comp, cor, cor + '_sombra')


def capa(q, cfg, dir, x, yt, quadril, larg):
    # manto curto preso nos ombros: atrás do corpo de frente, por cima de costas
    if 'capa' not in cfg['cores']:
        return
    fim = quadril + cfg.get('capa_desce', 4)
    if dir == 'frente':
        q.r(x - larg - 3, yt + 1, x + larg + 3, fim, 'capa')
        q.r(x - larg - 3, yt + 1, x - larg - 3, fim, 'capa_sombra')
    else:
        q.r(x - larg - 2, yt, x + larg + 2, fim, 'capa')
        q.r(x - larg - 2, yt, x - larg - 2, fim, 'capa_sombra')
        for xx in (x - 2, x + 2):
            q.r(xx, yt + 3, xx, fim, 'capa_sombra')                # dobras
        q.r(x - larg - 2, fim, x + larg + 2, fim, 'ouro')          # barra do manto


def ombros_da_capa(q, cfg, x, yt, larg):
    # de frente, o manto aparece sobre os ombros, preso por um broche dourado
    if 'capa' not in cfg['cores']:
        return
    q.r(x - larg - 2, yt, x + larg + 2, yt + 1, 'capa')
    q.r(x - larg - 2, yt + 1, x + larg + 2, yt + 1, 'capa_sombra')
    q.r(x - larg - 2, yt + 2, x - larg - 2, yt + 3, 'capa_sombra')
    q.p(x, yt + 1, 'ouro_luz')


def enfeites(q, cfg, dir, x, yt, quadril, larg, saia_voa):
    e = cfg.get('enfeites', ())
    if 'cinto' in e:      # cinto de couro com fivela dourada
        q.r(x - larg, quadril, x + larg, quadril, 'cinto')
        if dir == 'frente':
            q.p(x, quadril, 'ouro_luz')
    if 'faixa' in e:      # faixa dourada na cintura, com a ponta caindo
        q.r(x - larg, quadril - 1, x + larg, quadril - 1, 'ouro')
        q.r(x + larg - 1, quadril, x + larg - 1, quadril + 3, 'ouro_sombra')
    if 'gola' in e:       # gola bordada de ouro
        q.r(x - 2, yt, x + 2, yt, 'ouro')
        if dir == 'frente':
            q.p(x, yt + 1, 'ouro_luz')
    if 'barra' in e and cfg['roupa'].startswith('vestido'):   # barra bordada
        hem = PE - (3 if cfg['roupa'] == 'vestido_longo' else 5)
        a = larg + 1 + (hem - quadril) // cfg.get('saia_passo', 3)
        q.r(x - a - saia_voa, hem - 1, x + a, hem - 1, 'ouro')


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
    q = Q(cores)
    x = CX + inclina
    yc = cfg['topo'] + dy           # topo da cabeça
    yt = yc + 10                    # topo do tronco
    quadril = yt + cfg['tronco']
    larg = cfg['largura']
    estilo = cfg['cabelo']
    ate = quadril + 3               # o cabelo longo passa da cintura
    if dir == 'frente':
        capa(q, cfg, dir, x, yt, quadril, larg)
        cabelo_atras_frente(q, estilo, x, yc, ate, voa)
        pernas(q, CX, quadril, f_esq, f_dir, lift_esq, lift_dir)
        corpo_frente(q, cfg, x, yt, quadril, larg, braco_esq, braco_dir, alcance, voa // 2)
        enfeites(q, cfg, dir, x, yt, quadril, larg, voa // 2)
        ombros_da_capa(q, cfg, x, yt, larg)
        cabeca_frente(q, dir, x, yc, olho, bochecha)
        cabelo_frente(q, estilo, x, yc)
    else:
        pernas(q, CX, quadril, f_esq, f_dir, lift_esq, lift_dir)
        corpo_costas(q, cfg, x, yt, quadril, larg, braco_esq, braco_dir, alcance, voa // 2)
        enfeites(q, cfg, dir, x, yt, quadril, larg, voa // 2)
        capa(q, cfg, dir, x, yt, quadril, larg)
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


def sprite_frames(id, linhas):
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
