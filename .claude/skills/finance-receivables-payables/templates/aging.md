---
kind: report
status: active
summary: "Aging {AAAA-MM-DD} — em aberto R$ ____ · vencido > 30d R$ ____ · inadimplência __% vs limite __% (política §) · concentração __% ({cliente alias}) · {n} negociações abertas"
title: "Aging de Recebíveis — {AAAA-MM-DD}"
agent: finance-billing
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, billing, receivables, aging, inadimplencia]
related: ["[[receivables]]", "[[regua-cobranca]]", "[[../controller/{AAAA-MM}-fechamento]]", "[[../../project/finance-policy]]", "[[../strategy/decisions]]", "[[../reporting/{AAAA-MM}-relatorio]]"]
---

# Aging de Recebíveis — {AAAA-MM-DD}

> Todo valor = `#id` do fechamento ou do ledger. Faixas fixas. Inadimplência medida contra o limite da política. `perdido` só com decisão escrita.

## 1. Resumo
| Indicador | Fórmula | Valor | Componentes (`#id`) |
|---|---|---|---|
| Em aberto total | Σ a vencer + vencido | R$ ____ | |
| Vencido > 30 dias | Σ faixas 31–60, 61–90, > 90 | R$ ____ | |
| Receita faturada 12 meses | Σ #F…-01 dos 12 fechamentos | R$ ____ | |
| Inadimplência | vencido > 30d ÷ receita 12 m | __% | limite: __% (`finance-policy.md §__`) |
| Concentração | maior saldo por cliente ÷ em aberto | __% ({cliente alias}) | |
| Taxa de recebimento no prazo (6 m) | recebido até D0 ÷ faturado | __% | → DANUBIO (cenário conservador) |

## 2. Aging por faixa
| Faixa | Nº de títulos | Valor | % do em aberto |
|---|---|---|---|
| A vencer | | R$ ____ | |
| 1–30 dias | | R$ ____ | |
| 31–60 dias | | R$ ____ | |
| 61–90 dias | | R$ ____ | |
| > 90 dias | | R$ ____ | |
| **Total** | | **R$ ____** | 100% |

## 3. Aging por cliente
| Cliente (alias) | A vencer | 1–30 | 31–60 | 61–90 | > 90 | Total | Passo da régua | Status |
|---|---|---|---|---|---|---|---|---|

## 4. Negociações em curso
| Data | Cliente (alias) | `#id` | Proposta do cliente | Contraproposta | Aprovado por (AMAZONAS/usuário, data) | Resultado | Novo vencimento |
|---|---|---|---|---|---|---|---|

## 5. Perdas (decisão registrada)
| Cliente (alias) | `#id` | Valor | Decisão (quem, data, `decisions.md`) | Lançamento (GANGES, `#lanc`) |
|---|---|---|---|---|

## 6. Alertas gerados
| Alerta | Valor | Limite (política §) | Destinatário | Data |
|---|---|---|---|---|
| Inadimplência acima do limite | __% | __% | AMAZONAS, SENA | |
| Concentração acima do limite | __% | __% | AMAZONAS | |
| Título > 90 dias sem negociação | R$ ____ | — | AMAZONAS (decisão D+30) | |
