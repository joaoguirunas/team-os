#!/usr/bin/env bash
# feedback-scan.sh — junta as linhas [skill-feedback] gravadas nos projetos destino.
# SÓ LEITURA: não escreve em nenhum projeto nem no CT.
#
# Convenção (definida na team-os, reference/estrutura-smart-memory.md):
#   [skill-feedback] <skill|agente>: <correção, em 1 frase> (AAAA-MM-DD)
# gravada pelo lead em docs/smart-memory/_inbox/*.md e levada pelo *compact ao DIGEST.md da área.
#
# Onde procura, em cada projeto: docs/smart-memory/**/_inbox/*.md e docs/smart-memory/**/DIGEST.md.
# Nunca entra em docs/smart-memory/_archive/ (o arquivo morto não é lido — mesma regra do
# guard-smart-memory-read.sh). Só grep de linhas marcadas: nenhuma nota é lida inteira.
#
# Projetos: mesma raiz do scan-ct-projects.sh (--root, CT_ROOT, .team-os-root ou pasta pai do CT);
# entram as pastas irmãs do CT e os filhos de contêiner que têm docs/smart-memory/ (o próprio CT
# fica de fora). Para testar ou olhar um só:
#   feedback-scan.sh --project <pasta> [--project <pasta2> ...]
#   feedback-scan.sh --root <raiz dos projetos>
#
# Saída (uma linha por ocorrência, depois o resumo por alvo):
#   FEEDBACK=<projeto>|<alvo>|<texto>          ("|" no nome do projeto vira "¦")
#   TARGET=<alvo>|<tipo>|<ocorrências>|<projetos>   tipo = skill | agente | desconhecido (no CT)
#   REPEAT=<alvo>|<projetos>                   mesmo alvo corrigido em 2+ projetos → considerar
#                                              hook/barreira estrutural
#   FEEDBACK_TOTAL=<n>  FEEDBACK_TARGETS=<n>  FEEDBACK_PROJECTS=<n>  PROJECTS_SCANNED=<n>
#   ROOT=<raiz usada> (só sem --project)
# bash 3.2-safe. Requer python3 (agrupamento).

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
CT="$(cd "$HERE/../../../.." && pwd)"
ROOT=""
PROJECTS_FILE="$(mktemp "${TMPDIR:-/tmp}/feedback-scan.XXXXXX")" || exit 1
HITS_FILE="$(mktemp "${TMPDIR:-/tmp}/feedback-hits.XXXXXX")" || exit 1
trap 'rm -f "$PROJECTS_FILE" "$HITS_FILE"' EXIT

while [ $# -gt 0 ]; do
  case "$1" in
    --project)
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "ERROR=missing_value|--project exige uma pasta" >&2; exit 2; }
      [ -d "$2" ] || { echo "ERROR=not_found|$2" >&2; exit 2; }
      d="$(cd "$2" && pwd)"
      printf '%s\t%s\n' "$d" "$(basename "$d")" >> "$PROJECTS_FILE"
      shift 2 ;;
    --root)
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "ERROR=missing_value|--root exige uma pasta" >&2; exit 2; }
      ROOT="$2"; shift 2 ;;
    -h|--help) sed -n '2,27p' "$0"; exit 0 ;;
    *) echo "ERROR=unknown_flag|$1 (use --project <pasta> | --root <pasta>)" >&2; exit 2 ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "ERROR=python3_missing|python3 é necessário" >&2; exit 1; }

