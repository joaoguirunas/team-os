#!/usr/bin/env bash
# detect-project-signals.sh — infere archetype do projeto baseado em sinais
# Output: key=value linhas (consumível por eval ou grep)

ARCHETYPE="custom"
LANGUAGE="unknown"
FRAMEWORK="none"
HAS_FRONTEND=0
HAS_BACKEND=0
HAS_DATABASE=0
HAS_MOBILE=0
HAS_CI=0
HAS_ML=0
HAS_CONTENT=0

# Detectar linguagem principal
if [ -f "package.json" ]; then
  LANGUAGE="typescript"
  # Se só js, ainda marca typescript pra escolher templates certos
  if find . -maxdepth 3 -name "*.ts" -o -name "*.tsx" -not -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
    LANGUAGE="typescript"
  fi
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
  LANGUAGE="python"
elif [ -f "go.mod" ]; then
  LANGUAGE="go"
elif [ -f "Cargo.toml" ]; then
  LANGUAGE="rust"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
  LANGUAGE="java"
elif [ -f "Gemfile" ]; then
  LANGUAGE="ruby"
fi

# Detectar framework (TypeScript/JS)
if [ -f "package.json" ]; then
  if grep -q '"next"' package.json 2>/dev/null; then FRAMEWORK="next"
  elif grep -q '"react"' package.json 2>/dev/null; then FRAMEWORK="react"
  elif grep -q '"vue"' package.json 2>/dev/null; then FRAMEWORK="vue"
  elif grep -q '"svelte"' package.json 2>/dev/null; then FRAMEWORK="svelte"
  elif grep -q '"express"\|"fastify"\|"hono"' package.json 2>/dev/null; then FRAMEWORK="node-api"
  fi
fi

# Frontend signals
if find . -maxdepth 4 \( -name "*.tsx" -o -name "*.jsx" -o -path "*/components/*" -o -path "*/pages/*" \) -not -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
  HAS_FRONTEND=1
fi

# Backend signals
if find . -maxdepth 4 \( -path "*/api/*" -o -path "*/routes/*" -o -path "*/controllers/*" -o -path "*/services/*" \) -not -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
  HAS_BACKEND=1
fi
# Python backend
if find . -maxdepth 3 -name "manage.py" -o -name "main.py" -o -name "app.py" 2>/dev/null | head -1 | grep -q .; then
  HAS_BACKEND=1
fi

# Database signals
if find . -maxdepth 4 \( -name "*.sql" -o -name "schema.prisma" -o -path "*/migrations/*" -o -path "*/supabase/*" \) -not -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
  HAS_DATABASE=1
fi

# Mobile signals
if find . -maxdepth 3 \( -name "App.tsx" -o -name "AndroidManifest.xml" -o -name "Info.plist" -o -name "pubspec.yaml" \) 2>/dev/null | head -1 | grep -q .; then
  HAS_MOBILE=1
fi
# React Native / Expo
if [ -f "package.json" ] && grep -q '"react-native"\|"expo"' package.json 2>/dev/null; then
  HAS_MOBILE=1
fi

# CI/CD
if [ -d ".github/workflows" ] || [ -f ".gitlab-ci.yml" ] || [ -f "circle.yml" ] || [ -f ".circleci/config.yml" ]; then
  HAS_CI=1
fi

# ML signals (Python)
if [ -f "requirements.txt" ] && grep -qE "torch|tensorflow|scikit-learn|pandas|numpy" requirements.txt 2>/dev/null; then
  HAS_ML=1
fi

# Content site signals
if find . -maxdepth 3 \( -path "*/content/*" -o -path "*/posts/*" -o -name "*.mdx" \) -not -path "*/node_modules/*" 2>/dev/null | head -5 | grep -q .; then
  HAS_CONTENT=1
fi

# Classificar archetype
if [ $HAS_ML -eq 1 ]; then
  ARCHETYPE="data-pipeline"
elif [ $HAS_FRONTEND -eq 1 ] && [ $HAS_BACKEND -eq 1 ] && [ $HAS_DATABASE -eq 1 ]; then
  ARCHETYPE="fullstack-saas"
elif [ $HAS_FRONTEND -eq 1 ] && [ $HAS_CONTENT -eq 1 ]; then
  ARCHETYPE="content-site"
elif [ $HAS_MOBILE -eq 1 ]; then
  ARCHETYPE="mobile-app"
elif [ $HAS_BACKEND -eq 1 ] && [ $HAS_FRONTEND -eq 0 ]; then
  ARCHETYPE="api-service"
elif [ $HAS_FRONTEND -eq 1 ]; then
  ARCHETYPE="frontend-app"
fi

echo "PROJECT_ARCHETYPE=$ARCHETYPE"
echo "LANGUAGE=$LANGUAGE"
echo "FRAMEWORK=$FRAMEWORK"
echo "HAS_FRONTEND=$HAS_FRONTEND"
echo "HAS_BACKEND=$HAS_BACKEND"
echo "HAS_DATABASE=$HAS_DATABASE"
echo "HAS_MOBILE=$HAS_MOBILE"
echo "HAS_CI=$HAS_CI"
echo "HAS_ML=$HAS_ML"
echo "HAS_CONTENT=$HAS_CONTENT"
