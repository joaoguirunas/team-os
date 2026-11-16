#!/usr/bin/env bash
# check-resources.sh — mede a máquina do usuário ANTES de um processo local pesado
# (transcrição, modelo de IA local, render de vídeo, build grande, lote em paralelo)
# e diz quantos jobs cabem ao mesmo tempo sem travar o computador.
#
# Só leitura: não instala, não mata processo, não grava nada.
#
# Usage: check-resources.sh [--per-job-gb N] [--threads-per-job N] [--reserve-gb N]
#   --per-job-gb N       memória que UM job usa (ver tabela da skill machine-resources §2).
#                        Sem a flag: só mede, sem calcular MAX_PARALLEL.
#   --threads-per-job N  núcleos que UM job ocupa. Default: todos (a maioria dos processos
#                        pesados — whisper, ffmpeg, LLM local, build — usa todos os núcleos).
#   --reserve-gb N       memória que fica livre para o sistema, o Claude e o navegador.
#                        Default: o maior entre 4 GB e 25% da RAM total.
#
# Saída (chave=valor):
#   OS · CPU_CORES · RAM_TOTAL_GB · RAM_AVAILABLE_GB · SWAP_USED_GB · MEM_FREE_PCT (macOS)
#   LOAD_1M · DISK_FREE_GB · RESERVE_GB · TOP_PROC=<rss_gb>|<comando> (5 maiores)
#   com --per-job-gb: PER_JOB_GB · MAX_PARALLEL · VERDICT=ok|apertado|parar · ADVICE=<frase>
#
# Bash 3.2 / macOS e Linux — sem mapfile, sem declare -A, sem grep -P.

set -u

PER_JOB=""
THREADS=""
RESERVE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --per-job-gb)      [ $# -ge 2 ] || { echo "⛔ --per-job-gb exige um valor" >&2; exit 2; }; PER_JOB="$2"; shift 2 ;;
    --threads-per-job) [ $# -ge 2 ] || { echo "⛔ --threads-per-job exige um valor" >&2; exit 2; }; THREADS="$2"; shift 2 ;;
    --reserve-gb)      [ $# -ge 2 ] || { echo "⛔ --reserve-gb exige um valor" >&2; exit 2; }; RESERVE="$2"; shift 2 ;;
    -h|--help)         sed -n '2,22p' "$0"; exit 0 ;;
    *)                 echo "⛔ argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

# divisão com 1 casa decimal (awk existe em macOS e Linux)
gb() { awk -v b="$1" 'BEGIN{printf "%.1f", b/1073741824}'; }

OS="$(uname -s)"
CORES=1; TOTAL_B=0; AVAIL_B=0; SWAP_B=0; FREE_PCT=""

if [ "$OS" = "Darwin" ]; then
  CORES="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
  TOTAL_B="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
  PAGE="$(vm_stat | awk '/page size of/ {for(i=1;i<=NF;i++) if($i=="of"){print $(i+1); exit}}')"
  [ -n "$PAGE" ] || PAGE=4096
  # disponível ≈ livre + inativa + especulativa + purgeable (o que o macOS devolve sem swap)
  PAGES="$(vm_stat | awk -F: '/Pages free|Pages inactive|Pages speculative|Pages purgeable/ {gsub(/[ .]/,"",$2); s+=$2} END{print s+0}')"
  AVAIL_B=$(awk -v p="$PAGES" -v s="$PAGE" 'BEGIN{printf "%.0f", p*s}')
  SWAP_B="$(sysctl -n vm.swapusage 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="used"){v=$(i+2); u=substr(v,length(v)); n=v+0; if(u=="G") n*=1024; print n*1048576; exit}}')"
  FREE_PCT="$(memory_pressure -Q 2>/dev/null | awk -F: '/free percentage/ {gsub(/[ %]/,"",$2); print $2}')"
  # o próprio macOS conta também a memória comprimível: quando ele responde, vale o número dele
  if [ -n "$FREE_PCT" ]; then
    AVAIL_B=$(awk -v t="$TOTAL_B" -v p="$FREE_PCT" 'BEGIN{printf "%.0f", t*p/100}')
  fi
  LOAD="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')"
