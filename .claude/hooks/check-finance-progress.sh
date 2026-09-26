#!/usr/bin/env bash
# .claude/hooks/check-finance-progress.sh
# TaskCompleted hook — quality gate de EXECUÇÃO financeira (squad finance).
# Exit 2 NEGA a conclusão (a task volta a in_progress e o teammate recebe o stderr).
#
# Payload real do evento (doc oficial de hooks): stdin JSON com task_id, task_subject,
# task_description (opcional), teammate_name, team_name + campos comuns.
# Chaves primárias: task_subject/task_description; fallback: title|subject|name|description|body|...
#
# A squad finance PREPARA; quem move dinheiro é o humano. Este hook garante que nenhuma task
# que declara uma execução financeira feche sem as duas evidências:
#   • veredicto PASS do finance-qa (ex.: "PASS", "VEREDICTO: PASS", "QA PASS"), E
#   • confirmação explícita do usuário (ex.: "confirmado pelo usuário em 2026-09-20").
#
# Dispara quando a task referencia a squad finance (docs/smart-memory/agents/[finance/]{controller,
# billing,tax,reporting,planning,strategy,research,qa} — com ou sem o segmento de squad —, story
# F<N>-… ou vocabulário financeiro: pagar, transferir, recolher, emitir nota/boleto, pagamento,
# transferência, PIX, boleto, cobrança, nota fiscal, guia de imposto/recolhimento/DAS/DARF, DAS/DARF
# (maiúsculas), fechamento, relatório para sócios/investidores/banco) E descreve um ATO de execução
# (pagar, transferir, enviar PIX, emitir boleto/nota/guia, enviar cobrança, recolher, quitar,
# liquidar, agendar no banco, enviar relatório, efetuar/realizar pagamento).
#
# NÃO dispara com "das" (artigo), "guia" solto, "pago/paga" como adjetivo ("registrar boleto pago")
# nem "paid" solto ("mark invoice as paid") — isso é escrituração, não execução.
# Tasks de PREPARAÇÃO (preparar lote, montar régua, conciliar, calcular, registrar) não disparam —
# use esses verbos no título. Caso não haja referência ou ato de execução → exit 0.
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

# Referencia a squad finance ou um artefato financeiro?
finance_ref = (
    re.search(r"docs/smart-memory/agents/" + SQUAD + r"(controller|billing|tax|reporting|planning|strategy|research|qa)\b", blob)
    or re.search(r"stories/[a-z-]+/F\d+-", blob)
    or re.search(
        r"\bpagar\b|\btransferir\b|\brecolher\b|\bemitir\s+(?:a\s+|o\s+|uma\s+|um\s+|as\s+|os\s+)?(?:notas?|boletos?|nf-?e|nfs-?e|guias?)\b|"
        r"\bpagamentos?\b|\btransfer[êe]ncias?\b|\bpix\b|\bboletos?\b|\bcobran[çc]as?\b|\bnotas?\s+fisca(?:l|is)\b|\bnf-?e\b|\bnfs-?e\b|"
        r"\bguias?\s+(?:de|do|da)\s+(?:impostos?|recolhimento|das|darf|gps|inss|fgts|iss|icms)\b|"
        r"\bfechamento\b|\brelat[óo]rio\s+(?:financeiro|mensal|(?:para|aos?)\s+(?:os?\s+)?(?:s[óo]cios|investidor(?:es)?|banco))\b|"
        r"\bfinance-(?:qa|billing|tax|reporter|controller)\b", blob, re.I)
    or re.search(r"\bDAS\b|\bDARF\b|\bGPS\b", blob)   # siglas: só em maiúsculas (evita o artigo "das")
)
if not finance_ref:
    print("OK"); sys.exit(0)

# Ato de EXECUÇÃO financeira (não preparação, não escrituração)?
exec_act = re.search(
    r"\bpagar\b|\bpagamento\s+(?:efetuad|realizad|executad|feit|agendad)|"
    r"\b(?:efetuar|realizar|executar|fazer|agendar)\w*\s+(?:\w+\s+){0,3}(?:pagamentos?|pag[oa]s?)\b|"
    r"\btransferir\b|\btransferid[oa]s?\b|\btransfer[êe]ncia\s+(?:realizad|feit|executad|enviad)|"
    r"\benviar\s+(?:o\s+|um\s+)?pix\b|\bpix\s+(?:enviad|feit|realizad)|"
    r"\bemitir\b|\bemiss[ãa]o\b|\bemitid[oa]s?\b|\bgerar\s+(?:o\s+|a\s+)?(?:boleto|nota|nf|guia)|"
    r"\benviar\s+(?:a\s+|as\s+)?cobran[çc]a|\bcobran[çc]a\s+(?:enviad|disparad)|\bdisparar\s+(?:a\s+)?cobran[çc]a|"
    r"\brecolher\b|\brecolhid[oa]s?\b|\brecolhimento\s+(?:efetuad|realizad|feit)|\bquitar\b|\bquitad[oa]s?\b|\bliquidar\b|\bliquidad[oa]s?\b|"
    r"\bagendar\s+(?:no\s+|em\s+)?(?:banco|internet banking)|\bagendad[oa]\s+no\s+banco|"
    r"\benviar\s+(?:o\s+)?relat[óo]rio|\brelat[óo]rio\s+enviad|\benviad[oa]\s+(?:aos|para os|ao|para o)\s+(?:s[óo]cios|investidor|banco)|"
    r"\bsend\s+payment\b|\bmake\s+(?:the\s+)?payment\b|\bpay\b|\bwire\b", blob, re.I)
if not exec_act:
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
      echo "🚫 Task de EXECUÇÃO financeira (pagar, transferir, PIX, boleto, nota, guia, cobrança, relatório enviado) só fecha com PASS do finance-qa e confirmação explícita do usuário — quem executa é o humano."
      echo ""
      case "$MISSING" in
        *PASS*) echo "• Falta evidência do veredicto PASS de finance-qa (ex.: \"QA PASS lote 2026-09-20 — agents/finance/qa/results.md\")." ;;
      esac
      case "$MISSING" in
        *USER_OK*) echo "• Falta evidência de confirmação explícita do usuário para ESTA execução (ex.: \"confirmado pelo usuário em 2026-09-20\")." ;;
      esac
      echo ""
      echo "Se a task é só PREPARAÇÃO (preparar lote, montar régua, conciliar, calcular, registrar), reescreva o título com esses verbos — sem 'pagar/enviar/emitir/recolher'."
      echo "Adicione as evidências à descrição antes de concluir — sem PASS + confirmação, dinheiro não se move."
    } >&2
    exit 2 ;;
  OK) exit 0 ;;
  *)
    echo "⚠️ check-finance-progress.sh: python3 falhou (${RESULT:-sem saída}) — hook não avaliou a task." >&2
    exit 0 ;;
esac
