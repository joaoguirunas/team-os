#!/usr/bin/env bash
# .claude/hooks/check-social-progress.sh
# TaskCompleted hook — quality gate de publicação de conteúdo social.
# Exit 2 NEGA a conclusão (a task volta a in_progress e o teammate recebe o stderr).
#
# Se a task referencia conteúdo social (arquivos em
# docs/smart-memory/agents/{content,design,photo,video,publisher}) E é uma task
# de publicação ("publicar"/"publish"), a descrição da task precisa conter
# evidência de aprovação editorial ("aprovado" pela VERA/strategist) antes de
# fechar. Caso contrário → exit 0 (não bloqueia tasks genéricas).
#
# Defensivo: JSON malformado ou sem python3 → exit 0 (nunca quebra o fluxo).

INPUT=$(cat)

command -v python3 >/dev/null 2>&1 || exit 0

RESULT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json, re

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

# Referencia conteudo social?
if not re.search(r"docs/smart-memory/agents/(content|design|photo|video|publisher)\b", blob):
    print("OK"); sys.exit(0)

# Task de publicacao?
if not re.search(r"\bpublicar\b|\bpublish\b|\bpublica[cç][aã]o\b", blob, re.I):
    print("OK"); sys.exit(0)

# Evidencia de aprovacao editorial (VERA/strategist)?
if re.search(r"aprovad[oa]", blob, re.I):
    print("OK"); sys.exit(0)

print("BLOCK")
' 2>/dev/null)

case "$RESULT" in
  BLOCK*)
    {
      echo "🚫 Task de publicação social só fecha com aprovação editorial registrada."
      echo ""
      echo "A task referencia conteúdo social e está marcada como publicação, mas a"
      echo "descrição não contém evidência de aprovação da VERA/strategist."
      echo "Adicione à descrição a evidência (ex.: \"Aprovado pela VERA em 2026-09-05\")"
      echo "antes de concluir — sem aprovação editorial, nada é publicado."
    } >&2
    exit 2 ;;
  *) exit 0 ;;
esac
