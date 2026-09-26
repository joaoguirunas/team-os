---
name: brand-research
description: "Método de pesquisa para reposicionamento — auditoria da marca como ela é hoje (promessa por canal, ativos, coerência, percepção externa com citação), mapa de concorrentes e territórios, síntese de públicos na linguagem deles, benchmarks com fonte primária e a regra achado vs. recomendação. Use antes de qualquer decisão de posicionamento, ao auditar uma marca ou mapear concorrentes."
version: "1.0"
updated: "2026-09-25"
---

# Brand Research — a marca como ela é, antes da marca como vai ser

**Quando usar esta vs. `deep-research`:** esta é o método de pesquisa de marca (auditoria, concorrentes, públicos, benchmarks) que alimenta o reposicionamento. Para pesquisa profunda sobre qualquer outro tema com rastreio de citações, use `deep-research`.

Reposicionar sem diagnóstico é trocar um problema que você não conhece por outro que você inventou. A pesquisa de marca responde a quatro perguntas, **com fonte**: o que a marca promete hoje em cada canal (e onde se contradiz), como é percebida por quem está fora, quem ocupa os territórios vizinhos, e como o público fala da categoria com as próprias palavras. Quem pesquisa entrega achados; quem decide o território é outro.

## 1. Achado vs. recomendação

| É achado (entra) | É recomendação (não entra) |
|---|---|
| "Território {X} sem ocupante claro entre os 6 concorrentes mapeados" | "A marca deveria ocupar o território X" |
| "5 de 7 canais prometem 'agilidade'; o site promete 'profundidade'" | "A promessa deveria ser profundidade" |
| "12 reviews (2026) citam 'caro' — 9 associam a 'vale'" | "Manter o preço premium" |
| "Concorrente A usa azul institucional + serifa; B e C usam preto + sans" | "Ir de cor quente para diferenciar" |

Regra: achado é verificável e datado; recomendação é escolha — e escolha é da strategist. Se a leitura pede uma inferência ("isso sugere que…"), marque-a como **leitura**, separada do fato.

## 2. Auditoria da marca atual

### 2.1 Inventário de pontos de contato
Liste **cada canal vivo**: site (páginas-chave), perfis sociais (bio + últimos 12 posts), materiais de venda (propostas, decks), e-mail (assinatura, newsletter), apresentações, embalagem/papelaria se houver, marketplace/perfis de terceiros. Para cada um: **link + data de acesso + captura** (texto limpo via `/dev-defuddle`, screenshot quando o visual importa).

### 2.2 Promessa por canal
| Canal | Promessa observada (literal) | Para quem fala | Tom (3 adjetivos) | Visual (cor/tipo/imagem) | Capturado em |
|---|---|---|---|---|---|

A promessa é o que o canal **diz** que a marca entrega — copie a frase, não interprete.

### 2.3 Incoerências
Cruze canal a canal: promessa diferente, tom diferente, visual quebrado, nome/grafia variando, público diferente. Tabela `# | Onde | O que diverge | Evidência (dois links)`. Incoerência é o insumo mais valioso da plataforma — mostra o que a marca já é sem querer.

### 2.4 Ativos
O que a marca **tem** e a audiência reconhece: nome, logo, cor, slogan, mascote, formato recorrente, tom, pessoa (marca pessoal). Para cada ativo: evidência de reconhecimento (menções, reviews, comentários que citam) ou `[SEM EVIDÊNCIA DE RECONHECIMENTO]`. A strategist decide o que preservar — você mostra o que é reconhecido de fato.

### 2.5 Percepção externa
Reviews, comentários, menções, entrevistas fornecidas pelo usuário, pesquisas existentes. **Citação literal + autor/canal + data.** Agrupe por tema depois de coletar, nunca antes (agrupar antes vira confirmação do que você já achava). Confuso → `[CONFIRMAR]` com a pergunta de follow-up.

## 3. Concorrentes e mapa de territórios

### 3.1 Quem entra
Concorrentes diretos + **alternativas que o público compararia** (inclusive "não fazer nada" ou "fazer internamente"). Fonte: `brand-context.md` (declarado pelo usuário) + busca. 5–8 é o número útil.

### 3.2 Ficha por concorrente
Promessa central (literal) · público declarado · tom · território visual (cor, tipo, imagem) · faixa de preço quando pública · prova que usa (números, clientes, prêmios) · **link + data**.

### 3.3 Mapa de territórios
Escolha **2 eixos relevantes para a categoria** (ex.: acessível ↔ premium; técnico ↔ humano; tradição ↔ ruptura; especialista ↔ generalista). Posicione cada concorrente **pelo que ele diz**, com a evidência. O resultado mostra quadrantes ocupados, disputados e vazios. **Vazio é achado, não recomendação** — pode estar vazio porque ninguém quer.

## 4. Públicos

Para cada público que o usuário declarou (e os que apareceram na percepção externa): quem é (papel, contexto), o que valoriza na categoria, **como fala** (vocabulário literal: o que chama de problema, o que chama de solução, o que elogia, o que reclama), onde se informa, quem escuta. Fonte: citações coletadas em §2.5, entrevistas, comunidades públicas. Nunca invente "voz do cliente" — sem citação, não há síntese.

## 5. Benchmarks

Números que a strategist e a insights vão precisar: tamanho/crescimento da categoria, hábitos de compra, referências de awareness ou preferência do setor, custo médio, ciclo de decisão. Regra: **fonte primária, autor, ano** — em 2 tentativas; se não achar, registre a lacuna. Benchmark reutilizável vai para `benchmarks.md` com o contexto em que vale.

## 6. Prazo de validade

Auditoria de marca vale **90 dias**. Depois disso é histórico: reabra os canais, capture de novo, date de novo. Mapa de concorrentes: 180 dias. Benchmarks: conforme a fonte.

## 7. Template

`templates/brand-audit.md` — auditoria completa (§2 a §5) com os campos e tabelas prontos. O relatório de pesquisa avulsa segue o template do agente (`research report`).
