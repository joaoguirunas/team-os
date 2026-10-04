#!/usr/bin/env bash
# release.sh — fecha uma versão do pack team-os. SÓ DO MANTENEDOR.
#
# Uso: release.sh X.Y.Z [--dry-run] [--skip-tests]
#   X.Y.Z         nova versão (semver; não pode ser menor que a atual nem já ter tag)
#   --dry-run     mostra o que faria e NÃO altera nada (não roda os testes pesados)
#   --skip-tests  só com --dry-run: nem tenta listar os testes (uso interno de teste)
#
# O que faz, em ordem:
#   1. exige o arquivo .team-os-maintainer na raiz (sem ele: recusa);
#   2. recusa se a árvore git tiver alteração fora de VERSION, CHANGELOG.md,
#      docs/agentes.html e pack-manifest.json (o que o próprio release mexe);
#   3. recusa se não estiver na branch main, se a tag vX.Y.Z já existir ou se
#      `## [Não lançado]` do CHANGELOG estiver vazio;
#   4. grava VERSION, converte `## [Não lançado]` em `## [X.Y.Z] — AAAA-MM-DD`
#      (recriando um `## [Não lançado]` vazio acima), regera docs/agentes.html e
#      o pack-manifest.json;
#   5. roda validate-agent.sh, validate-agent.sh --skills, test-hooks.sh,
#      test-update.sh e test-propagate.sh sobre o resultado — se algo falhar,
#      devolve os 4 arquivos ao estado de antes e sai com erro;
#   6. cria o commit "release: vX.Y.Z" e a tag ANOTADA vX.Y.Z, LOCAIS;
#   7. IMPRIME o comando `git push origin main vX.Y.Z` — quem executa é você.
# Este script NUNCA dá push.
#
# Saída KEY=value (RELEASE_VERSION, RELEASE_STEP=…, RELEASE_COMMIT, RELEASE_TAG, PUSH_COMMAND, ERROR).
# Exit: 0 ok · 1 erro/recusa. Bash 3.2-safe.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../../.." && pwd)"
VER=""; DRY=0; SKIP_TESTS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY=1; shift ;;
    --skip-tests) SKIP_TESTS=1; shift ;;
    -h|--help)    sed -n '2,28p' "$0"; exit 0 ;;
    -*)           echo "ERROR=argumento desconhecido: $1"; exit 1 ;;
    *)            [ -z "$VER" ] && VER="$1" || { echo "ERROR=versão duplicada: $1"; exit 1; }; shift ;;
  esac
done

die() { echo "ERROR=$*"; exit 1; }
step() { echo "RELEASE_STEP=$*"; }

[ -n "$VER" ] || die "informe a versão: release.sh X.Y.Z [--dry-run]"
VER="${VER#v}"
printf '%s' "$VER" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || die "versão inválida '$VER' (esperado X.Y.Z)"
[ "$SKIP_TESTS" = "1" ] && [ "$DRY" != "1" ] && die "--skip-tests só vale com --dry-run"

cd "$ROOT" || die "não consegui entrar em $ROOT"

# 1. mantenedor
[ -f "$ROOT/.team-os-maintainer" ] || die "release é só do mantenedor: falta o arquivo .team-os-maintainer na raiz do pack"
command -v git >/dev/null 2>&1 || die "git não encontrado"
command -v python3 >/dev/null 2>&1 || die "python3 não encontrado"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "esta pasta não é um repositório git"
[ "$(git rev-parse --show-toplevel)" = "$ROOT" ] || die "a raiz do pack não é a raiz do repositório git"

# 3. branch / tag / versão
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[ "$BRANCH" = "main" ] || die "release só na branch main (agora: $BRANCH)"
git rev-parse -q --verify "refs/tags/v$VER" >/dev/null 2>&1 && die "a tag v$VER já existe"
CUR="$(tr -d ' \r\n' < VERSION)"
python3 - "$CUR" "$VER" <<'PY' || die "a versão $VER é menor que a atual ($CUR)"
import sys
a = tuple(int(x) for x in sys.argv[1].split("."))
b = tuple(int(x) for x in sys.argv[2].split("."))
sys.exit(0 if b >= a else 1)
PY

# 2. árvore suja fora do que o release altera
DIRTY="$(git status --porcelain --untracked-files=all | sed 's/^...//' | grep -vE '^(VERSION|CHANGELOG\.md|docs/agentes\.html|pack-manifest\.json)$' || true)"
if [ -n "$DIRTY" ]; then
  echo "$DIRTY" | while IFS= read -r l; do echo "DIRTY=$l"; done
  die "há alterações não commitadas fora de VERSION/CHANGELOG.md/docs/agentes.html/pack-manifest.json — commite ou descarte antes do release"
fi

# CHANGELOG: [Não lançado] precisa ter conteúdo
python3 - "$VER" <<'PY' || exit 1
import re, sys
ver = sys.argv[1]
t = open("CHANGELOG.md", encoding="utf-8").read()
if re.search(r"^## \[" + re.escape(ver) + r"\]", t, re.M):
    print(f"ERROR=o CHANGELOG já tem a seção [{ver}]"); sys.exit(1)
