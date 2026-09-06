#!/usr/bin/env bash
# weigh-memory.sh — mede o "peso" da smart-memory e sinaliza se precisa de compactação.
# Dependency-free (bash 3.2, find, wc, awk). Roda nos projetos (só depende da skill team-os).
#
# Usage: weigh-memory.sh [--target <dir>] [--quiet]
#   --target <dir>  raiz do projeto (default: git root ou pwd)
#   --quiet         só imprime o bloco machine-readable (sem o resumo humano)
#
# Saída (sempre): um bloco WEIGH_* machine-readable que o /team-os lê na Fase 0.
#   WEIGH_STATUS=OK|HEAVY|ABSENT
#   WEIGH_LINES=<int>              (working set — exclui _archive/)
#   WEIGH_FILES=<int>
#   WEIGH_DONE=<int>               (arquivos em stories/done/, exclui LEDGER)
#   WEIGH_FAT=<int>                (informativo — arquivos > FAT_FILE_LINES no working set)
#   WEIGH_FAT_LIST=<paths;...>     (relativos à smart-memory)
#   WEIGH_RESOLVED=<int>           (informativo — notas resolved/superseded arquiváveis)
#   WEIGH_EXPIRED=<int>            (informativo — notas com `expires:` vencido, arquiváveis)
#   WEIGH_EXPIRED_LIST=<paths;...>
#   WEIGH_ARCHIVABLE=<int>         (resolved + expired)
#   WEIGH_BOOTSTRAP_<AREA>=<int>   (custo de leitura inicial da área em tokens ≈ palavras×1.33)
#   WEIGH_BOOTSTRAP_MAX=<int>      (pior área)
#   WEIGH_BOOTSTRAP_MAX_AREA=<área>
#   WEIGH_BOOTSTRAP_BUDGET=<int>
#   WEIGH_ARCHIVE_LINES=<int>      (já arquivado em _archive/, não conta como peso)
#   WEIGH_DASHBOARD=<valor pronto p/ o painel — SEM o rótulo "smart-memory :" (o SKILL renderiza)>
#
# Veredicto HEAVY: só quando (linhas > TOTAL_LINES_WARN) OU (done > DONE_FILES_WARN)
# OU (bootstrap da pior área > BOOTSTRAP_BUDGET_TOKENS). FAT files e notas
# resolved/expiradas são INFORMATIVOS ("arquiváveis") — não forçam HEAVY.
#
# Limiares (ajustáveis por env): TOTAL_LINES_WARN, DONE_FILES_WARN, FAT_FILE_LINES,
#                                BOOTSTRAP_BUDGET_TOKENS

TOTAL_LINES_WARN="${TOTAL_LINES_WARN:-8000}"
DONE_FILES_WARN="${DONE_FILES_WARN:-30}"
FAT_FILE_LINES="${FAT_FILE_LINES:-1500}"
BOOTSTRAP_BUDGET_TOKENS="${BOOTSTRAP_BUDGET_TOKENS:-2000}"

TARGET=""; QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "ERRO: --target requer um valor (diretório do projeto)" >&2
        exit 2
      fi
      TARGET="$2"; shift 2 ;;
    --quiet)  QUIET=1; shift ;;
    *) shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  TARGET="$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
# Guarda: cd falho deixaria TARGET vazio → SM viraria /docs/smart-memory
TARGET_RESOLVED="$(cd "$TARGET" 2>/dev/null && pwd)"
if [ -z "$TARGET_RESOLVED" ] || [ ! -d "$TARGET_RESOLVED" ]; then
  echo "ERRO: target não existe ou não é acessível: $TARGET" >&2
  exit 2
fi
TARGET="$TARGET_RESOLVED"
SM="$TARGET/docs/smart-memory"
TODAY="$(date +%F)"

# ── Smart-memory ausente ──────────────────────────────────────────────────────
if [ ! -d "$SM" ]; then
  echo "WEIGH_STATUS=ABSENT"
  echo "WEIGH_DASHBOARD=NÃO encontrada (rode discovery)"
  exit 0
fi

# Working set = tudo em docs/smart-memory EXCETO _archive/
# (o arquivo morto não conta como peso — é justamente o ponto da compactação)
# Sem mapfile (bash 3.2 do macOS não tem) — loop via while-read.

# Lê um campo do frontmatter YAML — ancorado: a LINHA 1 tem que ser `---`
# (um `---` no meio do corpo não abre frontmatter).
fm_field() { # $1=file $2=field
  awk -v f="$2" '
    NR==1 { if ($0 != "---") exit; inf=1; next }
    inf && /^---$/ { exit }
    inf && $0 ~ "^"f":" { sub("^"f":[[:space:]]*",""); gsub(/^["'"'"']|["'"'"']$/,""); print; exit }
  ' "$1"
}

# Conta palavras de um arquivo (0 se ausente)
wc_words() { # $1=file
  if [ -f "$1" ]; then wc -w < "$1" | tr -d ' '; else echo 0; fi
}

