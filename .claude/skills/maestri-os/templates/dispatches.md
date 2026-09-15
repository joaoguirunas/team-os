---
title: Histórico de despachos — Sala de Controle
kind: digest
type: maestri-dispatches
status: living
summary: "Uma linha por pedido despachado: quando, para qual terminal, o que, e o status/resposta. Fatos atômicos datados; linhas com mais de ~30 dias vão para _archive/ no *compact."
updated: {data}
tags: [maestri, roteamento, task-log]
related: ["[[maestri/registry]]", "[[maestri/OVERVIEW]]"]
---

# Despachos — {nome da Sala de Controle}

Formato: `- [YYYY-MM-DD HH:MM] → "<Terminal>" · <pedido resumido> · status: <enviado|aguardando aviso|respondido: <resumo>|erro: <motivo>>`
Atualize a **mesma linha** quando a resposta chegar — não crie uma segunda.

## Em andamento
<!-- - [2026-09-14 21:40] → "João Guirunas | Site | Home" · corrigir botão do hero · status: aguardando aviso (longo, background) -->

## Concluídos (últimos 30 dias)
<!-- - [2026-09-14 21:52] → "João Guirunas | Site | Home" · corrigir botão do hero · status: respondido: PR #42 aberto, QA PASS -->
