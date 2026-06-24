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
MATCH_TARGET=0   # --match-target-squads: deriva squads do que JÁ existe no destino (modo propagate)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)       SOURCE="$2";   shift 2 ;;
    --target)       TARGET="$2";   shift 2 ;;
    --squads)       SQUADS="$2";   shift 2 ;;
    --match-target-squads) MATCH_TARGET=1; shift ;;
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

# Modo propagate: deriva as squads a sincronizar a partir do que JÁ existe no destino.
# Garante que squads podadas (não instaladas) nunca sejam re-adicionadas.
if [ $MATCH_TARGET -eq 1 ]; then
  if [ -d "$TARGET/.claude/agents" ]; then
    SQUADS=$(find "$TARGET/.claude/agents" -maxdepth 1 -name '*.md' -type f -exec basename {} .md \; 2>/dev/null \
      | sed 's/-.*//' | sort -u | tr '\n' ',' | sed 's/,$//')
  fi
  [ -z "$SQUADS" ] && SQUADS="__none__"   # destino sem agentes → não sincroniza nenhum
  echo "MATCH_TARGET_SQUADS=$SQUADS"
fi

# Guarda-dura: instalar TODAS as squads sem derivar do destino re-adiciona squads podadas.
# Só permitido com --match-target-squads (deriva do destino) ou --squads <categoria> explícito.
if [ "$SQUADS" = "all" ] && [ $MATCH_TARGET -eq 0 ]; then
  echo "ERROR=squads_all_without_match_target|--squads default é 'all', o que re-instalaria TODAS as squads e desfaria podas por categoria. Passe --match-target-squads (deriva as squads do destino) ou --squads <categoria> explícito (ex: --squads social)." >&2
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

  if [ -f "$target_file" ]; then
    # Destino já tem o agente: decide por CONTEÚDO (não por mtime).
    # Conteúdo idêntico → skipped (alinha com o scan por hash). Difere → updated.
    if cmp -s "$agent_file" "$target_file"; then
      agents_skipped=$((agents_skipped + 1))
      continue
    fi
    do_cp "$agent_file" "$target_file"
    agents_updated=$((agents_updated + 1))
    agents_list="$agents_list $agent_name"
    continue
  fi

  # Novo no destino → copiado
  do_cp "$agent_file" "$target_file"
  agents_copied=$((agents_copied + 1))
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

  # Filtra por squad. Skill com prefixo de squad ({dev,sites,social,traffic,pm}-*)
  # só entra se a squad está na lista; QUALQUER outra skill (geral, com ou sem hífen:
  # accessibility, deep-research, data-*, ai-ml-*) é sempre incluída.
  if [ "$SQUADS" != "all" ]; then
    skill_prefix="${skill_name%%-*}"
    case "$skill_prefix" in
      dev|sites|social|traffic|pm)
        match=0
        for squad in $(echo "$SQUADS" | tr ',' ' '); do
          [ "$skill_prefix" = "$squad" ] && { match=1; break; }
        done ;;
      *) match=1 ;;   # skill geral (não-squad) → sempre incluir
    esac
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

# ── Session-title hook (global, core UX — sempre instalado) ──────────────────
# Nomeia toda sessão pelo projeto+branch. Vale para todos os projetos de uma vez.
GLOBAL_HOOK_SRC="$SOURCE/.claude/hooks/team-os-session-title.sh"
GLOBAL_HOOK_DST="$HOME/.claude/hooks/team-os-session-title.sh"
if [ -f "$GLOBAL_HOOK_SRC" ]; then
  if [ $DRY_RUN -eq 0 ]; then
    mkdir -p "$HOME/.claude/hooks"
    cp "$GLOBAL_HOOK_SRC" "$GLOBAL_HOOK_DST"
    chmod +x "$GLOBAL_HOOK_DST"
  fi
  echo "SESSION_TITLE_HOOK=installed"
  # Registro do SessionStart no settings global é feito pela skill (edição segura de JSON).
  if [ -f "$HOME/.claude/settings.json" ] && grep -q "team-os-session-title" "$HOME/.claude/settings.json" 2>/dev/null; then
    echo "SESSION_TITLE_REGISTERED=1"
  else
    echo "SESSION_TITLE_REGISTER_TODO=1|adicione um hook SessionStart em ~/.claude/settings.json apontando para \$HOME/.claude/hooks/team-os-session-title.sh"
  fi
else
  echo "SESSION_TITLE_HOOK_MISSING=team-os-session-title.sh não encontrado na fonte"
fi

echo "---"
echo "STATUS=done"
