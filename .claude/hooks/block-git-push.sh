#!/usr/bin/env bash
# .claude/hooks/block-git-push.sh
# PreToolUse hook — bloqueia git push em agentes dev-dev-*
# Referenciado inline no frontmatter (campo `hooks:`) de cada dev-dev-*.
# Grav (dev-devops) não tem esse hook no frontmatter, então push funciona normalmente para ele.
#
# Como funciona:
# - Recebe o JSON do Claude Code via stdin: {"tool_name":"Bash","tool_input":{"command":"..."}, ...}
# - Se o comando contém "git push", bloqueia com exit 2 e mensagem explicativa
# - Qualquer outro comando Bash passa normalmente com exit 0

INPUT=$(cat)

# Extrair command do JSON (tool_input.command)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | sed 's/"command":"//;s/"$//')

# Verificar se é um git push
if echo "$COMMAND" | grep -qE 'git[[:space:]]+push'; then
  echo "🚫 BLOQUEADO: git push não é permitido neste agente." >&2
  echo "" >&2
  echo "Apenas Grav (dev-devops) tem autoridade para fazer push." >&2
  echo "Solicite ao Chief que acione Grav para publicar esta branch." >&2
  echo "" >&2
  echo "Comando bloqueado: $COMMAND" >&2
  exit 2
fi

exit 0
