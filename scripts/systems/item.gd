class_name Item
extends Resource
## Dados de um item do inventário. Cada item é um .tres em
## res://data/itens/, e o nome do arquivo deve ser igual ao [member id].

enum Tipo { ARMA, EQUIPAMENTO, CONSUMIVEL, HISTORIA, DIVERSOS }
## ESCUDO é a mão livre: escudo e proteções improvisadas (caixa, panela).
## Valores novos entram sempre no fim, para não mudar os .tres que já existem.
enum Encaixe { NENHUM, ARMA, ARMADURA, ACESSORIO, ESCUDO, ELMO }
## Como a arma golpeia: muda o giro dela na mão e o efeito do golpe.
## CORTE e PANCADA mostram o arco do golpe; TIRO solta uma flecha.
enum Estilo { CORTE, PANCADA, ESTOCADA, TIRO }
## De onde vem a peça: escudos, armaduras e elmos têm as cores de cada reino
## (e dos bandidos). Sem efeito nos bônus.
enum Origem { NENHUMA, OLYMPIA, AGAPE, KHRONOSSES, BANDIDOS }

## Id sem acento, igual ao nome do arquivo, por exemplo "pocao_teste".
@export var id: String = ""

## Chaves de tradução do nome e da descrição (i18n/strings.csv).
@export var chave_nome: String = ""
@export var chave_descricao: String = ""

## Ícone da bolsa. Sem arte, a interface mostra um quadro provisório.
@export var icone: Texture2D

## Desenho do item na mão do personagem, quando equipado (armas).
## Sem ele, o item equipado não aparece no corpo.
@export var visual_na_mao: Texture2D

## Pixel de [member visual_na_mao] que fica dentro do punho: o canto de
## cima à esquerda da mão 2×2 do personagem.
@export var pega_na_mao := Vector2i.ZERO

## Aba da bolsa onde o item aparece.
@export var tipo: Tipo = Tipo.DIVERSOS

## Onde o item é equipado. NENHUM = não se equipa.
@export var encaixe: Encaixe = Encaixe.NENHUM

## Preço base em moedas, para lojas.
@export var preco: int = 0

## Reino (ou bandidos) de onde vem a peça, pelas cores.
@export var origem: Origem = Origem.NENHUMA

## Qualidade, para o balanceamento: 0 = improvisado (caixa, panela),
## 1 = comum, 2 = reforçado. Quanto maior, mais pontos de bônus.
@export_range(0, 5) var nivel: int = 1

@export_group("Bônus")
## Bônus somados aos do personagem enquanto o item está equipado.
## Cada item gasta os pontos que o nível e o encaixe dão (Balanceamento).
@export var ataque: int = 0
@export var defesa: int = 0
## Em porcentagem: +10 = 10% mais rápido; negativo deixa mais lento.
## Vale para andar e para golpear.
@export var velocidade: int = 0

@export_group("Arma")
## Armas de duas mãos ocupam também o encaixe ESCUDO.
@export_range(1, 2) var maos: int = 1
@export var estilo_golpe: Estilo = Estilo.CORTE
## Até onde o golpe pega, em pixels. 0 = o alcance normal do personagem.
@export var alcance: float = 0.0
## Giro na mão em cada quadro do golpe, em graus (0 = como o desenho,
## ponta para baixo; 180 = para cima; -90 = para a frente). Vazio = o giro
## padrão da folha do personagem.
@export var angulos_golpe := PackedFloat32Array()

@export_group("")
## Desenho por cima do corpo, quadro a quadro (armadura e elmo): mesmas
## animações e quadros da folha do personagem.
@export var visual_no_corpo: SpriteFrames

## Cura, para consumíveis.
@export var cura: int = 0

## Itens da história não podem ser largados nem vendidos pelo jogador.
func e_da_historia() -> bool:
	return tipo == Tipo.HISTORIA


func pode_equipar() -> bool:
	return encaixe != Encaixe.NENHUM


func pode_usar() -> bool:
	return tipo == Tipo.CONSUMIVEL


func duas_maos() -> bool:
	return encaixe == Encaixe.ARMA and maos >= 2
