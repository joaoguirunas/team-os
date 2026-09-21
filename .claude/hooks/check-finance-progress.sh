#!/usr/bin/env bash
# .claude/hooks/check-finance-progress.sh
# TaskCompleted hook — quality gate de EXECUÇÃO financeira (squad finance).
# Exit 2 NEGA a conclusão (a task volta a in_progress e o teammate recebe o stderr).
#
# A squad finance PREPARA; quem move dinheiro é o humano. Este hook garante que nenhuma task
# que declara uma execução financeira feche sem as duas evidências:
#   • veredicto PASS do finance-qa (ex.: "PASS", "VEREDICTO: PASS", "QA PASS"), E
#   • confirmação explícita do usuário (ex.: "confirmado pelo usuário em 2026-09-20").
#
# Dispara quando a task referencia a squad finance (docs/smart-memory/agents/{controller,billing,
# tax,reporting,planning,strategy,research,qa}, story F<N>-… ou vocabulário financeiro: pagamento,
# transferência, PIX, boleto, cobrança, nota fiscal, guia, DAS/DARF, fechamento, relatório para
# sócios/investidores/banco) E descreve um ATO de execução (pagar, transferir, enviar PIX, emitir
# boleto/nota/guia, enviar cobrança, recolher, quitar, liquidar, agendar no banco, enviar relatório).
#
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

# Referencia a squad finance ou um artefato financeiro?
finance_ref = re.search(r"docs/smart-memory/agents/(controller|billing|tax|reporting|planning|strategy|research|qa)\b", blob) \
    or re.search(r"stories/[a-z-]+/F\d+-", blob) \
    or re.search(r"\bpagamentos?\b|\btransfer[êe]ncias?\b|\bpix\b|\bboletos?\b|\bcobran[çc]as?\b|\bnotas? fiscal|\bnf-?e\b|\bnfs-?e\b|\bguias?\b|\bdas\b|\bdarf\b|\bfechamento\b|\brelat[óo]rio (financeiro|mensal|para (os )?s[óo]cios|para (o )?investidor|para (o )?banco)|\bfinance-(qa|billing|tax|reporter|controller)\b", blob, re.I)
if not finance_ref:
    print("OK"); sys.exit(0)

# Ato de EXECUÇÃO financeira (não preparação)?
exec_act = re.search(
    r"\bpagar\b|\bpag[oa]s?\b|\bpagamento (efetuad|realizad|executad|feit|agendad)|"
    r"\btransferir\b|\btransferid[oa]s?\b|\btransfer[êe]ncia (realizad|feit|executad|enviad)|"
    r"\benviar (o |um )?pix\b|\bpix (enviad|feit|realizad)|"
    r"\bemitir\b|\bemiss[ãa]o\b|\bemitid[oa]s?\b|\bgerar (o |a )?(boleto|nota|nf|guia)|"
    r"\benviar (a |as )?cobran[çc]a|\bcobran[çc]a (enviad|disparad)|\bdisparar (a )?cobran[çc]a|"
    r"\brecolher\b|\brecolhid[oa]s?\b|\brecolhimento\b|\bquitar\b|\bquitad[oa]s?\b|\bliquidar\b|\bliquidad[oa]s?\b|"
    r"\bagendar (no |em )?(banco|internet banking)|\bagendad[oa] no banco|"
    r"\benviar (o )?relat[óo]rio|\brelat[óo]rio enviad|\benviad[oa] (aos|para os|ao|para o) (s[óo]cios|investidor|banco)|"
    r"\bsend payment\b|\bpaid\b|\bwire\b", blob, re.I)
if not exec_act:
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
      echo "🚫 Task de EXECUÇÃO financeira (pagar, transferir, PIX, boleto, nota, guia, cobrança, relatório enviado) só fecha com PASS do finance-qa e confirmação explícita do usuário — quem executa é o humano."
      echo ""
      case "$MISSING" in
        *PASS*) echo "• Falta evidência do veredicto PASS de finance-qa (ex.: \"QA PASS lote 2026-09-20 — agents/qa/results.md\")." ;;
      esac
      case "$MISSING" in
        *USER_OK*) echo "• Falta evidência de confirmação explícita do usuário para ESTA execução (ex.: \"confirmado pelo usuário em 2026-09-20\")." ;;
      esac
      echo ""
      echo "Se a task é só PREPARAÇÃO (preparar lote, montar régua, conciliar, calcular), reescreva o título com esses verbos — sem 'pagar/enviar/emitir/recolher'."
      echo "Adicione as evidências à descrição antes de concluir — sem PASS + confirmação, dinheiro não se move."
    } >&2
    exit 2 ;;
  *) exit 0 ;;
esac
