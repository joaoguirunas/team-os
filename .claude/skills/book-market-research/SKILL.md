---
name: book-market-research
description: "Método de inteligência de mercado editorial — intenção do livro, demanda e concorrência por categoria na Amazon (ranking com data, vendas só em faixa estimada), palavras do leitor, tendências e BookTok, coleta com Apify sob custo aprovado, mineração de avaliações, padrão dos líderes, 2–3 posições, validação e relatório com M-NN. Use antes do conceito e ao escolher categorias e palavras-chave."
version: "1.0"
updated: "2026-11-17"
---

# Book Market Research — quem compra, antes de escrever

Livro leva meses para ficar pronto e anos na prateleira. Esta skill é o método de CARNEGIE para descobrir, antes do conceito fechar, **onde há leitor que paga, o que ele digita, do que reclama e que buraco a prateleira deixa**. Tudo fica em `docs/smart-memory/agents/book/market/`. CARNEGIE entrega evidência e 2–3 posições possíveis; CAMPBELL e o autor decidem (`/book-concept-outline` §5).

Divisão com HYPATIA: sinal de mercado (`M-NN`) é de CARNEGIE; fato que vai dentro do livro (`F-NN`) é dela (`/book-research-sources`). Um número de mercado só vira fato do livro se HYPATIA verificar na fonte primária.

Referências — leia quando chegar na etapa:
- `references/amazon-categorias.md` — ranking, tabela de estimativa de vendas, leitura de categoria, Kindle Unlimited, padrão dos líderes (§3, §8)
- `references/palavras-tendencias.md` — sugestões de busca letra a letra, Google Trends, as 7 palavras do KDP, listas de mais vendidos, BookTok, ficção (§4, §5, §12)
- `references/coleta-avaliacoes.md` — Apify passo a passo e mineração de 200–500 avaliações (§6, §7)
- `references/validacao-relatorio.md` — roteiros de validação e o modelo do `market-report.md` (§10, §11)

## 1. Pergunta de mercado — antes de abrir a Amazon

Pergunte ao autor (ou leia em `architecture/concept.md`, bloco Intenção) **para que o livro existe**. A resposta muda o peso de cada sinal:

| Intenção | O que pesa mais | O que pesa menos | Leitura de um mercado pequeno |
|---|---|---|---|
| Vender em escala | Demanda da categoria (ranking dos líderes), preço, KU, palavras com busca | Público atual do autor | Problema: troque de categoria ou de ângulo |
| Autoridade | Posição distinta, lacuna nas avaliações, qualidade dos comparáveis | Volume de vendas | Aceitável se a posição for clara e o autor for o melhor nela |
| Captar cliente | Leitor = cliente ideal do autor, linguagem da dor, validação com o público | Ranking geral | Aceitável; mede-se por contato gerado, não por cópia |
| Legado / memória | Comparáveis de memória profissional, formato | Quase tudo de demanda | Aceitável; avise o autor da expectativa realista |

Registre a intenção na 1ª linha do `market-report.md`. Sem ela, nenhuma recomendação sai.

## 2. Arquivos e banco `M-NN`

| Arquivo | Conteúdo |
|---|---|
| `signals.md` | Banco de sinais — todo número de mercado |
| `comps.md` | 5–8 comparáveis (dono: CARNEGIE) |
| `categories.md` | 3–5 categorias lidas (§3) |
| `keywords.md` | Lista de palavras do leitor e as 7 do KDP (§4) |
| `trends.md` | Temas em alta, com veredicto moda × tendência (§5) |
| `reviews.md` | Mineração de avaliações (§7) |
| `validation.md` | Testes com o público e resultado (§10) |
| `market-report.md` | Relatório para o G1 (§11) |

Formato do `signals.md`:

| Id | Sinal | Fonte | Data | Número | Confiança |
|---|---|---|---|---|---|
| M-07 | Ranking do 1º em "Gestão de pequenas empresas" (Kindle, .com.br) | amazon.com.br, página de Mais vendidos da categoria | 17/11/2026 14h | #312 na loja Kindle | alta (lido na página) |
| M-08 | Vendas estimadas do 1º | Tabela da calculadora X, convertida de M-07 | 17/11/2026 | 30–80 / dia (faixa) | baixa (estimativa de terceiro) |

Confiança: **alta** = lido direto na fonte, com print ou URL e hora · **média** = ferramenta de terceiro com método declarado, ou duas fontes que batem · **baixa** = estimativa, amostra pequena, uma fonte só. Id nunca é reaproveitado; sinal velho ganha linha nova com data nova.

## 3. Demanda e concorrência por categoria (Amazon .com.br e .com)

O ranking de mais vendidos (BSR) é a **posição relativa** do livro nas vendas recentes da loja e da categoria, por formato. Muda ao longo do dia. Nunca é contagem de vendas. Registre sempre: loja, formato, categoria, número, data e hora.

Leitura de uma categoria (detalhe e limiares em `references/amazon-categorias.md`):

