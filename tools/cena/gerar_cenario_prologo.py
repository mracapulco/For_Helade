"""Monta os cenários 3D do prólogo (castelo Olympia, noite) como cenas do Godot.

Gera em scenes/prologo/cenario/:
  quarto_nicholas.tscn, corredor.tscn, aposentos.tscn (com a varanda) e exterior.tscn.

Tudo é feito com formas do próprio Godot (caixas, cilindros, esferas) e os
materiais de assets/art/prologo/materiais, até a arte definitiva chegar.
Coordenadas em metros: y para cima, o mar fica ao sul (+z).

Planta (vista de cima):
    z=0    ┌────────────── corredor (portas trancadas) ──────────────┐
    z=3.6  └──[porta]─────────────────────────────[porta dupla]──────┘
             quarto de Nicholas                   aposentos da duquesa
             x -12,5 a -5,5                       x 4 a 14
    z=12.6 ────────── fachada sobre o penhasco ────[arco]────────────
                                                   varanda (até z 16,6)

Uso: python3 tools/cena/gerar_cenario_prologo.py
"""
import math
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
SAIDA = RAIZ / "scenes/prologo/cenario"
MAT = "res://assets/art/prologo/materiais/"
CHAMA_SCRIPT = "res://scripts/prologo/chama_tremula.gd"


# ------------------------------------------------------------ formatação

def num(v: float) -> str:
    v = round(float(v), 4)
    if v == int(v):
        return str(int(v)) if abs(v) < 1e9 else str(v)
    return repr(v)


def v3(x, y, z) -> str:
    return f"Vector3({num(x)}, {num(y)}, {num(z)})"


def v2(x, y) -> str:
    return f"Vector2({num(x)}, {num(y)})"


def cor(r, g, b, a=1.0) -> str:
    return f"Color({num(r)}, {num(g)}, {num(b)}, {num(a)})"


def transform(pos=(0, 0, 0), rot=(0.0, 0.0, 0.0), escala=(1, 1, 1)) -> str:
    """rot em graus (x, y, z), na ordem do Godot (YXZ)."""
    rx, ry, rz = (math.radians(a) for a in rot)
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    # R = Ry * Rx * Rz
    m = [
        [cy * cz + sy * sx * sz, -cy * sz + sy * sx * cz, sy * cx],
        [cx * sz, cx * cz, -sx],
        [-sy * cz + cy * sx * sz, sy * sz + cy * sx * cz, cy * cx],
    ]
    for i in range(3):
        for j in range(3):
            m[i][j] *= escala[j]
    vals = [m[0][0], m[0][1], m[0][2], m[1][0], m[1][1], m[1][2], m[2][0], m[2][1], m[2][2], *pos]
    return "Transform3D(" + ", ".join(num(v) for v in vals) + ")"


# ------------------------------------------------------------ cena

class Cena:
    def __init__(self, nome_raiz: str):
        self.ext: dict[str, tuple[str, str]] = {}
        self.subs: list[tuple[str, str, dict]] = []
        self._chaves: dict[tuple, str] = {}
        self.nos: list[tuple[str, str, str | None, dict]] = []
        self._nomes: dict[tuple[str, str], int] = {}
        self.raiz = nome_raiz
        self.nos.append((nome_raiz, "Node3D", None, {}))

    def e(self, tipo: str, caminho: str) -> str:
        if caminho not in self.ext:
            ident = f"{len(self.ext) + 1}_{Path(caminho).stem}"
            self.ext[caminho] = (tipo, ident)
        return f'ExtResource("{self.ext[caminho][1]}")'

    def mat(self, nome: str) -> str:
        return self.e("Material", MAT + nome + ".tres")

    def s(self, tipo: str, **props) -> str:
        chave = (tipo, tuple(sorted((k, str(v)) for k, v in props.items())))
        if chave not in self._chaves:
            ident = f"{tipo}_{len(self.subs) + 1}"
            self.subs.append((tipo, ident, props))
            self._chaves[chave] = ident
        return f'SubResource("{self._chaves[chave]}")'

    def no(self, nome: str, tipo: str, pai: str = ".", **props) -> str:
        """Acrescenta um nó e devolve o caminho dele (para ser pai de outros)."""
        n = self._nomes.get((pai, nome), 0)
        self._nomes[(pai, nome)] = n + 1
        if n:
            nome = f"{nome}{n + 1}"
        self.nos.append((nome, tipo, pai, props))
        return nome if pai == "." else f"{pai}/{nome}"

    def salvar(self, caminho: Path) -> None:
        linhas = ["[gd_scene format=3]", ""]
        for caminho_res, (tipo, ident) in self.ext.items():
            linhas.append(f'[ext_resource type="{tipo}" path="{caminho_res}" id="{ident}"]')
        linhas.append("")
        for tipo, ident, props in self.subs:
            linhas.append(f'[sub_resource type="{tipo}" id="{ident}"]')
            for k, v in props.items():
                linhas.append(f"{k} = {v}")
            linhas.append("")
        for nome, tipo, pai, props in self.nos:
            cab = f'[node name="{nome}" type="{tipo}"'
            if pai is not None:
                cab += f' parent="{pai}"'
            linhas.append(cab + "]")
            for k, v in props.items():
                linhas.append(f"{k} = {v}")
            linhas.append("")
        caminho.parent.mkdir(parents=True, exist_ok=True)
        caminho.write_text("\n".join(linhas))


# ------------------------------------------------------------ peças básicas

def bloco(c: Cena, nome, pai, minimo, maximo, mat, colisao=True, rot=(0, 0, 0)):
    """Caixa dada pelos cantos (no espaço do pai)."""
    centro = [(a + b) / 2 for a, b in zip(minimo, maximo)]
    tam = [abs(b - a) for a, b in zip(minimo, maximo)]
    return caixa(c, nome, pai, centro, tam, mat, colisao, rot)


def caixa(c: Cena, nome, pai, centro, tam, mat, colisao=False, rot=(0, 0, 0)):
    if colisao:
        return c.no(nome, "CSGBox3D", pai, transform=transform(centro, rot), use_collision="true",
                    size=v3(*tam), material=c.mat(mat))
    return c.no(nome, "MeshInstance3D", pai, transform=transform(centro, rot),
                mesh=c.s("BoxMesh", size=v3(*tam)), material_override=c.mat(mat))


