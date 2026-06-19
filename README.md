# CT — Centro de Treinamento

**49 agentes pré-construídos** para Claude Code, organizados em 5 squads (Dev, Sites, Social, Traffic, PM), com Native Teams Protocol e smart-memory em formato Obsidian.

> Fonte da verdade para agentes e skills. Use `/team-os-creator` para instalar em qualquer projeto, e `/team-os` para orquestrar sessões com Agent Teams.

---

## Como usar

### 1. Orquestrar com team-os (Agent Teams)

Abra o CT ou qualquer projeto que tenha agentes instalados e carregue a skill:

```
/team-os
```

A skill faz o bootstrap completo: verifica o ambiente, apresenta os agentes disponíveis, lê a smart-memory e pergunta o objetivo da sessão. A partir daí, propõe o time certo e você spawna.

Ou use diretamente via `claude agents` para gerenciar sessões em background.

### 2. Instalar agentes em um projeto

```
/team-os-creator *install
```

Selecione o projeto destino e as squads. O instalador copia agentes, cria `docs/smart-memory/` e configura `settings.json`.

### 3. Criar agentes novos

```
/team-os-creator *create <role>
```

Ou montar uma squad do zero:

```
/team-os-creator *squad dev
```

---

## Squads (49 agentes)

| Squad | Agentes | Para |
|---|---|---|
| **Dev** | 12 | Fullstack SaaS — analyst, architect, bi, data-engineer, data-performance, ux, dev-alpha, dev-beta, dev-delta, dev-gamma, qa, devops |
| **Sites** | 10 | Sites e landing pages — analyst, architect, data, ux, dev-alpha, dev-beta, dev-delta, dev-gamma, qa, devops |
| **Social** | 7 | Social media — analyst, content, design, photo, publisher, strategist, video |
| **Traffic** | 10 | Tráfego pago — analyst, automation, bi, copywriter, designer, google, meta, qa, strategist, tiktok |
| **PM** | 10 | Gestão de projetos — analyst, client, coach, data, demand, engineer, ops, planner, qa, reporter |

---

## Arquitetura

Os agentes seguem o **Native Teams Protocol** — autônomos, com smart-memory integrada, comunicação peer-to-peer via `SendMessage`, coordenação por `TaskList` nativo.

```
Você (lead — sessão principal)
  │
  ├── Agent Panel / claude agents
  │     ├── dev-architect    → src/auth/, docs/smart-memory/architecture/
  │     ├── dev-dev-alpha    → src/frontend/  (worktree isolada)
  │     ├── dev-qa           → review paralelo
  │     └── dev-devops       → git push, PRs, releases
  │
  ├── TaskList compartilhada
  │     └── tasks com dependências, auto-claim, self-coordination
  │
  └── docs/smart-memory/
        ├── INDEX.md              ← todos os agentes leem ao iniciar
        ├── stories/active/       ← stories em andamento
        └── qa/                   ← findings de QA
```

---

## Smart-Memory

Cada projeto tem `docs/smart-memory/` — base de conhecimento persistente em formato Obsidian:

```
docs/smart-memory/
├── INDEX.md              ← MOC raiz (navegação)
├── project/              ← tech-stack, conventions, overview
├── architecture/         ← decisões arquiteturais (ADRs)
├── decisions/            ← decisões técnicas pontuais
├── stories/              ← backlog / active / in-review / done
├── research/             ← findings de pesquisa
├── modules/              ← documentação de módulos
└── qa/                   ← resultados de QA
```

Bootstrap via:
```
/team-os-creator *bootstrap
```

---

## Estrutura do CT

```
.claude/
├── agents/              ← 49 definições de agentes (fonte da verdade)
├── hooks/               ← hooks de qualidade do projeto
│   ├── block-git-push.sh          ← bloqueia push em agentes implementers
│   ├── check-story-progress.sh    ← valida progresso de stories
│   └── check-social-progress.sh   ← valida progresso de conteúdo social
└── skills/              ← skills carregáveis (team-os e team-os-creator exclusivos do CT)
```

`team-os` e `team-os-creator` existem **somente aqui** e não são copiados para projetos destino.

---

## Comandos principais

```
/team-os                          → bootstrap da sessão + proposta de time
/team-os-creator                  → menu principal (scan + sugestões)
/team-os-creator *install         → instalar em projeto destino
/team-os-creator *propagate       → atualizar agentes em projetos existentes
/team-os-creator *migrate         → migrar agentes do padrão antigo
/team-os-creator *bootstrap       → inicializar smart-memory no projeto atual
/team-os-creator *audit           → validar compliance dos agentes
```

---

## Requisitos

- Claude Code com `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` em `~/.claude/settings.json`
- Plano com suporte a Agent Teams
