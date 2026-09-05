#!/usr/bin/env bash
# validate-agent.sh — *audit v2, archetype-driven
#
# Usage: ./validate-agent.sh [<name>]
#   sem args  → valida todos os agentes de .claude/agents/ + checks globais
#   <name>    → valida só .claude/agents/<name>.md (sem checks globais)
#
# Fontes da verdade:
#   - presets/*.yaml ............ archetype + squad + persona de cada agente
#   - reference/native-teams-protocol.md ... bloco NTP canônico (hash byte-idêntico)
#   - reference/archetypes.md ... defaults documentados (este script implementa as regras)
#
# Regras por ARCHETYPE (não por nome hardcoded):
#   model  : architect/reviewer/strategist → opus; demais → inherit
#   effort : architect/reviewer/strategist/hardening/data → high;
#            researcher/ux → medium; implementer/devops → omitido
#            EXCEÇÕES canônicas: dev-bi, dev-data-performance, pm-coach → medium
#   permissionMode: obrigatório (qualquer valor do enum; recomendado acceptEdits) em
#            qualquer agente com Write/Edit em tools — exceto reviewer/strategist,
#            onde é opcional; bypassPermissions proibido em reviewer/strategist;
#            valor sempre no enum
#   color  : enum red/blue/green/yellow/purple/orange/pink/cyan; blue proibido em
#            teammates; reviewer (QA) deve ser red; repetição na squad = warning
#   hook   : block-git-push.sh obrigatório em todo agente com Bash cujo archetype
#            NÃO é devops; proibido em archetype devops
#   tools  : reviewer/strategist e implementer devem ter Write E Edit
#   NTP    : bloco "## Native Teams Protocol" byte-idêntico ao canônico (hash md5,
#            após remover linhas em branco iniciais/finais)
#
# Extração de PERSONA (padrão documentado): a persona de um agente é o texto do
# primeiro H1 antes de " — " (em dash), ex.: "# Nova — Frontend Developer" → "Nova".
# O glossário de personas é construído a partir dos H1 de todos os agentes.
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

COLOR_ENUM="red blue green yellow purple orange pink cyan"
PERMISSION_ENUM="default acceptEdits auto dontAsk bypassPermissions plan"
EFFORT_ENUM="low medium high xhigh max"
# Exceções canônicas de effort (documentadas em reference/archetypes.md)
EFFORT_EXCEPTIONS_MEDIUM="dev-bi dev-data-performance pm-coach"
# Placeholders instrucionais que NÃO são citação de skill
SKILL_PLACEHOLDERS="nome-da-skill nome-skill skill-name nome-da-sua-skill sua-skill"
# Slash commands built-in do Claude Code com hífen (não são skills)
BUILTIN_SLASH="install-slack-app terminal-setup release-notes pr-comments add-dir output-style statusline-setup skill-doctor"

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

# ── Pré-requisito: bloco NTP canônico ────────────────────────────────────────
if [ ! -f "$NTP_FILE" ]; then
  echo "⛔ Fonte canônica do NTP ausente: $NTP_FILE" >&2
  exit 1
fi
NTP_HASH="$(awk '/<!-- NTP-START -->/{f=1;next} /<!-- NTP-END -->/{f=0} f' "$NTP_FILE" | trim_blank_edges | hash_text)"

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

    # ── permissionMode ──
    if [ -n "$PMODE" ] && ! in_list "$PMODE" "$PERMISSION_ENUM"; then
      errors+=("permissionMode: '$PMODE' fora do enum ($PERMISSION_ENUM)")
    fi
    case "$ARCH" in
      reviewer|strategist)
        [ "$PMODE" = "bypassPermissions" ] && errors+=("permissionMode: bypassPermissions é PROIBIDO em reviewer/strategist") ;;
      *)
        if [ $HAS_WRITE -eq 1 ] || [ $HAS_EDIT -eq 1 ]; then
          [ -z "$PMODE" ] && errors+=("permissionMode: obrigatório (tem Write/Edit em tools; recomendado 'acceptEdits')")
        fi ;;
    esac

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

  # ── Skills citadas no body existem ──
  local token skill
  for token in $(printf '%s\n' "$BODY" | grep -oE '(^|[[:space:]`(])/[a-z][a-z0-9]*(-[a-z0-9]+)+' | sed 's|^[^/]*/||' | sort -u); do
    skill="$token"
    in_list "$skill" "$SKILL_PLACEHOLDERS" && continue
    in_list "$skill" "$BUILTIN_SLASH" && continue
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
$(printf '%s\n' "$BODY" | grep -oE '[A-Z][A-Za-z+]+ \((dev|sites|social|traffic|pm)-[a-z][a-z-]+\)' | sort -u)
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

  # repetição de cor na mesma squad = WARNING
  DUPS="$(cut -d'|' -f1,2 "$COLOR_FILE" | sort | uniq -d)"
  if [ -n "$DUPS" ]; then
    while IFS='|' read -r d_squad d_color; do
      [ -n "$d_squad" ] || continue
      AGENTS_W_COLOR="$(grep "^$d_squad|$d_color|" "$COLOR_FILE" | cut -d'|' -f3 | tr '\n' ' ')"
      echo "⚠️  squad $d_squad: cor '$d_color' repetida em: $AGENTS_W_COLOR"
      WARNED=$((WARNED + 1))
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
  [ $GLOBAL_ERRORS -eq 0 ] && [ -z "$DUPS" ] && echo "(sem erros globais)"
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
