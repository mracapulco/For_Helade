"""Monta a cena da visão da varanda (Capítulo 01, cena 8) em scenes/capitulo_01/visao_varanda.tscn.

A visão de Nicholas na carruagem, em primeira pessoa 3D e sem andar: uma varanda
fria à noite, céu limpo salpicado de luzes, ar imóvel e uma garota de costas
(cabelos longos, ondulados, escuros). A garota vem de malhas feitas por código
(tools/arte/gerar_garota_visao.py); o resto usa formas do próprio Godot e os
materiais do prólogo, até a arte definitiva chegar. Renderer gl_compatibility:
sem SSAO e sem névoa volumétrica.

A raiz é um CanvasLayer (por cima da cena 2D do capítulo) com:
  Mundo (SubViewportContainer > Viewport com mundo 3D próprio), Vinheta,
  Tremor (shader do sonho), Escuro (cortina preta) e Texto (frases do livro).
O comportamento fica em scripts/capitulo_01/visao_varanda.gd.

Coordenadas em metros: y para cima; a câmera olha para +z; a garota está de
costas para a câmera, de frente para o corrimão (z = 4,4).

Uso: python3 tools/cena/gerar_visao_varanda.py   (rodar na raiz do projeto)
"""
import math
import random
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

from gerar_cenario_prologo import RAIZ, Cena, bloco, cilindro, cor, num, transform, v2, v3  # noqa: E402

SAIDA = RAIZ / "scenes/capitulo_01/visao_varanda.tscn"
SCRIPT = "res://scripts/capitulo_01/visao_varanda.gd"
TEXTO_SOLTO = "res://scripts/prologo/texto_solto.gd"
TREMOR = "res://scripts/capitulo_01/tremor_do_sonho.gdshader"
VINHETA = "res://assets/shaders/prologo/vinheta.gdshader"
CEU = "res://assets/shaders/prologo/ceu_noite.gdshader"
GAROTA = "res://assets/art/capitulo_01/visao/"

MUNDO = "Mundo"
VIEW = "Mundo/Viewport"
CEN = "Mundo/Viewport/Cenario"
Z_CORRIMAO = 4.4
LARGURA = 3.2          # meia largura da varanda


def pleno(c: Cena, nome, tipo, pai, **props):
    """Control que ocupa a tela toda (filho do CanvasLayer)."""
    base = dict(layout_mode="3", anchors_preset="15", anchor_right="1.0", anchor_bottom="1.0",
                grow_horizontal="2", grow_vertical="2", mouse_filter="2")
    base.update(props)
    return c.no(nome, tipo, pai, **base)


def material(c: Cena, albedo, rugosidade=0.8, emissao=None, energia=1.0, sem_luz=False):
    props = dict(albedo_color=cor(*albedo), roughness=num(rugosidade))
    if emissao:
        props.update(emission_enabled="true", emission=cor(*emissao), emission_energy_multiplier=num(energia))
    if sem_luz:
        props["shading_mode"] = "0"
    return c.s("StandardMaterial3D", **props)


def malha(c: Cena, nome, pai, mesh, mat, pos=(0, 0, 0), rot=(0, 0, 0), escala=(1, 1, 1)):
    return c.no(nome, "MeshInstance3D", pai, transform=transform(pos, rot, escala), mesh=mesh, material_override=mat)


def elipsoide(c: Cena, nome, pai, pos, raio, mat, escala=(1, 1, 1), rot=(0, 0, 0)):
    return malha(c, nome, pai, c.s("SphereMesh", radius=num(raio), height=num(raio * 2), radial_segments=14, rings=7),
                 mat, pos, rot, escala)


def haste(c: Cena, nome, pai, pos, raio, altura, mat, rot=(0, 0, 0), raio_baixo=None):
    return malha(c, nome, pai, c.s("CylinderMesh", top_radius=num(raio),
                                   bottom_radius=num(raio if raio_baixo is None else raio_baixo),
                                   height=num(altura), radial_segments=14, rings=1), mat, pos, rot)


# ------------------------------------------------------------ garota

