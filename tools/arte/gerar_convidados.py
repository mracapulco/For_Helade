# Gera a arte dos "convidados": pessoas reais (e, depois, pets) que aparecem
# no jogo como easter egg. Não são personagens do livro.
# Uso: python3 tools/arte/gerar_convidados.py   (rodar na raiz do projeto)
# Para cada convidado grava em assets/art/convidados/<id>/:
# - <id>_exploracao.png e .tres: folha de animação 32×48 (mesma grade, mesmas
#   animações e mesmas partes de gerar_personagens.py);
# - <id>_parado.png: um quadro parado de frente (figurante no acampamento);
# - <id>_figurante.png: faixa de 4 quadros 32×48 respirando (como o mercador);
# - <id>_retrato.png e <id>_retrato_fala.png: o rosto 48×48 da caixa de
#   diálogo, parado e falando (3 quadros: boca fechada, entreaberta, aberta).
# E as peças próprias de cada um (barraca do Rafael, banca da Shara).
#
# Para acrescentar alguém: copie uma entrada de CONVIDADOS, troque as cores e
# escolha o cabelo ('rebelde', 'ombros', 'longo', 'topete', 'chanel') e a
# roupa ('camiseta', 'moletom', 'escoteiro', 'colete', 'vestido_curto',
# 'vestido_longo'). Opcionais: 'oculos' (cor da armação), 'mochila' (True,
# com as cores 'mochila*' e 'alca*'), 'olho' (cor da íris), 'pele' (tons).
# Altura: 'topo' é a linha do alto da cabeça (menor = mais alto) e 'tronco' o
# comprimento do tronco; 'largura' é meia largura do tronco. O retrato é uma
# função própria em RETRATOS (desenho à mão, pixel a pixel).
# Pets vão precisar de um desenho próprio (corpo de quatro patas); a folha e o
# SpriteFrames (folha(), sprite_frames()) servem igual.
import os
import sys

from PIL import Image, ImageDraw

sys.dont_write_bytecode = True  # sem __pycache__ dentro de tools/
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_personagens import ANIM, W, HH, folha, personagem, sprite_frames  # noqa: E402
from gerar_objetos import C, H as H_OBJ, Q as QObj  # noqa: E402

PELE_CLARA = dict(pele_luz='#F0D4C2', pele='#DDB39E', pele_sombra='#B08470')
JEANS = dict(calca='#3E5470', calca_sombra='#2A3A50')
TENIS = dict(sapato='#4A4A50', sapato_sombra='#2C2C30')

CONVIDADOS = {
    # Rafael: alto, pele clara, sem barba, cabelo castanho escuro curto com
    # topete, olhos verdes. Viajante escoteiro: camisa caqui de manga curta
    # com bolsos, lenço verde com anel dourado, cinto, calça e botas, mochila.
    'rafael': dict(
        topo=3, tronco=13, largura=5, cabelo='topete', roupa='escoteiro',
        pele=PELE_CLARA, olho='#4E8A4A', mochila=True,
        cores=dict(
            cab_luz='#6B4A34', cab='#4A3022', cab_sombra='#2E1C13', cab_fundo='#1C110B',
            escoteiro_luz='#D9C79A', escoteiro='#BCA576', escoteiro_sombra='#8E7A52',
            lenco='#2A6B3E', lenco_sombra='#1A4A28', anel='#ECBD75', cinto='#4A3428',
            mochila_luz='#6E8EAC', mochila='#4E6E8E', mochila_sombra='#34506C',
            alca='#C4C8CC', alca_sombra='#9095A0',
            calca='#4E4A36', calca_sombra='#34311F',
            sapato='#5A3C26', sapato_sombra='#3A2617',
        ),
    ),
    # Shara: pele clara, cabelo castanho liso na altura dos ombros, óculos de
    # armação redonda escura, moletom preto (no jogo, uma túnica preta com
    # capuz), jeans e tênis escuro. Mercadora de livros e poções.
    'shara': dict(
        topo=8, tronco=11, largura=4, cabelo='chanel', roupa='moletom',
        pele=PELE_CLARA, olho='#6E6A48', oculos='#1A1A20',
        cores=dict(
            cab_luz='#A07A54', cab='#7A5838', cab_sombra='#573C24', cab_fundo='#3A2716',
            moletom_luz='#46464E', moletom='#2A2A31', moletom_sombra='#18181D',
            cordao='#B8BCC4', **TENIS, **JEANS,
        ),
    ),
}


