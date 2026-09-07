---
name: sales-proposal-copy
description: Régua editorial e método de redação para propostas comerciais, decks e follow-ups — voz declarativa, arco em três aberturas, dependência do cliente escrita como compromisso conjunto, objeção respondida pelo enquadramento (nunca enunciada), número só com origem na ficha, proibições verificáveis por grep. Use ao escrever ou revisar qualquer texto que um cliente vá ler em contexto de proposta.
version: "1.0"
updated: "2026-09-07"
---

# Sales Proposal Copy — a proposta afirma

Texto de proposta não é texto de site nem de anúncio: o leitor já conversou com você, tem uma dor nomeada e vai decidir com base no que está escrito. Cada frase ou aumenta a confiança ou planta uma dúvida. Esta skill dá o método e a **régua** — um conjunto de regras verificáveis que a redatora aplica antes de entregar e o QA aplica antes de aprovar.

## 1. Voz

- **Declarativa, presente do indicativo.** "O sistema entra no ar em 14 dias." Não "esperamos colocar", "pretendemos", "deve entrar".
- **Sujeito é a empresa ou o cliente** — nunca abstrações ("a solução permitirá"). "Nós configuramos; vocês nomeiam um dono interno."
- **Frases curtas. Uma ideia por frase, um argumento por página.**
- **Especificidade sobre adjetivo.** "Resposta em segundos" > "resposta rápida". "3 landing pages com manutenção" > "páginas completas".
- **Linguagem do cliente** nas páginas de diagnóstico — as palavras que ele usou na reunião (do intake), não as suas.
- Tom, termos fixos, emoji, maiúsculas, pontuação: **conforme a nota de marca do projeto** (`project/brand.md`). Sem nota de marca, pergunte — não improvise.

## 2. O arco em três aberturas

| Abertura | Pergunta que responde | Páginas típicas |
|---|---|---|
| **I — O ponto de partida** | *Vocês me entenderam?* | O que ouvimos (dores, literal) · onde a receita/tempo vaza (com dados e fonte) · a oportunidade |
| **II — O que entregamos** | *Como isso resolve?* | A oferta em uma imagem · o método/módulos · o roadmap por marcos · o que você passa a enxergar |
| **III — Como começamos** | *O que eu faço agora?* | Governança e "para o marco 1 rodar" · investimento (o que inclui/exclui/termos) · próximo passo e aceite |

Cada página tem **título-asserção** (afirma algo: "Onde a receita vaza", não "Diagnóstico"), **corpo** que prova a asserção e uma **ponte** para a próxima. A frase de posicionamento aparece no máximo duas vezes: abertura e fecho.

## 3. Regras do que vai e do que não vai

### Vai
- Dores na linguagem do cliente
- Oferta com nomes exatos do catálogo
- Roadmap com marcos e o que fica pronto em cada um
- **Compromisso conjunto**: tabela "o que entregamos / o que precisamos de vocês" — é a única forma permitida de falar de dependência
- Investimento, inclusões, exclusões, termos, próximo passo
- Números com origem na ficha da financeira (`#id`) e dados de mercado com fonte

### Não vai — nunca
- **Riscos** ("existe o risco de…", "caso a aprovação atrase…")
- **Objeção enunciada** ("você pode achar caro, mas…") — a objeção é respondida pelo enquadramento, não citada
- **Condicional de resultado** ("se der certo", "esperamos que", "pode ser que", "tentaremos", "caso funcione")
- **Comparativo com concorrente nomeado**, margem, custo interno, decisão pendente do time
- **Número sem `#id`**, caso de sucesso sem fonte, depoimento não fornecido
- **Promessa fora da tese** (escopo, prazo ou bônus que a estrategista não aprovou)
- Emoji, gíria ou piada quando a marca não autoriza

## 4. Padrões prontos

**Dependência → compromisso conjunto**
> ✗ "O prazo depende de recebermos os acessos a tempo."
> ✓ "Para o sprint 1 rodar: nós montamos o time e iniciamos na semana da assinatura; vocês nomeiam um dono interno com agenda no planning semanal e liberam os acessos listados."

**Risco → sequenciamento**
> ✗ "Há risco de o WhatsApp oficial demorar para aprovar o template."
> ✓ "Abrimos o cadastro do WhatsApp oficial no primeiro dia. Enquanto a aprovação corre, a esteira de e-mail já opera."

**Objeção → enquadramento**
> ✗ "Você pode pensar que 12 meses é muito tempo."
> ✓ "O ciclo é de 12 meses porque a construção é por camadas. Vocês encerram quando quiserem, com 60 dias de aviso, sem multa. O compromisso é nosso."

**Impacto em pessoas → redesenho de função**
> ✗ "A automação vai reduzir a necessidade de atendentes."
> ✓ "Ninguém é substituído. A IA assume o que é mecânico — rastreio, prazo, status — e o time vai para o que gera receita."

**Preço → conta**
> ✗ "Um investimento acessível."
> ✓ "R$ [#1]/mês. O equivalente de tabela dessas frentes separadas é R$ [#2]. A implantação está inclusa."

## 5. Deck e one-pager

- **Um slide, uma asserção**; o corpo é a evidência (número, imagem, diagrama)
- Slide de preço só depois do slide de valor
- One-pager de leave-behind: problema em 1 frase → o que fazemos → 3 diferenciais → 1 prova → próximo passo com contato
- E-mail/mensagem de envio e follow-up: 3-5 linhas, uma pergunta, um próximo passo com data — mesma régua

## 6. A régua — checklist antes de entregar e antes de aprovar

Detalhe e padrões de busca em `reference/regua-editorial.md`. Resumo:

| # | Verificação | Como |
|---|---|---|
| R1 | Zero condicional de resultado | grep dos padrões; leitura |
| R2 | Zero risco enunciado | grep ("risco", "caso", "se … não") |
| R3 | Zero objeção enunciada | leitura das páginas II e III |
| R4 | Todo número com `#id` na ficha (valor e formato idênticos) | cruzamento manual |
| R5 | Toda estatística externa com fonte | leitura |
| R6 | Termos da oferta exatamente como no catálogo | grep dos nomes |
| R7 | Dependências só como compromisso conjunto | leitura da página de governança |
| R8 | Títulos são asserções | leitura do índice |
| R9 | Voz, termos e proibições da marca respeitados | grep de emoji/termos vetados |
| R10 | Páginas = estrutura aprovada (§9 do plano) | contagem |

Uma falha em R1–R7 é bloqueante.
