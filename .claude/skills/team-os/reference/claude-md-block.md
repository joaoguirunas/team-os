# Bloco canônico — Smart-Memory Protocol para o CLAUDE.md do projeto

> Este arquivo é a **única fonte** do bloco injetado no `CLAUDE.md` de cada projeto pela Fase 2-E do `/team-os` (e verificado na Fase 0). Injete o conteúdo abaixo **verbatim** — do primeiro `## Smart-Memory Protocol` até o fim — se e somente se o `CLAUDE.md` do projeto ainda não contém a seção `## Smart-Memory Protocol`. Nunca duplicar; nunca injetar versões editadas.

---

## Smart-Memory Protocol

Este projeto mantém sua base de conhecimento em `docs/smart-memory/` (formato Obsidian). Ela é a **fonte de verdade** de contexto do projeto — toda sessão, agente ou teammate a lê e a alimenta. Contrato mínimo:

**Leitura em camadas (summary-first — obrigatório):**
1. **L0** — ao iniciar: ler `docs/smart-memory/INDEX.md` + o `DIGEST.md` da sua área (`agents/<área>/DIGEST.md`) + as stories ativas (`stories/active/*.md`). Nada além disso no bootstrap.
2. **L1** — para achar contexto além do L0: buscar pelos summaries com
   `bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/sm-find.sh" "<termo>"`
   (saída: `path / kind / status / summary`) — nunca abrir arquivos para "procurar".
3. **L2** — ler a nota inteira **só** quando o `summary` retornado confirma relevância — **máximo 3 notas por tarefa**.
4. ⛔ **NUNCA** ler pastas inteiras nem `docs/smart-memory/_archive/` (conteúdo frio; só sob apontamento explícito de um LEDGER/DIGEST).

**Escrita:**
- Durante a sessão, escreva preferencialmente em `docs/smart-memory/_inbox/<agente>-<data>.md` (notas rápidas; a consolidação nos DIGESTs acontece no `/team-os *compact`).
- Fatos no `DIGEST.md` são **atômicos e datados**; fato novo **SUBSTITUI** a linha antiga (supersedes) — nunca acumular versões da mesma verdade.
- Notas temporárias levam `expires:` no frontmatter (TTL — arquivadas automaticamente no `*compact`).
- Frontmatter obrigatório em toda nota: `kind`, `status`, `summary` (+ `expires`/`supersedes` quando aplicável). Wikilinks `[[...]]` para navegação.

**Git:** ⛔ worktrees e branches novas são **proibidos** — nunca `isolation: worktree`, EnterWorktree ou `git worktree add`; todo trabalho (lead e agentes) acontece **diretamente na branch ativa**. Conflito entre agentes se resolve com ownership disjunto de arquivos, nunca com isolamento.
