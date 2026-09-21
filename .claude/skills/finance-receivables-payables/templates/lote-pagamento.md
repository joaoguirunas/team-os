---
kind: task
status: active
summary: "Lote {AAAA-MM-DD} — {n} itens · total R$ ____ · janela {dd/mm}–{dd/mm} · status {preparado | PASS | confirmado pelo usuário | executado | conciliado}"
title: "Lote de Pagamento — {AAAA-MM-DD}"
agent: finance-billing
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, billing, payables, lote]
related: ["[[../payables]]", "[[../../controller/{AAAA-MM}-fechamento]]", "[[../../planning/cash-plan-13w]]", "[[../../../project/finance-policy]]", "[[../../qa/{AAAA-MM-DD}-lote-qa]]"]
---

# Lote de Pagamento — {AAAA-MM-DD}

> A squad prepara; o humano executa. Nada deste lote é pago, transferido ou agendado sem PASS de TIGRE **e** confirmação explícita do usuário para **este** lote. Beneficiários por alias — dados bancários ficam no sistema do usuário.

## 1. Janela e folga
| Item | Valor | Origem |
|---|---|---|
| Janela de vencimento | {dd/mm} a {dd/mm} | payables.md |
| Total do lote | R$ ____ | Σ §2 |
| Folga da semana (S__) no plano de caixa | R$ ____ | cash-plan-13w.md (DANUBIO) |
| Folga após o lote | R$ ____ | fórmula |

## 2. Itens
| # | Fornecedor (alias) | `#id` documento | Tipo | Vencimento | Valor | Prioridade (política §) | Alçada (quem aprova) | Documento (arquivo) | Duplicidade checada |
|---|---|---|---|---|---|---|---|---|---|
| 1 | | | fixo / variável / tributo / dívida | | R$ ____ | | | | ✅ / ⚠ |
| | **Total** | | | | **R$ ____** | | | | |

## 3. Checagens (TEJO, antes de pedir PASS)
| Checagem | Critério | ✅/⚠ |
|---|---|---|
| Documento de origem em 100% dos itens | arquivo referenciado por item | |
| Valor = documento | item a item | |
| Vencimento dentro da janela | | |
| Duplicidade | mesmo fornecedor + valor + vencimento ±7d de item pago/em lote → ⚠ | |
| Total bate | Σ itens = total declarado | |
| Prioridade conforme política | `finance-policy.md §__` ou `[POLÍTICA PENDENTE]` | |
| Beneficiário por alias | nenhum dado bancário no arquivo | |
| Itens adiados | decisão do usuário registrada (`decisions.md`, data) | |

## 4. QA (TIGRE)
Veredicto: {pendente | PASS | CONCERNS | FAIL} — {data} — `agents/qa/…` · Itens com FAIL: {#, motivo, responsável}

## 5. Confirmação do usuário (para este lote)
| Data | Texto da confirmação (literal) | Itens confirmados | Itens excluídos (motivo) |
|---|---|---|---|
| | "…" | 1–{n} | |

## 6. Execução (pelo usuário)
| # | Executado em | Referência ao comprovante (nome de arquivo) | Observação |
|---|---|---|---|

## 7. Conciliação (GANGES)
| # | `#lanc` | Data no extrato | Diferença | Status |
|---|---|---|---|---|
