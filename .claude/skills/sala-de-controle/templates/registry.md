---
title: Registro de sessões — Sala de Controle
kind: reference
type: sala-registry
status: active
summary: "Sessões do Claude que a Sala conhece: pasta, título, apelidos, se foi aberta pela Sala, como acionar. Entrada nova nasce sozinha do scan; apelidos e 'como acionar' só mudam por pedido do usuário."
updated: {data}
tags: [sala-de-controle, roteamento]
related: ["[[sala-de-controle/PANORAMA]]", "[[sala-de-controle/dispatches]]"]
---

# Registro de sessões

Uma seção por sessão, com o **nome exato** do scan. Padrão de nome: `<NOME DA PASTA> | <Título>`.
Sessão que sumiu do scan fica marcada `fechada em <data>` — se reabrir com o mesmo nome, a entrada é reaproveitada.

<!-- Exemplo — apague ao registrar a primeira sessão real.

### Minha Marca | Site | Home
- pasta: <raiz>/Minha Marca/Minha Marca | Site
- título / escopo: Home (página inicial)
- apelidos: home, site, landing
- aberta pela Sala: não  ·  id: —
- como acionar: (opcional — ex.: "sempre começa pelo sites-architect")
- status: aberta (visto em 2026-09-25 14:50)

-->
