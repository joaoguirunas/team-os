#!/usr/bin/env bash
# install-to-project.sh — instala agentes e skills do projeto fonte em um projeto destino
# Skills instaladas = união de: citadas no body dos agentes instalados (`/skill` ou skill `x`),
# team-os (sempre), --extra-skills, prefixo da squad (<squad>-*, squads lidas de presets/*.yaml), e as já presentes
# no destino (mantidas atualizadas). Copiadas se ausentes, ATUALIZADAS (arquivo por arquivo) se o
# conteúdo difere — menos o que o usuário editou no destino (vira CONFLICT, ver --on-conflict).
# Skills e arquivos extras no destino são preservados. Exclusivas do CT, nunca vão para o destino:
# team-os-creator e sala-de-controle (a Sala de Controle mora no CT; o maestri-os saiu do pack).
# --dry-run imprime a origem de cada skill (SKILL_ORIGIN=<skill>|<origem>).
# No *install, antes de qualquer escrita, um .claude/ prévio do destino é copiado para
# .claude.bak-<timestamp>/ (só fora do dry-run; o *propagate não faz backup; guarda 3, o resto vai à Lixeira). settings.json é garantido pelo
# ensure-settings.sh da team-os (merge idempotente, nunca sobrescreve valores).
# Usage: install-to-project.sh --source <path> --target <path> [options]
#
# Options:
#   --squads dev,sites,instagram        squads a instalar (default: all). Squads do pack = campo
#                                       `name:` de presets/*.yaml (presets/custom/ fora). O estúdio
#                                       `social` sem squad de plataforma (instagram, tiktok, youtube,
#                                       linkedin) instala, mas avisa: WARN=studio_without_platform
#   --extra-skills <s1,s2>              skills opt-in, fora do filtro por squad. sala-de-controle e
#                                       maestri-os são recusadas (ERROR=sala_mora_no_ct): a Sala de
#                                       Controle mora no CT. --squads none (antigo modo Sala) também.
#   --include-hooks                     copia também hooks extras (fora do pacote padrão)
#                                       (block-worktree.sh, block-git-push.sh, task-quality.sh,
#                                       check-story-progress.sh, check-social-progress.sh,
#                                       check-proposal-progress.sh, check-finance-progress.sh,
#                                       check-legal-progress.sh, guard-push-branch.sh,
#                                       guard-smart-memory-read.sh, guard-message-size.sh e
#                                       context-watch.sh são
#                                       SEMPRE instalados)
#   --with-env-guard                    hook OPCIONAL guard-env-files.sh (bloqueia escrita em .env e
#                                       lockfile): copia e registra no settings.json (ensure-settings.sh
#                                       --with-env-guard). Só com OK do usuário. Destino que já tem o
#                                       hook continua recebendo a versão nova no propagate.
#   --dry-run                           simula sem copiar nada
#   (com --match-target-squads)         agente do destino que saiu do pack (registrado ou no histórico
#                                       do CT, sem `origin: custom`) sai como ORPHAN_AGENT=<nome>|… —
#                                       nunca é removido; social-* → rode migrate-social-split.sh
#   --custom <nome1,nome2|all>          instala também agentes PRÓPRIOS do CT (`origin: custom`,
#                                       registrados em presets/custom/*.yaml), fora do filtro por
#                                       squad. Com --match-target-squads os próprios que já existem
#                                       no destino são atualizados como os do pack.
#   --on-conflict keep|new              arquivo que o usuário editou NO DESTINO e que o CT também
#                                       mudou (CONFLICT): keep = mantém o do usuário; new = usa o
#                                       novo e guarda o do usuário em .team-os/backups/<data>/.
#                                       Sem a flag: mantém e grava <arquivo>.new ao lado (pendente).
#                                       Com a flag (decisão do usuário): keep descarta o .new e não
#                                       pergunta de novo até o CT mudar esse arquivo outra vez.
#   --only <nome1,nome2>                restringe a gravação a esses agentes/skills/hooks (usado
#                                       depois que o usuário decide cada conflito)
#
# Estado do destino: .team-os/installed.json (versão do pack + sha256 de cada arquivo gravado:
# agentes, arquivos de skill e hooks) — permite saber o que o usuário editou lá. Destino sem
# installed.json (instalação antiga): sobrescreve o que difere, como antes, e grava a base
# (BASELINE_CREATED=1). Motor por arquivo: propagate-sync.py. Arquivos que o usuário criou no
# destino nunca são tocados nem apagados. Conflito não é erro: exit 0 com CONFLICT_FILES=<n> e
# uma linha CONFLICT=<caminho relativo> por arquivo.

