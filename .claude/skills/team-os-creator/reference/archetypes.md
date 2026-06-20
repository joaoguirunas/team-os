# Archetypes de agente — defaults completos

Cada archetype mapeia pra um template em `templates/{archetype}.md` e define os defaults de frontmatter. Quando o `*create` roda, a skill lê essa referência, aplica defaults do archetype escolhido, e substitui os placeholders com input do usuário.

---

## Tabela de defaults

| Archetype | Model | memory | isolation | permissionMode | Tools base | Hook git push |
|---|---|---|---|---|---|---|
| `architect` | opus | project | — | — | Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage | — |
| `implementer` | inherit | project | worktree | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, SendMessage | ✅ |
| `hardening` | inherit | project | worktree | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, WebSearch, SendMessage | ✅ |
| `reviewer` | opus | project | — | — | Read, Glob, Grep, Bash, SendMessage | — |
| `researcher` | inherit | project | — | — | Read, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage | — |
| `data` | inherit | project | — | — | Read, Write, Edit, Glob, Grep, Bash, SendMessage | — |
| `devops` | inherit | project | — | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, SendMessage | — |
| `ux` | inherit | project | — | — | Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, SendMessage | — |

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

### Por que hook de git push só em implementer/hardening
Mesmo argumento: são os que executam `git` commands. Outros archetypes não deveriam fazer commit/push — e se tentarem, o hook em 2 agentes já é suficiente pra bloquear (o código é chamado via path absoluto).

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
