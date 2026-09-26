#!/usr/bin/env bash
# .claude/hooks/guard-push-branch.sh
# PreToolUse hook (Bash) para agentes devops — push permitido só na main/master.
#
# REGRA (conservadora, sempre aplicada):
#   • A branch do repositório ALVO precisa ser main ou master, E
#   • toda ref de destino do push (se houver refspec) precisa ser main ou master
#     (`git push`, `git push origin main`, `git push -u origin HEAD:main`,
#      `git push origin HEAD:refs/heads/master` → ok estando na main;
#      `git push origin feature`, `git push origin main:feature`, `git push origin :x`,
#      `git push origin v1.0` → bloqueado; para tags use `git push --tags`).
#   • Detached HEAD, repositório inexistente ou branch indeterminável → BLOQUEIA.
#
# "Pedido explícito do usuário" NÃO é verificável por um hook (ele só vê o comando e o cwd).
# Por isso, fora da main/master o bloqueio é SEMPRE aplicado: o agente deve pedir ao usuário
# que faça o push manualmente (ou que mude para a main antes). Não existe override por
# variável de ambiente nem por texto no comando — isso seria bypass trivial.
#
# Repositório ALVO (nesta ordem):
#   1. `git -C <dir>` (encadeado: `-C a -C b` = a/b) ou `--git-dir=<x>` do próprio comando
#   2. `cwd` do JSON do hook
#   3. CLAUDE_PROJECT_DIR
#   4. pwd
#
# Detecção de push: mesma tokenização robusta do block-git-push.sh (shlex, flags globais entre
# git e push, wrappers, encadeamentos, `git send-pack`, `git -c alias.x=push x`) + passada
# conservadora para shell/intérprete embutido e variáveis indiretas (tratados como push com
# alvo = cwd). Se python3 falhar ou faltar, avisa em stderr e usa o fallback em grep.
# Comandos sem push → exit 0.

INPUT=$(cat)

block_branch() {
  {
    echo "🚫 Push permitido só na main/master. $1"
    echo ""
    echo "Fora da main o bloqueio é sempre aplicado — o hook não consegue verificar um pedido"
    echo "explícito do usuário. Peça ao usuário que faça o push manualmente (ou que volte para"
    echo "a main/master) e continue o trabalho na branch ativa."
  } >&2
  exit 2
}

json_str() {  # json_str <chave> — string de 1º nível (fallback sem python3)
  printf '%s' "$INPUT" | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" \
    | head -1 | sed -E "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//; s/\\\\\"/\"/g; s/\\\\\\\\/\\\\/g"
}

# ── Detecção de git push + alvo + refspecs (python3) ─────────────────────────
# Saída: NO | NOPARSE | PUSH<TAB><cwd><TAB><-C dir><TAB><--git-dir><TAB><dest1,dest2,...>
RESULT=""
if command -v python3 >/dev/null 2>&1; then
  RESULT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json, re, shlex, os

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
cwd = data.get("cwd") if isinstance(data.get("cwd"), str) else ""
cmd = re.sub(r"\\\r?\n", " ", raw)
cmd = re.sub(r"\s+", " ", cmd).strip()
if not cmd:
    print("NO"); sys.exit(0)

GIT_VALUE_FLAGS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix"}
PUSH_VALUE_FLAGS = {"-o", "--push-option", "--repo", "--receive-pack", "--exec"}

def toks_of(seg):
    try:
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

def basename(tok):
    return tok.lstrip("\\").rsplit("/", 1)[-1]

def dests_of(args):
    """refs de destino de um `git push <args>`; HEAD = branch atual."""
    remote = None
    dests = []
    delete = False
    k = 0
    while k < len(args):
        a = args[k]
        if a == "--":
            for r in args[k + 1:]:
                dests.append(r)
            break
        if a.startswith("-"):
            base = a.split("=", 1)[0]
            if base in ("-d", "--delete"):
                delete = True
            if base in PUSH_VALUE_FLAGS and "=" not in a and k + 1 < len(args):
                k += 1
            k += 1
            continue
        if remote is None:
            remote = a
        else:
            dests.append(a)
        k += 1
    out = []
    for r in dests:
        r = r.lstrip("+")
        if delete:
            dst = r
        elif ":" in r:
            src, dst = r.split(":", 1)
            dst = dst or src
        else:
            dst = r
        if dst.startswith("refs/heads/"):
            dst = dst[len("refs/heads/"):]
        out.append(dst or "?")
    return out

def report(cdir, gitdir, dests):
    print("PUSH\t" + cwd + "\t" + cdir + "\t" + gitdir + "\t" + ",".join(dests)); sys.exit(0)