else
  CORES="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  TOTAL_B="$(awk '/^MemTotal:/ {print $2*1024}' /proc/meminfo 2>/dev/null || echo 0)"
  AVAIL_B="$(awk '/^MemAvailable:/ {print $2*1024}' /proc/meminfo 2>/dev/null || echo 0)"
  SWAP_B="$(awk '/^SwapTotal:/ {t=$2} /^SwapFree:/ {f=$2} END{print (t-f)*1024}' /proc/meminfo 2>/dev/null || echo 0)"
  LOAD="$(awk '{print $1}' /proc/loadavg 2>/dev/null)"
fi
[ -n "${SWAP_B:-}" ] || SWAP_B=0
[ -n "${LOAD:-}" ] || LOAD="?"

DISK_FREE_B="$(df -k . 2>/dev/null | awk 'NR==2 {print $4*1024}')"
[ -n "$DISK_FREE_B" ] || DISK_FREE_B=0

TOTAL_GB="$(gb "$TOTAL_B")"
AVAIL_GB="$(gb "$AVAIL_B")"
if [ -z "$RESERVE" ]; then
  RESERVE="$(awk -v t="$TOTAL_GB" 'BEGIN{r=t*0.25; if(r<4) r=4; printf "%.1f", r}')"
fi

echo "OS=$OS"
echo "CPU_CORES=$CORES"
echo "RAM_TOTAL_GB=$TOTAL_GB"
echo "RAM_AVAILABLE_GB=$AVAIL_GB"
echo "SWAP_USED_GB=$(gb "$SWAP_B")"
[ -n "$FREE_PCT" ] && echo "MEM_FREE_PCT=$FREE_PCT"
echo "LOAD_1M=$LOAD"
echo "DISK_FREE_GB=$(gb "$DISK_FREE_B")"
echo "RESERVE_GB=$RESERVE"

# 5 processos que mais usam memória (rss em KB no ps de macOS e Linux)
ps -axo rss=,comm= 2>/dev/null | sort -rn | head -5 | while read -r rss cmd; do
  printf 'TOP_PROC=%s|%s\n' "$(awk -v k="$rss" 'BEGIN{printf "%.1f", k/1048576}')" "$(basename "$cmd")"
done

[ -n "$PER_JOB" ] || exit 0

[ -n "$THREADS" ] || THREADS="$CORES"
echo "PER_JOB_GB=$PER_JOB"

# MAX_PARALLEL = menor entre o limite de memória e o de CPU
read -r MAXP VERDICT <<EOF
$(awk -v a="$AVAIL_GB" -v r="$RESERVE" -v j="$PER_JOB" -v c="$CORES" -v t="$THREADS" -v sw="$(gb "$SWAP_B")" -v fp="${FREE_PCT:-100}" 'BEGIN{
  if (j <= 0) { print "0 parar"; exit }
  mem = int((a - r) / j); if (mem < 0) mem = 0
  cpu = int(c / t); if (cpu < 1) cpu = 1
  m = (mem < cpu) ? mem : cpu
  if (m >= 1 && fp >= 20) v = "ok"
  else if (a >= j + 1) { m = 1; v = "apertado" }
  else { m = 0; v = "parar" }
  print m, v
}')
EOF

echo "MAX_PARALLEL=$MAXP"
echo "VERDICT=$VERDICT"
case "$VERDICT" in
  ok)       echo "ADVICE=Rode no máximo $MAXP job(s) ao mesmo tempo e confira a memória entre um lote e outro." ;;
  apertado) echo "ADVICE=Cabe só 1 job por vez e sem folga: feche o que não usa (navegador, apps pesados) ou use um modelo menor." ;;
  parar)    echo "ADVICE=Não rode agora: a memória livre não cabe nem 1 job. Feche programas, use um modelo menor ou rode em nuvem." ;;
esac
exit 0
