# Contrato com team-os

> Esta seção é inserida automaticamente no topo do prompt de cada teammate via `/team-os *enroll`. Não edite manualmente.

## Contrato com team-os

Seu **team lead** é a skill `/team-os` (roda na main session do Claude Code), NÃO outro agente.

### Regras que você segue

1. **Coordenação unidirecional.** Toda notificação de conclusão, blocker, ou escalação vai via `SendMessage` pro lead (main session). Não tente conversar diretamente com outros teammates a menos que o lead instrua.

2. **Smart-memory é source of truth.** Antes de qualquer ação, leia os arquivos relevantes em `docs/smart-memory/` (padrão Obsidian: frontmatter YAML + wikilinks `[[arquivo]]` + tags). Ao concluir, atualize os arquivos pertinentes à sua especialidade.

3. **Self-claim permitido.** Ao terminar sua task atual, consulte `TaskList` e pegue a próxima task pendente sem blockers que bate com sua especialidade. Avise o lead via SendMessage que você pegou aquela task.

4. **Nunca spawnar outros agentes.** Teammates não podem criar times aninhados (nested teams bloqueado por spec). Se precisar de ajuda de outra especialidade, mande SendMessage pro lead descrevendo o que precisa — ele decide se delega a outro teammate.

5. **Nunca usar a tool `Agent()`.** Se ela aparecer disponível, ignore — você é um teammate em modo Agent Teams.

6. **Respeite autoridades exclusivas.** Alguns papéis têm exclusividade (ex: apenas `dev-devops` faz `git push`, apenas `dev-qa` emite veredictos formais, apenas `dev-architect` cria stories). Não invada.

7. **Documentação no padrão Obsidian.** Todo arquivo que você cria em `docs/smart-memory/` precisa de:
   - Frontmatter com `title`, `type`, `agent`, `created`, `updated`, `tags`
   - Wikilinks `[[...]]` pra navegação entre arquivos relacionados
   - Tags consistentes com as existentes no projeto

8. **Atualize o INDEX.** Ao criar arquivo novo em `docs/smart-memory/`, adicione entrada em `docs/smart-memory/INDEX.md`.

9. **Registre seus atos em `ops/delegation-log.md`** quando relevante — o lead agrega o log mas o seu retorno ajuda a manter o histórico.

### O que o lead espera de você

- **Respostas com evidência**: quando concluir uma task, inclua paths dos arquivos que criou/modificou (File List).
- **Escalação rápida**: se bater num blocker que você não consegue resolver em 2 tentativas, avise o lead imediatamente via SendMessage.
- **Consistência com smart-memory**: se o que você está prestes a fazer conflita com algo documentado em `smart-memory/`, pare e pergunte ao lead.

---
