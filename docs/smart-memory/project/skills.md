---
title: Skills — Catálogo Completo
type: modules
status: active
agent: dev-analyst
created: 2026-04-24
updated: 2026-04-24
tags: [project, skills]
related: ["[[overview]]", "[[modules]]", "[[architecture]]"]
---

# Catálogo de Skills (42 total)

Skills ficam em `.claude/skills/{nome}/SKILL.md` e são invocadas com `/{nome}`.

## Orquestração

| Skill | Função |
|---|---|
| `/team-os` | Team Lead Orchestrator — bootstrap, plan, dispatch, status, resume |
| `/team-os-creator` | Cria novos agentes nativos do Claude Code para Agent Teams |

## Squad dev — Skills especializadas

| Skill | Função |
|---|---|
| `/dev-api-design` | Design de APIs REST, tRPC, contratos, versionamento |
| `/dev-database-patterns` | Padrões de DB: migrations seguras, indexação, query optimization |
| `/dev-error-handling` | Resiliência: retry, circuit breaker, fallback patterns |
| `/dev-security-patterns` | Segurança: autenticação, autorização, RBAC |
| `/dev-testing-strategy` | Estratégia de testes: pirâmide, cobertura, test design |
| `/dev-typescript-patterns` | TypeScript idiomático: types vs interfaces, generics |
| `/dev-git-workflow` | Branch strategy, conventional commits, PR workflow |
| `/dev-technical-writing` | ADRs, module specs, decisões técnicas |
| `/dev-defuddle` | Extrai markdown limpo de páginas web via Defuddle CLI |

## Squad sites — Skills especializadas

| Skill | Função |
|---|---|
| `/sites-seo-keywords` | Keyword research e estratégia de conteúdo SEO |
| `/sites-seo-technical` | SEO técnico: meta tags, schema.org, sitemap, robots.txt |
| `/sites-copywriting` | Frameworks: AIDA, PAS, BAB, 4Ps, StoryBrand |
| `/sites-copy-editing` | Revisão e edição de copy: clareza, consistência, tom |
| `/sites-page-cro` | Otimização de conversão: estrutura, hierarquia, trust signals |
| `/sites-tailwind-design-system` | Design system com Tailwind: tokens, tipografia, paleta |
| `/sites-shadcn-ui` | Padrões shadcn/ui: instalação, customização, composição |
| `/sites-frontend-design` | Design e implementação frontend: componentes React |
| `/sites-ux-interaction` | UX e interações: navegação, micro-animações, acessibilidade |
| `/sites-canvas-design` | Canvas HTML5 e SVG: gráficos complexos, visualizações |
| `/sites-content-strategy` | Arquitetura de informação, hierarquia, plano editorial |
| `/sites-web-accessibility` | WCAG 2.1 AA, ARIA, navegação por teclado e leitores |
| `/sites-deployment` | Deploy Next.js: Vercel, Netlify, Cloudflare Pages, CI/CD |

## Squad social — Skills especializadas

| Skill | Função |
|---|---|
| `/social-copywriting` | Legendas, hooks, CTAs, estrutura de copy social |
| `/social-scriptwriting` | Roteiros para Reels, TikToks, Stories, Shorts |
| `/social-carousel-design` | Estrutura narrativa de slides, copy e design de carousels |
| `/social-key-visual` | Key Visuals para campanhas: identidade, paleta, composição |
| `/social-format-specs` | Specs técnicas de formatos por plataforma (dimensões, duração) |
| `/social-editorial-validation` | Checklist de qualidade e alinhamento editorial |
| `/social-analytics` | KPIs, benchmarks, relatórios e otimização de métricas |
| `/social-apify-research` | Research de tendências e concorrentes via Apify MCP |
| `/social-freepik-generation` | Prompts eficazes para geração de imagens via Freepik |
| `/social-stitch-workflow` | Workflow de design com Google Stitch MCP |
| `/social-video-editing` | Edição de vídeo com ffmpeg para redes sociais |
| `/social-meta-publishing` | Publicação via Meta MCP: upload, agendamento, workflow |
| `/social-cinematic-composition` | Regras de composição cinematográfica para foto e vídeo |
| `/tiktok-marketing` | Estratégia TikTok, criação de vídeo, otimização de postagem |

## Cross-squad — Skills universais

| Skill | Função |
|---|---|
| `/deep-research` | Pesquisa multi-fonte com rastreamento de evidências e citações |
| `/accessibility` | Auditoria WCAG 2.2 e melhoria de acessibilidade web |
| `/ui-ux-pro-max` | Design intelligence: 50+ estilos, 161 paletas, web e mobile |
| `/web-design-guidelines` | Review de UI code para conformidade com guidelines |

## Utilitários do Claude Code

| Skill | Função |
|---|---|
| `/init` | Inicializa CLAUDE.md com documentação do codebase |
| `/review` | Review de pull request |
| `/security-review` | Security review das mudanças pendentes no branch |

## Como funciona uma skill

```
.claude/skills/{nome}/
├── SKILL.md          # Prompt completo da skill (lido pelo sistema ao invocar)
├── templates/        # Templates usados internamente
├── scripts/          # Scripts bash de suporte
└── reference/        # Docs de referência
```

Ao invocar `/{nome}`, o conteúdo de `SKILL.md` é carregado como instrução especializada para a sessão atual. Skills podem spawnar teammates, criar arquivos, ler smart-memory e coordenar workflows complexos.
