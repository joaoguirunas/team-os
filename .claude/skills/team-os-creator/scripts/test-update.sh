#!/usr/bin/env bash
# test-update.sh — teste hermético do `*update` (update-pack.sh + pack-manifest.sh + trash.sh).
#
# Tudo acontece numa pasta temporária, com HOME e TMPDIR falsos (a Lixeira e o ~/.claude
# reais nunca são tocados). O "upstream" é um repositório git local (file://) com as tags
# v1.0.0, v1.1.0 e v1.2.0 de um pack de brinquedo — os scripts do pack são os REAIS deste CT.
#
# Cenários: sem installed.json · --check não grava nada · pulo de 2 versões · agente do pack
# editado pelo usuário (conflito, não perde) · agente próprio intacto (só o bloco NTP muda) ·
# skill/preset próprios intocados · arquivo novo · arquivo removido · bit de execução ·
# .gitignore · --undo · resolução keep/new (+ undo do new) · manifest adulterado (recusa) ·
# tag com versão errada (recusa) · sem git (tarball) · --from · clone git do usuário intacto
# (HEAD e índice) · guarda só 3 backups · trava do mantenedor · --status.
#
# Uso: bash test-update.sh   (exit 0 = tudo passou). Bash 3.2-safe; precisa de git, python3, tar.

set -u

SRC_SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ORIG_TMP="${TMPDIR:-/tmp}"
T="$(mktemp -d "$ORIG_TMP/team-os-test-update.XXXXXX")" || exit 1
# pasta temporária do próprio teste (TEAM_OS_TEST_KEEP=1 mantém para inspeção)
[ "${TEAM_OS_TEST_KEEP:-0}" = "1" ] && echo "(mantendo $T)" || trap 'rm -rf "$T"' EXIT

export HOME="$T/home"
export TMPDIR="$T/tmp"
export XDG_DATA_HOME="$T/home/.local/share"
export GIT_CONFIG_NOSYSTEM=1
export COPYFILE_DISABLE=1
mkdir -p "$HOME" "$TMPDIR"
unset TEAM_OS_ROOT TEAM_OS_NO_GIT TEAM_OS_TAGS_URL TEAM_OS_TARBALL_URL
if [ "$(uname -s)" = "Darwin" ]; then
  TRASH="$HOME/.Trash"            # trash.sh usa ~/.Trash (HOME falso)
  unset TEAM_OS_TRASH_DIR
else
  TRASH="$T/trash"                # Linux: força destino local (gio usaria a Lixeira do disco)
  export TEAM_OS_TRASH_DIR="$TRASH"
fi

PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); }
bad()  { FAIL=$((FAIL + 1)); echo "  ❌ $*"; }
check() {  # check "<descrição>" <comando...>
  local d="$1"; shift
  if "$@"; then ok; else bad "$d"; fi
}
kv() { grep -m1 "^$1=" "$2" | cut -d= -f2-; }          # kv KEY arquivo
kvc() { grep -c "^$1=" "$2" | tr -d ' '; }             # nº de linhas KEY=
h() { python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$1"; }
treehash() {  # hash de toda a árvore (nomes + conteúdo), sem .git
  (cd "$1" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do
     printf '%s %s\n' "$f" "$(h "$f")"; done) | h /dev/stdin
}
same_file() { cmp -s "$1" "$2"; }
gitq() { git -c user.name=teste -c user.email=teste@example.com -c init.defaultBranch=main "$@"; }

UP="$T/upstream"
UPURL="file://$UP"
CR=".claude/skills/team-os-creator"

# ─── pack de brinquedo, versão a versão ───────────────────────────────────────
mk_version() {  # mk_version <pasta> <versão>
  local d="$1" v="$2" ntp alpha beta skill
  case "$v" in 1.0.0) ntp=1; alpha=1; beta=1; skill=1 ;;
               1.1.0) ntp=2; alpha=2; beta=1; skill=2 ;;
               *)     ntp=3; alpha=2; beta=2; skill=2 ;; esac
  mkdir -p "$d/$CR/scripts" "$d/$CR/reference" "$d/$CR/presets" "$d/.claude/agents" \
           "$d/.claude/skills/demo-skill" "$d/.claude/hooks"
  for s in update-pack.sh update-pack.py trash.sh pack-manifest.sh migrate-ntp.sh validate-agent.sh; do
    cp "$SRC_SCRIPTS/$s" "$d/$CR/scripts/$s"
  done
  [ "$v" != "1.0.0" ] && printf '\n# fixture %s (o próprio update-pack.sh muda entre versões)\n' "$v" >> "$d/$CR/scripts/update-pack.sh"
  printf '%s\n' "$v" > "$d/VERSION"
  printf 'MIT\n' > "$d/LICENSE"
  printf '# CLAUDE do pack (igual em todas as versões)\n' > "$d/CLAUDE.md"
  printf '# README %s\n' "$v" > "$d/README.md"
  printf '.DS_Store\n' > "$d/.gitignore"
  {
    printf '# Changelog\n\n## [Não lançado]\n\n'
    [ "$v" = "1.2.0" ] && printf '## [1.2.0] — 2026-10-02\n\n- agente pk-gamma e hook added.sh\n\n'
    case "$v" in 1.1.0|1.2.0) printf '## [1.1.0] — 2026-10-01\n\n- demo-skill v2\n\n' ;; esac
    printf '## [1.0.0] — 2026-09-30\n\n- primeira versão\n'
  } > "$d/CHANGELOG.md"
  printf '# NTP canônico\n\n<!-- NTP-START -->\n## Native Teams Protocol\n\nProtocolo versão %s.\n<!-- NTP-END -->\n' "$ntp" > "$d/$CR/reference/native-teams-protocol.md"
  printf 'name: pk\ndescription: squad de teste\nagents:\n  - name: pk-alpha\n    archetype: implementer\n' > "$d/$CR/presets/pk.yaml"
  printf -- '---\nname: pk-alpha\nmemory: project\n---\n\n## Native Teams Protocol\n\nProtocolo versão %s.\n\n---\n\n# Alpha\n\nalpha rev %s\n' "$ntp" "$alpha" > "$d/.claude/agents/pk-alpha.md"
  printf -- '---\nname: pk-beta\nmemory: project\n---\n\n# Beta\n\nbeta rev %s\n' "$beta" > "$d/.claude/agents/pk-beta.md"
  printf -- '---\nname: demo-skill\ndescription: demo\nversion: "%s"\nupdated: "2026-10-01"\n---\n# demo rev %s\n' "$skill" "$skill" > "$d/.claude/skills/demo-skill/SKILL.md"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$d/.claude/hooks/demo.sh"; chmod +x "$d/.claude/hooks/demo.sh"
  if [ "$v" != "1.2.0" ]; then printf 'vai sair na 1.2.0\n' > "$d/.claude/skills/demo-skill/old.md"; fi
  if [ "$v" != "1.0.0" ]; then printf 'referência nova\n' > "$d/.claude/skills/demo-skill/new-ref.md"; fi
  if [ "$v" = "1.2.0" ]; then
    printf -- '---\nname: pk-gamma\nmemory: project\n---\n\n# Gamma\n' > "$d/.claude/agents/pk-gamma.md"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$d/.claude/hooks/added.sh"; chmod +x "$d/.claude/hooks/added.sh"
  fi
  bash "$d/$CR/scripts/pack-manifest.sh" --root "$d" --upstream "$UPURL" > "$T/pm.out" 2>&1 \
    || { echo "⛔ pack-manifest.sh falhou ao montar a fixture $v"; cat "$T/pm.out"; exit 1; }
}

echo "── montando upstream (v1.0.0, v1.1.0, v1.2.0) em pasta temporária"
mkdir -p "$UP"
gitq -C "$UP" init -q
for v in 1.0.0 1.1.0 1.2.0; do
  mk_version "$T/build-$v" "$v"
  (cd "$UP" && find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +)   # só no upstream de teste
  cp -R "$T/build-$v/." "$UP/"
  gitq -C "$UP" add -A && gitq -C "$UP" commit -q -m "release $v" && gitq -C "$UP" tag "v$v"
done

