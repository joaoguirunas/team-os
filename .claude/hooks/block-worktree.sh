#!/usr/bin/env bash
# .claude/hooks/block-worktree.sh
# PreToolUse hook — garantia dura: nenhum trabalho em git worktree neste projeto.
# Registrado no .claude/settings.json do projeto com dois matchers:
#   - "Agent|Task|EnterWorktree" → bloqueia spawn de agente com isolation: worktree
#     e qualquer uso da ferramenta EnterWorktree
#   - "Bash" → bloqueia "git worktree add", criação de branch (git checkout -b,
#     git switch -c/-C, git branch <nome>) e aliases que escondam worktree
#
# Racional: worktrees escondem o trabalho do checkout principal (onde o dev
# server roda), geram branches zumbis e quebram o fluxo local. Todo agente
# trabalha direto na branch ativa; conflito se resolve com ownership disjunto.
# Criação de branch é decisão do usuário — nunca de um agente.
#
# Como funciona:
# - Recebe o JSON do Claude Code via stdin: {"tool_name":"...","tool_input":{...}}
# - Comando Bash é normalizado (newlines/espaços múltiplos → espaço único) e
#   tokenizado (python3 + shlex): pega git com flags globais no meio
#   (`git -C <path> worktree add`, `git --git-dir=X checkout -b`).
# - exit 2 bloqueia a chamada e devolve a mensagem de stderr ao modelo
# - exit 0 deixa passar

INPUT=$(cat)

block() {
  echo "🚫 BLOQUEADO: worktrees são proibidos neste projeto." >&2
  echo "" >&2
  echo "Motivo: $1" >&2
  echo "" >&2
  echo "Todo trabalho acontece DIRETO na branch ativa do checkout principal." >&2
  echo "Se dois agentes podem conflitar no mesmo arquivo, use ownership disjunto" >&2
  echo "(paths exclusivos por agente) — nunca isolamento por worktree." >&2
  exit 2
}

block_branch() {
  echo "🚫 BLOQUEADO: criação de branch é decisão do usuário." >&2
  echo "" >&2
  echo "Motivo: $1" >&2
  echo "" >&2
  echo "Todo trabalho acontece DIRETO na branch ativa do checkout principal." >&2
  echo "Nenhum agente cria branch por conta própria — se uma branch nova for" >&2
  echo "necessária, o USUÁRIO decide e cria. Continue na branch ativa." >&2
  exit 2
}

# ── Caminho principal: análise tokenizada (python3) ──────────────────────────
VERDICT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json, re, shlex

try:
    data = json.load(sys.stdin)
except Exception:
    print("NOPARSE"); sys.exit(0)

ti = data.get("tool_input", {}) or {}
tool = data.get("tool_name", "") or ""
iso = ti.get("isolation", "") or ""

if tool == "EnterWorktree":
    print("BLOCKW:tentativa de usar a ferramenta EnterWorktree."); sys.exit(0)
if iso == "worktree":
    print("BLOCKW:spawn de agente com isolation: \"worktree\". Spawne sem o campo isolation."); sys.exit(0)

cmd = ti.get("command", "") or ""
# Normaliza ANTES do match: newlines e espaços múltiplos viram espaço único.
cmd = re.sub(r"\s+", " ", cmd).strip()
if not cmd:
    print("OK"); sys.exit(0)

GIT_VALUE_FLAGS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix"}

def toks_of(seg):
    try:
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

def bw(reason):   # bloqueio worktree
    print("BLOCKW:" + reason); sys.exit(0)

def bb(reason):   # bloqueio criação de branch
    print("BLOCKB:" + reason); sys.exit(0)

BRANCH_DELETE = {"-d", "-D", "--delete"}
# flags de listagem/filtragem que consomem o argumento posicional (não é criação)
BRANCH_LIST_VALUE = {"-l", "--list", "--contains", "--no-contains", "--merged",
                     "--no-merged", "--sort", "--format", "--column", "--points-at"}