# --- retratos (48×48) ---------------------------------------------------------
# Cada função desenha o rosto com a boca em 3 posições: 0 fechada (parado),
# 1 entreaberta e 2 aberta. A caixa de diálogo alterna as três enquanto o
# texto aparece.

T = 48
H = lambda h: tuple(int(h[i:i+2], 16) for i in (1, 3, 5)) + (255,)


class R:
    def __init__(s, cores):
        s.im = Image.new('RGBA', (T, T), (0, 0, 0, 0))
        s.d = ImageDraw.Draw(s.im)
        s.c = {k: H(v) for k, v in cores.items()}
    def p(s, x, y, c):
        if 0 <= x < T and 0 <= y < T: s.im.putpixel((x, y), s.c[c])
    def r(s, x0, y0, x1, y1, c):
        s.d.rectangle((x0, y0, x1, y1), fill=s.c[c])
    def e(s, x0, y0, x1, y1, c):
        s.d.ellipse((x0, y0, x1, y1), fill=s.c[c])
    def poly(s, pts, c):
        s.d.polygon(pts, fill=s.c[c])
    def linha(s, pts, c):
        s.d.line(pts, fill=s.c[c])
    def pts(s, lista, c):
        for x, y in lista: s.p(x, y, c)
    def contornar(s):
        px = s.im.load()
        cheios = {(x, y) for x in range(T) for y in range(T) if px[x, y][3]}
        for (x, y) in list(cheios):
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n not in cheios and 0 <= n[0] < T and 0 <= n[1] < T:
                    px[n] = s.c['contorno']
        return s.im

PELE = dict(pele_luz='#F4DCCB', pele='#E2B9A2', pele_sombra='#BD8C76', pele_funda='#94604F', boca='#9E4A45', dente='#F4F0E8', labio='#C77A6E')

