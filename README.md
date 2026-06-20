# CT — Centro de Treinamento

**Fonte da verdade de 49 agentes e ~50 skills para o Claude Code Agent Teams**, organizados em 5 squads (Dev, Sites, Social, Traffic, PM). Todo agente segue o **Native Teams Protocol** — autônomo, com smart-memory integrada (formato Obsidian) e coordenação peer-to-peer.

> Edite agentes e skills **aqui**, audite com `/team-os-creator *audit` e propague para os projetos destino com `/team-os-creator *propagate`. Nunca edite agentes direto no destino.

---

## Índice

1. [Conceitos fundamentais](#1-conceitos-fundamentais)
2. [Pré-requisitos e setup](#2-pré-requisitos-e-setup)
3. [As duas skills principais](#3-as-duas-skills-principais)
4. [Os 49 agentes](#4-os-49-agentes)
5. [Skills de apoio](#5-skills-de-apoio)
6. [Tutorial passo a passo](#6-tutorial-passo-a-passo)
7. [Modelo de coordenação](#7-modelo-de-coordenação)
8. [Política de modelos (Híbrido)](#8-política-de-modelos-híbrido)
9. [Hooks de qualidade](#9-hooks-de-qualidade)
10. [Estrutura do repositório](#10-estrutura-do-repositório)
11. [Troubleshooting](#11-troubleshooting)
12. [Manutenção do CT](#12-manutenção-do-ct)

---

## 1. Conceitos fundamentais

| Conceito | O que é |
|---|---|
| **Agent Teams** | Recurso (experimental) do Claude Code onde várias sessões trabalham em paralelo como um time. Uma sessão é o **lead**; as demais são **teammates**, cada uma com seu próprio context window. |
| **Lead nativo** | A **main session** do Claude Code é o lead — não existe agente "orquestrador". O lead spawna teammates, distribui tasks e sintetiza resultados. |
| **Teammate** | Sessão independente spawnada pelo lead a partir de uma definição em `.claude/agents/`. Comunica-se **peer-to-peer** com outros teammates via `SendMessage`. |
| **Subagent** | Mesma definição rodando como helper dentro de uma sessão (reporta só ao chamador). Os arquivos em `.claude/agents/` servem aos dois modos. |
| **TaskList nativo** | Lista de tasks compartilhada pelo time. Tasks têm estados `pending → in_progress → completed`, suportam dependências e **self-claim**. |
| **Smart-memory** | Base de conhecimento persistente em `docs/smart-memory/` (formato Obsidian: frontmatter YAML + wikilinks `[[...]]` + tags). É o *source of truth* que todo agente lê ao iniciar e atualiza ao concluir. |
| **Native Teams Protocol** | Contrato que todo agente do CT carrega no corpo: smart-memory como fonte da verdade, TaskList nativo, comunicação peer-to-peer, sem nested teams. |

**Agent Teams vs Subagents:** use **Agent Teams** quando os trabalhadores precisam conversar entre si, dividir um trabalho complexo e se coordenar. Use **subagents** quando você só quer um worker focado que reporta um resultado de volta.

---

## 2. Pré-requisitos e setup

1. **Claude Code** com Agent Teams habilitado. Adicione em `~/.claude/settings.json`:
   ```json
   {
     "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
     "teammateMode": "auto"
   }
   ```
   Reinicie o Claude Code após adicionar. Sem essa variável, nenhum time é criado.

2. **`teammateMode`** (opcional): default é `"in-process"` (todos no terminal principal, agent panel ativo). Use `"auto"` para abrir split panes quando estiver em tmux/iTerm2.

3. A skill `/team-os` faz esse check e corrige o `settings.json` automaticamente — basta carregá-la.

---

## 3. As duas skills principais

Estas duas existem **somente no CT** e nunca são copiadas para projetos destino.

### `/team-os` — Bootstrap e orquestração de sessão

Carregue no início de qualquer sessão onde você quer coordenar múltiplos agentes. Ela:

- Faz scan silencioso do ambiente (settings, agentes disponíveis, smart-memory, TaskList);
- Mostra um dashboard de abertura e pergunta o **objetivo da sessão**;
- Classifica o tipo de trabalho (research / implementação / review / mixed);
- Mapeia o paralelismo real e **dimensiona o time** (`tasks independentes ÷ 5 = nº de agentes`; research adversarial = 3-5 sempre);
- Propõe a composição (agentes, ownership de paths, plan mode, skills) e, após seu OK, cria as tasks e orienta o spawn.

```
/team-os                → bootstrap completo da sessão
/team-os *env           → só verificar/corrigir settings.json
/team-os *memory        → status/bootstrap da smart-memory
/team-os *tasks         → mostrar a task list atual
/team-os *spawn {desc}  → proposta de time para {desc} (pula o scan)
/team-os *status        → dashboard do time atual
```

### `/team-os-creator` — Factory de agentes

Cria e mantém os agentes nativos. Gera arquivos `.claude/agents/*.md` completos (Native Teams Protocol + smart-memory) a partir de 8 archetypes e presets de squad.

```
/team-os-creator               → menu principal (scan + sugestões)
/team-os-creator *analyze      → detecta o archetype/stack, sem criar
/team-os-creator *squad <preset>→ cria uma squad inteira (dev/sites/social/traffic/pm)
/team-os-creator *create <role> → cria UM agente interativamente
/team-os-creator *migrate      → migra agentes do padrão antigo p/ Native Teams Protocol
/team-os-creator *bootstrap    → cria docs/smart-memory/ + injeta protocolo no CLAUDE.md
/team-os-creator *skills <ag>  → enriquece um agente com skills relevantes
/team-os-creator *audit        → valida compliance de todos os agentes
/team-os-creator *propagate    → propaga agentes atualizados p/ outros projetos
/team-os-creator *install      → instala squads + skills + smart-memory num projeto destino
```

**8 archetypes:** `architect`, `implementer`, `hardening`, `reviewer`, `researcher`, `data`, `devops`, `ux`. Não existe archetype de lead/orquestrador — a main session já é o lead nativo.

---

## 4. Os 49 agentes

Cada agente roda como teammate (ou subagent). Spawne pelo nome do arquivo, ex.:
`"Spawn um teammate usando o agente dev-architect para mapear a arquitetura de auth"`.

### Dev — Fullstack SaaS (12)
| Agente | Papel |
|---|---|
| `dev-analyst` | Pesquisa técnica, comparação de libs, CVEs, feasibility (on-demand) |
| `dev-architect` | Arquitetura, ADRs, **criação e validação de stories** (exclusivo) |
| `dev-bi` | Data architect & dashboard strategist (queries SELECT-only) |
| `dev-data-engineer` | Schema, migrations, RLS, otimização (safety protocol: snapshot→dry-run→apply→smoke-test) |
| `dev-data-performance` | Interpreta dados, gera insights, detecta anomalias, forecasts |
| `dev-ux` | UX research + design visual + acessibilidade |
| `dev-dev-alpha` | Frontend (React, Next.js, Tailwind) |
| `dev-dev-beta` | Backend (APIs, serviços, lógica de negócio) |
| `dev-dev-gamma` | Fullstack / integração cross-layer |
| `dev-dev-delta` | Hardening e resiliência (após features prontas) |
| `dev-qa` | Veredictos formais PASS/CONCERNS/FAIL/WAIVED (exclusivo) |
| `dev-devops` | `git push`, PRs, CI/CD, releases (exclusivo) |

### Sites — Sites e landing pages (10)
`sites-analyst`, `sites-architect`, `sites-data`, `sites-ux`, `sites-dev-alpha` (frontend/shadcn), `sites-dev-beta` (backend/CMS), `sites-dev-gamma` (CRO/SEO/analytics), `sites-dev-delta` (Core Web Vitals/hardening), `sites-qa` (a11y/SEO/copy/perf), `sites-devops` (Vercel/Netlify).

### Social — Social media (7)
| Agente | Persona | Papel |
|---|---|---|
| `social-analyst` | — | Trends, concorrência, hashtags, analytics |
| `social-content` | LYRIS | Research (Apify MCP) + copywriting |
| `social-design` | AEON | Key visuals, carrosséis (Stitch MCP) |
| `social-photo` | IRIS | Fotos AI (Freepik MCP) |
| `social-publisher` | PULSE | Publicação (Meta MCP) + métricas — **só publica após aprovação da VERA + confirmação do usuário** |
| `social-strategist` | VERA | Estratégia + validação editorial (gate de aprovação) |
| `social-video` | FLUX | Reels/Stories/Shorts (ffmpeg) |

### Traffic — Tráfego pago (10)
`traffic-analyst`, `traffic-automation` (APIs Google/Meta/TikTok), `traffic-bi` (atribuição, ROAS/LTV/CPA), `traffic-copywriter`, `traffic-designer`, `traffic-google`, `traffic-meta`, `traffic-qa` (compliance pré-launch), `traffic-strategist` (briefings + stories, exclusivo), `traffic-tiktok`.

### PM — Gestão de projetos (10, personas Kaelthari)
| Agente | Persona | Papel |
|---|---|---|
| `pm-analyst` | Serak | Inteligência de portfólio (carga, risco) |
| `pm-client` | Eshara | Camada de cliente (acesso, churn) |
| `pm-coach` | Aevon | Metodologias / Scrum Master |
| `pm-data` | Nexar | Banco (único com Supabase CLI) |
| `pm-demand` | Draketh | Intake de demandas |
| `pm-engineer` | Faelor | Templates de processo / flows |
| `pm-ops` | Varek | Operações diárias (status, subtasks) |
| `pm-planner` | Zynath | Sprints, roadmap, capacidade |
| `pm-qa` | Thyron | Auditor formal de entregas |
| `pm-reporter` | Lyrith | Meeting intelligence (dailies, retros) |

---

## 5. Skills de apoio

Skills são conhecimento carregável que os agentes ativam via `/nome-skill`. Diferente do frontmatter `skills:` (ignorado em Agent Teams), elas são carregadas do projeto/usuário como em sessão normal.

**Dev:** `dev-api-design`, `dev-database-patterns`, `dev-defuddle`, `dev-error-handling`, `dev-git-workflow`, `dev-security-patterns`, `dev-technical-writing`, `dev-testing-strategy`, `dev-typescript-patterns`

**Data & ML:** `ai-ml-data-science`, `ai-ml-timeseries`, `data-analytics-engineering`, `data-lake-platform`, `data-sql-optimization`

**Sites:** `sites-canvas-design`, `sites-content-strategy`, `sites-copy-editing`, `sites-copywriting`, `sites-deployment`, `sites-frontend-design`, `sites-page-cro`, `sites-scroll-motion`, `sites-seo-keywords`, `sites-seo-technical`, `sites-shadcn-ui`, `sites-tailwind-design-system`, `sites-ux-interaction`, `sites-web-accessibility`

**Social:** `social-analytics`, `social-apify-research`, `social-carousel-design`, `social-cinematic-composition`, `social-copywriting`, `social-editorial-validation`, `social-format-specs`, `social-freepik-generation`, `social-key-visual`, `social-meta-publishing`, `social-scriptwriting`, `social-stitch-workflow`, `social-video-editing`

**Design & geral:** `ui-ux-pro-max`, `web-design-guidelines`, `accessibility`, `deep-research`, `tiktok-marketing`

**Utilitárias compartilhadas (symlink p/ store externo `.agents/skills/`):** `grill-me`, `handoff`, `to-issues`, `to-prd`, `triage`, `supabase`, `supabase-postgres-best-practices`. ⚠️ São symlinks para um store fora deste repositório — só resolvem em ambientes que tenham esse store. Em um clone limpo ficam pendentes.

---

## 6. Tutorial passo a passo

### A. Orquestrar uma sessão com Agent Teams

```
1. Abra o projeto no Claude Code (CT ou qualquer projeto com agentes instalados)
2. Carregue:  /team-os
3. Responda o objetivo quando perguntado (ex.: "implementar auth com Supabase")
4. Revise a proposta de time (agentes, ownership, tasks) → confirme com [s]
5. Acompanhe pelo agent panel (↑↓ navega, Enter entra na sessão, x para)
6. Ao final, peça: "Peça ao agente {nome} para encerrar"
```

> Não encerre o time cedo: se o lead "concluir" com tasks abertas, diga *"Continue — há tasks incompletas"*.

### B. Instalar squads num projeto novo

```
1. No CT, carregue:  /team-os-creator *install
2. Selecione o projeto destino e as squads desejadas
3. Confirme o preview
→ copia os agentes (exceto team-os-creator), cria docs/smart-memory/ e configura settings.json
```

### C. Criar ou atualizar um agente

```
/team-os-creator *create <role>     # um agente
/team-os-creator *squad dev         # uma squad inteira
```
Depois, **sempre** valide: `/team-os-creator *audit`.

### D. Propagar mudanças do CT para os destinos

```
Editar agente no CT → /team-os-creator *audit → /team-os-creator *propagate → commit por projeto
```

---

## 7. Modelo de coordenação

- **Peer-to-peer:** teammates conversam direto entre si por nome via `SendMessage` (ex.: implementer → QA ao concluir). O lead é notificado automaticamente quando um teammate fica idle.
- **TaskList + self-claim:** ao terminar uma task, o agente pega sozinho a próxima livre compatível. ~5-6 tasks por agente mantém o pipeline fluindo sem o lead intervir a cada conclusão.
- **Sem nested teams:** teammates não spawnam outros teammates — precisam de outra especialidade? `SendMessage` para o teammate certo.

### Agent panel ≠ Agent view
| | Agent panel | Agent view (`claude agents`) |
|---|---|---|
| O que é | Teammates do time, abaixo do prompt da sua sessão | Tela de **sessões em background** independentes |
| Controles | ↑↓, Enter (abrir/mensagem), Esc (interromper), `x` (parar), Ctrl+T (task list) | Space (peek), Enter/→ (attach), Ctrl+X (stop) |
| Comunicação | Peer-to-peer entre teammates | Cada sessão é isolada; teammates/subagents **não** aparecem como linhas |

---

## 8. Política de modelos (Híbrido)

O campo `model` do arquivo do agente **prevalece** sobre o "Default teammate model" do `/config` quando o agente roda como teammate. Por isso o CT adota o **Híbrido**:

| Modelo | Agentes | Por quê |
|---|---|---|
| `opus` (fixo) | architects, todos os `*-qa`/reviewers, strategists | Raciocínio crítico e veredictos — não vale economizar |
| `inherit` | todos os demais | Seguem o `/model` do lead → controle central de custo (lead baixa a frota inteira p/ sonnet/haiku quando quiser) |

Para forçar outro modelo num agente `inherit`, especifique no spawn: `"Spawn {nome} usando modelo haiku para…"`.

---

## 9. Hooks de qualidade

Referenciados no frontmatter dos agentes e em `.claude/hooks/`:

- **`block-git-push.sh`** — `PreToolUse` nos implementers (dev-dev-*, sites-dev-*, social-video): bloqueia `git push` (delega ao DevOps).
- **`check-story-progress.sh`** — valida progresso de stories.
- **`check-social-progress.sh`** — valida progresso de conteúdo social.

Hooks de time (em `.claude/settings.json` do projeto) ajudam a enforçar qualidade: `TeammateIdle`, `TaskCreated`, `TaskCompleted` — exit code 2 envia feedback e mantém o agente trabalhando.

---

## 10. Estrutura do repositório

```
.claude/
├── agents/              ← 49 definições de agentes (fonte da verdade)
├── hooks/               ← hooks de qualidade
│   ├── block-git-push.sh
│   ├── check-story-progress.sh
│   └── check-social-progress.sh
└── skills/              ← skills carregáveis
    ├── team-os/                 ← orquestração (exclusiva do CT)
    └── team-os-creator/         ← factory de agentes (exclusiva do CT)
        ├── templates/           ← 8 templates de archetype
        ├── reference/           ← archetypes, smart-memory, catálogo de skills
        ├── scripts/             ← validate-agent.sh, scan/diff/install
        ├── presets/             ← presets de squad
        └── hooks/

docs/smart-memory/       ← base de conhecimento por projeto (Obsidian)
├── INDEX.md             ← MOC raiz (todos leem ao iniciar)
├── project/            architecture/   decisions/
├── stories/ (backlog/active/in-review/done)
├── research/   modules/   qa/
```

---

## 11. Troubleshooting

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

## 12. Manutenção do CT

Fluxo canônico para qualquer alteração:

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
