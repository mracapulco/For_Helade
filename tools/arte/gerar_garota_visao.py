"""Malhas 3D provisórias da garota da visão da varanda (Capítulo 01, cena 8).

"A garota estava de costas para mim. Parada na varanda fria." / "Seus cabelos
longos, ondulados, escuros, descendo pelas costas e abraçando sua cintura."

A garota é Ophelia adulta (Rafael, 25/10/2026): a visão antecipa a sacada do
Palácio Imperial no aniversário de 17 anos dela (V2 c04). Como o livro a
descreve nessa noite (V2 c01 e c03 a c04, fichas-personagens): pequena, pele
escura cor de caramelo; cabelos escuros cacheados que "rodopiavam desde o
topo da sua cabeça, caindo pelos ombros e abraçando sua cintura", parte presa
atrás da cabeça e duas mechas moldando o rosto; pérolas no pescoço e nas
orelhas; vestido de veludo vermelho com os ombros nus.

No lugar do boneco de formas do Godot (cone, esferas, cilindros), malhas feitas
por código e gravadas em .obj (o Godot importa cada uma como Mesh):
  garota_vestido.obj - o vestido longo num torno de seção oval: corpete reto
                       abaixo dos ombros, cintura fina, saia pesada que abre
                       até o chão com pregas que somem para cima.
  garota_pele.obj    - ombros e colo, braços, mãos, pescoço e cabeça.
  garota_perolas.obj - o colar e os brincos de pérola.
  garota_cabelo.obj  - a coroa, o coque que prende parte do cabelo atrás, as
                       duas mechas do rosto e a cascata de cachos que desce
                       pelas costas até a cintura, com pontas desiguais.
A garota está de costas para a câmera, de frente para +z (o corrimão), com os
pés na origem e as mãos no corrimão (z 0,43). Metros; y para cima.
O corte exato do vestido e do coque é inferência do jogo.

Uso: python3 tools/arte/gerar_garota_visao.py   (rodar na raiz do projeto)
"""
import math
from pathlib import Path

PASTA = Path(__file__).resolve().parents[2] / "assets/art/capitulo_01/visao"
VOLTAS = 48            # divisões em volta do torno
CORPETE = 1.30         # altura da borda de cima do vestido

# (altura, meia largura x, meia profundidade z) do corpo com o vestido
PERFIL_VESTIDO = [
    (0.012, 0.40, 0.36), (0.03, 0.40, 0.36), (0.30, 0.335, 0.295), (0.60, 0.255, 0.215),
    (0.88, 0.17, 0.135), (1.02, 0.122, 0.092), (1.14, 0.135, 0.098), (1.26, 0.152, 0.108),
    (1.35, 0.178, 0.098), (1.40, 0.168, 0.085), (1.435, 0.10, 0.06), (1.445, 0.05, 0.045),
]


class Malha:
    def __init__(self):
        self.v: list[tuple[float, float, float]] = []
        self.f: list[tuple[int, int, int]] = []

    def grade(self, pontos: list[list[tuple[float, float, float]]], fechar_u=False) -> None:
        """Liga uma grade de pontos (linhas = v, colunas = u) em triângulos."""
        base = len(self.v)
        linhas, colunas = len(pontos), len(pontos[0])
        for linha in pontos:
            self.v.extend(linha)
        cu = colunas if fechar_u else colunas - 1
        # normais para fora: compara a de um quadrado do meio com o centro da linha
        i0 = (linhas - 1) // 2
        a, c, b = (pontos[i0][0], pontos[i0 + 1][0], pontos[i0][1 % colunas])
        u = [c[k] - a[k] for k in range(3)]
        w = [b[k] - a[k] for k in range(3)]
        n = (u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0])
        meio = [sum(q[k] for q in pontos[i0]) / colunas for k in range(3)]
        virar = sum(n[k] * (a[k] - meio[k]) for k in range(3)) < 0
        for i in range(linhas - 1):
            for j in range(cu):
                j2 = (j + 1) % colunas
                a, b = base + i * colunas + j, base + i * colunas + j2
                c, d = base + (i + 1) * colunas + j, base + (i + 1) * colunas + j2
                if virar:
                    self.f.append((a, b, c))
                    self.f.append((b, d, c))
                else:
                    self.f.append((a, c, b))
                    self.f.append((b, c, d))

    def normais(self) -> list[tuple[float, float, float]]:
        n = [[0.0, 0.0, 0.0] for _ in self.v]
        for a, b, c in self.f:
            pa, pb, pc = self.v[a], self.v[b], self.v[c]
            u = [pb[k] - pa[k] for k in range(3)]
            w = [pc[k] - pa[k] for k in range(3)]
            x = (u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0])
            for i in (a, b, c):
                for k in range(3):
                    n[i][k] += x[k]
        saida = []
        for x in n:
            m = math.sqrt(sum(c * c for c in x)) or 1.0
            saida.append((x[0] / m, x[1] / m, x[2] / m))
        return saida

    def salvar(self, nome: str) -> None:
        PASTA.mkdir(parents=True, exist_ok=True)
        ns = self.normais()
        linhas = [f"# {nome}: gerado por código (tools/arte/gerar_*_visao.py)", f"o {Path(nome).stem}"]
        linhas += [f"v {x:.4f} {y:.4f} {z:.4f}" for x, y, z in self.v]
        linhas += [f"vn {x:.4f} {y:.4f} {z:.4f}" for x, y, z in ns]
        # faces em sentido anti-horário vistas de fora (o importador do Godot vira)
        linhas += [f"f {a + 1}//{a + 1} {b + 1}//{b + 1} {c + 1}//{c + 1}" for a, b, c in self.f]
        (PASTA / nome).write_text("\n".join(linhas) + "\n")
        print(nome, len(self.v), "vértices", len(self.f), "triângulos")


