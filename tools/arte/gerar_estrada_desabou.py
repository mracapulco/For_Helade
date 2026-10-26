# Gera a arte provisória da fase "A estrada desabou" (estrada Atenas–Olympia,
# trecho 3): caixa, barril e toras da carga, o buraco da estrada e as pontes
# que as peças fazem ao cair nele, pedras (fixas e rolando), a encosta, a
# beira do precipício, a carroça do comboio, o carroceiro e o ninho de águia.
# Mesma paleta e contorno de gerar_objetos.py. Nada aqui é do livro: o
# carroceiro e a carroça são inventados (provisórios, Rafael autorizou em
# 26/10/2026) até a arte final.
# Uso: python3 tools/arte/gerar_estrada_desabou.py   (rodar na raiz do projeto)
import math
import os
import random
import sys

from PIL import Image

sys.dont_write_bytecode = True  # sem __pycache__ dentro de tools/
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_objetos import C, H, Q  # noqa: E402

C.update(
    terra=H('#6B5238'), terra_luz=H('#8A6C4A'), terra_sombra=H('#4A3826'),
    vazio=H('#120C10'), vazio_meio=H('#22171A'),
    rocha_luz=H('#A49C92'), rocha=H('#7A7268'), rocha_sombra=H('#4E4842'),
    grama=H('#5E7344'), grama_sombra=H('#435533'), grama_luz=H('#7C8F55'),
    tunica=H('#8A6A44'), tunica_sombra=H('#664C30'), chapeu=H('#C8A860'), chapeu_sombra=H('#9C8040'),
    barba=H('#5A4030'), cavalo=H('#7A5236'), cavalo_sombra=H('#553824'), crina=H('#2E2018'),
    ovo=H('#EDE6D6'), penas=H('#4A3A2E'), penas_luz=H('#7A6450'), bico=H('#D8A840'),
)

PASTA = 'assets/art/estrada_oa/estrada_desabou'


def losango(q, cx, cy, mw, mh, c):
    """Losango cheio (face de cima) com centro (cx, cy) e meias medidas."""
    for y in range(cy - mh, cy + mh + 1):
        meia = round(mw * (1 - abs(y - cy) / (mh + 0.5)))
        q.linha(y, cx - meia, cx + meia, c)


def bloco_iso(q, cx, cy, mw, mh, alt, topo, esq, dir_):
    """Caixa isométrica: base com centro (cx, cy), altura alt em pixels."""
    # faces laterais: a borda de baixo da base, levantada até a altura
    for x in range(cx - mw, cx + mw + 1):
        fundo = cy + mh - round(abs(x - cx) * mh / mw)
        q.coluna(x, fundo - alt, fundo, esq if x < cx else dir_)
    losango(q, cx, cy - alt, mw, mh, topo)


# ---------- peças da carga ----------

def caixa():
    q = Q(40, 42)
    q.sombra_no_chao(20, 32, 18, 7)
    bloco_iso(q, 20, 32, 18, 9, 20, 'madeira_luz', 'madeira', 'madeira_sombra')
    # tábuas e cintas na frente
    for x in range(3, 37):
        base = 41 - round(abs(x - 20) * 9 / 18) - 1
        if x in (4, 19, 20, 35):
            q.coluna(x, base - 19, base, 'madeira_sombra')
        q.p(x, base - 10, 'madeira_sombra')
    losango(q, 20, 12, 12, 5, 'madeira')
    losango(q, 20, 12, 10, 4, 'madeira_luz')
    return q.contornar()


def barril():
    q = Q(26, 32)
    q.sombra_no_chao(13, 28, 11, 4)
    for y in range(6, 28):
        q.linha(y, 3, 22, 'madeira')
        q.r(3, y, 6, y, 'madeira_luz'); q.r(19, y, 22, y, 'madeira_sombra')
    q.elipse(13, 28, 10, 3, 'madeira_sombra')
    for y in (10, 22):
        q.linha(y, 3, 22, 'pedra_sombra'); q.linha(y + 1, 3, 22, 'pedra')
    q.elipse(13, 6, 10, 3, 'madeira_luz')
    q.elipse(13, 6, 7, 2, 'madeira')
    q.p(13, 6, 'madeira_sombra')
    return q.contornar()


