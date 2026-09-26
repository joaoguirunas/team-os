#!/usr/bin/env bash
# .claude/hooks/guard-smart-memory-read.sh
# PreToolUse hook (matcher "Read|Bash") — garantia dura do protocolo "buscar em vez de ler"
# da smart-memory (L0 → L1 → L2). Registrado no .claude/settings.json pelo ensure-settings.sh.
#
# O que BLOQUEIA (exit 2 + motivo em stderr):
#   (a) qualquer leitura de docs/smart-memory/_archive/** — Read (file_path) ou Bash com
#       cat|head|tail|less|more|sed -n|awk|bat sobre esse path (o arquivo morto nunca é lido);
#   (b) leitura de PASTA INTEIRA da smart-memory via Bash: glob (`cat docs/smart-memory/*`,
#       `cat docs/smart-memory/**/*.md`), diretório como alvo de leitor, `find docs/smart-memory
#       -exec cat|head|…`, `find … | xargs cat`, e `grep -r`/`rg` SEM `-l`/`-c`/`-q` sobre uma
#       pasta de docs/smart-memory (`grep -rl`/`-c`/`-q` é busca → permitido);
#   (c) orçamento L2: leituras (Read ou leitor no Bash) de notas de docs/smart-memory/** que NÃO
#       são L0 contam num contador por sessão em ${TMPDIR:-/tmp}/team-os-l2-<session_id>.count
#       (uma linha por nota distinta — reler a mesma nota não conta de novo). A partir da
#       (TEAM_OS_L2_BUDGET + 1)-ésima nota distinta (default 3 → a 4ª) BLOQUEIA.
#       Um Bash cujo comando contenha `sm-find.sh` ZERA o contador (o resto do comando continua
#       sujeito a (a) e (b)). Sem session_id no JSON → não conta.
#
# L0 (não conta no orçamento): INDEX.md · qualquer DIGEST.md · stories/active/*.md ·
#   stories/BACKLOG.md · _inbox/* · project/*.md · _session/* (ledger do lead) · stories/done/LEDGER.md
#
# Paths podem vir absolutos (/x/y/docs/smart-memory/...) ou relativos (./docs/smart-memory/...):
# tudo é normalizado para o trecho depois de `docs/smart-memory/`. Escrever na smart-memory
# (`cat > docs/smart-memory/x.md <<EOF`) não é leitura: alvo de redirecionamento e corpo de
# heredoc são ignorados. grep sem -r sobre arquivo(s) imprime só as linhas que casam → permitido.
#
# Knobs (env): TEAM_OS_L2_BUDGET (default 3).
# Defensivo: JSON inválido, payload sem tool_input reconhecível → exit 0 (nunca quebra o fluxo).
# bash 3.2-safe. python3 no caminho principal; fallback em grep/sed cobre (a), (b) e o contador
# de Read se o python3 faltar/falhar (aviso ⚠️ em stderr).

INPUT=$(cat)
BUDGET="${TEAM_OS_L2_BUDGET:-3}"
case "$BUDGET" in ''|*[!0-9]*) BUDGET=3 ;; esac
TMPD="${TMPDIR:-/tmp}"
TMPD="${TMPD%/}"

block_archive() {
  echo "🚫 BLOQUEADO: \`docs/smart-memory/_archive/\` nunca é lido." >&2
  echo "" >&2
  echo "Motivo: $1" >&2
  echo "" >&2
  echo "O arquivo morto está fora do working set por design (é o ponto da compactação)." >&2
  echo "O que importa dele sobrevive no DIGEST.md da área e nos LEDGERs. Se precisa de um fato" >&2
  echo "antigo, busque com sm-find.sh e leia a nota viva que o cita — não o _archive/." >&2
  exit 2
}

block_folder() {
  echo "🚫 BLOQUEADO: leitura de pasta inteira da smart-memory." >&2
  echo "" >&2
  echo "Motivo: $1" >&2
  echo "" >&2
  echo "Protocolo: L0 = INDEX.md + DIGEST.md da área + stories/active/ · L1 = buscar com" >&2
  echo "  bash \"\$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/sm-find.sh\" \"<termo>\"" >&2
  echo "L2 = abrir a nota inteira SÓ com summary confirmando (máx ${BUDGET} por tarefa)." >&2
  echo "grep -l / grep -rl (só nomes de arquivo) continuam permitidos — é busca, não leitura." >&2
  exit 2
}

