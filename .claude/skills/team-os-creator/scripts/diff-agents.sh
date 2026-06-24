#!/usr/bin/env bash
# diff-agents.sh — compara agentes entre fonte e destino(s)
# Usage: diff-agents.sh <source_path> <target_path1> [target_path2 ...]
# Output: relatório de diff por projeto destino

SOURCE="${1:-}"
if [ -z "$SOURCE" ]; then
  SOURCE=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
shift

if [ ! -d "$SOURCE/.claude/agents" ]; then
  echo "ERROR=no_source_agents|SOURCE=$SOURCE"
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
    echo "TARGET=$target_name|PATH=$target_path|STATUS=no_agents_dir|MISSING=$SOURCE_COUNT|PRESENT=0|OUTDATED=0|MISSING_LIST=$(echo "$SOURCE_AGENTS" | tr '\n' ',')"
    continue
  fi

  TARGET_AGENTS=$(find "$target/.claude/agents" -maxdepth 1 -name "*.md" -type f \
    -exec basename {} .md \; 2>/dev/null | sort)

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

    if ! echo "$TARGET_AGENTS" | grep -qx "$agent"; then
      missing=$((missing + 1))
      missing_list="$missing_list,$agent"
    elif ! cmp -s "$src_file" "$tgt_file"; then
      # Decide por CONTEÚDO (não por mtime) — alinha com scan-ct-projects.sh (hash).
      outdated=$((outdated + 1))
      outdated_list="$outdated_list,$agent"
    else
      present=$((present + 1))
      ok_list="$ok_list,$agent"
    fi
  done <<< "$SOURCE_AGENTS"

  total_issues=$((missing + outdated))
  status="synced"
  [ $total_issues -gt 0 ] && status="needs_update"

  echo "TARGET=$target_name|PATH=$target_path|STATUS=$status|MISSING=$missing|PRESENT=$present|OUTDATED=$outdated|MISSING_LIST=${missing_list#,}|OUTDATED_LIST=${outdated_list#,}"
done