def interpolar(perfil, y):
    for (y0, *a), (y1, *b) in zip(perfil, perfil[1:]):
        if y0 <= y <= y1:
            t = (y - y0) / (y1 - y0) if y1 > y0 else 0.0
            t = t * t * (3 - 2 * t)
            return [a[k] + (b[k] - a[k]) * t for k in range(len(a))]
    return list(perfil[-1][1:])


def torno(m: Malha, perfil, ys, centro=(0.0, 0.0), pregas=None) -> None:
    """Superfície de revolução de seção oval; tampa em cima e embaixo."""
    pontos = []
    for y in ys:
        rx, rz = interpolar(perfil, y)
        linha = []
        for j in range(VOLTAS):
            th = 2 * math.pi * j / VOLTAS
            k = 1.0 + (pregas(y, th) if pregas else 0.0)
            linha.append((centro[0] + rx * k * math.sin(th), y, centro[1] + rz * k * math.cos(th)))
        pontos.append(linha)
    base = len(m.v)
    m.grade(pontos, fechar_u=True)
    for primeiro, cima in ((base, False), (base + (len(ys) - 1) * VOLTAS, True)):
        # vértices próprios da tampa, para a normal dela não escurecer a borda do vestido
        linha = m.v[primeiro:primeiro + VOLTAS]
        primeiro = len(m.v)
        m.v.extend(linha)
        meio = len(m.v)
        m.v.append((sum(q[0] for q in linha) / VOLTAS, linha[0][1], sum(q[2] for q in linha) / VOLTAS))
        for j in range(VOLTAS):
            a, b = primeiro + j, primeiro + (j + 1) % VOLTAS
            m.f.append((meio, a, b) if cima else (meio, b, a))


def pregas_da_saia(y, th):
    """Pregas que abrem perto da barra e somem antes da cintura."""
    t = max(0.0, 1.0 - y / 0.95)
    return 0.045 * t * t * math.sin(9 * th + 0.6) + 0.015 * t * math.sin(17 * th)


def vestido() -> Malha:
    m = Malha()
    # um pouco por fora do corpo, e só até o corpete (ombros nus)
    perfil = [(y, rx + 0.005, rz + 0.005) for (y, rx, rz) in PERFIL_VESTIDO]
    ys = [0.012] + [i * 0.03 for i in range(1, 44)] + [CORPETE]
    ys = sorted(set(y for y in ys if y <= CORPETE))
    torno(m, perfil, ys, pregas=pregas_da_saia)
    return m


