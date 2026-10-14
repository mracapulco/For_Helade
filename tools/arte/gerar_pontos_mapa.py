# Gera data/mapa/*.tres (pontos e caminhos do mapa de Hélade).
# Uso: python3 tools/arte/gerar_pontos_mapa.py  (apaga e recria data/mapa/*.tres)
# Depois rode tools/arte/gerar_mapa.py para a arte acompanhar.
# Regra: cada lugar tem no máximo uma saída por direção (norte, sul, leste, oeste).
# tipo: 0 região, 1 estrada, 2 acampamento, 3 porto, 4 mar
import os, glob, sys
R = 'data/mapa'
E, C, PT, M = 1, 2, 3, 4
nomes = {E: 'MAPA_ESTRADA_NOME', C: 'MAPA_ACAMPAMENTO_NOME', PT: 'MAPA_PORTO_NOME', M: 'MAPA_MAR_NOME'}
P = {}   # id -> (tipo, nome, regiao, pos, cena)
LIG = []  # (a, b, mar)
reg = dict(olympia=(780, 1036), atenas=(430, 700), agape=(910, 770), norte=(470, 330), templo=(930, 372), floresta_ninfas=(1326, 636))
for k, v in reg.items():
    P[k] = (0, f'MAPA_{k.upper()}_NOME', f'MAPA_{k.upper()}_REGIAO', v, '')

def rota(chave, inicio, pontos, fim, mar=()):
    """pontos: [(id, tipo, (x,y))]; mar: índices de trechos por mar (0 = inicio->p0)"""
    seq = [inicio] + [p[0] for p in pontos] + [fim]
    for pid, tipo, pos in pontos:
        cena = f'res://scenes/exploracao/acampamentos/{pid}.tscn' if tipo == C else ''
        nome = 'MAPA_TRILHA_NOME' if pid.startswith('ot_trilha') else nomes[tipo]
        P[pid] = (tipo, nome, chave, pos, cena)
    for i, (a, b) in enumerate(zip(seq, seq[1:])):
        LIG.append((a, b, i in mar))

rota('MAPA_ROTA_OLYMPIA_ATENAS', 'olympia', [
    ('oa_estrada_1', E, (700, 1030)), ('oa_estrada_2', E, (622, 992)), ('oa_acampamento', C, (566, 930)),
    ('oa_estrada_3', E, (508, 862)), ('oa_estrada_4', E, (452, 790))], 'atenas')
rota('MAPA_ROTA_OLYMPIA_ATENAS_TRILHA', 'olympia', [
    ('ot_trilha_1', E, (782, 1118)), ('ot_trilha_2', E, (700, 1128)), ('ot_trilha_3', E, (604, 1080)),
    ('ot_acampamento', C, (500, 1052)), ('ot_trilha_4', E, (390, 1030)), ('ot_trilha_5', E, (276, 990)),
    ('ot_trilha_6', E, (206, 892)), ('ot_trilha_7', E, (226, 790)), ('ot_trilha_8', E, (322, 704))], 'atenas')
rota('MAPA_ROTA_OLYMPIA_AGAPE', 'olympia', [
    ('og_estrada_1', E, (784, 958)), ('og_acampamento', C, (838, 904)), ('og_estrada_2', E, (904, 850))], 'agape')
rota('MAPA_ROTA_ATENAS_AGAPE', 'atenas', [
    ('ag_estrada_1', E, (520, 704)), ('ag_estrada_2', E, (606, 716)), ('ag_acampamento', C, (676, 724)),
    ('ag_estrada_3', E, (752, 748)), ('ag_estrada_4', E, (830, 766))], 'agape')
rota('MAPA_ROTA_ATENAS_NORTE', 'atenas', [
    ('an_estrada_1', E, (432, 620)), ('an_estrada_2', E, (446, 548)), ('an_acampamento', C, (470, 478)),
    ('an_estrada_3', E, (478, 408))], 'norte')
rota('MAPA_ROTA_NORTE_TEMPLO', 'norte', [
    ('nt_estrada_1', E, (552, 332)), ('nt_estrada_2', E, (632, 312)), ('nt_acampamento', C, (710, 318)),
    ('nt_estrada_3', E, (790, 344)), ('nt_estrada_4', E, (862, 370))], 'templo')
rota('MAPA_ROTA_AGAPE_TEMPLO', 'agape', [
    ('at_estrada_1', E, (914, 690)), ('at_estrada_2', E, (936, 620)), ('at_acampamento', C, (926, 540)),
    ('at_estrada_3', E, (930, 460))], 'templo')
# Portos e rotas de barco.
rota('MAPA_PORTO_OLYMPIA_REGIAO', 'olympia', [('po_estrada', E, (878, 1046))], 'porto_olympia')
rota('MAPA_PORTO_AGAPE_REGIAO', 'agape', [('pa_estrada', E, (1030, 790))], 'porto_agape')
P['porto_olympia'] = (PT, 'MAPA_PORTO_NOME', 'MAPA_PORTO_OLYMPIA_REGIAO', (972, 1062), '')
P['porto_agape'] = (PT, 'MAPA_PORTO_NOME', 'MAPA_PORTO_AGAPE_REGIAO', (1146, 806), '')
rota('MAPA_ROTA_OLYMPIA_FLORESTA', 'porto_olympia', [
    ('mo_mar_1', M, (1100, 1000)), ('mo_mar_2', M, (1262, 900)), ('ilha_acampamento', C, (1410, 772))],
    'floresta_ninfas', mar=(0, 1, 2, 3))
rota('MAPA_ROTA_AGAPE_FLORESTA', 'porto_agape', [
    ('ilhota_acampamento', C, (1250, 790)), ('ma_mar_1', M, (1214, 706)), ('ma_mar_2', M, (1176, 642))],
    'floresta_ninfas', mar=(0, 1, 2, 3))

if __name__ == '__main__':
    for f in glob.glob(R + '/*.tres'):
        os.remove(f)
    viz = {k: ([], []) for k in P}
    for a, b, mar in LIG:
        viz[a][1 if mar else 0].append(b)
    for pid, (tipo, nome, regiao, (x, y), cena) in P.items():
        arr = lambda l: 'Array[String]([%s])' % ', '.join(f'"{i}"' for i in l)
        t = f'''[gd_resource type="Resource" script_class="LocalMapa" format=3]

[ext_resource type="Script" path="res://scripts/systems/local_mapa.gd" id="1_local"]

[resource]
script = ExtResource("1_local")
id = "{pid}"
chave_nome = "{nome}"
chave_regiao = "{regiao}"
posicao = Vector2({x}, {y})
'''
        if tipo: t += f'tipo = {tipo}\n'
        if viz[pid][0]: t += f'vizinhos = {arr(viz[pid][0])}\n'
        if viz[pid][1]: t += f'vizinhos_por_mar = {arr(viz[pid][1])}\n'
        if cena: t += f'cena = "{cena}"\n'
        if pid == 'olympia': t += 'liberado_no_inicio = true\n'
        open(f'{R}/{pid}.tres', 'w').write(t)
    print(len(P), 'pontos', len(LIG), 'ligações')
