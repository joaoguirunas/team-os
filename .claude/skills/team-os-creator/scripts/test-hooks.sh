#!/usr/bin/env bash
# .claude/skills/team-os-creator/scripts/test-hooks.sh
# Testa os hooks de .claude/hooks/ com payloads REAIS (formato da doc oficial de hooks):
#   • TaskCreated/TaskCompleted → task_subject / task_description / cwd
#   • PreToolUse Bash           → tool_name / tool_input.command / cwd
#   • PreToolUse Agent          → tool_input.isolation
#   • SessionStart              → source / cwd / session_title
#   • PreToolUse Read           → tool_input.file_path (+ session_id p/ o orçamento L2)
#   • PreToolUse SendMessage    → tool_input.message (string ou objeto de protocolo)
# Monta um repositório git temporário com docs/smart-memory/stories/{active,in-review,backlog,done}
# e stories de exemplo, roda cada hook e confere o exit code (0 = passa, 2 = bloqueia).
# Também simula falha do python3 (PATH com python3 falso) para cobrir os fallbacks em grep.
#
# bash 3.2-safe (sem mapfile, ${x,,}, declare -A, grep -P). Dependências: bash, python3, git.
# Roda no macOS e no CI ubuntu. Saída: PASS/FAIL por caso + resumo N/N; exit 1 se algum falhar.
#
# Uso: bash .claude/skills/team-os-creator/scripts/test-hooks.sh [--verbose]
#      HOOKS_DIR=/outro/.claude/hooks bash test-hooks.sh   (para testar hooks propagados)

set -u

VERBOSE=""
[ "${1:-}" = "--verbose" ] && VERBOSE=1

HERE=$(cd "$(dirname "$0")" && pwd)
CT_ROOT=$(cd "$HERE/../../../.." && pwd)
HOOKS="${HOOKS_DIR:-$CT_ROOT/.claude/hooks}"

if [ ! -d "$HOOKS" ]; then
  echo "hooks não encontrados em: $HOOKS" >&2
  exit 1
fi
command -v python3 >/dev/null 2>&1 || { echo "python3 é necessário para montar os payloads" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git é necessário" >&2; exit 1; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/hooks-test.XXXXXX")
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ── Fixtures ─────────────────────────────────────────────────────────────────
GIT="git -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false"

mk_repo() {  # mk_repo <dir> <branch>
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" symbolic-ref HEAD "refs/heads/$2"
  echo "x" > "$1/README.md"
  $GIT -C "$1" add README.md
  $GIT -C "$1" commit -q -m "init"
}

REPO="$TMP/repo-main"
REPO_FEATURE="$TMP/repo-feature"
REPO_DETACHED="$TMP/repo-detached"
NOT_A_REPO="$TMP/not-a-repo"

mk_repo "$REPO" main
mk_repo "$REPO_FEATURE" "feature/x"
mk_repo "$REPO_DETACHED" main
git -C "$REPO_DETACHED" checkout -q --detach HEAD
mkdir -p "$NOT_A_REPO"

STORIES="$REPO/docs/smart-memory/stories"
mkdir -p "$STORIES/active" "$STORIES/in-review" "$STORIES/backlog" "$STORIES/done"

cat > "$STORIES/active/S1-login.md" <<'EOF'
---
id: S1
title: Login com e-mail
status: in-progress
---
# S1 — Login com e-mail
## Acceptance Criteria
- usuário entra com e-mail e senha
EOF

cat > "$STORIES/in-review/S2-checkout.md" <<'EOF'
---
id: S2
title: Checkout
status: in-review
---
# S2 — Checkout
EOF

cat > "$STORIES/active/3.2-pagamentos.md" <<'EOF'
---
id: 3.2
title: Pagamentos
status: in-progress
---
# 3.2 — Pagamentos

## QA Results
PASS — 2026-09-25
EOF

cat > "$STORIES/backlog/S4-relatorio.md" <<'EOF'
---
id: S4
status: backlog
---
# S4 — Relatório
EOF

# TMPDIR isolado para os hooks (contador L2 do guard-smart-memory-read.sh)
mkdir -p "$TMP/tmpd"

# python3 falso: simula falha do intérprete (hook deve avisar em stderr e usar o fallback grep)
mkdir -p "$TMP/nopy"
cat > "$TMP/nopy/python3" <<'EOF'
#!/bin/sh
echo "boom: python3 simulado falhando" >&2
exit 1
EOF
chmod +x "$TMP/nopy/python3"

# ── Helpers ──────────────────────────────────────────────────────────────────
TOTAL=0; PASSED=0; FAILED=0
CPD="$REPO"            # CLAUDE_PROJECT_DIR usado nos casos
TESTPATH="$PATH"       # PATH usado nos casos (troca para simular python3 quebrado)

jstr() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

task_payload() {  # <event> <subject> <description> [cwd]
  printf '{"session_id":"t1","hook_event_name":%s,"cwd":%s,"task_id":"42","task_subject":%s,"task_description":%s,"teammate_name":"dev-alpha","team_name":"dev"}' \
    "$(jstr "$1")" "$(jstr "${4:-$REPO}")" "$(jstr "$2")" "$(jstr "$3")"
}
task_payload_legacy() {  # <event> <title> <description>  (chaves antigas, fallback)
  printf '{"session_id":"t1","hook_event_name":%s,"cwd":%s,"task_id":"42","title":%s,"description":%s}' \
    "$(jstr "$1")" "$(jstr "$REPO")" "$(jstr "$2")" "$(jstr "$3")"
}
bash_payload() {  # <command> [cwd]
  printf '{"session_id":"t1","hook_event_name":"PreToolUse","cwd":%s,"tool_name":"Bash","tool_input":{"command":%s}}' \
    "$(jstr "${2:-$REPO}")" "$(jstr "$1")"
}
bash_payload_nocwd() {  # <command>  (sem cwd → hook usa CLAUDE_PROJECT_DIR)
  printf '{"session_id":"t1","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":%s}}' "$(jstr "$1")"
}
agent_payload() {  # <isolation>
  printf '{"session_id":"t1","hook_event_name":"PreToolUse","cwd":%s,"tool_name":"Agent","tool_input":{"prompt":"faz x","subagent_type":"dev-dev-alpha","isolation":%s}}' \
    "$(jstr "$REPO")" "$(jstr "$1")"
}
tool_payload() {  # <tool_name>
  printf '{"session_id":"t1","hook_event_name":"PreToolUse","cwd":%s,"tool_name":%s,"tool_input":{}}' "$(jstr "$REPO")" "$(jstr "$1")"
}
session_payload() {  # <source> <cwd> <session_title>
  printf '{"session_id":"t1","hook_event_name":"SessionStart","source":%s,"cwd":%s,"session_title":%s}' \
    "$(jstr "$1")" "$(jstr "$2")" "$(jstr "$3")"
}

LAST_OUT=""
run_hook() {  # <hook> <payload>  → LAST_OUT = stdout+stderr ; retorna rc
  LAST_OUT=$(printf '%s' "$2" | PATH="$TESTPATH" CLAUDE_PROJECT_DIR="$CPD" TMPDIR="$TMP/tmpd" bash "$HOOKS/$1" 2>&1)
  return $?
}

