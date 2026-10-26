# Gera as artes provisórias em pixel art da fase "Cavalos soltos" (estrada
# Atenas–Olympia, olivais da saída de Atenas): os três cavalos do comboio,
# oliveiras, macieira, colunas caídas, mureta e cerca em diagonal (bordas das
# casas isométricas), o marco antigo, o carroceiro e a fruta (ícone, na mão e
# no chão).
# Nada aqui é do livro: o carroceiro e os cavalos são figurantes inventados
# (Rafael autorizou, 26/10/2026), provisórios até a arte final.
# Uso: python3 tools/arte/gerar_estrada_oa_cavalos.py   (rodar na raiz do projeto)
import os
import sys

from PIL import Image

sys.dont_write_bytecode = True  # sem __pycache__ dentro de tools/
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_objetos import C, H, Q  # noqa: E402

C.update(
    # oliveira: verde acinzentado, o prata das folhas por baixo
    oliva_sombra=H('#34402F'), oliva=H('#56654A'), oliva_luz=H('#8A9878'), oliva_prata=H('#B5BCA6'),
    # macieira e grama de dia
    copa_sombra=H('#2F4A2C'), copa=H('#4A6B3A'), copa_luz=H('#6E8A52'),
    # palha do chapéu do carroceiro
    palha_sombra=H('#8C7240'), palha=H('#C2A160'), palha_luz=H('#E2C98A'),
    # pelagens: castanho, tordilho (cinzento) e preto
    castanho_sombra=H('#4E2E1C'), castanho=H('#7A4A2C'), castanho_luz=H('#A06A3E'),
    tordilho_sombra=H('#7C7F88'), tordilho=H('#B4B7BE'), tordilho_luz=H('#E0E1E4'),
    preto_sombra=H('#0B1018'), preto=H('#1C2430'), preto_luz=H('#3A4658'),
)

PASTA = 'assets/art/placeholders/estrada_oa/cavalos_soltos'
PASTA_ITENS = 'assets/art/placeholders/combate'

# Cada cavalo: (pelo, sombra, luz, crina, focinho)
PELAGENS = {
    'castanho': ('castanho', 'castanho_sombra', 'castanho_luz', 'preto', 'castanho_sombra'),
    'tordilho': ('tordilho', 'tordilho_sombra', 'tordilho_luz', 'pedra', 'pedra_sombra'),
    'preto': ('preto', 'preto_sombra', 'preto_luz', 'preto_sombra', 'nuvem'),
}
LARGURA_CAVALO, ALTURA_CAVALO = 40, 32
# Quadros da folha (lado a lado): parado, pastando, passo A, passo B.
QUADROS = ('parado', 'pastando', 'passo_a', 'passo_b')


def _cavalo(pelagem, quadro):
    pelo, sombra, luz, crina, focinho = PELAGENS[pelagem]
    q = Q(LARGURA_CAVALO, ALTURA_CAVALO)
    q.sombra_no_chao(19, 29, 14, 2)
    # pernas: de trás em x 10/13, da frente em x 24/27; o passo abre e fecha
    abre = {'passo_a': 1, 'passo_b': -1}.get(quadro, 0)
    for i, px in enumerate((10, 13, 24, 27)):
        dx = abre if i % 2 == 0 else -abre
        q.r(px + dx, 19, px + dx + 1, 27, sombra if i in (1, 3) else pelo)
        q.r(px + dx, 27, px + dx + 1, 28, 'noite')                       # casco
    # corpo
    q.elipse(18, 15, 11, 5, pelo)
    q.linha(11, 11, 25, luz); q.linha(10, 14, 22, luz)                    # lombo ao sol
    q.r(12, 18, 24, 19, sombra)                                           # barriga
    # cauda
    q.r(5, 11, 7, 13, crina); q.r(4, 14, 6, 21, crina); q.p(5, 22, crina)
    if quadro == 'pastando':
        # pescoço desce e a cabeça fica no chão
        q.r(26, 13, 30, 19, pelo); q.r(29, 18, 33, 22, pelo)
        q.r(31, 21, 36, 26, pelo); q.r(34, 24, 36, 27, focinho)
        q.p(32, 22, 'noite')                                              # olho
        q.r(25, 11, 27, 16, crina); q.r(28, 16, 29, 19, crina)            # crina
        q.p(30, 20, luz)
    else:
        # pescoço erguido e cabeça
        q.r(25, 8, 29, 14, pelo); q.r(27, 5, 31, 9, pelo)
        q.r(30, 3, 36, 8, pelo); q.r(34, 6, 37, 9, focinho)
        q.p(33, 5, 'noite')                                               # olho
        q.r(29, 1, 30, 3, pelo); q.p(29, 0, sombra)                       # orelha
        q.r(24, 7, 26, 13, crina); q.r(26, 4, 28, 7, crina)               # crina
        q.linha(4, 31, 34, luz)
    return q.contornar()


