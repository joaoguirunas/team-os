---
title: Tech Stack
type: tech-stack
status: active
agent: dev-analyst
created: 2026-04-24
updated: 2026-04-24
tags: [project, tech-stack]
related: ["[[overview]]", "[[architecture]]"]
---

# Tech Stack — Centro de Treinamento

## Core Platform

| Componente | Versão/Detalhe | Papel |
|---|---|---|
| **Claude Code** | CLI + Desktop + IDE Extensions | Runtime dos agentes |
| **Claude API (Anthropic)** | claude-opus-4-x / claude-sonnet-4-x / claude-haiku-4-x | LLM por trás dos agentes |
| **Agent Teams** | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | Orquestração multi-agente nativa |

## Modelos por papel

| Modelo | Uso nos agentes |
|---|---|
| `opus` | Papéis estratégicos/QA: dev-architect, dev-qa, sites-architect, sites-qa, social-strategist, traffic-strategist, traffic-qa |
| `sonnet` | Papéis de execução: todos os demais (dev, implementação, análise) |

## MCPs (Model Context Protocol) integrados

| MCP | Agentes que usam | Função |
|---|---|---|
| **Apify** | social-content | Web scraping, research de tendências via RAG |
| **Google Stitch** | social-design | Geração de assets visuais e design system |
| **Freepik** | social-photo | Geração de imagens AI (generate, upscale, reframe) |
| **Meta** | social-publisher | Publicação no Instagram/Facebook, scheduling, insights |
| **magic/21st** | social-design | Component builder e logo search |

## Ferramentas padrão dos agentes

Todos os agentes têm acesso à combinação adequada de:
- `Read, Glob, Grep` — navegação e leitura de código
- `Write, Edit` — produção/edição de arquivos
- `Bash` — execução de comandos shell
- `WebSearch, WebFetch` — pesquisa e acesso web
- `SendMessage` — comunicação com o lead (team-os) e outros teammates

## Configuração do projeto

```json
// .claude/settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Convenção de memória dos agentes

Todos os agentes têm `memory: project` no frontmatter — leem e escrevem em `docs/smart-memory/` como fonte de verdade compartilhada.

## Skills como módulos de comportamento

Skills em `.claude/skills/` são invocadas via `/skill-name` e definem comportamentos especializados (ex: `/team-os`, `/ui-ux-pro-max`, `/deep-research`). São a principal forma de estender o comportamento do agente além do prompt base.