def tubo(m: Malha, caminho, raios, lados=14, passos=10) -> None:
    """Tubo ao longo de uma curva (Bézier quadrática por 3 pontos), raio que afina."""
    p0, p1, p2 = caminho
    centros = []
    for i in range(passos + 1):
        t = i / passos
        centros.append(tuple((1 - t) ** 2 * p0[k] + 2 * (1 - t) * t * p1[k] + t * t * p2[k] for k in range(3)))
    pontos = []
    for i, c in enumerate(centros):
        a = centros[max(i - 1, 0)]
        b = centros[min(i + 1, passos)]
        d = [b[k] - a[k] for k in range(3)]
        n = math.sqrt(sum(x * x for x in d))
        d = [x / n for x in d]
        ref = (1.0, 0.0, 0.0) if abs(d[0]) < 0.9 else (0.0, 0.0, 1.0)
        e1 = (d[1] * ref[2] - d[2] * ref[1], d[2] * ref[0] - d[0] * ref[2], d[0] * ref[1] - d[1] * ref[0])
        n1 = math.sqrt(sum(x * x for x in e1))
        e1 = [x / n1 for x in e1]
        e2 = (d[1] * e1[2] - d[2] * e1[1], d[2] * e1[0] - d[0] * e1[2], d[0] * e1[1] - d[1] * e1[0])
        r = raios[0] + (raios[1] - raios[0]) * i / passos
        pontos.append([tuple(c[k] + r * (math.cos(2 * math.pi * j / lados) * e1[k]
                                         + math.sin(2 * math.pi * j / lados) * e2[k]) for k in range(3))
                       for j in range(lados)])
    m.grade(pontos, fechar_u=True)


def elipsoide(m: Malha, centro, raios, aneis=12, lados=20) -> None:
    pontos = []
    for i in range(aneis + 1):
        fi = math.pi * i / aneis
        pontos.append([(centro[0] + raios[0] * math.sin(fi) * math.sin(2 * math.pi * j / lados),
                        centro[1] + raios[1] * math.cos(fi),
                        centro[2] + raios[2] * math.sin(fi) * math.cos(2 * math.pi * j / lados))
                       for j in range(lados)])
    m.grade(pontos, fechar_u=True)


# ombro, cotovelo e pulso de cada lado (as mãos descansam no corrimão)
def braco(lado):
    ombro = (lado * 0.158, 1.375, 0.0)
    cotovelo = (lado * 0.205, 1.13, 0.09)
    pulso = (lado * 0.185, 0.995, 0.39)
    return ombro, cotovelo, pulso


def pele() -> Malha:
    m = Malha()
    # ombros e colo, do corpete para cima
    ys = [CORPETE - 0.03 + i * 0.015 for i in range(11)] + [1.445]
    torno(m, PERFIL_VESTIDO, sorted(set(y for y in ys if y <= 1.445)))
    for lado in (-1, 1):
        ombro, cotovelo, pulso = braco(lado)
        meio = tuple((ombro[k] + cotovelo[k]) / 2 + (0.01 * lado if k == 0 else 0) for k in range(3))
        tubo(m, (ombro, meio, cotovelo), (0.042, 0.035))
        elipsoide(m, ombro, (0.046, 0.042, 0.044))
        meio = tuple((cotovelo[k] + pulso[k]) / 2 for k in range(3))
        tubo(m, (cotovelo, meio, pulso), (0.034, 0.025))
        elipsoide(m, (pulso[0], 0.99, 0.43), (0.03, 0.019, 0.048))
    tubo(m, ((0, 1.42, -0.005), (0, 1.50, -0.01), (0, 1.57, 0.0)), (0.041, 0.038))
    elipsoide(m, (0, 1.64, 0.008), (0.086, 0.11, 0.098))
    return m


def perolas() -> Malha:
    """Colar de pérolas rente ao pescoço e um brinco em cada orelha."""
    m = Malha()
    for i in range(26):
        th = 2 * math.pi * i / 26
        y = 1.452 - 0.012 * max(0.0, math.cos(th))      # cai um pouco na frente
        elipsoide(m, (0.052 * math.sin(th), y, -0.006 + 0.05 * math.cos(th)), (0.0085,) * 3, 6, 8)
    for lado in (-1, 1):
        elipsoide(m, (lado * 0.09, 1.595, 0.012), (0.011,) * 3, 8, 10)
    return m


