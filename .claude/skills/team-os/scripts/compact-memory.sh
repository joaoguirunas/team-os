#!/usr/bin/env bash
# compact-memory.sh — compacta a smart-memory movendo conteúdo frio para _archive/ + LEDGER.
# NUNCA hard-deleta: só MOVE (mv). O conteúdo integral fica em docs/smart-memory/_archive/YYYY-QN/.
# Dependency-free (bash 3.2 compatível — sem mapfile). Roda nos projetos.
#
# Usage:
#   compact-memory.sh [--target <dir>] [--dry-run]
#       Ação padrão: (a) arquiva TODAS as stories em stories/done/ → _archive/<Q>/stories-done/
#       e atualiza stories/done/LEDGER.md (uma linha por story); (b) arquiva toda nota com
#       frontmatter `status: resolved|superseded` → _archive/<Q>/resolved/ + _archive/LEDGER.md
#       (exceto kind: reference|digest, DIGEST.md, INDEX.md e tudo sob stories/ não-done).
#
#   compact-memory.sh --archive-file <path-relativo-à-smart-memory> [--target <dir>] [--dry-run]
#       Arquiva UM arquivo específico (ex.: um append-only gordo) → _archive/<Q>/misc/
#       e registra no LEDGER geral (_archive/LEDGER.md). Use para os "gordos" sinalizados
#       pelo weigh-memory.sh que você decidiu esfriar.
#
#   --dry-run   mostra o que faria, sem mover nada.
#
# Segurança: nunca toca em stories/active, in-review, backlog, project/, decisions/, INDEX.md.
# O que for para _archive/ some do working set (agentes não leem _archive/ por convenção).

TARGET=""; DRY=0; ARCHIVE_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target)       TARGET="$2"; shift 2 ;;
    --dry-run)      DRY=1; shift ;;
    --archive-file) ARCHIVE_FILE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  TARGET="$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)"
SM="$TARGET/docs/smart-memory"
DATE="$(date +%F)"
# Quarter atual: YYYY-QN
Y="$(date +%Y)"; M="$(date +%-m 2>/dev/null || date +%m | sed 's/^0//')"
Q=$(( (M - 1) / 3 + 1 ))
QDIR="$Y-Q$Q"

if [ ! -d "$SM" ]; then
  echo "ABORT: smart-memory não existe em $SM (rode discovery primeiro)." >&2
  exit 2
fi

# ── Helper: extrai título de um .md (frontmatter title: ou 1º heading #) ───────
md_title() {
  local file="$1" t=""
  t="$(grep -m1 '^title:' "$file" 2>/dev/null | sed 's/^title:[[:space:]]*//; s/^["'"'"']//; s/["'"'"']$//')"
  [ -z "$t" ] && t="$(grep -m1 '^# ' "$file" 2>/dev/null | sed 's/^# //')"
  [ -z "$t" ] && t="$(basename "$file" .md)"
  # escapa pipe para não quebrar a tabela markdown
  echo "$t" | tr '|' '/'
}

# ── Modo: arquivar UM arquivo específico ──────────────────────────────────────
if [ -n "$ARCHIVE_FILE" ]; then
  SRC="$SM/$ARCHIVE_FILE"
  if [ ! -f "$SRC" ]; then
    echo "ABORT: arquivo não encontrado: $SRC" >&2
    exit 2
  fi
  DEST_DIR="$SM/_archive/$QDIR/misc"
  DEST="$DEST_DIR/$(basename "$ARCHIVE_FILE")"
  LINES="$(wc -l < "$SRC" | tr -d ' ')"
  TITLE="$(md_title "$SRC")"
  if [ "$DRY" -eq 1 ]; then
    echo "DRY-RUN: moveria '$ARCHIVE_FILE' ($LINES linhas) → _archive/$QDIR/misc/"
    exit 0
  fi
  mkdir -p "$DEST_DIR"
  mv "$SRC" "$DEST"
  LEDGER="$SM/_archive/LEDGER.md"
  if [ ! -f "$LEDGER" ]; then
    printf '# Arquivo — LEDGER geral\n\n| Data | Origem | Título | Linhas | Arquivo |\n|---|---|---|---|---|\n' > "$LEDGER"
  fi
  printf '| %s | `%s` | %s | %s | `_archive/%s/misc/%s` |\n' \
    "$DATE" "$ARCHIVE_FILE" "$TITLE" "$LINES" "$QDIR" "$(basename "$ARCHIVE_FILE")" >> "$LEDGER"
  echo "DONE: '$ARCHIVE_FILE' → _archive/$QDIR/misc/ · registrado em _archive/LEDGER.md"
  exit 0