block_budget() {
  echo "🚫 BLOQUEADO: orçamento L2 (${BUDGET} notas) estourado — rode sm-find.sh para escolher; o contador zera quando o sm-find roda." >&2
  echo "" >&2
  echo "Motivo: $1" >&2
  echo "" >&2
  echo "  bash \"\$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/sm-find.sh\" \"<termo>\"" >&2
  echo "devolve path / kind / status / summary sem abrir nota. Escolha pelo summary e leia só" >&2
  echo "o que confirmar relevância. (L0 — INDEX, DIGESTs, stories ativas, _inbox, project — não conta.)" >&2
  exit 2
}

# ── Caminho principal: análise com python3 ───────────────────────────────────
# O programa vive num heredoc com delimitador entre aspas lido por `read -d ''` (sem expansão,
# sem conflito de aspas, sem o parse frágil de heredoc dentro de $( ) no bash 3.2); o JSON do
# hook entra por stdin.
GSM_PY=""
IFS= read -r -d '' GSM_PY <<'GSM_PY_EOF'
import sys, os, re, json, shlex

try:
    data = json.load(sys.stdin)
except Exception:
    print("NOPARSE"); sys.exit(0)
if not isinstance(data, dict):
    print("OK"); sys.exit(0)

tool = data.get("tool_name", "") or ""
ti = data.get("tool_input", {}) or {}
if not isinstance(ti, dict):
    ti = {}
sid = data.get("session_id", "") or ""
if not isinstance(sid, str):
    sid = ""
sid = re.sub(r"[^A-Za-z0-9_.-]", "", sid)[:80]
try:
    budget = int(os.environ.get("GSM_BUDGET", "3") or "3")
except ValueError:
    budget = 3
tmpd = os.environ.get("GSM_TMP", "/tmp")
counter = os.path.join(tmpd, "team-os-l2-%s.count" % sid) if sid else ""
cwd = data.get("cwd", "") or os.environ.get("CLAUDE_PROJECT_DIR", "") or os.getcwd()
if not isinstance(cwd, str):
    cwd = os.getcwd()

SM = "docs/smart-memory/"
READERS = {"cat", "head", "tail", "less", "more", "bat", "batcat", "awk", "gawk", "nawk", "mawk",
           "tac", "nl", "strings", "view", "vim", "vi", "nano", "od", "xxd", "hexdump", "pr", "fold"}
WRAPPERS = {"command", "env", "nohup", "time", "exec", "sudo", "doas", "nice", "ionice", "timeout",
            "caffeinate", "stdbuf", "builtin", "chronic", "unbuffer"}
SEARCHERS = {"grep", "egrep", "fgrep", "rg", "ag", "ack", "git-grep"}
REDIR_OPS = {">", ">>", ">|", "&>", "&>>", "<<", "<<<", "<<-"}

def rel_of(tok):
    """Path relativo à smart-memory (o que vem depois de docs/smart-memory/) ou None."""
    if not isinstance(tok, str):
        return None
    t = tok.strip("\"\x27")
    i = t.find(SM)
    if i < 0:
        if re.search(r"(^|/)docs/smart-memory/?$", t):
            return ""  # a pasta em si
        return None
    rel = t[i + len(SM):]
    trail = rel.endswith("/")
    if rel and not any(ch in rel for ch in "*?[{$"):
        rel = os.path.normpath(rel)
        if rel == ".":
            rel = ""
        elif trail:
            rel += "/"
    return rel

def is_archive(rel):
    return rel == "_archive" or rel.startswith("_archive/")

def is_l0(rel):
    if rel in ("INDEX.md", "stories/BACKLOG.md", "stories/done/LEDGER.md"):
        return True
    if rel.rsplit("/", 1)[-1] == "DIGEST.md":
        return True
    if rel.startswith("_inbox/") or rel.startswith("_session/"):
        return True
    if re.match(r"^stories/active/[^/]+\.md$", rel):
        return True
    if re.match(r"^project/[^/]+\.md$", rel):
        return True
    return False