# pasta do usuário: cópia da 1.0.0 sem git (como um .zip), com coisas dele
mk_user() {  # mk_user <pasta>
  local u="$1"
  cp -R "$T/build-1.0.0" "$u"
  printf '\nMINHA EDIÇÃO no alpha\n' >> "$u/.claude/agents/pk-alpha.md"        # editado + pack muda → conflito
  printf '\nminha nota no CLAUDE.md\n' >> "$u/CLAUDE.md"                         # editado, pack não muda → mantém
  printf -- '---\nname: me-helper\nmemory: project\norigin: custom\n---\n\n## Native Teams Protocol\n\nProtocolo versão 1.\n\n---\n\n# Helper\n\nMEU CONTEÚDO PRÓPRIO\n' > "$u/.claude/agents/me-helper.md"
  mkdir -p "$u/.claude/skills/minha-skill" "$u/$CR/presets/custom"
  printf -- '---\nname: minha-skill\n---\nminha\n' > "$u/.claude/skills/minha-skill/SKILL.md"
  printf 'name: custom\nagents:\n  - name: me-helper\n    archetype: implementer\n' > "$u/$CR/presets/custom/custom.yaml"
}
up() { local u="$1"; shift; bash "$u/$CR/scripts/update-pack.sh" "$@"; }

# ═══ 1. check sem installed.json, pulo de 2 versões, não grava nada ═══════════
echo "── 1. --check (sem installed.json, 1.0.0 → 1.2.0)"
U="$T/user1"; mk_user "$U"
BEFORE="$(treehash "$U")"
up "$U" --check > "$T/c1.out" 2>&1; rc=$?
check "check exit 0 (rc=$rc)" [ $rc -eq 0 ]
check "BASELINE=manifest" [ "$(kv BASELINE "$T/c1.out")" = "manifest" ]
check "LATEST_VERSION=1.2.0" [ "$(kv LATEST_VERSION "$T/c1.out")" = "1.2.0" ]
check "UPDATE_AVAILABLE=1" [ "$(kv UPDATE_AVAILABLE "$T/c1.out")" = "1" ]
check "VERIFY=ok" [ "$(kv VERIFY "$T/c1.out")" = "ok" ]
check "CHANGELOG com 1.2.0 e 1.1.0" [ "$(kv CHANGELOG_VERSIONS "$T/c1.out")" = "1.2.0,1.1.0" ]
check "CONFLICT=pk-alpha.md" grep -qx 'CONFLICT=.claude/agents/pk-alpha.md' "$T/c1.out"
check "KEEP_EDITED=CLAUDE.md" grep -qx 'KEEP_EDITED=CLAUDE.md' "$T/c1.out"
check "REMOVE=old.md" grep -qx 'REMOVE=.claude/skills/demo-skill/old.md' "$T/c1.out"
check "ADD=pk-gamma" grep -qx 'ADD=.claude/agents/pk-gamma.md' "$T/c1.out"
check "UPDATE=pk-beta" grep -qx 'UPDATE=.claude/agents/pk-beta.md' "$T/c1.out"
check "custom agent fora da lista" sh -c "! grep -q 'me-helper' '$T/c1.out'"
check "--check não grava nada na pasta" [ "$(treehash "$U")" = "$BEFORE" ]
check "--check não cria .team-os/" [ ! -e "$U/.team-os" ]