FILES=0
LINES=0
FAT=0
FAT_LIST=""
RESOLVED=0        # notas resolved/superseded ainda no working set (frias esquecidas)
EXPIRED=0         # notas com frontmatter `expires:` vencido (TTL) — arquiváveis
EXPIRED_LIST=""
NO_STATUS=0       # notas sem campo status (dívida de metadata — pré-v2)
AREAS_TMP=""      # acumulador "área linhas" para o top de áreas
while IFS= read -r f; do
  [ -n "$f" ] || continue
  FILES=$((FILES + 1))
  n="$(wc -l < "$f" 2>/dev/null | tr -d ' ')"
  n="${n:-0}"
  LINES=$((LINES + n))
  rel="${f#$SM/}"
  if [ "$n" -gt "$FAT_FILE_LINES" ]; then
    FAT=$((FAT + 1))
    FAT_LIST="${FAT_LIST}${FAT_LIST:+;}${rel}(${n})"
  fi
  # área = 2 primeiros níveis do path (ex.: agents/bi) ou 1º nível
  area="$(echo "$rel" | awk -F/ '{if (NF>=3) print $1"/"$2; else if (NF==2) print $1; else print "(raiz)"}')"
  AREAS_TMP="${AREAS_TMP}${area} ${n}
"
  # ciclo de vida (barato: só o frontmatter) — dívida de metadata só onde episódios vivem
  base="$(basename "$f")"
  case "$base" in DIGEST.md|INDEX.md|LEDGER.md|README.md|BACKLOG.md) : ;; *)
    st="$(fm_field "$f" status)"
    case "$st" in
      resolved|superseded) RESOLVED=$((RESOLVED + 1)) ;;
      "") case "$rel" in agents/*|decisions/*) NO_STATUS=$((NO_STATUS + 1)) ;; esac ;;
    esac
    # TTL: `expires: YYYY-MM-DD` no passado = arquivável (não conta duas vezes se já resolved)
    case "$st" in resolved|superseded) : ;; *)
      exp="$(fm_field "$f" expires)"
      case "$exp" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
          if [ "$exp" \< "$TODAY" ]; then
            EXPIRED=$((EXPIRED + 1))
            EXPIRED_LIST="${EXPIRED_LIST}${EXPIRED_LIST:+;}${rel}(exp:${exp})"
          fi ;;
      esac
    ;; esac
  ;; esac
done <<EOF
$(find "$SM" -type d -name '_archive' -prune -o -type f -name '*.md' -print 2>/dev/null)
EOF

# Top 5 áreas por linhas
AREAS_TOP="$(printf '%s' "$AREAS_TMP" | awk '{sum[$1]+=$2} END{for (a in sum) printf "%s(%d)\n", a, sum[a]}' | sort -t'(' -k2 -rn | head -5 | paste -sd';' -)"

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

# ── Orçamento de bootstrap por área ──────────────────────────────────────────
# Custo de leitura inicial de um agente da área = palavras de
# (INDEX.md + DIGEST.md da área + stories/active/*.md) × 1.33 ≈ tokens.
BASE_WORDS="$(wc_words "$SM/INDEX.md")"
ACTIVE_WORDS=0
if [ -d "$SM/stories/active" ]; then
  ACTIVE_WORDS="$(find "$SM/stories/active" -maxdepth 1 -type f -name '*.md' -exec cat {} + 2>/dev/null | wc -w | tr -d ' ')"
  ACTIVE_WORDS="${ACTIVE_WORDS:-0}"
fi
BOOTSTRAP_MAX=0
BOOTSTRAP_MAX_AREA="-"
BOOTSTRAP_BLOCK=""
if [ -d "$SM/agents" ]; then
  for d in "$SM/agents"/*/; do
    [ -d "$d" ] || continue
    area="$(basename "$d")"
    dw="$(wc_words "${d}DIGEST.md")"
    w=$((BASE_WORDS + ACTIVE_WORDS + dw))
    t=$(( w * 133 / 100 ))
    key="$(echo "$area" | tr 'a-z-' 'A-Z_' | tr -cd 'A-Z0-9_')"
    BOOTSTRAP_BLOCK="${BOOTSTRAP_BLOCK}WEIGH_BOOTSTRAP_${key}=${t}
"
    if [ "$t" -gt "$BOOTSTRAP_MAX" ]; then
      BOOTSTRAP_MAX="$t"
      BOOTSTRAP_MAX_AREA="$area"
    fi
  done
fi

