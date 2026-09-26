# team-os — by João Guirunas

Repositório fonte do pack **team-os**: 95 agentes e 108 skills para Claude Code Agent Teams. (Codinome interno do repo: **CT — Centro de Treinamento**.)

> 📖 **Documentação completa: [README.md](./README.md)** — tutorial detalhado das skills principais (`/team-os` e `/team-os-creator`), dos 95 agentes com suas skills relacionadas, do catálogo de skills de apoio, passo a passo, modelo de coordenação, política de modelos, hooks e manutenção. Consulte o README como fonte completa; este arquivo traz só as regras operacionais essenciais.

## O que é este projeto

O CT é a **fonte da verdade** — qualquer alteração em agentes ou skills é feita aqui e propagada para os projetos destino via `/team-os-creator *propagate`. Nunca editar agentes diretamente nos projetos destino; a partir do CT só se roda `*install`/`*propagate` (nunca git ou arquivos de produto num destino).
→ Detalhes em [README.md §13 — Manutenção do CT](./README.md#13-manutenção-do-ct).

## As skills principais

- **`/team-os`** — Bootstrap e orquestração de sessões Agent Teams. **É distribuída para todos os projetos** (obrigatória — o usuário roda `/team-os` no início de cada sessão). → [README.md §3](./README.md#3-skill-principal-team-os)
- **`/team-os-creator`** — Factory de agentes. **Única skill exclusiva do CT** — nunca copiada para projetos destino. Comandos e flags reais em `.claude/skills/team-os-creator/SKILL.md`. → [README.md §4](./README.md#4-skill-principal-team-os-creator)
- **`/sala-de-controle`** — **Sala de Controle** (opt-in) das sessões do Claude Code: lugar único de comando — relê todas as sessões e a etapa de cada projeto pela smart-memory, despacha cada pedido para a sessão certa e propõe a organização de pastas. Vive numa pasta isolada (`<raiz>/1 | Sala de Controle`) **sem agentes e sem `team-os`**; só via `*install --squads none --extra-skills sala-de-controle` — onde já está instalada, o `*propagate` a mantém atualizada. → [README.md §6 — Sala de Controle](./README.md#sala-de-controle--sala-de-controle-sessões-do-claude-code)
- **`/maestri-os`** — **Sala de Controle** no modo Maestri (recurso opt-in para o Maestri): roteia pedidos entre os terminais dos projetos. Vive numa pasta própria **sem agentes e sem `team-os`**; só via `*install --squads none --extra-skills maestri-os` — onde já está instalada, o `*propagate` a mantém atualizada. → [README.md §6 — Sala de Controle](./README.md#sala-de-controle--maestri-os-recurso-para-o-maestri)

## Padrão de agentes

Todo agente do CT segue o **Native Teams Protocol** (detalhado em [README.md §1](./README.md#1-conceitos-fundamentais)):
- `memory: project` no frontmatter (obrigatório)
- Bloco `## Native Teams Protocol` no body, byte-idêntico em todos (trocar só via `scripts/migrate-ntp.sh`)
- Linha `**Área na smart-memory:** \`docs/smart-memory/agents/<squad>/<área>/\`` logo após o H1 — o `discovery.sh` da `team-os` lê essa linha para criar as áreas no projeto destino
- Sem campo `skills:` no frontmatter (ignorado em Agent Teams); tools `mcp__*` só na forma curta `mcp__<server>` e só servidores de `.claude/skills/team-os-creator/reference/mcp-servers.md`
- `block-git-push.sh` em **todo agente com Bash exceto os devops** (todas as squads); sem `isolation: worktree` — agentes escrevem direto na branch ativa
- Política de modelos **Híbrida**: `opus` fixo em architects/planners, QA e strategists (23); `inherit` nos demais (72). Effort por archetype em `.claude/skills/team-os-creator/reference/archetypes.md` (omitido em implementer/devops) → [README.md §9](./README.md#9-política-de-modelos-híbrido)

Para criar ou atualizar agentes, use `/team-os-creator` — nunca editar manualmente sem rodar `*audit` depois.

## Smart-memory (convenção do projeto destino)

O CT não versiona `docs/smart-memory/` — ela nasce em cada destino na 1ª sessão de `/team-os` (Discovery Engine). Convenção: `agents/<squad>/<área>/` (um DIGEST.md por área; PM em `agents/pm/*`), `stories/BACKLOG.md` + `stories/{backlog,active,in-review,done}/<id>-<slug>.md`. → `.claude/skills/team-os/reference/estrutura-smart-memory.md` e [README.md §11](./README.md#11-estrutura-do-repositório)

## Hooks

12 hooks em `.claude/hooks/`, testados por `scripts/test-hooks.sh` (493 casos, no CI). Descrição completa em [README.md §10](./README.md#10-hooks-de-qualidade):

- Guards de git (`PreToolUse`): `block-git-push.sh` (92 agentes) · `guard-push-branch.sh` (2 devops — push só na `main`/`master`; fora dela o bloqueio é **sempre** aplicado, o hook não consegue verificar pedido do usuário, push é manual) · `block-worktree.sh` (settings.json de cada projeto). Ambos os guards de push bloqueiam shell embutido (`sh -c`, `eval`, `xargs`…).
- Gates de task (`TaskCreated`/`TaskCompleted`, leem `task_subject`/`task_description`): `task-quality.sh` · `check-story-progress.sh` · `check-social-progress.sh` · `check-proposal-progress.sh` · `check-finance-progress.sh` · `check-legal-progress.sh`
- Economia de tokens (`PreToolUse`, settings de cada projeto): `guard-smart-memory-read.sh` (bloqueia `_archive/`, pasta inteira e a 4ª nota sem `sm-find.sh`) · `guard-message-size.sh` (mensagem entre agentes ≤20 linhas; `[handoff]` até 60)
- Sessão: `team-os-session-title.sh` (`SessionStart`, instalado em `~/.claude/hooks/` pelo `*install`)

## Fluxo de trabalho

```
Editar agente/skill no CT
→ validate-agent.sh            (= *audit; 95/95)
→ validate-agent.sh --skills   (lint das 108 skills)
→ test-hooks.sh                (493/493)
→ generate-agents-page.py      (regenera docs/agentes.html — obrigatório após mudar agente ou skill)
→ commit no CT (registrar no CHANGELOG.md)
→ /team-os-creator *propagate  (--match-target-squads) → commit por projeto, na sessão de cada destino
```

Scripts em `.claude/skills/team-os-creator/scripts/`. O CI (`.github/workflows/audit.yml`) repete tudo e ainda confere as contagens "95 agentes"/"108 skills" no README e aqui, zero caminho de máquina versionado (use `<raiz>/...`) e `docs/agentes.html` em dia.

## Comandos rápidos

```
/team-os                    → orquestrar sessão com Agent Teams
/team-os-creator *audit     → validar todos os agentes e skills
/team-os-creator *propagate → propagar para projetos destino
/team-os-creator *install   → instalar squads em projeto novo
```

> Para qualquer dúvida de uso, agentes, skills ou fluxo: **[README.md](./README.md)** é a referência completa. Licença MIT — [LICENSE](./LICENSE); terceiros em [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md); contribuição em [CONTRIBUTING.md](./CONTRIBUTING.md).
