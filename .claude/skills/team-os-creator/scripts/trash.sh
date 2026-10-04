#!/usr/bin/env bash
# trash.sh — manda arquivos e pastas para a Lixeira, no macOS e no Linux. NUNCA apaga.
#
# Como comando:     bash trash.sh <caminho>...
#                   → uma linha por item: TRASHED=<caminho>|<onde foi parar>
#                     (ou TRASH_FAILED=<caminho>|<motivo>); exit 1 se algum falhou
# Como biblioteca:  . trash.sh ; team_os_trash <caminho>...
#                   (mesma saída; devolve 1 se algum falhou)
#
# Ordem de destino:
#   1. TEAM_OS_TRASH_DIR (se definida — usada pelos testes): move para lá
#   2. macOS: ~/.Trash/
#   3. Linux: `gio trash` → `trash-put` → ${XDG_DATA_HOME:-~/.local/share}/Trash/files
#      (com o .trashinfo do padrão freedesktop, para o "Restaurar" do gerenciador de arquivos)
# Nome repetido na Lixeira ganha sufixo .<data-hora>[.<n>] — nada é sobrescrito.
# Bash 3.2-safe (sem mapfile, declare -A, ${x,,}).

_team_os_trash_unique() {  # _team_os_trash_unique <pasta> <nome> → caminho livre
  local dir="$1" base="$2" cand n
  cand="$dir/$base"
  [ -e "$cand" ] || [ -L "$cand" ] || { printf '%s\n' "$cand"; return 0; }
  cand="$dir/$base.$(date +%Y%m%d-%H%M%S)"
  n=1
  while [ -e "$cand" ] || [ -L "$cand" ]; do
    cand="$dir/$base.$(date +%Y%m%d-%H%M%S).$n"; n=$((n + 1))
  done
  printf '%s\n' "$cand"
}

_team_os_trash_one() {  # _team_os_trash_one <caminho>
  local p="$1" abs base dest data files info enc
  if [ ! -e "$p" ] && [ ! -L "$p" ]; then
    echo "TRASH_FAILED=$p|não existe"; return 1
  fi
  base="$(basename "$p")"
  abs="$(cd "$(dirname "$p")" 2>/dev/null && pwd)/$base"

  # 1. destino forçado (testes)
  if [ -n "${TEAM_OS_TRASH_DIR:-}" ]; then
    mkdir -p "$TEAM_OS_TRASH_DIR" || { echo "TRASH_FAILED=$p|não consegui criar $TEAM_OS_TRASH_DIR"; return 1; }
    dest="$(_team_os_trash_unique "$TEAM_OS_TRASH_DIR" "$base")"
    mv -- "$p" "$dest" && { echo "TRASHED=$p|$dest"; return 0; }
    echo "TRASH_FAILED=$p|mv falhou"; return 1
  fi

  # 2. macOS
  if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
    mkdir -p "$HOME/.Trash" 2>/dev/null
    dest="$(_team_os_trash_unique "$HOME/.Trash" "$base")"
    mv -- "$p" "$dest" && { echo "TRASHED=$p|$dest"; return 0; }
    echo "TRASH_FAILED=$p|mv para ~/.Trash falhou"; return 1
  fi

  # 3. Linux / outros
  if command -v gio >/dev/null 2>&1 && gio trash -- "$abs" 2>/dev/null; then
    echo "TRASHED=$p|gio trash"; return 0
  fi
  if command -v trash-put >/dev/null 2>&1 && trash-put -- "$abs" 2>/dev/null; then
    echo "TRASHED=$p|trash-put"; return 0
  fi
  data="${XDG_DATA_HOME:-$HOME/.local/share}"
  files="$data/Trash/files"; info="$data/Trash/info"
  mkdir -p "$files" "$info" 2>/dev/null || { echo "TRASH_FAILED=$p|não consegui criar $files"; return 1; }
  dest="$(_team_os_trash_unique "$files" "$base")"
  enc="$abs"
  if command -v python3 >/dev/null 2>&1; then
    enc="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$abs" 2>/dev/null || printf '%s' "$abs")"
  fi
  if mv -- "$p" "$dest"; then
    printf '[Trash Info]\nPath=%s\nDeletionDate=%s\n' "$enc" "$(date +%Y-%m-%dT%H:%M:%S)" \
      > "$info/$(basename "$dest").trashinfo" 2>/dev/null
    echo "TRASHED=$p|$dest"; return 0
  fi
  echo "TRASH_FAILED=$p|mv para $files falhou"; return 1
}

team_os_trash() {  # team_os_trash <caminho>...
  local rc=0 p
  for p in "$@"; do
    _team_os_trash_one "$p" || rc=1
  done
  return $rc
}

# Executado direto (não via `source`): trata os argumentos como caminhos
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  if [ $# -eq 0 ]; then
    echo "Uso: bash trash.sh <caminho>..." >&2; exit 2
  fi
  team_os_trash "$@"; exit $?
fi