# ── Veredicto ─────────────────────────────────────────────────────────────────
# HEAVY = peso estrutural (linhas, done, bootstrap acima do budget).
# FAT/RESOLVED/EXPIRED são informativos ("arquiváveis") — não forçam HEAVY.
STATUS="OK"
REASONS=""
[ "$LINES" -gt "$TOTAL_LINES_WARN" ] && { STATUS="HEAVY"; REASONS="${REASONS}${REASONS:+ · }${LINES} linhas"; }
[ "$DONE" -gt "$DONE_FILES_WARN" ]   && { STATUS="HEAVY"; REASONS="${REASONS}${REASONS:+ · }${DONE} stories done"; }
[ "$BOOTSTRAP_MAX" -gt "$BOOTSTRAP_BUDGET_TOKENS" ] && { STATUS="HEAVY"; REASONS="${REASONS}${REASONS:+ · }bootstrap ${BOOTSTRAP_MAX}t > ${BOOTSTRAP_BUDGET_TOKENS}t (${BOOTSTRAP_MAX_AREA})"; }

ARCHIVABLE=$((RESOLVED + EXPIRED))

if [ "$STATUS" = "HEAVY" ]; then
  DASH="⚠ PESADA (${REASONS}) · ${ARCHIVABLE} arquivável(is) → /team-os *compact"
else
  # (${VAR:+...} não serve aqui: "0" é não-vazio e imprimia "0 arquiváveis")
  ARCH_PART=""
  [ "$ARCHIVABLE" -gt 0 ] && ARCH_PART=" · ${ARCHIVABLE} arquivável(is) → *compact opcional"
  DASH="OK (${LINES} linhas · bootstrap max ${BOOTSTRAP_MAX}t/${BOOTSTRAP_BUDGET_TOKENS}t${ARCH_PART})"
fi

# ── Bloco machine-readable ────────────────────────────────────────────────────
echo "WEIGH_STATUS=$STATUS"
echo "WEIGH_LINES=$LINES"
echo "WEIGH_FILES=$FILES"
echo "WEIGH_DONE=$DONE"
echo "WEIGH_FAT=$FAT"
echo "WEIGH_FAT_LIST=$FAT_LIST"
echo "WEIGH_RESOLVED=$RESOLVED"
echo "WEIGH_EXPIRED=$EXPIRED"
echo "WEIGH_EXPIRED_LIST=$EXPIRED_LIST"
echo "WEIGH_ARCHIVABLE=$ARCHIVABLE"
echo "WEIGH_NO_STATUS=$NO_STATUS"
echo "WEIGH_AREAS_TOP=$AREAS_TOP"
printf '%s' "$BOOTSTRAP_BLOCK"
echo "WEIGH_BOOTSTRAP_MAX=$BOOTSTRAP_MAX"
echo "WEIGH_BOOTSTRAP_MAX_AREA=$BOOTSTRAP_MAX_AREA"
echo "WEIGH_BOOTSTRAP_BUDGET=$BOOTSTRAP_BUDGET_TOKENS"
echo "WEIGH_ARCHIVE_LINES=$ARCHIVE_LINES"
echo "WEIGH_DASHBOARD=$DASH"

# ── Resumo humano (opcional) ──────────────────────────────────────────────────
if [ "$QUIET" -ne 1 ]; then
  echo "---"
  echo "smart-memory: $SM"
  echo "  status        : $STATUS${REASONS:+  ($REASONS)}"
  echo "  working set   : $LINES linhas · $FILES arquivos"
  echo "  bootstrap     : pior área = $BOOTSTRAP_MAX_AREA ($BOOTSTRAP_MAX tokens / budget $BOOTSTRAP_BUDGET_TOKENS)"
  if [ -n "$BOOTSTRAP_BLOCK" ]; then
    printf '%s' "$BOOTSTRAP_BLOCK" | sed 's/^WEIGH_BOOTSTRAP_/    - /; s/=/ : /' | tr 'A-Z_' 'a-z-'
  fi
  echo "  stories done  : $DONE"
  echo "  arquiváveis   : $ARCHIVABLE ($RESOLVED resolved/superseded + $EXPIRED expirada(s) por TTL)"
  if [ "$EXPIRED" -gt 0 ]; then
    echo "  expiradas (TTL vencido):"
    printf '%s\n' "$EXPIRED_LIST" | tr ';' '\n' | sed 's/^/    - /'
  fi
  echo "  sem metadata  : $NO_STATUS nota(s) sem status (pré-v2 — archivist infere no *compact)"
  echo "  top áreas     : $(echo "$AREAS_TOP" | tr ';' ' ')"
  echo "  arquivo morto : $ARCHIVE_LINES linhas em _archive/"
  if [ "$FAT" -gt 0 ]; then
    echo "  gordos (> $FAT_FILE_LINES linhas — informativos, candidatos a --archive-file):"
    printf '%s\n' "$FAT_LIST" | tr ';' '\n' | sed 's/^/    - /'
  fi
  echo "  limiares      : linhas>$TOTAL_LINES_WARN · done>$DONE_FILES_WARN · bootstrap>$BOOTSTRAP_BUDGET_TOKENS t · gordo>$FAT_FILE_LINES (info)"
  if [ "$STATUS" = "HEAVY" ] || [ "$ARCHIVABLE" -gt 0 ]; then
    echo "  recomendação  : /team-os *compact"
  fi
fi
