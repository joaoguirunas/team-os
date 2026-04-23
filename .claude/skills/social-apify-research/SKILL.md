---
name: social-apify-research
description: Research de tendências e concorrentes via Apify MCP — Instagram, TikTok, hashtags e análise de engagement. Injectado em LYRIS (social-content).
---

# Social Apify Research — Research via Apify MCP

## Casos de uso principais

### 1. Trend research por nicho
Identificar o que está a viralizar num nicho específico para informar criação de conteúdo.

**Output esperado:**
```markdown
## Trends — [Nicho] — [Data]

**Formatos em alta:**
- Reels curtos (15-30s) com [padrão]
- Carousels sobre [tema]

**Sounds/músicas trending:**
- [Nome do som] — [nº de vídeos]

**Temas virais:**
- [Tema 1]: [por que está a crescer]
- [Tema 2]: ...

**Padrões de copy:**
- Hooks frequentes: "...", "..."
- CTAs mais usados: "..."
```

### 2. Análise de concorrentes
Perceber o que funciona para concorrentes directos.

**Métricas a recolher:**
- Posts com maior engagement (últimos 30 dias)
- Formatos mais usados
- Frequência de publicação
- Hashtags mais usadas
- Horários de publicação

### 3. Hashtag research
Identificar hashtags com bom volume e competição adequada.

**Output:**
```markdown
## Hashtags — [Nicho]

**Volume alto, competição alta (awareness):**
#hashtag — Xk posts

**Volume médio, nicho (reach):**
#hashtag — Xk posts

**Volume baixo, muito específico (conversão):**
#hashtag — Xk posts

**Recomendação mix:** 3 alta + 7 média + 5 baixa
```

## Protocolo de research

1. Definir nicho e mercado (PT, BR, ES, EN)
2. Identificar 5-10 concorrentes directos
3. Correr scrapers Apify relevantes
4. Consolidar dados em relatório estruturado
5. Extrair 3-5 insights accionáveis para LYRIS implementar em copy

## Frequência recomendada
- Trend research: semanal
- Análise de concorrentes: quinzenal
- Hashtag research: mensal ou por campanha
