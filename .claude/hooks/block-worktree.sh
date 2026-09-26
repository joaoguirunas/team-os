#!/usr/bin/env bash
# .claude/hooks/block-worktree.sh
# PreToolUse hook — garantia dura: nenhum trabalho em git worktree neste projeto.
# Registrado no .claude/settings.json do projeto com dois matchers:
#   - "Agent|Task|EnterWorktree" → bloqueia spawn de agente com isolation: worktree
#     e qualquer uso da ferramenta EnterWorktree
#   - "Bash" → bloqueia "git worktree add", criação de branch e aliases que escondam worktree
#
# Racional: worktrees escondem o trabalho do checkout principal (onde o dev
# server roda), geram branches zumbis e quebram o fluxo local. Todo agente
# trabalha direto na branch ativa; conflito se resolve com ownership disjunto.
# Criação de branch é decisão do usuário — nunca de um agente.
#
# O que BLOQUEIA (criação de branch, local ou remota):
#   git checkout -b/-B/--orphan/-t/--track   git switch -c/-C/--create/-t/--track
#   git branch <nome> (inclusive -f, -c/--copy, --track)   git stash branch <x>
#   git update-ref refs/heads/<x>            git symbolic-ref HEAD refs/heads/<nova>
#   git push <remote> <src>:refs/heads/<x>   (criação remota; main/master liberadas)
#   git -c alias.<x>=… / git config alias.* com worktree|checkout -b|switch -c|branch
# O que NÃO bloqueia (não cria branch):
#   git branch (listagem, -a, -v, -l, --list, --show-current, --contains …)
#   git branch -m/-M/--move (renomear)   git branch --set-upstream-to=… / -u … / --unset-upstream
#   git branch --edit-description        git branch -d/-D/--delete
#
# Como funciona:
# - Recebe o JSON do Claude Code via stdin: {"tool_name":"...","tool_input":{...}}
# - Comando Bash é normalizado (continuação de linha, newlines/espaços múltiplos → espaço
#   único) e tokenizado (python3 + shlex): pega git com flags globais no meio
#   (`git -C <path> worktree add`, `git --git-dir=X checkout -b`), wrappers (env, sudo,
#   timeout, \git, /usr/bin/git, GIT_DIR=…) e encadeamentos (;, &&, ||, |, $(...)).
# - Passada 2 (conservadora): shell/intérprete embutido (`sh -c`, `eval`, `xargs`,
#   `find -exec`, heredoc, `| sh`, `python -c`, `node -e`) ou variável indireta
#   (`$g worktree add`, `git ${X} -b`) combinado com o padrão proibido → bloqueia.
#   Shell embutido não é permitido para operações git.
# - Se python3 falhar ou faltar, registra aviso em stderr e usa o fallback em grep.
# - exit 2 bloqueia a chamada e devolve a mensagem de stderr ao modelo; exit 0 deixa passar.

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

