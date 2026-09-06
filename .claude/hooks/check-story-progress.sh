#!/usr/bin/env bash
# .claude/hooks/check-story-progress.sh
# TaskCompleted hook — quality gate de fechamento de tasks de story.
# Exit 2 NEGA a conclusão (a task volta a in_progress e o teammate recebe o stderr).
#
# Se o título/descrição da task referencia um arquivo de story
# (docs/smart-memory/stories/...), a task só fecha se a story tem evidência
# de progresso:
#   • seção "## QA Results", OU
#   • frontmatter com status: done | in-review
#
# Sem referência a story → exit 0 (não bloqueia tasks genéricas).
# Defensivo: JSON malformado ou sem python3 → exit 0 (nunca quebra o fluxo).

INPUT=$(cat)

command -v python3 >/dev/null 2>&1 || exit 0

RESULT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json, os, re

try:
    data = json.load(sys.stdin)
except Exception:
    print("OK"); sys.exit(0)

KEYS = {"title", "subject", "name", "description", "body", "content", "details", "prompt"}

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

refs = re.findall(r"docs/smart-memory/stories/[^\s\"\x27`\)\]]+\.md", blob)
if not refs:
    print("OK"); sys.exit(0)

cwd = data.get("cwd") if isinstance(data.get("cwd"), str) else ""
root = os.environ.get("CLAUDE_PROJECT_DIR") or cwd or os.getcwd()

for ref in dict.fromkeys(refs):
    path = ref if os.path.isabs(ref) else os.path.join(root, ref)
    ok = False
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
        if re.search(r"^##\s*QA Results", text, re.M):
            ok = True
        else:
            m = re.match(r"\A---\s*\n(.*?)\n---", text, re.S)
            fm = m.group(1) if m else text[:800]
            if re.search(r"^\s*status:\s*[\"\x27]?(done|in-review)\b", fm, re.M | re.I):
                ok = True
    except OSError:
        ok = False  # story referenciada mas inexistente = sem evidencia
    if not ok:
        print("BLOCK:" + ref); sys.exit(0)

print("OK")
' 2>/dev/null)

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
  *) exit 0 ;;
esac