def cilindro(c: Cena, nome, pai, centro, raio, altura, mat, raio_topo=None, rot=(0, 0, 0), lados=16):
    return c.no(nome, "MeshInstance3D", pai, transform=transform(centro, rot),
                mesh=c.s("CylinderMesh", top_radius=num(raio if raio_topo is None else raio_topo),
                         bottom_radius=num(raio), height=num(altura), radial_segments=lados, rings=1),
                material_override=c.mat(mat))


def esfera(c: Cena, nome, pai, centro, raio, mat, escala=(1, 1, 1)):
    return c.no(nome, "MeshInstance3D", pai, transform=transform(centro, escala=escala),
                mesh=c.s("SphereMesh", radius=num(raio), height=num(raio * 2), radial_segments=16, rings=8),
                material_override=c.mat(mat))


def plano(c: Cena, nome, pai, centro, tam, mat, rot=(0, 0, 0)):
    """Plano com UV de 0 a 1 (tapetes, tapeçarias). Virado para +y antes de girar."""
    return c.no(nome, "MeshInstance3D", pai, transform=transform(centro, rot),
                mesh=c.s("PlaneMesh", size=v2(*tam)), material_override=c.mat(mat))


def grupo(c: Cena, nome, pai, pos, giro=0.0):
    return c.no(nome, "Node3D", pai, transform=transform(pos, (0, giro, 0)))


def chama(c: Cena, pai, pos, largura=0.05, altura=0.12, intensidade=None):
    props = dict(transform=transform(pos), cast_shadow="0",
                 mesh=c.s("QuadMesh", size=v2(largura, altura), center_offset=v3(0, altura / 2, 0)),
                 material_override=c.mat("chama"))
    return c.no("Chama", "MeshInstance3D", pai, **props)


def luz(c: Cena, nome, pai, pos, energia, alcance, cor_luz=(1, 0.68, 0.38), sombra=False, tremor=None):
    props = dict(transform=transform(pos), light_color=cor(*cor_luz), light_energy=num(energia),
                 omni_range=num(alcance), script=c.e("Script", CHAMA_SCRIPT))
    if tremor is not None:
        props["tremor"] = num(tremor)
    if sombra:
        props["shadow_enabled"] = "true"
    return c.no(nome, "OmniLight3D", pai, **props)


# ------------------------------------------------------------ paredes

def parede(c: Cena, nome, pai, minimo, maximo, mat, aberturas=()):
    """Parede reta com aberturas (portas e janelas) em arco.

    Cada abertura: (centro_ao_longo, base_y, largura, altura). O eixo "ao longo"
    é x se a parede é mais comprida em x, senão z.
    """
    no = c.no(nome, "CSGCombiner3D", pai, use_collision="true")
    # Dentro de um CSGCombiner3D as peças precisam ser CSG, não MeshInstance.
    c.no("Pedra", "CSGBox3D", no, transform=transform([(a + b) / 2 for a, b in zip(minimo, maximo)]),
         size=v3(*[abs(b - a) for a, b in zip(minimo, maximo)]), material=c.mat(mat))
    ao_longo_x = (maximo[0] - minimo[0]) >= (maximo[2] - minimo[2])
    espessura = (maximo[2] - minimo[2]) if ao_longo_x else (maximo[0] - minimo[0])
    meio = (minimo[2] + maximo[2]) / 2 if ao_longo_x else (minimo[0] + maximo[0]) / 2
    for centro, base, largura, altura in aberturas:
        reta = altura - largura / 2
        if ao_longo_x:
            pos = (centro, base + reta / 2, meio)
            tam = (largura, reta, espessura + 0.2)
            pos_arco = (centro, base + reta, meio)
            rot_arco = (90, 0, 0)
        else:
            pos = (meio, base + reta / 2, centro)
            tam = (espessura + 0.2, reta, largura)
            pos_arco = (meio, base + reta, centro)
            rot_arco = (0, 0, 90)
        c.no("Vao", "CSGBox3D", no, transform=transform(pos), operation="2", size=v3(*tam), material=c.mat(mat))
        c.no("Arco", "CSGCylinder3D", no, transform=transform(pos_arco, rot_arco), operation="2",
             radius=num(largura / 2), height=num(espessura + 0.2), sides="24", material=c.mat(mat))
    return no


def vigas(c: Cena, pai, ao_longo_x, posicoes, y, comprimento_de, comprimento_ate):
    """Vigas de madeira no teto."""
    for p in posicoes:
        if ao_longo_x:  # vigas atravessando em z
            caixa(c, "Viga", pai, (p, y, (comprimento_de + comprimento_ate) / 2), (0.25, 0.3, comprimento_ate - comprimento_de), "madeira_movel")
        else:
            caixa(c, "Viga", pai, ((comprimento_de + comprimento_ate) / 2, y, p), (comprimento_ate - comprimento_de, 0.28, 0.24), "madeira_movel")


# ------------------------------------------------------------ objetos

def porta_fechada(c: Cena, pai, pos, giro, largura=1.2, altura=2.4, dupla=False):
    """Porta trancada encostada na parede; a frente olha para +z local."""
    g = grupo(c, "PortaTrancada", pai, pos, giro)
    caixa(c, "Batente", g, (-largura / 2 - 0.08, altura / 2, 0.04), (0.16, altura, 0.12), "madeira_movel")
    caixa(c, "Batente", g, (largura / 2 + 0.08, altura / 2, 0.04), (0.16, altura, 0.12), "madeira_movel")
    caixa(c, "Verga", g, (0, altura + 0.1, 0.05), (largura + 0.5, 0.2, 0.14), "parede_pedra")
    caixa(c, "Folha", g, (0, altura / 2, 0.035), (largura, altura, 0.07), "madeira_movel")
    for y in (0.35, altura / 2, altura - 0.35):
        caixa(c, "Ferragem", g, (0, y, 0.075), (largura - 0.06, 0.06, 0.015), "ferro")
    if dupla:
        caixa(c, "Junta", g, (0, altura / 2, 0.076), (0.02, altura, 0.01), "carvao")
        for x in (-0.12, 0.12):
            c.no("Argola", "MeshInstance3D", g, transform=transform((x, altura * 0.45, 0.1), (90, 0, 0)),
                 mesh=c.s("TorusMesh", inner_radius="0.05", outer_radius="0.07"), material_override=c.mat("ferro"))
    else:
        c.no("Argola", "MeshInstance3D", g, transform=transform((largura * 0.3, altura * 0.45, 0.1), (90, 0, 0)),
             mesh=c.s("TorusMesh", inner_radius="0.05", outer_radius="0.07"), material_override=c.mat("ferro"))
        caixa(c, "Fechadura", g, (largura * 0.3, altura * 0.45 - 0.15, 0.08), (0.08, 0.12, 0.02), "ferro")
    return g


