#!/usr/bin/env bash
# install-to-project.sh — instala agentes e skills do projeto fonte em um projeto destino
# Skills são SEMPRE sincronizadas (incluindo team-os obrigatória): copiadas se ausentes,
# ATUALIZADAS se o conteúdo difere da fonte. Skills extras no destino são preservadas.
# team-os-creator nunca vai para o destino. Sem opção "agentes apenas".
# Usage: install-to-project.sh --source <path> --target <path> [options]
#
# Options:
#   --squads dev,sites,social,traffic   squads a instalar (default: all)
#   --squads none                       modo Sala de Controle: nenhum agente, nenhuma skill geral,
#                                       sem team-os/hooks/settings — só o que vier em --extra-skills
#                                       (+ CLAUDE.md mínimo se não existir)
#   --extra-skills maestri-os           skills opt-in, fora do filtro por squad. maestri-os NUNCA
#                                       entra sozinha: só por esta flag ou se já existir no destino
#   --include-hooks                     copia também hooks extras (fora do pacote padrão)
#                                       (block-worktree.sh, block-git-push.sh, task-quality.sh,
#                                       check-story-progress.sh, check-social-progress.sh,
#                                       check-proposal-progress.sh e guard-push-branch.sh são
#                                       SEMPRE instalados)
#   --dry-run                           simula sem copiar nada

SOURCE=""
TARGET=""
SQUADS="all"
INCLUDE_HOOKS=0
DRY_RUN=0
MATCH_TARGET=0   # --match-target-squads: deriva squads do que JÁ existe no destino (modo propagate)
EXTRA_SKILLS=""  # --extra-skills: opt-in fora do filtro por squad (ex.: maestri-os)
CONTROL_ROOM=0   # Sala de Controle: --squads none, ou propagate em destino sem agentes mas com maestri-os

need_value() { # $1=flag — aborta se a flag veio sem valor (evita loop infinito do shift 2)
  if [ $# -lt 2 ] || [ -z "$2" ]; then
    echo "ERROR=missing_value|FLAG=$1 exige um valor" >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)       need_value "$1" "${2:-}"; SOURCE="$2";   shift 2 ;;
    --target)       need_value "$1" "${2:-}"; TARGET="$2";   shift 2 ;;
    --squads)       need_value "$1" "${2:-}"; SQUADS="$2";   shift 2 ;;
    --extra-skills) need_value "$1" "${2:-}"; EXTRA_SKILLS="$2"; shift 2 ;;
    --match-target-squads) MATCH_TARGET=1; shift ;;
    --include-hooks)  INCLUDE_HOOKS=1;  shift ;;
    --dry-run)      DRY_RUN=1;     shift ;;
    --include-skills) shift ;;  # ignorado — skills são sempre incluídas
    *)
      echo "ERROR=unknown_flag|FLAG=$1" >&2
      echo "Usage: install-to-project.sh --source <path> --target <path> [--squads <lista> | --match-target-squads] [--include-hooks] [--dry-run]" >&2
      exit 2 ;;
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
  # Zera o default "all" ANTES de derivar: destino sem .claude/agents/ (ou derivação
  # vazia) tem que virar __none__ — nunca cair no "all" e instalar tudo.
  SQUADS=""
  if [ -d "$TARGET/.claude/agents" ]; then
    SQUADS=$(find "$TARGET/.claude/agents" -maxdepth 1 -name '*.md' -type f -exec basename {} .md \; 2>/dev/null \
      | sed 's/-.*//' | sort -u | tr '\n' ',' | sed 's/,$//')
  fi
  [ -z "$SQUADS" ] && SQUADS="__none__"   # destino sem agentes → não sincroniza nenhum
  echo "MATCH_TARGET_SQUADS=$SQUADS"
  if [ "$SQUADS" = "__none__" ]; then
    if [ -d "$TARGET/.claude/skills/maestri-os" ]; then
      # Sala de Controle: sem agentes, mas com maestri-os → propagate mantém SÓ a skill atualizada.
      CONTROL_ROOM=1
      echo "CONTROL_ROOM=1"
    else
      # Destino sem nenhum agente = team-os não instalado → propagate não tem o que
      # sincronizar (nem skills). Instalação inicial exige --squads <categoria> explícito.
      echo "SKIP=target_sem_squad|propagate não instala nada num projeto sem agentes; use --squads <categoria> para instalar (ou --squads none --extra-skills maestri-os para uma Sala de Controle)."
      exit 0
    fi
  fi