def is_glob(rel):
    return any(ch in rel for ch in "*?[{")

def is_dir(tok, rel):
    if rel == "" or rel.endswith("/"):
        return True
    t = tok.strip("\"\x27")
    p = t if os.path.isabs(t) else os.path.join(cwd, t)
    try:
        return os.path.isdir(os.path.expandvars(p))
    except Exception:
        return False

def looks_like_file(rel):
    return bool(re.search(r"\.[A-Za-z0-9]{1,6}$", rel.rsplit("/", 1)[-1]))

def count_l2(rel, what):
    """Orçamento L2. Devolve None (ok) ou o veredito de bloqueio."""
    if not counter:
        return None
    seen = []
    try:
        with open(counter) as fh:
            seen = [l.rstrip("\n") for l in fh if l.strip()]
    except Exception:
        seen = []
    if rel in seen:
        return None
    if len(seen) >= budget:
        return "BUDGET:%d nota(s) L2 já lida(s) nesta sessão (%s); a próxima seria %s." % (
            len(seen), ", ".join(seen[-3:]), what)
    try:
        with open(counter, "a") as fh:
            fh.write(rel + "\n")
    except Exception:
        pass
    return None

# ── Read ────────────────────────────────────────────────────────────────────
if tool == "Read":
    fp = ti.get("file_path", "") or ""
    rel = rel_of(fp)
    if rel is None:
        print("OK"); sys.exit(0)
    if is_archive(rel):
        print("ARCHIVE:Read de " + fp); sys.exit(0)
    if rel == "" or rel.endswith("/") or is_l0(rel):
        print("OK"); sys.exit(0)  # Read de diretório falha sozinho; L0 não conta
    v = count_l2(rel, "Read " + rel)
    print(v if v else "OK"); sys.exit(0)

if tool != "Bash":
    print("OK"); sys.exit(0)

# ── Bash ────────────────────────────────────────────────────────────────────
raw = ti.get("command", "") or ""
if not isinstance(raw, str) or not raw.strip():
    print("OK"); sys.exit(0)

# sm-find.sh → busca L1: zera o orçamento (o resto do comando continua sendo checado)
if "sm-find.sh" in raw and counter:
    try:
        os.remove(counter)
    except Exception:
        pass

if "docs/smart-memory" not in raw:
    print("OK"); sys.exit(0)

# 1) continuação de linha; 2) corpo de heredoc fora (é dado escrito, não leitura)
text = re.sub(r"\\\r?\n", " ", raw)
kept, delim = [], None
for ln in text.split("\n"):
    if delim is not None:
        if ln.strip() == delim:
            delim = None
        continue
    kept.append(ln)
    m = re.search(r"<<-?\s*[\"\x27]?([A-Za-z_][A-Za-z0-9_]*)[\"\x27]?", ln)
    if m:
        delim = m.group(1)
text = "\n".join(kept)

def split_segments(s):
    """Divide em ; && || | & e newline FORA de aspas."""
    segs, cur, q, i = [], [], None, 0
    while i < len(s):
        c = s[i]
        if q:
            cur.append(c)
            if c == "\\" and q == "\"" and i + 1 < len(s):
                cur.append(s[i + 1]); i += 2; continue
            if c == q:
                q = None
            i += 1; continue
        if c in "\"\x27":
            q = c; cur.append(c); i += 1; continue
        if c == "\\" and i + 1 < len(s):
            cur.append(c); cur.append(s[i + 1]); i += 2; continue
        if c in ";\n|&":
            prev = cur[-1] if cur else ""
            # `>|`, `&>`, `2>&1` são redirecionamento, não separador
            if c == "|" and prev == ">":
                cur.append(c); i += 1; continue
            if c == "&" and (prev == ">" or (i + 1 < len(s) and s[i + 1] == ">")):
                cur.append(c); i += 1; continue
            segs.append("".join(cur)); cur = []
            i += 1
            while i < len(s) and s[i] in "|&":
                i += 1
            continue
        cur.append(c); i += 1
    segs.append("".join(cur))
    return [x.strip() for x in segs if x.strip()]