def folha_aberta(c: Cena, pai, dobradica, giro, largura, altura):
    g = grupo(c, "FolhaAberta", pai, dobradica, giro)
    caixa(c, "Folha", g, (largura / 2, altura / 2, 0), (largura, altura, 0.07), "madeira_movel")
    for y in (0.35, altura / 2, altura - 0.35):
        caixa(c, "Ferragem", g, (largura / 2, y, 0.04), (largura - 0.06, 0.06, 0.015), "ferro")
    return g


def tocha(c: Cena, pai, pos, giro, nome_luz, sombra=False):
    """Suporte de ferro na parede com tocha acesa; a parede fica no -z local."""
    g = grupo(c, "Tocha", pai, pos, giro)
    caixa(c, "Placa", g, (0, 0, 0.02), (0.14, 0.3, 0.04), "ferro")
    caixa(c, "Braco", g, (0, -0.08, 0.14), (0.04, 0.04, 0.24), "ferro")
    cilindro(c, "Cesto", g, (0, 0.02, 0.26), 0.07, 0.12, "ferro", raio_topo=0.1)
    cilindro(c, "Cabo", g, (0, -0.1, 0.26), 0.03, 0.3, "madeira_movel")
    chama(c, g, (0, 0.06, 0.26), 0.2, 0.38)
    luz(c, nome_luz, g, (0, 0.3, 0.4), 1.6, 6.0, (1, 0.6, 0.3), sombra, tremor=0.4)
    return g


def vela(c: Cena, pai, pos, altura=0.18, castical=True, acesa=True):
    """Vela num castiçal. Acesa, tem chama; quem chama precisa pôr a luz ao lado."""
    g = grupo(c, "Vela", pai, pos)
    if castical:
        cilindro(c, "Pires", g, (0, 0.01, 0), 0.07, 0.02, "bronze")
        cilindro(c, "Haste", g, (0, 0.05, 0), 0.015, 0.08, "bronze")
        cilindro(c, "Copo", g, (0, 0.095, 0), 0.03, 0.02, "bronze")
        base = 0.105
    else:
        base = 0.0
    cilindro(c, "Cera", g, (0, base + altura / 2, 0), 0.022, altura, "cera")
    if acesa:
        chama(c, g, (0, base + altura, 0), 0.05, 0.11)
    return g, base + altura


def candelabro(c: Cena, pai, pos, nome_luz, sombra=False, energia=1.3):
    g = grupo(c, "Candelabro", pai, pos)
    cilindro(c, "Pe", g, (0, 0.04, 0), 0.2, 0.08, "bronze", raio_topo=0.12)
    cilindro(c, "Haste", g, (0, 0.8, 0), 0.025, 1.5, "bronze")
    caixa(c, "Braco", g, (0, 1.52, 0), (0.5, 0.03, 0.03), "bronze")
    for x in (-0.24, 0.0, 0.24):
        vela(c, g, (x, 1.52 if x else 1.56, 0), altura=0.2)
    # A luz fica direto no cômodo, para a SequenciaPrologo achar "VelaCama".
    return luz(c, nome_luz, pai, (pos[0], 1.9, pos[2]), energia, 7.0, sombra=sombra)


def mesa(c: Cena, pai, pos, largura, profundidade, altura, giro=0.0, colisao=True, mat="madeira_movel"):
    g = grupo(c, "Mesa", pai, pos, giro)
    caixa(c, "Tampo", g, (0, altura - 0.025, 0), (largura, 0.05, profundidade), mat, colisao)
    for sx in (-1, 1):
        for sz in (-1, 1):
            caixa(c, "Perna", g, (sx * (largura / 2 - 0.06), (altura - 0.05) / 2, sz * (profundidade / 2 - 0.06)), (0.06, altura - 0.05, 0.06), mat)
    return g


def cadeira(c: Cena, pai, pos, giro=0.0):
    """Encosto no +z local (a pessoa senta olhando para -z)."""
    g = grupo(c, "Cadeira", pai, pos, giro)
    caixa(c, "Assento", g, (0, 0.45, 0), (0.45, 0.05, 0.45), "madeira_movel", True)
    for sx in (-1, 1):
        for sz in (-1, 1):
            caixa(c, "Perna", g, (sx * 0.19, 0.21, sz * 0.19), (0.04, 0.42, 0.04), "madeira_movel")
    caixa(c, "Encosto", g, (0, 0.78, 0.2), (0.45, 0.6, 0.04), "madeira_movel")
    return g


def bau(c: Cena, pai, pos, giro=0.0, largura=0.9, profundidade=0.5, altura=0.5):
    """Frente no +z local."""
    g = grupo(c, "Bau", pai, pos, giro)
    caixa(c, "Corpo", g, (0, altura / 2 - 0.04, 0), (largura, altura - 0.08, profundidade), "madeira_movel", True)
    caixa(c, "Tampa", g, (0, altura - 0.04, 0), (largura + 0.02, 0.08, profundidade + 0.02), "madeira_movel")
    for x in (-largura * 0.35, largura * 0.35):
        caixa(c, "Cinta", g, (x, altura / 2, 0), (0.05, altura + 0.01, profundidade + 0.02), "ferro")
    caixa(c, "Fecho", g, (0, altura - 0.12, profundidade / 2 + 0.012), (0.08, 0.12, 0.02), "ferro")
    return g


