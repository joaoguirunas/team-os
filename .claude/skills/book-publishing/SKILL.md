---
name: book-publishing
description: "Método de publicação de livro no Brasil e na Amazon — ISBN pela CBL por formato, código de barras, ficha catalográfica, depósito legal na Biblioteca Nacional, registro de direitos, metadados KDP (palavras-chave, categorias, divulgação de IA, preço e royalty), gráfica ou sob demanda, checklist do G4 e lançamento. Use ao preparar registro, metadados, preço ou lançamento."
version: "1.0"
updated: "2026-11-17"
---

# Book Publishing — o agente prepara, o autor publica

LOBATO (book-publisher) monta tudo o que a publicação exige e guia o usuário passo a passo. **Ele nunca paga, cadastra, envia nem publica.** Pagamento de ISBN, conta no KDP, envio à gráfica, depósito na Biblioteca Nacional: o usuário executa, depois do PASS de BORGES no G4 e da confirmação explícita dele (piso 6). Tudo fica em `publishing/registro.md`, `publishing/metadata.md` e `publishing/launch.md`.

Números de plataforma mudam. Cada número abaixo traz a data da conferência; **a página oficial manda** — confira de novo no dia de executar e anote a data em `registro.md`.

## 1. Ordem do trabalho

| # | Etapa | Depende de | Quem executa |
|---|---|---|---|
| 1 | Decidir formatos (e-book, brochura, capa dura) e canais (KDP, gráfica, sob demanda) | G1 | usuário decide, LOBATO propõe |
| 2 | ISBN de cada formato + código de barras do impresso | título final, editora/selo definido | usuário compra na CBL |
| 3 | Ficha catalográfica (CIP) | ISBN, sumário, número de páginas aproximado | bibliotecário com CRB |
| 4 | Metadados, descrição, palavras-chave, categorias, preço | G3 (arquivos finais) | LOBATO escreve |
| 5 | G4 — PASS de BORGES | 2 a 4 | BORGES |
| 6 | Cadastro e publicação no KDP / envio à gráfica | G4 + confirmação | usuário |
| 7 | Depósito legal (até 30 dias após publicar) | livro publicado | usuário envia |
| 8 | Lançamento e kit para marketing | publicação | LOBATO prepara, squads de marketing executam |

## 2. ISBN e código de barras — CBL

- No Brasil o ISBN é emitido pela **Câmara Brasileira do Livro** (agência nacional), em isbn.cbl.org.br. Cadastro único do autor ou da editora; depois, pedido por título.
- **Um ISBN por formato.** Brochura, capa dura, e-book EPUB e e-book em PDF são produtos diferentes e cada um tem o seu. Nova edição com mudança relevante de conteúdo também exige ISBN novo.
- O ISBN é obrigatório na editoração do livro e vai na **quarta capa do impresso** (Lei 10.753/2003, art. 6º, parágrafo único).
- **Código de barras** (EAN-13 gerado do ISBN): necessário para livraria e gráfica; compre junto. No KDP com ISBN gratuito da Amazon o código é aplicado por ela.
- Preços em cblservicos.org.br/precos, conferidos em 17/11/2026: ISBN **R$ 28,60**; código de barras **R$ 41,20**; ficha catalográfica **R$ 68,60** (associado R$ 34,30). Confira de novo antes de pagar.

**ISBN gratuito do KDP:** serve só no KDP (o selo aparece como "Independently published") e não pode ser usado em outra gráfica ou plataforma. Livro que vai circular no Brasil fora da Amazon: use ISBN próprio da CBL. E-book no KDP não precisa de ISBN (a Amazon atribui ASIN), mas para catálogo, ficha e depósito legal o ISBN próprio do e-book é o caminho limpo.

## 3. Ficha catalográfica (CIP)

