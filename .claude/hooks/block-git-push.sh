#!/usr/bin/env bash
# .claude/hooks/block-git-push.sh
# PreToolUse hook — bloqueia git push em todo agente com Bash exceto os devops.
# Referenciado inline no frontmatter (campo `hooks:`) de cada agente implementer.
# O agente devops não tem esse hook no frontmatter, então push funciona normalmente para ele.
#
# Como funciona:
# - Recebe o JSON do Claude Code via stdin: {"tool_name":"Bash","tool_input":{"command":"..."}, ...}
# - Normaliza o comando (continuação de linha "\", newlines e espaços múltiplos → espaço único)
#   e analisa com tokenização real (python3 + shlex).
#
# PASSADA 1 (tokens): pega `git push` mesmo com flags globais no meio (`git -C <path> push`,
#   `git --git-dir=X push`, `git -c k=v push`), wrappers (`command`, `env`, `GIT_DIR=… git`,
#   `\git`, `/usr/bin/git`, `sudo`, `timeout 5 git`), `git "push"`, comandos multilinha e
#   encadeamentos (;, &&, ||, |, $(...)). Bloqueia também `git send-pack`, `git svn dcommit`,
#   `git -c alias.<x>=push <x>`, `git config alias.*` com push, `gh pr create/merge`,
#   `gh release create`, `gh repo sync` e `gh api` de escrita em /pulls|/merge.
#   Variável no lugar do programa ou do subcomando (`$g push`, `git ${X} push`, `git p$@ush`)
#   é bloqueada: expansão indireta não é permitida para operações git.
#
# PASSADA 2 (conservadora, sobre a string normalizada): bloqueia quando o comando contém ao
#   mesmo tempo um token de shell/intérprete embutido (`sh|bash|zsh|dash -c`, `eval`, `xargs`,
#   `find … -exec`, heredoc para sh/bash, `… | sh|bash`, `python3 -c`/`node -e`/`perl -e` com
#   git) e o token `push` (ou `send-pack`/`dcommit`, ou push ofuscado por quotes/variável).
#   Shell embutido não é permitido para operações git — rode o comando direto.
#
# - Sem falso positivo por palavra solta: `echo "push"` e `git commit -m "push"` passam.
# - Se python3 falhar ou faltar, registra aviso em stderr e usa o fallback em grep
#   (que cobre `\git`, `GIT_DIR=`, `/usr/bin/git`, `git -C "dir com espaço"`, `git "push"`
#   e a mesma passada conservadora).
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
VERDICT=""
if command -v python3 >/dev/null 2>&1; then
  VERDICT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json, re, shlex

try:
    data = json.load(sys.stdin)
except Exception:
    print("NOPARSE"); sys.exit(0)

ti = data.get("tool_input", {}) or {}
if not isinstance(ti, dict):
    ti = {}
raw = ti.get("command", "") or data.get("command", "") or ""
if not isinstance(raw, str):
    raw = ""
# Normaliza ANTES do match: continuação de linha some; newlines e espaços múltiplos → espaço único.
cmd = re.sub(r"\\\r?\n", " ", raw)
cmd = re.sub(r"\s+", " ", cmd).strip()
if not cmd:
    print("OK"); sys.exit(0)

def blocked(reason):
    print("BLOCK:" + reason); sys.exit(0)

# Flags globais do git que consomem um valor separado (git -C <dir> push, git -c k=v push)
GIT_VALUE_FLAGS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix"}
WRAPPERS = {"command", "env", "nohup", "time", "exec", "sudo", "doas", "nice", "ionice",
            "timeout", "caffeinate", "stdbuf", "builtin", "chronic", "unbuffer"}
PUSHY = re.compile(r"^(push|send-pack)$|^p\S*?[$\x27\"\\{}]\S*?ush$")

def toks_of(seg):
    try:
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

def basename(tok):
    return tok.lstrip("\\").rsplit("/", 1)[-1]

def analyze_git(rest):
    """rest = tokens depois de `git`. Devolve motivo de bloqueio ou None."""
    j = 0
    while j < len(rest) and rest[j].startswith("-"):
        flag = rest[j]
        base, _, inline_val = flag.partition("=")
        j += 1
        val = inline_val
        if base in GIT_VALUE_FLAGS and not inline_val and j < len(rest):
            val = rest[j]
            j += 1
        if base == "-c" and val.startswith("alias.") and re.search(r"push|send-pack|dcommit", val):
            return "git -c alias.*=push (bypass de alias inline)"
    if j >= len(rest):
        return None
    sub = rest[j]
    args = rest[j + 1:]
    if "$" in sub:
        return "subcomando git via expansão de variável (" + sub + ") — expansão indireta não é permitida para operações git"
    if sub in ("push", "send-pack"):
        return "git " + sub + " (inclusive com flags globais antes do subcomando)"
    if sub == "svn" and "dcommit" in args:
        return "git svn dcommit (push via svn)"
    if sub == "config":
        joined = " ".join(args)
        if "alias." in joined and re.search(r"\bpush\b|send-pack|dcommit", joined):
            return "git config alias.* com valor contendo push (bypass de alias)"
    return None

