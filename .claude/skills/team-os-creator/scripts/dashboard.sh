#!/usr/bin/env bash
# dashboard.sh — Command Center do team-os-creator
# Roda o scan e renaderiza o painel de status dos projetos irmãos + as 3 ações.
# Determinístico: mesma entrada → mesma saída. Usado pela skill ao abrir /team-os-creator.
# Usage: dashboard.sh [CT_ROOT]

HERE="$(cd "$(dirname "$0")" && pwd)"
SCAN="$HERE/scan-ct-projects.sh"

if [ ! -f "$SCAN" ]; then
  echo "ERRO: scan-ct-projects.sh não encontrado em $HERE" >&2
  exit 1
fi

RAW="$(bash "$SCAN" "$@")"

field() { printf '%s' "$1" | tr '|' '\n' | grep "^$2=" | cut -d= -f2-; }

ct_root="$(printf '%s\n' "$RAW" | grep '^CT_ROOT=' | cut -d= -f2-)"
src_agents="$(printf '%s\n' "$RAW" | grep '^SOURCE_AGENTS=' | cut -d= -f2-)"

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  team-os-creator  ·  Command Center  ·  by João Guirunas            ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo
echo "  CT (fonte): ${src_agents:-?} agentes  ·  root: $ct_root"
echo
printf "  %-24s %-8s %-8s %-13s %s\n" "PROJETO" "team-os" "agentes" "smart-mem" "DRIFT vs CT"
printf "  %-24s %-8s %-8s %-13s %s\n" "------------------------" "-------" "-------" "-------------" "-----------"

projects=0
need_update=0
not_installed=0

while IFS= read -r line; do
  case "$line" in PROJECT=*) ;; *) continue ;; esac

  name="$(field "$line" PROJECT)"
  is_current="$(field "$line" IS_CURRENT)"
  [ "$is_current" = "1" ] && continue   # pula o próprio CT

  projects=$((projects + 1))
  has_agents="$(field "$line" HAS_AGENTS)"
  acount="$(field "$line" AGENT_COUNT)"
  has_team_os="$(field "$line" HAS_TEAM_OS)"
  has_sm="$(field "$line" HAS_SMART_MEMORY)"
  d_ok="$(field "$line" DRIFT_OK)"
  d_out="$(field "$line" DRIFT_OUTDATED)"
  d_extra="$(field "$line" DRIFT_EXTRA)"
  d_miss="$(field "$line" DRIFT_MISSING)"

  tos=$([ "$has_team_os" = "1" ] && echo "sim" || echo "--")
  sm=$([ "$has_sm" = "1" ] && echo "sim" || echo "--")

  if [ "$has_agents" != "1" ] || [ "${acount:-0}" -eq 0 ]; then
    drift="nao instalado"
    not_installed=$((not_installed + 1))
  elif [ "${d_out:-0}" -gt 0 ] || [ "${d_miss:-0}" -gt 0 ]; then
    drift="! ${d_out:-0} desatual. / ${d_miss:-0} ausentes"
    need_update=$((need_update + 1))
  else
    drift="em dia"
  fi

  printf "  %-24.24s %-8s %-8s %-13s %s\n" "$name" "$tos" "${acount:-0}" "$sm" "$drift"
done <<EOF
$RAW
EOF

echo
echo "  Resumo: $projects projeto(s)  ·  $need_update precisam atualizar  ·  $not_installed sem squad"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [1] Criar equipe      → novos agentes/squad (*create / *squad)"
echo "  [2] Atualizar equipes → propaga o drift detectado (*propagate)"
echo "  [3] Instalar equipe   → squad + skills + team-os num projeto (*install)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
