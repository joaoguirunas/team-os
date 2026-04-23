#!/usr/bin/env bash
# generate-agent.sh — renderiza template de archetype com placeholders substituídos
# Usage: ./generate-agent.sh <archetype> <name> <persona> <role_title> <color> <description>
# Output: escreve .claude/agents/<name>.md

set -e

ARCHETYPE="$1"
NAME="$2"
PERSONA="$3"
ROLE_TITLE="$4"
COLOR="$5"
DESCRIPTION="$6"

if [ -z "$ARCHETYPE" ] || [ -z "$NAME" ] || [ -z "$ROLE_TITLE" ]; then
  echo "Usage: $0 <archetype> <name> <persona-or-empty> <role_title> <color> <description>" >&2
  exit 1
fi

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$SKILL_DIR/templates/${ARCHETYPE}.md"

if [ ! -f "$TEMPLATE" ]; then
  echo "❌ Template não encontrado: $TEMPLATE" >&2
  echo "   Archetypes válidos: $(ls $SKILL_DIR/templates/ | sed 's/\.md//' | tr '\n' ' ')" >&2
  exit 1
fi

# Proteger contra sobrescrita silenciosa
OUTPUT=".claude/agents/${NAME}.md"
if [ -f "$OUTPUT" ]; then
  echo "⚠️  $OUTPUT já existe. Não sobrescrito." >&2
  echo "   Remova manualmente ou renomeie se quiser regenerar." >&2
  exit 2
fi

# Se persona vazia, usa role_title como fallback
DISPLAY_NAME="${PERSONA:-$ROLE_TITLE}"

# Renderizar template — substituição de placeholders
# Usamos sed com separador alternativo pra evitar conflito com / nos valores
sed \
  -e "s|{NAME}|${NAME}|g" \
  -e "s|{PERSONA}|${DISPLAY_NAME}|g" \
  -e "s|{ROLE_TITLE}|${ROLE_TITLE}|g" \
  -e "s|{COLOR}|${COLOR}|g" \
  -e "s|{DESCRIPTION}|${DESCRIPTION}|g" \
  "$TEMPLATE" > "$OUTPUT"

echo "✅ Gerado: $OUTPUT"
