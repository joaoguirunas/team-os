#!/usr/bin/env bash
# .claude/hooks/check-story-progress.sh
# SubagentStop hook — varre stories ativas e alerta se algum agente dev-dev-*
# iniciou story mas não registrou conclusão dentro do threshold.
# Dispara toda vez que um subagente termina; o Chief recebe o alerta e intervém.
# Exit 0: nenhuma story travada detectada
# Exit 2: feedback ao Chief com lista de stories suspeitas

THRESHOLD_HOURS=2
NOW=$(date +%s)
ACTIVE_DIR="docs/smart-memory/stories/active"

if [ ! -d "$ACTIVE_DIR" ]; then
  exit 0
fi

STUCK_STORIES=""

for story_file in "$ACTIVE_DIR"/*.md; do
  [ -f "$story_file" ] || continue

  # Checar se tem Iniciado preenchido mas Concluído vazio
  INICIADO=$(grep -m1 "| Iniciado" "$story_file" | grep -v "| — |" | awk -F'|' '{print $3}' | xargs)
  CONCLUIDO=$(grep -m1 "| Concluído" "$story_file" | awk -F'|' '{print $3}' | xargs)
  AGENTE=$(grep -m1 "| Agente" "$story_file" | grep -v "| — |" | awk -F'|' '{print $3}' | xargs)
  STORY_NAME=$(basename "$story_file" .md)

  # Se tem Iniciado preenchido e Concluído está vazio/traço
  if [ -n "$INICIADO" ] && [ "$INICIADO" != "—" ] && { [ -z "$CONCLUIDO" ] || [ "$CONCLUIDO" = "—" ]; }; then

    # Tentar parsear data do Iniciado (formato: YYYY-MM-DD)
    START_DATE=$(echo "$INICIADO" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    if [ -n "$START_DATE" ]; then
      START_TS=$(date -d "$START_DATE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$START_DATE" +%s 2>/dev/null)
      if [ -n "$START_TS" ]; then
        HOURS_ELAPSED=$(( (NOW - START_TS) / 3600 ))
        if [ "$HOURS_ELAPSED" -ge "$THRESHOLD_HOURS" ]; then
          STUCK_STORIES="${STUCK_STORIES}\n- Story ${STORY_NAME} | Agente: ${AGENTE} | Iniciada: ${INICIADO} (${HOURS_ELAPSED}h atrás)"
        fi
      fi
    fi
  fi
done

if [ -n "$STUCK_STORIES" ]; then
  echo -e "⚠️  Agentes possivelmente travados detectados (>${THRESHOLD_HOURS}h sem conclusão registrada):${STUCK_STORIES}\n\nVerificar via SendMessage direto a cada agente. Possíveis causas: erro não reportado, aguardando dependência, esqueceu de atualizar story."
  exit 2
fi

exit 0
