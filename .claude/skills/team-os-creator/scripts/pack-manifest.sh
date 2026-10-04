#!/usr/bin/env bash
# pack-manifest.sh — gera (ou confere) o pack-manifest.json na raiz do CT.
#
# O manifest diz QUAIS arquivos são do pack e o sha256 de cada um. É a base do
# `*update`: tudo que NÃO está nele é do usuário e nunca é tocado.
#
# Uso: pack-manifest.sh [--check] [--root <pasta>] [--upstream <url>]
#   (sem flag)   gera/atualiza <raiz>/pack-manifest.json (só reescreve se algo mudou)
#   --check      só confere: exit 0 se em dia, 1 se desatualizado (lista as diferenças)
#   --root       raiz do pack (padrão: 4 pastas acima deste script)
#   --upstream   URL do repositório oficial (padrão: a do manifest atual, ou
#                https://github.com/joaoguirunas/team-os)
#
# Saída KEY=value: MANIFEST=written|unchanged|ok|stale · VERSION= · FILES= ·
#   MANIFEST_DIFF=+<path> (novo) / -<path> (sumiu) / ~<path> (mudou) / version / upstream
#
# Do pack (exatamente):
#   .claude/agents/*.md                (exceto agentes com `origin: custom` no frontmatter)
#   .claude/skills/**                  (exceto presets/custom/ e lixo de runtime: .venv,
#                                       ms-playwright, runtime-state.json, __pycache__,
#                                       *.pyc, .DS_Store, Icon?, *.new)
#   .claude/hooks/*.sh
#   README.md CHANGELOG.md CLAUDE.md CONTRIBUTING.md LICENSE THIRD_PARTY_NOTICES.md VERSION
# sha256 via python3 hashlib (igual no macOS e no Linux). Bash 3.2-safe.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../../.." && pwd)"
MODE="write"
UPSTREAM=""

while [ $# -gt 0 ]; do
  case "$1" in
    --check)    MODE="check"; shift ;;
    --root)     [ $# -ge 2 ] || { echo "ERROR=--root exige um valor" >&2; exit 1; }; ROOT="$(cd "$2" && pwd)" || exit 1; shift 2 ;;
    --upstream) [ $# -ge 2 ] || { echo "ERROR=--upstream exige um valor" >&2; exit 1; }; UPSTREAM="$2"; shift 2 ;;
    -h|--help)  sed -n '2,25p' "$0"; exit 0 ;;
    *)          echo "ERROR=argumento desconhecido: $1" >&2; exit 1 ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "ERROR=python3 não encontrado (necessário para o sha256 portável)" >&2; exit 1; }
[ -f "$ROOT/VERSION" ] || { echo "ERROR=arquivo VERSION não encontrado em $ROOT" >&2; exit 1; }

PM_ROOT="$ROOT" PM_MODE="$MODE" PM_UPSTREAM="$UPSTREAM" python3 - <<'PYEOF'
import hashlib, json, os, re, sys, datetime

root = os.environ["PM_ROOT"]
mode = os.environ["PM_MODE"]
upstream_arg = os.environ.get("PM_UPSTREAM", "")
DEFAULT_UPSTREAM = "https://github.com/joaoguirunas/team-os"
DOCS = ["README.md", "CHANGELOG.md", "CLAUDE.md", "CONTRIBUTING.md", "LICENSE",
        "THIRD_PARTY_NOTICES.md", "VERSION"]
JUNK_DIRS = {".venv", "ms-playwright", "__pycache__", "node_modules"}
CUSTOM_PRESETS = ".claude/skills/team-os-creator/presets/custom/"
out = os.path.join(root, "pack-manifest.json")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def junk_file(name):
    return (name == ".DS_Store" or name == "runtime-state.json" or name.endswith(".pyc")
            or name.endswith(".new") or name == "Icon\r")


def is_custom_agent(path):
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read(4096)
    except OSError:
        return False
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    return bool(m and re.search(r"^origin:\s*custom\s*$", m.group(1), re.M))


files = {}
adir = os.path.join(root, ".claude", "agents")
if os.path.isdir(adir):
    for n in sorted(os.listdir(adir)):
        p = os.path.join(adir, n)
        if n.endswith(".md") and os.path.isfile(p) and not os.path.islink(p) and not is_custom_agent(p):
            files[".claude/agents/" + n] = sha256(p)

sdir = os.path.join(root, ".claude", "skills")
for dp, dns, fns in os.walk(sdir):
    dns[:] = sorted(d for d in dns if d not in JUNK_DIRS)
    for n in sorted(fns):
        p = os.path.join(dp, n)
        rel = os.path.relpath(p, root).replace(os.sep, "/")
        if rel.startswith(CUSTOM_PRESETS) or junk_file(n) or os.path.islink(p) or not os.path.isfile(p):
            continue
        files[rel] = sha256(p)

hdir = os.path.join(root, ".claude", "hooks")
if os.path.isdir(hdir):
    for n in sorted(os.listdir(hdir)):
        p = os.path.join(hdir, n)
        if n.endswith(".sh") and os.path.isfile(p) and not os.path.islink(p):
            files[".claude/hooks/" + n] = sha256(p)

for d in DOCS:
    p = os.path.join(root, d)
    if os.path.isfile(p):
        files[d] = sha256(p)

version = open(os.path.join(root, "VERSION"), encoding="utf-8").read().strip()
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    print(f"ERROR=VERSION inválido: '{version}' (esperado X.Y.Z)", file=sys.stderr)
    sys.exit(1)

old = None
if os.path.isfile(out):
    try:
        old = json.load(open(out, encoding="utf-8"))
    except Exception:
        old = None
upstream = upstream_arg or (old or {}).get("upstream") or DEFAULT_UPSTREAM

files = dict(sorted(files.items()))
print(f"VERSION={version}")
print(f"FILES={len(files)}")

same = (old is not None and old.get("name") == "team-os" and old.get("version") == version
        and old.get("upstream") == upstream and old.get("files") == files)

if mode == "check":
    if same:
        print("MANIFEST=ok")
        sys.exit(0)
    print("MANIFEST=stale")
    if old is None:
        print("MANIFEST_DIFF=pack-manifest.json ausente ou ilegível")
    else:
        of = old.get("files", {})
        if old.get("version") != version:
            print(f"MANIFEST_DIFF=version {old.get('version')} → {version}")
        if old.get("upstream") != upstream:
            print(f"MANIFEST_DIFF=upstream {old.get('upstream')} → {upstream}")
        for k in sorted(set(of) | set(files)):
            if k not in of:
                print(f"MANIFEST_DIFF=+{k}")
            elif k not in files:
                print(f"MANIFEST_DIFF=-{k}")
            elif of[k] != files[k]:
                print(f"MANIFEST_DIFF=~{k}")
    print("HINT=rode: bash .claude/skills/team-os-creator/scripts/pack-manifest.sh", file=sys.stderr)
    sys.exit(1)

if same:
    print("MANIFEST=unchanged")
    sys.exit(0)

data = {
    "name": "team-os",
    "version": version,
    "upstream": upstream,
    "generated": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "files": files,
}
tmp = out + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=1)
    f.write("\n")
os.replace(tmp, out)
print("MANIFEST=written")
PYEOF
