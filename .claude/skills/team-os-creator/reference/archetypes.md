# Archetypes de agente — defaults completos

Cada archetype mapeia pra um template em `templates/{archetype}.md` e define os defaults de frontmatter. Quando o `*create` roda, a skill lê essa referência, aplica defaults do archetype escolhido, e substitui os placeholders com input do usuário.

---

## Tabela de defaults

| Archetype | Model | Effort | memory | isolation | permissionMode | Tools base | Hook git push |
|---|---|---|---|---|---|---|---|
| `architect` | opus | high | project | — | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage | ✅¹ |
| `strategist` | opus | high | project | — | —² | Read, Write, Edit, Glob, Grep, Bash, SendMessage | ✅¹ |
| `implementer` | inherit | — | project | — | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, SendMessage | ✅¹ |
| `hardening` | inherit | high | project | — | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, WebSearch, SendMessage | ✅¹ |
| `reviewer` | opus | high | project | — | —² | Read, Glob, Grep, Bash, SendMessage, Write, Edit³ | ✅¹ |
| `researcher` | inherit | medium | project | — | — | Read, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage | ✅¹ |
| `data` | inherit | high | project | — | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, SendMessage | ✅¹ |
| `devops` | inherit | — | project | — | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, SendMessage | ⛔ proibido |
| `ux` | inherit | medium | project | — | acceptEdits | Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, SendMessage | ✅¹ |

> **Effort por papel (política canônica, validada pelo `*audit`):** `high` em architect/reviewer(QA)/strategist/hardening/data (raciocínio crítico); `medium` em researcher/ux; **omitido** em implementer/devops (seguem o default do modelo). **Exceções canônicas por nome** (validadas pelo `*audit`): `dev-bi`, `dev-data-performance` e `pm-coach` usam `medium` — são papéis de BI/insights/coaching que interpretam dados e processos, não desenham schema.

> **¹ Hook git push (push exclusivo do devops — regra validada pelo `*audit`):** **todo** agente que tem `Bash` em `tools` e cujo archetype **não é `devops`** carrega `block-git-push.sh` — em **todas as squads** (`dev`, `sites`, `social`, `traffic`, `pm`), não só nas de código e não só nos implementers. E o inverso também é garantia dura: o `devops` é **proibido** de ter o hook (push é a autoridade exclusiva dele). Agente sem `Bash` (ex.: `social-strategist`) não precisa — não tem como dar push.

> **² permissionMode (regra validada pelo `*audit`):** `permissionMode` é **obrigatório** (valor no enum `default | acceptEdits | auto | dontAsk | bypassPermissions | plan`; recomendado `acceptEdits`) em **qualquer agente com `Write` ou `Edit` em tools** — exceto nos archetypes `reviewer` e `strategist`, onde é **opcional** (o default do sistema mantém a revisão humana das poucas escritas que eles fazem). Em `reviewer`/`strategist`, `bypassPermissions` é **proibido**.

> **³ Reviewer com Write/Edit de escopo restrito:** o reviewer tem `Write`/`Edit` em tools, mas o body restringe o uso a `docs/smart-memory/agents/qa/*` e à seção `## QA Results` da story em revisão (+ mover a story de `active/` para `done/`). Nunca modifica código.

