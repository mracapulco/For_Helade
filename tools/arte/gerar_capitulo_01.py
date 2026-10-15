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


def parede():
    # bloco de 64×64: topo em losango de 64×32 e a face embaixo
    # 0 = pedra da Casa Olympia; 1 = a parede lisa do sonho (corredor
    # estranho); 2 = madeira e veludo, por dentro da carruagem
    q = Q(192, 64)
    _parede_pedra(q, 0)
    _parede_antiga(q, 64)
    _parede_madeira(q, 128)
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


def _cavalo(d, a0, b, quadro, claro):
    """Cavalo de perfil a trote, virado para +a; a0 = meio do corpo."""
    E = 1.45                       # cavalo maior que o desenho-base
    def _pc(pts):
        return _perfil(a0, b, [(u * E, v * E) for u, v in pts])
    pele, sombra = ('cavalo', 'cavalo_sombra') if claro else ('cavalo2', 'cavalo2_sombra')
    # pernas: pares diagonais a trote (3 quadros)
    passo = (-3, 0, 3)[quadro]
    pernas = [(-11, passo), (-7, -passo), (9, -passo), (13, passo)]
    for i, (u, dx) in enumerate(pernas):
        cor = sombra if i in (0, 2) else pele
        d.line(_pc([(u, 20), (u + dx * 0.5, 9), (u + dx, 1)]), fill=C[cor], width=4)
        d.line(_pc([(u + dx - 1, 0), (u + dx + 1, 0)]), fill=C['roda'], width=2)
    # cauda
    d.polygon(_pc([(-16, 27), (-19, 24), (-21, 12), (-18, 13), (-15, 23)]), fill=C['crina'])
    # corpo, peito e garupa
    d.polygon(_elipse_perfil(a0, b, 0, 24 * E, 17 * E, 7.5 * E), fill=C[pele])
    d.polygon(_elipse_perfil(a0, b, 0, 21 * E, 15 * E, 3 * E), fill=C[sombra])
    # pescoço e cabeça
    d.polygon(_pc([(10, 27), (15, 21), (24, 33), (21, 39), (16, 38)]), fill=C[pele])
    d.polygon(_pc([(19, 39), (24, 40), (33, 31), (32, 28), (28, 29), (22, 34)]), fill=C[pele])
    d.polygon(_pc([(29, 30), (33, 31), (32, 28)]), fill=C[sombra])
    d.polygon(_pc([(20, 40), (21, 43), (23, 40)]), fill=C[pele])        # orelha
    d.line(_pc([(10, 30), (16, 38), (20, 41)]), fill=C['crina'], width=2)   # crina
    x, y = _pc([(26, 35)])[0]
    d.point((x, y), fill=C['contorno'])                                              # olho
    # arreio: coleira, cilha e rédeas
    d.line(_pc([(13, 21), (17, 30)]), fill=C['couro'], width=2)
    d.line(_pc([(-2, 17), (-2, 31)]), fill=C['couro'], width=2)
    d.line(_pc([(-2, 30), (4, 31), (13, 28)]), fill=C['couro'])
    xs, ys = _pc([(-2, 31)])[0]
    d.point((xs, ys), fill=C['ouro'])


def _cocheiro(d):
    """O cocheiro no banco da frente, de perfil, virado para os cavalos."""
    A = CARRO_A
    a0, b = A + 0.25, 0.0
    # banco alto do cocheiro
    _carro_quad(d, [(A, -0.4, 30), (A + 0.42, -0.4, 30), (A + 0.42, 0.4, 30), (A, 0.4, 30)], 'carro_luz')
    _carro_quad(d, [(A, 0.4, 6), (A + 0.42, 0.4, 6), (A + 0.42, 0.4, 30), (A, 0.4, 30)], 'carro')
    _carro_quad(d, [(A + 0.42, -0.4, 6), (A + 0.42, 0.4, 6), (A + 0.42, 0.4, 30), (A + 0.42, -0.4, 30)], 'carro_sombra')
    # corpo sentado: capa, pernas para a frente, cabeça e chapéu
    d.polygon(_perfil(a0, b, [(-5, 30), (5, 30), (4, 46), (-3, 47), (-6, 40)]), fill=C['cocheiro'])
    d.polygon(_perfil(a0, b, [(2, 30), (11, 29), (11, 22), (8, 22), (8, 26), (2, 26)]), fill=C['cocheiro_luz'])
    d.polygon(_elipse_perfil(a0, b, 1, 50, 3, 3.5), fill=C['pele_cocheiro'])
    d.polygon(_perfil(a0, b, [(-4, 52), (6, 52), (6, 54), (2, 54), (2, 58), (-2, 58), (-2, 54), (-4, 54)]),
              fill=C['cocheiro'])
    d.line(_perfil(a0, b, [(4, 40), (12, 36)]), fill=C['cocheiro_luz'], width=2)   # braço nas rédeas


def carruagem_frente():
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
        _cavalo(d, A + 1.95, -0.38, (i + 1) % 3, False)
        d.line([_carro_t(A, 0.0, 12), _carro_t(A + 2.9, 0.0, 26)], fill=C['carro_luz'], width=2)
        # lado da frente (a = A), baixo em corte, e o cocheiro do lado de fora
        _carro_quad(d, [(A, -B, 6), (A, B, 6), (A, B, bd), (A, -B, bd)], 'carro_sombra')
        _carro_quad(d, [(A, -B, bd), (A + 0.06, -B, bd), (A + 0.06, B, bd), (A, B, bd)], 'ouro_sombra')
        _cocheiro(d)
        # lado de perto (b = B): borda baixa com friso grego e porta
        _carro_quad(d, [(-A, B, 6), (A, B, 6), (A, B, bd), (-A, B, bd)], 'carro')
        _carro_quad(d, [(-A, B, bd), (A, B, bd), (A, B + 0.06, bd), (-A, B + 0.06, bd)], 'ouro_sombra')
        _friso_grego(d, B, -A, A, 21)
        for a in (-0.3, 0.3):
            d.line([_carro_t(a, B, 8), _carro_t(a, B, 18)], fill=C['carro_sombra'])
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
        _cavalo(d, A + 1.95, 0.38, i, True)
        # rédeas: da boca de cada cavalo até as mãos do cocheiro
        mao = _carro_t(A + 0.25 + 12 / CASA, 0.0, 36)
        for b in (-0.38, 0.38):
            boca = _carro_t(A + 1.95 + 31 * 1.45 / CASA, b, 31 * 1.45)
            d.line([boca, mao], fill=C['couro'])
        tira.paste(q.im, (i * CARRO_W, 0))
    return tira


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
    'banco_carruagem.png': banco_carruagem,
    'carruagem_fundo.png': carruagem_fundo,
    'carruagem_frente.png': carruagem_frente,
    'parede/janela_carruagem_esq.png': lambda: na_face(janela_carruagem(), 'esq', 7, 2),
    'parede/janela_carruagem_dir.png': lambda: na_face(janela_carruagem(), 'dir', 7, 2),
    'parede/porta_esq.png': lambda: na_face(porta_na_parede(), 'esq', 9, 6),
    'parede/espada_placa_esq.png': lambda: na_face(espada_placa(), 'esq', 3, 10),
}

if __name__ == '__main__':
    for nome, desenhar in ARTES.items():
        caminho = os.path.join(PASTA, nome)
        os.makedirs(os.path.dirname(caminho), exist_ok=True)
        desenhar().save(caminho)
        print(caminho)
