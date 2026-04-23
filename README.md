# Claude Squads — Pacote de Configuração

Backup e template de referência das 2 skills + squad padrão pra Claude Code com Agent Teams.

## Conteúdo

```
.claude/
├── agents/            # 10 agentes teammates (dev squad)
├── skills/            # 14 skills
│   ├── team-os/          # skill lead (orquestrador)
│   ├── team-os-creator/  # skill criadora de novos agentes
│   ├── dev-*             # 9 skills técnicas (typescript, api-design, etc)
│   ├── ui-ux-pro-max     # design system + 161 paletas + 99 UX guidelines
│   ├── accessibility     # WCAG 2.2 (Addy Osmani)
│   └── web-design-guidelines # Vercel UI audit
├── hooks/             # block-git-push.sh + check-story-progress.sh
└── settings.json      # env: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Instalar em um projeto novo

```bash
# no diretório do projeto alvo
cp -R ~/Desktop/Projetos/Squads/claude/.claude .

# reinstalar obsidian-markdown (se precisar, vinha do skills-lock do projeto original)
# (opcional — as outras skills já vêm copiadas)
```

Depois, recarregue o Claude Code e digite `/team-os` pra começar.

## 2 skills disponíveis

### `/team-os`
Team lead — orquestra Agent Teams usando os agentes em `.claude/agents/`. Mantém smart-memory (padrão Obsidian) como fonte de verdade. Auto-detecta estado do projeto e propõe bootstrap de descoberta quando smart-memory não existe.

**Comandos:** `*init`, `*bootstrap`, `*discover`, `*plan`, `*dispatch`, `*status`, `*audit`, `*resume`, `*unblock`, `*enroll`, `*close`

### `/team-os-creator`
Factory de agentes — cria novos agentes seguindo os padrões validados (Agent Teams + smart-memory + contrato + skills.sh curada). Use antes do `/team-os` quando quiser montar squad customizada.

**Comandos:** `*analyze`, `*squad <preset>`, `*create <role>`, `*skills <agente>`, `*preset-list`, `*audit`

## Pré-requisitos

- Claude Code (última versão)
- Node.js (pra `npx skills add` ao instalar skills do skills.sh)
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (já vem no settings.json)

## Padrões-chave

- **Agent Teams, não subagents.** Skill team-os forma times nativos via `TeamCreate` + `Agent(team_name=..., name=...)`.
- **Smart-memory em `docs/smart-memory/`** com padrão Obsidian (frontmatter + wikilinks + tags).
- **Team name** sempre `{pasta-do-projeto}-{objetivo-slug}` pra evitar colisão em `~/.claude/teams/`.
- **Contrato com team-os** injetado em todo agente — lead é a skill, não outro agente.
- **Worktree isolation** nos implementers (alpha/beta/gamma/delta).
- **Hook `block-git-push`** nos implementers — só DevOps faz push.

## Agentes incluídos (squad dev)

| Agente | Archetype | Persona | Papel |
|---|---|---|---|
| dev-analyst | researcher | Lyra | Research, CVE, feasibility |
| dev-architect | architect | Zael | Stories, ADRs, arquitetura |
| dev-ux | ux | Vela+Astra | UX research, component specs |
| dev-dev-alpha | implementer | Nova | Frontend |
| dev-dev-beta | implementer | Rex | Backend |
| dev-dev-gamma | implementer | Sera | Fullstack/integração |
| dev-dev-delta | hardening | Kron | Resilience (APÓS features) |
| dev-qa | reviewer | Axis | Quality gates formais |
| dev-devops | devops | Grav | Push, PRs, CI/CD |
| dev-data-engineer | data | Byte | Schema, migrations, RLS |

## Projetos que usam

- `~/Desktop/Projetos/Sistemas/team-os` (projeto de origem)
- `~/Desktop/Projetos/Sistemas/rev-os`

Mantenha esse pacote atualizado quando fizer melhorias — é o ponto de referência pra novos projetos.