def garota(c: Cena, pai) -> None:
    """Ophelia adulta, de costas (malhas de tools/arte/gerar_garota_visao.py): pele cor de
    caramelo, veludo vermelho de ombros nus, pérolas e cabelo escuro cacheado (V2 c01, c04)."""
    pele = material(c, (0.56, 0.37, 0.25), 0.6)
    veludo = c.s("StandardMaterial3D", albedo_color=cor(0.42, 0.035, 0.05), roughness=num(0.95),
                 rim_enabled="true", rim=num(0.55), rim_tint=num(0.15))
    perola = c.s("StandardMaterial3D", albedo_color=cor(0.94, 0.91, 0.86), roughness=num(0.22),
                 metallic_specular=num(0.8))
    cabelo = c.s("StandardMaterial3D", albedo_color=cor(0.06, 0.04, 0.035), roughness=num(0.38),
                 cull_mode="2", rim_enabled="true", rim=num(0.35), rim_tint=num(0.6))
    g = c.no("Garota", "Node3D", pai, transform=transform((0, 0, 3.9)))
    for nome, mat in (("vestido", veludo), ("pele", pele), ("perolas", perola), ("cabelo", cabelo)):
        mesh = c.e("ArrayMesh", f"{GAROTA}garota_{nome}.obj")
        malha(c, nome.capitalize(), g, mesh, mat)
        c.nos[-1][3]["layers"] = "3"                       # camada 2: só ela recebe o contorno


# ------------------------------------------------------------ varanda

def varanda(c: Cena, pai) -> None:
    # laje de mármore frio e a parede de pedra atrás da câmera
    bloco(c, "Chao", pai, (-LARGURA, -0.3, -3.0), (LARGURA, 0, Z_CORRIMAO + 0.1), "marmore_varanda", colisao=False)
    bloco(c, "ParedeFundo", pai, (-LARGURA - 0.5, -0.3, -3.5), (LARGURA + 0.5, 4.5, -3.0), "parede_pedra", colisao=False)
    bloco(c, "BeiralTeto", pai, (-LARGURA - 0.5, 4.5, -3.5), (LARGURA + 0.5, 4.8, 0.2), "parede_pedra", colisao=False)
    # corrimão e balaústres na frente e nos lados
    bloco(c, "Corrimao", pai, (-LARGURA, 0.88, Z_CORRIMAO - 0.07), (LARGURA, 0.98, Z_CORRIMAO + 0.07),
          "marmore_varanda", colisao=False)
    bloco(c, "Rodape", pai, (-LARGURA, 0, Z_CORRIMAO - 0.07), (LARGURA, 0.1, Z_CORRIMAO + 0.07),
          "marmore_varanda", colisao=False)
    n = int(2 * LARGURA / 0.28)
    for i in range(n):
        x = -LARGURA + (i + 0.5) * (2 * LARGURA / n)
        cilindro(c, "Balaustre", pai, (x, 0.49, Z_CORRIMAO), 0.05, 0.78, "marmore_varanda", raio_topo=0.035, lados=8)
    for lado in (-1, 1):
        bloco(c, "CorrimaoLado", pai, (lado * LARGURA - 0.07, 0.88, -3.0), (lado * LARGURA + 0.07, 0.98, Z_CORRIMAO),
              "marmore_varanda", colisao=False)
        bloco(c, "Pilar", pai, (lado * LARGURA - 0.14, 0, Z_CORRIMAO - 0.14),
              (lado * LARGURA + 0.14, 1.25, Z_CORRIMAO + 0.14), "marmore_varanda", colisao=False)
        for i in range(8):
            z = -2.6 + i * 0.85
            cilindro(c, "Balaustre", pai, (lado * LARGURA, 0.49, z), 0.05, 0.78, "marmore_varanda",
                     raio_topo=0.035, lados=8)


def horizonte(c: Cena, pai, sorte) -> None:
    """Terra escura ao longe, com luzes distantes, e um vazio frio embaixo."""
    escuro = material(c, (0.012, 0.016, 0.03), 1.0)
    luz_quente = material(c, (1.0, 0.8, 0.5), 1.0, emissao=(1.0, 0.78, 0.45), energia=3.0, sem_luz=True)
    luz_fria = material(c, (0.75, 0.88, 1.0), 1.0, emissao=(0.7, 0.85, 1.0), energia=2.5, sem_luz=True)
    caixa_mesh = c.s("BoxMesh", size=v3(1, 1, 1))
    # silhueta de colinas, blocos de alturas diferentes
    x = -260.0
    while x < 260.0:
        w = sorte.uniform(30, 70)
        topo = sorte.uniform(-6.0, 4.5)
        malha(c, "Colina", pai, caixa_mesh, escuro, (x + w / 2, (topo - 60) / 2, 190), escala=(w, topo + 60, 40))
        x += w * 0.8
    malha(c, "Vazio", pai, c.s("PlaneMesh", size=v2(900, 700)), escuro, (0, -60, 150))
    bola = c.s("SphereMesh", radius="0.35", height="0.7", radial_segments=6, rings=3)
    for i in range(70):
        x = sorte.uniform(-220, 220)
        y = sorte.uniform(-9.0, -0.5)
        tam = 1.0 if i % 3 else 1.5
        malha(c, "LuzDistante", pai, bola, luz_fria if i % 6 == 0 else luz_quente, (x, y, 168),
              escala=(tam, tam, tam))


