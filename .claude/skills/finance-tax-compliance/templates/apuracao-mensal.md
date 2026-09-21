---
kind: report
status: active
summary: "Apuração {AAAA-MM} — {n} tributos · base #F{AAAA-MM} {FECHADO | ABERTO → rascunho} · {k} preparados · {v} validados pelo contador · {r} recolhidos · {p} [CONFIRMAR COM CONTADOR]"
title: "Apuração Fiscal — {AAAA-MM}"
agent: finance-tax
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, tax, apuracao, "{AAAA-MM}"]
related: ["[[../controller/{AAAA-MM}-fechamento]]", "[[calendario-fiscal]]", "[[regras]]", "[[para-o-contador-{AAAA-MM}]]", "[[../billing/payables]]", "[[../qa/{AAAA-MM}-apuracao-qa]]"]
---

# Apuração Fiscal — {AAAA-MM}

> Base = `#id` de fechamento FECHADO. Toda alíquota, faixa e prazo com fonte datada. Nada segue para guia sem `validado pelo contador`. A squad não recolhe nem transmite.

## 0. Base
| Item | Valor |
|---|---|
| Fechamento de referência | `#F{AAAA-MM}` — {FECHADO em {data} / ABERTO → apuração em rascunho} |
| Regime/enquadramento (finance-context.md) | {…} — confirmado pelo contador em {data} |

## 1. Apuração por tributo
### T1 — {tributo}
| Campo | Valor | Fonte / referência |
|---|---|---|
| Base de cálculo | R$ ____ | `#F{AAAA-MM}-__` (+ `#F…` se composta) |
| Regra (alíquota/faixa) | {…} | {norma, artigo} · {órgão} · consultado em {data} |
| Deduções/retenções previstas | R$ ____ | por nota (§2) — {norma} |
| Compensações/créditos | R$ ____ | decisão do contador em {data} |
| Valor preparado | R$ ____ | fórmula acima; arredondamento: {regra do órgão, fonte} |
| Variação vs mês anterior | __% | explicação: base (`#id`) / regra (fonte) |
| Prazo | {data} | {regra de prazo, fonte}; dia não útil: {regra do órgão} |
| Status | rascunho / preparado / validado pelo contador ({alias}, {data}, {meio}) / recolhido ({data}, comprovante {arquivo}) | |
| Pendências | `[CONFIRMAR COM CONTADOR]` #__ | |

### T2 — {tributo}
(mesma estrutura)

## 2. Conferência documental
| Nota (nº/arquivo) | Emitida/recebida | Parte (alias) | Valor | `#id` | Natureza | Retenções | Competência | Par (cancelada/substituta) | Resultado |
|---|---|---|---|---|---|---|---|---|---|
| | | | R$ ____ | | ✅/⚠ | ✅/⚠ | ✅/⚠ | ✅/⚠/— | OK / ⚠ {tipo} → pergunta #__ |

## 3. Remuneração de sócios (se aplicável no mês)
| Via | Requisito (regra + fonte) | Encargos/tributos (regra + fonte) | Custo total empresa | Líquido sócio | Restrição | Decisão (usuário + contador, data) |
|---|---|---|---|---|---|---|
| Pró-labore | | | R$ ____ | R$ ____ | | |
| Distribuição | | | R$ ____ | R$ ____ | resultado `#F…-10` FECHADO; contrato social | |

## 4. Perguntas ao contador `[CONFIRMAR COM CONTADOR]`
| # | Pergunta | Tributo/nota | Aberta em | Resposta | Respondida em |
|---|---|---|---|---|---|

## 5. Retorno do contador (item a item)
| Item | Resultado (confirmado / corrigido / pendente) | Valor novo | Motivo | Data |
|---|---|---|---|---|

## 6. Checklist mensal
| # | Item | ✅/⚠ |
|---|---|---|
| 1 | Regime lido em finance-context.md (confirmação ≤ 12 m) | |
| 2 | Calendário atualizado | |
| 3 | Bases com `#id` FECHADO | |
| 4 | Toda alíquota/prazo com fonte | |
| 5 | Notas conferidas | |
| 6 | Pacote enviado ao contador (usuário, data) | |
| 7 | Retorno registrado | |
| 8 | `validado pelo contador` antes de guia | |
| 9 | Recolhimento registrado (usuário) | |
| 10 | PASS de TIGRE | {pendente | PASS | CONCERNS | FAIL} — {data} |
