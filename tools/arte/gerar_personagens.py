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
        # rendicao: as duas mãos para cima ("Nicholas ergueu as mãos, fingindo
        # rendição", no quarto da Althea).
        # bracos_cruzados: na porta da Althea ("Nicholas cruzou os braços e
        # esperou").
        topo=17, tronco=9, largura=4, cabelo='rebelde', roupa='colete', golpe=True, rendicao=True,
        bracos_cruzados=True,
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
        topo=10, tronco=11, largura=4, cabelo='rebelde', roupa='colete', aba=3, golpe=True,
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
    # Golpe com a espada de madeira do aniversário, "esculpida para o tamanho
    # de suas mãos": a espada vem desenhada na mão nos quadros do golpe (ela
    # não usa o Inventario, como a arma do Nicholas).
    'althea_6': dict(
        topo=20, tronco=6, largura=3, cabelo='ombros', roupa='vestido_curto',
        olho='#3F7CC4', bochecha='#D98C84', golpe=True, espada_madeira=True,
        # abraca_espada: à mesa, com o duque, a espada no colo (as duas mãos
        # no cabo, a lâmina deitada) e, no "P-parem de brigar...", o punho
        # apertado contra o peito.
        abraca_espada=True,
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
    # --- Rodada 1 do Capítulo 01 (19/10/2026): elenco de apoio ----------------
    # O livro quase não descreve esses personagens. Em cada entrada, o que vem
    # do texto/das fichas está dito; todo o resto é INFERÊNCIA provisória,
    # marcada como tal, até o Rafael ou a Shara confirmarem.
    #
    # Danica (duquesa atual, adulta). DO LIVRO (fichas, V1 P2 c12): cabelos
    # lisos e escuros na altura dos ombros, pele clara demais, vestido
    # verde-musgo. INFERÊNCIA: o tom exato do verde e dos cabelos, os olhos
    # castanhos (ela não é Abençoada; o livro não diz), o corte simples do
    # vestido sem enfeites (ela parece "hóspede" no castelo) e a altura.
    'danica': dict(
        topo=4, tronco=12, largura=4, cabelo='chanel', roupa='vestido_longo', saia_passo=5,
        olho='#5A4636',
        pele=dict(pele_luz='#F2E2D6', pele='#E6CDBE', pele_sombra='#BE9A8C'),
        cores=dict(
            cab_luz='#4A3A38', cab='#2B2223', cab_sombra='#1A1315', cab_fundo='#100B0C',
            vestido_luz='#7C8B52', vestido='#5B6B3A', vestido_sombra='#3C4A27',
            calca='#3C4A27', calca_sombra='#28331A',
        ),
    ),
    # Pany definitiva, governanta da Mansão Olympia em Atenas (cap. 01: guia o
    # cortejo das criadas, acende as velas do bolo, repreende "Lady Althea!").
    # DO LIVRO: só o cargo e o olhar entre respeito e vontade de puxar a
    # orelha de Nicholas. INFERÊNCIA (mantida do sprite provisório
    # pany_provisoria.png): vestido escuro roxo-acinzentado de governanta,
    # avental claro, chaves na cintura e cabelo grisalho preso em coque; a
    # idade madura vem daí. Cor de pele: a padrão (livro não diz).
    'pany': dict(
        topo=6, tronco=12, largura=4, cabelo='coque', roupa='vestido_longo', saia_passo=5,
        enfeites=('avental', 'chaves'),
        cores=dict(
            cab_luz='#E4E0DA', cab='#B6B1AA', cab_sombra='#807B78', cab_fundo='#5A5654',
            vestido_luz='#544458', vestido='#3A2F3C', vestido_sombra='#241C26',
            calca='#241C26', calca_sombra='#150F18',
            avental='#D8CFC4', avental_sombra='#A79E94',
        ),
    ),
    # Guarda imperial. DO LIVRO (V2 c31): "uniforme dourado e vermelho" e
    # "colar dourado do uniforme"; no Capítulo 01 são poucos, silenciosos, e
    # recuam para o anexo. INFERÊNCIA: o corte (casaco vermelho com a faixa
    # central, ombreiras, cinto e botões dourados), cabelo escuro curto, sem
    # elmo, sem arma na mão, porte alto de soldado.
    'guarda_imperial': dict(
        pasta='guarda_imperial',
        topo=3, tronco=13, largura=5, cabelo='topete', roupa='colete',
        enfeites=('colar', 'ombreiras', 'cinto'),
        cores=dict(
            cab_luz='#5A4636', cab='#3A2B22', cab_sombra='#24180F', cab_fundo='#170E09',
            camisa_luz='#ECBD75', camisa='#B98543', camisa_sombra='#8A5E2C',
            manga='#A8232B', manga_sombra='#6E1219',
            colete='#A8232B', colete_sombra='#6E1219',
            cinto='#8A5E2C',
            calca='#5E1218', calca_sombra='#3E0B10',
        ),
    ),
    # Cocheiro (cap. 01: "cochichou com o cocheiro, alterando a rota"; anuncia
    # a chegada). DO LIVRO: nada de aparência; a carruagem é azul-marinho e
    # dourada, com o brasão de Olympia. INFERÊNCIA: é o cocheiro da casa
    # Olympia, então casaco longo azul-marinho com gola dourada, chapéu de
    # aba curta com faixa dourada, cabelo castanho, adulto de meia-idade.
    'cocheiro': dict(
        topo=5, tronco=13, largura=5, cabelo='topete', roupa='colete', aba=8,
        enfeites=('gola', 'cinto'),
        cores=dict(
            cab_luz='#7A6450', cab='#5A4636', cab_sombra='#3A2B22', cab_fundo='#24180F',
            camisa_luz='#E4E7EC', camisa='#C9CED8', camisa_sombra='#9AA3B3',
            manga='#2B3D55', manga_sombra='#13253C',
            colete='#2B3D55', colete_sombra='#13253C',
            cinto='#4A3428',
            calca='#23262F', calca_sombra='#15171C',
            chapeu='#13253C', chapeu_sombra='#0A1626', chapeu_faixa='#B98543',
        ),
    ),
    # Casal de lojistas da loja de pelúcias (Rua das Butiques). DO LIVRO: são
    # os "donos" ("o homem do casal"), a loja faz pelúcias sob encomenda a
    # partir de desenhos estranhos e criaturas do Mar de Equidna, e eles se
    # ajoelham ao saber quem é Ophelia. INFERÊNCIA: tudo na aparência: roupas
    # de artesãos com avental, idade madura, cores quentes e discretas.
    'lojista_homem': dict(
        pasta='lojista_homem',
        topo=6, tronco=12, largura=5, cabelo='topete', roupa='colete',
        enfeites=('avental',),
        cores=dict(
            cab_luz='#9A8266', cab='#7A6450', cab_sombra='#554434', cab_fundo='#3A2B22',
            camisa_luz='#F2EFE8', camisa='#D9D4CA', camisa_sombra='#A9A398',
            colete='#6B5A3A', colete_sombra='#4A3E28',
            calca='#3A3F4C', calca_sombra='#23262F',
            avental='#D8CFC4', avental_sombra='#A79E94',
        ),
    ),
    'lojista_mulher': dict(
        pasta='lojista_mulher',
        topo=7, tronco=11, largura=4, cabelo='coque', roupa='vestido_longo', saia_passo=5,
        enfeites=('avental',),
        cores=dict(
            cab_luz='#9A7A5C', cab='#6E5240', cab_sombra='#4A362A', cab_fundo='#33241B',
            vestido_luz='#C9A08A', vestido='#A67C68', vestido_sombra='#7A5646',
            calca='#7A5646', calca_sombra='#553B30',
            avental='#EDE3D2', avental_sombra='#C9B79C',
        ),
    ),
    # Garçom do restaurante (cap. 01: coloca o prato diante de Ophelia e
    # "permanece"; sai quando Nicholas manda os empregados se retirarem).
    # DO LIVRO: nada de aparência. INFERÊNCIA: camisa branca, colete escuro,
    # avental longo branco na cintura, calça escura, cabelo escuro curto.
    'garcom': dict(
        topo=5, tronco=12, largura=4, cabelo='topete', roupa='colete',
        enfeites=('avental',),
        cores=dict(
            cab_luz='#4A3A38', cab='#2B2223', cab_sombra='#1A1315', cab_fundo='#100B0C',
            camisa_luz='#F2EFE8', camisa='#E4E0DA', camisa_sombra='#B6B1AA',
            colete='#23262F', colete_sombra='#15171C',
            calca='#23262F', calca_sombra='#15171C',
            avental='#F2EFE8', avental_sombra='#C9CED8',
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
    elif estilo == 'coque':
        # repuxado para trás, risca ao meio e coque no alto da cabeça
        q.r(x - 5, y, x + 5, y + 3, 'cab')
        q.r(x - 4, y - 1, x + 4, y - 1, 'cab')
        q.r(x - 5, y + 3, x - 5, y + 6, 'cab_sombra')
        q.r(x + 5, y + 3, x + 5, y + 5, 'cab_sombra')
        q.r(x - 4, y + 3, x - 3, y + 3, 'cab'); q.r(x + 3, y + 3, x + 4, y + 3, 'cab')
        q.p(x, y, 'cab_sombra'); q.p(x, y + 1, 'cab_sombra')
        q.r(x - 2, y - 3, x + 2, y - 2, 'cab')
        q.r(x - 1, y - 4, x + 1, y - 4, 'cab')
        q.r(x - 2, y - 2, x + 2, y - 2, 'cab_sombra')
        for (dx, dy) in [(-3, 0), (-2, 1), (2, 0), (3, 1), (-1, -3), (1, -4)]:
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
    elif estilo == 'coque':
        q.r(x - 5, y + 2, x + 5, y + 7, 'cab')
        q.r(x - 4, y + 8, x + 4, y + 8, 'cab_sombra')
        q.r(x - 2, y - 3, x + 2, y - 2, 'cab')
        q.r(x - 1, y - 4, x + 1, y - 4, 'cab')
        q.r(x - 2, y - 2, x + 2, y - 2, 'cab_sombra')
        for (dx, dy) in [(-3, 1), (0, 2), (3, 3), (-1, 5), (-1, -3), (1, -4)]:
            q.p(x + dx, y + dy, 'cab_luz')
        q.p(x + 2, y - 3, 'ouro'); q.p(x - 2, y - 3, 'ouro')       # grampos
    elif estilo == 'chanel':
        q.r(x - 6, y + 2, x + 6, y + 9, 'cab')
        q.r(x - 5, y + 10, x + 5, y + 10, 'cab')
        q.r(x - 5, y + 11, x + 5, y + 11, 'cab_sombra')        # pontas retas
        q.r(x - 6, y + 6, x - 6, y + 9, 'cab_sombra')
        q.p(x + 2, y, 'cab_sombra'); q.p(x + 2, y + 1, 'cab_sombra')   # risca
        for (dx, dy) in [(-3, 1), (0, 2), (4, 1), (-1, 5), (3, 6), (-4, 8)]:
            q.p(x + dx, y + dy, 'cab_luz')


def chapeu(q, x, y):
    # chapéu de aba curta com faixa; cobre o topo do cabelo (cores 'chapeu*')
    q.r(x - 5, y - 3, x + 5, y - 1, 'chapeu')
    q.r(x - 4, y - 4, x + 4, y - 4, 'chapeu')
    q.r(x - 5, y, x + 5, y, 'chapeu_faixa')
    q.r(x - 6, y + 1, x + 6, y + 1, 'chapeu_sombra')
    q.r(x + 2, y - 3, x + 3, y - 2, 'chapeu_sombra')


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


def braco_erguido(q, x, yt, larg, cor, lado=1):
    # Braço da frente erguido ao lado da cabeça, preparando o golpe (como o
    # do adulto em gerar_nicholas.py). Desenhado por último, por cima do cabelo.
    # lado=-1: o mesmo braço espelhado, do outro lado (rendição).
    def r(dx0, y0, dx1, y1, c):
        q.r(x + lado * dx0, y0, x + lado * dx1, y1, c)
    r(larg + 1, yt - 1, larg + 2, yt + 1, cor)
    r(larg + 2, yt - 4, larg + 3, yt - 2, cor)
    r(larg + 1, yt + 1, larg + 1, yt + 1, cor + '_sombra'); r(larg + 2, yt - 2, larg + 2, yt - 2, cor + '_sombra')
    r(larg + 2, yt - 6, larg + 3, yt - 5, 'pele')


def espada_madeira(q, mx, my, angulo):
    # Espada de madeira pequena na mão 2×2 cujo canto é (mx, my), apontando
    # para onde o ângulo diz (0 = para baixo, 180 = para cima, -90 = para a
    # frente), como o giro do item na mão (MaosPersonagem.angulos).
    passo = {0: (0, 1), 180: (0, -1), -90: (1, 0)}[angulo]
    dx, dy = passo
    px, py = (abs(dy), abs(dx))            # de lado (a lâmina tem 2 pixels)
    cx, cy = mx + (1 if dx > 0 else 0), my + (1 if dy > 0 else 0)
    if dy < 0:
        cy = my
    # guarda logo depois do punho e lâmina curta com a ponta mais clara
    gx, gy = cx + dx, cy + dy
    for k in (-1, 0, 1):
        q.p(gx + px * k, gy + py * k, 'madeira_sombra')
    for i in range(2, 6):
        q.p(cx + dx * i, cy + dy * i, 'madeira_luz' if i == 5 else 'madeira')
        q.p(cx + dx * i + px, cy + dy * i + py, 'madeira_sombra')


def espada_no_colo(q, cfg, dir, x, yt, quadril, larg):
    # A espada deitada na altura das mãos, de um lado a outro do corpo (o
    # cabo na mão da direita, a ponta para a esquerda); de costas, só a ponta
    # e o cabo aparecem dos lados.
    y = yt + 1 + (quadril - yt - 1) + 1          # a linha das mãos
    if dir == 'frente':
        q.r(x - larg - 3, y, x + larg - 1, y, 'madeira')
        q.r(x - larg - 3, y + 1, x + larg - 1, y + 1, 'madeira_sombra')
        q.p(x - larg - 3, y, 'madeira_luz')
        q.r(x + larg, y - 1, x + larg, y + 2, 'madeira_sombra')   # guarda
        q.r(x + larg + 1, y, x + larg + 2, y + 1, 'pele')         # a mão no cabo
        q.r(x - larg - 2, y, x - larg - 1, y + 1, 'pele')         # a outra mão
    else:
        q.r(x - larg - 4, y, x - larg - 3, y, 'madeira')
        q.r(x + larg + 3, y, x + larg + 4, y, 'madeira_sombra')


def abraca_espada(q, cfg, dir, x, yt, quadril, larg):
    # Os braços dobrados à frente do peito, as mãos juntas no punho e a
    # lâmina para baixo, rente ao vestido; de costas, só os cotovelos.
    cor = cor_braco(cfg)
    if dir == 'frente':
        q.r(x - 1, yt + 4, x, yt + 4, 'madeira_sombra')           # guarda
        for i in range(5, 9):
            q.p(x - 1, yt + i, 'madeira_luz' if i == 8 else 'madeira')
            q.p(x, yt + i, 'madeira_sombra')
        for lado in (-1, 1):
            ombro = x - larg - 2 if lado < 0 else x + larg + 1
            q.r(ombro, yt + 1, ombro + 1, yt + 3, cor)
            q.p(ombro, yt + 1, cor + '_sombra')
        q.r(x - larg - 1, yt + 2, x - 2, yt + 3, cor)             # antebraços
        q.r(x + 1, yt + 2, x + larg, yt + 3, cor)
        q.r(x - 2, yt + 2, x + 1, yt + 3, 'pele')                 # as mãos no punho
        q.r(x - 1, yt + 1, x, yt + 1, 'madeira')                  # o pomo
    else:
        for lado in (-1, 1):
            ombro = x - larg - 2 if lado < 0 else x + larg + 1
            q.r(ombro, yt + 1, ombro + 1, yt + 3, cor)
            q.p(ombro, yt + 1, cor + '_sombra')


def bracos_cruzados(q, cfg, dir, x, yt, quadril, larg):
    # Os braços cruzados no peito: os dois braços colados ao corpo até o
    # cotovelo, um antebraço por cima do outro e cada mão no braço oposto;
    # de costas, só os braços até o cotovelo.
    cor = cor_braco(cfg)
    for lado in (-1, 1):
        ombro = x - larg - 2 if lado < 0 else x + larg + 1
        q.r(ombro, yt + 1, ombro + 1, yt + 5, cor)
        q.r(ombro, yt + 1, ombro, yt + 5, cor + '_sombra')
    if dir != 'frente':
        return
    q.r(x - larg, yt + 3, x + larg + 2, yt + 3, cor + '_sombra')    # antebraço de baixo
    q.r(x - larg - 2, yt + 3, x - larg - 1, yt + 3, 'pele')         # a mão no braço esquerdo
    q.r(x - larg - 2, yt + 4, x + larg, yt + 5, cor)                # antebraço de cima
    q.r(x - larg - 2, yt + 5, x + larg, yt + 5, cor + '_sombra')
    q.r(x + larg + 1, yt + 4, x + larg + 2, yt + 4, 'pele')         # a mão no braço direito


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


def cor_braco(cfg):
    # mangas de outra cor (cores 'manga' e 'manga_sombra') ou da própria roupa
    if 'manga' in cfg['cores']:
        return 'manga'
    return 'camisa' if cfg['roupa'] == 'colete' else 'vestido'


def corpo_frente(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance, saia_voa, ergue=False, rende=False,
                 sem_bracos=False):
    roupa = cfg['roupa']
    comp = quadril - yt - 1
    cor_manga = cor_braco(cfg)
    aba = cfg.get('aba', 0)          # túnica que desce por cima das coxas
    if roupa in CASUAIS:
        casual_frente(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance)
    elif roupa == 'colete':
        if not rende and not sem_bracos:
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
        elif not ergue and not sem_bracos:
            braco(q, x + larg + 1, yt + 1, b_dir, comp, cor_manga)
    else:
        hem = PE - (3 if roupa == 'vestido_longo' else 5)
        if not sem_bracos:
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
        elif not ergue and not sem_bracos:
            braco(q, x + larg + 1, yt + 1, b_dir, comp, cor_manga)


def corpo_costas(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance, saia_voa, ergue=False, rende=False,
                 sem_bracos=False):
    roupa = cfg['roupa']
    comp = quadril - yt - 1
    cor_manga = cor_braco(cfg)
    aba = cfg.get('aba', 0)
    if roupa in CASUAIS:
        casual_costas(q, cfg, x, yt, quadril, larg, b_esq, b_dir, alcance)
        return
    if alcance:
        braco_estendido(q, x + larg + 1, yt + 2, alcance, cor_manga)
    elif not ergue and not sem_bracos:
        braco(q, x + larg + 1, yt + 1, b_dir, comp, cor_manga)
    if roupa == 'colete':
        q.r(x - larg, yt, x + larg, quadril + aba, 'colete')
        q.r(x - larg, yt, x - larg + 1, quadril + aba, 'colete_sombra')
        q.r(x - 1, yt + 2, x + 1, yt + 2, 'colete_sombra')        # costura das costas
        if not aba:
            q.r(x - larg, quadril, x + larg, quadril, 'calca')
        if not rende and not sem_bracos:
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
        if not sem_bracos:
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
    if 'avental' in e:    # avental claro: peitilho e saia (vestido) ou da cintura ao joelho (colete)
        if cfg['roupa'].startswith('vestido'):
            hem = PE - (3 if cfg['roupa'] == 'vestido_longo' else 5)
            topo_av, fim, meia = yt + 3, hem - 1, 3
        else:
            topo_av, fim, meia = quadril - 1, quadril + 9, larg
        if dir == 'frente':
            q.r(x - meia, topo_av, x + meia, fim, 'avental')
            q.r(x - meia, topo_av, x - meia, fim, 'avental_sombra')
            q.r(x - meia, fim, x + meia, fim, 'avental_sombra')
            q.r(x + 1, topo_av + 1, x + 2, topo_av + 2, 'avental')
        else:   # de costas só se vê o laço da cintura
            q.r(x - larg, quadril - 1, x + larg, quadril - 1, 'avental')
            q.r(x - 1, quadril, x + 1, quadril + 2, 'avental')
            q.p(x - 1, quadril + 2, 'avental_sombra'); q.p(x + 1, quadril + 2, 'avental_sombra')
    if 'chaves' in e:     # molho de chaves pendurado na cintura
        q.r(x + larg - 1, quadril + 1, x + larg, quadril + 3, 'ouro')
        q.p(x + larg - 1, quadril + 4, 'ouro_sombra'); q.p(x + larg, quadril + 4, 'ouro_luz')
    if 'colar' in e:      # colar dourado do uniforme, em volta do pescoço
        if dir == 'frente':
            for (dx, dy) in [(-3, 0), (-2, 1), (-1, 2), (0, 2), (1, 2), (2, 1), (3, 0)]:
                q.p(x + dx, yt + dy, 'ouro')
            q.p(x, yt + 2, 'ouro_luz')
        else:
            q.r(x - 3, yt, x + 3, yt, 'ouro')
    if 'ombreiras' in e:  # ombreiras douradas
        q.r(x - larg - 2, yt, x - larg, yt + 1, 'ouro')
        q.r(x + larg, yt, x + larg + 2, yt + 1, 'ouro')
        q.p(x - larg - 2, yt + 1, 'ouro_sombra'); q.p(x + larg + 2, yt + 1, 'ouro_sombra')
        q.p(x - larg - 1, yt, 'ouro_luz'); q.p(x + larg + 1, yt, 'ouro_luz')
    if 'barra' in e and cfg['roupa'].startswith('vestido'):   # barra bordada
        hem = PE - (3 if cfg['roupa'] == 'vestido_longo' else 5)
        a = larg + 1 + (hem - quadril) // cfg.get('saia_passo', 3)
        q.r(x - a - saia_voa, hem - 1, x + a, hem - 1, 'ouro')


def personagem(cfg, dir, f_esq=0, f_dir=0, lift_esq=0, lift_dir=0, dy=0, inclina=0,
               braco_esq=0, braco_dir=0, alcance=0, voa=0, ergue=False, rende=False, espada=None,
               colo=False, abraca=False, cruza=False):
    # rende: as duas mãos para cima (rendição); espada: ângulo da espada de
    # madeira na mão da frente (só nos quadros do golpe de quem tem uma);
    # colo: a espada deitada nas mãos; abraca: a espada apertada no peito;
    # cruza: os braços cruzados.
    cores = dict(BASE)
    cores.update(MADEIRA)
    if rende:
        ergue = True
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
        capa(q, cfg, dir, x, yt, quadril, larg)
        cabelo_atras_frente(q, estilo, x, yc, ate, voa)
        pernas(q, CX, quadril, f_esq, f_dir, lift_esq, lift_dir)
        corpo_frente(q, cfg, x, yt, quadril, larg, braco_esq, braco_dir, alcance, voa // 2, ergue, rende,
                     abraca or cruza)
        enfeites(q, cfg, dir, x, yt, quadril, larg, voa // 2)
        ombros_da_capa(q, cfg, x, yt, larg)
        cabeca_frente(q, dir, x, yc, olho, bochecha)
        cabelo_frente(q, estilo, x, yc)
        if 'chapeu' in cores:
            chapeu(q, x, yc)
        if 'oculos' in cfg:
            oculos_frente(q, x, yc)
    else:
        pernas(q, CX, quadril, f_esq, f_dir, lift_esq, lift_dir)
        corpo_costas(q, cfg, x, yt, quadril, larg, braco_esq, braco_dir, alcance, voa // 2, ergue, rende,
                     abraca or cruza)
        enfeites(q, cfg, dir, x, yt, quadril, larg, voa // 2)
        capa(q, cfg, dir, x, yt, quadril, larg)
        cabeca_costas(q, estilo, x, yc, ate, voa)
        if 'chapeu' in cores:
            chapeu(q, x, yc)
        if estilo == 'longo':   # braços por cima do cabelo comprido
            braco_costas(q, cfg, x, yt, quadril, larg, braco_esq, braco_dir, alcance)
    if ergue:
        braco_erguido(q, x, yt, larg, cor_braco(cfg))
    if rende:
        braco_erguido(q, x, yt, larg, cor_braco(cfg), -1)
    if espada is not None:
        mx, my = mao(cfg, dir, f_esq, f_dir, lift_esq, lift_dir, dy, inclina, braco_esq, braco_dir,
                     alcance, voa, ergue)
        espada_madeira(q, mx, my, espada)
    if colo:
        espada_no_colo(q, cfg, dir, x, yt, quadril, larg)
    if abraca:
        abraca_espada(q, cfg, dir, x, yt, quadril, larg)
    if cruza:
        bracos_cruzados(q, cfg, dir, x, yt, quadril, larg)
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
    # golpe de espada, só de quem tem cfg['golpe'] (o Nicholas que luta):
    # ergue, corta para a frente, termina com a lâmina baixa, como o adulto
    'golpe':       [dict(ergue=True), dict(alcance=5, inclina=1, dy=1), dict(braco_dir=1, inclina=1, dy=1)],
    # rendição fingida, só de quem tem cfg['rendicao']: as duas mãos para cima
    'rendicao':    [dict(rende=True), dict(rende=True, dy=1)],
    # só de quem tem cfg['abraca_espada'] (Althea com o duque): a espada no
    # colo e a espada apertada contra o peito
    'espada_colo':   [dict(colo=True), dict(colo=True, dy=1)],
    'abraca_espada': [dict(abraca=True), dict(abraca=True, dy=1)],
    # só de quem tem cfg['bracos_cruzados'] (Nicholas esperando na porta)
    'bracos_cruzados': [dict(cruza=True), dict(cruza=True, dy=1)],
}
# Espada de madeira (Althea): madeira clara, a mesma das tábuas.
MADEIRA = dict(madeira_luz='#D8B47E', madeira='#A97C4A', madeira_sombra='#6E4C2C')
ORDEM = ['parado', 'andando', 'correndo', 'interagindo']
VELOCIDADE = {'parado': 2.0, 'andando': 8.0, 'correndo': 12.0, 'interagindo': 10.0, 'golpe': 12.0,
              'rendicao': 2.0, 'espada_colo': 2.0, 'abraca_espada': 2.0,
              'bracos_cruzados': 2.0}
# Giro do item na mão em cada quadro, em graus (0 = ponta para baixo).
ANGULOS = {'golpe': [180, -90, 0]}
DIRS = ['frente', 'costas']


def quadros(cfg, a):
    # Os quadros da animação para este personagem. O golpe da Althea leva a
    # espada de madeira na mão e corta mais perto do corpo (o braço dela é
    # curto e a lâmina sairia do quadro).
    lista = ANIM[a]
    if a == 'golpe' and cfg.get('espada_madeira'):
        lista = [dict(k, espada=ANGULOS[a][i], alcance=min(k.get('alcance', 0), 2))
                 for i, k in enumerate(lista)]
    return lista


def linhas_da_folha(cfg):
    # O golpe fica no fim, para não mudar o lugar das linhas que já existiam.
    linhas = [(d, a) for d in DIRS for a in ORDEM]
    if cfg.get('golpe'):
        linhas += [(d, 'golpe') for d in DIRS]
    if cfg.get('rendicao'):
        linhas += [(d, 'rendicao') for d in DIRS]
    if cfg.get('abraca_espada'):
        linhas += [(d, a) for a in ('espada_colo', 'abraca_espada') for d in DIRS]
    if cfg.get('bracos_cruzados'):
        linhas += [(d, 'bracos_cruzados') for d in DIRS]
    return linhas


def folha(cfg):
    linhas = linhas_da_folha(cfg)
    im = Image.new('RGBA', (W * 4, HH * len(linhas)), (0, 0, 0, 0))
    for linha, (d, a) in enumerate(linhas):
        for i, k in enumerate(quadros(cfg, a)):
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
            ', '.join(quadros), 'false' if a in ('interagindo', 'golpe') else 'true', a, d, VELOCIDADE[a]))
    partes.append('[resource]\nanimations = [%s]\n' % ', '.join(animacoes))
    return '\n'.join(partes)


def mao(cfg, dir, f_esq=0, f_dir=0, lift_esq=0, lift_dir=0, dy=0, inclina=0,
        braco_esq=0, braco_dir=0, alcance=0, voa=0, ergue=False, rende=False, espada=None,
        colo=False, abraca=False, cruza=False):
    # Canto de cima à esquerda da mão 2×2 do braço da frente (o da direita
    # na tela), com as mesmas contas de personagem().
    x = CX + inclina
    yt = cfg['topo'] + dy + 10
    larg = cfg['largura']
    if ergue or rende:
        return (x + larg + 2, yt - 6)
    if cruza:
        return (x + larg + 1, yt + 4)
    if alcance:
        return (x + larg + 2 + alcance, yt + 2)
    comp = cfg['tronco'] - 1
    return (x + larg + 1, yt + 1 + braco_dir + comp + 1)


def mao_tras(cfg, dir, f_esq=0, f_dir=0, lift_esq=0, lift_dir=0, dy=0, inclina=0,
             braco_esq=0, braco_dir=0, alcance=0, voa=0, ergue=False, rende=False, espada=None,
             colo=False, abraca=False, cruza=False):
    # Mão do braço de trás (o da esquerda na tela), onde vai o escudo.
    x = CX + inclina
    yt = cfg['topo'] + dy + 10
    if rende:
        return (x - cfg['largura'] - 3, yt - 6)
    if cruza:
        return (x - cfg['largura'] - 2, yt + 3)
    comp = cfg['tronco'] - 1
    return (x - cfg['largura'] - 2, yt + 1 + braco_esq + comp + 1)


def maos_tres(cfg):
    # Onde ficam as mãos em cada quadro (MaosPersonagem), para desenhar a
    # arma e o escudo na mão; mesmo formato do nicholas_maos.tres do adulto.
    linhas, tras, giros = [], [], []
    for d, a in linhas_da_folha(cfg):
        linhas.append('&"%s_%s": PackedVector2Array(%s)' % (
            a, d, ', '.join('%d, %d' % mao(cfg, d, **k) for k in quadros(cfg, a))))
        tras.append('&"%s_%s": PackedVector2Array(%s)' % (
            a, d, ', '.join('%d, %d' % mao_tras(cfg, d, **k) for k in quadros(cfg, a))))
        if a in ANGULOS:
            giros.append('&"%s_%s": PackedFloat32Array(%s)' % (a, d, ', '.join(str(g) for g in ANGULOS[a])))
    return ('[gd_resource type="Resource" script_class="MaosPersonagem" format=3]\n\n'
            '[ext_resource type="Script" path="res://scripts/systems/maos_personagem.gd" id="1_maos"]\n\n'
            '[resource]\nscript = ExtResource("1_maos")\n'
            'tamanho_quadro = Vector2i(%d, %d)\n'
            'pontos = {\n%s\n}\n'
            'angulos = {\n%s\n}\n'
            'pontos_tras = {\n%s\n}\n' % (W, HH, ',\n'.join(linhas), ',\n'.join(giros), ',\n'.join(tras)))


if __name__ == '__main__':
    raiz = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'art', 'personagens')
    for id, cfg in PERSONAGENS.items():
        nome_pasta = cfg.get('pasta', id.split('_')[0])
        pasta = os.path.join(raiz, nome_pasta)
        os.makedirs(pasta, exist_ok=True)
        im, linhas = folha(cfg)
        im.save(os.path.join(pasta, '%s_exploracao.png' % id))
        with open(os.path.join(pasta, '%s_exploracao.tres' % id), 'w') as f:
            f.write(sprite_frames(id, linhas, 'res://assets/art/personagens/%s/%s_exploracao.png' % (nome_pasta, id)))
        if cfg.get('golpe'):
            with open(os.path.join(pasta, '%s_maos.tres' % id), 'w') as f:
                f.write(maos_tres(cfg))
        print(id, im.size)
