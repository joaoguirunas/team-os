#!/usr/bin/env bash
# install-to-project.sh — instala agentes e skills do projeto fonte em um projeto destino
# Skills são SEMPRE sincronizadas (incluindo team-os obrigatória): copiadas se ausentes,
# ATUALIZADAS se o conteúdo difere da fonte. Skills extras no destino são preservadas.
# team-os-creator nunca vai para o destino. Sem opção "agentes apenas".
# Usage: install-to-project.sh --source <path> --target <path> [options]
#
# Options:
#   --squads dev,sites,social,traffic   squads a instalar (default: all)
#   --include-hooks                     copia também os hooks
#   --dry-run                           simula sem copiar nada

SOURCE=""
TARGET=""
SQUADS="all"
INCLUDE_HOOKS=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)       SOURCE="$2";   shift 2 ;;
    --target)       TARGET="$2";   shift 2 ;;
    --squads)       SQUADS="$2";   shift 2 ;;
    --include-hooks)  INCLUDE_HOOKS=1;  shift ;;
    --dry-run)      DRY_RUN=1;     shift ;;
    --include-skills) shift ;;  # ignorado — skills são sempre incluídas
    *) shift ;;
  esac
done

# Defaults
if [ -z "$SOURCE" ]; then
  SOURCE=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

if [ -z "$TARGET" ]; then
  echo "ERROR=missing_target"
  exit 1
fi

SOURCE=$(cd "$SOURCE" && pwd)
TARGET=$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")

SOURCE_NAME=$(basename "$SOURCE")
TARGET_NAME=$(basename "$TARGET")

if [ "$SOURCE" = "$TARGET" ]; then
  echo "ERROR=same_path|SOURCE=$SOURCE_NAME|TARGET=$TARGET_NAME"
  exit 1
fi

if [ ! -d "$SOURCE/.claude/agents" ]; then
  echo "ERROR=no_source_agents|SOURCE=$SOURCE_NAME"
  exit 1
fi

echo "STATUS=starting"
echo "SOURCE=$SOURCE_NAME"
echo "TARGET=$TARGET_NAME"
echo "SQUADS=$SQUADS"
echo "DRY_RUN=$DRY_RUN"
echo "---"

# Cria diretórios necessários no destino
do_mkdir() {
  [ $DRY_RUN -eq 1 ] && return
  mkdir -p "$1"
}

do_cp() {
  [ $DRY_RUN -eq 1 ] && return
  cp "$1" "$2"
}

do_cp_r() {
  [ $DRY_RUN -eq 1 ] && return
  cp -r "$1" "$2"
}

# ── Agentes ──────────────────────────────────────────────────────────────────

do_mkdir "$TARGET/.claude/agents"

agents_copied=0
agents_skipped=0
agents_updated=0
agents_list=""

for agent_file in "$SOURCE/.claude/agents/"*.md; do
  [ -f "$agent_file" ] || continue
  agent_name=$(basename "$agent_file" .md)

  # Filtra por squad
  if [ "$SQUADS" != "all" ]; then
    match=0
    for squad in $(echo "$SQUADS" | tr ',' ' '); do
      [[ "$agent_name" == ${squad}-* ]] && { match=1; break; }
    done
    [ $match -eq 0 ] && { agents_skipped=$((agents_skipped + 1)); continue; }
  fi

  target_file="$TARGET/.claude/agents/$agent_name.md"

  if [ -f "$target_file" ] && [ "$agent_file" -ot "$target_file" ]; then
    # Destino já tem versão mais nova — pula
    agents_skipped=$((agents_skipped + 1))
    continue
  fi

  action="copied"
  [ -f "$target_file" ] && action="updated"

  do_cp "$agent_file" "$target_file"
  [ "$action" = "updated" ] && agents_updated=$((agents_updated + 1)) || agents_copied=$((agents_copied + 1))
  agents_list="$agents_list $agent_name"
done

echo "AGENTS_COPIED=$agents_copied"
echo "AGENTS_UPDATED=$agents_updated"
echo "AGENTS_SKIPPED=$agents_skipped"
echo "AGENTS_LIST=${agents_list# }"

# ── Skills — sempre copiadas (incluindo team-os obrigatória) ─────────────────

do_mkdir "$TARGET/.claude/skills"

skills_copied=0
skills_updated=0
skills_skipped=0
skills_list=""

