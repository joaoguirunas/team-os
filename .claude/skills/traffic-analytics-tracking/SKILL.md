---
name: traffic-analytics-tracking
description: Implementação e auditoria de analytics — GA4, Google Tag Manager, tracking plans, convenções de eventos, UTMs, atribuição multi-touch e validação de dados. Use ao configurar ou auditar GA4/GTM, definir plano de eventos, padronizar UTMs, medir campanhas, investigar discrepância de atribuição ou validar conversion tracking antes de campanha subir.
version: "1.0"
updated: "2026-08-26"
---

# Analytics & Tracking

Skill de medição destilada do skill "analytics" (ex-analytics-tracking) do marketingskills de Corey Haines. Usada por **traffic-bi** (fonte de verdade de métricas e atribuição), **traffic-qa** (validação de UTMs/pixels pré-launch), **traffic-automation** (pipelines de dados de campanha) e **sites-dev-gamma / dev-dev-gamma** (wiring de analytics no código). Regra de ouro da squad: nenhuma campanha sobe sem tracking validado.

## 1. Princípios

1. **Decision-driven tracking:** todo evento deve informar uma decisão. Zero vanity metrics. Qualidade > quantidade de eventos.
2. **Questions-first:** trabalhe de trás para frente — que pergunta o dado responde? que ação será tomada com a resposta? Se não há ação, não rastreie.
3. **Consistência antes de implementação:** convenção de nomes e tracking plan documentados ANTES de qualquer tag entrar no site.

## 2. Antes de implementar (assessment obrigatório)

1. **Contexto de negócio:** quais são as conversões-chave (macro e micro)? Qual o funil?
2. **Estado atual:** o que já é rastreado, com quais ferramentas (GA4, GTM, Mixpanel, Segment, pixels de plataforma)? Onde há duplicação?
3. **Stack técnico e compliance:** SPA ou MPA? Consent mode/LGPD/GDPR? Server-side tagging?

## 3. Convenção de eventos (object_action)

Formato: **`objeto_ação` em snake_case, minúsculas, verbo no passado.**

```
✅ signup_completed, trial_started, checkout_completed, video_played, lead_form_submitted
❌ Click Button 3, NewSignup!, page_visited_pricing_v2_final
```

**Estrutura de cada evento no tracking plan:**

| Campo | Exemplo |
|---|---|
| Event name | `checkout_completed` |
| Category | conversion |
| Properties | `value`, `currency`, `items`, `coupon` |
| Trigger | server-side, após confirmação de pagamento |
| Notes | dispara 1x por pedido; dedup por `transaction_id` |

**Propriedades padrão em todos os eventos:** page (title, location, referrer), identificador de usuário (ID interno, nunca PII), atribuição de campanha (source, medium, campaign), detalhes de produto quando aplicável.

**Regras:**
- Tracking plan é documento vivo e versionado (planilha ou repo) — é a fonte de verdade; GA4/GTM refletem o plano, nunca o contrário.
- Eventos de conversão críticos (purchase, lead) preferencialmente server-side (Measurement Protocol / CAPI) com dedup por event_id.
- **Nunca enviar PII** (email, telefone, nome) em nomes de eventos, propriedades ou URLs.

## 4. UTMs — convenção obrigatória

| Parâmetro | Papel | Exemplos |
|---|---|---|
| `utm_source` | Origem do tráfego | `google`, `meta`, `tiktok`, `newsletter` |
| `utm_medium` | Canal | `cpc`, `paid_social`, `email`, `organic_social`, `referral` |
| `utm_campaign` | Campanha | `2026q3_freetrial_lookalike` |
| `utm_content` | Variação de anúncio/criativo | `video_hook2`, `carousel_prova` |
| `utm_term` | Keyword (search) | `crm+para+dentistas` |

**Regras duras:**
- Tudo minúsculo, sem espaços (usar `_` ou `-`), sem acentos — `Google`, `google` e `GOOGLE` viram 3 fontes diferentes no GA4.
- Vocabulário fechado de source/medium documentado; naming de campaign alinhado com o naming das plataformas (`[PLATAFORMA]_[OBJETIVO]_[AUDIÊNCIA]_[OFERTA]_[DATA]` — ver `traffic-paid-ads-optimization`).
- **Nunca usar UTMs em links internos** — sobrescreve a atribuição original da sessão.
- Gerar links via planilha/template central, não à mão; QA valida antes do launch.

## 5. GA4 — setup essencial

- **Conversões (key events):** marcar apenas as que mapeiam para o funil de negócio; micro-conversões ficam como eventos normais.
- **Custom dimensions/metrics** registradas para toda propriedade usada em relatório (evento não registrado = invisível em exploration).
- **Filtros:** excluir tráfego interno e dev; definir `unwanted referrals` (gateways de pagamento) para não roubar atribuição.
- **Data retention:** subir de 2 para 14 meses (default apaga histórico de exploration).
- **Google Ads link + import de conversões** quando aplicável; BigQuery export ligado desde o dia 1 (é grátis e não retroage).
- **GTM:** um container por site; tags organizadas por pasta; versões nomeadas com changelog; variáveis de dataLayer tipadas e documentadas no tracking plan.

## 6. Atribuição

- **Plataformas de ads inflam resultados** (janelas próprias, view-through, dedup inexistente entre plataformas). A soma das conversões reportadas por Google + Meta + TikTok será sempre maior que o real.
- Hierarquia de leitura: **dados de plataforma para otimização intra-plataforma; GA4/BigQuery para comparação entre canais; CAC blended para decisão de negócio.**
- Nunca somar conversões de janelas de atribuição diferentes — reportar lado a lado.
- Modelos: GA4 usa data-driven por padrão; para funis longos B2B, complementar com atribuição de primeiro toque (origem do lead no CRM) e offline conversion import.
- Aceitar a incerteza: triangular (plataforma + GA4 + CRM/receita real) em vez de buscar "o número certo".

## 7. Validação (obrigatória antes de dar tracking como pronto)

Loop de validação:

1. **GTM Preview Mode** — cada tag dispara no trigger certo, uma única vez.
2. **GA4 DebugView** — evento chega com todas as propriedades populadas corretamente.
3. **Conversão real de teste** ponta a ponta (compra/lead de teste) confirmada na plataforma de ads E no GA4.
4. **Checagem de PII** — nenhum email/nome/telefone em URLs, eventos ou propriedades.
5. **Cross-check após 48h** — volumes batem entre plataforma, GA4 e backend (tolerância típica 5–15%; acima disso, investigar dedup/consent/adblock).

## Checklist de auditoria (traffic-qa / traffic-bi)

- [ ] Tracking plan documentado e atualizado (eventos, propriedades, triggers, owners)
- [ ] Convenção object_action aplicada; sem eventos duplicados/órfãos
- [ ] Conversões-chave marcadas como key events e testadas com conversão real
- [ ] UTMs em 100% dos links pagos, minúsculos, vocabulário fechado
- [ ] Sem UTMs em links internos
- [ ] Sem PII em nenhum evento/URL
- [ ] Tráfego interno filtrado; referrals indesejados excluídos
- [ ] Data retention 14 meses + BigQuery export ativo
- [ ] Consent mode configurado conforme LGPD/GDPR
- [ ] Discrepância plataforma × GA4 × backend medida e documentada

---

Adaptado de coreyhaines31/marketingskills → skill "analytics" (ex-"analytics-tracking" na v1.x) (skills.sh) — 2026-08-26. Seções de GA4 setup e atribuição expandidas com conhecimento próprio sobre os mesmos tópicos do skill fonte.