fi

# ── Helpers de frontmatter (para o modo resolved) ─────────────────────────────
# Lê um campo do frontmatter YAML (primeiro bloco --- ... ---)
fm_field() { # $1=file $2=field
  awk -v f="$2" 'BEGIN{inf=0} /^---$/{c++; if(c==2)exit; inf=1; next} inf && $0 ~ "^"f":" {sub("^"f":[[:space:]]*",""); gsub(/^["'"'"']|["'"'"']$/,""); print; exit}' "$1"
}

# ── Modo padrão (parte b): arquivar notas resolved/superseded ─────────────────
archive_resolved() {
  local moved=0 dest_dir="$SM/_archive/$QDIR/resolved" ledger="$SM/_archive/LEDGER.md"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base="$(basename "$f")"
    # proteções: nunca DIGEST/INDEX/LEDGER, nunca kind reference|digest
    case "$base" in DIGEST.md|INDEX.md|LEDGER.md|README.md) continue ;; esac
    st="$(fm_field "$f" status)"
    case "$st" in resolved|superseded) : ;; *) continue ;; esac
    k="$(fm_field "$f" kind)"
    case "$k" in reference|digest) continue ;; esac
    rel="${f#$SM/}"
    # nunca tocar stories/ fora de done (active/in-review/backlog são do fluxo de stories)
    case "$rel" in stories/*) continue ;; esac
    lines="$(wc -l < "$f" | tr -d ' ')"
    title="$(md_title "$f")"
    if [ "$DRY" -eq 1 ]; then
      echo "DRY-RUN: moveria '$rel' (status=$st, $lines linhas) → _archive/$QDIR/resolved/"
      moved=$((moved + 1))
      continue
    fi
    mkdir -p "$dest_dir"
    if [ ! -f "$ledger" ]; then
      printf '# Arquivo — LEDGER geral\n\n| Data | Origem | Título | Linhas | Arquivo |\n|---|---|---|---|---|\n' > "$ledger"
    fi
    mv "$f" "$dest_dir/$base"
    printf '| %s | `%s` | %s | %s | `_archive/%s/resolved/%s` |\n' \
      "$DATE" "$rel" "$title" "$lines" "$QDIR" "$base" >> "$ledger"
    moved=$((moved + 1))
  done <<EOF
$(find "$SM" -type d -name '_archive' -prune -o -type f -name '*.md' -print 2>/dev/null)
EOF
  if [ "$DRY" -eq 1 ]; then
    echo "RESOLVED: $moved nota(s) resolved/superseded a arquivar"
  else
    [ "$moved" -gt 0 ] && echo "DONE: $moved nota(s) resolved/superseded → _archive/$QDIR/resolved/"
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
  # parte (b) roda mesmo assim — notas resolved/superseded espalhadas pelas áreas
  archive_resolved
  exit 0
fi

DEST_DIR="$SM/_archive/$QDIR/stories-done"
LEDGER="$DONE_DIR/LEDGER.md"

if [ "$DRY" -eq 1 ]; then
  echo "DRY-RUN: arquivaria $COUNT story(ies) de stories/done/ → _archive/$QDIR/stories-done/"
  echo "         e registraria cada uma em stories/done/LEDGER.md"
  find "$DONE_DIR" -maxdepth 1 -type f -name '*.md' ! -name 'LEDGER.md' 2>/dev/null \
    | sed "s#$DONE_DIR/#  - #"
  archive_resolved
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
  mv "$f" "$DEST_DIR/$base"
  printf '| `%s` | %s | %s | `_archive/%s/stories-done/%s` |\n' \
    "$story" "$title" "$DATE" "$QDIR" "$base" >> "$LEDGER"
  MOVED=$((MOVED + 1))
done <<EOF
$(find "$DONE_DIR" -maxdepth 1 -type f -name '*.md' ! -name 'LEDGER.md' 2>/dev/null)
EOF

# atualiza o campo updated do ledger (best-effort)
sed -i.bak "s/^updated:.*/updated: $DATE/" "$LEDGER" 2>/dev/null && rm -f "$LEDGER.bak"

echo "DONE: $MOVED story(ies) arquivada(s) → _archive/$QDIR/stories-done/"
echo "  index: stories/done/LEDGER.md ($MOVED linha(s) adicionada(s))"

# parte (b): notas resolved/superseded nas áreas
archive_resolved

echo "  working set aliviado — agentes não leem _archive/ por convenção."
