---
kind: reference
status: active
summary: "Calendário fiscal — {n} obrigações · regime {declarado em finance-context.md} · próximas 30 dias: {k} · atrasadas: {m} · última confirmação do contador {data}"
title: "Calendário de Obrigações Fiscais — {empresa}"
agent: finance-tax
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, tax, calendario, compliance]
related: ["[[../../project/finance-context]]", "[[regras]]", "[[{AAAA-MM}-apuracao]]", "[[../billing/payables]]", "[[../planning/cash-plan-13w]]"]
---

# Calendário de Obrigações Fiscais — {empresa}

> Toda obrigação com órgão, regra de prazo **com fonte** e três responsáveis (prepara / valida / executa). RENO prepara; o contador valida; o usuário ou o contador executa. Sem fonte → `[CONFIRMAR COM CONTADOR]`.

## 0. Contexto (de `finance-context.md`, confirmado pelo contador)
| Item | Valor | Confirmado em | Por (alias) |
|---|---|---|---|
| Jurisdição | | | |
| Regime tributário declarado | | | contador |
| Atividade / enquadramento | | | |
| Contador | {alias} | | |
| Referência de país | `reference/brasil.md` (se aplicável) | | |

## 1. Obrigações recorrentes
| # | Obrigação | Tipo | Órgão | Periodicidade | Regra de prazo + fonte (norma, artigo, consultado em) | Base (`#id` ou documento) | Prepara / Valida / Executa | Próxima data | Status |
|---|---|---|---|---|---|---|---|---|---|
| T1 | | tributo | | mensal | {regra} — fonte: {…} · {data} | #F… | RENO / contador / usuário | | a preparar |
| D1 | | declaração | | | | | RENO / contador / contador | | |

## 2. Obrigações anuais e eventuais
| # | Obrigação | Órgão | Regra de prazo + fonte | Base | Prepara / Valida / Executa | Próxima data | Status |
|---|---|---|---|---|---|---|---|

## 3. Alertas do mês
| Obrigação | D-10 base disponível? | D-5 validado pelo contador? | D-1 executado? | Ação |
|---|---|---|---|---|

## 4. Atrasos
| Obrigação | Vencimento | Motivo | Custo (multa/juros — regra + fonte) | Decisão (quem, data) | Regularizado em |
|---|---|---|---|---|---|

## 5. Perguntas abertas `[CONFIRMAR COM CONTADOR]`
| # | Pergunta | Obrigação | Aberta em | Respondida em | Resposta (resumo) |
|---|---|---|---|---|---|

## 6. Histórico (obrigações extintas ou alteradas)
| Obrigação | Mudança | Norma (fonte, data) | Vale a partir de |
|---|---|---|---|