for seg in re.split(r"[;&|]+|\$\(|\)|`", cmd):
    toks = toks_of(seg)
    i = 0
    while i < len(toks) and (re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", toks[i])
                            or toks[i] in ("command", "env", "nohup", "time", "exec")):
        i += 1
    if i >= len(toks):
        continue
    prog = toks[i].rsplit("/", 1)[-1]
    if prog != "git":
        continue
    rest = toks[i + 1:]
    j = 0
    while j < len(rest) and rest[j].startswith("-"):
        flag = rest[j]
        base = flag.split("=", 1)[0]
        j += 1
        if base in GIT_VALUE_FLAGS and "=" not in flag and j < len(rest):
            j += 1
    if j >= len(rest):
        continue
    sub = rest[j]
    args = rest[j + 1:]

    if sub == "worktree" and args and args[0] == "add":
        bw("comando \"git worktree add\" (inclusive com flags globais antes do subcomando).")
    if sub == "config":
        joined = " ".join(args)
        if "alias." in joined and re.search(r"\bworktree\b", joined):
            bw("git config alias.* com valor contendo worktree (bypass de alias).")
        if "alias." in joined and re.search(r"\b(checkout -b|switch -c|branch )", joined):
            bb("git config alias.* que cria branch (bypass de alias).")
    if sub == "checkout" and any(a in ("-b", "-B", "--orphan") or a.startswith("--orphan=") for a in args):
        bb("git checkout -b/-B/--orphan cria branch nova.")
    if sub == "switch" and any(a in ("-c", "-C", "--create", "--force-create")
                               or a.startswith("--create=") or a.startswith("--force-create=") for a in args):
        bb("git switch -c/-C cria branch nova.")
    if sub == "branch":
        flags = [a for a in args if a.startswith("-")]
        positionals = [a for a in args if not a.startswith("-")]
        delete_mode = any(a in BRANCH_DELETE for a in flags)
        list_mode = any(a.split("=", 1)[0] in BRANCH_LIST_VALUE for a in flags)
        # sem posicional (git branch, -a, -v, --show-current, ...) → listagem, permitido;
        # posicional consumido por flag de listagem/filtragem ou delete → permitido
        if positionals and not delete_mode and not list_mode:
            bb("git branch <nome> cria branch nova (listagem: use git branch, -a, -l, --list, --show-current, -v).")
print("OK")
' 2>/dev/null)

case "$VERDICT" in
  BLOCKW:*) block "${VERDICT#BLOCKW:}" ;;
  BLOCKB:*) block_branch "${VERDICT#BLOCKB:}" ;;
  OK|NOPARSE) exit 0 ;;
esac

# ── Fallback sem python3: grep tolerante sobre comando normalizado ────────────
TOOL_NAME=$(printf '%s' "$INPUT" \
  | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
  | sed -E 's/^"tool_name"[[:space:]]*:[[:space:]]*"//; s/"$//')
ISOLATION=$(printf '%s' "$INPUT" \
  | grep -oE '"isolation"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
  | sed -E 's/^"isolation"[[:space:]]*:[[:space:]]*"//; s/"$//')
COMMAND=$(printf '%s' "$INPUT" \
  | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 \
  | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\n/ /g; s/\\t/ /g')
NORM=$(printf '%s' "$COMMAND" | tr '\n\t' '  ' | sed -E 's/[[:space:]]+/ /g')

if [ "$TOOL_NAME" = "EnterWorktree" ]; then
  block "tentativa de usar a ferramenta EnterWorktree."
fi
if [ "$ISOLATION" = "worktree" ]; then
  block "spawn de agente com isolation: \"worktree\". Spawne sem o campo isolation."
fi

GIT_PREFIX='(^|[;&|`]|\$\()[[:space:]]*(env |command )*git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?)*'
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+worktree[[:space:]]+add\b"; then
  block "comando \"git worktree add\" (fallback). Comando: $NORM"
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+config\b" \
  && printf '%s' "$NORM" | grep -q 'alias\.' \
  && printf '%s' "$NORM" | grep -qE '\bworktree\b'; then
  block "git config alias.* com worktree (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+checkout[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-b|-B|--orphan)\b"; then
  block_branch "git checkout -b/-B/--orphan cria branch nova (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+switch[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-c|-C|--create|--force-create)\b"; then
  block_branch "git switch -c/-C cria branch nova (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+branch[[:space:]]+[^-]"; then
  block_branch "git branch <nome> cria branch nova (fallback)."
fi

exit 0
