#!/usr/bin/env bash
# diff-agents.sh — compara agentes entre fonte e destino(s)
# Usage: diff-agents.sh <source_path> <target_path1> [target_path2 ...]
# Output: relatório de diff por projeto destino (TSV — TAB-delimitado, como o
#         scan-ct-projects.sh; nomes reais de pasta podem conter "|").
#
# Regra de MISSING (alinha com scan-ct-projects.sh): um agente do CT ausente no
# destino SÓ conta como MISSING se a squad dele (prefixo antes do 1º hífen) já
# está instalada no destino. Squad inteira ausente = poda intencional, não drift.

SOURCE="${1:-}"
if [ -z "$SOURCE" ]; then
  SOURCE=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
[ $# -gt 0 ] && shift

if [ ! -d "$SOURCE/.claude/agents" ]; then
  printf 'ERROR=no_source_agents\tSOURCE=%s\n' "$SOURCE"
  exit 1
fi

SOURCE_NAME=$(basename "$SOURCE")
SOURCE_AGENTS=$(find "$SOURCE/.claude/agents" -maxdepth 1 -name "*.md" -type f \
  -exec basename {} .md \; 2>/dev/null | sort)
SOURCE_COUNT=$(echo "$SOURCE_AGENTS" | grep -c . 2>/dev/null || echo 0)

echo "SOURCE=$SOURCE_NAME"
echo "SOURCE_PATH=$SOURCE"
echo "SOURCE_AGENT_COUNT=$SOURCE_COUNT"
echo "---"

for target in "$@"; do
  target_name=$(basename "$target")
  target_path=$(cd "$target" 2>/dev/null && pwd || echo "$target")

  if [ ! -d "$target/.claude/agents" ]; then
    # Sem diretório de agentes = squad nenhuma instalada → nada é MISSING
    # (poda total; instalação é decisão do usuário via *install, não drift).
    printf 'TARGET=%s\tPATH=%s\tSTATUS=no_agents_dir\tMISSING=0\tPRESENT=0\tOUTDATED=0\tMISSING_LIST=\tOUTDATED_LIST=\n' \
      "$target_name" "$target_path"
    continue
  fi

  TARGET_AGENTS=$(find "$target/.claude/agents" -maxdepth 1 -name "*.md" -type f \
    -exec basename {} .md \; 2>/dev/null | sort)

  # Squads instaladas no destino (prefixo antes do 1º hífen), como CSV com sentinelas
  target_squads=",$(echo "$TARGET_AGENTS" | sed 's/-.*//' | sort -u | tr '\n' ',')"

  missing=0
  present=0
  outdated=0
  missing_list=""
  outdated_list=""
  ok_list=""

  while IFS= read -r agent; do
    [ -z "$agent" ] && continue
    src_file="$SOURCE/.claude/agents/$agent.md"
    tgt_file="$target/.claude/agents/$agent.md"

    if ! echo "$TARGET_AGENTS" | grep -qxF "$agent"; then
      # Ausente no destino: só é MISSING se a squad dele existe lá.
      squad="${agent%%-*}"
      case "$target_squads" in
        *",$squad,"*)
          missing=$((missing + 1))
          missing_list="$missing_list,$agent"
          ;;
      esac
    elif ! cmp -s "$src_file" "$tgt_file"; then
      # Decide por CONTEÚDO (não por mtime) — alinha com scan-ct-projects.sh (hash).
      outdated=$((outdated + 1))
      outdated_list="$outdated_list,$agent"
    else
      present=$((present + 1))
      ok_list="$ok_list,$agent"
    fi
  done <<EOF
$SOURCE_AGENTS
EOF

  total_issues=$((missing + outdated))
  status="synced"
  [ $total_issues -gt 0 ] && status="needs_update"

  printf 'TARGET=%s\tPATH=%s\tSTATUS=%s\tMISSING=%s\tPRESENT=%s\tOUTDATED=%s\tMISSING_LIST=%s\tOUTDATED_LIST=%s\n' \
    "$target_name" "$target_path" "$status" "$missing" "$present" "$outdated" \
    "${missing_list#,}" "${outdated_list#,}"
done