SOURCE=""
TARGET=""
SQUADS="all"
INCLUDE_HOOKS=0
WITH_ENV_GUARD=0  # --with-env-guard: hook opcional guard-env-files.sh (copia + registra)
DRY_RUN=0
MATCH_TARGET=0   # --match-target-squads: deriva squads do que JÁ existe no destino (modo propagate)
EXTRA_SKILLS=""  # --extra-skills: opt-in fora do filtro por squad
CUSTOM=""        # --custom: agentes próprios (origin: custom) do CT a instalar (lista ou "all")
ON_CONFLICT="keep"
ON_CONFLICT_SET=0  # 1 = --on-conflict veio explícito (decisão do usuário)
ONLY=""          # --only: restringe a gravação a estes agentes/skills/hooks
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Skills exclusivas do CT: nunca copiadas para projeto (nem por --extra-skills, nem se já presentes).
CT_ONLY_SKILLS="team-os-creator sala-de-controle"
# Skills de Sala de Controle de versões antigas do pack (pasta de Sala separada). maestri-os saiu do pack.
LEGACY_CR_SKILLS="sala-de-controle maestri-os"
SALA_MSG="A Sala de Controle agora mora no Centro de Treinamento: abra uma sessão no CT e rode /sala-de-controle. Pasta de Sala antiga? migrate-sala-to-ct.sh"

# Squads do pack — derivadas do campo `name:` de cada presets/*.yaml (presets/custom/ fica de
# fora: agente próprio segue a regra do prefixo, mas não vira squad do pack). Sem presets
# legíveis, cai na lista fixa abaixo (fallback seguro). Nunca escreva a lista à mão em outro lugar.
PACK_SQUADS_FALLBACK="dev sites social instagram tiktok youtube linkedin traffic pm sales brand finance legal seo security"
# Squads de PLATAFORMA social: dão gate (estrategista) e publicação ao estúdio `social`.
PLATFORM_SQUADS="instagram tiktok youtube linkedin"
pack_squads() { # $1=raiz do CT → squads separadas por espaço
  local out="" y n
  for y in "$1/.claude/skills/team-os-creator/presets/"*.yaml; do
    [ -f "$y" ] || continue
    n=$(sed -n 's/^name:[[:space:]]*["'\'']\{0,1\}\([a-z][a-z0-9]*\)["'\'']\{0,1\}[[:space:]]*$/\1/p' "$y" | head -1)
    [ -n "$n" ] && case " $out " in *" $n "*) ;; *) out="$out $n" ;; esac
  done
  if [ -n "$out" ]; then echo "${out# }"; else echo "$PACK_SQUADS_FALLBACK"; fi
}
in_list() { case " $2 " in *" $1 "*) return 0 ;; esac; return 1; }
has_legacy_cr_skill() { # $1=pasta — tem alguma skill de Sala antiga (sala-de-controle/maestri-os)?
  for crs in $LEGACY_CR_SKILLS; do [ -d "$1/.claude/skills/$crs" ] && return 0; done; return 1
}

need_value() { # $1=flag — aborta se a flag veio sem valor (evita loop infinito do shift 2)
  if [ $# -lt 2 ] || [ -z "$2" ]; then
    echo "ERROR=missing_value|FLAG=$1 exige um valor" >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)       need_value "$1" "${2:-}"; SOURCE="$2";   shift 2 ;;
    --target)       need_value "$1" "${2:-}"; TARGET="$2";   shift 2 ;;
    --squads)       need_value "$1" "${2:-}"; SQUADS="$2";   shift 2 ;;
    --extra-skills) need_value "$1" "${2:-}"; EXTRA_SKILLS="$2"; shift 2 ;;
    --custom)       need_value "$1" "${2:-}"; CUSTOM="$2";   shift 2 ;;
    --only)         need_value "$1" "${2:-}"; ONLY="$2";     shift 2 ;;
    --on-conflict)  need_value "$1" "${2:-}"
                    case "$2" in keep|new) ;; *) echo "ERROR=invalid_on_conflict|use keep ou new (veio: $2)" >&2; exit 2 ;; esac
                    ON_CONFLICT="$2"; ON_CONFLICT_SET=1; shift 2 ;;
    --match-target-squads) MATCH_TARGET=1; shift ;;
    --include-hooks)  INCLUDE_HOOKS=1;  shift ;;
    --with-env-guard) WITH_ENV_GUARD=1; shift ;;
    --dry-run)      DRY_RUN=1;     shift ;;
    --include-skills) shift ;;  # ignorado — skills são sempre incluídas
    *)
      echo "ERROR=unknown_flag|FLAG=$1" >&2
      echo "Usage: install-to-project.sh --source <path> --target <path> [--squads <lista> | --match-target-squads] [--custom <nomes|all>] [--on-conflict keep|new] [--only <nomes>] [--include-hooks] [--with-env-guard] [--dry-run]" >&2
      exit 2 ;;
  esac
done

# A Sala de Controle mora no CT: --extra-skills de Sala e --squads none (antigo modo Sala) são recusados.
sala_refuse() {
  echo "ERROR=sala_mora_no_ct|$SALA_MSG"
  echo "$SALA_MSG" >&2
  exit 1
}
[ "$SQUADS" = "none" ] && sala_refuse
for es in $(echo "$EXTRA_SKILLS" | tr ',' ' '); do
  in_list "$es" "$LEGACY_CR_SKILLS" && sala_refuse
done

# Defaults
if [ -z "$SOURCE" ]; then
  SOURCE=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

if [ -z "$TARGET" ]; then
  echo "ERROR=missing_target"
  exit 1
fi

SOURCE=$(cd "$SOURCE" && pwd)
TARGET=$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")

SOURCE_NAME=$(basename "$SOURCE")
TARGET_NAME=$(basename "$TARGET")

