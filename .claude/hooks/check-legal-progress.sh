#!/usr/bin/env bash
# .claude/hooks/check-legal-progress.sh
# TaskCompleted hook — quality gate de SAÍDA jurídica (squad legal).
# Exit 2 NEGA a conclusão (a task volta a in_progress e o teammate recebe o stderr).
#
# Payload real do evento (doc oficial de hooks): stdin JSON com task_id, task_subject,
# task_description (opcional), teammate_name, team_name + campos comuns.
# Chaves primárias: task_subject/task_description; fallback: title|subject|name|description|body|...
#
# A squad legal PREPARA; quem envia, assina e protocola é o humano (com o advogado inscrito).
# Este hook garante que nenhuma task que declara uma saída jurídica feche sem as duas evidências:
#   • veredicto PASS do legal-qa (ex.: "PASS", "VEREDICTO: PASS", "QA PASS"), E
#   • confirmação explícita do usuário (ex.: "confirmado pelo usuário em 2026-09-20").
#
# Dispara quando a task referencia a squad legal (docs/smart-memory/agents/[legal/]{drafting,
# disputes,ops,compliance,architecture,strategy,research,qa} — com ou sem o segmento de squad —,
# story L<N>-… ou vocabulário jurídico: contrato, minuta, aditivo, distrato, NDA, notificação,
# acordo, termos de uso, política de privacidade, procuração, petição) E descreve um ATO de saída
# no INFINITIVO/IMPERATIVO com objeto jurídico ou contraparte: "enviar minuta à contraparte",
# "assinar contrato", "coletar assinaturas", "protocolar", "ajuizar", "publicar política/termos",
# "notificar a contraparte", "disparar notificação".
#
# Particípio NÃO dispara (é histórico/revisão): "Revisar contrato enviado pela contraparte",
# "minuta assinada arquivada". Tasks de PREPARAÇÃO (redigir, revisar, marcar desvios, registrar,
# montar dossiê) não disparam. Caso não haja referência ou ato de saída → exit 0.
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

# Referencia a squad legal ou um artefato jurídico?
legal_ref = re.search(r"docs/smart-memory/agents/" + SQUAD + r"(drafting|disputes|ops|compliance|architecture|strategy|research|qa)\b", blob) \
    or re.search(r"stories/[a-z-]+/L\d+-", blob) \
    or re.search(r"\bcontratos?\b|\bminutas?\b|\baditivos?\b|\bdistratos?\b|\bnda\b|\bnotifica[çc][ãa]o\b|\bnotifica[çc][õo]es\b|\bacordos?\b|\btermos de uso\b|\bpol[íi]tica de privacidade\b|\bprocura[çc][ãa]o\b|\bpeti[çc][ãa]o\b|\bcl[áa]usulas?\b|\blegal-(qa|ops|drafter|disputes|compliance)\b", blob, re.I)
if not legal_ref:
    print("OK"); sys.exit(0)

# Objeto jurídico / destinatário externo que caracteriza SAÍDA
OBJ = (r"(?:minutas?|contratos?|aditivos?|distratos?|ndas?|notifica[çc](?:[ãa]o|[õo]es)|acordos?|termos|pol[íi]ticas?|"
       r"procura[çc](?:[ãa]o|[õo]es)|peti[çc](?:[ãa]o|[õo]es)|documentos?|vers[ãa]o\s+final|proposta|"
       r"contraparte|cliente|fornecedor|parceiro|devedor|credor|s[óo]cios?|"
       r"contracts?|drafts?|agreements?|notices?|terms|policy|counterpart(?:y|ies))")

# Ato de SAÍDA jurídica — só infinitivo/imperativo (particípio = já aconteceu / revisão)
exit_act = (
    re.search(r"\b(?:enviar|mandar|encaminhar|remeter|entregar)\s+(?:\w+\s+){0,4}" + OBJ + r"\b", blob, re.I)
    or re.search(r"\benvio\s+(?:d[aeo]s?\s+(?:\w+\s+){0,2})?(?:à|a|para\s+a|para\s+o|ao)\s+(?:contraparte|cliente|fornecedor|parceiro)\b", blob, re.I)
    or re.search(r"\b(?:assinar|protocolar|ajuizar)\b", blob, re.I)
    or re.search(r"\bcoletar\s+(?:as\s+)?assinaturas?\b|\bdistribuir\s+(?:a\s+)?a[çc][ãa]o\b", blob, re.I)
    or re.search(r"\bpublicar\s+(?:\w+\s+){0,3}(?:pol[íi]tica|termos|aviso|documento)\b", blob, re.I)
    or re.search(r"\bnotificar\b|\bdisparar\s+(?:\w+\s+){0,2}notifica", blob, re.I)
    or re.search(r"\bsend\s+(?:\w+\s+){0,4}" + OBJ + r"\b", blob, re.I)
    or re.search(r"\bsign\b|\bfile\s+(?:the\s+|a\s+)?(?:lawsuit|suit|petition|claim|complaint)\b|\bserve\s+(?:the\s+|a\s+)?notice\b", blob, re.I)
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
      echo "🚫 Task de SAÍDA jurídica (enviar minuta/notificação, assinar, protocolar, publicar termos/política) só fecha com PASS do legal-qa e confirmação explícita do usuário — quem envia e assina é o humano, com o advogado inscrito."
      echo ""
      case "$MISSING" in
        *PASS*) echo "• Falta evidência do veredicto PASS de legal-qa (ex.: \"QA PASS contrato-x v2 em 2026-09-20 — agents/legal/qa/results.md\")." ;;
      esac
      case "$MISSING" in
        *USER_OK*) echo "• Falta evidência de confirmação explícita do usuário para ESTE envio/assinatura (ex.: \"confirmado pelo usuário em 2026-09-20\")." ;;
      esac
      echo ""
      echo "Se a task é só PREPARAÇÃO ou REVISÃO (redigir, revisar contrato enviado pela contraparte, marcar desvios, registrar, montar dossiê), reescreva o título com esses verbos — sem 'enviar/assinar/protocolar/publicar'."
      echo "Adicione as evidências à descrição antes de concluir — sem PASS + confirmação, nada sai."
    } >&2
    exit 2 ;;
  OK) exit 0 ;;
  *)
    echo "⚠️ check-legal-progress.sh: python3 falhou (${RESULT:-sem saída}) — hook não avaliou a task." >&2
    exit 0 ;;
esac
