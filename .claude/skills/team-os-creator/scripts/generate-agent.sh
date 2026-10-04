#!/usr/bin/env bash
# generate-agent.sh — renderiza template de archetype com placeholders substituídos
# Usage: ./generate-agent.sh <archetype> <name> <persona> <role_title> <color> <description>
# Output: escreve .claude/agents/<name>.md
#
# Origem do agente:
#   - mantenedor (arquivo .team-os-maintainer na raiz): agente DO PACK — registre-o no
#     preset da squad (presets/<squad>.yaml), como sempre.
#   - qualquer outra pessoa: agente PRÓPRIO — o frontmatter ganha `origin: custom` e o
#     agente é registrado em presets/custom/custom.yaml (squad = prefixo do nome).
#     Essa pasta é sua: o *update nunca a toca.
#   - TEAM_OS_AGENT_ORIGIN=pack|custom força um dos dois.

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

# Raiz do CT = 3 pastas acima da skill (funciona também sem git, ex.: pack baixado em .zip)
ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"

ORIGIN="${TEAM_OS_AGENT_ORIGIN:-}"
if [ -z "$ORIGIN" ]; then
  if [ -f "$ROOT/.team-os-maintainer" ]; then ORIGIN="pack"; else ORIGIN="custom"; fi
fi
case "$ORIGIN" in pack|custom) ;; *) echo "❌ TEAM_OS_AGENT_ORIGIN inválido: $ORIGIN (use pack ou custom)" >&2; exit 1 ;; esac

# Proteger contra sobrescrita silenciosa
OUTPUT="$ROOT/.claude/agents/${NAME}.md"
if [ -f "$OUTPUT" ]; then
  echo "⚠️  $OUTPUT já existe. Não sobrescrito." >&2
  echo "   Remova manualmente ou renomeie se quiser regenerar." >&2
  exit 2
fi

# Squad = prefixo do nome (ex.: "finance-billing" → "finance") — usado em {SQUAD}
# (linha "Área na smart-memory" e paths docs/smart-memory/agents/<squad>/<área>/)
SQUAD="${NAME%%-*}"

# Se persona vazia, usa role_title como fallback
DISPLAY_NAME="${PERSONA:-$ROLE_TITLE}"

# Renderizar template — substituição LITERAL de placeholders via python3.
# (sed quebrava: "|" no valor conflita com o delimitador e "&"/"\" têm
# significado especial no replacement do sed. str.replace é literal.)
TPL="$TEMPLATE" OUT="$OUTPUT" V_ORIGIN="$ORIGIN" \
V_NAME="$NAME" V_PERSONA="$DISPLAY_NAME" V_ROLE_TITLE="$ROLE_TITLE" \
V_COLOR="$COLOR" V_DESCRIPTION="$DESCRIPTION" V_SQUAD="$SQUAD" \
python3 - <<'PYEOF'
import os, re

with open(os.environ["TPL"], encoding="utf-8") as f:
    text = f.read()

for placeholder, env in (
    ("{NAME}", "V_NAME"),
    ("{PERSONA}", "V_PERSONA"),
    ("{ROLE_TITLE}", "V_ROLE_TITLE"),
    ("{COLOR}", "V_COLOR"),
    ("{DESCRIPTION}", "V_DESCRIPTION"),
    ("{SQUAD}", "V_SQUAD"),
):
    text = text.replace(placeholder, os.environ.get(env, ""))

# Agente próprio: `origin: custom` logo após `memory: project` (só no frontmatter)
if os.environ.get("V_ORIGIN") == "custom":
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if m and not re.search(r"^origin:", m.group(1), re.M):
        fm = m.group(1)
        if re.search(r"^memory:.*$", fm, re.M):
            fm = re.sub(r"^(memory:.*)$", r"\1\norigin: custom", fm, count=1, flags=re.M)
        else:
            fm += "\norigin: custom"
        text = "---\n" + fm + "\n---" + text[m.end():]

with open(os.environ["OUT"], "w", encoding="utf-8") as f:
    f.write(text)
PYEOF

echo "✅ Gerado: $OUTPUT"

# Agente próprio: registrar em presets/custom/custom.yaml (pasta do usuário, nunca tocada pelo *update)
if [ "$ORIGIN" = "custom" ]; then
  CUSTOM_YAML="$SKILL_DIR/presets/custom/custom.yaml"
  mkdir -p "$SKILL_DIR/presets/custom"
  Y="$CUSTOM_YAML" V_NAME="$NAME" V_ARCH="$ARCHETYPE" V_PERSONA="$DISPLAY_NAME" \
  V_ROLE_TITLE="$ROLE_TITLE" V_COLOR="$COLOR" V_DESCRIPTION="$DESCRIPTION" \
  python3 - <<'PYEOF'
import json, os, re
y = os.environ["Y"]
name = os.environ["V_NAME"]
if not os.path.isfile(y):
    with open(y, "w", encoding="utf-8") as f:
        f.write("name: custom\n"
                "description: \"Agentes próprios (origin: custom). Esta pasta é sua — o *update do team-os nunca a toca.\"\n"
                "agents:\n")
text = open(y, encoding="utf-8").read()
if re.search(r"^  - name:\s*" + re.escape(name) + r"\s*$", text, re.M):
    print(f"ℹ️  {name} já estava registrado em presets/custom/custom.yaml")
else:
    persona = os.environ.get("V_PERSONA", "")
    if not re.fullmatch(r"[A-Za-z0-9À-ÿ+._-]+", persona or "x"):
        persona = json.dumps(persona, ensure_ascii=False)
    entry = (f"  - name: {name}\n"
             f"    archetype: {os.environ['V_ARCH']}\n"
             f"    persona: {persona}\n"
             f"    role_title: {json.dumps(os.environ.get('V_ROLE_TITLE', ''), ensure_ascii=False)}\n"
             f"    color: {os.environ.get('V_COLOR', '')}\n"
             f"    description: {json.dumps(os.environ.get('V_DESCRIPTION', ''), ensure_ascii=False)}\n")
    if not text.endswith("\n"):
        text += "\n"
    with open(y, "w", encoding="utf-8") as f:
        f.write(text + entry)
    print(f"✅ Registrado como agente próprio em presets/custom/custom.yaml")
PYEOF
fi

# Validar o agente gerado e propagar o exit code do audit
HERE="$(cd "$(dirname "$0")" && pwd)"
if [ -x "$HERE/validate-agent.sh" ] || [ -f "$HERE/validate-agent.sh" ]; then
  # set -e está ativo: capturar exit code sem abortar
  set +e
  (cd "$ROOT" && bash "$HERE/validate-agent.sh" "$NAME")
  VALIDATE_EXIT=$?
  set -e
  if [ "$VALIDATE_EXIT" -ne 0 ]; then
    echo "❌ validate-agent.sh falhou (exit $VALIDATE_EXIT) para $NAME" >&2
  fi
  exit "$VALIDATE_EXIT"
else
  echo "⚠️  validate-agent.sh não encontrado em $HERE — validação pulada" >&2
fi