def toks_of(seg):
    seg = re.sub(r"[()`]", " ", seg)  # subshell / $( ) / crase → tokens soltos
    seg = seg.replace("$ ", " ")
    try:
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

def basename(tok):
    return tok.lstrip("\\").rsplit("/", 1)[-1]

def strip_wrappers(toks):
    i = 0
    while i < len(toks):
        t = toks[i]
        if not t.startswith("-") and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            i += 1; continue  # VAR=x
        if basename(t) in WRAPPERS:
            i += 1
            while i < len(toks) and (toks[i].startswith("-") or re.match(r"^[0-9.]+[smhd]?$", toks[i])):
                i += 1
            continue
        break
    return toks[i:]

def drop_redirects(args):
    """Remove alvos de redirecionamento de saída/heredoc (escrever não é ler)."""
    out, skip = [], False
    for a in args:
        if skip:
            skip = False; continue
        if a in REDIR_OPS or re.match(r"^[0-9]*(>>?|>\||&>>?)$", a):
            skip = True; continue
        if re.match(r"^[0-9]*(>>?|&>>?)\S", a) or a.startswith("<<"):
            continue
        if a == "<":
            continue  # `cat < arquivo` → o arquivo continua como alvo de leitura
        if a.startswith("<") and len(a) > 1:
            out.append(a[1:]); continue
        out.append(a)
    return out

def names_only_flag(x):
    return bool(re.match(r"^-[A-Za-z]*[lLcq][A-Za-z]*$", x)) or x in (
        "--files-with-matches", "--files-without-match", "--count", "--quiet", "--silent", "--files")

verdict = None
sm_listed = False     # algum segmento lista/encontra dentro da smart-memory (find/ls/grep -l)
xargs_reader = False  # algum segmento é `xargs <leitor>`

