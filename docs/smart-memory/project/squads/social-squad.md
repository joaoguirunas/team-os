---
title: Social Squad
type: squad-doc
status: active
created: 2026-04-24
updated: 2026-04-24
tags: [squad, social]
related: ["[[../modules]]", "[[../architecture]]"]
---

# Squad social — Redes Sociais

## Visão geral

Squad para produção e publicação de conteúdo em redes sociais. 7 agentes com identidades alien race, MCPs especializados (Apify, Google Stitch, Freepik, Meta) e um fluxo editorial com gate obrigatório da VERA antes de qualquer publicação.

## Identidades alien race

| Agente | Identidade | Arquétipo |
|---|---|---|
| social-content | **LYRIS** | Content Creator — pesquisa + escrita |
| social-design | **AEON** | Graphic Designer — visual + design system |
| social-photo | **IRIS** | Photo Creator — imagens AI |
| social-publisher | **PULSE** | Publisher + Analytics — ativação + métricas |
| social-strategist | **VERA** | Strategist + Validator — editorial gate |
| social-video | **FLUX** | Video Editor — Reels, TikToks, Shorts |

## Composição

### social-analyst (sonnet) — sem identidade alien
**Papel:** Research e analytics — tendências, concorrentes, hashtags, audiências, benchmarks.
**Quando usar:** On-demand. Entrega dados, não decide.
**Tools:** `Read, Glob, Grep, Bash, WebSearch, WebFetch, SendMessage`

### social-content / LYRIS (sonnet)
**Papel dual:** Research via Apify MCP + copywriting (captions, scripts, hooks, hashtags).
**MCPs:** `mcp__apify__apify--rag-web-browser`, `mcp__apify__call-actor`, `mcp__apify__get-actor-output`
**Quando usar:** Research de mercado e criação de copy social.
**Tools:** `Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, SendMessage` + Apify MCPs

### social-design / AEON (sonnet)
**Papel:** Key Visuals, carousels, templates e overlays via Google Stitch MCP.
**MCPs:** Stitch completo (create_project, create_design_system, generate_screen, variants, edit, apply) + 21st Magic (component_builder, inspiration, logo_search)
**Quando usar:** Criação de assets gráficos para feed posts, carousels, Stories templates.

### social-photo / IRIS (sonnet)
**Papel:** Geração de fotos AI para covers, carousels, hero images, backgrounds cinematográficos.
**MCPs:** `mcp__freepik__generate-image`, `mcp__freepik__upscale-image`, `mcp__freepik__reframe-image`
**Quando usar:** Imagens fotográficas (produto, pessoas, lifestyle, cenários).

### social-publisher / PULSE (sonnet)
**Papel dual:** Publicação via Meta MCP + análise de métricas.
**MCPs:** `mcp__meta__publish_post`, `mcp__meta__schedule_post`, `mcp__meta__get_insights`, `mcp__meta__get_posts`, `mcp__meta__upload_media`
**Regra crítica:** SÓ publica APÓS VERA (social-strategist) aprovar E usuário confirmar explicitamente.

### social-strategist / VERA (opus)
**Papel:** Validação editorial e direcionamento estratégico.
**NUNCA cria conteúdo** — valida e dirige. Aprovação OBRIGATÓRIA antes de qualquer publicação.
**Tools:** `Read, Write, Edit, Glob, Grep, SendMessage` (sem Bash, sem web)

### social-video / FLUX (sonnet)
**Papel:** Edição de vídeo para Reels, Stories, TikToks, Shorts via ffmpeg.
**Quando usar:** Produção/edição de vídeos para social media.
**Tools:** `Read, Write, Edit, Glob, Grep, Bash, SendMessage`

## Fluxo obrigatório de publicação

```
social-analyst (trend research)
  → LYRIS / social-content (copy + research Apify)
  → AEON / social-design (visuals via Stitch) + IRIS / social-photo (fotos via Freepik)
  → FLUX / social-video (se vídeo necessário)
  → VERA / social-strategist ← GATE OBRIGATÓRIO (aprova ou rejeita)
  → [usuário confirma explicitamente]
  → PULSE / social-publisher (Meta MCP → publicação)
```

## Skills complementares da squad social

| Skill | Função |
|---|---|
| `/social-copywriting` | Frameworks: hooks, CTAs, legendas |
| `/social-scriptwriting` | Roteiros para Reels, TikToks, Shorts |
| `/social-carousel-design` | Estrutura narrativa de slides |
| `/social-key-visual` | Key Visuals para campanhas |
| `/social-format-specs` | Specs técnicas por plataforma |
| `/social-editorial-validation` | Checklist de qualidade editorial |
| `/social-analytics` | KPIs, benchmarks, relatórios |
| `/social-apify-research` | Research via Apify |
| `/social-freepik-generation` | Prompts para Freepik |
| `/social-stitch-workflow` | Workflow com Google Stitch |
| `/social-video-editing` | Edição ffmpeg para social |
| `/social-meta-publishing` | Publicação Meta MCP |
| `/social-cinematic-composition` | Composição cinematográfica |
| `/tiktok-marketing` | Estratégia e criação para TikTok |

## Plataformas suportadas

Instagram, Facebook (Meta MCP), TikTok (via ffmpeg/FLUX), YouTube Shorts (via ffmpeg/FLUX), Reels, Stories
