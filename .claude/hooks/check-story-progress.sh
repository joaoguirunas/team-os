#!/usr/bin/env bash
# .claude/hooks/check-story-progress.sh
# TaskCompleted hook — quality gate de fechamento de tasks de story.
# Exit 2 NEGA a conclusão (a task volta a in_progress e o teammate recebe o stderr).
#
# Payload real do evento (doc oficial de hooks): stdin JSON com task_id, task_subject,
# task_description (opcional), teammate_name, team_name + campos comuns (cwd, session_id...).
# Chaves primárias: task_subject/task_description; fallback: title|subject|name|description|body|...
#
# Se o título/descrição da task referencia uma story — por caminho
# (docs/smart-memory/stories/<pasta>/<arquivo>.md, com ou sem "./" na frente) ou por id
# ("story 3.2", "story S12", "story #7"; "S12"/"3.2" soltos só quando o texto fala em story) —
# a task só fecha se a story tem evidência de progresso:
#   • seção "## QA Results", OU
#   • frontmatter com status: done | in-review
#
# Referência por id: o arquivo é procurado em
#   docs/smart-memory/stories/{active,in-review,backlog,done}/<id>-*.md (ou <id>.md).
# Story referenciada que não existe em lugar nenhum → BLOQUEIA (sem evidência = sem fechamento).
#
# Raiz do projeto: cwd do JSON → CLAUDE_PROJECT_DIR → pwd.
# Sem referência a story → exit 0 (não bloqueia tasks genéricas).
# Defensivo: JSON malformado ou sem python3 → exit 0 (nunca quebra o fluxo).

INPUT=$(cat)

command -v python3 >/dev/null 2>&1 || exit 0

RESULT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json, os, re, glob

try:
    data = json.load(sys.stdin)
except Exception:
    print("OK"); sys.exit(0)

KEYS = {"task_subject", "task_description",
        "title", "subject", "name", "description", "body", "content", "details", "prompt"}

def collect(obj, acc):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, str) and k in KEYS:
                acc.append(v)
            elif isinstance(v, (dict, list)):
                collect(v, acc)
    elif isinstance(obj, list):
        for v in obj:
            collect(v, acc)

texts = []
collect(data, texts)
blob = "\n".join(texts)

cwd = data.get("cwd") if isinstance(data.get("cwd"), str) else ""
root = cwd if (cwd and os.path.isdir(cwd)) else (os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())

STORY_DIRS = ("active", "in-review", "backlog", "done")

# ── 1. Referências por caminho (normaliza "./" e caminhos absolutos) ──────────
path_refs = []
for m in re.finditer(r"(?:^|[\s\"\x27`(\[])((?:\.?/)?(?:[^\s\"\x27`()\[\]]*?/)?docs/smart-memory/stories/[^\s\"\x27`()\[\]]+\.md)", blob):
    ref = m.group(1)
    if ref.startswith("./"):
        ref = ref[2:]
    path_refs.append(ref)

# ── 2. Referências por id ─────────────────────────────────────────────────────
id_refs = []
# "story 3.2" / "story S12" / "story #7" / "história 4.1"
for m in re.finditer(r"\b(?:story|stories|hist[óo]ria)\s*#?\s*([A-Za-z]?\d+(?:\.\d+)?)\b", blob, re.I):
    id_refs.append(m.group(1))
# "S12" / "3.2" soltos: só contam quando o texto fala em story (evita "AWS S3", "2.5 segundos")
if re.search(r"\bstor(?:y|ies)\b|\bhist[óo]ria\b|stories/", blob, re.I):
    for m in re.finditer(r"(?<![\w.])(S\d+(?:\.\d+)?)(?![\w.])", blob):
        id_refs.append(m.group(1))
    for m in re.finditer(r"(?<![\w.])(\d+\.\d+)(?![\w.])", blob):
        id_refs.append(m.group(1))

if not path_refs and not id_refs:
    print("OK"); sys.exit(0)

def has_evidence(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        return False
    if re.search(r"^##\s*QA Results", text, re.M):
        return True
    m = re.match(r"\A---\s*\n(.*?)\n---", text, re.S)
    fm = m.group(1) if m else text[:800]
    return re.search(r"^\s*status:\s*[\"\x27]?(done|in-review)\b", fm, re.M | re.I) is not None

def find_by_id(sid):
    low = sid.lower()
    found = []
    for d in STORY_DIRS:
        base = os.path.join(root, "docs", "smart-memory", "stories", d)
        try:
            names = os.listdir(base)
        except OSError:
            continue
        for n in names:
            nl = n.lower()
            if nl == low + ".md" or (nl.startswith(low + "-") and nl.endswith(".md")):
                found.append(os.path.join(base, n))
    return found

for ref in dict.fromkeys(path_refs):
    path = ref if os.path.isabs(ref) else os.path.join(root, ref)
    if not os.path.isfile(path):
        print("MISSING:" + ref); sys.exit(0)
    if not has_evidence(path):
        print("BLOCK:" + ref); sys.exit(0)

for sid in dict.fromkeys(id_refs):
    files = find_by_id(sid)
    if not files:
        print("MISSING:story " + sid + " (procurada em docs/smart-memory/stories/{active,in-review,backlog,done}/" + sid + "-*.md)")
        sys.exit(0)
    if not any(has_evidence(p) for p in files):
        print("BLOCK:" + os.path.relpath(files[0], root)); sys.exit(0)

print("OK")
' 2>&1)

case "$RESULT" in
  BLOCK:*)
    STORY="${RESULT#BLOCK:}"
    {
      echo "🚫 Task de story só fecha com QA Results ou status atualizado na story."
      echo ""
      echo "Story referenciada: $STORY"
      echo "Antes de concluir esta task, registre na story uma seção \"## QA Results\""
      echo "ou atualize o frontmatter para status: done ou status: in-review."
    } >&2
    exit 2 ;;
  MISSING:*)
    STORY="${RESULT#MISSING:}"
    {
      echo "🚫 A task referencia uma story que não existe: $STORY"
      echo ""
      echo "Sem o arquivo da story não há evidência de progresso (QA Results ou status)."
      echo "Confira o caminho/id da story na task ou crie a story em docs/smart-memory/stories/<pasta>/"
      echo "antes de concluir."
    } >&2
    exit 2 ;;
  OK) exit 0 ;;
  *)
    echo "⚠️ check-story-progress.sh: python3 falhou (${RESULT:-sem saída}) — hook não avaliou a task." >&2
    exit 0 ;;
esac
