#!/usr/bin/env bash
# sm-find.sh — busca summary-first na smart-memory (ferramenta do protocolo "buscar antes de ler").
# Procura cada termo (OR, case-insensitive) nos METADADOS das notas do working set:
# frontmatter (kind/status/summary/tags), título H1 e nome de arquivo — NUNCA no corpo,
# e NUNCA imprime conteúdo. Exclui _archive/.
#
# Usage: sm-find.sh [--target <dir>] <termo> [termo2 ...]
#   --target <dir>  raiz do projeto (default: git root ou pwd)
#
# Saída (uma linha por match, TAB-separada):
#   path<TAB>kind<TAB>status<TAB>summary
# path relativo à raiz do projeto (docs/smart-memory/...), pronto para Read.
#
# Exit: 0 com pelo menos um match · 1 sem matches · 2 erro de uso.
# Disciplina summary-first: L0 = DIGEST da área · L1 = sm-find (isto) · L2 = ler a nota
# inteira SÓ quando o match justificar (máx 3 notas por tarefa).

TARGET=""
TERMS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "ERRO: --target requer um valor (diretório do projeto)" >&2
        exit 2
      fi
      TARGET="$2"; shift 2 ;;
    -*)
      echo "ERRO: flag desconhecida: $1" >&2
      exit 2 ;;
    *)
      TERMS="${TERMS}$1
"; shift ;;
  esac
done

if [ -z "$TERMS" ]; then
  echo "Usage: sm-find.sh [--target <dir>] <termo> [termo2 ...]" >&2
  exit 2
fi

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

if [ ! -d "$SM" ]; then
  echo "ERRO: smart-memory não existe em $SM (rode discovery primeiro)." >&2
  exit 2
fi

# Lê um campo do frontmatter YAML — ancorado: a LINHA 1 tem que ser `---`.
# Suporta valor dobrado (`summary: >` / `summary: |` — junta as linhas indentadas seguintes).
fm_field() { # $1=file $2=field
  awk -v f="$2" '
    NR==1 { if ($0 != "---") exit; inf=1; next }
    inf && /^---$/ { exit }
    !inf { exit }
    found && /^[[:space:]]/ { v=$0; sub(/^[[:space:]]+/,"",v); out=out (out?" ":"") v; next }
    found { print out; out=""; exit }
    $0 ~ "^"f":" {
      v=$0; sub("^"f":[[:space:]]*","",v); gsub(/^["'"'"']|["'"'"']$/,"",v)
      if (v != "" && v != ">" && v != "|") { print v; exit }
      found=1
    }
    END { if (found && out != "") print out }
  ' "$1"
}

# Título H1 (1ª linha `# ...`)
h1_title() { grep -m1 '^# ' "$1" 2>/dev/null | sed 's/^# //'; }

FOUND=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  rel="${f#$TARGET/}"
  base="$(basename "$f")"
  kind="$(fm_field "$f" kind)"
  status="$(fm_field "$f" status)"
  summary="$(fm_field "$f" summary)"
  tags="$(fm_field "$f" tags)"
  title="$(h1_title "$f")"
  # Haystack de METADADOS (nunca o corpo): kind + status + summary + tags + H1 + filename
  hay="$base
$kind
$status
$summary
$tags
$title"
  match=0
  while IFS= read -r term; do
    [ -n "$term" ] || continue
    if printf '%s' "$hay" | grep -qiF -- "$term"; then
      match=1
      break
    fi
  done <<EOF2
$TERMS
EOF2
  if [ "$match" -eq 1 ]; then
    FOUND=$((FOUND + 1))
    printf '%s\t%s\t%s\t%s\n' "$rel" "${kind:--}" "${status:--}" "${summary:--}"
  fi
done <<EOF
$(find "$SM" -type d -name '_archive' -prune -o -type f -name '*.md' -print 2>/dev/null | sort)
EOF

if [ "$FOUND" -eq 0 ]; then
  exit 1
fi
exit 0
