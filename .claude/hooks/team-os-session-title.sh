#!/usr/bin/env bash
# .claude/hooks/team-os-session-title.sh
# SessionStart hook — nomeia a sessão pelo PROJETO (+ branch git), igual ao /rename.
# Resolve o problema de toda sessão team-os ficar com nome genérico ("team-os ...")
# e impossível de identificar no agent view / no /resume.
#
# Como funciona:
# - Recebe via stdin o JSON do SessionStart: {"source":"startup|resume|clear|compact",
#   "cwd":"/path/do/projeto", "session_title":"<título atual>", ...}
# - Só age em source == startup | resume (sessionTitle é ignorado em clear/compact pela spec).
# - title = nome da pasta do projeto, + " · <branch>" quando há branch git (não-detached).
# - Em resume, PRESERVA um rename deliberado do usuário; só sobrescreve título vazio,
#   título antigo genérico ("team-os ...") ou o próprio padrão (refresh da branch).
# - Emite {"hookSpecificOutput":{"hookEventName":"SessionStart","sessionTitle":"..."}}.
#
# Registro: SessionStart hook em ~/.claude/settings.json (global) ou .claude/settings.json (projeto).

INPUT=$(cat)

# Helper: extrai um campo string de 1º nível do JSON (sem dependência de jq)
json_field() {
  printf '%s' "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
    | sed "s/\"$1\"[[:space:]]*:[[:space:]]*\"//;s/\"$//"
}

SOURCE=$(json_field "source")
CWD=$(json_field "cwd")
CURRENT=$(json_field "session_title")

# Só nomeia em startup/resume (a spec ignora sessionTitle em clear/compact)
case "$SOURCE" in
  startup|resume) ;;
  *) exit 0 ;;
esac

[ -z "$CWD" ] && CWD="$PWD"
PROJ=$(basename "$CWD")
[ -z "$PROJ" ] && exit 0

# Branch git (se houver e não estiver detached)
BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
TITLE="$PROJ"
if [ -n "$BRANCH" ] && [ "$BRANCH" != "HEAD" ]; then
  TITLE="$PROJ · $BRANCH"
fi

# Em resume, preservar rename deliberado do usuário.
# Sobrescreve apenas: título vazio | genérico antigo ("team-os ...") | nosso próprio padrão (começa com o nome do projeto).
if [ "$SOURCE" = "resume" ] && [ -n "$CURRENT" ]; then
  case "$CURRENT" in
    team-os*|"$PROJ"|"$PROJ "*) ;;   # genérico antigo ou nosso padrão → atualiza
    *) exit 0 ;;                       # rename deliberado do usuário → mantém
  esac
fi
# Em startup, um session_title já presente significa --name explícito → respeita
if [ "$SOURCE" = "startup" ] && [ -n "$CURRENT" ]; then
  exit 0
fi

# Escapa aspas e barras invertidas para JSON
ESC_TITLE=$(printf '%s' "$TITLE" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","sessionTitle":"%s"}}\n' "$ESC_TITLE"
exit 0
