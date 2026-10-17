# Por Hélade — contexto do projeto

Jogo baseado no livro **"Pelos Olhos Dele"**, de Shara M. Schwartz (publicado na Amazon, 2026).
O jogo é uma **segunda forma de percorrer a história**: começa e termina como o livro, do prólogo ao final, de forma fiel.

- **Título:** Por Hélade (em inglês: *For Hélade*)
- **Nome técnico** (pastas, arquivos, identificadores): `helade` — sem acentos em nada técnico

## Decisões já tomadas

### Gênero e estilo
- **Estilo principal:** RPG narrativo de exploração com câmera **isométrica** (visão de cima, inspirada em Diablo), focado em diálogo, relações e intriga política, **com combate em tempo real** (decisão do Rafael, 13/10/2026; plano em `planos/combate.md`).
- **Trocas de perspectiva só em momentos-chave e curtos**, sempre motivadas pela história (o título pede: "pelos olhos dele"):
  - **Prólogo em primeira pessoa:** o jogador é Nicholas aos 5 anos, na noite do nascimento de Althea no Castelo Olympia. Curto, sem combate, foco em impacto.
  - **Memórias e lendas em plataforma 2D:** lembranças de Nicholas ou a lenda do Ano Dourado, em fases curtas.
  - **Prequel de estratégia** (modo extra, futuro): a guerra entre os três reinos antigos (Khronosses, Ágape, Olympia), no estilo Age of Empires.
- **Regra de escopo:** um estilo principal. Cada mudança de estilo custa quase um jogo novo, então só entra se a história justificar e se a base já estiver funcionando.

### Inspirações e o que cada uma traz
- **Diablo:** câmera isométrica, exploração de ambientes, atmosfera mais sombria.
- **Super Mario World:** mapa de Hélade como tela de viagem entre regiões e capítulos, liberando lugares com o avanço.
- **Age of Empires:** sistema de **influência com as casas nobres**; prequel de estratégia.
- **A Lenda do Herói:** a história contada *pelo próprio jogo* (cenário, música, ritmo), não por cima dele.
- **LittleBigPlanet:** sequências curtas de variação (poderes de Apolo, momentos com outros Abençoados).
- Referência moderna próxima: **Fire Emblem: Three Houses** (jovens nobres de casas diferentes, política, romance).

### Narrativa
- História principal **fiel ao livro**; o final não muda.
- Escolhas do jogador só em momentos pontuais (o que Nicholas diz, quem procura). Elas afetam relações e influência, nunca o rumo principal.
- **Sem narração falada.** Texto com retratos dos personagens, música e som ambiente.
- **Conflitos:** debates na corte e embates políticos continuam como "duelos" de argumentos. Combate (tempo real, como Diablo) é para estradas, mar, ruínas e as lutas do livro; não muda o rumo da história.
- **Itens de combate:** cada arma e proteção é um `.tres` em `data/itens/` com bônus de ataque, defesa e velocidade. Todo item gasta exatamente o orçamento de pontos do `Balanceamento` (`scripts/systems/balanceamento.gd`); um teste GUT confere todos.
- **Códice** desbloqueável: Abençoados, casas, regiões, lenda do Ano Dourado. Pode ter conteúdo inédito da autora.

### Plataforma e tecnologia
- **Engine:** Godot 4 (build padrão, **não** a .NET).
- **Linguagem:** GDScript.
- **Plataforma:** PC primeiro (para testar); celular (Android) depois.
- Controle no PC por **teclado** (WASD/setas, Enter para interagir). **Clicar no chão para andar foi removido** (decisão de 14/10/2026: ficou ruim); o controle do celular será outro, decidido depois. A interface continua pensada para toque (botões grandes, sem depender de hover).
- Testes de lógica com **GUT** ou **gdUnit4** (influência, save/load, progressão).
- Versionamento com **git**, com commits pequenos.
- **Roteiro e diálogo:** arquivos `.dialogue` do plugin **Dialogue Manager** em `data/dialogos/`, com pt-BR no próprio arquivo e `[ID:...]` fixo por fala para tradução (POT/PO). Retrato por etiqueta `[#retrato=expressao]`; escolhas chamam `Relacoes.ajustar(...)` e `Influencia.ajustar(...)` e sempre voltam para a linha principal. Detalhes no README.