# ------------------------------------------------------------ cena

def montar() -> Cena:
    sorte = random.Random(8)
    c = Cena("VisaoVaranda")
    c.nos[0] = ("VisaoVaranda", "CanvasLayer", None, dict(layer="60", script=c.e("Script", SCRIPT)))

    # mundo 3D num viewport próprio (a cena 2D do capítulo continua por baixo)
    pleno(c, "Mundo", "SubViewportContainer", ".", visible="false", stretch="true", unique_name_in_owner="true")
    c.no("Viewport", "SubViewport", MUNDO, handle_input_locally="false", msaa_3d="0", own_world_3d="true")
    c.no("Cenario", "Node3D", VIEW)

    ceu_mat = c.s("ShaderMaterial", shader=c.e("Shader", CEU), **{
        "shader_parameter/quantidade_estrelas": "1.0",
        "shader_parameter/brilho_estrelas": "3.2",
        # a lua fica atrás da câmera: o céu é só escuridão e luzes distantes
        "shader_parameter/direcao_lua": "Vector3(0.1, 0.6, -0.8)",
    })
    ceu = c.s("Sky", sky_material=ceu_mat)
    ambiente = c.s("Environment", background_mode="2", sky=ceu, ambient_light_source="2",
                   ambient_light_color=cor(0.28, 0.34, 0.55), ambient_light_energy="0.45",
                   tonemap_mode="3", tonemap_exposure="1.1", glow_enabled="true", glow_intensity="0.6",
                   glow_bloom="0.03", glow_hdr_threshold="0.9", adjustment_enabled="true",
                   adjustment_contrast="1.06", adjustment_saturation="0.85")
    c.no("Ambiente", "WorldEnvironment", CEN, environment=ambiente)
    # luz fria vinda de trás da câmera, tocando as costas da garota
    c.no("LuzFria", "DirectionalLight3D", CEN, transform=transform(rot=(-30, 180, 0)),
         light_color=cor(0.62, 0.72, 1.0), light_energy="0.7")
    # contorno: luz fraca vinda do céu à frente, para a silhueta (cabelo, ombros) não sumir no escuro
    c.no("LuzContorno", "DirectionalLight3D", CEN, transform=transform(rot=(-15, 0, 0)),
         light_color=cor(0.55, 0.65, 1.0), light_energy="0.7", light_cull_mask="2")
    c.no("Camera", "Camera3D", CEN, transform=transform((0, 1.72, -0.6), (-1.5, 180, 0)), current="true",
         fov="58.0", unique_name_in_owner="true")
    varanda(c, CEN)
    garota(c, CEN)
    horizonte(c, CEN, sorte)

    # por cima do 3D
    pleno(c, "Vinheta", "ColorRect", ".", color=cor(1, 1, 1, 1), material=c.s(
        "ShaderMaterial", shader=c.e("Shader", VINHETA), **{
            "shader_parameter/vinheta": "0.5", "shader_parameter/desfoque": "0.0",
            "shader_parameter/granulacao": "0.04"}))
    pleno(c, "Tremor", "ColorRect", ".", color=cor(1, 1, 1, 1), unique_name_in_owner="true", material=c.s(
        "ShaderMaterial", shader=c.e("Shader", TREMOR), **{"shader_parameter/forca": "0.001"}))
    pleno(c, "Escuro", "ColorRect", ".", color=cor(0, 0, 0, 0), unique_name_in_owner="true")
    c.no("Texto", "Label", ".", unique_name_in_owner="true", layout_mode="3", anchors_preset="-1", anchor_top="0.1",
         anchor_right="1.0", anchor_bottom="0.34", offset_left="80.0", offset_right="-80.0", mouse_filter="2",
         horizontal_alignment="1", vertical_alignment="1", autowrap_mode="3",
         script=c.e("Script", TEXTO_SOLTO), tempo_fade="0.35", tempo_minimo="0.5", tempo_por_letra="0.02",
         **{"theme_override_font_sizes/font_size": "32",
            "theme_override_colors/font_color": cor(0.97, 0.92, 0.8, 1),
            "theme_override_colors/font_outline_color": cor(0, 0, 0, 0.85),
            "theme_override_constants/outline_size": "10"})
    return c


if __name__ == "__main__":
    cena = montar()
    cena.salvar(SAIDA)
    print("visao_varanda", len(cena.nos), "nós")
