#!/usr/bin/env bash
# discovery.sh — Smart-Memory Discovery Engine (self-contained)
# Analisa o codebase real e gera uma docs/smart-memory/ POPULADA (não scaffolding vazio).
# Roda nos projetos (onde só existe a skill team-os). Sem dependências externas (jq não exigido).
#
# Usage: discovery.sh [--target <dir>] [--force] [--dry-run]
#   --target <dir>  raiz do projeto (default: git root ou pwd)
#   --force         sobrescreve docs/smart-memory/ existente
#   --dry-run       mostra o que faria, sem escrever
#
# Saída: cria docs/smart-memory/{INDEX.md, project/, modules/, architecture/, decisions/,
#        stories/{backlog,active,in-review,done}, research/, qa/} com conteúdo detectado.
# Pontos narrativos (domínio/propósito) ficam marcados com <!-- TODO --> para o agente enriquecer.

# NB: sem `set -e` — o script usa muitos `teste && add ...` cujo lado esquerdo
# falha de propósito quando um arquivo não existe (isso não é erro).

TARGET=""; FORCE=0; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --force)  FORCE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    *) shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  TARGET="$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
TARGET="$(cd "$TARGET" && pwd)"
SM="$TARGET/docs/smart-memory"
DATE="$(date +%F)"
PROJECT_NAME="$(basename "$TARGET")"

echo "DISCOVERY target=$TARGET"

if [ -d "$SM" ] && [ "$FORCE" -ne 1 ] && [ "$DRY" -ne 1 ]; then
  echo "ABORT: docs/smart-memory já existe. Use --force para sobrescrever." >&2
  exit 2
fi

# ── Helpers de detecção (dependency-free) ────────────────────────────────────
hasf() { [ -e "$TARGET/$1" ]; }
# $1 é o token de grep já com as aspas necessárias, ex: '"next"' ou '"@remix-run'
pkg_has() { [ -f "$TARGET/package.json" ] && grep -q -- "$1" "$TARGET/package.json"; }
pyreq_has() { grep -riq -- "$1" "$TARGET/requirements.txt" "$TARGET/pyproject.toml" "$TARGET/setup.py" 2>/dev/null; }

LANGS=""; FRAMEWORKS=""; STYLING=""; DB=""; TESTING=""; TOOLING=""; PKG_MGR=""
add() { eval "$1=\"\$$1\${$1:+, }$2\""; }

# Linguagens / runtimes
hasf package.json && add LANGS "Node.js / JavaScript"
{ pkg_has '"typescript"' || hasf tsconfig.json; } && add LANGS "TypeScript"
{ hasf pyproject.toml || hasf requirements.txt || hasf setup.py; } && add LANGS "Python"
hasf go.mod && add LANGS "Go"
hasf Cargo.toml && add LANGS "Rust"
hasf Gemfile && add LANGS "Ruby"
hasf composer.json && add LANGS "PHP"
{ hasf pom.xml || hasf build.gradle; } && add LANGS "Java/JVM"

# Frameworks JS
pkg_has '"next"' && add FRAMEWORKS "Next.js"
pkg_has '"nuxt"' && add FRAMEWORKS "Nuxt"
pkg_has '"@remix-run' && add FRAMEWORKS "Remix"
pkg_has '"astro"' && add FRAMEWORKS "Astro"
pkg_has '"react"' && ! pkg_has '"next"' && add FRAMEWORKS "React"
pkg_has '"vue"' && add FRAMEWORKS "Vue"
pkg_has '"svelte"' && add FRAMEWORKS "Svelte"
pkg_has '"@angular/core"' && add FRAMEWORKS "Angular"
pkg_has '"express"' && add FRAMEWORKS "Express"
pkg_has '"fastify"' && add FRAMEWORKS "Fastify"
pkg_has '"@nestjs/core"' && add FRAMEWORKS "NestJS"
pkg_has '"vite"' && add FRAMEWORKS "Vite"
# Frameworks Python
pyreq_has fastapi && add FRAMEWORKS "FastAPI"
pyreq_has django && add FRAMEWORKS "Django"
pyreq_has flask && add FRAMEWORKS "Flask"

# Styling / UI
pkg_has '"tailwindcss"' && add STYLING "Tailwind CSS"
pkg_has '"styled-components"' && add STYLING "styled-components"
{ pkg_has '"@radix-ui' || hasf components.json; } && add STYLING "shadcn/ui · Radix"
pkg_has '"@mui/material"' && add STYLING "MUI"

# DB / ORM
{ hasf prisma/schema.prisma || pkg_has '"prisma"'; } && add DB "Prisma"
pkg_has '"drizzle-orm"' && add DB "Drizzle"
{ pkg_has '"@supabase/supabase-js"' || hasf supabase; } && add DB "Supabase"
pkg_has '"mongoose"' && add DB "MongoDB/Mongoose"
{ pkg_has '"pg"' || pkg_has '"postgres"'; } && add DB "PostgreSQL"
pyreq_has sqlalchemy && add DB "SQLAlchemy"

