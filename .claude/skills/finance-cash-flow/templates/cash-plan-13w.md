---
kind: plan
status: active
summary: "Plano de caixa 13w — S1 {data}: saldo inicial #F{AAAA-MM}-__ · gap {nenhum | S{n} R$ ____} · reserva {x} meses vs mínimo {y} · gate {pendente | APROVADO | AJUSTES}"
title: "Plano de Caixa 13 Semanas — {empresa}"
agent: finance-planner
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, cash-flow, plan, rolling]
related: ["[[../controller/{AAAA-MM}-fechamento]]", "[[../billing/receivables]]", "[[../billing/payables]]", "[[../tax/calendario-fiscal]]", "[[../../project/finance-policy]]", "[[forecast-cenarios]]", "[[../strategy/decisions]]"]
---

# Plano de Caixa 13 Semanas — {empresa}

> Saldo inicial = `#id` do fechamento FECHADO. Toda premissa com data e origem. Gap com semana e tamanho. Atualizado toda segunda-feira. Cenário: **base** (conservador e estresse em `forecast-cenarios.md`).

## 0. Base do plano
| Item | Valor | Origem |
|---|---|---|
| Fechamento de referência | `#F{AAAA-MM}` — FECHADO em {data} | `agents/controller/{AAAA-MM}-fechamento.md` |
| Saldo inicial (S1) | R$ ____ | `#F{AAAA-MM}-__` |
| Custo fixo mensal (média 3 fechamentos) | R$ ____ | `#F…`, `#F…`, `#F…` |
| Reserva mínima da política | {n} meses = R$ ____ | `finance-policy.md §__` |
| Última atualização rolling | {data} | — |

## 1. Plano semanal
| Bloco / Linha | Origem | S1 {dd/mm} | S2 | S3 | S4 | S5 | S6 | S7 | S8 | S9 | S10 | S11 | S12 | S13 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Saldo inicial** | `#id` / S−1 | | | | | | | | | | | | | |
| Entradas — {cliente alias} | receivables `#id` | | | | | | | | | | | | | |
| Entradas — recorrência contratada | contratos | | | | | | | | | | | | | |
| Entradas — pontuais assinadas | contrato | | | | | | | | | | | | | |
| Entradas — aporte/empréstimo | decisions.md {data} | | | | | | | | | | | | | |
| **Σ Entradas** | | | | | | | | | | | | | | |
| Fixas — folha e encargos | payables `#id` | | | | | | | | | | | | | |
| Fixas — pró-labore | política | | | | | | | | | | | | | |
| Fixas — aluguel/infra | payables | | | | | | | | | | | | | |
| Fixas — dívidas (parcela) | contrato | | | | | | | | | | | | | |
| Fixas — tributos | calendario-fiscal | | | | | | | | | | | | | |
| Fixas — assinaturas | payables | | | | | | | | | | | | | |
| Variáveis — fornecedores | payables | | | | | | | | | | | | | |
| Variáveis — comissões | política | | | | | | | | | | | | | |
| Variáveis — tributos s/ receita | apuracao | | | | | | | | | | | | | |
| **Σ Saídas** | | | | | | | | | | | | | | |
| **Saldo final** | fórmula | | | | | | | | | | | | | |
| Mínimo da política | R$ ____ | | | | | | | | | | | | | |
| **Folga / GAP** | fórmula | | | | | | | | | | | | | |

## 2. Premissas
| # | Premissa | Valor | Origem | Registrada em | Informada por | Válida até | Cenário |
|---|---|---|---|---|---|---|---|
| P1 | | | | | | | base |

## 3. Gaps
| Semana | Data | Tamanho | Causa | Opção A (custo, prazo) | Opção B (custo, prazo) | Decisão (quem, quando, ref.) |
|---|---|---|---|---|---|---|
| S__ | | R$ ____ | | | | PENDENTE: usuário |

## 4. Realizado vs projetado (semana descartada)
| Semana | Bloco | Projetado | Realizado (`#id`) | Desvio | Causa |
|---|---|---|---|---|---|

## 5. Gate (AMAZONAS)
| # | Ponto | ✅/⚠ | Evidência |
|---|---|---|---|
| 1 | Rastreável ao fechamento FECHADO | | `#F…` |
| 2 | Política respeitada (reserva, alçadas) | | |
| 3 | Base + conservador com premissas escritas | | forecast-cenarios.md |
| 4 | Receitas com origem | | |
| 5 | Fixas completas com data | | |
| 6 | Gap coberto ou decisão do usuário | | decisions.md |
| 7 | Critério de aceite verificável por TIGRE | | |
Veredicto: {pendente | APROVADO | AJUSTES | REPROVADO} — {data} — `agents/strategy/validations.md`
