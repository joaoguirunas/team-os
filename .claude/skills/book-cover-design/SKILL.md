---
name: book-cover-design
description: "Método da capa do livro — brief a partir do conceito, teste da miniatura em 160 px, hierarquia título/subtítulo/autor, tipografia e cor, capa completa (contracapa, lombada, frente, sangria), cálculo da lombada (KDP e gráfica), 300 dpi e CMYK, capa do eBook, texto de contracapa e orelhas e checklist do G3. Use ao briefar, criar, medir ou revisar a capa de um livro."
version: "1.1"
updated: "2026-11-17"
---

# Book Cover Design — a capa vende na miniatura

A capa tem um trabalho: fazer o leitor certo parar na vitrine da Amazon, onde ela aparece do tamanho de um selo, e reconhecer em 2 segundos o gênero e a promessa do livro. Beleza que não funciona em miniatura não paga a capa. Toda medida de plataforma abaixo foi conferida em **2026-11-17**; **a página oficial manda** se mudar.

Arquivos (em `docs/smart-memory/agents/book/`): `architecture/concept.md` (entrada), `design/cover-spec.md` (saída), `illustration/image-log.md` (toda imagem da capa vira `IMG-NN`). Arquivos finais em `assets/capa/`.

## 1. Brief de capa (antes de qualquer imagem)

Monte o brief em `design/cover-spec.md` a partir do `concept.md` e do `market/comps.md` (e da tabela de padrão de capa dos líderes da categoria, de CARNEGIE). Sem estes cinco campos, não se gera nada:

| Campo | Pergunta | Exemplo (não ficção) |
|---|---|---|
| Gênero e prateleira | Em que categoria da Amazon ele vai estar? | Negócios › Pequenas empresas |
| Leitor | Quem precisa reconhecer o livro como "para mim"? | Dono de agência com 5–20 pessoas |
| Promessa | O que o título + subtítulo prometem? | Sair da operação em 12 meses |
| Comparáveis | 3–5 capas da mesma prateleira, com link, lidas na miniatura | 4 best-sellers de gestão de 2024–2026 |
| Diferença | O que fica igual ao gênero (para ser reconhecido) e o que muda (para ser lembrado)? | Fundo claro como o gênero; ícone próprio no lugar de foto do autor |

Regra: **pareça do gênero, diferencie no detalhe**. Capa que foge do código do gênero confunde quem compra.

## 2. Teste da miniatura (160 px de largura)

Na busca da Amazon a capa aparece com cerca de 100–200 px de largura. Teste toda opção em **160 px**:

```bash
magick assets/capa/frente.png -resize 160x assets/capa/teste-160.png   # ImageMagick 7
sips --resampleWidth 160 assets/capa/frente.png --out assets/capa/teste-160.png   # macOS, sem instalar nada
```

- [ ] O título lê sem zoom (na prática: título ocupa ≥ 1/3 da altura ou é a maior massa da capa).
- [ ] O gênero é reconhecível ao lado das capas dos comparáveis (monte um painel com as 5 em 160 px).
- [ ] Contraste resiste em escala de cinza (`magick frente.png -colorspace Gray`): título e fundo não viram o mesmo cinza.
- [ ] O subtítulo pode sumir em 160 px; o título e o elemento central não.

## 3. Hierarquia, tipografia e cor

- **Hierarquia** (do maior para o menor): título → elemento visual → nome do autor → subtítulo. Autor conhecido inverte nome e título.
- **Tipografia**: no máximo 2 famílias. Título em peso forte (bold/black) ou serifa de alto contraste; subtítulo em peso regular. Nada de fonte fina sobre foto. Fonte licenciada para uso comercial e impressão (as da SIL Open Font License servem).
- **Cor**: 1 cor dominante + 1 de contraste. Defina a paleta em CMYK para a gráfica e confira como fica em RGB na tela. Preto "rico" para fundos grandes só com o valor que a gráfica indicar.
- **Elemento visual**: um só, grande. Mais de três elementos na frente vira ruído em miniatura.
- Identidade do livro (paleta, fontes, ícone) é a mesma que o ZIRALDO usa no miolo (`book-illustration` §1). Livro de autor com marca própria: alinhe com `/brand-visual-system`.