# ═══ 2. apply ════════════════════════════════════════════════════════════════
echo "── 2. --apply --yes"
ALPHA_MINE="$(h "$U/.claude/agents/pk-alpha.md")"
CLAUDE_MINE="$(h "$U/CLAUDE.md")"
SKILL_MINE="$(h "$U/.claude/skills/minha-skill/SKILL.md")"
PRESET_MINE="$(h "$U/$CR/presets/custom/custom.yaml")"
up "$U" --apply > "$T/a0.out" 2>&1 </dev/null; rc=$?
check "--apply sem --yes e sem terminal recusa (rc=$rc)" [ $rc -eq 1 ]
check "recusa não altera nada" [ "$(treehash "$U")" = "$BEFORE" ]
up "$U" --apply --yes > "$T/a1.out" 2>&1; rc=$?
check "apply exit 2 (conflito pendente) (rc=$rc)" [ $rc -eq 2 ]
check "APPLIED=1" [ "$(kv APPLIED "$T/a1.out")" = "1" ]
check "VERSION=1.2.0" [ "$(cat "$U/VERSION")" = "1.2.0" ]
check "pk-alpha do usuário intacto" [ "$(h "$U/.claude/agents/pk-alpha.md")" = "$ALPHA_MINE" ]
check "pk-alpha.md.new = versão 1.2.0" same_file "$U/.claude/agents/pk-alpha.md.new" "$T/build-1.2.0/.claude/agents/pk-alpha.md"
check "CLAUDE.md do usuário intacto" [ "$(h "$U/CLAUDE.md")" = "$CLAUDE_MINE" ]
check "pk-beta atualizado" same_file "$U/.claude/agents/pk-beta.md" "$T/build-1.2.0/.claude/agents/pk-beta.md"
check "pk-gamma adicionado" same_file "$U/.claude/agents/pk-gamma.md" "$T/build-1.2.0/.claude/agents/pk-gamma.md"
check "new-ref.md adicionado" [ -f "$U/.claude/skills/demo-skill/new-ref.md" ]
check "hook novo com bit de execução" [ -x "$U/.claude/hooks/added.sh" ]
check "old.md saiu da árvore" [ ! -e "$U/.claude/skills/demo-skill/old.md" ]
check "old.md guardado em .team-os/removed/" sh -c "ls '$U'/.team-os/removed/*/.claude/skills/demo-skill/old.md >/dev/null 2>&1"
check "update-pack.sh também foi atualizado" same_file "$U/$CR/scripts/update-pack.sh" "$T/build-1.2.0/$CR/scripts/update-pack.sh"
check "skill própria intocada" [ "$(h "$U/.claude/skills/minha-skill/SKILL.md")" = "$SKILL_MINE" ]
check "preset próprio intocado" [ "$(h "$U/$CR/presets/custom/custom.yaml")" = "$PRESET_MINE" ]
check "agente próprio: conteúdo preservado" grep -q 'MEU CONTEÚDO PRÓPRIO' "$U/.claude/agents/me-helper.md"
check "agente próprio: origin: custom preservado" grep -q '^origin: custom' "$U/.claude/agents/me-helper.md"
check "agente próprio: NTP reinjetado (versão 3)" grep -q 'Protocolo versão 3' "$U/.claude/agents/me-helper.md"
check "NTP_REINJECTED=1" [ "$(kv NTP_REINJECTED "$T/a1.out")" = "1" ]
check "installed.json versão 1.2.0" python3 -c "import json,sys; d=json.load(open('$U/.team-os/installed.json')); sys.exit(0 if d['version']=='1.2.0' else 1)"
check "installed.json mantém hash antigo do conflito" python3 -c "
import json,sys
d=json.load(open('$U/.team-os/installed.json')); m=json.load(open('$T/build-1.0.0/pack-manifest.json'))
k='.claude/agents/pk-alpha.md'; sys.exit(0 if d['files'][k]==m['files'][k] and d['pending']==[k] else 1)"
check "pack-manifest.json local = 1.2.0" same_file "$U/pack-manifest.json" "$T/build-1.2.0/pack-manifest.json"
check "update-report.md escrito" grep -q 'pk-alpha.md.new' "$U/.team-os/update-report.md"
check "report sem sugestão de commit/push" sh -c "! grep -qiE 'commit|push' '$U/.team-os/update-report.md'"
check ".gitignore ganhou .team-os/" grep -qx '.team-os/' "$U/.gitignore"
check "GITIGNORE_UPDATED=1" [ "$(kv GITIGNORE_UPDATED "$T/a1.out")" = "1" ]
check "CHANGED lista o .new" grep -qx 'CHANGED=.claude/agents/pk-alpha.md.new' "$T/a1.out"
check "AUDIT informado" [ -n "$(kv AUDIT "$T/a1.out")" ]
check "backup só com arquivos trocados (sem pk-gamma)" sh -c "[ ! -e '$U'/.team-os/backups/*/files/.claude/agents/pk-gamma.md ] && [ -f '$U'/.team-os/backups/*/files/.claude/agents/pk-beta.md ]"

