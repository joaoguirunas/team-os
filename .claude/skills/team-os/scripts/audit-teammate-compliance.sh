#!/usr/bin/env bash
# audit-teammate-compliance.sh — verifica se todos os agentes seguem o contrato team-os
# Output: relatório com os non-conformers
# Exit 0: todos conformes
# Exit 1: pelo menos um não conforme

PROBLEMS=0
CHECKED=0

check_agent() {
  local file="$1"
  local name=$(basename "$file" .md)
  local issues=()

  # Check 1: Frontmatter tem memory: project (ou user, local)
  if ! grep -qE '^memory:[[:space:]]*(project|user|local)' "$file"; then
    issues+=("sem 'memory:' válido no frontmatter")
  fi

  # Check 2: Prompt tem seção "Contrato com team-os"
  if ! grep -q "Contrato com team-os" "$file"; then
    issues+=("sem seção 'Contrato com team-os' — rode *enroll")
  fi

  # Check 3: Menciona smart-memory
  if ! grep -qi "smart-memory" "$file"; then
    issues+=("não menciona smart-memory no prompt")
  fi

  # Check 4: Menciona SendMessage
  if ! grep -q "SendMessage" "$file"; then
    issues+=("não menciona SendMessage no prompt")
  fi

  if [ ${#issues[@]} -eq 0 ]; then
    return 0
  fi

  echo "  ❌ $name:"
  for issue in "${issues[@]}"; do
    echo "       - $issue"
  done
  PROBLEMS=$((PROBLEMS + 1))
  return 1
}

echo "🔍 Auditoria de conformidade dos teammates — $(date '+%Y-%m-%d %H:%M')"
echo ""

# Project scope
if [ -d ".claude/agents" ]; then
  for f in .claude/agents/*.md; do
    [ -f "$f" ] || continue
    CHECKED=$((CHECKED + 1))
    check_agent "$f"
  done
fi

# User scope (inclui no report, mas não duplica nomes)
SEEN=" "
if [ -d ".claude/agents" ]; then
  for f in .claude/agents/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .md)
    SEEN="$SEEN$name "
  done
fi
if [ -d "$HOME/.claude/agents" ]; then
  for f in "$HOME"/.claude/agents/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .md)
    case "$SEEN" in *" $name "*) continue ;; esac
    CHECKED=$((CHECKED + 1))
    check_agent "$f"
  done
fi

echo ""
if [ $PROBLEMS -eq 0 ]; then
  echo "✅ Todos $CHECKED agente(s) conforme(s)."
  exit 0
else
  echo "⚠️  $PROBLEMS de $CHECKED agente(s) não conforme(s)."
  echo "    Rode /team-os *enroll <agente> para corrigir automaticamente."
  exit 1
fi