### Visual
- Mesmo estilo da capa do livro: fantasia clássica, tons noturnos com dourado, castelos à beira-mar, lua.
- Marca visual: **olhos azuis claros com um anel dourado na íris**, característica dos Abençoados.
- A arte vem de fora (desenho ou geração em outra ferramenta). Até lá, usar placeholders simples e claramente provisórios.

## Universo (o que se sabe até agora, pela amostra)

- **Império de Hélade**, formado pela união de três reinos antigos há 2.000 anos:
  - **Khronosses** (Norte, montanhas): racional, letrado, deusa regente Atena. Rainha antiga: Lógos.
  - **Ágape** (Leste): mercantil, artístico, águas quentes que brilham à noite, deus regente Poseidon. Princesa antiga: Epithymía.
  - **Olympia** (Sul, costa gélida): guerreiro e disciplinado. Rei antigo: Thymós.
- **Ano Dourado:** nasceram 12 crianças com olhos de anel dourado e poderes sobre-humanos, os **Abençoados**. Isso trouxe uma trégua milenar, e a capital **Atenas** foi fundada para educá-los. Um **Ciclo** equivale a 100 anos. A história acontece no **20º Ciclo**.
- **Mapa:** Norte (antiga Khronosses), Templo, Atenas, Ágape, Floresta das Ninfas, Olympia.
- **Abençoados conhecidos** (7 dos 12):
  - Nicholas Olympia (Apolo) — **protagonista e narrador**, herdeiro da Casa Olympia
  - Ophelia Hélade (Zeus) — princesa legítima
  - Tahy Cetus (Poseidon) — herdeiro da Casa Cetus
  - Persephone Flóga (Ares) — Casa Flóga
  - Dallan Apóleia (Hades)
  - Icarus Yiannis (Hermes) — herdeiro da Casa Yiannis
  - Kassiani Ágape (Afrodite) — Casa Ágape
- **Casas:**
  - Hélade (imperial, Atenas): Imperador Varsélios, Ophelia, Tristan (príncipe), Tichy de Prodosia (concubina)
  - Yiannis (marquesado, Atenas): Dédalo (marquês), Icarus
  - Flóga (marquesado, Atenas): Sylas (general do Império), Persephone
  - Olympia (ducado, Sul): Apollon (duque, conselheiro do Imperador), Danica (duquesa atual), Nicholas, Althea
  - Cetus (marquesado, Olympia): Llyr, Límni Kýma, Nerya (capitã de frota), Tahy
  - Ágape (ducado, Leste): Nátrio, Dalyma, Kassiani
  - Outros: Dorian Fowler (herdeiro de baronato), Clímede (ninfa da Floresta das Ninfas), Janet (babá de Nicholas)
- **Prólogo:** Castelo Olympia, início da primavera do 6º ano do 20º Ciclo. Nicholas, com 5 anos, presencia a morte da mãe, a duquesa Neola, no parto de Althea. O pai está em Atenas. Nicholas é o primeiro a segurar e nomear a irmã. Termina com: *"Por Hélade. Pelo Ano Dourado. Nicholas, um verdadeiro Filho dos Deuses."*

Ao receber o livro completo, acrescentar aqui o **mapa de capítulos** (o que cada parte vira no jogo).

## Como trabalhar neste projeto

- **Uma funcionalidade por vez.** Implementar, eu testo no editor, ajustar e só então seguir.
- Antes de um sistema novo, propor um plano curto e esperar aprovação.
- Não dá para ver o jogo rodando: quando algo for visual ou de "sensação", pedir que eu teste e descreva ou mande print.
- Fidelidade ao livro é prioridade: **nunca inventar** nomes, fatos, relações ou eventos de lore. Na dúvida, perguntar.
- Textos do jogo em **português do Brasil**, já preparados para tradução (strings externas, não fixas no código).
- Primeiro marco: **fatia vertical do prólogo** jogável do começo ao fim.

## Itens em aberto

- Receber o livro completo (.txt) e montar o mapa de capítulos
- Definir a origem da arte e o estilo final dos retratos
- Validar o conceito com a autora (incluindo o que pode aparecer sem spoilers)
