#!/usr/bin/env bash
# .claude/skills/team-os/scripts/tdah.sh
# Liga, desliga e mostra o modo TDAH do team-os (respostas curtas, ação primeiro, sem jargão).
#
#   bash tdah.sh on       → instala o hook global + cópia das regras, registra o SessionStart
#                           em ~/.claude/settings.json (idempotente) e liga o modo
#   bash tdah.sh off      → desliga (o hook continua registrado, mas não faz nada)
#   bash tdah.sh status   → TDAH=on|off + se o hook está registrado
#
# Vale para todos os projetos da pessoa (é uma preferência dela, não do projeto).
# Respeita CLAUDE_CONFIG_DIR (padrão ~/.claude). Nunca reescreve um settings.json inválido:
# nesse caso avisa com TDAH_REGISTER_TODO e não toca no arquivo.
# Saída KEY=valor. Exit 0 ok · 1 erro · 2 uso.

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
SKILL_DIR=$(cd "$HERE/.." && pwd)
PROJ_CLAUDE=$(cd "$SKILL_DIR/../.." && pwd)
SRC_HOOK="$PROJ_CLAUDE/hooks/team-os-tdah.sh"
SRC_RULES="$SKILL_DIR/reference/modo-tdah.md"

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
FLAG="$CFG/.team-os-tdah"
DST_HOOK="$CFG/hooks/team-os-tdah.sh"
DST_RULES="$CFG/hooks/team-os-tdah.md"
SETTINGS="$CFG/settings.json"
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
  HOOK_CMD="bash \"$DST_HOOK\""
else
  HOOK_CMD='bash "$HOME/.claude/hooks/team-os-tdah.sh"'
fi

registered() { [ -f "$SETTINGS" ] && grep -q "team-os-tdah.sh" "$SETTINGS" 2>/dev/null; }

register() {
  python3 - "$SETTINGS" "$HOOK_CMD" <<'PY'
import json, os, shutil, sys
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    try:
        with open(path, encoding="utf-8") as f:
            raw = f.read()
        data = json.loads(raw) if raw.strip() else {}
    except Exception:
        print("TDAH_REGISTER_TODO=1|settings.json inválido — não foi tocado; registre o SessionStart à mão")
        sys.exit(0)
    if not isinstance(data, dict):
        print("TDAH_REGISTER_TODO=1|settings.json não é um objeto — não foi tocado")
        sys.exit(0)
hooks = data.setdefault("hooks", {})
starts = hooks.setdefault("SessionStart", [])
for group in starts:
    for h in (group or {}).get("hooks", []):
        if "team-os-tdah.sh" in str(h.get("command", "")):
            print("TDAH_REGISTERED=already")
            sys.exit(0)
starts.append({"matcher": "", "hooks": [{"type": "command", "command": cmd}]})
if os.path.exists(path):
    shutil.copy2(path, path + ".bak-tdah")
os.makedirs(os.path.dirname(path), exist_ok=True)
tmp = path + ".tmp-tdah"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, path)
print("TDAH_REGISTERED=1")
PY
}

case "${1:-status}" in
  on)
    [ -f "$SRC_HOOK" ] || { echo "ERROR=hook_ausente|$SRC_HOOK"; exit 1; }
    [ -f "$SRC_RULES" ] || { echo "ERROR=regras_ausentes|$SRC_RULES"; exit 1; }
    command -v python3 >/dev/null 2>&1 || { echo "ERROR=python3_ausente"; exit 1; }
    mkdir -p "$CFG/hooks" || { echo "ERROR=sem_permissao|$CFG/hooks"; exit 1; }
    cp "$SRC_HOOK" "$DST_HOOK" && chmod +x "$DST_HOOK"
    cp "$SRC_RULES" "$DST_RULES"
    echo "TDAH_HOOK=installed"
    register
    : > "$FLAG"
    echo "TDAH=on"
    ;;
  off)
    rm -f "$FLAG"
    echo "TDAH=off"
    ;;
  status)
    if [ -f "$FLAG" ]; then echo "TDAH=on"; else echo "TDAH=off"; fi
    if registered; then echo "TDAH_REGISTERED=1"; else echo "TDAH_REGISTERED=0"; fi
    ;;
  *)
    echo "uso: tdah.sh on|off|status" >&2
    exit 2
    ;;
esac
exit 0
