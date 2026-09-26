# Servidores MCP aceitos em `tools:` dos agentes

> Fonte da verdade do check (e) do `validate-agent.sh`: toda tool `mcp__…` citada no frontmatter de um agente precisa apontar para um servidor desta tabela — senão é **ERRO**. Servidor novo? Adicione a linha aqui **antes** de citar no agente.

## Como o nome vira prefixo (doc oficial do Claude Code)

O `<server>` é o nome que o usuário passa em `claude mcp add <nome> …` (ou a chave em `mcpServers` do `.mcp.json`). Caracteres fora de `A-Za-z0-9_-` viram `_`. Três formas de prefixo:

| Origem | Prefixo da tool | Exemplo |
|---|---|---|
| `claude mcp add <nome>` / `.mcp.json` | `mcp__<nome>__<tool>` | `mcp__stitch__generate_screen_from_text` |
| Plugin (`/plugin install`) | `mcp__plugin_<plugin>_<server>__<tool>` | `mcp__plugin_heygen_heygen__create_video` |
| Conector claude.ai | `mcp__claude_ai_<server>__<tool>` | `mcp__claude_ai_Hey_Gen__create_video_from_avatar` |

**Forma curta (recomendada):** `tools:` aceita `mcp__<server>` (nível do servidor, sem `__<tool>`) e isso libera **todas** as ferramentas daquele servidor. Prefira a curta: nomes de tool mudam entre versões do servidor; o nome do servidor não. O `*audit` dá **WARN** na forma longa `mcp__<server>__<tool>` e **ERRO** quando `<server>` não está na tabela.

O check extrai `<server>` = texto entre `mcp__` e o próximo `__` (ou o fim). Cada identificador aceito aparece abaixo em crase, na forma `mcp__<id>` — é essa lista que o script lê.

## Tabela

| Servidor | Identificadores aceitos em `tools:` | Squad(s) | Como instalar |
|---|---|---|---|
| **Apify** (scraping/research) | `mcp__apify` · conector: `mcp__claude_ai_apify` | social (`social-content`) | `claude mcp add apify -- npx -y @apify/actors-mcp-server` com `APIFY_TOKEN`; ou conector Apify no claude.ai |
| **Google Stitch** (design generativo) | `mcp__stitch` | social (`social-design`) | `claude mcp add stitch -- npx -y @google/stitch-mcp` (requer projeto Google Cloud + credencial); ver skill `social-stitch-workflow` |
| **Freepik** (imagens AI) | `mcp__freepik` · conector: `mcp__claude_ai_freepik` | social (`social-photo`) | `claude mcp add freepik --transport http https://mcp.freepik.com` com `FREEPIK_API_KEY`; ou conector Freepik no claude.ai |
| **Meta** (Instagram/Facebook publishing + insights) | `mcp__meta` · conector: `mcp__claude_ai_meta` | social (`social-publisher`) | `claude mcp add meta …` (servidor Meta Marketing/Graph API com token de página); ver skill `social-meta-publishing` |
| **HeyGen** (avatar/vídeo AI) | `mcp__heygen` · conector: `mcp__claude_ai_Hey_Gen` · plugin: `mcp__plugin_heygen_heygen` | social (`social-video`) | `claude mcp add heygen …` com `HEYGEN_API_KEY`, plugin `heygen`, ou conector HeyGen no claude.ai; ver skill `social-heygen-avatar` |
| **Supabase** (Postgres/RLS/migrations) | `mcp__supabase` | dev (`dev-data-engineer`, `dev-bi`), sites (`sites-data`), pm (`pm-data`) | `claude mcp add supabase -- npx -y @supabase/mcp-server-supabase@latest --project-ref <ref>` com `SUPABASE_ACCESS_TOKEN`; ver skill `data-supabase-patterns` |
| **Google Ads** | `mcp__google-ads` | traffic (`traffic-google`, `traffic-automation`) | `claude mcp add google-ads …` (servidor Google Ads API com OAuth + developer token); ver skill `traffic-google-ads-mcp` |
| **Google Analytics 4** | `mcp__ga4` · oficial: `mcp__analytics-mcp` | traffic (`traffic-bi`, `traffic-analyst`, `traffic-qa`) | `claude mcp add analytics-mcp -- pipx run analytics-mcp` (servidor oficial `googleanalytics/google-analytics-mcp`, ADC do gcloud); ver skill `traffic-ga4-mcp` |

## Regras

1. **Um agente cita só os servidores da sua função** — `social-publisher` não leva `mcp__stitch`, `dev-data-engineer` não leva `mcp__meta`.
2. **Servidor ausente na máquina não quebra o agente**: o Claude Code ignora tools `mcp__*` não conectadas. Por isso o agente pode citar `mcp__heygen` mesmo que o usuário só tenha o conector claude.ai — mas o `*audit` exige que o identificador esteja nesta tabela.
3. **Conector do claude.ai e plugin têm prefixo diferente** do `claude mcp add` (ver tabela acima). Se o agente precisa funcionar nas três instalações, cite as três formas curtas.
4. **Nunca** colocar credencial (token, key, project-ref) no agente ou na smart-memory — vai no `.mcp.json`/env da máquina.