if [ "$SOURCE" = "$TARGET" ]; then
  echo "ERROR=same_path|SOURCE=$SOURCE_NAME|TARGET=$TARGET_NAME"
  exit 1
fi

if [ ! -d "$SOURCE/.claude/agents" ]; then
  echo "ERROR=no_source_agents|SOURCE=$SOURCE_NAME"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR=python3_missing|instale o Python 3 — ele confere arquivo por arquivo para não perder edições do destino"
  exit 1
fi
SYNC_PY="$SCRIPT_DIR/propagate-sync.py"
[ -f "$SYNC_PY" ] || { echo "ERROR=propagate_sync_missing|$SYNC_PY"; exit 1; }

# O destino não pode ser outra cópia do pack (lá o .team-os/ é do *update)
if [ -f "$TARGET/pack-manifest.json" ] && grep -q '"name": *"team-os"' "$TARGET/pack-manifest.json" 2>/dev/null; then
  echo "ERROR=target_is_pack|$TARGET_NAME é uma cópia do pack team-os — para atualizá-la use /team-os-creator *update lá dentro"
  exit 1
fi

PACK_VERSION="$(sed -n '1p' "$SOURCE/VERSION" 2>/dev/null | tr -d '[:space:]')"
[ -n "$PACK_VERSION" ] || PACK_VERSION="desconhecida"

# Agente próprio do usuário (frontmatter com `origin: custom`)
is_custom_agent() {
  awk 'NR==1 && $0!="---"{exit 1} NR>1 && $0=="---"{exit 1} /^origin:[[:space:]]*custom[[:space:]]*$/{f=1; exit 0} END{exit f?0:1}' "$1" 2>/dev/null
}
in_csv() { # $1=item $2=csv
  case ",$2," in *",$1,"*) return 0 ;; esac; return 1
}

# Modo propagate: deriva as squads a sincronizar a partir do que JÁ existe no destino.
# Garante que squads podadas (não instaladas) nunca sejam re-adicionadas.
if [ $MATCH_TARGET -eq 1 ]; then
  # Zera o default "all" ANTES de derivar: destino sem .claude/agents/ (ou derivação
  # vazia) tem que virar __none__ — nunca cair no "all" e instalar tudo.
  SQUADS=""
  if [ -d "$TARGET/.claude/agents" ]; then
    SQUADS=$(find "$TARGET/.claude/agents" -maxdepth 1 -name '*.md' -type f -exec basename {} .md \; 2>/dev/null \
      | sed 's/-.*//' | sort -u | tr '\n' ',' | sed 's/,$//')
  fi
  [ -z "$SQUADS" ] && SQUADS="__none__"   # destino sem agentes → não sincroniza nenhum
  echo "MATCH_TARGET_SQUADS=$SQUADS"
  if [ "$SQUADS" = "__none__" ]; then
    if has_legacy_cr_skill "$TARGET"; then
      # Pasta de Sala de Controle antiga (skill de Sala, nenhum agente): a Sala agora mora no CT.
      # Não atualiza nada — só avisa e sugere a migração (dry-run primeiro; nada muda sem OK).
      echo "LEGACY_CONTROL_ROOM=1|$TARGET_NAME é uma pasta de Sala de Controle antiga — nada foi atualizado. $SALA_MSG"
      echo "NEXT=bash \"$SOURCE/.claude/skills/team-os-creator/scripts/migrate-sala-to-ct.sh\" \"$TARGET\""
      exit 0
    fi
    # Destino sem nenhum agente = team-os não instalado → propagate não tem o que
    # sincronizar (nem skills). Instalação inicial exige --squads <categoria> explícito.
    echo "SKIP=target_sem_squad|propagate não instala nada num projeto sem agentes; use --squads <categoria> para instalar."
    exit 0
  fi
fi

# Guarda-dura: instalar TODAS as squads sem derivar do destino re-adiciona squads podadas.
# Só permitido com --match-target-squads (deriva do destino) ou --squads <categoria> explícito.
if [ "$SQUADS" = "all" ] && [ $MATCH_TARGET -eq 0 ]; then
  echo "ERROR=squads_all_without_match_target|--squads default é 'all', o que re-instalaria TODAS as squads e desfaria podas por categoria. Passe --match-target-squads (deriva as squads do destino) ou --squads <categoria> explícito (ex: --squads social)." >&2
  exit 1
fi

PACK_SQUADS="$(pack_squads "$SOURCE")"