m = re.search(r"^## \[Não lançado\][^\n]*\n(.*?)(?=^## \[|\Z)", t, re.M | re.S)
if not m:
    print("ERROR=CHANGELOG.md não tem a seção '## [Não lançado]'"); sys.exit(1)
if not re.sub(r"^###[^\n]*$", "", m.group(1), flags=re.M).strip():
    print("ERROR=a seção [Não lançado] do CHANGELOG está vazia — registre o que mudou antes do release"); sys.exit(1)
PY

TODAY="$(date +%Y-%m-%d)"
echo "RELEASE_VERSION=$VER"
echo "RELEASE_FROM=$CUR"
echo "RELEASE_DATE=$TODAY"

if [ "$DRY" = "1" ]; then
  echo "DRY_RUN=1"
  step "gravaria VERSION: $CUR -> $VER"
  step "converteria '## [Não lançado]' em '## [$VER] — $TODAY' e recriaria '## [Não lançado]' vazio"
  step "regeraria docs/agentes.html e pack-manifest.json"
  if [ "$SKIP_TESTS" != "1" ]; then
    step "rodaria: validate-agent.sh · validate-agent.sh --skills · test-hooks.sh · test-update.sh · test-propagate.sh"
  fi
  step "criaria o commit 'release: v$VER' e a tag anotada v$VER (locais)"
  echo "PUSH_COMMAND=git push origin main v$VER"
  echo "NOTE=dry-run: nada foi alterado. Este script nunca dá push."
  exit 0
fi

# 4. aplica (com backup para voltar atrás se algo falhar)
BK="$(mktemp -d "${TMPDIR:-/tmp}/team-os-release.XXXXXX")" || die "não consegui criar pasta temporária"
FILES="VERSION CHANGELOG.md docs/agentes.html pack-manifest.json"
for f in $FILES; do
  mkdir -p "$BK/$(dirname "$f")"
  [ -f "$f" ] && cp -p "$f" "$BK/$f"
done
restore() {
  for f in $FILES; do
    if [ -f "$BK/$f" ]; then cp -p "$BK/$f" "$f"; fi
  done
  echo "RELEASE_ROLLBACK=1"
}
fail() { echo "ERROR=$*"; restore; echo "BACKUP_DIR=$BK"; exit 1; }

step "gravando VERSION e CHANGELOG"
printf '%s\n' "$VER" > VERSION
python3 - "$VER" "$TODAY" <<'PY' || fail "não consegui converter o CHANGELOG"
import re, sys
ver, today = sys.argv[1], sys.argv[2]
t = open("CHANGELOG.md", encoding="utf-8").read()
t2, n = re.subn(r"^## \[Não lançado\][^\n]*\n", f"## [Não lançado]\n\n## [{ver}] — {today}\n", t, count=1, flags=re.M)
if n != 1:
    sys.exit(1)
open("CHANGELOG.md", "w", encoding="utf-8").write(t2)
PY

step "regerando docs/agentes.html e pack-manifest.json"
python3 "$HERE/generate-agents-page.py" >/dev/null || fail "generate-agents-page.py falhou"
bash "$HERE/pack-manifest.sh" >/dev/null || fail "pack-manifest.sh falhou"
bash "$HERE/pack-manifest.sh" --check >/dev/null || fail "pack-manifest.sh --check não fechou"

# 5. verificações sobre o resultado
if [ "$SKIP_TESTS" != "1" ]; then
  run_check() {
    local label="$1"; shift
    step "rodando $label"
    "$@" >"$BK/out.txt" 2>&1 || { tail -20 "$BK/out.txt"; fail "falhou: $label"; }
  }
  run_check "validate-agent.sh"            bash "$HERE/validate-agent.sh"
  run_check "validate-agent.sh --skills"   bash "$HERE/validate-agent.sh" --skills
  run_check "test-hooks.sh"                bash "$HERE/test-hooks.sh"
  run_check "test-update.sh"               bash "$HERE/test-update.sh"
  run_check "test-propagate.sh"            bash "$HERE/test-propagate.sh"
  # os testes não podem ter mexido nos arquivos do release
  bash "$HERE/pack-manifest.sh" --check >/dev/null || fail "o manifest ficou desatualizado depois dos testes"
fi

# 6. commit + tag anotada, locais
step "criando commit e tag locais"
git add -- $FILES || fail "git add falhou"
git commit -q -m "release: v$VER" -- $FILES || fail "git commit falhou (confira user.name/user.email do git)"
git tag -a "v$VER" -m "team-os v$VER" || { echo "ERROR=commit criado mas a tag falhou — crie com: git tag -a v$VER -m 'team-os v$VER'"; exit 1; }
rm -rf "$BK"

echo "RELEASE_COMMIT=$(git rev-parse --short HEAD)"
echo "RELEASE_TAG=v$VER"
echo "PUSH_COMMAND=git push origin main v$VER"
echo "NOTE=commit e tag criados só nesta máquina. O push é seu: rode o PUSH_COMMAND acima quando quiser publicar. Este script nunca dá push."
exit 0
