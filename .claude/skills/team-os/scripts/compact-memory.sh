#!/usr/bin/env bash
# compact-memory.sh — compacta a smart-memory movendo conteúdo frio para _archive/ + LEDGER.
# NUNCA hard-deleta: só MOVE (mv). O conteúdo integral fica em docs/smart-memory/_archive/YYYY-QN/.
# Dependency-free (bash 3.2 compatível — sem mapfile). Roda nos projetos.
#
# Usage:
#   compact-memory.sh [--target <dir>] [--dry-run]
#       Ação padrão: (a) arquiva TODAS as stories em stories/done/ → _archive/<Q>/stories-done/
#       e atualiza stories/done/LEDGER.md (uma linha por story); (b) arquiva toda nota com
#       frontmatter `status: resolved|superseded` → _archive/<Q>/resolved/ + _archive/LEDGER.md;
#       (c) arquiva toda nota com frontmatter `expires: YYYY-MM-DD` vencido (TTL) →
#       _archive/<Q>/expired/ + LEDGER marcado "(expired)".
#       (exceto kind: reference|digest, DIGEST.md, INDEX.md e tudo sob stories/ não-done).
#       Ao final, reporta o _inbox/ (COMPACT_INBOX_PENDING=) e os wikilinks órfãos
#       deixados pelos moves (COMPACT_ORPHAN_LINKS=).
#
#   compact-memory.sh --archive-file <path-relativo-à-smart-memory> [--target <dir>] [--dry-run]
#       Arquiva UM arquivo específico (ex.: um append-only gordo) → _archive/<Q>/misc/
#       e registra no LEDGER geral (_archive/LEDGER.md). Mesmas guardas do modo padrão:
#       nunca INDEX.md/DIGEST.md/LEDGER.md, nunca kind: reference|digest, nada fora de
#       docs/smart-memory/, paths com `..` rejeitados.
#
#   compact-memory.sh --clear-inbox <arquivo> [--target <dir>] [--dry-run]
#       Move UMA nota do _inbox/ JÁ CONSOLIDADA pelo archivist → _archive/<Q>/inbox/.
#       (A consolidação semântica é do archivist — o script só reporta e move.)
#
#   --dry-run   mostra o que faria, sem mover nada.
#
# Segurança: nunca toca em stories/active, in-review, backlog, project/, decisions/, INDEX.md.
# O que for para _archive/ some do working set (agentes não leem _archive/ por convenção).

TARGET=""; DRY=0; ARCHIVE_FILE=""; CLEAR_INBOX=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "ERRO: --target requer um valor (diretório do projeto)" >&2
        exit 2
      fi
      TARGET="$2"; shift 2 ;;
    --dry-run)      DRY=1; shift ;;
    --archive-file)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "ERRO: --archive-file requer um valor (path relativo à smart-memory)" >&2
        exit 2
      fi
      ARCHIVE_FILE="$2"; shift 2 ;;
    --clear-inbox)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "ERRO: --clear-inbox requer um valor (arquivo do _inbox/)" >&2
        exit 2
      fi
      CLEAR_INBOX="$2"; shift 2 ;;
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
DATE="$(date +%F)"
TODAY="$DATE"
# Quarter atual: YYYY-QN
Y="$(date +%Y)"; M="$(date +%m | sed 's/^0//')"
Q=$(( (M - 1) / 3 + 1 ))
QDIR="$Y-Q$Q"

if [ ! -d "$SM" ]; then
  echo "ABORT: smart-memory não existe em $SM (rode discovery primeiro)." >&2
  exit 2
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

# Extrai título de um .md (frontmatter title: ou 1º heading #)
md_title() {
  local file="$1" t=""
  t="$(grep -m1 '^title:' "$file" 2>/dev/null | sed 's/^title:[[:space:]]*//; s/^["'"'"']//; s/["'"'"']$//')"
  [ -z "$t" ] && t="$(grep -m1 '^# ' "$file" 2>/dev/null | sed 's/^# //')"
  [ -z "$t" ] && t="$(basename "$file" .md)"
  # escapa pipe para não quebrar a tabela markdown
  echo "$t" | tr '|' '/'
}

# Lê um campo do frontmatter YAML — ancorado: a LINHA 1 tem que ser `---`
# (um `---` no meio do corpo não abre frontmatter).
fm_field() { # $1=file $2=field
  awk -v f="$2" '
    NR==1 { if ($0 != "---") exit; inf=1; next }
    inf && /^---$/ { exit }
    inf && $0 ~ "^"f":" { sub("^"f":[[:space:]]*",""); gsub(/^["'"'"']|["'"'"']$/,""); print; exit }
  ' "$1"
}

