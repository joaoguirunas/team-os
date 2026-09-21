---
kind: plan
status: active
summary: "Forecast {período} — base/conservador/estresse · runway base {x} m · conservador {y} m · reserva {z} m vs mínimo {n} · gap conservador {nenhum | S{n} R$ ____}"
title: "Forecast e Cenários — {empresa} — {período}"
agent: finance-planner
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, forecast, scenarios, runway]
related: ["[[cash-plan-13w]]", "[[../controller/{AAAA-MM}-fechamento]]", "[[../../project/finance-policy]]", "[[../strategy/decisions]]", "[[../research/benchmarks]]"]
---

# Forecast e Cenários — {empresa} — {período}

> Base do fechamento `#F{AAAA-MM}` FECHADO em {data}. Conservador é obrigatório. Estresse obrigatório se há dívida ou cliente > 30% da receita. Toda premissa em §4 com data e origem.

## 1. Reserva, burn e runway (realizado)
| Indicador | Fórmula | Valor | Componentes (`#id`) |
|---|---|---|---|
| Saldo conciliado | — | R$ ____ | `#F…` |
| Custo fixo mensal | média 3 fechamentos FECHADOS | R$ ____ | `#F…`, `#F…`, `#F…` |
| Reserva atual | saldo ÷ custo fixo | {x} meses | |
| Mínimo da política | `finance-policy.md §__` | {n} meses = R$ ____ | |
| Burn líquido mensal | média 3 m (saídas − entradas) | R$ ____ / não aplicável | |
| Runway | saldo ÷ burn | {x} meses / não aplicável (caixa positivo) | |

## 2. Cenários lado a lado
| Linha | Base | Conservador | Estresse | Regra aplicada |
|---|---|---|---|---|
| Entradas contratadas | R$ ____ | R$ ____ | R$ ____ | conservador × taxa_recebimento_prazo {__%} (TEJO, 6 m) |
| Entradas pontuais | R$ ____ | R$ ____ | R$ ____ | só assinadas |
| Perda do maior cliente ({alias}) | — | — | a partir de S__ | estresse |
| Saídas fixas | R$ ____ | R$ ____ | R$ ____ | integrais |
| Saídas variáveis | R$ ____ | R$ ____ | R$ ____ | média 3 m / pior mês 6 m / pior mês 6 m |
| Saldo final do período | R$ ____ | R$ ____ | R$ ____ | |
| Menor saldo semanal (semana) | R$ ____ (S__) | R$ ____ (S__) | R$ ____ (S__) | |
| Gap (semana, tamanho) | {nenhum / S__ R$ ____} | | | |
| Runway no cenário | {x} m | {y} m | {z} m | |

## 3. O que aciona e o que cobre
| Cenário | Aciona o gap | Cobertura | Custo da cobertura | Prazo | Decisão (quem, ref.) |
|---|---|---|---|---|---|
| Conservador | | | | | PENDENTE: usuário |
| Estresse | | | | | |

## 4. Premissas
| # | Premissa | Base | Conservador | Estresse | Origem | Registrada em | Informada por | Válida até |
|---|---|---|---|---|---|---|---|---|
| P1 | taxa de recebimento no prazo | 100% | __% | — | receivables.md (6 m) | | TEJO | |
| P2 | índice ({câmbio/CDI/IPCA}) | | | | benchmarks.md — {fonte, data} | | NILO | |

## 5. Alertas gerados
| Alerta | Valor | Limite (política §) | Destinatário | Data |
|---|---|---|---|---|
| Reserva abaixo do mínimo | | | AMAZONAS, SENA | |
| Gap no conservador | | | AMAZONAS, usuário | |

## 6. Gate
Veredicto de AMAZONAS: {pendente | APROVADO | AJUSTES | REPROVADO} — {data} · QA (TIGRE, pontos 8 e 9): {pendente | PASS | CONCERNS | FAIL} — {data}