for seg in split_segments(text):
    toks = strip_wrappers(toks_of(seg))
    if not toks:
        continue
    prog = basename(toks[0])
    args = drop_redirects(toks[1:])
    if prog == "git" and args and args[0] == "grep":
        prog, args = "git-grep", args[1:]
    sm_args = [(a, rel_of(a)) for a in args if rel_of(a) is not None]

    if prog == "xargs":
        if any(basename(t) in READERS or basename(t) == "sed" for t in args if not t.startswith("-")):
            xargs_reader = True
        continue

    if prog == "find":
        if sm_args:
            sm_listed = True
            for i, a in enumerate(args):
                if a in ("-exec", "-execdir", "-ok", "-okdir") and i + 1 < len(args):
                    b = basename(args[i + 1])
                    if b in READERS or b == "sed":
                        verdict = "FOLDER:find sobre docs/smart-memory com -exec %s (lê tudo que encontrar)." % b
                        break
                    if b in SEARCHERS and not any(names_only_flag(x) for x in args[i + 2:]):
                        verdict = "FOLDER:find sobre docs/smart-memory com -exec %s sem -l (imprime o conteúdo de tudo que encontrar)." % b
                        break
            if not verdict and any(is_archive(rel) for _, rel in sm_args):
                verdict = "ARCHIVE:find sobre docs/smart-memory/_archive/."
        if verdict:
            break
        continue

    if prog in ("ls", "tree", "du", "wc", "stat", "file", "mv", "cp", "mkdir", "touch", "rm", "git", "tee"):
        if sm_args and prog in ("ls", "tree"):
            sm_listed = True
        continue

    if prog in SEARCHERS:
        if not sm_args:
            continue
        recursive = prog in ("rg", "ag", "ack", "git-grep")
        names_only = False
        explicit_pattern = False
        positionals = []
        if prog in ("grep", "egrep", "fgrep", "git-grep"):
            takes_value = set("efABCmdD")
        else:
            takes_value = set("efABCmgtTM")
        i = 0
        while i < len(args):
            f = args[i]
            if f == "--":
                positionals.extend(args[i + 1:]); break
            if f.startswith("--"):
                name = f.split("=", 1)[0]
                if name in ("--recursive", "--dereference-recursive"):
                    recursive = True
                if names_only_flag(name):
                    names_only = True
                if name in ("--regexp", "--file"):
                    explicit_pattern = True
                i += 1; continue
            if f.startswith("-") and len(f) > 1 and not f[1:].isdigit():
                letters = f[1:]
                if prog in ("grep", "egrep", "fgrep") and ("r" in letters or "R" in letters):
                    recursive = True
                if any(ch in letters for ch in "lLcq"):
                    names_only = True
                if "e" in letters or "f" in letters:
                    explicit_pattern = True
                if letters[-1] in takes_value:
                    i += 2; continue  # flag com valor separado (-e PAT, -A 3, -g GLOB…)
                i += 1; continue
            positionals.append(f); i += 1
        targets = positionals if explicit_pattern else positionals[1:]
        tgt = [(a, rel_of(a)) for a in targets if rel_of(a) is not None]
        if not tgt:
            continue  # "docs/smart-memory" aparece só como padrão de busca
        if names_only:
            sm_listed = True
            continue
        if any(is_archive(rel) for _, rel in tgt):
            verdict = "ARCHIVE:%s sobre docs/smart-memory/_archive/ (imprime conteúdo)." % prog
            break
        folder = any(rel == "" or rel.endswith("/") or is_dir(a, rel)
                     or (not looks_like_file(rel) and not is_glob(rel)) for a, rel in tgt)
        if recursive and folder:
            verdict = ("FOLDER:%s recursivo sobre docs/smart-memory sem -l (imprime o conteúdo de "
                       "todas as notas). Use grep -rl (só nomes) ou sm-find.sh." % prog)
            break
        continue

    is_reader = prog in READERS or (prog == "sed" and any(
        a in ("-n", "--quiet", "--silent")
        or (re.match(r"^-[A-Za-z]+$", a) and "n" in a[1:] and "i" not in a[1:])
        for a in args))
    if not is_reader:
        continue
    for a, rel in sm_args:
        if is_archive(rel):
            verdict = "ARCHIVE:%s %s" % (prog, a)
            break
        if is_glob(rel):
            verdict = "FOLDER:%s com glob (%s) — lê várias notas de uma vez." % (prog, a)
            break
        if is_dir(a, rel):
            verdict = "FOLDER:%s sobre diretório (%s)." % (prog, a)
            break
        if is_l0(rel):
            continue
        v = count_l2(rel, "%s %s" % (prog, rel))
        if v:
            verdict = v
            break
    if verdict:
        break

if not verdict and sm_listed and xargs_reader:
    verdict = "FOLDER:find/ls/grep -l sobre docs/smart-memory encadeado em xargs <leitor> (lê tudo que encontrar)."

print(verdict if verdict else "OK")
GSM_PY_EOF

VERDICT=""
if command -v python3 >/dev/null 2>&1; then
  VERDICT=$(printf '%s' "$INPUT" | GSM_BUDGET="$BUDGET" GSM_TMP="$TMPD" python3 -c "$GSM_PY" 2>&1)
  case "$VERDICT" in
    ARCHIVE:*) block_archive "${VERDICT#ARCHIVE:}" ;;
    FOLDER:*)  block_folder  "${VERDICT#FOLDER:}" ;;
    BUDGET:*)  block_budget  "${VERDICT#BUDGET:}" ;;
    OK|NOPARSE) exit 0 ;;
    *) echo "⚠️ guard-smart-memory-read.sh: python3 falhou (${VERDICT:-sem saída}) — usando fallback grep." >&2 ;;
  esac
fi

# ── Fallback sem python3 (grep/sed) ──────────────────────────────────────────
# Cobre: (a) _archive por Read e por leitor no Bash; (b) glob/pasta e grep -r sem -l;
# (c) contador só para Read (o parse de Bash sem shlex seria frágil demais).
json_str() { # $1=chave → valor da string (sem unescape completo; suficiente para paths)
  printf '%s' "$INPUT" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" \
    | head -1 | sed -E "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"$//"
}
TOOL="$(json_str tool_name)"
SID="$(json_str session_id | tr -cd 'A-Za-z0-9_.-' | cut -c1-80)"

