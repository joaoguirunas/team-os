---
name: book-editing
description: "Método de edição e revisão de livro — três níveis na ordem (estrutural, linha, revisão), carta editorial por capítulo, edição de linha que preserva a voz do autor, revisão pelo Acordo Ortográfico, folha de estilo e glossário como fonte única, citações e referências ABNT, continuidade em ficção e checklist do G2. Use ao editar, revisar ou aprovar um capítulo antes da diagramação."
version: "1.0"
updated: "2026-11-17"
---

# Book Editing — estrutura antes da vírgula

PERKINS (book-editor) faz a edição estrutural e a de linha; HOUAISS (book-proofreader) faz a revisão e mantém a folha de estilo. Os dois trabalham sobre `manuscrito/CAP-NN-<slug>.md` e nunca reescrevem o livro no lugar do autor: **o editor sugere, o autor decide.** Nenhuma frase nova entra como se fosse do autor sem aprovação dele (piso 5 do G2).

## 1. Os três níveis e a ordem

| Nível | Quem | Pergunta | Unidade | Saída |
|---|---|---|---|---|
| 1. Estrutural | PERKINS | O capítulo cumpre o objetivo do `outline.md`? A ordem convence? | capítulo e livro | `editing/CAP-NN-carta.md` |
| 2. Linha | PERKINS | Cada parágrafo diz o que quer com o menor número de palavras, na voz do autor? | parágrafo e frase | sugestões marcadas no arquivo do capítulo |
| 3. Revisão (copidesque + prova) | HOUAISS | Está correto e consistente com a folha de estilo? | palavra e sinal | correções + `copyedit/style-sheet.md` atualizada |

Regra da ordem: **nunca revisar vírgula de capítulo que ainda vai mudar de estrutura.** Um capítulo só desce de nível quando o anterior fechou e o autor aprovou. Mudança de estrutura depois da revisão (mover seção, cortar capítulo, trocar a ordem) volta ao nível 1 e precisa de decisão `D-NN` de CAMPBELL; a revisão daquele trecho é refeita.

## 2. Edição estrutural — o que PERKINS lê

Leia o capítulo inteiro uma vez sem marcar nada. Depois responda, com trecho como evidência:

- [ ] **Objetivo:** o capítulo entrega o objetivo escrito para ele no `outline.md`? Em uma frase, o que o leitor sabe ou faz ao terminar?
- [ ] **Promessa:** conversa com a promessa do `concept.md` ou é desvio?
- [ ] **Abertura:** as primeiras 2 páginas dizem por que este capítulo importa para o leitor do `concept.md`?
- [ ] **Sequência:** cada seção depende da anterior? Há conceito usado antes de ser explicado?
- [ ] **Prova:** cada afirmação forte tem caso do autor, dado `F-NN` ou exemplo? Sem prova vira `[PERGUNTA AO AUTOR: …]`.
- [ ] **Repetição entre capítulos:** a mesma história ou o mesmo argumento já apareceu em outro `CAP-NN`?
- [ ] **Tamanho:** palavras reais contra tamanho-alvo do `outline.md`. Desvio acima de 20% entra na carta.
- [ ] **Fecho:** o capítulo termina com síntese, aplicação ou ponte para o próximo — não para no meio.

Em não ficção de método, cheque se o método tem passos nomeados e na mesma ordem em todo o livro (o passo 3 do CAP-04 não pode virar passo 2 no CAP-09).

## 3. Carta editorial — `editing/CAP-NN-carta.md`

Uma por capítulo, por rodada. Curta: o autor precisa ler em 10 minutos.

```markdown
# CAP-07 — carta editorial · rodada 1 · 2026-11-17
## O que funciona (manter)
- A história da primeira demissão (p. 3) prova o argumento melhor que qualquer dado.
## O que não funciona
- O conceito de "margem de contribuição" é usado na seção 2 e só explicado na seção 4.
## O que mudar (proposta — o autor decide)
| # | Prioridade | Trecho | Proposta | Por quê |
| 1 | ALTA | seções 2 e 4 | inverter a ordem | conceito antes do uso |
| 2 | MÉDIA | p. 6–7 | cortar a lista de 9 ferramentas ou levar para anexo | quebra o ritmo |
| 3 | BAIXA | título | "Quanto sobra" no lugar de "Análise financeira" | promessa concreta |
## Perguntas ao autor
- [PERGUNTA AO AUTOR: qual era o faturamento da empresa em 2019? O texto diz "alto".]
## Tamanho: 6.800 palavras · alvo 5.000 (+36%)
```

Prioridade: **ALTA** impede o capítulo de cumprir o objetivo; **MÉDIA** atrapalha o leitor; **BAIXA** é gosto e pode ser recusada sem discussão.

## 4. Edição de linha — cortar sem apagar o autor

