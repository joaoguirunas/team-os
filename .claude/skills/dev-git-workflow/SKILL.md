---
name: dev-git-workflow
description: Git workflow para projetos de software complexo — branch strategy, conventional commits, PR templates, merge flows e regras de autoridade.
version: "1.1"
updated: "2026-04-21"
---

# Git Workflow — Software Complexo

## Branch Strategy

> ⚠️ **Regra dura — branch de publicação:** antes de qualquer `push`/`PR`/`merge`, **pergunte em qual branch publicar; a `main` é o padrão prioritário.** Nunca crie branch nova nem assuma a branch atual por conta própria. Só use `feature/*` (ou outra) quando o usuário pedir explicitamente — nesse caso vale a nomenclatura abaixo.

```
main             → padrão de publicação, produção, sempre estável
├── feature/     → novas features SÓ quando o usuário pedir (ex: feature/42-user-auth)
├── fix/         → bugfixes sob demanda (ex: fix/login-null-pointer)
├── hotfix/      → urgente produção, parte de main
└── chore/       → deps, config, infra
```

**Nomenclatura (quando branch for solicitada):** `{type}/{issue-id}-{slug}` — ex: `feature/42-user-authentication`

## Conventional Commits

Formato: `type(scope): descrição imperativa em inglês`

| Type | Quando usar |
|---|---|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `refactor` | Mudança sem feature nem fix |
| `test` | Adicionar/corrigir testes |
| `chore` | Deps, config, build |
| `docs` | Documentação |
| `perf` | Melhoria de performance |
| `ci` | CI/CD |

**Exemplos:**
```
feat(auth): add JWT refresh token rotation
fix(api): handle null response from payment provider
test(auth): add token expiration edge cases
chore(deps): upgrade Next.js to 15.2.0
```

**Regras:**
- Imperativo, minúsculo, sem ponto final
- Scope identifica o módulo (`auth`, `api`, `ui`, `db`)
- Breaking change: `feat(api)!: rename user endpoint`
- Referenciar story no rodapé: `Story: docs/smart-memory/stories/active/2.3-titulo.md`

## Autoridade de Git

| Operação | Quem pode |
|---|---|
| `git add`, `git commit` | Todos os devs |
| `git branch`, `git checkout` | Todos os devs |
| `git diff`, `git log`, `git status` | Todos os agentes |
| `git merge` (local) | Todos os devs |
| **`git push`** | **EXCLUSIVO dev-devops (Grav)** |
| **`gh pr create/merge`** | **EXCLUSIVO dev-devops (Grav)** |

**Garantia técnica:** Os agentes `dev-dev-alpha`, `dev-dev-beta`, `dev-dev-gamma` e `dev-dev-delta` têm o hook `block-git-push.sh` configurado via `PreToolUse` no frontmatter. Qualquer tentativa de `git push` nesses agentes é bloqueada automaticamente antes de executar — não é apenas uma regra no prompt, é uma barreira técnica.

O hook está em `.claude/hooks/block-git-push.sh` no projeto e é referenciado diretamente no frontmatter de cada agente implementer via `$CLAUDE_PROJECT_DIR/.claude/hooks/block-git-push.sh`.

Se `git push` for necessário em algum desses agentes, o fluxo correto é:
1. Dev completa o commit local
2. Dev notifica lead via SendMessage
3. Lead delega ao Grav (dev-devops)
4. Grav executa os quality gates e faz o push

## Worktree por Dev

Cada dev trabalha em worktree isolado — zero conflito entre agentes paralelos.

### Isolamento automático via frontmatter (recomendado)

Agentes com `isolation: worktree` no frontmatter recebem worktree própria automaticamente ao serem spawnados como subagents. Não é necessário criar manualmente. Os agentes `dev-dev-alpha`, `dev-dev-beta`, `dev-dev-gamma` e `dev-dev-delta` já têm esse campo configurado.

### Isolamento manual (quando necessário controle explícito)

```bash
# Dev Alpha inicia story-2.1
git worktree add .claude/worktrees/story-2.1 -b feature/story-2.1

# Dev Beta inicia story-2.2 simultaneamente
git worktree add .claude/worktrees/story-2.2 -b feature/story-2.2
```

> Adicione `.claude/worktrees/` ao `.gitignore` para que worktrees não apareçam como untracked no checkout principal.

### Copiar arquivos gitignored (`.env`, secrets)

Crie `.worktreeinclude` na raiz do projeto para copiar automaticamente arquivos gitignored para cada nova worktree:

```text
# .worktreeinclude
.env
.env.local
config/secrets.json
```

Só arquivos que já estão no `.gitignore` são copiados — arquivos rastreados nunca são duplicados.

### Base branch da worktree

Por padrão worktrees partem de `origin/HEAD` (branch padrão remota, sempre limpa). Para partir do HEAD local (útil quando se quer incluir commits não publicados):

```json
// .claude/settings.json
{
  "worktree": {
    "baseRef": "head"
  }
}
```

### Sessões em background e worktrees

Sessões iniciadas com `claude --bg` ou via Agent View ganham worktree isolada automaticamente em `.claude/worktrees/`, sem necessidade de `--worktree`. Para desativar esse comportamento:

```json
{ "worktree": { "bgIsolation": "none" } }
```

### Remoção (responsabilidade do DevOps)

```bash
git worktree list
git worktree remove .claude/worktrees/story-2.1
git branch -d feature/story-2.1
```

## Merge Strategy

| Situação | Estratégia |
|---|---|
| Feature → main | Squash merge (histórico limpo) |
| Hotfix → main | Merge commit (rastreabilidade) |
| Chore/deps | Squash merge |

## PR Template

```markdown
## O que esta PR faz
{1-3 bullets descrevendo a mudança}

## Story
docs/smart-memory/stories/done/{story-id}.md

## Checklist
- [ ] `npm test` passando
- [ ] `npm run lint` sem erros
- [ ] `npm run typecheck` sem erros
- [ ] QA Gate: PASS (Axis)
- [ ] Docs atualizadas (se aplicável)

🤖 Generated with [Claude Code](https://claude.ai/claude-code)
```

## Quality Gates antes de push (responsabilidade de Grav)

```bash
npm run lint && npm run typecheck && npm test && npm run build
```

Todos devem passar. Se algum falhar, Grav notifica Chief e retorna ao dev responsável.

## Regras absolutas

- Nunca commitar `.env`, secrets ou credenciais
- Nunca force push em `main`
- Sempre `git status` antes de commitar
- Nunca `git add .` — sempre arquivos específicos
- Branch deletado após merge — zero branches stale
- **`git push` é exclusivo de Grav** — garantido por hook técnico nos agentes dev
