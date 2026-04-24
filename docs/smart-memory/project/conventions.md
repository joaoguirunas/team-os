---
title: Conventions
type: conventions
status: active
agent: dev-analyst
created: 2026-04-24
updated: 2026-04-24
tags: [project, conventions]
related: ["[[overview]]", "[[tech-stack]]", "[[modules]]"]
---

# Convenções — Centro de Treinamento

## Estrutura de um agente (.claude/agents/{nome}.md)

```markdown
---
name: {nome}
description: {descrição curta — aparece na UI do Claude Code}
model: opus | sonnet | haiku
memory: project
tools: {lista de tools separadas por vírgula}
color: {cor opcional}
---

## Contrato com team-os

[seção gerada pelo *enroll — não editar manualmente]

# {Nome do Agente} — {Título}

[prompt completo do agente]
```

## Convenção de nomenclatura

- `{squad}-{papel}` para agentes de execução: `dev-dev-alpha`, `sites-dev-beta`
- `{squad}-{função}` para papéis especializados: `dev-qa`, `traffic-strategist`
- Sem prefixo para skills trans-squad: `deep-research`, `accessibility`, `ui-ux-pro-max`

## Seleção de modelo

| Critério | Modelo |
|---|---|
| Decisão arquitetural, criação de stories, validação QA | **opus** |
| Execução de código, análise, research, produção | **sonnet** |
| Tarefas simples/rápidas, alto volume | **haiku** |

## Ferramentas por tipo de agente

| Tipo | Tools típicas |
|---|---|
| Read-only analyst | `Read, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage` |
| Executor/implementador | `Read, Write, Edit, Glob, Grep, Bash, SendMessage` |
| Architect/QA (sem write no código) | `Read, Glob, Grep, Bash, SendMessage` + `Write, Edit` para docs |
| DevOps | `Read, Write, Edit, Glob, Grep, Bash, SendMessage` |
| Agente com MCP | + MCPs específicos para a função |

## Convenção de skills (.claude/skills/{nome}/)

```
{nome}/
├── SKILL.md          # Prompt completo da skill
├── templates/        # Templates que a skill usa
├── scripts/          # Scripts de suporte (bash)
└── reference/        # Docs de referência da skill
```

## Smart-memory — padrão Obsidian

- Wikilinks: `[[arquivo]]` ou `[[subdir/arquivo]]`
- Frontmatter YAML obrigatório em todos os arquivos
- `INDEX.md` = MOC raiz — sempre atualizar ao criar arquivos novos
- `shared-context.md` = status board atualizado pelo lead a cada mudança
- Stories: `{N.M}` onde N = épico, M = story dentro do épico

## Padrão de story

```markdown
---
id: {N.M}
title: {título}
status: backlog | active | done
assignee: {nome-do-agente ou "—"}
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
complexity: XS | S | M | L | XL
tags: []
---

# {título}

## Contexto
## Critérios de aceite
## Notas técnicas
```

## Autoridades exclusivas (nunca violar)

| Função | Agente exclusivo |
|---|---|
| Criar stories (dev) | `dev-architect` |
| Criar stories (sites) | `sites-architect` |
| Criar stories (traffic) | `traffic-strategist` |
| QA final (dev) | `dev-qa` |
| QA final (sites) | `sites-qa` |
| QA final (traffic) | `traffic-qa` |
| git push + PR (dev/sites) | `dev-devops` ou `sites-devops` |
| Publicar social | `social-publisher` (APÓS `social-strategist` aprovar) |

## Ciclo de vida de um Agent Team

1. `TeamCreate` → 2. `Agent()` × N → 3. `TaskCreate` → 4. trabalho paralelo → 5. `SendMessage` (conclusão) → 6. QA gate → 7. DevOps publish → 8. `*close`
