#!/usr/bin/env bash
# discovery.sh — Smart-Memory Discovery Engine (self-contained)
# Analisa o codebase real e gera uma docs/smart-memory/ POPULADA (não scaffolding vazio).
# Roda nos projetos (onde só existe a skill team-os). Sem dependências externas (jq não exigido).
#
# Usage: discovery.sh [--target <dir>] [--force] [--repair] [--dry-run] [--areas "a,b,c"]
#   --target <dir>   raiz do projeto (default: git root ou pwd)
#   --force          sobrescreve docs/smart-memory/ existente — MAS antes faz backup de
#                    cada arquivo que vai sobrescrever em _archive/pre-force-<data>/
#   --repair         cria SÓ o que falta (pastas/DIGESTs/INDEX/arquivos ausentes);
#                    nunca sobrescreve nada existente
#   --dry-run        mostra o que faria, sem escrever
#   --areas "a,b,c"  override manual das áreas de agents/ (ignora a detecção por squad)
#
# Áreas de agents/: derivadas das squads INSTALADAS no projeto (ls .claude/agents/ do target):
#   dev     → research, qa, ux, bi, data-engineer, data-performance
#   sites   → research, qa, ux, data
#   social  → content, design, photo, video, publisher
#   traffic → traffic, qa, copy, automation
#   pm      → portfolio, qa, processos
# Squads combinam (união). Sem .claude/agents/ → fallback (dev).
#
# Saída: cria docs/smart-memory/{INDEX.md, project/, decisions/,
#        stories/{backlog,active,in-review,done}, agents/<área>/, _inbox/, _archive/}
#        com conteúdo detectado (architecture e modules vivem como arquivos em project/).
# Pontos narrativos (domínio/propósito) ficam marcados com <!-- TODO --> para o agente enriquecer.

# NB: sem `set -e` — o script usa muitos `teste && add ...` cujo lado esquerdo
# falha de propósito quando um arquivo não existe (isso não é erro).

TARGET=""; FORCE=0; DRY=0; REPAIR=0; AREAS_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "ERRO: --target requer um valor (diretório do projeto)" >&2
        exit 2
      fi
      TARGET="$2"; shift 2 ;;
    --force)  FORCE=1; shift ;;
    --repair) REPAIR=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --areas)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "ERRO: --areas requer um valor (lista \"a,b,c\")" >&2
        exit 2
      fi
      AREAS_OVERRIDE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ "$FORCE" -eq 1 ] && [ "$REPAIR" -eq 1 ]; then
  echo "ERRO: --force e --repair são mutuamente exclusivos." >&2
  exit 2
fi

if [ -z "$TARGET" ]; then
  TARGET="$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
# Guarda: se o cd falhar (typo no path), TARGET viraria vazio e o script
# tentaria criar /docs/smart-memory na raiz do filesystem. Abortar limpo.
TARGET_RESOLVED="$(cd "$TARGET" 2>/dev/null && pwd)"
if [ -z "$TARGET_RESOLVED" ] || [ ! -d "$TARGET_RESOLVED" ]; then
  echo "ERRO: target não existe ou não é acessível: $TARGET" >&2
  exit 2
fi
TARGET="$TARGET_RESOLVED"
SM="$TARGET/docs/smart-memory"
DATE="$(date +%F)"
PROJECT_NAME="$(basename "$TARGET")"

echo "DISCOVERY target=$TARGET"

if [ -d "$SM" ] && [ "$FORCE" -ne 1 ] && [ "$REPAIR" -ne 1 ] && [ "$DRY" -ne 1 ]; then
  echo "ABORT: docs/smart-memory já existe. Use --repair (cria só o que falta) ou --force (sobrescreve com backup)." >&2
  exit 2
fi

# ── Escrita segura (repair nunca sobrescreve; force faz backup antes) ─────────
BACKUP_DIR="$SM/_archive/pre-force-$DATE"

# want <path> → retorna 0 se o arquivo deve ser (re)escrito.
#   --repair : escreve só se NÃO existir.
#   --force  : faz backup do existente em _archive/pre-force-<data>/ e escreve.
#   fresh    : escreve.
want() { # $1=path-absoluto-dentro-da-SM
  local p="$1" rel
  if [ -e "$p" ]; then
    if [ "$REPAIR" -eq 1 ]; then
      return 1
    fi
    if [ "$FORCE" -eq 1 ]; then
      rel="${p#$SM/}"
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      cp "$p" "$BACKUP_DIR/$rel"
      echo "  backup: $rel → _archive/pre-force-$DATE/$rel"
    fi
  fi
  return 0
}

