#!/usr/bin/env bash
# .claude/hooks/check-proposal-progress.sh
# TaskCompleted hook — quality gate de emissão/envio de proposta ou apresentação (squad sales).
# Exit 2 NEGA a conclusão (a task volta a in_progress e o teammate recebe o stderr).
#
# Payload real do evento (doc oficial de hooks): stdin JSON com task_id, task_subject,
# task_description (opcional), teammate_name, team_name + campos comuns.
# Chaves primárias: task_subject/task_description; fallback: title|subject|name|description|body|...
#
# Se a task referencia artefatos da squad sales (docs/smart-memory/agents/[sales/]{closer,design,
# copy,planning,finance,strategy,discovery,qa} — com ou sem o segmento de squad — ou uma story
# P<N>-…) OU fala de proposta/deck, E descreve um ATO de emissão/envio no infinitivo/imperativo
# ("enviar proposta ao cliente", "emitir", "send"), a descrição precisa conter:
#   • evidência de veredicto PASS do QA (ex.: "PASS", "VEREDICTO: PASS", "QA PASS"), E
#   • evidência de confirmação explícita do usuário (ex.: "confirmado pelo usuário").
#
# NÃO dispara em particípio (histórico/revisão): "Revisar proposta enviada pelo cliente",
# "proposta emitida v2 registrada" — nem em "envio interno" ("Preparar apresentação para envio
# interno"). Caso contrário → exit 0 (não bloqueia tasks genéricas).
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

SQUAD = r"(?:(?:sales|dev|sites|social|traffic|pm|brand|finance|legal|seo)/)?"

# Referencia a squad sales ou um artefato de proposta?
sales_ref = re.search(r"docs/smart-memory/agents/" + SQUAD + r"(closer|design|copy|planning|finance|strategy|discovery|qa)\b", blob) \
    or re.search(r"stories/[a-z-]+/P\d+-", blob) \
    or re.search(r"\bpropostas?\b|\bproposal\b|\bdeck\b|\bapresenta[cç][aã]o\b|\bone-?pager\b", blob, re.I)
if not sales_ref:
    print("OK"); sys.exit(0)

# Ato de emissao/envio — infinitivo/imperativo ou substantivo de ato (não particípio, não "envio interno")
exit_act = (
    re.search(r"\b(?:enviar|mandar|encaminhar|remeter|emitir|disparar|entregar|send|deliver|submit|issue)\b", blob, re.I)
    or re.search(r"\benvio\b(?!\s+intern)", blob, re.I)
    or re.search(r"\bemiss[aã]o\b(?!\s+intern)", blob, re.I)
    or re.search(r"\bentrega\s+(?:ao|para o|à|a)\s+cliente\b", blob, re.I)
)
if not exit_act:
    print("OK"); sys.exit(0)

has_pass = re.search(r"\bPASS\b|veredicto:\s*pass|qa\s*pass", blob, re.I) is not None
has_user_ok = re.search(r"confirmad[oa] pel[oa] usu[aá]ri[oa]|confirma[cç][aã]o (expl[íi]cita )?d[oa] usu[aá]ri[oa]|usu[aá]ri[oa] confirmou|user confirmed", blob, re.I) is not None

if has_pass and has_user_ok:
    print("OK"); sys.exit(0)

missing = []
if not has_pass: missing.append("PASS")
if not has_user_ok: missing.append("USER_OK")
print("BLOCK:" + ",".join(missing))
' 2>&1)

case "$RESULT" in
  BLOCK:*)
    MISSING="${RESULT#BLOCK:}"
    {
      echo "🚫 Task de emissão/envio de proposta só fecha com PASS do QA e confirmação explícita do usuário."
      echo ""
      case "$MISSING" in
        *PASS*) echo "• Falta evidência do veredicto PASS de sales-qa (ex.: \"QA PASS v2 em 2026-09-07 — agents/sales/qa/results.md\")." ;;
      esac
      case "$MISSING" in
        *USER_OK*) echo "• Falta evidência de confirmação explícita do usuário para ESTE envio (ex.: \"confirmado pelo usuário em 2026-09-07\")." ;;
      esac
      echo ""
      echo "Se a task é só PREPARAÇÃO ou REVISÃO (revisar proposta enviada pelo cliente, preparar para envio interno), reescreva o título com esses verbos."
      echo "Adicione as evidências à descrição antes de concluir — sem PASS + confirmação, nada sai."
    } >&2
    exit 2 ;;
  OK) exit 0 ;;
  *)
    echo "⚠️ check-proposal-progress.sh: python3 falhou (${RESULT:-sem saída}) — hook não avaliou a task." >&2
    exit 0 ;;
esac
