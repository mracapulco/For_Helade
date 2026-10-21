# Gera a arte provisória da manhã do Capítulo 01 ("A garota do corredor"):
# chão e parede da Mansão Olympia em Atenas, camas, espelho, portas, mesa de
# chá, o bolo azul de três andares no carrinho, o embrulho da espada, Pany e
# a garota da visão. Tudo provisório, na paleta de Hélade, para testar até a
# arte final. Do livro: o bolo azul de três andares com pérolas de açúcar e
# seis velas, o embrulho comprido, a pelúcia de monstro marinho de Althea, o
# espelho grande demais para o quarto. O resto (móveis, cores, Pany) é
# inferência provisória.
# Identidade visual da Casa Olympia (pedido do Rafael, 14/10/2026): a mansão
# segue o Castelo Olympia do prólogo (tools/cena/gerar_cenario_prologo.py,
# branch do prólogo): parede de pedra clara em blocos, assoalho nos quartos,
# piso de pedra com passadeira vermelha de borda azul e dourada no corredor,
# tochas e arandelas com chama, quadros que são recortes do mapa de Hélade em
# moldura dourada, tapeçaria, a espada sobre uma placa de madeira e camas de
# madeira com coberta azul (a de Althea com dossel azul-escuro, como a cama da
# duquesa no prólogo).
# Uso: python3 tools/arte/gerar_capitulo_01.py   (rodar na raiz do projeto)
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_objetos import Q, C, H  # noqa: E402

C.update(
    piso=H('#6E5C4A'), piso_luz=H('#857058'), piso_sombra=H('#54453A'),
    parede=H('#3B4A5E'), parede_luz=H('#52627A'), parede_sombra=H('#26324A'),
    lencol=H('#D8D4CC'), lencol_sombra=H('#A9A398'),
    colcha=H('#2B3D55'), colcha_luz=H('#3E5470'),
    bolo=H('#7FA2C8'), bolo_luz=H('#A9C4E0'), bolo_sombra=H('#55779E'),
    perola=H('#F4EFE8'),
    vestido_althea=H('#D8E2EE'),
    cab_althea=H('#E3D5AE'), cab_althea_luz=H('#F6EED2'),
    monstro=H('#3F7C78'), monstro_luz=H('#5FA39C'),
    embrulho=H('#8E1F25'), embrulho_luz=H('#B8343A'),
    pany_vestido=H('#3A2F3C'), pany_vestido_luz=H('#544458'),
    silhueta=H('#1A1210'), silhueta_luz=H('#3A2820'),
    vidro=H('#9FB8D2'), vidro_luz=H('#D4E2EF'),
    # do castelo do prólogo (cores dos materiais de gerar_texturas_prologo.py)
    pedra_parede=H('#A0968A'), pedra_parede_luz=H('#B9AFA1'),
    pedra_parede_sombra=H('#7C7369'), argamassa=H('#5E574F'),
    pedra_piso=H('#736E68'), pedra_piso_luz=H('#837D76'), pedra_piso_sombra=H('#5A5550'),
    assoalho=H('#7A5236'), assoalho_luz=H('#8A5F3F'), assoalho_sombra=H('#5E3F2A'),
    tapete=H('#6B1210'), tapete_luz=H('#82201C'), tapete_azul=H('#0D143A'),
    creme=H('#D1BF99'), ferro=H('#3A3D42'), ferro_luz=H('#6E737A'),
    veludo=H('#0F1A3A'), veludo_luz=H('#1F2E58'),
    grama=H('#4E6B3A'), grama_luz=H('#6A8A4A'), grama_sombra=H('#3B5530'),
    folha=H('#2F4A2C'), folha_luz=H('#46663C'), folha_escura=H('#1F3420'),
    oliva=H('#7C8A6A'), oliva_luz=H('#9AA884'), oliva_sombra=H('#5E6A50'),
    tronco=H('#5A4232'), tronco_luz=H('#77583F'),
    marmore=H('#E2DED4'), marmore_luz=H('#F6F3EC'), marmore_sombra=H('#B8B2A6'),
    flor=H('#C9A4D8'), flor2=H('#E8D27A'),
    # Rodada 1 das cenas 7 a 10 (Palácio, Rua das Butiques, loja, restaurante).
    # Inferência provisória: o livro não dá as cores de reboco, toldo ou louça.
    reboco=H('#CDBB94'), reboco_luz=H('#E2D3AE'), reboco_sombra=H('#A8977A'),
)
PASTA = 'assets/art/capitulo_01'


def _losango(ox):
    """Pixels do losango de 64×32 que começa em ox, com as coordenadas da
    grade: a anda para baixo e à direita (eixo x do mapa), b para baixo e à
    esquerda (eixo y); as duas vão de -0,5 a 0,5 dentro da casa."""
    for y in range(32):
        meia = 32 - abs(y - 15.5) * 2
        for x in range(int(32 - meia), int(32 + meia)):
            dx = x - 31.5; dy = y - 15.5
            a = (dx / 32 + dy / 16) / 2
            b = (dy / 16 - dx / 32) / 2
            yield ox + x, y, a, b


def _assoalho(q, ox, escuro):
    # tábuas ao longo do eixo x, emendas desencontradas
    for x, y, a, b in _losango(ox):
        faixa = int((b + 0.5) * 6)
        cor = 'assoalho_sombra' if escuro and faixa % 2 else 'assoalho'
        if abs(((b + 0.5) * 6) % 1) < 0.12:
            cor = 'assoalho_sombra'
        elif abs(((a + 0.5 + faixa * 0.37) * 2) % 1) < 0.04:
            cor = 'assoalho_sombra'
        elif (x * 7 + y * 3) % 23 == 0:
            cor = 'assoalho_luz'
        q.p(x, y, cor)


def _pedra(q, ox, variante):
    # lajes de pedra, duas por lado da casa
    for x, y, a, b in _losango(ox):
        la = int((a + 0.5) * 2); lb = int((b + 0.5) * 2)
        cor = ('pedra_piso', 'pedra_piso_luz', 'pedra_piso', 'pedra_piso_sombra')[(la + lb * 2 + variante) % 4]
        if abs(((a + 0.5) * 2) % 1) < 0.05 or abs(((b + 0.5) * 2) % 1) < 0.05:
            cor = 'argamassa'
        q.p(x, y, cor)


def _grama(q, ox, variante):
    # grama em tufos, com pontos de luz e sombra
    for x, y, a, b in _losango(ox):
        n = (x * 13 + y * 7 + variante * 5) % 17
        cor = 'grama'
        if n in (0, 5):
            cor = 'grama_luz'
        elif n in (3, 11):
            cor = 'grama_sombra'
        elif (x + variante * 3) % 9 == 0 and y % 3 == 0:
            cor = 'grama_luz'
        q.p(x, y, cor)


def _passadeira(q, ox, borda):
    # passadeira do corredor do prólogo: vermelha, treliça dourada fraca,
    # faixa azul com ornamentos creme e filetes dourados nas bordas
    for x, y, a, b in _losango(ox):
        d = None                                    # distância até a borda da passadeira
        if borda == 'cima':
            d = b + 0.5 - 0.22
        elif borda == 'baixo':
            d = 0.5 - 0.22 - b
        if d is not None and d < 0:
            cor = 'argamassa' if abs(((a + 0.5) * 2) % 1) < 0.05 else 'pedra_piso'
        elif d is not None and d < 0.03:
            cor = 'ouro'
        elif d is not None and d < 0.16:
            cor = 'tapete_azul'
            if abs(d - 0.095) < 0.03 and abs(((a + 0.5) * 4) % 1 - 0.5) < 0.16:
                cor = 'creme'
        elif d is not None and d < 0.19:
            cor = 'ouro_sombra'
        else:
            cor = 'tapete'
            if abs(((a * 4 + b * 4) % 1)) < 0.06 or abs(((a * 4 - b * 4) % 1)) < 0.06:
                cor = 'ouro_sombra'
        q.p(x, y, cor)


def _marmore(q, ox, variante):
    # lajes grandes de mármore claro, duas por lado da casa, com veios finos
    # (inferência: o livro só fala em "colunas, jardins, flores" no pátio)
    for x, y, a, b in _losango(ox):
        la = int((a + 0.5) * 2); lb = int((b + 0.5) * 2)
        cor = 'marmore' if (la + lb + variante) % 2 == 0 else 'marmore_luz'
        if abs(((a + 0.5) * 2) % 1) < 0.05 or abs(((b + 0.5) * 2) % 1) < 0.05:
            cor = 'marmore_sombra'
        elif (x * 5 + y * 11 + variante * 3) % 29 == 0:
            cor = 'marmore_sombra'
        q.p(x, y, cor)


def _calcada(q, ox, variante):
    # paralelepípedo: fileiras de pedras pequenas desencontradas
    for x, y, a, b in _losango(ox):
        fb = (b + 0.5) * 5
        linha = int(fb)
        fa = (a + 0.5) * 5 + (0.5 if (linha + variante) % 2 else 0)
        pedra = int(fa)
        cor = ('pedra_piso', 'pedra_piso_luz', 'pedra_piso', 'pedra_piso_sombra')[(pedra * 3 + linha * 5 + variante) % 4]
        if fb % 1 < 0.13 or fa % 1 < 0.13:
            cor = 'argamassa'
        q.p(x, y, cor)


def _ladrilho(q, ox, variante):
    # xadrez de ladrilhos creme e marrom-claro (inferência)
    for x, y, a, b in _losango(ox):
        la = int((a + 0.5) * 4); lb = int((b + 0.5) * 4)
        cor = 'creme' if (la + lb + variante) % 2 == 0 else 'assoalho_luz'
        if abs(((a + 0.5) * 4) % 1) < 0.04 or abs(((b + 0.5) * 4) % 1) < 0.04:
            cor = 'assoalho_sombra'
        q.p(x, y, cor)


def piso():
    # 0-1 assoalho dos quartos, 2-3 pedra, 4-6 passadeira (borda em cima,
    # borda embaixo, meio): como o castelo do prólogo; 7-8 grama (as margens
    # da rua por onde passa a carruagem)
    # 9-10 mármore claro do pátio do Palácio; 11-12 paralelepípedo da Rua das
    # Butiques; 13-14 ladrilho creme do restaurante (cenas 7 a 10)
    q = Q(64 * 15, 32)
    _assoalho(q, 0, False)
    _assoalho(q, 64, True)
    _pedra(q, 128, 0)
    _pedra(q, 192, 1)
    _passadeira(q, 256, 'cima')
    _passadeira(q, 320, 'baixo')
    _passadeira(q, 384, None)
    _grama(q, 448, 0)
    _grama(q, 512, 1)
    _marmore(q, 576, 0)
    _marmore(q, 640, 1)
    _calcada(q, 704, 0)
    _calcada(q, 768, 1)
    _ladrilho(q, 832, 0)
    _ladrilho(q, 896, 1)
    return q.im


def _topo(x):
    # altura onde a face da parede começa, na coluna x do bloco
    return 31.5 - abs(x - 31.5) / 2


def _parede_antiga(q, ox):
    for y in range(32):
        meia = 32 - abs(y - 15.5) * 2
        for x in range(int(32 - meia), int(32 + meia)):
            q.p(ox + x, y, 'parede_luz')
    for y in range(16, 64):
        for x in range(64):
            if _topo(x) <= y <= _topo(x) + 32:
                q.p(ox + x, y, 'parede' if x < 32 else 'parede_sombra')