# Agentes órfãos (só no *propagate): agente do destino com prefixo de squad do pack que JÁ foi do
# pack (registrado no .team-os/installed.json ou presente no histórico git do CT) e não existe mais
# no CT. Nada é removido — só avisa. Agente próprio (`origin: custom`) e agente que o usuário criou
# no destino nunca são órfãos. social-* órfão = squad social antiga → migrate-social-split.sh.
if [ $MATCH_TARGET -eq 1 ] && [ -d "$TARGET/.claude/agents" ]; then
  orphans=0
  for ta in "$TARGET/.claude/agents/"*.md; do
    [ -f "$ta" ] || continue
    tn=$(basename "$ta" .md)
    in_list "${tn%%-*}" "$PACK_SQUADS" || continue
    [ -f "$SOURCE/.claude/agents/$tn.md" ] && continue
    is_custom_agent "$ta" && continue
    was_pack=0
    grep -qF "\".claude/agents/$tn.md\"" "$TARGET/.team-os/installed.json" 2>/dev/null && was_pack=1
    if [ $was_pack -eq 0 ] && [ -n "$(git -C "$SOURCE" log -1 --format=%h HEAD -- ".claude/agents/$tn.md" 2>/dev/null)" ]; then
      was_pack=1
    fi
    [ $was_pack -eq 1 ] || continue
    orphans=$((orphans + 1))
    case "$tn" in
      social-*) echo "ORPHAN_AGENT=$tn|saiu do pack (a social virou estúdio + squads de plataforma) — não foi removido; rode migrate-social-split.sh \"$TARGET\" (dry-run) para migrar sem ficar com dois gates" ;;
      *)        echo "ORPHAN_AGENT=$tn|saiu do pack — não foi removido nem atualizado; revise e mova para .team-os/removed/ se não usa mais" ;;
    esac
  done
  [ $orphans -gt 0 ] && echo "ORPHAN_AGENTS=$orphans"
fi

# Estúdio `social` (design, foto, vídeo) produz sob brief de uma squad de plataforma e nunca
# aprova nem publica — sozinho não tem gate. Não bloqueia: só avisa.
if [ "$SQUADS" != "all" ] && in_csv social "$SQUADS"; then
  has_platform=0
  for ps in $PLATFORM_SQUADS; do in_csv "$ps" "$SQUADS" && { has_platform=1; break; }; done
  if [ $has_platform -eq 0 ]; then
    echo "WARN=studio_without_platform|a squad social é só o estúdio (design, foto, vídeo) e não aprova nem publica — instale também uma squad de plataforma (--squads social,instagram | tiktok | youtube | linkedin) para ter gate editorial e publicação."
  fi
fi

echo "STATUS=starting"
echo "SOURCE=$SOURCE_NAME"
echo "TARGET=$TARGET_NAME"
echo "SQUADS=$SQUADS"
echo "DRY_RUN=$DRY_RUN"
echo "---"

# Cria diretórios necessários no destino
do_mkdir() {
  [ $DRY_RUN -eq 1 ] && return
  mkdir -p "$1"
}

# Lixo que NUNCA viaja para o destino: artefatos macOS (.DS_Store, Icon?), runtime local da
# skill seo (.venv, ms-playwright, runtime-state.json), bytecode Python (__pycache__, *.pyc) e
# pendências do *update do CT (*.new). A lista vive no propagate-sync.py (SKIP_DIRS/SKIP_FILES),
# que é quem grava — arquivo por arquivo, sem rsync --delete (nada do usuário é apagado).

# ── Backup do .claude/ prévio (antes de QUALQUER escrita no destino) ─────────
# Só no *install (1ª instalação num .claude/ existente): o *propagate (--match-target-squads) NÃO faz
# backup — tudo que ele grava vem do CT (versionado), então desfazer = rodar o propagate de novo, e
# cada cópia custava centenas de MB por projeto. Só fora do dry-run; cp -R, nunca mv.
# Guarda no máximo BACKUP_KEEP (default 3) cópias; as mais antigas vão para a Lixeira (trash.sh: macOS/Linux), não são apagadas.
if [ $DRY_RUN -eq 0 ] && [ $MATCH_TARGET -eq 0 ] && [ -d "$TARGET/.claude" ]; then
  BACKUP_DIR="$TARGET/.claude.bak-$(date +%Y%m%d-%H%M%S)"
  if cp -R "$TARGET/.claude" "$BACKUP_DIR" 2>/dev/null; then
    echo "BACKUP=$BACKUP_DIR"
    KEEP=${BACKUP_KEEP:-3}; case "$KEEP" in ''|*[!0-9]*) KEEP=3 ;; esac
    TRASHED=0
    # Lixeira portável (macOS ~/.Trash · Linux gio/trash-put/~/.local/share/Trash) — nunca rm
    # shellcheck source=trash.sh
    . "$SCRIPT_DIR/trash.sh"
    OLD_BAKS="$(ls -1d "$TARGET"/.claude.bak-* 2>/dev/null | sort -r | tail -n +$((KEEP + 1)))"
    if [ -n "$OLD_BAKS" ]; then
      while IFS= read -r old_bak; do
        [ -n "$old_bak" ] || continue
        team_os_trash "$old_bak" >/dev/null && TRASHED=$((TRASHED + 1))
      done <<EOF
$OLD_BAKS
EOF
    fi
    [ $TRASHED -gt 0 ] && echo "BACKUP_TRASHED=$TRASHED|cópias antigas de .claude.bak-* movidas para a Lixeira (guardadas: $KEEP)"
  else
    echo "BACKUP_FAILED=$BACKUP_DIR|não foi possível copiar .claude/ — abortando sem escrever" >&2
    exit 1
  fi
fi

