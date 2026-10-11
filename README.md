# Por Hélade

Jogo baseado no livro *Pelos Olhos Dele*, de Shara M. Schwartz. Contexto e decisões do projeto ficam no `CLAUDE.md`.

## Requisitos

- **Godot 4.7** (build padrão, não a .NET). O Dialogue Manager 4 exige Godot 4.6 ou mais novo e o GUT 9.7 é feito para o 4.7.

## Rodar

Abra a pasta no Godot e aperte F5. Por enquanto a cena principal é a tela de teste do diálogo (`cenas/teste_dialogo.tscn`).

## Pastas

| Pasta | O que tem |
| --- | --- |
| `dialogos/` | Cenas de roteiro em `.dialogue`, uma pasta por capítulo |
| `dados/personagens/` | Um `.tres` por personagem (nome no roteiro e retratos por expressão) |
| `scripts/estado/` | `Relacoes`, `Influencia` e `Elenco` (autoloads) |
| `ui/dialogo/` | Caixa de diálogo com retrato e escolhas |
| `cenas/` | Cenas do jogo |
| `tests/` | Testes GUT |
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

- **Retrato:** `[#retrato=expressao]`. Sem a etiqueta, usa `neutro`. Sem arte, aparece um quadro provisório com nome e expressão.
- **Quem fala** precisa estar no `Elenco` (`scripts/estado/elenco.gd`), senão o quadro aparece em vermelho com "FORA DO ELENCO".
- **Escolhas não mudam o rumo:** toda opção volta para a mesma fala principal.
- **Tradução:** o texto em pt-BR fica no `.dialogue`; `[ID:...]` é a chave fixa de cada fala. O editor de diálogo tem um comando para gerar IDs. Para exportar, use *Projeto > Configurações > Localização > Modelo POT*.
- `##` antes de uma fala vira nota para quem for traduzir.

## Testes

No editor: painel GUT, botão *Run All*. Pela linha de comando:

```
godot --headless -s addons/gut/gut_cmdln.gd
```