up "$U" --status > "$T/s1.out" 2>&1; rc=$?
check "--status exit 2 com pendência (rc=$rc)" [ $rc -eq 2 ]
check "--status PENDING_FILE" grep -qx 'PENDING_FILE=.claude/agents/pk-alpha.md' "$T/s1.out"
check "--status EDITED inclui CLAUDE.md" grep -qx 'EDITED_FILE=CLAUDE.md' "$T/s1.out"

# ═══ 3. undo ═════════════════════════════════════════════════════════════════
echo "── 3. --undo"
up "$U" --undo > "$T/u1.out" 2>&1; rc=$?
check "undo exit 0 (rc=$rc)" [ $rc -eq 0 ]
check "VERSION volta a 1.0.0" [ "$(cat "$U/VERSION")" = "1.0.0" ]
check "pk-beta volta à 1.0.0" same_file "$U/.claude/agents/pk-beta.md" "$T/build-1.0.0/.claude/agents/pk-beta.md"
check "pk-gamma (adicionado) foi para a Lixeira" sh -c "[ ! -e '$U/.claude/agents/pk-gamma.md' ] && ls '$TRASH' | grep -q '^pk-gamma.md'"
check ".new foi para a Lixeira" [ ! -e "$U/.claude/agents/pk-alpha.md.new" ]
check "old.md restaurado" same_file "$U/.claude/skills/demo-skill/old.md" "$T/build-1.0.0/.claude/skills/demo-skill/old.md"
check "agente próprio volta ao NTP 1" grep -q 'Protocolo versão 1' "$U/.claude/agents/me-helper.md"
check "pk-alpha do usuário segue intacto" [ "$(h "$U/.claude/agents/pk-alpha.md")" = "$ALPHA_MINE" ]
check "pack-manifest volta à 1.0.0" same_file "$U/pack-manifest.json" "$T/build-1.0.0/pack-manifest.json"
check "installed.json (não existia) saiu" [ ! -e "$U/.team-os/installed.json" ]

# ═══ 4. resolve keep ═════════════════════════════════════════════════════════
echo "── 4. --resolve keep"
up "$U" --apply --yes > "$T/a2.out" 2>&1
up "$U" --resolve .claude/agents/pk-alpha.md=keep > "$T/r1.out" 2>&1; rc=$?
check "resolve keep exit 0 (rc=$rc)" [ $rc -eq 0 ]
check "keep: .new saiu" [ ! -e "$U/.claude/agents/pk-alpha.md.new" ]
check "keep: o do usuário intacto" [ "$(h "$U/.claude/agents/pk-alpha.md")" = "$ALPHA_MINE" ]
up "$U" --status > "$T/s2.out" 2>&1; rc=$?
check "status sem pendência após keep (rc=$rc)" [ $rc -eq 0 ]
up "$U" --check > "$T/c2.out" 2>&1; rc=$?
check "check após keep: em dia, sem conflito (rc=$rc)" sh -c "[ $rc -eq 0 ] && grep -qx 'UPDATE_AVAILABLE=0' '$T/c2.out' && ! grep -q '^CONFLICT=' '$T/c2.out'"

# ═══ 5. resolve new + undo do resolve ════════════════════════════════════════
echo "── 5. --resolve new (+ --undo)"
U2="$T/user2"; mk_user "$U2"
up "$U2" --apply --yes > "$T/a3.out" 2>&1
up "$U2" --resolve .claude/agents/pk-alpha.md.new=new > "$T/r2.out" 2>&1; rc=$?
check "resolve new exit 0 (rc=$rc)" [ $rc -eq 0 ]
check "new: pk-alpha = 1.2.0" same_file "$U2/.claude/agents/pk-alpha.md" "$T/build-1.2.0/.claude/agents/pk-alpha.md"
check "new: o do usuário guardado no backup" sh -c "grep -l 'MINHA EDIÇÃO' '$U2'/.team-os/backups/*/files/.claude/agents/pk-alpha.md >/dev/null"
up "$U2" --undo > "$T/u2.out" 2>&1; rc=$?
check "undo do resolve exit 0 (rc=$rc)" [ $rc -eq 0 ]
check "undo do resolve: o do usuário volta" grep -q 'MINHA EDIÇÃO' "$U2/.claude/agents/pk-alpha.md"
check "undo do resolve: o novo volta a ser .new" same_file "$U2/.claude/agents/pk-alpha.md.new" "$T/build-1.2.0/.claude/agents/pk-alpha.md"
up "$U2" --status > "$T/s3.out" 2>&1; rc=$?
check "undo do resolve: pendência volta (rc=$rc)" [ $rc -eq 2 ]