def retrato_rafael(boca=0):
    q = R(dict(contorno='#050C14', **PELE,
        cab_luz='#7A5640', cab='#4E3324', cab_sombra='#33200F', cab_fundo='#1E1209',
        olho='#4E8A4A', olho_escuro='#1F2A1C', branco='#F2EEE6', sobrancelha='#3A2618',
        camisa_luz='#D9C79A', camisa='#BCA576', camisa_sombra='#8E7A52',
        lenco_luz='#3E8A54', lenco='#2A6B3E', lenco_sombra='#1A4A28', anel='#ECBD75'))
    # ombros e camisa caqui
    q.poly([(4, 47), (8, 41), (17, 38), (31, 38), (40, 41), (44, 47)], 'camisa')
    q.poly([(4, 47), (8, 41), (14, 39), (11, 47)], 'camisa_sombra')
    q.linha([(35, 41), (39, 44)], 'camisa_luz')
    # pescoço
    q.r(19, 33, 29, 40, 'pele_sombra'); q.r(21, 33, 29, 39, 'pele')
    # gola
    q.poly([(16, 38), (20, 37), (24, 42), (18, 43)], 'camisa_luz')
    q.poly([(32, 38), (28, 37), (24, 42), (30, 43)], 'camisa_luz')
    # lenço: V em volta do pescoço e o anel
    q.poly([(18, 38), (21, 37), (24, 41), (27, 37), (30, 38), (26, 44), (24, 47), (22, 44)], 'lenco')
    q.linha([(19, 38), (23, 43)], 'lenco_luz'); q.linha([(28, 39), (25, 44)], 'lenco_sombra')
    q.r(23, 42, 25, 43, 'anel'); q.p(24, 42, 'pele_luz')
    # orelhas
    q.e(11, 20, 15, 28, 'pele_sombra'); q.e(33, 20, 37, 28, 'pele_sombra')
    q.r(12, 22, 13, 25, 'pele'); q.r(35, 22, 36, 25, 'pele')
    # rosto (oval alongado, queixo marcado)
    q.e(13, 9, 35, 35, 'pele')
    q.poly([(15, 27), (33, 27), (29, 34), (24, 36), (19, 34)], 'pele')
    q.poly([(14, 24), (16, 31), (20, 35), (17, 30)], 'pele_sombra')
    q.r(28, 14, 31, 16, 'pele_luz')
    # cabelo: laterais curtas, topete alto penteado para cima e para trás
    q.e(14, 1, 35, 15, 'cab')
    q.poly([(15, 6), (19, 1), (27, 0), (33, 2), (36, 7), (35, 12), (31, 8), (24, 7), (18, 9)], 'cab')
    q.poly([(13, 9), (15, 8), (15, 19), (13, 19)], 'cab_sombra')      # lateral curta
    q.poly([(35, 9), (33, 8), (33, 18), (35, 18)], 'cab_sombra')
    # testa alta: a linha do cabelo sobe nas entradas
    q.poly([(15, 14), (18, 11), (21, 12), (24, 10), (28, 11), (31, 10), (34, 13), (34, 9), (15, 9)], 'cab')
    q.linha([(18, 4), (23, 2), (29, 2)], 'cab_luz'); q.linha([(20, 7), (26, 5), (32, 6)], 'cab_luz')
    q.linha([(22, 9), (28, 8)], 'cab_luz'); q.pts([(34, 7), (17, 7)], 'cab_luz')
    q.linha([(16, 10), (17, 12)], 'cab_fundo'); q.linha([(30, 9), (32, 10)], 'cab_sombra')
    # sobrancelhas retas
    q.r(17, 18, 21, 18, 'sobrancelha'); q.p(16, 19, 'sobrancelha')
    q.r(27, 18, 31, 18, 'sobrancelha'); q.p(32, 19, 'sobrancelha')
    # olhos verdes (um pouco apertados pelo sorriso)
    for x in (17, 27):
        q.r(x, 21, x + 4, 22, 'branco')
        q.r(x + 1, 21, x + 2, 22, 'olho'); q.p(x + 2, 21, 'olho_escuro')
        q.r(x, 20, x + 4, 20, 'olho_escuro')
        q.p(x + 1, 23, 'pele_sombra'); q.p(x + 3, 23, 'pele_sombra')
    # nariz reto
    q.linha([(24, 22), (24, 27)], 'pele_sombra'); q.r(22, 28, 25, 28, 'pele_sombra'); q.p(26, 27, 'pele_luz')
    # bochechas do sorriso
    q.pts([(17, 28), (31, 28), (18, 29), (30, 29)], 'pele_sombra')
    # boca: 0 fechada sorrindo, 1 entreaberta, 2 aberta (sorriso largo mostra os dentes)
    if boca == 0:
        q.linha([(19, 29), (21, 31), (27, 31), (29, 29)], 'boca')
        q.r(22, 32, 26, 32, 'pele_sombra')
    elif boca == 1:
        q.poly([(19, 30), (29, 30), (27, 32), (21, 32)], 'boca')
        q.r(21, 30, 27, 30, 'dente')
        q.r(22, 33, 26, 33, 'labio')
    else:
        q.poly([(19, 30), (29, 30), (27, 34), (21, 34)], 'boca')
        q.r(20, 30, 28, 31, 'dente')
        q.r(22, 35, 26, 35, 'labio')
    # sombra do queixo
    q.linha([(21, 36), (27, 36)], 'pele_sombra')
    return q.contornar()

