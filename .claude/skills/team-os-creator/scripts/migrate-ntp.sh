#!/usr/bin/env bash
# migrate-ntp.sh — *migrate: reinjeta o bloco canônico "## Native Teams Protocol"
# em cada .claude/agents/*.md de um diretório.
#
# Substitui, em cada agente, o trecho que vai da linha "## Native Teams Protocol"
# até (exclusive) o próximo separador `---` ou o próximo heading `## ` pelo bloco
# canônico de reference/native-teams-protocol.md (entre NTP-START e NTP-END).
# Agente sem o bloco: injeta o bloco logo após o frontmatter (antes do 1º H1),
# seguido de `---`. Agente com o antigo "## Contrato com team-os": esse bloco é
# substituído da mesma forma.
#
# Idempotente: rodar duas vezes não muda nada. --dry-run mostra o diff e não grava.
#
# Usage: migrate-ntp.sh [--dir <.claude/agents>] [--canonical <arquivo>] [--dry-run] [<agente>...]
#   --dir        diretório dos agentes (default: <git root>/.claude/agents)
#   --canonical  arquivo com o bloco canônico entre <!-- NTP-START --> e <!-- NTP-END -->
#                (default: team-os-creator/reference/native-teams-protocol.md)
#   --dry-run    imprime `diff -u` por agente, sem gravar
#   <agente>     nomes (sem .md) para migrar só alguns; sem args = todos
#
# Bash 3.2 / macOS — sem mapfile, sem declare -A, sem grep -P.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIR="$ROOT/.claude/agents"
CANON="$HERE/../reference/native-teams-protocol.md"
DRY=0
ONLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)       [ $# -ge 2 ] || { echo "⛔ --dir exige um valor" >&2; exit 2; }; DIR="$2"; shift 2 ;;
    --canonical) [ $# -ge 2 ] || { echo "⛔ --canonical exige um valor" >&2; exit 2; }; CANON="$2"; shift 2 ;;
    --dry-run)   DRY=1; shift ;;
    -h|--help)   sed -n '2,22p' "$0"; exit 0 ;;
    --*)         echo "⛔ flag desconhecida: $1" >&2; exit 2 ;;
    *)           ONLY="$ONLY ${1%.md}"; shift ;;
  esac
done

[ -d "$DIR" ] || { echo "⛔ diretório de agentes não existe: $DIR" >&2; exit 1; }
[ -f "$CANON" ] || { echo "⛔ bloco canônico não encontrado: $CANON" >&2; exit 1; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/migrate-ntp.XXXXXX")" || exit 1
trap 'rm -rf "$TMP"' EXIT

# Bloco canônico, sem linhas em branco iniciais/finais (mesmo critério do *audit)
awk '/<!-- NTP-START -->/{f=1;next} /<!-- NTP-END -->/{f=0} f' "$CANON" \
  | awk 'NF{if(!s)s=NR; e=NR} {l[NR]=$0} END{for(i=s;i<=e;i++) print l[i]}' > "$TMP/canon.md"
grep -q '^## Native Teams Protocol' "$TMP/canon.md" || { echo "⛔ bloco canônico inválido (sem '## Native Teams Protocol'): $CANON" >&2; exit 1; }

# rebuild <arquivo> → escreve a versão migrada em stdout
rebuild() {
  local f="$1" start end total fm_end
  total="$(wc -l < "$f" | tr -d ' ')"
  # início: heading NTP (ou o bloco antigo "Contrato com team-os")
  start="$(grep -n -m1 -E '^## (Native Teams Protocol|Contrato com team-os)' "$f" | cut -d: -f1)"
  if [ -z "$start" ]; then
    # sem bloco: injeta após o frontmatter (2º '---'), antes do 1º H1
    fm_end="$(awk '/^---$/{c++; if(c==2){print NR; exit}}' "$f")"
    if [ -z "$fm_end" ]; then
      echo "⛔ $(basename "$f"): sem frontmatter — não sei onde injetar" >&2
      return 1
    fi
    sed -n "1,${fm_end}p" "$f"
    echo ""
    cat "$TMP/canon.md"
    echo ""
    echo "---"
    sed -n "$((fm_end + 1)),\$p" "$f"
    return 0
  fi
  # fim: próxima linha `---` ou próximo `## ` depois do início (exclusive)
  end="$(awk -v s="$start" 'NR>s && (/^---$/ || /^## /){print NR; exit}' "$f")"
  [ -n "$end" ] || end=$((total + 1))
  # antes do bloco (linhas 1..start-1)
  [ "$start" -gt 1 ] && sed -n "1,$((start - 1))p" "$f"
  cat "$TMP/canon.md"
  echo ""
  # do terminador em diante (linha `---` / `## …` / fim)
  [ "$end" -le "$total" ] && sed -n "${end},\$p" "$f"
  return 0
}

changed=0; same=0; failed=0; injected=0
for f in "$DIR"/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f" .md)"
  if [ -n "$ONLY" ]; then
    case " $ONLY " in *" $name "*) ;; *) continue ;; esac
  fi
  grep -q -E '^## (Native Teams Protocol|Contrato com team-os)' "$f" || injected=$((injected + 1))
  if ! rebuild "$f" > "$TMP/new.md"; then
    failed=$((failed + 1)); continue
  fi
  if cmp -s "$f" "$TMP/new.md"; then
    same=$((same + 1)); continue
  fi
  changed=$((changed + 1))
  if [ $DRY -eq 1 ]; then
    echo "── $name (dry-run) ──"
    diff -u "$f" "$TMP/new.md" | sed '1,2d'
  else
    cp "$TMP/new.md" "$f"
    echo "✓ $name — bloco NTP reinjetado"
  fi
done

echo ""
echo "NTP_MIGRATE: ${changed} alterado(s) · ${same} já canônico(s) · ${injected} sem bloco (injetado) · ${failed} falha(s)$([ $DRY -eq 1 ] && printf ' · dry-run (nada gravado)')"
[ $failed -eq 0 ] || exit 1
exit 0
