#!/usr/bin/env bash
# detect-project-signals.sh — infere archetype do projeto baseado em sinais
# Usage: detect-project-signals.sh [pasta]   (default: pasta atual)
# Output: key=value linhas (consumível por eval ou grep)

if [ -n "${1:-}" ]; then
  cd "$1" 2>/dev/null || { echo "ERROR=not_a_dir|PATH=$1" >&2; exit 1; }
fi

ARCHETYPE="custom"
HAS_CONTROL_ROOM=0
LANGUAGE="unknown"
FRAMEWORK="none"
HAS_FRONTEND=0
HAS_BACKEND=0
HAS_DATABASE=0
HAS_MOBILE=0
HAS_CI=0
HAS_ML=0
HAS_CONTENT=0
HAS_PROPOSALS=0
HAS_BRANDING=0
HAS_FINANCE=0
HAS_LEGAL=0
HAS_SEO=0
HAS_PACKAGE=0
[ -f "package.json" ] && HAS_PACKAGE=1

# Detectar linguagem principal
if [ -f "package.json" ]; then
  LANGUAGE="typescript"
  # Se só js, ainda marca typescript pra escolher templates certos
  if find . -maxdepth 3 \( -name "*.ts" -o -name "*.tsx" \) -not -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
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
  elif grep -q '"astro"' package.json 2>/dev/null; then FRAMEWORK="astro"
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
if find . -maxdepth 3 \( -name "manage.py" -o -name "main.py" -o -name "app.py" \) -not -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
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