block_indirect() {
  echo "🚫 BLOQUEADO: shell embutido / expansão indireta não é permitido para operações git." >&2
  echo "" >&2
  echo "Motivo: $1" >&2
  echo "" >&2
  echo "Rode o comando git direto, sem sh -c / eval / xargs / find -exec / heredoc /" >&2
  echo "pipe para sh nem variáveis no lugar do programa ou do subcomando." >&2
  echo "Worktree e criação de branch continuam proibidos: todo trabalho é na branch ativa." >&2
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
tool = data.get("tool_name", "") or ""
iso = ti.get("isolation", "") or ""

if tool == "EnterWorktree":
    print("BLOCKW:tentativa de usar a ferramenta EnterWorktree."); sys.exit(0)
if iso == "worktree":
    print("BLOCKW:spawn de agente com isolation: \"worktree\". Spawne sem o campo isolation."); sys.exit(0)

raw = ti.get("command", "") or ""
if not isinstance(raw, str):
    raw = ""
cmd = re.sub(r"\\\r?\n", " ", raw)
cmd = re.sub(r"\s+", " ", cmd).strip()
if not cmd:
    print("OK"); sys.exit(0)

GIT_VALUE_FLAGS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix"}
WRAPPERS = {"command", "env", "nohup", "time", "exec", "sudo", "doas", "nice", "ionice",
            "timeout", "caffeinate", "stdbuf", "builtin", "chronic", "unbuffer"}

def toks_of(seg):
    try:
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

def basename(tok):
    return tok.lstrip("\\").rsplit("/", 1)[-1]

def bw(reason): print("BLOCKW:" + reason); sys.exit(0)   # worktree
def bb(reason): print("BLOCKB:" + reason); sys.exit(0)   # criação de branch
def bx(reason): print("BLOCKX:" + reason); sys.exit(0)   # indireção / shell embutido

ALIAS_BRANCH = re.compile(r"checkout\s+(?:-\S+\s+)*(?:-b|-B|--orphan|-t|--track)|switch\s+(?:-\S+\s+)*(?:-c|-C|--create|-t|--track)|\bbranch\s+[^-\s]|stash\s+branch|update-ref|symbolic-ref")

BRANCH_DELETE = {"-d", "-D", "--delete"}
BRANCH_RENAME = {"-m", "-M", "--move"}
BRANCH_UPSTREAM_VALUE = {"-u", "--set-upstream-to"}
BRANCH_NOCREATE = {"--unset-upstream", "--edit-description", "--show-current"}
# flags de listagem/filtragem que consomem o argumento posicional (não é criação)
BRANCH_LIST_VALUE = {"-l", "--list", "--contains", "--no-contains", "--merged",
                     "--no-merged", "--sort", "--format", "--column", "--points-at"}

def push_creates_branch(args):
    """git push <remote> <src>:refs/heads/<x> cria branch remota (main/master liberadas)."""
    k = 0
    while k < len(args):
        a = args[k]
        if a.startswith("-"):
            base = a.split("=", 1)[0]
            if base in ("-o", "--push-option", "--repo", "--receive-pack", "--exec") and "=" not in a:
                k += 1
            k += 1
            continue
        m = re.match(r"^\+?[^:]*:refs/heads/(.+)$", a)
        if m and m.group(1) not in ("main", "master"):
            return m.group(1)
        k += 1
    return None

def analyze_git(rest):
    j = 0
    while j < len(rest) and rest[j].startswith("-"):
        flag = rest[j]
        base, _, inline_val = flag.partition("=")
        j += 1
        val = inline_val
        if base in GIT_VALUE_FLAGS and not inline_val and j < len(rest):
            val = rest[j]
            j += 1
        if base == "-c" and val.startswith("alias."):
            if re.search(r"\bworktree\b", val):
                bw("git -c alias.*=worktree (bypass de alias inline).")
            if ALIAS_BRANCH.search(val):
                bb("git -c alias.* que cria branch (bypass de alias inline).")
    if j >= len(rest):
        return
    sub = rest[j]
    args = rest[j + 1:]
    if "$" in sub:
        bx("subcomando git via expansão de variável (" + sub + ").")

    if sub == "worktree" and args and args[0] == "add":
        bw("comando \"git worktree add\" (inclusive com flags globais antes do subcomando).")
    if sub == "config":
        joined = " ".join(args)
        if "alias." in joined and re.search(r"\bworktree\b", joined):
            bw("git config alias.* com valor contendo worktree (bypass de alias).")
        if "alias." in joined and ALIAS_BRANCH.search(joined):
            bb("git config alias.* que cria branch (bypass de alias).")
    if sub == "checkout" and any(a in ("-b", "-B", "--orphan", "-t", "--track") or a.startswith("--orphan=") for a in args):
        bb("git checkout -b/-B/--orphan/-t/--track cria branch nova.")
    if sub == "switch" and any(a in ("-c", "-C", "--create", "--force-create", "-t", "--track")
                               or a.startswith("--create=") or a.startswith("--force-create=") for a in args):
        bb("git switch -c/-C/-t/--track cria branch nova.")
    if sub == "branch":
        flags = [a for a in args if a.startswith("-")]
        delete_mode = any(a in BRANCH_DELETE for a in flags)
        rename_mode = any(a in BRANCH_RENAME for a in flags)
        upstream_mode = any(a.split("=", 1)[0] in BRANCH_UPSTREAM_VALUE for a in flags)
        nocreate_mode = any(a in BRANCH_NOCREATE for a in flags)
        list_mode = any(a.split("=", 1)[0] in BRANCH_LIST_VALUE for a in flags)
        positionals = [a for a in args if not a.startswith("-")]
        # sem posicional (git branch, -a, -v, --show-current, ...) → listagem, permitido;
        # rename / upstream / unset / delete / listagem-com-filtro → permitido
        if positionals and not (delete_mode or rename_mode or upstream_mode or nocreate_mode or list_mode):
            bb("git branch <nome> cria branch nova (listagem: git branch, -a, -l, --list, --show-current, -v; renomear: -m).")
    if sub == "stash" and args and args[0] == "branch":
        bb("git stash branch <nome> cria branch nova a partir do stash.")
    if sub == "update-ref":
        if not any(a in ("-d", "--delete") for a in args) and any(a.startswith("refs/heads/") for a in args):
            bb("git update-ref refs/heads/<nome> cria/move branch por baixo dos panos.")
    if sub == "symbolic-ref":
        pos = [a for a in args if not a.startswith("-")]
        if len(pos) >= 2 and pos[0] == "HEAD" and pos[1].startswith("refs/heads/"):
            bb("git symbolic-ref HEAD refs/heads/<nova> aponta HEAD para branch nova.")
    if sub == "push":
        created = push_creates_branch(args)
        if created:
            bb("git push <remote> <src>:refs/heads/" + created + " cria branch remota.")

CREATE_SIG = re.compile(
    r"\bworktree\s+add\b"
    r"|\bcheckout\s+(?:-\S+\s+)*(?:-b|-B|--orphan|-t|--track)(?![\w-])"
    r"|\bswitch\s+(?:-\S+\s+)*(?:-c|-C|--create|--force-create|-t|--track)(?![\w-])"
    r"|\bbranch\s+[\"\x27]?[A-Za-z0-9_./]"
    r"|\bstash\s+branch\b"
    r"|\bupdate-ref\s+(?:-\S+\s+)*[\"\x27]?refs/heads/"
    r"|\bsymbolic-ref\s+(?:-\S+\s+)*HEAD\s+[\"\x27]?refs/heads/"
    r"|:refs/heads/(?!main\b|master\b)")

# ── Passada 1: tokens por comando simples ────────────────────────────────────
for seg in re.split(r"[;&|]+|\$\(|\)|`", cmd):
    toks = toks_of(seg)
    if not toks:
        continue
    first = toks[0]
    if (first.startswith("$") or first.startswith("${")) and CREATE_SIG.search(" ".join(toks[1:])):
        bx("programa via variável (" + first + ") seguido de worktree add / criação de branch.")
    for k, t in enumerate(toks):
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            continue
        if basename(t) == "git":
            analyze_git(toks[k + 1:])

# ── Passada 2 (conservadora): shell/intérprete embutido + padrão proibido ────
SHELL_INTERP = re.compile(
    r"(?:^|[\s;&|(`{])\\?(?:\S*/)?(?:"
    r"(?:sh|bash|zsh|dash|ksh)\s+(?:-\S+\s+)*-[A-Za-z]*c\b"
    r"|(?:sh|bash|zsh|dash|ksh)\s*<<"
    r"|eval\b|xargs\b"
    r")"
    r"|\|\s*\\?(?:\S*/)?(?:sh|bash|zsh|dash|ksh)(?:\s|$)"
    r"|\bfind\b[^;&|]*\s-(?:exec|execdir|ok|okdir)\b", re.I)
LANG_INTERP = re.compile(
    r"(?:^|[\s;&|(`{])\\?(?:\S*/)?(?:python[0-9.]*|perl|ruby|php|node|deno|bun)\s+(?:-\S+\s+)*"
    r"(?:-[A-Za-z]*[ceEpr]\b|--eval\b|--print\b|--command\b)", re.I)
VAR_GIT = re.compile(r"(?:^|[\s;&|(`])[\"\x27]?\$\{?[A-Za-z_][^\s}]*\}?[\"\x27]?\s+(?:-\S+\s+)*(?:worktree|checkout|switch|branch|stash|update-ref|symbolic-ref)\b|\bgit\s+(?:[\"\x27]?\$\S*\s+)+(?:worktree|checkout|switch|branch|stash|update-ref|symbolic-ref)\b", re.I)
OBFUSC = re.compile(r"(?<!\w)(?:w\S*?[$\x27\"\\{}]\S*?orktree|c\S*?[$\x27\"\\{}]\S*?heckout|b\S*?[$\x27\"\\{}]\S*?ranch)(?!\w)")

if CREATE_SIG.search(cmd) or re.search(r"\bworktree\b", cmd, re.I):
    if SHELL_INTERP.search(cmd):
        bx("shell embutido (sh -c / eval / xargs / find -exec / heredoc / pipe para sh) contendo worktree add / criação de branch.")
    if LANG_INTERP.search(cmd) and re.search(r"\bgit\b", cmd, re.I):
        bx("intérprete embutido (python -c / node -e / perl -e) contendo git + worktree/criação de branch.")
    if VAR_GIT.search(cmd):
        bx("git via variável indireta com worktree/criação de branch.")
if OBFUSC.search(cmd) and re.search(r"\bgit\b|\$", cmd):
    bx("subcomando git ofuscado por quotes/variável (worktree/checkout/branch).")
print("OK")
' 2>&1)
  case "$VERDICT" in
    BLOCKW:*) block "${VERDICT#BLOCKW:}" ;;
    BLOCKB:*) block_branch "${VERDICT#BLOCKB:}" ;;
    BLOCKX:*) block_indirect "${VERDICT#BLOCKX:}" ;;
    OK) exit 0 ;;
    NOPARSE) echo "⚠️ block-worktree.sh: JSON do hook não parseável — usando fallback grep." >&2 ;;
    *) echo "⚠️ block-worktree.sh: python3 falhou (${VERDICT:-sem saída}) — usando fallback grep." >&2 ;;
  esac
