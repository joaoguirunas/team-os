#!/usr/bin/env bash
# validate-agent.sh — *audit v3, archetype-driven
#
# Usage: ./validate-agent.sh [<name>] | ./validate-agent.sh --skills
#   sem args  → valida todos os agentes de .claude/agents/ + checks globais
#   <name>    → valida só .claude/agents/<name>.md (sem checks globais)
#   --skills  → lint de TODAS as .claude/skills/*/SKILL.md (frontmatter, name = pasta,
#               description de 1 linha ≤ 400 chars, version/updated com aspas).
#               sala-de-controle e maestri-os: só WARN (nunca erro).
#
# Fontes da verdade:
#   - presets/*.yaml ............ archetype + squad + persona de cada agente
#   - reference/native-teams-protocol.md ... bloco NTP canônico (hash byte-idêntico)
#   - reference/archetypes.md ... defaults documentados (este script implementa as regras)
#   - reference/mcp-servers.md .. servidores MCP aceitos em tools: (identificadores `mcp__<id>`)
#
# Regras por ARCHETYPE (não por nome hardcoded):
#   model  : architect/reviewer/strategist → opus; demais → inherit
#   effort : architect/reviewer/strategist/hardening/data → high;
#            researcher/ux → medium; implementer/devops → omitido
#            EXCEÇÕES canônicas: dev-bi, dev-data-performance, pm-coach → medium
#   permissionMode: OBRIGATÓRIO em todo archetype (valor do enum);
#            reviewer/strategist = acceptEdits (bypassPermissions proibido neles)
#   color  : enum red/blue/green/yellow/purple/orange/pink/cyan; blue proibido em
#            teammates; reviewer (QA) deve ser red; repetição na squad = warning
#            (só quando a squad tem ≤ 8 agentes — só existem 8 cores)
#   hook   : block-git-push.sh obrigatório em todo agente com Bash cujo archetype
#            NÃO é devops; proibido em archetype devops
#   hooks: : estrutura válida (evento conhecido → lista com matcher/hooks[].command)
#            e cada command referenciado existe em .claude/hooks/
#   tools  : reviewer/strategist e implementer devem ter Write E Edit;
#            mcp__<server>[__<tool>]: <server> precisa estar em reference/mcp-servers.md
#            (ERRO); forma longa mcp__<server>__<tool> = WARN (prefira a curta)
#   NTP    : bloco "## Native Teams Protocol" byte-idêntico ao canônico (hash md5,
#            após remover linhas em branco iniciais/finais)
#   área   : linha `**Área na smart-memory:** \`docs/smart-memory/agents/<squad>/<área>/\``
#            obrigatória, com <squad> = prefixo do agente (logo após o H1 — posição = warning)
#   paths  : ERRO se o body cita docs/smart-memory/agents/<área>/ sem squad,
#            docs/smart-memory/pm/, ou stories/<x> com x fora de
#            {backlog,active,in-review,done,BACKLOG.md}
#   skills : todo /token citado no body (com ou sem hífen) e todo skill `x` precisam
#            existir em .claude/skills/ — exceto slash commands built-in do Claude Code
#
# Extração de PERSONA (padrão documentado): a persona de um agente é o texto do
# primeiro H1 antes de " — " (em dash), ex.: "# Nova — Frontend Developer" → "Nova".
# Checks de persona são WARNING (nunca erro):
#   - persona citada no formato "Nome (agent-name)" divergente do H1 atual do agente
#   - persona de OUTRA squad citada no body
#
# Saída: ✅ (ok) / ⚠️ (só warnings) / ❌ (erros) por agente + resumo.
# Exit 1 se qualquer ❌. Bash 3.2 / macOS, sem dependências (awk/grep/sed).

set -u

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

AGENTS_DIR=".claude/agents"
SKILLS_DIR=".claude/skills"
HOOKS_DIR=".claude/hooks"
PRESETS_DIR="$SKILLS_DIR/team-os-creator/presets"
NTP_FILE="$SKILLS_DIR/team-os-creator/reference/native-teams-protocol.md"
MCP_FILE="$SKILLS_DIR/team-os-creator/reference/mcp-servers.md"