# ── Áreas de agents/ — derivadas das squads instaladas ────────────────────────
AREAS=""
add_area() { case " $AREAS " in *" $1 "*) : ;; *) AREAS="$AREAS${AREAS:+ }$1" ;; esac; }

squad_areas() { # $1=squad
  case "$1" in
    dev)     echo "research qa ux bi data-engineer data-performance" ;;
    sites)   echo "research qa ux data" ;;
    social)  echo "content design photo video publisher" ;;
    traffic) echo "traffic qa copy automation" ;;
    pm)      echo "portfolio qa processos" ;;
  esac
}

SQUADS_DETECTED=""
if [ -n "$AREAS_OVERRIDE" ]; then
  for a in $(echo "$AREAS_OVERRIDE" | tr ',' ' '); do
    [ -n "$a" ] && add_area "$a"
  done
  SQUADS_DETECTED="(override --areas)"
elif [ -d "$TARGET/.claude/agents" ]; then
  for sq in dev sites social traffic pm; do
    if ls "$TARGET/.claude/agents/$sq-"*.md >/dev/null 2>&1; then
      SQUADS_DETECTED="$SQUADS_DETECTED${SQUADS_DETECTED:+, }$sq"
      for a in $(squad_areas "$sq"); do add_area "$a"; done
    fi
  done
fi
if [ -z "$AREAS" ]; then
  # fallback: sem .claude/agents/ (ou sem squad reconhecida) → áreas da squad dev
  for a in $(squad_areas dev); do add_area "$a"; done
  [ -z "$SQUADS_DETECTED" ] && SQUADS_DETECTED="(fallback dev — sem .claude/agents/)"
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
  echo "Modo       : $([ "$REPAIR" -eq 1 ] && echo repair || { [ "$FORCE" -eq 1 ] && echo "force (com backup)" || echo create; })"
  echo "Squads     : ${SQUADS_DETECTED:-—}"
  echo "Áreas      : $AREAS"
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

mkdir -p "$SM"/project "$SM"/decisions \
         "$SM"/stories/backlog "$SM"/stories/active "$SM"/stories/in-review "$SM"/stories/done \
         "$SM"/_inbox "$SM"/_archive
for area in $AREAS; do
  mkdir -p "$SM/agents/$area"
done

# _inbox/ — anotações baratas durante a sessão; consolidação em lote no *compact
[ -e "$SM/_inbox/.gitkeep" ] || touch "$SM/_inbox/.gitkeep"

# DIGEST.md por área de agente — porta de entrada da leitura em camadas (L0).
# Formato v3: fatos atômicos datados (Core / Contexto recente / Apontadores).
for area in $AREAS; do
  DPATH="$SM/agents/$area/DIGEST.md"
  want "$DPATH" || continue
  cat > "$DPATH" <<EOF
---
kind: digest
area: $area
updated: $DATE
---
# DIGEST — $area

## Core (permanente)
<!-- fatos atômicos duráveis, 1 linha cada, com data. Fato novo SUBSTITUI o antigo. -->
- [$DATE] Área criada pelo discovery — sem fatos registrados ainda.

## Contexto recente (expira em ~14 dias se não renovado)
<!-- - [YYYY-MM-DD] {estado em andamento} -->

## Apontadores
<!-- - [[nota-relevante]] — por que importa (1 linha) -->

<!-- Regras: máx ~40 linhas por DIGEST · bullets ≤200 chars · nada de prosa.
     Fato novo SUBSTITUI o antigo (mesma linha, data nova) — não acumule histórico. -->
EOF
done

# _archive/ — arquivo morto (fora do working set). Nunca lido no bootstrap nem pelos agentes.
if want "$SM/_archive/README.md"; then
cat > "$SM/_archive/README.md" <<EOF
---
title: "Arquivo Morto (_archive)"
type: readme
agent: team-os (discovery)
created: $DATE
tags: [archive]
---

# _archive — conteúdo frio compactado

