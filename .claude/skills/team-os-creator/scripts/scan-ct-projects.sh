#!/usr/bin/env bash
# scan-ct-projects.sh — mapeia projetos no root do Centro de Treinamento
# e reporta, por projeto: team-os instalada, contagem de agentes, smart-memory e DRIFT vs CT.
# Usage: scan-ct-projects.sh [CT_ROOT]
# Output: CT_ROOT, depois uma linha por projeto encontrado.

CT_ROOT="${1:-}"

# Git root do projeto atual = fonte da verdade (CT)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
SOURCE_AGENTS=""
[ -n "$GIT_ROOT" ] && [ -d "$GIT_ROOT/.claude/agents" ] && SOURCE_AGENTS="$GIT_ROOT/.claude/agents"

# Auto-detecta root: sobe um nível acima do git root do projeto atual
if [ -z "$CT_ROOT" ]; then
  if [ -n "$GIT_ROOT" ]; then
    CT_ROOT=$(dirname "$GIT_ROOT")
  else
    CT_ROOT=$(dirname "$(pwd)")
  fi
fi

CT_ROOT=$(cd "$CT_ROOT" && pwd)

# Helper de hash (shasum no macOS, md5sum no Linux)
hash_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
  else
    md5sum "$1" 2>/dev/null | awk '{print $1}'
  fi
}

echo "CT_ROOT=$CT_ROOT"
[ -n "$SOURCE_AGENTS" ] && echo "SOURCE_AGENTS=$(find "$SOURCE_AGENTS" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
echo "---"

for dir in "$CT_ROOT"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")

  has_agents=0; agent_count=0; agent_squads=""
  has_skills=0; skill_count=0; has_hooks=0; is_current=0
  has_team_os=0; has_smart_memory=0
  drift_ok=0; drift_outdated=0; drift_extra=0; drift_missing=0

  PROJ_REAL=$(cd "$dir" && pwd)
  [ "$PROJ_REAL" = "$GIT_ROOT" ] && is_current=1

  # Agentes
  if [ -d "$dir/.claude/agents" ]; then
    has_agents=1
    agent_count=$(find "$dir/.claude/agents" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    agent_squads=$(find "$dir/.claude/agents" -maxdepth 1 -name "*.md" -type f -exec basename {} .md \; 2>/dev/null \
      | sed 's/-.*//' | sort -u | tr '\n' ',' | sed 's/,$//')
  fi

  # Skills + team-os
  if [ -d "$dir/.claude/skills" ]; then
    has_skills=1
    skill_count=$(find "$dir/.claude/skills" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' ')
  fi
  [ -d "$dir/.claude/skills/team-os" ] && has_team_os=1

  # Smart-memory
  { [ -d "$dir/docs/smart-memory" ] || [ -f "$dir/docs/smart-memory/INDEX.md" ]; } && has_smart_memory=1

  # Drift vs CT (só para projetos que não são o CT e têm agentes)
  if [ "$is_current" -eq 0 ] && [ "$has_agents" -eq 1 ] && [ -n "$SOURCE_AGENTS" ]; then
    for pf in "$dir/.claude/agents/"*.md; do
      [ -f "$pf" ] || continue
      an=$(basename "$pf")
      sf="$SOURCE_AGENTS/$an"
      if [ -f "$sf" ]; then
        if [ "$(hash_file "$pf")" = "$(hash_file "$sf")" ]; then
          drift_ok=$((drift_ok + 1))
        else
          drift_outdated=$((drift_outdated + 1))
        fi
      else
        drift_extra=$((drift_extra + 1))
      fi
    done
    # Agentes do CT ausentes no projeto (informativo)
    for sf in "$SOURCE_AGENTS/"*.md; do
      [ -f "$sf" ] || continue
      [ -f "$dir/.claude/agents/$(basename "$sf")" ] || drift_missing=$((drift_missing + 1))
    done
  fi

  echo "PROJECT=$name|PATH=$dir|IS_CURRENT=$is_current|HAS_AGENTS=$has_agents|AGENT_COUNT=$agent_count|AGENT_SQUADS=$agent_squads|HAS_SKILLS=$has_skills|SKILL_COUNT=$skill_count|HAS_HOOKS=$([ -d "$dir/.claude/hooks" ] && echo 1 || echo 0)|HAS_TEAM_OS=$has_team_os|HAS_SMART_MEMORY=$has_smart_memory|DRIFT_OK=$drift_ok|DRIFT_OUTDATED=$drift_outdated|DRIFT_EXTRA=$drift_extra|DRIFT_MISSING=$drift_missing"
done
