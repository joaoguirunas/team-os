---
name: book-research-sources
description: "Método de pesquisa de um livro — escolha e leitura de 5–8 comparáveis, hierarquia de fontes com fonte primária, banco de fatos F-NN com status, verificação, transcrição de entrevistas e áudios do autor com Whisper (máquina medida antes), citações e permissões pela Lei 9.610/98 e separação entre achado e recomendação. Use ao pesquisar, checar fato, transcrever ou citar terceiro."
version: "1.1"
updated: "2026-11-17"
---

# Book Research & Sources — nada entra no livro sem origem

Um livro fica anos em circulação. Um número errado na página 40 aparece em avaliação de leitor, em print de rede social e na segunda edição que ninguém fez. Esta skill dá o método de HYPATIA para pesquisar, registrar e verificar, e para transformar a fala do autor em material utilizável. Arquivos em `docs/smart-memory/agents/book/research/`: `facts.md`, `interviews/`, `permissions.md`. Comparáveis, categorias, tendências e todo o mercado são de CARNEGIE (book-market), com método em `/book-market-research` e arquivos em `agents/book/market/`.

HYPATIA entrega evidência. Quem decide o que entra no livro é CAMPBELL (estrutura) e o autor (conteúdo).

## 1. Livros comparáveis — leitura mínima (o mercado completo é de CARNEGIE)

CARNEGIE escolhe os comparáveis e faz a pesquisa de mercado em `market/comps.md` (`/book-market-research`). Esta seção fica como a régua mínima de leitura de cada um, útil quando HYPATIA precisa checar um fato ou uma citação dentro deles.

| Critério | Regra |
|---|---|
| Mesmo leitor | O comparável fala com o leitor da `concept.md` §2, mesmo que o tema seja vizinho |
| Recente | Pelo menos metade publicada nos últimos 5 anos |
| Mistura | 2–3 do mercado brasileiro, 2–3 traduzidos ou estrangeiros, 1–2 autopublicados |
| Escala realista | Nada de usar só clássicos com milhões de cópias; inclua livros do tamanho que o autor pode alcançar |
| Lidos | Pelo menos índice, introdução e um capítulo de cada (amostra da Amazon ou do Google Livros) |

O que se extrai de cada um, numa linha da tabela em `market/comps.md`:

| Campo | Exemplo |
|---|---|
| Título, autor, editora, ano | — |
| Formato e tamanho | 14 × 21 cm, 224 p., brochura |
| Preço impresso / e-book (data da consulta) | R$ 59,90 / R$ 29,90 (consultado em 17/11/2026) |
| Categorias na Amazon | as que aparecem na página do produto |
| Promessa (subtítulo, contracapa) | uma linha |
| Estrutura | partes, nº de capítulos, como abre um capítulo |
| Elogios e reclamações recorrentes nas avaliações | 3 de cada, parafraseados, com contagem |
| Lacuna que o nosso livro cobre | uma linha, ligada à tese do autor |

Ranking de vendas da Amazon muda de hora em hora: registre com data e trate como sinal, nunca como número de vendas.

## 2. Hierarquia de fontes

Use sempre a mais alta disponível. Fonte secundária só aponta o caminho até a primária.

| Nível | Exemplos | Pode ir para o livro? |
|---|---|---|
| 1. Primária | Lei no Planalto, dado do IBGE/Sebrae/Banco Central, artigo científico original, relatório anual da empresa, documento do autor | Sim |
| 2. Secundária de qualidade | Reportagem de veículo com apuração, livro de referência com notas | Sim, citando o veículo; procure a primária |
| 3. Agregadores | Blog, post, Wikipédia, resumo de IA, apresentação sem fonte | Não. Só serve para achar a primária |
| 4. Memória do autor | "Li em algum lugar que 80% das empresas…" | Não, até virar nível 1 ou 2, ou ser reescrito como opinião dele |

Para pesquisa com muitas fontes ou tema em disputa, use `/deep-research`. Para ler PDF, DOCX ou planilha do autor sem gastar contexto, `/doc-to-markdown`.