def folha_cavalo(pelagem):
    folha = Image.new('RGBA', (LARGURA_CAVALO * len(QUADROS), ALTURA_CAVALO), (0, 0, 0, 0))
    for i, quadro in enumerate(QUADROS):
        folha.alpha_composite(_cavalo(pelagem, quadro), (i * LARGURA_CAVALO, 0))
    return folha


def oliveira(variante=0):
    # tronco retorcido e copa larga, verde-acinzentada com o prata das folhas
    q = Q(48, 52)
    q.sombra_no_chao(24, 49, 16, 3)
    torce = (0, 2, -2)[variante % 3]
    for y in range(28, 50):
        meio = 24 + (torce * (49 - y)) // 21
        q.r(meio - 3, y, meio + 2, y, 'madeira')
        q.p(meio - 3, y, 'madeira_sombra'); q.p(meio + 2, y, 'madeira_luz')
    q.r(20, 46, 29, 49, 'madeira')                                        # raízes
    q.p(18, 49, 'madeira_sombra'); q.p(30, 49, 'madeira_sombra')
    q.r(24 + torce, 22, 26 + torce, 30, 'madeira')                        # galho
    q.r(17, 24, 21, 27, 'madeira_sombra')
    tufos = [(14, 18, 10, 7), (32, 17, 11, 7), (23, 11, 12, 8), (24, 21, 14, 6),
             (10, 24, 6, 4), (38, 24, 6, 4)]
    if variante % 2:
        tufos.append((30, 8, 7, 5))
    for (cx, cy, rx, ry) in tufos:
        q.elipse(cx, cy + 1, rx, ry, 'oliva_sombra')
    for (cx, cy, rx, ry) in tufos:
        q.elipse(cx, cy, rx - 1, ry - 1, 'oliva')
    for (cx, cy, rx, ry) in tufos:
        for i in range(-rx + 2, rx - 1, 3):
            q.p(cx + i, cy - ry // 2, 'oliva_luz')
            q.p(cx + i + 1, cy + ry // 2 - 1, 'oliva_prata')
    for (x, y) in ((12, 16), (21, 9), (33, 14), (27, 20), (37, 22)):
        q.p(x, y, 'folha_sombra')                                         # azeitonas
    return q.contornar()


def macieira():
    q = Q(48, 54)
    q.sombra_no_chao(24, 51, 15, 3)
    q.r(21, 30, 26, 51, 'madeira'); q.coluna(21, 30, 51, 'madeira_sombra')
    q.coluna(26, 30, 51, 'madeira_luz')
    q.r(19, 49, 28, 51, 'madeira')
    for (cx, cy, rx, ry) in ((24, 18, 17, 13), (13, 26, 9, 6), (35, 26, 9, 6)):
        q.elipse(cx, cy + 1, rx, ry, 'copa_sombra')
        q.elipse(cx, cy, rx - 1, ry - 1, 'copa')
    q.elipse(20, 13, 8, 5, 'copa_luz')
    for (x, y) in ((14, 18), (22, 22), (31, 16), (27, 9), (36, 25), (12, 27), (18, 28), (33, 29)):
        q.r(x, y, x + 1, y + 1, 'cura'); q.p(x, y, 'cura_luz')            # maçãs
    return q.contornar()


def coluna_caida():
    # tambor de coluna de mármore deitado, com caneluras e a ponta quebrada
    q = Q(54, 22)
    q.sombra_no_chao(27, 19, 25, 2)
    q.r(4, 5, 48, 17, 'prata')
    for y in (7, 10, 13, 16):
        q.linha(y, 5, 47, 'prata_sombra')                                 # caneluras
    q.linha(5, 4, 48, 'lua'); q.linha(17, 4, 48, 'pedra_luz')
    q.elipse(4, 11, 3, 6, 'lua'); q.elipse(4, 11, 1, 4, 'prata')          # face lisa
    for (x, y) in ((49, 6), (50, 9), (48, 12), (51, 14), (49, 16)):
        q.r(48, y, x, y + 1, 'prata_sombra')                              # quebra
    return q.contornar()


def coluna_quebrada():
    q = Q(20, 40)
    q.sombra_no_chao(10, 37, 8, 2)
    q.r(2, 33, 17, 37, 'pedra_luz'); q.linha(33, 2, 17, 'lua')            # base
    q.r(4, 10, 15, 33, 'prata')
    for x in (6, 9, 12):
        q.coluna(x, 11, 32, 'prata_sombra')
    q.coluna(14, 10, 33, 'pedra_luz'); q.coluna(4, 10, 33, 'lua')
    for (x, y) in ((4, 10), (6, 8), (9, 11), (11, 7), (13, 9), (15, 12)):
        q.r(x, y, x + 1, 11, 'prata')                                     # topo partido
    return q.contornar()


def _diagonal(desce_para_direita, altura, desenhar):
    # Peça de borda de casa: base de (0, 0) a (32, 16) (ou espelhada), a
    # [altura] pixels acima dela. O meio da base fica no centro da imagem,
    # na linha [altura] + 10 (o Godot alinha por ali).
    q = Q(36, altura + 22)
    for t in range(0, 33):
        x = t + 2 if desce_para_direita else 34 - t
        base = altura + 2 + t // 2
        desenhar(q, t, x, base)
    return q.contornar()


def _mureta(q, t, x, base):
    q.coluna(x, base - 8, base, 'pedra')
    q.p(x, base - 8, 'pedra_luz'); q.p(x, base, 'pedra_sombra')
    if t % 6 in (0, 1):
        q.p(x, base - 4, 'pedra_sombra')                                  # junta das pedras
    if t % 6 == 3:
        q.p(x, base - 7, 'lua')


def _cerca(q, t, x, base):
    if t in (1, 16, 31):
        q.coluna(x, base - 13, base, 'madeira'); q.p(x, base - 14, 'madeira_luz')
    for alto in (5, 10):
        q.p(x, base - alto, 'madeira_luz')
        q.p(x, base - alto + 1, 'madeira')


def mureta_a():
    return _diagonal(True, 8, _mureta)


def mureta_b():
    return _diagonal(False, 8, _mureta)


def cerca_a():
    return _diagonal(True, 14, _cerca)


def cerca_b():
    return _diagonal(False, 14, _cerca)


def marco():
    # marco de estrada antigo: pedra gasta com três círculos dourados gastos
    # (o símbolo é desenho provisório; sem texto da autora, fica só desenho)
    q = Q(16, 30)
    q.sombra_no_chao(8, 27, 7, 2)
    q.r(3, 6, 12, 26, 'pedra'); q.elipse(8, 6, 4, 3, 'pedra')
    q.coluna(3, 6, 26, 'pedra_sombra'); q.coluna(12, 7, 26, 'pedra_luz')
    q.r(2, 25, 13, 27, 'pedra_sombra')
    for (cx, cy) in ((6, 12), (10, 12), (8, 15)):
        q.p(cx, cy - 1, 'ouro_sombra'); q.p(cx - 1, cy, 'ouro_sombra')
        q.p(cx + 1, cy, 'ouro'); q.p(cx, cy + 1, 'ouro_sombra')
    for (x, y) in ((4, 20), (9, 22), (11, 18)):
        q.p(x, y, 'oliva')                                                # musgo
    return q.contornar()


def carroceiro():
    # Figurante inventado: carroceiro do comboio, chapéu de palha, barba
    # grisalha, túnica de couro e chicote enrolado no cinto.
    q = Q(32, 48)
    q.sombra_no_chao(16, 45, 8, 2)
    x = 16
    q.r(x - 4, 38, x - 2, 44, 'couro'); q.r(x + 1, 38, x + 3, 44, 'couro')      # pernas
    q.r(x - 5, 44, x - 2, 45, 'madeira_sombra'); q.r(x + 1, 44, x + 4, 45, 'madeira_sombra')
    for y in range(18, 39):
        meia = 6 + (y - 18) // 8
        q.linha(y, x - meia, x + meia, 'madeira_luz')
        q.p(x - meia, y, 'madeira'); q.p(x + meia, y, 'ouro_sombra')
    q.linha(29, x - 7, x + 7, 'couro'); q.p(x, 29, 'ouro')                       # cinto
    q.elipse(x + 6, 32, 2, 2, 'couro_luz')                                       # chicote enrolado
    q.r(x - 9, 20, x - 7, 30, 'madeira_luz'); q.r(x + 7, 20, x + 9, 30, 'madeira_luz')  # braços
    q.r(x - 9, 30, x - 7, 32, 'pele'); q.r(x + 7, 30, x + 9, 32, 'pele')
    q.elipse(x, 12, 5, 6, 'pele'); q.coluna(x + 4, 9, 15, 'pele_sombra')         # rosto
    q.p(x - 2, 11, 'noite'); q.p(x + 2, 11, 'noite')
    q.r(x - 4, 14, x + 4, 18, 'prata_sombra'); q.r(x - 3, 18, x + 3, 19, 'prata_sombra')  # barba
    q.linha(15, x - 1, x + 1, 'pele_sombra')
    q.linha(6, x - 9, x + 9, 'palha'); q.linha(7, x - 10, x + 10, 'palha_sombra')  # aba
    q.r(x - 5, 2, x + 5, 6, 'palha'); q.linha(2, x - 4, x + 4, 'palha_luz')
    q.linha(5, x - 5, x + 5, 'ferrugem')                                         # fita
    return q.contornar()


# ---------- a fruta ----------

def _maca(q, cx, cy, r):
    q.elipse(cx, cy, r, r, 'cura')
    q.elipse(cx + r // 3, cy + r // 3, r // 2, r // 2, 'cura_sombra') if r > 3 else None
    q.elipse(cx - r // 3, cy - r // 3, max(r // 3, 1), max(r // 3, 1), 'cura_luz')
    q.coluna(cx, cy - r - 2, cy - r, 'madeira')
    q.r(cx + 1, cy - r - 2, cx + 1 + max(r // 2, 1), cy - r - 1, 'copa_luz')    # folha


def icone_fruta():
    q = Q(32, 32)
    _maca(q, 15, 18, 9)
    return q.contornar()


def fruta_na_mao():
    q = Q(8, 9)
    _maca(q, 3, 5, 2)
    return q.contornar()


def fruta_no_chao():
    q = Q(10, 10)
    q.sombra_no_chao(5, 8, 4, 1)
    _maca(q, 5, 5, 2)
    return q.contornar()


ARTES = {
    'oliveira': lambda: oliveira(0), 'oliveira_b': lambda: oliveira(1), 'oliveira_c': lambda: oliveira(2),
    'macieira': macieira, 'coluna_caida': coluna_caida, 'coluna_quebrada': coluna_quebrada,
    'mureta_a': mureta_a, 'mureta_b': mureta_b, 'cerca_a': cerca_a, 'cerca_b': cerca_b,
    'marco': marco, 'carroceiro': carroceiro, 'fruta_no_chao': fruta_no_chao,
}
ARTES.update({f'cavalo_{p}': (lambda p=p: folha_cavalo(p)) for p in PELAGENS})
ITENS = {'icone_fruta': icone_fruta, 'fruta_na_mao': fruta_na_mao}

if __name__ == '__main__':
    os.makedirs(PASTA, exist_ok=True)
    for nome, desenhar in ARTES.items():
        caminho = f'{PASTA}/{nome}.png'
        desenhar().save(caminho)
        print(caminho)
    for nome, desenhar in ITENS.items():
        caminho = f'{PASTA_ITENS}/{nome}.png'
        desenhar().save(caminho)
        print(caminho)