def tora(eixo):
    # tronco deitado ao longo de x da grade (desce para a direita na tela) ou
    # de y (desce para a esquerda); o centro da casa fica em (32, 26).
    q = Q(64, 40)
    sinal = 1 if eixo == 'x' else -1
    dx, dy = 2 * sinal, 1
    norma = math.hypot(dx, dy)
    ux, uy = dx / norma, dy / norma
    for t in range(-24, 25):
        cx, cy = 32 + ux * t, 26 + uy * t
        q.sombra_no_chao(round(cx), round(cy) + 3, 6, 2)
    for t in range(-24, 25):
        cx, cy = 32 + ux * t, 22 + uy * t
        q.elipse(round(cx), round(cy), 6, 6, 'madeira')
        q.p(round(cx), round(cy) - 5, 'madeira_luz'); q.p(round(cx), round(cy) - 4, 'madeira_luz')
        q.p(round(cx), round(cy) + 5, 'madeira_sombra')
    # pontas cortadas (anéis claros)
    for ponta in (-1, 1):
        cx, cy = 32 + ux * 25 * ponta, 22 + uy * 25 * ponta
        q.elipse(round(cx), round(cy), 4 if ponta > 0 else 3, 6, 'madeira_luz')
        q.p(round(cx), round(cy), 'madeira_sombra')
    # nós da casca
    for t in (-12, 4, 15):
        q.p(round(32 + ux * t), round(20 + uy * t), 'madeira_sombra')
    return q.contornar()


# ---------- buraco e pontes (64×32, centro da casa no meio) ----------

def _buraco_base(q):
    losango(q, 32, 16, 31, 15, 'vazio')
    # paredes de terra no fundo do buraco (as bordas de cima)
    rng = random.Random(3)
    for x in range(1, 63):
        topo = 16 - round(15 * (1 - abs(x - 32) / 31.5))
        fundo = topo + 5 + rng.randint(0, 2)
        q.coluna(x, topo, fundo, 'terra_sombra' if x < 32 else 'terra')
        if rng.random() < 0.3:
            q.p(x, fundo + 1, 'vazio_meio')
    # torrões soltos na borda de baixo
    for x in range(4, 61, 5):
        base = 16 + round(15 * (1 - abs(x - 32) / 31.5))
        q.p(x, base, 'terra'); q.p(x + 1, base - 1, 'terra_luz')


def buraco():
    q = Q(64, 32)
    _buraco_base(q)
    return q.im


def ponte(tipo):
    q = Q(64, 32)
    _buraco_base(q)
    if tipo == 'caixa':
        losango(q, 32, 18, 22, 10, 'madeira')
        losango(q, 32, 18, 19, 8, 'madeira_luz')
        for x in range(14, 51, 6):
            q.coluna(x, 18 - round(8 * (1 - abs(x - 32) / 19.5)), 18 + round(8 * (1 - abs(x - 32) / 19.5)), 'madeira_sombra')
    elif tipo == 'barril':
        q.elipse(32, 18, 14, 7, 'madeira_sombra')
        q.elipse(32, 17, 12, 6, 'madeira_luz')
        q.elipse(32, 17, 9, 4, 'madeira')
        q.p(32, 17, 'madeira_sombra')
        for x in (18, 46):   # terra empurrada para os lados
            q.r(x - 3, 16, x + 3, 19, 'terra')
    else:
        for desloc in (-4, 4):
            for t in range(-22, 23):
                cx, cy = 32 + 2 * t / math.sqrt(5) * 1.0, 17 + t / math.sqrt(5) + desloc
                q.elipse(round(cx), round(cy), 3, 3, 'madeira')
                q.p(round(cx), round(cy) - 2, 'madeira_luz')
    return q.contornar()


# ---------- pedras ----------

def pedra_fixa(semente):
    rng = random.Random(semente)
    q = Q(48, 40)
    q.sombra_no_chao(24, 32, 21, 6)
    for i in range(5):
        cx, cy = 24 + rng.randint(-10, 10), 22 + rng.randint(-4, 6)
        rx, ry = rng.randint(8, 13), rng.randint(7, 11)
        q.elipse(cx, cy, rx, ry, 'rocha')
        q.elipse(cx - 2, cy - 3, rx - 4, ry - 4, 'rocha_luz')
        q.elipse(cx + 3, cy + 4, rx - 6, max(ry - 7, 1), 'rocha_sombra')
    for _ in range(6):
        x, y = rng.randint(8, 40), rng.randint(14, 30)
        q.p(x, y, 'rocha_sombra'); q.p(x + 1, y + 1, 'rocha_sombra')
    return q.contornar()


