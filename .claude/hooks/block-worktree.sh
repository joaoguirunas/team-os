#!/usr/bin/env bash
# .claude/hooks/block-worktree.sh
# PreToolUse hook — garantia dura: nenhum trabalho em git worktree neste projeto.
# Registrado no .claude/settings.json do projeto com dois matchers:
#   - "Agent|Task|EnterWorktree" → bloqueia spawn de agente com isolation: worktree
#     e qualquer uso da ferramenta EnterWorktree
#   - "Bash" → bloqueia "git worktree add"
#
# Racional: worktrees escondem o trabalho do checkout principal (onde o dev
# server roda), geram branches zumbis e quebram o fluxo local. Todo agente
# trabalha direto na branch ativa; conflito se resolve com ownership disjunto.
#
# Como funciona:
# - Recebe o JSON do Claude Code via stdin: {"tool_name":"...","tool_input":{...}}
# - exit 2 bloqueia a chamada e devolve a mensagem de stderr ao modelo
# - exit 0 deixa passar

INPUT=$(cat)

# Extrair tool_name e campos relevantes. Usa python3 quando disponível;
# cai para grep tolerante caso contrário (mesmo padrão do block-git-push.sh).
PARSED=$(printf '%s' "$INPUT" | python3 -c 'import sys, json
try:
    data = json.load(sys.stdin)
    ti = data.get("tool_input", {}) or {}
    print(data.get("tool_name", ""))
    print(ti.get("isolation", ""))
    print((ti.get("command", "") or "").replace("\n", " "))
except Exception:
    pass' 2>/dev/null)

TOOL_NAME=$(printf '%s\n' "$PARSED" | sed -n '1p')
ISOLATION=$(printf '%s\n' "$PARSED" | sed -n '2p')
COMMAND=$(printf '%s\n' "$PARSED" | sed -n '3p')

if [ -z "$TOOL_NAME" ]; then
  # Fallback sem python3
  TOOL_NAME=$(printf '%s' "$INPUT" \
    | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
    | sed -E 's/^"tool_name"[[:space:]]*:[[:space:]]*"//; s/"$//')
  ISOLATION=$(printf '%s' "$INPUT" \
    | grep -oE '"isolation"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
    | sed -E 's/^"isolation"[[:space:]]*:[[:space:]]*"//; s/"$//')
  COMMAND=$(printf '%s' "$INPUT" \
    | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 \
    | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')
fi

block() {
  echo "🚫 BLOQUEADO: worktrees são proibidos neste projeto." >&2
  echo "" >&2
  echo "Motivo: $1" >&2
  echo "" >&2
  echo "Todo trabalho acontece DIRETO na branch ativa do checkout principal." >&2
  echo "Se dois agentes podem conflitar no mesmo arquivo, use ownership disjunto" >&2
  echo "(paths exclusivos por agente) — nunca isolamento por worktree." >&2
  exit 2
}

# 1. Ferramenta EnterWorktree — bloquear sempre
if [ "$TOOL_NAME" = "EnterWorktree" ]; then
  block "tentativa de usar a ferramenta EnterWorktree."
fi

# 2. Spawn de agente com isolation: worktree
if [ "$ISOLATION" = "worktree" ]; then
  block "spawn de agente com isolation: \"worktree\". Spawne sem o campo isolation."
fi

# 3. Bash: git worktree add
if printf '%s' "$COMMAND" | grep -qE 'git[[:space:]]+worktree[[:space:]]+add'; then
  block "comando \"git worktree add\". Comando bloqueado: $COMMAND"
fi

exit 0