def panos(c: Cena, pai, pos, quantos=3, giro=0.0):
    g = grupo(c, "Panos", pai, pos, giro)
    for i in range(quantos):
        caixa(c, "Pano", g, (0.01 * i, 0.025 + 0.045 * i, -0.008 * i), (0.4, 0.04, 0.32), "lencol")
    return g


def bacia(c: Cena, pai, pos, raio=0.24):
    g = grupo(c, "Bacia", pai, pos)
    cilindro(c, "Louca", g, (0, 0.06, 0), raio * 0.55, 0.12, "louca", raio_topo=raio)
    cilindro(c, "Agua", g, (0, 0.09, 0), raio * 0.85, 0.01, "agua")
    return g


def jarro(c: Cena, pai, pos):
    g = grupo(c, "Jarro", pai, pos)
    esfera(c, "Bojo", g, (0, 0.11, 0), 0.1, "louca", escala=(1, 1.15, 1))
    cilindro(c, "Gargalo", g, (0, 0.27, 0), 0.04, 0.12, "louca", raio_topo=0.055)
    return g


def anfora(c: Cena, pai, pos, escala=1.0):
    g = grupo(c, "Anfora", pai, pos)
    esfera(c, "Bojo", g, (0, 0.38 * escala, 0), 0.22 * escala, "terracota", escala=(1, 1.45, 1))
    cilindro(c, "Pe", g, (0, 0.05 * escala, 0), 0.1 * escala, 0.1 * escala, "terracota")
    cilindro(c, "Gargalo", g, (0, 0.78 * escala, 0), 0.07 * escala, 0.18 * escala, "terracota", raio_topo=0.09 * escala)
    return g


def vaso_planta(c: Cena, pai, pos):
    g = grupo(c, "Planta", pai, pos)
    cilindro(c, "Vaso", g, (0, 0.2, 0), 0.18, 0.4, "terracota", raio_topo=0.25)
    for i, (x, y, z, r) in enumerate([(0, 0.62, 0, 0.28), (0.15, 0.75, 0.05, 0.2), (-0.12, 0.8, -0.08, 0.18), (0.02, 0.95, 0.1, 0.15)]):
        esfera(c, "Folhas", g, (x, y, z), r, "folhagem")
    return g


def tapecaria(c: Cena, pai, pos, giro, largura, altura):
    """Pano pendurado na parede (a parede no -z local)."""
    g = grupo(c, "Tapecaria", pai, pos, giro)
    plano(c, "Pano", g, (0, 0, 0.02), (largura, altura), "tapete", rot=(90, 0, 0))
    cilindro(c, "Varao", g, (0, altura / 2 + 0.04, 0.04), 0.02, largura + 0.2, "bronze", rot=(0, 0, 90))
    return g


def quadro(c: Cena, pai, pos, giro, largura, imagem, proporcao=0.75):
    """Quadro na parede (a parede no -z local): recorte em pixel art do mapa de
    Hélade (tools/arte/gerar_quadros_prologo.py), com moldura dourada."""
    altura = largura * proporcao
    g = grupo(c, "Quadro", pai, pos, giro)
    tela = c.s("StandardMaterial3D", albedo_texture=c.e("Texture2D", f"res://assets/art/prologo/quadros/{imagem}.png"),
               roughness="0.85", texture_filter="0")
    c.no("Tela", "MeshInstance3D", g, transform=transform((0, 0, 0.035), (90, 0, 0)),
         mesh=c.s("PlaneMesh", size=v2(largura, altura)), material_override=tela)
    caixa(c, "Fundo", g, (0, 0, 0.015), (largura + 0.04, altura + 0.04, 0.03), "madeira_movel")
    m = 0.07
    for nome, centro, tam in (("Moldura", (0, (altura + m) / 2, 0.03), (largura + 2 * m, m, 0.06)),
                              ("Moldura", (0, -(altura + m) / 2, 0.03), (largura + 2 * m, m, 0.06)),
                              ("Moldura", ((largura + m) / 2, 0, 0.03), (m, altura, 0.06)),
                              ("Moldura", (-(largura + m) / 2, 0, 0.03), (m, altura, 0.06))):
        caixa(c, nome, g, centro, tam, "ouro")
    return g


def espada_na_parede(c: Cena, pai, pos, giro):
    """Espada deitada sobre uma placa de madeira (a parede no -z local). Sem brasão."""
    g = grupo(c, "EspadaNaParede", pai, pos, giro)
    caixa(c, "Placa", g, (0, 0, 0.02), (1.4, 0.42, 0.04), "madeira_movel")
    for x in (-0.38, 0.3):
        cilindro(c, "Suporte", g, (x, -0.06, 0.07), 0.018, 0.08, "bronze", rot=(90, 0, 0))
    caixa(c, "Lamina", g, (0.12, 0, 0.1), (0.86, 0.05, 0.012), "ferro")
    c.no("Ponta", "MeshInstance3D", g, transform=transform((0.585, 0, 0.1), (0, 0, -90)),
         mesh=c.s("PrismMesh", size=v3(0.05, 0.08, 0.012)), material_override=c.mat("ferro"))
    caixa(c, "Guarda", g, (-0.33, 0, 0.1), (0.04, 0.22, 0.04), "bronze")
    cilindro(c, "Punho", g, (-0.44, 0, 0.1), 0.02, 0.18, "madeira_movel", rot=(0, 0, 90))
    esfera(c, "Pomo", g, (-0.55, 0, 0.1), 0.035, "bronze")
    return g


def armario(c: Cena, pai, pos, giro, largura=1.4, altura=2.2, profundidade=0.6):
    """Armário de duas portas; a frente olha para +z local."""
    g = grupo(c, "Armario", pai, pos, giro)
    caixa(c, "Corpo", g, (0, altura / 2, 0), (largura, altura, profundidade), "madeira_movel", True)
    caixa(c, "Topo", g, (0, altura + 0.04, 0.02), (largura + 0.1, 0.08, profundidade + 0.06), "madeira_movel")
    caixa(c, "Fresta", g, (0, altura / 2, profundidade / 2 + 0.001), (0.02, altura - 0.2, 0.01), "carvao")
    for x in (-0.08, 0.08):
        cilindro(c, "Puxador", g, (x, altura / 2 + 0.05, profundidade / 2 + 0.02), 0.015, 0.04, "bronze", rot=(90, 0, 0))
    return g


