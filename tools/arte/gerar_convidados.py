# Gera as folhas de animação dos "convidados": pessoas reais (e, depois,
# pets) que aparecem no jogo como easter egg. Não são personagens do livro.
# Mesma grade, mesmas animações e mesmas partes de gerar_personagens.py.
# Uso: python3 tools/arte/gerar_convidados.py
# Grava assets/art/convidados/<id>/<id>_exploracao.png e o SpriteFrames
# <id>_exploracao.tres ao lado. Rodar de novo recria tudo.
#
# Para acrescentar alguém: copie uma entrada de CONVIDADOS, troque as cores e
# escolha o cabelo ('rebelde', 'ombros', 'longo', 'topete', 'chanel') e a
# roupa ('camiseta', 'moletom', 'colete', 'vestido_curto', 'vestido_longo').
# Opcionais: 'oculos' (cor da armação), 'mochila' (True, com as cores
# 'mochila*' e 'alca*'), 'olho' (cor da íris), 'pele' (tons da pele).
# Altura: 'topo' é a linha do alto da cabeça (menor = mais alto) e 'tronco' o
# comprimento do tronco; 'largura' é meia largura do tronco.
# Pets vão precisar de um desenho próprio (corpo de quatro patas); a folha e o
# SpriteFrames (folha(), sprite_frames()) servem igual.
import os
from gerar_personagens import folha, sprite_frames

PELE_CLARA = dict(pele_luz='#F0D4C2', pele='#DDB39E', pele_sombra='#B08470')
JEANS = dict(calca='#3E5470', calca_sombra='#2A3A50')

CONVIDADOS = {
    # Rafael: alto, pele clara, sem barba, cabelo castanho escuro curto com
    # topete; camiseta verde-clara, jeans, tênis escuro e mochila azul-acinzentada.
    'rafael': dict(
        topo=3, tronco=13, largura=5, cabelo='topete', roupa='camiseta',
        pele=PELE_CLARA, olho='#7A6A48', mochila=True,
        cores=dict(
            cab_luz='#6B4A34', cab='#4A3022', cab_sombra='#2E1C13', cab_fundo='#1C110B',
            camiseta_luz='#DDF2E2', camiseta='#B5DCC2', camiseta_sombra='#86B596',
            mochila_luz='#6E8EAC', mochila='#4E6E8E', mochila_sombra='#34506C',
            alca='#C4C8CC', alca_sombra='#9095A0',
            sapato='#4A4A50', sapato_sombra='#2C2C30',
            **JEANS,
        ),
    ),
    # Shara: pele clara, cabelo castanho liso na altura dos ombros, óculos de
    # armação redonda escura, moletom preto, jeans e tênis escuro.
    'shara': dict(
        topo=8, tronco=11, largura=4, cabelo='chanel', roupa='moletom',
        pele=PELE_CLARA, olho='#6A8494', oculos='#1A1A20',
        cores=dict(
            cab_luz='#A07A54', cab='#7A5838', cab_sombra='#573C24', cab_fundo='#3A2716',
            moletom_luz='#46464E', moletom='#2A2A31', moletom_sombra='#18181D',
            cordao='#B8BCC4',
            sapato='#4A4A50', sapato_sombra='#2C2C30',
            **JEANS,
        ),
    ),
}


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
        print(id, im.size)
