#!/usr/bin/env bash
# list-teammates.sh — enumera todos os agentes disponíveis dos 2 escopos
# Output: tabela tab-separated: nome<TAB>description<TAB>scope
# Projeto tem precedência sobre user (se houver colisão, projeto vence)

SEEN=" "

extract_field() {
  local file="$1"
  local field="$2"
  awk -v field="$field" '
    BEGIN { in_fm = 0; found = 0 }
    /^---$/ {
      if (in_fm == 0) { in_fm = 1; next }
      else { exit }
    }
    in_fm && $0 ~ "^" field ":" {
      sub("^" field ":[[:space:]]*", "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      print
      found = 1
      exit
    }
  ' "$file"
}

# Project scope primeiro (prioridade)
if [ -d ".claude/agents" ]; then
  for f in .claude/agents/*.md; do
    [ -f "$f" ] || continue
    name=$(extract_field "$f" "name")
    desc=$(extract_field "$f" "description")
    [ -z "$name" ] && continue
    SEEN="$SEEN$name "
    printf "%s\t%s\t%s\n" "$name" "$desc" "project"
  done
fi

# User scope, pulando duplicados
if [ -d "$HOME/.claude/agents" ]; then
  for f in "$HOME"/.claude/agents/*.md; do
    [ -f "$f" ] || continue
    name=$(extract_field "$f" "name")
    desc=$(extract_field "$f" "description")
    [ -z "$name" ] && continue
    case "$SEEN" in *" $name "*) continue ;; esac
    printf "%s\t%s\t%s\n" "$name" "$desc" "user"
  done
fi
