---
name: book-concept-outline
description: "Método do conceito e do sumário de um livro — leitor específico e problema, promessa e transformação, tese e ângulo do autor, posicionamento contra comparáveis, testes de título, sumário com CAP-NN, objetivo e tamanho-alvo, plano por etapas em stories e checklist do G1; em ficção, premissa, personagens, arco e bíblia. Use ao idear um livro, escrever concept.md e outline.md ou mudar a estrutura."
version: "1.1"
updated: "2026-11-17"
---

# Book Concept & Outline — o livro antes da primeira página

Livro que começa pela escrita costuma virar coletânea de posts: capítulos bons que não levam o leitor a lugar nenhum. Esta skill fixa, antes de qualquer capítulo, **para quem é, o que muda na vida dessa pessoa e em que ordem**. Tudo aqui vira dois arquivos em `docs/smart-memory/agents/book/architecture/`: `concept.md` e `outline.md`. Decisões de estrutura vão para `decisions.md` como `D-NN`.

Regra de base: o conceito sai **das respostas do autor**. O agente propõe, compara e testa; não inventa a história, o método nem os resultados dele. O que faltar vira `[PERGUNTA AO AUTOR: …]`.

## 1. Entrevista de conceito — o que perguntar ao autor

Faça em blocos curtos, uma rodada por vez. Grave as respostas literais em `concept.md` (seção "Respostas do autor").

| Bloco | Perguntas |
|---|---|
| Intenção | Por que este livro agora? O livro existe para gerar autoridade, vender mentoria, registrar legado, ganhar com venda ou servir quem já te segue? |
| Leitor | Quem é a pessoa que mais precisa disto? O que ela já tentou? O que ela pesquisa no Google na noite em que o problema aperta? |
| Matéria-prima | Que material já existe: aulas, posts, palestras, áudios, apostilas, casos? Onde está? |
| Método | Você tem um passo a passo que aplica com clientes? Tem nome? Quantas etapas? |
| Limites | Que histórias e nomes não podem aparecer? Tem cliente que não autorizou ser citado? |

A intenção muda a leitura de tudo depois: um livro de autoridade aceita nicho pequeno; um livro para vender precisa de categoria com demanda (§5).

## 2. Leitor específico e problema

"Empreendedores" não é leitor. Leitor é uma pessoa que dá para descrever numa frase com situação, dor e gatilho.

- [ ] **Situação:** "dono de clínica com 3 a 10 funcionários que ainda atende e gerencia ao mesmo tempo"
- [ ] **Dor nomeada nas palavras dele:** "eu sou o gargalo da minha empresa"
- [ ] **O que já tentou e falhou:** curso de gestão, contratar gerente, planilha
- [ ] **Crença que atrapalha:** "se eu largar, cai a qualidade"
- [ ] **Gatilho de compra:** a semana em que tirou férias e o faturamento caiu
- [ ] **Leitor secundário** (se houver) e o que ele precisa a mais — no máximo um

Teste: se o autor não consegue citar três pessoas reais que se encaixam, o leitor está largo demais.

## 3. Promessa e transformação

A promessa é o contrato. Escreva o leitor no ponto A e no ponto B com **verbos**:

| Ponto A (antes) | Ponto B (depois) |
|---|---|
| Resolve tudo pessoalmente | Delega com rotina semanal de 1 hora |
| Acredita que contratar resolve | Sabe documentar o processo antes de contratar |
| Não sabe a margem por serviço | Calcula a margem e corta o serviço que dá prejuízo |

Frase de promessa: **"Este livro ajuda [leitor] a [resultado B] por meio de [método], sem [o custo que ele teme]."** Uma frase só. Se precisar de duas, há dois livros escondidos num.

Sinais de alerta: o ponto B descreve só informação ("vai entender gestão"); a promessa depende de número que o autor não comprova (vai para HYPATIA como fato `F-NN` ou sai).

## 4. Tese e ângulo do autor

