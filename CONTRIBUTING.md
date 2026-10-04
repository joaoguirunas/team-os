# Contribuindo com o team-os

Este repositório é a **fonte da verdade** dos agentes, skills e hooks. Tudo é editado aqui e propagado aos projetos destino com `/team-os-creator *propagate`. Nunca edite um agente diretamente num projeto destino.

> **Contribuir é diferente de usar o pack.** Quem só usa o pack (cria os próprios agentes e recebe as versões novas com `*update`) não precisa deste arquivo e não commita nada no CT. Quem contribui via Pull Request trabalha no próprio fork e commita normalmente — as regras abaixo valem para esse caso. O ciclo de release (versão, manifest, tag e push) é só do mantenedor: [MAINTAINERS.md](./MAINTAINERS.md); numa contribuição, **não** altere `VERSION` (quem define a versão é o mantenedor). Já o `pack-manifest.json` precisa estar em dia para o CI passar: depois de mexer em agente, skill, hook ou doc do pack, rode `bash .claude/skills/team-os-creator/scripts/pack-manifest.sh`.

## Antes de abrir um PR

1. **Agentes** — crie ou altere com `/team-os-creator` (`*create`, `*squad`, `*migrate`). Depois rode:
   ```bash
   bash .claude/skills/team-os-creator/scripts/validate-agent.sh
   ```
   Zero erros é obrigatório. O bloco `## Native Teams Protocol` é byte-idêntico em todos os agentes — para trocá-lo use `scripts/migrate-ntp.sh`, nunca edite à mão.
2. **Skills** — cada skill vive em `.claude/skills/<nome>/SKILL.md` com frontmatter `name` (= pasta), `description` (uma linha, ≤ 400 caracteres, em português), `version` e `updated` (com aspas). Skill importada de terceiros entra também em `THIRD_PARTY_NOTICES.md`. Lint:
   ```bash
   bash .claude/skills/team-os-creator/scripts/validate-agent.sh --skills
   ```
3. **Hooks** — qualquer mudança em `.claude/hooks/*.sh` precisa passar em:
   ```bash
   bash .claude/skills/team-os-creator/scripts/test-hooks.sh
   ```
   Scripts devem continuar compatíveis com bash 3.2 (macOS): sem `mapfile`, `${x,,}`, `declare -A`, `grep -P`.
4. **Página de agentes** — após mudar agente ou skill, regenere:
   ```bash
   python3 .claude/skills/team-os-creator/scripts/generate-agents-page.py
   ```
   e o manifest do pack: `bash .claude/skills/team-os-creator/scripts/pack-manifest.sh`.
5. **Testes do `*update` e da propagação** — se você mexeu em `update-pack.*`, `pack-manifest.sh`, `install-to-project.sh` ou `propagate-sync.py`, rode também `test-update.sh` e `test-propagate.sh` (o segundo precisa de `rsync`). Em PR, deixe o `CHANGELOG.md` em `[Não lançado]` descrevendo a mudança.
6. **README** — contagens e tabelas (agentes por squad, política de modelos, presets) devem bater com os arquivos. O CI confere.

## Convenções

- **Commits** (de quem contribui via PR): Conventional Commits em português (`feat(squad): …`, `fix(team-os): …`, `docs: …`). Um commit por assunto.
- **Smart-memory**: `docs/smart-memory/agents/<squad>/<área>/` por agente; `stories/BACKLOG.md` + `stories/{backlog,active,in-review,done}/`.
- **Modelos**: `opus` fixo em architects/planners, QA e strategists; `inherit` nos demais.
- **Nada específico de empresa ou máquina**: exemplos usam `<Negócio> | <Projeto>`; caminhos de máquina vão em `.claude/settings.local.json` (gitignored).
- **Idioma**: português do Brasil em descrições, títulos e documentação; termos técnicos podem ficar em inglês.

## Fluxo

```
editar no CT → validate-agent.sh → test-hooks.sh → generate-agents-page.py → pack-manifest.sh → commit (no seu fork) → Pull Request
```

Depois do merge, o mantenedor registra no CHANGELOG e faz o release ([MAINTAINERS.md](./MAINTAINERS.md)); quem usa o pack recebe a versão nova com `/team-os-creator *update`.
