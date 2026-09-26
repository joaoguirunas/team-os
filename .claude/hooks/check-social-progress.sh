#!/usr/bin/env bash
# .claude/hooks/check-social-progress.sh
# TaskCompleted hook — quality gate de publicação de conteúdo social.
# Exit 2 NEGA a conclusão (a task volta a in_progress e o teammate recebe o stderr).
#
# Payload real do evento (doc oficial de hooks): stdin JSON com task_id, task_subject,
# task_description (opcional), teammate_name, team_name + campos comuns.
# Chaves primárias: task_subject/task_description; fallback: title|subject|name|description|body|...
#
# Dispara quando a task é de PUBLICAÇÃO social — por caminho
# (docs/smart-memory/agents/[<squad>/]{content,design,photo,video,publisher}, com ou sem o
# segmento de squad) OU por vocabulário ("publicar post/reel/story/carrossel", "agendar
# publicação", "publish reel", "schedule post"...) — e a descrição precisa conter evidência de
# aprovação editorial ("aprovado pela VERA/strategist") antes de fechar.
#
# Negação NÃO conta como aprovação: "não aprovado", "ainda não aprovado", "não foi aprovado",
# "desaprovado", "reprovado", "not approved", "unapproved".
# Caso contrário → exit 0 (não bloqueia tasks genéricas).
#
# Defensivo: JSON malformado ou sem python3 → exit 0 (nunca quebra o fluxo).

INPUT=$(cat)

command -v python3 >/dev/null 2>&1 || exit 0

RESULT=$(printf '%s' "$INPUT" | python3 -c '
import sys, json, re

try:
    data = json.load(sys.stdin)
except Exception:
    print("OK"); sys.exit(0)

KEYS = {"task_subject", "task_description",
        "title", "subject", "name", "description", "body", "content", "details", "prompt"}

def collect(obj, acc):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, str) and k in KEYS:
                acc.append(v)
            elif isinstance(v, (dict, list)):
                collect(v, acc)
    elif isinstance(obj, list):
        for v in obj:
            collect(v, acc)

texts = []
collect(data, texts)
blob = "\n".join(texts)

SQUAD = r"(?:(?:sales|dev|sites|social|traffic|pm|brand|finance|legal|seo)/)?"
path_ref = re.search(r"docs/smart-memory/agents/" + SQUAD + r"(content|design|photo|video|publisher)\b", blob) is not None

SOCIAL_NOUN = r"(?:posts?|reels?|stor(?:y|ies)|carross[eé]is|carrossel|carousels?|feed|v[íi]deos?|conte[úu]dos?|campanha|instagram|facebook|tiktok|linkedin|youtube|threads|meta|redes? sociais?|social)"

# Ato de publicação (infinitivo/imperativo/substantivo — não "publicado" como histórico de revisão)
publish_act = (
    re.search(r"\b(?:publicar|postar|agendar|programar|publish|schedule)\b\s+(?:\w+\s+){0,3}" + SOCIAL_NOUN + r"\b", blob, re.I)
    or re.search(r"\b(?:agendar|programar)\s+(?:a\s+|uma\s+|as\s+)?publica[cç](?:[aã]o|[oõ]es)\b", blob, re.I)
    or re.search(r"\bschedule\s+(?:the\s+|a\s+)?(?:post|publication|reel|story)\b", blob, re.I)
    or re.search(r"\bpost\s+(?:it\s+|this\s+|the\s+\w+\s+)?(?:to|on)\s+(?:instagram|facebook|tiktok|linkedin|youtube|threads)\b", blob, re.I)
)
if path_ref:
    # Com caminho social, basta o verbo de publicação
    publish_act = publish_act or re.search(r"\bpublicar\b|\bpublish\b|\bpublica[cç][aã]o\b|\bagendar\b|\bschedule\b", blob, re.I)

if not publish_act:
    print("OK"); sys.exit(0)

# Evidencia de aprovacao editorial (VERA/strategist) — descartando negações
clean = re.sub(r"\b(?:ainda\s+)?n[ãa]o\s+(?:foi\s+|est[áa]\s+|esta\s+|ainda\s+|totalmente\s+)*aprovad[oa]s?\b", " ", blob, flags=re.I)
clean = re.sub(r"\b(?:des|re)aprovad[oa]s?\b", " ", clean, flags=re.I)
clean = re.sub(r"\bsem\s+aprova[cç][aã]o\b|\baguardando\s+aprova[cç][aã]o\b|\bpendente\s+de\s+aprova[cç][aã]o\b", " ", clean, flags=re.I)
clean = re.sub(r"\bnot\s+(?:yet\s+)?approved\b|\bunapproved\b|\bdisapproved\b", " ", clean, flags=re.I)

if re.search(r"\baprovad[oa]s?\b|\bapproved\b", clean, re.I):
    print("OK"); sys.exit(0)

print("BLOCK")
' 2>&1)

case "$RESULT" in
  BLOCK)
    {
      echo "🚫 Task de publicação social só fecha com aprovação editorial registrada."
      echo ""
      echo "A task é de publicação social (post, reel, story, carrossel, agendamento), mas a"
      echo "descrição não contém evidência de aprovação da VERA/strategist — negação"
      echo "(\"não aprovado\", \"reprovado\") não conta."
      echo "Adicione à descrição a evidência (ex.: \"Aprovado pela VERA em 2026-09-05 —"
      echo "agents/social/strategist/approvals.md\") antes de concluir — sem aprovação editorial, nada é publicado."
    } >&2
    exit 2 ;;
  OK) exit 0 ;;
  *)
    echo "⚠️ check-social-progress.sh: python3 falhou (${RESULT:-sem saída}) — hook não avaliou a task." >&2
    exit 0 ;;
esac
