# Gera as artes provisórias em pixel art dos acampamentos (pontos de descanso
# entre os reinos): barraca, fogueira, mercador, viajante, animais, enfeites de
# cada bioma e os pisos isométricos (64×32) de cada acampamento.
# Mesma paleta e mesmo contorno escuro de gerar_objetos.py, com os tons de
# terra, mar e vegetação do mapa (gerar_mapa.py).
# Nada aqui é do livro: são peças genéricas para testar até a arte final.
# Uso: python3 tools/arte/gerar_acampamento.py   (rodar na raiz do projeto)
import math
import os
import random
import sys

from PIL import Image

sys.dont_write_bytecode = True  # sem __pycache__ dentro de tools/
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_objetos import C, H, Q  # noqa: E402

# Tons do mapa de Hélade (gerar_mapa.py), para o chão e a vegetação.
C.update(
    mar_fundo=H('#0E2238'), mar=H('#173452'), mar_raso=H('#24507A'), espuma=H('#7FA6C8'),
    areia=H('#B8A27A'), areia_sombra=H('#8E7A58'),
    gelo=H('#DCE4EC'), gelo_sombra=H('#A9B8C8'), geada=H('#7E909A'), geada_escura=H('#5C6E78'),
    grama_luz=H('#6E8A52'), grama=H('#4F6B3F'), grama_sombra=H('#3A5232'),
    campo=H('#8C8A4E'), campo_sombra=H('#6F6C3C'), campo_quente=H('#A3804A'),
    mata=H('#2C4A33'), mata_escura=H('#1C3226'), mata_luz=H('#3F6545'),
    rocha_luz=H('#9A9AA0'), rocha=H('#6E6E78'), rocha_sombra=H('#46465A'),
    terra=H('#6B5238'), telhado=H('#7A3A32'), telhado_luz=H('#A0503E'),
)

PASTA = 'assets/art/placeholders/acampamento'


# ---------- peças do acampamento ----------

