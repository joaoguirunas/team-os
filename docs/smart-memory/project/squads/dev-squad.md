---
title: Dev Squad
type: squad-doc
status: active
created: 2026-04-24
updated: 2026-04-24
tags: [squad, dev]
related: ["[[../modules]]", "[[../architecture]]"]
---

# Squad dev — Software Complexo

## Visão geral

Squad para construção de software complexo: APIs, backends, frontends, bancos de dados, infraestrutura e qualidade. 10 agentes cobrindo todo o ciclo de vida de desenvolvimento.

## Composição

### dev-analyst (sonnet)
**Papel:** Research e análise — on-demand only. Entrega evidências, não decide.
**Quando usar:** Antes de decisões arquiteturais, comparação de libs, investigação de CVE, market analysis, análise de dependências.
**Tools:** `Read, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### dev-architect (opus)
**Papel:** Arquitetura + criação exclusiva de stories + ADRs + module docs.
**Quando usar:** Decisões de arquitetura, seleção de tech stack, design de API, qualquer criação de stories.
**Exclusividade:** Único que pode criar e validar stories (checklist de 5 pontos).
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### dev-data-engineer (sonnet)
**Papel:** Banco de dados — schema, migrations, RLS, query optimization, indexing.
**Quando usar:** Toda e qualquer tarefa de banco de dados.
**Protocolo obrigatório:** snapshot → dry-run → apply → smoke-test.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### dev-dev-alpha (sonnet)
**Papel:** Frontend — React, Next.js, Tailwind, UI components, client-side logic.
**Quando usar:** Stories de frontend e implementação de UI em software complexo.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### dev-dev-beta (sonnet)
**Papel:** Backend — APIs, services, business logic, performance, server-side integrations.
**Quando usar:** Stories de backend em software complexo.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### dev-dev-delta (sonnet)
**Papel:** Hardening e resiliência — error handling, retry logic, edge cases.
**Quando usar:** APÓS features implementadas. Mindset adversarial — encontra o que quebra.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebSearch, SendMessage`

### dev-dev-gamma (sonnet)
**Papel:** Fullstack — integração cross-layer, glue code, features que cruzam front + back.
**Quando usar:** Stories que não pertencem claramente ao frontend nem ao backend.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### dev-devops (sonnet)
**Papel:** DevOps + release guardian.
**Exclusividade:** ÚNICA autoridade para git push, gh pr create/merge, CI/CD, releases.
**Quando usar:** Push de código, criação de PRs, releases, operações de infraestrutura.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

### dev-qa (opus)
**Papel:** Quality assurance master.
**Exclusividade:** ÚNICA autoridade para emitir veredictos PASS / CONCERNS / FAIL / WAIVED.
**Quando usar:** Revisões de stories, QA gates, security checks, design de testes.
**Tools:** `Read, Glob, Grep, Bash, SendMessage` (+ Write, Edit para docs)

### dev-ux (sonnet)
**Papel:** UX specialist — research, user flows, wireframes, component specs, accessibility.
**Quando usar:** Research UX antes de features complexas e especificação de UI antes do dev-dev-alpha implementar.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, SendMessage`

## Fluxo típico

```
dev-analyst (research) 
  → dev-architect (stories + ADRs)
    → dev-ux (UX spec, se frontend)
    → dev-data-engineer (schema, se DB)
    → dev-dev-alpha (frontend) + dev-dev-beta (backend) em paralelo
    → dev-dev-delta (hardening)
    → dev-qa (PASS/FAIL)
    → dev-devops (push + PR)
```

## Composição mínima para uma story típica

- Backend only: `dev-architect` + `dev-dev-beta` + `dev-qa` + `dev-devops`
- Fullstack: + `dev-dev-alpha` ou `dev-dev-gamma`
- Com DB: + `dev-data-engineer`
- Com hardening: + `dev-dev-delta`