expect() {  # <rc esperado> <hook> <payload> <rótulo>
  local want="$1" hook="$2" payload="$3" label="$4" rc
  run_hook "$hook" "$payload"; rc=$?
  TOTAL=$((TOTAL + 1))
  if [ "$rc" -eq "$want" ]; then
    PASSED=$((PASSED + 1))
    echo "PASS [$hook] $label"
    [ -n "$VERBOSE" ] && [ -n "$LAST_OUT" ] && printf '%s\n' "$LAST_OUT" | sed 's/^/      /'
  else
    FAILED=$((FAILED + 1))
    echo "FAIL [$hook] $label — esperado exit $want, obteve $rc"
    printf '%s\n' "$LAST_OUT" | sed 's/^/      /'
  fi
}

expect_out_contains() {  # <hook> <payload> <substring> <rótulo>
  local hook="$1" payload="$2" needle="$3" label="$4" out
  out=$(printf '%s' "$payload" | PATH="$TESTPATH" CLAUDE_PROJECT_DIR="$CPD" bash "$HOOKS/$hook" 2>/dev/null)
  TOTAL=$((TOTAL + 1))
  case "$out" in
    *"$needle"*) PASSED=$((PASSED + 1)); echo "PASS [$hook] $label" ;;
    *) FAILED=$((FAILED + 1)); echo "FAIL [$hook] $label — stdout não contém '$needle':"; printf '%s\n' "$out" | sed 's/^/      /' ;;
  esac
}

expect_out_empty() {  # <hook> <payload> <rótulo>
  local hook="$1" payload="$2" label="$3" out
  out=$(printf '%s' "$payload" | PATH="$TESTPATH" CLAUDE_PROJECT_DIR="$CPD" bash "$HOOKS/$hook" 2>/dev/null)
  TOTAL=$((TOTAL + 1))
  if [ -z "$out" ]; then PASSED=$((PASSED + 1)); echo "PASS [$hook] $label"
  else FAILED=$((FAILED + 1)); echo "FAIL [$hook] $label — stdout deveria ser vazio:"; printf '%s\n' "$out" | sed 's/^/      /'; fi
}

expect_stderr_warning() {  # <hook> <payload> <rótulo> — LAST_OUT deve conter o aviso ⚠️
  run_hook "$1" "$2" || true
  TOTAL=$((TOTAL + 1))
  case "$LAST_OUT" in
    *"⚠️"*) PASSED=$((PASSED + 1)); echo "PASS [$1] $3" ;;
    *) FAILED=$((FAILED + 1)); echo "FAIL [$1] $3 — sem aviso ⚠️ em stderr:"; printf '%s\n' "$LAST_OUT" | sed 's/^/      /' ;;
  esac
}

section() { echo ""; echo "── $1"; }

