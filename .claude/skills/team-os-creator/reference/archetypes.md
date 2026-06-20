# Archetypes de agente — defaults completos

Cada archetype mapeia pra um template em `templates/{archetype}.md` e define os defaults de frontmatter. Quando o `*create` roda, a skill lê essa referência, aplica defaults do archetype escolhido, e substitui os placeholders com input do usuário.

---

## Tabela de defaults

| Archetype | Model | memory | isolation | permissionMode | Tools base | Hook git push |
|---|---|---|---|---|---|---|
| `architect` | opus | project | — | — | Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage | ✅¹ |
| `implementer` | inherit | project | worktree | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, SendMessage | ✅ |
| `hardening` | inherit | project | worktree | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, WebSearch, SendMessage | ✅ |
| `reviewer` | opus | project | — | — | Read, Glob, Grep, Bash, SendMessage | ✅¹ |
| `researcher` | inherit | project | — | — | Read, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage | ✅¹ |
| `data` | inherit | project | — | — | Read, Write, Edit, Glob, Grep, Bash, SendMessage | ✅¹ |
| `devops` | inherit | project | — | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, SendMessage | — |
| `ux` | inherit | project | — | — | Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, SendMessage | ✅¹ |

> **¹ Hook git push (push exclusivo do devops):** em **squads de código** (`dev`/`sites`), **todo** agente não-`devops` que tem `Bash` carrega `block-git-push.sh` — não só os implementers. Isso transforma "push é só do devops" de convenção em **garantia dura** (defense-in-depth): qualquer agente com Bash poderia tecnicamente dar `git push`, então só o `devops` fica sem o hook. Em squads **não-código** (`social`/`traffic`/`pm`) não há devops nem fluxo de push de código — lá só o archetype `implementer` (ex.: `social-video`) leva o hook.

> **Nota sobre `model` (Híbrido):** o campo `model` do arquivo do agente PREVALECE sobre o ajuste "Default teammate model" do `/config` quando o agente roda como teammate. Por isso `architect`/`reviewer` ficam fixos em `opus` (raciocínio crítico que não vale economizar) e os demais usam `inherit` — assim seguem o `/model` escolhido pelo lead, dando controle central de custo. **Não existe archetype `orchestrator`:** a main session do Claude Code já é o lead nativo (ver RULE #7 do SKILL.md).

---

## Justificativas das decisões

### Por que `opus` para architect/reviewer
Esses papéis precisam de raciocínio profundo: decisões arquiteturais, veredictos de qualidade. Não vale economizar tokens aqui — uma decisão errada custa muito mais depois. Por isso ficam fixos em `opus` (o campo do arquivo vence o `/config`).

### Por que `inherit` para implementer/data/devops/ux/researcher/hardening
Execução com especialização bem definida. Com `inherit`, o teammate segue o `/model` escolhido pelo lead na sessão — o lead pode baixar a frota inteira pra haiku/sonnet numa sessão barata, mantendo `architect`/`reviewer` protegidos em opus. Com contratos claros (smart-memory + Native Teams Protocol) o output fica consistente em qualquer modelo.

### Por que worktree só em implementer/hardening
Apenas esses dois **escrevem código que vai pro repositório**. Isolar em worktree permite múltiplos rodando em paralelo sem pisar no branch principal.

Reviewer é read-only (não escreve código), UX escreve specs (não código), architect escreve stories/ADRs (não código). Nenhum precisa de worktree.

### Por que hook de git push em todo agente não-devops das squads de código
A autoridade de push é **exclusiva do `devops`**. Antes o hook ficava só nos implementers (assumindo que só eles rodam `git`), mas qualquer agente com `Bash` — architect, reviewer/QA, data, analyst, ux — *pode* tecnicamente dar `git push` e furar a exclusividade. Para fazer disso uma garantia dura (não convenção), nas squads `dev`/`sites` **todos** os não-`devops` com Bash carregam `block-git-push.sh`; só o `devops` fica livre. Nas squads não-código (`social`/`traffic`/`pm`) não há devops nem push de código, então só o `implementer` (ex.: `social-video`) leva o hook. O script é chamado via path absoluto (`$CLAUDE_PROJECT_DIR`).

### Por que `permissionMode: acceptEdits` só em implementer/hardening/devops
Esses 3 fazem edições extensas e previsíveis (code, migrations, CI configs). `acceptEdits` reduz fricção de autorização repetitiva.

Architect/analyst/UX escrevem poucos arquivos (docs) — deixar o default permite revisão humana natural.

### Por que reviewer não tem Write/Edit
Exclusividade de **veredicto formal**. Se pudesse editar código, borraria o papel. Ele SÓ lê e emite veredicto em `docs/smart-memory/agents/qa/results.md` (e esse é a única exceção — via Bash `cat >>`).

---

## Regras aplicadas a TODOS os archetypes

Independente do archetype, todo agente gerado pela skill tem:

1. **Frontmatter `memory: project`** — integração com smart-memory
2. **Seção "Native Teams Protocol"** no topo do corpo — 7 regras canônicas (peer-to-peer, TaskList nativo, smart-memory)
3. **Mention de `SendMessage`** — obrigatório para coordenação peer-to-peer
4. **Mention de `docs/smart-memory/`** — smart-memory obrigatório
5. **"Regras absolutas"** ao final — enforcement
6. **H1 com persona + role title** — identidade

Se algum desses faltar após geração, `validate-agent.sh` retorna falha e a skill tenta reinjetar.

---

## Escolha de archetype — heurísticas

Quando o usuário diz um role, mapear pra archetype assim:

| Se usuário disse... | Archetype |
|---|---|
| "frontend", "backend", "fullstack", "developer", "implementer" | `implementer` |
| "architect", "system design", "tech lead" | `architect` |
| "QA", "quality", "reviewer", "auditor" | `reviewer` |
| "research", "analyst", "investigator" | `researcher` |
| "DBA", "data engineer", "database" | `data` |
| "devops", "SRE", "release", "CI/CD" | `devops` |
| "UX", "design", "UI", "accessibility" | `ux` |
| "hardening", "resilience", "error handling", "security engineer" | `hardening` |
| "chief", "orchestrator", "coordinator", "lead" | ⛔ Recusar — a main session do Claude Code já é o lead nativo (RULE #7). Não criar agente de orquestração. |

Se ambíguo, perguntar ao usuário qual archetype usar (listar opções).

---

## Color palette convencionada

Evitar repetir cores na mesma squad (facilita shift+tab visual no Claude Code):

Valores válidos (doc oficial): `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan`.

| Cor | Uso típico |
|---|---|
| `blue` | Reservada ao lead (main session) — evitar em teammates |
| `purple` | Architect |
| `cyan` | Researcher/analyst |
| `pink` | UX |
| `yellow` | Frontend implementer / writer |
| `orange` | Backend implementer / data |
| `green` | Fullstack implementer / devops |
| `red` | QA / hardening |
