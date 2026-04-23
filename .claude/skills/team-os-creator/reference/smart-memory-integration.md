# Integração smart-memory por archetype

Todo agente gerado pela skill precisa saber **o que escreve em `docs/smart-memory/`** e **em que formato** (padrão Obsidian). Esta referência é consumida pelos templates em `templates/{archetype}.md` — a seção "O que você escreve na smart-memory".

---

## Matriz: archetype × responsabilidade em smart-memory

| Archetype | Escreve em | Formato |
|---|---|---|
| `orchestrator` | `shared-context.md`, `ops/delegation-log.md`, `ops/teams-log.md` | Status board + logs cronológicos |
| `architect` | `project/architecture.md`, `project/modules.md`, `decisions/ADR-*.md`, `stories/backlog/*.md`, `stories/BACKLOG.md` | Obsidian + Mermaid |
| `implementer` | `stories/active/<N.M>-*.md` (só updates em Dev Agent Record / File List / AC) | Não cria arquivos, só atualiza |
| `hardening` | `stories/active/<N.M>-*.md` (mesmas regras do implementer) | Updates on story |
| `reviewer` (QA) | `agents/qa/results.md`, seção QA Results da story | Veredicto formal |
| `researcher` | `agents/research/<tema>.md`, `project/tech-stack.md`, `project/conventions.md` | Research reports |
| `data` | `agents/data-engineer/schema.md`, `agents/data-engineer/migrations-log.md` | Schema tabular + log |
| `devops` | `ops/releases-log.md` (se existir) + comentários em teams-log ao encerrar team | Log de releases |
| `ux` | `agents/ux/components.md`, `agents/ux/flows/*.md` | Component specs + ASCII wireframes + Mermaid user flows |

---

## Regras comuns (todos os archetypes)

1. **Frontmatter Obsidian obrigatório** em todo `.md` criado em `docs/smart-memory/`:
   ```yaml
   ---
   title: "..."
   type: overview | story | decision | research | qa-result | schema | task-log | backlog | status-board | index | component-spec
   status: active | backlog | done | deprecated | proposed | accepted  # quando aplicável
   agent: <nome-do-agente>
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   tags: [...]
   related: ["[[...]]", "[[...]]"]
   ---
   ```

2. **Wikilinks `[[arquivo]]`** pra navegação — nunca links relativos crus no corpo.

3. **Tags canônicas** (não inventar): `#project`, `#architecture`, `#story`, `#decision`, `#research`, `#qa`, `#database`, `#ux`, `#security`, `#performance`, `#task-log`.

4. **Atualizar `INDEX.md`** sempre que criar arquivo novo.

5. **Datas ISO 8601** (`YYYY-MM-DD`) — nunca relativas.

---

## Templates de frontmatter por tipo de arquivo

### Story
```yaml
---
title: "Story {N}.{M}: {Título}"
type: story
status: backlog | active | done
epic: {N}
complexity: S | M | L | XL
agent: {quem-assumiu}
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [story, {domínio}]
related: [[../../decisions/ADR-{N}]]
---
```

### ADR
```yaml
---
title: "ADR-{N}: {Título}"
type: decision
status: proposed | accepted | deprecated
agent: {architect-name}
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [architecture, {domínio}]
related: [[../agents/research/{tema}]]
---
```

### Research report
```yaml
---
title: "Research: {tema}"
type: research
agent: {researcher-name}
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [research, {domínio}]
related: [[../../decisions/ADR-{N}]]
---
```

### Schema
```yaml
---
title: Schema Atual
type: schema
agent: {data-name}
updated: YYYY-MM-DD
tags: [database, schema]
related: [[migrations-log]]
---
```

### QA Results (índice cross-story)
```yaml
---
title: QA Results
type: qa-result
agent: {qa-name}
updated: YYYY-MM-DD
tags: [qa]
---
```

### Component specs
```yaml
---
title: Component Specs
type: component-spec
agent: {ux-name}
updated: YYYY-MM-DD
tags: [ux, components]
---
```

---

## Anti-patterns a evitar nos templates gerados

1. **NÃO deixar o prompt do agente sem seção "O que escreve na smart-memory"** — obriga o agente a entender seu dever de persistência.

2. **NÃO deixar o prompt sem mention de atualizar `INDEX.md`** — novos arquivos ficam órfãos.

3. **NÃO deixar o agente escrever em paths fora de `docs/smart-memory/`** pra conhecimento canônico — só escreva em outros lugares se for parte do código do projeto (implementers escrevem código fora de smart-memory; isso é ok).

4. **NÃO misturar responsabilidades** — ex: analyst NÃO escreve `modules.md` (é do architect); architect NÃO escreve `tech-stack.md` (é do analyst). Conflitos de escrita quebram a discovery paralela.

---

## Como a skill `*audit` valida

A skill team-os-creator não audita smart-memory — essa é responsabilidade de `/team-os *audit`. Mas o `validate-agent.sh` verifica que:

1. O prompt menciona `docs/smart-memory/` em alguma parte do corpo
2. O prompt menciona `SendMessage` (pra coordenação)
3. O prompt menciona "Contrato com team-os"

Se algum faltar, o validate falha e a skill tenta reinjetar o bloco faltante a partir dos templates.
