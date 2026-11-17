---
name: book-production
description: "Método da diagramação do livro — manuscrito em Markdown (um arquivo por CAP-NN) → Pandoc → PDF de impressão (Typst ou LaTeX) e EPUB 3; formato de página, margens e medianiz pelo número de páginas, sangria, fontes embutidas, elementos pré e pós-textuais, EPUBCheck, Kindle Previewer e build reproduzível com build-log.md. Use ao montar, rodar ou conferir o miolo em PDF e o EPUB."
version: "1.0"
updated: "2026-11-17"
---

# Book Production — o mesmo Markdown vira PDF e EPUB, sempre do mesmo jeito

O agente roda o build; **o usuário confere a prova impressa** (exemplar de prova da KDP ou prova da gráfica) antes de liberar a tiragem. Tela não mostra medianiz apertada, cinza fraco nem lombada torta. Números de plataforma conferidos em **2026-11-17**; **a página oficial manda** se mudar.

Arquivos (em `docs/smart-memory/agents/book/`): `production/specs.md` (formato, margens, fontes, decisões) e `production/build-log.md`. No projeto: `manuscrito/`, `modelos/`, `assets/imagens/`, `assets/capa/`, `build/`.

## 1. Manuscrito em Markdown

- Um arquivo por capítulo: `manuscrito/CAP-NN-<slug>.md` (zero à esquerda: `CAP-01` … `CAP-12`, a ordem do glob é a ordem do livro). Pré-textuais em `manuscrito/00-<slug>.md`, pós-textuais em `manuscrito/99-<slug>.md`.
- Cada capítulo começa com **um** título nível 1 (`# Título do capítulo`); seções em `##`. Nada de formatação manual (espaços, quebras para "empurrar" texto).
- Imagem: `![Figura 3.2 — Funil de vendas. Fonte: elaborado pelo autor.](assets/imagens/IMG-07-funil.png)` — só imagens com `IMG-NN` no `image-log.md` (`book-illustration` §6).
- O GARAMOND diagrama só capítulo com **PASS no G2**. Nenhum `[PERGUNTA AO AUTOR` pode restar: `grep -rn "PERGUNTA AO AUTOR" manuscrito/` tem de voltar vazio.
- Texto é do autor e já revisado: o diagramador **não reescreve**. Achou erro, devolve ao HOUAISS.

## 2. Instalar as ferramentas

| Ferramenta | macOS | Windows | Para quê |
|---|---|---|---|
| Pandoc (3.14 em 2026-11) | `brew install pandoc` | `winget install --id JohnMacFarlane.Pandoc` | Markdown → Typst / EPUB |
| Typst (0.15.1 em 2026-11) | `brew install typst` | `winget install --id Typst.Typst` | PDF de impressão |
| EPUBCheck (5.4.0 em 2026-11, precisa de Java) | `brew install epubcheck` | baixar o `.jar` em github.com/w3c/epubcheck/releases | Validar o EPUB |
| Poppler (`pdffonts`, `pdfinfo`) | `brew install poppler` | `winget install --id oschwartz10612.Poppler` (ou conferir no Acrobat) | Conferir fontes e páginas do PDF |
| Kindle Previewer 3 | download gratuito na página da Amazon | idem | Ver o EPUB como no Kindle |

Instalar programa e baixar arquivo pede OK do usuário. Alternativa ao Typst: LaTeX (`--pdf-engine=lualatex`, TeX Live ou MacTeX, ~5 GB) — use só se o projeto já tiver modelo LaTeX.

## 3. Formato de página e margens

| Formato | Onde é comum | Observação |
|---|---|---|
| **14 × 21 cm** | Brasil (gráfica e impressão sob demanda nacional) | Na KDP é tamanho personalizado (largura 4–8,5 pol, altura 6–11,69 pol são aceitas); o padrão mais próximo é 5,5 × 8,5 pol |
| 16 × 23 cm | Brasil, livros técnicos | Confirme com a gráfica |
| **6 × 9 pol** (15,24 × 22,86 cm) | KDP, não ficção | Tamanho padrão "regular" |
| 5 × 8 / 5,5 × 8,5 pol | KDP, ficção | — |