def retrato_shara(boca=0):
    q = R(dict(contorno='#050C14', **PELE,
        cab_luz='#B08A60', cab='#86643F', cab_sombra='#5E4429', cab_fundo='#3E2B19',
        olho='#6E6A48', olho_escuro='#1F1C14', branco='#F2EEE6', sobrancelha='#5E4429',
        oculos='#16161C', lente='#DCE6EE',
        moletom_luz='#4A4A54', moletom='#2A2A31', moletom_sombra='#18181D', cordao='#B8BCC4'))
    # cabelo de trás (até os ombros)
    q.poly([(11, 14), (37, 14), (39, 36), (36, 41), (12, 41), (9, 36)], 'cab_sombra')
    # moletom preto com capuz caído
    q.poly([(3, 47), (7, 41), (16, 37), (32, 37), (41, 41), (45, 47)], 'moletom')
    q.poly([(13, 38), (18, 36), (30, 36), (35, 38), (31, 41), (17, 41)], 'moletom_luz')
    q.poly([(16, 39), (32, 39), (30, 42), (18, 42)], 'moletom_sombra')
    q.linha([(21, 42), (21, 47)], 'cordao'); q.linha([(27, 42), (27, 46)], 'cordao')
    # pescoço
    q.r(20, 32, 28, 39, 'pele_sombra'); q.r(21, 32, 28, 38, 'pele')
    q.linha([(18, 38), (24, 40), (30, 38)], 'moletom_sombra')
    # rosto mais redondo
    q.e(13, 10, 35, 37, 'pele')
    q.poly([(13, 22), (15, 31), (20, 36), (17, 28)], 'pele_sombra')
    q.r(28, 15, 31, 18, 'pele_luz')
    # cabelo da frente: liso, risca de lado, emoldurando o rosto até os ombros
    q.e(11, 3, 37, 19, 'cab')
    q.poly([(11, 14), (15, 12), (16, 30), (14, 40), (10, 40), (9, 30)], 'cab')
    q.poly([(37, 14), (33, 13), (33, 30), (35, 40), (39, 40), (39, 30)], 'cab')
    # franja varrida da risca (à esquerda de quem olha) para o lado
    q.poly([(19, 7), (34, 10), (35, 17), (31, 12), (25, 11), (19, 12), (16, 17), (16, 11)], 'cab')
    q.poly([(16, 12), (19, 9), (18, 12), (16, 17)], 'cab_sombra')
    q.linha([(19, 6), (19, 9)], 'cab_fundo')    # risca
    q.linha([(21, 6), (28, 6), (33, 9)], 'cab_luz'); q.linha([(23, 9), (30, 10)], 'cab_luz')
    q.linha([(12, 18), (11, 30)], 'cab_luz'); q.linha([(36, 18), (37, 30)], 'cab_luz')
    q.linha([(15, 22), (15, 34)], 'cab_sombra'); q.linha([(33, 22), (34, 34)], 'cab_sombra')
    q.pts([(10, 40), (13, 41), (36, 41), (38, 40)], 'cab_sombra')
    # sobrancelhas finas
    q.r(17, 17, 21, 17, 'sobrancelha'); q.r(27, 17, 31, 17, 'sobrancelha')
    # olhos
    for x in (18, 27):
        q.r(x, 21, x + 3, 22, 'branco')
        q.r(x + 1, 21, x + 2, 22, 'olho'); q.p(x + 1, 21, 'olho_escuro')
        q.r(x, 20, x + 3, 20, 'olho_escuro')
    # óculos de armação redonda escura
    for x0 in (15, 25):
        q.d.ellipse((x0, 17, x0 + 8, 25), outline=q.c['oculos'])
    q.r(24, 20, 24, 20, 'oculos')
    q.pts([(14, 20), (13, 20), (34, 20), (35, 20)], 'oculos')
    q.pts([(22, 19), (32, 19)], 'lente')
    # nariz pequeno
    q.p(24, 25, 'pele_sombra'); q.r(23, 27, 25, 27, 'pele_sombra'); q.p(25, 26, 'pele_luz')
    q.pts([(18, 28), (30, 28)], 'labio')     # bochechas rosadas
    if boca == 0:
        q.linha([(21, 30), (22, 31), (26, 31), (27, 30)], 'boca')
        q.r(23, 32, 25, 32, 'pele_sombra')
    elif boca == 1:
        q.poly([(21, 30), (27, 30), (26, 32), (22, 32)], 'boca')
        q.r(22, 30, 26, 30, 'dente')
        q.r(23, 33, 25, 33, 'labio')
    else:
        q.poly([(20, 30), (28, 30), (26, 34), (22, 34)], 'boca')
        q.r(21, 30, 27, 30, 'dente')
        q.r(23, 35, 25, 35, 'labio')
    return q.contornar()