Antes de editar, leia `manuscript/voice-profile.md`. A voz do autor vence a preferência do editor: se ele escreve frases longas e coloquiais, a edição deixa as frases longas mais claras, não curtas.

| Lente | O que procurar | Exemplo |
|---|---|---|
| Corte | muleta e redundância | "com o objetivo de" → "para"; "nos dias de hoje" → "hoje"; "elo de ligação" → "elo" |
| Clareza | sujeito escondido, pronome ambíguo, abstração | "Existem muitos motivos para o cliente sair" → "O cliente sai por muitos motivos" |
| Ritmo | 4 frases seguidas do mesmo tamanho ou com a mesma abertura | alternar uma curta depois de duas longas |
| Repetição | mesma palavra forte em 3 linhas; mesmo bordão no capítulo | trocar só se o sinônimo existir na voz do autor |
| Precisão | adjetivo no lugar de número ou fato | "cresceu muito" → `[PERGUNTA AO AUTOR: quanto?]` |
| Cara de IA | tiques de texto gerado | aplicar `/copy-humanize` |

Como marcar no Markdown (o autor aceita ou recusa cada uma):

```markdown
O time {--basicamente--} entregou o projeto {~~com o objetivo de~>para~~} fechar o trimestre.
{>>PERKINS: a frase seguinte repete "entregou" — sugiro "concluiu"?<<}
```

Limite por rodada: se a edição de linha muda mais de ~30% das frases de um parágrafo, pare e mande para a carta como problema estrutural ou de voz — reescrita é trabalho do MACHADO com o autor.

## 5. Revisão — o que HOUAISS corrige

Referência de grafia: Acordo Ortográfico de 1990 (Decreto 6.583/2008, obrigatório no Brasil desde 1º/1/2016) e o VOLP da Academia Brasileira de Letras. Dúvida de grafia: o VOLP decide, e a decisão vai para a folha de estilo.

- [ ] **Acordo:** sem trema (frequente), sem acento em ditongo aberto de paroxítona (ideia, assembleia), sem acento diferencial abolido (para, pelo); hífen: "autoestima", "antissocial", "micro-ondas", "dia a dia".
- [ ] **Concordância:** verbal com sujeito posposto ("Faltam três etapas"), "haver" impessoal ("Havia problemas"), "fazer" de tempo ("Faz dez anos"), nominal com "meio", "anexo", "obrigado".
- [ ] **Crase:** antes de feminino que aceita artigo ("à empresa", "às 14h"); nunca antes de masculino, verbo ou pronome pessoal ("a partir de", "a ela"); facultativa antes de possessivo feminino — escolha registrada na folha.
- [ ] **Numerais:** padrão da casa (sugestão: zero a dez por extenso, 11 em diante em algarismo; nunca começar frase com algarismo; porcentagem sempre em algarismo — "7%"; valores "R$ 1.200,00"; anos "2026", décadas "anos 1990").
- [ ] **Maiúsculas:** cargos em minúscula ("o diretor financeiro"), nomes de instituições com maiúscula, meses e dias em minúscula; títulos de livro citados no texto em itálico com só a primeira palavra e nomes próprios em maiúscula (padrão ABNT) ou como a folha definir.
- [ ] **Itálico:** estrangeirismo não aportuguesado (*feedback*, *startup* — ou a folha decide que são de uso corrente e vão em redondo), título de obra, termo em destaque na primeira ocorrência. Nunca itálico e aspas juntos.
- [ ] **Diálogo:** travessão (—), não hífen nem meia-risca; fala em parágrafo próprio; "— Vamos — disse ela. — Agora." Fala dentro de não ficção, se for citação literal de entrevista, entre aspas e com fonte.
- [ ] **Aspas:** curvas ("…"), aspas simples dentro de aspas; pontuação final fora das aspas quando a citação é parte da frase.
- [ ] **Sinais:** reticências como um caractere (…), sem espaço antes de dois-pontos, ponto e vírgula, ponto de exclamação ou interrogação.

## 6. Folha de estilo e glossário — fonte única

`copyedit/style-sheet.md` é a única fonte de consistência do livro. Toda decisão tomada em um capítulo vale para todos. HOUAISS cria a folha no CAP-01 e só acrescenta.

```markdown
## Decisões gerais
| Item | Decisão | Desde |
| Numerais | zero a dez por extenso | CAP-01 |
| Crase antes de possessivo | sem crase ("a sua empresa") | CAP-02 |
| feedback, startup, CEO | redondo (uso corrente) | CAP-01 |
## Glossário (termos do método e nomes próprios)
| Termo | Grafia | Definição curta | 1ª ocorrência |
| Ciclo de Caixa Curto | sempre com maiúsculas, sem sigla | … | CAP-03 |
| Ana Ribeiro | (cliente, nome trocado a pedido) | … | CAP-05 |
```

