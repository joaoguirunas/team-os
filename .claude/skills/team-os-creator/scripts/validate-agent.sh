#!/usr/bin/env bash
# validate-agent.sh — valida um agente criado (ou todos se sem args)
# Usage: ./validate-agent.sh [<name>]
# Exit 0: conforme
# Exit 1: um ou mais não conformes

PROBLEMS=0
CHECKED=0

validate() {
  local file="$1"
  local name=$(basename "$file" .md)
  local issues=()

  # Check 1: frontmatter presente e válido
  if ! head -1 "$file" | grep -q '^---$'; then
    issues+=("sem frontmatter no topo")
  fi

  # Check 2: name: no frontmatter bate com filename
  FM_NAME=$(awk '/^---$/{c++; if(c==2)exit} c==1 && /^name:/{sub("^name:[[:space:]]*",""); print; exit}' "$file")
  if [ "$FM_NAME" != "$name" ]; then
    issues+=("name:'$FM_NAME' não bate com arquivo '$name'")
  fi

  # Check 3: description: não vazia
  if ! awk '/^---$/{c++; if(c==2)exit} c==1' "$file" | grep -qE '^description:[[:space:]]+.+'; then
    issues+=("description: vazia ou ausente")
  fi

  # Check 4: memory: project (RULE #1 — estrito)
  if ! awk '/^---$/{c++; if(c==2)exit} c==1' "$file" | grep -qE '^memory:[[:space:]]*project[[:space:]]*$'; then
    issues+=("memory: deve ser exatamente 'project' (RULE #1)")
  fi

  # Check 5: model: definido
  if ! awk '/^---$/{c++; if(c==2)exit} c==1' "$file" | grep -qE '^model:[[:space:]]+'; then
    issues+=("model: ausente")
  fi

  # Check 6: tools: presente
  if ! awk '/^---$/{c++; if(c==2)exit} c==1' "$file" | grep -q '^tools:'; then
    issues+=("tools: ausente")
  fi

  # Check 7: Native Teams Protocol presente (padrão atual)
  if ! grep -q "Native Teams Protocol" "$file"; then
    issues+=("sem seção 'Native Teams Protocol'")
  fi

  # Check 7b: regressão — não pode conter o padrão antigo
  if grep -q "Contrato com team-os" "$file"; then
    issues+=("ainda contém padrão antigo 'Contrato com team-os' — rode *migrate")
  fi

  # Check 8: menciona smart-memory
  if ! grep -qi "smart-memory" "$file"; then
    issues+=("não menciona smart-memory")
  fi

  # Check 9: menciona SendMessage
  if ! grep -q "SendMessage" "$file"; then
    issues+=("não menciona SendMessage")
  fi

  # Check 10: tem H1 (título principal)
  if ! grep -q "^# " "$file"; then
    issues+=("sem heading H1")
  fi

  # ── Checks 11-15: regras do ecossistema (garantias duras) ──
  local FM
  FM=$(awk '/^---$/{c++; if(c==2)exit} c==1' "$file")

  # Check 11: campo skills: proibido no frontmatter (ignorado em Agent Teams)
  if printf '%s\n' "$FM" | grep -qE '^skills:'; then
    issues+=("campo skills: no frontmatter é proibido (ignorado em Agent Teams — remova)")
  fi

  # Check 12: campo isolation: proibido (worktrees banidos — branch ativa sempre)
  if printf '%s\n' "$FM" | grep -qE '^isolation:'; then
    issues+=("campo isolation: proibido — agentes trabalham direto na branch ativa")
  fi

  # Check 13: hook block-git-push.sh — obrigatório em dev-*/sites-* não-devops e social-video;
  # proibido no frontmatter dos devops (push é autoridade exclusiva deles)
  local has_hook=0
  printf '%s\n' "$FM" | grep -q 'block-git-push.sh' && has_hook=1
  case "$name" in
    dev-devops|sites-devops)
      [ "$has_hook" -eq 1 ] && issues+=("devops não pode ter block-git-push.sh no frontmatter (push é a autoridade dele)") ;;
    dev-*|sites-*|social-video)
      [ "$has_hook" -eq 0 ] && issues+=("falta hook block-git-push.sh no frontmatter (obrigatório em não-devops com Bash das squads de código)") ;;
  esac

  # Check 14: política de modelos (Híbrido) — opus fixo nos 8 canônicos, inherit nos demais
  local MODEL
  MODEL=$(printf '%s\n' "$FM" | grep -m1 -E '^model:' | sed -E 's/^model:[[:space:]]*//; s/[[:space:]]*$//')
  case "$name" in
    dev-architect|sites-architect|dev-qa|sites-qa|pm-qa|traffic-qa|traffic-strategist|social-strategist)
      [ "$MODEL" != "opus" ] && issues+=("model: deve ser 'opus' (architect/QA/strategist — política Híbrido)") ;;
    *)
      [ "$MODEL" != "inherit" ] && issues+=("model: deve ser 'inherit' (só architects/QAs/strategists usam opus fixo)") ;;
  esac

  # Check 15: política de effort por papel
  local EFFORT
  EFFORT=$(printf '%s\n' "$FM" | grep -m1 -E '^effort:' | sed -E 's/^effort:[[:space:]]*//; s/[[:space:]]*$//')
  if [ -n "$EFFORT" ] && ! printf '%s' "$EFFORT" | grep -qE '^(low|medium|high|xhigh|max)$'; then
    issues+=("effort: '$EFFORT' inválido (low/medium/high/xhigh/max)")
  fi
  case "$name" in
    dev-architect|sites-architect|dev-qa|sites-qa|pm-qa|traffic-qa|traffic-strategist|social-strategist|dev-dev-delta|sites-dev-delta|dev-data-engineer|sites-data|pm-data|pm-planner|pm-coach)
      [ "$EFFORT" != "high" ] && issues+=("effort: deve ser 'high' (architect/QA/strategist/hardening/data)") ;;
    dev-analyst|sites-analyst|social-analyst|traffic-analyst|pm-analyst|dev-ux|sites-ux|dev-bi|traffic-bi|dev-data-performance)
      [ "$EFFORT" != "medium" ] && issues+=("effort: deve ser 'medium' (researcher/ux/BI)") ;;
    dev-dev-alpha|dev-dev-beta|dev-dev-gamma|sites-dev-alpha|sites-dev-beta|sites-dev-gamma|dev-devops|sites-devops)
      [ -n "$EFFORT" ] && issues+=("effort: deve ser omitido (implementer/devops seguem o default)") ;;
  esac

  if [ ${#issues[@]} -eq 0 ]; then
    echo "✅ $name"
    return 0
  fi

  echo "❌ $name:"
  for issue in "${issues[@]}"; do
    echo "    • $issue"
  done
  PROBLEMS=$((PROBLEMS + 1))
  return 1
}

# Resolver a raiz do repo — funciona de qualquer cwd
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

if [ -n "$1" ]; then
  # Validar um específico
  FILE=".claude/agents/${1}.md"
  if [ ! -f "$FILE" ]; then
    echo "❌ Agente '$1' não encontrado em .claude/agents/" >&2
    exit 1
  fi
  CHECKED=1
  validate "$FILE"
else
  # Validar todos
  if [ ! -d ".claude/agents" ]; then
    echo "⛔ .claude/agents/ não existe"
    exit 1
  fi
  for f in .claude/agents/*.md; do
    [ -f "$f" ] || continue
    CHECKED=$((CHECKED + 1))
    validate "$f"
  done
fi

echo ""
if [ $PROBLEMS -eq 0 ]; then
  echo "✅ Todos $CHECKED agente(s) conforme(s)."
  exit 0
else
  echo "⚠️  $PROBLEMS de $CHECKED não conforme(s)."
  exit 1
fi