- **Tese:** uma afirmação com que alguém pode discordar. Modelo: "A maioria acredita que [senso comum]; na prática [tese], porque [o que o autor viu]." Se ninguém discorda, o que você tem é um tema, e tema não sustenta um livro.
- **Ângulo:** por que este autor. Experiência vivida, prática com clientes, acesso a dados ou um jeito próprio de enxergar. Registre a prova de cada um (anos, número de clientes, cargo) **só com o que o autor informou**.
- **Inimigo:** a prática, crença ou indústria contra a qual o livro se posiciona. Concreto ("planilha de metas copiada de multinacional"), nunca uma pessoa identificável.

## 5. Posicionamento contra comparáveis

CARNEGIE (book-market) entrega `market/comps.md` com 5–8 livros e o relatório de mercado — demanda por categoria, palavras do leitor, tendências e posições possíveis (método em `/book-market-research`). Com ele, CAMPBELL escreve no `concept.md`:

1. **Prateleira:** categoria da livraria e duas categorias da Amazon onde o livro mora.
2. **O que os comparáveis prometem** (uma linha cada) e **o que os leitores reclamam** nas avaliações.
3. **Diferença:** "Ao contrário de [comp], este livro [diferença verificável]." Diferença verificável = público, método, formato, profundidade ou contexto brasileiro. "Mais prático" não conta.
4. **Livro-âncora para o leitor:** "é o [comp A] para [leitor específico]" — útil no pitch, nunca na capa.

## 6. Título e subtítulo — testes

Proponha 5–10 combinações, rode os testes e leve as 3 melhores ao autor. O título final é decisão do autor e vira `D-NN`.

| Teste | Passa quando |
|---|---|
| Dizível | Dá para falar numa conversa sem soletrar nem explicar |
| Buscável | O subtítulo contém as palavras que o leitor digita (ver palavras da §2) |
| Promessa | Título + subtítulo juntos deixam claro o ponto B |
| Distinto | Nenhum livro da mesma categoria com título igual ou quase igual (busca na Amazon e no catálogo da CBL) |
| Curto | Título com até ~5 palavras; subtítulo com até ~15 |
| Miniatura | Lido em 2 segundos numa capa do tamanho de um polegar (confirmar com MUNARI) |
| Honesto | Não promete o que o livro não entrega |

Exemplo: título "Fora do Balcão"; subtítulo "Como donos de clínica saem da operação em 12 semanas sem perder a qualidade do atendimento". O "12 semanas" só fica se o método do autor tiver esse prazo.

## 7. Sumário com `CAP-NN`

`outline.md` tem uma linha por capítulo, numeração fixa (`CAP-01`, `CAP-02`…). O id nunca muda depois de criado; se um capítulo sai, o id fica marcado como removido. Arquivo do capítulo: `manuscrito/CAP-NN-<slug>.md` na raiz do projeto.

| Id | Título de trabalho | Objetivo (o leitor sai…) | Entra sabendo | Sai sabendo / fazendo | Material do autor | Alvo (palavras) |
|---|---|---|---|---|---|---|
| CAP-01 | O dono gargalo | …reconhecendo o próprio padrão | Sente o caos | Nomeia as 3 tarefas que só ele faz | Áudio 03, post de 12/03 | 3.500 |
| CAP-02 | Por que contratar não resolve | …desistindo do atalho | Acha que falta gente | Entende que falta processo escrito | Aula 2 do curso | 4.000 |

Faixas de referência para não ficção de negócio no Brasil (ajuste ao comparável):

| Formato | Livro inteiro | Capítulo |
|---|---|---|
| Livro curto / guia | 20–30 mil palavras | 2.000–3.500 |
| Negócio / método padrão | 40–60 mil palavras | 3.500–6.000 |
| Memória profissional | 50–80 mil palavras | 3.000–6.000 |

Conversão em páginas só depois do teste de diagramação com GARAMOND (depende de formato, fonte e entrelinha). Não prometa número de páginas ao autor antes disso.

Estruturas que funcionam em não ficção:
- **Problema → causa → método → aplicação → manutenção** (padrão para método)
- **Um capítulo por etapa do método** (quando o método tem 5–9 passos)
- **Partes I/II/III** quando o livro tem mais de 12 capítulos: por exemplo "Entender", "Fazer", "Sustentar"
- **Cronológica** para memórias profissionais, com uma lição explícita por capítulo

