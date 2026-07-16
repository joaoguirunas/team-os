#!/usr/bin/env bash
# apify-ig-scrape.sh — raspa Instagram via API da Apify, sem depender do MCP.
#
# Por que existe: o MCP `apify` não expõe de forma confiável os actors de Instagram
# como tools (mesmo configurado com --actors ...instagram-scraper --tools actors, o
# processo MCP do Claude Code frequentemente não respawna com os args novos). Além
# disso, agentes como social-analyst têm Bash mas NÃO têm tools MCP do Apify — para
# eles este wrapper é o único caminho. Chamar a API direto é determinístico.
#
# Uso:
#   apify-ig-scrape.sh hashtag <hashtag> [limite]   # posts por hashtag
#   apify-ig-scrape.sh profile <usuario> [limite]   # posts de um perfil
#
# Token (primeira fonte que resolver vence):
#   1. $APIFY_TOKEN no ambiente
#   2. ~/.claude.json → projects[<raiz do projeto>].mcpServers.apify.env.APIFY_TOKEN
#      A raiz é o git root; sem git, o cwd. Nunca hardcode caminho — mover a pasta
#      do projeto muda a chave e quebra a resolução.
#
# Limite default = 5 — actors de Instagram são PAGOS, por item retornado.
# Saída: JSON enxuto (perfil · legenda · likes · comentários · url) no stdout;
#        contagem de itens no stderr.
set -euo pipefail

MODE="${1:-}"; TARGET="${2:-}"; LIMIT="${3:-5}"
if [[ -z "$MODE" || -z "$TARGET" ]]; then
  echo "uso: $(basename "$0") <hashtag|profile> <alvo> [limite]" >&2
  exit 1
fi

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [ "$LIMIT" -lt 1 ]; then
  echo "erro: limite deve ser inteiro positivo (recebido: $LIMIT)" >&2
  exit 1
fi
if [ "$LIMIT" -gt 50 ]; then
  echo "aviso: limite $LIMIT é alto — actor pago, cobra por item. Prossiga só se intencional." >&2
fi

# Valida o modo ANTES de resolver token — erro de uso deve falhar na hora, sem
# mandar o agente caçar credencial por causa de um typo no argumento.
case "$MODE" in
  hashtag)
    ACTOR="apify~instagram-hashtag-scraper"
    INPUT="{\"hashtags\":[\"${TARGET#\#}\"],\"resultsLimit\":${LIMIT}}" ;;
  profile)
    ACTOR="apify~instagram-scraper"
    INPUT="{\"directUrls\":[\"https://www.instagram.com/${TARGET#@}/\"],\"resultsType\":\"posts\",\"resultsLimit\":${LIMIT}}" ;;
  *)
    echo "modo inválido: $MODE (use hashtag|profile)" >&2; exit 1 ;;
esac

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

resolve_token() {
  if [ -n "${APIFY_TOKEN:-}" ]; then printf '%s' "$APIFY_TOKEN"; return 0; fi
  python3 - "$PROJECT_ROOT" <<'PY'
import json, os, sys
root = sys.argv[1]
try:
    cfg = json.load(open(os.path.expanduser('~/.claude.json')))
except Exception:
    sys.exit(1)
proj = cfg.get('projects', {}).get(root)
if not proj:
    sys.exit(1)
tok = (proj.get('mcpServers', {}).get('apify', {}).get('env', {}) or {}).get('APIFY_TOKEN')
if not tok:
    sys.exit(1)
print(tok, end='')
PY
}

TOKEN="$(resolve_token || true)"
if [ -z "$TOKEN" ]; then
  cat >&2 <<EOF
erro: APIFY_TOKEN não encontrado.
  Procurei em:
    1. \$APIFY_TOKEN no ambiente
    2. ~/.claude.json → projects["$PROJECT_ROOT"].mcpServers.apify.env.APIFY_TOKEN
  Se o projeto mudou de pasta, a chave em ~/.claude.json ainda aponta pro caminho
  antigo — migre a chave ou exporte APIFY_TOKEN.
EOF
  exit 1
fi

curl -sS -X POST \
  "https://api.apify.com/v2/acts/${ACTOR}/run-sync-get-dataset-items?token=${TOKEN}&timeout=150" \
  -H "Content-Type: application/json" -d "$INPUT" --max-time 170 \
| python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
except json.JSONDecodeError:
    print('erro: resposta da Apify não é JSON — token inválido ou actor indisponível', file=sys.stderr)
    sys.exit(1)
if isinstance(d, dict) and d.get('error'):
    print('erro da Apify:', d['error'].get('message', d['error']), file=sys.stderr)
    sys.exit(1)
items = d if isinstance(d, list) else []
out = [{'perfil': i.get('ownerUsername'),
        'legenda': (i.get('caption', '') or '')[:160],
        'likes': i.get('likesCount'),
        'coments': i.get('commentsCount'),
        'url': i.get('url')} for i in items]
print(json.dumps(out, ensure_ascii=False, indent=2))
print(f'\n# {len(out)} itens', file=sys.stderr)
"
