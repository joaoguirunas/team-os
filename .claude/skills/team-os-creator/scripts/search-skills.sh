#!/usr/bin/env bash
# search-skills.sh — busca no skills.sh com filtros de qualidade
# Usage: ./search-skills.sh <keyword> [min_installs]
# Output: tab-separated: owner/repo@skill<TAB>installs<TAB>trusted_author
# Default min_installs: 1500

KEYWORD="${1:-}"
MIN_INSTALLS="${2:-1500}"

if [ -z "$KEYWORD" ]; then
  echo "Usage: $0 <keyword> [min_installs]" >&2
  exit 1
fi

# Whitelist de autores trusted (sempre passam, independente de install count)
TRUSTED_AUTHORS=" vercel-labs supabase anthropic microsoft figma better-auth shadcn wshobson addyosmani kepano playwright "

# Rodar busca e parsear
# Output do `skills find` tem padrão: "owner/repo@slug" + "\nXX.XK installs"
RAW=$(npx --yes skills find "$KEYWORD" 2>&1)

# Parsear linhas no formato "owner/repo@skill ... XX.XK installs"
# Usar awk pra extrair pares
echo "$RAW" | awk '
  /@/ && /installs/ {
    # Remover ANSI colors
    gsub(/\x1b\[[0-9;]*[mK]/, "")
    # Extrair padrão owner/repo@skill
    if (match($0, /[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+/)) {
      slug = substr($0, RSTART, RLENGTH)
    } else { next }
    # Extrair installs (ex: "18.5K" ou "1.4K")
    if (match($0, /[0-9]+(\.[0-9]+)?K/)) {
      installs_str = substr($0, RSTART, RLENGTH)
      # Converter pra número (18.5K → 18500)
      num = installs_str
      gsub(/K/, "", num)
      installs = num * 1000
    } else if (match($0, /[0-9]+ installs/)) {
      installs = substr($0, RSTART, RLENGTH-9) + 0
    } else {
      installs = 0
    }
    # Extrair autor (antes do /)
    split(slug, parts, "/")
    author = parts[1]
    print slug "\t" installs "\t" author
  }
' | while IFS=$'\t' read -r slug installs author; do
  # Filtrar: autor trusted OU installs >= threshold
  IS_TRUSTED=0
  case "$TRUSTED_AUTHORS" in *" $author "*) IS_TRUSTED=1 ;; esac

  if [ "$IS_TRUSTED" -eq 1 ] || [ "$installs" -ge "$MIN_INSTALLS" ]; then
    printf "%s\t%s\t%s\n" "$slug" "$installs" "$IS_TRUSTED"
  fi
done | sort -k2,2 -nr -t$'\t' | head -10
