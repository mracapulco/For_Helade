# Gera os retratos 64×64 dos convidados (Rafael e Shara) para a caixa de
# diálogo, a partir de fotos deles. As fotos NÃO ficam no repositório: são
# só a referência, passadas na linha de comando. O resultado (PNG) é que fica
# em assets/art/convidados/<id>/.
# Uso: python3 tools/arte/retratos_convidados.py <foto do rafael> <foto da shara>
#
# Como funciona: a cabeça é recortada da foto por um contorno (pontos na
# escala da foto), reduzida e pintada só com uma paleta curta de pele e outra
# de cabelo, o que dá o aspecto de pixel art e mantém as feições. Olhos,
# sobrancelhas, boca, óculos e a roupa (da época do jogo) são desenhados por
# cima, pixel a pixel. A boca tem 3 posições (fechada, entreaberta, aberta):
# <id>_retrato.png é a fechada; <id>_retrato_fala.png tem as 3 lado a lado.
# Os pontos dos contornos valem para aquelas fotos; outra foto pede outros.
import os
import sys

FOTOS = {}

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageChops
H=lambda h: tuple(int(h[i:i+2],16) for i in (1,3,5))

def mapear(pq, m, pal):
    palH=[H(c) for c in pal]
    out=Image.new('RGBA',pq.size,(0,0,0,0))
    for y in range(pq.height):
        for x in range(pq.width):
            if m.getpixel((x,y)):
                r,g,b=pq.getpixel((x,y))
                c=min(palH,key=lambda p:(p[0]-r)**2*0.3+(p[1]-g)**2*0.59+(p[2]-b)**2*0.11)
                out.putpixel((x,y),c+(255,))
    return out

def cabeca(foto, orig, cabeca_pts, cabelo_pts, alt, pal_pele, pal_cab, blur=1.5, brilho=1.0):
    im=Image.open(foto).convert('RGB')
    im=ImageEnhance.Brightness(im).enhance(brilho)
    ox,oy=orig
    tr=lambda pts:[(x+ox,y+oy) for x,y in pts]
    P=tr(cabeca_pts); C=tr(cabelo_pts)
    xs=[p[0] for p in P]; ys=[p[1] for p in P]; bb=(min(xs),min(ys),max(xs)+1,max(ys)+1)
    mc=Image.new('L',im.size,0); ImageDraw.Draw(mc).polygon(P,fill=255)
    mh=Image.new('L',im.size,0); ImageDraw.Draw(mh).polygon(C,fill=255)
    im=ImageEnhance.Contrast(im).enhance(1.1).filter(ImageFilter.GaussianBlur(blur))
    k=alt/(bb[3]-bb[1]); w=round((bb[2]-bb[0])*k)
    pq=im.crop(bb).resize((w,alt),Image.LANCZOS)
    thr=lambda m: m.crop(bb).resize((w,alt),Image.BOX).point(lambda v:255 if v>120 else 0)
    m_cab=thr(mc); m_hair=thr(mh)
    m_pele=ImageChops.subtract(m_cab,m_hair)
    m_h=ImageChops.multiply(m_cab,m_hair)
    a=mapear(pq,m_pele,pal_pele); b=mapear(pq,m_h,pal_cab)
    a.alpha_composite(b)
    conv=lambda x,y:(round((x+ox-bb[0])*k),round((y+oy-bb[1])*k))
    return a,conv,k

def contornar(im, cor=(5,12,20,255)):
    px=im.load(); W,Hh=im.size
    cheios={(x,y) for x in range(W) for y in range(Hh) if px[x,y][3]}
    for (x,y) in list(cheios):
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
            n=(x+dx,y+dy)
            if n not in cheios and 0<=n[0]<W and 0<=n[1]<Hh: px[n]=cor
    return im
N=64
def P(im,x,y,c):
    if 0<=x<im.width and 0<=y<im.height: im.putpixel((x,y),H(c)+(255,))
def R(im,x0,y0,x1,y1,c):
    for y in range(y0,y1+1):
        for x in range(x0,x1+1): P(im,x,y,c)

def rafael_cabeca():
    PELE=['#F6D9C6','#EBBDA2','#D49B80','#B07560','#8A5444']
    CAB=['#7A5640','#563826','#3A2416','#1C110B']
    cab=[(165,32),(110,45),(80,75),(72,120),(74,160),(68,175),(78,225),(95,240),(110,268),(125,285),(122,330),(232,330),(228,280),(238,262),(250,225),(260,200),(262,160),(258,120),(255,80),(235,45)]
    hair=[(110,45),(165,32),(235,45),(258,85),(262,120),(258,152),(248,140),(243,110),(200,95),(150,92),(102,102),(95,150),(84,150),(78,120),(80,75)]
    return cabeca(FOTOS['rafael'],(230,140),cab,hair,56,PELE,CAB)