> **Nota sobre `model` (Híbrido):** o campo `model` do arquivo do agente PREVALECE sobre o ajuste "Default teammate model" do `/config` quando o agente roda como teammate. Por isso `architect`/`reviewer` ficam fixos em `opus` (raciocínio crítico que não vale economizar) e os demais usam `inherit` — assim seguem o `/model` escolhido pelo lead, dando controle central de custo. **Não existe archetype `orchestrator`:** a main session do Claude Code já é o lead nativo (ver RULE #7 do SKILL.md).

---

## Justificativas das decisões

### Por que `opus` para architect/reviewer/strategist
Esses papéis precisam de raciocínio profundo: decisões arquiteturais, veredictos de qualidade, direção estratégica. Não vale economizar tokens aqui — uma decisão errada custa muito mais depois. Por isso ficam fixos em `opus` (o campo do arquivo vence o `/config`).

### Strategist — quando usar
`strategist` é o papel de **direção + validação** em squads não-código: define estratégia e briefings, cria/prioriza stories da squad e emite veredicto formal antes da publicação/execução (ex.: `social-strategist`, `traffic-strategist`). É um "reviewer que também direciona": mesma classe de raciocínio (opus, effort high), com `Write`/`Edit` para escrever briefs e estratégia na smart-memory — mas **nunca produz o deliverable** (copy, criativo, campanha). Template em `templates/strategist.md`.

### Por que `inherit` para implementer/data/devops/ux/researcher/hardening
Execução com especialização bem definida. Com `inherit`, o teammate segue o `/model` escolhido pelo lead na sessão — o lead pode baixar a frota inteira pra haiku/sonnet numa sessão barata, mantendo `architect`/`reviewer` protegidos em opus. Com contratos claros (smart-memory + Native Teams Protocol) o output fica consistente em qualquer modelo.

### Por que isolation: worktree foi removido de implementer/hardening
Worktree cria branches isoladas automaticamente — útil em teoria para paralelismo, mas na prática impede que as mudanças apareçam no checkout principal (onde o servidor dev roda), gera branches zumbis no git e confunde o fluxo de trabalho local. Agentes implementers e hardening agora escrevem direto na branch ativa (main), tal como o desenvolvedor faria manualmente.

### Por que hook de git push em todo agente não-devops com Bash (todas as squads)
A autoridade de push é **exclusiva do `devops`**. Antes o hook ficava só nos implementers (assumindo que só eles rodam `git`), mas qualquer agente com `Bash` — architect, reviewer/QA, data, analyst, ux, strategist — *pode* tecnicamente dar `git push` e furar a exclusividade. Para fazer disso uma garantia dura (não convenção), **em todas as squads** todo agente não-`devops` com `Bash` carrega `block-git-push.sh`; só o `devops` fica livre (e é **proibido** de ter o hook — se o tivesse, ninguém conseguiria dar push). Isso vale também nas squads sem devops (`social`/`traffic`/`pm`): lá o hook garante que nenhum agente empurra nada — push nessas squads é sempre do usuário/lead. O script é chamado via path absoluto (`$CLAUDE_PROJECT_DIR`). Regra validada pelo `*audit`.

### Por que `permissionMode` é obrigatório em quem tem Write/Edit
Qualquer agente com `Write`/`Edit` em tools precisa declarar `permissionMode` explicitamente (valor no enum; recomendado `acceptEdits`, que reduz fricção de autorização repetitiva em edições extensas e previsíveis — code, migrations, docs, specs). As exceções são `reviewer` e `strategist`: neles o campo é **opcional** (o default do sistema mantém revisão humana das poucas escritas formais que fazem) e `bypassPermissions` é **proibido** — um gate de qualidade nunca roda sem freios. Regra validada pelo `*audit`.

### Por que reviewer tem Write/Edit de escopo restrito
Exclusividade de **veredicto formal**. O reviewer tem `Write`/`Edit` em tools (registrar veredicto via `cat >>` no Bash era frágil), mas o body restringe a escrita a `docs/smart-memory/agents/qa/*` e à seção `## QA Results` da story em revisão (+ mover a story de `active/` para `done/`). Se editasse código, borraria o papel — nunca modifica código, stories fora da seção QA, ou acceptance criteria.

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
| "estrategista", "strategist", "direção editorial", "planejamento de campanha", "validação editorial" | `strategist` |
| "DBA", "data engineer", "database" | `data` |
| "devops", "SRE", "release", "CI/CD" | `devops` |
| "UX", "design", "UI", "accessibility" | `ux` |
| "hardening", "resilience", "error handling", "security engineer" | `hardening` |
| "chief", "orchestrator", "coordinator", "lead" | ⛔ Recusar — a main session do Claude Code já é o lead nativo (RULE #7). Não criar agente de orquestração. |

Se ambíguo, perguntar ao usuário qual archetype usar (listar opções).

---

## Color palette convencionada

Valores válidos (doc oficial): `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan`.

**Regras validadas pelo `*audit`:**
- `color` fora do enum acima → **erro**
- `blue` em teammate → **erro** (reservada ao lead / main session)
- archetype `reviewer` (QA) sem `red` → **erro** (red é a cor do gate de qualidade)
- cor repetida entre agentes da mesma squad → **warning** (dificulta o shift+tab visual, mas às vezes é inevitável em squads grandes)

| Cor | Uso típico |
|---|---|
| `blue` | Reservada ao lead (main session) — proibida em teammates |
| `purple` | Architect / strategist |
| `cyan` | Researcher/analyst |
| `pink` | UX |
| `yellow` | Frontend implementer / writer |
| `orange` | Backend implementer / data |
| `green` | Fullstack implementer / devops |
| `red` | QA/reviewer (obrigatório) / hardening |
