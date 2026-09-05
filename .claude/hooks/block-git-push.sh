#!/usr/bin/env bash
# .claude/hooks/block-git-push.sh
# PreToolUse hook — bloqueia git push em agentes dev-dev-*
# Referenciado inline no frontmatter (campo `hooks:`) de cada dev-dev-*.
# O agente devops não tem esse hook no frontmatter, então push funciona normalmente para ele.
#
# Como funciona:
# - Recebe o JSON do Claude Code via stdin: {"tool_name":"Bash","tool_input":{"command":"..."}, ...}
# - Analisa o comando com tokenização real (python3 + shlex): pega `git push` mesmo
#   com flags globais no meio (`git -C <path> push`, `git --git-dir=X push`,
#   `git -c k=v push`), comandos multilinha e encadeamentos (;, &&, ||, |, $(...)).
# - Bloqueia também `gh pr create/merge`, `gh api` de escrita em /pulls|/merge
#   e `git config alias.*` cujo valor contenha push.
# - Sem falso positivo por palavra solta: `echo "push"` e `git commit -m "push"` passam.
# - Se o comando ofende, bloqueia com exit 2 e mensagem explicativa; senão exit 0.

INPUT=$(cat)

block() {
  echo "🚫 BLOQUEADO: git push / gh pr não é permitido neste agente." >&2
  echo "" >&2
  echo "Apenas o agente devops tem autoridade para push, criação e merge de PRs." >&2
  echo "Solicite ao lead que acione o agente devops para publicar esta branch." >&2
  echo "" >&2
  echo "Motivo: $1" >&2
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
cmd = ti.get("command", "") or data.get("command", "") or ""
# Normaliza ANTES do match: newlines e espaços múltiplos viram espaço único.
cmd = re.sub(r"\s+", " ", cmd).strip()
if not cmd:
    print("OK"); sys.exit(0)

# Flags globais do git que consomem um valor separado (git -C <dir> push, git -c k=v push)
GIT_VALUE_FLAGS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix"}

def toks_of(seg):
    try:
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

def blocked(reason):
    print("BLOCK:" + reason); sys.exit(0)

# Divide em comandos simples (aproximação: separadores de shell e subshells)
for seg in re.split(r"[;&|]+|\$\(|\)|`", cmd):
    toks = toks_of(seg)
    i = 0
    # pula assignments de env e wrappers comuns
    while i < len(toks) and (re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", toks[i])
                            or toks[i] in ("command", "env", "nohup", "time", "exec")):
        i += 1
    if i >= len(toks):
        continue
    prog = toks[i].rsplit("/", 1)[-1]
    rest = toks[i + 1:]

    if prog == "git":
        # pula flags globais (e o valor das que exigem valor) até achar o subcomando
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
        if sub == "push":
            blocked("git push (inclusive com flags globais antes do subcomando)")
        if sub == "config":
            joined = " ".join(args)
            if "alias." in joined and re.search(r"\bpush\b", joined):
                blocked("git config alias.* com valor contendo push (bypass de alias)")
    elif prog == "gh":
        for k, t in enumerate(rest):
            if t == "pr" and k + 1 < len(rest) and rest[k + 1] in ("create", "merge"):
                blocked("gh pr " + rest[k + 1])
        if "api" in rest[:3]:
            joined = " ".join(rest)
            write = (re.search(r"(^| )(-X|--method)[ =](POST|PUT|PATCH|DELETE)\b", joined, re.I)
                     or re.search(r"(^| )(-f|-F|--field|--raw-field|--input)([ =]|$)", joined))
            if write and re.search(r"/pulls(\b|/)|/merge(\b|/)", joined):
                blocked("gh api de escrita em endpoint /pulls ou /merge")
print("OK")
' 2>/dev/null)

case "$VERDICT" in
  BLOCK:*) block "${VERDICT#BLOCK:}" ;;
  OK|NOPARSE) exit 0 ;;
esac

# ── Fallback sem python3: grep sobre comando normalizado ─────────────────────
COMMAND=$(printf '%s' "$INPUT" \
  | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
  | head -1 \
  | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\n/ /g; s/\\t/ /g')
NORM=$(printf '%s' "$COMMAND" | tr '\n\t' '  ' | sed -E 's/[[:space:]]+/ /g')

GIT_PREFIX='(^|[;&|`]|\$\()[[:space:]]*(env |command )*git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?)*'
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+push\b"; then
  block "git push (fallback)"
fi
if printf '%s' "$NORM" | grep -qE 'gh[[:space:]]+pr[[:space:]]+(create|merge)\b'; then
  block "gh pr create/merge (fallback)"
fi
if printf '%s' "$NORM" | grep -qE 'gh[[:space:]]+api\b' \
  && printf '%s' "$NORM" | grep -qE '/pulls|/merge' \
  && printf '%s' "$NORM" | grep -qE '(-X|--method)[ =](POST|PUT|PATCH|DELETE)|(-f|-F|--field|--raw-field|--input)[ =]'; then
  block "gh api de escrita em /pulls ou /merge (fallback)"
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+config\b" \
  && printf '%s' "$NORM" | grep -q 'alias\.' \
  && printf '%s' "$NORM" | grep -qE '\bpush\b'; then
  block "git config alias.* com push (fallback)"
fi

exit 0
