---
kind: reference
status: living
summary: "Registro de contratos: {N} vigentes, {a} em aviso, {b} em disputa, próximo prazo {data} (#K{NN}), {c} alertas ativos"
title: "Contracts Registry — registro de contratos e obrigações"
agent: legal-compliance
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [legal, compliance, registry, contracts]
related: ["[[legal-context]]", "[[../agents/compliance/calendario-obrigacoes]]", "[[../agents/ops/signature-ledger]]", "[[../agents/ops/arquivo]]", "[[../agents/disputes/casos]]"]
---

# Contracts Registry — registro de contratos e obrigações

> Fonte única de prazos. Contrato vigente sem `#K` não existe para a squad. Renovação automática tem data-limite de denúncia registrada. Partes por alias; dados completos e arquivo no repositório da empresa. Alertas D-30 / D-15 / D-7. Isto não é parecer.

## Próximos prazos (90 dias)
| #K | Contraparte (alias) | O quê (renovação / aviso / obrigação) | Data | Dono | Alerta |
|---|---|---|---|---|---|

## Registro
| #K | Tipo | Relação (M{N}) | Contraparte (alias) | Objeto | Assinado em | Vigência | Renovação (auto? data-limite de denúncia) | Aviso prévio (dias, contados de) | Obrigações recorrentes (o quê, quando, dono) | Valor (alias #id financeiro) | Status | Próximo prazo | Dono | Arquivo (path, hash) | Versão assinada |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| #K01 | | M1 | | | | {início}–{fim} | | | | | vigente | | | | v{N} |

## Aditivos
| #K.a | Contrato-mãe | O que mudou | Assinado em | Nova vigência / valor / escopo | Arquivo (path, hash) |
|---|---|---|---|---|---|

## Encerrados
| #K | Contraparte (alias) | Encerrado em | Motivo (fim / distrato / denúncia / rescisão) | Obrigações sobreviventes (confidencialidade, PI — até quando) | Arquivo |
|---|---|---|---|---|---|

## Em disputa
| #K | Caso #P | Fase | Advogado (alias) | Próximo prazo (#id, fonte) |
|---|---|---|---|---|