def barraca():
    # barraca de lona em "A", vista de frente, com a entrada aberta
    q = Q(56, 44)
    q.sombra_no_chao(28, 40, 26, 3)
    topo, base = 6, 40
    for y in range(topo, base + 1):
        meia = (y - topo) * 24 // (base - topo)
        q.linha(y, 28 - meia, 28 + meia, 'prata')
        q.r(28 - meia, y, 28 - meia + 1, y, 'prata_sombra')       # lado na sombra
        if y > topo + 2:
            q.p(28 + meia - 1, y, 'lua')                          # beira ao luar
    for y in range(topo + 8, base + 1, 7):
        q.linha(y, 28 - (y - topo) * 24 // (base - topo) + 2,
                28 + (y - topo) * 24 // (base - topo) - 2, 'prata_sombra')  # costuras
    # entrada escura com aba dobrada
    for y in range(topo + 12, base + 1):
        meia = (y - topo - 12) * 8 // (base - topo - 12)
        q.linha(y, 28 - meia, 28 + meia, 'noite')
    for y in range(topo + 14, base - 2):
        q.p(28 + (y - topo - 12) * 8 // (base - topo - 12) + 1, y, 'ouro_sombra')
    q.r(25, base - 4, 27, base - 2, 'vela_escura')                 # brilho lá dentro
    # mastro e cordas
    q.coluna(28, 1, topo + 2, 'madeira'); q.p(28, 0, 'ouro_luz')
    q.r(27, 2, 30, 3, 'telhado'); q.r(31, 3, 33, 4, 'telhado_luz')  # flâmula
    for i in range(7):
        q.p(26 - i * 3, topo + 2 + i * 4, 'madeira_luz')
        q.p(30 + i * 3, topo + 2 + i * 4, 'madeira_luz')
    q.r(1, base - 1, 2, base, 'madeira'); q.r(53, base - 1, 54, base, 'madeira')  # estacas
    q.linha(base, 5, 51, 'prata_sombra')
    return q.contornar()


def base_da_fogueira():
    q = Q(26, 26)
    q.sombra_no_chao(13, 22, 11, 3)
    # pedras em volta
    for (x, y) in [(3, 20), (7, 22), (12, 23), (17, 22), (21, 20), (5, 17), (20, 17)]:
        q.r(x - 1, y - 1, x + 1, y, 'pedra'); q.p(x - 1, y - 1, 'pedra_luz'); q.p(x + 1, y, 'pedra_sombra')
    q.r(7, 18, 19, 20, 'noite')                                    # cinzas
    # lenha cruzada
    for i in range(10):
        q.p(8 + i, 20 - i // 3, 'madeira'); q.p(8 + i, 21 - i // 3, 'madeira_sombra')
        q.p(18 - i, 20 - i // 3, 'madeira_luz'); q.p(18 - i, 21 - i // 3, 'madeira')
    return q


def fogueira():
    q = base_da_fogueira()
    # chamas
    q.elipse(13, 13, 5, 5, 'vela_escura')
    q.elipse(13, 14, 4, 4, 'vela')
    q.r(12, 4, 14, 10, 'vela'); q.p(13, 2, 'vela'); q.p(13, 3, 'vela')
    q.p(9, 8, 'vela_escura'); q.p(10, 7, 'vela_escura'); q.p(17, 9, 'vela_escura'); q.p(16, 6, 'vela')
    q.r(12, 11, 14, 16, 'ouro_luz'); q.p(13, 9, 'ouro_luz'); q.p(13, 15, 'branco')
    q.p(8, 3, 'ouro_luz'); q.p(18, 1, 'vela')                       # faíscas
    return q.contornar()


def tronco():
    # tora deitada para sentar
    q = Q(30, 14)
    q.sombra_no_chao(15, 11, 14, 2)
    q.r(3, 4, 25, 10, 'madeira')
    q.linha(4, 3, 25, 'madeira_luz'); q.linha(10, 3, 25, 'madeira_sombra')
    for x in (8, 15, 21):
        q.p(x, 6, 'madeira_sombra'); q.p(x + 1, 7, 'madeira_sombra')
    q.elipse(25, 7, 3, 3, 'ouro_sombra'); q.elipse(25, 7, 2, 2, 'ouro'); q.p(25, 7, 'madeira')
    return q.contornar()


def banca():
    # carrinho do mercador com toldo listrado, potes e sacos
    q = Q(42, 40)
    q.sombra_no_chao(21, 36, 20, 3)
    q.r(4, 22, 37, 31, 'madeira')                                  # caixa do carrinho
    q.linha(22, 4, 37, 'madeira_luz'); q.linha(31, 4, 37, 'madeira_sombra')
    for x in (12, 20, 28): q.coluna(x, 23, 30, 'madeira_sombra')
    q.elipse(10, 33, 4, 4, 'madeira_sombra'); q.elipse(10, 33, 2, 2, 'madeira_luz')  # roda
    q.p(10, 33, 'ouro')
    q.r(36, 27, 41, 28, 'madeira')                                 # varal de puxar
    for x in (5, 36): q.r(x, 7, x + 1, 22, 'madeira')               # postes do toldo
    for x in range(2, 40):                                          # toldo listrado
        cor = 'telhado' if (x // 4) % 2 == 0 else 'prata'
        q.r(x, 4, x, 9, cor)
    q.linha(4, 2, 39, 'telhado_luz')
    for x in range(2, 40, 4): q.p(x + 1, 10, 'telhado' if (x // 4) % 2 == 0 else 'prata')
    # mercadorias
    q.r(8, 16, 13, 21, 'areia'); q.linha(16, 8, 13, 'prata'); q.p(10, 15, 'areia_sombra')   # saco
    q.elipse(19, 18, 3, 3, 'ouro'); q.r(18, 13, 20, 15, 'ouro'); q.p(18, 17, 'ouro_luz')  # ânfora
    q.r(24, 17, 30, 21, 'telhado'); q.linha(17, 24, 30, 'telhado_luz')                     # pano dobrado
    q.elipse(34, 19, 2, 2, 'olho'); q.p(33, 18, 'olho_luz')                               # pote azul
    return q.contornar()


def placa_saida():
    # poste com uma tábua em forma de seta (saída para a estrada)
    q = Q(26, 32)
    q.sombra_no_chao(12, 29, 5, 1)
    q.r(11, 12, 12, 29, 'madeira'); q.coluna(11, 12, 29, 'madeira_luz')
    q.r(2, 4, 19, 11, 'madeira')
    for i in range(5):                                              # ponta da seta
        q.coluna(20 + i, 4 + i, 11 - i, 'madeira')
    q.linha(4, 2, 19, 'madeira_luz'); q.linha(11, 2, 19, 'madeira_sombra')
    q.linha(7, 5, 17, 'ouro'); q.linha(8, 5, 17, 'ouro_sombra')     # seta pintada
    q.p(19, 6, 'ouro'); q.p(19, 9, 'ouro'); q.p(20, 7, 'ouro'); q.p(20, 8, 'ouro')
    q.p(3, 5, 'pedra_luz'); q.p(3, 10, 'pedra_luz')
    q.r(9, 28, 14, 29, 'pedra'); q.p(9, 28, 'pedra_luz')
    return q.contornar()


def barco():
    # bote encalhado na beira, de proa para a direita
    q = Q(48, 26)
    q.sombra_no_chao(24, 22, 22, 3)
    for y in range(11, 21):
        recuo = (y - 11) // 2
        q.linha(y, 3 + recuo, 42 - recuo * 2, 'madeira')
    for x in range(36, 46):                                         # proa erguida
        q.coluna(x, 11 - (x - 36) // 2, 14, 'madeira')
    q.linha(11, 3, 40, 'madeira_luz'); q.linha(12, 4, 40, 'ouro_sombra')
    q.linha(16, 6, 36, 'madeira_sombra')
    q.r(8, 8, 33, 11, 'madeira_sombra')                             # borda de dentro
    q.r(10, 9, 31, 10, 'noite')
    q.r(14, 8, 16, 11, 'madeira_luz'); q.r(26, 8, 28, 11, 'madeira_luz')   # bancos
    q.coluna(21, 0, 9, 'madeira'); q.r(17, 2, 25, 3, 'prata')       # remo apoiado
    q.r(13, 3, 18, 5, 'madeira_luz')
    q.p(44, 7, 'ouro'); q.p(45, 6, 'ouro_luz')
    return q.contornar()


# ---------- gente (32×48, pés na linha 45, como os figurantes) ----------

def mercador():
    q = Q(32, 48)
    q.sombra_no_chao(16, 45, 9, 2)
    x = 16
    # mochila grande atrás (aparece dos dois lados)
    q.r(x - 9, 14, x + 8, 30, 'madeira'); q.r(x - 9, 14, x - 7, 30, 'madeira_sombra')
    q.r(x - 8, 10, x + 7, 14, 'areia'); q.linha(10, x - 8, x + 7, 'prata')  # rolo de cobertor
    q.p(x + 7, 22, 'ouro'); q.p(x - 9, 24, 'ouro')
    # túnica até o joelho
    for y in range(17, 37):
        meia = 5 + (y - 17) // 6
        q.linha(y, x - meia, x + meia - 1, 'telhado')
        q.p(x - meia, y, 'madeira_sombra')
    q.linha(25, x - 6, x + 5, 'ouro_sombra')                       # cinto
    q.r(x + 1, 26, x + 4, 30, 'madeira'); q.p(x + 2, 27, 'ouro')    # bolsa de moedas
    q.r(x - 4, 17, x + 3, 18, 'telhado_luz')
    # pernas e botas
    for px in (x - 4, x + 1):
        q.r(px, 37, px + 2, 41, 'pele_sombra')
        q.r(px, 42, px + 3, 45, 'madeira_sombra')
    # braços
    q.r(x - 7, 18, x - 6, 27, 'telhado'); q.r(x - 7, 28, x - 6, 29, 'pele')
    q.r(x + 5, 18, x + 6, 27, 'telhado'); q.r(x + 5, 28, x + 6, 29, 'pele')
    # cabeça, barba e chapéu de aba larga
    q.r(x - 3, 9, x + 3, 15, 'pele'); q.coluna(x - 3, 9, 15, 'pele_sombra')
    q.p(x - 1, 11, 'olho_escuro'); q.p(x + 2, 11, 'olho_escuro')
    q.r(x - 3, 13, x + 3, 16, 'madeira_luz'); q.p(x, 13, 'pele_sombra')
    q.linha(7, x - 7, x + 7, 'campo_sombra'); q.linha(8, x - 6, x + 6, 'campo_sombra')
    q.r(x - 4, 3, x + 4, 7, 'campo'); q.linha(6, x - 4, x + 4, 'ouro_sombra')
    q.r(x - 3, 3, x - 1, 4, 'areia')
    return q.contornar()


def viajante():
    q = Q(32, 48)
    q.sombra_no_chao(16, 45, 8, 2)
    x = 16
    # cajado
    q.coluna(x + 8, 6, 45, 'madeira'); q.coluna(x + 9, 8, 45, 'madeira_sombra')
    q.r(x + 7, 4, x + 9, 6, 'madeira_luz')
    # manto com capuz
    for y in range(12, 44):
        meia = 6 + (y - 12) // 6
        q.linha(y, x - meia, x + meia - 2, 'nuvem')
        q.p(x - meia, y, 'azul'); q.p(x - meia + 1, y, 'azul')
        q.p(x + meia - 2, y, 'azul_luz')
    q.linha(43, x - 11, x + 9, 'azul')
    q.r(x - 1, 20, x, 42, 'azul')                                   # dobra do manto
    q.r(x - 5, 17, x + 3, 18, 'ouro_sombra'); q.p(x - 1, 18, 'ouro')  # broche
    q.r(x + 6, 21, x + 8, 23, 'pele')                               # mão no cajado
    q.r(x - 9, 26, x - 5, 31, 'madeira'); q.linha(26, x - 9, x - 5, 'madeira_luz')  # alforje
    q.r(x - 3, 44, x - 1, 45, 'madeira_sombra'); q.r(x + 2, 44, x + 4, 45, 'madeira_sombra')
    # capuz e rosto na sombra
    q.elipse(x, 9, 6, 6, 'nuvem'); q.r(x - 6, 9, x - 5, 14, 'azul')
    q.r(x - 3, 8, x + 3, 14, 'azul')
    q.r(x - 2, 10, x + 2, 14, 'pele_sombra')
    q.p(x - 1, 11, 'noite'); q.p(x + 1, 11, 'noite')
    q.p(x - 2, 4, 'azul_luz'); q.p(x - 3, 5, 'azul_luz')
    return q.contornar()


# ---------- animais (genéricos) ----------

def cao():
    q = Q(26, 22)
    q.sombra_no_chao(13, 19, 10, 2)
    q.r(6, 9, 18, 14, 'ouro_sombra'); q.linha(9, 6, 18, 'ouro')     # corpo
    q.r(9, 13, 15, 14, 'areia')                                     # barriga clara
    for px in (6, 9, 15, 17):
        q.r(px, 15, px + 1, 19, 'ouro_sombra'); q.p(px, 19, 'madeira_sombra')
    q.r(3, 5, 5, 6, 'ouro_sombra'); q.p(2, 4, 'ouro'); q.p(4, 7, 'ouro_sombra')  # rabo erguido
    q.p(5, 8, 'ouro_sombra')
    q.r(17, 4, 22, 9, 'ouro'); q.r(22, 7, 24, 9, 'ouro_sombra')     # cabeça e focinho
    q.p(24, 7, 'noite'); q.p(20, 6, 'noite')
    q.r(17, 2, 18, 5, 'madeira'); q.p(19, 3, 'madeira')             # orelha
    q.linha(9, 18, 21, 'telhado')                                   # coleira
    return q.contornar()


def ovelha():
    q = Q(26, 22)
    q.sombra_no_chao(13, 19, 10, 2)
    for px in (7, 10, 15, 18):
        q.r(px, 14, px, 19, 'noite')
    q.elipse(12, 10, 9, 5, 'prata')                                 # lã
    for (cx, cy) in [(6, 8), (10, 6), (15, 6), (18, 9), (9, 13), (15, 13)]:
        q.elipse(cx, cy, 2, 2, 'lua')
    q.p(8, 9, 'prata_sombra'); q.p(14, 11, 'prata_sombra'); q.p(11, 8, 'branco')
    q.r(19, 6, 23, 11, 'pedra_sombra'); q.r(20, 7, 23, 10, 'noite')  # cara escura
    q.p(22, 8, 'lua'); q.r(18, 6, 19, 7, 'pedra_sombra')
    return q.contornar()


def cabra():
    q = Q(26, 24)
    q.sombra_no_chao(13, 21, 10, 2)
    q.r(5, 10, 17, 15, 'prata_sombra'); q.linha(10, 5, 17, 'prata')
    q.r(6, 15, 16, 16, 'pedra')
    for px in (6, 8, 14, 16):
        q.r(px, 16, px, 21, 'pedra_sombra')
    q.p(4, 9, 'prata'); q.p(3, 8, 'prata')                         # rabinho
    q.r(17, 5, 21, 11, 'prata'); q.r(21, 8, 22, 11, 'prata_sombra')  # cabeça
    q.p(20, 7, 'noite'); q.r(19, 12, 20, 14, 'pedra_luz')            # barbicha
    for i in range(4):                                              # chifres curvos
        q.p(17 - i // 2, 4 - i, 'areia_sombra'); q.p(18 - i // 2, 4 - i, 'areia')
    q.p(15, 1, 'areia_sombra')
    return q.contornar()


def burro():
    q = Q(34, 30)
    q.sombra_no_chao(16, 27, 13, 2)
    q.r(6, 12, 22, 19, 'pedra'); q.linha(12, 6, 22, 'pedra_luz')
    q.r(8, 18, 20, 19, 'lua')                                       # barriga clara
    for px in (7, 10, 18, 21):
        q.r(px, 20, px + 1, 26, 'pedra_sombra'); q.r(px, 26, px + 1, 27, 'noite')
    q.coluna(5, 13, 17, 'pedra_sombra'); q.p(4, 18, 'noite')
    q.r(21, 7, 25, 13, 'pedra'); q.r(25, 9, 29, 13, 'pedra')        # pescoço e cabeça
    q.r(27, 11, 29, 13, 'lua'); q.p(26, 10, 'noite')
    q.r(22, 1, 23, 7, 'pedra'); q.r(24, 2, 25, 7, 'pedra_sombra')   # orelhas compridas
    # cestos de carga
    q.r(7, 8, 13, 16, 'campo'); q.linha(8, 7, 13, 'campo_sombra'); q.coluna(10, 9, 16, 'campo_sombra')
    q.r(14, 7, 20, 15, 'areia'); q.linha(7, 14, 20, 'prata')
    q.r(13, 11, 14, 12, 'telhado')                                  # corda
    return q.contornar()


def coruja():
    # coruja empoleirada num toco
    q = Q(20, 30)
    q.sombra_no_chao(10, 27, 8, 2)
    q.r(4, 17, 15, 27, 'madeira'); q.coluna(4, 17, 27, 'madeira_sombra'); q.coluna(15, 17, 27, 'madeira_sombra')
    q.elipse(10, 17, 6, 2, 'ouro_sombra'); q.elipse(10, 17, 4, 1, 'madeira_luz')
    q.p(3, 27, 'madeira'); q.p(16, 27, 'madeira')
    q.elipse(10, 10, 5, 6, 'madeira_luz')                           # corpo
    q.r(7, 11, 13, 15, 'areia'); q.p(9, 13, 'madeira'); q.p(11, 12, 'madeira'); q.p(12, 14, 'madeira')
    q.r(5, 3, 15, 8, 'madeira_luz'); q.p(5, 2, 'madeira'); q.p(15, 2, 'madeira')   # cabeça e orelhas
    q.r(6, 4, 9, 7, 'areia'); q.r(11, 4, 14, 7, 'areia')
    q.p(7, 5, 'ouro_luz'); q.p(8, 5, 'noite'); q.p(12, 5, 'ouro_luz'); q.p(13, 5, 'noite')
    q.p(10, 7, 'ouro_sombra')
    q.p(8, 16, 'ouro'); q.p(12, 16, 'ouro')
    return q.contornar()


def gaivota():
    q = Q(20, 16)
    q.sombra_no_chao(10, 14, 6, 1)
    q.elipse(9, 8, 5, 3, 'branco')
    q.r(4, 6, 12, 8, 'lua')
    q.r(3, 6, 10, 7, 'pedra'); q.r(2, 7, 4, 8, 'noite')              # asa cinza e ponta preta
    q.r(12, 3, 15, 6, 'branco'); q.p(14, 4, 'noite')                # cabeça
    q.r(16, 5, 17, 5, 'ouro_luz'); q.p(16, 6, 'vela_escura')        # bico
    q.coluna(8, 11, 13, 'vela'); q.coluna(11, 11, 13, 'vela')
    return q.contornar()


def caranguejo():
    q = Q(18, 12)
    q.sombra_no_chao(9, 10, 6, 1)
    q.elipse(9, 6, 5, 3, 'telhado'); q.r(6, 4, 11, 5, 'telhado_luz')
    for i in range(3):
        q.p(3 - (i == 2), 7 + i, 'telhado'); q.p(15 + (i == 2), 7 + i, 'telhado')
    q.r(1, 3, 3, 4, 'telhado_luz'); q.r(15, 3, 17, 4, 'telhado_luz')   # pinças
    q.p(7, 2, 'noite'); q.p(11, 2, 'noite'); q.p(7, 3, 'telhado'); q.p(11, 3, 'telhado')
    return q.contornar()


# ---------- vegetação e pedras (obstáculos) ----------

def pinheiro(neve=False):
    q = Q(32, 56)
    q.sombra_no_chao(16, 52, 10, 3)
    q.r(14, 44, 17, 52, 'madeira'); q.coluna(14, 44, 52, 'madeira_luz')
    for camada, (topo, base, larg) in enumerate([(4, 18, 6), (12, 30, 10), (22, 46, 14)]):
        for y in range(topo, base + 1):
            meia = 1 + (y - topo) * larg // (base - topo)
            q.linha(y, 16 - meia, 16 + meia, 'mata')
            q.r(16 - meia, y, 15, y, 'mata_escura')
            q.p(16 + meia, y, 'mata_luz')
        q.linha(base, 16 - larg, 16 + larg, 'mata_escura')
        if neve:
            for y in range(topo, topo + (base - topo) // 2):
                meia = 1 + (y - topo) * larg // (base - topo)
                q.r(16 - meia + 1, y, 16 + meia, y, 'gelo' if y % 3 else 'branco')
            q.linha(base - 1, 16 - larg + 2, 16 + larg - 1, 'gelo_sombra')
    q.p(16, 3, 'branco' if neve else 'mata_luz')
    if not neve:
        for (x, y) in [(19, 10), (21, 22), (24, 36), (12, 26)]: q.p(x, y, 'lua')
    return q.contornar()


def arvore_campo():
    # árvore de copa redonda, tons de campo ao luar
    q = Q(40, 50)
    q.sombra_no_chao(20, 47, 12, 3)
    q.r(18, 30, 21, 47, 'madeira'); q.coluna(18, 30, 47, 'madeira_luz'); q.coluna(21, 30, 47, 'madeira_sombra')
    q.p(17, 47, 'madeira'); q.p(22, 47, 'madeira')
    for (cx, cy, rx, ry, c) in [(20, 17, 16, 13, 'grama_sombra'), (11, 24, 8, 6, 'grama_sombra'),
                                (29, 24, 8, 6, 'grama_sombra'), (19, 14, 12, 9, 'grama'),
                                (10, 21, 6, 5, 'grama'), (28, 21, 7, 5, 'grama'), (20, 26, 9, 4, 'grama')]:
        q.elipse(cx, cy, rx, ry, c)
    for (cx, cy, rx, ry) in [(15, 9, 4, 3), (24, 11, 4, 2), (9, 19, 3, 2), (27, 19, 3, 2)]:
        q.elipse(cx, cy, rx, ry, 'grama_luz')
    for (x, y) in [(14, 7), (23, 9), (8, 18)]: q.p(x, y, 'lua')
    return q.contornar()


def arvore_escura():
    # árvore alta de mata fechada, galhos tortos e copa quase preta
    q = Q(44, 62)
    q.sombra_no_chao(22, 58, 14, 3)
    q.r(19, 32, 24, 58, 'madeira_sombra'); q.coluna(19, 32, 58, 'madeira')
    for i in range(5):                                              # raízes
        q.p(18 - i, 58 - i // 2, 'madeira_sombra'); q.p(25 + i, 58 - i // 2, 'madeira_sombra')
    q.r(13, 34, 18, 35, 'madeira_sombra'); q.r(25, 30, 30, 31, 'madeira_sombra')
    q.r(21, 44, 22, 46, 'noite')                                    # oco
    for (cx, cy, rx, ry, c) in [(22, 18, 19, 16, 'mata_escura'), (10, 28, 9, 8, 'mata_escura'),
                                (34, 27, 9, 8, 'mata_escura'), (22, 15, 14, 11, 'mata'),
                                (11, 25, 6, 5, 'mata'), (33, 24, 6, 5, 'mata')]:
        q.elipse(cx, cy, rx, ry, c)
    for (cx, cy, rx, ry) in [(17, 9, 4, 2), (27, 11, 3, 2), (10, 22, 2, 2)]:
        q.elipse(cx, cy, rx, ry, 'mata_luz')
    return q.contornar()


def toco():
    q = Q(22, 18)
    q.sombra_no_chao(11, 15, 9, 2)
    q.r(5, 6, 16, 15, 'madeira'); q.coluna(5, 6, 15, 'madeira_sombra'); q.coluna(16, 6, 15, 'madeira_sombra')
    q.elipse(10, 6, 5, 2, 'ouro_sombra'); q.elipse(10, 6, 3, 1, 'madeira_luz')
    q.p(4, 15, 'madeira'); q.p(17, 15, 'madeira'); q.p(3, 15, 'madeira_sombra')
    q.r(13, 10, 15, 11, 'mata_luz')                                 # musgo
    return q.contornar()


def arbusto():
    q = Q(24, 18)
    q.sombra_no_chao(12, 15, 10, 2)
    for (cx, cy, rx, ry, c) in [(12, 10, 10, 6, 'grama_sombra'), (8, 9, 5, 4, 'grama'),
                                (16, 9, 5, 4, 'grama'), (12, 6, 5, 3, 'grama')]:
        q.elipse(cx, cy, rx, ry, c)
    q.p(9, 6, 'grama_luz'); q.p(14, 4, 'grama_luz'); q.p(17, 7, 'grama_luz')
    return q.contornar()


def rocha(neve=False):
    q = Q(26, 20)
    q.sombra_no_chao(13, 17, 11, 2)
    q.elipse(12, 11, 10, 6, 'rocha_sombra')
    q.elipse(11, 10, 8, 5, 'rocha')
    q.r(7, 6, 12, 8, 'rocha_luz'); q.p(16, 13, 'rocha_sombra')
    q.r(16, 12, 21, 15, 'rocha'); q.p(17, 12, 'rocha_luz')           # pedra menor
    if neve:
        q.r(6, 5, 15, 6, 'gelo'); q.r(8, 4, 13, 4, 'branco'); q.r(17, 11, 20, 11, 'gelo')
    return q.contornar()


def rochedo():
    q = Q(40, 36)
    q.sombra_no_chao(20, 32, 18, 3)
    q.elipse(20, 21, 17, 11, 'rocha_sombra')
    q.elipse(18, 18, 14, 10, 'rocha')
    q.elipse(14, 13, 8, 5, 'rocha_luz')
    for i in range(8):                                              # rachaduras
        q.p(22 + i // 2, 12 + i, 'rocha_sombra')
    q.r(9, 25, 30, 26, 'rocha_sombra')
    q.p(12, 10, 'lua'); q.p(15, 9, 'lua')
    return q.contornar()


def videira():
    # fileira curta de parreira em estacas
    q = Q(34, 30)
    q.sombra_no_chao(17, 27, 15, 2)
    for x in (4, 17, 29): q.r(x, 8, x + 1, 27, 'madeira'); q.p(x, 8, 'madeira_luz')
    q.linha(10, 4, 30, 'madeira_luz')                              # arame
    for (cx, cy) in [(8, 13), (13, 12), (21, 13), (26, 12), (10, 18), (24, 18)]:
        q.elipse(cx, cy, 4, 3, 'grama'); q.p(cx - 1, cy - 2, 'grama_luz')
    for (cx, cy) in [(9, 16), (14, 15), (22, 16), (27, 15)]:        # cachos
        q.r(cx, cy, cx + 1, cy + 2, 'telhado'); q.p(cx, cy, 'telhado_luz')
    q.r(4, 22, 30, 23, 'grama_sombra')
    return q.contornar()


def feixe_trigo():
    q = Q(18, 24)
    q.sombra_no_chao(9, 21, 7, 2)
    for x in range(4, 14):
        topo = 2 + abs(x - 9) // 2
        q.coluna(x, topo, 21, 'campo' if x % 2 else 'campo_quente')
    q.linha(13, 3, 14, 'madeira'); q.linha(14, 4, 13, 'madeira_sombra')   # amarrado
    for x in range(4, 14, 2): q.p(x, 2 + abs(x - 9) // 2, 'ouro_luz')
    return q.contornar()


# ---------- enfeites de chão (sem colisão) ----------

def tufo():
    q = Q(10, 8)
    for (x, h) in [(2, 3), (4, 5), (5, 6), (7, 4)]:
        q.coluna(x, 7 - h, 7, 'grama_luz' if h > 4 else 'grama')
    return q.contornar()


def flores():
    q = Q(12, 8)
    for (x, y, c) in [(2, 3, 'ouro_luz'), (6, 1, 'prata'), (9, 4, 'olho'), (4, 5, 'vela')]:
        q.coluna(x, y + 1, 7, 'grama'); q.p(x, y, c)
    return q.contornar()


def juncos():
    q = Q(12, 16)
    for (x, h) in [(2, 9), (4, 13), (6, 11), (8, 14), (10, 8)]:
        q.coluna(x, 15 - h, 15, 'campo_sombra' if x % 4 else 'campo')
    q.r(4, 2, 4, 4, 'madeira'); q.r(8, 1, 8, 3, 'madeira')
    return q.contornar()


def neve_mancha():
    q = Q(22, 9)
    q.elipse(11, 4, 9, 3, 'gelo_sombra'); q.elipse(10, 4, 7, 2, 'gelo'); q.r(7, 3, 10, 3, 'branco')
    return q.im


def geada_tufo():
    q = Q(10, 8)
    for (x, h) in [(2, 3), (4, 5), (6, 6), (8, 4)]:
        q.coluna(x, 7 - h, 7, 'geada'); q.p(x, 7 - h, 'gelo')
    return q.contornar()


def pedrinhas():
    q = Q(14, 7)
    for (x, y) in [(3, 4), (8, 3), (11, 5)]:
        q.r(x - 1, y - 1, x + 1, y, 'pedra'); q.p(x - 1, y - 1, 'pedra_luz')
    return q.contornar()


def cogumelos():
    q = Q(12, 9)
    for (x, h) in [(3, 4), (7, 6), (10, 3)]:
        q.coluna(x, 8 - h + 1, 8, 'prata')
        q.r(x - 1, 8 - h, x + 1, 8 - h, 'telhado'); q.p(x, 8 - h - 1, 'telhado_luz')
    return q.contornar()


def folhas():
    q = Q(16, 8)
    for (x, y, c) in [(2, 4, 'ouro_sombra'), (6, 2, 'campo_quente'), (10, 5, 'madeira_luz'), (13, 3, 'ouro_sombra')]:
        q.r(x, y, x + 1, y, c); q.p(x + 1, y + 1, c)
    return q.contornar()


def conchas():
    q = Q(12, 7)
    q.elipse(3, 4, 2, 1, 'prata'); q.p(3, 3, 'branco')
    q.elipse(9, 3, 1, 1, 'pele_luz'); q.p(9, 4, 'pele')
    return q.contornar()


# ---------- pisos isométricos (64×32) ----------
# Cada bioma vira uma faixa de 8 pisos: 0-2 chão comum, 3 clareira (terra
# batida em volta da fogueira), 4 margem (beira da água), 5-6 água (2 quadros
# de animação), 7 borda (o que cerca o acampamento: plantação, mata, neve...).

L, A = 64, 32


def dentro_do_losango(x, y):
    yy = y if y < A // 2 else A - 1 - y
    meia = 2 * (yy + 1)
    return 32 - meia <= x <= 31 + meia


def piso(cores, semente, manchas=(), riscos=None, listras=None, densidade=0.07):
    """cores: (base, escuro, claro). manchas: cores extras pontilhadas.
    riscos: cor de tracinhos verticais (folhas de grama). listras: (cor, período)
    em fileiras na diagonal (plantação)."""
    rng = random.Random(semente)
    im = Image.new('RGBA', (L, A), (0, 0, 0, 0)); px = im.load()
    base, escuro, claro = cores
    for y in range(A):
        for x in range(L):
            if not dentro_do_losango(x, y):
                continue
            c = base
            if listras and ((x // 2 + y) // listras[1]) % 2 == 0:
                c = listras[0]
            px[x, y] = C[c]
    # pintinhas de 2×1 (mais calmas que pixels soltos), que não passam da
    # beira do losango para o piso emendar sem costura
    for _ in range(int(L * A / 2 * densidade)):
        x, y = rng.randrange(L), rng.randrange(A)
        r = rng.random()
        c = escuro if r < 0.55 else claro if r < 0.85 or not manchas else rng.choice(manchas)
        for dx in (0, 1):
            if dentro_do_losango(x + dx, y):
                px[x + dx, y] = C[c]
    if riscos:
        for _ in range(14):
            x, y = rng.randrange(6, 58), rng.randrange(4, 28)
            for dy in range(2):
                if dentro_do_losango(x, y - dy): px[x, y - dy] = C[riscos]
    return im


def agua(cores, semente, quadro):
    base, fundo, brilho = cores
    rng = random.Random(semente)
    im = Image.new('RGBA', (L, A), (0, 0, 0, 0)); px = im.load()
    for y in range(A):
        for x in range(L):
            if dentro_do_losango(x, y):
                px[x, y] = C[fundo] if (x + 2 * y + quadro * 3) % 23 < 3 else C[base]
    for _ in range(7):
        x, y = rng.randrange(8, 52), rng.randrange(5, 27)
        x += quadro * 4
        for dx in range(rng.choice((3, 4, 5))):
            if dentro_do_losango(x + dx, y): px[x + dx, y] = C[brilho]
    return im


BIOMAS = {
    # oa: campina à beira do rio, entre plantações e a beira da mata
    'campina': dict(chao=('grama', 'grama_sombra', 'grama_luz'), riscos='grama_luz', manchas=('ouro_luz',),
                    clareira=('terra', 'madeira', 'areia_sombra'), margem=('areia_sombra', 'terra', 'areia'),
                    agua=('mar_raso', 'mar', 'espuma'),
                    borda=dict(cores=('campo', 'campo_sombra', 'campo_quente'), listras=('campo_sombra', 3))),
    # ot: mata fechada perto das falésias do sul
    'mata_costeira': dict(chao=('mata', 'mata_escura', 'mata_luz'), riscos='mata_luz', manchas=('ouro_sombra',),
                          clareira=('terra', 'madeira_sombra', 'madeira_luz'), margem=('rocha', 'rocha_sombra', 'rocha_luz'),
                          agua=('mar', 'mar_fundo', 'espuma'),
                          borda=dict(cores=('mata_escura', 'noite', 'mata'))),
    # og: colinas frias com geada, perto da costa gelada
    'colinas_geladas': dict(chao=('geada', 'geada_escura', 'gelo_sombra'), riscos='grama_sombra', manchas=('gelo',),
                            clareira=('terra', 'madeira', 'geada'), margem=('gelo_sombra', 'geada', 'gelo'),
                            agua=('mar_raso', 'mar', 'gelo'),
                            borda=dict(cores=('gelo', 'gelo_sombra', 'branco'))),
    # ag: beira de rio entre campos cultivados e parreirais
    'ribeira': dict(chao=('campo', 'campo_sombra', 'campo_quente'), riscos='grama_luz', manchas=('grama',),
                    clareira=('terra', 'madeira', 'areia_sombra'), margem=('areia', 'areia_sombra', 'prata'),
                    agua=('mar_raso', 'mar', 'espuma'),
                    borda=dict(cores=('campo_quente', 'campo_sombra', 'ouro'), listras=('grama_sombra', 3))),
    # an: passo de montanha com neve e pedras
    'passo_nevado': dict(chao=('gelo', 'gelo_sombra', 'branco'), manchas=('rocha_luz',),
                         clareira=('gelo_sombra', 'geada', 'gelo'), margem=('gelo_sombra', 'geada', 'gelo'),
                         agua=('mar_raso', 'mar', 'gelo'),
                         borda=dict(cores=('rocha', 'rocha_sombra', 'rocha_luz'), manchas=('gelo',))),
    # nt: pinhal nevado no alto da montanha
    'pinhal_nevado': dict(chao=('gelo', 'gelo_sombra', 'branco'), manchas=('mata',),
                          clareira=('gelo_sombra', 'terra', 'geada'), margem=('gelo_sombra', 'geada', 'gelo'),
                          agua=('mar_raso', 'mar', 'gelo'),
                          borda=dict(cores=('gelo_sombra', 'geada', 'gelo'), manchas=('mata_escura',))),
    # at: mata densa e escura
    'mata_escura': dict(chao=('mata_escura', 'noite', 'mata'), riscos='mata', manchas=('madeira_sombra',),
                        clareira=('madeira_sombra', 'noite', 'madeira'), margem=('mata', 'mata_escura', 'mata_luz'),
                        agua=('mar', 'mar_fundo', 'espuma'),
                        borda=dict(cores=('noite', 'mata_escura', 'madeira_sombra'))),
    # ilha: praia de uma ilha pequena com mata
    'ilha': dict(chao=('areia', 'areia_sombra', 'prata'), manchas=('prata_sombra',),
                 clareira=('areia_sombra', 'terra', 'areia'), margem=('areia_sombra', 'terra', 'areia'),
                 agua=('mar_raso', 'mar', 'espuma'),
                 borda=dict(cores=('grama', 'grama_sombra', 'mata'), riscos='grama_luz')),
    # ilhota: ilhota de pedra com uma prainha
    'ilhota': dict(chao=('areia', 'areia_sombra', 'rocha_luz'), manchas=('rocha',),
                   clareira=('areia_sombra', 'rocha', 'areia'), margem=('areia_sombra', 'rocha', 'areia'),
                   agua=('mar', 'mar_fundo', 'espuma'),
                   borda=dict(cores=('rocha', 'rocha_sombra', 'rocha_luz'))),
    # oa: pousada na estrada Atenas–Olympia (pátio de pedra, campina e rio)
    'pousada': dict(chao=('grama', 'grama_sombra', 'grama_luz'), riscos='grama_luz', manchas=('ouro_luz',),
                    clareira=('pedra', 'pedra_sombra', 'pedra_luz'), margem=('areia_sombra', 'terra', 'areia'),
                    agua=('mar_raso', 'mar', 'espuma'),
                    borda=dict(cores=('campo', 'campo_sombra', 'campo_quente'), listras=('campo_sombra', 3))),
}


def faixa_de_pisos(nome, b):
    faixa = Image.new('RGBA', (L * 8, A), (0, 0, 0, 0))
    semente = sum(map(ord, nome))
    pecas = [piso(b['chao'], semente + i, b.get('manchas', ()), b.get('riscos')) for i in range(3)]
    pecas.append(piso(b['clareira'], semente + 10, densidade=0.12))
    pecas.append(piso(b['margem'], semente + 11, densidade=0.10))
    pecas += [agua(b['agua'], semente + 12, q) for q in (0, 1)]
    bd = b['borda']
    pecas.append(piso(bd['cores'], semente + 13, bd.get('manchas', ()), bd.get('riscos'), bd.get('listras')))
    for i, peca in enumerate(pecas):
        faixa.paste(peca, (i * L, 0))
    return faixa


# ---------- animações e peças novas (faixas horizontais, quadros da esquerda para a direita) ----------

C.update(
    roxo_sombra=H('#3A2440'), roxo=H('#5A3560'), roxo_luz=H('#7A4C7E'),
    vinho=H('#6A2436'), vinho_luz=H('#8E3446'),
)


def faixa(quadros):
    w, h = quadros[0].size
    im = Image.new('RGBA', (w * len(quadros), h), (0, 0, 0, 0))
    for i, qd in enumerate(quadros):
        im.paste(qd, (i * w, 0))
    return im


# fogueira acesa: mesmas pedras, lenha e cinzas de fogueira(); só o fogo muda
QUADROS_FOGO = [
    # dx: inclinação das chamas; brilho: raios do halo; topo: alto da língua;
    # ponta, lambidas e faíscas: pixels soltos; miolo: alto do miolo claro
    dict(dx=0, brilho=(5, 5), topo=4, ponta=[(13, 2), (13, 3)],
         lambidas=[(9, 8, 'vela_escura'), (10, 7, 'vela_escura'), (17, 9, 'vela_escura'), (16, 6, 'vela')],
         miolo=9, faiscas=[(8, 3, 'ouro_luz'), (18, 1, 'vela')]),
    dict(dx=-1, brilho=(5, 4), topo=6, ponta=[(12, 5), (11, 4)],
         lambidas=[(8, 9, 'vela_escura'), (9, 8, 'vela'), (17, 10, 'vela_escura'), (18, 11, 'vela_escura')],
         miolo=10, faiscas=[(7, 1, 'vela'), (19, 5, 'ouro_luz')]),
    dict(dx=0, brilho=(4, 6), topo=3, ponta=[(13, 1), (13, 2)],
         lambidas=[(10, 9, 'vela_escura'), (16, 8, 'vela_escura'), (15, 5, 'vela')],
         miolo=8, faiscas=[(16, 6, 'ouro_luz'), (20, 2, 'vela')]),
    dict(dx=1, brilho=(5, 5), topo=5, ponta=[(14, 4), (15, 3)],
         lambidas=[(9, 7, 'vela'), (8, 9, 'vela_escura'), (18, 8, 'vela_escura'), (17, 6, 'vela_escura')],
         miolo=9, faiscas=[(10, 6, 'ouro_luz'), (17, 3, 'vela')]),
]


def fogueira_anim():
    quadros = []
    for f in QUADROS_FOGO:
        q = base_da_fogueira()
        d = f['dx']
        q.elipse(13 + d, 13, f['brilho'][0], f['brilho'][1], 'vela_escura')
        q.elipse(13, 14, 4, 4, 'vela')
        q.r(12 + d, f['topo'], 14 + d, 10, 'vela')
        for (x, y) in f['ponta']: q.p(x, y, 'vela')
        for (x, y, c) in f['lambidas']: q.p(x, y, c)
        q.r(12, 11, 14, 16, 'ouro_luz'); q.coluna(13 + d, f['miolo'], 11, 'ouro_luz')
        q.p(13, 15, 'branco')
        for (x, y, c) in f['faiscas']: q.p(x, y, c)
        quadros.append(q.contornar())
    return faixa(quadros)


# ---------- mercadores de cada acampamento (4 quadros de 32×48, pés na linha 45) ----------
# Respiração (tronco e cabeça descem 1 px), piscada num quadro e a mão
# direita que gesticula. Roupas genéricas de cada bioma; nada do livro.

RESPIRA = (0, 0, 1, 1)      # quanto o tronco desce em cada quadro
PISCA = (False, True, False, False)
MAO = (0, 1, 1, 0)          # a mão direita sobe e se abre um pouco


def _chapeu_palha(q, x, d, f):
    q.linha(7 + d, x - 7, x + 7, 'campo_quente'); q.linha(8 + d, x - 6, x + 6, 'ouro_sombra')
    q.r(x - 4, 3 + d, x + 4, 7 + d, 'ouro_luz'); q.linha(6 + d, x - 4, x + 4, 'telhado')
    q.r(x - 4, 3 + d, x - 3, 5 + d, 'campo_quente'); q.p(x + 3, 4 + d, 'branco')


def _colete(q, x, d, f):
    for xx in (x - 4, x + 2):
        q.r(xx, 18 + d, xx + 1, 24 + d, 'terra')
    q.p(x - 1, 20 + d, 'madeira_luz')


def _saco_nas_costas(q, x, d, f):
    q.r(x - 9, 18 + d, x - 6, 27 + d, 'areia'); q.coluna(x - 9, 18 + d, 27 + d, 'areia_sombra')
    q.linha(18 + d, x - 9, x - 6, 'madeira')


def _chapeu_pescador(q, x, d, f):
    q.r(x - 5, 7 + d, x + 5, 8 + d, 'areia_sombra')
    q.r(x - 4, 3 + d, x + 4, 7 + d, 'areia'); q.linha(3 + d, x - 3, x + 3, 'prata')
    q.p(x - 4, 3 + d, 'contorno')


def _rede(q, x, d, f):
    # rede de pesca no ombro, caindo pelas costas, com boias
    for y in range(17, 33):
        for xx in range(x + 6, x + 10):
            if (xx + y) % 3 == 0 and xx - x - 6 <= (y - 15) // 3:
                q.p(xx, y + d, 'prata_sombra')
    q.p(x + 7, 33 + d, 'ouro'); q.p(x + 9, 31 + d, 'ouro')


def _camisa_listrada(q, x, d, f):
    for y in range(19, 31, 3):
        q.linha(y + d, x - 4, x + 3, 'olho')


def _gola_pele(q, x, d, f):
    q.elipse(x, 17 + d, 7, 2, 'prata'); q.linha(18 + d, x - 6, x + 6, 'prata_sombra')
    for xx in (x - 5, x - 2, x + 2, x + 5):
        q.p(xx, 16 + d, 'lua'); q.p(xx + 1, 19 + d, 'prata_sombra')


def _gorro_pele(q, x, d, f):
    q.r(x - 4, 4 + d, x + 4, 8 + d, 'madeira_luz'); q.linha(4 + d, x - 3, x + 3, 'ouro_sombra')
    q.r(x - 5, 7 + d, x + 5, 9 + d, 'prata'); q.p(x - 3, 8 + d, 'prata_sombra'); q.p(x + 2, 7 + d, 'lua')


def _debrum_ouro(q, x, d, f):
    q.coluna(x - 1, 19 + d, 38 + d, 'ouro')                      # abotoadura
    for y in (21, 25, 29, 33): q.p(x - 1, y + d, 'ouro_luz')
    q.linha(38 + d, x - 8, x + 7, 'ouro')                        # barra
    q.linha(24 + d, x - 5, x + 4, 'vinho_luz'); q.p(x + 2, 24 + d, 'ouro_luz')  # faixa


def _boina_veludo(q, x, d, f):
    q.r(x - 5, 5 + d, x + 4, 8 + d, 'vinho'); q.linha(5 + d, x - 4, x + 3, 'vinho_luz')
    q.linha(8 + d, x - 4, x + 4, 'ouro')
    q.p(x + 4, 4 + d, 'prata'); q.p(x + 5, 3 + d, 'prata'); q.p(x + 6, 2 + d, 'lua')  # pluma


def _debrum_pele(q, x, d, f):
    q.coluna(x - 1, 18 + d, 41 + d, 'madeira_luz')
    q.linha(41 + d, x - 9, x + 8, 'madeira_luz')
    for y in (22, 28, 34): q.p(x, y + d, 'madeira')


def _gorro_la(q, x, d, f):
    q.elipse(x, 7 + d, 5, 4, 'nuvem'); q.r(x - 5, 7 + d, x + 5, 9 + d, 'azul_luz')
    q.linha(8 + d, x - 5, x + 5, 'nuvem')
    q.r(x - 1, 1 + d, x + 1, 2 + d, 'prata'); q.p(x, 1 + d, 'lua')   # pompom


def _cachecol(q, x, d, f):
    q.r(x - 4, 16 + d, x + 4, 18 + d, 'telhado'); q.linha(16 + d, x - 3, x + 3, 'telhado_luz')
    q.r(x - 4, 19 + d, x - 3, 26 + d, 'telhado'); q.coluna(x - 3, 19 + d, 26 + d, 'telhado_luz')
    q.linha(27 + d, x - 4, x - 3, 'ouro_sombra')                 # franja
    for y in (21, 25, 29, 33): q.p(x, y + d, 'ouro_sombra')      # botões


def _lanterna(q, x, d, f):
    # lanterna pendurada na mão esquerda; a chama tremeluz
    q.coluna(x - 7, 30 + d, 31 + d, 'pedra_sombra')
    q.r(x - 9, 32 + d, x - 5, 37 + d, 'pedra_sombra'); q.linha(32 + d, x - 9, x - 5, 'pedra')
    q.r(x - 8, 33 + d, x - 6, 36 + d, 'vela_escura' if f % 2 else 'vela')
    q.p(x - 7, 34 + d, 'ouro_luz' if f != 2 else 'vela')
    q.p(x - 7, 35 + d, 'branco' if f in (0, 3) else 'ouro_luz')
    q.linha(37 + d, x - 9, x - 5, 'pedra')


def _lenco_cabeca(q, x, d, f):
    q.r(x + 3, 9 + d, x + 5, 12 + d, 'vela'); q.p(x + 6, 13 + d, 'vela')   # nó atrás da orelha
    q.r(x + 5, 13 + d, x + 5, 16 + d, 'vela_escura'); q.p(x + 6, 14 + d, 'vela_escura')
    q.elipse(x, 7 + d, 4, 3, 'vela'); q.linha(9 + d, x - 4, x + 3, 'vela_escura')
    q.p(x - 4, 10 + d, 'vela_escura')
    q.linha(5 + d, x - 2, x + 2, 'ouro_luz'); q.p(x - 1, 7 + d, 'vela_escura'); q.p(x + 2, 8 + d, 'vela_escura')


def _faixa_e_colar(q, x, d, f):
    q.linha(25 + d, x - 6, x + 5, 'olho'); q.p(x - 4, 26 + d, 'olho'); q.p(x - 4, 27 + d, 'olho_luz')
    q.linha(17 + d, x - 2, x + 2, 'madeira_luz'); q.p(x, 18 + d, 'branco')     # colar de concha


def _bone_marinheiro(q, x, d, f):
    q.r(x - 4, 5 + d, x + 4, 8 + d, 'azul'); q.linha(5 + d, x - 3, x + 3, 'nuvem')
    q.linha(8 + d, x - 4, x + 6, 'contorno'); q.p(x + 6, 8 + d, 'nuvem')    # pala
    q.p(x - 1, 6 + d, 'ouro_luz')


def _oleado(q, x, d, f):
    for y in (20, 24, 28, 32): q.p(x, y + d, 'madeira_sombra')
    q.coluna(x - 1, 18 + d, 39 + d, 'ouro_sombra')
    q.r(x - 5, 17 + d, x + 4, 18 + d, 'ouro_luz')                # gola levantada


def _corda_nas_costas(q, x, d, f):
    q.elipse(x + 8, 24 + d, 3, 4, 'areia'); q.elipse(x + 8, 24 + d, 1, 2, 'contorno')
    q.p(x + 10, 22 + d, 'areia_sombra'); q.p(x + 6, 27 + d, 'areia_sombra')


ROUPAS = {
    # campina: chapéu de palha, túnica verde e colete marrom
    'oa': dict(capa=('grama', 'grama_sombra', 'grama_luz'), barra=36, manga='grama', calca='madeira_luz',
               bota='madeira_sombra', cinto='madeira', barba='madeira_luz',
               atras=[_saco_nas_costas], frente=[_colete, _chapeu_palha]),
    # mata costeira: pescador de camisa azul listrada, calça de lona clara, rede no ombro
    'ot': dict(capa=('azul_luz', 'nuvem', 'olho'), barra=33, manga='azul_luz', calca='areia',
               bota='areia_sombra', cinto='areia_sombra', barba='pedra_luz',
               atras=[_rede], frente=[_camisa_listrada, _chapeu_pescador]),
    # colinas geladas: manto cinza com gola de pele
    'og': dict(capa=('pedra', 'pedra_sombra', 'pedra_luz'), barra=40, manga='pedra', calca='madeira',
               bota='madeira_sombra', cinto=None, barba='madeira_luz',
               frente=[_gola_pele, _gorro_pele]),
    # ribeira dos vinhedos: casaca roxa com debrum dourado, boina de veludo
    'ag': dict(capa=('roxo', 'roxo_sombra', 'roxo_luz'), barra=38, manga='vinho', punho='ouro', calca='azul',
               bota='madeira_sombra', cinto=None, barba=None,
               frente=[_debrum_ouro, _boina_veludo]),
    # passo nevado: casacão de pele claro com capuz, barra marrom, luvas
    'an': dict(capa=('gelo', 'gelo_sombra', 'branco'), barra=41, largo=1, manga='gelo_sombra', mao='madeira_luz',
               calca='madeira', bota='madeira', cinto='madeira', barba=None,
               capuz=('gelo', 'gelo_sombra', 'madeira_luz'), frente=[_debrum_pele]),
    # pinhal nevado: gorro de lã, casaco verde-escuro, cachecol
    'nt': dict(capa=('mata', 'mata_escura', 'mata_luz'), barra=38, manga='mata', mao='madeira_luz',
               calca='madeira', bota='madeira_sombra', cinto=None, barba='ouro_sombra',
               frente=[_cachecol, _gorro_la]),
    # mata escura: capa com capuz verde-escuro e marrom, lanterna na mão
    'at': dict(capa=('mata_escura', 'madeira_sombra', 'mata'), barra=42, manga='mata_escura', calca='madeira_sombra',
               bota='madeira_sombra', cinto=None, barba=None, rosto='pele_sombra',
               capuz=('mata_escura', 'madeira_sombra', 'madeira'), frente=[_lanterna]),
    # ilha: linho claro, lenço na cabeça, sandálias
    'ilha': dict(capa=('prata', 'prata_sombra', 'branco'), barra=36, manga='prata', calca='pele',
                 bota='madeira_luz', cinto=None, barba=None,
                 frente=[_faixa_e_colar, _lenco_cabeca]),
    # ilhota: casaco de oleado amarelado, boné de marinheiro, corda nas costas
    'ilhota': dict(capa=('ouro', 'ouro_sombra', 'ouro_luz'), barra=39, manga='ouro', calca='nuvem',
                   bota='azul', cinto=None, barba='lua',
                   atras=[_corda_nas_costas], frente=[_oleado, _bone_marinheiro]),
}


def mercador_quadro(r, f):
    q = Q(32, 48)
    q.sombra_no_chao(16, 45, 9, 2)
    x, d, m = 16, RESPIRA[f], MAO[f]
    for fn in r.get('atras', ()): fn(q, x, d, f)
    # pernas e botas (paradas: os pés não saem da linha 45)
    for px in (x - 4, x + 1):
        q.r(px, 37, px + 2, 41, r['calca'])
        q.r(px, 42, px + 3, 45, r['bota'])
    # roupa do tronco, alargando para baixo
    cor, sombra, luz = r['capa']
    for y in range(17, r['barra'] + 1):
        meia = 5 + r.get('largo', 0) + (y - 17) // 6
        q.linha(y + d, x - meia, x + meia - 1, cor)
        q.p(x - meia, y + d, sombra); q.p(x - meia + 1, y + d, sombra)
        q.p(x + meia - 1, y + d, luz)
    if r.get('cinto'): q.linha(25 + d, x - 6, x + 5, r['cinto'])
    # braços: o esquerdo parado, o direito gesticula
    mao = r.get('mao', 'pele')
    q.r(x - 7, 18 + d, x - 6, 27 + d, r['manga']); q.r(x - 7, 28 + d, x - 6, 29 + d, mao)
    q.r(x + 5, 18 + d, x + 6, 27 + d - m, r['manga'])
    q.r(x + 5 + m, 28 + d - m, x + 6 + m, 29 + d - m, mao)
    if r.get('punho'):
        q.linha(27 + d, x - 7, x - 6, r['punho']); q.linha(27 + d - m, x + 5, x + 6, r['punho'])
    # cabeça (com ou sem capuz)
    rosto = r.get('rosto', 'pele')
    if r.get('capuz'):
        c, cs, borda = r['capuz']
        q.elipse(x, 11 + d, 6, 6, c); q.r(x - 6, 11 + d, x - 5, 17 + d, cs)
        q.elipse(x, 12 + d, 4, 4, borda)                         # beira do capuz
        q.elipse(x, 12 + d, 3, 3, rosto)
        q.linha(9 + d, x - 2, x + 2, cs); q.p(x - 3, 10 + d, cs)   # sombra do capuz na testa
        q.linha(14 + d, x, x + 1, 'pele_sombra' if rosto == 'pele' else 'madeira')  # boca
        brilho = ('lua', 'lua') if c == 'gelo' else ('mata_luz', 'mata')
        q.p(x - 2, 5 + d, brilho[0]); q.p(x - 3, 6 + d, brilho[1])
    else:
        q.r(x - 3, 9 + d, x + 3, 15 + d, rosto); q.coluna(x - 3, 9 + d, 15 + d, 'pele_sombra')
    olho = 'pele_sombra' if PISCA[f] else 'olho_escuro'
    if r.get('capuz'):
        q.p(x - 1, 11 + d, olho); q.p(x + 1, 11 + d, olho)
    else:
        q.p(x - 1, 11 + d, olho); q.p(x + 2, 11 + d, olho)
    if r.get('barba'):
        q.r(x - 3, 13 + d, x + 3, 16 + d, r['barba']); q.p(x, 13 + d, 'pele_sombra')
    elif not r.get('capuz'):
        q.linha(14 + d, x, x + 1, 'pele_sombra')
    for fn in r.get('frente', ()): fn(q, x, d, f)
    return q.contornar()


def mercador_de(id_):
    return lambda: faixa([mercador_quadro(ROUPAS[id_], f) for f in range(4)])


# ---------- falésia (pedaço de penhasco de arenito, base embaixo) ----------

CAMADAS = ['areia', 'prata_sombra', 'areia_sombra', 'rocha_luz', 'prata', 'areia', 'rocha', 'areia_sombra']
ESCURO = dict(areia='areia_sombra', prata='prata_sombra', prata_sombra='rocha', areia_sombra='terra',
              rocha_luz='rocha', rocha='rocha_sombra')


def _perfil(pontos, u):
    for (u0, a0), (u1, a1) in zip(pontos, pontos[1:]):
        if u0 <= u <= u1:
            return a0 + (a1 - a0) * (u - u0) / (u1 - u0)
    return pontos[-1][1]


def falesia_de(w, h, semente, pontos):
    rng = random.Random(semente)
    q = Q(w, h)
    base = h - 5
    q.sombra_no_chao(w // 2, base + 1, w // 2 - 2, 3)
    x0, x1 = 3, w - 4
    alto = base - 9                                   # sobra espaço para o tampo e o capim
    topo = {}
    salto = 0
    for x in range(x0, x1 + 1):
        if (x - x0) % 3 == 0: salto = rng.choice((0, 0, 1, -1))
        topo[x] = base - int(_perfil(pontos, (x - x0) / (x1 - x0)) * alto) + salto
    sombra_ate = x0 + (x1 - x0) // 5
    for x in range(x0, x1 + 1):
        t = topo[x]
        onda = int(round(2 * math.sin(x / 9.0)))     # camadas levemente onduladas
        for y in range(t, base + 1):
            k = (base - y + onda) // 5
            c = CAMADAS[k % len(CAMADAS)]
            if (base - y + onda) % 5 == 0 or x < sombra_ate:
                c = ESCURO.get(c, c)
            q.p(x, y, c)
        # tampo de cima, claro, visto de leve
        q.r(x, t - 3, x, t - 1, 'prata'); q.p(x, t - 3, 'lua')
        q.p(x, t, 'prata_sombra')
        q.p(x, base, 'rocha_sombra')
    # rachaduras
    for _ in range(w // 12):
        x = rng.randrange(x0 + 4, x1 - 3)
        y = topo[x] + rng.randrange(2, 6)
        for i in range(rng.randrange(6, 14)):
            if y + i >= base: break
            if i % 3 == 2: x += rng.choice((-1, 1))
            if x in topo and y + i > topo[x]: q.p(x, y + i, 'rocha_sombra')
    # capim por cima, escorrendo um pouco pela beira
    for _ in range(w // 8):
        x = rng.randrange(x0 + 2, x1 - 2)
        for dx in range(rng.randrange(3, 7)):
            xx = x + dx
            if xx not in topo: continue
            t = topo[xx] - 3
            q.coluna(xx, t - rng.randrange(1, 4), t, 'grama_luz' if dx % 2 else 'grama')
            if rng.random() < 0.4: q.coluna(xx, t + 1, t + 3 + rng.randrange(2), 'grama_sombra')
    # pedras soltas no pé
    for _ in range(w // 16):
        x = rng.randrange(x0, x1 - 3)
        q.r(x, base - 2, x + 2, base, 'rocha'); q.p(x, base - 2, 'rocha_luz')
    return q.contornar()


def falesia():
    return falesia_de(96, 72, 71, [(0, .15), (.06, .8), (.35, .95), (.55, .9), (.62, .62),
                                   (.85, .58), (.95, .35), (1, .1)])


def falesia_b():
    return falesia_de(80, 60, 72, [(0, .1), (.08, .5), (.25, .55), (.32, .95), (.55, 1.0),
                                   (.7, .85), (.9, .7), (1, .2)])


# ---------- partículas (sem contorno) ----------

def _pixels(w, h, pontos):
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0)); px = im.load()
    for (x, y), cor in pontos.items():
        px[x, y] = cor
    return im


def floco_neve():
    b, m, c = (244, 239, 232, 255), (244, 239, 232, 150), (201, 206, 216, 60)
    return _pixels(3, 3, {(1, 1): b, (0, 1): m, (2, 1): m, (1, 0): m, (1, 2): m,
                          (0, 0): c, (2, 0): c, (0, 2): c, (2, 2): c})


def vagalume():
    pts = {(2, 2): (236, 255, 150, 255)}
    for (x, y) in [(1, 2), (3, 2), (2, 1), (2, 3)]: pts[(x, y)] = (200, 232, 90, 210)
    for (x, y) in [(1, 1), (3, 1), (1, 3), (3, 3)]: pts[(x, y)] = (170, 210, 70, 110)
    for (x, y) in [(0, 2), (4, 2), (2, 0), (2, 4)]: pts[(x, y)] = (150, 200, 60, 60)
    return _pixels(5, 5, pts)


def inseto():
    corpo, asa = (34, 30, 36, 255), (150, 160, 175, 170)
    quadros = []
    for asas in ([(0, 0), (3, 0)], [(0, 2), (3, 2)]):           # asas para cima / para baixo
        pts = {(1, 1): corpo, (2, 1): corpo, (1, 2): corpo, (2, 2): (60, 52, 58, 255)}
        for a in asas: pts[a] = asa
        quadros.append(_pixels(4, 4, pts))
    return faixa(quadros)


def passaro():
    c = (28, 34, 48, 255)
    cima = [(0, 0), (9, 0), (1, 1), (8, 1), (2, 2), (3, 2), (5, 2), (6, 2), (7, 2),
            (3, 3), (4, 3), (5, 3), (6, 3), (4, 4)]
    baixo = [(5, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
             (1, 4), (2, 4), (4, 4), (7, 4), (8, 4), (0, 5), (9, 5)]
    return faixa([_pixels(10, 7, {p: c for p in pts}) for pts in (cima, baixo)])


# ---------- pousada da estrada Atenas–Olympia (oa_acampamento) ----------
# O livro (Cap. 2 da Parte I) só diz "uma simples pousada", "não era grande,
# era simples, mas bem cuidada". O desenho é inferência.

def pousada():
    # casa de dois andares vista de frente: pedra embaixo, enxaimel em cima,
    # telhado de telha, porta no meio com lanterna e a placa pendurada
    q = Q(120, 100)
    q.sombra_no_chao(60, 94, 56, 4)
    # telhado
    for y in range(10, 33):
        meia = 38 + (y - 10) * 18 // 22
        q.linha(y, 60 - meia, 60 + meia, 'telhado')
        if (y - 10) % 4 == 3:
            q.linha(y, 60 - meia, 60 + meia, 'telhado_luz' if y < 20 else 'madeira_sombra')
    q.linha(10, 22, 98, 'telhado_luz')
    for x in range(6, 115, 6):
        q.p(x, 32, 'madeira_sombra')
    # chaminé com fumacinha
    q.r(88, 2, 95, 14, 'pedra'); q.coluna(88, 2, 14, 'pedra_luz'); q.linha(2, 87, 96, 'pedra_sombra')
    q.p(91, 0, 'nuvem'); q.p(93, 1, 'azul_luz')
    # andar de cima: reboco com vigas de madeira
    q.r(12, 33, 107, 56, 'prata')
    q.r(12, 33, 15, 56, 'prata_sombra')
    for x in (12, 36, 60, 84, 106):
        q.r(x, 33, x + 1, 56, 'madeira')
    q.linha(33, 12, 107, 'madeira'); q.linha(44, 12, 107, 'madeira_sombra'); q.linha(56, 12, 107, 'madeira')
    for x0 in (16, 64):  # mãos-francesas em X
        for i in range(10):
            q.p(x0 + i * 2, 34 + i, 'madeira'); q.p(x0 + 18 - i * 2, 34 + i, 'madeira')
    # janelas de cima, com venezianas
    for x in (42, 88):
        q.r(x, 37, x + 9, 50, 'noite'); q.r(x + 1, 38, x + 8, 49, 'vela_escura')
        q.r(x + 2, 39, x + 7, 44, 'vela'); q.coluna(x + 4, 38, 49, 'madeira')
        q.r(x - 4, 37, x - 1, 50, 'olho_escuro'); q.r(x + 10, 37, x + 13, 50, 'olho_escuro')
        q.linha(51, x - 1, x + 10, 'madeira_luz')
    # andar de baixo: pedra em fiadas
    q.r(10, 57, 109, 92, 'pedra')
    for y in range(57, 93, 5):
        q.linha(y, 10, 109, 'pedra_sombra')
        off = 0 if (y // 5) % 2 else 6
        for x in range(10 + off, 110, 12):
            q.coluna(x, y, min(y + 4, 92), 'pedra_sombra')
            q.p(x + 2, y + 1, 'pedra_luz')
    q.r(10, 57, 13, 92, 'pedra_sombra')
    # porta em arco, entreaberta com luz
    q.r(52, 66, 67, 92, 'madeira')
    q.elipse(59, 66, 8, 5, 'madeira')
    q.r(54, 67, 65, 92, 'madeira_sombra')
    q.r(60, 69, 65, 92, 'vela_escura'); q.r(61, 72, 64, 92, 'vela')
    q.r(52, 62, 67, 63, 'pedra_luz')
    q.p(58, 80, 'ouro_luz')
    q.r(50, 92, 69, 93, 'pedra_luz')                                 # degrau
    # janelas de baixo, acesas
    for x in (20, 86):
        q.r(x, 66, x + 13, 79, 'noite'); q.r(x + 1, 67, x + 12, 78, 'vela')
        q.coluna(x + 6, 67, 78, 'madeira'); q.linha(72, x + 1, x + 12, 'madeira')
        q.r(x + 2, 68, x + 4, 70, 'ouro_luz')
        q.linha(80, x - 1, x + 14, 'pedra_luz')
    # lanterna ao lado da porta
    q.r(71, 64, 74, 65, 'madeira'); q.r(73, 66, 76, 72, 'ouro_sombra'); q.r(74, 67, 75, 71, 'vela')
    # placa pendurada num braço, com uma caneca pintada
    q.r(32, 58, 47, 59, 'madeira')
    q.coluna(35, 59, 61, 'pedra_sombra'); q.coluna(44, 59, 61, 'pedra_sombra')
    q.r(32, 62, 47, 72, 'madeira_luz'); q.linha(72, 32, 47, 'madeira_sombra')
    q.r(37, 64, 41, 70, 'ouro'); q.r(42, 65, 43, 68, 'ouro'); q.linha(64, 37, 41, 'branco')
    # banco de madeira encostado na parede
    q.r(76, 86, 84, 87, 'madeira_luz'); q.coluna(77, 88, 91, 'madeira'); q.coluna(83, 88, 91, 'madeira')
    return q.contornar()


def cerca():
    # pedaço de cerca de madeira (três postes e duas travessas)
    q = Q(40, 24)
    q.sombra_no_chao(20, 21, 18, 2)
    for x in (3, 19, 35):
        q.r(x, 4, x + 2, 21, 'madeira'); q.coluna(x, 4, 21, 'madeira_luz')
        q.p(x + 1, 3, 'madeira_luz')
    for y in (8, 15):
        q.r(1, y, 38, y + 1, 'madeira_luz'); q.linha(y + 1, 1, 38, 'madeira')
    return q.contornar()


def barril():
    q = Q(18, 22)
    q.sombra_no_chao(9, 19, 7, 2)
    q.elipse(9, 11, 7, 9, 'madeira')
    q.r(3, 4, 15, 18, 'madeira')
    q.coluna(4, 4, 18, 'madeira_luz'); q.coluna(14, 4, 18, 'madeira_sombra')
    for y in (6, 11, 16):
        q.linha(y, 2, 16, 'pedra_sombra')
    q.elipse(9, 3, 6, 2, 'madeira_luz'); q.elipse(9, 3, 4, 1, 'madeira_sombra')
    return q.contornar()


def carroca():
    # carroça do comboio parada, com fardos de feno e lona
    q = Q(56, 40)
    q.sombra_no_chao(28, 36, 26, 3)
    q.r(4, 20, 46, 28, 'madeira')
    q.linha(20, 4, 46, 'madeira_luz'); q.linha(28, 4, 46, 'madeira_sombra')
    for x in (14, 25, 36):
        q.coluna(x, 21, 27, 'madeira_sombra')
    q.r(6, 10, 26, 19, 'campo_quente'); q.linha(10, 6, 26, 'ouro_luz')   # feno
    for x in range(7, 26, 3):
        q.p(x, 13, 'campo_sombra'); q.p(x + 1, 16, 'campo_sombra')
    q.r(28, 8, 44, 19, 'prata'); q.linha(8, 28, 44, 'lua')               # lona
    q.coluna(36, 9, 19, 'prata_sombra')
    q.r(46, 24, 55, 25, 'madeira')                                        # varal
    for cx in (12, 38):                                                   # rodas
        q.elipse(cx, 31, 6, 6, 'madeira_sombra'); q.elipse(cx, 31, 4, 4, 'madeira')
        q.elipse(cx, 31, 2, 2, 'madeira_sombra'); q.p(cx, 31, 'ouro')
    return q.contornar()


def feno():
    q = Q(24, 18)
    q.sombra_no_chao(12, 15, 11, 2)
    q.r(2, 5, 21, 15, 'campo_quente')
    q.linha(5, 2, 21, 'ouro_luz'); q.linha(15, 2, 21, 'campo_sombra')
    for x in (7, 16):
        q.coluna(x, 5, 15, 'madeira')
    for x in range(3, 21, 3):
        q.p(x, 9, 'campo_sombra'); q.p(x + 1, 12, 'ouro')
    return q.contornar()


def lajota():
    # lajes soltas no chão do pátio (enfeite sem colisão)
    q = Q(22, 10)
    for (x0, y0, x1, y1) in ((1, 1, 8, 4), (10, 2, 19, 5), (4, 6, 12, 8)):
        q.r(x0, y0, x1, y1, 'pedra_luz'); q.linha(y1, x0, x1, 'pedra')
    return q.im


ARTES = {
    'barraca': barraca, 'fogueira': fogueira, 'tronco': tronco, 'banca': banca,
    'placa_saida': placa_saida, 'barco': barco,
    'mercador': mercador, 'viajante': viajante,
    'cao': cao, 'ovelha': ovelha, 'cabra': cabra, 'burro': burro, 'coruja': coruja,
    'gaivota': gaivota, 'caranguejo': caranguejo,
    'pinheiro': pinheiro, 'pinheiro_neve': lambda: pinheiro(True),
    'arvore_campo': arvore_campo, 'arvore_escura': arvore_escura, 'toco': toco, 'arbusto': arbusto,
    'rocha': rocha, 'rocha_neve': lambda: rocha(True), 'rochedo': rochedo,
    'videira': videira, 'feixe_trigo': feixe_trigo,
    'tufo': tufo, 'flores': flores, 'juncos': juncos, 'neve_mancha': neve_mancha,
    'geada_tufo': geada_tufo, 'pedrinhas': pedrinhas, 'cogumelos': cogumelos,
    'folhas': folhas, 'conchas': conchas,
    # pousada da estrada Atenas–Olympia
    'pousada': pousada, 'cerca': cerca, 'barril': barril, 'carroca': carroca,
    'feno': feno, 'lajota': lajota,
    # animações, falésias e partículas
    'fogueira_anim': fogueira_anim, 'falesia': falesia, 'falesia_b': falesia_b,
    'floco_neve': floco_neve, 'vagalume': vagalume, 'inseto': inseto, 'passaro': passaro,
}
ARTES.update({f'mercador_{i}': mercador_de(i) for i in ROUPAS})

if __name__ == '__main__':
    os.makedirs(PASTA, exist_ok=True)
    # Opcional: só as peças cujo nome contém o filtro (ex.: "pousada").
    filtro = set(sys.argv[1:])
    escolher = lambda nome: not filtro or nome in filtro
    for nome, desenhar in ARTES.items():
        if not escolher(nome):
            continue
        caminho = f'{PASTA}/{nome}.png'
        desenhar().save(caminho)
        print(caminho)
    for nome, bioma in BIOMAS.items():
        if not escolher(nome):
            continue
        caminho = f'{PASTA}/chao_{nome}.png'
        faixa_de_pisos(nome, bioma).save(caminho)
        print(caminho)