def analyze_gh(rest):
    for k, t in enumerate(rest):
        if t == "pr" and k + 1 < len(rest) and rest[k + 1] in ("create", "merge"):
            return "gh pr " + rest[k + 1]
        if t == "release" and k + 1 < len(rest) and rest[k + 1] == "create":
            return "gh release create (publica tag/release)"
        if t == "repo" and k + 1 < len(rest) and rest[k + 1] == "sync":
            return "gh repo sync (push implícito)"
    if "api" in rest[:3]:
        joined = " ".join(rest)
        write = (re.search(r"(^| )(-X|--method)[ =](POST|PUT|PATCH|DELETE)\b", joined, re.I)
                 or re.search(r"(^| )(-f|-F|--field|--raw-field|--input)([ =]|$)", joined))
        if write and re.search(r"/pulls(\b|/)|/merge(\b|/)", joined):
            return "gh api de escrita em endpoint /pulls ou /merge"
    return None

# ── Passada 1: comandos simples (separadores de shell e subshells) ───────────
for seg in re.split(r"[;&|]+|\$\(|\)|`", cmd):
    toks = toks_of(seg)
    if not toks:
        continue
    # Programa via variável ($g push, "$GIT" push, ${GIT:-git} push)
    first = toks[0]
    if first.startswith("$") or first.startswith("${"):
        if any(PUSHY.match(t) for t in toks[1:]):
            blocked("programa via variável (" + first + ") seguido de push — expansão indireta não é permitida para operações git")
    # Localiza git/gh em qualquer posição (cobre wrappers: env, sudo -u x, timeout 5, xargs, …)
    for k, t in enumerate(toks):
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            continue
        prog = basename(t)
        if prog == "git":
            reason = analyze_git(toks[k + 1:])
            if reason:
                blocked(reason)
        elif prog == "gh":
            reason = analyze_gh(toks[k + 1:])
            if reason:
                blocked(reason)
        elif prog in WRAPPERS or t.startswith("-"):
            continue

# ── Passada 2 (conservadora): shell/intérprete embutido + push ───────────────
SHELL_INTERP = re.compile(
    r"(?:^|[\s;&|(`{])\\?(?:\S*/)?(?:"
    r"(?:sh|bash|zsh|dash|ksh)\s+(?:-\S+\s+)*-[A-Za-z]*c\b"      # sh -c / bash -lc
    r"|(?:sh|bash|zsh|dash|ksh)\s*<<"                             # heredoc para shell
    r"|eval\b|xargs\b"
    r")"
    r"|\|\s*\\?(?:\S*/)?(?:sh|bash|zsh|dash|ksh)(?:\s|$)"          # … | sh
    r"|\bfind\b[^;&|]*\s-(?:exec|execdir|ok|okdir)\b", re.I)
LANG_INTERP = re.compile(
    r"(?:^|[\s;&|(`{])\\?(?:\S*/)?(?:python[0-9.]*|perl|ruby|php|node|deno|bun)\s+(?:-\S+\s+)*"
    r"(?:-[A-Za-z]*[ceEpr]\b|--eval\b|--print\b|--command\b)", re.I)
PUSH_SIG = re.compile(r"(?<![\w-])(?:push|send-pack|dcommit)(?![\w-])|(?<!\w)p\S*?[$\x27\"\\{}]\S*?ush(?!\w)", re.I)
VAR_PUSH = re.compile(r"(?:^|[\s;&|(`])[\"\x27]?\$\{?[A-Za-z_][^\s}]*\}?[\"\x27]?\s+[\"\x27]?push\b|\bgit\s+(?:[\"\x27]?\$\S*\s+)+[\"\x27]?push\b", re.I)

if PUSH_SIG.search(cmd):
    if SHELL_INTERP.search(cmd):
        blocked("shell embutido (sh -c / eval / xargs / find -exec / heredoc / pipe para sh) contendo push — shell embutido não é permitido para operações git; rode o comando direto")
    if LANG_INTERP.search(cmd) and re.search(r"\bgit\b|\bgh\b", cmd, re.I):
        blocked("intérprete embutido (python -c / node -e / perl -e) contendo git + push — não é permitido para operações git")
    if VAR_PUSH.search(cmd):
        blocked("push via variável indireta — expansão indireta não é permitida para operações git")
print("OK")
' 2>&1)
  case "$VERDICT" in
    BLOCK:*) block "${VERDICT#BLOCK:}" ;;
    OK) exit 0 ;;
    NOPARSE) echo "⚠️ block-git-push.sh: JSON do hook não parseável — usando fallback grep." >&2 ;;
    *) echo "⚠️ block-git-push.sh: python3 falhou (${VERDICT:-sem saída}) — usando fallback grep." >&2 ;;
  esac
else
  echo "⚠️ block-git-push.sh: python3 indisponível — usando fallback grep." >&2
fi