# Testing
pkg_has '"vitest"' && add TESTING "Vitest"
pkg_has '"jest"' && add TESTING "Jest"
pkg_has '"@playwright/test"' && add TESTING "Playwright"
pkg_has '"cypress"' && add TESTING "Cypress"
pyreq_has pytest && add TESTING "pytest"

# Tooling
hasf tsconfig.json && add TOOLING "tsconfig.json"
{ hasf .eslintrc || hasf .eslintrc.js || hasf .eslintrc.json || hasf eslint.config.js || hasf eslint.config.mjs; } && add TOOLING "ESLint"
{ hasf .prettierrc || hasf .prettierrc.json || hasf prettier.config.js; } && add TOOLING "Prettier"
{ hasf Dockerfile || hasf docker-compose.yml || hasf compose.yaml; } && add TOOLING "Docker"
hasf .github/workflows && add TOOLING "GitHub Actions"
hasf vercel.json && add TOOLING "Vercel"
hasf netlify.toml && add TOOLING "Netlify"
hasf turbo.json && add TOOLING "Turborepo"

# Gerenciador de pacotes
hasf pnpm-lock.yaml && PKG_MGR="pnpm"
[ -z "$PKG_MGR" ] && hasf yarn.lock && PKG_MGR="yarn"
[ -z "$PKG_MGR" ] && hasf bun.lockb && PKG_MGR="bun"
[ -z "$PKG_MGR" ] && hasf package-lock.json && PKG_MGR="npm"

# Monorepo?
MONOREPO="não"
{ hasf turbo.json || hasf pnpm-workspace.yaml || { hasf package.json && grep -q '"workspaces"' "$TARGET/package.json"; }; } && MONOREPO="sim"

# ── Mapa de módulos ──────────────────────────────────────────────────────────
MODULE_DIRS=""
for base in src app lib packages apps server api components services modules; do
  [ -d "$TARGET/$base" ] || continue
  # Diretórios de 1º nível dentro do base
  while IFS= read -r d; do
    [ -n "$d" ] && MODULE_DIRS="$MODULE_DIRS$base/$d\n"
  done <<EOF2
$(find "$TARGET/$base" -maxdepth 1 -mindepth 1 -type d -not -name 'node_modules' -exec basename {} \; 2>/dev/null | sort)
EOF2
done

# ── Dry-run: só reporta ──────────────────────────────────────────────────────
if [ "$DRY" -eq 1 ]; then
  echo "--- DRY-RUN ---"
  echo "Linguagens : ${LANGS:-(nenhuma detectada)}"
  echo "Frameworks : ${FRAMEWORKS:-—}"
  echo "Styling/UI : ${STYLING:-—}"
  echo "DB/ORM     : ${DB:-—}"
  echo "Testing    : ${TESTING:-—}"
  echo "Tooling    : ${TOOLING:-—}"
  echo "Pkg manager: ${PKG_MGR:-—}  ·  Monorepo: $MONOREPO"
  echo "Módulos    :"
  printf "%b" "$MODULE_DIRS" | sed 's/^/  - /'
  exit 0
fi

# ── Geração ──────────────────────────────────────────────────────────────────

# Links de módulos para o INDEX (limpos)
MODULES_LINKS="$(printf "%b" "$MODULE_DIRS" | while IFS= read -r m; do
  [ -n "$m" ] || continue
  safe="$(echo "$m" | sed 's#/#-#g')"
  echo "- [[modules/$safe]] — \`$m\`"
done)"
[ -z "$MODULES_LINKS" ] && MODULES_LINKS="<!-- nenhum módulo detectado automaticamente -->"

mkdir -p "$SM"/project "$SM"/modules "$SM"/architecture "$SM"/decisions \
         "$SM"/stories/backlog "$SM"/stories/active "$SM"/stories/in-review "$SM"/stories/done \
         "$SM"/research "$SM"/qa

# INDEX.md (MOC raiz)
cat > "$SM/INDEX.md" <<EOF
---
title: "Smart-Memory — $PROJECT_NAME"
type: index
agent: team-os (discovery)
created: $DATE
updated: $DATE
tags: [index, smart-memory]
---

# Smart-Memory — $PROJECT_NAME

