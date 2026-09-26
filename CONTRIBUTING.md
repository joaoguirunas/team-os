# Contribuindo com o team-os

Este repositório é a **fonte da verdade** dos agentes, skills e hooks. Tudo é editado aqui e propagado aos projetos destino com `/team-os-creator *propagate`. Nunca edite um agente diretamente num projeto destino.

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
5. **README** — contagens e tabelas (agentes por squad, política de modelos, presets) devem bater com os arquivos. O CI confere.

## Convenções

- **Commits**: Conventional Commits em português (`feat(squad): …`, `fix(team-os): …`, `docs: …`). Um commit por assunto.
- **Smart-memory**: `docs/smart-memory/agents/<squad>/<área>/` por agente; `stories/BACKLOG.md` + `stories/{backlog,active,in-review,done}/`.
- **Modelos**: `opus` fixo em architects/planners, QA e strategists; `inherit` nos demais.
- **Nada específico de empresa ou máquina**: exemplos usam `<Negócio> | <Projeto>`; caminhos de máquina vão em `.claude/settings.local.json` (gitignored).
- **Idioma**: português do Brasil em descrições, títulos e documentação; termos técnicos podem ficar em inglês.

## Fluxo

```
editar no CT → validate-agent.sh → test-hooks.sh → generate-agents-page.py → commit → *propagate → commit por projeto
```
