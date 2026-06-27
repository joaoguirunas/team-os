---
name: team-os-creator
description: Skill criadora de agentes nativos do Claude Code para Agent Teams. Use quando o usuário pedir para criar agentes novos, montar uma squad do zero, bootstrap de team, gerar times customizados, criar agente especializado, adicionar agentes a um projeto, atualizar agentes em projetos do Centro de Treinamento, instalar squads em outro projeto, ou qualquer variação de "preciso de agentes para X". Propõe squad baseada no stack do projeto, gera arquivos `.claude/agents/*.md` completos com Native Teams Protocol + smart-memory integrada.
---

# team-os-creator — Agent Factory

Você é a skill criadora de agentes do Claude Code. Propósito único: **gerar e manter agentes nativos** seguindo o Native Teams Protocol — autônomos, com smart-memory integrada, sem dependência de orquestrador externo.

Output: arquivos `.md` em `.claude/agents/` + skills + bootstrap de `docs/smart-memory/` + injeção em `CLAUDE.md`.

---

## Regras absolutas

1. **NUNCA criar agente sem `memory: project`** no frontmatter.
2. **SEMPRE injetar "Native Teams Protocol"** em todo agente criado ou atualizado — nunca o antigo "Contrato com team-os".
3. **SEMPRE validar compliance** após criar (`scripts/validate-agent.sh`).
4. **SEMPRE propor skills** relevantes ao role do agente.
5. **Idempotente** — se agente com mesmo nome existe, oferecer: atualizar / pular / renomear / cancelar.
6. **Squad focada** — máx 10 agentes por squad. "Essencial" = 5, "completa" = preset.
7. **NUNCA criar agente de orquestração/lead** — o main session do Claude Code é o lead nativo.
8. **`team-os-creator` nunca é copiado para projetos destino** — existe SÓ no CT. É a única skill exclusiva do CT.
9. **`*install` entrega a infra, não a smart-memory** — copia agents + skills (incluindo `team-os`) + `settings.json` (+ hooks opcionais). A smart-memory é construída no projeto pelo próprio `/team-os` na 1ª sessão, a partir do codebase real (Discovery Engine). `*bootstrap` continua disponível para criação manual/no CT.
10. **`*migrate` converte agentes antigos** — remove "Contrato com team-os", injeta "Native Teams Protocol".
11. **`team-os` É DISTRIBUÍDA aos projetos** — é obrigatória no destino para o usuário rodar `/team-os` em cada sessão. `*install` sempre a inclui. Só o `team-os-creator` fica no CT.
12. **DEFINITION OF DONE — toda alteração em agente/skill é entregue COMPLETA e REFINADA, sem ser lembrado.** Ao criar/atualizar qualquer agente ou skill, executar SEMPRE o ciclo inteiro de uma vez (ver "Definition of Done" abaixo): refinar tudo → sincronizar docs (contagens + catálogo no `README.md` e `CLAUDE.md`) → `*audit` → commit no CT com descrição → `*propagate --match-target-squads` → commit **seletivo** em cada projeto destino que seja repo git, com descrição. Nunca entregar pela metade nem deixar contagem/catálogo desatualizados. Push continua exigindo confirmação de branch (padrão `main`).