- Obrigatória na editoração do livro (Lei 10.753/2003, art. 6º). Vai no **verso da folha de rosto**, junto com créditos e direitos.
- É elaborada por **bibliotecário com registro no CRB** — a CBL oferece o serviço (§2), e bibliotecários autônomos também. O agente **não** produz ficha catalográfica; ele junta o que o bibliotecário pede: título, subtítulo, autor, edição, local, editora, ano, ISBN, número de páginas, dimensões, assuntos e o sumário.
- A ficha traz o número de páginas: peça depois do G3 ou atualize se a diagramação mudar.

## 4. Depósito legal — Biblioteca Nacional

- Lei 10.994/2004 regulamentada pela **Instrução Normativa FBN nº 001, de 18/6/2026** (conferida em 17/11/2026): depósito em até **30 dias corridos** após a publicação; responsabilidade solidária de autor, editor, gráfica e plataforma.
- Exemplares (art. 11): impresso — **pelo menos 2**; digital — **1 em formato de preservação**; impresso e digital — 2 físicos + 1 digital.
- Formato digital aceito (Anexo I): **PDF/A-2 ou PDF/A-3** para texto, entregue em **CD ou DVD**, com o formulário da FBN. EPUB não está na lista: gere um PDF/A do miolo (GARAMOND) para o depósito.
- Envio físico ao Protocolo da FBN (Av. Rio Branco, 219, 3º andar, Rio de Janeiro), com formulário baixado do site; recibo eletrônico por e-mail após conferência. Sem taxa.
- Descumprimento: advertência e, após 30 dias, multa de 10 vezes o valor de mercado da publicação, dobrando até 100 vezes (IN 001/2026, art. 5º).

## 5. Direitos autorais — o que de fato protege

- A proteção **nasce com a obra** e não depende de registro (Lei 9.610/98, art. 18). O registro é facultativo (art. 19) e serve como **prova de anterioridade** em disputa.
- Opções de registro: Escritório de Direitos Autorais da Biblioteca Nacional, pelo gov.br (serviço "Registrar ou Averbar Direitos Autorais") com GRU — tabela encontrada R$ 40 pessoa física, R$ 80 pessoa jurídica, sem data: **conferir no gov.br**; ou registro na CBL (R$ 69,90, conferido em 17/11/2026).
- O que protege mais na prática: manuscrito versionado `V{n}` com datas, e-mails de envio, contrato escrito com coautor, ilustrador e quem cedeu imagem ou texto.
- Página de créditos (verso da folha de rosto): © ano e nome do titular, "Todos os direitos reservados", créditos de capa, ilustração, revisão e diagramação, ficha catalográfica, ISBN.
- Ideias, métodos e nomes de método **não** são protegidos por direito autoral (art. 8º); marca de método se protege no INPI — encaminhe à squad Legal se o autor quiser.

## 6. KDP — e-book passo a passo

O usuário faz, com LOBATO guiando tela a tela, só depois do G4:

1. Conta em kdp.amazon.com com dados fiscais e bancários do próprio usuário (o agente não digita dados pessoais nem bancários).
2. **Detalhes:** idioma, título e subtítulo idênticos à capa, série, autor, colaboradores com papel, descrição, direitos de publicação, palavras-chave, categorias, idade (se infantil), pré-venda.
3. **Conteúdo:** gestão de direitos digitais (DRM), arquivo EPUB validado no G3, capa do e-book, **pergunta sobre conteúdo gerado por IA** (§8), pré-visualização.
4. **Preço:** KDP Select (sim/não), territórios, royalty 35% ou 70%, preço por loja.
5. Publicar. Revisão da Amazon leva até 72 horas (conferir em "Timelines" no KDP Help).

**Pré-venda (e-book):** data de lançamento até 18 meses à frente para pré-vendas criadas a partir de 2/9/2026; arquivo final até 72 h antes do lançamento (5 dias se for o primeiro título da conta); perder o prazo cancela a pré-venda (KDP Help, conferido em 17/11/2026). Impresso no KDP não tem pré-venda, só data agendada.

## 7. KDP — impresso, preço e royalty