# .gitignore do destino: cobrir lixo macOS (.DS_Store, Icon?)
ensure_gitignore() {
  [ $DRY_RUN -eq 1 ] && return
  local gi="$TARGET/.gitignore" added=""
  [ -f "$gi" ] || : > "$gi"
  # última linha sem quebra: completa antes de acrescentar (senão gruda na linha do usuário)
  if [ -s "$gi" ] && [ -n "$(tail -c1 "$gi")" ]; then printf '\n' >> "$gi"; fi
  if ! grep -q '^\.DS_Store$\|^\*\*/\.DS_Store$\|^\.DS_Store\b' "$gi" 2>/dev/null; then
    printf '.DS_Store\n' >> "$gi"; added="$added .DS_Store"
  fi
  if ! grep -q '^Icon?$\|^Icon\\r$\|^Icon\?' "$gi" 2>/dev/null; then
    printf 'Icon?\n' >> "$gi"; added="$added Icon?"
  fi
  # Estado local da instalação (installed.json, backups de conflito) — por máquina
  if ! grep -qE '^/?\.team-os/?[[:space:]]*$' "$gi" 2>/dev/null; then
    printf '.team-os/\n' >> "$gi"; added="$added .team-os/"
  fi
  [ -n "$added" ] && echo "GITIGNORE_ADDED=${added# }"
}

# ── Plano de gravação ────────────────────────────────────────────────────────
# Agentes, skills e hooks entram num PLANO (um item por linha: tipo<TAB>nome<TAB>caminho na
# fonte). Quem grava é o propagate-sync.py, arquivo por arquivo, comparando com o
# .team-os/installed.json do destino — assim uma edição feita lá nunca é sobrescrita.
PLAN="$(mktemp "${TMPDIR:-/tmp}/team-os-plan.XXXXXX")" || exit 1
RESULTS="$(mktemp "${TMPDIR:-/tmp}/team-os-results.XXXXXX")" || exit 1
trap 'rm -f "$PLAN" "$RESULTS"' EXIT
plan_add() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$PLAN"; }

# ── Agentes ──────────────────────────────────────────────────────────────────

agents_skipped=0           # fora do filtro de squad (os idênticos somam depois)
INSTALLED_AGENT_FILES=""   # todos os agentes que FICAM no destino (novos, atualizados ou idênticos)
custom_found=""

for agent_file in "$SOURCE/.claude/agents/"*.md; do
  [ -f "$agent_file" ] || continue
  agent_name=$(basename "$agent_file" .md)

  # Agente próprio (origin: custom) pedido em --custom: entra fora do filtro de squad
  custom_pick=0
  if [ -n "$CUSTOM" ] && is_custom_agent "$agent_file"; then
    if [ "$CUSTOM" = "all" ] || in_csv "$agent_name" "$CUSTOM"; then
      custom_pick=1; custom_found="$custom_found,$agent_name"
    fi
  fi

  # Filtra por squad (os próprios seguem a mesma regra: squad = prefixo do nome)
  if [ "$SQUADS" != "all" ] && [ $custom_pick -eq 0 ]; then
    match=0
    for squad in $(echo "$SQUADS" | tr ',' ' '); do
      [[ "$agent_name" == ${squad}-* ]] && { match=1; break; }
    done
    [ $match -eq 0 ] && { agents_skipped=$((agents_skipped + 1)); continue; }
  fi
  INSTALLED_AGENT_FILES="$INSTALLED_AGENT_FILES
$agent_file"
  plan_add agent "$agent_name" "$agent_file"
done

# --custom com nome que não existe (ou não é agente próprio) no CT: avisa
if [ -n "$CUSTOM" ] && [ "$CUSTOM" != "all" ]; then
  for cn in $(echo "$CUSTOM" | tr ',' ' '); do
    in_csv "$cn" "${custom_found#,}" || echo "CUSTOM_NOT_FOUND=$cn|não há agente próprio (origin: custom) com esse nome no CT"
  done
fi
[ -n "$custom_found" ] && echo "CUSTOM_AGENTS=${custom_found#,}"

# ── Skills — lista = união de 4 origens ──────────────────────────────────────
#   (i)   citadas no body dos agentes instalados (`/nome-da-skill` ou skill `nome`)
#   (ii)  team-os (sempre)
#   (iii) --extra-skills (opt-in)
#   (iv)  prefixo da squad instalada (<squad>-*, squads do pack lidas de presets/*.yaml)
#   (+)   já presente no destino → mantida atualizada (propagate), nunca removida
# Nunca: team-os-creator · sala-de-controle (exclusivas do CT) · maestri-os (saiu do pack).
# sala-de-controle/maestri-os já presentes num projeto: não são atualizadas → LEGACY_SKILL=<nome>.
# No dry-run cada skill sai com a origem: SKILL_ORIGIN=<skill>|<origem>.

do_mkdir "$TARGET/.claude/skills"

