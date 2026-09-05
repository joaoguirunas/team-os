---
name: traffic-ga4-mcp
description: Uso do MCP oficial do Google Analytics (googleanalytics/google-analytics-mcp) — tools de report GA4, validação realtime de tracking pré-launch, funis, links com Google Ads e dicionário de dimensões/métricas para tráfego pago. Use ao consultar dados GA4, validar conversões e UTMs de campanha, montar relatórios de canal/campanha ou investigar discrepância entre plataforma de ads e GA4.
version: "1.0"
updated: "2026-09-04"
---

# Google Analytics MCP (oficial)

Skill de preparação para o **MCP oficial do GA4** ([googleanalytics/google-analytics-mcp](https://github.com/googleanalytics/google-analytics-mcp)), mantido pelo Google (experimental, read-only, Admin API + Data API). Usada por **traffic-bi** (fonte de validação de conversão), **traffic-qa** (smoke-test de tracking pré/pós-launch), **traffic-analyst** (comportamento e canais) e **traffic-strategist** (dados para planejamento).

> **Status da conexão:** quando conectado, as tools aparecem como `mcp__analytics-mcp__run_report` etc. Sem conexão, esta skill vale como referência do modelo de dados GA4 — os mesmos reports saem pela Data API (`runReport`) em scripts do traffic-automation.

## 1. O que o servidor expõe (7 tools, read-only)

| Tool | O que faz | Quando usar |
|---|---|---|
| `get_account_summaries` | Contas e propriedades GA4 do usuário | Primeiro passo — descobrir property ID |
| `get_property_details` | Configuração da propriedade (timezone, moeda, indústria) | Antes de comparar períodos ou moedas |
| `list_google_ads_links` | Contas Google Ads linkadas à propriedade | Auditoria de setup — sem link, não há import de conversões nem audiences |
| `get_custom_dimensions_and_metrics` | Dimensões/métricas custom da propriedade | SEMPRE antes de usar dimensão custom num report |
| `run_report` | Report padrão da Data API (dimensões × métricas × período) | Todo relatório de canal, campanha, conversão |
| `run_funnel_report` | Análise de funil | Diagnóstico de queda entre etapas (view → cart → checkout → purchase) |
| `run_realtime_report` | Atividade ao vivo (últimos 30 min) | Smoke-test de tracking no launch de campanha |

## 2. Workflow: validação de tracking pré-launch (traffic-qa)

Regra de ouro da squad: **nenhuma campanha sobe sem tracking validado.**

1. `get_account_summaries` → confirmar property correta.
2. `list_google_ads_links` → conta de ads linkada? (obrigatório para conversion import/audiences).
3. `get_custom_dimensions_and_metrics` → dimensões custom do plano de eventos existem?
4. Disparar visita de teste com a URL final da campanha (UTMs completos).
5. `run_realtime_report` com dimensões `unifiedScreenName`/`eventName` → o evento-chave apareceu? A sessão entrou com o source/medium esperado?
6. Registrar evidência no veredicto QA (PASS só com evento visto no realtime).

## 3. Reports padrão para tráfego pago

**Performance por campanha (visão UTM):**
- Dimensões: `sessionCampaignName`, `sessionSourceMedium`
- Métricas: `sessions`, `activeUsers`, `keyEvents`, `totalRevenue`
- Período: janela da campanha

**Visão por canal (comparativo macro):**
- Dimensões: `sessionDefaultChannelGroup` (Paid Search, Paid Social, Display…)
- Métricas: `sessions`, `keyEvents`, `totalRevenue`, `engagementRate`

**Conversões por evento:**
- Dimensões: `eventName` — Métricas: `eventCount`, `keyEvents`, `eventValue`
- Filtro: apenas os key events do plano de medição (ver `/traffic-analytics-tracking`).

**Landing pages de campanha:**
- Dimensões: `landingPagePlusQueryString`, `sessionCampaignName`
- Métricas: `sessions`, `bounceRate`, `keyEvents`

**Funil (run_funnel_report):** etapas definidas por evento (ex.: `page_view` → `view_item` → `add_to_cart` → `begin_checkout` → `purchase`), segmentado por `sessionDefaultChannelGroup` para isolar o tráfego pago.

## 4. Dicionário rápido (nomes exatos da Data API)

| Conceito | Dimensão/Métrica GA4 |
|---|---|
| Campanha (UTM) | `sessionCampaignName` / `sessionManualTerm` / `sessionManualAdContent` |
| Origem/mídia | `sessionSourceMedium` (sessão) · `firstUserSourceMedium` (aquisição) |
| Canal | `sessionDefaultChannelGroup` |
| Conversões | `keyEvents` (nomenclatura atual; "conversions" legado) |
| Receita | `totalRevenue` · `purchaseRevenue` |
| Engajamento | `engagementRate` · `averageSessionDuration` · `bounceRate` |
| Usuários | `activeUsers` · `newUsers` · `totalUsers` |

⚠️ `session*` vs `firstUser*`: sessão atribui à campanha da visita; firstUser à campanha que trouxe o usuário pela primeira vez. Relatório de performance de campanha usa `session*`; análise de aquisição/LTV usa `firstUser*`. Nunca misturar os dois no mesmo relatório sem rotular.

## 5. Discrepância plataforma × GA4 (protocolo do traffic-bi)

Números de Meta/Google/TikTok **nunca** batem com GA4 — modelos e janelas de atribuição diferentes, iOS underreporting, consent mode. Divergência > 20% em conversões/ROAS aciona o protocolo do traffic-bi:
1. Investigar causa (janela de atribuição, CAPI/gtag mal configurado, consent, view-through incluído na plataforma).
2. Definir decision driver: plataforma para otimização in-platform; GA4 como árbitro cross-channel e validação de tendência.
3. Todo relatório cross-fonte declara fonte + janela temporal de cada número.

## 6. Guardrails

1. **Read-only** (escopo `analytics.readonly`) — o MCP não altera propriedade, eventos nem links. Mudanças de configuração GA4/GTM são trabalho guiado pela `/traffic-analytics-tracking`.
2. Report vazio ≠ tracking quebrado: conferir período, filtros e se a propriedade é a certa (`get_property_details`) antes de declarar incidente.
3. Dados intraday são parciais; números fecham em até 48h — não emitir veredicto de performance com dados de hoje.
4. Não puxar dimensões de alta cardinalidade sem limite (`landingPagePlusQueryString` explode linhas) — sempre limitar e filtrar.
5. Dimensão custom só existe se registrada na propriedade — validar com `get_custom_dimensions_and_metrics` antes de usar em report.

## 7. Divisão por agente

| Agente | Uso do MCP |
|---|---|
| traffic-bi | Consolidação cross-platform, árbitro de discrepância, ROAS/CPA validados |
| traffic-qa | Smoke-test realtime pré-launch, auditoria de links Ads↔GA4 e eventos-chave |
| traffic-analyst | Canais, comportamento pós-clique, benchmarks de engajamento |
| traffic-strategist | Dados históricos de canal/campanha para briefings e alocação de budget |