Lista oficial da KDP e limites de páginas: [Set Trim Size, Bleed, and Margins](https://kdp.amazon.com/en_US/help/topic/GVBQ3CMEQW3W2VL6) (P&B em papel branco: 24–828 páginas na maioria dos formatos). Em 2026-11-17 a KDP informa que a **Amazon.com.br não distribui livro impresso da KDP** — o impresso para o leitor brasileiro sai por gráfica ou impressão sob demanda nacional; confira antes de decidir.

**Margem interna (medianiz) da KDP pelo número de páginas** (mínimos; conferido em 2026-11-17):

| Páginas | Interna (medianiz) | Externa, topo e pé sem sangria | Com sangria |
|---|---|---|---|
| 24–150 | 0,375 pol (9,6 mm) | ≥ 0,25 pol (6,4 mm) | ≥ 0,375 pol (9,6 mm) |
| 151–300 | 0,5 pol (12,7 mm) | ≥ 0,25 pol | ≥ 0,375 pol |
| 301–500 | 0,625 pol (15,9 mm) | ≥ 0,25 pol | ≥ 0,375 pol |
| 501–700 | 0,75 pol (19,1 mm) | ≥ 0,25 pol | ≥ 0,375 pol |
| 701–828 | 0,875 pol (22,3 mm) | ≥ 0,25 pol | ≥ 0,375 pol |

Mínimo não é bonito: para leitura confortável use mais. Ponto de partida da squad para 14 × 21 cm com 200 páginas: interna 20 mm, externa 15 mm, topo 18 mm, pé 22 mm. **Gráfica brasileira**: siga o gabarito dela; margem e medianiz dependem da encadernação (brochura colada pede medianiz maior).

**Sangria** só quando houver imagem até a borda. Na KDP ela é de 0,125 pol (3,2 mm) no topo, no pé e na borda externa; a página fica +0,125 pol na largura e +0,25 pol na altura (6 × 9 → 6,125 × 9,25 pol) e, se **uma** página sangra, o miolo **inteiro** vai com sangria. Registre a decisão em `production/specs.md`.

## 4. Build do PDF de impressão (Typst)

O modelo de página fica em `modelos/livro-conf.typ` e é carregado pelo template padrão do Pandoc (variável `template`):

```typst
// modelos/livro-conf.typ — 14 x 21 cm. Recebe os argumentos que o Pandoc passa
#let conf(title: none, subtitle: none, authors: (), lang: "pt", region: "BR",
          font: ("Literata",), fontsize: 10.5pt, pagenumbering: "1", cols: 1, doc) = {
  set document(title: title)
  set page(width: 140mm, height: 210mm, numbering: pagenumbering,
           margin: (inside: 20mm, outside: 15mm, top: 18mm, bottom: 22mm))
  set text(font: font, size: fontsize, lang: lang, region: region, hyphenate: true)
  set par(justify: true, leading: 0.7em, first-line-indent: 1.2em)
  show heading.where(level: 1): it => { pagebreak(to: "odd", weak: true); v(25mm); it }
  doc
}
```

```bash
RAIZ="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"; cd "$RAIZ"
pandoc --metadata-file=modelos/livro.yaml manuscrito/CAP-*.md manuscrito/99-*.md \
  -s -t typst -V template=modelos/livro-conf.typ -B modelos/pretextuais.typ -o livro.typ
typst compile livro.typ build/livro-impressao.pdf
pdffonts build/livro-impressao.pdf     # coluna "emb" = yes em todas as linhas
pdfinfo build/livro-impressao.pdf | grep -E "Pages|Page size"
```

`livro.typ` é intermediário (fica na raiz para os caminhos das imagens funcionarem; ponha no `.gitignore`). `modelos/livro.yaml` traz só `title`, `subtitle`, `author`, `lang: pt-BR`, `mainfont`, `fontsize` — outra variável (ex.: `date`, `margin`) vira argumento novo e o `conf` precisa aceitá-lo. Comando do Pandoc conferido com Pandoc 3.10 em 2026-11-17; no primeiro build de cada projeto confira a saída do Typst página a página. Pré-textuais com layout próprio (folha de rosto, ficha) ficam em Typst em `modelos/pretextuais.typ`.

## 5. Fontes e tipografia

- **Fonte embutida e licenciada para impressão e PDF.** Fontes SIL Open Font License servem (Literata, EB Garamond, Crimson Pro, Source Serif 4). Fonte comercial: confira se a licença cobre embutir em PDF e, à parte, em EPUB. Typst embute as fontes usadas; confira com `pdffonts` (§4) e liste as disponíveis com `typst fonts`.
- Corpo 10–12 pt em serifa; entrelinha ~1,3–1,45; 55–75 caracteres por linha; hifenização em pt-BR ligada (`lang: "pt", region: "BR"`).
- Capítulo abre em página ímpar; sem cabeçalho e sem número na abertura de capítulo (estilo); sem viúva nem órfã gritante (corrija na prova, não no texto).
- O nome das fontes e o corpo vão para `production/specs.md` e para o MUNARI (capa usa a mesma família — `book-cover-design` §3).

## 6. Elementos pré e pós-textuais

| Ordem | Elemento | Observação |
|---|---|---|
| 1 | Falsa folha de rosto (só o título) | Opcional |
| 2 | **Folha de rosto** | Título, subtítulo, autor, editora/selo |
| 3 | **Verso da folha de rosto** | Copyright (© ano, autor), direitos reservados, ISBN de cada formato, **ficha catalográfica**, edição, créditos (capa, revisão, diagramação, ilustração) |
| 4 | Dedicatória, epígrafe, agradecimentos | Texto aprovado pelo autor |
| 5 | **Sumário** | No PDF, `toc: true` ou `#outline()`; no EPUB, o navegável (§7) |
| 6 | Prefácio / introdução | Já é texto do livro |
| — | Capítulos `CAP-NN` | — |
| fim | Notas, referências (ABNT NBR 6023, pelo HOUAISS), glossário, **sobre o autor**, outros livros e contato | — |

ISBN e ficha catalográfica são obrigatórios na editoração do livro (Lei 10.753/2003, art. 6º); ficha é feita por bibliotecário com registro no CRB. **LOBATO** obtém ISBN (CBL) e ficha e entrega o texto exato em `publishing/registro.md`; o GARAMOND só diagrama, sem alterar uma vírgula. Impresso e EPUB têm ISBN diferentes. A apresentação de livro segue a ABNT NBR 6029 (conferir a edição vigente).

## 7. EPUB 3

```bash
pandoc --metadata-file=modelos/livro-epub.yaml manuscrito/00-*.md manuscrito/CAP-*.md manuscrito/99-*.md \
  -o build/livro.epub --toc --toc-depth=2 --split-level=1 \
  --epub-cover-image=assets/capa/capa-ebook.jpg --css=modelos/epub.css
epubcheck build/livro.epub      # meta: 0 erros e 0 avisos
```

- **Metadados** (`livro-epub.yaml`): `title`, `subtitle`, `author`, `lang: pt-BR`, `identifier` com `scheme: ISBN` (ISBN do eBook), `publisher`, `rights`, `date`. Iguais aos de `publishing/metadata.md`.
- **Sumário navegável**: `--toc` gera o `nav.xhtml`; `--split-level=1` faz cada `#` virar um arquivo (abre capítulo em "página" nova).
- **Imagens**: PNG/JPEG (SVG só depois de conferir no Kindle Previewer); toda imagem com texto alternativo (a legenda do Markdown); tabela continua texto.
- CSS simples: sem fonte fixa em px, sem cor de fundo, sem margem lateral grande — o leitor controla fonte e tema. Não embuta fonte no EPUB sem licença para isso.
- **Validação**: EPUBCheck sem erro, depois abra no **Kindle Previewer 3** (celular, tablet, Kindle de tinta) e confira sumário, imagens, notas e quebras. A KDP aceita EPUB para eBook (conferir os formatos atuais na Ajuda KDP).
- Capa do eBook: 2560 × 1600 px, RGB (`book-cover-design` §7).

## 8. Build reproduzível e `build-log.md`

Cada build gera uma linha em `production/build-log.md`; sem linha, o arquivo não existe para o G3:

| Data | Versão | Comando | Pandoc / Typst / EPUBCheck | Saída | Páginas | Resultado |
|---|---|---|---|---|---|---|
| 2026-11-17 | V2 | `pandoc … && typst compile …` | 3.14 / 0.15.1 / 5.4.0 | build/livro-impressao.pdf | 212 | fontes emb = yes |

- Versões com `pandoc --version | head -1`, `typst --version`, `epubcheck --version`.
- Mesmo manuscrito + mesmos modelos + mesmas versões = mesmo PDF. Mudou ferramenta, registre.
- **Número final de páginas** vai ao MUNARI para fechar a lombada (`book-cover-design` §6). Mudou o miolo depois disso, a capa refaz a lombada.
- Build grande (livro com muitas imagens, várias saídas em paralelo): meça antes com `/machine-resources`.
- Depois do G3 o manuscrito congela em `V{n}`; correção pós-prova vira `V{n+1}` com novo build e nova linha.

## 9. Checklist do G3 (BORGES)

- [ ] Só capítulos com PASS no G2; zero `[PERGUNTA AO AUTOR` no `manuscrito/`.
- [ ] Formato, margens e medianiz conforme `production/specs.md` e a tabela da plataforma para o **número real de páginas** (§3); sangria só se houver imagem até a borda, e então no miolo inteiro.
- [ ] `pdffonts`: todas as fontes embutidas; licença das fontes registrada.
- [ ] Folha de rosto, verso com ISBN e ficha catalográfica idênticos a `publishing/registro.md`; sumário confere com os títulos.
- [ ] Todas as imagens com `IMG-NN` e 300 dpi no tamanho final.
- [ ] EPUBCheck 0 erros; conferido no Kindle Previewer; metadados iguais aos de `metadata.md`.
- [ ] Linha no `build-log.md` para o PDF e o EPUB entregues; manuscrito congelado em `V{n}`.
- [ ] Prova impressa pedida e **conferida pelo usuário** antes de liberar a tiragem.

## 10. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "No PDF na tela está perfeito" | Medianiz e cinza só aparecem no papel. Prova impressa antes da tiragem. |
| "Ajusto direto no PDF" | Correção fora do Markdown some no próximo build. Corrija na fonte. |
| "EPUBCheck deu só aviso" | Aviso vira rejeição ou leitura quebrada em algum aparelho. Zere. |
| "Uso a fonte que já está no computador" | Estar instalada não é licença para imprimir e embutir. |
| "Ponho sangria só na página da foto" | Uma página com sangria obriga o miolo inteiro com sangria (KDP). |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de smerchek/claude-epub-skill (MIT, © 2025 Scott Smerchek, commit 7c07230) — capítulo por título nível 1 e EPUB 3 com sumário navegável; e de queelius/pub-pipeline (MIT, © 2026 Alexander Towell, commit b40a0d7) — auditoria do miolo contra as specs da KDP. Números: Ajuda KDP, Lei 10.753/2003 e manual do Pandoc, conferidos em 2026-11-17.
