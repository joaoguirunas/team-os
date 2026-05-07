#!/usr/bin/env bash
# scan-ct-projects.sh — mapeia projetos no root do Centro de Treinamento
# Usage: scan-ct-projects.sh [CT_ROOT]
# Output: CT_ROOT, depois uma linha por projeto encontrado

CT_ROOT="${1:-}"

# Auto-detecta root: sobe um nível acima do git root do projeto atual
if [ -z "$CT_ROOT" ]; then
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$GIT_ROOT" ]; then
    CT_ROOT=$(dirname "$GIT_ROOT")
  else
    CT_ROOT=$(dirname "$(pwd)")
  fi
fi

# Normaliza o path
CT_ROOT=$(cd "$CT_ROOT" && pwd)

echo "CT_ROOT=$CT_ROOT"
echo "---"

for dir in "$CT_ROOT"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")

  has_agents=0
  agent_count=0
  agent_squads=""
  has_skills=0
  skill_count=0
  has_hooks=0
  is_current=0

  # Marca projeto atual
  CURRENT_GIT=$(git rev-parse --show-toplevel 2>/dev/null)
  PROJ_REAL=$(cd "$dir" && pwd)
  [ "$PROJ_REAL" = "$CURRENT_GIT" ] && is_current=1

  # Agentes
  if [ -d "$dir/.claude/agents" ]; then
    has_agents=1
    agent_count=$(find "$dir/.claude/agents" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    # Detecta squads presentes (prefixo antes do primeiro -)
    agent_squads=$(find "$dir/.claude/agents" -maxdepth 1 -name "*.md" -type f -exec basename {} .md \; 2>/dev/null \
      | sed 's/-.*//' | sort -u | tr '\n' ',' | sed 's/,$//')
  fi

  # Skills
  if [ -d "$dir/.claude/skills" ]; then
    has_skills=1
    skill_count=$(ls "$dir/.claude/skills" 2>/dev/null | wc -l | tr -d ' ')
  fi

  # Hooks
  [ -d "$dir/.claude/hooks" ] && has_hooks=1

  echo "PROJECT=$name|PATH=$dir|IS_CURRENT=$is_current|HAS_AGENTS=$has_agents|AGENT_COUNT=$agent_count|AGENT_SQUADS=$agent_squads|HAS_SKILLS=$has_skills|SKILL_COUNT=$skill_count|HAS_HOOKS=$has_hooks"
done
