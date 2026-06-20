---
title: "Story {N}.{M}: {Título}"
type: story
status: backlog
epic: {N}
complexity: S | M | L | XL
agent: {quem-assumiu — preenchido pelo implementer}
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [story, {domínio}]
related: ["[[../../decisions/ADR-{N}]]"]
---

# Story {N}.{M}: {Título}

> Template canônico de story do team-os. Criado e validado pelo **architect** (autoridade exclusiva).
> O implementer só atualiza **Dev Agent Record**, **checkboxes de AC** e **File List** — nunca título, AC, escopo ou QA Results.

## Contexto

{Por que esta story existe. Qual problema do usuário/negócio ela resolve. 2-4 linhas.}

## Acceptance Criteria

Critérios **testáveis e mensuráveis** (cada um vira teste):

- [ ] AC1 — {comportamento observável e verificável}
- [ ] AC2 — {…}
- [ ] AC3 — {…}

## Escopo

**IN (faz parte):**
- {item}

**OUT (explicitamente fora):**
- {item}

## Notas técnicas

{Stack, constraints, padrões a seguir, arquivos/módulos prováveis. Links: [[../../project/tech-stack]], [[../../project/conventions]].}

## Dependências

- Depende de: {Story {N}.{M} | nenhuma}
- Bloqueia: {Story {N}.{M} | nenhuma}

---

## Dev Agent Record

| Campo | Valor |
|---|---|
| Agente | {persona} ({nome}) |
| Iniciado | {YYYY-MM-DD} |
| Concluído | {YYYY-MM-DD} |
| Branch | feature/{N}-{M}-{slug} |

### File List
{Arquivos criados/alterados — preenchido ao concluir.}

---

## QA Results

> Preenchido **apenas** pelo reviewer (QA). Veredicto formal.

**Veredicto:** PASS | CONCERNS | FAIL | WAIVED
**Data:** {YYYY-MM-DD} · **Checklist:** {n}/8

{Findings com severidade e arquivo:linha quando houver.}
