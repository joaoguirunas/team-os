---
title: Histórico de despachos — Sala de Controle
kind: digest
type: sala-dispatches
status: living
summary: "Uma linha por sub-pedido despachado: quando, para qual sessão/projeto, o quê, e o status/retorno. Linha atualizada in-place quando o retorno chega."
updated: {data}
tags: [sala-de-controle, roteamento, task-log]
related: ["[[sala-de-controle/registry]]", "[[sala-de-controle/PANORAMA]]"]
---

# Despachos

Formato: `- [YYYY-MM-DD HH:MM] → "<Sessão>" (<Projeto>) · <pedido resumido> · status: <enviado: delivered|queued | sessão nova <id> | aguardando retorno | respondido: <resumo> | DECISÃO: <pergunta> | erro: <motivo>>`
Dependente: acrescente `· depende de: <linha>`. Atualize a **mesma linha** — nunca crie outra.

## Em andamento
<!-- - [2026-09-25 15:10] → "João Guirunas | Site | Home" (João Guirunas | Site) · depoimento novo na home · status: aguardando retorno (delivered) -->

## Concluídos (últimos 30 dias)
<!-- - [2026-09-25 15:10] → "João Guirunas | Site | Home" · depoimento novo na home · status: respondido: no ar em /#depoimentos, QA PASS -->
