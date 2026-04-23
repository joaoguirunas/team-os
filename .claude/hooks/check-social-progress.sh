#!/usr/bin/env bash
# ~/.claude/hooks/check-social-progress.sh
# TeammateIdle hook — detecta agentes social-* parados sem notificar SIRIA
# Exit 0: ok, agente pode ficar idle
# Exit 2: feedback ao Chief com situação

THRESHOLD_MINUTES=45
NOW=$(date +%s)
CAMPAIGNS_DIR="social-media/campaigns"

if [ ! -d "$CAMPAIGNS_DIR" ]; then
  exit 0
fi

STUCK=""

# Para cada campanha activa, verificar assets esperados
for campaign_dir in "$CAMPAIGNS_DIR"/*/; do
  [ -d "$campaign_dir" ] || continue
  CAMPAIGN_ID=$(basename "$campaign_dir")

  # Verificar se brief existe (campanha activa)
  [ -f "${campaign_dir}brief.md" ] || continue

  # Verificar se validação já existe (campanha concluída)
  if [ -f "${campaign_dir}validation.md" ]; then
    grep -q "Aprovação: VERA" "${campaign_dir}validation.md" 2>/dev/null && continue
  fi

  check_asset_phase() {
    local asset_path="$1"
    local phase_name="$2"
    local agent_name="$3"

    if [ ! -d "$asset_path" ] && [ ! -f "$asset_path" ]; then
      return
    fi

    local mtime
    mtime=$(stat -f %m "$asset_path" 2>/dev/null || stat -c %Y "$asset_path" 2>/dev/null)
    [ -z "$mtime" ] && return

    local minutes_elapsed=$(( (NOW - mtime) / 60 ))
    if [ "$minutes_elapsed" -ge "$THRESHOLD_MINUTES" ]; then
      STUCK="${STUCK}\n- Campanha: ${CAMPAIGN_ID} | Fase: ${phase_name} | Agente: ${agent_name} | Último update: ${minutes_elapsed}min atrás"
    fi
  }

  check_asset_phase "${campaign_dir}copy" "Copy/Research" "LYRIS"
  check_asset_phase "${campaign_dir}assets/design" "Design" "AEON"
  check_asset_phase "${campaign_dir}assets/photos/raw" "Fotos" "IRIS"
  check_asset_phase "${campaign_dir}assets/videos/raw" "Vídeo" "FLUX"
done

if [ -n "$STUCK" ]; then
  echo -e "⚠️  Fases possivelmente paradas (>${THRESHOLD_MINUTES}min sem update):${STUCK}\n\nVerificar via SendMessage direto a cada agente. Possíveis causas: bloqueado por falta de assets, erro no MCP, aguardando direcção."
  exit 2
fi

exit 0