def pedra_rolando():
    # quatro quadros: a mesma pedra girando (as rachaduras andam)
    quadros = []
    for i in range(4):
        q = Q(24, 22)
        q.elipse(12, 11, 10, 9, 'rocha')
        q.elipse(10, 8, 6, 5, 'rocha_luz')
        q.elipse(14, 15, 5, 3, 'rocha_sombra')
        a = i * math.pi / 2
        for t in range(-5, 6):
            x = 12 + round(math.cos(a) * t)
            y = 11 + round(math.sin(a) * t * 0.9)
            q.p(x, y, 'rocha_sombra')
        q.p(12 + round(math.cos(a + 1) * 6), 11 + round(math.sin(a + 1) * 5), 'pedra_sombra')
        quadros.append(q.contornar())
    folha = Image.new('RGBA', (24 * 4, 22), (0, 0, 0, 0))
    for i, im in enumerate(quadros):
        folha.paste(im, (24 * i, 0))
    return folha


def encosta(semente):
    # pedaço do paredão da encosta, acima da estrada (64 de largura)
    rng = random.Random(semente)
    q = Q(64, 72)
    for x in range(64):
        alto = 8 + rng.randint(0, 10) + round(abs(x - 32) * 0.3)
        q.coluna(x, alto, 71 - round(abs(x - 32) / 2), 'rocha_sombra' if x > 40 else 'rocha')
    for _ in range(14):
        cx, cy = rng.randint(6, 58), rng.randint(14, 56)
        q.elipse(cx, cy, rng.randint(3, 7), rng.randint(2, 5), 'rocha_luz' if rng.random() < 0.5 else 'rocha_sombra')
    for _ in range(10):   # tufos de mato nas fendas
        x, y = rng.randint(4, 60), rng.randint(10, 60)
        q.r(x, y, x + 2, y + 1, 'grama'); q.p(x + 1, y - 1, 'grama_luz')
    return q.contornar()


def beira():
    # a face do barranco abaixo da borda de baixo-esquerda de uma casa da
    # última fileira: do canto esquerdo (0, 0) ao de baixo (32, 16), caindo
    # 40 px; as casas vizinhas emendam sem costura
    rng = random.Random(5)
    q = Q(32, 58)
    for x in range(32):
        topo = round(x / 2)
        fundo = topo + 40
        for y in range(topo, min(fundo, 57) + 1):
            prof = (y - topo) / 40
            cor = 'terra' if prof < 0.25 else ('terra_sombra' if prof < 0.7 else 'vazio_meio')
            q.p(x, y, cor)
        q.p(x, topo, 'grama_sombra'); q.p(x, topo + 1, 'grama_sombra')
    for _ in range(10):
        x = rng.randint(1, 30)
        y = round(x / 2) + rng.randint(5, 26)
        q.r(x, y, x + 1, y, 'rocha_sombra'); q.p(x, y - 1, 'rocha')
    return q.im


# ---------- gente e carroça (inventadas, provisórias) ----------

