---
kind: reference
status: rascunho
summary: "Cláusula M{N}.{c} — {título}: padrão + {k} variantes (piso {…} / teto {…}), {p} proibidas, inegociável {sim/não}, status {rascunho/aprovada}"
title: "M{N}.{c} — {título}"
agent: legal-drafter
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [legal, clause, M{N}, {relação}]
related: ["[[../architecture/model-system]]", "[[../../project/legal-posture]]", "[[../research/{tema}-research]]", "[[../strategy/validations]]"]
---

# M{N}.{c} — {título}

> Placeholders nomeados (`{PARTE A}`, `{VALOR}`, `{PRAZO}`); zero dado real. Piso e teto verificáveis — nunca "razoável". Só `aprovada` entra em minuta. Isto não é parecer; o advogado inscrito da empresa valida o modelo.

## Ficha
| Campo | Valor |
|---|---|
| Modelo / relação | M{N} — {relação} |
| Bloco da anatomia | {1–15} — {nome} |
| Postura § | §{…} — {o que implementa} |
| Inegociável? | {sim / não} |
| Base legal exigida? | {sim: citação completa · consultado em {data} · vigência / não} |
| Registrável por FIDES | {prazo / obrigação / renovação — o quê e gatilho} |
| Status | {rascunho / aprovada / deprecated → substituída por …} |

## Padrão — M{N}.{c}.p
```
{texto completo da cláusula, linguagem clara, placeholders nomeados}
```

## Variantes negociáveis
| Id | Texto (diferença em relação ao padrão) | Piso | Teto | Quando usar | Quem aprova |
|---|---|---|---|---|---|
| M{N}.{c}.v1 | | | | | CONCORDIA (dentro do piso/teto) |
| M{N}.{c}.v2 | | | | | PRUDENTIA |

## Proibidas — M{N}.{c}.x
| O que nunca se assina | Motivo (postura §) |
|---|---|

## Histórico
| Versão | Data | Mudança | Gatilho | Aprovado por (validations.md) | Minutas que usaram |
|---|---|---|---|---|---|
| v1 | | criação | | | |
