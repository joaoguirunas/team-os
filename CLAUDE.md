# CT — Centro de Treinamento

Este é o repositório fonte dos 49 agentes e skills para Claude Code Agent Teams.

## O que é este projeto

O CT é a **fonte da verdade** — qualquer alteração em agentes ou skills é feita aqui e propagada para os projetos destino via `/team-os-creator *propagate`. Nunca editar agentes diretamente nos projetos destino.

## Skills exclusivas do CT

Duas skills existem **somente aqui** e nunca são copiadas para projetos destino:

- **`/team-os`** — Bootstrap e orquestração de sessões Agent Teams. Carregue ao iniciar qualquer sessão de trabalho com múltiplos agentes.
- **`/team-os-creator`** — Factory de agentes. Use para criar, migrar, auditar e instalar agentes em projetos.

## Padrão de agentes

Todo agente do CT segue o **Native Teams Protocol**:
- `memory: project` no frontmatter (obrigatório)
- Bloco `## Native Teams Protocol` no body (comunicação peer-to-peer, TaskList nativo, smart-memory)
- Sem campo `skills:` no frontmatter (ignorado em Agent Teams)
- Implementers com `isolation: worktree` e hook `block-git-push.sh`

Para criar ou atualizar agentes, use `/team-os-creator` — nunca editar manualmente sem rodar `*audit` depois.

## Hooks

Os hooks em `.claude/hooks/` são referenciados diretamente no frontmatter dos agentes:

- `block-git-push.sh` — PreToolUse nos agentes implementers (dev-dev-*, sites-dev-*, social-video)
- `check-story-progress.sh` — validação de progresso de stories
- `check-social-progress.sh` — validação de progresso de conteúdo social

## Fluxo de trabalho

```
Editar agente no CT → /team-os-creator *audit → /team-os-creator *propagate → commit por projeto
```

## Comandos rápidos

```
/team-os                    → orquestrar sessão com Agent Teams
/team-os-creator *audit     → validar todos os agentes
/team-os-creator *propagate → propagar para projetos destino
/team-os-creator *install   → instalar squads em projeto novo
```
