#!/usr/bin/env bash
# audit-smart-memory.sh — auditoria de integridade da smart-memory
# Verifica: frontmatter, wikilinks, INDEX, stories ativas, órfãos
# Output: relatório texto
# Exit 0: tudo ok
# Exit 1: problemas encontrados (detalhes no stdout)

SM="docs/smart-memory"
PROBLEMS=0

if [ ! -d "$SM" ]; then
  echo "⛔ Smart-memory não inicializada. Rode /team-os *init primeiro."
  exit 1
fi

echo "📊 Auditoria smart-memory — $(date '+%Y-%m-%d %H:%M')"
echo ""

# Check 1: Frontmatter YAML válido em todo .md
echo "• Verificando frontmatter..."
INVALID_FM=0
while IFS= read -r f; do
  # Todo arquivo deve começar com ---\n
  if ! head -n 1 "$f" | grep -q '^---$'; then
    echo "  ❌ sem frontmatter: $f"
    INVALID_FM=$((INVALID_FM + 1))
    continue
  fi
  # Deve ter title
  if ! awk '/^---$/{c++; if(c==2)exit} c==1' "$f" | grep -q '^title:'; then
    echo "  ⚠️  sem 'title': $f"
    INVALID_FM=$((INVALID_FM + 1))
  fi
done < <(find "$SM" -name "*.md" -type f 2>/dev/null)

if [ $INVALID_FM -eq 0 ]; then
  echo "  ✅ todos válidos"
else
  PROBLEMS=$((PROBLEMS + INVALID_FM))
fi

# Check 2: Wikilinks resolvem
echo "• Verificando wikilinks..."
BROKEN_LINKS=0
while IFS= read -r f; do
  # Extrair [[nome]] e [[nome|alias]]
  grep -oE '\[\[[^]|]+' "$f" 2>/dev/null | sed 's/\[\[//' | while IFS= read -r target; do
    # Resolver relativo ao arquivo
    dir=$(dirname "$f")
    # Tentar resolver como .md diretamente ou como caminho
    if [ -f "$dir/$target.md" ] || [ -f "$dir/$target" ]; then
      continue
    fi
    # Procurar no SM inteiro pelo basename
    base=$(basename "$target")
    if find "$SM" -name "${base}.md" -o -name "$base" 2>/dev/null | grep -q .; then
      continue
    fi
    echo "  ❌ $f → [[$target]] não resolve"
    BROKEN_LINKS=$((BROKEN_LINKS + 1))
  done
done < <(find "$SM" -name "*.md" -type f 2>/dev/null)

if [ $BROKEN_LINKS -eq 0 ]; then
  echo "  ✅ todos resolvem"
else
  PROBLEMS=$((PROBLEMS + BROKEN_LINKS))
fi

# Check 3: Stories ativas bem-formadas
echo "• Verificando stories ativas..."
ACTIVE_ISSUES=0
if [ -d "$SM/stories/active" ]; then
  for story in "$SM"/stories/active/*.md; do
    [ -f "$story" ] || continue
    # Deve ter Agente preenchido (não vazio nem "—")
    AGENTE_LINE=$(grep -m1 "| Agente" "$story" 2>/dev/null)
    if echo "$AGENTE_LINE" | grep -qE '\|[[:space:]]*(—|-|)[[:space:]]*\|'; then
      echo "  ⚠️  $(basename $story): Dev Agent Record sem Agente"
      ACTIVE_ISSUES=$((ACTIVE_ISSUES + 1))
    fi
    # Deve ter Iniciado preenchido
    INICIADO_LINE=$(grep -m1 "| Iniciado" "$story" 2>/dev/null)
    if echo "$INICIADO_LINE" | grep -qE '\|[[:space:]]*(—|-|)[[:space:]]*\|'; then
      echo "  ⚠️  $(basename $story): sem data de início"
      ACTIVE_ISSUES=$((ACTIVE_ISSUES + 1))
    fi
  done
fi
if [ $ACTIVE_ISSUES -eq 0 ]; then
  echo "  ✅ ok"
else
  PROBLEMS=$((PROBLEMS + ACTIVE_ISSUES))
fi

# Check 4: INDEX.md existe e lista arquivos principais
echo "• Verificando INDEX.md..."
if [ ! -f "$SM/INDEX.md" ]; then
  echo "  ❌ INDEX.md ausente"
  PROBLEMS=$((PROBLEMS + 1))
else
  echo "  ✅ presente"
fi

echo ""
if [ $PROBLEMS -eq 0 ]; then
  echo "✅ Auditoria OK — sem problemas"
  exit 0
else
  echo "⚠️  $PROBLEMS problema(s) encontrado(s)"
  exit 1
fi