RETRATOS = {'rafael': retrato_rafael, 'shara': retrato_shara}
BOCAS = 3


# --- peças do acampamento -----------------------------------------------------

C.update(
    lona_luz=H_OBJ('#8C9A5E'), lona=H_OBJ('#6B7A44'), lona_sombra=H_OBJ('#4C5830'),
    toldo_luz=H_OBJ('#DCCB9C'), toldo=H_OBJ('#BCA576'), toldo_sombra=H_OBJ('#8E7A52'),
    lenco=H_OBJ('#2A6B3E'), corda=H_OBJ('#A69C92'),
    roxo_luz=H_OBJ('#7A64A0'), roxo=H_OBJ('#4A3A6A'), roxo_sombra=H_OBJ('#2E2444'),
    pocao_verde=H_OBJ('#5FBF6A'), pocao_roxa=H_OBJ('#A36AD0'), pocao_azul=H_OBJ('#5A9AD8'),
    vidro=H_OBJ('#D4E2EF'), livro_vermelho=H_OBJ('#8E1F25'), livro_azul=H_OBJ('#2B3D55'),
    livro_verde=H_OBJ('#2A6B3E'), papel=H_OBJ('#F4EFE8'),
)


def flor_de_lis(q, x, y, cor):
    # o símbolo dos escoteiros, em 5×5
    for (dx, dy) in [(2, 0), (1, 1), (2, 1), (3, 1), (0, 2), (2, 2), (4, 2), (0, 3), (1, 3), (2, 3), (3, 3), (4, 3), (2, 4)]:
        q.p(x + dx, y + dy, cor)


