---
title: Architecture
type: architecture
status: active
agent: dev-architect
created: 2026-04-24
updated: 2026-04-24
tags: [project, architecture]
related: ["[[overview]]", "[[tech-stack]]", "[[modules]]"]
---

# Arquitetura — Centro de Treinamento

## Padrão: Skill-Based Agent Orchestration

O sistema segue um modelo hub-and-spoke onde `team-os` é o hub central (lead) e os agentes especializados são os spokes (teammates).

```
Usuário
  │
  ▼
[/team-os skill]  ◄──── team lead (main session)
  │
  ├─ TeamCreate({team_name})
  │
  ├─ Agent(dev-architect, team_name=X) ──► escreve docs/smart-memory/project/
  ├─ Agent(dev-analyst, team_name=X)   ──► escreve docs/smart-memory/project/
  ├─ Agent(dev-dev-beta, team_name=X)  ──► implementa stories
  ├─ Agent(dev-qa, team_name=X)        ──► emite veredictos PASS/FAIL
  └─ Agent(dev-devops, team_name=X)    ──► git push, PR, deploy
       │
       └── SendMessage(lead) ao concluir
```

## Estrutura de diretórios

```
.claude/
├── agents/          # 37 agentes — .md com frontmatter + prompt
├── skills/          # 42 skills — diretório por skill, SKILL.md
│   ├── team-os/     # Skill de orquestração (esta skill)
│   │   ├── SKILL.md
│   │   ├── templates/
│   │   ├── scripts/
│   │   └── reference/
│   └── {skill-name}/
│       └── SKILL.md
├── hooks/           # Hooks de automação (pre/post tool calls)
└── settings.json    # Env vars (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)

docs/smart-memory/   # Fonte de verdade compartilhada (Obsidian-compatible)
├── INDEX.md
├── shared-context.md
├── project/
├── stories/{backlog,active,done}/
├── decisions/
├── ops/
└── agents/
```

## Fluxo de trabalho padrão

```
1. /team-os             → detecta estado do projeto
2. *bootstrap/*plan     → cria smart-memory + backlog de stories
3. *dispatch            → forma team, spawna teammates, atribui tasks
4. [teammates trabalham em paralelo via Agent Teams]
5. SendMessage → lead   → cada teammate reporta conclusão
6. dev-qa gate          → PASS/CONCERNS/FAIL/WAIVED
7. dev-devops           → git push + PR (autoridade exclusiva)
8. *close               → arquiva smart-memory, encerra team
```

## Princípios de design

1. **Autoridade exclusiva por papel** — stories só via dev-architect/sites-architect/traffic-strategist; QA só via dev-qa/sites-qa/traffic-qa; git push só via dev-devops/sites-devops
2. **Prompt minimalista por agente** — cada agente faz UMA coisa bem; skills estendem comportamento quando necessário
3. **Comunicação via SendMessage** — teammates nunca spawnam sub-teammates; nested teams são bloqueados
4. **Smart-memory como fonte de verdade** — toda decisão relevante escrita em `docs/smart-memory/`; nunca em memória conversacional
5. **Model fit** — Opus para decisões/QA (custo maior, qualidade superior); Sonnet para execução (velocidade + custo)

## Squads como módulos independentes

Cada squad (dev, sites, social, traffic) é auto-suficiente:
- Tem seu próprio architect (estratégia + stories)
- Tem seu próprio QA (veredictos formais)
- Tem seu próprio devops/publisher (ativação)
- Pode ser usada independentemente sem as outras squads

## Agent Teams — como funciona

1. `TeamCreate({team_name})` — registra o team em `~/.claude/teams/`
2. `Agent({subagent_type, team_name, name, prompt})` — spawna teammate no team
3. Teammates ficam visíveis no painel (Shift+Tab) e acessíveis via `SendMessage`
4. TaskList é 1:1 com o team — tasks criadas APÓS TeamCreate ficam no team
5. Team lead (main session) coordena; teammates executam e reportam de volta