def pilastra(c: Cena, pai, pos, giro, altura):
    g = grupo(c, "Pilastra", pai, pos, giro)
    caixa(c, "Fuste", g, (0, altura / 2, 0.08), (0.45, altura, 0.16), "parede_pedra")
    caixa(c, "Base", g, (0, 0.12, 0.11), (0.55, 0.24, 0.22), "parede_pedra")
    caixa(c, "Capitel", g, (0, altura - 0.15, 0.11), (0.55, 0.3, 0.22), "parede_pedra")
    return g


# ------------------------------------------------------------ cômodos

def quarto_nicholas() -> Cena:
    c = Cena("QuartoNicholas")
    x0, x1, z0, z1, h = -12.5, -5.5, 3.9, 12.6, 4.0
    bloco(c, "Chao", ".", (x0, -0.2, z0), (x1, 0, z1), "assoalho")
    bloco(c, "Teto", ".", (x0, h, z0), (x1, h + 0.2, z1), "teto_reboco")
    vigas(c, ".", False, (5.2, 7.4, 9.6, 11.8), h - 0.14, x0, x1)
    parede(c, "ParedeOeste", ".", (x0 - 0.3, 0, z0 - 0.3), (x0, 4.8, z1 + 0.3), "parede_pedra")
    parede(c, "ParedeLeste", ".", (x1, 0, z0 - 0.3), (x1 + 0.3, 4.8, z1 + 0.3), "parede_pedra")
    # Janela para o mar, na fachada.
    parede(c, "ParedeSul", ".", (x0 - 0.3, 0, z1), (x1 + 0.3, 4.8, z1 + 0.3), "parede_pedra",
           aberturas=[(-9.0, 0.9, 1.2, 1.9)])
    caixa(c, "Peitoril", ".", (-9.0, 0.88, z1 + 0.05), (1.4, 0.08, 0.5), "parede_pedra")
    for lado, x in ((-1, -9.6), (1, -8.4)):
        g = grupo(c, "Postigo", ".", (x, 1.85, z1 - 0.02), 0)
        caixa(c, "Folha", g, (lado * 0.27, 0, -0.27), (0.04, 1.3, 0.55), "madeira_movel", rot=(0, 0, 0))

    # Cama baixa (dá para subir pulando); o colchão fica a 0,36 m do chão.
    bloco(c, "Cama", ".", (-12.4, 0, 8.0), (-10.4, 0.3, 9.2), "madeira_movel")
    bloco(c, "Coberta", ".", (-11.95, 0.3, 8.02), (-10.45, 0.36, 9.18), "coberta_azul")
    bloco(c, "Lencol", ".", (-12.38, 0.3, 8.02), (-11.95, 0.34, 9.18), "lencol", colisao=False)
    caixa(c, "Travesseiro", ".", (-12.12, 0.4, 8.6), (0.38, 0.12, 0.8), "lencol")
    caixa(c, "Cabeceira", ".", (-12.45, 0.6, 8.6), (0.08, 1.2, 1.3), "madeira_movel")
    caixa(c, "Remate", ".", (-12.45, 1.24, 8.6), (0.14, 0.08, 1.4), "madeira_movel")
    for z in (8.0, 9.2):
        cilindro(c, "Coluna", ".", (-12.42, 0.7, z), 0.05, 1.4, "madeira_movel")
        esfera(c, "Pinha", ".", (-12.42, 1.44, z), 0.06, "madeira_movel")

    criado = mesa(c, ".", (-12.1, 0, 7.35), 0.5, 0.45, 0.6, colisao=True)
    _, topo = vela(c, criado, (0.05, 0.6, 0), altura=0.14)
    luz(c, "Vela", ".", (-12.05, 0.6 + topo + 0.15, 7.35), 1.2, 5.5, sombra=True)
    jarro(c, criado, (-0.12, 0.6, 0.08))

    plano(c, "Tapete", ".", (-8.8, 0.006, 8.6), (3.0, 2.2), "tapete")
    bau(c, ".", (-12.15, 0, 10.7), giro=90, largura=0.9, profundidade=0.5)
    # Armário encostado na parede leste.
    armario(c, ".", (-5.82, 0, 6.2), -90)
    # Baú de brinquedos e, acima dele, Olympia vista no mapa: a casa de Nicholas.
    bau(c, ".", (-5.85, 0, 8.9), giro=-90, largura=0.8, profundidade=0.45, altura=0.45)
    quadro(c, ".", (-5.5, 1.75, 8.9), -90, 1.0, "olympia")
    m = mesa(c, ".", (-7.0, 0, 11.6), 1.0, 0.6, 0.72)
    cadeira(c, ".", (-7.0, 0, 10.95), giro=180)
    _, topo = vela(c, m, (0.3, 0.72, 0.1), altura=0.1)
    luz(c, "VelaMesa", ".", (-6.7, 0.72 + topo + 0.15, 11.7), 0.7, 3.5)
    caixa(c, "Livro", m, (-0.2, 0.74, 0), (0.22, 0.04, 0.3), "veludo_vermelho", rot=(0, 12, 0))
    return c