def carroca():
    # carroça pesada do comboio, carregada, com um cavalo virado para a
    # direita de baixo (o sentido da estrada na tela)
    q = Q(88, 60)
    q.sombra_no_chao(40, 52, 36, 7)
    # caixa da carroça
    bloco_iso(q, 30, 42, 24, 12, 14, 'madeira_luz', 'madeira', 'madeira_sombra')
    # carga: fardos e barris em cima
    losango(q, 26, 24, 9, 4, 'nuvem'); q.r(18, 20, 34, 24, 'prata')
    q.elipse(38, 22, 5, 7, 'madeira'); q.elipse(38, 16, 5, 2, 'madeira_luz')
    # rodas
    for (cx, cy) in ((14, 46), (40, 52)):
        q.elipse(cx, cy, 7, 8, 'madeira_sombra'); q.elipse(cx, cy, 5, 6, 'madeira')
        q.p(cx, cy, 'contorno'); q.coluna(cx, cy - 6, cy + 6, 'madeira_sombra'); q.linha(cy, cx - 5, cx + 5, 'madeira_sombra')
    # varais até o cavalo
    for t in range(18):
        q.p(52 + t, 42 + t // 2, 'madeira_sombra')
    # cavalo
    q.elipse(70, 40, 10, 6, 'cavalo'); q.elipse(68, 38, 7, 3, 'cavalo')
    for px in (63, 66, 74, 77):
        q.r(px, 44, px + 1, 53, 'cavalo_sombra'); q.p(px, 53, 'contorno')
    q.r(77, 30, 81, 38, 'cavalo'); q.r(80, 31, 85, 35, 'cavalo'); q.p(84, 33, 'contorno')
    q.coluna(77, 29, 37, 'crina'); q.coluna(76, 31, 37, 'crina')
    q.r(59, 38, 61, 46, 'crina')   # cauda
    return q.contornar()


def carroceiro():
    q = Q(32, 48)
    q.sombra_no_chao(16, 45, 8, 2)
    x = 16
    for px in (x - 4, x + 1):
        q.r(px, 34, px + 2, 42, 'pele_sombra')
        q.r(px, 43, px + 3, 45, 'couro'); q.linha(45, px, px + 3, 'couro_sombra')
    q.r(x - 6, 17, x + 5, 35, 'tunica')
    q.coluna(x + 5, 17, 35, 'tunica_sombra'); q.r(x - 5, 18, x - 4, 34, 'couro_luz')
    q.linha(26, x - 6, x + 5, 'couro_sombra')       # cinto de corda
    q.r(x - 8, 18, x - 7, 29, 'pele'); q.r(x + 6, 18, x + 7, 29, 'pele_sombra')
    q.r(x + 6, 12, x + 7, 30, 'madeira')            # chicote de condutor, de pé
    q.r(x - 3, 8, x + 3, 16, 'pele'); q.coluna(x - 3, 8, 16, 'pele_sombra')
    q.p(x - 1, 11, 'olho_escuro'); q.p(x + 2, 11, 'olho_escuro')
    q.r(x - 3, 13, x + 3, 16, 'barba'); q.p(x, 14, 'pele_sombra')
    # chapéu de palha de abas largas
    q.r(x - 7, 7, x + 7, 8, 'chapeu'); q.linha(8, x - 7, x + 7, 'chapeu_sombra')
    q.r(x - 3, 3, x + 3, 7, 'chapeu'); q.coluna(x + 3, 3, 7, 'chapeu_sombra')
    return q.contornar()


def ninho():
    # ninho de águia no alto de um pico de pedra (só cenário)
    q = Q(44, 64)
    for y in range(22, 64):
        meia = 6 + (y - 22) * 12 // 42
        q.linha(y, 22 - meia, 22 + meia, 'rocha')
        q.r(22 + meia - 3, y, 22 + meia, y, 'rocha_sombra'); q.r(22 - meia, y, 22 - meia + 2, y, 'rocha_luz')
    q.elipse(22, 22, 11, 4, 'madeira_sombra')
    for i in range(16):
        a = i * math.pi / 8
        q.p(22 + round(math.cos(a) * 11), 22 + round(math.sin(a) * 4), 'madeira_luz')
    q.p(17, 20, 'ovo'); q.p(18, 20, 'ovo')
    # a águia de perfil, pousada
    q.elipse(25, 13, 5, 6, 'penas'); q.elipse(24, 12, 3, 4, 'penas_luz')
    q.r(26, 3, 29, 7, 'branco'); q.p(28, 5, 'contorno'); q.r(30, 5, 31, 6, 'bico')
    q.r(20, 15, 22, 19, 'penas')
    return q.contornar()


def salvar(nome, imagem):
    imagem.save(os.path.join(PASTA, nome + '.png'))


def main():
    os.makedirs(PASTA, exist_ok=True)
    salvar('caixa', caixa())
    salvar('barril', barril())
    salvar('tora_x', tora('x'))
    salvar('tora_y', tora('y'))
    salvar('buraco', buraco())
    for tipo in ('caixa', 'barril', 'tora'):
        salvar('ponte_' + tipo, ponte(tipo))
    for i in range(3):
        salvar('pedra_fixa_%d' % (i + 1), pedra_fixa(10 + i))
    salvar('pedra_rolando', pedra_rolando())
    for i in range(3):
        salvar('encosta_%d' % (i + 1), encosta(20 + i))
    salvar('beira', beira())
    salvar('carroca', carroca())
    salvar('carroceiro', carroceiro())
    salvar('ninho', ninho())


if __name__ == '__main__':
    main()