# (i) skills citadas nos bodies dos agentes instalados → "skill|agente1 agente2"
CITED_MAP=""
if [ -n "$INSTALLED_AGENT_FILES" ]; then
  CITED_MAP="$(printf '%s\n' "$INSTALLED_AGENT_FILES" | while IFS= read -r af; do
    [ -f "$af" ] || continue
    an=$(basename "$af" .md)
    # body = depois do 2º '---'; tokens /x-y (precedidos de espaço, crase ou parêntese) e skill `x`
    body="$(awk '/^---$/{c++; next} c>=2' "$af")"
    {
      printf '%s\n' "$body" | grep -oE '(^|[[:space:]`(])/[a-z][a-z0-9-]+' | sed 's|^[^/]*/||'
      printf '%s\n' "$body" | grep -oE 'skill `[a-z][a-z0-9-]+`' | sed 's/^skill `//; s/`$//'
    } | sort -u | while IFS= read -r sk; do
      [ -n "$sk" ] || continue
      [ -f "$SOURCE/.claude/skills/$sk/SKILL.md" ] || continue
      echo "$sk|$an"
    done
  done | sort -u | awk -F'|' '{ a[$1] = (a[$1] == "" ? $2 : a[$1] " " $2) } END { for (k in a) print k "|" a[k] }')"
fi
cited_by() { printf '%s\n' "$CITED_MAP" | grep -m1 "^$1|" | cut -d'|' -f2; }

skills_copied=0
skills_updated=0
skills_skipped=0
skills_list=""
team_os_handled=0   # evita dupla contagem de team-os no bloco "forçado" (bug do dry-run)