## 3. Banco de fatos `F-NN`

Todo número, estudo, data, citação atribuída ou afirmação verificável do livro vira uma linha em `facts.md`. O capítulo cita o id no rascunho (`[F-14]`); HOUAISS troca pela referência ABNT na revisão.

| Id | Afirmação (como vai no livro) | Fonte | Página / URL | Acesso | Status | Capítulos |
|---|---|---|---|---|---|---|
| F-14 | 48% dos pequenos negócios citam falta de capital de giro | Sebrae, pesquisa X | p. 12 / URL | 17/11/2026 | verificado | CAP-03 |
| F-15 | "Feito é melhor que perfeito" — atribuída a fulano | — | — | 17/11/2026 | a confirmar | CAP-05 |

Regras:
- Status só tem dois valores: `verificado` ou `a confirmar`. G2 bloqueia capítulo com fato `a confirmar` em não ficção (piso 2).
- `verificado` = HYPATIA abriu a fonte primária e achou a afirmação **com o mesmo número, o mesmo recorte e a mesma data**.
- Afirmação que muda de sentido na redação (de "48% citam" para "metade quebra") volta a `a confirmar`.
- Id nunca é reaproveitado. Fato derrubado fica com status `a confirmar` e nota "descartado: motivo".

## 4. Verificação — passo a passo

1. Ache a origem: busque a frase ou o número entre aspas e siga até o documento que o produziu.
2. Confira recorte: país, ano, amostra, quem respondeu. "Empresas brasileiras" pode ser "empresas de São Paulo com mais de 50 funcionários".
3. Confira data: dado de 2015 apresentado como atual é erro. Prefira a edição mais recente da mesma pesquisa.
4. Citação atribuída a pessoa famosa: exija a obra, o discurso ou a entrevista de origem. Sem isso, a frase sai ou vira "frase popular".
5. Estudo científico: leia o resumo e a conclusão do artigo, não a notícia sobre ele. Anote tamanho da amostra.
6. Registre em `facts.md` e avise MACHADO quando um fato cai ou muda.

## 5. Entrevistas e áudios do autor

O autor costuma ter mais livro gravado do que escrito. Fluxo:

1. **Inventário:** liste os arquivos em `research/interviews/INDEX.md` (arquivo, data, duração, assunto, capítulos prováveis). Arquivos originais ficam onde o autor guardou; não mova.
2. **Medir a máquina antes.** Transcrição é processo pesado. Rode `/machine-resources` com a memória do modelo escolhido (ex.: `--per-job-gb 2` para `small`, `--per-job-gb 5` para `medium` no Whisper do PyTorch). Respeite o `MAX_PARALLEL` devolvido.
3. **Um processo com vários arquivos, nunca vários Whispers em paralelo.** O modelo carrega uma vez:
   ```bash
   whisper aula01.m4a aula02.m4a aula03.m4a --model small --language Portuguese --output_format all --output_dir "docs/smart-memory/agents/book/research/interviews/"
   ```
   Se `VERDICT` vier apertado, use modelo menor ou whisper.cpp; nunca dispare um Whisper por arquivo ao mesmo tempo.
4. **Revisão da transcrição:** corrija nomes próprios, termos do método e números ouvindo o trecho. Marque `[inaudível 12:34]` em vez de adivinhar.
5. **Mapa para o livro:** no topo de cada transcrição, liste trechos úteis com minuto e capítulo (`12:40–15:10 → CAP-04, história da primeira contratação`).
6. **Terceiros entrevistados** (cliente, sócio, ex-funcionário): registre em `permissions.md` o consentimento para uso no livro, com nome, data e forma (e-mail, mensagem, termo). Sem consentimento, o trecho só entra anonimizado e sem detalhe que identifique.

## 6. Citações e permissões (Lei 9.610/98)

Base: Lei 9.610/1998 (planalto.gov.br/ccivil_03/leis/l9610.htm, conferida em 17/11/2026). Isto é orientação prática, não parecer jurídico; caso de dúvida real vai para advogado.

