---
name: dev-defuddle
description: Extrair markdown limpo de páginas web usando Defuddle CLI — remove ruído (nav, ads, sidebars) para obter conteúdo técnico puro. Para uso do Analyst e UX em research.
version: "1.1"
updated: "2026-04-21"
---

# Defuddle — Web Content Extraction

Defuddle extrai o conteúdo principal de páginas web em Markdown limpo, removendo navegação, anúncios, sidebars e qualquer elemento que não seja o conteúdo em si.

## Verificar disponibilidade antes de usar

**Sempre verificar antes de chamar defuddle:**

```bash
# Verificar se defuddle está disponível
which defuddle 2>/dev/null || npx --yes @kepano/defuddle-cli --version 2>/dev/null
```

- Se disponível globalmente → usar `defuddle {url}`
- Se não disponível → usar `npx @kepano/defuddle-cli {url}` (instala temporariamente)
- Se npx falhar (sem rede/permissão) → usar fallback `WebFetch` abaixo

## Instalação (por projeto, se necessário)

```bash
npm install -g @kepano/defuddle-cli
# ou via npx sem instalação
npx @kepano/defuddle-cli {url}
```

## Uso básico

```bash
# Extrair conteúdo de uma URL
defuddle https://docs.react.dev/learn/state-a-components-memory

# Salvar em arquivo para referência
defuddle https://example.com/article > docs/research/article-title.md

# Via npx (sem instalação prévia)
npx @kepano/defuddle-cli https://example.com/article
```

## Fallback obrigatório — quando defuddle não está disponível

```
WebFetch(url, "Extract the main technical content only, ignoring navigation, ads, sidebars, headers and footers. Return as clean markdown with headings, code blocks and lists preserved.")
```

Usar o fallback sempre que:
- `defuddle` não encontrado E `npx` falhar
- Página requer autenticação (defuddle não consegue)
- Timeout no CLI

## Quando usar

- Research de documentação técnica (comparar bibliotecas, ler specs)
- Capturar artigos técnicos para referência durante análise
- Extrair conteúdo de páginas de concorrentes para análise de produto
- Documentação de APIs externas para o Architect tomar decisões
- Research de UX patterns e referências visuais

## Onde salvar conteúdo extraído

```
docs/research/          → pesquisas técnicas gerais
docs/research/ux/       → referências de UX e design
docs/research/market/   → análise de concorrentes/mercado
```

## Fluxo típico do Analyst

```bash
# 1. Verificar disponibilidade
which defuddle 2>/dev/null && EXTRACTOR="defuddle" || EXTRACTOR="npx @kepano/defuddle-cli"

# 2. Extrair conteúdo limpo
$EXTRACTOR https://engineering.blog.example.com/approach-to-auth > docs/research/auth-approaches.md

# 3. Se CLI falhar, usar WebFetch como fallback
# 4. Revisar e sintetizar o conteúdo extraído
# 5. Entregar relatório ao Chief/Architect baseado em evidências
```

## Boas práticas

- Sempre citar fonte original no documento de research
- Extrair apenas o necessário — não acumular conteúdo desnecessário
- Conteúdo extraído é referência, não a decisão — Architect/Chief decidem
- Limpar arquivos de research após projeto concluído
- Nunca extrair conteúdo de páginas que exijam login sem autorização explícita