for skill_path in "$SOURCE/.claude/skills"/*/; do
  [ -d "$skill_path" ] || continue
  skill_name=$(basename "$skill_path")

  # team-os-creator nunca é copiada para projetos destino
  [[ "$skill_name" == "team-os-creator" ]] && { skills_skipped=$((skills_skipped + 1)); continue; }

  # Filtra por squad (skills core e sem prefixo de squad são sempre incluídas)
  if [ "$SQUADS" != "all" ]; then
    match=0
    for squad in $(echo "$SQUADS" | tr ',' ' '); do
      [[ "$skill_name" == ${squad}-* ]] && { match=1; break; }
    done
    # Skills sem prefixo squad (ex: accessibility, deep-research) — sempre incluir
    [[ "$skill_name" != *-* ]] && match=1
    # team-os é sempre incluída; team-os-creator fica só no projeto de origem
    [[ "$skill_name" == "team-os" ]] && match=1
    [ $match -eq 0 ] && { skills_skipped=$((skills_skipped + 1)); continue; }
  fi

  target_skill="$TARGET/.claude/skills/$skill_name"

  if [ -d "$target_skill" ]; then
    # Já existe: ATUALIZA se o conteúdo difere da fonte (CT é source of truth).
    # Skills extras no destino (não presentes na fonte) são preservadas — não apagamos.
    if diff -rq "$skill_path" "$target_skill" >/dev/null 2>&1; then
      skills_skipped=$((skills_skipped + 1))   # idêntica — nada a fazer
      continue
    fi
    if [ $DRY_RUN -eq 0 ]; then
      rm -rf "$target_skill"
      cp -R "$skill_path" "$target_skill"
    fi
    skills_updated=$((skills_updated + 1))
    skills_list="$skills_list $skill_name"
    continue
  fi

  do_cp_r "$skill_path" "$target_skill"
  skills_copied=$((skills_copied + 1))
  skills_list="$skills_list $skill_name"
done

# Garante team-os no destino (obrigatória para /team-os funcionar)
if [ ! -d "$TARGET/.claude/skills/team-os" ] && [ -d "$SOURCE/.claude/skills/team-os" ]; then
  do_cp_r "$SOURCE/.claude/skills/team-os" "$TARGET/.claude/skills/team-os"
  skills_copied=$((skills_copied + 1))
  skills_list="$skills_list team-os"
  echo "TEAM_OS_FORCED=1"
elif [ ! -d "$TARGET/.claude/skills/team-os" ]; then
  echo "TEAM_OS_WARNING=skill team-os não encontrada na fonte — instale manualmente"
fi

echo "SKILLS_COPIED=$skills_copied"
echo "SKILLS_UPDATED=$skills_updated"
echo "SKILLS_SKIPPED=$skills_skipped"
echo "SKILLS_LIST=${skills_list# }"

# ── Settings.json ────────────────────────────────────────────────────────────

# Garantir que CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS está ativo no destino
TARGET_SETTINGS="$TARGET/.claude/settings.json"
if [ ! -f "$TARGET_SETTINGS" ]; then
  if [ $DRY_RUN -eq 0 ]; then
    cat > "$TARGET_SETTINGS" <<'EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
EOF
  fi
  echo "SETTINGS_CREATED=1"
else
  # Verificar se já tem a variável; se não, avisar (não sobrescreve settings existente)
  if ! grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$TARGET_SETTINGS" 2>/dev/null; then
    echo "SETTINGS_WARNING=settings.json existe mas não tem CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS — adicione manualmente"
  else
    echo "SETTINGS_OK=1"
  fi
fi

# ── Hooks ────────────────────────────────────────────────────────────────────

if [ $INCLUDE_HOOKS -eq 1 ] && [ -d "$SOURCE/.claude/hooks" ]; then
  do_mkdir "$TARGET/.claude/hooks"

  hooks_copied=0
  # Copiar apenas hooks relevantes para as squads instaladas (evitar hooks de outros squads)
  for hook_file in "$SOURCE/.claude/hooks/"*.sh; do
    [ -f "$hook_file" ] || continue
    hook_name=$(basename "$hook_file")

    # block-git-push.sh é universal — sempre incluir
    if [[ "$hook_name" == "block-git-push.sh" ]]; then
      do_cp "$hook_file" "$TARGET/.claude/hooks/$hook_name"
      hooks_copied=$((hooks_copied + 1))
      continue
    fi

    # Hooks com prefixo de squad — só copiar se squad está sendo instalada
    hook_squad=""
    [[ "$hook_name" == check-social-* ]] && hook_squad="social"
    [[ "$hook_name" == check-story-* ]] && hook_squad="any"  # relevante para qualquer squad

    if [ "$hook_squad" = "any" ] || [ "$SQUADS" = "all" ]; then
      do_cp "$hook_file" "$TARGET/.claude/hooks/$hook_name"
      hooks_copied=$((hooks_copied + 1))
    elif [ -n "$hook_squad" ] && echo "$SQUADS" | grep -q "$hook_squad"; then
      do_cp "$hook_file" "$TARGET/.claude/hooks/$hook_name"
      hooks_copied=$((hooks_copied + 1))
    fi
  done

  echo "HOOKS_COPIED=$hooks_copied"
fi

echo "---"
echo "STATUS=done"
