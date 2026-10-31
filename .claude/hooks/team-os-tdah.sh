#!/usr/bin/env bash
# .claude/hooks/team-os-tdah.sh
# SessionStart hook — modo TDAH do team-os: respostas curtas, ação primeiro, sem jargão.
#
# Como funciona:
# - Só age se o modo estiver ligado: existe o arquivo ${CLAUDE_CONFIG_DIR:-~/.claude}/.team-os-tdah
#   (criado por `/team-os *tdah`, removido por `*tdah off`). TEAM_OS_TDAH=0 desliga sem mexer no arquivo.
# - Lê as regras de .claude/skills/team-os/reference/modo-tdah.md do projeto (cwd do JSON ou
#   CLAUDE_PROJECT_DIR); sem a skill no projeto, usa a cópia team-os-tdah.md ao lado deste hook.
# - Imprime as regras (sem o frontmatter) no stdout — o SessionStart as injeta no contexto da sessão.
#   Roda também em resume/clear/compact: as regras voltam depois de cada compactação.
# - Nunca bloqueia: qualquer falha sai 0 sem saída.
#
# Registro: SessionStart em ~/.claude/settings.json (global), feito pelo team-os/scripts/tdah.sh on.

[ "${TEAM_OS_TDAH:-}" = "0" ] && exit 0

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
[ -f "$CFG/.team-os-tdah" ] || exit 0

INPUT=$(cat 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
  | sed 's/"cwd"[[:space:]]*:[[:space:]]*"//;s/"$//')

REL=".claude/skills/team-os/reference/modo-tdah.md"
HERE=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
RULES=""
for f in "${CWD:+$CWD/$REL}" "${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/$REL}" "$HERE/team-os-tdah.md"; do
  [ -n "$f" ] && [ -f "$f" ] && { RULES="$f"; break; }
done
[ -n "$RULES" ] || exit 0

echo "MODO TDAH LIGADO (team-os). As regras abaixo valem para toda resposta ao usuário nesta sessão."
echo "Desligar: /team-os *tdah off (ou \"modo normal\")."
echo ""
# Remove o frontmatter YAML do topo (--- … ---)
awk 'NR==1 && /^---[[:space:]]*$/ {fm=1; next} fm && /^---[[:space:]]*$/ {fm=0; next} !fm' "$RULES" 2>/dev/null
exit 0
