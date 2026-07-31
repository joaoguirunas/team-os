#!/usr/bin/env bash
# scan-ct-projects.sh — mapeia projetos destino do Centro de Treinamento
# e reporta, por projeto: team-os instalada, contagem de agentes, smart-memory e DRIFT vs CT.
# Usage: scan-ct-projects.sh [SEARCH_ROOT]
# Output: SEARCH_ROOT, depois uma linha por projeto encontrado.
#
# Descoberta: RECURSIVA — acha qualquer diretório que contenha `.claude/agents`, em
# qualquer profundidade até MAX_DEPTH. Um scan raso (só `ROOT/*/`) não enxerga projeto
# aninhado (ex: `Site /cranium-site`) nem projeto cliente fora do root (ex:
# `Desktop/Bonfim/Site`) — e o que o scan não vê, o *propagate nunca atualiza.
# Por isso o root default sobe DOIS níveis a partir do CT, cobrindo os projetos irmãos.

SEARCH_ROOT="${1:-}"
MAX_DEPTH=6

# Git root do projeto atual = fonte da verdade (CT)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
SOURCE_AGENTS=""
[ -n "$GIT_ROOT" ] && [ -d "$GIT_ROOT/.claude/agents" ] && SOURCE_AGENTS="$GIT_ROOT/.claude/agents"

# Auto-detecta root: sobe DOIS níveis acima do git root do CT.
# (um nível = só os projetos irmãos do CT; dois = também os clientes fora de Projeto/)
if [ -z "$SEARCH_ROOT" ]; then
  BASE="${GIT_ROOT:-$(pwd)}"
  SEARCH_ROOT=$(dirname "$(dirname "$BASE")")
fi

SEARCH_ROOT=$(cd "$SEARCH_ROOT" && pwd)
CT_ROOT="$SEARCH_ROOT"

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

# Descoberta recursiva: todo dir com `.claude/agents` é um projeto destino.
# Poda node_modules/.git/backups — caros de varrer e nunca são projeto real.
discover_projects() {
  find "$SEARCH_ROOT" -maxdepth "$MAX_DEPTH" \
    \( -name node_modules -o -name .git -o -name 'agents.bak-*' -o -name .next -o -name dist \) -prune \
    -o -type d -name agents -path '*/.claude/agents' -print 2>/dev/null \
  | while IFS= read -r agents_dir; do
      # .../<projeto>/.claude/agents → <projeto>
      dirname "$(dirname "$agents_dir")"
    done | sort -u
}

while IFS= read -r proj; do
  [ -n "$proj" ] || continue
  dir="$proj/"
  # Nome = caminho relativo ao root (basename sozinho é ambíguo: "Site " vs "site")
  name="${proj#$SEARCH_ROOT/}"

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
    skill_count=$(find "$dir/.claude/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
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
    # Agentes do CT ausentes no projeto — só conta ausências DENTRO das squads já
    # instaladas. Squad que o projeto não tem (poda intencional por categoria) NÃO é drift.
    # Agente listado em .claude/agents-ignore (poda intencional por agente) também NÃO é drift.
    ignore_csv=","
    if [ -f "$dir/.claude/agents-ignore" ]; then
      ignore_csv=",$(grep -v '^\s*#' "$dir/.claude/agents-ignore" 2>/dev/null | sed '/^\s*$/d' | tr -d ' ' | tr '\n' ',')"
    fi
    squads_csv=",${agent_squads},"
    for sf in "$SOURCE_AGENTS/"*.md; do
      [ -f "$sf" ] || continue
      bn=$(basename "$sf")
      [ -f "$dir/.claude/agents/$bn" ] && continue
      an="${bn%.md}"
      case "$ignore_csv" in *",$an,"*) continue ;; esac
      sprefix="${bn%%-*}"
      case "$squads_csv" in *",$sprefix,"*) drift_missing=$((drift_missing + 1)) ;; esac
    done
  fi

  # HOOKS_BROKEN: agente referencia um hook que não existe no destino. É falha silenciosa —
  # o hook não roda e a garantia (ex: só devops dá push) deixa de valer sem ninguém notar.
  hooks_broken=0
  if [ "$has_agents" -eq 1 ]; then
    for hf in $(grep -ho '\.claude/hooks/[a-z-]*\.sh' "$dir/.claude/agents/"*.md 2>/dev/null | sort -u); do
      [ -f "$dir/$hf" ] || hooks_broken=$((hooks_broken + 1))
    done
  fi

  echo "PROJECT=$name|PATH=$dir|IS_CURRENT=$is_current|HAS_AGENTS=$has_agents|AGENT_COUNT=$agent_count|AGENT_SQUADS=$agent_squads|HAS_SKILLS=$has_skills|SKILL_COUNT=$skill_count|HAS_HOOKS=$([ -d "$dir/.claude/hooks" ] && echo 1 || echo 0)|HOOKS_BROKEN=$hooks_broken|HAS_TEAM_OS=$has_team_os|HAS_SMART_MEMORY=$has_smart_memory|DRIFT_OK=$drift_ok|DRIFT_OUTDATED=$drift_outdated|DRIFT_EXTRA=$drift_extra|DRIFT_MISSING=$drift_missing"
done < <(discover_projects)
