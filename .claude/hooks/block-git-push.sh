#!/usr/bin/env bash
# .claude/hooks/block-git-push.sh
# PreToolUse hook — bloqueia git push em agentes dev-dev-*
# Referenciado inline no frontmatter (campo `hooks:`) de cada dev-dev-*.
# O agente devops não tem esse hook no frontmatter, então push funciona normalmente para ele.
#
# Como funciona:
# - Recebe o JSON do Claude Code via stdin: {"tool_name":"Bash","tool_input":{"command":"..."}, ...}
# - Se o comando contém "git push", bloqueia com exit 2 e mensagem explicativa
# - Qualquer outro comando Bash passa normalmente com exit 0

INPUT=$(cat)

# Extrair command do JSON (tool_input.command).
# Parser tolerante: usa python3 quando disponível (lida com aspas escapadas,
# espaços em "command" : "...", quebras de linha). Cai para grep/sed tolerante
# a espaços caso python3 não exista no ambiente.
COMMAND=$(printf '%s' "$INPUT" | python3 -c 'import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get("tool_input", {}).get("command", "") or data.get("command", ""))
except Exception:
    pass' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  # Fallback sem python3: grep tolerante a espaços ao redor de ":" e remoção das aspas.
  COMMAND=$(printf '%s' "$INPUT" \
    | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
    | head -1 \
    | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')
fi

# Verificar se é um git push
if echo "$COMMAND" | grep -qE 'git[[:space:]]+push'; then
  echo "🚫 BLOQUEADO: git push não é permitido neste agente." >&2
  echo "" >&2
  echo "Apenas o agente devops tem autoridade para fazer push." >&2
  echo "Solicite ao lead que acione o agente devops para publicar esta branch." >&2
  echo "" >&2
  echo "Comando bloqueado: $COMMAND" >&2
  exit 2
fi

exit 0
