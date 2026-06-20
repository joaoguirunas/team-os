# CT — Centro de Treinamento

**Fonte da verdade de 49 agentes e 48 skills para o Claude Code Agent Teams**, organizados em 5 squads (Dev, Sites, Social, Traffic, PM). Todo agente segue o **Native Teams Protocol** — autônomo, com smart-memory integrada (formato Obsidian) e coordenação peer-to-peer.

> Edite agentes e skills **aqui**, audite com `/team-os-creator *audit` e propague para os projetos destino com `/team-os-creator *propagate`. Nunca edite agentes direto no destino.

---

## Índice

1. [Conceitos fundamentais](#1-conceitos-fundamentais)
2. [Pré-requisitos e setup](#2-pré-requisitos-e-setup)
3. [Skill principal: `/team-os`](#3-skill-principal-team-os)
4. [Skill principal: `/team-os-creator`](#4-skill-principal-team-os-creator)
5. [Os 49 agentes e suas skills](#5-os-49-agentes-e-suas-skills)
6. [Catálogo de skills de apoio](#6-catálogo-de-skills-de-apoio)
7. [Tutorial passo a passo](#7-tutorial-passo-a-passo)
8. [Modelo de coordenação](#8-modelo-de-coordenação)
9. [Política de modelos (Híbrido)](#9-política-de-modelos-híbrido)
10. [Hooks de qualidade](#10-hooks-de-qualidade)
11. [Estrutura do repositório](#11-estrutura-do-repositório)
12. [Troubleshooting](#12-troubleshooting)
13. [Manutenção do CT](#13-manutenção-do-ct)

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

**Bootstrap e orquestração de sessão.** Existe **somente no CT** e nunca é copiada para projetos destino. Carregue no início de qualquer sessão onde você quer coordenar múltiplos agentes em paralelo.

### O que ela faz, em fases
1. **Scan silencioso** — lê `settings.json` (env + teammateMode), mapeia `.claude/agents/`, lê `docs/smart-memory/INDEX.md` e roda `TaskList`.
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
/team-os-creator *squad <preset>→ cria uma squad inteira (dev/sites/social/traffic/pm)
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
| `implementer` | Escreve código (front/back/fullstack) | `inherit` | `worktree` |
| `hardening` | Resiliência, retry, edge cases (após features) | `inherit` | `worktree` |
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

## 5. Os 49 agentes e suas skills

Spawne pelo nome do arquivo, ex.:
`"Spawn um teammate usando o agente dev-architect para mapear a arquitetura de auth"`.

A coluna **Skills relacionadas** lista as skills de apoio que cada agente normalmente ativa via `/nome-skill` (o `/team-os` as inclui no spawn prompt).

### Dev — Fullstack SaaS (12)
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
| Agente | Papel | Skills relacionadas |
|---|---|---|
| `sites-analyst` | Keyword/competitor research, feasibility | `/deep-research`, `/sites-seo-keywords` |
| `sites-architect` | Arquitetura de páginas, stories (exclusivo) | `/dev-api-design`, `/dev-technical-writing`, `/sites-seo-technical` |
| `sites-data` | Schema, migrations, RLS (sites) | `/dev-database-patterns`, `/data-sql-optimization` |
| `sites-ux` | UX research + design visual + a11y | `/sites-ux-interaction`, `/ui-ux-pro-max`, `/accessibility`, `/sites-web-accessibility` |
| `sites-dev-alpha` | Frontend / landing pages (shadcn) | `/sites-frontend-design`, `/sites-shadcn-ui`, `/sites-tailwind-design-system`, `/sites-scroll-motion`, `/ui-ux-pro-max` |
| `sites-dev-beta` | Backend / CMS / integrações | `/dev-api-design`, `/dev-error-handling`, `/dev-database-patterns` |
| `sites-dev-gamma` | CRO, SEO, analytics, fullstack | `/sites-page-cro`, `/sites-seo-technical`, `/dev-typescript-patterns` |
| `sites-dev-delta` | Hardening, Core Web Vitals | `/dev-security-patterns`, `/dev-error-handling`, `/sites-web-accessibility` |
| `sites-qa` | QA: a11y, SEO, copy, performance | `/dev-testing-strategy`, `/web-design-guidelines`, `/sites-seo-technical`, `/sites-web-accessibility` |
| `sites-devops` | Deploy Vercel/Netlify, CI/CD | `/dev-git-workflow`, `/sites-deployment` |

### Social — Social media (7)
| Agente | Persona | Papel | Skills relacionadas |
|---|---|---|---|
| `social-analyst` | — | Trends, concorrência, hashtags, analytics | `/social-analytics`, `/social-apify-research`, `/deep-research` |
| `social-content` | LYRIS | Research (Apify) + copywriting | `/social-copywriting`, `/social-scriptwriting`, `/social-editorial-validation`, `/social-format-specs`, `/social-apify-research` |
| `social-design` | AEON | Key visuals, carrosséis (Stitch) | `/social-key-visual`, `/social-carousel-design`, `/social-stitch-workflow` |
| `social-photo` | IRIS | Fotos AI (Freepik) | `/social-freepik-generation`, `/social-cinematic-composition` |
| `social-publisher` | PULSE | Publicação (Meta) + métricas | `/social-meta-publishing`, `/social-analytics` |
| `social-strategist` | VERA | Estratégia + validação editorial (gate) | `/social-editorial-validation`, `/social-format-specs` |
| `social-video` | FLUX | Reels/Stories/Shorts (ffmpeg) | `/social-video-editing`, `/social-scriptwriting`, `/social-cinematic-composition` |

> Regra do squad Social: `social-publisher` **só publica** após aprovação da `social-strategist` (VERA) **e** confirmação explícita do usuário.

### Traffic — Tráfego pago (10)
| Agente | Papel | Skills relacionadas |
|---|---|---|
| `traffic-analyst` | Audiências, concorrência, benchmarks | `/deep-research`, `/social-analytics` |
| `traffic-automation` | Bulk ops, APIs Google/Meta/TikTok | `/dev-api-design`, `/dev-error-handling` |
| `traffic-bi` | Atribuição, ROAS/LTV/CPA (fonte de verdade) | `/data-analytics-engineering`, `/data-sql-optimization` |
| `traffic-copywriter` | Copy de anúncios, variantes A/B | `/social-copywriting`, `/tiktok-marketing` |
| `traffic-designer` | Criativos (banners, carrosséis, vídeos) | `/social-key-visual`, `/social-carousel-design`, `/ui-ux-pro-max` |
| `traffic-google` | Google Ads (Search, PMax, Shopping, YT) | `/social-analytics` |
| `traffic-meta` | Meta Ads (FB + IG, Advantage+) | `/social-meta-publishing`, `/social-analytics` |
| `traffic-qa` | Compliance pré-launch (UTMs, pixels) | `/dev-testing-strategy` |
| `traffic-strategist` | Briefings + stories de campanha (exclusivo) | `/deep-research`, `/tiktok-marketing` |
| `traffic-tiktok` | TikTok Ads (Spark, In-Feed, TopView) | `/tiktok-marketing`, `/social-format-specs` |

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

---

## 6. Catálogo de skills de apoio

48 skills, todas diretórios reais e versionados (repositório self-contained).

**Dev (9):** `dev-api-design`, `dev-database-patterns`, `dev-defuddle`, `dev-error-handling`, `dev-git-workflow`, `dev-security-patterns`, `dev-technical-writing`, `dev-testing-strategy`, `dev-typescript-patterns`

**Data & ML (5):** `ai-ml-data-science`, `ai-ml-timeseries`, `data-analytics-engineering`, `data-lake-platform`, `data-sql-optimization`

**Sites (14):** `sites-canvas-design`, `sites-content-strategy`, `sites-copy-editing`, `sites-copywriting`, `sites-deployment`, `sites-frontend-design`, `sites-page-cro`, `sites-scroll-motion`, `sites-seo-keywords`, `sites-seo-technical`, `sites-shadcn-ui`, `sites-tailwind-design-system`, `sites-ux-interaction`, `sites-web-accessibility`

**Social (13):** `social-analytics`, `social-apify-research`, `social-carousel-design`, `social-cinematic-composition`, `social-copywriting`, `social-editorial-validation`, `social-format-specs`, `social-freepik-generation`, `social-key-visual`, `social-meta-publishing`, `social-scriptwriting`, `social-stitch-workflow`, `social-video-editing`

**Design & geral (5):** `ui-ux-pro-max`, `web-design-guidelines`, `accessibility`, `deep-research`, `tiktok-marketing`

**Orquestração (2, exclusivas do CT):** `team-os`, `team-os-creator`

> Para banco de dados, os agentes usam `/dev-database-patterns` e `/data-sql-optimization`. Para design, o padrão é **Claude Design** (sem dependências de marketplaces externos).

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
| `opus` (fixo) | architects, todos os `*-qa`/reviewers, strategists (8 agentes) | Raciocínio crítico e veredictos — não vale economizar |
| `inherit` | os 41 demais | Seguem o `/model` do lead → controle central de custo |

Para forçar outro modelo num agente `inherit`, especifique no spawn: `"Spawn {nome} usando modelo haiku para…"`.

---

## 10. Hooks de qualidade

Referenciados no frontmatter dos agentes e em `.claude/hooks/`:

- **`block-git-push.sh`** — `PreToolUse` nos implementers (dev-dev-*, sites-dev-*, social-video): bloqueia `git push` (delega ao DevOps).
- **`check-story-progress.sh`** — valida progresso de stories.
- **`check-social-progress.sh`** — valida progresso de conteúdo social.

Hooks de time (em `.claude/settings.json` do projeto): `TeammateIdle`, `TaskCreated`, `TaskCompleted` — exit code 2 envia feedback e mantém o agente trabalhando.

---

## 11. Estrutura do repositório

```
.claude/
├── agents/              ← 49 definições de agentes (fonte da verdade)
├── hooks/               ← hooks de qualidade
│   ├── block-git-push.sh
│   ├── check-story-progress.sh
│   └── check-social-progress.sh
└── skills/              ← 48 skills (diretórios reais)
    ├── team-os/                 ← orquestração (exclusiva do CT)
    └── team-os-creator/         ← factory de agentes (exclusiva do CT)
        ├── templates/           ← 8 templates de archetype
        ├── reference/           ← archetypes, smart-memory, catálogo de skills
        ├── scripts/             ← validate-agent.sh, scan/diff/install
        ├── presets/             ← presets de squad
        └── hooks/

docs/smart-memory/       ← base de conhecimento por projeto (Obsidian)
├── INDEX.md             ← MOC raiz (todos leem ao iniciar)
├── project/   architecture/   decisions/
├── stories/ (backlog/active/in-review/done)
├── research/   modules/   qa/
```

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
2. /team-os-creator *audit       → 49/49 conforme
3. /team-os-creator *propagate   → leva aos projetos destino
4. commit por projeto
```

**Regra de ouro:** o CT é a fonte da verdade. Auditoria sempre verde antes de propagar.

---

## Requisitos

- Claude Code com `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` em `~/.claude/settings.json`
- Plano com suporte a Agent Teams
- Agent Teams é experimental — ver [limitações oficiais](https://code.claude.com/docs/en/agent-teams#limitations)