# ═══ 6. manifest adulterado / tag com versão errada ══════════════════════════
echo "── 6. pacote adulterado (recusa)"
U3="$T/user3"; mk_user "$U3"
B3="$(treehash "$U3")"
cp -R "$T/build-1.2.0" "$T/tampered"
printf '\nlinha maliciosa\n' >> "$T/tampered/.claude/agents/pk-beta.md"
up "$U3" --apply --yes --from "$T/tampered" > "$T/t1.out" 2>&1; rc=$?
check "adulterado: exit 1 (rc=$rc)" [ $rc -eq 1 ]
check "adulterado: ERROR de verificação" grep -q '^ERROR=verificação falhou' "$T/t1.out"
check "adulterado: nada mudou" [ "$(treehash "$U3")" = "$B3" ]
cp -R "$T/build-1.2.0" "$T/escape"
python3 - "$T/escape/pack-manifest.json" <<'PYEOF'
import json, sys
p = sys.argv[1]; m = json.load(open(p)); m["files"]["../fora.txt"] = "0" * 64; json.dump(m, open(p, "w"))
PYEOF
up "$U3" --check --from "$T/escape" > "$T/t2.out" 2>&1; rc=$?
check "manifest com caminho para fora do pack: recusa (rc=$rc)" sh -c "[ $rc -eq 1 ] && grep -q 'fora do pack' '$T/t2.out'"
cp -R "$UP" "$T/upstream-bad"
gitq -C "$T/upstream-bad" tag v9.9.9
up "$U3" --check --upstream "file://$T/upstream-bad" > "$T/t3.out" 2>&1; rc=$?
check "tag v9.9.9 com manifest 1.2.0: recusa (rc=$rc)" sh -c "[ $rc -eq 1 ] && grep -q 'tag pedida' '$T/t3.out'"
check "recusas não mudam nada" [ "$(treehash "$U3")" = "$B3" ]

# ═══ 7. sem git (tarball) e --from ═══════════════════════════════════════════
echo "── 7. sem git (tarball + API de tags) e --from"
mkdir -p "$T/tar/src" "$T/tar/pub"
cp -R "$T/build-1.2.0" "$T/tar/src/team-os-1.2.0"
tar -C "$T/tar/src" -czf "$T/tar/pub/v1.2.0.tar.gz" team-os-1.2.0
printf '[{"name":"v1.2.0"},{"name":"v1.1.0"},{"name":"v1.0.0"},{"name":"nao-semver"}]\n' > "$T/tar/pub/tags.json"
U4="$T/user4"; mk_user "$U4"
TEAM_OS_NO_GIT=1 TEAM_OS_TAGS_URL="file://$T/tar/pub/tags.json" TEAM_OS_TARBALL_URL="file://$T/tar/pub/{tag}.tar.gz" \
  up "$U4" --apply --yes > "$T/n1.out" 2>&1; rc=$?
check "sem git: apply (rc=$rc, esperado 2)" [ $rc -eq 2 ]
check "sem git: via tarball" grep -qx 'SOURCE_KIND=tarball' "$T/n1.out"
check "sem git: VERSION=1.2.0" [ "$(cat "$U4/VERSION")" = "1.2.0" ]
check "sem git: hook com bit de execução" [ -x "$U4/.claude/hooks/added.sh" ]
U5="$T/user5"; mk_user "$U5"
up "$U5" --apply --yes --from "$T/build-1.1.0" > "$T/f1.out" 2>&1; rc=$?
check "--from 1.1.0 (rc=$rc, esperado 2)" [ $rc -eq 2 ]
check "--from: VERSION=1.1.0" [ "$(cat "$U5/VERSION")" = "1.1.0" ]
check "--from: old.md ainda existe na 1.1.0" [ -f "$U5/.claude/skills/demo-skill/old.md" ]

