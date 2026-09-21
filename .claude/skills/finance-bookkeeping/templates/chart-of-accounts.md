---
kind: reference
status: active
summary: "Plano de contas gerencial v{N} — {n} contas em 8 grupos · vigente desde {AAAA-MM} · última conta criada {data}"
title: "Plano de Contas Gerencial — {empresa}"
agent: finance-controller
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, bookkeeping, chart-of-accounts]
related: ["[[finance-context]]", "[[../agents/controller/{AAAA-MM}-fechamento]]", "[[../agents/research/pendencias]]"]
---

# Plano de Contas Gerencial — {empresa} (v{N})

> Conta nova só com regra escrita (uma frase com condição), exemplo e contra-exemplo. Mudança vale a partir do mês seguinte; mês FECHADO não se reclassifica. Contas bancárias por alias.

## 1. Contas bancárias (alias)
| Alias | Uso | Titular (alias) | Conciliada mensalmente |
|---|---|---|---|
| conta operacional | recebimentos e pagamentos | {entidade alias} | ✅ |
| conta reserva | reserva da política | | ✅ |

## 2. Grupo 1 — Receita
| Código | Conta | Regra | Exemplo | Contra-exemplo |
|---|---|---|---|---|
| 1.1 | Receita recorrente | contrato com renovação | mensalidade de {serviço} | projeto único (→ 1.2) |
| 1.2 | Receita pontual | entrega única com contrato/NF | | |
| 1.9 | Outras receitas | receita operacional fora de 1.1/1.2, com documento | | aporte (→ 7.1) |

## 3. Grupo 2 — Deduções
| Código | Conta | Regra | Exemplo | Contra-exemplo |
|---|---|---|---|---|
| 2.1 | Tributos sobre receita | pela apuração de RENO (`#id`) | | tributo sobre folha (→ 4.1) |
| 2.2 | Devoluções/cancelamentos | NF cancelada ou devolução documentada | | |
| 2.3 | Descontos concedidos | só com decisão registrada (`decisions.md`) | | |

## 4. Grupo 3 — Custo direto
| Código | Conta | Regra | Exemplo | Contra-exemplo |
|---|---|---|---|---|
| 3.1 | Fornecedores de entrega | contratado para um projeto/cliente específico | | contador (→ 4.5) |
| 3.2 | Ferramentas por projeto | licença que existe só por um cliente | | assinatura geral (→ 4.4) |
| 3.3 | Comissões | % sobre receita conforme política | | |

## 5. Grupo 4 — Despesa fixa
| Código | Conta | Regra | Exemplo | Contra-exemplo |
|---|---|---|---|---|
| 4.1 | Folha e encargos | folha do mês (referência, sem dados pessoais) | | pró-labore (→ 4.2) |
| 4.2 | Pró-labore | remuneração de sócios conforme política | | distribuição (→ 7.3) |
| 4.3 | Aluguel e infraestrutura | | | |
| 4.4 | Assinaturas e ferramentas gerais | | | |
| 4.5 | Serviços fixos (contador, jurídico) | | | |

## 6. Grupo 5 — Despesa variável
| Código | Conta | Regra | Exemplo | Contra-exemplo |
|---|---|---|---|---|
| 5.1 | Marketing e mídia | | | |
| 5.2 | Viagens e representação | | | |
| 5.3 | Tarifas bancárias | documento = extrato | | juros (→ 6.1) |
| 5.9 | Serviços eventuais | | | |

## 7. Grupo 6 — Resultado financeiro
| Código | Conta | Regra | Exemplo | Contra-exemplo |
|---|---|---|---|---|
| 6.1 | Juros e multas pagos | documento = extrato/boleto | | parcela principal (→ 7.2) |
| 6.2 | Juros e rendimentos recebidos | | | |
| 6.3 | Variação cambial | índice com fonte (NILO) | | |

## 8. Grupo 7 — Não operacional (só fluxo de caixa)
| Código | Conta | Regra | Exemplo | Contra-exemplo |
|---|---|---|---|---|
| 7.1 | Aporte de sócio/investidor | decisão registrada | | |
| 7.2 | Empréstimo — principal | contrato | | juros (→ 6.1) |
| 7.3 | Distribuição de lucro | fechamento FECHADO + política + contador | | pró-labore (→ 4.2) |
| 7.4 | Investimento em ativo | | | |

## 9. Grupo 9 — Transitória (zera antes do FECHADO)
| Código | Conta | Regra |
|---|---|---|
| 9.1 | A classificar `[DOC PENDENTE]` | sem documento ou sem regra aplicável; pergunta em `pendencias.md` |
| 9.2 | Transferência entre contas próprias | dois lançamentos que se anulam no mesmo dia |

## 10. Histórico de versões
| Versão | Data | Mudança | Vale a partir de | Autor |
|---|---|---|---|---|
| v1 | {data} | criação | {AAAA-MM} | GANGES |