def shara_cabeca():
    PELE=['#F4DCCB','#E5BFA6','#CB9C83','#A87563','#7A5040']
    CAB=['#B89468','#94704A','#6E5034','#4A3420','#2E1F12']
    cab=[(150,18),(105,28),(75,55),(60,95),(55,150),(45,200),(40,240),(70,252),(110,250),(118,290),(188,290),(195,250),(235,250),(262,232),(250,190),(242,120),(225,60),(195,30)]
    hair=[(150,18),(105,28),(75,55),(60,95),(55,150),(45,200),(40,240),(70,252),(110,250),(112,228),(100,200),(92,150),(95,105),(118,72),(160,58),(198,72),(214,110),(216,170),(205,210),(192,235),(195,250),(235,250),(262,232),(250,190),(242,120),(225,60),(195,30)]
    return cabeca(FOTOS['shara'],(150,150),cab,hair,58,PELE,CAB,brilho=1.35)


def poly(im,pts,c):
    ImageDraw.Draw(im).polygon(pts,fill=H(c)+(255,))

def rafael(boca):
    cab,_,_=rafael_cabeca()
    im=Image.new('RGBA',(N,N),(0,0,0,0))
    x0=32-cab.width//2; y0=2
    # ombros: camisa caqui
    poly(im,[(2,63),(7,55),(20,51),(44,51),(57,55),(62,63)],'#BCA576')
    poly(im,[(2,63),(7,55),(16,52),(12,63)],'#8E7A52')
    poly(im,[(48,53),(57,55),(61,62),(52,58)],'#D9C79A')
    im.alpha_composite(cab,(x0,y0))
    X=lambda x:x0+x; Y=lambda y:y0+y
    # sobrancelhas
    for a,b in ((8,17),(23,32)):
        R(im,X(a),Y(20),X(b),Y(21),'#3A2416')
    P(im,X(7),Y(21),'#3A2416'); P(im,X(33),Y(21),'#3A2416')
    # olhos verdes, apertados pelo sorriso
    for cx in (13,28):
        R(im,X(cx-3),Y(24),X(cx+2),Y(24),'#2A1A10')
        P(im,X(cx-2),Y(25),'#F2EEE6'); R(im,X(cx-1),Y(25),X(cx),Y(25),'#4E8A4A'); P(im,X(cx+1),Y(25),'#2E5A2E')
        P(im,X(cx+2),Y(25),'#F2EEE6')
        R(im,X(cx-2),Y(26),X(cx+1),Y(26),'#B07560')
    # boca
    R(im,X(15),Y(35),X(29),Y(40),'#EBBDA2')
    R(im,X(16),Y(40),X(28),Y(40),'#D49B80')
    if boca==0:
        P(im,X(15),Y(35),'#7A3A34'); P(im,X(16),Y(36),'#7A3A34')
        R(im,X(17),Y(37),X(27),Y(37),'#7A3A34')
        P(im,X(28),Y(36),'#7A3A34'); P(im,X(29),Y(35),'#7A3A34')
        R(im,X(19),Y(38),X(25),Y(38),'#C9776C')
    elif boca==1:
        P(im,X(15),Y(35),'#7A3A34'); R(im,X(16),Y(36),X(28),Y(36),'#6A2E2A'); P(im,X(29),Y(35),'#7A3A34')
        R(im,X(17),Y(37),X(27),Y(37),'#F4F0E8')
        R(im,X(18),Y(38),X(26),Y(38),'#6A2E2A')
        R(im,X(19),Y(39),X(25),Y(39),'#C9776C')
    else:
        P(im,X(15),Y(35),'#7A3A34'); R(im,X(16),Y(36),X(28),Y(36),'#6A2E2A'); P(im,X(29),Y(35),'#7A3A34')
        R(im,X(17),Y(37),X(27),Y(38),'#F4F0E8')
        R(im,X(18),Y(39),X(26),Y(39),'#6A2E2A')
        R(im,X(19),Y(40),X(25),Y(40),'#C9776C')
    # gola e lenço verde com anel
    poly(im,[(22,51),(27,50),(32,57),(25,59)],'#D9C79A')
    poly(im,[(42,51),(37,50),(32,57),(39,59)],'#D9C79A')
    poly(im,[(25,51),(28,50),(32,55),(36,50),(39,51),(35,59),(32,63),(29,59)],'#2A6B3E')
    R(im,X(0)-x0+30,57,33,58,'#ECBD75'); P(im,31,57,'#F4F0E8')
    poly(im,[(34,55),(38,52),(36,58)],'#1A4A28')
    return contornar(im)

