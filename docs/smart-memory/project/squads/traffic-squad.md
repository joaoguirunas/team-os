---
title: Traffic Squad
type: squad-doc
status: active
created: 2026-04-24
updated: 2026-04-24
tags: [squad, traffic]
related: ["[[../modules]]", "[[../architecture]]"]
---

# Squad traffic — Tráfego Pago

## Visão geral

Squad para gestão cross-platform de tráfego pago: Google Ads, Meta Ads e TikTok Ads. 10 agentes cobrindo o ciclo completo: inteligência de mercado → estratégia → creative → QA → ativação → BI.

## Composição

### traffic-analyst (sonnet)
**Papel:** Performance intel — audiências, concorrentes, tendências, benchmarks, diagnóstico.
**Quando usar:** Pesquisa de audiência, análise de concorrência, benchmarks de setor. On-demand only — entrega evidências.
**Tools:** `Read, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### traffic-automation (sonnet)
**Papel:** Scripts de automação e integrações API — bulk operations, Google/Meta/TikTok APIs, pipelines.
**Quando usar:** Automações em escala, scripts de gestão, integrações entre plataformas, pipelines de dados.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### traffic-bi (sonnet)
**Papel:** BI e atribuição — consolida métricas de todas as plataformas, calcula ROAS, LTV, CPA, atribuição multi-touch.
**Autoridade:** Fonte oficial de verdade para todas as métricas da squad.
**Quando usar:** Dashboards, relatórios de performance, análise de atribuição.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### traffic-copywriter (sonnet)
**Papel:** Copy de anúncios — headlines, descrições, CTAs, variantes A/B por plataforma.
**Quando usar:** Criar e otimizar copy de ads, roteiros de vídeo para ads, variantes de teste.
**Conhecimento:** Limites de caractere e best practices de cada plataforma.
**Tools:** `Read, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### traffic-designer (sonnet)
**Papel:** Criativos para ads — banners, carousels, vídeos, assets para Stories.
**Quando usar:** Criação de criativos, specs de assets, revisão de materiais antes do upload.
**Garante:** Brand-consistency e conformidade com specs de cada plataforma.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, SendMessage`

### traffic-google (sonnet)
**Papel:** Google Ads — Search, Performance Max, Shopping, YouTube, Display.
**Quando usar:** Setup, otimização e gestão de campanhas Google Ads.
**Pré-requisito:** Briefing aprovado pelo traffic-strategist + validação traffic-qa.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### traffic-meta (sonnet)
**Papel:** Meta Ads — Facebook + Instagram, Ads Manager, Advantage+, retargeting, lookalike, pixel/CAPI.
**Quando usar:** Setup, otimização e gestão de campanhas Meta.
**Pré-requisito:** Briefing do traffic-strategist + aprovação traffic-qa.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### traffic-qa (opus)
**Papel:** QA pré-campanha.
**Exclusividade:** ÚNICA autoridade para veredictos PASS/CONCERNS/FAIL/WAIVED.
**Valida:** UTMs, pixels, compliance de plataforma, copy, criativos, configuração.
**Regra crítica:** Sem QA aprovado, NENHUMA campanha sobe.
**Tools:** `Read, Glob, Grep, Bash, WebSearch, SendMessage`

### traffic-strategist (opus)
**Papel:** Estratégia cross-platform — planejamento, alocação de budget, KPIs, briefings.
**Exclusividade:** ÚNICA autoridade para criar stories de campanha e validá-las (checklist de 5 pontos).
**Quando usar:** Planejamento estratégico, briefings, distribuição de budget, definição de objetivos.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### traffic-tiktok (sonnet)
**Papel:** TikTok Ads — Spark Ads, In-Feed, TopView, Brand Takeover, TikTok Ads Manager.
**Quando usar:** Setup, otimização e gestão de campanhas TikTok.
**Pré-requisito:** Briefing do traffic-strategist + aprovação traffic-qa.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

## Fluxo obrigatório

```
traffic-analyst (inteligência de mercado)
  → traffic-strategist ← AUTORIDADE: cria briefing + stories
    → traffic-copywriter (copy de ads)
    → traffic-designer (criativos)
    → traffic-qa ← GATE OBRIGATÓRIO (PASS/FAIL antes de qualquer ativação)
      → traffic-google (Google Ads)
      → traffic-meta (Meta Ads)         ← ativação em paralelo
      → traffic-tiktok (TikTok Ads)
        → traffic-bi (consolidação de métricas + relatórios)
        → traffic-automation (automações e otimizações em escala)
```

## Plataformas suportadas

| Plataforma | Agente responsável |
|---|---|
| Google Search, PMax, Shopping, YouTube, Display | `traffic-google` |
| Facebook + Instagram (Ads Manager, Advantage+) | `traffic-meta` |
| TikTok (Spark Ads, In-Feed, TopView, Brand Takeover) | `traffic-tiktok` |

## Métricas e BI

Todas as métricas são consolidadas pelo `traffic-bi`:
- **ROAS** (Return on Ad Spend)
- **LTV** (Lifetime Value)
- **CPA** (Cost per Acquisition)
- **Atribuição multi-touch** entre plataformas
