class_name TrilhaDasCenas
extends RefCounted
## O que tocar em cada cena e em cada etapa dela (data/musica/cenas.cfg):
## seção = caminho da cena, chave = etapa (ou [constant INICIO], quando a cena
## abre), valor = [música, ambiente] ou [música, ambiente, fade em segundos].
## "" é silêncio e [constant MANTER] deixa como está.

const ARQUIVO := "res://data/musica/cenas.cfg"
## Chave do que toca quando a cena abre.
const INICIO := "inicio"
## Valor que deixa a música (ou o ambiente) como está.
const MANTER := "="

var _cfg := ConfigFile.new()


static func carregar(caminho := ARQUIVO) -> TrilhaDasCenas:
	var t := TrilhaDasCenas.new()
	if t._cfg.load(caminho) != OK:
		push_warning("Trilha: não abriu %s" % caminho)
	return t


## A cena tem música configurada.
func tem(cena: String) -> bool:
	return _cfg.has_section(cena)


## Cenas configuradas.
func cenas() -> PackedStringArray:
	return _cfg.get_sections()


## Etapas configuradas da [param cena].
func etapas(cena: String) -> PackedStringArray:
	return _cfg.get_section_keys(cena) if tem(cena) else PackedStringArray()


## {musica, ambiente, fade (-1 = o padrão)} da etapa, ou vazio se ela não muda nada.
func faixas(cena: String, etapa: String) -> Dictionary:
	if not tem(cena) or not _cfg.has_section_key(cena, etapa):
		return {}
	var valor: Variant = _cfg.get_value(cena, etapa)
	if not valor is Array or valor.size() < 2:
		push_warning("Trilha: %s/%s precisa ser [música, ambiente]" % [cena, etapa])
		return {}
	return {
		"musica": str(valor[0]),
		"ambiente": str(valor[1]),
		"fade": float(valor[2]) if valor.size() > 2 else -1.0,
	}
