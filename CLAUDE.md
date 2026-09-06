# team-os — by João Guirunas

Repositório fonte do pack **team-os**: 48 agentes e 52 skills para Claude Code Agent Teams. (Codinome interno do repo: **CT — Centro de Treinamento**.)

> 📖 **Documentação completa: [README.md](./README.md)** — tutorial detalhado das skills principais (`/team-os` e `/team-os-creator`), dos 48 agentes com suas skills relacionadas, do catálogo de skills de apoio, passo a passo, modelo de coordenação, política de modelos e manutenção. Consulte o README como fonte completa; este arquivo traz só as regras operacionais essenciais.

## O que é este projeto

O CT é a **fonte da verdade** — qualquer alteração em agentes ou skills é feita aqui e propagada para os projetos destino via `/team-os-creator *propagate`. Nunca editar agentes diretamente nos projetos destino.
→ Detalhes em [README.md §13 — Manutenção do CT](./README.md#13-manutenção-do-ct).

## As duas skills principais

- **`/team-os`** — Bootstrap e orquestração de sessões Agent Teams. **É distribuída para todos os projetos** (obrigatória — o usuário roda `/team-os` no início de cada sessão). → [README.md §3](./README.md#3-skill-principal-team-os)
- **`/team-os-creator`** — Factory de agentes. **Única skill exclusiva do CT** — nunca copiada para projetos destino. → [README.md §4](./README.md#4-skill-principal-team-os-creator)

## Padrão de agentes

Todo agente do CT segue o **Native Teams Protocol** (detalhado em [README.md §1](./README.md#1-conceitos-fundamentais)):
- `memory: project` no frontmatter (obrigatório)
- Bloco `## Native Teams Protocol` no body (comunicação peer-to-peer, TaskList nativo, smart-memory)
- Sem campo `skills:` no frontmatter (ignorado em Agent Teams)
- Implementers com hook `block-git-push.sh` (sem `isolation: worktree` — agentes escrevem direto na branch ativa)
- Política de modelos **Híbrida**: `opus` fixo em architects/reviewers(QA)/strategists; `inherit` nos demais → [README.md §9](./README.md#9-política-de-modelos-híbrido)

Para criar ou atualizar agentes, use `/team-os-creator` — nunca editar manualmente sem rodar `*audit` depois.

## Hooks

Os hooks em `.claude/hooks/` são referenciados diretamente no frontmatter dos agentes (ver [README.md §10](./README.md#10-hooks-de-qualidade)):

- `block-git-push.sh` — PreToolUse em **TODO agente com Bash exceto os devops** (todas as squads): push é garantia dura, exclusiva do devops. Cobre `git -C`/`--git-dir`/aliases/multilinha e `gh pr`/`gh api`
- `block-worktree.sh` — PreToolUse registrado no `.claude/settings.json` de cada projeto (matchers `Agent|Task|EnterWorktree` e `Bash`): bloqueia `isolation: worktree`, EnterWorktree, `git worktree add` **e criação de branch** (`checkout -b`/`switch -c`/`git branch <nome>`) — todo trabalho acontece direto na branch ativa. Complementado por `"worktree": { "bgIsolation": "none" }` no mesmo settings
- `guard-push-branch.sh` — PreToolUse nos devops: push permitido só na `main`/`master`; fora dela exige pedido explícito do usuário na sessão
- `task-quality.sh` — hook `TaskCreated` (registrado no settings): rejeita task vaga (título curto/genérico ou sem descrição)
- `check-story-progress.sh` — hook `TaskCompleted`: task que referencia story só fecha com `## QA Results` ou `status: done|in-review` na story
- `check-social-progress.sh` — hook `TaskCompleted`: task de publicação social só fecha com aprovação registrada (VERA/strategist)
- `team-os-session-title.sh` — hook `SessionStart` que nomeia a sessão por "projeto · branch" (instalado globalmente em `~/.claude/hooks/` e registrado no `~/.claude/settings.json` pelo `*install`)

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

> Para qualquer dúvida de uso, agentes, skills ou fluxo: **[README.md](./README.md)** é a referência completa.
