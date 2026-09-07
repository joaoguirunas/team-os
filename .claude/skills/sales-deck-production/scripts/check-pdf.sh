#!/usr/bin/env bash
# check-pdf.sh — checagem obrigatória do PDF gerado (páginas, peso, fontes, render, texto).
# Usage: check-pdf.sh <arquivo.pdf> [--expect-pages N] [--max-mb 15] [--render] [--text <saida.txt>]
# Exit 1 se páginas ≠ esperado ou peso > limite. Nunca aprova por si — produz o relatório.
#
# Dependências opcionais: python3 + pypdf (contagem/fontes exatas), poppler (pdfinfo, pdffonts,
# pdftoppm, pdftotext). Sem elas, usa heurísticas e avisa.

PDF="${1:-}"; shift || true
[ -f "$PDF" ] || { echo "ERROR=pdf_not_found $PDF" >&2; exit 2; }

EXPECT=""; MAX_MB=15; RENDER=0; TEXT_OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --expect-pages) EXPECT="$2"; shift 2 ;;
    --max-mb) MAX_MB="$2"; shift 2 ;;
    --render) RENDER=1; shift ;;
    --text) TEXT_OUT="$2"; shift 2 ;;
    *) echo "ERROR=unknown_flag $1" >&2; exit 2 ;;
  esac
done

FAIL=0
echo "PDF=$PDF"

# ── Peso ──────────────────────────────────────────────────────────────────────
BYTES=$(stat -f%z "$PDF" 2>/dev/null || stat -c%s "$PDF")
MB=$(awk -v b="$BYTES" 'BEGIN{printf "%.2f", b/1048576}')
echo "SIZE_MB=$MB"
awk -v m="$MB" -v max="$MAX_MB" 'BEGIN{exit !(m>max)}' && { echo "WARN=size_over_${MAX_MB}MB"; FAIL=1; }

# ── Páginas ───────────────────────────────────────────────────────────────────
PAGES=""
if command -v pdfinfo >/dev/null 2>&1; then
  PAGES=$(pdfinfo "$PDF" 2>/dev/null | awk '/^Pages:/{print $2}')
fi
if [ -z "$PAGES" ] && command -v python3 >/dev/null 2>&1; then
  PAGES=$(python3 - "$PDF" <<'PY' 2>/dev/null
import sys
try:
    from pypdf import PdfReader
    print(len(PdfReader(sys.argv[1]).pages))
except Exception:
    import re
    data = open(sys.argv[1], "rb").read()
    print(len(re.findall(rb"/Type\s*/Page[^s]", data)))
PY
)
fi
[ -n "$PAGES" ] && echo "PAGES=$PAGES" || echo "PAGES=unknown (instale poppler ou pypdf)"
if [ -n "$EXPECT" ] && [ -n "$PAGES" ] && [ "$PAGES" != "$EXPECT" ]; then
  echo "FAIL=pages_mismatch expected=$EXPECT got=$PAGES"; FAIL=1
fi

# ── Fontes ────────────────────────────────────────────────────────────────────
if command -v pdffonts >/dev/null 2>&1; then
  echo "FONTS:"; pdffonts "$PDF" 2>/dev/null | tail -n +3 | awk '{print "  " $1 "  emb=" $(NF-3)}'
  if pdffonts "$PDF" 2>/dev/null | tail -n +3 | awk '{print $(NF-3)}' | grep -q '^no$'; then
    echo "WARN=font_not_embedded"; FAIL=1
  fi
  if pdffonts "$PDF" 2>/dev/null | grep -qiE '^(Helvetica|Times|Arial|Courier)\b'; then
    echo "WARN=generic_fallback_font (confira se está no design system)"
  fi
else
  echo "FONTS=unknown (instale poppler para pdffonts)"
fi

# ── Render de amostra ─────────────────────────────────────────────────────────
if [ $RENDER -eq 1 ]; then
  if command -v pdftoppm >/dev/null 2>&1 && [ -n "$PAGES" ]; then
    OUTDIR="${PDF%.pdf}-render"; mkdir -p "$OUTDIR"
    MID=$(( (PAGES + 1) / 2 ))
    for p in 1 "$MID" "$PAGES"; do
      pdftoppm -f "$p" -l "$p" -r 80 -png "$PDF" "$OUTDIR/p$p" >/dev/null 2>&1
    done
    echo "RENDER_DIR=$OUTDIR (p1, p$MID, p$PAGES — inspecione visualmente)"
  else
    echo "RENDER=skipped (pdftoppm ausente ou páginas desconhecidas)"
  fi
fi

# ── Texto para a régua editorial ─────────────────────────────────────────────
if [ -n "$TEXT_OUT" ]; then
  if command -v pdftotext >/dev/null 2>&1; then
    pdftotext -layout "$PDF" "$TEXT_OUT" && echo "TEXT=$TEXT_OUT"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$PDF" "$TEXT_OUT" <<'PY' 2>/dev/null && echo "TEXT=$TEXT_OUT" || echo "TEXT=skipped (instale poppler ou pypdf)"
import sys
from pypdf import PdfReader
r = PdfReader(sys.argv[1])
open(sys.argv[2], "w").write("\n\f\n".join((p.extract_text() or "") for p in r.pages))
PY
  fi
fi

echo "RESULT=$([ $FAIL -eq 0 ] && echo OK || echo FAIL)"
exit $FAIL