fi

# --squads none = instalação explícita de Sala de Controle (só --extra-skills; nada de squad)
if [ "$SQUADS" = "none" ]; then
  CONTROL_ROOM=1
  SQUADS="__none__"
  echo "CONTROL_ROOM=1"
  if [ -z "$EXTRA_SKILLS" ]; then
    echo "ERROR=control_room_without_extra_skills|--squads none exige --extra-skills (ex.: --extra-skills maestri-os); sem isso não há nada a instalar." >&2
    exit 1
  fi
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

# Sync de diretório de skill: rsync com --delete e exclusão de lixo macOS
# (.DS_Store, Icon\r). Elimina lixo propagado e drift falso — o hash do scan
# ignora esses arquivos, então cp -R os copiando gerava divergência eterna.
do_sync_dir() { # $1=src (SEM barra final exigida) $2=dst
  [ $DRY_RUN -eq 1 ] && return
  mkdir -p "$2"
  rsync -a --delete --exclude '.DS_Store' --exclude 'Icon?' "${1%/}/" "$2/"
}

# Diferença de conteúdo ignorando lixo macOS (mesmo critério do sync)
dir_differs() { # $1=src $2=dst → exit 0 se DIFERE
  ! diff -rq -x '.DS_Store' -x 'Icon?' "${1%/}" "${2%/}" >/dev/null 2>&1
}

# .gitignore do destino: cobrir lixo macOS (.DS_Store, Icon?)
ensure_gitignore() {
  [ $DRY_RUN -eq 1 ] && return
  local gi="$TARGET/.gitignore" added=""
  [ -f "$gi" ] || : > "$gi"
  if ! grep -q '^\.DS_Store$\|^\*\*/\.DS_Store$\|^\.DS_Store\b' "$gi" 2>/dev/null; then
    printf '.DS_Store\n' >> "$gi"; added="$added .DS_Store"
  fi
  if ! grep -q '^Icon?$\|^Icon\\r$\|^Icon\?' "$gi" 2>/dev/null; then
    printf 'Icon?\n' >> "$gi"; added="$added Icon?"
  fi
  [ -n "$added" ] && echo "GITIGNORE_ADDED=${added# }"
}

# ── Agentes ──────────────────────────────────────────────────────────────────

[ $CONTROL_ROOM -eq 0 ] && do_mkdir "$TARGET/.claude/agents"

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
team_os_handled=0   # evita dupla contagem de team-os no bloco "forçado" (bug do dry-run)

