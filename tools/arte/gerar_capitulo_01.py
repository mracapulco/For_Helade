# Gera a arte provisória da manhã do Capítulo 01 ("A garota do corredor"):
# chão e parede da Mansão Olympia em Atenas, camas, espelho, portas, mesa de
# chá, o bolo azul de três andares no carrinho, o embrulho da espada, Pany e
# a garota da visão. Tudo provisório, na paleta de Hélade, para testar até a
# arte final. Do livro: o bolo azul de três andares com pérolas de açúcar e
# seis velas, o embrulho comprido, a pelúcia de monstro marinho de Althea, o
# espelho grande demais para o quarto. O resto (móveis, cores, Pany) é
# inferência provisória.
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
    cab_althea=H('#E3D5AE'), cab_althea_luz=H('#F6EED2'),
    monstro=H('#3F7C78'), monstro_luz=H('#5FA39C'),
    embrulho=H('#8E1F25'), embrulho_luz=H('#B8343A'),
    pany_vestido=H('#3A2F3C'), pany_vestido_luz=H('#544458'),
    silhueta=H('#1A1210'), silhueta_luz=H('#3A2820'),
    vidro=H('#9FB8D2'), vidro_luz=H('#D4E2EF'),
)
PASTA = 'assets/art/capitulo_01'


def piso():
    # dois losangos de 64×32 lado a lado (tábuas claras e escuras)
    q = Q(128, 32)
    for i, (base, luz) in enumerate((('piso', 'piso_luz'), ('piso_sombra', 'piso'))):
        ox = i * 64
        for y in range(32):
            meia = 32 - abs(y - 15.5) * 2
            x0 = int(ox + 32 - meia); x1 = int(ox + 32 + meia) - 1
            for x in range(x0, x1 + 1):
                q.p(x, y, base)
            # tábuas na diagonal
            for x in range(x0, x1 + 1):
                if (x - ox + y * 2) % 16 == 0:
                    q.p(x, y, luz)
    return q.im


def parede():
    # bloco de 64×64: topo em losango de 64×32 e a face embaixo
    q = Q(64, 64)
    for y in range(32):
        meia = 32 - abs(y - 15.5) * 2
        for x in range(int(32 - meia), int(32 + meia)):
            q.p(x, y, 'parede_luz')
    for y in range(16, 64):
        for x in range(64):
            # face esquerda e direita abaixo do losango
            topo = 31.5 - abs(x - 31.5) / 2
            fundo = topo + 32
            if topo <= y <= fundo:
                q.p(x, y, 'parede' if x < 32 else 'parede_sombra')
    for x in range(4, 60, 8):                       # frisos dourados no rodapé
        y = int(31.5 - abs(x - 31.5) / 2) + 30
        q.p(x, y, 'ouro_sombra')
    return q.im


def cama(com_althea):
    q = Q(48, 34)
    q.sombra_no_chao(24, 31, 22, 3)
    q.r(3, 10, 44, 30, 'madeira')                   # estrado
    q.r(3, 10, 5, 30, 'madeira_sombra')
    q.r(4, 2, 12, 12, 'madeira_luz')                # cabeceira
    q.linha(2, 4, 12, 'ouro')
    q.r(7, 12, 44, 24, 'lencol')                    # colchão
    q.r(9, 13, 16, 17, 'perola')                    # travesseiro
    q.r(18, 14, 44, 26, 'colcha')                   # cobertor
    q.linha(14, 18, 44, 'colcha_luz')
    q.linha(26, 18, 44, 'ouro_sombra')
    if com_althea:
        q.elipse(13, 15, 3, 3, 'cab_althea')        # cabeça no travesseiro
        q.p(12, 13, 'cab_althea_luz'); q.p(14, 13, 'cab_althea_luz')
        q.r(16, 15, 21, 18, 'monstro')              # a pelúcia abraçada
        q.p(21, 15, 'monstro_luz'); q.p(18, 15, 'monstro_luz')
        q.r(19, 17, 34, 22, 'colcha_luz')           # volume do corpo sob a colcha
    q.r(42, 12, 45, 30, 'madeira_luz')              # pé da cama
    return q.contornar()


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
    'cama_althea.png': lambda: cama(True),
    'cama_althea_vazia.png': lambda: cama(False),
    'espelho.png': espelho,
    'porta.png': lambda: porta(False),
    'porta_aberta.png': lambda: porta(True),
    'mesa_cha.png': mesa_cha,
    'carrinho_bolo.png': carrinho_bolo,
    'carrinho_bolo_aceso.png': lambda: velas_acesas(carrinho_bolo()),
    'embrulho.png': embrulho,
    'pany_provisoria.png': pany,
    'garota_visao.png': garota_visao,
}

if __name__ == '__main__':
    os.makedirs(PASTA, exist_ok=True)
    for nome, desenhar in ARTES.items():
        caminho = os.path.join(PASTA, nome)
        desenhar().save(caminho)
        print(caminho)