# ── Passada 1: tokens ────────────────────────────────────────────────────────
for seg in re.split(r"[;&|]+|\$\(|\)|`", cmd):
    toks = toks_of(seg)
    for k, t in enumerate(toks):
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            continue
        if basename(t) != "git":
            continue
        rest = toks[k + 1:]
        cdir = ""
        gitdir = ""
        j = 0
        alias_push = False
        while j < len(rest) and rest[j].startswith("-"):
            flag = rest[j]
            base, _, inline_val = flag.partition("=")
            j += 1
            val = inline_val
            if base in GIT_VALUE_FLAGS and not inline_val and j < len(rest):
                val = rest[j]
                j += 1
            if base == "-C" and val:
                cdir = os.path.join(cdir, val) if cdir else val
            elif base == "--git-dir" and val:
                gitdir = val
            elif base == "-c" and val.startswith("alias.") and re.search(r"push|send-pack", val):
                alias_push = True
        if j >= len(rest):
            continue
        sub = rest[j]
        args = rest[j + 1:]
        if sub in ("push", "send-pack") or "$" in sub or alias_push:
            report(cdir, gitdir, dests_of(args) if sub == "push" else [])

# ── Passada 2 (conservadora): shell/intérprete embutido ou variável + push ───
SHELL_INTERP = re.compile(
    r"(?:^|[\s;&|(`{])\\?(?:\S*/)?(?:(?:sh|bash|zsh|dash|ksh)\s+(?:-\S+\s+)*-[A-Za-z]*c\b|(?:sh|bash|zsh|dash|ksh)\s*<<|eval\b|xargs\b)"
    r"|\|\s*\\?(?:\S*/)?(?:sh|bash|zsh|dash|ksh)(?:\s|$)|\bfind\b[^;&|]*\s-(?:exec|execdir|ok|okdir)\b", re.I)
LANG_INTERP = re.compile(
    r"(?:^|[\s;&|(`{])\\?(?:\S*/)?(?:python[0-9.]*|perl|ruby|php|node|deno|bun)\s+(?:-\S+\s+)*(?:-[A-Za-z]*[ceEpr]\b|--eval\b|--print\b|--command\b)", re.I)
PUSH_SIG = re.compile(r"(?<![\w-])(?:push|send-pack)(?![\w-])|(?<!\w)p\S*?[$\x27\"\\{}]\S*?ush(?!\w)", re.I)
VAR_PUSH = re.compile(r"(?:^|[\s;&|(`])[\"\x27]?\$\{?[A-Za-z_][^\s}]*\}?[\"\x27]?\s+[\"\x27]?push\b|\bgit\s+(?:[\"\x27]?\$\S*\s+)+[\"\x27]?push\b", re.I)

if PUSH_SIG.search(cmd) and (SHELL_INTERP.search(cmd) or VAR_PUSH.search(cmd)
                             or (LANG_INTERP.search(cmd) and re.search(r"\bgit\b", cmd, re.I))):
    m = re.search(r"\bpush\b((?:\s+[^;&|`)]+)*)", cmd)
    dests = dests_of(toks_of(m.group(1))) if m else []
    report("", "", dests)
print("NO")
' 2>&1)
fi