KNOWN_SQUADS="dev sites social traffic pm sales brand finance legal seo"
COLOR_ENUM="red blue green yellow purple orange pink cyan"
COLOR_LIMIT=7  # 8 cores do enum menos blue (reservada ao lead): acima disso repetição é inevitável
PERMISSION_ENUM="default acceptEdits auto dontAsk bypassPermissions plan"
EFFORT_ENUM="low medium high xhigh max"
HOOK_EVENTS="PreToolUse PostToolUse PermissionRequest Notification UserPromptSubmit Stop SubagentStop SubagentStart PreCompact SessionStart SessionEnd TaskCreated TaskCompleted TeammateIdle ConfigChange"
STORY_DIRS="backlog active in-review done BACKLOG.md"
# Exceções canônicas de effort (documentadas em reference/archetypes.md)
EFFORT_EXCEPTIONS_MEDIUM="dev-bi dev-data-performance pm-coach"
# Placeholders instrucionais que NÃO são citação de skill
SKILL_PLACEHOLDERS="nome-da-skill nome-skill skill-name nome-da-sua-skill sua-skill skill"
# Slash commands built-in do Claude Code (não são skills). /design NÃO é built-in.
BUILTIN_SLASH="help clear compact model config init review rename resume loop cost doctor status memory permissions mcp agents hooks login logout bug vim effort plan tasks context export exit quit btw usage stats fast theme ide diff files insights rewind branch sandbox teammates upgrade version keybindings privacy-settings release-notes pr-comments add-dir output-style statusline-setup skill-doctor terminal-setup install-slack-app"
# Palavras que aparecem como "/x" mas são caminho de sistema, não skill
PATH_WORDS="tmp dev etc usr bin var opt private src app docs public lib home root proc sbin mnt"
# Skills onde o lint de --skills só avisa (sem version/updated por design)
SKILLS_WARN_ONLY="sala-de-controle maestri-os"

TMPDIR_V="$(mktemp -d "${TMPDIR:-/tmp}/validate-agent.XXXXXX")" || exit 1
trap 'rm -rf "$TMPDIR_V"' EXIT
MAP_FILE="$TMPDIR_V/preset-map.txt"     # agent|squad|archetype|persona_preset
GLOSS_FILE="$TMPDIR_V/persona-map.txt"  # agent|squad|persona_h1
COLOR_FILE="$TMPDIR_V/colors.txt"       # squad|color|agent

PROBLEMS=0
WARNED=0
CHECKED=0
GLOBAL_ERRORS=0

hash_text() {  # hash de stdin (md5 -q no macOS, md5sum como fallback)
  if command -v md5 >/dev/null 2>&1; then md5 -q; else md5sum | awk '{print $1}'; fi
}

trim_blank_edges() {  # remove linhas em branco iniciais/finais do stdin
  awk 'NF{if(!s)s=NR; e=NR} {lines[NR]=$0} END{for(i=s;i<=e;i++) print lines[i]}'
}

in_list() {  # in_list "item" "a b c"
  local item="$1" list="$2" x
  for x in $list; do [ "$x" = "$item" ] && return 0; done
  return 1
}

