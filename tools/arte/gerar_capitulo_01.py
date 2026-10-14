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


def piso():
    # 0-1 assoalho dos quartos, 2-3 pedra, 4-6 passadeira (borda em cima,
    # borda embaixo, meio): como o castelo do prólogo
    q = Q(64 * 7, 32)
    _assoalho(q, 0, False)
    _assoalho(q, 64, True)
    _pedra(q, 128, 0)
    _pedra(q, 192, 1)
    _passadeira(q, 256, 'cima')
    _passadeira(q, 320, 'baixo')
    _passadeira(q, 384, None)
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


def parede():
    # bloco de 64×64: topo em losango de 64×32 e a face embaixo
    # 0 = pedra da Casa Olympia; 1 = a parede lisa do sonho (corredor estranho)
    q = Q(128, 64)
    _parede_pedra(q, 0)
    _parede_antiga(q, 64)
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
    'parede/tocha_esq.png': lambda: na_face(tocha(), 'esq', 12, 4),
    'parede/arandela_esq.png': lambda: na_face(arandela(), 'esq', 13, 8),
    'parede/arandela_dir.png': lambda: na_face(arandela(), 'dir', 13, 8),
    'parede/quadro_olympia_dir.png': lambda: na_face(quadro('olympia'), 'dir', 7, 5),
    'parede/quadro_olympia_esq.png': lambda: na_face(quadro('olympia'), 'esq', 7, 5),
    'parede/quadro_atenas_esq.png': lambda: na_face(quadro('atenas'), 'esq', 7, 5),
    'parede/quadro_norte_esq.png': lambda: na_face(quadro('norte'), 'esq', 7, 5),
    'parede/tapecaria_esq.png': lambda: na_face(tapecaria(), 'esq', 9, 3),
    'parede/tapecaria_dir.png': lambda: na_face(tapecaria(), 'dir', 9, 3),
    'parede/porta_esq.png': lambda: na_face(porta_na_parede(), 'esq', 9, 6),
    'parede/espada_placa_esq.png': lambda: na_face(espada_placa(), 'esq', 3, 10),
}

if __name__ == '__main__':
    for nome, desenhar in ARTES.items():
        caminho = os.path.join(PASTA, nome)
        os.makedirs(os.path.dirname(caminho), exist_ok=True)
        desenhar().save(caminho)
        print(caminho)
