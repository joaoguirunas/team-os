#!/usr/bin/env bash
# detect-state.sh — classifica o estado atual do projeto
# Output: uma das strings:
#   NEW             → docs/smart-memory/ não existe
#   NO_DISCOVERY    → existe estrutura mas sem modules.md e há código no repo
#   IN_PROGRESS     → há stories em stories/active/
#   READY           → smart-memory ok, sem stories ativas

SM="docs/smart-memory"

if [ ! -d "$SM" ]; then
  echo "NEW"
  exit 0
fi

# Checa se há stories em progresso
if [ -d "$SM/stories/active" ]; then
  ACTIVE_COUNT=$(find "$SM/stories/active" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ACTIVE_COUNT" -gt 0 ]; then
    echo "IN_PROGRESS"
    exit 0
  fi
fi

# Smart-memory existe mas sem discovery?
if [ ! -f "$SM/project/modules.md" ]; then
  # Há código no repo? Olhar sinais comuns
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

echo "READY"
exit 0