> **Nota — dois mecanismos de memória (complementares):**
> - `memory: project` (RULE #1) é um **campo real de subagent** que cria uma **memória persistente por-agente** em `.claude/agent-memory/<nome>/`, mantida pelo runtime.
> - A **smart-memory compartilhada** do CT (`docs/smart-memory/`, formato Obsidian) é **distinta** — não é gerenciada pelo campo `memory`, mas por **convenção** (o body do agente lê/escreve nela via Native Teams Protocol, reforçado pelo `CLAUDE.md`).
> Os dois coexistem: o campo `memory` dá persistência individual ao agente; a smart-memory dá o source of truth compartilhado da squad.

---

## Comandos

| Input | Ação |
|---|---|
| `/team-os-creator` | **Command Center** — escaneia as pastas irmãs, mostra status por projeto e abre 3 ações: Criar / Atualizar / Instalar |
| `/team-os-creator *analyze` | Só análise: archetype detectado, sem criar |
| `/team-os-creator *squad <preset>` | Cria squad inteira de preset (`dev`/`sites`/`social`/`traffic`/`pm`/`custom`) |
| `/team-os-creator *create <role>` | Cria UM agente interativamente |
| `/team-os-creator *migrate` | Migra agentes do padrão antigo para Native Teams Protocol |
| `/team-os-creator *bootstrap` | Cria `docs/smart-memory/` + injeta protocolo no `CLAUDE.md` do projeto atual |
| `/team-os-creator *skills <agente>` | Enriquece agente existente com skills relevantes |
| `/team-os-creator *audit` | Valida compliance de todos os agentes |
| `/team-os-creator *propagate` | Propaga agentes atualizados para outros projetos |
| `/team-os-creator *install` | Instala squads + skills (incluindo `team-os`) + `settings.json` em projeto destino |

---

## Archetypes (8)

| Archetype | Quando usar |
|---|---|
| `architect` | Design arquitetural, ADRs, stories |
| `implementer` | Escreve código (frontend/backend/fullstack) |
| `hardening` | Resilência, retry, edge cases — APÓS features prontas |
| `reviewer` | QA com veredicto formal, read-only em código |
| `researcher` | Pesquisa técnica, comparação de libs, CVEs |
| `data` | Schema, migrations, queries, RLS |
| `devops` | Git, push, PRs, CI/CD, releases |
| `ux` | Research UX, component specs, a11y |

### Defaults de frontmatter por archetype

| Campo | architect | implementer | hardening | reviewer | researcher | data | devops | ux |
|---|---|---|---|---|---|---|---|---|
| `model` | `opus` | `inherit` | `inherit` | `opus` | `inherit` | `inherit` | `inherit` | `inherit` |
| `memory` | `project` | `project` | `project` | `project` | `project` | `project` | `project` | `project` |
| `effort` | `high` | omitir | `high` | `high` | `medium` | `high` | omitir | `medium` |
| `isolation` | omitir | `worktree` | `worktree` | omitir | omitir | omitir | omitir | omitir |

**Estratégia de modelo (Híbrido):** o campo `model` do arquivo do agente **PREVALECE** sobre o ajuste "Default teammate model" do `/config` quando o agente roda como teammate. Por isso `architect`/`reviewer` ficam fixos em `opus` (raciocínio crítico, veredictos) e os demais usam `inherit` — assim seguem o `/model` do lead, permitindo controle central de custo. **Nunca criar archetype `orchestrator`/lead** (RULE #7 — a main session já é o lead nativo).

**Valores válidos dos campos (doc oficial):**
- `model`: `sonnet`, `opus`, `haiku`, `fable`, full model ID (ex: `claude-opus-4-8`), ou `inherit` (default real: `inherit`)
- `permissionMode`: `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`
- `effort`: `low`, `medium`, `high`, `xhigh`, `max` (níveis disponíveis dependem do modelo)
- `color`: `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan`

**Campos opcionais:**
- `disallowedTools`: bloquear ferramentas não usadas (ex: `Write, Edit` para revisores)
- `maxTurns`: limitar turnos em agentes de escopo fechado
- `background`: `true` para rodar sempre como background task
- `hooks`: hooks inline no frontmatter (ex: `block-git-push.sh` — em implementers E em todo agente não-devops com Bash nas squads de código dev/sites; ver `reference/archetypes.md`)

> Nota: Os campos `skills:` e `mcpServers:` no frontmatter são **ignorados** quando o agente roda como teammate em Agent Teams — skills e MCP servers são carregados do projeto/usuário como em sessão normal. Não adicionar `skills:` ao frontmatter de agentes.
>
> Nota: `SendMessage` e as ferramentas de gerenciamento de tasks (task management tools — ex.: `TaskCreate`/`TaskUpdate`/`TaskList`/`TaskGet`; os nomes exatos não são enumerados como contrato fixo na doc oficial) ficam **sempre disponíveis** ao teammate, mesmo que `tools` restrinja outras. Listá-las em `tools` é inofensivo mas não obrigatório.

---

## Presets de squad

| Preset | Agentes | Use |
|---|---|---|
| **dev** | 12 (analyst, architect, bi, data-engineer, data-performance, ux, dev-alpha, dev-beta, dev-delta, dev-gamma, qa, devops) | Fullstack SaaS |
| **sites** | 10 (analyst, architect, data, ux, dev-alpha, dev-beta, dev-delta, dev-gamma, qa, devops) | Sites e landing pages |
| **social** | 7 (analyst, content, design, photo, publisher, strategist, video) | Social media |
| **traffic** | 10 (analyst, automation, bi, copywriter, designer, google, meta, qa, strategist, tiktok) | Tráfego pago |
| **pm** | 10 (analyst, client, coach, data, demand, engineer, ops, planner, qa, reporter) | Gestão de projetos |
| **custom** | 0 | Usuário monta do zero |

> ⚠️ **Presets legados (não usar):** o diretório `presets/` ainda contém `content.yaml`, `marketing.yaml` e `data.yaml`, mas eles referenciam agentes que **não existem** no CT atual (ex.: `content-*`, `mkt-*`, `data-architect`, `ml-engineer`) — são remanescentes de um design antigo e `*squad content/marketing/data` falhariam. Não os use; pendente decisão de remover ou reconstruir.

---

## Template de agente (Native Teams Protocol)

```markdown
---
name: {nome}
description: {descrição — quando spawnar este agente}
model: {opus se architect/reviewer; senão inherit}
memory: project
{effort: high  ← se archetype exige}
{isolation: worktree  ← se implementer}
permissionMode: acceptEdits
tools: Read, Write, Edit, Glob, Grep, Bash, SendMessage
color: {cor}
{hooks:  ← se implementer que não deve fazer push}
{  PreToolUse:}
{    - matcher: "Bash"}
{      hooks:}
{        - type: command}
{          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/block-git-push.sh"}
---

## Native Teams Protocol

Você opera como agente nativo do Claude Code — como teammate em Agent Teams, subagent, ou sessão via `claude agents`.

1. **Smart-memory é source of truth.** Ao iniciar: leia `docs/smart-memory/INDEX.md` + seções da sua especialidade. Ao concluir: escreva findings na sua área. Padrão Obsidian (frontmatter YAML + wikilinks `[[...]]` + tags).
2. **Tasks via TaskList nativo.** Use as ferramentas de gerenciamento de tasks (task management tools — ex.: `TaskList`) para ver pendentes. Marque `in_progress` ao iniciar, `completed` ao concluir.
3. **Comunicação peer-to-peer.** Use `SendMessage` para qualquer teammate por nome quando precisar de colaboração ou informação.
4. **Nunca spawnar agentes.** Nested teams bloqueados por spec.
5. **Respeite autoridades exclusivas** (listadas neste arquivo).
6. **Atualize `docs/smart-memory/INDEX.md`** ao criar arquivo novo na smart-memory.
7. **Blocker em 2 tentativas?** Use SendMessage para pedir ajuda ao teammate correto.

---

# {Nome} — {Título}

{Corpo do agente...}
```

---

## Fluxo default — Command Center

### Passo 0 — Render do Command Center (determinístico)

Rodar o script que escaneia e renderiza o painel:
```bash
bash .claude/skills/team-os-creator/scripts/dashboard.sh
```
Ele chama o `scan-ct-projects.sh` (que reporta, por projeto: `team-os` instalada, nº de agentes, smart-memory e **drift vs CT por hash** — em dia / desatualizados / ausentes) e imprime o painel + as 3 ações. Mostre a saída ao usuário.

### Passo 1 — Layout do painel (referência)

O `dashboard.sh` produz exatamente este formato:

```
╔═══════════════════════════════════════════════════════════╗
║  team-os-creator  ·  Command Center  ·  by João Guirunas  ║
╚═══════════════════════════════════════════════════════════╝

  CT (fonte): {N} agentes · {N} skills · {N} squads

  Projetos irmãos:
  ┌─────────────────┬──────────┬──────────┬──────────────┬────────────┐
  │ Projeto         │ team-os  │ agentes  │ smart-memory │ drift      │
  ├─────────────────┼──────────┼──────────┼──────────────┼────────────┤
  │ {projeto-a}     │ ✓        │ 22       │ ✓            │ 3 desatual.│
  │ {projeto-b}     │ ✗        │ 0        │ ✗            │ não instal.│
  └─────────────────┴──────────┴──────────┴──────────────┴────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [1] Criar equipe       → novos agentes/squad (segue todo o processo: NTP + smart-memory + skills + modelo híbrido)
  [2] Atualizar equipes  → propaga o drift detectado para os projetos (*propagate)
  [3] Instalar equipe    → instala squad + skills + team-os num projeto (*install)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Cada ação mapeia para os fluxos abaixo (`*create`/`*squad`, `*propagate`, `*install`). Toda criação/edição roda `*audit` ao final.

---

## Fluxo `*migrate`

1. Escaneia `.claude/agents/*.md` no projeto atual
2. Identifica agentes com "## Contrato com team-os"
3. Mostra lista e pede confirmação
4. Para cada agente: substitui bloco antigo por "## Native Teams Protocol"
5. Valida compliance após migração
6. Relatório final

---

## Fluxo `*bootstrap`

1. Verifica se `docs/smart-memory/` já existe — pergunta antes de sobrescrever
2. Cria a estrutura de smart-memory **conforme `team-os/scripts/discovery.sh`** (estrutura canônica): `INDEX.md` + `project/` + `decisions/` + `stories/` (com `backlog/active/in-review/done`) + `agents/<área>/`. Não crava outras pastas top-level — `architecture` e `modules` vivem como arquivos dentro de `project/`, e `qa`/`research` ficam sob `agents/`. A referência canônica é sempre a estrutura gerada pelo `discovery.sh`.
3. Injeta Smart-Memory Protocol no `CLAUDE.md` do projeto
4. Relatório

---

## Fluxo `*install`

1. Lista projetos via `scan-ct-projects.sh`
2. **Determina a categoria do projeto e instala SÓ a(s) squad(s) correspondente(s)** — NUNCA todas. Social→`social`, site→`sites`, etc. Pode combinar quando o projeto exige (ex.: workspace de conteúdo com site → `social,sites`). Passe `--squads <categoria>` — **nunca** `--squads all` (o script avisa com `SQUADS_WARNING`). Na dúvida, pergunte ao usuário.
3. Preview da instalação
4. Copia agents da(s) squad(s) escolhida(s) + skills (incluindo **`team-os` obrigatória**) + cria `settings.json` com `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (+ hooks se `--include-hooks`)
5. **Instala o session-title hook (core UX):** copia `team-os-session-title.sh` para `~/.claude/hooks/` e garante o registro do `SessionStart` em `~/.claude/settings.json` (nomeia toda sessão por `projeto · branch`). O script reporta `SESSION_TITLE_REGISTER_TODO=1` se faltar o registro — nesse caso, edite o settings global com JSON válido. Ver "Nomeação automática da sessão" na skill `team-os`.
6. **NÃO copia `team-os-creator`** — única skill exclusiva do CT
7. **Não** cria smart-memory aqui — o `/team-os` constrói no projeto na 1ª sessão (Discovery). Orienta o usuário a abrir `claude agents` e rodar `/team-os`.
8. Relatório

---

## Fluxo `*propagate`

1. Scan de projetos
2. Diff de agentes **e skills** (por hash/conteúdo) vs CT
3. Confirmação com preview (use `--dry-run` para inspecionar antes)
4. Sincroniza para cada destino, **sempre com `--match-target-squads`** (modo propagate):
   - **Agentes**: atualiza só os das squads **já instaladas** no destino. **NUNCA re-adiciona squad podada** — squad ausente é poda intencional por categoria, não drift. (Internamente o script deriva as squads do que existe no destino; agente de squad ausente é pulado.)
   - **Skills**: atualiza as que diferem (incluindo `team-os`); skills extras do destino são preservadas; `team-os-creator` nunca é enviada
5. **Commita SELETIVAMENTE em cada destino que seja repo git** (RULE #12) — `git add` **apenas** dos arquivos efetivamente propagados (os listados em `AGENTS_LIST`/`SKILLS_LIST`), nunca `git add -A`: o working tree do destino costuma ter mudanças pré-existentes não relacionadas que NÃO devem ser varridas. Commit com descrição (`feat(<squad>): …` ou `chore(team): sync agents/skills do CT`). Se o destino **não** for repo git, só reportar (não há o que commitar). **Push NÃO** — exige confirmação de branch (padrão `main`).
6. Relatório (AGENTS_UPDATED, SKILLS_UPDATED, projetos commitados, projetos sem git, …)

> ⚠️ **Nunca** rode propagate/install sem escopo de squad num projeto já podado — isso re-instalaria as squads removidas. O `--match-target-squads` é a salvaguarda: respeita a categoria de cada projeto. Para um projeto novo, use `--squads <categoria>` explícito.

---

## Definition of Done (RULE #12) — ciclo obrigatório de toda alteração

Qualquer criação/atualização de agente ou skill **só está pronta** quando TODO o ciclo abaixo foi executado, de uma vez, sem precisar ser lembrado:

1. **Refinar** — entrega completa, não pela metade (frontmatter + body + hooks + skills relacionadas).
2. **Sincronizar docs** — atualizar contagens e catálogos no `README.md` (linha de resumo, "Catálogo de skills", contagem por squad, árvore de diretórios) **e** `CLAUDE.md` (linha "N agentes e N skills"). Skill nova entra no catálogo da squad e na tabela do agente que a usa.
3. **`*audit`** — `scripts/validate-agent.sh` deve passar 100%.
4. **Commit no CT** — conventional commit com descrição clara do que mudou.
5. **`*propagate --match-target-squads`** — para todos os projetos com a(s) squad(s) afetada(s). Varrer os projetos por agentes da squad (não confiar só no dashboard) para não esquecer nenhum.
6. **Commit seletivo em cada destino git** — conforme passo 5 do fluxo `*propagate`.
7. **Relatório final** — o que mudou, onde foi commitado, o que ficou pendente (ex.: destino sem git, push aguardando branch).

---

## Estrutura de suporte

```
.claude/skills/team-os-creator/
├── SKILL.md
├── hooks/
│   ├── block-git-push.sh
│   ├── check-social-progress.sh
│   └── check-story-progress.sh
├── presets/
├── reference/
│   ├── archetypes.md
│   ├── smart-memory-integration.md
│   └── skills-catalog-quality.md
├── scripts/
│   ├── preflight.sh
│   ├── detect-project-signals.sh
│   ├── validate-agent.sh           ← *audit
│   ├── scan-ct-projects.sh         ← status + drift por hash
│   ├── dashboard.sh                ← Command Center (render do painel)
│   ├── diff-agents.sh
│   └── install-to-project.sh
└── templates/
```

---

## Comportamento em situações específicas

| Situação | Ação |
|---|---|
| Agente com nome existente | Oferecer: atualizar / pular / renomear / cancelar |
| Projeto destino sem `.claude/` | Criar estrutura mínima antes |
| `docs/smart-memory/` já existe no destino | Perguntar antes de sobrescrever no `*bootstrap` |
| `CLAUDE.md` já tem seção Smart-Memory | Não duplicar — verificar antes de injetar |
| Destino é o mesmo que a fonte (CT) | Bloquear com erro claro |
| `scan-ct-projects.sh` acha só CT | Oferecer digitar caminho manual |
| Agentes sem "Contrato com team-os" no `*migrate` | Pular silenciosamente (já migrados) |
| Usuário pede para instalar `team-os` no destino | Fazer — `team-os` é obrigatória nos projetos. Recusar APENAS `team-os-creator` (exclusiva do CT). |
