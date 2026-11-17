---
name: book-illustration
description: "Método das imagens do livro — guia de estilo único, quando usar foto, diagrama ou tabela, diagramas legíveis em preto e branco, geração com IA consistente, registro IMG-NN com origem e licença, direitos (foto de terceiro, banco, IA e divulgação na KDP, uso de imagem de pessoa) e especificação técnica (300 dpi, P&B ou cor, custo). Use ao planejar, gerar, registrar ou revisar imagens de um livro."
version: "1.0"
updated: "2026-11-17"
---

# Book Illustration — uma linguagem visual, toda imagem com origem

Imagem em livro serve ao texto: explica o que a frase não explica, ou dá ritmo à leitura. Cada imagem entra no livro com **origem e licença registradas** — sem isso ela não entra, por mais bonita que seja (piso 3). Números de plataforma conferidos em **2026-11-17**; **a página oficial manda** se mudar.

Arquivos (em `docs/smart-memory/agents/book/`): `illustration/style-guide.md`, `illustration/image-log.md`. Imagens em `assets/imagens/IMG-NN-<slug>.<ext>`.

## 1. Guia de estilo (antes da primeira imagem)

Escreva `illustration/style-guide.md` e faça o autor aprovar. Um livro, uma linguagem:

- [ ] **Tipo dominante**: diagrama vetorial, ilustração em traço, foto, ou mistura com regra (ex.: "fotos só em memórias; o resto em diagrama").
- [ ] **Paleta**: a do livro (`book-cover-design` §3) e sua versão em tons de cinza para miolo P&B.
- [ ] **Traço e forma**: espessura de linha (ex.: 1 pt no tamanho final), cantos (retos ou arredondados), ícones de uma única família.
- [ ] **Tipografia nas imagens**: a mesma família do miolo (`book-production` §5), corpo ≥ 8 pt no tamanho final (regra da squad).
- [ ] **Legenda e crédito**: formato fixo, ex.: "Figura 3.2 — Funil de vendas da agência. Fonte: elaborado pelo autor."
- [ ] **Prompt base de IA** (se houver geração, §4) e 2–3 imagens de referência aprovadas.

## 2. Quando usar cada tipo

| O conteúdo é… | Use | Não use |
|---|---|---|
| Processo, etapas, relação entre partes | **Diagrama** (fluxo, ciclo, matriz 2×2) | Foto ilustrativa |
| Números para comparar | **Tabela** (poucos números) ou gráfico (tendência) | Infográfico decorativo |
| Lugar, pessoa, objeto real, documento | **Foto** (do autor ou licenciada) | Imagem gerada que finge ser real |
| Clima, metáfora, abertura de capítulo | **Ilustração** (traço ou IA, no estilo do §1) | Banco de imagem genérico ("aperto de mão") |
| Algo que uma frase resolve | **Nada** | Qualquer imagem |

Tabela é texto: fica no Markdown do capítulo, não vira imagem (lê no EPUB, cresce com a fonte). Em não ficção de método, uma imagem a cada 10–20 páginas costuma bastar; o ARCHITECT define no `outline.md` quais capítulos pedem figura.

**Em ficção**: em geral não há imagem no miolo. Exceções: mapa (fantasia), vinheta de abertura de capítulo, ilustração em livro infantojuvenil. Mesmo guia de estilo e mesmo registro.

## 3. Diagramas e infográficos legíveis em P&B

- Faça em **vetor**: Mermaid para fluxos simples, SVG desenhado para o resto. Exporte SVG para o PDF e PNG de 300 dpi para o EPUB (confira no Kindle Previewer — `book-production` §7).
  ```bash
  npx -y @mermaid-js/mermaid-cli -i assets/imagens/IMG-07-funil.mmd -o assets/imagens/IMG-07-funil.svg
  ```