def cabelo() -> Malha:
    """Coroa, coque, as duas mechas do rosto e a cascata de cachos pelas costas."""
    m = Malha()
    # coroa: um pouco maior que a cabeça, aberta embaixo na frente (o rosto)
    pontos = []
    for i in range(15):
        fi = math.pi * 0.62 * i / 14
        linha = []
        for j in range(28):
            th = 2 * math.pi * j / 28
            frente = max(0.0, math.cos(th))            # cos > 0: rosto, para +z
            fi_max = math.pi * (0.62 - 0.22 * frente)
            f = min(fi, fi_max)
            r = 1.0 + 0.04 * math.sin(7 * th + 2 * fi)
            linha.append((0.098 * r * math.sin(f) * math.sin(th), 1.655 + 0.118 * r * math.cos(f),
                          0.0 + 0.112 * r * math.sin(f) * math.cos(th)))
        pontos.append(linha)
    m.grade(pontos, fechar_u=True)
    # parte do cabelo presa atrás da cabeça: um coque baixo, enrolado
    elipsoide(m, (0, 1.665, -0.112), (0.052, 0.042, 0.036))
    for k in range(5):
        a = 2 * math.pi * k / 5
        elipsoide(m, (0.03 * math.cos(a), 1.665 + 0.024 * math.sin(a), -0.135), (0.024, 0.02, 0.018), 8, 10)
    # as duas mechas que moldam o rosto, na frente das orelhas
    for lado in (-1, 1):
        tubo(m, ((lado * 0.088, 1.70, 0.05), (lado * 0.112, 1.58, 0.075), (lado * 0.09, 1.49, 0.065)),
             (0.014, 0.004), lados=8, passos=14)
    # cascata: mechas lado a lado, cada uma uma fita grossa que cacheia
    mechas = 27
    for k in range(mechas):
        u = -1.0 + 2.0 * k / (mechas - 1)                  # -1 esquerda .. 1 direita
        ang = u * 1.25                                     # posição em volta das costas
        fim = 0.96 - 0.05 * math.cos(u * 1.6) + 0.05 * math.sin(k * 2.3) + 0.03 * math.sin(k * 5.1)
        if abs(u) > 0.8:
            fim += 0.12                                    # as de fora param mais alto
        fase = k * 1.7
        passos = 44
        pontos = []
        for i in range(passos + 1):
            t = i / passos
            y = 1.70 - (1.70 - fim) * t
            # contorno das costas nessa altura (cabeça em cima, corpo embaixo)
            hr = max(0.0, 0.118 ** 2 - (y - 1.655) ** 2) ** 0.5 if y > 1.54 else 0.0
            rx, rz = interpolar(PERFIL_VESTIDO, min(max(y, 0.0), 1.445))
            if y > 1.445:
                rx, rz = 0.045, 0.045
            mistura = max(0.0, min(1.0, (1.62 - y) / 0.25))  # da cabeça para o corpo
            larg = max(hr * 1.05, 0.11) * (1 - mistura) + (rx * 0.95 + 0.012) * mistura
            prof = max(hr * 1.08, 0.12) * (1 - mistura) + (rz + 0.03) * mistura
            # abaixo da nuca o cabelo fica solto, um pouco afastado das costas
            prof += 0.02 * mistura * math.sin(t * math.pi)
            onda = 0.012 * math.sin(t * 6.0 + fase) * min(1.0, t * 3)
            a = ang + onda * 2.2
            cx = larg * math.sin(a)
            cz = -prof * math.cos(a)
            # normal para fora e a tangente lateral da fita
            nx, nz = math.sin(a), -math.cos(a)
            tx, tz = math.cos(a), math.sin(a)
            meia = 0.026 * (1.0 - 0.85 * t ** 2.5) + 0.002      # afina até a ponta
            esp = 0.012 * (1.0 - 0.8 * t)
            # cachos: a mecha gira em espiral, mais aberta para as pontas
            giro = 2 * math.pi * 4.5 * t + fase
            raio = (0.006 + 0.016 * t) * min(1.0, t * 4)
            cx += nx * raio * math.sin(giro) + tx * raio * math.cos(giro)
            cz += nz * raio * math.sin(giro) + tz * raio * math.cos(giro)
            secao = []
            for (s, e) in ((-1, 0), (0, 1), (1, 0), (0, -1)):
                secao.append((cx + tx * meia * s + nx * esp * e, y, cz + tz * meia * s + nz * esp * e))
            pontos.append(secao)
        m.grade(pontos, fechar_u=True)
    return m


if __name__ == "__main__":
    vestido().salvar("garota_vestido.obj")
    perolas().salvar("garota_perolas.obj")
    pele().salvar("garota_pele.obj")
    cabelo().salvar("garota_cabelo.obj")