- [ ] Ranking na loja do **1º, do 10º e do 20º** da lista de Mais vendidos da categoria, com hora
- [ ] Quantos dos 20 primeiros têm **menos de 100 avaliações** (sinal de concorrência fraca)
- [ ] **Idade** dos livros do topo (lançados nos últimos 12 meses entram? ou só clássicos?)
- [ ] **Preço** médio e faixa, e-book e impresso; quantos estão no **Kindle Unlimited**
- [ ] Conversão do ranking em vendas **só em faixa, como estimativa**, com a tabela usada e a data (`M-NN` com confiança baixa)

Categoria boa para quem quer vender: o 20º ainda tem ranking forte na loja (há demanda além do topo) e vários do top 20 têm poucas avaliações ou são recentes (dá para entrar). Categoria sem concorrência e sem ranking forte geralmente é categoria sem leitor.

## 4. Palavras do leitor

O leitor não digita o título do livro; ele digita o problema. Fontes, nesta ordem (passo a passo em `references/palavras-tendencias.md`):

1. **Busca da Amazon** (.com.br, departamento Livros e loja Kindle): a palavra-semente e depois letra a letra (`fluxo de caixa a`, `… b`…). Sugestão automática indica que alguém busca isso, sem dizer quanto.
2. **Google:** sugestões automáticas e o bloco "As pessoas também perguntam" — viram perguntas de capítulo.
3. **Google Trends** (Brasil, 5 anos): sazonalidade e comparação entre termos (escala relativa 0–100, não volume).
4. **YouTube:** sugestões da busca e títulos dos vídeos com mais visualizações no tema.

Saída em `keywords.md`: tabela palavra · onde apareceu · data · uso (título, subtítulo, descrição, palavra-chave do KDP). Dela sai a proposta das **7 palavras-chave do KDP**, entregue a LOBATO, que aplica as regras do cadastro (`/book-publishing` §8).

## 5. Tendências e temas virais

Fontes: listas de mais vendidos (PublishNews/Nielsen, Amazon Mais vendidos, Mais desejados e Novidades em alta), BookTok e Bookstagram, Goodreads e Skoob, temas recorrentes em podcast e YouTube do nicho. Detalhe em `references/palavras-tendencias.md`.

Moda passageira × tendência — só chame de tendência quando passar nos 3:

- [ ] **Tempo:** o sinal se mantém em 3 leituras espaçadas por pelo menos 2 semanas (ou 12 meses de Trends sem queda)
- [ ] **Várias fontes:** aparece em pelo menos 3 fontes independentes (ex.: Trends + lista de vendidos + BookTok)
- [ ] **Compra:** existe livro vendendo no tema (ranking), não só vídeo visto

Livro leva 6–12 meses do conceito à loja. Tema que só tem pico de uma semana estará morto no lançamento. Em não ficção de negócio, o que interessa é **o que está crescendo no nicho do autor** (ferramenta nova, mudança de lei, prática que virou padrão), com prova em Trends e em comparáveis recentes.

## 6. Coleta automatizada com Apify (`mcp__apify`)

Use quando a coleta manual passar de ~20 páginas (muitas avaliações, várias categorias, contagem de vídeos de hashtag). Passo a passo e regras em `references/coleta-avaliacoes.md`. Resumo:

1. `search-actors` com o tipo de coleta (ex.: "amazon reviews", "amazon product", "tiktok hashtag"). **Não crave nome de actor sem ter visto no resultado.**
2. `fetch-actor-details` do escolhido: entrada, saída, termos e **preço**.
3. Estime o custo da rodada (itens × preço) e **peça o OK do usuário** antes de `call-actor`. Sem OK, não roda.
4. Limite explícito de itens. Guarde só texto, nota, data e país da avaliação — **nunca nome, perfil ou foto de avaliador**.
5. Registre amostra, data, actor e custo real em `signals.md`.

## 7. Mineração de avaliações

De **200 a 500 avaliações** dos 5–8 comparáveis (método em `references/coleta-avaliacoes.md`). Agrupe em quatro colunas: **dores** (por que comprou), **promessas não cumpridas**, **pedidos** ("queria que tivesse…") e **frases exatas do leitor** (viram título, subtítulo, descrição e copy de lançamento). Conte quantas avaliações caem em cada grupo.

Avaliação de **3 estrelas** é onde está a lacuna: o leitor gostou do tema e diz exatamente o que faltou. Leia todas as de 3 estrelas antes das de 1 e 5.

## 8. Padrão de quem vende

Tabela dos 10 primeiros de cada categoria-alvo em `categories.md` (colunas e leitura em `references/amazon-categorias.md`): título (nº de palavras), subtítulo (nº de palavras, palavra de promessa, número), capa (cor dominante, tipografia, foto × só tipo, rosto do autor), preço e-book/impresso, páginas, estrutura (partes, nº de capítulos, exercícios).