| Situação | Precisa de autorização? | Fundamento |
|---|---|---|
| Trecho curto de livro para estudo, crítica ou polêmica, com autor e obra indicados, na medida justificada | Não | Art. 46, III |
| Pequeno trecho em obra nova, quando não é o objetivo principal e não prejudica a exploração normal | Não | Art. 46, VIII |
| Ideia, método, conceito de outro autor, recontado com suas palavras e crédito | Não (ideia não é protegida) | Art. 8º, I |
| Trecho longo, capítulo, poema inteiro, letra de música (mesmo um verso como epígrafe), tabela ou figura reproduzida | **Sim, por escrito** | Art. 29 |
| Obra de autor morto há mais de 70 anos (contados de 1º de janeiro do ano seguinte à morte) | Não (domínio público); tradução recente pode ter direito próprio | Art. 41 |
| Foto, ilustração ou print de terceiro | Sim, ou licença registrada como `IMG-NN` com ZIRALDO | Art. 29 |

Letra de música é o pedido mais negado e mais caro; recomende ao autor tirar antes de pedir. Registre toda permissão em `permissions.md`: obra, trecho, titular, data do pedido, resposta, condições (crédito exigido, valor, território, edições).

Modelo de pedido (o usuário envia; HYPATIA só redige):
> Assunto: Pedido de autorização para citação no livro "[título]"
> Prezados, sou [autor] e estou concluindo o livro "[título]", previsto para [mês/ano], em edição impressa e digital, com venda no Brasil e na Amazon. Peço autorização para reproduzir o trecho abaixo, de [obra, autor, edição, página], com o crédito "[crédito]". Trecho: "[…]" ([n] palavras). Fico à disposição para ajustar o crédito ou as condições.

## 7. Pessoas reais e empresas

- Afirmação negativa sobre pessoa ou empresa identificável precisa de fonte primária ou some (piso 4). Opinião do autor fica marcada como opinião.
- Caso de cliente com nome, empresa ou detalhe que permita identificar: consentimento registrado (§5.6). Sem ele, anonimize de verdade (setor, cidade e porte trocados ou omitidos).
- Uso de nome, imagem ou história de pessoa em contexto comercial pode depender de autorização (Código Civil, art. 20).

## 8. Achado × recomendação

Todo relatório de HYPATIA separa:

| Achado | Leitura | Recomendação |
|---|---|---|
| 6 dos 8 comparáveis abrem capítulo com caso de cliente | O leitor da categoria espera história antes da teoria | Abrir capítulos com caso do autor (decisão de CAMPBELL) |

Achado tem fonte. Recomendação tem dono que decide. Nunca escreva recomendação como se fosse achado.

## 9. Em ficção

Pesquisa serve à verossimilhança: época, lugar, profissão, linguagem de época, procedimento policial ou médico. Registre em `facts.md` só o que o leitor pode checar (data histórica, geografia, lei vigente na época). Epígrafes e citações seguem a §6 igual à não ficção. Personagem inspirado em pessoa real identificável cai na §7.

## 10. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "Todo mundo cita esse número" | Número repetido sem origem é boato. Sem fonte primária, fica `a confirmar` e não passa no G2. |
| "É só um verso de música na epígrafe" | Letra de música exige autorização escrita do titular, mesmo um verso. |
| "Roda os 10 áudios de uma vez que acaba mais rápido" | Dez Whispers juntos não terminam antes e travam a máquina. Um processo, vários arquivos (§5.3). |
| "A IA já resumiu o estudo" | Resumo de IA é nível 3. Abra o artigo. |
| "O cliente não vai se importar" | Sem consentimento registrado, o caso entra anonimizado. |

## Origem

Método próprio do CT. Fatos públicos citados com link e data: Lei 9.610/1998 (planalto.gov.br/ccivil_03/leis/l9610.htm), Código Civil art. 20 (planalto.gov.br/ccivil_03/leis/2002/l10406compilada.htm), opções de linha de comando do openai/whisper (github.com/openai/whisper, README), conferidos em 17/11/2026.
