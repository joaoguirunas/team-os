---
title: Sites Squad
type: squad-doc
status: active
created: 2026-04-24
updated: 2026-04-24
tags: [squad, sites]
related: ["[[../modules]]", "[[../architecture]]"]
---

# Squad sites — Websites / Next.js

## Visão geral

Squad especializada para websites, landing pages e projetos Next.js. Espelho da squad dev mas focada em sites: SEO, CRO, performance web, acessibilidade, Vercel/Netlify deployments, shadcn/ui, e integrações CMS.

## Composição

### sites-analyst (sonnet)
**Papel:** Research para websites — keyword research, competitor analysis, tech stack feasibility, SEO research, market analysis.
**Quando usar:** Antes de decisões arquiteturais em projetos de sites. On-demand only.
**Tools:** `Read, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### sites-architect (opus)
**Papel:** Arquitetura de sites + criação exclusiva de stories + module docs.
**Exclusividade:** Único que pode criar e validar stories (checklist de 5 pontos) em projetos de sites.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### sites-data (sonnet)
**Papel:** DB para websites — schema, migrations, RLS, query optimization, indexing.
**Protocolo obrigatório:** snapshot → dry-run → apply → smoke-test.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### sites-dev-alpha (sonnet)
**Papel:** Frontend para websites — React/Next.js, Tailwind, shadcn/ui, landing pages, client-side.
**Diferencial vs dev-dev-alpha:** Foco em shadcn/ui, landing pages e conversão.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### sites-dev-beta (sonnet)
**Papel:** Backend para websites — APIs, CMS integrations, server-side logic, third-party integrations.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### sites-dev-delta (sonnet)
**Papel:** Hardening para websites — Core Web Vitals, performance, edge cases.
**Diferencial vs dev-dev-delta:** Inclui Core Web Vitals como critério chave.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, SendMessage`

### sites-dev-gamma (sonnet)
**Papel:** Fullstack para websites — CRO features, SEO implementation, analytics wiring.
**Diferencial:** Especializado em features de conversão e SEO técnico.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### sites-devops (sonnet)
**Papel:** DevOps + release guardian para websites.
**Exclusividade:** ÚNICA autoridade para git push, Vercel/Netlify deployments, releases em projetos de sites.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### sites-qa (opus)
**Papel:** QA master para websites.
**Exclusividade:** ÚNICA autoridade para veredictos PASS/CONCERNS/FAIL/WAIVED.
**Diferencial:** Inclui checks de acessibilidade, copy quality, SEO validation, performance.
**Tools:** `Read, Glob, Grep, Bash, SendMessage` (+ Write, Edit para docs)

### sites-ux (sonnet)
**Papel:** UX para websites — research, wireframes, component specs, accessibility, visual design.
**Cobre:** Tanto UX research quanto design visual.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, SendMessage`

## Skills complementares da squad sites

| Skill | Função |
|---|---|
| `/sites-seo-keywords` | Keyword research e estratégia SEO |
| `/sites-seo-technical` | SEO técnico: meta tags, schema.org, sitemap |
| `/sites-copywriting` | Frameworks: AIDA, PAS, BAB, StoryBrand |
| `/sites-copy-editing` | Revisão e edição de copy |
| `/sites-page-cro` | Otimização de conversão |
| `/sites-tailwind-design-system` | Design system com Tailwind |
| `/sites-shadcn-ui` | Padrões shadcn/ui |
| `/sites-frontend-design` | Design e implementação frontend |
| `/sites-ux-interaction` | UX e micro-interações |
| `/sites-canvas-design` | Canvas HTML5 e SVG |
| `/sites-content-strategy` | Arquitetura de informação e hierarquia |
| `/sites-web-accessibility` | WCAG 2.1 AA, ARIA |
| `/sites-deployment` | Deploy Vercel/Netlify/Cloudflare |

## Fluxo típico

```
sites-analyst (keyword/competitor research)
  → sites-architect (stories + page structure)
    → sites-ux (UX spec + visual design)
    → sites-data (schema, se houver DB)
    → sites-dev-alpha (frontend) + sites-dev-beta (backend) em paralelo
    → sites-dev-gamma (SEO, analytics, CRO)
    → sites-dev-delta (Core Web Vitals, hardening)
    → sites-qa (PASS/FAIL + a11y + SEO)
    → sites-devops (Vercel deploy + PR)
```