# ── 0. Sintaxe + permissão de execução ───────────────────────────────────────
section "sintaxe (bash -n) e chmod +x"
for f in "$HOOKS"/*.sh; do
  TOTAL=$((TOTAL + 1))
  if bash -n "$f" 2>/dev/null; then PASSED=$((PASSED + 1)); echo "PASS [$(basename "$f")] bash -n"
  else FAILED=$((FAILED + 1)); echo "FAIL [$(basename "$f")] bash -n"; fi
  TOTAL=$((TOTAL + 1))
  if [ -x "$f" ]; then PASSED=$((PASSED + 1)); echo "PASS [$(basename "$f")] executável"
  else FAILED=$((FAILED + 1)); echo "FAIL [$(basename "$f")] não é executável (chmod +x)"; fi
done

# ── 1. task-quality.sh (TaskCreated) ─────────────────────────────────────────
section "task-quality.sh"
H=task-quality.sh
expect 0 $H "$(task_payload TaskCreated "Corrigir paginação da listagem de campanhas" "A listagem pula a página 2. Done: páginas navegam certo.")" "chaves reais: título+descrição ok"
expect 2 $H "$(task_payload TaskCreated "fix" "Corrige.")" "chaves reais: título curto"
expect 2 $H "$(task_payload TaskCreated "ajuste task 3" "descrição qualquer")" "chaves reais: só palavras genéricas"
expect 2 $H "$(task_payload TaskCreated "Corrigir paginação da listagem de campanhas" "")" "chaves reais: sem descrição"
expect 0 $H "$(task_payload_legacy TaskCreated "Corrigir paginação da listagem de campanhas" "Contexto suficiente.")" "fallback title/description ok"
expect 2 $H "$(task_payload_legacy TaskCreated "todo" "x")" "fallback title curto"
expect 0 $H '{"hook_event_name":"TaskCreated","foo":"bar"}' "payload sem título identificável → passa"
expect 0 $H 'não é json' "JSON malformado → passa"

# ── 2. check-story-progress.sh (TaskCompleted) ───────────────────────────────
section "check-story-progress.sh"
H=check-story-progress.sh
expect 0 $H "$(task_payload TaskCompleted "Atualizar README do projeto" "Sem story envolvida.")" "sem referência a story → passa"
expect 2 $H "$(task_payload TaskCompleted "Implementar login" "Story: docs/smart-memory/stories/active/S1-login.md")" "path: story in-progress sem QA → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Implementar checkout" "Story: ./docs/smart-memory/stories/in-review/S2-checkout.md")" "path com ./ normalizado: status in-review → passa"
expect 0 $H "$(task_payload TaskCompleted "Implementar pagamentos" "Story docs/smart-memory/stories/active/3.2-pagamentos.md")" "path: story com ## QA Results → passa"
expect 2 $H "$(task_payload TaskCompleted "Implementar busca" "Story: docs/smart-memory/stories/active/S9-busca.md")" "path inexistente → bloqueia (defensivo)"
expect 2 $H "$(task_payload TaskCompleted "Fechar story S1" "Login pronto.")" "id 'story S1' (in-progress) → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Fechar story S2" "Checkout em review.")" "id 'story S2' (in-review) → passa"
expect 0 $H "$(task_payload TaskCompleted "Fechar story 3.2" "Pagamentos com QA.")" "id 'story 3.2' (QA Results) → passa"
expect 2 $H "$(task_payload TaskCompleted "Fechar story S4" "Relatório.")" "id 'story S4' (backlog) → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Fechar story S9" "Não existe.")" "id 'story S9' inexistente → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Implementar S1 conforme a story" "Detalhes.")" "id 'S1' solto com a palavra story → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Configurar bucket S3 na AWS" "Upload de assets.")" "'S3' sem contexto de story → passa (não é id)"
expect 0 $H "$(task_payload TaskCompleted "Ajustar timeout para 2.5 segundos" "Config.")" "'2.5' sem contexto de story → passa"
expect 2 $H "$(task_payload_legacy TaskCompleted "Implementar login" "docs/smart-memory/stories/active/S1-login.md")" "fallback title/description com path → bloqueia"
CPD="/nonexistent-dir"
expect 2 $H "$(task_payload TaskCompleted "Implementar login" "docs/smart-memory/stories/active/S1-login.md")" "raiz vem do cwd do JSON (CLAUDE_PROJECT_DIR inválido)"
CPD="$REPO"
expect 0 $H 'não é json' "JSON malformado → passa"

# ── 3. check-social-progress.sh ──────────────────────────────────────────────
section "check-social-progress.sh"
H=check-social-progress.sh
expect 0 $H "$(task_payload TaskCompleted "Publicar post no Instagram" "Aprovado pela VERA em 2026-09-05 — agents/social/strategist/approvals.md")" "publicar post + aprovado → passa"
expect 2 $H "$(task_payload TaskCompleted "Publicar post no Instagram" "Pendente.")" "publicar post sem aprovação (vocabulário, sem path) → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Publicar reel no Instagram" "Ainda não aprovado pela VERA.")" "negação 'ainda não aprovado' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Publicar story" "Conteúdo não aprovado.")" "negação 'não aprovado' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Publicar carrossel no LinkedIn" "Desaprovado pela VERA, refazer.")" "'desaprovado' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Publicar carrossel no LinkedIn" "Reprovado pela VERA.")" "'reprovado' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Publicar post" "Não foi aprovado ainda.")" "'não foi aprovado' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Agendar publicação do carrossel" "Para amanhã 9h.")" "'agendar publicação' → bloqueia sem aprovação"
expect 2 $H "$(task_payload TaskCompleted "Schedule post for LinkedIn" "Tomorrow 9am.")" "'schedule post' → bloqueia sem aprovação"
expect 0 $H "$(task_payload TaskCompleted "Schedule post for LinkedIn" "Approved by VERA on 2026-09-05.")" "'schedule post' + approved → passa"
expect 2 $H "$(task_payload TaskCompleted "Publish reel on Instagram" "Not approved yet.")" "'publish reel' + 'not approved' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Publicar" "Fila: docs/smart-memory/agents/publisher/queue.md")" "path antigo agents/publisher + publicar → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Publicar" "Fila: docs/smart-memory/agents/social/publisher/queue.md")" "path novo agents/social/publisher + publicar → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Publicar" "Fila: docs/smart-memory/agents/social/publisher/queue.md — aprovado pela VERA")" "path novo + aprovado → passa"
expect 0 $H "$(task_payload TaskCompleted "Escrever legenda do post de sexta" "Rascunho em agents/social/content/")" "sem ato de publicação → passa"
expect 0 $H "$(task_payload TaskCompleted "Revisar post do Instagram de ontem" "Ajustar hashtags.")" "'post' como substantivo (revisão) → passa"
expect 0 $H "$(task_payload TaskCompleted "Publish npm package @acme/ui" "Bump 1.2.0")" "'publish' sem objeto social → passa"

# ── 4. check-proposal-progress.sh ────────────────────────────────────────────
section "check-proposal-progress.sh"
H=check-proposal-progress.sh
expect 2 $H "$(task_payload TaskCompleted "Enviar proposta ao cliente Acme" "PDF v3 pronto.")" "'Enviar proposta ao cliente' sem PASS+confirmação → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Enviar proposta ao cliente Acme" "QA PASS v3 em 2026-09-07 — agents/sales/qa/results.md. Confirmado pelo usuário em 2026-09-07.")" "envio com PASS + confirmação → passa"
expect 2 $H "$(task_payload TaskCompleted "Enviar proposta ao cliente Acme" "QA PASS v3 — agents/sales/qa/results.md")" "só PASS (sem confirmação) → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Enviar proposta ao cliente Acme" "Confirmado pelo usuário em 2026-09-07.")" "só confirmação (sem PASS) → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Revisar proposta enviada pelo cliente" "Marcar pontos de negociação.")" "particípio 'enviada' (revisão) → passa"
expect 0 $H "$(task_payload TaskCompleted "Preparar apresentação para envio interno" "Deck para o time.")" "'envio interno' → passa"
expect 2 $H "$(task_payload TaskCompleted "Emitir proposta v3 para Acme" "Gerar PDF final.")" "'emitir proposta' sem evidências → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Enviar" "Ledger: docs/smart-memory/agents/closer/ledger.md")" "path antigo agents/closer + enviar → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Enviar" "Ledger: docs/smart-memory/agents/sales/closer/ledger.md")" "path novo agents/sales/closer + enviar → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Send final version" "Story stories/active/P3-proposta-acme.md")" "story P<N> + send → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Atualizar planilha de custos internos" "Sem proposta envolvida.")" "sem referência sales → passa"
expect 0 $H "$(task_payload TaskCompleted "Registrar proposta emitida v2 no ledger" "Histórico.")" "particípio 'emitida' (registro) → passa"

# ── 5. check-finance-progress.sh ─────────────────────────────────────────────
section "check-finance-progress.sh"
H=check-finance-progress.sh
expect 2 $H "$(task_payload TaskCompleted "Pagar fornecedor X" "Boleto vence hoje.")" "'Pagar fornecedor X' sem PASS+confirmação → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Pagar fornecedor X" "QA PASS lote 2026-09-20 — agents/finance/qa/results.md. Confirmado pelo usuário em 2026-09-20.")" "pagar com PASS + confirmação → passa"
expect 2 $H "$(task_payload TaskCompleted "Pagar fornecedor X" "QA PASS lote — agents/finance/qa/results.md")" "só PASS → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Conciliar extrato das contas de setembro" "Item a item.")" "'das' (artigo) não é DAS → passa"
expect 0 $H "$(task_payload TaskCompleted "Revisar guia de boas práticas do onboarding" "Doc interno.")" "'guia' solto não é guia de imposto → passa"
expect 0 $H "$(task_payload TaskCompleted "Registrar boleto pago no ledger" "Escrituração.")" "'pago' adjetivo (escrituração) → passa"
expect 0 $H "$(task_payload TaskCompleted "Mark invoice as paid in ledger" "Bookkeeping.")" "'paid' solto → passa"
expect 2 $H "$(task_payload TaskCompleted "Recolher DAS de setembro" "Vence dia 20.")" "'recolher DAS' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Emitir nota fiscal para cliente Y" "NFS-e.")" "'emitir nota fiscal' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Transferir saldo para conta reserva" "R$ 10k.")" "'transferir' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Realizar pagamento do fornecedor Z" "Via PIX.")" "'realizar pagamento' → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Preparar lote de pagamento da semana" "Documentos anexos.")" "preparação (preparar lote) → passa"
expect 0 $H "$(task_payload TaskCompleted "Montar régua de cobrança" "D-5/D0/D+3.")" "preparação (montar régua) → passa"
expect 2 $H "$(task_payload TaskCompleted "Enviar relatório de setembro" "Base: docs/smart-memory/agents/reporting/relatorio.md")" "path antigo agents/reporting + enviar relatório → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Enviar relatório de setembro" "Base: docs/smart-memory/agents/finance/reporting/relatorio.md")" "path novo agents/finance/reporting + enviar relatório → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Enviar relatório aos sócios" "Setembro.")" "'enviar relatório aos sócios' → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Enviar relatório de bugs ao time" "Sem finanças.")" "'enviar relatório' sem referência financeira → passa"

# ── 6. check-legal-progress.sh ───────────────────────────────────────────────
section "check-legal-progress.sh"
H=check-legal-progress.sh
expect 2 $H "$(task_payload TaskCompleted "Enviar minuta à contraparte" "v2 final.")" "'enviar minuta à contraparte' sem PASS+confirmação → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Enviar minuta à contraparte" "QA PASS contrato-x v2 em 2026-09-20 — agents/legal/qa/results.md. Confirmado pelo usuário em 2026-09-20.")" "envio com PASS + confirmação → passa"
expect 0 $H "$(task_payload TaskCompleted "Revisar contrato enviado pela contraparte" "Marcar desvios.")" "particípio 'enviado' (revisão) → passa"
expect 0 $H "$(task_payload TaskCompleted "Arquivar contrato assinado no registro" "Vigência 12 meses.")" "particípio 'assinado' (arquivo) → passa"
expect 2 $H "$(task_payload TaskCompleted "Assinar contrato com fornecedor" "Versão travada.")" "'assinar contrato' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Protocolar petição inicial" "Foro central.")" "'protocolar petição' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Notificar a contraparte sobre inadimplemento do contrato" "Extrajudicial.")" "'notificar a contraparte' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Publicar política de privacidade no site" "LGPD.")" "'publicar política' → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Enviar minuta" "Base: docs/smart-memory/agents/drafting/minuta-acme.md")" "path antigo agents/drafting + enviar minuta → bloqueia"
expect 2 $H "$(task_payload TaskCompleted "Enviar minuta" "Base: docs/smart-memory/agents/legal/drafting/minuta-acme.md")" "path novo agents/legal/drafting + enviar minuta → bloqueia"
expect 0 $H "$(task_payload TaskCompleted "Redigir aditivo do contrato Acme" "Base: docs/smart-memory/agents/legal/drafting/minuta-acme.md")" "path novo + redigir (preparação) → passa"
expect 0 $H "$(task_payload TaskCompleted "Montar dossiê do caso Acme" "Cronologia + evidências.")" "preparação (montar dossiê) → passa"
expect 0 $H "$(task_payload TaskCompleted "Enviar e-mail de status ao time" "Sem jurídico.")" "'enviar' sem referência legal → passa"

# ── 7. block-git-push.sh ─────────────────────────────────────────────────────
section "block-git-push.sh"
H=block-git-push.sh
for c in \
  'git push origin main' \
  'git push' \
  'git push --dry-run' \
  'git -C /tmp/x push' \
  'git -C "dir com espaço" push origin main' \
  'git --git-dir=.git push' \
  'git --git-dir .git --work-tree . push' \
  'GIT_DIR=.git git push' \
  '\git push' \
  '/usr/bin/git push' \
  'command git push' \
  'env git push' \
  'env -i PATH=/usr/bin git push' \
  'git "push"' \
  "git 'push' origin main" \
  'git status && git push' \
  'git add . ; git push' \
  'git add . || git push' \
  'echo $(git push)' \
  'sudo -u deploy git push' \
  'timeout 30 git push' \
  'nohup git push &' \
  'xargs git push < remotes.txt' \
  'sh -c "git push"' \
  "bash -lc 'git push origin main'" \
  'zsh -c "git push"' \
  '/bin/sh -c "git push"' \
  'eval "git push"' \
  'c="git push"; eval "$c"' \
  'find . -name x -exec git push \;' \
  'echo "git push" | sh' \
  "printf 'git push' | bash" \
  'echo "git push" | /bin/bash' \
  "python3 -c \"import os; os.system('git push')\"" \
  "python -c \"import subprocess; subprocess.run(['git','push'])\"" \
  "node -e \"require('child_process').execSync('git push')\"" \
  "perl -e 'system(\"git push\")'" \
  'g=git; $g push' \
  'GIT=git; "$GIT" push origin main' \
  '${GIT:-git} push' \
  'git ${X} push' \
  'git $SUB origin main' \
  'git p$@ush' \
  "git pu''sh" \
  'git -c alias.p=push p' \
  'git -c alias.p="push --force" p' \
  'git config alias.p push' \
  'git config --global alias.pp "push --force"' \
  'git send-pack origin' \
  'git svn dcommit' \
  'gh pr create --fill' \
  'gh pr merge 12 --squash' \
  'gh release create v1.0.0' \
  'gh repo sync' \
  'gh api -X POST repos/acme/x/pulls -f title=x' \
  'gh api repos/acme/x/pulls/1/merge -X PUT' \
  'gh api --method PATCH repos/acme/x/pulls/1 -f state=closed'
do
  expect 2 $H "$(bash_payload "$c")" "bloqueia: $c"
done
expect 2 $H "$(bash_payload "$(printf 'git add .\ngit push')")" "bloqueia: multilinha (git add . \\n git push)"
expect 2 $H "$(bash_payload "$(printf 'git \\\n  push')")" "bloqueia: continuação de linha (git \\ push)"
expect 2 $H "$(bash_payload "$(printf 'bash <<EOF\ngit push\nEOF')")" "bloqueia: heredoc para bash"
expect 2 $H "$(bash_payload "$(printf 'sh <<-X\n\tgit push\nX')")" "bloqueia: heredoc para sh"
for c in \
  'git status' \
  'git commit -m "push"' \
  'git commit -m "git push later"' \
  'git commit -am "feat: push notifications"' \
  'echo "push"' \
  'echo push' \
  'echo pushed' \
  'git log --oneline -5' \
  'git pull --rebase' \
  'git fetch origin' \
  'git stash push -m wip' \
  'git branch -a' \
  'git config user.name x' \
  'git diff HEAD~1' \
  'npm run build' \
  'grep -r "push" src/' \
  "python3 -c \"print('hello')\"" \
  'bash -c "npm test"' \
  'bash -c "git status"' \
  'gh pr list' \
  'gh pr view 12' \
  'gh api repos/acme/x/pulls' \
  'gh api repos/acme/x/pulls/1' \
  'gh release list' \
  'git -C "dir com espaço" status' \
  'ls -la'
do
  expect 0 $H "$(bash_payload "$c")" "passa: $c"
done
expect 0 $H 'não é json' "JSON malformado → passa"

# ── 8. block-worktree.sh ─────────────────────────────────────────────────────
section "block-worktree.sh"
H=block-worktree.sh
expect 2 $H "$(agent_payload worktree)" "bloqueia: Agent com isolation: worktree"
expect 0 $H "$(agent_payload "")" "passa: Agent sem isolation"
expect 2 $H "$(tool_payload EnterWorktree)" "bloqueia: ferramenta EnterWorktree"
for c in \
  'git worktree add ../x' \
  'git worktree add -b feat ../x' \
  'git -C /p worktree add ../x' \
  'GIT_DIR=.git git worktree add ../x' \
  '\git worktree add ../x' \
  'git checkout -b feat' \
  'git checkout -B feat' \
  'git checkout --orphan gh-pages' \
  'git checkout -t origin/feat' \
  'git checkout --track origin/feat' \
  'git switch -c feat' \
  'git switch -C feat' \
  'git switch --create feat' \
  'git switch -t origin/feat' \
  'git switch --track origin/feat' \
  'git branch feat' \
  'git branch -f feat HEAD' \
  'git branch --track feat origin/feat' \
  'git branch -c main feat' \
  'git stash branch feat' \
  'git update-ref refs/heads/feat HEAD' \
  'git push origin HEAD:refs/heads/feat' \
  'git push -u origin main:refs/heads/feat' \
  'git symbolic-ref HEAD refs/heads/feat' \
  'git config alias.wt "worktree add"' \
  'git config alias.nb "checkout -b"' \
  'git -c alias.wt="worktree add" wt ../x' \
  'git -c alias.nb="checkout -b" nb feat' \
  'sh -c "git worktree add ../x"' \
  'eval "git checkout -b feat"' \
  "bash -c 'git branch feat'" \
  'echo "git switch -c feat" | sh' \
  'xargs git checkout -b < names.txt' \
  "python3 -c \"import os; os.system('git worktree add ../x')\"" \
  'g=git; $g worktree add ../x' \
  'git ${X} -b feat' \
  'git w$Xorktree add ../x' \
  "git check''out -b feat"
do
  expect 2 $H "$(bash_payload "$c")" "bloqueia: $c"
done
expect 2 $H "$(bash_payload "$(printf 'git fetch\ngit checkout -b feat')")" "bloqueia: multilinha (checkout -b)"
expect 2 $H "$(bash_payload "$(printf 'bash <<EOF\ngit worktree add ../x\nEOF')")" "bloqueia: heredoc para bash (worktree add)"
for c in \
  'git branch' \
  'git branch -a' \
  'git branch -v' \
  'git branch -vv' \
  'git branch --show-current' \
  'git branch -l "feat*"' \
  'git branch --list' \
  'git branch --contains abc123' \
  'git branch --merged main' \
  'git branch -d feat' \
  'git branch -D feat' \
  'git branch --delete feat' \
  'git branch -m old new' \
  'git branch -M main' \
  'git branch --move old new' \
  'git branch --set-upstream-to=origin/main' \
  'git branch --set-upstream-to origin/main' \
  'git branch -u origin/main' \
  'git branch -u origin/main feat' \
  'git branch --unset-upstream' \
  'git branch --edit-description' \
  'git checkout main' \
  'git checkout -- file.txt' \
  'git checkout HEAD~1 -- file.txt' \
  'git switch main' \
  'git switch -' \
  'git worktree list' \
  'git worktree prune' \
  'git stash' \
  'git stash push -m wip' \
  'git stash pop' \
  'git stash list' \
  'git push origin HEAD:refs/heads/main' \
  'git push origin main:refs/heads/master' \
  'git push origin main' \
  'git symbolic-ref HEAD' \
  'git symbolic-ref --short HEAD' \
  'git update-ref -d refs/heads/feat' \
  'git status' \
  'git log --branches --oneline' \
  'git commit -m "new branch feature"' \
  'bash -c "git status"' \
  'ls -la'
do
  expect 0 $H "$(bash_payload "$c")" "passa: $c"
done
expect 0 $H 'não é json' "JSON malformado → passa"

# ── 9. guard-push-branch.sh ──────────────────────────────────────────────────
section "guard-push-branch.sh"
H=guard-push-branch.sh
expect 0 $H "$(bash_payload 'git status' "$REPO")" "sem push → passa"
expect 0 $H "$(bash_payload 'git push' "$REPO")" "main: git push → passa"
expect 0 $H "$(bash_payload 'git push origin main' "$REPO")" "main: git push origin main → passa"
expect 0 $H "$(bash_payload 'git push -u origin HEAD:main' "$REPO")" "main: git push -u origin HEAD:main → passa"
expect 0 $H "$(bash_payload 'git push origin HEAD:refs/heads/main' "$REPO")" "main: HEAD:refs/heads/main → passa"
expect 0 $H "$(bash_payload 'git push --force-with-lease origin main' "$REPO")" "main: --force-with-lease origin main → passa"
expect 0 $H "$(bash_payload 'git push --tags' "$REPO")" "main: git push --tags → passa"
expect 0 $H "$(bash_payload 'git push origin HEAD' "$REPO")" "main: git push origin HEAD → passa"
expect 2 $H "$(bash_payload 'git push origin feature' "$REPO")" "main: git push origin feature → bloqueia (ref destino ≠ main)"
expect 2 $H "$(bash_payload 'git push origin main:feature' "$REPO")" "main: git push origin main:feature → bloqueia"
expect 2 $H "$(bash_payload 'git push origin :feature' "$REPO")" "main: git push origin :feature (delete remoto) → bloqueia"
expect 2 $H "$(bash_payload 'git push origin --delete feature' "$REPO")" "main: git push origin --delete feature → bloqueia"
expect 2 $H "$(bash_payload 'git push origin v1.0.0' "$REPO")" "main: git push origin v1.0.0 (tag explícita) → bloqueia"
expect 2 $H "$(bash_payload 'git push' "$REPO_FEATURE")" "feature: git push → bloqueia"
expect 2 $H "$(bash_payload 'git push origin main' "$REPO_FEATURE")" "feature: git push origin main → bloqueia (branch atual ≠ main)"
expect 2 $H "$(bash_payload 'git push origin HEAD:main' "$REPO_FEATURE")" "feature: git push origin HEAD:main → bloqueia"
expect 2 $H "$(bash_payload 'git push' "$REPO_DETACHED")" "detached HEAD: git push → bloqueia"
expect 2 $H "$(bash_payload 'git push' "$NOT_A_REPO")" "fora de repositório: git push → bloqueia"
expect 2 $H "$(bash_payload "git -C \"$REPO_FEATURE\" push" "$REPO")" "cwd main, -C repo-feature → bloqueia (alvo é o -C)"
expect 0 $H "$(bash_payload "git -C \"$REPO\" push" "$REPO_FEATURE")" "cwd feature, -C repo-main → passa (alvo é o -C)"
expect 0 $H "$(bash_payload "git --git-dir=\"$REPO/.git\" push" "$REPO_FEATURE")" "cwd feature, --git-dir repo-main → passa"
expect 2 $H "$(bash_payload 'git -C repo-feature push' "$TMP")" "-C relativo ao cwd (repo-feature) → bloqueia"
expect 0 $H "$(bash_payload 'git -C repo-main push' "$TMP")" "-C relativo ao cwd (repo-main) → passa"
expect 2 $H "$(bash_payload 'git -C repo-main -C ../repo-feature push' "$TMP")" "-C encadeado (repo-main/../repo-feature) → bloqueia"
expect 2 $H "$(bash_payload 'sh -c "git push origin feature"' "$REPO")" "main: sh -c com push para feature → bloqueia"
expect 0 $H "$(bash_payload 'sh -c "git push"' "$REPO")" "main: sh -c \"git push\" → passa (alvo = cwd main)"
expect 2 $H "$(bash_payload 'sh -c "git push"' "$REPO_FEATURE")" "feature: sh -c \"git push\" → bloqueia"
expect 2 $H "$(bash_payload 'g=git; $g push' "$REPO_FEATURE")" "feature: \$g push → bloqueia"
expect 2 $H "$(bash_payload 'git send-pack origin' "$REPO_FEATURE")" "feature: git send-pack → bloqueia"
CPD="$REPO_FEATURE"
expect 2 $H "$(bash_payload_nocwd 'git push')" "sem cwd no JSON: CLAUDE_PROJECT_DIR=feature → bloqueia"
CPD="$REPO"
expect 0 $H "$(bash_payload_nocwd 'git push')" "sem cwd no JSON: CLAUDE_PROJECT_DIR=main → passa"

# ── 10. team-os-session-title.sh (SessionStart) ──────────────────────────────
section "team-os-session-title.sh"
H=team-os-session-title.sh
expect_out_contains $H "$(session_payload startup "$REPO" "")" '"sessionTitle":"repo-main · main"' "startup sem título → nomeia 'repo-main · main'"
expect_out_empty $H "$(session_payload resume "$REPO" "Meu título escolhido")" "resume com título do usuário → preserva (sem saída)"
expect_out_empty $H "$(session_payload clear "$REPO" "")" "clear → ignora (sem saída)"
expect 0 $H "$(session_payload startup "$REPO" "")" "exit 0 em startup"

# ── 10b. guard-smart-memory-read.sh (PreToolUse Read|Bash) ───────────────────
section "guard-smart-memory-read.sh"
H=guard-smart-memory-read.sh
SMD="$REPO/docs/smart-memory"
mkdir -p "$SMD/_archive/2026-Q3" "$SMD/agents/dev/backend" "$SMD/_inbox" "$SMD/project"
GSM_N=0
gsm_sid() { GSM_N=$((GSM_N + 1)); GSM_SID="gsm-$$-$GSM_N"; }   # session_id novo por cenário
read_payload() {  # <file_path> [session_id|-]  ("-" = sem session_id)
  if [ "${2:-}" = "-" ]; then
    printf '{"hook_event_name":"PreToolUse","cwd":%s,"tool_name":"Read","tool_input":{"file_path":%s}}' "$(jstr "$REPO")" "$(jstr "$1")"
  else
    printf '{"session_id":%s,"hook_event_name":"PreToolUse","cwd":%s,"tool_name":"Read","tool_input":{"file_path":%s}}' "$(jstr "${2:-$GSM_SID}")" "$(jstr "$REPO")" "$(jstr "$1")"
  fi
}
sm_bash() {  # <command> [session_id]
  printf '{"session_id":%s,"hook_event_name":"PreToolUse","cwd":%s,"tool_name":"Bash","tool_input":{"command":%s}}' "$(jstr "${2:-$GSM_SID}")" "$(jstr "$REPO")" "$(jstr "$1")"
}
gsm_sid
expect 2 $H "$(read_payload "$SMD/_archive/2026-Q3/velha.md")" "(a) Read _archive/ com path absoluto → bloqueia"
expect 2 $H "$(read_payload "docs/smart-memory/_archive/LEDGER.md")" "(a) Read _archive/ com path relativo → bloqueia"
expect 2 $H "$(read_payload "./docs/smart-memory/agents/../_archive/x.md")" "(a) Read _archive/ via ../ (normalizado) → bloqueia"
expect 2 $H "$(sm_bash 'cat docs/smart-memory/_archive/2026-Q3/velha.md')" "(a) cat _archive/ → bloqueia"
expect 2 $H "$(sm_bash "head -n 20 \"$SMD/_archive/2026-Q3/velha.md\"")" "(a) head _archive/ (absoluto, com aspas) → bloqueia"
expect 2 $H "$(sm_bash "sed -n '1,40p' docs/smart-memory/_archive/LEDGER.md")" "(a) sed -n _archive/ → bloqueia"
expect 2 $H "$(sm_bash 'bash .claude/skills/team-os/scripts/sm-find.sh x && tail docs/smart-memory/_archive/a.md')" "(a) sm-find não libera _archive/ no mesmo comando → bloqueia"
expect 2 $H "$(sm_bash 'cat docs/smart-memory/*')" "(b) cat docs/smart-memory/* → bloqueia"
expect 2 $H "$(sm_bash 'cat docs/smart-memory/**/*.md')" "(b) cat docs/smart-memory/**/*.md → bloqueia"
expect 2 $H "$(sm_bash 'head -5 docs/smart-memory/agents/dev/*.md')" "(b) head com glob numa área → bloqueia"
expect 2 $H "$(sm_bash 'cat docs/smart-memory/agents/dev/backend')" "(b) diretório como alvo de leitor → bloqueia"
expect 2 $H "$(sm_bash "find docs/smart-memory -name '*.md' -exec cat {} \;")" "(b) find -exec cat → bloqueia"
expect 2 $H "$(sm_bash "find docs/smart-memory -type f | xargs cat")" "(b) find | xargs cat → bloqueia"
expect 2 $H "$(sm_bash 'grep -r "login" docs/smart-memory')" "(b) grep -r sem -l → bloqueia"
expect 2 $H "$(sm_bash 'grep -rn TODO docs/smart-memory/agents/')" "(b) grep -rn numa área → bloqueia"
expect 2 $H "$(sm_bash 'rg login docs/smart-memory')" "(b) rg sem -l → bloqueia"
expect 0 $H "$(sm_bash 'grep -rl "login" docs/smart-memory')" "(b) grep -rl (só nomes) → passa"
expect 0 $H "$(sm_bash 'grep -rc login docs/smart-memory/agents')" "(b) grep -rc (contagem) → passa"
expect 0 $H "$(sm_bash 'rg -l login docs/smart-memory')" "(b) rg -l → passa"
expect 0 $H "$(sm_bash 'grep -rn "docs/smart-memory" .claude/skills')" "(b) docs/smart-memory só como padrão de busca → passa"
expect 0 $H "$(sm_bash 'grep -n "status:" docs/smart-memory/stories/active/S1-login.md')" "(b) grep sem -r num arquivo → passa"
expect 0 $H "$(sm_bash "cat > docs/smart-memory/_inbox/dev-2026.md <<'EOF'
nota sobre docs/smart-memory/_archive/x e docs/smart-memory/*
EOF")" "escrever via heredoc (corpo cita _archive/) → passa"
expect 0 $H "$(sm_bash 'ls docs/smart-memory/agents')" "ls da smart-memory → passa"
# (c) orçamento L2 — L0 não conta
gsm_sid
for f in INDEX.md agents/dev/backend/DIGEST.md stories/active/S1-login.md _inbox/dev-2026.md project/overview.md stories/BACKLOG.md stories/done/LEDGER.md; do
  expect 0 $H "$(read_payload "docs/smart-memory/$f")" "(c) L0 não conta: $f"
done
expect 0 $H "$(read_payload "$SMD/agents/dev/backend/n1.md")" "(c) 1ª nota L2 → passa"
expect 0 $H "$(read_payload "docs/smart-memory/agents/dev/backend/n2.md")" "(c) 2ª nota L2 → passa"
expect 0 $H "$(sm_bash 'cat docs/smart-memory/agents/dev/backend/n3.md')" "(c) 3ª nota L2 (cat) → passa"
expect 0 $H "$(read_payload "./docs/smart-memory/agents/dev/backend/n1.md")" "(c) reler a 1ª (outro formato de path) não conta → passa"
expect 2 $H "$(read_payload "docs/smart-memory/agents/dev/backend/n4.md")" "(c) 4ª nota distinta → bloqueia (L0 lidos antes não contaram)"
expect 2 $H "$(sm_bash 'head -40 docs/smart-memory/agents/dev/backend/n5.md')" "(c) 5ª nota via head → bloqueia"
expect 0 $H "$(read_payload "docs/smart-memory/agents/dev/backend/n2.md")" "(c) reler nota já contada após estouro → passa"
expect 0 $H "$(sm_bash 'bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/sm-find.sh" pagamento')" "(c) sm-find.sh → passa e zera o contador"
expect 0 $H "$(read_payload "docs/smart-memory/agents/dev/backend/n4.md")" "(c) depois do sm-find, a 4ª nota passa"
gsm_sid
expect 0 $H "$(read_payload docs/smart-memory/decisions/d1.md "$GSM_SID")" "(c) sessão nova: contador próprio → passa"
for i in 1 2 3 4 5; do
  expect 0 $H "$(read_payload "docs/smart-memory/agents/dev/backend/x$i.md" -)" "(c) sem session_id não conta (leitura $i)"
done
expect 0 $H "$(read_payload "$REPO/README.md")" "Read fora da smart-memory → passa"
expect 0 $H "$(sm_bash 'cat README.md && head -3 src/app.ts')" "leitor fora da smart-memory → passa"
expect 0 $H "$(tool_payload Grep)" "outra ferramenta → passa"
expect 0 $H 'não é json' "JSON inválido → passa (fail-open)"

# ── 10c. guard-message-size.sh (PreToolUse SendMessage) ──────────────────────
section "guard-message-size.sh"
H=guard-message-size.sh
msg_payload() {  # <mensagem>  (JSON com \uXXXX para não-ASCII)
  python3 -c 'import json,sys; print(json.dumps({"session_id":"m1","hook_event_name":"PreToolUse","tool_name":"SendMessage","tool_input":{"to":"team-lead","summary":"s","message":sys.argv[1]}}))' "$1"
}
msg_payload_utf8() {  # <mensagem>  (JSON com UTF-8 cru)
  python3 -c 'import json,sys; print(json.dumps({"session_id":"m1","hook_event_name":"PreToolUse","tool_name":"SendMessage","tool_input":{"to":"team-lead","message":sys.argv[1]}}, ensure_ascii=False))' "$1"
}
mk_lines() {  # <n> [primeira linha]
  python3 -c 'import sys; n=int(sys.argv[1]); first=sys.argv[2] if len(sys.argv)>2 else "linha 1"; print("\n".join([first]+["linha %d" % i for i in range(2, n+1)]))' "$@"
}
mk_chars() { python3 -c 'import sys; print(sys.argv[2] * int(sys.argv[1]))' "$1" "$2"; }
expect 0 $H "$(msg_payload "$(mk_lines 20)")" "20 linhas → passa"
expect 2 $H "$(msg_payload "$(mk_lines 21)")" "21 linhas → bloqueia"
expect 0 $H "$(msg_payload "$(mk_chars 1500 a)")" "1500 caracteres → passa"
expect 2 $H "$(msg_payload "$(mk_chars 1501 a)")" "1501 caracteres → bloqueia"
expect 0 $H "$(msg_payload "$(mk_chars 1500 ç)")" "1500 'ç' (acento = 1 caractere) → passa"
expect 0 $H "$(msg_payload_utf8 "$(mk_chars 1500 ã)")" "1500 'ã' em UTF-8 cru → passa"
expect 2 $H "$(msg_payload "$(mk_chars 1501 é)")" "1501 'é' → bloqueia"
expect 0 $H "$(msg_payload "$(mk_lines 50 '[handoff] S1 pronto')")" "[handoff] com 50 linhas → passa"
expect 2 $H "$(msg_payload "$(mk_lines 61 '[handoff] S1 pronto')")" "[handoff] com 61 linhas → bloqueia"
expect 2 $H "$(msg_payload "[handoff] $(mk_chars 4001 x)")" "[handoff] com mais de 4000 caracteres → bloqueia"
expect 2 $H "$(msg_payload "$(mk_lines 30 'resumo') 
[handoff] no fim")" "[handoff] fora da 1ª linha não libera → bloqueia"
expect 0 $H '{"session_id":"m1","tool_name":"SendMessage","tool_input":{"to":"dev","message":{"type":"shutdown_request","reason":"fim"}}}' "JSON de protocolo (message objeto) → passa"
expect 0 $H '{"session_id":"m1","tool_name":"SendMessage","tool_input":{"to":"dev"}}' "sem message → passa"
expect 0 $H 'não é json' "JSON inválido → passa (fail-open)"
TEAM_OS_MSG_MAX_LINES=5 expect 2 $H "$(msg_payload "$(mk_lines 6)")" "TEAM_OS_MSG_MAX_LINES=5: 6 linhas → bloqueia"

# ── 11. Fallback sem python3 funcional (python3 falso que falha) ─────────────
section "fallback grep (python3 falhando → aviso em stderr + fallback)"
TESTPATH="$TMP/nopy:$PATH"
H=block-git-push.sh
expect_stderr_warning $H "$(bash_payload 'git push')" "python3 falhou → aviso ⚠️ em stderr (não silenciado)"
for c in \
  'git push' \
  'git push origin main' \
  'git -C "dir com espaço" push' \
  "git -C 'dir com espaço' push" \
  '\git push' \
  'GIT_DIR=.git git push' \
  '/usr/bin/git push' \
  'git "push"' \
  'command git push' \
  'env git push' \
  'git --git-dir=.git push' \
  'git status && git push' \
  'sh -c "git push"' \
  'eval "git push"' \
  'echo "git push" | sh' \
  'xargs git push' \
  'g=git; $g push' \
  'git ${X} push' \
  'git p$@ush' \
  'git -c alias.p=push p' \
  'git config alias.p push' \
  'git send-pack origin' \
  'git svn dcommit' \
  'gh pr create' \
  'gh pr merge 1' \
  'gh release create v1' \
  'gh repo sync' \
  'gh api -X POST repos/a/b/pulls -f title=x'
do
  expect 2 $H "$(bash_payload "$c")" "fallback bloqueia: $c"
done
expect 2 $H "$(bash_payload "$(printf 'git add .\ngit push')")" "fallback bloqueia: multilinha"
expect 2 $H "$(bash_payload "$(printf 'git \\\n  push')")" "fallback bloqueia: continuação de linha (git \\ push)"
for c in \
  'git status' \
  'git commit -m "push"' \
  'echo "push"' \
  'git stash push -m wip' \
  'gh pr list' \
  'bash -c "git status"' \
  'git -C "dir com espaço" status'
do
  expect 0 $H "$(bash_payload "$c")" "fallback passa: $c"
done

H=block-worktree.sh
expect_stderr_warning $H "$(bash_payload 'git status')" "python3 falhou → aviso ⚠️ em stderr"
for c in \
  'git worktree add ../x' \
  'git -C /p worktree add ../x' \
  'git checkout -b feat' \
  'git checkout -t origin/feat' \
  'git switch -c feat' \
  'git switch --track origin/feat' \
  'git branch feat' \
  'git branch -f feat' \
  'git stash branch feat' \
  'git update-ref refs/heads/feat HEAD' \
  'git symbolic-ref HEAD refs/heads/feat' \
  'git push origin HEAD:refs/heads/feat' \
  'git config alias.wt "worktree add"' \
  'sh -c "git worktree add ../x"' \
  'eval "git checkout -b feat"' \
  'g=git; $g worktree add ../x' \
  'git w$Xorktree add ../x'
do
  expect 2 $H "$(bash_payload "$c")" "fallback bloqueia: $c"
done
expect 2 $H "$(bash_payload "$(printf 'git fetch\ngit checkout -b feat')")" "fallback bloqueia: multilinha (checkout -b)"
expect 2 $H "$(agent_payload worktree)" "fallback bloqueia: Agent isolation worktree"
expect 2 $H "$(tool_payload EnterWorktree)" "fallback bloqueia: EnterWorktree"
for c in \
  'git branch' \
  'git branch -a' \
  'git branch --show-current' \
  'git branch -m old new' \
  'git branch -M main' \
  'git branch --set-upstream-to=origin/main' \
  'git branch -u origin/main' \
  'git branch --unset-upstream' \
  'git branch --edit-description' \
  'git branch -d feat' \
  'git branch -l "feat*"' \
  'git checkout main' \
  'git switch main' \
  'git stash push -m wip' \
  'git push origin HEAD:refs/heads/main' \
  'git symbolic-ref --short HEAD' \
  'git status'
do
  expect 0 $H "$(bash_payload "$c")" "fallback passa: $c"
done

H=guard-push-branch.sh
expect_stderr_warning $H "$(bash_payload 'git push' "$REPO")" "python3 falhou → aviso ⚠️ em stderr"
expect 0 $H "$(bash_payload 'git push' "$REPO")" "fallback main: git push → passa"
expect 0 $H "$(bash_payload 'git push origin main' "$REPO")" "fallback main: git push origin main → passa"
expect 2 $H "$(bash_payload 'git push origin feature' "$REPO")" "fallback main: git push origin feature → bloqueia"
expect 2 $H "$(bash_payload 'git push' "$REPO_FEATURE")" "fallback feature: git push → bloqueia"
expect 2 $H "$(bash_payload 'git push' "$REPO_DETACHED")" "fallback detached → bloqueia"
expect 2 $H "$(bash_payload "git -C \"$REPO_FEATURE\" push" "$REPO")" "fallback -C repo-feature (com aspas) → bloqueia"
expect 0 $H "$(bash_payload "git -C \"$REPO\" push" "$REPO_FEATURE")" "fallback -C repo-main (com aspas) → passa"
expect 2 $H "$(bash_payload 'sh -c "git push"' "$REPO_FEATURE")" "fallback feature: sh -c \"git push\" → bloqueia"
expect 0 $H "$(bash_payload 'git status' "$REPO_FEATURE")" "fallback sem push → passa"

H=task-quality.sh
expect_stderr_warning $H "$(task_payload TaskCreated "fix" "x")" "python3 falhou → aviso ⚠️ em stderr"
expect 2 $H "$(task_payload TaskCreated "fix" "x")" "fallback: task_subject curto → bloqueia"
expect 0 $H "$(task_payload TaskCreated "Corrigir paginação da listagem" "x")" "fallback: task_subject ok → passa"

H=guard-smart-memory-read.sh
gsm_sid
expect_stderr_warning $H "$(read_payload docs/smart-memory/_archive/a.md)" "python3 falhou → aviso ⚠️ em stderr"
expect 2 $H "$(read_payload "$SMD/_archive/2026-Q3/velha.md")" "fallback: Read _archive/ → bloqueia"
expect 2 $H "$(sm_bash 'cat docs/smart-memory/_archive/LEDGER.md')" "fallback: cat _archive/ → bloqueia"
expect 2 $H "$(sm_bash 'cat docs/smart-memory/*')" "fallback: cat com glob → bloqueia"
expect 2 $H "$(sm_bash "find docs/smart-memory -name '*.md' -exec cat {} +")" "fallback: find -exec cat → bloqueia"
expect 2 $H "$(sm_bash 'grep -r login docs/smart-memory')" "fallback: grep -r sem -l → bloqueia"
expect 0 $H "$(sm_bash 'grep -rl login docs/smart-memory')" "fallback: grep -rl → passa"
expect 0 $H "$(read_payload docs/smart-memory/INDEX.md)" "fallback: L0 (INDEX) → passa"
for i in 1 2 3; do expect 0 $H "$(read_payload "docs/smart-memory/agents/dev/backend/f$i.md")" "fallback: nota L2 $i → passa"; done
expect 2 $H "$(read_payload docs/smart-memory/agents/dev/backend/f4.md)" "fallback: 4ª nota L2 → bloqueia"
expect 0 $H "$(sm_bash 'bash .claude/skills/team-os/scripts/sm-find.sh x')" "fallback: sm-find zera o contador"
expect 0 $H "$(read_payload docs/smart-memory/agents/dev/backend/f4.md)" "fallback: 4ª nota após sm-find → passa"

H=guard-message-size.sh
expect_stderr_warning $H "$(msg_payload "$(mk_lines 3)")" "python3 falhou → aviso ⚠️ em stderr"
expect 0 $H "$(msg_payload "$(mk_lines 20)")" "fallback: 20 linhas → passa"
expect 2 $H "$(msg_payload "$(mk_lines 21)")" "fallback: 21 linhas → bloqueia"
expect 0 $H "$(msg_payload "$(mk_chars 1500 ç)")" "fallback: 1500 'ç' (\\u escapado) → passa"
expect 0 $H "$(msg_payload_utf8 "$(mk_chars 1500 ã)")" "fallback: 1500 'ã' UTF-8 cru → passa"
expect 2 $H "$(msg_payload "$(mk_chars 1501 a)")" "fallback: 1501 caracteres → bloqueia"
expect 0 $H "$(msg_payload "$(mk_lines 50 '[handoff] pronto')")" "fallback: [handoff] 50 linhas → passa"
expect 2 $H "$(msg_payload "$(mk_lines 61 '[handoff] pronto')")" "fallback: [handoff] 61 linhas → bloqueia"
expect 0 $H '{"tool_name":"SendMessage","tool_input":{"to":"dev","message":{"type":"shutdown_request"}}}' "fallback: JSON de protocolo → passa"
TESTPATH="$PATH"

# ── Resumo ───────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "Resultado: $PASSED/$TOTAL PASS ($FAILED FAIL)"
echo "════════════════════════════════════════"
[ "$FAILED" -eq 0 ] || exit 1
exit 0
