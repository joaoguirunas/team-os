---
kind: reference
status: living
summary: "Ledger de assinatura: {N} documentos, {a} travados, {b} enviados, {c} assinados, {d} aguardando confirmação do usuário"
title: "Signature Ledger — travamento, envio e assinatura"
agent: legal-ops
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [legal, ops, signature, ledger]
related: ["[[arquivo]]", "[[../../project/contracts-registry]]", "[[../qa/results]]", "[[../strategy/validations]]", "[[../../project/legal-context]]"]
---

# Signature Ledger — travamento, envio e assinatura

> Nada sai sem PASS de IUSTITIA para esta versão **e** confirmação explícita do usuário para este arquivo e este destinatário. Hash diferente = outro documento = outro PASS. Quem envia e assina é o humano; AEQUITAS registra. Documento enviado não se corrige — vira versão nova.

## Ledger
| Documento (slug) | Versão | Hash (sha256) | Nome do arquivo (convenção) | PASS IUSTITIA (data) | Gate PRUDENTIA (data) | Poderes conferidos | Confirmação do usuário (data, texto) | Destinatário (alias) | Enviado em (pelo usuário) | Ferramenta / id do envelope | Signatários (ordem) | Status | Assinado em | Hash do assinado | Trilha de auditoria (path) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| | v{N} | | | | | {sim / [PODERES A CONFIRMAR]} | | | | | | {travado / aguardando confirmação / enviado / parcialmente assinado / assinado / devolvido} | | | |

## Confirmações do usuário (texto literal)
| Data | Documento v{N} | Hash | Destinatário (alias) | Texto da confirmação |
|---|---|---|---|---|

## Devoluções da contraparte
| Data | Documento v{N} | O que pediram | Encaminhado a | Nova versão | Novo PASS |
|---|---|---|---|---|---|

## Follow-up
| Documento | Signatário pendente | Lembrete D+3 | Lembrete D+7 | Próximo passo | Dono |
|---|---|---|---|---|---|