else
  echo "⚠️ block-worktree.sh: python3 indisponível — usando fallback grep." >&2
fi

# ── Fallback sem python3: grep tolerante sobre comando normalizado ────────────
TOOL_NAME=$(printf '%s' "$INPUT" \
  | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
  | sed -E 's/^"tool_name"[[:space:]]*:[[:space:]]*"//; s/"$//')
ISOLATION=$(printf '%s' "$INPUT" \
  | grep -oE '"isolation"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
  | sed -E 's/^"isolation"[[:space:]]*:[[:space:]]*"//; s/"$//')
COMMAND=$(printf '%s' "$INPUT" \
  | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 \
  | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\\\\\n/ /g; s/\\n/ ; /g; s/\\t/ /g; s/\\"/"/g; s/\\\\/\\/g')
NORM=$(printf '%s' "$COMMAND" | tr '\n\t' '  ' | sed -E 's/\\ / /g; s/[[:space:]]+/ /g')

if [ "$TOOL_NAME" = "EnterWorktree" ]; then
  block "tentativa de usar a ferramenta EnterWorktree."
fi
if [ "$ISOLATION" = "worktree" ]; then
  block "spawn de agente com isolation: \"worktree\". Spawne sem o campo isolation."
fi

SQ="'"
GIT_PREFIX="(^|[;&|\`]|\\\$\\()[[:space:]]*(\\\\?(env|command|nohup|time|exec|sudo|timeout|nice)[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+|-[^[:space:]]+[[:space:]]+|[0-9]+[smh]?[[:space:]]+)*(/[^[:space:]]*/)?\\\\?git([[:space:]]+-[^[:space:]]+([[:space:]]+(\"[^\"]*\"|${SQ}[^${SQ}]*${SQ}|[^-][^[:space:]]*))?)*"
WORD_END="([^A-Za-z0-9_-]|$)"

if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+worktree[[:space:]]+add${WORD_END}"; then
  block "comando \"git worktree add\" (fallback). Comando: $NORM"
fi
if printf '%s' "$NORM" | grep -qE "git([[:space:]]+-[^[:space:]]+)*[[:space:]]+(-c[[:space:]]+|config[[:space:]])" \
  && printf '%s' "$NORM" | grep -q 'alias\.'; then
  if printf '%s' "$NORM" | grep -qE "worktree"; then
    block "git config/-c alias.* com worktree (fallback)."
  fi
  if printf '%s' "$NORM" | grep -qE "checkout[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-b|-B|--orphan|-t|--track)|switch[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-c|-C|--create|-t|--track)|branch[[:space:]]+[^-[:space:]]|stash[[:space:]]+branch|update-ref|symbolic-ref"; then
    block_branch "git config/-c alias.* que cria branch (fallback)."
  fi
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+[^[:space:]]*\\\$"; then
  block_indirect "subcomando git via variável (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+checkout[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-b|-B|--orphan|-t|--track)${WORD_END}"; then
  block_branch "git checkout -b/-B/--orphan/-t/--track cria branch nova (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+switch[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-c|-C|--create|--force-create|-t|--track)${WORD_END}"; then
  block_branch "git switch -c/-C/-t/--track cria branch nova (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+branch[[:space:]]+([^-[:space:]]|-f[[:space:]]|--force[[:space:]]|-c[[:space:]]|--copy[[:space:]]|-t[[:space:]]|--track[[:space:]])" \
  && ! printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+branch[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-m|-M|--move|-u|--set-upstream-to|--unset-upstream|--edit-description|-d|-D|--delete|-l|--list|--contains|--no-contains|--merged|--no-merged|--points-at)"; then
  block_branch "git branch <nome> cria branch nova (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+stash[[:space:]]+branch${WORD_END}"; then
  block_branch "git stash branch <nome> cria branch nova (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+update-ref[[:space:]]+[\"${SQ}]?refs/heads/"; then
  block_branch "git update-ref refs/heads/<nome> (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+symbolic-ref[[:space:]]+(-[^[:space:]]+[[:space:]]+)*HEAD[[:space:]]+[\"${SQ}]?refs/heads/"; then
  block_branch "git symbolic-ref HEAD refs/heads/<nova> (fallback)."
fi
if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+push${WORD_END}" \
  && printf '%s' "$NORM" | grep -qE ":refs/heads/" \
  && ! printf '%s' "$NORM" | grep -qE ":refs/heads/(main|master)${WORD_END}"; then
  block_branch "git push <remote> <src>:refs/heads/<x> cria branch remota (fallback)."
fi

# Passada conservadora (fallback): intérprete embutido / variável + padrão proibido
INTERP_RE="(^|[[:space:];&|(\`{])\\\\?(/[^[:space:]]*/)?((sh|bash|zsh|dash|ksh)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-[A-Za-z]*c${WORD_END}|(sh|bash|zsh|dash|ksh)[[:space:]]*<<|eval${WORD_END}|xargs${WORD_END})|\\|[[:space:]]*\\\\?(/[^[:space:]]*/)?(sh|bash|zsh|dash|ksh)([[:space:]]|$)|find[[:space:]][^;&|]*[[:space:]]-(exec|execdir|ok|okdir)${WORD_END}"
LANG_RE="(^|[[:space:];&|(\`{])\\\\?(/[^[:space:]]*/)?(python[0-9.]*|perl|ruby|php|node|deno|bun)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-[A-Za-z]*[ceEpr]${WORD_END}|--eval|--print|--command)"
CREATE_RE="worktree[[:space:]]+add|checkout[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-b|-B|--orphan|-t|--track)${WORD_END}|switch[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-c|-C|--create|--force-create|-t|--track)${WORD_END}|branch[[:space:]]+[\"${SQ}]?[A-Za-z0-9_./]|stash[[:space:]]+branch|update-ref[[:space:]]+(-[^[:space:]]+[[:space:]]+)*[\"${SQ}]?refs/heads/|symbolic-ref[[:space:]]+(-[^[:space:]]+[[:space:]]+)*HEAD[[:space:]]+[\"${SQ}]?refs/heads/|:refs/heads/"
VARGIT_RE="(^|[[:space:];&|(\`])[\"${SQ}]?\\\$[{]?[A-Za-z_][^[:space:]}]*[}]?[\"${SQ}]?[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(worktree|checkout|switch|branch|stash|update-ref|symbolic-ref)${WORD_END}|git[[:space:]]+([\"${SQ}]?\\\$[^[:space:]]*[[:space:]]+)+(worktree|checkout|switch|branch|stash|update-ref|symbolic-ref)${WORD_END}"
OBFUSC_RE="(^|[^A-Za-z0-9_])(w[^[:space:]]*[\$\"${SQ}\\\\{}][^[:space:]]*orktree|c[^[:space:]]*[\$\"${SQ}\\\\{}][^[:space:]]*heckout|b[^[:space:]]*[\$\"${SQ}\\\\{}][^[:space:]]*ranch)([^A-Za-z0-9_]|$)"

if printf '%s' "$NORM" | grep -qE "$CREATE_RE" || printf '%s' "$NORM" | grep -qiE "worktree"; then
  if printf '%s' "$NORM" | grep -qE "$INTERP_RE"; then
    block_indirect "shell embutido contendo worktree add / criação de branch (fallback)."
  fi
  if printf '%s' "$NORM" | grep -qE "$LANG_RE" && printf '%s' "$NORM" | grep -qiE "(^|[^A-Za-z0-9_])git([^A-Za-z0-9_]|$)"; then
    block_indirect "intérprete embutido (python -c / node -e) contendo git + worktree/criação de branch (fallback)."
  fi
  if printf '%s' "$NORM" | grep -qE "$VARGIT_RE"; then
    block_indirect "git via variável indireta com worktree/criação de branch (fallback)."
  fi
fi
if printf '%s' "$NORM" | grep -qE "$OBFUSC_RE"; then
  block_indirect "subcomando git ofuscado por quotes/variável (fallback)."
fi

exit 0