if [ "$TOOL" = "Read" ]; then
  FP="$(json_str file_path)"
  case "$FP" in
    *docs/smart-memory/_archive/*|*docs/smart-memory/_archive) block_archive "Read de $FP (fallback)" ;;
    *docs/smart-memory/*)
      REL="${FP#*docs/smart-memory/}"
      REL="${REL#./}"
      case "$REL" in
        INDEX.md|stories/BACKLOG.md|stories/done/LEDGER.md|*/DIGEST.md|DIGEST.md|_inbox/*|_session/*) exit 0 ;;
        project/*.md) case "${REL#project/}" in */*) : ;; *) exit 0 ;; esac ;;
        stories/active/*.md) case "${REL#stories/active/}" in */*) : ;; *) exit 0 ;; esac ;;
      esac
      [ -n "$SID" ] || exit 0
      CF="$TMPD/team-os-l2-$SID.count"
      if [ -f "$CF" ] && grep -qxF -- "$REL" "$CF"; then exit 0; fi
      N=0; [ -f "$CF" ] && N="$(grep -c . "$CF" | tr -d ' ')"
      if [ "${N:-0}" -ge "$BUDGET" ]; then block_budget "$N nota(s) L2 já lida(s) nesta sessão (fallback)"; fi
      printf '%s\n' "$REL" >> "$CF"
      exit 0 ;;
  esac
  exit 0
fi

[ "$TOOL" = "Bash" ] || exit 0
CMD="$(json_str command | sed 's/\\n/ /g; s/\\"/"/g')"
case "$CMD" in *sm-find.sh*) [ -n "$SID" ] && rm -f "$TMPD/team-os-l2-$SID.count" ;; esac
case "$CMD" in *docs/smart-memory*) : ;; *) exit 0 ;; esac
READER_RE='(^|[[:space:];&|(`])\\?(/[^[:space:]]*/)?(cat|head|tail|less|more|bat|awk|gawk|tac|nl|sed[[:space:]]+-[A-Za-z]*n)[[:space:]]'
if printf '%s' "$CMD" | grep -qE "$READER_RE" && printf '%s' "$CMD" | grep -qE 'docs/smart-memory/_archive(/|[[:space:]]|$)'; then
  block_archive "leitor sobre docs/smart-memory/_archive/ (fallback)"
fi
if printf '%s' "$CMD" | grep -qE "$READER_RE" && printf '%s' "$CMD" | grep -qE 'docs/smart-memory[^[:space:]]*[*?[]'; then
  block_folder "leitor com glob sobre docs/smart-memory (fallback)"
fi
if printf '%s' "$CMD" | grep -qE "$READER_RE" && printf '%s' "$CMD" | grep -qE 'docs/smart-memory(/[^[:space:]]*)?/([[:space:]]|$)|docs/smart-memory([[:space:]]|$)'; then
  block_folder "leitor sobre diretório da smart-memory (fallback)"
fi
if printf '%s' "$CMD" | grep -qE '(^|[[:space:];&|(`])find[[:space:]][^;&|]*docs/smart-memory[^;&|]*-(exec|execdir|ok|okdir)[[:space:]]+(cat|head|tail|less|more|sed|awk)' ; then
  block_folder "find -exec <leitor> sobre docs/smart-memory (fallback)"
fi
if printf '%s' "$CMD" | grep -qE '(^|[[:space:];&|(`])(grep|egrep|fgrep)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-[A-Za-z]*[rR]' \
  && printf '%s' "$CMD" | grep -qE '(grep|egrep|fgrep)[^;&|]*docs/smart-memory' \
  && ! printf '%s' "$CMD" | grep -qE '(grep|egrep|fgrep)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-[A-Za-z]*[lLcq]|--files-with-matches|--files-without-match|--count|--quiet)'; then
  block_folder "grep -r sem -l sobre docs/smart-memory (fallback)"
fi
exit 0
