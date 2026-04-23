#!/usr/bin/env bash
# validate-agent.sh — valida um agente criado (ou todos se sem args)
# Usage: ./validate-agent.sh [<name>]
# Exit 0: conforme
# Exit 1: um ou mais não conformes

PROBLEMS=0
CHECKED=0

validate() {
  local file="$1"
  local name=$(basename "$file" .md)
  local issues=()

  # Check 1: frontmatter presente e válido
  if ! head -1 "$file" | grep -q '^---$'; then
    issues+=("sem frontmatter no topo")
  fi

  # Check 2: name: no frontmatter bate com filename
  FM_NAME=$(awk '/^---$/{c++; if(c==2)exit} c==1 && /^name:/{sub("^name:[[:space:]]*",""); print; exit}' "$file")
  if [ "$FM_NAME" != "$name" ]; then
    issues+=("name:'$FM_NAME' não bate com arquivo '$name'")
  fi

  # Check 3: description: não vazia
  if ! awk '/^---$/{c++; if(c==2)exit} c==1' "$file" | grep -qE '^description:[[:space:]]+.+'; then
    issues+=("description: vazia ou ausente")
  fi

  # Check 4: memory: project/user/local
  if ! awk '/^---$/{c++; if(c==2)exit} c==1' "$file" | grep -qE '^memory:[[:space:]]*(project|user|local)'; then
    issues+=("memory: ausente ou inválido (use project/user/local)")
  fi

  # Check 5: model: definido
  if ! awk '/^---$/{c++; if(c==2)exit} c==1' "$file" | grep -qE '^model:[[:space:]]+'; then
    issues+=("model: ausente")
  fi

  # Check 6: tools: presente
  if ! awk '/^---$/{c++; if(c==2)exit} c==1' "$file" | grep -q '^tools:'; then
    issues+=("tools: ausente")
  fi

  # Check 7: Contrato com team-os presente
  if ! grep -q "Contrato com team-os" "$file"; then
    issues+=("sem seção 'Contrato com team-os'")
  fi

  # Check 8: menciona smart-memory
  if ! grep -qi "smart-memory" "$file"; then
    issues+=("não menciona smart-memory")
  fi

  # Check 9: menciona SendMessage
  if ! grep -q "SendMessage" "$file"; then
    issues+=("não menciona SendMessage")
  fi

  # Check 10: tem H1 (título principal)
  if ! grep -q "^# " "$file"; then
    issues+=("sem heading H1")
  fi

  if [ ${#issues[@]} -eq 0 ]; then
    echo "✅ $name"
    return 0
  fi

  echo "❌ $name:"
  for issue in "${issues[@]}"; do
    echo "    • $issue"
  done
  PROBLEMS=$((PROBLEMS + 1))
  return 1
}

if [ -n "$1" ]; then
  # Validar um específico
  FILE=".claude/agents/${1}.md"
  if [ ! -f "$FILE" ]; then
    echo "❌ Agente '$1' não encontrado em .claude/agents/" >&2
    exit 1
  fi
  CHECKED=1
  validate "$FILE"
else
  # Validar todos
  if [ ! -d ".claude/agents" ]; then
    echo "⛔ .claude/agents/ não existe"
    exit 1
  fi
  for f in .claude/agents/*.md; do
    [ -f "$f" ] || continue
    CHECKED=$((CHECKED + 1))
    validate "$f"
  done
fi

echo ""
if [ $PROBLEMS -eq 0 ]; then
  echo "✅ Todos $CHECKED agente(s) conforme(s)."
  exit 0
else
  echo "⚠️  $PROBLEMS de $CHECKED não conforme(s)."
  exit 1
fi
