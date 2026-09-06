#!/bin/bash
# ensure-settings.sh — team-os
# Garante as chaves mínimas de Agent Teams no .claude/settings.json do PROJETO.
# Idempotente: SÓ ADICIONA o que falta — nunca duplica, nunca remove, nunca
# sobrescreve valor existente (divergência vira aviso). Sempre valida o JSON final.
#
# Garante:
#   env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
#   worktree.bgIsolation = "none"
#   subagentPromptCacheTtl = "1h"
#   hooks.PreToolUse  → block-worktree.sh (matchers "Agent|Task|EnterWorktree" e "Bash")
#   hooks.TaskCreated → task-quality.sh (rejeita task vaga)
#   hooks.TaskCompleted → check-story-progress.sh (story só fecha com evidência)
#
# Uso:
#   bash ensure-settings.sh                     # aplica em $CLAUDE_PROJECT_DIR (ou cwd)
#   bash ensure-settings.sh --dry-run           # mostra o merge sem gravar nada
#   bash ensure-settings.sh --project-dir <p>   # projeto explícito (combinável com --dry-run)
#
# Compatível com bash 3.2 (macOS). Requer python3 para o merge de JSON.
set -eu

DRY_RUN=0
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --project-dir)
      shift
      [ $# -gt 0 ] || { echo "⛔ --project-dir requer um path" >&2; exit 1; }
      PROJECT_DIR="$1"
      ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "⛔ argumento desconhecido: $1 (use --dry-run | --project-dir <p>)" >&2; exit 1 ;;
  esac
  shift
done

[ -d "$PROJECT_DIR" ] || { echo "⛔ projeto não encontrado: $PROJECT_DIR" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "⛔ python3 é necessário para o merge de JSON" >&2; exit 1; }

SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"

# Avisa (sem bloquear) hooks referenciados que ainda não existem no projeto.
for h in block-worktree.sh task-quality.sh check-story-progress.sh; do
  if [ ! -f "$PROJECT_DIR/.claude/hooks/$h" ]; then
    echo "⚠ hook ausente no projeto: .claude/hooks/$h — rode /team-os-creator *propagate no CT" >&2
  fi
done

ES_DRY_RUN="$DRY_RUN" ES_SETTINGS_FILE="$SETTINGS_FILE" python3 <<'PYEOF'
import copy, json, os, sys

path = os.environ["ES_SETTINGS_FILE"]
dry = os.environ.get("ES_DRY_RUN") == "1"

# --- carregar (ou começar do zero), sem tolerar JSON quebrado ---
existed = os.path.exists(path)
settings = {}
if existed:
    with open(path, "r") as f:
        raw = f.read().strip()
    if raw:
        try:
            settings = json.loads(raw)
        except json.JSONDecodeError as e:
            sys.exit(f"⛔ {path} não é JSON válido ({e}) — corrija antes de rodar o ensure-settings")
    if not isinstance(settings, dict):
        sys.exit(f"⛔ {path}: o topo do JSON não é um objeto")

before = copy.deepcopy(settings)
changes, warnings = [], []

def ensure_object(container, key, label):
    """Garante que container[key] é um dict; recusa a mexer se for outro tipo."""
    if key not in container:
        container[key] = {}
        return container[key]
    if not isinstance(container[key], dict):
        warnings.append(f"~ {label} existe mas não é objeto — deixado intacto (corrija manualmente)")
        return None
    return container[key]

def ensure_scalar(container, key, value, label):
    """Adiciona se falta; se existe com outro valor, NÃO sobrescreve (só avisa)."""
    if container is None:
        return
    if key not in container:
        container[key] = value
        changes.append(f"+ {label} = {json.dumps(value)}")
    elif container[key] != value:
        warnings.append(
            f"~ {label} já existe com valor {json.dumps(container[key])} "
            f"(mantido; o team-os espera {json.dumps(value)})"
        )

# --- chaves escalares ---
env = ensure_object(settings, "env", "env")
ensure_scalar(env, "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1", "env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS")

wt = ensure_object(settings, "worktree", "worktree")
ensure_scalar(wt, "bgIsolation", "none", "worktree.bgIsolation")

ensure_scalar(settings, "subagentPromptCacheTtl", "1h", "subagentPromptCacheTtl")

# --- hooks ---
hooks = ensure_object(settings, "hooks", "hooks")

def hook_present(event, script_name, matcher=None):
    """True se algum registro do evento (opcionalmente com o matcher dado) já chama o script."""
    if hooks is None:
        return True  # hooks corrompido: não mexer
    entries = hooks.get(event)
    if not isinstance(entries, list):
        return False
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        if matcher is not None and entry.get("matcher") != matcher:
            continue
        for h in entry.get("hooks", []) or []:
            if isinstance(h, dict) and script_name in str(h.get("command", "")):
                return True
    return False

def ensure_hook(event, matcher, script_name, match_on_matcher):
    """Adiciona o registro só se o script ainda não está registrado no evento."""
    if hooks is None:
        return
    if hook_present(event, script_name, matcher if match_on_matcher else None):
        return
    entries = hooks.get(event)
    if entries is None:
        entries = []
        hooks[event] = entries
    if not isinstance(entries, list):
        warnings.append(f"~ hooks.{event} existe mas não é lista — deixado intacto (corrija manualmente)")
        return
    command = f"$CLAUDE_PROJECT_DIR/.claude/hooks/{script_name}"
    entries.append({"matcher": matcher, "hooks": [{"type": "command", "command": command}]})
    label = matcher if matcher else "(sem matcher)"
    changes.append(f"+ hooks.{event} [{label}] → {script_name}")

# PreToolUse: o mesmo script em dois matchers distintos → deduplicar POR matcher.
ensure_hook("PreToolUse", "Agent|Task|EnterWorktree", "block-worktree.sh", match_on_matcher=True)
ensure_hook("PreToolUse", "Bash", "block-worktree.sh", match_on_matcher=True)
# Eventos de task: basta o script estar registrado no evento (qualquer matcher).
ensure_hook("TaskCreated", "", "task-quality.sh", match_on_matcher=False)
ensure_hook("TaskCompleted", "", "check-story-progress.sh", match_on_matcher=False)

# --- validação final (sempre) ---
final_text = json.dumps(settings, indent=2, ensure_ascii=False) + "\n"
json.loads(final_text)  # se isto falhar, nada é gravado

# --- relatório ---
if changes:
    print(f"{'[dry-run] ' if dry else ''}mudanças em {path}:")
    for c in changes:
        print(f"  {c}")
else:
    print(f"✓ {path} já contém tudo — nada a adicionar")

for w in warnings:
    print(f"  {w}")

if dry:
    print("--- resultado do merge (NÃO gravado) ---")
    sys.stdout.write(final_text)
    sys.exit(0)

if changes or not existed:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(final_text)
    os.replace(tmp, path)
    print(f"✓ gravado: {path}")
PYEOF
