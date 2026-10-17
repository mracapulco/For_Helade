# Gera a arte dos "convidados": pessoas reais (e, depois, pets) que aparecem
# no jogo como easter egg. Não são personagens do livro.
# Uso: python3 tools/arte/gerar_convidados.py   (rodar na raiz do projeto)
# Para cada convidado grava em assets/art/convidados/<id>/:
# - <id>_exploracao.png e .tres: folha de animação 32×48 (mesma grade, mesmas
#   animações e mesmas partes de gerar_personagens.py);
# - <id>_parado.png: um quadro parado de frente (figurante no acampamento);
# - <id>_figurante.png: faixa de 4 quadros 32×48 respirando (como o mercador);
# Os retratos da caixa de diálogo saem de retratos_convidados.py (a partir de
# fotos, que não ficam no repositório).
# E as peças próprias de cada um (barraca do Rafael, banca da Shara).
#
# Para acrescentar alguém: copie uma entrada de CONVIDADOS, troque as cores e
# escolha o cabelo ('rebelde', 'ombros', 'longo', 'topete', 'chanel') e a
# roupa ('camiseta', 'moletom', 'escoteiro', 'colete', 'vestido_curto',
# 'vestido_longo'). Opcionais: 'oculos' (cor da armação), 'mochila' (True,
# com as cores 'mochila*' e 'alca*'), 'olho' (cor da íris), 'pele' (tons),
# 'chapeu' (True: chapéu de abas largas com a copa vincada em quatro, com as
# cores 'chapeu*' e 'fita').
# Altura: 'topo' é a linha do alto da cabeça (menor = mais alto) e 'tronco' o
# comprimento do tronco; 'largura' é meia largura do tronco.
# Pets vão precisar de um desenho próprio (corpo de quatro patas); a folha e o
# SpriteFrames (folha(), sprite_frames()) servem igual.
import os
import sys

from PIL import Image

sys.dont_write_bytecode = True  # sem __pycache__ dentro de tools/
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_personagens import ANIM, BASE, CX, DIRS, ORDEM, W, HH, H, personagem, sprite_frames  # noqa: E402
from gerar_objetos import C, H as H_OBJ, Q as QObj  # noqa: E402

PELE_CLARA = dict(pele_luz='#F0D4C2', pele='#DDB39E', pele_sombra='#B08470')

CONVIDADOS = {
    # Rafael: alto, pele clara, sem barba, cabelo castanho escuro curto com
    # topete, olhos verdes. Viajante escoteiro: camisa caqui de manga curta
    # com bolsos, lenço verde com anel dourado, cinto, calça e botas, mochila.
    'rafael': dict(
        topo=3, tronco=13, largura=5, cabelo='topete', roupa='escoteiro',
        pele=PELE_CLARA, olho='#4E8A4A', mochila=True, chapeu=True,
        cores=dict(
            chapeu_luz='#B0905E', chapeu='#8C6E44', chapeu_sombra='#644C2C', fita='#3A2A1C',
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
    # armação redonda escura. Mercadora de livros e poções, com roupa da época:
    # vestido longo escuro (o preto de sempre dela) e sapatos de couro.
    'shara': dict(
        topo=8, tronco=11, largura=4, cabelo='longo', roupa='vestido_longo',
        pele=PELE_CLARA, olho='#5FA070', oculos='#1A1A20',
        cores=dict(
            cab_luz='#A87A52', cab='#7C5434', cab_sombra='#583A22', cab_fundo='#3C2614',
            vestido_luz='#4A4A58', vestido='#2C2C36', vestido_sombra='#1A1A22',
            calca='#1A1A22', calca_sombra='#101016',
            sapato='#4A3428', sapato_sombra='#2E2019',
        ),
    ),
}


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


def chapeu(im, cfg, x, y):
    # chapéu de abas largas com a copa em ponta vincada (como o de Baden-Powell),
    # por cima do cabelo; y é o topo da cabeça. Igual de frente e de costas.
    cores = {k: H(v) for k, v in cfg['cores'].items()}
    px = im.load()
    novos = set()

    def r(x0, y0, x1, y1, c):
        for yy in range(y0, y1 + 1):
            for xx in range(x0, x1 + 1):
                if 0 <= xx < W and 0 <= yy < HH:
                    px[xx, yy] = cores[c]; novos.add((xx, yy))
    r(x - 1, y - 2, x + 1, y - 2, 'chapeu')
    r(x - 2, y - 1, x + 2, y - 1, 'chapeu')
    r(x - 3, y, x + 3, y, 'chapeu')
    r(x - 2, y - 1, x - 1, y, 'chapeu_luz')
    r(x, y - 2, x, y, 'chapeu_sombra')            # vinco do meio
    r(x + 2, y - 1, x + 3, y, 'chapeu_sombra')
    r(x - 4, y + 1, x + 4, y + 1, 'fita')
    r(x - 8, y + 2, x + 8, y + 2, 'chapeu')        # aba larga
    r(x - 7, y + 2, x - 4, y + 2, 'chapeu_luz')
    r(x - 8, y + 3, x - 6, y + 3, 'chapeu_sombra')
    r(x + 6, y + 3, x + 8, y + 3, 'chapeu_sombra')
    contorno = H(BASE['contorno'])
    for (xx, yy) in novos:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (xx + dx, yy + dy)
            if n not in novos and 0 <= n[0] < W and 0 <= n[1] < HH and px[n][3] == 0:
                px[n] = contorno
    return im


def figura(cfg, dir, **k):
    im = personagem(cfg, dir, **k)
    if cfg.get('chapeu'):
        chapeu(im, cfg, CX + k.get('inclina', 0), cfg['topo'] + k.get('dy', 0))
    return im


def folha(cfg):
    # mesma folha de gerar_personagens.folha(), com os acessórios dos convidados
    linhas = [(d, a) for d in DIRS for a in ORDEM]
    im = Image.new('RGBA', (W * 4, HH * len(linhas)), (0, 0, 0, 0))
    for linha, (d, a) in enumerate(linhas):
        for i, k in enumerate(ANIM[a]):
            im.paste(figura(cfg, d, **k), (i * W, linha * HH))
    return im, linhas


def faixa_figurante(cfg):
    # 4 quadros parado de frente, respirando (mesmo formato do mercador)
    quadros = [figura(cfg, 'frente', **k) for k in ANIM['parado']]
    im = Image.new('RGBA', (W * 4, HH), (0, 0, 0, 0))
    for i, q in enumerate([0, 0, 1, 1]):
        im.paste(quadros[q], (i * W, 0))
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
        figura(cfg, 'frente').save(os.path.join(pasta, '%s_parado.png' % id))
        faixa_figurante(cfg).save(os.path.join(pasta, '%s_figurante.png' % id))
        for nome, desenho in PECAS.get(id, {}).items():
            desenho().save(os.path.join(pasta, '%s.png' % nome))
        print(id, im.size)
