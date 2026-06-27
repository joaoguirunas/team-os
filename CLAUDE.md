# team-os — by João Guirunas

Repositório fonte do pack **team-os**: 49 agentes e 49 skills para Claude Code Agent Teams. (Codinome interno do repo: **CT — Centro de Treinamento**.)

> 📖 **Documentação completa: [README.md](./README.md)** — tutorial detalhado das skills principais (`/team-os` e `/team-os-creator`), dos 49 agentes com suas skills relacionadas, do catálogo de skills de apoio, passo a passo, modelo de coordenação, política de modelos e manutenção. Consulte o README como fonte completa; este arquivo traz só as regras operacionais essenciais.

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
- Implementers com `isolation: worktree` e hook `block-git-push.sh` — exceção: `social-video` é implementer que mantém o `block-git-push.sh` mas roda **sem** `isolation: worktree` (exceção intencional — produz assets de mídia via ffmpeg)
- Política de modelos **Híbrida**: `opus` fixo em architects/reviewers(QA)/strategists; `inherit` nos demais → [README.md §9](./README.md#9-política-de-modelos-híbrido)

Para criar ou atualizar agentes, use `/team-os-creator` — nunca editar manualmente sem rodar `*audit` depois.

## Hooks

Os hooks em `.claude/hooks/` são referenciados diretamente no frontmatter dos agentes (ver [README.md §10](./README.md#10-hooks-de-qualidade)):

- `block-git-push.sh` — PreToolUse nos implementers (dev-dev-*, sites-dev-*, social-video) **e em todo agente não-devops com Bash nas squads de código** (dev-*/sites-* exceto devops): push é garantia dura, exclusiva do devops
- `check-story-progress.sh` — validação de progresso de stories
- `check-social-progress.sh` — validação de progresso de conteúdo social
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