def corredor() -> Cena:
    c = Cena("Corredor")
    x0, x1, z0, z1, h = -15.0, 15.0, 0.0, 3.6, 4.5
    bloco(c, "Chao", ".", (x0, -0.2, z0), (x1, 0, z1), "piso_pedra")
    bloco(c, "Teto", ".", (x0, h, z0), (x1, h + 0.2, z1), "teto_reboco")
    vigas(c, ".", True, [x for x in range(-14, 15, 2)], h - 0.15, z0, z1)
    parede(c, "ParedeNorte", ".", (x0 - 0.3, 0, z0 - 0.3), (x1 + 0.3, h, z0), "parede_pedra")
    parede(c, "ParedeSul", ".", (x0 - 0.3, 0, z1), (x1 + 0.3, 4.8, z1 + 0.3), "parede_pedra",
           aberturas=[(-9.0, 0.0, 1.3, 2.7), (9.0, 0.0, 2.0, 3.1)])
    parede(c, "ParedeOeste", ".", (x0 - 0.3, 0, z0), (x0, h, z1), "parede_pedra")
    parede(c, "ParedeLeste", ".", (x1, 0, z0), (x1 + 0.3, h, z1), "parede_pedra")

    for x in (-13.5, -6.5, 0.0, 6.5, 13.5):
        pilastra(c, ".", (x, 0, z0), 0, h)
    for x in (-13.5, -5.5, 0.0, 4.5, 13.5):
        pilastra(c, ".", (x, 0, z1), 180, h)
    # Portas trancadas: o resto do castelo existe, mas não é para hoje.
    for x in (-10.0, -3.25, 3.25, 10.0):
        porta_fechada(c, ".", (x, 0, z0), 0)
    porta_fechada(c, ".", (-2.6, 0, z1), 180)
    porta_fechada(c, ".", (x0, 0, 1.8), 90, largura=2.0, altura=3.0, dupla=True)
    porta_fechada(c, ".", (x1, 0, 1.8), -90, largura=1.3, altura=2.5)
    # Batentes das portas abertas.
    for x, larg, alt in ((-9.0, 1.3, 2.7), (9.0, 2.0, 3.1)):
        for lado in (-1, 1):
            caixa(c, "Batente", ".", (x + lado * (larg / 2 - 0.06), (alt - larg / 2) / 2, z1 + 0.15), (0.12, alt - larg / 2, 0.36), "madeira_movel")

    tocha(c, ".", (-13.5, 2.3, z0 + 0.16), 0, "Tocha1")
    tocha(c, ".", (-6.5, 2.3, z0 + 0.16), 0, "Tocha2", sombra=True)
    tocha(c, ".", (6.5, 2.3, z0 + 0.16), 0, "Tocha3", sombra=True)
    tocha(c, ".", (13.5, 2.3, z0 + 0.16), 0, "Tocha4")
    luz(c, "LuzPorta", ".", (9.0, 1.8, 3.2), 0.8, 3.0, (1, 0.75, 0.45))

    plano(c, "Passadeira", ".", (0, 0.006, 1.8), (28.0, 1.6), "passadeira")
    tapecaria(c, ".", (-8.25, 2.5, z0), 0, 1.5, 2.2)
    tapecaria(c, ".", (8.25, 2.5, z0), 0, 1.5, 2.2)
    quadro(c, ".", (-1.6, 2.15, z0), 0, 1.2, "atenas")
    quadro(c, ".", (1.6, 2.15, z0), 0, 1.2, "norte")
    espada_na_parede(c, ".", (-4.3, 1.9, z1), 180)
    banco = grupo(c, "Banco", ".", (1.6, 0, 0.35), 0)
    caixa(c, "Assento", banco, (0, 0.42, 0), (1.3, 0.06, 0.4), "madeira_movel", True)
    for x in (-0.55, 0.55):
        caixa(c, "Pe", banco, (x, 0.2, 0), (0.08, 0.4, 0.34), "madeira_movel")
    anfora(c, ".", (-1.0, 0, 3.25))
    anfora(c, ".", (1.0, 0, 3.25))
    vaso_planta(c, ".", (-14.4, 0, 0.45))
    vaso_planta(c, ".", (14.4, 0, 0.45))
    return c


