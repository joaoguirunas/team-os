---
name: dev-git-workflow
description: Git workflow para projetos de software complexo — branch strategy, conventional commits, PR templates, merge flows e regras de autoridade.
version: "1.1"
updated: "2026-04-21"
---

# Git Workflow — Software Complexo

## Branch Strategy

```
main             → produção, protegida, sempre estável
├── feature/     → novas features (ex: feature/42-user-auth)
├── fix/         → bugfixes (ex: fix/login-null-pointer)
├── hotfix/      → urgente produção, parte de main
└── chore/       → deps, config, infra
```

**Nomenclatura:** `{type}/{issue-id}-{slug}` — ex: `feature/42-user-authentication`

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

**Garantia técnica:** Os agentes `dev-dev-alpha`, `dev-dev-beta`, `dev-dev-gamma` e `dev-dev-delta` têm o hook `~/.claude/hooks/block-git-push.sh` configurado via `PreToolUse`. Qualquer tentativa de `git push` nesses agentes é bloqueada automaticamente antes de executar — não é apenas uma regra no prompt, é uma barreira técnica.

Se `git push` for necessário em algum desses agentes, o fluxo correto é:
1. Dev completa o commit local
2. Dev notifica Chief via SendMessage
3. Chief delega ao Grav (dev-devops)
4. Grav executa os quality gates e faz o push

## Worktree por Dev

Cada dev trabalha em worktree isolado — zero conflito entre agentes paralelos:

```bash
# Dev Alpha inicia story-2.1
git worktree add ../worktrees/story-2.1 -b feature/story-2.1

# Dev Beta inicia story-2.2 simultaneamente
git worktree add ../worktrees/story-2.2 -b feature/story-2.2
```

DevOps (Grav) remove worktrees após merge:
```bash
git worktree remove ../worktrees/story-2.1
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