# ═════════════════════════════════════════════════════════════════════════════
# Modo --skills: lint de .claude/skills/*/SKILL.md
# ═════════════════════════════════════════════════════════════════════════════
lint_skills() {
  local d sname sfile fm errs warns warn_only line desc dlen ver upd n_err n_warn n_ok
  n_err=0; n_warn=0; n_ok=0
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    sname="$(basename "$d")"
    sfile="${d}SKILL.md"
    errs=(); warns=()
    warn_only=0
    in_list "$sname" "$SKILLS_WARN_ONLY" && warn_only=1

    if [ ! -f "$sfile" ]; then
      errs+=("sem SKILL.md")
    else
      head -1 "$sfile" | grep -q '^---$' || errs+=("sem frontmatter '---' na 1ª linha")
      fm="$(awk '/^---$/{c++; next} c==1' "$sfile")"
      [ "$(grep -c '^---$' "$sfile")" -ge 2 ] || errs+=("frontmatter não fechado (falta o 2º '---')")

      line="$(printf '%s\n' "$fm" | grep -m1 -E '^name:' | sed -E 's/^name:[[:space:]]*//; s/[[:space:]]*$//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/')"
      [ "$line" = "$sname" ] || errs+=("name:'$line' ≠ pasta '$sname'")

      desc="$(printf '%s\n' "$fm" | grep -m1 -E '^description:' | sed -E 's/^description:[[:space:]]*//; s/[[:space:]]*$//')"
      if [ -z "$desc" ]; then
        errs+=("description: ausente ou vazia")
      else
        case "$desc" in '>'*|'|'*) errs+=("description: bloco multi-linha (>/|) — deve ser uma linha") ;; esac
        # valor entre aspas não conta as aspas
        dlen="$(printf '%s' "$desc" | sed -E 's/^"(.*)"$/\1/' | LC_ALL=C.UTF-8 wc -m 2>/dev/null | tr -d ' ')"
        # CI sem locale UTF-8: wc -m conta bytes — usar python3 se disponível
        if command -v python3 >/dev/null 2>&1; then dlen="$(printf '%s' "$desc" | sed -E 's/^"(.*)"$/\1/' | python3 -c 'import sys; print(len(sys.stdin.read()))')"; fi
        [ "$dlen" -gt 400 ] && errs+=("description com $dlen chars (> 400)")
      fi

      ver="$(printf '%s\n' "$fm" | grep -m1 -E '^version:' | sed -E 's/^version:[[:space:]]*//; s/[[:space:]]*$//')"
      upd="$(printf '%s\n' "$fm" | grep -m1 -E '^updated:' | sed -E 's/^updated:[[:space:]]*//; s/[[:space:]]*$//')"
      if [ -z "$ver" ]; then errs+=("version: ausente (use version: \"1.0\")")
      else case "$ver" in '"'*'"'|"'"*"'") ;; *) errs+=("version: $ver sem aspas (YAML lê 1.10 como 1.1)") ;; esac; fi
      if [ -z "$upd" ]; then errs+=("updated: ausente (use updated: \"YYYY-MM-DD\")")
      else case "$upd" in '"'*'"'|"'"*"'") ;; *) errs+=("updated: $upd sem aspas (YAML converte para date)") ;; esac; fi
    fi

    if [ $warn_only -eq 1 ] && [ ${#errs[@]} -gt 0 ]; then
      warns=("${warns[@]+"${warns[@]}"}" "${errs[@]}"); errs=()
    fi
    if [ ${#errs[@]} -eq 0 ] && [ ${#warns[@]} -eq 0 ]; then
      echo "✅ $sname"; n_ok=$((n_ok + 1))
    elif [ ${#errs[@]} -eq 0 ]; then
      echo "⚠️  $sname:"; for line in "${warns[@]}"; do echo "    ⚠ $line"; done; n_warn=$((n_warn + 1))
    else
      echo "❌ $sname:"; for line in "${errs[@]}"; do echo "    • $line"; done
      for line in "${warns[@]+"${warns[@]}"}"; do echo "    ⚠ $line"; done; n_err=$((n_err + 1))
    fi
  done
  echo ""
  if [ $n_err -eq 0 ]; then
    echo "✅ skills: $n_ok ok · $n_warn com warning · 0 com erro."
    return 0
  fi
  echo "❌ skills: $n_err com erro · $n_warn com warning · $n_ok ok."
  return 1
}

if [ "${1:-}" = "--skills" ]; then
  lint_skills; exit $?
fi

# ── Pré-requisito: bloco NTP canônico ────────────────────────────────────────
if [ ! -f "$NTP_FILE" ]; then
  echo "⛔ Fonte canônica do NTP ausente: $NTP_FILE" >&2
  exit 1
fi
NTP_HASH="$(awk '/<!-- NTP-START -->/{f=1;next} /<!-- NTP-END -->/{f=0} f' "$NTP_FILE" | trim_blank_edges | hash_text)"

# ── Servidores MCP aceitos (identificadores `mcp__<id>` do reference) ────────
MCP_ACCEPTED=""
if [ -f "$MCP_FILE" ]; then
  MCP_ACCEPTED="$(grep -oE '`mcp__[A-Za-z0-9_-]+`' "$MCP_FILE" | tr -d '`' | sort -u | tr '\n' ' ')"
fi

# ── Carregar presets → mapa agent|squad|archetype|persona ────────────────────
if [ ! -d "$PRESETS_DIR" ]; then
  echo "⛔ Diretório de presets ausente: $PRESETS_DIR" >&2
  exit 1
fi
: > "$MAP_FILE"
for preset in "$PRESETS_DIR"/*.yaml; do
  [ -f "$preset" ] || continue
  awk -v squad="$(awk -F': *' '/^name:/{print $2; exit}' "$preset")" '
    /^  - name:/      { if (a != "") print a "|" squad "|" arch "|" pers;
                        a=$3; arch=""; pers="" }
    /^    archetype:/ { arch=$2 }
    /^    persona:/   { pers=$2 }
    END               { if (a != "") print a "|" squad "|" arch "|" pers }
  ' "$preset" >> "$MAP_FILE"
done

preset_field() {  # preset_field <agent> <n>  (2=squad 3=archetype 4=persona)
  grep -m1 "^$1|" "$MAP_FILE" | cut -d'|' -f"$2"
}

# ── Glossário de personas (H1 de cada agente) ────────────────────────────────
: > "$GLOSS_FILE"
for f in "$AGENTS_DIR"/*.md; do
  [ -f "$f" ] || continue
  a="$(basename "$f" .md)"
  p="$(grep -m1 '^# ' "$f" | sed 's/^# //; s/ — .*//; s/[[:space:]]*$//')"
  s="$(preset_field "$a" 2)"
  [ -n "$p" ] && echo "$a|${s:-?}|$p" >> "$GLOSS_FILE"
done

# ── Contagem de skills instaladas ────────────────────────────────────────────
SKILLS_COUNT=0
for d in "$SKILLS_DIR"/*/; do
  [ -f "${d}SKILL.md" ] && SKILLS_COUNT=$((SKILLS_COUNT + 1))
done

# ═════════════════════════════════════════════════════════════════════════════
validate() {
  local file="$1"
  local name; name="$(basename "$file" .md)"
  local errors=() warnings=()
  local PREFIX="${name%%-*}"

  # ── Frontmatter ──
  if ! head -1 "$file" | grep -q '^---$'; then
    errors+=("sem frontmatter no topo")
  fi
  local FM BODY
  FM="$(awk '/^---$/{c++; next} c==1' "$file")"
  BODY="$(awk '/^---$/{c++; next} c>=2' "$file")"

  fm_get() { printf '%s\n' "$FM" | grep -m1 -E "^$1:" | sed -E "s/^$1:[[:space:]]*//; s/[[:space:]]*$//"; }

  local FM_NAME DESC MODEL EFFORT PMODE COLOR TOOLS
  FM_NAME="$(fm_get name)"
  DESC="$(fm_get description)"
  MODEL="$(fm_get model)"
  EFFORT="$(fm_get effort)"
  PMODE="$(fm_get permissionMode)"
  COLOR="$(fm_get color)"
  TOOLS="$(fm_get tools)"

  # ── Archetype (fonte: presets) ──
  local SQUAD ARCH
  SQUAD="$(preset_field "$name" 2)"
  ARCH="$(preset_field "$name" 3)"
  if [ -z "$ARCH" ]; then
    errors+=("agente órfão de preset — sem entrada (com archetype:) em presets/*.yaml")
  fi

  # ── Checks v1 mantidos ──
  [ "$FM_NAME" != "$name" ] && errors+=("name:'$FM_NAME' não bate com arquivo '$name'")
  [ -z "$DESC" ] && errors+=("description: vazia ou ausente")
  printf '%s\n' "$FM" | grep -qE '^memory:[[:space:]]*project[[:space:]]*$' \
    || errors+=("memory: deve ser exatamente 'project' (RULE #1)")
  [ -z "$MODEL" ] && errors+=("model: ausente")
  [ -z "$TOOLS" ] && errors+=("tools: ausente ou vazio")
  grep -q '^# ' "$file" || errors+=("sem heading H1")
  grep -q "Native Teams Protocol" "$file" || errors+=("sem seção 'Native Teams Protocol'")
  grep -q "Contrato com team-os" "$file" && errors+=("ainda contém padrão antigo 'Contrato com team-os' — rode *migrate")
  grep -qi "smart-memory" "$file" || errors+=("não menciona smart-memory")
  grep -q "SendMessage" "$file" || errors+=("não menciona SendMessage")
  printf '%s\n' "$FM" | grep -qE '^skills:' && errors+=("campo skills: no frontmatter é proibido (ignorado em Agent Teams)")
  printf '%s\n' "$FM" | grep -qE '^isolation:' && errors+=("campo isolation: proibido — agentes trabalham direto na branch ativa")

  # ── Tools ──
  local HAS_BASH=0 HAS_WRITE=0 HAS_EDIT=0
  printf '%s' "$TOOLS" | grep -qE '(^|[, ])Bash([, ]|$)'  && HAS_BASH=1
  printf '%s' "$TOOLS" | grep -qE '(^|[, ])Write([, ]|$)' && HAS_WRITE=1
  printf '%s' "$TOOLS" | grep -qE '(^|[, ])Edit([, ]|$)'  && HAS_EDIT=1

  # ── Tools MCP: servidor precisa estar em reference/mcp-servers.md ──
  local mtok mserver
  for mtok in $(printf '%s\n' "$TOOLS" | grep -oE 'mcp__[A-Za-z0-9_-]+' | sort -u); do
    mserver="$(printf '%s' "$mtok" | sed -E 's/^mcp__//; s/__.*$//')"
    if [ ! -f "$MCP_FILE" ]; then
      errors+=("tools: $mtok — reference/mcp-servers.md ausente (tabela de servidores aceitos)")
      break
    fi
    if ! in_list "mcp__$mserver" "$MCP_ACCEPTED"; then
      errors+=("tools: servidor MCP '$mserver' ($mtok) não está em reference/mcp-servers.md — adicione o servidor à tabela antes")
    elif printf '%s' "$mtok" | grep -qE '^mcp__[A-Za-z0-9_-]+__'; then
      warnings+=("tools: $mtok usa a forma longa — prefira mcp__$mserver (libera todas as tools do servidor; nomes de tool mudam entre versões)")
    fi
  done

  if [ -n "$ARCH" ]; then
    # ── model por archetype ──
    case "$ARCH" in
      architect|reviewer|strategist)
        [ "$MODEL" != "opus" ] && errors+=("model: '$MODEL' — archetype $ARCH exige 'opus'") ;;
      *)
        [ "$MODEL" != "inherit" ] && errors+=("model: '$MODEL' — archetype $ARCH exige 'inherit'") ;;
    esac

    # ── effort por archetype (+ exceções canônicas) ──
    if [ -n "$EFFORT" ] && ! in_list "$EFFORT" "$EFFORT_ENUM"; then
      errors+=("effort: '$EFFORT' fora do enum ($EFFORT_ENUM)")
    fi
    local EXPECTED_EFFORT=""
    if in_list "$name" "$EFFORT_EXCEPTIONS_MEDIUM"; then
      EXPECTED_EFFORT="medium"
    else
      case "$ARCH" in
        architect|reviewer|strategist|hardening|data) EXPECTED_EFFORT="high" ;;
        researcher|ux)                                EXPECTED_EFFORT="medium" ;;
        implementer|devops)                           EXPECTED_EFFORT="" ;;
      esac
    fi
    if [ -n "$EXPECTED_EFFORT" ]; then
      [ "$EFFORT" != "$EXPECTED_EFFORT" ] && errors+=("effort: '$EFFORT' — esperado '$EXPECTED_EFFORT' (archetype $ARCH$(in_list "$name" "$EFFORT_EXCEPTIONS_MEDIUM" && printf ', exceção canônica'))")
    else
      [ -n "$EFFORT" ] && errors+=("effort: deve ser omitido (archetype $ARCH segue o default do modelo)")
    fi

    # ── permissionMode: obrigatório em todo archetype ──
    if [ -z "$PMODE" ]; then
      errors+=("permissionMode: ausente — obrigatório em todo archetype (reviewer/strategist: acceptEdits; demais: recomendado acceptEdits)")
    elif ! in_list "$PMODE" "$PERMISSION_ENUM"; then
      errors+=("permissionMode: '$PMODE' fora do enum ($PERMISSION_ENUM)")
    else
      case "$ARCH" in
        reviewer|strategist)
          [ "$PMODE" = "bypassPermissions" ] && errors+=("permissionMode: bypassPermissions é PROIBIDO em reviewer/strategist")
          [ "$PMODE" != "acceptEdits" ] && [ "$PMODE" != "bypassPermissions" ] && errors+=("permissionMode: '$PMODE' — archetype $ARCH exige 'acceptEdits'") ;;
      esac
    fi

    # ── color ──
    if [ -z "$COLOR" ]; then
      errors+=("color: ausente")
    elif ! in_list "$COLOR" "$COLOR_ENUM"; then
      errors+=("color: '$COLOR' fora do enum ($COLOR_ENUM)")
    else
      [ "$COLOR" = "blue" ] && errors+=("color: blue é reservado ao lead (main session) — proibido em teammates")
      [ "$ARCH" = "reviewer" ] && [ "$COLOR" != "red" ] && errors+=("color: '$COLOR' — QA/reviewer deve ser red")
      [ -n "$SQUAD" ] && echo "$SQUAD|$COLOR|$name" >> "$COLOR_FILE"
    fi

    # ── hook block-git-push.sh ──
    local HAS_HOOK=0
    printf '%s\n' "$FM" | grep -q 'block-git-push\.sh' && HAS_HOOK=1
    if [ "$ARCH" = "devops" ]; then
      [ $HAS_HOOK -eq 1 ] && errors+=("devops não pode ter block-git-push.sh (push é a autoridade exclusiva dele)")
    else
      [ $HAS_BASH -eq 1 ] && [ $HAS_HOOK -eq 0 ] && errors+=("falta hook block-git-push.sh (obrigatório: tem Bash e archetype '$ARCH' ≠ devops)")
    fi

    # ── tools mínimos por archetype ──
    case "$ARCH" in
      reviewer|strategist|implementer)
        { [ $HAS_WRITE -eq 0 ] || [ $HAS_EDIT -eq 0 ]; } && errors+=("tools: archetype $ARCH exige Write E Edit") ;;
    esac
  fi

  # ── hooks: estrutura (evento → [- matcher + hooks: [- type: command + command]]) ──
  if printf '%s\n' "$FM" | grep -qE '^hooks:'; then
    local HBLOCK hev n_matcher n_type n_cmd
    # bloco = linhas após "hooks:" até a próxima chave de topo (coluna 0)
    HBLOCK="$(printf '%s\n' "$FM" | awk '/^hooks:/{f=1; next} f && /^[A-Za-z]/{exit} f')"
    if ! printf '%s\n' "$HBLOCK" | grep -qE '^  [A-Za-z]+:'; then
      errors+=("hooks: declarado mas sem evento (esperado ex.: '  PreToolUse:')")
    fi
    for hev in $(printf '%s\n' "$HBLOCK" | grep -oE '^  [A-Za-z]+:' | tr -d ' :' | sort -u); do
      in_list "$hev" "$HOOK_EVENTS" || errors+=("hooks: evento desconhecido '$hev' (válidos: $HOOK_EVENTS)")
    done
    n_matcher="$(printf '%s\n' "$HBLOCK" | grep -cE '^    - matcher:')"
    n_type="$(printf '%s\n' "$HBLOCK" | grep -cE '^        - type: command')"
    n_cmd="$(printf '%s\n' "$HBLOCK" | grep -cE '^          command:')"
    [ "$n_matcher" -eq 0 ] && errors+=("hooks: nenhum '- matcher:' (cada evento é uma lista de {matcher, hooks})")
    printf '%s\n' "$HBLOCK" | grep -qE '^      hooks:' || errors+=("hooks: falta a lista 'hooks:' dentro do matcher")
    [ "$n_type" -eq 0 ] && errors+=("hooks: nenhum '- type: command' na lista hooks")
    [ "$n_type" -ne "$n_cmd" ] && errors+=("hooks: $n_type '- type: command' vs $n_cmd 'command:' — cada type precisa do seu command")
  fi

  # ── Hooks referenciados existem fisicamente ──
  local hook_ref
  for hook_ref in $(printf '%s\n' "$FM" | grep -oE '\.claude/hooks/[A-Za-z0-9._-]+\.sh' | sort -u); do
    [ -f "$hook_ref" ] || errors+=("hook referenciado não existe: $hook_ref")
  done

  # ── Bloco NTP byte-idêntico ao canônico ──
  if grep -q "^## Native Teams Protocol" "$file"; then
    local agent_ntp_hash
    agent_ntp_hash="$(awk '/^## Native Teams Protocol/{f=1} f{if(/^---$/) exit; print}' "$file" | trim_blank_edges | hash_text)"
    [ "$agent_ntp_hash" != "$NTP_HASH" ] && errors+=("bloco NTP divergente do canônico (reference/native-teams-protocol.md) — rode *migrate")
  fi

  # ── Área na smart-memory: linha obrigatória, squad = prefixo, logo após o H1 ──
  local AREA_LINE AREA_PATH AREA_SQUAD
  AREA_LINE="$(printf '%s\n' "$BODY" | grep -m1 '^\*\*Área na smart-memory:\*\*')"
  if [ -z "$AREA_LINE" ]; then
    errors+=("falta a linha '**Área na smart-memory:** \`docs/smart-memory/agents/$PREFIX/<área>/\`' (logo após o H1)")
  else
    AREA_PATH="$(printf '%s' "$AREA_LINE" | sed -n 's|^\*\*Área na smart-memory:\*\* `docs/smart-memory/agents/\([a-z][a-z0-9-]*/[a-z][a-z0-9-]*\)/`$|\1|p')"
    if [ -z "$AREA_PATH" ]; then
      errors+=("linha 'Área na smart-memory' fora do formato exato: **Área na smart-memory:** \`docs/smart-memory/agents/<squad>/<área>/\`")
    else
      AREA_SQUAD="${AREA_PATH%%/*}"
      [ "$AREA_SQUAD" != "$PREFIX" ] && errors+=("Área na smart-memory aponta para squad '$AREA_SQUAD' mas o agente é da squad '$PREFIX'")
    fi
    # posição: entre as 3 linhas seguintes ao H1 (warning)
    if ! printf '%s\n' "$BODY" | awk '/^# /{f=1; n=0; next} f{n++; if($0 ~ /^\*\*Área na smart-memory:\*\*/){print "ok"; exit} if(n>=3) exit}' | grep -q ok; then
      warnings+=("linha 'Área na smart-memory' não está logo após o H1 (até 3 linhas depois)")
    fi
  fi

  # ── Paths de smart-memory citados no body: sempre com squad; stories só nas 4 pastas ──
  local seg
  for seg in $(printf '%s\n' "$BODY" | grep -oE 'docs/smart-memory/agents/[a-z][a-z0-9-]*/' | sed 's|docs/smart-memory/agents/||; s|/$||' | sort -u); do
    in_list "$seg" "$KNOWN_SQUADS" || errors+=("cita docs/smart-memory/agents/$seg/ sem squad — use docs/smart-memory/agents/$PREFIX/$seg/")
  done
  printf '%s\n' "$BODY" | grep -q 'docs/smart-memory/pm/' && errors+=("cita docs/smart-memory/pm/ — o layout antigo virou docs/smart-memory/agents/pm/")
  for seg in $(printf '%s\n' "$BODY" | grep -oE '(^|[^A-Za-z0-9_./-])stories/[A-Za-z0-9_.{<-]+' | sed 's|.*stories/||' | sort -u); do
    case "$seg" in '{'*|'<'*) continue ;; esac   # placeholders: stories/{backlog,…}, stories/<status>/
    in_list "$seg" "$STORY_DIRS" || errors+=("cita stories/$seg — stories vivem só em stories/{backlog,active,in-review,done}/<id>-<slug>.md (+ stories/BACKLOG.md)")
  done

  # ── Skills citadas no body existem (com ou sem hífen; skill \`x\` também) ──
  local token skill
  for token in $( {
      printf '%s\n' "$BODY" | grep -oE '(^|[[:space:]`(])/[a-z][a-z0-9-]+([^]a-z0-9/._-]|$)' | sed -E 's|^[^/]*/||; s/[^a-z0-9-]$//'
      printf '%s\n' "$BODY" | grep -oE 'skill `[a-z][a-z0-9-]+`' | sed 's/^skill `//; s/`$//'
    } | sort -u); do
    skill="$token"
    in_list "$skill" "$SKILL_PLACEHOLDERS" && continue
    in_list "$skill" "$BUILTIN_SLASH" && continue
    in_list "$skill" "$PATH_WORDS" && continue
    [ -d "$SKILLS_DIR/$skill" ] && [ -f "$SKILLS_DIR/$skill/SKILL.md" ] || errors+=("skill citada no body não existe: /$skill (esperado $SKILLS_DIR/$skill/SKILL.md)")
  done

  # ── description: qualidade (warnings) ──
  if [ -n "$DESC" ]; then
    [ ${#DESC} -gt 500 ] && warnings+=("description com ${#DESC} chars (> 500) — description = só triggers")
    printf '%s' "$DESC" | grep -qE '(^|[[:space:]])[0-9]+[.)][[:space:]]' \
      && warnings+=("description contém passos numerados de workflow — mova para o body (description = só triggers)")
  fi

  # ── Personas (warnings) ──
  # (a) citação "Persona (agent-name)" desatualizada
  local cite cited_persona cited_agent current_persona
  while IFS= read -r cite; do
    [ -n "$cite" ] || continue
    cited_persona="${cite%% (*}"
    cited_agent="$(printf '%s' "$cite" | sed 's/.*(\(.*\))/\1/')"
    [ "$cited_agent" = "$name" ] && continue
    current_persona="$(grep -m1 "^$cited_agent|" "$GLOSS_FILE" | cut -d'|' -f3)"
    if [ -n "$current_persona" ] && [ "$current_persona" != "$cited_persona" ]; then
      warnings+=("cita persona '$cited_persona' para $cited_agent, mas o H1 atual dele é '$current_persona'")
    fi
  done <<EOF_CITES
$(printf '%s\n' "$BODY" | grep -oE '[A-Z][A-Za-z+]+ \((dev|sites|social|traffic|pm|sales|brand|finance|legal|seo)-[a-z][a-z-]+\)' | sort -u)
EOF_CITES
  # (b) persona de OUTRA squad citada no body
  if [ -n "$SQUAD" ]; then
    local gl_agent gl_squad gl_persona
    while IFS='|' read -r gl_agent gl_squad gl_persona; do
      [ -n "$gl_persona" ] || continue
      [ "$gl_squad" = "$SQUAD" ] && continue
      [ ${#gl_persona} -ge 3 ] || continue
      if printf '%s\n' "$BODY" | grep -qE "(^|[^A-Za-z])${gl_persona}([^A-Za-z]|$)"; then
        warnings+=("cita persona '$gl_persona' ($gl_agent, squad $gl_squad) — fora do glossário da squad $SQUAD")
      fi
    done < "$GLOSS_FILE"
  fi

  # ── Veredicto ──
  local w e
  if [ ${#errors[@]} -eq 0 ] && [ ${#warnings[@]} -eq 0 ]; then
    echo "✅ $name (${ARCH:-?})"
    return 0
  fi
  if [ ${#errors[@]} -eq 0 ]; then
    echo "⚠️  $name (${ARCH:-?}):"
    for w in "${warnings[@]}"; do echo "    ⚠ $w"; done
    WARNED=$((WARNED + 1))
    return 0
  fi
  echo "❌ $name (${ARCH:-?}):"
  for e in "${errors[@]}"; do echo "    • $e"; done
  for w in "${warnings[@]+"${warnings[@]}"}"; do echo "    ⚠ $w"; done
  PROBLEMS=$((PROBLEMS + 1))
  return 1
}

# ═════════════════════════════════════════════════════════════════════════════
: > "$COLOR_FILE"

if [ -n "${1:-}" ]; then
  FILE="$AGENTS_DIR/${1}.md"
  if [ ! -f "$FILE" ]; then
    echo "❌ Agente '$1' não encontrado em $AGENTS_DIR/" >&2
    exit 1
  fi
  CHECKED=1
  validate "$FILE"
else
  if [ ! -d "$AGENTS_DIR" ]; then
    echo "⛔ $AGENTS_DIR/ não existe"
    exit 1
  fi
  for f in "$AGENTS_DIR"/*.md; do
    [ -f "$f" ] || continue
    CHECKED=$((CHECKED + 1))
    validate "$f"
  done

  # ── Checks globais ──
  echo ""
  echo "── Checks globais ──"

  # entrada de preset sem arquivo de agente = ERRO
  while IFS='|' read -r p_agent p_squad p_arch p_persona; do
    [ -n "$p_agent" ] || continue
    if [ ! -f "$AGENTS_DIR/$p_agent.md" ]; then
      echo "❌ preset $p_squad declara '$p_agent' mas $AGENTS_DIR/$p_agent.md não existe"
      GLOBAL_ERRORS=$((GLOBAL_ERRORS + 1))
    fi
  done < "$MAP_FILE"

  # repetição de cor na mesma squad = WARNING — só quando a squad tem ≤ 8 agentes
  # (8 cores disponíveis; acima disso a repetição é inevitável)
  DUPS="$(cut -d'|' -f1,2 "$COLOR_FILE" | sort | uniq -d)"
  DUPS_REPORTED=0
  if [ -n "$DUPS" ]; then
    while IFS='|' read -r d_squad d_color; do
      [ -n "$d_squad" ] || continue
      SQUAD_SIZE="$(grep -c "^$d_squad|" "$COLOR_FILE")"
      [ "$SQUAD_SIZE" -gt "$COLOR_LIMIT" ] && continue
      AGENTS_W_COLOR="$(grep "^$d_squad|$d_color|" "$COLOR_FILE" | cut -d'|' -f3 | tr '\n' ' ')"
      echo "⚠️  squad $d_squad ($SQUAD_SIZE agentes): cor '$d_color' repetida em: $AGENTS_W_COLOR"
      WARNED=$((WARNED + 1)); DUPS_REPORTED=1
    done <<EOF_DUPS
$DUPS
EOF_DUPS
  fi

  # contagens: arquivos reais vs linha "N agentes e N skills" (CLAUDE.md e README.md) = WARNING
  AGENTS_COUNT=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  PRESET_COUNT=$(wc -l < "$MAP_FILE" | tr -d ' ')
  if [ "$AGENTS_COUNT" != "$PRESET_COUNT" ]; then
    echo "⚠️  $AGENTS_COUNT arquivo(s) em $AGENTS_DIR vs $PRESET_COUNT entrada(s) nos presets"
    WARNED=$((WARNED + 1))
  fi
  for doc in CLAUDE.md README.md; do
    [ -f "$doc" ] || continue
    DOC_LINE="$(grep -m1 -oE '[0-9]+ agentes e [0-9]+ skills' "$doc")"
    [ -n "$DOC_LINE" ] || continue
    DOC_AGENTS="$(printf '%s' "$DOC_LINE" | awk '{print $1}')"
    DOC_SKILLS="$(printf '%s' "$DOC_LINE" | awk '{print $4}')"
    if [ "$DOC_AGENTS" != "$AGENTS_COUNT" ]; then
      echo "⚠️  $doc diz '$DOC_AGENTS agentes' mas $AGENTS_DIR tem $AGENTS_COUNT arquivos"
      WARNED=$((WARNED + 1))
    fi
    if [ "$DOC_SKILLS" != "$SKILLS_COUNT" ]; then
      echo "⚠️  $doc diz '$DOC_SKILLS skills' mas $SKILLS_DIR tem $SKILLS_COUNT skills (com SKILL.md)"
      WARNED=$((WARNED + 1))
    fi
  done
  [ $GLOBAL_ERRORS -eq 0 ] && [ $DUPS_REPORTED -eq 0 ] && echo "(sem erros globais)"
fi

echo ""
TOTAL_ERR=$((PROBLEMS + GLOBAL_ERRORS))
if [ $TOTAL_ERR -eq 0 ]; then
  if [ $WARNED -gt 0 ]; then
    echo "✅ $CHECKED agente(s) sem erro — $WARNED item(ns) com warning."
  else
    echo "✅ Todos $CHECKED agente(s) conforme(s)."
  fi
  exit 0
else
  echo "❌ $PROBLEMS agente(s) com erro + $GLOBAL_ERRORS erro(s) global(is), de $CHECKED verificado(s)."
  exit 1
fi
