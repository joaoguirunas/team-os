#!/usr/bin/env bash
# detect-state.sh — classifica o estado atual do projeto
# Output: uma das strings:
#   NEW             → docs/smart-memory/ não existe
#   NO_DISCOVERY    → existe estrutura mas discovery incompleto e há código no repo
#   IN_PROGRESS     → há stories em stories/active/ ou stories/in-review/
#   READY           → smart-memory ok, sem stories ativas ou em review
#
# Discovery considerado completo quando ao menos 2 dos 3 arquivos existem:
#   project/modules.md, project/tech-stack.md, project/architecture.md

SM="docs/smart-memory"

# Estado NEW: estrutura não existe
if [ ! -d "$SM" ]; then
  echo "NEW"
  exit 0
fi

# Estado IN_PROGRESS: stories ativas ou em review presentes (tem precedência sobre NO_DISCOVERY)
ACTIVE_COUNT=0
for dir in "$SM/stories/active" "$SM/stories/in-review"; do
  if [ -d "$dir" ]; then
    COUNT=$(find "$dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    ACTIVE_COUNT=$((ACTIVE_COUNT + COUNT))
  fi
done
if [ "$ACTIVE_COUNT" -gt 0 ]; then
  echo "IN_PROGRESS"
  exit 0
fi

# Contar arquivos de discovery presentes no disco (estado atual, ignora git)
DISCOVERY_FILES=0
for f in "$SM/project/modules.md" "$SM/project/tech-stack.md" "$SM/project/architecture.md"; do
  [ -f "$f" ] && DISCOVERY_FILES=$((DISCOVERY_FILES + 1))
done

# Se discovery incompleto (menos de 2 arquivos) e há código no repo → NO_DISCOVERY
if [ "$DISCOVERY_FILES" -lt 2 ]; then
  HAS_CODE=0
  for sig in package.json pyproject.toml go.mod Cargo.toml pom.xml build.gradle src app; do
    if [ -e "$sig" ]; then
      HAS_CODE=1
      break
    fi
  done
  if [ "$HAS_CODE" -eq 1 ]; then
    echo "NO_DISCOVERY"
    exit 0
  fi
fi

# Default: READY (smart-memory ok, sem stories ativas)
echo "READY"
exit 0