Padrão é referência, nunca modelo para copiar. A tabela de capas vai para MUNARI; a de título e subtítulo, para CAMPBELL.

## 9. Lacuna e posicionamento

Cruze: demanda da categoria (§3) × reclamações e pedidos (§7) × o que o autor sabe e viveu (`concept.md`). Saem **2 ou 3 posições**, nunca uma só:

| Posição | Leitor | Promessa | Categorias | Prós | Contras | Sinais (`M-NN`) |
|---|---|---|---|---|---|---|
| A — "o guia para clínicas" | Dono de clínica 3–10 func. | Sair da operação em 12 semanas | Gestão + Saúde | Nicho com 6 de 20 abaixo de 100 avaliações | Demanda menor | M-07, M-12, M-21 |
| B — "o livro do primeiro gerente" | Dono de serviço que vai contratar gerente | … | … | … | … | … |

**Mapa de posicionamento:** dois eixos que o leitor usa para escolher (tirados das avaliações, não inventados), por exemplo *teórico ↔ passo a passo* e *genérico ↔ setor específico*. Plote os comparáveis e as posições A/B/C; quadrante vazio com demanda nos vizinhos é candidato. Quadrante vazio sem vizinho vendendo é alerta.

Cada posição precisa caber no que o autor pode provar. Posição que pede experiência que ele não tem sai da lista.

## 10. Validação antes de escrever

Quando o autor tem público, teste antes do G1 (roteiros em `references/validacao-relatorio.md`):

| Teste | Sinal forte |
|---|---|
| Enquete no Instagram do autor (2 opções de tema ou promessa) | Diferença ≥ 20 pontos entre as opções, com pelo menos 200 votos |
| Caixa de perguntas | Mesma dúvida repetida por várias pessoas, nas palavras delas |
| Teste de título (2–4 opções) | Uma opção vence em 2 testes diferentes (enquete + conversa) |
| Lista de espera / pré-venda | Inscrição ou compra; conta mais que curtida |
| 5 conversas com leitores-alvo | 4 de 5 descrevem a dor sem você sugerir |
| Anúncio teste pequeno | Só com orçamento aprovado pelo usuário, executado pela squad traffic |

Curtida, comentário "quero!" e elogio de amigo são sinal fraco. Quem respondeu enquete não tem nome guardado.

## 11. Relatório de mercado (`market-report.md`)

Estrutura fixa (modelo completo em `references/validacao-relatorio.md`): intenção do livro → resumo em 5 linhas → categorias → palavras → tendências → avaliações → padrão dos líderes → posições A/B/C com mapa → validação → **o que não foi verificado** → próximos passos. Regras:

- [ ] Todo número com `M-NN` (que traz data e confiança)
- [ ] Achado separado de recomendação, em colunas diferentes
- [ ] Venda estimada sempre em faixa e com a palavra "estimativa"
- [ ] Seção "Não verificado" nunca vazia: diga o que não foi lido e por quê
- [ ] Decisão final registrada por CAMPBELL como `D-NN`, não por CARNEGIE

## 12. Em ficção

O leitor de ficção compra **gênero, tropo e sensação**, e o método muda (detalhe em `references/palavras-tendencias.md`): categorias por subgênero (romance de época, fantasia, suspense psicológico), tropos que o público busca pelo nome ("inimigos que se apaixonam", "cidade pequena"), BookTok como vitrine principal, comparáveis por gênero e tamanho e o pitch "para quem gostou de X e Y". Avaliações mostram tropo amado, tropo cansado e o que irritou no final.

## 13. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "Esse tema viralizou ontem, vamos escrever" | Pico de uma semana não sustenta livro de 9 meses. Passe pelos 3 testes da §5. |
| "BSR 5.000 = 5 mil vendas" | BSR é posição, não contagem. Na loja Kindle dos EUA, #5.000 dá na ordem de dezenas por dia, por estimativa de terceiro. Faixa, fonte e data. |
| "O meu público vai comprar, não precisa pesquisar" | Seguidor não é comprador de livro. Lista de espera ou pré-venda mostra; enquete aponta. |
| "Categoria sem concorrência é ouro" | Sem concorrente pode ser sem leitor. Confira o ranking do 1º e do 20º. |
| "Roda o scraper das 2 mil avaliações agora" | Custo e regras primeiro: preço do actor, OK do usuário, sem dado de avaliador. 300 bem lidas bastam. |
| "Copia o título do líder e muda uma palavra" | Confunde o leitor, apaga a diferença e pode dar problema. Use o padrão, não o texto. |
| "A ferramenta disse 412 vendas por mês" | Estimativa sobre estimativa. Registre como faixa, confiança baixa. |

## Origem

Método próprio do CT. Fatos públicos e ferramentas citados com link e data em cada referência (Amazon Mais vendidos, Google Trends, PublishNews/Nielsen, profitable.app, Kindlepreneur, documentação do Apify MCP), conferidos em 17/11/2026.
