# Padrões Obsidian para smart-memory

Todo arquivo em `docs/smart-memory/` segue esses padrões. Eles são a base de navegação — sem eles o smart-memory vira um amontoado de markdown solto.

## Frontmatter obrigatório

Todo `.md` em `docs/smart-memory/` começa com YAML:

```yaml
---
title: "Nome descritivo"      # obrigatório
type: overview | story | decision | research | qa-result | schema | task-log | backlog | status-board | index  # obrigatório
status: active | backlog | done | deprecated | proposed | accepted  # quando aplicável
agent: dev-architect          # quem é responsável por esse arquivo
created: 2026-04-22           # ISO date, obrigatório
updated: 2026-04-22           # ISO date, obrigatório
tags: [architecture, auth]    # array — vide lista canônica abaixo
related: ["[[../stories/1.1-auth]]", "[[ADR-003]]"]  # wikilinks de contexto
---
```

## Tags canônicas

Use só essas — não invente novas sem atualizar esse arquivo e o INDEX.

| Tag | Uso |
|---|---|
| `#project` | overview, tech-stack, conventions |
| `#architecture` | modules, architecture, ADRs |
| `#story` | stories (backlog, active, done) |
| `#decision` | ADRs |
| `#research` | research reports |
| `#qa` | QA results, verdictos |
| `#database` | schema, migrations |
| `#ux` | component specs, design decisions |
| `#security` | auth, permissions, CVEs |
| `#performance` | otimizações, benchmarks |
| `#task-log` | delegation-log, migrations-log, teams-log |

## Wikilinks

Navegação entre arquivos é sempre via wikilink `[[...]]`, nunca via path relativo direto no corpo.

Formas:

```markdown
[[overview]]                  → resolve pra overview.md no mesmo dir ou anywhere em smart-memory
[[../stories/BACKLOG]]        → path relativo (use só quando necessário para desambiguar)
[[ADR-003|decisão de cache]]  → wikilink com alias display
```

**Regra:** Ao criar arquivo novo, sempre adicionar wikilinks saindo dele (no frontmatter `related` e no corpo) E uma entrada em `INDEX.md` ou em algum MOC existente.

## Maps of Content (MOCs)

Hubs que agregam wikilinks por tema. Ficam em `docs/smart-memory/INDEX.md` (o MOC raiz) e em arquivos `{tema}-MOC.md` quando um tema ganhar volume.

Exemplo de MOC por tema:

```markdown
---
title: Auth MOC
type: index
updated: 2026-04-22
tags: [security, auth]
---

# Auth — Map of Content

## Decisões
- [[../decisions/ADR-003-jwt-strategy]]
- [[../decisions/ADR-007-rbac-model]]

## Stories
- [[../stories/done/1.1-basic-auth]]
- [[../stories/active/2.3-oauth-google]]

## Research
- [[../agents/research/jwt-vs-session]]
- [[../agents/research/oauth-providers-comparison]]
```

## Dev Agent Record (dentro de stories)

Toda story ativa tem essa tabela — teammates atualizam conforme trabalham:

```markdown
## Dev Agent Record

| Campo      | Valor |
|---         |---|
| Agente     | {nome-teammate} |
| Iniciado   | {ISO date} |
| Concluído  | {ISO date ou —} |
| Branch     | feature/{N}-{M}-{slug} |
```

Auditoria de `*audit` verifica: se Iniciado preenchido mas Concluído vazio há > 2h, flaga como possível travamento.

## Linha "Related" no frontmatter vs body

- **`related:` no frontmatter**: wikilinks críticos pra resolver dependências (ex: story → ADR que motivou, ADR → research).
- **Wikilinks no corpo**: uso descritivo, navegação natural.

Use os dois. Ferramenta de grafo do Obsidian lê ambos.

## Datas

Sempre ISO 8601 (`YYYY-MM-DD`). Se precisar de timestamp: `YYYY-MM-DD HH:MM`. Nunca relativas ("ontem", "semana passada") — não sobrevivem a leituras futuras.
