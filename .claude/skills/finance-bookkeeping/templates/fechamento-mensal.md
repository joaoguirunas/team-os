---
kind: report
status: active
summary: "Fechamento {AAAA-MM} — {ABERTO | FECHADO} · {n} contas conciliadas de {m} · {k} diferenças · {p} [DOC PENDENTE] · resultado do mês #F{AAAA-MM}-__ · QA {pendente | PASS}"
title: "Fechamento Mensal — {AAAA-MM}"
agent: finance-controller
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, fechamento, controller, "{AAAA-MM}"]
related: ["[[conciliacao-{AAAA-MM}]]", "[[../research/{AAAA-MM}-coleta]]", "[[../../project/chart-of-accounts]]", "[[../tax/para-o-contador-{AAAA-MM}]]", "[[../qa/{AAAA-MM}-fechamento-qa]]"]
---

# Fechamento Mensal — {AAAA-MM}

## Status: ABERTO | FECHADO
FECHADO em {data} · PASS de TIGRE em {data} (`agents/qa/…`). Enquanto ABERTO: nenhum `#id` abaixo pode ser citado em relatório, plano, cobrança ou apuração.

## 1. Números do mês
| # | Número | Valor | Origem (lançamentos / extrato) | Conciliação | Status |
|---|---|---|---|---|---|
| #F{AAAA-MM}-01 | Receita bruta (Σ 1.x) | R$ ____ | #lanc … | ✅ / ⚠ | |
| #F{AAAA-MM}-02 | Deduções (Σ 2.x) | R$ ____ | | | |
| #F{AAAA-MM}-03 | Receita líquida | R$ ____ | fórmula 01 − 02 | | |
| #F{AAAA-MM}-04 | Custo direto (Σ 3.x) | R$ ____ | | | |
| #F{AAAA-MM}-05 | Margem de contribuição (valor · %) | R$ ____ · __% | fórmula 03 − 04 | | |
| #F{AAAA-MM}-06 | Despesa fixa (Σ 4.x) | R$ ____ | | | |
| #F{AAAA-MM}-07 | Despesa variável (Σ 5.x) | R$ ____ | | | |
| #F{AAAA-MM}-08 | Resultado operacional (valor · %) | R$ ____ · __% | fórmula 05 − 06 − 07 | | |
| #F{AAAA-MM}-09 | Resultado financeiro (Σ 6.x) | R$ ____ | extrato | | |
| #F{AAAA-MM}-10 | Resultado do mês | R$ ____ | fórmula 08 + 09 | | |
| #F{AAAA-MM}-11 | Receita recorrente (1.1) | R$ ____ | | | |
| #F{AAAA-MM}-12 | Receita pontual (1.2) | R$ ____ | | | |
| #F{AAAA-MM}-13 | Maior cliente ({alias}) — receita | R$ ____ | | | |
| #F{AAAA-MM}-14 | Entradas de caixa (realizado) | R$ ____ | extrato | | |
| #F{AAAA-MM}-15 | Saídas de caixa (realizado) | R$ ____ | extrato | | |
| #F{AAAA-MM}-16 | Movimento 7.x (aporte/dívida/distribuição) | R$ ____ | extrato + decisão | | |
| #F{AAAA-MM}-17 | Saldo final — conta operacional | R$ ____ | extrato {data} | ✅ diferença 0 | |
| #F{AAAA-MM}-18 | Saldo final — conta reserva | R$ ____ | extrato {data} | | |
| #F{AAAA-MM}-19 | Saldo conciliado total | R$ ____ | Σ 17 + 18 | | |
| #F{AAAA-MM}-20 | Custo fixo mensal (média 3 FECHADOS) | R$ ____ | #F…-06 × 3 | | |

## 2. Conciliação por conta
| Conta (alias) | Saldo extrato | Saldo contábil | Diferença | Pares ✅ | Itens ⚠ | Status |
|---|---|---|---|---|---|---|
| conta operacional | R$ ____ | R$ ____ | R$ 0 | | | |

## 3. Diferenças de conciliação e estornos
| ⚠ / #lanc-E | Valor | Hipótese ou motivo | Documento esperado | Referência ao original | Resolvido em |
|---|---|---|---|---|---|
| ⚠ | R$ ____ | hipótese: {…} | | — | |
| #lanc-E… | | motivo: {conta errada / valor / duplicidade / contraparte / doc substituído} | | #lanc… | |

## 4. Pendências [DOC PENDENTE]
| #lanc | Valor | Conta 9.x | Contraparte (alias) | Pergunta pronta (NILO) | Desde |
|---|---|---|---|---|---|

## 5. Checklist de fechamento
| # | Item | ✅/⚠ | Evidência |
|---|---|---|---|
| 1 | Coleta recebida de NILO | | `{AAAA-MM}-coleta.md` |
| 2 | 100% dos lançamentos com documento ou em 9.x | | |
| 3 | Conciliação item a item por conta | | §2 |
| 4 | 9.x zerada ou listada em §4 | | |
| 5 | Estornos com motivo e referência | | §3 |
| 6 | DRE com `#id` por linha | | §1 |
| 7 | Fluxo realizado com `#id` | | §1 |
| 8 | Saldos finais por conta com `#id` | | §1 |
| 9 | Documentos fiscais separados para RENO | | `para-o-contador-{AAAA-MM}.md` |
| 10 | PASS de TIGRE | | `agents/qa/…` |

## 6. Planilhas
| Arquivo (convenção do projeto) | Conteúdo | Atualizado em |
|---|---|---|
| {caminho} | lançamentos do mês | |
| {caminho} | conciliação por conta | |
