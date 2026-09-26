# Avisos de terceiros (Third-Party Notices)

O pack **team-os** é distribuído sob a licença MIT (ver [LICENSE](./LICENSE), © 2026 João Guirunas).
Algumas skills em `.claude/skills/` foram importadas de projetos de terceiros e adaptadas
(tradução da descrição, frontmatter padronizado, ajustes de caminhos). Os direitos autorais e a
licença originais permanecem com os respectivos autores, listados abaixo. Cada skill importada
que tenha `LICENSE.txt` próprio aponta para este arquivo.

Legenda: **Autor** = titular declarado no `metadata.author`/`LICENSE.txt` da skill; **Origem** = URL
declarada em `metadata`, `source:` ou `LICENSE.txt`; quando não há URL nem licença verificável, o
item está marcado para conferência antes de qualquer redistribuição.

## claude-seo (27 skills `seo*`)

| Skill | Autor | Licença | Origem |
|---|---|---|---|
| `seo` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-ahrefs` | AgriciDaniel (extensão do claude-seo) | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-audit` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-backlinks` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-bing` | AgriciDaniel (extensão do claude-seo) | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-cluster` | AgriciDaniel — autoria original: Lutfiya Miller (Pro Hub Challenge) | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-competitor-pages` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-content` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-content-brief` | **puneetindersingh** (titular do copyright, contribuição ao claude-seo) | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-dataforseo` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-drift` | AgriciDaniel — autoria original: Dan Colta (Pro Hub Challenge) | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-ecommerce` | AgriciDaniel — autoria original: Matej Marjanovic (Pro Hub Challenge) | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-flow` | AgriciDaniel — base de prompts FLOW em `references/` sob **CC BY 4.0** (github.com/AgriciDaniel/flow) | MIT (skill) / CC BY 4.0 (prompts) | https://github.com/AgriciDaniel/claude-seo |
| `seo-geo` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-google` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-hreflang` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-image-gen` | AgriciDaniel (baseada em Claude Banana, github.com/AgriciDaniel/banana-claude) | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-images` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-local` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-maps` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-page` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-plan` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-programmatic` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-schema` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-sitemap` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-sxo` | AgriciDaniel — autoria original: Florian Schmitz (Pro Hub Challenge) | MIT | https://github.com/AgriciDaniel/claude-seo |
| `seo-technical` | AgriciDaniel | MIT | https://github.com/AgriciDaniel/claude-seo |

Texto da licença: `MIT License — Copyright (c) 2026 AgriciDaniel` (e `Copyright (c) 2026 puneetindersingh`
para `seo-content-brief`). Os `LICENSE.txt` das skills remetem ao `LICENSE` raiz do repositório de origem;
o texto integral da MIT é o mesmo de [LICENSE](./LICENSE), trocando-se o titular.

## Outras skills importadas

| Skill | Autor | Licença | Origem / observação |
|---|---|---|---|
| `accessibility` | não identificado no arquivo (frontmatter declara apenas `license: MIT`) | MIT | origem não declarada; conteúdo baseado em WCAG 2.2 (W3C) e Lighthouse — **verificar autoria antes de redistribuir** |
| `deep-research` | 199 Biotechnologies | MIT (README, "modify as needed") | https://github.com/199-biotechnologies/claude-deep-research-skill |
| `negotiation` | wondelai | MIT | origem não declarada em URL (`metadata.author: wondelai`, v1.5.0) |
| `presentation-design` | jwynia | MIT | origem não declarada em URL (`metadata.author: jwynia`, v1.0) |
| `pricing` | não declarado (`metadata.version: 2.1.1`; referencia skills irmãs `paywalls`, `offers`) | **licença upstream não localizada; verificar antes de redistribuir** | origem não declarada |
| `sales-enablement` | não declarado (`metadata.version: 2.0.1`; referencia skills irmãs `competitors`, `copywriting`, `cold-email`, `offers`) | **licença upstream não localizada; verificar antes de redistribuir** | origem não declarada |
| `slides` | claudekit | **licença upstream não localizada; verificar antes de redistribuir** | `metadata.author: claudekit`, v1.0.0; repositório não localizado |
| `startup-financial-modeling` | não declarado (corpo menciona adaptação ao "Codex 8 KB skill body cap") | **licença upstream não localizada; verificar antes de redistribuir** | origem não declarada |
| `ui-ux-pro-max` | nextlevelbuilder | MIT (LICENSE do repositório upstream, conferido em 2026-09-25) | https://github.com/nextlevelbuilder/ui-ux-pro-max-skill — inclui dados derivados de Google Fonts (licenças por família em `data/google-font-licenses.json`) e Phosphor Icons (`data/phosphor-icons-upstream.json`, MIT) |
| `ai-ml-data-science` | não declarado | **licença upstream não localizada; verificar antes de redistribuir** | importada em 2026-06-18 (commit 65743d2) sem metadados de origem; cita `data/sources.json` |
| `ai-ml-timeseries` | não declarado | **licença upstream não localizada; verificar antes de redistribuir** | idem |
| `data-analytics-engineering` | não declarado | **licença upstream não localizada; verificar antes de redistribuir** | idem |
| `data-lake-platform` | não declarado | **licença upstream não localizada; verificar antes de redistribuir** | idem |
| `data-sql-optimization` | não declarado | **licença upstream não localizada; verificar antes de redistribuir** | idem |
| `web-design-guidelines` | João Guirunas (skill) — carrega as **Vercel Web Interface Guidelines** em runtime | MIT (skill); guidelines © Vercel, uso conforme o repositório da Vercel | conteúdo externo não é vendorizado |

Skills não listadas aqui são de autoria de João Guirunas e seguem a licença MIT do repositório.