def _parede_pedra(q, ox):
    # pedra clara em blocos, como as paredes do Castelo Olympia
    for y in range(32):
        meia = 32 - abs(y - 15.5) * 2
        for x in range(int(32 - meia), int(32 + meia)):
            borda = abs(y - 15.5) * 2 + 2 >= 32 - abs(x - 31.5)
            q.p(ox + x, y, 'pedra_parede_sombra' if borda else 'pedra_parede_luz')
    for x in range(64):
        esquerda = x < 32
        u = x if esquerda else 63 - x
        for y in range(16, 64):
            v = y - _topo(x)
            if not 0 <= v <= 32:
                continue
            fileira = int(v // 6)
            cor = 'pedra_parede' if esquerda else 'pedra_parede_sombra'
            if v % 6 < 1 or (u + fileira * 5) % 11 == 0:
                cor = 'argamassa'
            elif v > 29:
                cor = 'pedra_parede_sombra' if esquerda else 'argamassa'
            q.p(ox + x, y, cor)


def _parede_madeira(q, ox):
    # lambris escuro do interior da carruagem, com filete dourado
    for y in range(32):
        meia = 32 - abs(y - 15.5) * 2
        for x in range(int(32 - meia), int(32 + meia)):
            q.p(ox + x, y, 'madeira_sombra')
    for x in range(64):
        esquerda = x < 32
        u = x if esquerda else 63 - x
        for y in range(16, 64):
            v = y - _topo(x)
            if not 0 <= v <= 32:
                continue
            cor = 'madeira' if esquerda else 'madeira_sombra'
            if u % 8 == 0:
                cor = 'madeira_sombra'
            if abs(v - 14) < 1:
                cor = 'ouro_sombra'
            elif v > 14:
                cor = 'veludo' if esquerda else 'noite'                # forro de veludo azul
            q.p(ox + x, y, cor)


def _bloco(q, ox, topo, topo_borda, face):
    """Bloco de parede de 64×64: topo em losango e face(esquerda, u, v, x) para
    cada pixel da face (v = altura abaixo do topo, 0 a 32)."""
    for y in range(32):
        meia = 32 - abs(y - 15.5) * 2
        for x in range(int(32 - meia), int(32 + meia)):
            borda = abs(y - 15.5) * 2 + 2 >= 32 - abs(x - 31.5)
            q.p(ox + x, y, topo_borda if borda else topo)
    for x in range(64):
        esquerda = x < 32
        u = x if esquerda else 63 - x
        for y in range(16, 64):
            v = y - _topo(x)
            if 0 <= v <= 32:
                q.p(ox + x, y, face(esquerda, u, int(v), x))


def _parede_marmore(q, ox):
    # mármore claro em blocos grandes, com cornija e soco (Palácio Imperial;
    # inferência: o livro só diz "alto demais, amplo demais, ornamentado demais")
    def face(esq, u, v, x):
        fileira = v // 8
        cor = 'marmore' if esq else 'marmore_sombra'
        if v < 3:
            cor = 'marmore_luz' if esq else 'marmore'
        elif v % 8 == 3 or (u + fileira * 7) % 13 == 0:
            cor = 'prata_sombra'
        elif v > 29:
            cor = 'prata_sombra' if esq else 'pedra_parede_sombra'
        elif (x * 7 + v * 5) % 31 == 0:
            cor = 'marmore_luz' if esq else 'prata'
        return cor
    _bloco(q, ox, 'marmore_luz', 'marmore_sombra', face)


def _parede_fachada(q, ox):
    # fachada de reboco claro com beiral de madeira e soco de pedra
    # (inferência: o livro não descreve as fachadas da Rua das Butiques)
    def face(esq, u, v, x):
        cor = 'reboco' if esq else 'reboco_sombra'
        if v < 3:
            cor = 'madeira' if esq else 'madeira_sombra'
        elif v == 3:
            cor = 'madeira_sombra'
        elif v > 26:
            cor = 'pedra_parede' if esq else 'pedra_parede_sombra'
            if v == 27:
                cor = 'argamassa'
        elif (x * 7 + v * 13) % 17 == 0:
            cor = 'reboco_luz' if esq else 'reboco'
        return cor
    _bloco(q, ox, 'pedra_parede_sombra', 'argamassa', face)


def _parede_reboco(q, ox):
    # reboco quente por dentro, com lambri de madeira embaixo e filete dourado
    def face(esq, u, v, x):
        cor = 'reboco' if esq else 'reboco_sombra'
        if v < 2:
            cor = 'reboco_luz' if esq else 'reboco'
        elif v == 16:
            cor = 'ouro_sombra'
        elif v > 16:
            cor = 'madeira' if esq else 'madeira_sombra'
            if u % 8 == 0:
                cor = 'madeira_sombra'
            elif v == 17:
                cor = 'madeira_luz' if esq else 'madeira'
        elif (x * 11 + v * 7) % 19 == 0:
            cor = 'reboco_luz' if esq else 'reboco'
        return cor
    _bloco(q, ox, 'reboco_luz', 'reboco', face)


def parede():
    # bloco de 64×64: topo em losango de 64×32 e a face embaixo
    # 0 = pedra da Casa Olympia; 1 = a parede lisa do sonho (corredor
    # estranho); 2 = madeira e veludo, por dentro da carruagem
    # 3 = mármore do Palácio Imperial; 4 = fachada de reboco da Rua das
    # Butiques; 5 = reboco por dentro, com lambri (loja e restaurante)
    q = Q(384, 64)
    _parede_pedra(q, 0)
    _parede_antiga(q, 64)
    _parede_madeira(q, 128)
    _parede_marmore(q, 192)
    _parede_fachada(q, 256)
    _parede_reboco(q, 320)
    return q.im


# --- coisas penduradas nas paredes --------------------------------------
# Cada uma é um bloco de 64×64 transparente, alinhado ao bloco da parede,
# com o desenho na face da esquerda (paredes da linha y = 0) ou da direita
# (coluna x = 0), inclinado como a face.

def na_face(plano, lado, u0, v0):
    q = Q(64, 64)
    largura, altura = plano.size
    px = plano.load()
    for i in range(largura):
        x = u0 + i if lado == 'esq' else 63 - u0 - (largura - 1 - i)
        topo = int(round(_topo(x)))
        for j in range(altura):
            cor = px[i, j]
            if cor[3] and 0 <= x < 64 and 0 <= topo + v0 + j < 64:
                q.px[x, topo + v0 + j] = cor
    return q.im


def tocha():
    q = Q(9, 18)
    q.r(3, 10, 5, 17, 'ferro')                      # suporte de ferro
    q.r(2, 15, 6, 15, 'ferro_luz')
    q.r(3, 8, 5, 10, 'madeira')                     # tocha
    q.elipse(4, 4, 2, 3, 'vela_escura')             # chama visível
    q.elipse(4, 5, 1, 2, 'vela')
    q.p(4, 5, 'ouro_luz'); q.p(4, 0, 'vela_escura')
    return q.im


def arandela():
    q = Q(7, 14)
    q.r(1, 11, 5, 12, 'ouro_sombra'); q.r(3, 9, 3, 13, 'ouro')
    q.r(2, 6, 4, 10, 'perola')                      # vela
    q.elipse(3, 3, 1, 2, 'vela'); q.p(3, 3, 'ouro_luz'); q.p(3, 0, 'vela_escura')
    return q.im


MAPA = 'assets/art/mapa/mapa_helade.png'
# Os mesmos recortes do mapa usados nos quadros do prólogo
# (tools/arte/gerar_quadros_prologo.py).
RECORTES = {
    'olympia': (600, 900, 960, 1170),
    'atenas': (250, 565, 610, 835),
    'norte': (230, 150, 710, 510),
}


def quadro(nome):
    from PIL import Image
    tela = Image.open(MAPA).convert('RGBA').crop(RECORTES[nome]).resize((14, 10), Image.BOX)
    q = Q(18, 14)
    q.r(0, 0, 17, 13, 'ouro'); q.r(0, 13, 17, 13, 'ouro_sombra'); q.r(17, 0, 17, 13, 'ouro_sombra')
    q.r(0, 0, 17, 0, 'ouro_luz')
    q.im.paste(tela, (2, 2))
    return q.im


def tapecaria():
    q = Q(14, 24)
    q.r(0, 0, 13, 0, 'ferro')                       # varão
    q.r(1, 1, 12, 22, 'tapete')
    q.r(1, 1, 12, 2, 'tapete_azul'); q.r(1, 20, 12, 22, 'tapete_azul')
    q.r(1, 1, 2, 22, 'tapete_azul'); q.r(11, 1, 12, 22, 'tapete_azul')
    for y in (3, 19):
        q.linha(y, 3, 10, 'ouro')
    q.elipse(6, 11, 3, 4, 'ouro_sombra'); q.elipse(6, 11, 2, 3, 'tapete_azul')
    q.p(6, 11, 'creme'); q.p(6, 8, 'creme'); q.p(6, 14, 'creme')
    for x in range(2, 12, 2):
        q.p(x, 23, 'ouro')                          # franja
    return q.im


def espada_placa():
    # espada deitada sobre uma placa de madeira, sem brasão (como no prólogo)
    q = Q(26, 7)
    q.r(0, 0, 25, 6, 'madeira'); q.r(0, 6, 25, 6, 'madeira_sombra'); q.r(0, 0, 25, 0, 'madeira_luz')
    q.r(9, 3, 23, 3, 'ferro_luz'); q.r(9, 4, 22, 4, 'ferro'); q.p(24, 3, 'ferro_luz')   # lâmina
    q.r(8, 1, 8, 5, 'ouro')                         # guarda
    q.r(4, 3, 7, 4, 'madeira_sombra')               # punho
    q.r(2, 3, 3, 4, 'ouro_sombra')                  # pomo
    return q.im


def cama(com_althea, dossel=False, sentada=False):
    # cama de madeira com colunas e pinhas na cabeceira e coberta azul, como
    # a de Nicholas no prólogo; com dossel azul-escuro, como a da duquesa
    alto = 22 if dossel else 0
    q = Q(48, 34 + alto)
    y = alto
    q.sombra_no_chao(24, 31 + y, 22, 3)
    if dossel:
        for x in (3, 43):                           # colunas do dossel
            q.r(x, 2, x + 1, 30 + y, 'madeira_luz')
        q.r(1, 0, 46, 4, 'veludo')                  # dossel
        q.r(1, 5, 46, 7, 'veludo_luz')              # sanefa
        q.linha(7, 1, 46, 'ouro_sombra')
        q.r(0, 0, 3, 26, 'veludo'); q.r(44, 0, 47, 26, 'veludo')   # cortinas presas
        q.coluna(1, 2, 25, 'veludo_luz'); q.coluna(46, 2, 25, 'veludo_luz')
    q.r(3, 10 + y, 44, 30 + y, 'madeira')                   # estrado
    q.r(3, 10 + y, 5, 30 + y, 'madeira_sombra')
    q.r(4, 2 + y, 12, 12 + y, 'madeira_luz')                # cabeceira
    for x in (4, 12):                                       # colunas com pinhas
        q.r(x, 0 + y, x, 12 + y, 'madeira_sombra')
        q.p(x, y, 'madeira_luz')
    q.r(7, 12 + y, 44, 24 + y, 'lencol')                    # colchão
    q.r(9, 13 + y, 16, 17 + y, 'perola')                    # travesseiro
    q.r(18, 14 + y, 44, 26 + y, 'colcha')                   # coberta azul
    q.linha(14 + y, 18, 44, 'colcha_luz')
    if com_althea:
        q.elipse(13, 15 + y, 3, 3, 'cab_althea')            # cabeça no travesseiro
        q.p(12, 13 + y, 'cab_althea_luz'); q.p(14, 13 + y, 'cab_althea_luz')
        q.r(16, 15 + y, 21, 18 + y, 'monstro')              # a pelúcia abraçada
        q.p(21, 15 + y, 'monstro_luz'); q.p(18, 15 + y, 'monstro_luz')
        q.r(19, 17 + y, 34, 22 + y, 'colcha_luz')           # volume do corpo sob a colcha
    if sentada:
        # Althea sentada na beira da cama, abaixo do dossel, com a pelúcia,
        # antes de pular para o chão
        q.r(7, 12 + y, 44, 24 + y, 'lencol'); q.r(9, 13 + y, 16, 17 + y, 'perola')
        q.r(18, 14 + y, 44, 26 + y, 'colcha'); q.linha(14 + y, 18, 44, 'colcha_luz')
        x = 30
        q.r(x - 3, 9 + y, x + 3, 18 + y, 'vestido_althea')            # camisola
        q.r(x - 2, 19 + y, x - 1, 27 + y, 'pele'); q.r(x + 1, 19 + y, x + 2, 27 + y, 'pele')   # pernas para fora
        q.elipse(x, 5 + y, 3, 3, 'pele_luz')                           # rosto
        q.r(x - 3, 1 + y, x + 3, 3 + y, 'cab_althea')                  # cabelo curto
        q.r(x - 3, 3 + y, x - 3, 7 + y, 'cab_althea'); q.r(x + 3, 3 + y, x + 3, 7 + y, 'cab_althea')
        q.p(x - 1, 5 + y, 'azul'); q.p(x + 1, 5 + y, 'azul')
        q.r(x + 3, 12 + y, x + 7, 15 + y, 'monstro'); q.p(x + 6, 12 + y, 'monstro_luz')
    q.r(42, 12 + y, 45, 30 + y, 'madeira_luz')              # pé da cama
    return q.contornar()


# --- móveis em caixa isométrica ------------------------------------------
# Desenhados na mesma projeção do chão (a anda para baixo e à direita, b para
# baixo e à esquerda, de -0,5 a 0,5 dentro da casa), para acompanharem as
# paredes. O centro da casa fica a PE_CAIXA pixels da base da imagem
# (SalaMontada.adicionar_objeto(..., pe)).
PE_CAIXA = 17


def _tela(a, b, z, oy):
    return (32 + 32 * (a - b), oy + 16 * (a + b) - z)


def caixa_iso(a0, a1, b0, b1, h, frente, lado, topo):
    from PIL import ImageDraw
    largura, altura = 64, h + 34
    oy = h + 17
    q = Q(largura, altura)
    d = ImageDraw.Draw(q.im)
    t = lambda a, b, z: _tela(a, b, z, oy)
    d.polygon([t(a0, b1, 0), t(a1, b1, 0), t(a1, b1, h), t(a0, b1, h)], fill=C[frente])
    d.polygon([t(a1, b0, 0), t(a1, b1, 0), t(a1, b1, h), t(a1, b0, h)], fill=C[lado])
    d.polygon([t(a0, b0, h), t(a1, b0, h), t(a1, b1, h), t(a0, b1, h)], fill=C[topo])
    q.px = q.im.load()

    def na_frente_b(s_, t_, cor):         # face de frente para +b (paredes da linha y = 0)
        x, y = t(a0 + s_ * (a1 - a0), b1, t_ * h)
        q.p(int(round(x)), int(round(y)), cor)

    def na_frente_a(s_, t_, cor):         # face de frente para +a (paredes da coluna x = 0)
        x, y = t(a1, b0 + s_ * (b1 - b0), t_ * h)
        q.p(int(round(x)), int(round(y)), cor)
    return q, na_frente_b, na_frente_a


def _riscar(ponto, s0, s1, t0, t1, cor, passos=60):
    for i in range(passos + 1):
        k = i / passos
        ponto(s0 + (s1 - s0) * k, t0 + (t1 - t0) * k, cor)


def armario():
    # armário de duas portas encostado na parede do fundo (linha y = 0),
    # com as portas viradas para o quarto
    q, frente, _ = caixa_iso(-0.42, 0.42, -0.5, -0.12, 44, 'madeira', 'madeira_sombra', 'madeira_luz')
    _riscar(frente, 0.5, 0.5, 0.04, 0.92, 'madeira_sombra')            # fresta entre as portas
    for s0, s1 in ((0.1, 0.42), (0.58, 0.9)):                          # almofadas das portas
        for t0, t1 in ((0.52, 0.86), (0.1, 0.44)):
            _riscar(frente, s0, s1, t0, t0, 'madeira_luz'); _riscar(frente, s0, s1, t1, t1, 'madeira_luz')
            _riscar(frente, s0, s0, t0, t1, 'madeira_luz'); _riscar(frente, s1, s1, t0, t1, 'madeira_luz')
    _riscar(frente, 0.0, 1.0, 0.95, 0.95, 'madeira_luz')               # remate
    for s_ in (0.46, 0.54):
        frente(s_, 0.48, 'ouro')                                       # puxadores
    return q.contornar()


def bau():
    # baú encostado na parede da esquerda (coluna x = 0), virado para o quarto
    q, _, frente = caixa_iso(-0.5, -0.05, -0.36, 0.36, 13, 'madeira_sombra', 'madeira', 'madeira_luz')
    _riscar(frente, 0.0, 1.0, 0.62, 0.62, 'madeira_sombra')            # tampa
    for s_ in (0.2, 0.8):                                              # cintas de bronze
        _riscar(frente, s_, s_, 0.0, 1.0, 'ouro_sombra', 20)
    frente(0.5, 0.5, 'ouro'); frente(0.5, 0.45, 'ouro'); frente(0.52, 0.5, 'ouro')   # fechadura
    return q.contornar()


def banco_carruagem():
    # assento de veludo azul encostado no fundo da carruagem (linha y = 0)
    q, frente, _ = caixa_iso(-0.5, 0.5, -0.5, -0.05, 9, 'veludo', 'noite', 'veludo_luz')
    _riscar(frente, 0.0, 1.0, 0.9, 0.9, 'ouro_sombra')
    return q.contornar()


def janela_carruagem():
    # janela com cortina presa e a rua de Atenas de manhã
    q = Q(18, 14)
    q.r(0, 0, 17, 13, 'ouro_sombra')
    q.r(2, 2, 15, 11, 'vidro_luz')
    q.r(2, 7, 5, 11, 'pedra_parede'); q.r(6, 5, 9, 11, 'pedra_parede_luz'); q.r(10, 8, 15, 11, 'pedra_parede')
    q.r(7, 3, 8, 4, 'pedra_parede_luz')
    q.r(2, 2, 3, 11, 'veludo_luz'); q.r(14, 2, 15, 11, 'veludo_luz')
    return q.im


def janela_alta():
    # janela alta em arco, com o céu do amanhecer e a faixa dourada (o livro:
    # "uma faixa dourada começou a surgir no horizonte, avançando pelas
    # janelas"); nas duas pontas do corredor
    q = Q(16, 34)
    q.r(0, 4, 15, 33, 'pedra_parede_sombra')
    q.r(1, 2, 14, 3, 'pedra_parede_sombra'); q.r(3, 0, 12, 1, 'pedra_parede_sombra')
    ceu = ('veludo', 'veludo_luz', 'veludo_luz', 'vidro', 'vidro', 'vidro_luz', 'ouro_luz', 'ouro', 'ouro_sombra')
    for y in range(2, 32):
        cor = ceu[min(len(ceu) - 1, (y - 2) * len(ceu) // 30)]
        x0 = 2 if y > 4 else 4
        q.r(x0, y, 15 - x0, y, cor)
    q.coluna(7, 2, 31, 'pedra_parede_sombra'); q.coluna(8, 2, 31, 'pedra_parede_sombra')
    q.linha(16, 2, 13, 'pedra_parede_sombra')
    q.r(0, 32, 15, 33, 'pedra_parede_luz')
    return q.im


def porta_na_parede():
    # porta fechada desenhada na face da parede
    q = Q(14, 26)
    q.r(0, 0, 13, 25, 'madeira_sombra')
    q.r(2, 2, 11, 25, 'madeira')
    q.r(3, 4, 6, 12, 'madeira_luz'); q.r(8, 4, 10, 12, 'madeira_luz')
    q.r(3, 15, 6, 23, 'madeira_luz'); q.r(8, 15, 10, 23, 'madeira_luz')
    q.p(10, 14, 'ouro')
    return q.im


def espelho():
    # grande demais para o quarto
    q = Q(22, 44)
    q.sombra_no_chao(11, 41, 9, 2)
    q.r(2, 2, 19, 40, 'ouro')
    q.r(2, 2, 3, 40, 'ouro_sombra')
    q.r(5, 5, 16, 37, 'vidro')
    for i in range(6):
        q.p(13 - i, 8 + i * 2, 'vidro_luz'); q.p(14 - i, 8 + i * 2, 'vidro_luz')
    q.linha(1, 6, 15, 'ouro_luz')
    q.r(4, 40, 6, 42, 'ouro_sombra'); q.r(15, 40, 17, 42, 'ouro_sombra')
    return q.contornar()


def porta(aberta):
    q = Q(30, 46)
    q.r(1, 2, 28, 45, 'madeira_sombra')             # batente
    q.linha(2, 1, 28, 'ouro')
    if aberta:
        q.r(4, 5, 25, 45, 'noite')
        q.r(4, 5, 8, 45, 'madeira')                 # folha aberta, de lado
        q.r(9, 40, 25, 45, 'vela')                  # luz do outro lado
    else:
        q.r(4, 5, 25, 45, 'madeira')
        q.r(6, 7, 13, 22, 'madeira_luz'); q.r(16, 7, 23, 22, 'madeira_luz')
        q.r(6, 26, 13, 42, 'madeira_luz'); q.r(16, 26, 23, 42, 'madeira_luz')
        q.r(21, 24, 22, 25, 'ouro')                 # maçaneta
    return q.contornar()


def mesa_cha():
    q = Q(34, 24)
    q.sombra_no_chao(17, 21, 15, 2)
    q.elipse(17, 9, 15, 5, 'madeira_luz')
    q.elipse(17, 10, 15, 5, 'madeira')
    q.elipse(17, 9, 14, 4, 'madeira_luz')
    q.r(5, 11, 6, 21, 'madeira_sombra'); q.r(28, 11, 29, 21, 'madeira_sombra')
    q.r(16, 13, 18, 21, 'madeira')
    for (x, y) in ((11, 7), (22, 8)):               # xícaras
        q.r(x, y, x + 2, y + 1, 'perola'); q.p(x + 3, y, 'perola')
    return q.contornar()


def carrinho_bolo():
    q = Q(32, 44)
    q.sombra_no_chao(16, 41, 14, 2)
    q.r(3, 32, 28, 34, 'madeira_luz')               # tampo do carrinho
    q.r(4, 35, 5, 41, 'madeira_sombra'); q.r(26, 35, 27, 41, 'madeira_sombra')
    q.elipse(5, 41, 2, 2, 'ouro_sombra'); q.elipse(26, 41, 2, 2, 'ouro_sombra')
    # bolo azul de três andares com pérolas de açúcar
    for (x0, x1, y0, y1) in ((6, 25, 24, 31), (9, 22, 17, 23), (12, 19, 11, 16)):
        q.r(x0, y0, x1, y1, 'bolo')
        q.r(x0, y0, x0 + 1, y1, 'bolo_sombra')
        q.linha(y0, x0, x1, 'bolo_luz')
        for x in range(x0 + 1, x1, 3):
            q.p(x, y1, 'perola')
    for x in (12, 13, 15, 16, 18, 19):              # seis velas
        q.r(x, 6, x, 10, 'perola')
    return q.contornar()


def velas_acesas(im):
    # o mesmo bolo com as chamas
    q = Q(32, 44)
    q.im = im.copy(); q.px = q.im.load()
    for x in (12, 13, 15, 16, 18, 19):
        q.p(x, 4, 'vela'); q.p(x, 5, 'ouro_luz')
    return q.im


def embrulho():
    q = Q(10, 30)
    q.sombra_no_chao(5, 28, 4, 1)
    q.r(2, 1, 7, 28, 'embrulho')
    q.r(2, 1, 3, 28, 'embrulho')
    q.r(5, 1, 6, 28, 'embrulho_luz')
    q.linha(10, 2, 7, 'ouro'); q.p(4, 9, 'ouro_luz'); q.p(5, 9, 'ouro_luz')
    return q.contornar()


def pany():
    # governanta da mansão em Atenas; aparência não descrita no livro
    q = Q(32, 48)
    q.sombra_no_chao(16, 45, 8, 2)
    x = 16
    for y in range(18, 45):
        meia = 5 + (y - 18) // 5
        q.linha(y, x - meia, x + meia - 1, 'pany_vestido')
        q.p(x - meia, y, 'noite')
    q.linha(44, x - 10, x + 9, 'noite')
    q.r(x - 3, 26, x + 2, 41, 'prata'); q.coluna(x - 3, 26, 41, 'prata_sombra')   # avental
    q.r(x - 5, 17, x + 4, 25, 'pany_vestido'); q.r(x - 5, 17, x - 4, 25, 'noite')
    q.r(x - 7, 18, x - 6, 27, 'pany_vestido'); q.r(x - 7, 28, x - 6, 29, 'pele')
    q.r(x + 5, 18, x + 6, 27, 'pany_vestido'); q.r(x + 5, 28, x + 6, 29, 'pele')
    q.r(x - 2, 16, x + 2, 17, 'prata')
    q.r(x + 4, 26, x + 5, 28, 'ouro')                        # chaves na cintura
    q.r(x - 3, 8, x + 3, 15, 'pele'); q.coluna(x - 3, 8, 15, 'pele_sombra')
    q.p(x - 1, 11, 'olho_escuro'); q.p(x + 2, 11, 'olho_escuro'); q.p(x + 1, 13, 'pele_sombra')
    q.r(x - 4, 4, x + 4, 7, 'prata_sombra'); q.r(x - 4, 7, x - 4, 11, 'prata_sombra')  # cabelo grisalho preso
    q.elipse(x, 3, 3, 2, 'prata_sombra')
    q.r(x - 2, 4, x + 1, 4, 'prata')
    return q.contornar()


def garota_visao():
    # vista de costas, quase uma sombra no corredor quente do sonho; mais
    # baixa que Nicholas, cabelos longos e ondulados até a cintura
    q = Q(32, 48)
    x = 16
    for y in range(24, 45):                                  # saia
        meia = 4 + (y - 24) // 4
        q.linha(y, x - meia, x + meia - 1, 'silhueta')
    q.r(x - 4, 19, x + 3, 25, 'silhueta')                    # tronco
    q.r(x - 6, 20, x - 5, 30, 'silhueta'); q.r(x + 4, 20, x + 5, 30, 'silhueta')   # braços
    q.elipse(x, 13, 4, 5, 'silhueta_luz')                    # cabeça
    q.r(x - 4, 14, x + 3, 29, 'silhueta_luz')                # cabelo descendo pelas costas
    for y in range(16, 29, 3):
        q.p(x - 2 + (y % 2), y, 'silhueta'); q.p(x + 1, y + 1, 'silhueta')
    for xx in range(x - 4, x + 4, 2):
        q.p(xx, 30, 'silhueta_luz')
    return q.contornar()


def garota_visao_frente():
    # a mesma garota quando se vira para Nicholas (Rafael, 17/10/2026): ainda
    # quase uma sombra, sem rosto definido (o livro não a descreve), só o
    # contorno do rosto entre os cabelos longos que caem pelos ombros
    q = Q(32, 48)
    x = 16
    for y in range(24, 45):                                  # saia
        meia = 4 + (y - 24) // 4
        q.linha(y, x - meia, x + meia - 1, 'silhueta')
    q.r(x - 4, 19, x + 3, 25, 'silhueta')                    # tronco
    q.r(x - 6, 20, x - 5, 30, 'silhueta'); q.r(x + 4, 20, x + 5, 30, 'silhueta')   # braços
    q.r(x - 5, 11, x - 4, 27, 'silhueta_luz'); q.r(x + 3, 11, x + 4, 27, 'silhueta_luz')  # cabelo nos ombros
    q.elipse(x, 13, 4, 5, 'silhueta_luz')                    # cabelo em volta do rosto
    q.elipse(x, 14, 2, 3, 'silhueta')                        # rosto na sombra
    for y in range(16, 27, 3):
        q.p(x - 5 + (y % 2), y, 'silhueta'); q.p(x + 4, y + 1, 'silhueta')
    return q.contornar()


# --- carruagem por fora, em corte (Rafael, 15/10/2026: a sala de paredes
# grossas não parecia um veículo; depois: inspirar nas carruagens antigas,
# gregas, romanas e medievais, e pôr os animais de tração). Caixa baixa de
# madeira com friso grego dourado, cobertura em arco de tecido sobre arcos de
# madeira (como o carpentum romano e a carruagem medieval), rodas grandes
# raiadas, varal, dois cavalos e o cocheiro no banco da frente (o livro cita o
# cocheiro). Parede da frente e metade da cobertura "cortadas" para ver
# Nicholas e Althea no banco.
# Duas imagens com a mesma origem: o fundo (rodas de trás, chão, paredes do
# fundo e da esquerda, cobertura, banco) e a frente (borda baixa, rodas da
# frente, cavalos e cocheiro, três quadros: rodas girando e cavalos a trote).
# A origem (CARRO_O) é o centro da carruagem no chão; o jogo usa a mesma conta
# (Capitulo01.ponto_carruagem). Tudo provisório: o livro não descreve a
# carruagem nem os cavalos.
import math
CARRO_W, CARRO_H = 420, 216
CARRO_O = (150, 128)
CARRO_A, CARRO_B = 1.5, 0.8          # meio comprimento e meia largura, em casas
CARRO_CHAO, CARRO_TOPO, CARRO_BORDA = 18, 58, 34
CARRO_ARCO = 22                      # altura do arco da cobertura acima do topo
CARRO_RAIO, CARRO_EIXO = 15, 15
CASA = 35.8                          # pixels de uma casa ao longo de um eixo
C.update(
    carro=H('#3A2418'), carro_luz=H('#5A3A26'), carro_sombra=H('#24160F'),
    lambris=H('#2E1C14'), lambris_luz=H('#4A2E20'), roda=H('#1E1410'),
    lona=H('#1B2A4C'), lona_luz=H('#2C3F68'), lona_sombra=H('#111B33'),
    cavalo=H('#D9D2C6'), cavalo_luz=H('#F0EBE2'), cavalo_sombra=H('#A79E92'),
    cavalo2=H('#B9B0A3'), cavalo2_sombra=H('#8A8277'),
    crina=H('#6E665C'), couro=H('#4A2A1A'),
    cocheiro=H('#2A2F3A'), cocheiro_luz=H('#3E4656'), pele_cocheiro=H('#D8A882'),
)


def _carro_t(a, b, h):
    return (CARRO_O[0] + 32 * (a - b), CARRO_O[1] + 16 * (a + b) - h)


def _carro_quad(d, pts, cor):
    d.polygon([_carro_t(*p) for p in pts], fill=C[cor])


def _perfil(a0, b, pontos):
    """Pontos (u, v) de um desenho de perfil num plano vertical ao longo de a:
    u em pixels para a frente (+a), v em pixels para cima."""
    return [_carro_t(a0 + u / CASA, b, v) for u, v in pontos]


def _elipse_perfil(a0, b, cu, cv, ru, rv, n=24):
    return _perfil(a0, b, [(cu + ru * math.cos(k * 2 * math.pi / n), cv + rv * math.sin(k * 2 * math.pi / n))
                           for k in range(n)])


def _roda(d, a_c, b, giro):
    """Roda num plano vertical ao longo de a (lado da carruagem)."""
    r = CARRO_RAIO
    def ponto(ang, raio):
        return _carro_t(a_c + raio * math.cos(ang) / CASA, b, CARRO_EIXO + raio * math.sin(ang))
    aro = [ponto(k * math.pi / 16, r) for k in range(32)]
    d.polygon(aro, fill=C['roda'])
    d.polygon([ponto(k * math.pi / 16, r - 1.5) for k in range(32)], fill=C['carro_luz'])
    d.polygon([ponto(k * math.pi / 16, r - 3) for k in range(32)], fill=C['carro_sombra'])
    for k in range(8):
        ang = giro + k * math.pi / 4
        d.line([ponto(ang, 2), ponto(ang, r - 2)], fill=C['carro_luz'], width=1)
    cx, cy = ponto(0, 0)
    d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=C['ouro'])
    d.polygon(aro, outline=C['contorno'])


def _arco_h(b):
    """Altura da cobertura em arco sobre a largura da carruagem."""
    k = max(0.0, 1 - (b / CARRO_B) ** 2)
    return CARRO_TOPO + CARRO_ARCO * math.sqrt(k)


def _friso_grego(d, b, a0, a1, h0):
    """Friso grego (meandro) dourado ao longo da borda, no plano b."""
    passo = 7
    u = 0.0
    comp = (a1 - a0) * CASA
    while u + passo <= comp:
        pts = [(u, h0), (u, h0 + 5), (u + 4, h0 + 5), (u + 4, h0 + 2), (u + 2, h0 + 2)]
        d.line(_perfil(a0, b, pts), fill=C['ouro'], width=1)
        u += passo
    d.line(_perfil(a0, b, [(0, h0 - 2), (comp, h0 - 2)]), fill=C['ouro_sombra'])
    d.line(_perfil(a0, b, [(0, h0 + 7), (comp, h0 + 7)]), fill=C['ouro_sombra'])


def carruagem_fundo():
    from PIL import ImageDraw
    q = Q(CARRO_W, CARRO_H)
    d = ImageDraw.Draw(q.im)
    A, B = CARRO_A, CARRO_B
    ch, tp = CARRO_CHAO, CARRO_TOPO
    # rodas do outro lado (quase escondidas pela caixa)
    _roda(d, -0.95, -B - 0.06, 0.3)
    _roda(d, 1.0, -B - 0.06, 0.3)
    # metade de trás da cobertura em arco: tecido azul-escuro sobre arcos
    for i in range(24):
        b0 = -B + i * B / 24
        b1 = -B + (i + 1) * B / 24
        cor = 'lona_luz' if i % 6 in (0, 1) else 'lona'
        _carro_quad(d, [(-A, b0, _arco_h(b0)), (A, b0, _arco_h(b0)), (A, b1, _arco_h(b1)), (-A, b1, _arco_h(b1))], cor)
    for a in (-A, -0.5, 0.5, A):
        d.line([_carro_t(a, -B + i * B / 24, _arco_h(-B + i * B / 24)) for i in range(25)],
               fill=C['carro_luz'], width=2)
    d.line([_carro_t(-A, 0, _arco_h(0)), _carro_t(A, 0, _arco_h(0))], fill=C['ouro_sombra'])
    # ponta da esquerda da cobertura (o pano fecha o arco)
    d.polygon([_carro_t(-A, -B + i * B / 24, _arco_h(-B + i * B / 24)) for i in range(25)]
              + [_carro_t(-A, 0, tp), _carro_t(-A, -B, tp)], fill=C['lona_sombra'])
    # chão de tábuas
    _carro_quad(d, [(-A, -B, ch), (A, -B, ch), (A, B, ch), (-A, B, ch)], 'carro_luz')
    for k in range(1, 6):
        b = -B + k * 2 * B / 6
        d.line([_carro_t(-A, b, ch), _carro_t(A, b, ch)], fill=C['carro'])
    # parede do fundo (b = -B) e da esquerda (a = -A), de dentro, finas
    _carro_quad(d, [(-A, -B, ch), (A, -B, ch), (A, -B, tp), (-A, -B, tp)], 'lambris')
    _carro_quad(d, [(-A, -B, ch), (-A, B, ch), (-A, B, tp), (-A, -B, tp)], 'lambris_luz')
    d.line([_carro_t(-A, -B, tp), _carro_t(A, -B, tp)], fill=C['ouro'])
    d.line([_carro_t(-A, -B, tp), _carro_t(-A, B, tp)], fill=C['ouro'])
    # janelas abertas com cortina presa
    for a0, a1 in ((-1.15, -0.55), (0.55, 1.15)):
        _carro_quad(d, [(a0, -B, ch + 22), (a1, -B, ch + 22), (a1, -B, tp - 5), (a0, -B, tp - 5)], 'vidro_luz')
        _carro_quad(d, [(a0, -B, ch + 22), (a0 + 0.12, -B, ch + 22), (a0 + 0.12, -B, tp - 5), (a0, -B, tp - 5)], 'veludo_luz')
    _carro_quad(d, [(-A, -0.3, ch + 22), (-A, 0.3, ch + 22), (-A, 0.3, tp - 5), (-A, -0.3, tp - 5)], 'vidro')
    _carro_quad(d, [(-A, 0.18, ch + 22), (-A, 0.3, ch + 22), (-A, 0.3, tp - 5), (-A, 0.18, tp - 5)], 'veludo_luz')
    # banco de veludo encostado no fundo: assento e encosto
    s0, s1, sa = -B, -B + 0.42, ch + 12
    _carro_quad(d, [(-A, s1, ch), (A, s1, ch), (A, s1, sa), (-A, s1, sa)], 'lona_luz')
    _carro_quad(d, [(-A, s0, sa), (A, s0, sa), (A, s1, sa), (-A, s1, sa)], 'bolo_sombra')
    _carro_quad(d, [(-A, s0, sa), (A, s0, sa), (A, s0, sa + 14), (-A, s0, sa + 14)], 'lona_luz')
    d.line([_carro_t(-A, s1, sa), _carro_t(A, s1, sa)], fill=C['ouro_sombra'])
    return q.im


def _camada(im, desenhar, luz=1.0):
    """Desenha numa camada à parte, clareia ou escurece e cola em im."""
    from PIL import Image, ImageDraw, ImageEnhance
    t = Image.new('RGBA', im.size, (0, 0, 0, 0))
    desenhar(ImageDraw.Draw(t))
    if luz != 1.0:
        r, g, b, a = t.split()
        rgb = ImageEnhance.Brightness(Image.merge('RGB', (r, g, b))).enhance(luz)
        t = Image.merge('RGBA', (*rgb.split(), a))
    im.alpha_composite(t)


def _volume(im, b, meia, desenhar, camadas=6, luz_topo=1.18, luz_fundo=0.62):
    """Dá volume a um desenho de perfil (Rafael, 16/10/2026: os cavalos e o
    cocheiro pareciam 2D chapados): repete o perfil em planos de b - meia a
    b + meia. O plano de trás sai escuro (o contorno), os do meio claros (o
    dorso que a luz de cima pega) e o da frente com as cores normais."""
    for k in range(camadas):
        bk = b - meia + 2 * meia * k / (camadas - 1)
        luz = luz_fundo if k == 0 else (1.0 if k == camadas - 1 else luz_topo)
        _camada(im, lambda d, bk=bk: desenhar(d, bk), luz)


def _sombra_no_chao(im, a0, b, ru, rb):
    from PIL import ImageDraw
    pts = [_carro_t(a0 + ru * math.cos(t * math.pi / 12), b + rb * math.sin(t * math.pi / 12), 0)
           for t in range(24)]
    _camada(im, lambda d: d.polygon(pts, fill=(10, 14, 8, 90)))


def _cavalo(im, a0, b, quadro, claro):
    """Cavalo a trote, virado para +a; a0 = meio do corpo. Corpo com volume
    (vários planos), pernas de cada lado no seu plano, cabeça que balança no
    trote, crina e cauda soltas, antolhos e arreio com fivelas douradas."""
    E = 1.45                       # cavalo maior que o desenho-base
    def _pc(bb, pts, sobe=0.0):
        return _perfil(a0, bb, [(u * E, (v + sobe) * E) for u, v in pts])
    pele, sombra = ('cavalo', 'cavalo_sombra') if claro else ('cavalo2', 'cavalo2_sombra')
    luz = 'cavalo_luz' if claro else 'cavalo'
    meia = 0.16                    # meia largura do corpo, em casas
    passo = (-3, 0, 3)[quadro]
    sobe = (0.0, 1.0, 0.0)[quadro]          # o corpo sobe no meio do trote
    cabeca = (0.0, -1.0, 1.0)[quadro]       # e a cabeça balança
    # pernas: as do lado de lá no plano de trás, as de cá no da frente
    pernas = [(-11, passo, -1), (-7, -passo, 1), (9, -passo, -1), (13, passo, 1)]
    def perna(d, bb, u, dx):
        cor = sombra if bb < b else pele
        d.line(_pc(bb, [(u, 20), (u + dx * 0.5, 9), (u + dx, 1)], sobe * 0.5), fill=C[cor], width=4)
        d.line(_pc(bb, [(u + dx * 0.5 - 1, 9), (u + dx * 0.5 + 1, 9)]), fill=C['cavalo_sombra'], width=2)
        d.line(_pc(bb, [(u + dx - 1, 0), (u + dx + 1, 0)]), fill=C['roda'], width=2)
    for u, dx, lado in pernas:
        if lado < 0:
            _camada(im, lambda d, u=u, dx=dx: perna(d, b - meia * 0.6, u, dx), 0.85)
    # cauda (balança com o trote) no plano do meio
    rabo = (-1, 1, 0)[quadro]
    _camada(im, lambda d: d.polygon(_pc(b, [(-16, 27), (-19 + rabo, 24), (-22 + rabo, 11),
                                            (-18 + rabo, 12), (-15, 23)], sobe), fill=C['crina']))
    # corpo, pescoço e cabeça com volume
    def corpo(d, bb):
        d.polygon(_elipse_perfil(a0, bb, 0, (24 + sobe) * E, 17 * E, 7.5 * E), fill=C[pele])
        d.polygon(_elipse_perfil(a0, bb, 0, (21 + sobe) * E, 15 * E, 3 * E), fill=C[sombra])
        d.polygon(_elipse_perfil(a0, bb, -2, (28 + sobe) * E, 12 * E, 2.5 * E), fill=C[luz])
        d.polygon(_pc(bb, [(10, 27), (15, 21), (24, 33 + cabeca), (21, 39 + cabeca), (16, 38)], sobe), fill=C[pele])
    _volume(im, b, meia, corpo, camadas=6)
    def cabeca_de(d, bb):
        c = cabeca + sobe
        d.polygon(_pc(bb, [(19, 39), (24, 40), (33, 31), (32, 28), (28, 29), (22, 34)], c), fill=C[pele])
        d.polygon(_pc(bb, [(29, 30), (33, 31), (32, 28)], c), fill=C[sombra])
        d.polygon(_pc(bb, [(20, 40), (21, 44), (23, 40)], c), fill=C[pele])         # orelha
    _volume(im, b, meia * 0.5, cabeca_de, camadas=4)
    # crina no alto do pescoço, entre o plano do meio e o de trás
    def crina(d):
        c = cabeca + sobe
        pts = [(9, 31), (12, 34), (15, 37), (18, 40), (21, 42)]
        d.line(_pc(b - meia * 0.3, pts, c), fill=C['crina'], width=3)
        for k, (u, v) in enumerate(pts[:-1]):
            d.line(_pc(b - meia * 0.3, [(u, v), (u - 2, v - 3 - (k + quadro) % 2)], c), fill=C['crina'])
    _camada(im, crina)
    # pernas do lado de cá, por cima do corpo
    for u, dx, lado in pernas:
        if lado > 0:
            _camada(im, lambda d, u=u, dx=dx: perna(d, b + meia * 0.6, u, dx))
    # olho, antolho e arreio no plano da frente
    def arreio(d):
        c = cabeca + sobe
        bb = b + meia * 0.5
        x, y = _pc(bb, [(26, 35)], c)[0]
        d.point((x, y), fill=C['contorno'])
        d.polygon(_pc(bb, [(24, 34), (27, 34), (27, 37), (24, 37)], c), outline=C['couro'])   # antolho
        d.line(_pc(bb, [(23, 33), (31, 30)], c), fill=C['couro'])                            # cabeçada
        bf = b + meia
        d.line(_pc(bf, [(13, 21), (17, 30)], sobe), fill=C['couro'], width=3)                # coleira
        d.line(_pc(bf, [(-2, 17), (-2, 31)], sobe), fill=C['couro'], width=2)                # cilha
        d.line(_pc(bf, [(-2, 30), (4, 31), (13, 28)], sobe), fill=C['couro'])
        for u, v in ((-2, 31), (15, 25), (-2, 18)):
            d.point(_pc(bf, [(u, v)], sobe)[0], fill=C['ouro'])
    _camada(im, arreio)


def _cocheiro(im, quadro):
    """O cocheiro no banco da frente, virado para os cavalos, com volume:
    capa, chapéu de aba, rédeas numa mão e o chicote erguido na outra."""
    A = CARRO_A
    a0, b = A + 0.25, 0.0
    sobe = (0, 1, 0)[quadro]
    def banco(d):
        _carro_quad(d, [(A, -0.4, 30), (A + 0.42, -0.4, 30), (A + 0.42, 0.4, 30), (A, 0.4, 30)], 'carro_luz')
        _carro_quad(d, [(A, 0.4, 6), (A + 0.42, 0.4, 6), (A + 0.42, 0.4, 30), (A, 0.4, 30)], 'carro')
        _carro_quad(d, [(A + 0.42, -0.4, 6), (A + 0.42, 0.4, 6), (A + 0.42, 0.4, 30), (A + 0.42, -0.4, 30)], 'carro_sombra')
    _camada(im, banco)
    def corpo(d, bb):
        d.polygon(_perfil(a0, bb, [(-6, 30), (5, 30), (4, 46 + sobe), (-3, 47 + sobe), (-7, 40)]), fill=C['cocheiro'])
        d.polygon(_perfil(a0, bb, [(2, 30), (11, 29), (11, 22), (8, 22), (8, 26), (2, 26)]), fill=C['cocheiro_luz'])
        d.polygon(_elipse_perfil(a0, bb, 1, 50 + sobe, 3, 3.5), fill=C['pele_cocheiro'])
    _volume(im, b, 0.11, corpo, camadas=4)
    def chapeu(d):
        aba = [_carro_t(a0 + 1 / CASA + 0.16 * math.cos(t * math.pi / 8), b + 0.16 * math.sin(t * math.pi / 8),
                        53 + sobe) for t in range(16)]
        d.polygon(aba, fill=C['cocheiro'], outline=C['contorno'])
        d.polygon(_perfil(a0, b, [(-2, 53 + sobe), (4, 53 + sobe), (3, 58 + sobe), (-1, 58 + sobe)]),
                  fill=C['cocheiro_luz'])
    _camada(im, chapeu)
    def bracos(d):
        bf = b + 0.12
        d.line(_perfil(a0, bf, [(1, 42 + sobe), (6, 38), (12, 36)]), fill=C['cocheiro_luz'], width=3)  # rédeas
        x, y = _perfil(a0, bf, [(12, 36)])[0]
        d.point((x, y), fill=C['pele_cocheiro'])
        bt = b - 0.12                                                                    # chicote
        ponta = (24 + 3 * (quadro - 1), 66 - abs(quadro - 1) * 2)
        d.line(_perfil(a0, bt, [(1, 42 + sobe), (6, 46)]), fill=C['cocheiro'], width=3)
        d.line(_perfil(a0, bt, [(6, 46), (10, 58)]), fill=C['carro_luz'], width=1)
        d.line(_perfil(a0, bt, [(10, 58), (17, 64), ponta]), fill=C['couro'], width=1)
    _camada(im, bracos)


def carruagem_frente(brasao=False):
    """Três quadros lado a lado: a borda baixa da frente, as rodas girando, o
    varal, os dois cavalos a trote e o cocheiro."""
    from PIL import Image, ImageDraw
    tira = Image.new('RGBA', (CARRO_W * 3, CARRO_H), (0, 0, 0, 0))
    A, B = CARRO_A, CARRO_B
    for i in range(3):
        q = Q(CARRO_W, CARRO_H)
        d = ImageDraw.Draw(q.im)
        bd = CARRO_BORDA
        # cavalo do outro lado, varal e cocheiro (atrás da borda de perto)
        _sombra_no_chao(q.im, A + 1.95, 0.0, 0.85, 0.75)
        _cavalo(q.im, A + 1.95, -0.38, (i + 1) % 3, False)
        d.line([_carro_t(A, 0.0, 12), _carro_t(A + 2.9, 0.0, 26)], fill=C['carro_luz'], width=2)
        # lado da frente (a = A), baixo em corte, e o cocheiro do lado de fora
        _carro_quad(d, [(A, -B, 6), (A, B, 6), (A, B, bd), (A, -B, bd)], 'carro_sombra')
        _carro_quad(d, [(A, -B, bd), (A + 0.06, -B, bd), (A + 0.06, B, bd), (A, B, bd)], 'ouro_sombra')
        _cocheiro(q.im, i)
        # lado de perto (b = B): borda baixa com friso grego e porta
        _carro_quad(d, [(-A, B, 6), (A, B, 6), (A, B, bd), (-A, B, bd)], 'carro')
        _carro_quad(d, [(-A, B, bd), (A, B, bd), (A, B + 0.06, bd), (-A, B + 0.06, bd)], 'ouro_sombra')
        _friso_grego(d, B, -A, A, 21)
        for a in (-0.3, 0.3):
            d.line([_carro_t(a, B, 8), _carro_t(a, B, 18)], fill=C['carro_sombra'])
        if brasao:
            # brasão de Olympia na lateral (azul e dourado; o desenho é marcador)
            a0 = -5 / CASA
            d.polygon(_perfil(a0, B + 0.01, [(0, 19), (10, 19), (10, 12), (5, 6), (0, 12)]), fill=C['ouro'])
            d.polygon(_perfil(a0, B + 0.01, [(1, 18), (9, 18), (9, 12), (5, 8), (1, 12)]), fill=C['colcha'])
            d.polygon(_perfil(a0, B + 0.01, [(1, 18), (5, 18), (5, 8), (1, 12)]), fill=C['colcha_luz'])
            d.point(_perfil(a0, B + 0.01, [(5, 14)])[0], fill=C['ouro_luz'])
        # cantos com pilares finos até a cobertura (só as quinas)
        for a in (-A, A):
            _carro_quad(d, [(a, B, 6), (a, B, CARRO_TOPO), (a - 0.06 if a > 0 else a + 0.06, B, CARRO_TOPO),
                            (a - 0.06 if a > 0 else a + 0.06, B, 6)], 'carro_luz')
        # lanternas nas quinas de perto
        for la in (A + 0.05, -A - 0.05):
            lx, ly = _carro_t(la, B + 0.05, CARRO_TOPO - 4)
            d.rectangle([lx - 2, ly - 4, lx + 2, ly + 3], fill=C['ouro'])
            d.rectangle([lx - 1, ly - 3, lx + 1, ly + 2], fill=C['vidro_luz'])
        # rodas de perto e o cavalo de perto
        giro = i * math.pi / 12
        _roda(d, -0.95, B + 0.08, giro)
        _roda(d, 1.0, B + 0.08, giro)
        _cavalo(q.im, A + 1.95, 0.38, i, True)
        # rédeas: da boca de cada cavalo até as mãos do cocheiro
        mao = _carro_t(A + 0.25 + 12 / CASA, 0.0, 36)
        for b, qd in ((-0.38, (i + 1) % 3), (0.38, i)):
            v = 31 + (0.0, 1.0, 0.0)[qd] + (0.0, -1.0, 1.0)[qd]
            boca = _carro_t(A + 1.95 + 31 * 1.45 / CASA, b + 0.08, v * 1.45)
            d.line([boca, mao], fill=C['couro'])
        tira.paste(q.im, (i * CARRO_W, 0))
    return tira



# --- margens da rua em Atenas (Rafael, 15/10/2026: grama, árvores e coisas
# do reino passando dos lados). Ciprestes e oliveiras, colunas de mármore e
# canteiros floridos, como uma capital de inspiração grega. Provisório: o
# livro não descreve o caminho até o Palácio Imperial.
def cipreste():
    q = Q(18, 58)
    q.sombra_no_chao(9, 55, 6, 2)
    q.r(8, 46, 9, 55, 'tronco')
    for y in range(2, 50):
        k = (y - 2) / 47
        meia = int(1 + 7 * math.sin(min(1.0, k * 1.25) * math.pi / 2) * (1 - max(0, k - 0.8) * 2.5))
        for x in range(9 - meia, 9 + meia + 1):
            cor = 'folha'
            if x < 9 - meia // 3:
                cor = 'folha_luz' if (x + y) % 4 else 'folha'
            elif x > 9 + meia // 2:
                cor = 'folha_escura'
            if (x * 5 + y * 3) % 11 == 0:
                cor = 'folha_escura'
            q.p(x, y, cor)
    return q.contornar()


def oliveira():
    q = Q(40, 40)
    q.sombra_no_chao(20, 37, 12, 3)
    # tronco torto
    for y in range(22, 37):
        x = 19 + int(2 * math.sin(y / 3))
        q.r(x, y, x + 2, y, 'tronco')
        q.p(x, y, 'tronco_luz')
    q.r(14, 22, 26, 24, 'tronco')
    # copa em nuvens prateadas
    for cx, cy, rx, ry in ((12, 16, 9, 7), (27, 15, 10, 7), (20, 10, 10, 7), (20, 19, 12, 6)):
        q.elipse(cx, cy, rx, ry, 'oliva')
    for cx, cy, rx, ry in ((10, 13, 4, 3), (22, 7, 5, 3), (28, 12, 4, 3)):
        q.elipse(cx, cy, rx, ry, 'oliva_luz')
    for x in range(4, 36):
        for y in range(4, 26):
            if q.px[x, y][3] and (x * 7 + y * 5) % 13 == 0:
                q.p(x, y, 'oliva_sombra')
    return q.contornar()


def coluna():
    q = Q(16, 48)
    q.sombra_no_chao(8, 45, 7, 2)
    q.r(2, 42, 13, 45, 'marmore_sombra'); q.r(2, 42, 13, 42, 'marmore')       # base
    q.r(4, 8, 11, 41, 'marmore')
    for x in (5, 8, 10):
        q.coluna(x, 9, 40, 'marmore_sombra')                                     # caneluras
    q.coluna(4, 8, 41, 'marmore_luz')
    q.r(2, 4, 13, 7, 'marmore'); q.r(2, 4, 13, 4, 'marmore_luz')              # capitel
    q.p(2, 7, 'marmore_sombra'); q.p(13, 7, 'marmore_sombra')
    return q.contornar()


def canteiro():
    q = Q(28, 16)
    q.sombra_no_chao(14, 13, 12, 2)
    q.elipse(14, 9, 12, 5, 'folha')
    q.elipse(11, 7, 6, 3, 'folha_luz')
    for i, (x, y) in enumerate(((5, 8), (9, 5), (13, 9), (17, 6), (21, 8), (24, 10), (8, 11), (16, 11))):
        q.p(x, y, 'flor' if i % 2 else 'flor2')
        q.p(x + 1, y, 'flor' if i % 2 else 'flor2')
    return q.contornar()


# --- Rodada 1 das cenas 7 a 10 (Palácio Imperial, Rua das Butiques, loja de
# pelúcias, restaurante) -----------------------------------------------------
# DO LIVRO (Cap. 1): no Palácio, "colunas, jardins, flores em profusão" e uma
# "fonte central" cuja água Althea vê como "diamantes líquidos"; poucos
# guardas; o anexo, vazio; o vestido da princesa é "rubro, a cor do Império".
# Na Rua das Butiques o movimento só para quando reconhecem o "brasão de
# Olympia". Na loja: "pelúcias, feitas sob encomenda a partir de desenhos
# estranhos e criaturas do Mar de Equidna", "prateleiras baixas" e "algo entre
# cobra e enguia". No restaurante: "mesa redonda pequena", "jarras de água e
# suco", "pequenas travessas de salada" e o "armário onde o restaurante
# guardava parte da louça".
# INFERÊNCIA PROVISÓRIA (tudo o mais): cores de reboco, toldos, vitrines,
# lampiões, vasos, ladrilho, formas e cores das pelúcias, o desenho do brasão
# (o livro não o descreve; só se sabe que Olympia usa azul e dourado) e a
# arquitetura do Palácio.
C.update(flor_sombra=H('#9A7AAE'))


def _bicho(q, x, y, cor, luz):
    """Pelúcia pequena sentada, 5×4, com a base em (x, y)."""
    q.r(x - 2, y - 3, x + 2, y, cor)
    q.p(x - 1, y - 3, luz); q.p(x - 1, y - 2, 'noite'); q.p(x + 1, y - 2, 'noite')


BICHOS = (('monstro', 'monstro_luz'), ('bolo', 'bolo_luz'), ('flor', 'perola'), ('vela', 'ouro_luz'),
          ('rapidez', 'rapidez_luz'), ('cura', 'cura_luz'), ('flor2', 'perola'))


def _escudo(q, x0, y0, largura=16, altura=20):
    meia0 = largura // 2
    def m(y):
        return meia0 if y < altura * 0.55 else max(1, meia0 - int((y - altura * 0.55) * 1.0))
    cx = x0 + meia0
    for y in range(altura):
        q.linha(y0 + y, cx - m(y), cx + m(y) - 1, 'ouro')
    for y in range(1, altura - 1):
        mi = m(y) - 1
        if mi > 0:
            q.linha(y0 + y, cx - mi, cx + mi - 1, 'colcha')
            q.linha(y0 + y, cx - mi, cx - 1, 'colcha_luz')


def brasao():
    # Brasão de Olympia, azul e dourado. O desenho central (losango dourado e
    # onda branca) é um marcador: o livro não descreve o brasão.
    q = Q(16, 20)
    _escudo(q, 0, 0)
    for i in range(4):
        q.linha(4 + i, 7 - i, 8 + i, 'ouro_luz')
        q.linha(8 + i, 4 + i, 11 - i, 'ouro')
    q.linha(14, 4, 11, 'perola'); q.p(5, 13, 'perola'); q.p(8, 13, 'perola'); q.p(10, 13, 'perola')
    return q.im


def estandarte_imperial():
    # estandarte rubro ("a cor do Império"), com o disco dourado como marcador
    q = Q(10, 28)
    q.r(0, 0, 9, 1, 'ouro'); q.p(0, 0, 'ouro_luz')
    q.r(1, 2, 8, 22, 'embrulho'); q.coluna(1, 2, 22, 'embrulho_luz'); q.coluna(2, 2, 22, 'embrulho_luz')
    for y in range(23, 28):
        meia = 4 - (y - 23)
        q.linha(y, 5 - meia, 4 + meia, 'embrulho')
    q.elipse(5, 10, 2, 2, 'ouro'); q.p(4, 9, 'ouro_luz')
    q.linha(2, 1, 8, 'ouro_sombra'); q.linha(21, 1, 8, 'ouro_sombra')
    return q.im


def portal_palacio():
    # portão do Palácio: arco de mármore e folhas rubras com ferragem dourada
    q = Q(28, 30)
    q.r(0, 0, 27, 29, 'marmore_sombra')
    q.r(0, 0, 27, 2, 'marmore_luz')
    q.r(5, 5, 22, 29, 'prata_sombra')
    q.r(6, 6, 21, 29, 'embrulho')
    q.r(6, 6, 7, 29, 'embrulho_luz')
    q.coluna(13, 6, 29, 'noite'); q.coluna(14, 6, 29, 'noite')
    for y in (10, 18):
        q.linha(y, 6, 21, 'ouro_sombra')
    q.r(11, 16, 12, 17, 'ouro'); q.r(15, 16, 16, 17, 'ouro')
    q.r(3, 5, 4, 29, 'marmore_luz'); q.r(23, 5, 24, 29, 'marmore_luz')
    return q.im


def portal_anexo():
    # anexo fechado e vazio: porta de madeira, janelas escuras com cortinas
    # puxadas, nenhuma luz
    q = Q(28, 30)
    q.r(0, 0, 27, 29, 'marmore_sombra')
    q.r(0, 0, 27, 2, 'marmore_luz')
    q.r(9, 6, 18, 29, 'madeira_sombra'); q.r(10, 7, 17, 29, 'madeira')
    q.coluna(13, 7, 29, 'madeira_sombra'); q.coluna(14, 7, 29, 'madeira_sombra')
    q.r(11, 9, 12, 16, 'madeira_luz'); q.r(15, 9, 16, 16, 'madeira_luz')
    q.p(12, 20, 'ferro_luz'); q.p(15, 20, 'ferro_luz')
    for x0 in (2, 21):
        q.r(x0, 8, x0 + 4, 21, 'noite')
        q.r(x0 + 1, 9, x0 + 3, 20, 'veludo'); q.coluna(x0 + 2, 9, 20, 'veludo_luz')
        q.linha(7, x0 - 1, x0 + 5, 'marmore_luz'); q.linha(22, x0 - 1, x0 + 5, 'marmore_luz')
    return q.im


def vitrine(conteudo='pelucias'):
    """Vitrine de butique. conteudo: 'pelucias' (a loja da cena, com luz
    quente por dentro para chamar o olho), 'chapeus', 'vestidos', 'joias' ou
    'perfumes' (as outras lojas da rua; mercadorias por inferência)."""
    q = Q(26, 18)
    q.r(0, 0, 25, 17, 'madeira_sombra')
    q.r(2, 2, 23, 13, 'vela' if conteudo == 'pelucias' else 'vidro')
    for i in range(5):
        q.p(4 + i * 2, 3 + i, 'vidro_luz'); q.p(5 + i * 2, 3 + i, 'vidro_luz')
    q.coluna(12, 2, 13, 'madeira_sombra'); q.coluna(13, 2, 13, 'madeira_sombra')
    for k, x in enumerate((6, 10, 16, 20)):
        if conteudo == 'pelucias':
            _bicho(q, x, 13, *BICHOS[(k * 2) % len(BICHOS)])
        elif conteudo == 'chapeus':
            q.coluna(x, 10, 13, 'ferro')
            q.r(x - 3, 9, x + 3, 9, ('lona', 'veludo', 'oliva', 'creme')[k]); q.r(x - 1, 6, x + 1, 8, ('lona', 'veludo', 'oliva', 'creme')[k])
            q.linha(8, x - 1, x + 1, 'ouro')
        elif conteudo == 'vestidos':
            cor = ('veludo', 'perola', 'lona', 'flor')[k]
            q.r(x - 1, 4, x + 1, 7, cor); q.r(x - 2, 8, x + 2, 11, cor); q.r(x - 3, 12, x + 3, 13, cor)
            q.p(x, 3, 'ferro')
        elif conteudo == 'joias':
            q.r(x - 2, 10, x + 2, 13, 'veludo'); q.linha(10, x - 2, x + 2, 'veludo_luz')
            q.p(x - 1, 8, 'ouro'); q.p(x + 1, 8, 'ouro'); q.p(x, 9, ('perola', 'cura', 'flor', 'ouro_luz')[k])
        elif conteudo == 'perfumes':
            cor = ('cura', 'flor', 'ouro_luz', 'azul_luz')[k]
            q.r(x - 1, 10, x + 1, 13, cor); q.p(x, 9, 'ouro'); q.p(x, 8, 'ouro_luz'); q.p(x - 1, 11, 'vidro_luz')
    q.r(0, 14, 25, 17, 'madeira'); q.linha(14, 0, 25, 'madeira_luz')
    return q.im


def toldo(cor='lona', luz='lona_luz'):
    # toldo listrado (inferência); a loja de pelúcias tem o seu, verde-água
    # como o monstro da placa
    q = Q(28, 9)
    for x in range(28):
        c = cor if (x // 4) % 2 == 0 else 'creme'
        q.r(x, 0, x, 5, c)
        if x % 4 in (1, 2):
            q.r(x, 6, x, 7, c)
    q.linha(0, 0, 27, luz)
    return q.im


def placa_butique(tipo='pelucias'):
    # placa pendurada com o desenho da mercadoria (sem letras); a de
    # pelúcias tem moldura dourada e o monstro verde-água
    q = Q(14, 16)
    q.linha(0, 0, 13, 'ferro'); q.coluna(3, 0, 3, 'ferro'); q.coluna(10, 0, 3, 'ferro')
    q.r(1, 3, 12, 14, 'madeira'); q.r(1, 3, 12, 3, 'madeira_luz')
    moldura = 'ouro' if tipo == 'pelucias' else 'madeira_sombra'
    q.r(1, 14, 12, 14, moldura); q.coluna(1, 3, 14, moldura); q.coluna(12, 3, 14, moldura)
    if tipo == 'pelucias':
        q.r(4, 6, 9, 12, 'monstro'); q.p(4, 6, 'monstro_luz'); q.p(5, 8, 'branco'); q.p(8, 8, 'branco')
        q.p(5, 9, 'noite'); q.p(8, 9, 'noite'); q.linha(11, 5, 8, 'branco')
    elif tipo == 'chapeus':
        q.r(3, 10, 10, 11, 'lona'); q.r(5, 6, 8, 9, 'lona'); q.linha(9, 5, 8, 'ouro')
    elif tipo == 'vestidos':
        q.r(5, 5, 8, 7, 'veludo'); q.r(4, 8, 9, 10, 'veludo'); q.r(3, 11, 10, 12, 'veludo'); q.p(6, 4, 'ferro'); q.p(7, 4, 'ferro')
    elif tipo == 'joias':
        q.elipse(6, 8, 3, 3, 'ouro'); q.elipse(6, 8, 1, 1, 'madeira'); q.p(6, 4, 'perola'); q.p(6, 5, 'cura')
    elif tipo == 'perfumes':
        q.r(5, 7, 8, 12, 'cura'); q.r(6, 5, 7, 6, 'ouro'); q.p(5, 8, 'vidro_luz')
    return q.im


def fonte():
    # Fonte central do pátio: duas bacias de mármore e a água que Althea vê
    # como "diamantes líquidos" (pontos brancos e dourados no jato). Cabe numa
    # casa (64×32); pe = 14.
    q = Q(64, 64)
    q.sombra_no_chao(32, 52, 29, 10)
    q.elipse(32, 52, 28, 11, 'marmore_sombra')
    q.elipse(32, 49, 28, 11, 'marmore_luz')
    q.elipse(32, 49, 25, 9, 'marmore')
    q.elipse(32, 50, 23, 8, 'olho')
    q.elipse(30, 49, 12, 4, 'olho_luz')
    for x, y in ((14, 50), (22, 54), (45, 52), (50, 49), (26, 47)):
        q.p(x, y, 'branco')
    q.r(28, 30, 35, 49, 'marmore'); q.coluna(28, 30, 49, 'marmore_luz'); q.coluna(35, 30, 49, 'marmore_sombra')
    q.elipse(32, 32, 13, 5, 'marmore_sombra')
    q.elipse(32, 30, 13, 5, 'marmore_luz')
    q.elipse(32, 31, 10, 3, 'olho_luz')
    q.r(30, 16, 33, 30, 'marmore'); q.coluna(30, 16, 30, 'marmore_luz')
    q.elipse(32, 17, 6, 2, 'marmore_luz')
    q.elipse(32, 17, 4, 1, 'olho_luz')
    # jato e gotas caindo em arco
    for dx in (-1, 0, 1):
        q.coluna(32 + dx, 8, 16, 'olho_luz')
    q.p(32, 6, 'branco'); q.p(31, 7, 'branco'); q.p(33, 7, 'branco')
    for k, dx in enumerate((3, 6, 9, 12, 15, 18)):
        y = int(8 + (dx / 3.0) ** 2 * 0.55 + 2)
        q.p(32 - dx, y, 'branco' if k % 2 else 'olho_luz')
        q.p(32 + dx, y, 'olho_luz' if k % 2 else 'branco')
    for x, y in ((24, 20), (40, 21), (21, 36), (43, 37), (27, 14), (37, 14)):
        q.p(x, y, 'ouro_luz')                              # os diamantes
    return q.contornar()


def canteiro_flores():
    # canteiro florido ("flores em profusão"), com borda de pedra; uma casa
    import random
    rng = random.Random(7)
    q = Q(56, 28)
    q.sombra_no_chao(28, 21, 26, 5)
    q.elipse(28, 16, 26, 10, 'pedra_parede_sombra')
    q.elipse(28, 14, 26, 10, 'pedra_parede')
    q.elipse(28, 14, 23, 8, 'folha_escura')
    q.elipse(28, 13, 22, 7, 'folha')
    q.elipse(20, 11, 10, 4, 'folha_luz')
    cores = ('flor', 'flor2', 'cura', 'branco', 'olho', 'vela', 'flor_sombra')
    for _ in range(46):
        x = rng.randint(8, 48); y = rng.randint(6, 19)
        if ((x - 28) / 22.0) ** 2 + ((y - 13) / 7.0) ** 2 <= 1:
            c = rng.choice(cores)
            q.p(x, y, c); q.p(x + 1, y, c); q.p(x, y - 1, 'folha_luz')
    return q.contornar()


def posto_guarda():
    # Posto de guarda do pátio (inferência): um degrau de mármore com a lança
    # e a flâmula rubra do Império. O livro diz "poucos guardas"; os postos
    # vazios no caminho mostram isso. Uma casa; pe = 3.
    q = Q(30, 52)
    q.sombra_no_chao(15, 48, 13, 4)
    q.elipse(15, 47, 13, 5, 'marmore_sombra')
    q.elipse(15, 45, 13, 5, 'marmore_luz')
    q.elipse(15, 45, 11, 4, 'marmore')
    q.r(14, 4, 15, 44, 'ferro'); q.coluna(14, 4, 44, 'ferro_luz')
    q.r(13, 1, 16, 4, 'prata'); q.p(14, 0, 'prata'); q.p(15, 0, 'prata_sombra')
    q.r(16, 6, 25, 9, 'embrulho'); q.r(16, 10, 22, 12, 'embrulho')
    q.r(16, 6, 25, 6, 'embrulho_luz'); q.p(23, 12, 'ouro_luz')
    return q.contornar()


def lampiao():
    # lampião de rua de ferro (inferência)
    q = Q(14, 50)
    q.sombra_no_chao(7, 47, 5, 2)
    q.r(6, 14, 7, 46, 'ferro'); q.coluna(6, 14, 46, 'ferro_luz')
    q.r(3, 44, 10, 47, 'ferro'); q.r(4, 42, 9, 43, 'ferro_luz')
    q.r(2, 3, 11, 12, 'ouro_sombra'); q.r(3, 4, 10, 11, 'vela')
    q.r(5, 5, 8, 9, 'ouro_luz')
    q.linha(2, 2, 11, 'ferro'); q.r(4, 0, 9, 1, 'ferro'); q.p(6, 0, 'ferro_luz')
    q.linha(13, 2, 11, 'ferro')
    return q.contornar()


def vaso_flor():
    q = Q(16, 24)
    q.sombra_no_chao(8, 21, 6, 2)
    q.r(4, 13, 11, 21, 'vela_escura'); q.coluna(4, 13, 21, 'ferrugem'); q.r(3, 12, 12, 13, 'vela')
    q.linha(21, 4, 11, 'ferrugem')
    q.elipse(8, 8, 6, 5, 'folha'); q.elipse(6, 6, 3, 2, 'folha_luz')
    for x, y, c in ((4, 6, 'flor'), (8, 3, 'flor2'), (11, 7, 'cura'), (7, 8, 'branco'), (10, 4, 'flor')):
        q.p(x, y, c); q.p(x + 1, y, c)
    return q.contornar()


# --- loja de pelúcias ----------------------------------------------------
def prateleira_baixa(lado, h=22, andares=(0.05, 0.5)):
    """Prateleira baixa (22 px: dá para uma criança se agachar entre elas) com
    pelúcias nos andares e em cima. lado 'esq': encostada na parede da
    linha y = 0; 'dir': na da coluna x = 0. pe = PE_CAIXA. Com h maior e mais
    andares vira a estante alta."""
    if lado == 'esq':
        a0, a1, b0, b1 = -0.45, 0.45, -0.5, -0.2
        q, _, _ = caixa_iso(a0, a1, b0, b1, h, 'madeira_sombra', 'madeira', 'madeira_luz')
        pt = lambda s_, t_: _tela(a0 + s_ * (a1 - a0), b1, t_ * h, h + 17)
    else:
        a0, a1, b0, b1 = -0.5, -0.2, -0.45, 0.45
        q, _, _ = caixa_iso(a0, a1, b0, b1, h, 'madeira', 'madeira_sombra', 'madeira_luz')
        pt = lambda s_, t_: _tela(a1, b0 + s_ * (b1 - b0), t_ * h, h + 17)
    for t_ in andares:                                  # tábuas dos andares
        for i in range(61):
            x, y = pt(i / 60, t_)
            q.p(int(round(x)), int(round(y)), 'madeira_luz')
            q.p(int(round(x)), int(round(y)) + 1, 'madeira')
    for k, s_ in enumerate((0.14, 0.38, 0.62, 0.86)):
        for t_, desloc in [(a, 0) for a in andares] + [(1.0, 3)]:
            x, y = pt(s_, t_)
            cor, luz = BICHOS[(k * 2 + int(t_ * 4)) % len(BICHOS)]
            _bicho(q, int(round(x)), int(round(y)) - 1 - desloc, cor, luz)
    return q.contornar()


def balcao_loja():
    # balcão da loja (inferência: o livro só diz que os donos vêm ao encontro)
    q, frente, _ = caixa_iso(-0.5, 0.5, -0.5, -0.1, 24, 'madeira', 'madeira_sombra', 'madeira_luz')
    for s0, s1 in ((0.07, 0.46), (0.54, 0.93)):
        t0, t1 = 0.14, 0.78
        _riscar(frente, s0, s1, t0, t0, 'madeira_luz'); _riscar(frente, s0, s1, t1, t1, 'madeira_luz')
        _riscar(frente, s0, s0, t0, t1, 'madeira_luz'); _riscar(frente, s1, s1, t0, t1, 'madeira_luz')
    _riscar(frente, 0.0, 1.0, 0.95, 0.95, 'ouro_sombra')
    return q.contornar()


def pelucia_enguia():
    # A criatura "entre cobra e enguia" (livro): corpo longo e ondulado, de
    # pano claro, olhos de botão e uma crista; cores e forma são inferência
    q = Q(46, 30)
    q.sombra_no_chao(23, 25, 20, 3)
    passos = 70
    pontos = []
    for i in range(passos):
        u = i / (passos - 1)
        x = 4 + u * 38
        y = 15 + 5 * math.sin(u * math.pi * 2.3 + 0.4)
        r = 4.2 - 2.2 * u if u > 0.15 else 4.4
        pontos.append((x, y, r))
    for x, y, r in pontos:
        q.elipse(int(x), int(y) + 1, int(r), int(r), 'rapidez')
    for x, y, r in pontos:
        q.elipse(int(x), int(y), int(r), int(r), 'rapidez_luz')
    for i, (x, y, r) in enumerate(pontos):
        if i % 6 == 3 and r > 2:
            q.p(int(x), int(y - r) - 1, 'ouro_luz')                       # crista
        if i % 5 == 2 and 6 < i < 62:
            q.p(int(x), int(y + r) - 1, 'prata')                         # ventre
        if i % 7 == 4 and 8 < i < 60:
            q.p(int(x), int(y), 'perola')                                # pontos de costura
    hx, hy, _ = pontos[2]
    q.elipse(int(hx) + 1, int(hy) - 1, 1, 1, 'branco'); q.p(int(hx) + 1, int(hy) - 1, 'noite')
    q.elipse(int(hx) + 4, int(hy) - 1, 1, 1, 'branco'); q.p(int(hx) + 4, int(hy) - 1, 'noite')
    return q.contornar()


def pelucia_dragao_marinho(nadadeiras=True):
    # nadadeiras=False (sem nadadeiras nem chifres): a do jogo dos desenhos
    # que NÃO é a da Thea
    q = Q(30, 28)
    q.sombra_no_chao(15, 24, 12, 3)
    for k in range(5):                                                   # cauda enrolada
        q.elipse(22 + k, 20 - k, 3 - k // 3, 3 - k // 3, 'bolo_sombra')
    q.elipse(14, 17, 9, 7, 'bolo'); q.elipse(12, 15, 5, 3, 'bolo_luz')
    q.elipse(8, 9, 5, 4, 'bolo'); q.elipse(6, 11, 3, 2, 'bolo_luz')      # cabeça e focinho
    for x in (11, 14, 17, 20) if nadadeiras else ():                     # nadadeiras dorsais
        q.p(x, 9 + (x - 11) // 2, 'ouro'); q.p(x, 10 + (x - 11) // 2, 'ouro_luz')
    if nadadeiras:                                                       # chifres
        q.p(6, 4, 'ouro_luz'); q.p(9, 4, 'ouro_luz'); q.p(6, 5, 'ouro'); q.p(9, 5, 'ouro')
    q.p(5, 8, 'noite'); q.p(9, 8, 'noite'); q.p(5, 7, 'branco'); q.p(9, 7, 'branco')
    q.linha(12, 4, 7, 'noite')
    return q.contornar()


def pelucia_polvo(bracos=6):
    # bracos=3: a do jogo dos desenhos que NÃO é a da Thea
    q = Q(26, 26)
    q.sombra_no_chao(13, 23, 10, 2)
    for k, x in enumerate((5, 8, 11, 14, 17, 20) if bracos == 6 else (7, 13, 19)):
        for y in range(14, 22):
            q.p(x + (1 if (y // 2 + k) % 2 else 0), y, 'flor_sombra')
            q.p(x + (1 if (y // 2 + k) % 2 else 0) - 1, y, 'flor')
            if bracos != 6:                                              # braços grossos
                q.p(x + (1 if (y // 2 + k) % 2 else 0) - 2, y, 'flor')
    q.elipse(13, 10, 9, 8, 'flor'); q.elipse(10, 7, 4, 3, 'perola')
    q.elipse(13, 12, 8, 4, 'flor')
    q.r(8, 10, 9, 12, 'branco'); q.r(16, 10, 17, 12, 'branco'); q.p(9, 11, 'noite'); q.p(17, 11, 'noite')
    return q.contornar()


def pelucia_monstro(olhos=1):
    # monstrinho de olho grande e dentes, parente do que Althea abraça (livro:
    # "pelúcia de um monstro marinho"); olhos=2: a do jogo dos desenhos que
    # NÃO é a da Thea
    q = Q(26, 26)
    q.sombra_no_chao(13, 23, 10, 2)
    q.elipse(13, 15, 9, 8, 'monstro'); q.elipse(10, 12, 4, 3, 'monstro_luz')
    q.p(7, 5, 'ouro_luz'); q.p(7, 6, 'ouro'); q.p(18, 5, 'ouro_luz'); q.p(18, 6, 'ouro')
    q.r(4, 21, 8, 22, 'monstro'); q.r(17, 21, 21, 22, 'monstro')
    if olhos == 1:
        q.elipse(13, 11, 4, 3, 'branco'); q.p(13, 11, 'noite'); q.p(14, 11, 'noite')
    else:
        for cx in (9, 17):
            q.elipse(cx, 11, 2, 2, 'branco'); q.p(cx, 11, 'noite')
    for x in range(8, 18, 2):
        q.p(x, 18, 'branco'); q.p(x + 1, 17, 'branco')
    return q.contornar()


def expositor_enguia():
    """Pedestal baixo com a pelúcia longa enrolada em cima: o objeto que o
    jogador examina para escolher o presente. pe = 5."""
    q = Q(52, 40)
    q.sombra_no_chao(26, 35, 22, 3)
    q.r(7, 26, 44, 34, 'madeira'); q.r(7, 26, 12, 34, 'madeira_sombra'); q.linha(34, 7, 44, 'madeira_sombra')
    q.elipse(26, 26, 19, 5, 'veludo_luz'); q.elipse(26, 26, 16, 4, 'veludo')
    q.linha(30, 7, 44, 'ouro_sombra')
    q.contornar()
    q.im.alpha_composite(pelucia_enguia(), (3, 0))
    return q.im


def cesta_pelucias():
    q = Q(32, 26)
    q.sombra_no_chao(16, 22, 13, 2)
    for k, (x, y) in enumerate(((10, 8), (16, 6), (22, 9))):
        cor, luz = BICHOS[(k * 3 + 1) % len(BICHOS)]
        q.elipse(x, y, 4, 4, cor); q.p(x - 1, y - 2, luz)
        q.p(x - 1, y, 'noite'); q.p(x + 2, y, 'noite')
    q.elipse(16, 17, 12, 5, 'madeira_sombra')
    q.r(4, 12, 27, 19, 'madeira'); q.coluna(4, 12, 19, 'madeira_sombra')
    for y in (14, 17):
        q.linha(y, 5, 27, 'madeira_luz')
    q.elipse(16, 12, 12, 3, 'madeira_luz'); q.elipse(16, 12, 10, 2, 'madeira_sombra')
    return q.contornar()


def estante_alta(lado):
    """Estante alta, com pelúcias em quatro andares (ambiente da loja,
    inferência). pe = PE_CAIXA."""
    return prateleira_baixa(lado, h=46, andares=(0.03, 0.27, 0.51, 0.75))


def caixas_presente():
    # pilha de caixas de presente com laço (ambiente da loja, inferência)
    q = Q(30, 30)
    q.sombra_no_chao(15, 27, 13, 2)
    for x0, y0, x1, y1, cor, luz in ((3, 16, 16, 27, 'embrulho', 'embrulho_luz'),
                                     (15, 18, 26, 27, 'veludo', 'veludo_luz'),
                                     (7, 7, 18, 16, 'monstro', 'monstro_luz')):
        q.r(x0, y0, x1, y1, cor); q.linha(y0, x0, x1, luz)
        meio = (x0 + x1) // 2
        q.coluna(meio, y0, y1, 'ouro'); q.linha((y0 + y1) // 2, x0, x1, 'ouro')
    q.p(11, 5, 'ouro_luz'); q.p(14, 5, 'ouro_luz'); q.p(12, 6, 'ouro'); q.p(13, 6, 'ouro')
    return q.contornar()


def cavalinho():
    # cavalinho de balanço de madeira (brinquedo, ambiente da loja, inferência)
    q = Q(32, 30)
    q.sombra_no_chao(16, 27, 13, 2)
    for x in range(3, 29):                               # o arco de balanço
        y = 25 + int(round(((x - 16) / 13) ** 2 * -3)) + 1
        q.p(x, y, 'madeira_sombra'); q.p(x, y - 1, 'madeira')
    q.coluna(9, 18, 24, 'madeira_sombra'); q.coluna(22, 18, 24, 'madeira_sombra')
    q.r(8, 12, 23, 18, 'creme'); q.linha(12, 8, 23, 'branco')
    q.r(20, 5, 25, 13, 'creme'); q.r(24, 7, 27, 10, 'creme')   # pescoço e cabeça
    q.p(24, 7, 'noite'); q.coluna(19, 5, 12, 'veludo')
    q.r(4, 12, 7, 15, 'veludo')                          # rabo
    q.r(12, 10, 17, 12, 'veludo'); q.linha(10, 12, 17, 'ouro')  # sela
    return q.contornar()


# Blocos da sala lateral (jogo das caixas, regra do jogo): cada um ocupa uma
# casa inteira; a altura em pixels é a do degrau onde Nicholas pisa
# (CenaButiques.BLOCOS). pe = PE_CAIXA.
ALTURA_BANQUINHO = 12
ALTURA_CAIXA = 24
ALTURA_CAIXOTE = 40


def banquinho():
    """Banquinho de madeira, degrau baixo (altura 1)."""
    q, frente, lado = caixa_iso(-0.34, 0.34, -0.34, 0.34, ALTURA_BANQUINHO, 'madeira', 'madeira_sombra', 'madeira_luz')
    _riscar(frente, 0.0, 1.0, 0.8, 0.8, 'madeira_sombra')
    _riscar(lado, 0.0, 1.0, 0.8, 0.8, 'madeira')
    return q.contornar()


def caixa_madeira():
    """Caixa de mercadoria fechada, degrau médio (altura 2)."""
    q, frente, lado = caixa_iso(-0.4, 0.4, -0.4, 0.4, ALTURA_CAIXA, 'madeira_luz', 'madeira', 'ouro_luz')
    for t_ in (0.08, 0.92):
        _riscar(frente, 0.0, 1.0, t_, t_, 'madeira_sombra')
        _riscar(lado, 0.0, 1.0, t_, t_, 'madeira_sombra')
    _riscar(frente, 0.0, 1.0, 0.08, 0.92, 'madeira_sombra')
    _riscar(lado, 0.0, 1.0, 0.92, 0.08, 'madeira_sombra')
    return q.contornar()


def caixote_pesado():
    """Caixote pesado com cintas de ferro: alto demais para subir e pesado
    demais para mover."""
    q, frente, lado = caixa_iso(-0.42, 0.42, -0.42, 0.42, ALTURA_CAIXOTE, 'madeira_sombra', 'madeira', 'madeira_luz')
    for t_ in (0.15, 0.5, 0.85):
        _riscar(frente, 0.0, 1.0, t_, t_, 'ferro')
        _riscar(lado, 0.0, 1.0, t_, t_, 'ferro')
    for s_ in (0.06, 0.94):
        _riscar(frente, s_, s_, 0.0, 1.0, 'ferro')
        _riscar(lado, s_, s_, 0.0, 1.0, 'ferro')
    return q.contornar()


def tapete_loja():
    """Tapete redondo de brincar, deitado no chão (2×2 casas, 128×64), sem
    bloquear. Fica no chão: z_index abaixo de quem anda."""
    q = Q(128, 64)
    for y in range(64):
        for x in range(128):
            d = abs(x - 63.5) / 60 + abs(y - 31.5) / 30
            if d <= 1.0:
                cor = 'tapete_azul' if d > 0.9 else ('ouro_sombra' if d > 0.84 else
                      ('tapete' if d > 0.5 else ('tapete_luz' if d > 0.42 else 'tapete')))
                q.p(x, y, cor)
    for k in range(8):                                   # estrelinhas
        import math as _m
        a = k * _m.pi / 4
        q.p(int(64 + _m.cos(a) * 20), int(32 + _m.sin(a) * 10), 'ouro_luz')
    return q.im


def arco_sala():
    """Passagem em arco para a sala lateral, com a cortina aberta e uma
    pelúcia pendurada em cima (para não ser confundida com a porta da rua)."""
    q = Q(18, 30)
    q.r(0, 4, 17, 29, 'ouro_sombra')
    q.r(2, 8, 15, 29, 'vela')                            # luz da sala ao fundo
    for x in range(2, 16):
        topo = 8 - int(round(4 * (1 - ((x - 8.5) / 6.5) ** 2)))
        q.coluna(x, topo, 8, 'vela')
        q.p(x, topo - 1, 'ouro')
    q.r(2, 8, 4, 29, 'veludo'); q.coluna(5, 10, 29, 'veludo_luz')     # cortinas abertas
    q.r(13, 8, 15, 29, 'veludo'); q.coluna(12, 10, 29, 'veludo_luz')
    _bicho(q, 9, 4, 'monstro', 'monstro_luz')
    return q.im


# --- restaurante -----------------------------------------------------------
def mesa_redonda():
    """Mesa redonda pequena (livro) posta para três: toalha, três pratos,
    jarra de água, jarra de suco e duas travessinhas de salada. pe = 3."""
    q = Q(60, 44)
    q.sombra_no_chao(30, 40, 22, 3)
    q.r(28, 22, 31, 38, 'madeira'); q.coluna(28, 22, 38, 'madeira_sombra')
    q.r(21, 38, 38, 40, 'madeira_sombra'); q.linha(38, 21, 38, 'madeira')
    q.elipse(30, 22, 26, 11, 'prata_sombra')                 # a toalha cai pela borda
    q.elipse(30, 18, 26, 11, 'branco')
    q.elipse(30, 18, 22, 8, 'perola')
    for x in range(8, 53, 3):
        q.p(x, 28 if abs(x - 30) < 14 else 27, 'prata')
    for x, y in ((18, 19), (42, 19), (30, 25)):              # três lugares
        q.elipse(x, y, 5, 2, 'prata'); q.elipse(x, y, 4, 1, 'branco')
        q.p(x - 7, y, 'ferro_luz'); q.p(x + 7, y, 'ferro_luz')
    q.r(27, 8, 30, 16, 'olho'); q.r(27, 8, 27, 16, 'olho_luz'); q.p(30, 9, 'olho_luz'); q.linha(7, 27, 30, 'olho_luz')
    q.r(33, 10, 36, 16, 'vela'); q.r(33, 10, 33, 16, 'ouro_luz'); q.linha(9, 33, 36, 'ouro_luz')
    for x, y in ((24, 15), (38, 14)):                        # salada
        q.elipse(x, y, 3, 1, 'branco'); q.elipse(x, y - 1, 2, 1, 'folha_luz'); q.p(x, y - 1, 'cura')
    return q.contornar()


def cadeira(de_costas):
    """Cadeira de madeira com assento estofado. de_costas: vista pelo encosto
    (a cadeira do lado de cá da mesa); senão, de frente. pe = 3."""
    q = Q(16, 30)
    q.sombra_no_chao(8, 27, 6, 2)
    if de_costas:
        q.r(2, 3, 13, 17, 'madeira'); q.coluna(2, 3, 17, 'madeira_luz'); q.coluna(13, 3, 17, 'madeira_sombra')
        q.r(2, 3, 13, 4, 'madeira_luz')
        for x in (5, 8, 11):
            q.coluna(x, 6, 16, 'madeira_sombra')
        q.r(1, 18, 14, 20, 'veludo'); q.linha(18, 1, 14, 'veludo_luz')
        q.r(2, 21, 3, 27, 'madeira_sombra'); q.r(12, 21, 13, 27, 'madeira_sombra')
    else:
        q.r(3, 2, 12, 12, 'madeira_sombra'); q.coluna(3, 2, 12, 'madeira')
        for x in (6, 9):
            q.coluna(x, 3, 11, 'madeira')
        q.r(1, 14, 14, 19, 'veludo_luz'); q.r(1, 14, 14, 15, 'veludo'); q.linha(19, 1, 14, 'veludo')
        q.r(2, 20, 3, 27, 'madeira'); q.r(12, 20, 13, 27, 'madeira')
        q.r(5, 20, 5, 24, 'madeira_sombra'); q.r(10, 20, 10, 24, 'madeira_sombra')
    return q.contornar()


def armario_louca():
    """Armário de louça: portas de vidro em cima, com pratos empilhados e
    xícaras, e portas de madeira embaixo. Encostado na parede y = 0. pe = 17."""
    q, frente, _ = caixa_iso(-0.42, 0.42, -0.5, -0.12, 50, 'madeira', 'madeira_sombra', 'madeira_luz')
    _riscar(frente, 0.5, 0.5, 0.04, 0.95, 'madeira_sombra')
    for s0, s1 in ((0.08, 0.44), (0.56, 0.92)):
        for i in range(36):                                 # vidro
            t_ = 0.5 + i * 0.0125
            _riscar(frente, s0, s1, t_, t_, 'vidro', 50)
        for t_ in (0.6, 0.72, 0.84):                         # prateleiras de louça
            _riscar(frente, s0, s1, t_, t_, 'madeira_luz', 50)
            for s_ in (s0 + 0.07, s0 + 0.16, s0 + 0.25):
                _riscar(frente, s_, s_ + 0.05, t_ + 0.02, t_ + 0.02, 'branco', 8)
                _riscar(frente, s_, s_ + 0.05, t_ + 0.04, t_ + 0.04, 'prata', 8)
        for t_ in (0.5, 0.93):
            _riscar(frente, s0, s1, t_, t_, 'madeira_luz')
        for s_ in (s0, s1):
            _riscar(frente, s_, s_, 0.5, 0.93, 'madeira_luz')
        _riscar(frente, s0, s1, 0.08, 0.08, 'madeira_luz'); _riscar(frente, s0, s1, 0.42, 0.42, 'madeira_luz')
        _riscar(frente, s0, s0, 0.08, 0.42, 'madeira_luz'); _riscar(frente, s1, s1, 0.08, 0.42, 'madeira_luz')
    _riscar(frente, 0.0, 1.0, 0.97, 0.97, 'ouro_sombra')
    for s_ in (0.46, 0.54):
        frente(s_, 0.3, 'ouro')
    return q.contornar()


def carruagem_parada():
    """A carruagem de Olympia parada na rua, com o brasão na lateral (livro:
    a carruagem é azul-marinho e dourada, com o brasão de Olympia; só quando
    o brasão é reconhecido a rua se abre). Uma imagem só (fundo + frente, 1º
    quadro), com a mesma origem de carruagem_fundo.png (CARRO_O)."""
    fundo = carruagem_fundo()
    quadro = carruagem_frente(brasao=True).crop((0, 0, CARRO_W, CARRO_H))
    fundo.alpha_composite(quadro)
    return fundo


def carruagem_parada_frente():
    """Só a frente da carruagem parada (borda baixa com o brasão, rodas da
    frente, cavalos e cocheiro), mesma origem: o Palácio a desenha por cima de
    quem está sentado no banco, para a borda cobrir o quadril."""
    return carruagem_frente(brasao=True).crop((0, 0, CARRO_W, CARRO_H))


ARTES = {
    'piso_mansao.png': piso,
    'parede_mansao.png': parede,
    'cama_nicholas.png': lambda: cama(False),
    'cama_althea.png': lambda: cama(True, dossel=True),
    'cama_althea_sentada.png': lambda: cama(False, dossel=True, sentada=True),
    'cama_althea_vazia.png': lambda: cama(False, dossel=True),
    'espelho.png': espelho,
    'armario.png': armario,
    'bau.png': bau,
    'porta.png': lambda: porta(False),
    'porta_aberta.png': lambda: porta(True),
    'mesa_cha.png': mesa_cha,
    'carrinho_bolo.png': carrinho_bolo,
    'carrinho_bolo_aceso.png': lambda: velas_acesas(carrinho_bolo()),
    'embrulho.png': embrulho,
    'pany_provisoria.png': pany,
    'garota_visao.png': garota_visao,
    'garota_visao_frente.png': garota_visao_frente,
    'parede/tocha_esq.png': lambda: na_face(tocha(), 'esq', 12, 4),
    'parede/arandela_esq.png': lambda: na_face(arandela(), 'esq', 13, 8),
    'parede/arandela_dir.png': lambda: na_face(arandela(), 'dir', 13, 8),
    'parede/quadro_olympia_dir.png': lambda: na_face(quadro('olympia'), 'dir', 7, 5),
    'parede/quadro_olympia_esq.png': lambda: na_face(quadro('olympia'), 'esq', 7, 5),
    'parede/quadro_atenas_esq.png': lambda: na_face(quadro('atenas'), 'esq', 7, 5),
    'parede/quadro_norte_esq.png': lambda: na_face(quadro('norte'), 'esq', 7, 5),
    'parede/tapecaria_esq.png': lambda: na_face(tapecaria(), 'esq', 9, 3),
    'parede/tapecaria_dir.png': lambda: na_face(tapecaria(), 'dir', 9, 3),
    'banco_carruagem.png': banco_carruagem,
    'carruagem_fundo.png': carruagem_fundo,
    'margem/cipreste.png': cipreste,
    'margem/oliveira.png': oliveira,
    'margem/coluna.png': coluna,
    'margem/canteiro.png': canteiro,
    'carruagem_frente.png': carruagem_frente,
    'parede/janela_carruagem_esq.png': lambda: na_face(janela_carruagem(), 'esq', 7, 2),
    'parede/janela_carruagem_dir.png': lambda: na_face(janela_carruagem(), 'dir', 7, 2),
    'parede/janela_alta_esq.png': lambda: na_face(janela_alta(), 'esq', 24, 6),
    'parede/janela_alta_dir.png': lambda: na_face(janela_alta(), 'dir', 24, 6),
    'parede/porta_esq.png': lambda: na_face(porta_na_parede(), 'esq', 9, 6),
    'parede/espada_placa_esq.png': lambda: na_face(espada_placa(), 'esq', 3, 10),
    # Rodada 1, cenas 7 a 10 (veja o bloco acima das funções)
    'parede/brasao_olympia_esq.png': lambda: na_face(brasao(), 'esq', 8, 5),
    'parede/brasao_olympia_dir.png': lambda: na_face(brasao(), 'dir', 8, 5),
    'parede/estandarte_imperial_esq.png': lambda: na_face(estandarte_imperial(), 'esq', 11, 2),
    'parede/estandarte_imperial_dir.png': lambda: na_face(estandarte_imperial(), 'dir', 11, 2),
    'parede/portal_palacio_esq.png': lambda: na_face(portal_palacio(), 'esq', 2, 3),
    'parede/portal_palacio_dir.png': lambda: na_face(portal_palacio(), 'dir', 2, 3),
    'parede/portal_anexo_esq.png': lambda: na_face(portal_anexo(), 'esq', 2, 3),
    'parede/portal_anexo_dir.png': lambda: na_face(portal_anexo(), 'dir', 2, 3),
    'parede/vitrine_esq.png': lambda: na_face(vitrine(), 'esq', 3, 13),
    'parede/vitrine_dir.png': lambda: na_face(vitrine(), 'dir', 3, 13),
    'parede/toldo_esq.png': lambda: na_face(toldo(), 'esq', 2, 4),
    'parede/toldo_dir.png': lambda: na_face(toldo(), 'dir', 2, 4),
    'parede/placa_butique_esq.png': lambda: na_face(placa_butique(), 'esq', 9, 4),
    'parede/placa_butique_dir.png': lambda: na_face(placa_butique(), 'dir', 9, 4),
    'palacio/fonte.png': fonte,
    'palacio/canteiro_flores.png': canteiro_flores,
    'palacio/posto_guarda.png': posto_guarda,
    'rua/lampiao.png': lampiao,
    'rua/vaso_flor.png': vaso_flor,
    'rua/carruagem_parada.png': carruagem_parada,
    'rua/carruagem_parada_frente.png': carruagem_parada_frente,
    'loja/prateleira_baixa_esq.png': lambda: prateleira_baixa('esq'),
    'loja/prateleira_baixa_dir.png': lambda: prateleira_baixa('dir'),
    'loja/balcao_loja.png': balcao_loja,
    'loja/pelucia_enguia.png': pelucia_enguia,
    'loja/pelucia_dragao_marinho.png': pelucia_dragao_marinho,
    'loja/pelucia_polvo.png': pelucia_polvo,
    'loja/pelucia_monstro.png': pelucia_monstro,
    'loja/expositor_enguia.png': expositor_enguia,
    'loja/cesta_pelucias.png': cesta_pelucias,
    'loja/estante_alta_esq.png': lambda: estante_alta('esq'),
    'loja/estante_alta_dir.png': lambda: estante_alta('dir'),
    'loja/caixas_presente.png': caixas_presente,
    'loja/cavalinho.png': cavalinho,
    'loja/banquinho.png': banquinho,
    'loja/caixa_madeira.png': caixa_madeira,
    'loja/caixote_pesado.png': caixote_pesado,
    'loja/tapete_loja.png': tapete_loja,
    'parede/arco_sala_esq.png': lambda: na_face(arco_sala(), 'esq', 7, 4),
    'parede/toldo_pelucias_esq.png': lambda: na_face(toldo('monstro', 'monstro_luz'), 'esq', 2, 4),
    'parede/vitrine_chapeus_esq.png': lambda: na_face(vitrine('chapeus'), 'esq', 3, 13),
    'parede/placa_chapeus_esq.png': lambda: na_face(placa_butique('chapeus'), 'esq', 9, 4),
    'parede/vitrine_chapeus_dir.png': lambda: na_face(vitrine('chapeus'), 'dir', 3, 13),
    'parede/placa_chapeus_dir.png': lambda: na_face(placa_butique('chapeus'), 'dir', 9, 4),
    'parede/vitrine_vestidos_esq.png': lambda: na_face(vitrine('vestidos'), 'esq', 3, 13),
    'parede/placa_vestidos_esq.png': lambda: na_face(placa_butique('vestidos'), 'esq', 9, 4),
    'parede/vitrine_vestidos_dir.png': lambda: na_face(vitrine('vestidos'), 'dir', 3, 13),
    'parede/placa_vestidos_dir.png': lambda: na_face(placa_butique('vestidos'), 'dir', 9, 4),
    'parede/vitrine_joias_esq.png': lambda: na_face(vitrine('joias'), 'esq', 3, 13),
    'parede/placa_joias_esq.png': lambda: na_face(placa_butique('joias'), 'esq', 9, 4),
    'parede/vitrine_joias_dir.png': lambda: na_face(vitrine('joias'), 'dir', 3, 13),
    'parede/placa_joias_dir.png': lambda: na_face(placa_butique('joias'), 'dir', 9, 4),
    'parede/vitrine_perfumes_esq.png': lambda: na_face(vitrine('perfumes'), 'esq', 3, 13),
    'parede/placa_perfumes_esq.png': lambda: na_face(placa_butique('perfumes'), 'esq', 9, 4),
    'parede/vitrine_perfumes_dir.png': lambda: na_face(vitrine('perfumes'), 'dir', 3, 13),
    'parede/placa_perfumes_dir.png': lambda: na_face(placa_butique('perfumes'), 'dir', 9, 4),
    'parede/vitrine_pelucias_esq.png': lambda: na_face(vitrine('pelucias'), 'esq', 3, 13),
    'parede/placa_pelucias_esq.png': lambda: na_face(placa_butique('pelucias'), 'esq', 9, 4),
    'parede/vitrine_pelucias_dir.png': lambda: na_face(vitrine('pelucias'), 'dir', 3, 13),
    'parede/placa_pelucias_dir.png': lambda: na_face(placa_butique('pelucias'), 'dir', 9, 4),
    'restaurante/mesa_redonda.png': mesa_redonda,
    'restaurante/cadeira_frente.png': lambda: cadeira(False),
    'restaurante/cadeira_costas.png': lambda: cadeira(True),
    'restaurante/armario_louca.png': armario_louca,
}

# --- montagem das salas da rodada 1 (as mesmas posições servem de receita para
# o SalaMontada e para a prévia: python3 tools/arte/gerar_capitulo_01.py
# --previa planos/capitulo_01_previa/cenarios_rodada1.png) -------------------
# Para cada sala: largura, profundidade, piso e estilo da parede (os mesmos
# nomes de SalaMontada.piso e SalaMontada.parede_estilo), as coisas penduradas
# (arquivo em parede/, casa) e os objetos (arquivo, casa, pe). Posições são
# sugestão de layout (inferência); o livro não desenha as salas.
PE = {'fonte': 14, 'expositor_enguia': 5, 'carruagem_parada': CARRO_H - CARRO_O[1]}
CENAS = {
    'palacio': dict(
        titulo='Cena 7: pátio do Palácio Imperial', largura=15, profundidade=14, piso='patio', parede='marmore',
        pendurar=[('janela_alta_esq', (2, 0)), ('janela_alta_esq', (4, 0)), ('estandarte_imperial_esq', (6, 0)),
                  ('portal_palacio_esq', (7, 0)), ('estandarte_imperial_esq', (8, 0)), ('janela_alta_esq', (10, 0)),
                  ('janela_alta_esq', (12, 0)), ('portal_anexo_dir', (0, 11))],
        objetos=[('palacio/fonte', (7, 5)),
                 ('margem/coluna', (1, 1)), ('margem/coluna', (3, 1)), ('margem/coluna', (5, 1)),
                 ('margem/coluna', (9, 1)), ('margem/coluna', (11, 1)), ('margem/coluna', (13, 1)),
                 ('palacio/canteiro_flores', (3, 4)), ('palacio/canteiro_flores', (3, 8)),
                 ('palacio/canteiro_flores', (11, 4)), ('palacio/canteiro_flores', (11, 8)),
                 ('palacio/posto_guarda', (5, 9)), ('palacio/posto_guarda', (9, 9)),
                 ('palacio/posto_guarda', (5, 7)), ('palacio/posto_guarda', (9, 7)),
                 ('margem/cipreste', (1, 12)), ('margem/cipreste', (13, 12)),
                 ('rua/carruagem_parada', (7, 13))]),
    'butiques': dict(
        titulo='Cena 9: Rua das Butiques', largura=34, profundidade=12, piso='rua', parede='fachada',
        pendurar=[('porta_esq', (x, 0)) if x in (8, 15, 21, 27, 32)
                  else ('placa_butique_esq', (x, 0)) for x in range(1, 34) if x in (7, 14, 26, 8, 15, 21, 27, 32)]
                 + [(a + '_esq', (x, 0)) for x in range(1, 34) if x not in (7, 14, 26, 8, 15, 21, 27, 32)
                    for a in ('vitrine', 'toldo')]
                 + [(a + '_dir', (0, y)) for y in range(1, 12) if y not in (4, 7) for a in ('vitrine', 'toldo')]
                 + [('placa_butique_dir', (0, 4))],
        objetos=[('rua/vaso_flor', (x, 1)) for x in (3, 11, 19, 24, 29)]
                + [('rua/lampiao', (x, 2)) for x in (4, 12, 18, 24, 30)] + [('rua/lampiao', (2, 8))]
                # a carruagem para dentro da rua, atrás de Nicholas (nunca na frente)
                + [('rua/carruagem_parada', (20, 8))]),
    'loja': dict(
        titulo='Cena 9: loja de pelúcias', largura=8, profundidade=7, piso='assoalho', parede='reboco',
        pendurar=[('arandela_esq', (2, 0)), ('porta_esq', (4, 0)), ('arandela_esq', (6, 0)), ('arandela_dir', (0, 4))],
        # as prateleiras baixas onde se procura o presente (a criatura longa vem
        # na mão de Ophelia, sem expositor)
        objetos=[('loja/prateleira_baixa_esq', (2, 1)), ('loja/prateleira_baixa_esq', (3, 1)), ('loja/balcao_loja', (6, 1)),
                 ('loja/prateleira_baixa_dir', (1, 3)), ('loja/prateleira_baixa_dir', (1, 5)), ('loja/prateleira_baixa_dir', (1, 6)),
                 ('loja/cesta_pelucias', (6, 5)),
                 ('loja/pelucia_dragao_marinho', (4, 6)), ('loja/pelucia_polvo', (7, 4)), ('loja/pelucia_monstro', (7, 5))]),
    'restaurante': dict(
        titulo='Cena 10: restaurante', largura=8, profundidade=7, piso='ladrilho', parede='reboco',
        pendurar=[('quadro_atenas_esq', (2, 0)), ('arandela_esq', (3, 0)), ('janela_carruagem_esq', (4, 0)),
                  ('janela_carruagem_esq', (5, 0)), ('arandela_esq', (6, 0)), ('arandela_dir', (0, 3))],
        objetos=[('restaurante/armario_louca', (6, 1)), ('restaurante/mesa_redonda', (4, 4)),
                 ('restaurante/cadeira_frente', (3, 4)), ('restaurante/cadeira_frente', (4, 3)),
                 ('restaurante/cadeira_costas', (5, 4))]),
}
PE_CAIXAS = ('loja/prateleira_baixa_esq', 'loja/prateleira_baixa_dir', 'loja/balcao_loja', 'restaurante/armario_louca')


def _quadro_piso(piso_, x, y, largura, profundidade):
    """Espelha SalaMontada._quadro_do_piso para os pisos novos (prévia)."""
    if piso_ == 'patio':
        if abs(x - largura // 2) <= 1 or y <= 1 or y >= profundidade - 2:
            return 9 + (x + y) % 2
        return 7 + (x * 3 + y) % 2
    if piso_ == 'rua':
        return 2 + (x + y) % 2 if y <= 1 or x <= 1 else 11 + (x + y) % 2
    if piso_ == 'ladrilho':
        return 13 + (x + y) % 2
    return (x + y) % 2                                   # assoalho


def _cena_previa(nome, escala=2):
    from PIL import Image, ImageDraw
    cena = CENAS[nome]
    l, pr = cena['largura'], cena['profundidade']
    abrir = lambda a: Image.open(os.path.join(PASTA, a + '.png')).convert('RGBA')
    pisos, paredes = abrir('piso_mansao'), abrir('parede_mansao')
    indice = {'marmore': 3, 'fachada': 4, 'reboco': 5}[cena['parede']]
    margem = 240
    tela = Image.new('RGBA', (32 * (l + pr) + 2 * margem, 16 * (l + pr) + 2 * margem), (6, 10, 18, 255))
    ox, oy = margem + 32 * pr, margem
    centro = lambda c: (ox + 32 * (c[0] - c[1]), oy + 16 * (c[0] + c[1]))
    for x in range(l):
        for y in range(pr):
            cx, cy = centro((x, y))
            i = _quadro_piso(cena['piso'], x, y, l, pr)
            tela.alpha_composite(pisos.crop((64 * i, 0, 64 * i + 64, 32)), (cx - 32, cy - 16))
    itens = []
    for x in range(l):
        for y in range(pr):
            if x == 0 or y == 0:
                itens.append((centro((x, y))[1], 0, 'parede', (x, y), None))
    for arq, casa in cena['pendurar']:
        itens.append((centro(casa)[1], 1, 'pendurar', casa, abrir('parede/' + arq)))
    for arq, casa in cena['objetos']:
        pe = PE.get(arq.split('/')[-1], 17 if arq in PE_CAIXAS else 3)
        itens.append((centro(casa)[1], 2, 'objeto', casa, (abrir(arq), pe)))
    for cy, _, tipo, casa, extra in sorted(itens, key=lambda t: t[:2]):
        cx, cy = centro(casa)
        if tipo == 'parede':
            tela.alpha_composite(paredes.crop((64 * indice, 0, 64 * indice + 64, 64)), (cx - 32, cy - 48))
        elif tipo == 'pendurar':
            tela.alpha_composite(extra, (cx - 32, cy + 1 - 49))
        else:
            im, pe = extra
            tela.alpha_composite(im, (int(cx - im.width / 2), cy - im.height + pe))
    # recorta ao redor do que há de desenhado fora do fundo
    fundo = Image.new('RGBA', tela.size, (6, 10, 18, 255))
    from PIL import ImageChops
    caixa = ImageChops.difference(tela.convert('RGB'), fundo.convert('RGB')).getbbox()
    tela = tela.crop((caixa[0] - 8, caixa[1] - 8, caixa[2] + 8, caixa[3] + 8))
    return tela.resize((tela.width * escala, tela.height * escala), Image.NEAREST), cena['titulo']


def previa(caminho):
    from PIL import Image, ImageDraw, ImageFont
    cenas = [_cena_previa(n) for n in CENAS]
    try:
        fonte_ = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf', 22)
    except OSError:
        fonte_ = ImageFont.load_default(size=22)
    colunas = 2
    larg = max(c[0].width for c in cenas) + 40
    alt = max(c[0].height for c in cenas) + 70
    folha = Image.new('RGBA', (larg * colunas, alt * 2), (3, 6, 12, 255))
    d = ImageDraw.Draw(folha)
    for i, (im, titulo) in enumerate(cenas):
        x0, y0 = (i % colunas) * larg, (i // colunas) * alt
        d.text((x0 + 20, y0 + 20), titulo + '  (provisório)', fill=C['ouro_luz'], font=fonte_)
        folha.alpha_composite(im, (x0 + 20, y0 + 55))
    os.makedirs(os.path.dirname(os.path.abspath(caminho)), exist_ok=True)
    folha.convert('RGB').save(caminho)
    print(caminho, folha.size)


if __name__ == '__main__':
    for nome, desenhar in ARTES.items():
        caminho = os.path.join(PASTA, nome)
        os.makedirs(os.path.dirname(caminho), exist_ok=True)
        desenhar().save(caminho)
        print(caminho)
    if len(sys.argv) == 3 and sys.argv[1] == '--previa':
        previa(sys.argv[2])
