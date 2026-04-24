---
title: Project Overview
type: overview
status: active
agent: team-os
created: 2026-04-24
updated: 2026-04-24
tags: [project]
related: ["[[tech-stack]]", "[[architecture]]", "[[../stories/BACKLOG]]", "[[modules]]"]
---

# Centro de Treinamento de Agentes Claude Code

## Objetivo

Repositório central de agentes Claude Code nativos e skills para orquestração via Agent Teams. Funciona como "sistema operacional" para squads especializadas: cada squad tem agentes com papéis bem definidos, tools restritas ao necessário, e contratos com o team-os para coordenação via SendMessage.

## Contexto

- **Plataforma:** Claude Code CLI (Anthropic) com `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- **Padrão:** Agent Teams nativos — team-os como lead, teammates spawned via `Agent({team_name, ...})`
- **Usuários alvo:** Operadores que precisam de squads especializadas para dev, sites, social ou tráfego pago
- **Fonte de verdade:** Este repositório `.claude/` — agentes em `.claude/agents/`, skills em `.claude/skills/`

## Squads disponíveis

| Squad | Agentes | Foco |
|---|---|---|
| **dev** | 10 | Software complexo (backend, frontend, infra, QA) |
| **sites** | 10 | Websites/Next.js (landing pages, CMS, SEO, deploy) |
| **social** | 7 | Redes sociais (content, design, photo, video, publish) |
| **traffic** | 10 | Tráfego pago Google/Meta/TikTok (estratégia → QA → ativação) |

**Total: 37 agentes + 42 skills**

## Equipe

Squad dinâmica — team lead via skill `/team-os`, teammates conforme disponibilidade em `.claude/agents/`.

## Links
- [[tech-stack]] — stack e dependências externas
- [[architecture]] — padrão arquitetural e fluxo de orquestração
- [[modules]] — mapa completo de todos os agentes e suas responsabilidades
- [[conventions]] — como criar e manter agentes/skills
- [[../stories/BACKLOG]] — backlog
- [[squads/dev-squad]] — squad dev detalhada
- [[squads/sites-squad]] — squad sites detalhada
- [[squads/social-squad]] — squad social detalhada
- [[squads/traffic-squad]] — squad traffic detalhada
