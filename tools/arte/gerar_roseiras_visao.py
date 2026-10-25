"""Roseiras da sacada da visão (Capítulo 01, cena 8), em malhas .obj feitas por código.

A sacada do Palácio Imperial no aniversário de Ophelia (V2 c04-c05): "no
centro da varanda havia um pequeno banco de pedra, e roseiras caíam pelo
guarda-corpo"; "as roseiras rastejantes"; Apollon "afastou um ramo que pendia
sobre o guarda-corpo". A cor das rosas não está no livro (inferência: vermelho
escuro, como o veludo de Ophelia).

  roseiras_ramos.obj  - ramos que correm por cima do guarda-corpo e caem pelos
                        dois lados, entre os balaústres.
  roseiras_folhas.obj - folhas ovais ao longo dos ramos.
  roseiras_flores.obj - rosas: um botão no meio e duas voltas de pétalas em taça.
Coordenadas da cena da varanda (gerar_visao_varanda.py): corrimão da frente em
z 4,4 (topo em y 0,98), laterais em x = +-LARGURA. Metros; y para cima.

Uso: python3 tools/arte/gerar_roseiras_visao.py   (rodar na raiz do projeto)
"""
import math
import random
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

from gerar_garota_visao import Malha, elipsoide, tubo  # noqa: E402

LARGURA = 1.9          # meia largura da sacada (igual a gerar_visao_varanda.py)
Z_CORRIMAO = 4.4
Z_FUNDO = -1.3         # a parede com a porta, atrás de quem olha
TOPO = 0.98

# (x, z, direção do corrimão) de cada moita; nada perto das mãos de Ophelia (x +-0,2)
MOITAS = [(-1.55, Z_CORRIMAO, "x"), (-1.0, Z_CORRIMAO, "x"), (-0.6, Z_CORRIMAO, "x"),
          (0.65, Z_CORRIMAO, "x"), (1.1, Z_CORRIMAO, "x"), (1.6, Z_CORRIMAO, "x"),
          (-LARGURA, 3.8, "z"), (-LARGURA, 3.1, "z"), (-LARGURA, 2.2, "z"), (-LARGURA, 1.0, "z"),
          (LARGURA, 3.7, "z"), (LARGURA, 2.8, "z"), (LARGURA, 1.6, "z"), (LARGURA, 0.4, "z")]


def folha(m: Malha, p, sorte):
    """Folha oval achatada, virada ao acaso."""
    a = sorte.uniform(0, 2 * math.pi)
    r = (0.038, 0.007, 0.024)
    pontos = []
    for i in range(5):
        fi = math.pi * i / 4
        linha = []
        for j in range(6):
            th = 2 * math.pi * j / 6
            x = r[0] * math.sin(fi) * math.sin(th)
            y = r[1] * math.cos(fi)
            z = r[2] * math.sin(fi) * math.cos(th)
            inc = sorte.uniform(-0.6, 0.6)
            y, z = y * math.cos(inc) - z * math.sin(inc), y * math.sin(inc) + z * math.cos(inc)
            linha.append((p[0] + x * math.cos(a) - z * math.sin(a), p[1] + y, p[2] + x * math.sin(a) + z * math.cos(a)))
        pontos.append(linha)
    m.grade(pontos, fechar_u=True)


def rosa(m: Malha, p, raio):
    """Botão fechado e duas voltas de pétalas abertas em taça para cima."""
    elipsoide(m, (p[0], p[1] + raio * 0.2, p[2]), (raio * 0.45, raio * 0.5, raio * 0.45), 4, 6)
    for volta, (n, abre, alto) in enumerate(((5, 0.7, 0.35), (7, 1.0, 0.1))):
        for k in range(n):
            a = 2 * math.pi * (k + 0.5 * volta) / n
            c = (p[0] + raio * abre * 0.6 * math.cos(a), p[1] + raio * alto, p[2] + raio * abre * 0.6 * math.sin(a))
            elipsoide(m, c, (raio * 0.42, raio * 0.32, raio * 0.42), 3, 5)


def caminho_do_ramo(x, z, eixo, lado, sorte):
    """Três pontos: em cima do corrimão, por cima da borda e pendendo para um lado."""
    d = sorte.uniform(-0.25, 0.25)
    if eixo == "x":
        p0 = (x + d, TOPO + 0.01, z)
        p1 = (x + d + sorte.uniform(-0.08, 0.08), TOPO + 0.03, z + lado * 0.1)
        p2 = (x + d + sorte.uniform(-0.15, 0.15), TOPO - sorte.uniform(0.25, 0.6), z + lado * 0.14)
    else:
        p0 = (x, TOPO + 0.01, z + d)
        p1 = (x + lado * 0.1, TOPO + 0.03, z + d + sorte.uniform(-0.08, 0.08))
        p2 = (x + lado * 0.14, TOPO - sorte.uniform(0.25, 0.6), z + d + sorte.uniform(-0.15, 0.15))
    return p0, p1, p2


def ponto(c, t):
    p0, p1, p2 = c
    return tuple((1 - t) ** 2 * p0[k] + 2 * (1 - t) * t * p1[k] + t * t * p2[k] for k in range(3))


def montar():
    sorte = random.Random(4)
    ramos, folhas, flores = Malha(), Malha(), Malha()
    for x, z, eixo in MOITAS:
        fora = 1 if (eixo == "x" or x > 0) else -1           # para fora da sacada
        for k in range(11):
            lado = fora if k % 3 else -fora                   # a maioria cai por fora
            c = caminho_do_ramo(x, z, eixo, lado, sorte)
            tubo(ramos, c, (0.009, 0.004), lados=6, passos=10)
            for i in range(13):
                t = (i + sorte.random()) / 13
                p = ponto(c, t)
                folha(folhas, (p[0] + sorte.uniform(-0.03, 0.03), p[1] + sorte.uniform(-0.02, 0.02),
                               p[2] + sorte.uniform(-0.03, 0.03)), sorte)
            for i in range(sorte.randint(1, 2)):
                p = ponto(c, sorte.uniform(0.0, 0.8))
                rosa(flores, (p[0] + sorte.uniform(-0.03, 0.03), p[1] + 0.02, p[2] + sorte.uniform(-0.03, 0.03)),
                     sorte.uniform(0.034, 0.05))
        # um tapete de folhas por cima do corrimão, onde os ramos nascem
        for i in range(26):
            dx = sorte.uniform(-0.35, 0.35)
            p = (x + dx, TOPO + 0.02, z + sorte.uniform(-0.06, 0.06)) if eixo == "x" else \
                (x + sorte.uniform(-0.06, 0.06), TOPO + 0.02, z + dx)
            folha(folhas, p, sorte)
    return ramos, folhas, flores


if __name__ == "__main__":
    ramos, folhas, flores = montar()
    ramos.salvar("roseiras_ramos.obj")
    folhas.salvar("roseiras_folhas.obj")
    flores.salvar("roseiras_flores.obj")