- **Nunca codifique informação só por cor**. No P&B, vermelho e verde viram o mesmo cinza. Use rótulo direto, padrão (hachura, tracejado) e diferença de cinza de pelo menos ~20 pontos percentuais entre áreas vizinhas.
- Teste: converta para cinza e imprima em A4 no tamanho final (`magick IMG-07.png -colorspace Gray teste.png`). Se não lê, refaça.
- Texto dentro da imagem ≥ 8 pt no tamanho final; nada de parágrafo dentro de diagrama — explicação vai no texto ou na legenda.
- Diagrama cabe na **mancha** (área de texto) da página; largura máxima = largura da mancha que o GARAMOND fixar em `production/specs.md`.

## 4. Geração com IA com consistência

Use `/social-freepik-generation` (Freepik). Antes de rodar geração **local** (Stable Diffusion, Flux ou similar), meça a máquina com `/machine-resources` e respeite o `MAX_PARALLEL`.

1. **Prompt base** fixo no `style-guide.md`: estilo, traço, paleta, luz, enquadramento, o que evitar. Ex.: "ilustração em traço preto fino sobre fundo branco, estilo editorial, sem texto, sem sombra, composição centrada".
2. **Variável por imagem**: só o assunto muda ("…uma pessoa organizando post-its numa parede").
3. **Referência**: passe 1–2 imagens aprovadas como referência de estilo; anote seed ou id do estilo quando a ferramenta oferecer.
4. **Variações**: gere 3–4, escolha uma, registre o prompt completo e a ferramenta no `image-log.md`.
5. **Revise**: mãos, texto ilegível dentro da imagem, objeto deformado, rosto parecido com pessoa real (descarte).

Imagem gerada **nunca** representa pessoa real, documento real ou evento real como se fosse foto.

## 5. Especificação técnica

| Item | Regra |
|---|---|
| Resolução | **≥ 300 dpi no tamanho final** (KDP pede ≥ 300 dpi e recomenda ≤ 600 dpi no miolo). Ex.: figura de 11 cm de largura → 11 / 2,54 × 300 = **1300 px** no mínimo |
| Miolo P&B | Converta você para tons de cinza e confira; a impressão escurece meios-tons — clareie sombras se precisar |
| Miolo colorido | Só se o livro precisa de cor (fotos, gráficos em cor). Custo de impressão KDP nos EUA, formato regular: P&B **US$ 1,00 + 0,012/página** (110–828 pág.); cor premium **US$ 1,00 + 0,065/página** (42–828 pág.); cor padrão **US$ 1,00 + 0,0255/página** (72–600 pág.) |
| Sangria | Imagem até a borda obriga o miolo **inteiro** com sangria (KDP: +0,125 pol na largura, +0,25 pol na altura) — avise o GARAMOND antes |
| Formato | SVG ou PDF vetorial para diagrama; PNG ou JPEG de alta qualidade para foto; nome `IMG-NN-<slug>` |
| Legenda e crédito | Toda figura numerada com legenda; crédito obrigatório para foto de terceiro (Lei 9.610/98, art. 79, §1º) |

