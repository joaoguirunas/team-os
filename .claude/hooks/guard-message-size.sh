#!/usr/bin/env bash
# .claude/hooks/guard-message-size.sh
# PreToolUse hook (matcher "SendMessage") — garantia dura de "mensagem curta entre agentes".
# Registrado no .claude/settings.json pelo ensure-settings.sh.
#
# BLOQUEIA (exit 2 + motivo em stderr) quando `tool_input.message` é string e passa de
#   TEAM_OS_MSG_MAX_LINES linhas (default 20) OU TEAM_OS_MSG_MAX_CHARS caracteres (default 1500).
#   Caracteres Unicode são contados como 1 (não bytes): "ação" = 4.
#
# PASSAM:
#   • `message` que não é string (objeto JSON de protocolo: shutdown_request, plan_approval…);
#   • mensagem cuja PRIMEIRA linha começa com `[handoff]` (resultado final de teammate ao lead)
#     até TEAM_OS_HANDOFF_MAX_LINES linhas (default 60) / TEAM_OS_HANDOFF_MAX_CHARS (default 4000);
#   • JSON inválido ou sem tool_input → exit 0 (fail-open, nunca quebra o fluxo).
#
# Regra: resumo primeiro; o detalhe vai num arquivo da smart-memory e a mensagem leva o path.
# bash 3.2-safe. python3 no caminho principal; fallback com wc/sed se o python3 faltar/falhar
# (aviso ⚠️ em stderr; no fallback a contagem de caracteres usa `wc -m` com locale UTF-8).

INPUT=$(cat)

num_or() { case "$1" in ''|*[!0-9]*) echo "$2" ;; *) echo "$1" ;; esac; }
MAX_LINES=$(num_or "${TEAM_OS_MSG_MAX_LINES:-}" 20)
MAX_CHARS=$(num_or "${TEAM_OS_MSG_MAX_CHARS:-}" 1500)
HO_LINES=$(num_or "${TEAM_OS_HANDOFF_MAX_LINES:-}" 60)
HO_CHARS=$(num_or "${TEAM_OS_HANDOFF_MAX_CHARS:-}" 4000)

block() {  # <linhas> <chars> <limite linhas> <limite chars> <handoff 0|1>
  echo "🚫 BLOQUEADO: mensagem longa demais — resumo primeiro (≤${3} linhas); detalhe vai em arquivo na smart-memory e a mensagem leva o path." >&2
  echo "" >&2
  echo "Tamanho: $1 linhas · $2 caracteres (limite: $3 linhas · $4 caracteres)." >&2
  echo "" >&2
  echo "Como fazer:" >&2
  echo "  1. Escreva o detalhe num arquivo (ex.: docs/smart-memory/_inbox/<agente>-<assunto>.md)." >&2
  echo "  2. Mande 3–10 linhas: o que mudou, decisão pedida, path do arquivo." >&2
  if [ "$5" = "0" ]; then
    echo "  Resultado final de teammate ao lead? Comece a 1ª linha com [handoff] (até ${HO_LINES} linhas / ${HO_CHARS} caracteres)." >&2
  fi
  exit 2
}

# ── Caminho principal: python3 ───────────────────────────────────────────────
if command -v python3 >/dev/null 2>&1; then
  OUT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print("OK"); sys.exit(0)
ti = d.get("tool_input") if isinstance(d, dict) else None
msg = ti.get("message") if isinstance(ti, dict) else None
if not isinstance(msg, str):
    print("OK"); sys.exit(0)
body = msg.rstrip("\n")
lines = body.count("\n") + 1 if body else 0
chars = len(msg)
first = body.split("\n", 1)[0].lstrip() if body else ""
ho = 1 if first.lower().startswith("[handoff]") else 0
print("MSG %d %d %d" % (lines, chars, ho))
' 2>&1)
  case "$OUT" in
    OK) exit 0 ;;
    "MSG "*)
      set -- $OUT
      L="$2"; C="$3"; HO="$4"
      if [ "$HO" = "1" ]; then LL="$HO_LINES"; LC="$HO_CHARS"; else LL="$MAX_LINES"; LC="$MAX_CHARS"; fi
      if [ "$L" -gt "$LL" ] || [ "$C" -gt "$LC" ]; then block "$L" "$C" "$LL" "$LC" "$HO"; fi
      exit 0 ;;
    *) echo "⚠️ guard-message-size.sh: python3 falhou (${OUT:-sem saída}) — usando fallback." >&2 ;;
  esac
fi

# ── Fallback sem python3 ─────────────────────────────────────────────────────
# Extrai "message":"..." (só string; objeto de protocolo não casa → passa).
RAW=$(printf '%s' "$INPUT" | tr -d '\n' \
  | grep -oE '"message"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 \
  | sed -E 's/^"message"[[:space:]]*:[[:space:]]*"//; s/"$//')
[ -n "$RAW" ] || exit 0
# \n do JSON → quebra real; \uXXXX e demais escapes simples viram 1 caractere
TXT=$(printf '%s' "$RAW" | sed -E 's/\\u[0-9a-fA-F]{4}/?/g' | sed 's/\\n/\
/g; s/\\t/ /g; s/\\"/"/g; s/\\\\/\\/g')
L=$(printf '%s\n' "$TXT" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | wc -l | tr -d ' ')
C=$(printf '%s' "$TXT" | LC_ALL=en_US.UTF-8 wc -m 2>/dev/null | tr -d ' ')
[ -n "$C" ] || C=$(printf '%s' "$TXT" | wc -c | tr -d ' ')
HO=0
case "$(printf '%s\n' "$TXT" | head -1 | sed 's/^[[:space:]]*//' | tr 'A-Z' 'a-z')" in "[handoff]"*) HO=1 ;; esac
if [ "$HO" = "1" ]; then LL="$HO_LINES"; LC="$HO_CHARS"; else LL="$MAX_LINES"; LC="$MAX_CHARS"; fi
if [ "${L:-0}" -gt "$LL" ] || [ "${C:-0}" -gt "$LC" ]; then block "$L" "$C" "$LL" "$LC" "$HO"; fi
exit 0