def barraca_rafael():
    # barraca canadense de lona verde com um toldo caqui na frente, apoiado em
    # dois postes e esticado por cordas; bandeirola com a flor-de-lis
    q = QObj(64, 48)
    q.sombra_no_chao(32, 43, 30, 3)
    topo, base = 10, 42
    for y in range(topo, base + 1):
        meia = (y - topo) * 22 // (base - topo)
        q.linha(y, 32 - meia, 32 + meia, 'lona')
        q.r(32 - meia, y, 32 - meia + 1, y, 'lona_sombra')
        if y > topo + 2:
            q.p(32 + meia - 1, y, 'lona_luz')
    for y in range(topo + 18, base + 1):                        # porta aberta
        meia = (y - topo - 18) * 7 // (base - topo - 18)
        q.linha(y, 32 - meia, 32 + meia, 'noite')
    q.r(30, base - 3, 32, base - 1, 'vela_escura')
    # toldo: faixa caqui na frente, com a borda recortada
    q.r(4, 18, 59, 22, 'toldo')
    q.linha(18, 4, 59, 'toldo_luz'); q.linha(22, 4, 59, 'toldo_sombra')
    for x in range(4, 60, 4):
        q.r(x + 1, 23, x + 2, 24, 'toldo_sombra')
    for x in (5, 58):                                           # postes
        q.coluna(x, 16, base, 'madeira'); q.p(x, 15, 'ouro_luz')
    for i in range(5):                                          # cordas até o chão
        q.p(4 - i // 2, 26 + i * 3, 'corda'); q.p(59 + i // 2, 26 + i * 3, 'corda')
    # mastro com bandeirola verde e a flor-de-lis dourada
    q.coluna(32, 1, topo + 1, 'madeira')
    q.r(33, 1, 42, 7, 'lenco'); q.p(43, 4, 'lenco')
    flor_de_lis(q, 35, 2, 'ouro_luz')
    q.r(1, base - 1, 2, base, 'madeira'); q.r(61, base - 1, 62, base, 'madeira')
    return q.contornar()


def frasco(q, x, y, liquido):
    # frasco de Erlenmeyer: gargalo estreito e base larga
    q.r(x + 2, y, x + 3, y + 2, 'vidro')
    for i in range(4):
        q.linha(y + 3 + i, x + 2 - i // 2 - 1, x + 3 + i // 2 + 1, 'vidro')
    q.linha(y + 5, x + 1, x + 4, liquido); q.linha(y + 6, x, x + 5, liquido)
    q.p(x + 2, y, 'branco')


def banca_shara():
    # carrinho de livros e poções: toldo roxo e prata, pilhas de livros,
    # um livro aberto e frascos com líquidos coloridos
    q = QObj(42, 40)
    q.sombra_no_chao(21, 36, 20, 3)
    q.r(4, 22, 37, 31, 'madeira')
    q.linha(22, 4, 37, 'madeira_luz'); q.linha(31, 4, 37, 'madeira_sombra')
    for x in (12, 20, 28): q.coluna(x, 23, 30, 'madeira_sombra')
    q.elipse(10, 33, 4, 4, 'madeira_sombra'); q.elipse(10, 33, 2, 2, 'madeira_luz')
    q.p(10, 33, 'ouro')
    q.r(36, 27, 41, 28, 'madeira')
    for x in (5, 36): q.r(x, 7, x + 1, 22, 'madeira')
    for x in range(2, 40):
        cor = 'roxo' if (x // 4) % 2 == 0 else 'prata'
        q.r(x, 4, x, 9, cor)
    q.linha(4, 2, 39, 'roxo_luz')
    for x in range(2, 40, 4): q.p(x + 1, 10, 'roxo' if (x // 4) % 2 == 0 else 'prata')
    # pilha de livros
    for i, cor in enumerate(['livro_azul', 'livro_vermelho', 'livro_verde']):
        y = 19 - i * 2
        q.r(7 + i % 2, y, 13 + i % 2, y + 1, cor); q.p(8 + i % 2, y, 'papel')
    # livro aberto
    q.r(15, 19, 22, 21, 'papel'); q.coluna(18, 19, 21, 'prata_sombra'); q.coluna(19, 19, 21, 'prata_sombra')
    q.linha(22 - 1, 15, 22, 'livro_vermelho')
    # frascos
    frasco(q, 23, 14, 'pocao_verde')
    frasco(q, 29, 14, 'pocao_roxa')
    q.elipse(35, 19, 2, 2, 'pocao_azul'); q.r(35, 14, 35, 16, 'vidro'); q.p(34, 18, 'vidro')
    return q.contornar()


PECAS = {
    'rafael': {'rafael_barraca': barraca_rafael},
    'shara': {'shara_banca': banca_shara},
}


def faixa_figurante(cfg):
    # 4 quadros parado de frente, respirando (mesmo formato do mercador)
    quadros = [personagem(cfg, 'frente', **k) for k in ANIM['parado']]
    im = Image.new('RGBA', (W * 4, HH), (0, 0, 0, 0))
    for i, q in enumerate([0, 0, 1, 1]):
        im.paste(quadros[q], (i * W, 0))
    return im


def faixa_fala(desenho):
    im = Image.new('RGBA', (T * BOCAS, T), (0, 0, 0, 0))
    for i in range(BOCAS):
        im.paste(desenho(i), (i * T, 0))
    return im


if __name__ == '__main__':
    raiz = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'art', 'convidados')
    for id, cfg in CONVIDADOS.items():
        pasta = os.path.join(raiz, id)
        os.makedirs(pasta, exist_ok=True)
        im, linhas = folha(cfg)
        im.save(os.path.join(pasta, '%s_exploracao.png' % id))
        caminho = 'res://assets/art/convidados/%s/%s_exploracao.png' % (id, id)
        with open(os.path.join(pasta, '%s_exploracao.tres' % id), 'w') as f:
            f.write(sprite_frames(id, linhas, caminho))
        personagem(cfg, 'frente').save(os.path.join(pasta, '%s_parado.png' % id))
        faixa_figurante(cfg).save(os.path.join(pasta, '%s_figurante.png' % id))
        if id in RETRATOS:
            RETRATOS[id](0).save(os.path.join(pasta, '%s_retrato.png' % id))
            faixa_fala(RETRATOS[id]).save(os.path.join(pasta, '%s_retrato_fala.png' % id))
        for nome, desenho in PECAS.get(id, {}).items():
            desenho().save(os.path.join(pasta, '%s.png' % nome))
        print(id, im.size)