def aposentos() -> Cena:
    c = Cena("Aposentos")
    x0, x1, z0, z1, h = 4.0, 14.0, 3.9, 12.6, 4.8
    bloco(c, "Chao", ".", (x0, -0.2, z0), (x1, 0, z1), "assoalho")
    bloco(c, "Teto", ".", (x0, h, z0), (x1, h + 0.2, z1), "teto_reboco")
    vigas(c, ".", False, (5.2, 7.4, 9.6, 11.8), h - 0.14, x0, x1)
    parede(c, "ParedeOeste", ".", (x0 - 0.3, 0, z0 - 0.3), (x0, h, z1 + 0.3), "parede_pedra")
    parede(c, "ParedeLeste", ".", (x1, 0, z0 - 0.3), (x1 + 0.3, h, z1 + 0.3), "parede_pedra")
    parede(c, "ParedeSul", ".", (x0 - 0.3, 0, z1), (x1 + 0.3, h, z1 + 0.3), "parede_pedra",
           aberturas=[(9.0, 0.0, 3.0, 3.5)])
    bloco(c, "Soleira", ".", (7.5, -0.2, z1 - 0.05), (10.5, 0, z1 + 0.35), "marmore_varanda")
    # Porta dupla aberta para dentro, vinda do corredor.
    folha_aberta(c, ".", (8.0, 0, z0 + 0.05), -95, 1.0, 3.0)
    folha_aberta(c, ".", (10.0, 0, z0 + 0.05), -85, 1.0, 3.0)

    # Cama da duquesa, com dossel azul-escuro (do livro).
    bloco(c, "CamaDuquesa", ".", (11.2, 0, 6.9), (14.0, 0.6, 9.3), "madeira_movel")
    bloco(c, "Colchao", ".", (11.25, 0.6, 6.95), (13.95, 0.72, 9.25), "lencol")
    for z in (7.55, 8.65):
        caixa(c, "Travesseiro", ".", (13.55, 0.82, z), (0.5, 0.18, 0.85), "lencol")
    caixa(c, "Manta", ".", (11.6, 0.75, 8.1), (0.6, 0.06, 2.34), "coberta_azul")
    caixa(c, "Cabeceira", ".", (13.97, 1.1, 8.1), (0.1, 2.2, 2.5), "madeira_movel")
    for x in (11.27, 13.93):
        for z in (6.97, 9.23):
            cilindro(c, "Coluna", ".", (x, 1.67, z), 0.07, 3.34, "madeira_movel")
            cilindro(c, "Cortina", ".", (x, 1.95, z), 0.15, 2.3, "veludo_azul_escuro", raio_topo=0.1)
    bloco(c, "Dossel", ".", (11.15, 3.3, 6.85), (14.05, 3.38, 9.35), "veludo_azul_escuro")
    for (mn, mx) in (((11.15, 2.9, 6.83), (14.05, 3.3, 6.87)), ((11.15, 2.9, 9.33), (14.05, 3.3, 9.37)),
                     ((11.13, 2.9, 6.85), (11.17, 3.3, 9.35))):
        bloco(c, "Sanefa", ".", mn, mx, "veludo_azul_escuro", colisao=False)

    luz_cama = candelabro(c, ".", (13.55, 0, 6.3), "VelaCama", sombra=True, energia=1.4)
    candelabro(c, ".", (13.55, 0, 9.9), "VelaCama2", energia=1.0)

    # Lareira na parede oeste: o quarto era "caloroso".
    lar = c.no("Lareira", "CSGCombiner3D", ".", use_collision="true")
    c.no("Bloco", "CSGBox3D", lar, transform=transform((4.35, 0.8, 8.0)), size=v3(0.7, 1.6, 2.2), material=c.mat("parede_pedra"))
    c.no("Boca", "CSGBox3D", lar, transform=transform((4.6, 0.5, 8.0)), operation="2", size=v3(0.7, 0.9, 1.2), material=c.mat("pedra_escura"))
    c.no("ArcoBoca", "CSGCylinder3D", lar, transform=transform((4.6, 0.95, 8.0), (0, 0, 90)), operation="2",
         radius="0.6", height="0.7", sides="24", material=c.mat("pedra_escura"))
    caixa(c, "Fundo", ".", (4.27, 0.75, 8.0), (0.02, 1.4, 1.2), "carvao")
    caixa(c, "Consolo", ".", (4.45, 1.66, 8.0), (0.9, 0.12, 2.5), "parede_pedra")
    caixa(c, "Chamine", ".", (4.25, 3.24, 8.0), (0.5, 3.04, 1.9), "parede_pedra")
    caixa(c, "Lajeado", ".", (4.75, 0.015, 8.0), (0.9, 0.03, 2.2), "pedra_escura")
    for z, r in ((7.8, 0), (8.2, 0), (8.0, 20)):
        cilindro(c, "Lenha", ".", (4.4, 0.1, z), 0.07, 0.7, "carvao", rot=(0, 90 + r, 90))
    for z, a in ((7.7, 0.55), (8.0, 0.75), (8.3, 0.5)):
        chama(c, ".", (4.42, 0.1, z), 0.4, a)
    luz(c, "Lareira", ".", (4.95, 0.6, 8.0), 2.2, 9.0, (1, 0.55, 0.25), sombra=True, tremor=0.35)
    for z in (7.1, 8.9):
        vela(c, ".", (4.5, 1.72, z), altura=0.2, acesa=False)
    pol = grupo(c, "Poltrona", ".", (5.7, 0, 6.3), 143)
    caixa(c, "Assento", pol, (0, 0.42, 0), (0.75, 0.16, 0.7), "veludo_vermelho", True)
    caixa(c, "Encosto", pol, (0, 0.9, 0.31), (0.75, 0.85, 0.12), "veludo_vermelho")
    for x in (-0.35, 0.35):
        caixa(c, "Braco", pol, (x, 0.62, 0.0), (0.1, 0.28, 0.7), "veludo_vermelho")
    for x in (-0.3, 0.3):
        for z in (-0.28, 0.28):
            caixa(c, "Pe", pol, (x, 0.17, z), (0.06, 0.34, 0.06), "madeira_movel")

    # Cômoda com espelho; a vela dela é a luz perto da porta.
    com = grupo(c, "Comoda", ".", (6.6, 0, 4.2), 0)
    caixa(c, "Corpo", com, (0, 0.45, 0), (1.6, 0.9, 0.55), "madeira_movel", True)
    for y in (0.2, 0.45, 0.7):
        caixa(c, "Gaveta", com, (0, y, 0.276), (1.5, 0.005, 0.01), "carvao")
        for x in (-0.4, 0.4):
            esfera(c, "Puxador", com, (x, y + 0.1, 0.29), 0.02, "bronze")
    caixa(c, "Moldura", com, (0, 1.6, -0.24), (0.9, 1.1, 0.04), "ouro")
    caixa(c, "Espelho", com, (0, 1.6, -0.215), (0.78, 0.98, 0.01), "espelho")
    vela(c, com, (-0.55, 0.9, 0.05), altura=0.16)
    luz(c, "VelaPorta", ".", (6.05, 1.35, 4.35), 0.8, 4.0)
    caixa(c, "Caixinha", com, (0.4, 0.95, 0.0), (0.22, 0.1, 0.15), "veludo_vermelho")

    # O que as parteiras e as empregadas usam: bacias, jarro e panos.
    apoio = grupo(c, "Apoio", ".", (10.5, 0, 6.1), 0)
    cilindro(c, "Tampo", apoio, (0, 0.78, 0), 0.32, 0.04, "madeira_movel")
    cilindro(c, "Coluna", apoio, (0, 0.39, 0), 0.05, 0.76, "madeira_movel")
    cilindro(c, "Base", apoio, (0, 0.03, 0), 0.22, 0.06, "madeira_movel")
    bacia(c, apoio, (0, 0.8, 0))
    jarro(c, ".", (10.95, 0, 5.7))
    bacia(c, ".", (11.0, 0, 10.1), raio=0.3)
    panos(c, ".", (10.6, 0, 10.4), 2, giro=25)
    panos(c, ".", (12.5, 0.5, 4.3), 4)

    bau(c, ".", (12.5, 0, 4.3), giro=0, largura=1.1)
    plano(c, "Tapete", ".", (9.0, 0.006, 8.1), (4.2, 3.2), "tapete")
    armario(c, ".", (x0 + 0.32, 0, 10.8), 90, largura=1.5, altura=2.4)
    bau(c, ".", (12.0, 0, z1 - 0.3), giro=180, largura=0.9)
    quadro(c, ".", (12.5, 2.2, z0), 0, 1.5, "helade", proporcao=0.77)
    quadro(c, ".", (x0, 2.0, 5.3), 90, 1.1, "agape")
    # Cortinas pesadas no arco da varanda.
    cilindro(c, "Varao", ".", (9.0, 3.75, z1 - 0.15), 0.025, 5.4, "bronze", rot=(0, 0, 90))
    for x in (7.05, 10.95):
        caixa(c, "CortinaVaranda", ".", (x, 1.85, z1 - 0.15), (0.9, 3.7, 0.12), "veludo_azul_escuro")
    vaso_planta(c, ".", (13.4, 0, 12.0))
    vaso_planta(c, ".", (4.7, 0, 12.0))

    # Varanda com vista para o mar, onde Nicholas tomava chá com a mãe.
    bloco(c, "ChaoVaranda", ".", (6.0, -0.3, z1 + 0.3), (12.0, 0, 16.6), "marmore_varanda")
    for x in (6.4, 9.0, 11.6):
        caixa(c, "Misula", ".", (x, -0.75, 14.6), (0.35, 0.9, 3.6), "parede_pedra")
    lados = [((6.0, 16.45), (12.0, 16.6), True), ((6.0, z1 + 0.3), (6.15, 16.6), False), ((11.85, z1 + 0.3), (12.0, 16.6), False)]
    for (a, b, ao_longo_x) in lados:
        bloco(c, "Rodape", ".", (a[0], 0, a[1]), (b[0], 0.1, b[1]), "marmore_varanda")
        bloco(c, "Corrimao", ".", (a[0] - 0.03, 0.88, a[1] - 0.03), (b[0] + 0.03, 0.98, b[1] + 0.03), "marmore_varanda", colisao=False)
        corpo = c.no("Guarda", "StaticBody3D", ".", transform=transform(((a[0] + b[0]) / 2, 0.6, (a[1] + b[1]) / 2)))
        c.no("Forma", "CollisionShape3D", corpo, shape=c.s("BoxShape3D", size=v3(b[0] - a[0], 1.2, b[1] - a[1])))
        comprimento = (b[0] - a[0]) if ao_longo_x else (b[1] - a[1])
        n = int(comprimento / 0.28)
        for i in range(n):
            t = (i + 0.5) / n
            if ao_longo_x:
                pos = (a[0] + t * (b[0] - a[0]), 0.49, (a[1] + b[1]) / 2)
            else:
                pos = ((a[0] + b[0]) / 2, 0.49, a[1] + t * (b[1] - a[1]))
            cilindro(c, "Balaustre", ".", pos, 0.05, 0.78, "marmore_varanda", raio_topo=0.035, lados=8)
    m = grupo(c, "MesaCha", ".", (7.4, 0, 15.3), 0)
    cilindro(c, "Tampo", m, (0, 0.7, 0), 0.45, 0.04, "marmore_varanda", lados=24)
    cilindro(c, "Coluna", m, (0, 0.35, 0), 0.05, 0.7, "bronze")
    cilindro(c, "Base", m, (0, 0.02, 0), 0.25, 0.04, "bronze")
    corpo = c.no("Corpo", "StaticBody3D", m)
    c.no("Forma", "CollisionShape3D", corpo, transform=transform((0, 0.36, 0)),
         shape=c.s("CylinderShape3D", radius="0.45", height="0.72"))
    cilindro(c, "Bandeja", m, (0, 0.73, 0), 0.22, 0.015, "bronze", lados=20)
    esfera(c, "Bule", m, (0.02, 0.81, 0), 0.08, "louca", escala=(1, 0.9, 1))
    cilindro(c, "Bico", m, (0.12, 0.82, 0), 0.012, 0.12, "louca", raio_topo=0.008, rot=(0, 0, -55))
    esfera(c, "Tampa", m, (0.02, 0.88, 0), 0.03, "louca")
    for x, z in ((-0.25, 0.15), (0.2, -0.22)):
        cilindro(c, "Pires", m, (x, 0.725, z), 0.06, 0.01, "louca", lados=16)
        cilindro(c, "Xicara", m, (x, 0.755, z), 0.03, 0.05, "louca", raio_topo=0.04, lados=16)
    cadeira(c, ".", (6.75, 0, 15.3), giro=-90)
    cadeira(c, ".", (8.05, 0, 15.3), giro=90)
    vaso_planta(c, ".", (6.5, 0, 16.1))
    vaso_planta(c, ".", (11.5, 0, 16.1))
    return c


