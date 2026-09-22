# team-os

### Pack de orquestração para Claude Code Agent Teams — *by João Guirunas*

**95 agentes e 107 skills** organizados em 10 squads (Dev, Sites, Social, Traffic, PM, Sales, Brand, Finance, Legal, SEO), com a skill `/team-os` para orquestrar sessões, a `/team-os-creator` para gerar e instalar squads em qualquer projeto, e a `/maestri-os` (opt-in) como **Sala de Controle** para quem usa o [Maestri](https://maestri.app) — roteia pedidos entre os terminais dos seus projetos. Todo agente segue o **Native Teams Protocol** — autônomo, com smart-memory integrada (formato Obsidian) e coordenação peer-to-peer.

> Este repositório é a **fonte da verdade**: edite agentes e skills **aqui**, audite com `/team-os-creator *audit` e propague para os projetos destino com `/team-os-creator *propagate`. Nunca edite agentes direto no destino.

---

## Por que team-os?

Times de IA superam uma sessão única quando o trabalho tem partes independentes. O team-os transforma isso em algo pronto pra usar:

- **Paralelismo real** — várias sessões trabalham ao mesmo tempo, cada uma com seu próprio context window. Research, review e features divididas por módulo terminam em uma fração do tempo de uma sessão sequencial.
- **Especialização com autoridade clara** — 56 papéis prontos, com fronteiras explícitas (quem cria story, quem dá veredicto de QA, quem faz `git push`). Sem sobreposição, sem agente pisando no outro.
- **Coordenação autônoma** — comunicação peer-to-peer + TaskList compartilhada + self-claim. Os teammates se organizam sozinhos; o lead orquestra em vez de microgerenciar.
- **Memória que persiste** — smart-memory em formato Obsidian acumula arquitetura, decisões, stories e QA entre sessões. O time não recomeça do zero.
- **Qualidade embutida** — hooks (`block-git-push`, gates de task), QA com veredicto formal PASS/CONCERNS/FAIL/WAIVED e plan mode obrigatório em mudanças de risco (schema, auth, CI/CD).
- **Custo sob controle** — política de modelos **Híbrida**: `opus` só onde o raciocínio é crítico (arquitetura, veredictos), `inherit` no resto (seguem o `/model` do lead). Você baixa a frota inteira pra um modelo barato quando quiser.
- **Reuso instantâneo** — `/team-os-creator *install` leva squads + skills + smart-memory para qualquer projeto. Uma fonte da verdade, propagação controlada.
- **Menos context-rot** — cada agente é isolado: exploração e logs ficam no context dele, não no seu.

---

## Índice

- ⭐ [the team-os Method](#-the-team-os-method) — a metodologia
1. [Conceitos fundamentais](#1-conceitos-fundamentais)
2. [Pré-requisitos e setup](#2-pré-requisitos-e-setup)
3. [Skill principal: `/team-os`](#3-skill-principal-team-os)
4. [Skill principal: `/team-os-creator`](#4-skill-principal-team-os-creator)
5. [Os 95 agentes e suas skills](#5-os-95-agentes-e-suas-skills)
6. [Catálogo de skills de apoio](#6-catálogo-de-skills-de-apoio)
7. [Tutorial passo a passo](#7-tutorial-passo-a-passo)
8. [Modelo de coordenação](#8-modelo-de-coordenação)
9. [Política de modelos (Híbrido)](#9-política-de-modelos-híbrido)
10. [Hooks de qualidade](#10-hooks-de-qualidade)
11. [Estrutura do repositório](#11-estrutura-do-repositório)
12. [Troubleshooting](#12-troubleshooting)
13. [Manutenção do CT](#13-manutenção-do-ct)

---

## ⭐ the team-os Method

A metodologia que torna o pack repetível para a sua equipe e seus mentorados. São **duas camadas** e **7 fases**.

### Duas camadas

```
CAMADA 1 — CT (configuração e manutenção, no command center)
  abre `claude` (puro) na pasta do CT
   └─ /team-os-creator  →  escaneia os projetos irmãos e mostra status (team-os? agentes? drift?)
        ├─ [1] Criar equipe       → novos agentes/squad (Native Teams Protocol + smart-memory + skills + modelo híbrido)
        ├─ [2] Atualizar equipes  → propaga o drift para os projetos
        └─ [3] Instalar equipe    → instala squad + skills + team-os num projeto
   → cada projeto passa a ter: agentes + skills + /team-os  (NUNCA team-os-creator)

CAMADA 2 — Projeto (execução, toda sessão de trabalho)
  abre `claude agents` (agent view)
   └─ /team-os  (SEMPRE o 1º comando da sessão)
        ├─ valida Agent Teams nativo
        ├─ sem smart-memory? → Discovery: lê o codebase e a constrói ANTES de começar
        └─ organiza o time com paralelismo máximo e dispara a execução
```

### As 7 fases

| # | Fase | O que acontece | Onde |
|---|---|---|---|
| 1 | **Setup** | Instalar a squad no projeto via `/team-os-creator *install` (uma vez por projeto). | CT |
| 2 | **Bootstrap** | `/team-os` no início de **toda** sessão — valida o ambiente de Agent Teams nativo. | Projeto |
| 3 | **Discovery** | Sem smart-memory? O team-os lê o codebase real e **constrói a smart-memory populada** antes de qualquer trabalho. | Projeto |
| 4 | **Team Design** | Objetivo → mapeia **workstreams independentes** → spawna o time certo (**comece com 3-5**, 1 por workstream independente, sem teto fixo), com ownership exclusivo de arquivos — onde o ownership não é disjunto, serializa com task dependencies. | Projeto |
| 5 | **Parallel Execution** | TaskList compartilhada + self-claim + comunicação **peer-to-peer** entre teammates. | Projeto |
| 6 | **Sync & QA** | Veredictos formais (PASS/CONCERNS/FAIL/WAIVED), gates por hook, hardening. | Projeto |
| 7 | **Memory & Ship** | Cada agente grava findings na smart-memory; DevOps faz push/PR/release. | Projeto |

### Princípios

- **Paralelismo é o default, sem teto fixo.** O limite não é um número mágico — é **independência real** (ownership de arquivos disjunto) + budget de tokens. N módulos independentes → N agentes, seja 5 ou 15.
- **Smart-memory é o cérebro compartilhado.** Todo agente lê ao iniciar e grava ao concluir. O time nunca recomeça do zero.
- **Autoridade clara, sem sobreposição.** Quem cria story, quem dá veredicto, quem faz push — cada papel tem fronteira explícita.
- **Uma fonte da verdade.** Tudo nasce no CT e é propagado; nunca se edita agente direto no projeto.

---

## 1. Conceitos fundamentais

| Conceito | O que é |
|---|---|
| **Agent Teams** | Recurso (experimental) do Claude Code onde várias sessões trabalham em paralelo como um time. Uma sessão é o **lead**; as demais são **teammates**, cada uma com seu próprio context window. |
| **Lead nativo** | A **main session** do Claude Code é o lead — não existe agente "orquestrador". O lead spawna teammates, distribui tasks e sintetiza resultados. |
| **Teammate** | Sessão independente spawnada pelo lead a partir de uma definição em `.claude/agents/`. Comunica-se **peer-to-peer** com outros teammates via `SendMessage`. |
| **Subagent** | Mesma definição rodando como helper dentro de uma sessão (reporta só ao chamador). Os arquivos em `.claude/agents/` servem aos dois modos. |
| **TaskList nativo** | Lista de tasks compartilhada pelo time. Estados `pending → in_progress → completed`, com dependências e **self-claim**. |
| **Smart-memory** | Base de conhecimento persistente em `docs/smart-memory/` (formato Obsidian: frontmatter YAML + wikilinks `[[...]]` + tags). *Source of truth* que todo agente lê ao iniciar e atualiza ao concluir. |
| **Native Teams Protocol** | Contrato que todo agente do CT carrega: smart-memory como fonte da verdade, TaskList nativo, comunicação peer-to-peer, sem nested teams. |
| **Skill** | Conhecimento carregável (`/nome-skill`). Em Agent Teams, skills são carregadas do projeto/usuário (o campo `skills:` do frontmatter é ignorado). |

**Agent Teams vs Subagents:** use **Agent Teams** quando os trabalhadores precisam conversar entre si, dividir um trabalho complexo e se coordenar. Use **subagents** quando você só quer um worker focado que reporta um resultado de volta.

---

## 2. Pré-requisitos e setup

1. **Claude Code** com Agent Teams habilitado. Em `~/.claude/settings.json`:
   ```json
   {
     "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
     "teammateMode": "auto"
   }
   ```
   Reinicie o Claude Code após adicionar. Sem essa variável, nenhum time é criado.

2. **`teammateMode`** (opcional): default `"in-process"` (todos no terminal principal, agent panel ativo). Use `"auto"` para split panes em tmux/iTerm2.

3. A skill `/team-os` faz esse check e corrige o `settings.json` automaticamente — basta carregá-la.

---

## 3. Skill principal: `/team-os`

**Bootstrap e orquestração de sessão.** É **distribuída para todos os projetos** (instalada junto com a squad) — você a carrega no **início de cada sessão** do projeto para coordenar múltiplos agentes em paralelo. No CT ela também existe. (A única skill que NÃO vai para os projetos é a `/team-os-creator`.)

> **Lead Discipline (regra dura):** com `/team-os` ativo, a sessão principal é **orquestrador puro** — nunca escreve código, pesquisa ou redige entregável sozinha. Para qualquer ação de trabalho ela **spawna um agente e fica livre** (monitorando, roteando, sintetizando). 1 tarefa = 1 agente, até as pequenas.

> **Team Persistence (regra dura):** o lead **nunca encerra o time sozinho**. Terminou uma rodada? Sintetiza, mantém os teammates vivos e **pergunta se há mais tasks** — só encerra quando você pede. E lembre: linha some do painel após ~30s = idle (agente **vivo**, não encerrado); reative com `SendMessage` pelo nome.

### O que ela faz, em fases
1. **Scan silencioso** — lê `settings.json` (env + teammateMode), mapeia `.claude/agents/`, lê `docs/smart-memory/INDEX.md`, **pesa a smart-memory** (`weigh-memory.sh`) e roda `TaskList`.
2. **Dashboard de abertura** — mostra status do ambiente e pergunta o **objetivo da sessão**.
3. **Correções automáticas** — injeta `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` se faltar, sugere `teammateMode`, oferece bootstrap da smart-memory.
4. **Análise do objetivo** — classifica o trabalho (research / implementação / review / mixed) e mapeia o paralelismo real.
5. **Dimensionamento** — `tasks independentes ÷ 5 = nº de agentes`; research adversarial = 3-5 sempre.
6. **Proposta de time** — agentes, ownership exclusivo de paths, plan mode onde há risco, skills por agente, modelo sugerido.
7. **Orquestração** — cria as tasks no TaskList com dependências e orienta o spawn.

### Comandos
```
/team-os                → bootstrap completo da sessão
/team-os *env           → só verificar/corrigir settings.json
/team-os *memory        → status/bootstrap da smart-memory
/team-os *compact       → compactação integral (mecânica + archivist), 1 confirmação; --auto sem confirmação
/team-os *tasks         → mostrar a task list atual
/team-os *spawn {desc}  → proposta de time para {desc} (pula o scan)
/team-os *status        → dashboard do time atual
```

### Boas práticas que ela aplica
- **Spawn prompts cirúrgicos** (papel + paths de ownership + contexto + entregável + como reportar).
- **Ownership exclusivo de arquivos** — dois agentes nunca no mesmo arquivo.
- **Plan mode** obrigatório em alto risco (schema, auth, CI/CD, refactors grandes, breaking changes).
- **Não encerrar o time cedo** — se o lead "concluir" com tasks abertas, ela orienta a continuar.

---

## 4. Skill principal: `/team-os-creator`

**Factory de agentes.** Existe **somente no CT**. Gera arquivos `.claude/agents/*.md` completos (Native Teams Protocol + smart-memory) a partir de **8 archetypes** e presets de squad, e mantém os agentes alinhados.

### Comandos
```
/team-os-creator                → menu principal (scan + sugestões)
/team-os-creator *analyze       → detecta archetype/stack, sem criar
/team-os-creator *squad <preset>→ cria uma squad inteira (dev/sites/social/traffic/pm/sales/brand/finance/legal)
/team-os-creator *create <role> → cria UM agente interativamente
/team-os-creator *migrate       → migra agentes do padrão antigo p/ Native Teams Protocol
/team-os-creator *bootstrap     → cria docs/smart-memory/ + injeta protocolo no CLAUDE.md
/team-os-creator *skills <ag>   → enriquece um agente com skills relevantes
/team-os-creator *audit         → valida compliance de todos os agentes
/team-os-creator *propagate     → propaga agentes atualizados p/ outros projetos
/team-os-creator *install       → instala squads + skills + smart-memory num projeto destino
```

### Os 8 archetypes
| Archetype | Quando usar | Model | isolation |
|---|---|---|---|
| `architect` | Design arquitetural, ADRs, stories | `opus` | — |
| `implementer` | Escreve código (front/back/fullstack) | `inherit` | — |
| `hardening` | Resiliência, retry, edge cases (após features) | `inherit` | — |
| `reviewer` | QA com veredicto formal, read-only | `opus` | — |
| `researcher` | Pesquisa técnica, libs, CVEs | `inherit` | — |
| `data` | Schema, migrations, queries, RLS | `inherit` | — |
| `devops` | Git, push, PRs, CI/CD, releases | `inherit` | — |
| `ux` | UX research, component specs, a11y | `inherit` | — |

> Não existe archetype de lead/orquestrador — a main session já é o lead nativo (regra absoluta da skill).

### Regras absolutas da factory
- Nunca cria agente sem `memory: project`.
- Sempre injeta o bloco **Native Teams Protocol** (nunca o antigo "Contrato com team-os").
- Sempre valida com `validate-agent.sh` após criar.
- Idempotente — se o agente existe, oferece atualizar / pular / renomear / cancelar.
- `*install` sempre faz bootstrap da smart-memory no destino.
- `team-os` e `team-os-creator` nunca vão para projetos destino.

---

## 5. Os 95 agentes e suas skills

Spawne pelo nome do arquivo, ex.:
`"Spawn um teammate usando o agente dev-architect para mapear a arquitetura de auth"`.

A coluna **Skills relacionadas** é um mapa de skills **recomendadas/disponíveis por papel** — as skills de apoio que fazem sentido para cada agente acionar via `/nome-skill` conforme a necessidade. Ela **não** reflete linha a linha o que o body de cada agente lista (vários agentes citam só um subconjunto, ou nenhuma, no próprio arquivo); serve como guia de qual skill ativar para qual tipo de trabalho. O `/team-os` pode incluí-las no spawn prompt.

> **Nota sobre veredictos QA:** as squads de código (`dev`/`sites`/`traffic`) usam PASS/CONCERNS/FAIL/WAIVED; as squads em contexto PT-BR usam taxonomia própria deliberada — `pm-qa`: APROVADO/PENDÊNCIAS/REPROVADO; `social-strategist`: APROVADO/COM RESSALVAS/REJEITADO (a squad social não tem QA dedicado — a VERA acumula validação editorial + veredicto, exceção deliberada da squad de 6).

### Dev — Fullstack SaaS (12)

> Sem teto de tamanho por squad — a dev inclui a camada completa de dados/BI (`dev-bi`, `dev-data-engineer`, `dev-data-performance`), chegando a 12.
| Agente | Papel | Skills relacionadas |
|---|---|---|
| `dev-analyst` | Pesquisa técnica, libs, CVEs, feasibility | `/deep-research`, `/data-analytics-engineering` |
| `dev-architect` | Arquitetura, ADRs, **criação/validação de stories** (exclusivo) | `/dev-api-design`, `/dev-technical-writing`, `/dev-database-patterns` |
| `dev-bi` | Data architect & dashboards (SELECT-only) | `/data-analytics-engineering`, `/data-sql-optimization`, `/data-lake-platform` |
| `dev-data-engineer` | Schema, migrations, RLS, otimização | `/dev-database-patterns`, `/data-sql-optimization`, `/dev-security-patterns` |
| `dev-data-performance` | Insights, anomalias, forecasts | `/data-analytics-engineering`, `/ai-ml-data-science`, `/ai-ml-timeseries` |
| `dev-ux` | UX research + design visual + a11y | `/ui-ux-pro-max`, `/accessibility`, `/web-design-guidelines` |
| `dev-dev-alpha` | Frontend (React, Next.js, Tailwind) | `/dev-typescript-patterns`, `/dev-testing-strategy`, `/dev-error-handling` |
| `dev-dev-beta` | Backend (APIs, serviços, lógica) | `/dev-api-design`, `/dev-error-handling`, `/dev-database-patterns` |
| `dev-dev-gamma` | Fullstack / cross-layer | `/dev-typescript-patterns`, `/dev-database-patterns`, `/dev-error-handling` |
| `dev-dev-delta` | Hardening e resiliência | `/dev-security-patterns`, `/dev-testing-strategy`, `/dev-error-handling` |
| `dev-qa` | Veredictos PASS/CONCERNS/FAIL/WAIVED (exclusivo) | `/dev-testing-strategy`, `/dev-security-patterns` |
| `dev-devops` | `git push`, PRs, CI/CD, releases (exclusivo) | `/dev-git-workflow` |

### Sites — Sites e landing pages (10)

> **Duas stacks, uma squad:** Next.js (App Router) ou Astro (Content Collections, Islands Architecture) — o `sites-architect` decide qual usar por projeto (ou um híbrido das duas), registrado como ADR. `/sites-frontend-stack` e `/sites-seo-technical` cobrem as duas stacks lado a lado, com a mesma profundidade. Astro é a recomendação padrão quando SEO/Core Web Vitals são a prioridade — HTML puro por padrão, JS só onde uma ilha pede explicitamente.

| Agente | Papel | Skills relacionadas |
|---|---|---|
| `sites-analyst` | Keyword/competitor research, feasibility | `/deep-research`, `/sites-seo-keywords` |
| `sites-architect` | Arquitetura de páginas, stories (exclusivo) | `/dev-api-design`, `/dev-technical-writing`, `/sites-seo-technical` |
| `sites-data` | Schema, migrations, RLS (sites) | `/dev-database-patterns`, `/data-sql-optimization` |
| `sites-ux` | UX research + design visual + a11y | `/sites-ux-interaction`, `/ui-ux-pro-max`, `/accessibility`, `/sites-frontend-stack` |
| `sites-dev-alpha` | Frontend / landing pages (shadcn) | `/sites-frontend-stack`, `/sites-scroll-motion`, `/ui-ux-pro-max`, `/nextjs-react-best-practices`, `/verify-before-done` |
| `sites-dev-beta` | Backend / CMS / integrações | `/dev-api-design`, `/dev-error-handling`, `/dev-database-patterns` |
| `sites-dev-gamma` | CRO, SEO, analytics, fullstack | `/sites-page-cro`, `/sites-seo-technical`, `/dev-typescript-patterns` |
| `sites-dev-delta` | Hardening, Core Web Vitals | `/dev-security-patterns`, `/dev-error-handling`, `/accessibility`, `/verify-before-done` |
| `sites-qa` | QA: a11y, SEO, copy, performance | `/dev-testing-strategy`, `/testing-playwright-e2e`, `/web-design-guidelines`, `/sites-seo-technical`, `/accessibility`, `/sites-copy`, `/verify-before-done` |
| `sites-devops` | Deploy Vercel/Netlify, CI/CD | `/dev-git-workflow`, `/sites-deployment` |

### Social — Social media (6)
| Agente | Persona | Papel | Skills relacionadas |
|---|---|---|---|
| `social-content` | LYRIS | Research (Apify) + copywriting | `/social-copywriting`, `/social-scriptwriting`, `/social-editorial-validation`, `/social-format-specs`, `/social-apify-research` |
| `social-design` | AEON | Key visuals, carrosséis (Stitch) | `/social-key-visual`, `/social-carousel-design`, `/social-stitch-workflow` |
| `social-photo` | IRIS | Fotos AI (Freepik) | `/social-freepik-generation`, `/social-cinematic-composition` |
| `social-publisher` | PULSE | Publicação (Meta) + métricas | `/social-meta-publishing`, `/social-analytics` |
| `social-strategist` | VERA | Estratégia + validação editorial (gate) | `/social-editorial-validation`, `/social-format-specs` |
| `social-video` | FLUX | Reels/Stories/Shorts (ffmpeg) + vídeo com avatar AI (HeyGen) | `/social-video-editing`, `/social-heygen-avatar`, `/social-scriptwriting`, `/social-cinematic-composition` |

> Regra do squad Social: `social-publisher` **só publica** após aprovação da `social-strategist` (VERA) **e** confirmação explícita do usuário.

### Traffic — Tráfego pago (10)
| Agente | Papel | Skills relacionadas |
|---|---|---|
| `traffic-analyst` | Audiências, concorrência, benchmarks | `/deep-research`, `/social-analytics`, `/traffic-google-ads-mcp`, `/traffic-ga4-mcp` |
| `traffic-automation` | Bulk ops, APIs Google/Meta/TikTok | `/dev-api-design`, `/dev-error-handling`, `/traffic-google-ads-mcp`, `/traffic-analytics-tracking` |
| `traffic-bi` | Atribuição, ROAS/LTV/CPA (fonte de verdade) | `/data-analytics-engineering`, `/data-sql-optimization`, `/traffic-ga4-mcp`, `/traffic-google-ads-mcp`, `/traffic-analytics-tracking` |
| `traffic-copywriter` | Copy de anúncios, variantes A/B | `/social-copywriting`, `/tiktok-marketing`, `/traffic-paid-ads-optimization` |
| `traffic-designer` | Criativos (banners, carrosséis, vídeos) | `/social-key-visual`, `/social-carousel-design`, `/ui-ux-pro-max` |
| `traffic-google` | Google Ads (Search, PMax, Shopping, YT) | `/social-analytics`, `/traffic-google-ads-mcp`, `/traffic-ga4-mcp`, `/traffic-paid-ads-optimization` |
| `traffic-meta` | Meta Ads (FB + IG, Advantage+) | `/social-meta-publishing`, `/social-analytics`, `/traffic-paid-ads-optimization` |
| `traffic-qa` | Compliance pré-launch (UTMs, pixels) | `/dev-testing-strategy`, `/traffic-analytics-tracking`, `/traffic-ga4-mcp`, `/traffic-google-ads-mcp` |
| `traffic-strategist` | Briefings + stories de campanha (exclusivo) | `/deep-research`, `/tiktok-marketing`, `/traffic-paid-ads-optimization`, `/traffic-ga4-mcp` |
| `traffic-tiktok` | TikTok Ads (Spark, In-Feed, TopView) | `/tiktok-marketing`, `/social-format-specs`, `/traffic-paid-ads-optimization` |

### PM — Gestão de projetos (10, personas Kaelthari)
| Agente | Persona | Papel | Skills relacionadas |
|---|---|---|---|
| `pm-analyst` | Serak | Inteligência de portfólio (carga, risco) | `/data-analytics-engineering`, `/data-sql-optimization` |
| `pm-client` | Eshara | Camada de cliente (acesso, churn) | `/dev-technical-writing` |
| `pm-coach` | Aevon | Metodologias / Scrum Master | — |
| `pm-data` | Nexar | Banco (único com Supabase CLI) | `/dev-database-patterns`, `/data-sql-optimization` |
| `pm-demand` | Draketh | Intake de demandas | `/dev-technical-writing` |
| `pm-engineer` | Faelor | Templates de processo / flows | `/dev-technical-writing` |
| `pm-ops` | Varek | Operações diárias (status, subtasks) | — |
| `pm-planner` | Zynath | Sprints, roadmap, capacidade | `/data-analytics-engineering` |
| `pm-qa` | Thyron | Auditor formal de entregas | — |
| `pm-reporter` | Lyrith | Meeting intelligence (dailies, retros) | `/dev-technical-writing`, `/deep-research` |

### Sales — Propostas e apresentações (8, personas olímpicas)

> Squad **genérica**: o método (intake → tese → planejamento → números → copy ∥ design → QA → envio) é do CT; o contexto da empresa — catálogo de ofertas e preços (`project/offer-catalog.md`), marca e design system (`project/brand.md`), convenção de pastas e versões (`project/conventions.md`) — vive na smart-memory do projeto e é preenchido com o usuário, nunca inventado. **Dois gates:** ATHENA aprova o *plano* (7 pontos) antes da produção; ARGUS aprova o *artefato* (12 pontos) antes do envio. Sem devops: enviar ao cliente é ato do usuário, e o hook `check-proposal-progress.sh` só fecha task de envio com PASS + confirmação explícita.

| Agente | Persona | Papel | Skills relacionadas |
|---|---|---|---|
| `sales-analyst` | ATLAS | Intake de reunião + pesquisa de cliente/setor/benchmarks, tudo com fonte | `/sales-discovery-intake`, `/deep-research`, `/dev-defuddle`, `/verify-before-done` |
| `sales-strategist` | ATHENA | Tese do negócio, enquadramento, postura de negociação, **gate do planejamento** (exclusivo) | `/negotiation`, `/sales-pricing-payback`, `/pricing`, `/sales-enablement` |
| `sales-planner` | DAEDALUS | Story da proposta + planejamento interno de 9 seções + estrutura página a página (exclusivo) | `/sales-proposal-planning`, `/sales-discovery-intake`, `/dev-technical-writing`, `/sales-enablement` |
| `sales-finance` | LIBRA | **Fonte única dos números**: preço vs. tabela, desconto/breakeven, payback, permuta, BP, valuation | `/sales-pricing-payback`, `/startup-financial-modeling`, `/pricing`, `/verify-before-done` |
| `sales-copywriter` | CALLIOPE | Texto página a página — voz declarativa, compromisso conjunto, número só com `#id` da ficha | `/sales-proposal-copy`, `/sales-enablement`, `/sites-copy`, `/sales-proposal-planning` |
| `sales-designer` | HELIOS | PDF e deck no design system do projeto — HTML + print CSS → export headless → checagem | `/sales-deck-production`, `/slides`, `/presentation-design`, `/ui-ux-pro-max`, `/verify-before-done` |
| `sales-qa` | ARGUS | Veredictos PASS/CONCERNS/FAIL/WAIVED sobre o artefato — 12 pontos (exclusivo) | `/sales-proposal-copy`, `/sales-deck-production`, `/presentation-design`, `/verify-before-done` |
| `sales-closer` | PEITHO | Brief de reunião, follow-up, ledger de propostas, envio só com PASS + confirmação do usuário | `/negotiation`, `/sales-enablement`, `/sales-proposal-copy`, `/verify-before-done` |

### Brand — Reposicionamento de marca (8, personas estelares)

> Squad **genérica**: o método (auditoria → plataforma → arquitetura e stories → voz ∥ visual → QA → baseline → rollout → leitura do depois) é do CT; o contexto da marca — histórico, ofertas, públicos, ativos, motivo do reposicionamento (`project/brand-context.md`) — vive na smart-memory do projeto e é preenchido com o usuário, nunca inventado. **Define e guarda a marca, não executa canal:** site, social, tráfego e propostas seguem com as squads deles, que recebem o kit de handoff em `project/brand.md`. **Dois gates:** POLARIS aprova a *plataforma* (7 pontos, com o usuário) e escolhe a *direção* entre ≥2 opções; RIGEL aprova cada *deliverable* (10 pontos) antes de virar lei para as outras squads. Sem devops: a virada externa exige PASS + baseline travada + confirmação explícita do usuário.

| Agente | Persona | Papel | Skills relacionadas |
|---|---|---|---|
| `brand-analyst` | SIRIUS | Auditoria da marca atual, mapa de concorrentes e territórios, públicos na linguagem deles — tudo com fonte | `/brand-research`, `/deep-research`, `/dev-defuddle`, `/verify-before-done` |
| `brand-strategist` | POLARIS | Plataforma de marca, postura do reposicionamento, **gate da plataforma e escolha de direção** (exclusivo) | `/brand-platform`, `/brand-research`, `/pricing`, `/verify-before-done` |
| `brand-architect` | ORION | Arquitetura de marca (marca-mãe, sub-marcas, marca pessoal, nomes), roadmap de migração, **stories** (exclusivo) | `/brand-platform`, `/dev-technical-writing`, `/brand-rollout`, `/verify-before-done` |
| `brand-voice` | LYRA | Guia de voz, framework de mensagens, manifesto, tagline, glossário, nomes dentro do sistema — ≥2 opções de direção | `/brand-verbal-identity`, `/sites-copy`, `/brand-platform`, `/verify-before-done` |
| `brand-designer` | AURORA | Direções visuais com opções, sistema de cor/tipo/grid/imagem, brandbook — via Claude Design | `/brand-visual-system`, `/design`, `/ui-ux-pro-max`, `/web-design-guidelines`, `/social-key-visual`, `/verify-before-done` |
| `brand-insights` | VEGA | **Fonte única dos números da marca**: scorecard, baseline antes, leitura depois, ficha com `#id` | `/brand-tracking`, `/data-analytics-engineering`, `/social-analytics`, `/verify-before-done` |
| `brand-rollout` | ALTAIR | Plano interno → externo, inventário e desligamentos, checklist por canal, kit de handoff — só com PASS + baseline + confirmação | `/brand-rollout`, `/brand-verbal-identity`, `/brand-visual-system`, `/verify-before-done` |
| `brand-qa` | RIGEL | Veredictos PASS/CONCERNS/FAIL/WAIVED sobre cada deliverable — 10 pontos (exclusivo); auditoria de consistência pós-virada | `/brand-verbal-identity`, `/brand-visual-system`, `/brand-platform`, `/verify-before-done` |

---

## 6. Catálogo de skills de apoio

### Finance — Gestão financeira (8, personas fluviais)

> Squad **genérica**: o método (coleta com documento → política e orçamento → plano de caixa e stories → lançamento e conciliação → contas a pagar/receber preparadas → fiscal preparado → relatório com `#id` → QA → execução pelo humano) é do CT; o contexto da empresa — entidades e contas por alias, regime tributário, contador, ciclo de fechamento, política (`project/finance-context.md`, `project/finance-policy.md`) — vive na smart-memory do projeto e é preenchido com o usuário. **A squad prepara, registra e confere; nunca move dinheiro nem declara ao fisco.** Dois gates: AMAZONAS aprova orçamento e plano de caixa (7 pontos); TIGRE aprova fechamento, lote, cobrança, apuração e relatório (12 pontos). O hook `check-finance-progress.sh` só fecha task de pagamento, cobrança, nota, guia ou relatório enviado com PASS + confirmação explícita do usuário. Dado sensível (conta, chave PIX, CPF/CNPJ de terceiro) nunca entra na smart-memory — só alias.

| Agente | Persona | Papel | Skills relacionadas |
|---|---|---|---|
| `finance-analyst` | NILO | Coleta e classificação de documentos do período, benchmarks, tarifas e índices — toda cifra com documento ou fonte datada | `/finance-bookkeeping`, `/deep-research`, `/dev-defuddle`, `/verify-before-done` |
| `finance-strategist` | AMAZONAS | Política financeira (margem, reserva, alçadas, prioridade, distribuição), **gate do orçamento e do plano de caixa** (exclusivo) | `/finance-cash-flow`, `/finance-reporting`, `/startup-financial-modeling`, `/pricing`, `/verify-before-done` |
| `finance-planner` | DANUBIO | Orçamento, plano de caixa 13 semanas, forecast com cenários, roadmap — **stories `F{N}`** (exclusivo) | `/finance-cash-flow`, `/finance-reporting`, `/startup-financial-modeling`, `/dev-technical-writing`, `/verify-before-done` |
| `finance-controller` | GANGES | **Fonte única dos números**: plano de contas, conciliação item a item, DRE gerencial, fechamento com `#id` | `/finance-bookkeeping`, `/finance-cash-flow`, `/data-analytics-engineering`, `/verify-before-done` |
| `finance-billing` | TEJO | Cobranças e régua de inadimplência, agenda e lotes de pagamento preparados — prepara, nunca executa | `/finance-receivables-payables`, `/finance-bookkeeping`, `/negotiation`, `/verify-before-done` |
| `finance-tax` | RENO | Calendário de obrigações, apuração preparatória com regra e fonte, pacote para o contador — não declara nem recolhe | `/finance-tax-compliance`, `/finance-bookkeeping`, `/deep-research`, `/verify-before-done` |
| `finance-reporter` | SENA | Relatório mensal para sócios, indicadores, relatório para investidor e banco — só com `#id` do fechamento FECHADO | `/finance-reporting`, `/finance-cash-flow`, `/dev-technical-writing`, `/verify-before-done` |
| `finance-qa` | TIGRE | Veredictos PASS/CONCERNS/FAIL/WAIVED sobre fechamento, lote, cobrança, apuração e relatório — 12 pontos (exclusivo) | `/finance-bookkeeping`, `/finance-receivables-payables`, `/finance-reporting`, `/verify-before-done` |

### Legal — Jurídico do dia a dia (8, personas latinas)

> Squad **genérica**: o método (pesquisa com fonte primária → postura jurídica → arquitetura documental e stories → minuta com desvios marcados → registro de prazos e LGPD → conflitos preparados → QA → envio/assinatura pelo humano) é do CT; o contexto da empresa — tipo societário, jurisdição, advogado e contador por alias, apetite a risco, contratos vigentes (`project/legal-context.md`, `project/legal-posture.md`) — vive na smart-memory do projeto. **A squad prepara, organiza e confere; não substitui advogado** — parecer, assinatura de peça e protocolo são do advogado inscrito; envio e assinatura são do usuário. Dois gates: PRUDENTIA aprova a postura de cada minuta e notificação (7 pontos); IUSTITIA aprova o documento (12 pontos). O hook `check-legal-progress.sh` só fecha task de envio, assinatura, protocolo ou publicação com PASS + confirmação explícita do usuário.

| Agente | Persona | Papel | Skills relacionadas |
|---|---|---|---|
| `legal-analyst` | VERITAS | Lei, jurisprudência, doutrina e precedentes internos — fonte primária com artigo/acórdão e data; achado ≠ leitura ≠ parecer | `/legal-research`, `/deep-research`, `/dev-defuddle`, `/verify-before-done` |
| `legal-strategist` | PRUDENTIA | Postura jurídica (apetite a risco, inegociáveis, negociáveis com piso/teto, foro, conflito), **gate de minuta e notificação** (exclusivo) | `/legal-contract-drafting`, `/legal-research`, `/negotiation`, `/verify-before-done` |
| `legal-architect` | LEX | Arquitetura documental, sistema de modelos `M{N}` versionado, hierarquia contrato-mãe/anexos/aditivos — **stories `L{N}`** (exclusivo) | `/legal-clause-library`, `/legal-contract-lifecycle`, `/dev-technical-writing`, `/verify-before-done` |
| `legal-drafter` | CONCORDIA | Contratos, aditivos, distratos, NDAs, termos e políticas a partir do modelo e da postura, com matriz de desvios — nunca envia | `/legal-contract-drafting`, `/legal-clause-library`, `/legal-research`, `/verify-before-done` |
| `legal-compliance` | FIDES | **Fonte única de prazos e obrigações**: registro de contratos com `#id`, mapa de dados com base legal, consentimentos, incidentes | `/legal-compliance-lgpd`, `/legal-contract-lifecycle`, `/data-analytics-engineering`, `/verify-before-done` |
| `legal-disputes` | CLEMENTIA | Notificação, cobrança extrajudicial, acordo, distrato e dossiê para o advogado — prepara, nunca envia nem ameaça | `/legal-contract-lifecycle`, `/legal-research`, `/negotiation`, `/verify-before-done` |
| `legal-ops` | AEQUITAS | Versão travada, assinatura, arquivamento, registro, renovações — envio só com PASS + confirmação | `/legal-contract-lifecycle`, `/legal-clause-library`, `/dev-technical-writing`, `/verify-before-done` |
| `legal-qa` | IUSTITIA | Veredictos PASS/CONCERNS/FAIL/WAIVED sobre minuta, notificação, política e dossiê — 12 pontos (exclusivo) | `/legal-contract-drafting`, `/legal-clause-library`, `/legal-compliance-lgpd`, `/verify-before-done` |

### SEO — Auditoria e otimização de busca (15, personas egípcias)

> Squad **genérica**: motor é o pacote [claude-seo](https://github.com/AgriciDaniel/claude-seo) v2.3.1 (MIT, AgriciDaniel) incorporado ao CT — 27 skills e o runtime Python em `.claude/skills/seo/` (`/seo setup` cria o ambiente isolado + Chromium na primeira vez; `/seo doctor` diagnostica). **Audita, prioriza e recomenda; nunca implementa o fix nem sobe deploy** — o handoff vai para a squad Sites via smart-memory. Dois gates: THOTH sequencia o roadmap com checklist de 5 pontos (achado rastreável · observação · dependência · critério de aceite · falseamento + indicador); MAAT aprova cada auditoria/relatório antes de virar story ou chegar ao cliente. SESHAT é fonte única dos números (GSC/PageSpeed/CrUX/GA4/Bing) — nenhum dado de campo ou estimativa entra sem `#id` dela; campo sempre vence laboratório, e FID (aposentado em 2024) nunca é citado — a métrica de interatividade é INP. Pressure-tested: 9/9 cenários limpos (THOTH, MAAT, SESHAT).

| Agente | Persona | Papel | Skills relacionadas |
|---|---|---|---|
| `seo-architect` | THOTH | Roadmap e stories de SEO, checklist de 5 pontos (exclusivo) | `/seo-plan`, `/seo-audit`, `/seo-flow`, `/dev-technical-writing` |
| `seo-technical` | PTAH | SEO técnico — 9 categorias (rastreabilidade, indexação, segurança, CWV, JS, IndexNow) | `/seo-technical`, `/seo-page`, `/sites-seo-technical` |
| `seo-content` | NEITH | E-E-A-T, conteúdo raso, citabilidade por IA, briefs, limpeza de última milha | `/seo-content`, `/seo-content-brief`, `/seo-image-gen`, `/sites-copy` |
| `seo-schema` | KHNUM | Detecção, validação e geração de Schema.org (JSON-LD) | `/seo-schema`, `/seo-technical` |
| `seo-sitemap` | GEB | Sitemap XML, hreflang/i18n, SEO programático em escala | `/seo-sitemap`, `/seo-hreflang`, `/seo-programmatic` |
| `seo-performance` | SHU | Core Web Vitals (LCP/INP/CLS), subpartes de LCP, renderização e visual | `/seo-technical`, `/seo-images`, `/nextjs-react-best-practices` |
| `seo-geo` | NUT | GEO/AI search — crawlers de IA, llms.txt, citabilidade por passagem | `/seo-geo`, `/seo-content` |
| `seo-sxo` | HORUS | SERP ao contrário, user stories, páginas de comparação | `/seo-sxo`, `/seo-competitor-pages`, `/sites-page-cro` |
| `seo-cluster` | HEKA | Clustering semântico por sobreposição real de SERP, hub-and-spoke | `/seo-cluster`, `/seo-content-brief`, `/sites-seo-keywords` |
| `seo-local` | BASTET | GBP, NAP, citações, avaliações, multi-localidade, geo-grid | `/seo-local`, `/seo-maps` |
| `seo-backlinks` | ANUBIS | Perfil de links multi-fonte com peso por confiança, verificação obrigatória | `/seo-backlinks`, `/seo-ahrefs`, `/seo-dataforseo` |
| `seo-ecommerce` | HAPI | Schema de produto, Google Shopping, marketplace, catálogo | `/seo-ecommerce`, `/seo-schema`, `/seo-images` |
| `seo-google` | SESHAT | **Fonte única dos números**: GSC, PageSpeed, CrUX, Indexing API, GA4 | `/seo-google`, `/seo-bing`, `/data-analytics-engineering` |
| `seo-drift` | WADJET | Baseline e comparação — detecção de regressão pós-deploy | `/seo-drift`, `/seo-technical` |
| `seo-qa` | MAAT | Veredictos PASS/CONCERNS/FAIL/WAIVED sobre auditoria/relatório (exclusivo) | `/seo-audit`, `/seo-technical`, `/seo-content` |

107 skills, todas diretórios reais e versionados (repositório self-contained).

**Dev (9):** `dev-api-design`, `dev-database-patterns`, `dev-defuddle`, `dev-error-handling`, `dev-git-workflow`, `dev-security-patterns`, `dev-technical-writing`, `dev-testing-strategy`, `dev-typescript-patterns`

**Data & ML (6):** `ai-ml-data-science`, `ai-ml-timeseries`, `data-analytics-engineering`, `data-lake-platform`, `data-sql-optimization`, `data-supabase-patterns`

**Sites (9):** `sites-canvas-design`, `sites-copy`, `sites-deployment`, `sites-frontend-stack`, `sites-page-cro`, `sites-scroll-motion`, `sites-seo-keywords`, `sites-seo-technical`, `sites-ux-interaction`

> Fusões 2026-09: `sites-copy` absorve content-strategy + copywriting + copy-editing; `sites-frontend-stack` absorve frontend-design + tailwind-design-system + shadcn-ui; `sites-web-accessibility` foi absorvida por `accessibility` (WCAG 2.2).

**Social (14):** `social-analytics`, `social-apify-research`, `social-carousel-design`, `social-cinematic-composition`, `social-copywriting`, `social-editorial-validation`, `social-format-specs`, `social-freepik-generation`, `social-heygen-avatar`, `social-key-visual`, `social-meta-publishing`, `social-scriptwriting`, `social-stitch-workflow`, `social-video-editing`

**Traffic (4):** `traffic-paid-ads-optimization`, `traffic-analytics-tracking`, `traffic-google-ads-mcp`, `traffic-ga4-mcp`

**Sales (6):** `sales-discovery-intake`, `sales-proposal-planning`, `sales-pricing-payback`, `sales-proposal-copy`, `sales-deck-production`, `sales-enablement`

**Brand (6):** `brand-research`, `brand-platform`, `brand-verbal-identity`, `brand-visual-system`, `brand-tracking`, `brand-rollout`

**Finance (5):** `finance-cash-flow`, `finance-bookkeeping`, `finance-receivables-payables`, `finance-tax-compliance`, `finance-reporting`

**Legal (5):** `legal-research`, `legal-contract-drafting`, `legal-clause-library`, `legal-compliance-lgpd`, `legal-contract-lifecycle`

**SEO (27, incorporado do pacote [claude-seo](https://github.com/AgriciDaniel/claude-seo) v2.3.1, MIT):** `seo` (orquestradora + runtime Python em `scripts/`, `schema/`, `data/`, `pdf/`), `seo-audit`, `seo-page`, `seo-plan`, `seo-technical`, `seo-content`, `seo-content-brief`, `seo-schema`, `seo-sitemap`, `seo-hreflang`, `seo-programmatic`, `seo-images`, `seo-image-gen`, `seo-geo`, `seo-sxo`, `seo-competitor-pages`, `seo-cluster`, `seo-local`, `seo-maps`, `seo-backlinks`, `seo-ahrefs`, `seo-ecommerce`, `seo-google`, `seo-bing`, `seo-drift`, `seo-dataforseo`, `seo-flow`

**Design & geral (13):** `ui-ux-pro-max`, `web-design-guidelines`, `accessibility`, `deep-research`, `tiktok-marketing`, `nextjs-react-best-practices`, `testing-playwright-e2e`, `verify-before-done`, `negotiation`, `pricing`, `slides`, `presentation-design`, `startup-financial-modeling`

> **Novas (adaptadas do registry [skills.sh](https://www.skills.sh/), auditadas):** `nextjs-react-best-practices` (Vercel — performance React/Next para devs de dev/sites), `data-supabase-patterns` (Supabase — Postgres/RLS/indexing para data engineers), `testing-playwright-e2e` (E2E para os QAs), `traffic-paid-ads-optimization` e `traffic-analytics-tracking` (marketingskills — para strategist/copywriter/bi/qa da traffic), `verify-before-done` (superpowers — gate de verificação antes de declarar "pronto", uso geral de todos os agentes).
>
> **Novas 2026-09 (squad Brand):** autorais do CT, todas com templates Obsidian — `brand-research` (auditoria, mapa de territórios, públicos), `brand-platform` (plataforma + gate de 7 pontos + arquitetura de marca), `brand-verbal-identity` (dimensões de tom, dizemos/não dizemos, mensagens, manifesto, naming), `brand-visual-system` (cor com papel e contraste, tipo, grid, imagem, brandbook via Claude Design), `brand-tracking` (scorecard, baseline, leitura do depois, ficha com `#id`), `brand-rollout` (pré-condições, fases, checklist por canal, kit de handoff `brand.md`).
>
> **Novas 2026-09 (squads Finance e Legal):** autorais do CT, com templates Obsidian — `finance-cash-flow` (plano de caixa 13 semanas, forecast, runway), `finance-bookkeeping` (plano de contas, conciliação, fechamento com `#id`), `finance-receivables-payables` (régua de cobrança, aging, lote de pagamento preparado), `finance-tax-compliance` (calendário fiscal, apuração preparatória, pacote para o contador; `reference/brasil.md` sem alíquotas cravadas), `finance-reporting` (relatório mensal, dicionário de indicadores); `legal-research` (fonte primária, achado ≠ parecer; `reference/fontes-brasil.md`), `legal-contract-drafting` (anatomia em 15 blocos, matriz de desvios, revisão da contraparte), `legal-clause-library` (modelos `M{N}.{c}`, variantes com piso/teto), `legal-compliance-lgpd` (mapa de dados, bases legais, incidentes), `legal-contract-lifecycle` (registro, assinatura travada por hash, notificação, dossiê).
>
> **Nova 2026-09 (Sala de Controle):** `maestri-os` — autoral do CT, recurso opt-in para o Maestri (roteador de pedidos entre terminais; `scripts/scan-project.sh` read-only + templates de registro/compilado/histórico). Não pertence a squad; só entra via `--squads none --extra-skills maestri-os`.
>
> **Novas 2026-09 (squad Sales):** autorais do CT — `sales-discovery-intake`, `sales-proposal-planning`, `sales-pricing-payback`, `sales-proposal-copy`, `sales-deck-production` (com `html-to-pdf.mjs` e `check-pdf.sh`); adotadas do registry após vetting — `sales-enablement` e `pricing` (marketingskills), `startup-financial-modeling` (wshobson), `negotiation` (wondelai — framework Voss), `slides` (nextlevelbuilder, mesmo autor do `ui-ux-pro-max`), `presentation-design` (jwynia). Descartadas no vetting: `proposal-writer` (template raso com número inventado), `html-slides`/`meeting-notes` (frontmatter quebrado), `html-to-pdf` (abaixo do corte — abordagem incorporada em `sales-deck-production`).
>
> **Nova 2026-09 (squad SEO):** pacote externo [claude-seo](https://github.com/AgriciDaniel/claude-seo) v2.3.1 (MIT, AgriciDaniel) incorporado 100% ao CT — as 25 skills do core + `seo-ahrefs` e `seo-bing` (mirrors de extensão), com o runtime Python (58 scripts: GSC, PageSpeed, CrUX, GA4, Playwright, geração de schema, drift) reidratado em `.claude/skills/seo/scripts/` e reescrito para rodar via `${CLAUDE_PROJECT_DIR}` em vez de `${CLAUDE_PLUGIN_ROOT}` (não é plugin, é skill do CT). `seo-flow`, `seo-dataforseo` e `seo-image-gen` entram como skill mas sem agente dedicado — `seo-flow` é framework de prompt, os outros dois dependem de MCP pago (DataForSEO, Gemini/nanobanana) ainda não autorizado. Os 15 agentes (personas egípcias) e a autoria do preset/bodies são do CT — pressure-tested 9/9.

**Orquestração:** `team-os` (distribuída a todos os projetos — obrigatória para rodar `/team-os` em cada sessão) · `team-os-creator` (**exclusiva do CT** — a única que não vai para os projetos) · `maestri-os` (**opt-in, só em Salas de Controle** — ver abaixo).

### Sala de Controle — `maestri-os` (recurso para o Maestri)

Para quem roda os projetos como terminais no [Maestri](https://maestri.app): uma pasta própria, **sem agentes e sem `team-os`**, que funciona como recepcionista dos outros terminais. Você fala em português normal (simples ou composto: *"atualize o site, crie um post e faça um relatório de tráfego"*); a skill descobre qual terminal cuida de cada parte, confirma o mapa e despacha em paralelo via `maestri ask`. Como o Maestri não diz o que cada terminal faz, na primeira vez ela monta sozinha a relação **janela → pasta → escopo → apelidos** (pela convenção `<pasta> | <escopo>` no nome da janela) e pede **um OK só**; depois não pergunta mais. O resto (squads, agentes, resumo do projeto) ela lê da pasta e relê a cada rodada. Tudo fica em `docs/smart-memory/maestri/` da Sala de Controle (`registry.md`, `OVERVIEW.md`, `dispatches.md`).

- **Enxerga só o que está ligado por fio** a ela no canvas (intencional). Terminal renomeado = pergunta de novo.
- **Lê, mas nunca escreve nem executa** em outra pasta — todo trabalho vai pelo terminal do projeto, com os agentes e travas daquele projeto.
- **Espia antes de mandar** (`maestri check`), pedido curto espera a resposta, pedido longo libera e é avisada de volta.
- **Autopilot no retorno:** quando um terminal responde, ela atualiza o histórico e despacha sozinha a próxima parte dependente do plano já confirmado; só para quando o terminal devolve `DECISÃO:` (pergunta que é do usuário). Os terminais já rodam `/team-os` — o cabeçalho manda usar a orquestração ativa, não recarregar.
- **Instalação:** `/team-os-creator *install` reconhece a pasta "Sala de Controle" e oferece só a skill (`--squads none --extra-skills maestri-os`). Nunca é propagada sozinha para projetos com squad. Uma Sala de Controle por dono/marca.

> Para banco de dados, os agentes usam `/dev-database-patterns` e `/data-sql-optimization`. Para design, o padrão é **Claude Design** (sem dependências de marketplaces externos).

> A skill `/sites-copy` é de **uso geral da squad Sites** — disponível a `sites-ux`, `sites-dev-gamma`, `sites-qa` e `sites-architect` conforme a story.

---

## 7. Tutorial passo a passo

### A. Orquestrar uma sessão com Agent Teams
```
1. Abra o projeto no Claude Code (CT ou qualquer projeto com agentes instalados)
2. Carregue:  /team-os
3. Responda o objetivo quando perguntado (ex.: "implementar auth com Supabase")
4. Revise a proposta de time (agentes, ownership, tasks) → confirme com [s]
5. Acompanhe pelo agent panel (↑↓ navega, Enter entra na sessão, x para)
6. Ao final: "Peça ao agente {nome} para encerrar"
```
> Se o lead encerrar cedo, diga: *"Continue — há tasks incompletas"*.

### B. Instalar squads num projeto novo
```
1. No CT, carregue:  /team-os-creator *install
2. Selecione o projeto destino e as squads
3. Confirme o preview
→ copia agentes (exceto team-os-creator), cria docs/smart-memory/ e configura settings.json
```

### C. Criar ou atualizar um agente
```
/team-os-creator *create <role>     # um agente
/team-os-creator *squad dev         # uma squad inteira
```
Depois, **sempre**: `/team-os-creator *audit`.

### D. Propagar mudanças do CT para os destinos
```
Editar agente no CT → /team-os-creator *audit → /team-os-creator *propagate → commit por projeto
```

---

## 8. Modelo de coordenação

- **Peer-to-peer:** teammates conversam direto entre si por nome via `SendMessage` (ex.: implementer → QA ao concluir). O lead é notificado automaticamente quando um teammate fica idle.
- **TaskList + self-claim:** ao terminar uma task, o agente pega sozinho a próxima livre compatível. ~5-6 tasks por agente mantêm o pipeline fluindo.
- **Sem nested teams:** teammates não spawnam outros teammates — precisa de outra especialidade? `SendMessage` para o teammate certo.

### Agent panel ≠ Agent view
| | Agent panel | Agent view (`claude agents`) |
|---|---|---|
| O que é | Teammates do time, abaixo do prompt da sessão | Tela de **sessões em background** independentes |
| Controles | ↑↓, Enter (abrir/mensagem), Esc (interromper), `x` (parar), Ctrl+T (task list) | Space (peek), Enter/→ (attach), Ctrl+X (stop) |
| Comunicação | Peer-to-peer entre teammates | Cada sessão isolada; teammates/subagents **não** aparecem como linhas |

---

## 9. Política de modelos (Híbrido)

O campo `model` do arquivo do agente **prevalece** sobre o "Default teammate model" do `/config` quando o agente roda como teammate. Por isso o CT adota o **Híbrido**:

| Modelo | Agentes | Por quê |
|---|---|---|
| `opus` (fixo) | os 8 canônicos: `dev-architect`, `sites-architect`, `dev-qa`, `sites-qa`, `pm-qa`, `traffic-qa`, `traffic-strategist`, `social-strategist` | Raciocínio crítico e veredictos — não vale economizar |
| `inherit` | os 41 demais (incluindo `pm-planner` e `pm-coach`) | Seguem o `/model` do lead → controle central de custo |

Para forçar outro modelo num agente `inherit`, especifique no spawn: `"Spawn {nome} usando modelo haiku para…"`.

**Política de `effort` (validada pelo `*audit`):**

| Effort | Papéis |
|---|---|
| `high` | architects, QAs, strategists, hardening (`*-dev-delta`), data engineers (`dev-data-engineer`, `sites-data`, `pm-data`), `pm-planner`, `pm-coach` |
| `medium` | analysts, UX, BI/insights (`dev-bi`, `traffic-bi`, `dev-data-performance`) |
| omitido | implementers (`*-dev-alpha/beta/gamma`) e devops — seguem o default do modelo |

---

## 10. Hooks de qualidade

Referenciados no frontmatter dos agentes e em `.claude/hooks/`:

- **`block-git-push.sh`** — `PreToolUse` em **70 agentes: todo agente com Bash exceto os devops, em TODAS as squads**. Bloqueia `git push` (inclusive `git -C`, `--git-dir`, aliases e comandos multilinha), `gh pr create/merge` e `gh api` de escrita em PRs — garantia dura, exclusiva do DevOps.
- **`block-worktree.sh`** — `PreToolUse` registrado no `.claude/settings.json` de **cada projeto** (matchers `Agent|Task|EnterWorktree` e `Bash`). Bloqueia spawn de agente com `isolation: worktree`, a ferramenta EnterWorktree, `git worktree add` **e criação de branch** (`checkout -b`, `switch -c`, `git branch <nome>`) — garantia dura de que todo trabalho acontece na branch ativa. Complementado por `"worktree": { "bgIsolation": "none" }` no mesmo settings (desliga worktree automático de background tasks). Instalado sempre pelo `*install`.
- **`guard-push-branch.sh`** — `PreToolUse` nos 2 devops: push permitido só na `main`/`master`; fora dela exige pedido explícito do usuário na sessão.
- **`task-quality.sh`** — hook `TaskCreated` (registrado no settings pelo `ensure-settings.sh`/`*install`): rejeita task vaga — título curto/genérico ou sem descrição.
- **`check-story-progress.sh`** — hook `TaskCompleted`: task que referencia story só fecha com `## QA Results` ou `status: done|in-review` na story.
- **`check-social-progress.sh`** — hook `TaskCompleted`: task de publicação social só fecha com aprovação registrada (VERA/strategist).
- **`check-proposal-progress.sh`** — hook `TaskCompleted`: task de emissão/envio de proposta ou deck (squad Sales) só fecha com veredicto **PASS** do `sales-qa` **e** confirmação explícita do usuário registradas na descrição.
- **`check-finance-progress.sh`** — hook `TaskCompleted`: task de **execução financeira** (pagar, transferir, PIX, boleto, nota, guia, cobrança enviada, relatório enviado — squad Finance) só fecha com **PASS** do `finance-qa` **e** confirmação explícita do usuário. Task de preparação (preparar lote, conciliar, calcular) não dispara.
- **`check-legal-progress.sh`** — hook `TaskCompleted`: task de **saída jurídica** (enviar minuta/notificação, assinar, protocolar, publicar termos — squad Legal) só fecha com **PASS** do `legal-qa` **e** confirmação explícita do usuário. Task de preparação (redigir, revisar, registrar) não dispara.

`TeammateIdle` fica como receita opcional (ver `team-os/reference/hooks-de-time.md` — hook incondicional cria loop infinito). Settings padrão também garantem `subagentPromptCacheTtl: "1h"`.

---

## 11. Estrutura do repositório

```
.claude/
├── agents/              ← 80 definições de agentes (fonte da verdade)
├── hooks/               ← hooks de qualidade
│   ├── block-git-push.sh
│   ├── block-worktree.sh          ← anti-worktree: bloqueia isolation: worktree, EnterWorktree e git worktree add (registrado no settings.json de cada projeto)
│   ├── guard-push-branch.sh       ← devops: push só na main/master
│   ├── task-quality.sh            ← TaskCreated: rejeita task vaga
│   ├── check-story-progress.sh
│   ├── check-social-progress.sh
│   ├── check-proposal-progress.sh ← TaskCompleted: envio de proposta só com PASS + confirmação do usuário
│   ├── check-finance-progress.sh  ← TaskCompleted: execução financeira só com PASS + confirmação do usuário
│   ├── check-legal-progress.sh    ← TaskCompleted: saída jurídica só com PASS + confirmação do usuário
│   └── team-os-session-title.sh   ← SessionStart: nomeia a sessão por "projeto · branch" (instalado globalmente em ~/.claude/hooks/ pelo *install)
└── skills/              ← 107 skills (diretórios reais)
    ├── maestri-os/              ← Sala de Controle (opt-in, recurso Maestri): SKILL.md + scripts/scan-project.sh + templates/{registry,overview,dispatches}.md
    ├── team-os/                 ← orquestração (distribuída aos projetos)
    │   ├── templates/story.md           ← template canônico de story
    │   ├── reference/obsidian-patterns.md
    │   └── scripts/
    │       ├── discovery.sh             ← Smart-Memory Discovery Engine (self-contained)
    │       ├── weigh-memory.sh          ← pesa a smart-memory no bootstrap (sinaliza se pesada)
    │       └── compact-memory.sh        ← *compact: arquiva o frio → _archive/ + LEDGER
    └── team-os-creator/         ← factory de agentes (exclusiva do CT)
        ├── templates/           ← 9 templates de archetype + pressure-scenarios/ (13 cenários)
        ├── reference/           ← archetypes, smart-memory, catálogo de skills, pressure-testing
        ├── scripts/             ← validate-agent.sh · scan-ct-projects.sh · dashboard.sh · diff · install (--squads none --extra-skills p/ Sala de Controle) · generate-agents-page.py
        └── presets/             ← 9 presets de squad (dev, sites, social, traffic, pm, sales, brand, finance, legal)

.github/workflows/audit.yml  ← CI: valida agentes + 0 symlinks quebrados a cada push

docs/smart-memory/       ← base de conhecimento por projeto (Obsidian)
├── INDEX.md             ← MOC raiz (todos leem ao iniciar)
├── project/   architecture/   decisions/
├── stories/ (backlog/active/in-review/done)
├── research/   modules/   qa/
└── _archive/   ← conteúdo frio compactado (fora do working set; não lido no bootstrap)
```

> **Smart-memory v2 — "estado, não histórico".** A base é um *cache quente*, não um baú: guarda estado atual e decisões, não narrativa. Três mecanismos mantêm-na enxuta:
> 1. **Leitura em camadas** — cada agente lê INDEX + `DIGEST.md` da sua área (≤150 linhas) + stories ativas; nunca pastas inteiras. Notas profundas só via wikilink.
> 2. **Escrita com ciclo de vida** — frontmatter `kind` (reference/episode/digest) + `status` (active/resolved/superseded) + `summary`; update-in-place, nunca `-v2`/`-r3`; teto ~300 linhas/episódio. Ver `team-os/reference/obsidian-patterns.md`.
> 3. **Compactação** — o bootstrap **pesa** a base (`weigh-memory.sh`: linhas, done, gordos, resolved não-arquivados, top áreas) e sinaliza; `/team-os *compact` roda o ciclo integral (mecânico + archivist semântico) com **uma única confirmação** (`--auto` dispensa até ela) e **move** (nunca deleta) o frio para `_archive/YYYY-QN/` — o `summary` sobrevive no DIGEST, os LEDGERs indexam tudo.

---

## 12. Troubleshooting

| Problema | Causa | Solução |
|---|---|---|
| Teammates não aparecem | Idle hide após 30s (v2.1.181+) — não pararam | `SendMessage` por nome para reativar |
| `/resume` não restaura teammates | Limitação conhecida | Re-spawnar com mesmo nome + contexto da smart-memory |
| Task travada (feita mas não marca) | Status pode atrasar | Verificar o trabalho → atualizar status manualmente |
| Lead implementa sozinho | Não delegou | *"Aguarde os teammates completarem antes de prosseguir"* |
| Muitos prompts de permissão | Teammates pedem aprovação | Pré-aprovar operações no settings ANTES de spawnar |
| Lead encerra cedo | Declarou concluído antes da hora | *"Continue — há tasks incompletas"* |
| tmux órfão | Sessão não encerrou limpo | `tmux ls` → `tmux kill-session -t {nome}` |

---

## 13. Manutenção do CT

```
1. Editar agente/skill AQUI (nunca no destino)
2. /team-os-creator *audit       → 56/56 conforme
3. /team-os-creator *propagate   → leva aos projetos destino
4. commit por projeto
```

**Regra de ouro:** o CT é a fonte da verdade. Auditoria sempre verde antes de propagar.

**Página oficial dos agentes:** [`docs/agentes.html`](./docs/agentes.html) — apresentação navegável dos 95 agentes: card inteiro clicável abre modal de **perfil completo** (bio, matriz de autoridade, regras absolutas, skills), skills clicáveis abrem modal com versão/seções e navegação cruzada de volta aos agentes que a usam. Gerada dos arquivos reais por `python3 .claude/skills/team-os-creator/scripts/generate-agents-page.py` — **regenerar após qualquer mudança em agentes ou skills**. Preview local: `npx http-server docs -p 8765` (config pronta em `.claude/launch.json`).

---

## Requisitos

- Claude Code com `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` em `~/.claude/settings.json`
- Plano com suporte a Agent Teams
- Agent Teams é experimental — ver [limitações oficiais](https://code.claude.com/docs/en/agent-teams#limitations)
