---
kind: report
status: active
summary: "Relatório {AAAA-MM} v{N} — resultado #F{AAAA-MM}-10 R$ ____ · reserva {x} m vs mínimo {n} · {k} alertas · {d} decisões pedidas · QA {pendente | PASS} · envio {pendente | confirmado {data} | enviado {data}}"
title: "Relatório Mensal — {AAAA-MM} — v{N}"
agent: finance-reporter
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, reporting, relatorio, "{AAAA-MM}"]
related: ["[[../controller/{AAAA-MM}-fechamento]]", "[[../planning/cash-plan-13w]]", "[[../planning/forecast-cenarios]]", "[[../billing/aging]]", "[[../tax/{AAAA-MM}-apuracao]]", "[[indicadores]]", "[[../../project/finance-policy]]", "[[../strategy/decisions]]", "[[../qa/{AAAA-MM}-relatorio-qa]]"]
---

# Relatório Mensal — {AAAA-MM} — v{N}

## 0. Cabeçalho
| Item | Valor |
|---|---|
| Fechamento | `#F{AAAA-MM}` — FECHADO em {data} (GANGES) |
| QA | {pendente | PASS} — {data} (TIGRE) — `agents/qa/…` |
| Destinatários | {sócios / investidor / banco — por alias} |
| Confirmação do usuário para esta versão | {pendente | "{texto literal}" — {data}} |
| Enviado pelo usuário em | {data} |
| Correções em relação à v{N−1} | {não se aplica | lista} |

## 1. Resumo (5 linhas, cada uma com `#id`)
- Resultado do mês: R$ ____ (`#F…-10`), margem operacional __% (`#F…-08`)
- Caixa conciliado: R$ ____ (`#F…-19`)
- Reserva: {x} meses (`#F…-19` ÷ `#F…-20`) vs mínimo {n} meses (`finance-policy.md §__`) · runway: {y} meses / não aplicável (caixa positivo)
- Maior alerta: {…} — S__ ({data}) — R$ ____ (`#id`)
- Decisão pedida: {…} — prazo {data} — decide: usuário

## 2. Alertas
| Alerta | Valor (`#id`) | Limite (política §) | Data | Opção em análise (custo) | Quem decide |
|---|---|---|---|---|---|

## 3. Receita
| Linha | Valor (`#id`) | Mês anterior (`#id`) | Variação |
|---|---|---|---|
| Receita bruta | R$ ____ (`#F…-01`) | | |
| Deduções | R$ ____ (`#F…-02`) | | |
| Receita líquida | R$ ____ (`#F…-03`) | | |
| Recorrente / pontual | R$ ____ (`#F…-11`) / R$ ____ (`#F…-12`) | | |
| Maior cliente ({alias}) | R$ ____ (`#F…-13`) = __% da bruta | | |

## 4. Custos e despesas
| Linha | Valor (`#id`) | Mês anterior | Variação | Causa (3 maiores variações) |
|---|---|---|---|---|
| Custo direto | R$ ____ (`#F…-04`) | | | |
| Despesa fixa | R$ ____ (`#F…-06`) | | | |
| Despesa variável | R$ ____ (`#F…-07`) | | | |

## 5. Margem e resultado
| Indicador | Valor (`#id`) | % | Meta (política §) | Mês anterior |
|---|---|---|---|---|
| Margem de contribuição | R$ ____ (`#F…-05`) | __% | | |
| Resultado operacional | R$ ____ (`#F…-08`) | __% | | |
| Resultado financeiro | R$ ____ (`#F…-09`) | — | | |
| Resultado do mês | R$ ____ (`#F…-10`) | __% | | |

## 6. Caixa e runway
| Item | Valor (`#id`) | Referência |
|---|---|---|
| Saldo — conta operacional | R$ ____ (`#F…-17`) | |
| Saldo — conta reserva | R$ ____ (`#F…-18`) | |
| Custo fixo mensal (média 3 m) | R$ ____ (`#F…-20`) | |
| Reserva | {x} meses | mínimo {n} (`finance-policy.md §__`) |
| Burn líquido | R$ ____ / não aplicável | forecast-cenarios.md |
| Runway (base / conservador) | {y} / {z} meses | forecast-cenarios.md |
| Gap previsto | {nenhum | S__ ({data}) R$ ____} | cash-plan-13w.md §3 |

## 7. Inadimplência
| Faixa | Valor (`#id`) | % |
|---|---|---|
| A vencer / 1–30 / 31–60 / 61–90 / > 90 | | |
| Inadimplência (vencido > 30d ÷ receita 12 m) | __% | limite __% (`finance-policy.md §__`) |
| Concentração em aberto | __% ({alias}) | |
| Negociações em curso | {n} — aging.md §4 | |

## 8. Realizado vs plano
| Linha | Planejado (DANUBIO) | Realizado (`#id`) | Desvio | Causa |
|---|---|---|---|---|
| Receita | R$ ____ | R$ ____ | __% | |
| Despesas | R$ ____ | R$ ____ | __% | |
| Caixa final | R$ ____ | R$ ____ | __% | |

## 9. Obrigações fiscais do mês
| Tributo/obrigação | Valor preparado | Status (preparado / validado pelo contador / recolhido) | Prazo | Atraso (custo) |
|---|---|---|---|---|

## 10. Decisões pedidas (AMAZONAS)
| Decisão | Opção A (custo) | Opção B (custo) | Prazo | Quem decide | Ref. `decisions.md` |
|---|---|---|---|---|---|

## 11. Anexos
- `agents/controller/{AAAA-MM}-fechamento.md` · `agents/planning/cash-plan-13w.md` · `agents/planning/forecast-cenarios.md` · `agents/billing/aging.md` · `agents/tax/{AAAA-MM}-apuracao.md` · `agents/reporting/indicadores.md`

## Auto-check (antes do PASS)
- [ ] `grep -inE "aprox|cerca de|em torno|quase|provavelmente|confort|delicad"` → zero ocorrências
- [ ] todo número com `(#id)` · [ ] fechamento FECHADO · [ ] nenhum dado sensível (alias)
