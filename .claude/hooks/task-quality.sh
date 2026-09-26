#!/usr/bin/env bash
# .claude/hooks/task-quality.sh
# TaskCreated hook — quality gate de criação de tasks (Agent Teams).
# Exit 2 NEGA a criação da task (feedback via stderr); exit 0 permite.
#
# Payload real do evento (doc oficial de hooks): stdin JSON com
#   task_id, task_subject, task_description (opcional), teammate_name, team_name
#   + campos comuns (session_id, cwd, hook_event_name, ...).
# Chaves primárias: task_subject (título) e task_description (descrição).
# Fallback (payloads antigos/aninhados): title|subject|name e description|body|content|details|prompt.
#
# Rejeita task com título vago:
#   • menos de 12 caracteres, OU
#   • só palavras genéricas (todo, fix, work, task, ajuste, coisa), OU
#   • sem descrição nenhuma.
#
# Defensivo: JSON malformado ou payload sem título identificável → exit 0
# (nunca quebra o fluxo por erro interno do hook).

INPUT=$(cat)

reject() {
  {
    echo "🚫 Task rejeitada: $1"
    echo ""
    echo "Uma task precisa de:"
    echo "  • Título específico (≥ 12 caracteres, dizendo O QUE será feito e ONDE)"
    echo "  • Descrição de 1-2 frases com contexto suficiente para outro agente executar"
    echo "  • Critério de done (como saber que terminou)"
    echo ""
    echo "Exemplo ruim:  \"fix\" / \"ajuste\" / \"task 3\""
    echo "Exemplo bom:   \"Corrigir paginação da listagem de campanhas\" + descrição + critério de done."
  } >&2
  exit 2
}

# ── Caminho principal: análise do JSON com python3 ───────────────────────────
if command -v python3 >/dev/null 2>&1; then
  VERDICT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json, re

try:
    data = json.load(sys.stdin)
except Exception:
    print("OK"); sys.exit(0)

def pick(d, keys):
    for k in keys:
        v = d.get(k)
        if isinstance(v, str) and v.strip():
            return v.strip()
    return ""

# A task vem no topo do payload (task_subject/task_description); payloads antigos
# podem trazê-la em tool_input ou num objeto "task".
candidates = [data]
for key in ("task", "tool_input", "input"):
    v = data.get(key)
    if isinstance(v, dict):
        candidates.append(v)
        t = v.get("task")
        if isinstance(t, dict):
            candidates.append(t)

title = desc = ""
for c in candidates:
    title = title or pick(c, ("task_subject", "title", "subject", "name"))
    desc = desc or pick(c, ("task_description", "description", "body", "content", "details", "prompt"))

if not title:
    # Formato de payload desconhecido → nao bloquear
    print("OK"); sys.exit(0)

GENERIC = {"todo", "fix", "work", "task", "ajuste", "coisa"}
words = re.findall(r"[a-zà-ú0-9]+", title.lower())

if len(title) < 12:
    print("BLOCK:titulo muito curto (menos de 12 caracteres): \"" + title + "\"")
elif words and all(w in GENERIC or w.isdigit() for w in words):
    print("BLOCK:titulo so com palavras genericas: \"" + title + "\"")
elif not desc:
    print("BLOCK:task sem descricao nenhuma")
else:
    print("OK")
' 2>&1)
  case "$VERDICT" in
    BLOCK:*) reject "${VERDICT#BLOCK:}" ;;
    OK) exit 0 ;;
    *) echo "⚠️ task-quality.sh: python3 falhou (${VERDICT:-sem saída}) — usando fallback grep." >&2 ;;
  esac
fi

# ── Fallback sem python3: checagem mínima do título via grep/sed ─────────────
TITLE=$(printf '%s' "$INPUT" \
  | grep -oE '"(task_subject|title|subject)"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
  | head -1 | sed -E 's/^"(task_subject|title|subject)"[[:space:]]*:[[:space:]]*"//; s/"$//')
if [ -n "$TITLE" ] && [ "${#TITLE}" -lt 12 ]; then
  reject "título muito curto (menos de 12 caracteres): \"$TITLE\" (fallback sem python3)"
fi
exit 0