## 4. Convenções de capa por gênero

| Não ficção | Código visual comum |
|---|---|
| Negócio / método | Fundo liso, título enorme em sans ou serifa forte, um ícone ou objeto, subtítulo com a promessa |
| Mentoria / desenvolvimento pessoal | Cores quentes ou claras, tipografia como imagem, às vezes foto do autor |
| Memórias profissionais | Foto (do autor ou do lugar), serifa, tom mais sóbrio |

**Em ficção** o método muda: a capa vende clima, não promessa. Leia os comparáveis do subgênero exato.

| Gênero | Código visual comum |
|---|---|
| Suspense / policial | Alto contraste, sans condensada grande, figura solitária ou cenário escuro |
| Romance (romântico) | Casal ou ilustração em traço, script ou serifa delicada, cores quentes ou pastel |
| Fantasia / ficção científica | Ilustração detalhada, serifa ornamentada ou futurista, paisagem ou objeto mágico |
| Literária / contos | Minimalista, tipografia como protagonista, arte abstrata ou pintura |

## 5. Capa completa: anatomia

Impressão = **um arquivo único** com contracapa + lombada + frente + sangria em volta.

```
| sangria | CONTRACAPA (largura do miolo) | LOMBADA | FRENTE (largura do miolo) | sangria |
```

- **Largura total** = sangria + largura do miolo + lombada + largura do miolo + sangria.
- **Altura total** = sangria + altura do miolo + sangria.
- **KDP**: sangria de **0,125 pol (3,2 mm)**; texto a pelo menos **0,125 pol (3,2 mm)** dentro do corte; texto da lombada a pelo menos **0,0625 pol (1,6 mm)** de cada borda da lombada; **texto na lombada só com mais de 79 páginas** (o Cover Creator pede 80).
- **Código de barras (KDP)**: área branca de **2 × 1,2 pol (50,8 × 30,5 mm)** no canto inferior direito da contracapa, a ≥ 0,25 pol da lombada e do corte; se você não colocar, a KDP coloca. Deixe a área livre.
- **Gráfica brasileira**: sangria, área de segurança e posição do código de barras vêm do **gabarito da gráfica** — peça antes de desenhar (costuma ser 3–5 mm de sangria). O código de barras EAN-13 sai do ISBN (LOBATO cuida do ISBN pela CBL).

## 6. Cálculo da lombada

