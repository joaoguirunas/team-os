#!/usr/bin/env bash
# .claude/hooks/guard-push-branch.sh
# PreToolUse hook (Bash) para agentes devops — push permitido só na main/master
# por padrão. Push fora da main exige pedido explícito do usuário.
#
# - Detecta `git push` com a mesma normalização robusta do block-git-push.sh
#   (tokenização com shlex, flags globais entre git e push, encadeamentos).
# - Se o comando contém push e a branch atual NÃO é main/master → exit 2.
# - Push na main/master → exit 0 (devops não tem block-git-push).
# - Comandos sem push, JSON malformado ou branch indeterminável → exit 0.

INPUT=$(cat)

block_branch() {
  {
    echo "🚫 Push permitido só na main por padrão. Branch atual: $1."
    echo "Push fora da main exige pedido explícito do usuário — confirme com ele antes."
  } >&2
  exit 2
}

# ── Detecção de git push (python3 — tokenização real) ────────────────────────
IS_PUSH=""
if command -v python3 >/dev/null 2>&1; then
  IS_PUSH=$(printf '%s' "$INPUT" | python3 -c '
import sys, json, re, shlex

try:
    data = json.load(sys.stdin)
except Exception:
    print("NOPARSE"); sys.exit(0)

ti = data.get("tool_input", {}) or {}
cmd = ti.get("command", "") or data.get("command", "") or ""
# Normaliza ANTES do match: newlines e espacos multiplos viram espaco unico.
cmd = re.sub(r"\s+", " ", cmd).strip()
if not cmd:
    print("NO"); sys.exit(0)

GIT_VALUE_FLAGS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix"}

def toks_of(seg):
    try:
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

for seg in re.split(r"[;&|]+|\$\(|\)|`", cmd):
    toks = toks_of(seg)
    i = 0
    while i < len(toks) and (re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", toks[i])
                            or toks[i] in ("command", "env", "nohup", "time", "exec")):
        i += 1
    if i >= len(toks):
        continue
    prog = toks[i].rsplit("/", 1)[-1]
    rest = toks[i + 1:]
    if prog != "git":
        continue
    j = 0
    while j < len(rest) and rest[j].startswith("-"):
        flag = rest[j]
        base = flag.split("=", 1)[0]
        j += 1
        if base in GIT_VALUE_FLAGS and "=" not in flag and j < len(rest):
            j += 1
    if j < len(rest) and rest[j] == "push":
        print("YES"); sys.exit(0)

print("NO")
' 2>/dev/null)
fi

if [ "$IS_PUSH" != "YES" ] && [ "$IS_PUSH" != "NO" ]; then
  # Fallback sem python3 (ou NOPARSE): grep sobre comando normalizado
  COMMAND=$(printf '%s' "$INPUT" \
    | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
    | head -1 \
    | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\n/ /g; s/\\t/ /g')
  NORM=$(printf '%s' "$COMMAND" | tr '\n\t' '  ' | sed -E 's/[[:space:]]+/ /g')
  GIT_PREFIX='(^|[;&|`]|\$\()[[:space:]]*(env |command )*git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?)*'
  if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+push\b"; then
    IS_PUSH="YES"
  else
    IS_PUSH="NO"
  fi
fi

[ "$IS_PUSH" = "YES" ] || exit 0

# ── Comando contém git push: verificar a branch atual do projeto ─────────────
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  PROJECT_DIR=$(printf '%s' "$INPUT" \
    | grep -oE '"cwd"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
    | head -1 | sed -E 's/^"cwd"[[:space:]]*:[[:space:]]*"//; s/"$//')
fi
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  PROJECT_DIR=$(pwd)
fi

BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
# Sem git ou branch indeterminável (detached HEAD, repo ausente) → não bloquear
[ -n "$BRANCH" ] || exit 0

case "$BRANCH" in
  main|master) exit 0 ;;
  *) block_branch "$BRANCH" ;;
esac