> Gerado pelo Discovery Engine do team-os em $DATE a partir do codebase. Enriqueça os pontos marcados com \`<!-- TODO -->\`.

## Projeto
- [[project/overview]] — Visão geral
- [[project/tech-stack]] — Stack tecnológico (detectado)
- [[project/conventions]] — Padrões de código

## Arquitetura
- [[architecture/overview]] — Visão arquitetural

## Módulos
$MODULES_LINKS

## Stories
- [[stories/BACKLOG]] — Backlog master

## Research / QA
- [[research/]] · [[qa/]]
EOF

# project/overview.md
cat > "$SM/project/overview.md" <<EOF
---
title: "Visão Geral — $PROJECT_NAME"
type: overview
agent: team-os (discovery)
created: $DATE
updated: $DATE
tags: [project]
---

# Visão Geral — $PROJECT_NAME

**Domínio / propósito:** <!-- TODO: o que este projeto faz e para quem (o discovery não infere isso do código) -->

**Stack resumido:** ${FRAMEWORKS:-${LANGS:-—}}${DB:+ · $DB}

**Tipo:** $([ "$MONOREPO" = "sim" ] && echo "Monorepo" || echo "Repositório único")

## Estado atual
<!-- TODO: maturidade, o que já existe, o que está em construção -->
EOF

# project/tech-stack.md
cat > "$SM/project/tech-stack.md" <<EOF
---
title: "Tech Stack — $PROJECT_NAME"
type: overview
agent: team-os (discovery)
created: $DATE
updated: $DATE
tags: [project, tech-stack]
---

# Tech Stack (detectado)

| Categoria | Detectado |
|---|---|
| Linguagens | ${LANGS:-—} |
| Frameworks | ${FRAMEWORKS:-—} |
| Styling / UI | ${STYLING:-—} |
| Banco / ORM | ${DB:-—} |
| Testes | ${TESTING:-—} |
| Tooling | ${TOOLING:-—} |
| Pkg manager | ${PKG_MGR:-—} |
| Monorepo | $MONOREPO |

> Detectado automaticamente dos manifestos do projeto. Confirme/complete o que faltar.
EOF

# project/conventions.md
cat > "$SM/project/conventions.md" <<EOF
---
title: "Convenções — $PROJECT_NAME"
type: overview
agent: team-os (discovery)
created: $DATE
updated: $DATE
tags: [project, conventions]
---

# Convenções de código

- **Gerenciador de pacotes:** ${PKG_MGR:-—}
- **TypeScript:** $(hasf tsconfig.json && echo "sim (tsconfig.json presente)" || echo "—")
- **Lint/format:** $(echo "$TOOLING" | grep -o 'ESLint\|Prettier' | paste -sd' · ' - 2>/dev/null || echo "—")
- **Estrutura:** $([ "$MONOREPO" = "sim" ] && echo "monorepo (workspaces)" || echo "app único")

## Padrões observados
<!-- TODO: naming, organização de pastas, padrões de import, etc. (enriquecer ao explorar) -->
EOF

# architecture/overview.md
cat > "$SM/architecture/overview.md" <<EOF
---
title: "Arquitetura — $PROJECT_NAME"
type: overview
agent: team-os (discovery)
created: $DATE
updated: $DATE
tags: [architecture]
---

# Arquitetura — $PROJECT_NAME

\`\`\`mermaid
flowchart TD
  user[Usuário] --> app[$PROJECT_NAME]
$(printf "%b" "$MODULE_DIRS" | sed 's#.*/##' | awk 'NF{printf "  app --> m_%s[%s]\n", NR, $0}')
\`\`\`

<!-- TODO: refinar o diagrama com as relações reais entre os módulos -->
EOF

# modules/*.md (um por módulo detectado)
printf "%b" "$MODULE_DIRS" | while IFS= read -r mod; do
  [ -n "$mod" ] || continue
  safe="$(echo "$mod" | sed 's#/#-#g')"
  files="$(find "$TARGET/$mod" -maxdepth 1 -mindepth 1 -not -name 'node_modules' -exec basename {} \; 2>/dev/null | sort | head -20)"
  cat > "$SM/modules/$safe.md" <<EOF
---
title: "Módulo: $mod"
type: overview
agent: team-os (discovery)
created: $DATE
updated: $DATE
tags: [module]
---

# Módulo: \`$mod\`

**Responsabilidade:** <!-- TODO: o que este módulo faz -->

## Itens (1º nível)
$(printf "%s\n" "$files" | sed 's/^/- `/; s/$/`/')
EOF
done

# stories/BACKLOG.md
cat > "$SM/stories/BACKLOG.md" <<EOF
---
title: "Backlog — $PROJECT_NAME"
type: backlog
agent: team-os (discovery)
created: $DATE
updated: $DATE
tags: [backlog]
---

# Backlog

| Story | Título | Complexidade | Status | Owner |
|---|---|---|---|---|
<!-- architect adiciona stories aqui -->
EOF

# Conta o que foi gerado
MOD_COUNT="$(printf "%b" "$MODULE_DIRS" | grep -c . || true)"
echo "DONE: smart-memory gerada em $SM"
echo "  módulos mapeados: ${MOD_COUNT:-0}"
echo "  stack: ${FRAMEWORKS:-${LANGS:-—}}${DB:+ · $DB}"
echo "PRÓXIMO: o agente enriquece os <!-- TODO --> (domínio, responsabilidades) e o architect cria stories."
