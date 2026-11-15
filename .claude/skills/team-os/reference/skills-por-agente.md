# Skills por tipo de agente

> Extraído do SKILL.md — carregar sob demanda ao montar o spawn prompt. A **fonte da verdade** por agente é o próprio body do agente em `.claude/agents/` (as skills que ele cita); esta tabela é o atalho de consulta.


team-os SEMPRE inclui no spawn prompt as skills relevantes para cada tipo de agente. Elas ficam disponíveis na sessão do agente para ativar via `/nome-skill`:

| Tipo de agente | Skills a mencionar no spawn prompt |
|---|---|
| **TODOS os agentes** | `/verify-before-done` — obrigatória antes de declarar qualquer trabalho como done |
| **dev-architect / sites-architect** | `/dev-api-design`, `/dev-technical-writing` |
| **dev-analyst / sites-analyst / researcher** | `/deep-research`, `/data-analytics-engineering`, `/dev-defuddle` |
| **dev-dev-alpha** | `/dev-typescript-patterns`, `/dev-testing-strategy`, `/dev-error-handling`, `/nextjs-react-best-practices`, `/ui-craft` |
| **dev-dev-beta** | `/dev-api-design`, `/dev-error-handling`, `/dev-database-patterns`, `/dev-debugging` |
| **dev-dev-gamma** | `/dev-typescript-patterns`, `/dev-database-patterns`, `/dev-error-handling` |
| **dev-dev-delta / sites-dev-delta** | `/dev-security-patterns`, `/dev-testing-strategy`, `/dev-error-handling`, `/dev-debugging`, `/core-web-vitals` |
| **dev-ux** | `/ui-ux-pro-max`, `/accessibility`, `/web-design-guidelines`, `/ui-craft` |
| **dev-qa** | `/dev-testing-strategy`, `/dev-security-patterns`, `/testing-playwright-e2e`, `/dev-debugging`, `/ui-craft` |
| **dev-devops / sites-devops** | `/dev-git-workflow` (+ `/sites-deployment` na squad sites) |
| **dev-data-engineer / sites-data (data engineers)** | `/dev-database-patterns`, `/data-supabase-patterns`, `/data-sql-optimization`, `/dev-security-patterns` |
| **dev-bi / dev-data-performance** | `/data-analytics-engineering`, `/data-sql-optimization`, `/data-lake-platform` |
| **sites-dev-alpha** | `/sites-frontend-stack`, `/ui-ux-pro-max`, `/nextjs-react-best-practices`, `/accessibility`, `/ui-craft` |
| **sites-dev-beta** | `/dev-api-design`, `/dev-error-handling`, `/dev-database-patterns` |
| **sites-dev-gamma** | `/sites-copy`, `/sites-page-cro`, `/sites-seo-technical`, `/traffic-analytics-tracking` |
| **sites-ux** | `/sites-ux-interaction`, `/sites-copy`, `/ui-ux-pro-max`, `/accessibility`, `/ui-craft` |
| **sites-qa** | `/dev-security-patterns`, `/dev-testing-strategy`, `/testing-playwright-e2e`, `/web-design-guidelines`, `/sites-seo-technical`, `/accessibility`, `/ui-craft` |
| **instagram-strategist** | `/instagram-strategy`, `/instagram-dm-flows`, `/social-editorial-validation`, `/social-analytics` |
| **instagram-content** | `/social-copywriting`, `/social-scriptwriting`, `/instagram-dm-flows`, `/social-apify-research`, `/social-carousel-design`, `/copy-humanize` |
| **instagram-publisher** | `/instagram-publishing`, `/social-analytics`, `/social-format-specs` |
| **tiktok-strategist** | `/tiktok-marketing`, `/tiktok-publishing`, `/social-editorial-validation`, `/social-format-specs` |
| **tiktok-content** | `/tiktok-marketing`, `/social-scriptwriting`, `/social-copywriting`, `/social-apify-research`, `/copy-humanize` |
| **tiktok-publisher** | `/tiktok-publishing`, `/tiktok-marketing`, `/social-analytics` |
| **youtube-strategist** | `/youtube-scriptwriting`, `/youtube-packaging`, `/youtube-analytics`, `/social-editorial-validation` |
| **youtube-content** | `/youtube-scriptwriting`, `/youtube-packaging`, `/social-scriptwriting`, `/deep-research`, `/copy-humanize` |
| **youtube-publisher** | `/youtube-publishing`, `/youtube-analytics`, `/youtube-packaging`, `/social-format-specs` |
| **linkedin-strategist** | `/linkedin-strategy`, `/linkedin-publishing`, `/social-editorial-validation`, `/social-copywriting` |
| **linkedin-content** | `/linkedin-strategy`, `/social-copywriting`, `/social-carousel-design`, `/social-format-specs`, `/copy-humanize` |
| **linkedin-publisher** | `/linkedin-publishing`, `/social-analytics`, `/social-format-specs` |
| **social-design** | `/social-key-visual`, `/social-carousel-design`, `/social-stitch-workflow`, `/social-format-specs` |
| **social-photo** | `/social-freepik-generation`, `/social-cinematic-composition` |
| **social-video** | `/social-video-editing`, `/social-heygen-avatar`, `/social-format-specs`, `/social-cinematic-composition` |
| **traffic-strategist** | `/traffic-paid-ads-optimization`, `/tiktok-marketing` |
| **traffic-google** | `/traffic-google-ads-mcp`, `/traffic-paid-ads-optimization` |
| **traffic-meta / traffic-tiktok** | `/traffic-paid-ads-optimization` (+ `/tiktok-marketing` no tiktok) |
| **traffic-bi / traffic-analyst** | `/traffic-ga4-mcp`, `/traffic-analytics-tracking`, `/data-analytics-engineering` |
| **traffic-qa** | `/traffic-analytics-tracking`, `/traffic-ga4-mcp` |
| **traffic-automation** | `/traffic-google-ads-mcp`, `/traffic-analytics-tracking` |
| **traffic-copywriter** | `/social-copywriting`, `/tiktok-marketing`, `/traffic-paid-ads-optimization`, `/copy-humanize` |
| **traffic-designer** | `/social-format-specs`, `/social-key-visual` |
| **pm-data / pm-analyst** | `/data-supabase-patterns`, `/data-sql-optimization`, `/data-analytics-engineering` |
| **pm-reporter / pm-coach** | `/dev-technical-writing` |
| **sales-analyst** | `/sales-discovery-intake`, `/deep-research`, `/dev-defuddle`, `/doc-to-markdown` |
| **sales-strategist** | `/negotiation`, `/sales-pricing-payback`, `/pricing` |
| **sales-planner** | `/sales-proposal-planning`, `/sales-discovery-intake`, `/dev-technical-writing` |
| **sales-finance** | `/sales-pricing-payback`, `/startup-financial-modeling`, `/pricing` |
| **sales-copywriter** | `/sales-proposal-copy`, `/sales-enablement`, `/sites-copy`, `/copy-humanize` |
| **sales-designer** | `/sales-deck-production` (com a variante deck), `/presentation-design`, `/ui-ux-pro-max` |
| **sales-qa** | `/sales-proposal-copy`, `/sales-deck-production`, `/presentation-design` |
| **sales-closer** | `/negotiation`, `/sales-enablement`, `/sales-proposal-copy` |
| **brand-analyst** | `/brand-research`, `/deep-research`, `/dev-defuddle` |
| **brand-strategist** | `/brand-platform`, `/brand-research`, `/pricing` |
| **brand-architect** | `/brand-platform`, `/dev-technical-writing`, `/brand-rollout` |
| **brand-voice** | `/brand-verbal-identity`, `/sites-copy`, `/brand-platform`, `/copy-humanize` |
| **brand-designer** | `/brand-visual-system`, `/design`, `/ui-ux-pro-max`, `/web-design-guidelines`, `/social-key-visual` |
| **brand-insights** | `/brand-tracking`, `/data-analytics-engineering`, `/social-analytics` |
| **brand-rollout** | `/brand-rollout`, `/brand-verbal-identity`, `/brand-visual-system` |
| **brand-qa** | `/brand-verbal-identity`, `/brand-visual-system`, `/brand-platform` |
| **finance-analyst** | `/finance-bookkeeping`, `/deep-research`, `/dev-defuddle`, `/doc-to-markdown` |
| **finance-strategist** | `/finance-cash-flow`, `/finance-reporting`, `/startup-financial-modeling`, `/pricing` |
| **finance-planner** | `/finance-cash-flow`, `/finance-reporting`, `/startup-financial-modeling`, `/dev-technical-writing` |
| **finance-controller** | `/finance-bookkeeping`, `/finance-cash-flow`, `/data-analytics-engineering` |
| **finance-billing** | `/finance-receivables-payables`, `/finance-bookkeeping`, `/negotiation` |
| **finance-tax** | `/finance-tax-compliance`, `/finance-bookkeeping`, `/deep-research` |
| **finance-reporter** | `/finance-reporting`, `/finance-cash-flow`, `/dev-technical-writing` |
| **finance-qa** | `/finance-bookkeeping`, `/finance-receivables-payables`, `/finance-reporting` |
| **legal-analyst** | `/legal-research`, `/deep-research`, `/dev-defuddle`, `/doc-to-markdown` |
| **legal-strategist** | `/legal-contract-drafting`, `/legal-research`, `/negotiation` |
| **legal-architect** | `/legal-clause-library`, `/legal-contract-lifecycle`, `/dev-technical-writing` |
| **legal-drafter** | `/legal-contract-drafting`, `/legal-clause-library`, `/legal-research`, `/doc-to-markdown` |
| **legal-compliance** | `/legal-compliance-lgpd`, `/legal-contract-lifecycle`, `/data-analytics-engineering` |
| **legal-disputes** | `/legal-contract-lifecycle`, `/legal-research`, `/negotiation` |
| **legal-ops** | `/legal-contract-lifecycle`, `/legal-clause-library`, `/dev-technical-writing` |
| **legal-qa** | `/legal-contract-drafting`, `/legal-clause-library`, `/legal-compliance-lgpd` |
| **squad seo (15 agentes)** | a skill homônima do papel (`/seo-technical`, `/seo-content`, `/seo-schema`…); `seo-performance` também `/core-web-vitals` — detalhe por agente no README §5 |
| **squad security (7 agentes)** | `/security-audit-method`, `/dev-security-patterns` + a do papel (`/security-threat-modeling`, `/security-privacy-data-map`, `/security-incident-response`) — detalhe no README §5 |
| **squad robotics (10 agentes)** | `/robotics-electrical-safety` e `/robotics-bringup-testing` (régua comum dos gates) + a do papel (`/robotics-project-planning`, `/robotics-component-research`, `/robotics-power-battery`, `/robotics-firmware-patterns`, `/robotics-motion-control`, `/robotics-ros2-autonomy`, `/robotics-iot-connectivity`, `/robotics-mechanical-build`) — detalhe no README §5 |

> Nomes novos após a fusão de skills (não usar os antigos): `/sites-copy` (ex sites-copywriting/copy-editing/content-strategy) e `/sites-frontend-stack` (ex sites-frontend-design/tailwind-design-system/shadcn-ui); `/accessibility` (ex sites-web-accessibility).