**Impresso:** brochura e capa dura exigem PDF de miolo e de capa (specs de GARAMOND e MUNARI). **A amazon.com.br não distribui brochura nem capa dura do KDP** (KDP Help, conferido em 17/11/2026): o impresso do KDP vende nas lojas de fora (amazon.com e outras). Para o leitor brasileiro, impresso vem de gráfica ou impressão sob demanda nacional (§9).

| Royalty (KDP Help, conferido em 17/11/2026) | Regra |
|---|---|
| E-book 35% | amazon.com.br: R$ 1,99 a R$ 400 (arquivo < 3 MB; R$ 3,99 de 3 a 10 MB; R$ 5,99 acima) · amazon.com: US$ 0,99 a US$ 200 |
| E-book 70% | amazon.com.br: R$ 5,99 a R$ 31,99 **e exige KDP Select** · amazon.com: US$ 2,99 a US$ 12,99 (teto subiu de 9,99 em 7/7/2026); desconta custo de entrega por MB (valor por loja: conferir em "Digital Book Pricing Page") |
| Brochura amazon.com | 50% até US$ 9,98; 60% a partir de US$ 9,99; menos o custo de impressão (fixo + páginas × custo por página) |
| Distribuição expandida | 40% do preço menos impressão |

Exemplo de conta (e-book, amazon.com.br, 70%, KDP Select): preço R$ 29,90 → o royalty é 70% do preço **sem impostos** da loja, menos o custo de entrega por MB; sem impostos e sem entrega seria R$ 20,93, então o valor real fica abaixo disso. Escreva a conta completa em `metadata.md` com a data e deixe o usuário decidir o preço. KDP Select dá exclusividade digital por 90 dias: o e-book não pode estar à venda em outra loja nesse período.

## 8. Metadados — `publishing/metadata.md`

- **Título e subtítulo:** exatamente como na capa; subtítulo diz a promessa do `concept.md`, sem palavra-chave enfiada.
- **Descrição** (até 4.000 caracteres, HTML simples): as 2 primeiras frases aparecem antes do "Ler mais" — problema do leitor e promessa. Não ficção: problema → o que o livro entrega → por que este autor → o que o leitor passa a fazer. Ficção: gancho → conflito → o que está em jogo, sem spoiler além do primeiro ato. Sem superlativo, sem link, sem preço, sem "best-seller" não comprovado. Passe por `/copy-humanize`.
- **Palavras-chave:** até **7** palavras ou frases curtas, como o leitor busca ("fluxo de caixa pequena empresa"). Proibido: palavra já no título ou nas categorias, nome de outro autor ou livro, "novo", "promoção", "KDP Select", aspas, adjetivo de qualidade (KDP Help, conferido em 17/11/2026).
- **Categorias:** até **3** por livro; prefira a mais específica que descreve o livro de verdade.
- **Divulgação de IA (piso 7):** o KDP exige declarar conteúdo **gerado** por IA — texto, imagem ou tradução criados por ferramenta de IA, mesmo que editados depois. Uso de IA só para revisar, editar ou ter ideias sobre texto escrito pelo autor é "assistido" e não precisa ser declarado (Content Guidelines, conferido em 17/11/2026). Nesta squad, capítulo redigido por MACHADO e imagem gerada (ver `image-log.md`) contam como gerados: a resposta sai do registro, nunca da memória.
- **Bio do autor:** fatos do autor, aprovada por ele.

## 9. Impressão no Brasil — gráfica × sob demanda

| Caminho | Quando faz sentido | Custo e risco |
|---|---|---|
| Gráfica com tiragem (offset ou digital) | lançamento com evento, venda direta em palestra e mentoria, livro como brinde corporativo | custo por exemplar cai com a tiragem; o autor paga antes e guarda estoque |
| Impressão sob demanda nacional (ex.: Clube de Autores, UICLAP) | sem estoque, venda contínua e baixa | sem custo inicial; preço por exemplar maior; conferir prazo, qualidade e reclamações recentes |
| KDP impresso | leitor fora do Brasil | não vende na amazon.com.br (§7) |

