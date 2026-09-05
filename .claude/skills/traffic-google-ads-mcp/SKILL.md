---
name: traffic-google-ads-mcp
description: Uso do MCP oficial do Google Ads (googleads/google-ads-mcp) — tools, GAQL cookbook, workflow de descoberta de contas, limites read-only e handoff para mutations. Use ao consultar dados de conta/campanha Google Ads via MCP, escrever queries GAQL, auditar performance, budget pacing, search terms ou preparar relatórios com dados reais da API.
version: "1.0"
updated: "2026-09-04"
---

# Google Ads MCP (oficial)

Skill de preparação para o **MCP oficial do Google Ads** ([googleads/google-ads-mcp](https://github.com/googleads/google-ads-mcp)), mantido pelo Google. Usada por **traffic-google** (consultas de conta e campanha), **traffic-bi** (dados brutos para atribuição/ROAS), **traffic-analyst** (benchmarks e diagnóstico), **traffic-qa** (auditoria pré/pós-launch) e **traffic-automation** (leitura via MCP; mutations via API).

> **Status da conexão:** quando o MCP estiver conectado ao projeto, as tools aparecem como `mcp__google-ads*__search` etc. Quando NÃO estiver conectado, esta skill continua válida como referência de GAQL — as mesmas queries rodam em scripts da Google Ads API (Python client) pelo traffic-automation.

## 1. O que o servidor expõe

**3 tools (todas read-only):**

| Tool | O que faz | Quando usar |
|---|---|---|
| `list_accessible_customers` | Lista os customer IDs acessíveis pelo usuário autenticado | SEMPRE primeiro numa sessão — descobrir contas antes de qualquer query |
| `get_resource_metadata` | Metadata de um resource type da API (ex.: `campaign`, `ad_group`) — campos, tipos, relações | Antes de montar GAQL para um resource pouco usado; valida nomes de campos |
| `search` | Executa query GAQL contra a conta | Toda consulta de dados: campanhas, métricas, budgets, keywords, search terms |

**4 resources:** `discovery-document` (superfície completa da API), `metrics` (métricas disponíveis para report), `segments` (segmentos disponíveis), `release-notes` (versão atual da API). Consulte `metrics`/`segments` quando não tiver certeza do nome exato de um campo.

## 2. Workflow canônico

```
1. list_accessible_customers        → obter customer ID (formato sem hífens: 1234567890)
2. get_resource_metadata("campaign") → confirmar campos, se necessário
3. search(customer_id, GAQL)         → consultar
```

- **Customer ID sempre sem hífens** (`1234567890`, nunca `123-456-7890`).
- Conta MCC (manager): as queries rodam contra a conta-filha; o acesso passa pelo `login_customer_id` configurado no servidor.
- Query falhou com campo inválido → conferir em `get_resource_metadata` ou no resource `metrics`/`segments` antes de tentar de novo.

## 3. GAQL — estrutura

```sql
SELECT <campos> FROM <resource>
WHERE <condições> ORDER BY <campo> [DESC] LIMIT <n>
```

- Datas: `segments.date DURING LAST_30_DAYS` (ou `LAST_7_DAYS`, `THIS_MONTH`, `LAST_MONTH`) ou intervalo explícito `segments.date BETWEEN '2026-08-01' AND '2026-08-31'`.
- Métricas de custo vêm em **micros** (`metrics.cost_micros ÷ 1.000.000` = valor na moeda da conta). Sempre converter antes de reportar.
- Segmentar por `segments.date`, `segments.device`, `segments.ad_network_type` multiplica linhas — só segmente o que o relatório precisa.

## 4. Cookbook GAQL (queries validadas)

**Performance de campanhas (visão-mãe de todo relatório):**
```sql
SELECT campaign.id, campaign.name, campaign.status, campaign.advertising_channel_type,
  metrics.impressions, metrics.clicks, metrics.ctr, metrics.average_cpc,
  metrics.cost_micros, metrics.conversions, metrics.conversions_value, metrics.cost_per_conversion
FROM campaign
WHERE segments.date DURING LAST_30_DAYS AND campaign.status != 'REMOVED'
ORDER BY metrics.cost_micros DESC
```

**Budget pacing (gasto vs orçamento):**
```sql
SELECT campaign.name, campaign_budget.amount_micros, campaign_budget.delivery_method,
  metrics.cost_micros
FROM campaign
WHERE segments.date DURING THIS_MONTH AND campaign.status = 'ENABLED'
```
Pacing = gasto acumulado ÷ (budget diário × dias corridos). Alerta se < 85% ou > 110%.

**Search terms (minerar negativas e vencedoras):**
```sql
SELECT search_term_view.search_term, segments.keyword.info.text, campaign.name,
  metrics.impressions, metrics.clicks, metrics.conversions, metrics.cost_micros
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS AND metrics.impressions > 10
ORDER BY metrics.cost_micros DESC LIMIT 200
```
Termo com custo alto + 0 conversões → candidato a negativa (handoff: traffic-automation aplica via API).

**Keywords + Quality Score:**
```sql
SELECT ad_group_criterion.keyword.text, ad_group_criterion.keyword.match_type,
  ad_group_criterion.quality_info.quality_score, ad_group.name, campaign.name,
  metrics.impressions, metrics.clicks, metrics.conversions, metrics.cost_micros
FROM keyword_view
WHERE segments.date DURING LAST_30_DAYS AND ad_group_criterion.status = 'ENABLED'
ORDER BY metrics.cost_micros DESC
```

**Anúncios (RSAs) por performance:**
```sql
SELECT ad_group_ad.ad.id, ad_group_ad.ad.responsive_search_ad.headlines,
  ad_group_ad.ad_strength, ad_group_ad.status, ad_group.name,
  metrics.impressions, metrics.clicks, metrics.conversions
FROM ad_group_ad
WHERE segments.date DURING LAST_30_DAYS AND ad_group_ad.status = 'ENABLED'
```
`ad_strength` < GOOD → acionar traffic-copywriter para variantes.

**Performance Max — asset groups:**
```sql
SELECT asset_group.name, asset_group.status, campaign.name,
  metrics.impressions, metrics.clicks, metrics.conversions, metrics.cost_micros
FROM asset_group
WHERE segments.date DURING LAST_30_DAYS
```

**Segmentação por dispositivo/rede (diagnóstico):**
```sql
SELECT campaign.name, segments.device, segments.ad_network_type,
  metrics.impressions, metrics.clicks, metrics.conversions, metrics.cost_micros
FROM campaign
WHERE segments.date DURING LAST_30_DAYS AND campaign.status = 'ENABLED'
```

**Auditoria de mudanças (traffic-qa — quem mexeu no quê):**
```sql
SELECT change_event.change_date_time, change_event.change_resource_type,
  change_event.changed_fields, change_event.user_email, campaign.name
FROM change_event
WHERE change_event.change_date_time DURING LAST_14_DAYS
ORDER BY change_event.change_date_time DESC LIMIT 50
```
(`change_event` exige janela ≤ 30 dias e `LIMIT` obrigatório.)

**Conversões por ação (validar tracking com traffic-qa):**
```sql
SELECT segments.conversion_action_name, metrics.conversions, metrics.conversions_value
FROM campaign
WHERE segments.date DURING LAST_30_DAYS
```

## 5. Limites e guardrails

1. **READ-ONLY — garantia dura.** O MCP oficial não cria, pausa, nem edita nada. Qualquer mutation (negativas, budgets, lances, status) é handoff para **traffic-automation** via Google Ads API — nunca tentar pelo MCP.
2. **Developer token com acesso Explorer** só enxerga contas de teste; produção exige Basic/Standard. Se `search` retornar erro de permissão em conta real, a causa provável é o nível do token — reportar ao usuário, não insistir.
3. **Dados expostos ao contexto:** tudo que a query retorna entra na conversa. Não puxar dados além do necessário para a tarefa (LIMIT sempre).
4. **Versão da API muda ~3x/ano** — em erro de campo removido/renomeado, consultar o resource `release-notes`.
5. Métricas do Google Ads ≠ GA4 (janela e modelo de atribuição diferentes). Comparações cross-fonte seguem o protocolo de discrepância do **traffic-bi** (ver `/traffic-ga4-mcp` e `/traffic-analytics-tracking`).

## 6. Divisão por agente

| Agente | Uso do MCP |
|---|---|
| traffic-google | Consulta de campanhas/keywords/RSAs para otimização; diagnóstico de performance |
| traffic-bi | Extração de custo/conversão/receita para ROAS, CPA e consolidação cross-platform |
| traffic-analyst | Benchmarks internos, tendências de CPC/CTR, diagnóstico de queda |
| traffic-qa | Auditoria pré-launch (status, budgets, conversion actions ativas) e `change_event` pós-launch |
| traffic-automation | Leitura exploratória via MCP; TODA mutation via scripts da API |