# ═══ 8. usuário com clone git: HEAD e índice intactos ════════════════════════
echo "── 8. clone git do usuário (sem git pull/commit/checkout)"
U6="$T/user6"
gitq clone -q --branch v1.0.0 "$UPURL" "$U6" 2>/dev/null
printf '\nMINHA EDIÇÃO\n' >> "$U6/.claude/agents/pk-alpha.md"
gitq -C "$U6" add .claude/agents/pk-alpha.md
HEAD0="$(git -C "$U6" rev-parse HEAD)"; IDX0="$(git -C "$U6" diff --cached --name-only)"
up "$U6" --apply --yes > "$T/g1.out" 2>&1; rc=$?
check "clone: apply (rc=$rc, esperado 2)" [ $rc -eq 2 ]
check "clone: HEAD não mudou" [ "$(git -C "$U6" rev-parse HEAD)" = "$HEAD0" ]
check "clone: índice não mudou" [ "$(git -C "$U6" diff --cached --name-only)" = "$IDX0" ]
check "clone: sem commit novo" [ "$(git -C "$U6" rev-list --count HEAD)" = "1" ]
check "clone: VERSION=1.2.0 no working tree" [ "$(cat "$U6/VERSION")" = "1.2.0" ]

# ═══ 9. só 3 backups; o resto na Lixeira ═════════════════════════════════════
echo "── 9. guarda 3 backups"
U7="$T/user7"; mk_user "$U7"
up "$U7" --apply --yes --to v1.1.0 > /dev/null 2>&1
up "$U7" --apply --yes --to v1.2.0 > /dev/null 2>&1
up "$U7" --apply --yes --to v1.0.0 > "$T/d1.out" 2>&1
check "downgrade marcado" grep -qx 'DOWNGRADE=1' "$T/d1.out"
up "$U7" --apply --yes > "$T/k1.out" 2>&1
NB="$(ls "$U7/.team-os/backups" | wc -l | tr -d ' ')"
check "3 backups guardados (achei $NB)" [ "$NB" = "3" ]
check "BACKUPS_TRASHED=1" [ "$(kv BACKUPS_TRASHED "$T/k1.out")" = "1" ]
check "pk-alpha do usuário intacto após 4 updates" grep -q 'MINHA EDIÇÃO no alpha' "$U7/.claude/agents/pk-alpha.md"

# ═══ 10. trava do mantenedor ═════════════════════════════════════════════════
echo "── 10. trava do mantenedor"
U8="$T/user8"; mk_user "$U8"; : > "$U8/.team-os-maintainer"
B8="$(treehash "$U8")"
up "$U8" --apply --yes > "$T/m1.out" 2>&1; rc=$?
check "mantenedor: apply recusado (rc=$rc)" sh -c "[ $rc -eq 1 ] && grep -q 'mantenedor' '$T/m1.out'"
check "mantenedor: nada mudou" [ "$(treehash "$U8")" = "$B8" ]

# ═══ 11. trash.sh ════════════════════════════════════════════════════════════
echo "── 11. trash.sh (nome repetido não sobrescreve)"
mkdir -p "$T/tt"; printf a > "$T/tt/x.txt"
bash "$SRC_SCRIPTS/trash.sh" "$T/tt/x.txt" > "$T/tr1.out"; printf b > "$T/tt/x.txt"
bash "$SRC_SCRIPTS/trash.sh" "$T/tt/x.txt" > "$T/tr2.out"
check "trash: dois x.txt na Lixeira" [ "$(ls "$TRASH" | grep -c '^x.txt')" = "2" ]
check "trash: inexistente falha" sh -c "! bash '$SRC_SCRIPTS/trash.sh' '$T/tt/nao-existe' >/dev/null"

# ═══ 12. o teste não tocou fora da pasta temporária ══════════════════════════
check "Lixeira usada é a do HOME falso/da pasta do teste" sh -c "case '$TRASH' in '$T'/*) exit 0;; esac; exit 1"

echo ""
if [ $FAIL -eq 0 ]; then
  echo "✅ test-update: $PASS/$PASS verificações passaram."
  exit 0
fi
echo "❌ test-update: $FAIL falha(s) de $((PASS + FAIL))."
exit 1