# ── Fallback sem python3: grep sobre comando normalizado ─────────────────────
COMMAND=$(printf '%s' "$INPUT" \
  | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
  | head -1 \
  | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\\\\\n/ /g; s/\\n/ ; /g; s/\\t/ /g; s/\\"/"/g; s/\\\\/\\/g')
NORM=$(printf '%s' "$COMMAND" | tr '\n\t' '  ' | sed -E 's/\\ / /g; s/[[:space:]]+/ /g')

SQ="'"
# prefixo: início/separador + wrappers/assignments/flags + [/caminho/]git + flags globais (valor pode ter aspas)
GIT_PREFIX="(^|[;&|\`]|\\\$\\()[[:space:]]*(\\\\?(env|command|nohup|time|exec|sudo|timeout|nice)[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+|-[^[:space:]]+[[:space:]]+|[0-9]+[smh]?[[:space:]]+)*(/[^[:space:]]*/)?\\\\?git([[:space:]]+-[^[:space:]]+([[:space:]]+(\"[^\"]*\"|${SQ}[^${SQ}]*${SQ}|[^-][^[:space:]]*))?)*"
WORD_END="([^A-Za-z0-9_-]|$)"

if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+[\"${SQ}]?(push|send-pack)[\"${SQ}]?${WORD_END}"; then
  block "git push (fallback)"
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+svn[[:space:]]+dcommit${WORD_END}"; then
  block "git svn dcommit (fallback)"
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+[^[:space:]]*\\\$"; then
  block "subcomando git via variável (fallback)"
fi
if printf '%s' "$NORM" | grep -qE "gh[[:space:]]+(pr[[:space:]]+(create|merge)|release[[:space:]]+create|repo[[:space:]]+sync)${WORD_END}"; then
  block "gh pr create/merge, gh release create ou gh repo sync (fallback)"
fi
if printf '%s' "$NORM" | grep -qE "gh[[:space:]]+api${WORD_END}" \
  && printf '%s' "$NORM" | grep -qE '/pulls|/merge' \
  && printf '%s' "$NORM" | grep -qE '(-X|--method)[ =](POST|PUT|PATCH|DELETE)|(-f|-F|--field|--raw-field|--input)[ =]'; then
  block "gh api de escrita em /pulls ou /merge (fallback)"
fi
if printf '%s' "$NORM" | grep -qE "git([[:space:]]+-[^[:space:]]+)*[[:space:]]+(-c[[:space:]]+|config[[:space:]])" \
  && printf '%s' "$NORM" | grep -q 'alias\.' \
  && printf '%s' "$NORM" | grep -qE "push|send-pack|dcommit"; then
  block "git config/-c alias.* com push (fallback)"
fi

# Passada conservadora (fallback): intérprete embutido + push
INTERP_RE="(^|[[:space:];&|(\`{])\\\\?(/[^[:space:]]*/)?((sh|bash|zsh|dash|ksh)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-[A-Za-z]*c${WORD_END}|(sh|bash|zsh|dash|ksh)[[:space:]]*<<|eval${WORD_END}|xargs${WORD_END})|\\|[[:space:]]*\\\\?(/[^[:space:]]*/)?(sh|bash|zsh|dash|ksh)([[:space:]]|$)|find[[:space:]][^;&|]*[[:space:]]-(exec|execdir|ok|okdir)${WORD_END}"
LANG_RE="(^|[[:space:];&|(\`{])\\\\?(/[^[:space:]]*/)?(python[0-9.]*|perl|ruby|php|node|deno|bun)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-[A-Za-z]*[ceEpr]${WORD_END}|--eval|--print|--command)"
PUSH_RE="(^|[^A-Za-z0-9_-])(push|send-pack|dcommit)([^A-Za-z0-9_-]|$)|(^|[^A-Za-z0-9_])p[^[:space:]]*[\$\"${SQ}\\\\{}][^[:space:]]*ush([^A-Za-z0-9_]|$)"
VARPUSH_RE="(^|[[:space:];&|(\`])[\"${SQ}]?\\\$[{]?[A-Za-z_][^[:space:]}]*[}]?[\"${SQ}]?[[:space:]]+[\"${SQ}]?push${WORD_END}|git[[:space:]]+([\"${SQ}]?\\\$[^[:space:]]*[[:space:]]+)+[\"${SQ}]?push${WORD_END}"

if printf '%s' "$NORM" | grep -qE "$PUSH_RE"; then
  if printf '%s' "$NORM" | grep -qE "$INTERP_RE"; then
    block "shell embutido (sh -c / eval / xargs / find -exec / heredoc / pipe para sh) contendo push — não é permitido para operações git (fallback)"
  fi
  if printf '%s' "$NORM" | grep -qE "$LANG_RE" && printf '%s' "$NORM" | grep -qiE "(^|[^A-Za-z0-9_])(git|gh)([^A-Za-z0-9_]|$)"; then
    block "intérprete embutido (python -c / node -e) contendo git + push (fallback)"
  fi
  if printf '%s' "$NORM" | grep -qE "$VARPUSH_RE"; then
    block "push via variável indireta (fallback)"
  fi
fi

exit 0