CWD_JSON=""; CDIR=""; GITDIR=""; DESTS=""
case "$RESULT" in
  NO) exit 0 ;;
  PUSH*)
    # campos separados por TAB (bash 3.2: sem mapfile)
    CWD_JSON=$(printf '%s' "$RESULT" | cut -f2)
    CDIR=$(printf '%s' "$RESULT" | cut -f3)
    GITDIR=$(printf '%s' "$RESULT" | cut -f4)
    DESTS=$(printf '%s' "$RESULT" | cut -f5)
    ;;
  *)
    if [ "$RESULT" = "NOPARSE" ]; then
      echo "⚠️ guard-push-branch.sh: JSON do hook não parseável — usando fallback grep." >&2
    elif command -v python3 >/dev/null 2>&1; then
      echo "⚠️ guard-push-branch.sh: python3 falhou (${RESULT:-sem saída}) — usando fallback grep." >&2
    else
      echo "⚠️ guard-push-branch.sh: python3 indisponível — usando fallback grep." >&2
    fi
    COMMAND=$(json_str command)
    NORM=$(printf '%s' "$COMMAND" | sed -E 's/\\\\\\n/ /g; s/\\n/ ; /g; s/\\t/ /g' | tr '\n\t' '  ' | sed -E 's/\\ / /g; s/[[:space:]]+/ /g')
    SQ="'"
    GIT_PREFIX="(^|[;&|\`]|\\\$\\()[[:space:]]*(\\\\?(env|command|nohup|time|exec|sudo|timeout|nice)[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+|-[^[:space:]]+[[:space:]]+|[0-9]+[smh]?[[:space:]]+)*(/[^[:space:]]*/)?\\\\?git([[:space:]]+-[^[:space:]]+([[:space:]]+(\"[^\"]*\"|${SQ}[^${SQ}]*${SQ}|[^-][^[:space:]]*))?)*"
    WORD_END="([^A-Za-z0-9_-]|$)"
    INTERP_RE="(^|[[:space:];&|(\`{])\\\\?(/[^[:space:]]*/)?((sh|bash|zsh|dash|ksh)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-[A-Za-z]*c${WORD_END}|(sh|bash|zsh|dash|ksh)[[:space:]]*<<|eval${WORD_END}|xargs${WORD_END})|\\|[[:space:]]*\\\\?(/[^[:space:]]*/)?(sh|bash|zsh|dash|ksh)([[:space:]]|$)|find[[:space:]][^;&|]*[[:space:]]-(exec|execdir|ok|okdir)${WORD_END}"
    PUSH_RE="(^|[^A-Za-z0-9_-])(push|send-pack)([^A-Za-z0-9_-]|$)|(^|[^A-Za-z0-9_])p[^[:space:]]*[\$\"${SQ}\\\\{}][^[:space:]]*ush([^A-Za-z0-9_]|$)"
    VARPUSH_RE="(^|[[:space:];&|(\`])[\"${SQ}]?\\\$[{]?[A-Za-z_][^[:space:]}]*[}]?[\"${SQ}]?[[:space:]]+[\"${SQ}]?push${WORD_END}|git[[:space:]]+([\"${SQ}]?\\\$[^[:space:]]*[[:space:]]+)+[\"${SQ}]?push${WORD_END}"
    IS_PUSH=""
    if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+[\"${SQ}]?(push|send-pack)[\"${SQ}]?${WORD_END}"; then IS_PUSH=1; fi
    if printf '%s' "$NORM" | grep -qE "${GIT_PREFIX}[[:space:]]+[^[:space:]]*\\\$"; then IS_PUSH=1; fi
    if printf '%s' "$NORM" | grep -qE "$PUSH_RE" \
      && { printf '%s' "$NORM" | grep -qE "$INTERP_RE" || printf '%s' "$NORM" | grep -qE "$VARPUSH_RE"; }; then IS_PUSH=1; fi
    [ -n "$IS_PUSH" ] || exit 0
    CWD_JSON=$(json_str cwd)
    # -C <dir> (com ou sem aspas) e --git-dir
    CDIR=$(printf '%s' "$NORM" | sed -nE "s/.*git[[:space:]]+(-[^C][^[:space:]]*[[:space:]]+)*-C[[:space:]]+(\"([^\"]*)\"|${SQ}([^${SQ}]*)${SQ}|([^[:space:]]+)).*/\\3\\4\\5/p" | head -1)
    GITDIR=$(printf '%s' "$NORM" | sed -nE "s/.*--git-dir[=[:space:]]+(\"([^\"]*)\"|${SQ}([^${SQ}]*)${SQ}|([^[:space:]]+)).*/\\2\\3\\4/p" | head -1)
    DESTS=$(printf '%s' "$NORM" | sed -nE 's/.*[[:space:]]push[[:space:]]+(-[^[:space:]]+[[:space:]]+)*[^[:space:]-]+[[:space:]]+(-[^[:space:]]+[[:space:]]+)*([^[:space:];&|-]+).*/\3/p' | head -1)
    DESTS="${DESTS#+}"
    case "$DESTS" in
      *:*) DESTS="${DESTS#*:}" ;;
    esac
    DESTS="${DESTS#refs/heads/}"
    ;;
esac

# ── Repositório ALVO: -C/--git-dir do comando → cwd do JSON → CLAUDE_PROJECT_DIR → pwd ──
BASE_DIR="$CWD_JSON"
if [ -z "$BASE_DIR" ] || [ ! -d "$BASE_DIR" ]; then
  BASE_DIR="${CLAUDE_PROJECT_DIR:-}"
fi
if [ -z "$BASE_DIR" ] || [ ! -d "$BASE_DIR" ]; then
  BASE_DIR=$(pwd)
fi

BRANCH=""
if [ -n "$GITDIR" ]; then
  case "$GITDIR" in
    /*) ;;
    *) GITDIR="$BASE_DIR/$GITDIR" ;;
  esac
  BRANCH=$(git --git-dir="$GITDIR" symbolic-ref -q --short HEAD 2>/dev/null)
  TARGET_DESC="--git-dir=$GITDIR"
else
  TARGET_DIR="$BASE_DIR"
  if [ -n "$CDIR" ]; then
    case "$CDIR" in
      /*) TARGET_DIR="$CDIR" ;;
      *) TARGET_DIR="$BASE_DIR/$CDIR" ;;
    esac
  fi
  BRANCH=$(git -C "$TARGET_DIR" symbolic-ref -q --short HEAD 2>/dev/null)
  TARGET_DESC="$TARGET_DIR"
fi

if [ -z "$BRANCH" ]; then
  block_branch "Branch do repositório alvo indeterminável (detached HEAD ou não é um repositório git): $TARGET_DESC."
fi

case "$BRANCH" in
  main|master) ;;
  *) block_branch "Branch atual do alvo ($TARGET_DESC): $BRANCH." ;;
esac

# ── Refs de destino: só main/master (HEAD = branch atual) ────────────────────
if [ -n "$DESTS" ]; then
  OLD_IFS="$IFS"; IFS=','
  for d in $DESTS; do
    IFS="$OLD_IFS"
    [ -n "$d" ] || continue
    [ "$d" = "HEAD" ] && d="$BRANCH"
    case "$d" in
      main|master) ;;
      *) block_branch "Ref de destino do push não é main/master: $d (estando na $BRANCH). Para tags use --tags; branch nova é decisão do usuário." ;;
    esac
  done
  IFS="$OLD_IFS"
fi

exit 0