Exemplo de custo: livro de 200 páginas em 6 × 9 pol → P&B US$ 1,00 + 200 × 0,012 = **US$ 3,40**; cor premium US$ 1,00 + 200 × 0,065 = **US$ 14,00** por exemplar. Cor só por causa de 4 fotos raramente compensa. Fonte: [Printing cost](https://kdp.amazon.com/en_US/help/topic/G201834340) e [Trim size, bleed and margins](https://kdp.amazon.com/en_US/help/topic/GVBQ3CMEQW3W2VL6), conferidos em 2026-11-17. Gráfica brasileira: peça orçamento P&B × cor com a tiragem.

## 6. Registro `IMG-NN` — sem registro a imagem não entra

Uma linha por imagem em `illustration/image-log.md`:

| Id | Arquivo | Origem | Licença / autorização | Crédito | Resolução | Onde aparece |
|---|---|---|---|---|---|---|
| IMG-07 | IMG-07-funil.svg | Desenho (Mermaid) | Própria | Elaborado pelo autor | vetor | CAP-03, fig. 3.2 |
| IMG-12 | IMG-12-oficina.jpg | Foto do autor | Própria; autorização de imagem das 2 pessoas (arquivo X) | Foto: acervo do autor | 3600 × 2400 | CAP-05 |
| IMG-15 | IMG-15-abertura.png | Gerada por IA — Freepik, prompt no log | Termos do plano Freepik conferidos em AAAA-MM-DD | — | 2480 × 3508 | Abertura CAP-01 |

Campos vazios = imagem fora do livro. BORGES confere o log contra as imagens do PDF e do EPUB no G3.

## 7. Direitos

- **Foto de terceiro**: o fotógrafo tem o direito (Lei 9.610/98, art. 7º, VII e art. 79). Precisa de licença por escrito para uso em livro, com crédito. "Achei no Google" não é licença.
- **Banco de imagem**: confira a licença do plano — uso em livro impresso, limite de tiragem, proibição de uso em capa ou de "uso sensível". Guarde o comprovante.
- **Domínio público**: obra de autor morto há mais de 70 anos, contados de 1º de janeiro do ano seguinte à morte (art. 41) — a foto nova de uma obra antiga pode ter dono.
- **Pessoa reconhecível**: precisa de **autorização de uso de imagem** por escrito (Código Civil, art. 20; Constituição, art. 5º, X), inclusive funcionário, cliente e familiar. Menor: autorização dos responsáveis.
- **Imagem gerada por IA**: a KDP define como conteúdo **gerado** por IA texto, imagens ou traduções criados por ferramenta de IA, **incluindo capa e imagens do miolo**, mesmo editados depois; isso **tem de ser declarado** no cadastro do livro. Conteúdo só **assistido** por IA (feito pelo autor e melhorado com IA) não precisa. Fonte: [Content Guidelines — AI-generated content](https://kdp.amazon.com/en_US/help/topic/G200672390), conferido em 2026-11-17. Omitir é piso 7. Imagem gerada pode não ter proteção autoral nem exclusividade — não registre como marca.
- Logo ou marca de terceiro em imagem: só com autorização ou em uso informativo justificado; na dúvida, LOBATO consulta.

## 8. Checklist para o G3 (BORGES)

- [ ] `style-guide.md` aprovado pelo autor; todas as imagens seguem o mesmo estilo.
- [ ] Toda imagem do PDF e do EPUB tem linha completa no `image-log.md` (piso 3).
- [ ] Autorização de uso de imagem guardada para cada pessoa reconhecível; licença de banco e de foto de terceiro guardada.
- [ ] Imagens geradas por IA listadas para a divulgação no cadastro KDP (passa ao LOBATO).
- [ ] 300 dpi no tamanho final; diagramas aprovados no teste em cinza; texto ≥ 8 pt.
- [ ] Legendas numeradas e créditos no formato do guia.

## 9. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "É só uma imagem de banco grátis" | Grátis não é sem licença. Registre a licença ou troque. |
| "No colorido dá para entender" | O miolo é P&B. Teste em cinza (§3). |
| "Foi a IA que fez, não precisa declarar" | A KDP exige declarar imagem gerada, inclusive a capa (§7). |
| "A pessoa aparece de lado, ninguém reconhece" | Se alguém que a conhece a reconhece, precisa de autorização. |
| "Gero 10 em paralelo para ganhar tempo" | Geração local pesa na máquina do usuário. `/machine-resources` primeiro. |

## Origem

Método próprio da squad; fatos públicos citados com link: Ajuda KDP (custos de impressão, sangria, conteúdo de IA, conferidos em 2026-11-17), Lei 9.610/98 (arts. 7º, 41, 46 e 79), Código Civil (art. 20) e Constituição Federal (art. 5º, X).
