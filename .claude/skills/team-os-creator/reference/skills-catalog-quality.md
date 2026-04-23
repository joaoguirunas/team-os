# Curadoria skills.sh — autores e filtros de qualidade

O catálogo skills.sh é um índice aberto — qualquer um publica. Muita coisa é clickbait sem substância. Esse arquivo documenta os filtros que `search-skills.sh` aplica pra só sugerir skills de qualidade.

## Critérios automáticos

Uma skill passa o filtro se **qualquer** dos seguintes é verdadeiro:

1. Autor está na lista branca (abaixo)
2. Install count ≥ 1500

Threshold de 1500 foi empírico — abaixo disso o catálogo tem muito ruído.

---

## Autores trusted (whitelist)

Skills desses autores passam automaticamente, independente do install count:

| Autor | Motivo |
|---|---|
| `vercel-labs` | Equipe oficial Vercel. Skills sobre React, Next, design, composition patterns. |
| `supabase` | Equipe oficial Supabase. Skills de Postgres, RLS, auth. |
| `anthropic` | Skills oficiais da Anthropic. |
| `microsoft` | Equipe MS — Playwright, TypeScript patterns, Fabric. |
| `figma` | Skills oficiais Figma (MCP, tokens). |
| `better-auth` | Maintainers do better-auth — skills de OAuth e auth patterns. |
| `shadcn` | Maintainer do shadcn/ui — skill oficial do component lib. |
| `wshobson` | Autor reconhecido de padrões (ADRs, error-handling). Muitas skills top. |
| `addyosmani` | Ex-Google, referência em web quality/performance. |
| `kepano` | Criador do Obsidian — skills de markdown e PKM. |
| `playwright` | Equipe oficial Playwright. |

Adicionar autor nessa lista exige: ≥ 3 skills publicadas + pelo menos 1 com > 5k installs OU presença pública reconhecida (maintainer conhecido).

---

## Mapeamento role → keywords de busca

Quando um archetype precisa de skills, usar os keywords correspondentes no `search-skills.sh <keyword>`:

| Archetype/Role | Keywords |
|---|---|
| `architect` | `adr`, `architecture`, `system-design`, `openapi`, `planning` |
| `implementer` (frontend) | `react`, `next`, `tailwind`, `shadcn`, `ui-patterns` |
| `implementer` (backend) | `api`, `openapi`, `security`, `auth`, `fastify`, `hono` |
| `implementer` (fullstack) | `oauth`, `auth`, `fullstack`, `edge-functions` |
| `hardening` | `error-handling`, `circuit-breaker`, `resilience`, `retry` |
| `reviewer` (QA) | `testing`, `playwright`, `security-review`, `code-review` |
| `reviewer` (security) | `security`, `owasp`, `audit`, `vulnerability` |
| `researcher` | `deep-research`, `tavily`, `research` |
| `data` | `postgres`, `supabase`, `prisma`, `schema`, `migration` |
| `devops` | `git`, `ci-cd`, `github-actions`, `conventional-commits` |
| `ux` | `accessibility`, `wcag`, `design-system`, `figma`, `ui-ux` |

---

## Skills já validadas (pré-aprovadas — dispensar buscar)

Skills que já passaram review humano e são seguras de propor direto:

| Skill | Slug de instalação | Para archetype |
|---|---|---|
| UI/UX Pro Max | `nextlevelbuilder/ui-ux-pro-max-skill@ui-ux-pro-max` | ux |
| Accessibility (Addy) | `addyosmani/web-quality-skills@accessibility` | ux, reviewer |
| Web Design Guidelines | `vercel-labs/agent-skills@web-design-guidelines` | ux, implementer(frontend) |
| Architecture Decision Records | `wshobson/agents@architecture-decision-records` | architect |
| Error Handling Patterns | `wshobson/agents@error-handling-patterns` | hardening |
| Deep Research | `199-biotechnologies/claude-deep-research-skill@deep-research` | researcher |
| Obsidian Markdown | `kepano/obsidian-skills@obsidian-markdown` | architect, researcher, any docs |
| Supabase Postgres Best Practices | `supabase/agent-skills@supabase-postgres-best-practices` | data |
| Next Best Practices | `vercel-labs/next-skills@next-best-practices` | implementer(frontend Next) |
| Tailwind v4 + Shadcn | `jezweb/claude-skills@tailwind-v4-shadcn` | implementer(frontend) |
| Security Review | `zackkorman/skills@security-review` | reviewer |
| QA Test Planner | `softaworks/agent-toolkit@qa-test-planner` | reviewer |
| Git Commit | `github/awesome-copilot@git-commit` | devops |
| GitHub CLI | `github/awesome-copilot@gh-cli` | devops |

---

## Red flags (descartar mesmo se passar no filtro automático)

Sinais de skill fraca que `search-skills.sh` pode não detectar — humano (ou a skill team-os-creator no prompt) deve descartar:

- SKILL.md com < 100 palavras
- Descrição genérica sem verbos de ação
- Só um script sem referências ou templates
- Último commit do repo > 12 meses
- Nenhuma issue ou PR — repo morto

A skill deve ler SKILL.md da candidata ANTES de sugerir ao usuário, pra sanity check dessas red flags. Se achar algo suspeito, excluir da lista proposta.
