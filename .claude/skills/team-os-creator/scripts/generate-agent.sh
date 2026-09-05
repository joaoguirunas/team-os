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
  echo "   Archetypes válidos: $(ls "$SKILL_DIR/templates/" | sed 's/\.md//' | tr '\n' ' ')" >&2
  exit 1
fi

# Proteger contra sobrescrita silenciosa
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT="$ROOT/.claude/agents/${NAME}.md"
if [ -f "$OUTPUT" ]; then
  echo "⚠️  $OUTPUT já existe. Não sobrescrito." >&2
  echo "   Remova manualmente ou renomeie se quiser regenerar." >&2
  exit 2
fi

# Se persona vazia, usa role_title como fallback
DISPLAY_NAME="${PERSONA:-$ROLE_TITLE}"

# Renderizar template — substituição LITERAL de placeholders via python3.
# (sed quebrava: "|" no valor conflita com o delimitador e "&"/"\" têm
# significado especial no replacement do sed. str.replace é literal.)
TPL="$TEMPLATE" OUT="$OUTPUT" \
V_NAME="$NAME" V_PERSONA="$DISPLAY_NAME" V_ROLE_TITLE="$ROLE_TITLE" \
V_COLOR="$COLOR" V_DESCRIPTION="$DESCRIPTION" \
python3 - <<'PYEOF'
import os

with open(os.environ["TPL"], encoding="utf-8") as f:
    text = f.read()

for placeholder, env in (
    ("{NAME}", "V_NAME"),
    ("{PERSONA}", "V_PERSONA"),
    ("{ROLE_TITLE}", "V_ROLE_TITLE"),
    ("{COLOR}", "V_COLOR"),
    ("{DESCRIPTION}", "V_DESCRIPTION"),
):
    text = text.replace(placeholder, os.environ.get(env, ""))

with open(os.environ["OUT"], "w", encoding="utf-8") as f:
    f.write(text)
PYEOF

echo "✅ Gerado: $OUTPUT"

# Validar o agente gerado e propagar o exit code do audit
HERE="$(cd "$(dirname "$0")" && pwd)"
if [ -x "$HERE/validate-agent.sh" ] || [ -f "$HERE/validate-agent.sh" ]; then
  # set -e está ativo: capturar exit code sem abortar
  set +e
  bash "$HERE/validate-agent.sh" "$NAME"
  VALIDATE_EXIT=$?
  set -e
  if [ "$VALIDATE_EXIT" -ne 0 ]; then
    echo "❌ validate-agent.sh falhou (exit $VALIDATE_EXIT) para $NAME" >&2
  fi
  exit "$VALIDATE_EXIT"
else
  echo "⚠️  validate-agent.sh não encontrado em $HERE — validação pulada" >&2
fi
