---
name: sites-seo-keywords
description: Keyword research e estratégia de conteúdo SEO — intent, clustering, mapeamento por página. Injectado em NEXUS (sites-seo).
---

# Sites SEO Keywords — Research e Estratégia

## Search Intent (tipos)

| Intent | Tipo de query | Página ideal |
|---|---|---|
| **Informational** | "como fazer X" | Blog, guia, FAQ |
| **Navigational** | "marca login" | Homepage, login |
| **Commercial** | "melhor X para Y" | Comparativo, landing |
| **Transactional** | "comprar X", "X preço" | Produto, pricing |

## Keyword mapping por página

```markdown
## Mapeamento — [Nome da Página]

**URL:** /caminho
**Keyword primária:** [keyword principal] — [volume/mês]
**Search intent:** [informational|navigational|commercial|transactional]
**Keywords secundárias:**
  - [keyword 2] — [volume]
  - [keyword 3] — [volume]
**LSI keywords:** [termos relacionados semanticamente]

**Implementação:**
- Title: [keyword primária] no início
- H1: variação natural da keyword primária
- H2s: keywords secundárias
- Body: keywords LSI distribuídas naturalmente
- Alt texts: descrição relevante com keyword quando natural
```

## Clusters de conteúdo

```
Pillar page (broad keyword)
    └── Cluster 1 (long-tail específico)
    └── Cluster 2 (long-tail específico)
    └── Cluster 3 (long-tail específico)
```

## Critérios de selecção de keywords

1. **Volume** — > 100 pesquisas/mês (nicho) ou > 1.000 (geral)
2. **Dificuldade** — KD < 40 para novos sites, < 70 para sites estabelecidos
3. **Intent** — Alinha com o objectivo da página
4. **Relevância** — Directamente relacionada com o produto/serviço

## Metas por tipo de página

| Página | Title (máx) | Description (máx) | H1 |
|---|---|---|---|
| Home | 60 chars | 160 chars | 1 (keyword primária) |
| Produto | 60 chars | 160 chars | 1 (keyword produto) |
| Blog | 60 chars | 155 chars | 1 (keyword artigo) |