def exterior() -> Cena:
    c = Cena("Exterior")
    # Penhasco: o castelo fica no alto, o mar 12 m abaixo.
    bloco(c, "Rocha", ".", (-60, -14, -10), (60, -0.2, 12.9), "pedra_escura")
    # Fachada sul (as paredes sul dos cômodos completam o resto).
    z0, z1 = 12.6, 12.9
    for (xa, xb, ya, yb) in ((-18, -12.8, 0, 9), (-5.2, 3.7, 0, 9), (14.3, 18, 0, 9),
                             (-12.8, -5.2, 4.8, 9), (3.7, 14.3, 4.8, 9)):
        bloco(c, "Fachada", ".", (xa, ya, z0), (xb, yb, z1), "parede_pedra")
    for i in range(18):
        x = -17.5 + i * 2.05
        caixa(c, "Ameia", ".", (x, 9.35, 12.75), (1.0, 0.7, 0.5), "parede_pedra")
    for x in (-19.5, 19.5):
        cilindro(c, "Torre", ".", (x, 6.0, 12.2), 3.0, 12.4, "parede_pedra", lados=24)
        cilindro(c, "Telhado", ".", (x, 14.2, 12.2), 3.4, 4.0, "madeira_movel", raio_topo=0.05, lados=24)
    mar = c.s("ShaderMaterial", shader=c.e("Shader", "res://assets/shaders/prologo/mar.gdshader"))
    c.no("Mar", "MeshInstance3D", ".", transform=transform((13.5, -12, 160)),
         mesh=c.s("PlaneMesh", material=mar, size=v2(700, 320), subdivide_width=140, subdivide_depth=64))
    # A lua é desenhada pelo céu (ceu_noite.gdshader), sempre junto do halo e da luz "Lua".
    return c


def main() -> None:
    for nome, gerar in (("quarto_nicholas", quarto_nicholas), ("corredor", corredor),
                        ("aposentos", aposentos), ("exterior", exterior)):
        cena = gerar()
        cena.salvar(SAIDA / f"{nome}.tscn")
        print(nome, len(cena.nos), "nós")


if __name__ == "__main__":
    main()
