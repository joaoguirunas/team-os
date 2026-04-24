---
title: Modules — Catálogo de Agentes
type: modules
status: active
agent: dev-architect
created: 2026-04-24
updated: 2026-04-24
tags: [project, modules, agents]
related: ["[[overview]]", "[[architecture]]", "[[squads/dev-squad]]", "[[squads/sites-squad]]", "[[squads/social-squad]]", "[[squads/traffic-squad]]"]
---

# Catálogo Completo de Agentes (37 total)

## Squad dev — Software Complexo (10 agentes)

| Agente | Modelo | Papel | Tools especiais |
|---|---|---|---|
| `dev-analyst` | sonnet | Research, CVE, library comparison — on-demand only | WebSearch, WebFetch |
| `dev-architect` | opus | Arquitetura, stories (EXCLUSIVO), ADRs, module docs | WebSearch, WebFetch |
| `dev-data-engineer` | sonnet | DB: schema, migrations, RLS, indexing — snapshot→dry-run→apply | — |
| `dev-dev-alpha` | sonnet | Frontend: React, Next.js, Tailwind, UI components | — |
| `dev-dev-beta` | sonnet | Backend: APIs, services, business logic, integrações | — |
| `dev-dev-delta` | sonnet | Hardening: error handling, retry, edge cases — usa APÓS feature | WebSearch |
| `dev-dev-gamma` | sonnet | Fullstack: glue code, cross-layer, features que cruzam front+back | — |
| `dev-devops` | sonnet | **Autoridade exclusiva** git push, gh pr, CI/CD, releases | — |
| `dev-qa` | opus | **Autoridade exclusiva** veredictos PASS/CONCERNS/FAIL/WAIVED | — |
| `dev-ux` | sonnet | UX research, user flows, wireframes, component specs, a11y | WebFetch, WebSearch |

## Squad sites — Websites / Next.js (10 agentes)

| Agente | Modelo | Papel | Tools especiais |
|---|---|---|---|
| `sites-analyst` | sonnet | Keyword research, competitor analysis, SEO, feasibility | WebSearch, WebFetch |
| `sites-architect` | opus | Arquitetura de sites, stories (EXCLUSIVO), page structure | WebSearch, WebFetch |
| `sites-data` | sonnet | DB para websites — mesmo protocolo snapshot→dry-run→apply | — |
| `sites-dev-alpha` | sonnet | Frontend: React/Next.js, Tailwind, shadcn/ui, landing pages | — |
| `sites-dev-beta` | sonnet | Backend: APIs, CMS integrations, server-side, third-party | — |
| `sites-dev-delta` | sonnet | Hardening: Core Web Vitals, performance, edge cases | WebSearch |
| `sites-dev-gamma` | sonnet | Fullstack: CRO features, SEO implementation, analytics | — |
| `sites-devops` | sonnet | **Autoridade exclusiva** git push, Vercel/Netlify deployments | — |
| `sites-qa` | opus | **Autoridade exclusiva** veredictos + a11y + copy + SEO checks | — |
| `sites-ux` | sonnet | UX research, visual design, component specs, accessibility | WebFetch, WebSearch |

## Squad social — Redes Sociais (7 agentes)

> Agentes da squad social têm identidades alien race.

| Agente | Identidade | Modelo | Papel | MCPs |
|---|---|---|---|---|
| `social-analyst` | — | sonnet | Research, competitor analysis, hashtag strategy, benchmarking | WebSearch, WebFetch |
| `social-content` | **LYRIS** | sonnet | Copywriting + research via Apify (dual function) | Apify (RAG, call-actor) |
| `social-design` | **AEON** | sonnet | Key Visuals, carousels, templates via Google Stitch | Stitch, 21st Magic |
| `social-photo` | **IRIS** | sonnet | Fotos AI (produto, lifestyle, cinematic) via Freepik | Freepik (generate, upscale, reframe) |
| `social-publisher` | **PULSE** | sonnet | Publicação + analytics via Meta MCP (só após VERA aprova) | Meta (publish, schedule, insights) |
| `social-strategist` | **VERA** | opus | Validação editorial — NUNCA cria conteúdo, só valida e dirige | — |
| `social-video` | **FLUX** | sonnet | Reels, Stories, TikToks, Shorts via ffmpeg | — |

**Regra crítica da squad social:** VERA (social-strategist) DEVE aprovar ANTES de PULSE (social-publisher) publicar qualquer conteúdo.

## Squad traffic — Tráfego Pago (10 agentes)

| Agente | Modelo | Papel |
|---|---|---|
| `traffic-analyst` | sonnet | Performance intel: audiências, concorrentes, benchmarks, diagnóstico |
| `traffic-automation` | sonnet | Scripts bulk ops, Google/Meta/TikTok API, pipelines de dados |
| `traffic-bi` | sonnet | BI + atribuição: ROAS, LTV, CPA, multi-touch — fonte oficial de métricas |
| `traffic-copywriter` | sonnet | Copy de ads: headlines, descrições, CTAs, variantes A/B por plataforma |
| `traffic-designer` | sonnet | Criativos: banners, carousels, vídeos, assets para Stories |
| `traffic-google` | sonnet | Google Ads: Search, PMax, Shopping, YouTube, Display |
| `traffic-meta` | sonnet | Meta Ads: Facebook + Instagram, Advantage+, retargeting, lookalike, CAPI |
| `traffic-qa` | opus | **Autoridade exclusiva** pré-campanha: UTMs, pixels, compliance, PASS/FAIL |
| `traffic-strategist` | opus | **Autoridade exclusiva** stories de campanha + checklist 5 pontos |
| `traffic-tiktok` | sonnet | TikTok Ads: Spark Ads, In-Feed, TopView, pixel, criativos nativos |

**Fluxo obrigatório:** traffic-strategist (brief) → traffic-qa (PASS) → plataforma ativa

## Padrões de modelo

- **opus** = papéis de decisão/arquitetura/QA (dev-architect, dev-qa, sites-architect, sites-qa, social-strategist, traffic-strategist, traffic-qa)
- **sonnet** = papéis de execução, análise e produção (todos os outros 30 agentes)

## Todos os agentes têm

- Frontmatter: `name`, `description`, `model`, `memory: project`, `tools`, `color`
- Seção "Contrato com team-os" no corpo do prompt
- Instrução para comunicar via `SendMessage` ao concluir tasks
