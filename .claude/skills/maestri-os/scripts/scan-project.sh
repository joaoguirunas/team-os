#!/usr/bin/env bash
# scan-project.sh — leitura READ-ONLY e limitada de um projeto irmão, para o mapa da Sala de Controle.
# Lê SÓ: .claude/agents/*.md (nome + description), .claude/skills/team-os (existe?),
# docs/smart-memory/INDEX.md e project/overview.md (resumo), docs/smart-memory/agents/* (áreas).
# Nunca lê código nem a pasta inteira. Nunca escreve nada.
# Usage: scan-project.sh <pasta>
# Output: KEY=value (uma por linha); agentes em linhas AGENT=<nome>\t<primeira frase da description>.

set -u

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "ERROR=missing_path|Usage: scan-project.sh <pasta>" >&2
  exit 2
fi
if [ ! -d "$TARGET" ]; then
  echo "ERROR=not_a_dir|PATH=$TARGET" >&2
  exit 1
fi
TARGET=$(cd "$TARGET" && pwd)

AGENTS_DIR="$TARGET/.claude/agents"
SM="$TARGET/docs/smart-memory"

echo "PATH=$TARGET"
echo "NAME=$(basename "$TARGET")"

# ── Agentes e squads ─────────────────────────────────────────────────────────
agent_count=0
squads=""
if [ -d "$AGENTS_DIR" ]; then
  agent_count=$(find "$AGENTS_DIR" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
  squads=$(find "$AGENTS_DIR" -maxdepth 1 -name '*.md' -type f -exec basename {} .md \; 2>/dev/null \
    | sed 's/-.*//' | sort -u | tr '\n' ',' | sed 's/,$//')
fi
echo "HAS_AGENTS=$([ "$agent_count" -gt 0 ] && echo 1 || echo 0)"
echo "AGENT_COUNT=$agent_count"
echo "SQUADS=${squads:-(sem agentes)}"

# Primeira frase da description do frontmatter (corta em ". " ou em 180 chars)
first_sentence() { # $1=arquivo
  awk '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---" { exit }
    /^description:/ {
      sub(/^description:[ ]*/, ""); gsub(/^["'"'"']|["'"'"']$/, "")
      print; exit
    }' "$1" \
  | sed -E 's/\. .*$/./' | cut -c1-180
}

if [ "$agent_count" -gt 0 ]; then
  for af in "$AGENTS_DIR"/*.md; do
    [ -f "$af" ] || continue
    printf 'AGENT=%s\t%s\n' "$(basename "$af" .md)" "$(first_sentence "$af")"
  done
fi

# ── team-os / smart-memory ───────────────────────────────────────────────────
echo "HAS_TEAM_OS=$([ -d "$TARGET/.claude/skills/team-os" ] && echo 1 || echo 0)"
echo "HAS_SMART_MEMORY=$([ -f "$SM/INDEX.md" ] && echo 1 || echo 0)"

areas=""
if [ -d "$SM/agents" ]; then
  areas=$(find "$SM/agents" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sort | tr '\n' ',' | sed 's/,$//')
fi
echo "AREAS=${areas:-}"

# ── Resumo do projeto ────────────────────────────────────────────────────────
# 1) summary: do frontmatter de project/overview.md
# 2) senão, primeira linha de prosa após o título "# " do overview
# 3) senão, summary: do INDEX.md
frontmatter_summary() { # $1=arquivo
  awk '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---" { exit }
    /^summary:/ { sub(/^summary:[ ]*/, ""); gsub(/^["'"'"']|["'"'"']$/, ""); print; exit }' "$1"
}
first_prose_after_title() { # $1=arquivo
  awk '
    BEGIN { fm=0; seen_title=0 }
    NR==1 && $0=="---" { fm=1; next }
    fm==1 && $0=="---" { fm=2; next }
    fm==1 { next }
    /^# / { seen_title=1; next }
    seen_title==1 && /^[[:space:]]*$/ { next }
    seen_title==1 && /^#/ { exit }
    seen_title==1 { print; exit }' "$1"
}

summary=""
OV="$SM/project/overview.md"
if [ -f "$OV" ]; then
  summary=$(frontmatter_summary "$OV")
  [ -z "$summary" ] && summary=$(first_prose_after_title "$OV")
fi
[ -z "$summary" ] && [ -f "$SM/INDEX.md" ] && summary=$(frontmatter_summary "$SM/INDEX.md")
# Uma linha só, sem markdown pesado, ≤ 240 chars
summary=$(printf '%s' "$summary" | tr '\n' ' ' | sed -E 's/\*\*//g; s/[[:space:]]+/ /g' | cut -c1-240)
echo "OVERVIEW_SUMMARY=${summary:-(sem resumo — smart-memory ainda não bootstrapada)}"

echo "SCANNED_AT=$(date +%Y-%m-%d)"
