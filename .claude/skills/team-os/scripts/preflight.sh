#!/usr/bin/env bash
# preflight.sh — verifica pré-condições antes de qualquer operação da skill team-os
# Exit 0: tudo ok
# Exit 1: erro bloqueante (mensagem em stderr, orientação ao usuário em stdout)

ERRORS=0

# Check 1: Agent Teams env var
if [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS}" != "1" ]; then
  echo "❌ Agent Teams não está ativo."
  echo ""
  echo "   Para ativar, adicione em .claude/settings.json (ou ~/.claude/settings.json):"
  echo ""
  echo '   {"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}'
  echo ""
  echo "   E recarregue a sessão do Claude Code."
  ERRORS=$((ERRORS + 1))
fi

# Check 2: Pelo menos um agente disponível
PROJECT_AGENTS=0
USER_AGENTS=0
if [ -d ".claude/agents" ]; then
  PROJECT_AGENTS=$(find .claude/agents -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
fi
if [ -d "$HOME/.claude/agents" ]; then
  USER_AGENTS=$(find "$HOME/.claude/agents" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
fi

TOTAL_AGENTS=$((PROJECT_AGENTS + USER_AGENTS))

if [ "$TOTAL_AGENTS" -eq 0 ]; then
  echo "❌ Nenhum agente encontrado."
  echo ""
  echo "   Crie pelo menos um agente em .claude/agents/ ou ~/.claude/agents/"
  echo "   antes de formar um time."
  ERRORS=$((ERRORS + 1))
fi

# Check 3: Diretório do projeto escrevível (para smart-memory)
if [ ! -w "." ]; then
  echo "❌ Diretório atual não é escrevível. Smart-memory não poderá ser criada."
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
  exit 1
fi

echo "✅ Preflight OK — ${TOTAL_AGENTS} agente(s) disponível(eis) (${PROJECT_AGENTS} projeto + ${USER_AGENTS} user)"
exit 0