# Destino sem sobrescrever (anti-colisão): sufixo -2, -3, … — zero perda.
safe_dest() { # $1=dest_dir $2=basename → imprime path livre
  local dir="$1" base="$2" stem ext n=2 cand
  cand="$dir/$base"
  if [ ! -e "$cand" ]; then echo "$cand"; return; fi
  stem="${base%.md}"; ext=".md"
  while [ -e "$dir/$stem-$n$ext" ]; do n=$((n + 1)); done
  echo "$dir/$stem-$n$ext"
}

# Garante o LEDGER geral
ensure_ledger() { # $1=ledger-path
  if [ ! -f "$1" ]; then
    printf '# Arquivo — LEDGER geral\n\n| Data | Origem | Título | Linhas | Arquivo |\n|---|---|---|---|---|\n' > "$1"
  fi
}

# Acumulador de stems movidos (p/ varredura de wikilinks órfãos pós-mv)
MOVED_STEMS=""
note_moved() { # $1=basename-original (com .md)
  MOVED_STEMS="${MOVED_STEMS}$(basename "$1" .md)
"
}

# Varre o working set por wikilinks [[...]] que apontam para arquivos movidos.
report_orphans() {
  local n=0 stem esc hits
  if [ "$DRY" -eq 1 ] || [ -z "$MOVED_STEMS" ]; then
    echo "COMPACT_ORPHAN_LINKS=0"
    return
  fi
  while IFS= read -r stem; do
    [ -n "$stem" ] || continue
    esc="$(printf '%s' "$stem" | sed 's/[][\.*^$\/]/\\&/g')"
    hits="$(grep -R --include='*.md' --exclude-dir=_archive -l -e "\[\[[^]]*${esc}" "$SM" 2>/dev/null)"
    if [ -n "$hits" ]; then
      n=$((n + 1))
      echo "ORPHAN_LINK: [[${stem}]] ainda referenciado em:"
      echo "$hits" | sed "s#^$SM/#  - #"
    fi
  done <<EOF
$MOVED_STEMS
EOF
  echo "COMPACT_ORPHAN_LINKS=$n"
}

# Reporta o _inbox/ (a consolidação semântica é do archivist — aqui só relatório).
report_inbox() {
  local n=0 f
  if [ -d "$SM/_inbox" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      n=$((n + 1))
      echo "INBOX: ${f#$SM/}"
    done <<EOF
$(find "$SM/_inbox" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
EOF
  fi
  echo "COMPACT_INBOX_PENDING=$n"
}

# ── Modo: arquivar UM arquivo específico ──────────────────────────────────────
if [ -n "$ARCHIVE_FILE" ]; then
  # Guardas de path: relativo à smart-memory, sem `..`
  case "$ARCHIVE_FILE" in
    /*)   echo "ABORT: --archive-file deve ser RELATIVO à smart-memory (recebi path absoluto)." >&2; exit 2 ;;
    *..*) echo "ABORT: path com '..' rejeitado: $ARCHIVE_FILE" >&2; exit 2 ;;
  esac
  BASE="$(basename "$ARCHIVE_FILE")"
  case "$BASE" in
    INDEX.md|DIGEST.md|LEDGER.md)
      echo "ABORT: '$BASE' é protegido — nunca arquivado (mesmas guardas do modo padrão)." >&2; exit 2 ;;
  esac
  SRC="$SM/$ARCHIVE_FILE"
  if [ ! -f "$SRC" ]; then
    echo "ABORT: arquivo não encontrado: $SRC" >&2
    exit 2
  fi
  K="$(fm_field "$SRC" kind)"
  case "$K" in
    reference|digest)
      echo "ABORT: kind: $K é conhecimento vivo — nunca arquivado (atualize in-place)." >&2; exit 2 ;;
  esac
  DEST_DIR="$SM/_archive/$QDIR/misc"
  LINES="$(wc -l < "$SRC" | tr -d ' ')"
  TITLE="$(md_title "$SRC")"
  if [ "$DRY" -eq 1 ]; then
    echo "DRY-RUN: moveria '$ARCHIVE_FILE' ($LINES linhas) → _archive/$QDIR/misc/"
    report_orphans
    exit 0
  fi
  mkdir -p "$DEST_DIR"
  DEST="$(safe_dest "$DEST_DIR" "$BASE")"
  mv "$SRC" "$DEST"
  note_moved "$BASE"
  LEDGER="$SM/_archive/LEDGER.md"
  ensure_ledger "$LEDGER"
  printf '| %s | `%s` | %s | %s | `_archive/%s/misc/%s` |\n' \
    "$DATE" "$ARCHIVE_FILE" "$TITLE" "$LINES" "$QDIR" "$(basename "$DEST")" >> "$LEDGER"
  echo "DONE: '$ARCHIVE_FILE' → _archive/$QDIR/misc/ · registrado em _archive/LEDGER.md"
  report_orphans
  exit 0
fi

# ── Modo: limpar UMA nota consolidada do _inbox/ ──────────────────────────────
if [ -n "$CLEAR_INBOX" ]; then
  case "$CLEAR_INBOX" in
    /*)   echo "ABORT: --clear-inbox deve ser um arquivo do _inbox/ (path relativo)." >&2; exit 2 ;;
    *..*) echo "ABORT: path com '..' rejeitado: $CLEAR_INBOX" >&2; exit 2 ;;
  esac
  # aceita "nota.md" ou "_inbox/nota.md"
  REL="${CLEAR_INBOX#_inbox/}"
  SRC="$SM/_inbox/$REL"
  if [ ! -f "$SRC" ]; then
    echo "ABORT: nota não encontrada no _inbox/: $REL" >&2
    exit 2
  fi
  LINES="$(wc -l < "$SRC" | tr -d ' ')"
  TITLE="$(md_title "$SRC")"
  if [ "$DRY" -eq 1 ]; then
    echo "DRY-RUN: moveria '_inbox/$REL' ($LINES linhas) → _archive/$QDIR/inbox/"
    exit 0
  fi
  DEST_DIR="$SM/_archive/$QDIR/inbox"
  mkdir -p "$DEST_DIR"
  DEST="$(safe_dest "$DEST_DIR" "$(basename "$REL")")"
  mv "$SRC" "$DEST"
  note_moved "$(basename "$REL")"
  LEDGER="$SM/_archive/LEDGER.md"
  ensure_ledger "$LEDGER"
  printf '| %s | `_inbox/%s` (inbox consolidado) | %s | %s | `_archive/%s/inbox/%s` |\n' \
    "$DATE" "$REL" "$TITLE" "$LINES" "$QDIR" "$(basename "$DEST")" >> "$LEDGER"
  echo "DONE: '_inbox/$REL' → _archive/$QDIR/inbox/ · registrado em _archive/LEDGER.md"
  report_orphans
  exit 0
fi

# ── Modo padrão (partes b+c): notas resolved/superseded + TTL vencido ─────────
archive_cold() {
  local moved_res=0 moved_exp=0 ledger="$SM/_archive/LEDGER.md"
  local f base st k rel lines title flat dest reason dest_sub exp mark
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base="$(basename "$f")"
    # proteções: nunca DIGEST/INDEX/LEDGER, nunca kind reference|digest
    case "$base" in DIGEST.md|INDEX.md|LEDGER.md|README.md) continue ;; esac
    k="$(fm_field "$f" kind)"
    case "$k" in reference|digest) continue ;; esac
    rel="${f#$SM/}"
    # nunca tocar stories/ fora de done (active/in-review/backlog são do fluxo de stories)
    # nem project/ e decisions/ (contrato do header: estado permanente, nunca arquivado)
    # _inbox/ é do fluxo de consolidação (--clear-inbox) — o modo padrão não o toca
    case "$rel" in stories/*|project/*|decisions/*|_inbox/*) continue ;; esac
    st="$(fm_field "$f" status)"
    reason=""
    case "$st" in resolved|superseded) reason="resolved" ;; esac
    if [ -z "$reason" ]; then
      # TTL: expires vencido → arquivável automaticamente
      exp="$(fm_field "$f" expires)"
      case "$exp" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
          [ "$exp" \< "$TODAY" ] && reason="expired" ;;
      esac
    fi
    [ -n "$reason" ] || continue
    lines="$(wc -l < "$f" | tr -d ' ')"
    title="$(md_title "$f")"
    if [ "$reason" = "expired" ]; then
      dest_sub="expired"; mark=" (expired)"
    else
      dest_sub="resolved"; mark=""
    fi
    if [ "$DRY" -eq 1 ]; then
      if [ "$reason" = "expired" ]; then
        echo "DRY-RUN: moveria '$rel' (expires=$exp vencido, $lines linhas) → _archive/$QDIR/expired/"
        moved_exp=$((moved_exp + 1))
      else
        echo "DRY-RUN: moveria '$rel' (status=$st, $lines linhas) → _archive/$QDIR/resolved/"
        moved_res=$((moved_res + 1))
      fi
      continue
    fi
    mkdir -p "$SM/_archive/$QDIR/$dest_sub"
    ensure_ledger "$ledger"
    # nome achatado do path relativo (agents/qa/audit.md → agents-qa-audit.md)
    # evita colisão entre áreas; safe_dest cobre colisão residual no mesmo quarter
    flat="$(echo "$rel" | tr '/' '-')"
    dest="$(safe_dest "$SM/_archive/$QDIR/$dest_sub" "$flat")"
    mv "$f" "$dest"
    note_moved "$base"
    printf '| %s | `%s`%s | %s | %s | `_archive/%s/%s/%s` |\n' \
      "$DATE" "$rel" "$mark" "$title" "$lines" "$QDIR" "$dest_sub" "$(basename "$dest")" >> "$ledger"
    if [ "$reason" = "expired" ]; then moved_exp=$((moved_exp + 1)); else moved_res=$((moved_res + 1)); fi
  done <<EOF
$(find "$SM" -type d -name '_archive' -prune -o -type f -name '*.md' -print 2>/dev/null)
EOF
  if [ "$DRY" -eq 1 ]; then
    echo "RESOLVED: $moved_res nota(s) resolved/superseded a arquivar"
    echo "EXPIRED: $moved_exp nota(s) com TTL vencido a arquivar"
  else
    [ "$moved_res" -gt 0 ] && echo "DONE: $moved_res nota(s) resolved/superseded → _archive/$QDIR/resolved/"
    [ "$moved_exp" -gt 0 ] && echo "DONE: $moved_exp nota(s) expirada(s) por TTL → _archive/$QDIR/expired/"
  fi
}

# ── Modo padrão (parte a): arquivar stories/done/ ─────────────────────────────
DONE_DIR="$SM/stories/done"

# Coleta as stories done (exclui um LEDGER existente)
COUNT=0
if [ -d "$DONE_DIR" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    COUNT=$((COUNT + 1))
  done <<EOF
$(find "$DONE_DIR" -maxdepth 1 -type f -name '*.md' ! -name 'LEDGER.md' 2>/dev/null)
EOF
fi

if [ "$COUNT" -eq 0 ]; then
  echo "stories/done/: nada para arquivar."
  # partes (b)+(c) rodam mesmo assim — notas frias espalhadas pelas áreas
  archive_cold
  report_inbox
  report_orphans
  exit 0
fi

DEST_DIR="$SM/_archive/$QDIR/stories-done"
LEDGER="$DONE_DIR/LEDGER.md"

if [ "$DRY" -eq 1 ]; then
  echo "DRY-RUN: arquivaria $COUNT story(ies) de stories/done/ → _archive/$QDIR/stories-done/"
  echo "         e registraria cada uma em stories/done/LEDGER.md"
  find "$DONE_DIR" -maxdepth 1 -type f -name '*.md' ! -name 'LEDGER.md' 2>/dev/null \
    | sed "s#$DONE_DIR/#  - #"
  archive_cold
  report_inbox
  report_orphans
  exit 0
fi

mkdir -p "$DEST_DIR"

# Cria o LEDGER se não existir
if [ ! -f "$LEDGER" ]; then
  cat > "$LEDGER" <<EOF
---
title: "Ledger de Stories Concluídas"
type: ledger
agent: team-os (compact)
created: $DATE
updated: $DATE
tags: [ledger, done, archive]
---

# Ledger — Stories Concluídas

> Índice das stories arquivadas em \`_archive/\`. Conteúdo integral preservado lá.
> Este arquivo fica em \`stories/done/\` (leve); o texto completo saiu do working set.

| Story | Título | Arquivada em | Localização |
|---|---|---|---|
EOF
fi

MOVED=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  base="$(basename "$f")"
  title="$(md_title "$f")"
  story="$(echo "$base" | sed 's/\.md$//')"
  dest="$(safe_dest "$DEST_DIR" "$base")"
  mv "$f" "$dest"
  note_moved "$base"
  printf '| `%s` | %s | %s | `_archive/%s/stories-done/%s` |\n' \
    "$story" "$title" "$DATE" "$QDIR" "$(basename "$dest")" >> "$LEDGER"
  MOVED=$((MOVED + 1))
done <<EOF
$(find "$DONE_DIR" -maxdepth 1 -type f -name '*.md' ! -name 'LEDGER.md' 2>/dev/null)
EOF

# atualiza o campo updated do ledger (best-effort)
sed -i.bak "s/^updated:.*/updated: $DATE/" "$LEDGER" 2>/dev/null && rm -f "$LEDGER.bak"

echo "DONE: $MOVED story(ies) arquivada(s) → _archive/$QDIR/stories-done/"
echo "  index: stories/done/LEDGER.md ($MOVED linha(s) adicionada(s))"

# partes (b)+(c): notas resolved/superseded + TTL vencido nas áreas
archive_cold

# relatório final: inbox pendente + wikilinks órfãos deixados pelos moves
report_inbox
report_orphans

echo "  working set aliviado — agentes não leem _archive/ por convenção."
