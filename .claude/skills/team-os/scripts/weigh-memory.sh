#!/usr/bin/env bash
# weigh-memory.sh — mede o "peso" da smart-memory e sinaliza se precisa de compactação.
# Dependency-free (bash, find, wc, awk). Roda nos projetos (só depende da skill team-os).
#
# Usage: weigh-memory.sh [--target <dir>] [--quiet]
#   --target <dir>  raiz do projeto (default: git root ou pwd)
#   --quiet         só imprime o bloco machine-readable (sem o resumo humano)
#
# Saída (sempre): um bloco WEIGH_* machine-readable que o /team-os lê na Fase 0.
#   WEIGH_STATUS=OK|HEAVY|ABSENT
#   WEIGH_LINES=<int>            (working set — exclui _archive/)
#   WEIGH_FILES=<int>
#   WEIGH_DONE=<int>             (arquivos em stories/done/, exclui LEDGER)
#   WEIGH_FAT=<int>              (arquivos > FAT_FILE_LINES no working set)
#   WEIGH_FAT_LIST=<paths;...>   (relativos à smart-memory)
#   WEIGH_ARCHIVE_LINES=<int>    (já arquivado em _archive/, não conta como peso)
#   WEIGH_DASHBOARD=<linha pronta p/ o painel de abertura>
#
# Limiares (ajustáveis por env): TOTAL_LINES_WARN, DONE_FILES_WARN, FAT_FILE_LINES

TOTAL_LINES_WARN="${TOTAL_LINES_WARN:-8000}"
DONE_FILES_WARN="${DONE_FILES_WARN:-30}"
FAT_FILE_LINES="${FAT_FILE_LINES:-1500}"

TARGET=""; QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --quiet)  QUIET=1; shift ;;
    *) shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  TARGET="$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)"
SM="$TARGET/docs/smart-memory"

# ── Smart-memory ausente ──────────────────────────────────────────────────────
if [ ! -d "$SM" ]; then
  echo "WEIGH_STATUS=ABSENT"
  echo "WEIGH_DASHBOARD=smart-memory : NÃO encontrada (rode discovery)"
  exit 0
fi

# Working set = tudo em docs/smart-memory EXCETO _archive/
# (o arquivo morto não conta como peso — é justamente o ponto da compactação)
# Sem mapfile (bash 3.2 do macOS não tem) — loop via while-read.
FILES=0
LINES=0
FAT=0
FAT_LIST=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  FILES=$((FILES + 1))
  n="$(wc -l < "$f" 2>/dev/null | tr -d ' ')"
  n="${n:-0}"
  LINES=$((LINES + n))
  if [ "$n" -gt "$FAT_FILE_LINES" ]; then
    FAT=$((FAT + 1))
    rel="${f#$SM/}"
    FAT_LIST="${FAT_LIST}${FAT_LIST:+;}${rel}(${n})"
  fi
done <<EOF
$(find "$SM" -type d -name '_archive' -prune -o -type f -name '*.md' -print 2>/dev/null)
EOF

# Stories concluídas (frias) — exclui um eventual LEDGER.md
DONE=0
if [ -d "$SM/stories/done" ]; then
  DONE="$(find "$SM/stories/done" -maxdepth 1 -type f -name '*.md' ! -name 'LEDGER.md' 2>/dev/null | wc -l | tr -d ' ')"
fi

# Já arquivado (informativo)
ARCHIVE_LINES=0
if [ -d "$SM/_archive" ]; then
  ARCHIVE_LINES="$(find "$SM/_archive" -type f -name '*.md' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')"
  ARCHIVE_LINES="${ARCHIVE_LINES:-0}"
fi

# ── Veredicto ─────────────────────────────────────────────────────────────────
STATUS="OK"
REASONS=""
[ "$LINES" -gt "$TOTAL_LINES_WARN" ] && { STATUS="HEAVY"; REASONS="${REASONS}${REASONS:+ · }${LINES} linhas"; }
[ "$DONE" -gt "$DONE_FILES_WARN" ]   && { STATUS="HEAVY"; REASONS="${REASONS}${REASONS:+ · }${DONE} stories done"; }
[ "$FAT" -gt 0 ]                     && { STATUS="HEAVY"; REASONS="${REASONS}${REASONS:+ · }${FAT} arquivo(s) > ${FAT_FILE_LINES} linhas"; }

if [ "$STATUS" = "HEAVY" ]; then
  DASH="smart-memory : ⚠ PESADA (${REASONS}) → /team-os *compact"
else
  DASH="smart-memory : OK (${LINES} linhas · ${FILES} arquivos${ARCHIVE_LINES:+ · ${ARCHIVE_LINES} arquivadas})"
fi

# ── Bloco machine-readable ────────────────────────────────────────────────────
echo "WEIGH_STATUS=$STATUS"
echo "WEIGH_LINES=$LINES"
echo "WEIGH_FILES=$FILES"
echo "WEIGH_DONE=$DONE"
echo "WEIGH_FAT=$FAT"
echo "WEIGH_FAT_LIST=$FAT_LIST"
echo "WEIGH_ARCHIVE_LINES=$ARCHIVE_LINES"
echo "WEIGH_DASHBOARD=$DASH"

# ── Resumo humano (opcional) ──────────────────────────────────────────────────
if [ "$QUIET" -ne 1 ]; then
  echo "---"
  echo "smart-memory: $SM"
  echo "  status        : $STATUS${REASONS:+  ($REASONS)}"
  echo "  working set   : $LINES linhas · $FILES arquivos"
  echo "  stories done  : $DONE"
  echo "  arquivo morto : $ARCHIVE_LINES linhas em _archive/"
  if [ "$FAT" -gt 0 ]; then
    echo "  gordos (> $FAT_FILE_LINES linhas):"
    printf '%s\n' "$FAT_LIST" | tr ';' '\n' | sed 's/^/    - /'
  fi
  echo "  limiares      : linhas>$TOTAL_LINES_WARN · done>$DONE_FILES_WARN · gordo>$FAT_FILE_LINES"
fi
