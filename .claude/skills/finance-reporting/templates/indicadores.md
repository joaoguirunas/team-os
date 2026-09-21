---
kind: reference
status: active
summary: "Dicionário de indicadores v{N} — {n} indicadores ativos · {m} descontinuados · metas de finance-policy.md v{…} · última alteração {data}"
title: "Dicionário de Indicadores — {empresa}"
agent: finance-reporter
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, reporting, indicadores, kpi]
related: ["[[../../project/finance-policy]]", "[[../controller/{AAAA-MM}-fechamento]]", "[[{AAAA-MM}-relatorio]]", "[[../planning/forecast-cenarios]]", "[[../billing/aging]]"]
---

# Dicionário de Indicadores — {empresa} (v{N})

> Cada indicador com definição operacional, fórmula, componentes por `#id`, arredondamento declarado, cadência, meta citada da política e dono do cálculo (GANGES). SENA copia; nunca recalcula. Fórmula alterada = nova linha; a anterior fica `descontinuada em {data}`.

## 1. Indicadores ativos
| Indicador | Definição operacional | Fórmula | Componentes (`#id`) | Casas / arredondamento | Cadência | Meta (política §) | Dono do cálculo | Limitação |
|---|---|---|---|---|---|---|---|---|
| Margem de contribuição % | quanto sobra da receita líquida após custo direto | (receita_liquida − custo_direto) ÷ receita_liquida | `#F…-03`, `#F…-04` | 1 casa, truncado | mensal | __% (§__) | GANGES | competência; não é caixa |
| Margem operacional % | resultado operacional sobre receita líquida | resultado_operacional ÷ receita_liquida | `#F…-08`, `#F…-03` | 1 casa, truncado | mensal | __% (§__) | GANGES | exclui 6.x e 7.x |
| Receita recorrente % | peso da recorrência na receita bruta | receita_recorrente ÷ receita_bruta | `#F…-11`, `#F…-01` | 1 casa | mensal | meta: não definida (AMAZONAS) | GANGES | depende da classificação 1.1/1.2 |
| Concentração de cliente | dependência do maior cliente | maior receita por cliente ÷ receita_bruta | `#F…-13`, `#F…-01` | 1 casa | mensal | ≤ __% (§__) | GANGES | alias; mês único |
| Custo fixo mensal | base da reserva | média(despesa fixa, 3 fechamentos FECHADOS) | `#F…-06` × 3 | R$ sem centavos | mensal | — | GANGES | 3 meses; muda com folha |
| Reserva (meses) | quantos meses de custo fixo o caixa cobre | saldo_conciliado ÷ custo_fixo_mensal | `#F…-19`, `#F…-20` | 1 casa, truncado | mensal | ≥ {n} meses (§__) | GANGES | não considera recebíveis |
| Burn líquido | caixa consumido por mês | média 3 m (saídas − entradas) | `#F…-14`, `#F…-15` | R$ sem centavos; ≤ 0 → "não aplicável (caixa positivo)" | mensal | — | GANGES | inclui 7.x se houver |
| Runway (meses) | meses até o caixa zerar no ritmo atual | saldo_conciliado ÷ burn_liquido | `#F…-19`, burn | 1 casa, truncado | mensal | ≥ {n} (§__) | GANGES | só com burn > 0 |
| Inadimplência % | recebíveis vencidos > 30 dias sobre faturamento 12 m | vencido_30d ÷ receita_faturada_12m | aging.md §1 | 1 casa | mensal | ≤ __% (§__) | GANGES (base TEJO) | 12 meses móveis |
| Desvio vs plano % | distância entre realizado e planejado | (realizado − planejado) ÷ planejado | `#F…`, cash-plan | 1 casa | mensal | ± __% (§__) | GANGES | plano de DANUBIO da data |

## 2. Indicadores por destinatário
| Indicador | Sócios | Investidor | Banco | Observação |
|---|---|---|---|---|
| Crescimento vs mesmo mês do ano anterior | — | ✅ | — | dois fechamentos FECHADOS |
| Runway conservador | — | ✅ | ✅ | forecast-cenarios.md |
| Cobertura da dívida | — | — | ✅ | resultado_operacional ÷ serviço da dívida (`#id`) |

## 3. Descontinuados
| Indicador | Fórmula antiga | Descontinuado em | Motivo | Substituído por |
|---|---|---|---|---|

## 4. Histórico de versões
| Versão | Data | Mudança | Autor | Meta alterada por (AMAZONAS, `decisions.md`) |
|---|---|---|---|---|
| v1 | {data} | criação | SENA (fórmulas GANGES) | — |
