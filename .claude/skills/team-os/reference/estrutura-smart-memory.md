# Estrutura da smart-memory (criada pelo discovery.sh)

> Extraído do SKILL.md — carregar sob demanda. Convenções: `agents/<squad>/<área>/` (DIGEST.md + arquivos; arquivo de squad inteira pode ficar em `agents/<squad>/`) e `stories/{backlog,active,in-review,done}/<id>-<slug>.md` + `stories/BACKLOG.md`.

## Árvore

```
docs/smart-memory/
├── INDEX.md                    ← MOC raiz — linka [[agents/<squad>/<área>/DIGEST]] e [[stories/active/]]
├── _inbox/                     ← notas rápidas da sessão (<agente>-<data>.md) — consolidadas
│                                  nos DIGESTs no *compact (--clear-inbox esvazia depois)
├── project/
│   ├── overview.md             ← visão geral do projeto (preencher junto com o usuário)
│   ├── tech-stack.md           ← stack detectado automaticamente + confirmar
│   ├── conventions.md          ← padrões de código do projeto
│   ├── architecture.md         ← visão arquitetural + diagrama Mermaid (dev-architect refina)
│   └── modules.md              ← mapa de módulos + God Nodes (devs enriquecem)
├── decisions/                  ← decisões técnicas / ADRs pontuais
├── stories/
│   ├── BACKLOG.md              ← lista master de todas as stories
│   ├── backlog/                ← stories aguardando priorização — <id>-<slug>.md
│   ├── active/                 ← stories em andamento (Fase 0 lê daqui direto)
│   ├── in-review/              ← stories em revisão/QA
│   └── done/                   ← stories concluídas
│                                  (formato do <id> é livre por squad: 1.2, P3, F1…)
├── agents/                     ← agents/<squad>/<área>/ — UMA área por agente da squad
│   │                              INSTALADA (o discovery.sh lê a linha "Área na smart-memory"
│   │                              de cada agente em .claude/agents/ — exemplo: squad dev)
│   └── dev/
│       ├── research/           ← findings de pesquisa (dev-analyst escreve)
│       │   └── DIGEST.md       ← resumo vivo da área (~40 linhas, máx 60) — seções "Core
│       │                          (permanente)" e "Contexto recente (expira ~14 dias)"; fatos
│       │                          atômicos datados
│       ├── qa/      (+DIGEST)  ← resultados de auditorias e QA (dev-qa escreve)
│       ├── data-engineer/ (+DIGEST) ← saídas de dados / schema
│       ├── ux/      (+DIGEST)  ← saídas de UX
│       ├── …        (+DIGEST)  ← demais áreas da squad
│       └── <arquivo>.md        ← nota de squad inteira pode ficar direto em agents/<squad>/
│                                  (ex.: agents/seo/numeros.md, agents/pm/portfolio.md)
└── _archive/                   ← arquivo morto (conteúdo frio compactado). NÃO é lido no
    │                              bootstrap nem pelos agentes — só sob pedido explícito.
    ├── README.md               ← explica a convenção (criado pelo discovery)
    ├── LEDGER.md               ← índice de arquivos gordos esfriados (criado pelo *compact)
    └── YYYY-QN/                ← criado sob demanda pelo *compact (stories-done/, resolved/, misc/)
```

> `_archive/` fica fora do working set: o `weigh-memory.sh` o exclui da contagem de peso e os agentes não o leem (convenção reforçada no Smart-Memory Protocol). Ver "Smart-Memory Compaction".

## `INDEX.md` template

```markdown
---
title: "Smart-Memory — {Nome do Projeto}"
type: index
agent: team-os (discovery)
created: {data}
updated: {data}
tags: [index, smart-memory]
---

# Smart-Memory — {Nome do Projeto}

## Projeto
- [[project/overview]] — Visão geral
- [[project/tech-stack]] — Stack tecnológico (detectado)
- [[project/conventions]] — Padrões de código

## Arquitetura
- [[project/architecture]] — Visão arquitetural

## Módulos
- [[project/modules]] — Mapa de módulos + God Nodes

## Stories
- [[stories/BACKLOG]] — Backlog master
- [[stories/active/]] — Stories em andamento

## DIGESTs por área — agents/<squad>/<área>/ (porta de entrada L0)
- [[agents/dev/research/DIGEST]] · [[agents/dev/qa/DIGEST]] · [[agents/dev/data-engineer/DIGEST]] · [[agents/dev/ux/DIGEST]] · …
  (uma linha por área — o discovery.sh gera conforme a squad instalada)
```

