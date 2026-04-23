#!/usr/bin/env bash
# preflight.sh — pré-condições pra criar agentes
# Exit 0: ok (mostra status)
# Exit 1: bloqueante (mostra orientação)

ERRORS=0
WARNINGS=0

# Check 1: skills CLI disponível (pra instalar do skills.sh)
if ! command -v npx >/dev/null 2>&1; then
  echo "❌ npx não encontrado — necessário pra instalar skills do skills.sh."
  echo "   Instale Node.js (https://nodejs.org/)."
  ERRORS=$((ERRORS + 1))
fi

# Check 2: .claude/agents/ existe ou pode ser criada
if [ ! -d ".claude/agents" ]; then
  mkdir -p .claude/agents 2>/dev/null || {
    echo "❌ Não consegui criar .claude/agents/ — permissão?"
    ERRORS=$((ERRORS + 1))
  }
fi

# Check 3: .claude/skills/ existe ou pode ser criada
if [ ! -d ".claude/skills" ]; then
  mkdir -p .claude/skills 2>/dev/null || {
    echo "❌ Não consegui criar .claude/skills/ — permissão?"
    ERRORS=$((ERRORS + 1))
  }
fi

# Check 4: agentes existentes (warning, não erro)
EXISTING=0
if [ -d ".claude/agents" ]; then
  EXISTING=$(find .claude/agents -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
fi

if [ $ERRORS -gt 0 ]; then
  exit 1
fi

echo "STATUS=ok"
echo "EXISTING_AGENTS=$EXISTING"
if [ $EXISTING -gt 0 ]; then
  echo "EXISTING_LIST=$(find .claude/agents -maxdepth 1 -name "*.md" -type f -exec basename {} .md \; 2>/dev/null | sort | tr '\n' ',' | sed 's/,$//')"
fi

exit 0
