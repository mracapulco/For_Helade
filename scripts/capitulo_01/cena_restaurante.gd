class_name CenaRestaurante
extends CenaCapitulo01
## Capítulo 01, cena 10: o restaurante, a sopa e a colher (livro, l. ~443-553).
## Sequência (cada [member etapa] só avança na ordem):
## 1. mesa: Nicholas entra, olha o lugar e senta à mesa redonda (E na mesa);
##    Ophelia e Althea sentam também; o garçom serve.
## 2. almoco: o prato intocado, a escolha de tom ao insistir (só muda a
##    relação com Ophelia), a sopa, a colher e as desculpas; Ophelia prova a
##    sopa e o garçom se retira.
## 3. armario: Nicholas se levanta e pega uma colher limpa (E no armário de
##    louça); as risadas e o fim do almoço.
## Ao terminar a etapa vira "passeio" (cena 11, ainda não implementada): por
## enquanto o jogo volta ao menu.
## Textos: data/dialogos/capitulo_01/restaurante.dialogue.

const ROTEIRO := preload("res://data/dialogos/capitulo_01/restaurante.dialogue")
const QUADROS_GARCOM := preload("res://assets/art/personagens/garcom/garcom_exploracao.tres")
## Cadeiras (casas): Nicholas, Ophelia e Althea (esta de costas para nós).
const CADEIRA_NICHOLAS := Vector2i(3, 4)
const CADEIRA_OPHELIA := Vector2i(4, 3)
const CADEIRA_ALTHEA := Vector2i(5, 4)
const CASA_ARMARIO := Vector2i(6, 1)
const CASA_GARCOM := Vector2i(7, 3)
## Casa ao lado da mesa onde o garçom serve.
const CASA_SERVIR := Vector2i(5, 5)

## Quem está sentado (nome do objeto -> imagem sentada na sala).
var sentados := {}
var pegou_colher := false


func _init() -> void:
	roteiro = ROTEIRO


func id_da_cena() -> String:
	return "restaurante"


func comecar() -> void:
	montar_restaurante()
	await _clarear()
	await _frases("frases_restaurante")
	_mudar("mesa")
	_ativar(objetos["mesa"], true)


func montar_restaurante() -> void:
	_nova_sala(8, 7, TOM_DENTRO, "ladrilho", "reboco")
	_pendurar([["quadro_atenas_esq", Vector2i(2, 0)], ["arandela_esq", Vector2i(3, 0)],
		["janela_carruagem_esq", Vector2i(4, 0)], ["janela_carruagem_esq", Vector2i(5, 0)],
		["arandela_esq", Vector2i(6, 0)], ["arandela_dir", Vector2i(0, 3)]])
	_objeto("armario", "restaurante/armario_louca", CASA_ARMARIO, true, PE_CAIXA)
	_objeto("mesa", "restaurante/mesa_redonda", Vector2i(4, 4), true)
	_objeto("cadeira_nicholas", "restaurante/cadeira_frente", CADEIRA_NICHOLAS)
	_objeto("cadeira_ophelia", "restaurante/cadeira_frente", CADEIRA_OPHELIA)
	_objeto("cadeira_althea", "restaurante/cadeira_costas", CADEIRA_ALTHEA)
	_pessoa("ophelia", QUADROS_OPHELIA, Vector2i(4, 2))
	_pessoa("althea", QUADROS_ALTHEA, Vector2i(3, 2))
	_pessoa("garcom", QUADROS_GARCOM, CASA_GARCOM)
	_entrar(Vector2i(2, 4))
	_ativar(objetos["mesa"], false)
	_ativar(objetos["armario"], false)
	_ao_interagir("mesa", sentar_a_mesa)
	_ao_interagir("armario", pegar_colher_limpa)
	_mudar("restaurante")


# --- 1. a mesa -------------------------------------------------------------

func sentar_a_mesa() -> void:
	if etapa != "mesa":
		return
	_mudar("almoco")
	_ativar(objetos["mesa"], false)
	_travar(true)
	await _caminhar(objetos["ophelia"], [sala.centro(CADEIRA_OPHELIA)], 0.8)
	await _caminhar(objetos["althea"], [sala.centro(CADEIRA_ALTHEA)], 0.8)
	_sentar("ophelia", QUADROS_OPHELIA, CADEIRA_OPHELIA)
	_sentar("althea", QUADROS_ALTHEA, CADEIRA_ALTHEA, &"parado_costas")
	jogador.position = sala.centro(CADEIRA_NICHOLAS)
	_sentar_nicholas()
	await _servir()
	await _almoco()


## O garçom traz os pratos e volta ao seu lugar.
func _servir() -> void:
	await _caminhar(objetos["garcom"], [sala.centro(CASA_SERVIR)], 1.2)
	_virar(objetos["garcom"], sala.centro(Vector2i(4, 4)))


func _almoco() -> void:
	await _falar_travado("prato_intocado")
	await _falar_travado("insistir")
	await _falar_travado("sopa")
	await _falar_travado("colher")
	await _falar_travado("desculpas")
	await _falar_travado("ophelia_toma")
	await _caminhar(objetos["garcom"], [sala.centro(CASA_GARCOM)], 1.2)
	await _sumir(objetos["garcom"])
	await levantar_nicholas()


# --- 3. o armário e o fim -----------------------------------------------------

## Nicholas se levanta (a casa livre mais perto do armário) e pode ir buscar a colher.
func levantar_nicholas() -> void:
	_mudar("armario")
	sentados["nicholas"].queue_free()
	sentados.erase("nicholas")
	jogador.get_node("Corpo").visible = true
	jogador.get_node("Sombra").visible = true
	jogador.position = sala.centro(_casa_livre_perto(CASA_ARMARIO, CADEIRA_NICHOLAS))
	_travar(false)
	_ativar(objetos["armario"], true)


## "Retirou uma colher limpa"; as risadas e o fim do almoço.
func pegar_colher_limpa() -> void:
	if etapa != "armario" or pegou_colher:
		return
	pegou_colher = true
	_ativar(objetos["armario"], false)
	await _falar_travado("risos")
	await _frases("frases_fim_almoco")
	await terminar()


# --- sentados ------------------------------------------------------------------

## Põe a pessoa sentada na cadeira (a imagem do quadro em pé, cortada no quadril).
func _sentar(nome: String, quadros: SpriteFrames, casa: Vector2i, tronco := &"parado_frente") -> Sprite2D:
	var pessoa: Node2D = objetos[nome]
	pessoa.position = sala.centro(casa)
	pessoa.get_node("Visual").visible = false
	var sprite := _imagem_sentada(nome, quadros, casa, tronco)
	sentados[nome] = sprite
	return sprite


func _sentar_nicholas() -> void:
	jogador.get_node("Corpo").visible = false
	jogador.get_node("Sombra").visible = false
	sentados["nicholas"] = _imagem_sentada("Nicholas", QUADROS_NICHOLAS, CADEIRA_NICHOLAS, &"parado_frente")


func _imagem_sentada(nome: String, quadros: SpriteFrames, casa: Vector2i, tronco: StringName) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "Sentado_" + nome.to_pascal_case()
	sprite.texture = Capitulo01.imagem_sentada(quadros, tronco)
	sprite.centered = false
	var meio := (sprite.texture.get_width() - 2 * roundi(16.0 * Capitulo01.COXA)) / 2.0
	sprite.offset = Vector2(-meio, -sprite.texture.get_height())
	# Um pouco à frente da cadeira na ordem de desenho.
	sprite.position = sala.centro(casa) + Vector2(0, 2)
	sala.add_child(sprite)
	return sprite
