# Por Hélade

Jogo baseado no livro *Pelos Olhos Dele*, de Shara M. Schwartz. Contexto e decisões do projeto ficam no `CLAUDE.md`.

## Requisitos

- **Godot 4.7** (build padrão, não a .NET). O Dialogue Manager 4 exige Godot 4.6 ou mais novo e o GUT 9.7 é feito para o 4.7.

## Rodar

Para testar o diálogo: abra `scenes/testes/teste_dialogo.tscn` no Godot e aperte F6 (rodar a cena atual).

## Pastas

| Pasta | O que tem |
| --- | --- |
| `data/dialogos/` | Cenas de roteiro em `.dialogue`, uma pasta por capítulo |
| `data/personagens/` | Um `.tres` por personagem (nome no roteiro e retratos por expressão) |
| `data/itens/` | Um `.tres` por item (`Item`); o nome do arquivo é o id. Entra sozinho no `Inventario` |
| `scripts/autoload/` | `Relacoes`, `Influencia`, `Elenco` e `Inventario` |
| `scripts/systems/` | `Medidor` (base de relações e influência), `Personagem` e `Item` |
| `scenes/ui/` + `scripts/ui/` | Caixa de diálogo com retrato e escolhas; tela da bolsa (`tela_bolsa.tscn`, abre com I/Tab ou o botão Bolsa) |
| `scenes/testes/` + `scripts/testes/` | Telas provisórias de teste |
| `i18n/strings.csv` | Textos de interface por chave |
| `tests/` | Testes GUT (`unit/`, `integration/`) |
| `addons/` | Plugins de terceiros sem modificação: Dialogue Manager 4.1.0 e GUT 9.7.1 |

## Escrevendo diálogo

Sintaxe completa: [documentação do Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager/tree/main/docs). O básico:

```
~ nome_da_cena

Nicholas: [#retrato=neutro] Texto da fala. [ID:CAP1_001]
- Texto da opção (sem dois-pontos, senão vira nome de personagem) [ID:CAP1_OPCAO_A]
	$> Relacoes.ajustar("id_do_personagem", 1)
	$> Influencia.ajustar("id_da_casa", 1)
	Nicholas: Resposta. [ID:CAP1_002]
- Outra opção [ID:CAP1_OPCAO_B]
Nicholas: Toda escolha volta para a linha principal. [ID:CAP1_003]
=> END
```

- **Itens:** `$> Inventario.adicionar("id_do_item")`, `$> Inventario.remover("id_do_item")`, `$> Inventario.ganhar_dinheiro(10)` e `if Inventario.tem("id_do_item")`. Itens da história (tipo HISTORIA) só saem pelo roteiro; o jogador não consegue largá-los.
- **Retrato:** `[#retrato=expressao]`. Sem a etiqueta, usa `neutro`. Sem arte, aparece um quadro provisório com nome e expressão.
- **Quem fala** precisa estar no `Elenco` (`scripts/autoload/elenco.gd`), senão o quadro aparece em vermelho com "FORA DO ELENCO".
- **Escolhas não mudam o rumo:** toda opção volta para a mesma fala principal.
- **Tradução:** o texto em pt-BR fica no próprio `.dialogue` e é a base. `[ID:...]` é a chave fixa de cada fala (o editor de diálogo tem um comando para gerar IDs) e vira o contexto no POT. Para exportar, use *Projeto > Configurações > Localização > Modelo POT*. Textos de interface ficam em `i18n/strings.csv`.
- `##` antes de uma fala vira nota para quem for traduzir.

## Testes

No editor: painel GUT, botão *Run All*. Pela linha de comando:

```
godot --headless -s addons/gut/gut_cmdln.gd
```
