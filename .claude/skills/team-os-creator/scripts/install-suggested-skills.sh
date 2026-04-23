#!/usr/bin/env bash
# install-suggested-skills.sh — instala 1 ou N skills via skills.sh CLI
# Usage: ./install-suggested-skills.sh <owner/repo> <skill-slug>
#   OR bulk: passa pela stdin, uma por linha: owner/repo@slug
# Sempre limpa .agents/ extra criada pelo CLI

install_one() {
  local repo="$1"
  local slug="$2"

  # Skip se já instalada
  if [ -d ".claude/skills/$slug" ]; then
    echo "⏭  $slug já instalada, pulando"
    return 0
  fi

  echo "⬇️  Instalando $repo → $slug..."
  if npx --yes skills add "$repo" -s "$slug" -y --copy >/dev/null 2>&1; then
    echo "✅ $slug instalada"
  else
    echo "⚠️  Falha ao instalar $slug (rede? repo privado?)"
    return 1
  fi
}

# Se 2 args → single install
if [ $# -eq 2 ]; then
  install_one "$1" "$2"
  EXIT=$?
# Se 1 arg no formato owner/repo@slug
elif [ $# -eq 1 ] && echo "$1" | grep -q '@'; then
  REPO="${1%@*}"
  SLUG="${1##*@}"
  install_one "$REPO" "$SLUG"
  EXIT=$?
# Stdin mode — uma linha por skill no formato owner/repo@slug
else
  EXIT=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    REPO="${line%@*}"
    SLUG="${line##*@}"
    install_one "$REPO" "$SLUG" || EXIT=1
  done
fi

# Sempre limpar .agents/ extra (o CLI cria pra outros runtimes; não usamos)
if [ -d ".agents" ]; then
  rm -rf .agents
fi

exit $EXIT
