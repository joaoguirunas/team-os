#!/usr/bin/env bash
# .claude/hooks/context-watch.sh
# UserPromptSubmit hook — avisa quando o contexto da sessão ficou grande demais.
# Registrado no .claude/settings.json pelo ensure-settings.sh.
#
# Por quê: a cada turno o Claude relê TODO o histórico (cache_read). Uma sessão com 500k de
# contexto gasta 5× mais por turno do que uma com 100k — e é onde a maior parte dos tokens vai.
#
# Lê a última resposta do transcript (tail), soma input + cache_creation + cache_read e, se passar do
# limite, injeta 2 linhas de contexto para o Claude AVISAR o usuário e propor compactar / sessão nova.
#   TEAM_OS_CTX_WARN  (default 200000) — 1º aviso      TEAM_OS_CTX_HIGH (default 400000) — aviso forte
#   TEAM_OS_CTX_WATCH=0 desliga.
# Anti-spam: avisa de novo só quando sobe de nível ou cresce ≥100k desde o último aviso (estado em $TMPDIR).
#
# NUNCA bloqueia (sempre exit 0) e é fail-open: JSON inválido, sem transcript ou sem python3 → silêncio.
# bash 3.2-safe.

[ "${TEAM_OS_CTX_WATCH:-1}" = "0" ] && exit 0
command -v python3 >/dev/null 2>&1 || exit 0

INPUT=$(cat)
num_or() { case "$1" in ''|*[!0-9]*) echo "$2" ;; *) echo "$1" ;; esac; }
WARN=$(num_or "${TEAM_OS_CTX_WARN:-}" 200000)
HIGH=$(num_or "${TEAM_OS_CTX_HIGH:-}" 400000)
STATE_DIR="${TMPDIR:-/tmp}"

printf '%s' "$INPUT" | CW_WARN="$WARN" CW_HIGH="$HIGH" CW_STATE="$STATE_DIR" python3 -c '
import json, os, sys

try:
    d = json.load(sys.stdin)
    path = d.get("transcript_path") or ""
    sid = str(d.get("session_id") or "x")
    warn, high = int(os.environ["CW_WARN"]), int(os.environ["CW_HIGH"])
    size = os.path.getsize(path)
    with open(path, "rb") as f:
        f.seek(max(0, size - 400_000))
        data = f.read().decode("utf-8", errors="replace")
except Exception:
    sys.exit(0)

ctx = 0
for line in reversed(data.splitlines()):
    if "\"usage\"" not in line:
        continue
    try:
        m = json.loads(line)
    except Exception:
        continue
    u = (m.get("message") or {}).get("usage")
    if m.get("type") == "assistant" and isinstance(u, dict):
        ctx = int(u.get("input_tokens") or 0) + int(u.get("cache_read_input_tokens") or 0) + int(u.get("cache_creation_input_tokens") or 0)
        break
if ctx < warn:
    sys.exit(0)

level = 2 if ctx >= high else 1
state = os.path.join(os.environ["CW_STATE"], "team-os-context-watch-" + "".join(c for c in sid if c.isalnum() or c in "-_")[:60])
last_level, last_ctx = 0, 0
try:
    a, b = open(state).read().split()
    last_level, last_ctx = int(a), int(b)
except Exception:
    pass
if level <= last_level and ctx - last_ctx < 100_000:
    sys.exit(0)
try:
    open(state, "w").write("%d %d" % (level, ctx))
except Exception:
    pass

k = ctx // 1000
if level == 2:
    msg = ("⚠️ CONTEXTO ENORME (%dk tokens): cada turno desta sessão relê tudo isso e o consumo dispara. "
           "Antes de seguir, diga ao usuário em 1 linha e proponha: registrar o estado no ledger/DIGEST e rodar /compact, "
           "ou fechar a rodada e abrir uma sessão nova." % k)
else:
    msg = ("⚠️ Contexto grande (%dk tokens). Ao terminar a tarefa atual, avise o usuário em 1 linha e sugira compactar (/compact) "
           "ou abrir sessão nova depois de registrar o estado no ledger/DIGEST." % k)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": msg}}, ensure_ascii=False))
' 2>/dev/null
exit 0