Antes de entregar cada capítulo: buscar no arquivo cada termo do glossário e cada variante errada (`grep -n -i "ciclo de caixa" manuscrito/*.md`). Variante fora da folha é erro, não estilo.

## 7. Citações e referências

- **Citação curta** (até 3 linhas): entre aspas, no corpo do texto, com autor, ano e página.
- **Citação longa** (mais de 3 linhas): parágrafo recuado (recomendação da ABNT NBR 10520:2023: 4 cm à esquerda), fonte menor, sem aspas.
- **Chamada no texto** (autor-data, NBR 10520:2023): "(Ribeiro, 2019, p. 42)" — só a inicial maiúscula na chamada. Em livro comercial, a casa pode usar nota de rodapé ou notas no fim do livro; a escolha vai para a folha de estilo e vale para o livro todo.
- **Referências** (ABNT NBR 6023:2018): SOBRENOME, Nome. *Título*: subtítulo. Edição. Local: Editora, ano. Exemplo: RIBEIRO, Ana. *Caixa primeiro*: finanças para quem empreende. 2. ed. São Paulo: Exemplo, 2019. Página web: … Disponível em: URL. Acesso em: 17 nov. 2026.
- Toda citação e todo número em não ficção precisa de `F-NN` com status `verificado` em `research/facts.md`. Sem isso, FAIL no G2 (piso 2).
- **Limite legal:** citação de terceiro só "na medida justificada para o fim a atingir", com autor e origem (Lei 9.610/98, art. 46, III). Epígrafe de música, poema inteiro, trecho longo de livro: só com permissão escrita registrada por HYPATIA. Sem ela, corte ou paráfrase com crédito (piso 1).

## 8. Em ficção — continuidade

Em romance e contos a revisão estrutural muda de foco (cena, ponto de vista, arco, tensão), e HOUAISS mantém uma **bíblia de continuidade** dentro da folha de estilo:

| Categoria | O que registrar | Erro típico |
|---|---|---|
| Personagens | nome, apelido, idade, aparência, cor dos olhos, relações | Clara tem olhos verdes no CAP-02 e castanhos no CAP-11 |
| Linha do tempo | data ou dia relativo de cada cena | a viagem dura 3 dias, mas é "na mesma noite" |
| Lugares | nomes, distâncias, disposição da casa | a cozinha muda de andar |
| Objetos e fatos | quem sabe o quê e desde quando | personagem cita segredo que só ouviu depois |
| Ponto de vista | narrador por capítulo, tempo verbal | troca de passado para presente sem motivo |

Diálogo em ficção segue o §5 (travessão). Gíria e erro gramatical **na fala** de personagem são voz — marque como `[intencional]` na folha para ninguém corrigir.

## 9. Checklist do G2 — antes de o capítulo ir para a diagramação

BORGES só abre o G2 com estes itens marcados por PERKINS e HOUAISS:

- [ ] Carta editorial da última rodada sem item ALTA aberto
- [ ] Autor aprovou o capítulo (registro com data em `editing/CAP-NN-carta.md`)
- [ ] Zero `[PERGUNTA AO AUTOR` no arquivo (`grep -c "PERGUNTA AO AUTOR" manuscrito/CAP-NN-*.md` = 0)
- [ ] Zero marca de edição pendente (`{++`, `{--`, `{~~`, `{>>` ausentes)
- [ ] Todo fato, número e citação com `F-NN` verificado
- [ ] Citações de terceiros dentro do art. 46, III ou com permissão registrada
- [ ] Termos e grafias batem com a folha de estilo e o glossário
- [ ] Nenhuma afirmação sobre pessoa real identificável que possa difamar (piso 4); na dúvida, nome trocado com aviso ou corte
- [ ] Ficção: bíblia de continuidade atualizada até este capítulo

## 10. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "Já que estou aqui, corrijo a vírgula também." | Se a estrutura muda, a vírgula some junto. Revisão só depois da estrutura aprovada. |
| "Ficou melhor do meu jeito." | O livro é do autor. Sugestão marcada; o autor decide. |
| "O autor disse algo parecido na entrevista, posso completar." | Só com a transcrição como fonte. Sem ela, `[PERGUNTA AO AUTOR]`. |
| "Todo mundo escreve *feedback* assim." | Vale o que está na folha de estilo; se não está, decida e registre. |
| "É só uma epígrafe de música." | Letra de música é obra protegida. Sem permissão escrita, não entra. |

## Origem

Lentes da edição de linha (clareza, corte, jargão, voz ativa) adaptadas (reescritas em pt-BR, sem copiar texto) de robertguss/claude-code-toolkit, `plugins/compound-writing/agents/clarity-editor.md` (MIT, © 2025-2026 Robert Guss, commit f7fd35e). Regras de língua e norma: Decreto 6.583/2008; ABNT NBR 6023:2018 e NBR 10520:2023; Lei 9.610/98, art. 46, III (planalto.gov.br) — conferidos em 17/11/2026.
