#!/usr/bin/env bash
# .claude/hooks/check-legal-progress.sh
# TaskCompleted hook — quality gate de SAÍDA jurídica (squad legal).
# Exit 2 NEGA a conclusão (a task volta a in_progress e o teammate recebe o stderr).
#
# A squad legal PREPARA; quem envia, assina e protocola é o humano (com o advogado inscrito).
# Este hook garante que nenhuma task que declara uma saída jurídica feche sem as duas evidências:
#   • veredicto PASS do legal-qa (ex.: "PASS", "VEREDICTO: PASS", "QA PASS"), E
#   • confirmação explícita do usuário (ex.: "confirmado pelo usuário em 2026-09-20").
#
# Dispara quando a task referencia a squad legal (docs/smart-memory/agents/{drafting,disputes,ops,
# compliance,architecture,strategy,research,qa}, story L<N>-… ou vocabulário jurídico: contrato,
# minuta, aditivo, distrato, NDA, notificação, acordo, termos de uso, política de privacidade,
# procuração, petição) E descreve um ATO de saída (enviar à contraparte, assinar, coletar assinatura,
# protocolar, ajuizar, publicar política/termos, notificar, disparar).
#
# Tasks de PREPARAÇÃO (redigir, revisar, marcar desvios, registrar, montar dossiê) não disparam —
# use esses verbos no título. Caso não haja referência ou ato de saída → exit 0.
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

# Referencia a squad legal ou um artefato jurídico?
legal_ref = re.search(r"docs/smart-memory/agents/(drafting|disputes|ops|compliance|architecture|strategy|research|qa)\b", blob) \
    or re.search(r"stories/[a-z-]+/L\d+-", blob) \
    or re.search(r"\bcontratos?\b|\bminutas?\b|\baditivos?\b|\bdistratos?\b|\bnda\b|\bnotifica[çc][ãa]o\b|\bnotifica[çc][õo]es\b|\bacordos?\b|\btermos de uso\b|\bpol[íi]tica de privacidade\b|\bprocura[çc][ãa]o\b|\bpeti[çc][ãa]o\b|\bcl[áa]usulas?\b|\blegal-(qa|ops|drafter|disputes|compliance)\b", blob, re.I)
if not legal_ref:
    print("OK"); sys.exit(0)

# Ato de SAÍDA jurídica (não preparação)?
exit_act = re.search(
    r"\benviar\b|\benvio\b|\benviad[oa]s?\b|\bencaminhar (à|a|para a) contraparte|"
    r"\bassinar\b|\bassinad[oa]s?\b|\bcoletar (as )?assinaturas?\b|\bassinatura (coletad|conclu[íi]d|realizad)|"
    r"\bprotocolar\b|\bprotocolad[oa]s?\b|\bajuizar\b|\bajuizad[oa]s?\b|\bdistribuir (a )?a[çc][ãa]o\b|"
    r"\bpublicar\b|\bpublicad[oa]s?\b|\bnotificar\b|\bnotificad[oa]s?\b|\bdisparar\b|\bdisparad[oa]s?\b|"
    r"\bsend\b|\bsent\b|\bsign(ed)?\b|\bfiled\b", blob, re.I)
if not exit_act:
    print("OK"); sys.exit(0)

has_pass = re.search(r"\bPASS\b|veredicto:\s*pass|qa\s*pass", blob, re.I) is not None
has_user_ok = re.search(r"confirmad[oa] pel[oa] usu[aá]ri[oa]|confirma[cç][aã]o (explícita )?d[oa] usu[aá]ri[oa]|usu[aá]ri[oa] confirmou|user confirmed", blob, re.I) is not None

if has_pass and has_user_ok:
    print("OK"); sys.exit(0)

missing = []
if not has_pass: missing.append("PASS")
if not has_user_ok: missing.append("USER_OK")
print("BLOCK:" + ",".join(missing))
' 2>/dev/null)

case "$RESULT" in
  BLOCK*)
    MISSING="${RESULT#BLOCK:}"
    {
      echo "🚫 Task de SAÍDA jurídica (enviar minuta/notificação, assinar, protocolar, publicar termos/política) só fecha com PASS do legal-qa e confirmação explícita do usuário — quem envia e assina é o humano, com o advogado inscrito."
      echo ""
      case "$MISSING" in
        *PASS*) echo "• Falta evidência do veredicto PASS de legal-qa (ex.: \"QA PASS contrato-x v2 em 2026-09-20 — agents/qa/results.md\")." ;;
      esac
      case "$MISSING" in
        *USER_OK*) echo "• Falta evidência de confirmação explícita do usuário para ESTE envio/assinatura (ex.: \"confirmado pelo usuário em 2026-09-20\")." ;;
      esac
      echo ""
      echo "Se a task é só PREPARAÇÃO (redigir, revisar, marcar desvios, registrar, montar dossiê), reescreva o título com esses verbos — sem 'enviar/assinar/protocolar/publicar'."
      echo "Adicione as evidências à descrição antes de concluir — sem PASS + confirmação, nada sai."
    } >&2
    exit 2 ;;
  *) exit 0 ;;
esac