# Proposals signals — workspace de propostas comerciais/apresentações (sem código):
# PDFs/decks de proposta, planejamentos internos, convenção de pastas, brandbook/design system.
PROPOSAL_HITS=$(find . -maxdepth 3 \( -iname "*proposta*" -o -iname "*proposal*" -o -iname "*planejamento*" -o -iname "*pitch*deck*" -o -iname "*_CONVENCAO*" -o -iname "*brandbook*" -o -iname "*design-system*" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -20 | wc -l | tr -d ' ')
# Sinal NUCLEAR de proposta (brandbook/design-system sozinhos são ativos de marca, não proposta)
PROPOSAL_CORE_HITS=$(find . -maxdepth 3 \( -iname "*proposta*" -o -iname "*proposal*" -o -iname "*planejamento*" -o -iname "*pitch*deck*" -o -iname "*_CONVENCAO*" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -20 | wc -l | tr -d ' ')
if [ "${PROPOSAL_HITS:-0}" -ge 2 ] && [ "${PROPOSAL_CORE_HITS:-0}" -ge 1 ] && [ $HAS_FRONTEND -eq 0 ] && [ $HAS_BACKEND -eq 0 ]; then
  HAS_PROPOSALS=1
fi

# Branding signals — workspace de marca/reposicionamento (sem código): plataforma de marca,
# posicionamento, manifesto, identidade, brandbook, tom de voz, arquitetura de marca.
# Brandbook sozinho não basta (pasta de propostas também tem) — exige ≥2 sinais e nenhum de proposta.
HAS_BRANDING=0
BRANDING_HITS=$(find . -maxdepth 3 \( -iname "*posicionamento*" -o -iname "*reposicionamento*" -o -iname "*brand-platform*" -o -iname "*plataforma-de-marca*" -o -iname "*manifesto*" -o -iname "*identidade*" -o -iname "*tom-de-voz*" -o -iname "*brand-voice*" -o -iname "*brandbook*" -o -iname "*rebrand*" -o -iname "*arquitetura-de-marca*" -o -iname "*institucional*" -o -iname "*fontes*" -o -iname "*fonts*" -o -iname "*logo*" -o -iname "*key-visual*" -o -iname "*-kv-*" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -20 | wc -l | tr -d ' ')
if [ "${BRANDING_HITS:-0}" -ge 2 ] && [ "${PROPOSAL_CORE_HITS:-0}" -lt 1 ] && [ $HAS_PACKAGE -eq 0 ] && [ $HAS_BACKEND -eq 0 ]; then
  HAS_BRANDING=1
fi

# Finance / Legal signals — workspaces de gestão financeira e jurídica (sem código).
# Pasta recém-criada costuma estar VAZIA: o nome da pasta é sinal forte (Financeiro, Finance,
# Jurídico, Legal, Contratos). Conteúdo: ≥2 arquivos/pastas com vocabulário da área e nenhum
# sinal de proposta (pasta de propostas também tem contrato e planilha).
BASENAME_LC=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[áàâã]/a/g; s/[éê]/e/g; s/í/i/g; s/[óôõ]/o/g; s/ú/u/g; s/ç/c/g')
FINANCE_HITS=$(find . -maxdepth 3 \( -iname "*financeiro*" -o -iname "*finance*" -o -iname "*fluxo*caixa*" -o -iname "*cash*flow*" -o -iname "*dre*" -o -iname "*balancete*" -o -iname "*extrato*" -o -iname "*contas*pagar*" -o -iname "*contas*receber*" -o -iname "*orcamento*" -o -iname "*orçamento*" -o -iname "*conciliacao*" -o -iname "*conciliação*" -o -iname "*fechamento*" -o -iname "*nota*fiscal*" -o -iname "*notas*fiscais*" -o -iname "*boleto*" -o -iname "*folha*pagamento*" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -20 | wc -l | tr -d ' ')
LEGAL_HITS=$(find . -maxdepth 3 \( -iname "*juridico*" -o -iname "*jurídico*" -o -iname "*legal*" -o -iname "*contrato*" -o -iname "*minuta*" -o -iname "*aditivo*" -o -iname "*distrato*" -o -iname "*nda*" -o -iname "*lgpd*" -o -iname "*procuracao*" -o -iname "*procuração*" -o -iname "*termos*de*uso*" -o -iname "*politica*de*privacidade*" -o -iname "*política*de*privacidade*" -o -iname "*notificacao*" -o -iname "*notificação*" -o -iname "*estatuto*" -o -iname "*contrato*social*" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -20 | wc -l | tr -d ' ')
case "$BASENAME_LC" in *financeiro*|*finance*|*financas*|*contabil*|*tesouraria*) FINANCE_HITS=$((FINANCE_HITS + 2)) ;; esac
case "$BASENAME_LC" in *juridico*|*legal*|*contratos*|*compliance*) LEGAL_HITS=$((LEGAL_HITS + 2)) ;; esac
if [ "${FINANCE_HITS:-0}" -ge 2 ] && [ "${PROPOSAL_CORE_HITS:-0}" -lt 1 ] && [ $HAS_PACKAGE -eq 0 ] && [ $HAS_BACKEND -eq 0 ] && [ "${FINANCE_HITS:-0}" -ge "${LEGAL_HITS:-0}" ]; then
  HAS_FINANCE=1
elif [ "${LEGAL_HITS:-0}" -ge 2 ] && [ "${PROPOSAL_CORE_HITS:-0}" -lt 1 ] && [ $HAS_PACKAGE -eq 0 ] && [ $HAS_BACKEND -eq 0 ]; then
  HAS_LEGAL=1
fi

# SEO signals — sitemap.xml, robots.txt, next-sitemap, "seo" no package.json, pasta seo/,
# ou o nome da pasta diz "seo". Squad seo audita e recomenda; não implementa (a squad sites
# implementa) — por isso, num site com código, `seo` é ADD-ON (`--squads sites,seo`), e só
# vira archetype principal num workspace sem código ou nomeado como SEO.
SEO_HITS=0
find . -maxdepth 3 -iname "sitemap*.xml" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -1 | grep -q . && SEO_HITS=$((SEO_HITS + 1))
find . -maxdepth 3 -iname "robots.txt" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -1 | grep -q . && SEO_HITS=$((SEO_HITS + 1))
[ -f "package.json" ] && grep -q '"next-sitemap"' package.json 2>/dev/null && SEO_HITS=$((SEO_HITS + 1))
[ -f "package.json" ] && grep -qi 'seo' package.json 2>/dev/null && SEO_HITS=$((SEO_HITS + 1))
find . -maxdepth 2 -type d -iname "seo" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/.claude/*" 2>/dev/null | head -1 | grep -q . && SEO_HITS=$((SEO_HITS + 2))
SEO_NAME=0
case "$BASENAME_LC" in *seo*|*"busca organica"*|*"organic search"*) SEO_NAME=1; SEO_HITS=$((SEO_HITS + 2)) ;; esac
[ "${SEO_HITS:-0}" -ge 2 ] && HAS_SEO=1

# Sala de Controle (recurso Maestri): pasta cujo nome diz "sala de controle"/"control room",
# ou que já tem a skill maestri-os. Sem código, sem squad — só a skill opt-in.
DIRNAME_LC=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]')
case "$DIRNAME_LC" in *"sala de controle"*|*"sala-de-controle"*|*"control room"*|*"control-room"*) HAS_CONTROL_ROOM=1 ;; esac
[ -d ".claude/skills/maestri-os" ] && HAS_CONTROL_ROOM=1
[ -d ".claude/skills/sala-de-controle" ] && HAS_CONTROL_ROOM=1

# Classificar archetype
# Ordem importa: control-room primeiro (é declarado pelo nome/skill, não inferido);
# depois fullstack (um SaaS com pandas no requirements não é data-pipeline — o
# teste HAS_ML vem DEPOIS da classificação fullstack).
# "website" = Next/Astro/landing sem backend pesado (backend + database juntos)
# — sem ele o preset `sites` era inalcançável. "proposals" = pasta de propostas
# comerciais sem código → preset `sales`.
if [ $HAS_CONTROL_ROOM -eq 1 ]; then
  ARCHETYPE="control-room"
elif [ $HAS_FINANCE -eq 1 ]; then
  ARCHETYPE="finance"
elif [ $HAS_LEGAL -eq 1 ]; then
  ARCHETYPE="legal"
elif [ $HAS_BRANDING -eq 1 ]; then
  ARCHETYPE="branding"
elif [ $HAS_PROPOSALS -eq 1 ]; then
  ARCHETYPE="proposals"
elif [ $HAS_SEO -eq 1 ] && { [ $SEO_NAME -eq 1 ] || { [ $HAS_FRONTEND -eq 0 ] && [ $HAS_BACKEND -eq 0 ]; }; }; then
  # workspace de SEO (sem código, ou nomeado como SEO) → squad seo é a principal
  ARCHETYPE="seo"
elif [ $HAS_FRONTEND -eq 1 ] && [ $HAS_BACKEND -eq 1 ] && [ $HAS_DATABASE -eq 1 ]; then
  ARCHETYPE="fullstack-saas"
elif [ $HAS_ML -eq 1 ]; then
  ARCHETYPE="data-pipeline"
elif [ $HAS_FRONTEND -eq 1 ] && { [ "$FRAMEWORK" = "next" ] || [ "$FRAMEWORK" = "astro" ]; }; then
  # Next/Astro sem backend pesado (o caso backend+database já saiu como fullstack)
  ARCHETYPE="website"
elif [ $HAS_FRONTEND -eq 1 ] && [ $HAS_CONTENT -eq 1 ]; then
  ARCHETYPE="content-site"
elif [ $HAS_MOBILE -eq 1 ]; then
  ARCHETYPE="mobile-app"
elif [ $HAS_BACKEND -eq 1 ] && [ $HAS_FRONTEND -eq 0 ]; then
  ARCHETYPE="api-service"
elif [ $HAS_FRONTEND -eq 1 ]; then
  ARCHETYPE="frontend-app"
fi

# Mapear archetype → preset do team-os-creator
SUGGESTED_PRESET="custom"
SUGGESTED_EXTRA_SKILLS=""
WARNING=""
case "$ARCHETYPE" in
  control-room)
    # Não é squad: instala só a skill de Sala (--squads none --extra-skills <skill>).
    # Default sala-de-controle (sessões do Claude); maestri-os se a pasta já é do Maestri.
    SUGGESTED_PRESET="none"
    if [ -d ".claude/skills/maestri-os" ]; then
      SUGGESTED_EXTRA_SKILLS="maestri-os"
    else
      SUGGESTED_EXTRA_SKILLS="sala-de-controle"
    fi
    CONTROL_ROOM_OPTIONS="sala-de-controle,maestri-os" ;;
  fullstack-saas|data-pipeline|api-service|frontend-app)
    SUGGESTED_PRESET="dev" ;;
  website|content-site)
    SUGGESTED_PRESET="sites" ;;
  proposals)
    SUGGESTED_PRESET="sales" ;;
  branding)
    SUGGESTED_PRESET="brand" ;;
  finance)
    SUGGESTED_PRESET="finance" ;;
  legal)
    SUGGESTED_PRESET="legal" ;;
  seo)
    SUGGESTED_PRESET="seo" ;;
  mobile-app)
    # Não existe preset mobile — usa dev (o mais próximo), com aviso explícito.
    SUGGESTED_PRESET="dev"
    WARNING="mobile-app detectado: não há preset mobile — usando preset dev (revise a squad manualmente)"
    ;;
esac
# Site com código e sinais de SEO → sugere a squad seo como add-on (audita; sites implementa)
SUGGESTED_SQUAD_ADDON=""
if [ $HAS_SEO -eq 1 ] && [ "$ARCHETYPE" != "seo" ]; then
  case "$ARCHETYPE" in website|content-site|fullstack-saas|frontend-app) SUGGESTED_SQUAD_ADDON="seo" ;; esac
fi
[ -n "$WARNING" ] && echo "⚠️  $WARNING" >&2

echo "PROJECT_ARCHETYPE=$ARCHETYPE"
echo "SUGGESTED_PRESET=$SUGGESTED_PRESET"
[ -n "$SUGGESTED_EXTRA_SKILLS" ] && echo "SUGGESTED_EXTRA_SKILLS=$SUGGESTED_EXTRA_SKILLS"
[ -n "$SUGGESTED_SQUAD_ADDON" ] && echo "SUGGESTED_SQUAD_ADDON=$SUGGESTED_SQUAD_ADDON"
[ -n "${CONTROL_ROOM_OPTIONS:-}" ] && echo "CONTROL_ROOM_OPTIONS=$CONTROL_ROOM_OPTIONS"
[ -n "$WARNING" ] && echo "WARNING=$WARNING"
echo "LANGUAGE=$LANGUAGE"
echo "FRAMEWORK=$FRAMEWORK"
echo "HAS_FRONTEND=$HAS_FRONTEND"
echo "HAS_BACKEND=$HAS_BACKEND"
echo "HAS_DATABASE=$HAS_DATABASE"
echo "HAS_MOBILE=$HAS_MOBILE"
echo "HAS_CI=$HAS_CI"
echo "HAS_ML=$HAS_ML"
echo "HAS_CONTENT=$HAS_CONTENT"
echo "HAS_SEO=$HAS_SEO"