Cada capítulo termina puxando o próximo: a saída do `CAP-NN` é a entrada do seguinte. Se dois capítulos têm a mesma saída, junte; se um capítulo tem três saídas, divida.

## 8. Plano por etapas e stories

Depois do G1, CAMPBELL cria as stories em `stories/backlog/`. Uma story por entrega verificável:

1. **Pesquisa por capítulo** (HYPATIA): fatos `F-NN` necessários e entrevistas a transcrever.
2. **Perfil de voz** (MACHADO): uma story, antes do primeiro capítulo.
3. **Capítulo `CAP-NN`**: redação → aprovação do autor → edição (PERKINS) → revisão (HOUAISS) → G2. Uma story por capítulo, critério de aceite = checklist do G2.
4. **Capa, ilustrações, diagramação, publicação**: uma story cada, depois do G2 dos capítulos.

Ordem: escreva primeiro o capítulo com mais material do autor (ganha ritmo e calibra a voz), depois a introdução, por último a conclusão. Mudança de estrutura depois do G1 só com `D-NN` e aviso a quem tem capítulo em andamento.

## 9. Checklist do G1 (o que BORGES confere)

- [ ] Leitor descrito com situação, dor, tentativas, crença e gatilho (§2)
- [ ] Promessa em uma frase, ponto A e ponto B com verbos (§3)
- [ ] Tese discutível e ângulo do autor com provas dadas por ele (§4)
- [ ] Relatório de mercado de CARNEGIE (`market/market-report.md`) com `comps.md` de 5–8 comparáveis, demanda da categoria com data e a diferença verificável (§5)
- [ ] Título e subtítulo aprovados pelo autor, testes rodados, registrados como `D-NN` (§6)
- [ ] `outline.md` com todos os `CAP-NN`, objetivo, entrada/saída, material de origem e alvo em palavras (§7)
- [ ] Nenhum capítulo sem material do autor indicado, ou com `[PERGUNTA AO AUTOR]` registrada
- [ ] Stories criadas com critério de aceite (§8)

## 10. Em ficção

O conceito vira **bíblia da história** (`architecture/concept.md` + `architecture/bible.md`):

- **Premissa (logline):** personagem + desejo + obstáculo + o que está em jogo, em até 35 palavras.
- **Personagens:** para o protagonista, desejo (o que quer), necessidade (o que precisa aprender), ferida (o passado que o trava) e arco (de onde a onde). Antagonista com motivação própria. Coadjuvantes com função na trama.
- **Estrutura em atos:** três atos com os pontos de virada marcados (incidente, virada do ato 1, ponto médio, crise, clímax, resolução). O sumário lista capítulos com PDV, cena principal e o que muda.
- **Mundo e regras:** época, lugar, o que é possível ali; linha do tempo para continuidade.
- **Comparáveis:** os mesmos 5–8, focando gênero, tamanho (romance adulto costuma ficar entre 60 e 100 mil palavras) e o que os leitores do gênero esperam.

## 11. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "O livro é para todo mundo que empreende" | Quem não se reconhece na página 1 não compra. Leitor específico vende mais, inclusive para quem está ao lado dele. |
| "O sumário a gente descobre escrevendo" | Descobre reescrevendo. Capítulo sem objetivo vira retrabalho na edição. |
| "Coloca 'best-seller' na ideia do título" | Título promete o que o livro entrega; selo de vendas exige número real. |
| "Inventa um caso para ilustrar a tese" | Caso inventado apresentado como real derruba o livro (piso 2 e 5 do G2). Pergunte ao autor. |
| "Depois a gente vê o tamanho" | Tamanho define preço, lombada e custo de impressão. Alvo por capítulo agora, ajuste depois. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de rhavekost/author-toolkit (MIT, © 2026 rhavekost, commit b5e15ef) — skills `narrative-nonfiction` (promessa, jornada do leitor antes/depois) e `fiction-workshop` (bíblia da história: desejo, necessidade, ferida, arco). Faixas de tamanho são referência de mercado; confira sempre contra os comparáveis do próprio livro.