# Lista de projetos: --project explícito, senão a MESMA raiz do scan-ct-projects.sh (argumento,
# CT_ROOT, .team-os-root ou pasta pai do CT). Sem o cálculo de drift do scan (lento em disco de
# nuvem): basta achar docs/smart-memory/ nas pastas irmãs do CT e nos filhos de contêiner
# ("<Negócio>/<Projeto>"), como o scan faz.
if [ ! -s "$PROJECTS_FILE" ]; then
  [ -z "$ROOT" ] && ROOT="${CT_ROOT:-}"
  if [ -z "$ROOT" ] && [ -f "$CT/.team-os-root" ]; then
    ROOT="$(sed -n '1p' "$CT/.team-os-root" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    case "$ROOT" in "~"|"~/"*) ROOT="$HOME${ROOT#\~}" ;; esac
  fi
  [ -z "$ROOT" ] && ROOT="$(dirname "$CT")"
  [ -d "$ROOT" ] || { echo "ERROR=root_not_found|$ROOT" >&2; exit 1; }
  ROOT="$(cd "$ROOT" && pwd)"
  echo "ROOT=$ROOT"
  # 3º nível: grupo → negócio → projeto (ex.: "Outros/Sahaj/Sahaj | Marketing")
  for d in "$ROOT"/*/ "$ROOT"/*/*/ "$ROOT"/*/*/*/; do
    [ -d "${d}docs/smart-memory" ] || continue
    d="${d%/}"
    case "$d" in "$ROOT"/.*|"$ROOT"/*/.*|"$ROOT"/*/*/.*) continue ;; esac
    # projeto dentro de projeto (ex.: pasta de proposta com smart-memory própria) não conta
    case "$(dirname "$d")" in "$ROOT") ;; *) [ -d "$(dirname "$d")/docs/smart-memory" ] && continue ;; esac
    printf '%s\t%s\n' "$d" "${d#"$ROOT"/}" >> "$PROJECTS_FILE"
  done
fi

SCANNED=0
while IFS="$(printf '\t')" read -r dir name; do
  [ -n "$dir" ] || continue
  [ "$(cd "$dir" 2>/dev/null && pwd)" = "$CT" ] && continue
  SM="$dir/docs/smart-memory"
  [ -d "$SM" ] || continue
  SCANNED=$((SCANNED + 1))
  # _archive/ podado; só _inbox/*.md e DIGEST.md; grep só das linhas marcadas
  find "$SM" -path "$SM/_archive" -prune -o -type f \
    \( -path '*/_inbox/*.md' -o -name 'DIGEST.md' \) -print 2>/dev/null \
  | while IFS= read -r f; do
      grep -h -- '\[skill-feedback\]' "$f" 2>/dev/null | while IFS= read -r line; do
        printf '%s\t%s\n' "$name" "$line"
      done
    done >> "$HITS_FILE"
done < "$PROJECTS_FILE"

FS_CT="$CT" FS_SCANNED="$SCANNED" python3 - "$HITS_FILE" <<'PYEOF'
import os, re, sys

ct = os.environ["FS_CT"]
scanned = os.environ.get("FS_SCANNED", "0")
rx = re.compile(r"\[skill-feedback\]\s*`?([A-Za-z0-9_.:-]+)`?\s*:\s*(.+?)\s*$")

seen, items = set(), []
with open(sys.argv[1], encoding="utf-8", errors="replace") as fh:
    for raw in fh:
        proj, _, line = raw.rstrip("\n").partition("\t")
        m = rx.search(line)
        if not m:
            continue
        target = m.group(1).strip().rstrip(".")
        if target.endswith(".md"):
            target = target[:-3]
        text = m.group(2).strip()
        key = (proj, target, text.lower())
        if key in seen:          # mesma linha no _inbox/ e no DIGEST.md → uma só
            continue
        seen.add(key)
        items.append((proj.replace("|", "¦"), target, text.replace("\n", " ")))

def kind(t):
    if os.path.isfile(os.path.join(ct, ".claude", "skills", t, "SKILL.md")):
        return "skill"
    if os.path.isfile(os.path.join(ct, ".claude", "agents", t + ".md")):
        return "agente"
    return "desconhecido"

items.sort(key=lambda x: (x[1], x[0], x[2]))
for p, t, txt in items:
    print(f"FEEDBACK={p}|{t}|{txt}")

groups = {}
for p, t, _ in items:
    g = groups.setdefault(t, {"n": 0, "projs": []})
    g["n"] += 1
    if p not in g["projs"]:
        g["projs"].append(p)

for t in sorted(groups, key=lambda k: (-len(groups[k]["projs"]), -groups[k]["n"], k)):
    g = groups[t]
    print(f"TARGET={t}|{kind(t)}|{g['n']}|{len(g['projs'])}")
for t in sorted(groups):
    if len(groups[t]["projs"]) >= 2:
        print(f"REPEAT={t}|{', '.join(groups[t]['projs'])}")

print(f"FEEDBACK_TOTAL={len(items)}")
print(f"FEEDBACK_TARGETS={len(groups)}")
print(f"FEEDBACK_PROJECTS={len({p for p, _, _ in items})}")
print(f"PROJECTS_SCANNED={scanned}")
PYEOF