for skill_path in "$SOURCE/.claude/skills"/*/; do
  [ -d "$skill_path" ] || continue
  skill_name=$(basename "$skill_path")

  # team-os-creator nunca é copiada para projetos destino
  [[ "$skill_name" == "team-os-creator" ]] && { skills_skipped=$((skills_skipped + 1)); continue; }

  # Opt-in explícito (--extra-skills) vale em qualquer modo
  extra=0
  for es in $(echo "$EXTRA_SKILLS" | tr ',' ' '); do
    [ "$es" = "$skill_name" ] && { extra=1; break; }
  done

  if [ "$skill_name" = "maestri-os" ]; then
    # Sala de Controle: NUNCA entra sozinha (cairia na regra "geral → sempre incluir" e vazaria
    # para todos os projetos). Só por --extra-skills, ou se já existe no destino (update via propagate).
    match=0
    { [ $extra -eq 1 ] || [ -d "$TARGET/.claude/skills/maestri-os" ]; } && match=1
    [ $match -eq 0 ] && { skills_skipped=$((skills_skipped + 1)); continue; }
  elif [ $CONTROL_ROOM -eq 1 ]; then
    # Modo Sala de Controle: nenhuma skill geral, nem team-os — só opt-in
    [ $extra -eq 0 ] && { skills_skipped=$((skills_skipped + 1)); continue; }
  elif [ "$SQUADS" != "all" ]; then
    # Filtra por squad. Skill com prefixo de squad ({dev,sites,social,traffic,pm,sales,brand}-*)
    # só entra se a squad está na lista; QUALQUER outra skill (geral, com ou sem hífen:
    # accessibility, deep-research, data-*, ai-ml-*) é sempre incluída.
    skill_prefix="${skill_name%%-*}"
    case "$skill_prefix" in
      dev|sites|social|traffic|pm|sales|brand)
        match=0
        for squad in $(echo "$SQUADS" | tr ',' ' '); do
          [ "$skill_prefix" = "$squad" ] && { match=1; break; }
        done ;;
      *) match=1 ;;   # skill geral (não-squad) → sempre incluir
    esac
    # team-os é sempre incluída; team-os-creator fica só no projeto de origem
    [[ "$skill_name" == "team-os" ]] && match=1
    [ $extra -eq 1 ] && match=1
    [ $match -eq 0 ] && { skills_skipped=$((skills_skipped + 1)); continue; }
  fi

  target_skill="$TARGET/.claude/skills/$skill_name"
  [ "$skill_name" = "team-os" ] && team_os_handled=1

  if [ -d "$target_skill" ]; then
    # Já existe: ATUALIZA se o conteúdo difere da fonte (CT é source of truth).
    # Skills extras no destino (não presentes na fonte) são preservadas — não apagamos.
    if ! dir_differs "$skill_path" "$target_skill"; then
      skills_skipped=$((skills_skipped + 1))   # idêntica — nada a fazer
      continue
    fi
    do_sync_dir "$skill_path" "$target_skill"
    skills_updated=$((skills_updated + 1))
    skills_list="$skills_list $skill_name"
    continue
  fi

  do_sync_dir "$skill_path" "$target_skill"
  skills_copied=$((skills_copied + 1))
  skills_list="$skills_list $skill_name"
done

# Garante team-os no destino (obrigatória para /team-os funcionar).
# team_os_handled evita dupla contagem quando o loop já processou team-os
# (no --dry-run nada é copiado de fato, então o teste de diretório enganava).
if [ $CONTROL_ROOM -eq 1 ]; then
  :   # Sala de Controle não tem squad → não força team-os
elif [ $team_os_handled -eq 0 ] && [ ! -d "$TARGET/.claude/skills/team-os" ] && [ -d "$SOURCE/.claude/skills/team-os" ]; then
  do_sync_dir "$SOURCE/.claude/skills/team-os" "$TARGET/.claude/skills/team-os"
  skills_copied=$((skills_copied + 1))
  skills_list="$skills_list team-os"
  echo "TEAM_OS_FORCED=1"
elif [ $team_os_handled -eq 0 ] && [ ! -d "$SOURCE/.claude/skills/team-os" ]; then
  echo "TEAM_OS_WARNING=skill team-os não encontrada na fonte — instale manualmente"
fi

echo "SKILLS_COPIED=$skills_copied"
echo "SKILLS_UPDATED=$skills_updated"
echo "SKILLS_SKIPPED=$skills_skipped"
echo "SKILLS_LIST=${skills_list# }"

# ── Higiene: remover artefatos Icon\r do macOS copiados junto ────────────────
# cp -R traz os ícones custom de pasta (Icon\r) da fonte; eles poluem o git
# dos destinos. Remove do que acabou de ser instalado (agents/skills/hooks).
if [ $DRY_RUN -eq 0 ]; then
  icon_cleaned=$(find "$TARGET/.claude/agents" "$TARGET/.claude/skills" "$TARGET/.claude/hooks" \
    -name "Icon"$'\r' -type f -print -delete 2>/dev/null | wc -l | tr -d ' ')
  echo "ICON_CLEANED=$icon_cleaned"
fi

# ── Sala de Controle: para aqui ──────────────────────────────────────────────
# Sem agentes → sem hooks de quality gate, sem settings de Agent Teams, sem session-title.
# Só a(s) skill(s) opt-in + CLAUDE.md mínimo (se não existir) + .gitignore.
if [ $CONTROL_ROOM -eq 1 ]; then
  if [ ! -f "$TARGET/CLAUDE.md" ]; then
    if [ $DRY_RUN -eq 0 ]; then
      cat > "$TARGET/CLAUDE.md" <<EOF
# $TARGET_NAME — Sala de Controle

Esta pasta é uma **Sala de Controle** do pack team-os: não tem agentes nem código. Sua única função é rotear pedidos para os outros terminais do Maestri (Site, Marketing, Campanhas…) ligados a ela por fio no canvas.

- Comando: \`/maestri-os <pedido>\` — ou \`/maestri-os\` sem pedido para ver o compilado dos projetos.
- Registro de terminais, compilado e histórico de despachos ficam em \`docs/smart-memory/maestri/\`.
- Regra de ouro: esta sessão **lê** as outras pastas só para mapear (agentes + INDEX/overview), mas **nunca edita nem executa nada** nelas. Todo trabalho vai pelo terminal do projeto, com os agentes e travas daquele projeto.
EOF
    fi
    echo "CLAUDE_MD_CREATED=1"
  fi
  ensure_gitignore
  echo "---"
  echo "STATUS=done"
  exit 0
fi

# ── Hooks universais (sempre instalados, independente de --include-hooks) ────
# block-worktree.sh é referenciado pelo settings.json; block-git-push.sh é
# referenciado no frontmatter dos implementers/agentes com Bash das squads de
# código — sem ele no destino, a garantia dura de push não existe.
WORKTREE_HOOK_SRC="$SOURCE/.claude/hooks/block-worktree.sh"
if [ -f "$WORKTREE_HOOK_SRC" ]; then
  do_mkdir "$TARGET/.claude/hooks"
  do_cp "$WORKTREE_HOOK_SRC" "$TARGET/.claude/hooks/block-worktree.sh"
  [ $DRY_RUN -eq 0 ] && chmod +x "$TARGET/.claude/hooks/block-worktree.sh"
  echo "WORKTREE_HOOK=installed"
else
  echo "WORKTREE_HOOK_MISSING=block-worktree.sh não encontrado na fonte"
fi

GIT_PUSH_HOOK_SRC="$SOURCE/.claude/hooks/block-git-push.sh"
if [ -f "$GIT_PUSH_HOOK_SRC" ]; then
  do_mkdir "$TARGET/.claude/hooks"
  do_cp "$GIT_PUSH_HOOK_SRC" "$TARGET/.claude/hooks/block-git-push.sh"
  [ $DRY_RUN -eq 0 ] && chmod +x "$TARGET/.claude/hooks/block-git-push.sh"
  echo "GIT_PUSH_HOOK=installed"
else
  echo "GIT_PUSH_HOOK_MISSING=block-git-push.sh não encontrado na fonte"
fi

# ── Hooks de quality gate (pacote padrão — sempre instalados) ─────────────────
# task-quality.sh (TaskCreated), check-story-progress.sh, check-social-progress.sh e
# check-proposal-progress.sh (TaskCompleted) e guard-push-branch.sh (PreToolUse Bash do
# devops). Registrados como quality gates no settings.json gerado — não são mais opcionais.
quality_hooks_installed=""
quality_hooks_missing=""
for qh in task-quality.sh check-story-progress.sh check-social-progress.sh check-proposal-progress.sh guard-push-branch.sh; do
  if [ -f "$SOURCE/.claude/hooks/$qh" ]; then
    do_mkdir "$TARGET/.claude/hooks"
    do_cp "$SOURCE/.claude/hooks/$qh" "$TARGET/.claude/hooks/$qh"
    [ $DRY_RUN -eq 0 ] && chmod +x "$TARGET/.claude/hooks/$qh"
    quality_hooks_installed="$quality_hooks_installed $qh"
  else
    quality_hooks_missing="$quality_hooks_missing $qh"
  fi
done
[ -n "$quality_hooks_installed" ] && echo "QUALITY_HOOKS=${quality_hooks_installed# }"
[ -n "$quality_hooks_missing" ] && echo "QUALITY_HOOKS_MISSING=${quality_hooks_missing# }"

# ── .gitignore do destino: cobrir lixo macOS (.DS_Store, Icon?) ──────────────
ensure_gitignore

# ── Settings.json ────────────────────────────────────────────────────────────

# Garantir CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS + trava anti-worktree no destino
TARGET_SETTINGS="$TARGET/.claude/settings.json"
if [ ! -f "$TARGET_SETTINGS" ]; then
  if [ $DRY_RUN -eq 0 ]; then
    cat > "$TARGET_SETTINGS" <<'EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "subagentPromptCacheTtl": "1h",
  "worktree": {
    "bgIsolation": "none"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Agent|Task|EnterWorktree",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-worktree.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-worktree.sh"
          }
        ]
      }
    ],
    "TaskCreated": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/task-quality.sh"
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-story-progress.sh"
          },
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-social-progress.sh"
          },
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-proposal-progress.sh"
          }
        ]
      }
    ]
  }
}
EOF
  fi
  echo "SETTINGS_CREATED=1"
else
  # Verificar peças obrigatórias; avisar sem sobrescrever settings existente
  if ! grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$TARGET_SETTINGS" 2>/dev/null; then
    echo "SETTINGS_WARNING=settings.json existe mas não tem CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS — adicione manualmente"
  else
    echo "SETTINGS_OK=1"
  fi
  if ! grep -q "bgIsolation" "$TARGET_SETTINGS" 2>/dev/null; then
    echo "SETTINGS_WORKTREE_TODO=1|adicione \"worktree\": { \"bgIsolation\": \"none\" } ao settings.json do destino"
  fi
  if ! grep -q "block-worktree" "$TARGET_SETTINGS" 2>/dev/null; then
    echo "SETTINGS_WORKTREE_HOOK_TODO=1|registre o hook block-worktree.sh em PreToolUse (matchers: Agent|Task|EnterWorktree e Bash) no settings.json do destino"
  fi
  if ! grep -q "task-quality" "$TARGET_SETTINGS" 2>/dev/null || ! grep -q "subagentPromptCacheTtl" "$TARGET_SETTINGS" 2>/dev/null; then
    echo "SETTINGS_TASKHOOKS_TODO=1|adicione \"subagentPromptCacheTtl\": \"1h\" e registre os hooks TaskCreated → task-quality.sh e TaskCompleted → check-story-progress.sh + check-social-progress.sh + check-proposal-progress.sh (matcher \"\") no settings.json do destino"
  fi
fi

# ── Hooks ────────────────────────────────────────────────────────────────────

if [ $INCLUDE_HOOKS -eq 1 ] && [ -d "$SOURCE/.claude/hooks" ]; then
  do_mkdir "$TARGET/.claude/hooks"

  hooks_copied=0
  # Copiar apenas hooks extras — o pacote padrão (block-worktree, block-git-push,
  # task-quality, check-story-progress, check-social-progress, check-proposal-progress,
  # guard-push-branch) já foi instalado acima, incondicionalmente.
  for hook_file in "$SOURCE/.claude/hooks/"*.sh; do
    [ -f "$hook_file" ] || continue
    hook_name=$(basename "$hook_file")

    case "$hook_name" in
      block-worktree.sh|block-git-push.sh|task-quality.sh|check-story-progress.sh|check-social-progress.sh|check-proposal-progress.sh|guard-push-branch.sh)
        continue ;;
    esac

    do_cp "$hook_file" "$TARGET/.claude/hooks/$hook_name"
    [ $DRY_RUN -eq 0 ] && chmod +x "$TARGET/.claude/hooks/$hook_name"
    hooks_copied=$((hooks_copied + 1))
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
