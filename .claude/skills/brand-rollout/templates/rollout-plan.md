---
kind: reference
status: active
summary: "Rollout {marca}: interno {data} · transição {janela} · externo {data | aguardando confirmação} · {N} ativos, {M} aposentados · QA {pendente|PASS}"
title: "Rollout Plan — {marca}"
agent: brand-rollout
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [rollout, brand, launch]
related: ["[[handoff/brand]]", "[[asset-inventory]]", "[[channel-checklists]]", "[[ledger]]", "[[../architecture/migration-roadmap]]", "[[../tracking/baseline]]"]
---

# Rollout Plan — {marca}

## 1. Pré-condições
| Pré-condição | Status | Evidência |
|---|---|---|
| Guia de voz PASS | | agents/qa/results.md — {data} |
| Sistema visual PASS | | |
| Baseline travada | | agents/tracking/baseline.md — {data} |
| Ordem de migração (ORION) | | agents/architecture/migration-roadmap.md |
| Confirmação do usuário — data externa | | ledger — {data} |

## 2. Inventário de ativos
| Ativo | Onde | Controla | Destino (mantém/migra/aposenta) | O que muda | Data | Dono |
|---|---|---|---|---|---|---|

## 3. Fases
### Interno — {data}
- Kit entregue a: {…} · Sessão de alinhamento: {data, 30–60 min} · FAQ interno: {path}
### Transição — {janela 24–72h}
| Ordem | Canal | Itens | Squad | Data |
|---|---|---|---|---|
### Externo — {data | aguardando confirmação}
- Comunicado: {formato, canal, squad que produz a partir do manifesto PASS}
- Diretórios/marketplaces/imprensa: {…}

## 4. Desligamentos
| Ativo antigo | Data de desligamento | O que acontece com quem chega (redirect/aviso/arquivo) | Dono |
|---|---|---|---|

## 5. Pós-virada
- +7d varredura de sobras: {data} · +30d auditoria de consistência (RIGEL): {data} · +60–90d leitura do depois (VEGA): {data}

## QA
Veredicto do plano + kit: {pendente | PASS | CONCERNS | FAIL} — {data}