Esta pasta guarda o que saiu do **working set** da smart-memory via \`/team-os *compact\`:
stories concluídas, QA/planos antigos, logs append-only esfriados, notas expiradas (TTL)
e inbox já consolidado.

- **Não é lido** no bootstrap do team-os nem pelos agentes (o \`weigh-memory.sh\` o exclui do peso).
- Conteúdo **movido, nunca deletado** — nada se perde.
- Os LEDGERs (\`stories/done/LEDGER.md\` e \`_archive/LEDGER.md\`) indexam o que foi arquivado.
- Consulte um item aqui **só** quando um LEDGER apontar que você precisa dele.
EOF
fi

# Links nominais dos DIGESTs por área
AGENT_LINKS=""
for area in $AREAS; do
  AGENT_LINKS="${AGENT_LINKS}- [[agents/$area/DIGEST]] — resumo vivo da área $area
"
done

# Stories ativas existentes (repair/força em memória viva) — lista nominal
ACTIVE_LINKS=""
while IFS= read -r s; do
  [ -n "$s" ] || continue
  b="$(basename "$s" .md)"
  ACTIVE_LINKS="${ACTIVE_LINKS}- [[stories/active/$b]]
"
done <<EOF
$(find "$SM/stories/active" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
EOF
[ -z "$ACTIVE_LINKS" ] && ACTIVE_LINKS="<!-- sem stories ativas — o architect move stories para cá e as lista aqui -->
"

# INDEX.md (MOC raiz)
if want "$SM/INDEX.md"; then
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
- [[project/architecture]] — Visão arquitetural

## Módulos
- [[project/modules]] — Mapa de módulos + God Nodes

## Stories
- [[stories/BACKLOG]] — Backlog master

### Ativas
$ACTIVE_LINKS
## DIGESTs por área (porta de entrada L0)
$AGENT_LINKS
## Inbox
- \`_inbox/\` — anotações baratas da sessão; consolidadas em lote no \`*compact\` (archivist)
EOF
fi

# project/overview.md
if want "$SM/project/overview.md"; then
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
fi

# project/tech-stack.md
if want "$SM/project/tech-stack.md"; then
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
fi

# project/conventions.md
if want "$SM/project/conventions.md"; then
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
- **Lint/format:** $(lf="$(echo "$TOOLING" | grep -o 'ESLint\|Prettier' | awk '{ if (NR > 1) printf(" · "); printf("%s", $0) } END { print "" }')"; echo "${lf:-—}")
- **Estrutura:** $([ "$MONOREPO" = "sim" ] && echo "monorepo (workspaces)" || echo "app único")

## Padrões observados
<!-- TODO: naming, organização de pastas, padrões de import, etc. (enriquecer ao explorar) -->
EOF
fi

# project/architecture.md
if want "$SM/project/architecture.md"; then
cat > "$SM/project/architecture.md" <<EOF
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
fi

# project/modules.md (mapa de módulos + God Nodes — lido pelos implementers antes de codar)
if want "$SM/project/modules.md"; then
cat > "$SM/project/modules.md" <<EOF
---
title: "Módulos — $PROJECT_NAME"
type: overview
agent: team-os (discovery)
created: $DATE
updated: $DATE
tags: [modules]
---

# Mapa de Módulos — $PROJECT_NAME

$(printf "%b" "$MODULE_DIRS" | while IFS= read -r mod; do
  [ -n "$mod" ] || continue
  files="$(find "$TARGET/$mod" -maxdepth 1 -mindepth 1 -not -name 'node_modules' -not -name '.DS_Store' -not -name "Icon"$'\r' -exec basename {} \; 2>/dev/null | sort | head -12 | awk '{ if (NR > 1) printf(", "); printf("%s", $0) } END { print "" }')"
  printf '## \140%s\140\n**Responsabilidade:** <!-- TODO -->\n\n1º nível: %s\n\n' "$mod" "${files:-—}"
done)

## God Nodes
<!-- TODO: arquivos críticos / de alto acoplamento que exigem testes + QA formal ao serem tocados.
     Liste paths \`src/...\` aqui (um por linha). Os implementers grep esta seção antes de implementar. -->
EOF
fi

# stories/BACKLOG.md
if want "$SM/stories/BACKLOG.md"; then
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
fi

# Conta o que foi gerado
MOD_COUNT="$(printf "%b" "$MODULE_DIRS" | grep -c . || true)"
MODE_LABEL="create"
[ "$REPAIR" -eq 1 ] && MODE_LABEL="repair (só o que faltava)"
[ "$FORCE" -eq 1 ] && MODE_LABEL="force (sobrescrito com backup em _archive/pre-force-$DATE/)"
echo "DONE: smart-memory gerada em $SM  [modo: $MODE_LABEL]"
echo "  squads: ${SQUADS_DETECTED:-—}"
echo "  áreas de agents/: $AREAS"
echo "  módulos mapeados: ${MOD_COUNT:-0}"
echo "  stack: ${FRAMEWORKS:-${LANGS:-—}}${DB:+ · $DB}"
echo "PRÓXIMO: o agente enriquece os <!-- TODO --> (domínio, responsabilidades) e o architect cria stories."