def shara(boca):
    cab,_,_=shara_cabeca()
    im=Image.new('RGBA',(N,N),(0,0,0,0))
    x0=32-cab.width//2; y0=1
    # vestido escuro com capa curta de capuz (capuz caído atrás do pescoço)
    poly(im,[(1,63),(6,54),(18,50),(46,50),(58,54),(63,63)],'#2A2A33')
    poly(im,[(1,63),(6,54),(14,51),(10,63)],'#18181F')
    poly(im,[(50,52),(58,54),(62,62),(54,57)],'#454552')
    im.alpha_composite(cab,(x0,y0))
    X=lambda x:x0+x; Y=lambda y:y0+y
    # decote quadrado com a blusa clara por baixo e o broche dourado da capa
    poly(im,[(27,55),(37,55),(35,60),(29,60)],'#E8E0D4')
    R(im,28,55,36,55,'#BFB6A8')
    R(im,31,61,33,62,'#ECBD75'); P(im,32,61,'#F4F0E8')
    # sobrancelhas acima da armação
    R(im,X(11),Y(19),X(19),Y(19),'#6E5034'); R(im,X(24),Y(18),X(33),Y(18),'#6E5034')
    # olhos
    for cx,cy in ((16,26),(29,25)):
        R(im,X(cx-2),Y(cy-1),X(cx+2),Y(cy-1),'#2A1A10')
        P(im,X(cx-2),Y(cy),'#F2EEE6'); P(im,X(cx-1),Y(cy),'#6E6A48'); P(im,X(cx),Y(cy),'#2E2A1C')
        P(im,X(cx+1),Y(cy),'#6E6A48'); P(im,X(cx+2),Y(cy),'#F2EEE6')
    # óculos de armação redonda escura e grossa
    d=ImageDraw.Draw(im)
    for (a,b,c,e) in ((10,21,21,31),(23,20,36,30)):
        d.ellipse((X(a),Y(b),X(c),Y(e)),outline=H('#16161C')+(255,))
    R(im,X(21),Y(24),X(23),Y(24),'#16161C')
    R(im,X(7),Y(24),X(9),Y(24),'#16161C'); R(im,X(37),Y(23),X(39),Y(23),'#16161C')
    P(im,X(19),Y(23),'#DCE6EE'); P(im,X(34),Y(22),'#DCE6EE')
    # boca
    R(im,X(18),Y(34),X(29),Y(39),'#E5BFA6')
    if boca==0:
        P(im,X(18),Y(35),'#9A4E48'); R(im,X(19),Y(36),X(28),Y(36),'#9A4E48'); P(im,X(29),Y(35),'#9A4E48')
        R(im,X(21),Y(37),X(26),Y(37),'#D08A80')
    elif boca==1:
        P(im,X(18),Y(35),'#9A4E48'); R(im,X(19),Y(36),X(28),Y(36),'#7A3A34'); P(im,X(29),Y(35),'#9A4E48')
        R(im,X(20),Y(37),X(27),Y(37),'#F4F0E8')
        R(im,X(21),Y(38),X(26),Y(38),'#D08A80')
    else:
        P(im,X(18),Y(35),'#9A4E48'); R(im,X(19),Y(36),X(28),Y(36),'#7A3A34'); P(im,X(29),Y(35),'#9A4E48')
        R(im,X(20),Y(37),X(27),Y(37),'#F4F0E8')
        R(im,X(20),Y(38),X(27),Y(38),'#7A3A34')
        R(im,X(21),Y(39),X(26),Y(39),'#D08A80')
    return contornar(im)


BOCAS = 3
DESENHOS = {'rafael': rafael, 'shara': shara}

if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit('uso: retratos_convidados.py <foto do rafael> <foto da shara>')
    FOTOS['rafael'], FOTOS['shara'] = sys.argv[1], sys.argv[2]
    raiz = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'art', 'convidados')
    for id, desenho in DESENHOS.items():
        pasta = os.path.join(raiz, id)
        os.makedirs(pasta, exist_ok=True)
        quadros = [desenho(i) for i in range(BOCAS)]
        quadros[0].save(os.path.join(pasta, '%s_retrato.png' % id))
        faixa = Image.new('RGBA', (N * BOCAS, N), (0, 0, 0, 0))
        for i, q in enumerate(quadros):
            faixa.paste(q, (i * N, 0))
        faixa.save(os.path.join(pasta, '%s_retrato_fala.png' % id))
        print(id, faixa.size)
