# Arte provisória dos prêmios das charadas dos convidados (Próskopos e
# Chymeía): ícones da bolsa (32×32) e, para o bastão, o desenho na mão. Usa
# as mesmas peças e a mesma paleta de gerar_armas.py e gerar_objetos.py.
# Uso: python3 tools/arte/gerar_premios.py   (rodar na raiz do projeto)
#      python3 tools/arte/gerar_premios.py --previa saida.png
import os
import sys

from PIL import Image

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_objetos import Q  # noqa: E402
import gerar_armas as armas   # noqa: E402

PASTA = 'assets/art/convidados/premios'


def bordao():
    # Bastão de caminhada do Próskopos: vara longa de madeira clara, com a
    # cabeça entalhada, faixa verde com anel dourado e ponteira de ferro.
    # Ponta para baixo, como as outras armas; o punho 2×2 fica vazio.
    q = Q(8, 40); g = armas.PEGA['bordao'] = (3, 7); gx, gy = g
    q.r(gx - 1, 0, gx + 2, 3, 'madeira')                                         # cabeça entalhada
    q.r(gx - 1, 0, gx, 2, 'madeira_luz'); q.linha(3, gx - 1, gx + 2, 'madeira_sombra')
    q.p(gx + 2, 1, 'madeira_sombra')
    q.r(gx, 4, gx + 1, 5, 'folha'); q.p(gx, 4, 'folha_luz')                      # faixa verde
    q.linha(6, gx, gx + 1, 'ouro')                                               # anel
    armas.cabo(q, gx, gy + 2, 35)                                                # vara
    for y in (14, 22, 30):                                                       # nós da madeira
        q.p(gx + 1, y, 'madeira_sombra')
    q.r(gx, 36, gx + 1, 38, 'pedra'); q.p(gx, 36, 'pedra_luz')                    # ponteira
    return armas.contornar_menos(q, armas.punho(g))


def icone_elixir():
    # Elixir de Chymeía: frasco de química (cônico) com as três poções em
    # camadas (vigor, rapidez e cura) e brilhos dourados em volta.
    q = Q(32, 32)
    for i in range(16):                                                          # vidro cônico
        meia = 3 + (i * 8) // 15
        q.linha(12 + i, 16 - meia, 15 + meia, 'olho_escuro')
    for i in range(14):                                                          # líquido em 3 faixas
        meia = 2 + (i * 8) // 15
        cor = 'vigor' if i < 4 else 'rapidez' if i < 9 else 'cura'
        q.linha(14 + i, 16 - meia, 15 + meia, cor)
    q.linha(14, 14, 17, 'vigor_luz'); q.linha(18, 12, 19, 'rapidez_luz'); q.linha(23, 10, 21, 'cura_luz')
    q.r(13, 5, 18, 11, 'olho_escuro'); q.r(14, 6, 17, 11, 'nuvem')               # gargalo
    q.r(12, 4, 19, 5, 'pedra_luz')                                               # boca
    q.r(14, 0, 17, 3, 'madeira'); q.r(14, 0, 15, 3, 'madeira_luz')               # rolha
    q.linha(9, 13, 18, 'ouro'); q.p(15, 10, 'ouro_luz'); q.p(16, 10, 'ouro')     # cordão
    q.coluna(11, 15, 18, 'branco'); q.p(12, 14, 'branco')                        # reflexo
    im = q.contornar()
    for (x, y) in ((4, 8), (26, 6), (27, 18), (3, 20)):                          # brilhos (sem contorno)
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            im.putpixel((x + dx, y + dy), (255, 236, 160, 255) if (dx, dy) == (0, 0) else (236, 189, 117, 255))
    return im


def icone_racao():
    # Ração de trilha: trouxinha de pano amarrada, com pão e frutas secas.
    q = Q(32, 32)
    q.elipse(16, 22, 11, 7, 'couro')                                             # pano
    q.elipse(14, 21, 8, 5, 'couro_luz')
    q.r(5, 26, 27, 27, 'couro_sombra')
    q.elipse(11, 13, 6, 3, 'madeira')                                            # pão comprido
    q.elipse(10, 12, 4, 2, 'madeira_luz')
    for x in (8, 11, 14):                                                        # cortes na casca
        q.p(x, 12, 'madeira_sombra'); q.p(x + 1, 13, 'madeira_sombra')
    q.elipse(20, 14, 3, 3, 'vigor_sombra'); q.p(19, 13, 'vigor')                 # fruta seca
    q.elipse(24, 16, 2, 2, 'ferrugem'); q.p(23, 15, 'ferrugem_luz')
    q.r(13, 16, 19, 17, 'couro_sombra')                                          # nó
    q.r(15, 15, 17, 18, 'couro'); q.p(15, 15, 'couro_luz')
    q.p(12, 18, 'couro_sombra'); q.p(20, 18, 'couro_sombra')
    return q.contornar()


def artes():
    return {
        '%s/bordao_na_mao.png' % PASTA: bordao(),
        '%s/icone_bordao.png' % PASTA: armas._no_centro(armas._arma_inteira(bordao, 'bordao'), girar=-40),
        '%s/icone_elixir_chymeia.png' % PASTA: icone_elixir(),
        '%s/icone_racao_trilha.png' % PASTA: icone_racao(),
    }


if __name__ == '__main__':
    saida = artes()
    if len(sys.argv) == 3 and sys.argv[1] == '--previa':
        icones = [im for nome, im in saida.items() if 'icone_' in nome]
        tela = Image.new('RGBA', (len(icones) * 200, 200), (40, 44, 60, 255))
        for i, im in enumerate(icones):
            tela.alpha_composite(im.resize((192, 192), Image.NEAREST), (i * 200 + 4, 4))
        tela.save(sys.argv[2])
    else:
        for caminho, im in saida.items():
            os.makedirs(os.path.dirname(caminho), exist_ok=True)
            im.save(caminho)
            print(caminho, im.size)
        print('pega do bastão:', armas.PEGA['bordao'])