Antes de recomendar uma plataforma ou gráfica: confira no site dela, na data, se o serviço existe, o custo por exemplar com as specs reais (formato, páginas, papel, cor), prazo, como fica o ISBN (o ISBN próprio da CBL pode ir para todas; ISBN dado pela plataforma fica preso a ela) e peça prova impressa. Registre em `registro.md` com fonte e data. Gráfica com tiragem: peça orçamento de pelo menos 3, com as mesmas specs de `production/specs.md`, e uma prova antes de aprovar.

## 10. Checklist do G4 — antes de o usuário publicar

- [ ] G3 com PASS e manuscrito congelado `V{n}`; arquivos de `build/` e `assets/capa/` são os que vão subir
- [ ] ISBN próprio de cada formato registrado em `registro.md` (ou decisão `D-NN` de usar o do KDP só lá)
- [ ] Código de barras e ISBN na quarta capa do impresso; ficha catalográfica com ISBN e páginas corretos no verso da folha de rosto
- [ ] Título, subtítulo e autor idênticos em capa, miolo, ficha e metadados
- [ ] Descrição, 7 palavras-chave e 3 categorias dentro das regras do §8
- [ ] Resposta de IA do KDP coerente com o registro de produção e o `image-log.md`
- [ ] Preço por loja com a conta de royalty e a data da conferência; decisão do usuário registrada
- [ ] Toda imagem com origem e licença; todo trecho de terceiro com permissão (pisos 1 e 3)
- [ ] Plano de depósito legal com data-limite (publicação + 30 dias)
- [ ] Confirmação explícita do usuário registrada antes de qualquer pagamento ou envio

## 11. Lançamento — `publishing/launch.md`

- **Pré-venda:** e-book no KDP (§6); impresso por lista de espera ou venda direta do autor.
- **Leitores beta e ARC:** 10 a 30 leitores do perfil do `concept.md` recebem cópia antecipada 4 a 6 semanas antes. Pode dar cópia grátis ou com desconto, mas **nunca exigir avaliação, avaliação positiva, nem dar outra recompensa** — a Amazon remove avaliação ligada a pagamento ou brinde. Peça avaliação honesta, sem condição.
- **Avaliações:** nada de troca de avaliações entre autores, compra de avaliação ou o próprio autor avaliando.
- **Kit de handoff** para as squads de marketing (instagram, linkedin, youtube, traffic): capa em alta e mockup, descrição curta e longa, 5 trechos aprovados pelo autor com página, bio, link de venda por loja, data e preço, público do `concept.md`, resposta de IA declarada e o que não pode ser prometido. As squads seguem os próprios gates; LOBATO não publica post nem anúncio.

## 12. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "Uso o mesmo ISBN no e-book e no impresso." | Cada formato tem o seu. ISBN repetido gera erro de catálogo e de ficha. |
| "Eu mesmo faço a ficha catalográfica." | Ficha é feita por bibliotecário com CRB. |
| "Registro é que protege o livro." | A obra é protegida desde a criação; registro é prova. |
| "O livro foi só editado com IA, não preciso marcar." | Texto redigido pela IA é gerado, mesmo revisado depois. Declare. |
| "Vou mandar o livro e pedir 5 estrelas aos amigos." | Pedido condicionado viola as regras da Amazon e a avaliação some. |
| "Coloco brochura na amazon.com.br pelo KDP." | A loja brasileira não distribui impresso do KDP. |

## Origem

Estrutura do checklist de KDP e da descrição por tipo de livro adaptada (reescrita em pt-BR, sem copiar texto) de queelius/pub-pipeline, `docs/kdp-reference.md` e `skills/kdp-listing` (MIT, © 2026 Alexander Towell, commit b40a0d7). Fatos públicos conferidos em 17/11/2026: KDP Help (kdp.amazon.com/help), CBL (cblservicos.org.br/precos), FBN (IN 001/2026, gov.br/bn), Leis 9.610/98, 10.753/2003 e 10.994/2004 (planalto.gov.br).
