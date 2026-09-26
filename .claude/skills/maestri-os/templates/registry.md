---
title: Registro de terminais Maestri
kind: reference
type: maestri-registry
status: active
summary: "Quem é cada terminal ligado à Sala de Controle: pasta, apelidos e o que foi lido da pasta (squads, agentes, resumo). Consultado antes de todo despacho."
updated: {data}
tags: [maestri, roteamento]
related: ["[[maestri/OVERVIEW]]", "[[maestri/dispatches]]"]
---

# Registro de terminais — {nome da Sala de Controle}

Uma seção por terminal, com o **nome exato** que aparece no `maestri list`. Nasce do onboarding em lote (tabela janela → pasta → escopo → apelidos, confirmada com um OK) e **não é perguntada de novo** — só quando aparece janela nova ou o usuário pede correção. A parte "Informado por você" só muda por pedido do usuário. A parte "Lido automaticamente" é reescrita a cada rodada pelo `scan-project.sh`.

<!-- Exemplo de seção — apague ao registrar o primeiro terminal real.

### Minha Marca | Site | Home
**Informado por você**
- pasta: <raiz>/Minha Marca | Site
- escopo: Home (página inicial do site) — derivado do nome da janela; outra janela da mesma pasta pode ser "Site | Mentoria"
- apelidos: site, home, landing
- como acionar: (opcional — ex.: "sempre começa pelo sites-architect")
**Lido automaticamente** (atualizado em 2026-09-14)
- squads: sites · agentes (10): sites-analyst, sites-architect, sites-data, sites-ux, sites-dev-alpha, sites-dev-beta, sites-dev-delta, sites-dev-gamma, sites-qa, sites-devops
- team-os: sim · smart-memory: sim · áreas: architect, data, qa, research, ux
- resumo: Site de autoridade pessoal + funil de conversão, publicado em minhamarca.com.

-->
