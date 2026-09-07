---
name: sales-deck-production
description: Produção do artefato final de propostas e apresentações — HTML com print CSS (uma seção por página, quebras controladas, fontes embutidas) exportado para PDF em navegador headless, componentes de página (capa, índice, aberturas, tabela de investimento, compromisso conjunto, contracapa), variante deck, e checagem obrigatória do PDF gerado (contagem de páginas, overflow, fontes, peso). Use ao montar, exportar, corrigir ou auditar o PDF/deck de qualquer proposta.
version: "1.0"
updated: "2026-09-07"
---

# Sales Deck Production — HTML → PDF que abre, cabe e imprime

O entregável é o **PDF** (ou o deck exportado), não o HTML. Esta skill padroniza como construir o HTML para impressão, como exportar sem depender de rede e — sobretudo — como **verificar o PDF** antes de entregar. Marca, paleta, tipografia e componentes vêm do design system **do projeto** (apontado em `docs/smart-memory/project/brand.md`); a skill dá a mecânica, não o visual.

## 1. Estrutura do HTML

- Um arquivo por artefato, na pasta da proposta, nomeado conforme a convenção do projeto
- **Uma `<section class="page">` por página do §9 do planejamento** — nem mais, nem menos. Ordem idêntica
- `templates/page-skeleton.html` traz o esqueleto: `<head>` com fontes locais, `<style>` com `templates/print.css` embutido, seções nomeadas por `data-page="N"` e `data-title`
- Componentes de página (adaptar ao design system): `cover` · `toc` · `opener` (aberturas I/II/III) · `content` (título-asserção + corpo + prova) · `table` (investimento, compromisso conjunto) · `closing` (próximo passo) · `back-cover`
- Números e textos **copiados** da copy aprovada e da ficha de números — nunca digitados de memória

## 2. Print CSS — o que não pode faltar

```css
@page { size: A4; margin: 0; }            /* ou 16:9 para deck: size: 338.67mm 190.5mm */
html, body { margin: 0; padding: 0; }
.page { width: 210mm; height: 297mm; overflow: hidden; break-after: page; position: relative; box-sizing: border-box; }
.page:last-child { break-after: auto; }
table, figure, .card, blockquote, img, svg { break-inside: avoid; }
h1, h2, h3 { break-after: avoid; }
p { orphans: 3; widows: 3; }
* { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
```
Regras práticas:
- **Fundo na `.page`, nunca em `html`/`body`** — fundo no body gera página extra em branco
- `overflow: hidden` na `.page` para o excesso não vazar para uma página fantasma; o excesso é detectado na checagem (§4), não escondido silenciosamente — relatar à redatora
- Fontes: `@font-face` com arquivos **locais** (`file://` relativo) ou `data:` embutido; nunca `<link>` para CDN no export. Esperar `document.fonts.ready` antes de imprimir
- Imagens em resolução de impressão (≥ 150 dpi no tamanho final); SVG para logos e ícones
- Nada de animação, `position: fixed` global ou `100vh` — unidades em mm

## 3. Exportação headless

`scripts/html-to-pdf.mjs` — usa Playwright (ou Puppeteer, o que estiver instalado), abre o HTML local, espera fontes e imagens, imprime com `printBackground` e `preferCSSPageSize`.

```bash
# uma vez, no projeto ou globalmente
npm i -D playwright && npx playwright install chromium     # ou: npm i -D puppeteer

node .claude/skills/sales-deck-production/scripts/html-to-pdf.mjs \
  "{pasta}/{arquivo}.html" "{pasta}/{nome conforme convenção}.pdf" [--landscape] [--scale 1]
```
Saída: caminho do PDF + páginas + tamanho. Falhou por fonte/imagem não carregada → o script aborta; não entregue um PDF com fallback.

## 4. Checagem obrigatória do PDF

`scripts/check-pdf.sh <pdf> [--expect-pages N] [--max-mb 15] [--render]`

Verifica e imprime um relatório:
1. **Páginas** — conta real; com `--expect-pages`, falha se diferente do §9
2. **Peso** — alerta acima do limite (padrão 15 MB; anexo de e-mail)
3. **Fontes** — lista as embutidas; alerta se aparecer fallback genérico (Helvetica/Times/Arial não previstos no design system)
4. **Render** (`--render`, requer `pdftoppm` do poppler) — PNG da 1ª, do meio e da última página para inspeção visual: cortes, sobreposição, contraste, logo
5. **Texto** — extrai o texto para permitir os greps da régua editorial no artefato final (o QA usa)

Registrar o relatório em `docs/smart-memory/agents/design/{cliente-slug}-render.md`: páginas geradas vs. esperadas, fontes, peso, caminho do PDF, observações. **Sem relatório, o artefato não está pronto.**

## 5. Overflow — o que fazer

Texto que não cabe **não é problema de design para resolver cortando frase**: o texto é da redatora. Medir o excesso (linhas/caracteres), devolver com a página e o trecho. Só depois de ela ajustar, re-exportar. Alternativas legítimas do designer: ajustar grid, respiro e tamanho dentro das faixas que o design system permite — nunca abaixo do mínimo legível (≈ 9,5 pt em A4).

## 6. Deck (apresentação)

Mesma mecânica com `@page` 16:9 e uma `.page` por slide. Diferenças: **uma asserção por slide**, corpo é a evidência; tipografia maior (mínimo 18 pt para corpo); número de slides = estrutura aprovada. Exportar PDF para envio; manter o HTML para apresentar (navegador em tela cheia, `F11`). Para decks navegáveis com controles, a skill `slides` do catálogo dá a estrutura; a marca continua vindo do design system do projeto.

## 7. Versão navegável do planejamento interno

Quando a convenção do projeto pede um `.html` do planejamento: converter o markdown com o mesmo `<head>` de fontes e um CSS de leitura (não de impressão), com o aviso *documento interno* fixo no topo. Nunca gerar PDF dele — é para revisão em tela.

## 8. Checklist de entrega

- [ ] `.page` = páginas do §9, na ordem, títulos iguais ao índice
- [ ] Fontes locais/embutidas; `document.fonts.ready` esperado
- [ ] Export headless concluído sem erro
- [ ] `check-pdf.sh` rodado: páginas ✓, peso ✓, fontes ✓, render inspecionado
- [ ] Relatório de render salvo na smart-memory
- [ ] Nome do arquivo e versão conforme a convenção; versão anterior preservada