for skill_path in "$SOURCE/.claude/skills"/*/; do
  [ -d "$skill_path" ] || continue
  skill_name=$(basename "$skill_path")

  # Exclusivas do CT (team-os-creator, sala-de-controle) e maestri-os nunca vão para o destino
  if in_list "$skill_name" "$CT_ONLY_SKILLS $LEGACY_CR_SKILLS"; then
    skills_skipped=$((skills_skipped + 1)); continue
  fi

  # Opt-in explícito (--extra-skills) vale em qualquer modo
  extra=0
  for es in $(echo "$EXTRA_SKILLS" | tr ',' ' '); do
    [ "$es" = "$skill_name" ] && { extra=1; break; }
  done

  origin=""
  {
    # (ii) team-os sempre
    [ "$skill_name" = "team-os" ] && origin="obrigatória (team-os)"
    # (iii) extra
    [ -z "$origin" ] && [ $extra -eq 1 ] && origin="extra"
    # (iv) prefixo da squad instalada
    if [ -z "$origin" ] && [ "$SQUADS" != "all" ]; then
      skill_prefix="${skill_name%%-*}"
      if in_list "$skill_prefix" "$PACK_SQUADS"; then
        for squad in $(echo "$SQUADS" | tr ',' ' '); do
          [ "$skill_prefix" = "$squad" ] && { origin="prefixo da squad $squad"; break; }
        done
      fi
    elif [ -z "$origin" ] && [ "$SQUADS" = "all" ]; then
      origin="todas as squads"
    fi
    # (i) citada por agente instalado
    if [ -z "$origin" ]; then
      cb="$(cited_by "$skill_name")"
      [ -n "$cb" ] && origin="citada por $cb"
    fi
    # (+) já presente no destino → mantém atualizada (nunca deixamos skill instalada envelhecer)
    [ -z "$origin" ] && [ -d "$TARGET/.claude/skills/$skill_name" ] && origin="já instalada no destino"
  }
  [ -z "$origin" ] && { skills_skipped=$((skills_skipped + 1)); continue; }
  [ $DRY_RUN -eq 1 ] && echo "SKILL_ORIGIN=$skill_name|$origin"

  [ "$skill_name" = "team-os" ] && team_os_handled=1
  # Existe no destino: arquivo por arquivo, só o que difere (edição do usuário vira conflito).
  # Arquivos que o usuário criou dentro da skill nunca são apagados.
  plan_add skill "$skill_name" "${skill_path%/}"
done

# Skill de Sala antiga num projeto comum: não é atualizada nem removida — só avisa.
for ls in $LEGACY_CR_SKILLS; do
  [ -d "$TARGET/.claude/skills/$ls" ] || continue
  echo "LEGACY_SKILL=$ls|não foi atualizada: a Sala de Controle mora no CT (rode /sala-de-controle numa sessão do CT); mova a pasta .claude/skills/$ls para a Lixeira quando quiser"
done

# Garante team-os no destino (obrigatória para /team-os funcionar).
# team_os_handled evita dupla contagem quando o loop já processou team-os.
if [ $team_os_handled -eq 0 ] && [ -d "$SOURCE/.claude/skills/team-os" ]; then
  plan_add skill team-os "$SOURCE/.claude/skills/team-os"
  [ -d "$TARGET/.claude/skills/team-os" ] || echo "TEAM_OS_FORCED=1"
elif [ $team_os_handled -eq 0 ]; then
  echo "TEAM_OS_WARNING=skill team-os não encontrada na fonte — instale manualmente"
fi

# ── Hooks ────────────────────────────────────────────────────────────────────
# block-worktree.sh é referenciado pelo settings.json; block-git-push.sh é referenciado no
# frontmatter dos agentes com Bash — sem ele no destino, a garantia dura de push não existe.
# Quality gate (pacote padrão — sempre): task-quality.sh (TaskCreated), check-*-progress.sh
# (TaskCompleted), guard-push-branch.sh (devops), guard-smart-memory-read.sh,
# guard-message-size.sh e context-watch.sh — registrados no settings.json pelo ensure-settings.sh.
# team-os-tdah.sh vai junto sem registro no projeto: é a fonte que o /team-os *tdah (tdah.sh on)
# instala no ~/.claude/hooks/ de quem liga o modo.
STD_HOOKS="block-worktree.sh block-git-push.sh task-quality.sh check-story-progress.sh check-social-progress.sh check-proposal-progress.sh check-finance-progress.sh check-legal-progress.sh guard-push-branch.sh guard-smart-memory-read.sh guard-message-size.sh context-watch.sh team-os-tdah.sh"
hooks_extra=0
{
  for uh in block-worktree.sh block-git-push.sh; do
    key="WORKTREE_HOOK"; [ "$uh" = "block-git-push.sh" ] && key="GIT_PUSH_HOOK"
    if [ -f "$SOURCE/.claude/hooks/$uh" ]; then
      plan_add hook "$uh" "$SOURCE/.claude/hooks/$uh"
      echo "$key=installed"
    else
      echo "${key}_MISSING=$uh não encontrado na fonte"
    fi
  done
  quality_hooks_installed=""
  quality_hooks_missing=""
  for qh in $STD_HOOKS; do
    case "$qh" in block-worktree.sh|block-git-push.sh) continue ;; esac
    if [ -f "$SOURCE/.claude/hooks/$qh" ]; then
      plan_add hook "$qh" "$SOURCE/.claude/hooks/$qh"
      quality_hooks_installed="$quality_hooks_installed $qh"
    else
      quality_hooks_missing="$quality_hooks_missing $qh"
    fi
  done
  [ -n "$quality_hooks_installed" ] && echo "QUALITY_HOOKS=${quality_hooks_installed# }"
  [ -n "$quality_hooks_missing" ] && echo "QUALITY_HOOKS_MISSING=${quality_hooks_missing# }"

  # --with-env-guard: hook opcional (OK do usuário). Já presente no destino → mantém atualizado.
  ENV_GUARD="guard-env-files.sh"
  if [ -f "$SOURCE/.claude/hooks/$ENV_GUARD" ] && { [ $WITH_ENV_GUARD -eq 1 ] || [ -f "$TARGET/.claude/hooks/$ENV_GUARD" ]; }; then
    plan_add hook "$ENV_GUARD" "$SOURCE/.claude/hooks/$ENV_GUARD"
    [ $WITH_ENV_GUARD -eq 1 ] && echo "ENV_GUARD_HOOK=installed" || echo "ENV_GUARD_HOOK=kept"
  elif [ $WITH_ENV_GUARD -eq 1 ]; then
    echo "ENV_GUARD_HOOK_MISSING=$ENV_GUARD não encontrado na fonte"
  fi

  # --include-hooks: só hooks extras (fora do pacote padrão)
  if [ $INCLUDE_HOOKS -eq 1 ] && [ -d "$SOURCE/.claude/hooks" ]; then
    for hook_file in "$SOURCE/.claude/hooks/"*.sh; do
      [ -f "$hook_file" ] || continue
      hook_name=$(basename "$hook_file")
      case " $STD_HOOKS $ENV_GUARD " in *" $hook_name "*) continue ;; esac
      plan_add hook "$hook_name" "$hook_file"
      hooks_extra=$((hooks_extra + 1))
    done
  fi
}

# ── Gravação (arquivo por arquivo, sem perder edição do destino) ─────────────
SYNC_ARGS="--on-conflict $ON_CONFLICT"
[ $ON_CONFLICT_SET -eq 1 ] && [ "$ON_CONFLICT" = "keep" ] && SYNC_ARGS="$SYNC_ARGS --decided"
[ $DRY_RUN -eq 1 ] && SYNC_ARGS="$SYNC_ARGS --dry-run"
[ -n "$ONLY" ] && echo "ONLY=$ONLY"
# shellcheck disable=SC2086
if ! python3 "$SYNC_PY" sync --target "$TARGET" --plan "$PLAN" --results "$RESULTS" \
    --version "$PACK_VERSION" --only "$ONLY" --trash "$SCRIPT_DIR/trash.sh" $SYNC_ARGS > "$RESULTS.out" 2>&1; then
  cat "$RESULTS.out"; rm -f "$RESULTS.out"
  echo "ERROR=sync_failed|a gravação parou no meio; rode de novo (o que já foi gravado está registrado)"
  exit 1
fi
SYNC_OUT="$(cat "$RESULTS.out")"; rm -f "$RESULTS.out"

# Contagens por item (copied | updated | skipped | only-skipped)
count_status() { awk -F'\t' -v k="$1" -v s="$2" '$1==k && $3==s {n++} END {print n+0}' "$RESULTS"; }
list_changed() { awk -F'\t' -v k="$1" '$1==k && ($3=="copied" || $3=="updated") {printf "%s%s", sep, $2; sep=" "}' "$RESULTS"; }

echo "AGENTS_COPIED=$(count_status agent copied)"
echo "AGENTS_UPDATED=$(count_status agent updated)"
echo "AGENTS_SKIPPED=$((agents_skipped + $(count_status agent skipped) + $(count_status agent only-skipped)))"
echo "AGENTS_LIST=$(list_changed agent)"
echo "SKILLS_COPIED=$(count_status skill copied)"
echo "SKILLS_UPDATED=$(count_status skill updated)"
echo "SKILLS_SKIPPED=$((skills_skipped + $(count_status skill skipped) + $(count_status skill only-skipped)))"
echo "SKILLS_LIST=$(list_changed skill)"
echo "HOOKS_UPDATED=$(( $(count_status hook copied) + $(count_status hook updated) ))"
[ $INCLUDE_HOOKS -eq 1 ] && echo "HOOKS_COPIED=$hooks_extra"
printf '%s\n' "$SYNC_OUT"

# ── .gitignore do destino: cobrir lixo macOS (.DS_Store, Icon?) ──────────────
ensure_gitignore

# ── Settings.json — delegado ao ensure-settings.sh da team-os (fonte única) ──
# Cria o arquivo se não existe e SÓ ADICIONA o que falta num existente (nunca
# sobrescreve valor, valida o JSON final). No dry-run mostra o merge sem gravar.
ENSURE_SETTINGS="$SOURCE/.claude/skills/team-os/scripts/ensure-settings.sh"
ES_EXTRA=""
[ $WITH_ENV_GUARD -eq 1 ] && ES_EXTRA="--with-env-guard"
TARGET_SETTINGS="$TARGET/.claude/settings.json"
if [ -f "$ENSURE_SETTINGS" ]; then
  [ -f "$TARGET_SETTINGS" ] && settings_existed=1 || settings_existed=0
  if [ $DRY_RUN -eq 1 ]; then
    # Só as linhas de mudança/aviso (o merge completo é ruído no dry-run)
    es_out="$(bash "$ENSURE_SETTINGS" --project-dir "$TARGET" --dry-run $ES_EXTRA 2>&1 | grep -E '^(\[dry-run\]|✓|⚠|  [+~])' || true)"
    [ -n "$es_out" ] && printf '%s\n' "$es_out" | sed 's/^/ENSURE_SETTINGS: /'
    echo "SETTINGS_ENSURED=dry-run"
  else
    if es_out="$(bash "$ENSURE_SETTINGS" --project-dir "$TARGET" $ES_EXTRA 2>&1)"; then
      printf '%s\n' "$es_out" | grep -E '^(✓|⚠|  [+~]|mudanças)' | sed 's/^/ENSURE_SETTINGS: /'
      if [ $settings_existed -eq 0 ]; then echo "SETTINGS_CREATED=1"; else echo "SETTINGS_ENSURED=1"; fi
    else
      printf '%s\n' "$es_out" | sed 's/^/ENSURE_SETTINGS: /' >&2
      echo "SETTINGS_ERROR=1|ensure-settings.sh falhou (JSON inválido no destino ou python3 ausente) — corrija e rode: bash \"$ENSURE_SETTINGS\" --project-dir \"$TARGET\""
    fi
  fi
else
  echo "SETTINGS_ERROR=1|ensure-settings.sh não encontrado em $ENSURE_SETTINGS — settings.json do destino não foi tocado"
fi

# ── Session-title hook (global, core UX — sempre instalado) ──────────────────
# Nomeia toda sessão pelo projeto+branch. Vale para todos os projetos de uma vez.
GLOBAL_HOOK_SRC="$SOURCE/.claude/hooks/team-os-session-title.sh"
GLOBAL_HOOK_DST="$HOME/.claude/hooks/team-os-session-title.sh"
if [ -f "$GLOBAL_HOOK_SRC" ]; then
  if [ $DRY_RUN -eq 0 ]; then
    mkdir -p "$HOME/.claude/hooks"
    cp "$GLOBAL_HOOK_SRC" "$GLOBAL_HOOK_DST"
    chmod +x "$GLOBAL_HOOK_DST"
  fi
  echo "SESSION_TITLE_HOOK=installed"
  # Registro do SessionStart no settings global é feito pela skill (edição segura de JSON).
  if [ -f "$HOME/.claude/settings.json" ] && grep -q "team-os-session-title" "$HOME/.claude/settings.json" 2>/dev/null; then
    echo "SESSION_TITLE_REGISTERED=1"
  else
    echo "SESSION_TITLE_REGISTER_TODO=1|adicione um hook SessionStart em ~/.claude/settings.json apontando para \$HOME/.claude/hooks/team-os-session-title.sh"
  fi
else
  echo "SESSION_TITLE_HOOK_MISSING=team-os-session-title.sh não encontrado na fonte"
fi

# ── Modo TDAH (global, opt-in) — só atualiza quem já ligou com /team-os *tdah ──
TDAH_HOOK_DST="$HOME/.claude/hooks/team-os-tdah.sh"
if [ -f "$TDAH_HOOK_DST" ] && [ -f "$SOURCE/.claude/hooks/team-os-tdah.sh" ]; then
  if [ $DRY_RUN -eq 0 ]; then
    cp "$SOURCE/.claude/hooks/team-os-tdah.sh" "$TDAH_HOOK_DST"
    chmod +x "$TDAH_HOOK_DST"
    cp "$SOURCE/.claude/skills/team-os/reference/modo-tdah.md" "$HOME/.claude/hooks/team-os-tdah.md" 2>/dev/null
  fi
  echo "TDAH_HOOK=refreshed"
fi

echo "---"
echo "STATUS=done"