**KDP** (fonte: [Create a Paperback Cover](https://kdp.amazon.com/en_US/help/topic/G201953020), conferido em 2026-11-17):

| Miolo | Espessura por página |
|---|---|
| P&B, papel branco | 0,002252 pol (0,0572 mm) |
| P&B, papel creme | 0,0025 pol (0,0635 mm) |
| Cor padrão (standard), branco | 0,002252 pol (0,0572 mm) |
| Cor premium, branco | 0,002347 pol (0,0596 mm) |

Exemplo — 6 × 9 pol, 200 páginas, P&B em creme: lombada = 200 × 0,0025 = **0,5 pol (12,7 mm)**. Largura total = 0,125 + 6 + 0,5 + 6 + 0,125 = **12,75 pol**; altura = 9 + 0,25 = **9,25 pol**. Em 300 dpi: **3825 × 2775 px**. Confira sempre no [Cover Calculator](https://kdp.amazon.com/cover-calculator), que também baixa o gabarito em PDF/PNG.

**Gráfica brasileira**: a espessura depende do papel (pólen, offset, gramatura) e da gráfica. **Peça o gabarito com o número final de páginas e o papel escolhido**; não calcule por tabela genérica. O número de páginas só é final depois da diagramação (GARAMOND, `book-production` §8): a capa fecha **depois** do miolo, nunca antes.

## 7. Especificação de arquivo

| Item | Impressão (KDP e gráfica) | eBook (Kindle) |
|---|---|---|
| Resolução | ≥ 300 dpi no tamanho final, imagens a 100%, achatadas | 2560 × 1600 px ideal (altura × largura, 1,6:1); lado maior ≥ 500 px; ≤ 10.000 px por lado |
| Cor | CMYK; KDP pede **sem perfil de cor embutido** e um só espaço de cor; gráfica: o perfil e o PDF (às vezes PDF/X-1a ou X-4) que ela indicar | RGB (CMYK é aceito e convertido) |
| Formato | PDF único, fontes embutidas, transparências achatadas, sem senha; KDP ≤ 650 MB (recomenda ≤ 40 MB) | JPEG preferido (aceita PNG, GIF, TIFF; SVG não); ≤ 50 MB |
| Conteúdo | Frente + lombada + contracapa | Só a frente, sem moldura branca nem texto de "best-seller" que não é verdade |

Fontes: [Paperback Submission Guidelines](https://kdp.amazon.com/en_US/help/topic/G201857950) e [Cover image guidelines (eBook)](https://kdp.amazon.com/en_US/help/topic/G6GTK3T3NUHKLEFX), conferidos em 2026-11-17.

## 8. Contracapa e orelhas

- **Contracapa** (100–180 palavras): gancho em 1 frase → o problema do leitor → o que o livro entrega (3 ganhos concretos) → por que este autor → 1–2 depoimentos **reais e autorizados** (nunca inventados — piso 5). Tudo que for número ou fato precisa de `F-NN` verificado.
- **Orelhas** (comuns em livro brasileiro de gráfica): orelha da frente com a sinopse ampliada; orelha de trás com foto e bio do autor (≤ 100 palavras, aprovada por ele). A KDP não imprime orelhas: na versão KDP o texto da orelha vai para a contracapa ou para a página "Sobre o autor".
- O texto passa por `/copy-humanize` e pelo HOUAISS (folha de estilo) antes de entrar na arte. **Em ficção**: contracapa apresenta protagonista, conflito e o que está em jogo, sem contar o desfecho.

## 9. Ferramentas

| Ferramenta | Uso |
|---|---|
| Claude Design | Explorar direções de capa e montar a composição tipográfica |
| Google Stitch, via `/social-stitch-workflow` | Variações de layout da frente e mockups |
| Freepik, via `/social-freepik-generation` | Imagem ou textura de fundo gerada por IA |
| ImageMagick / sips | Teste de miniatura, conferência de pixels e dpi (`magick identify -format "%w x %h %x" arquivo`) |

Toda imagem usada na capa (gerada, banco ou foto) entra no `image-log.md` como `IMG-NN` com origem e licença **antes** de entrar na arte (`book-illustration` §6). Imagem gerada por IA na capa obriga a divulgação de IA no cadastro da KDP (`book-illustration` §7).

## 10. Checklist da capa para o G3 (BORGES)

- [ ] Brief com os 5 campos de §1 e 2–3 opções testadas em 160 px ao lado dos comparáveis; escolha do autor registrada em `D-NN`.
- [ ] Dimensões batem com o gabarito da plataforma para o **número final de páginas** e o papel (§6); lombada recalculada depois da última prova do miolo.
- [ ] Texto fora da área de segurança; lombada sem texto se ≤ 79 páginas (KDP); área do código de barras livre.
- [ ] 300 dpi reais (não imagem ampliada), CMYK para impressão, fontes embutidas, PDF sem senha.
- [ ] Capa do eBook em 2560 × 1600 px, RGB.
- [ ] Título, subtítulo e nome do autor **idênticos** aos de `publishing/metadata.md` e da folha de rosto.
- [ ] Toda imagem com `IMG-NN`, origem e licença; IA declarada; depoimentos com autorização guardada.

## 11. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "No tamanho grande está lindo" | Quem compra vê 160 px. Reprovou na miniatura, reprova. |
| "Calculo a lombada agora e ajusto depois" | Lombada depende do número final de páginas. Capa fecha depois do miolo (§6). |
| "Aumento a imagem para 300 dpi" | Ampliar não cria detalhe. Gere ou compre no tamanho final. |
| "RGB fica mais bonito, mando assim" | A gráfica converte e a cor muda. Converta e confira você, em CMYK. |
| "Coloco um depoimento genérico" | Depoimento sem pessoa real que autorizou é invenção — piso 5. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de queelius/pub-pipeline (MIT, © 2026 Alexander Towell, commit b40a0d7) — auditoria de capa contra as specs da KDP e conferência das dimensões do arquivo. Números da KDP: páginas oficiais da Ajuda KDP citadas acima, conferidas em 2026-11-17.
