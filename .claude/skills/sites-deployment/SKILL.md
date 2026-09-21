---
name: sites-deployment
description: Deploy de sites Next.js ou Astro — Vercel, Netlify e Cloudflare Pages, CI/CD, variáveis de ambiente e processo de release.
version: "1.1"
updated: "2026-09-20"
---

# Sites Deployment — Plataformas e Processo

## Checklist pré-deploy

```
[ ] npm run build — sem erros
[ ] npm run lint — sem warnings críticos
[ ] npm run typecheck — sem erros de tipo
[ ] Variáveis de ambiente verificadas (.env.example actualizado)
[ ] Images otimizadas (next/image no Next.js; astro:assets Image/Picture no Astro)
[ ] Lighthouse score > 90 em todas as categorias
```

## Vercel (recomendado para Next.js)

```bash
npm i -g vercel
vercel login
vercel link
vercel          # preview
vercel --prod   # produção
vercel env add NOME_VAR production
```

## Netlify

```bash
npm i -g netlify-cli
netlify login
netlify init
netlify deploy --dir=.next --prod
```

## Cloudflare Pages

```bash
npm i -g wrangler
wrangler pages deploy .next --project-name=nome-projeto
```

## Astro

Diferença chave vs Next.js: build output padrão do Astro é `dist/` (não `.next/`) quando `output: 'static'`;
com adapter + `output: 'server'`, cada plataforma gera seu próprio formato de função serverless/edge (não
mais `.next/`). Sempre registrar `site:` no `astro.config.mjs` **antes** de configurar sitemap/canonical —
sem isso as URLs absolutas quebram.

| Plataforma | Adapter Astro | Build output | Comando |
|---|---|---|---|
| Vercel | `@astrojs/vercel` (ou zero-config — Vercel detecta Astro nativamente) | `.vercel/output` | `vercel --prod` (igual à trilha Next) |
| Netlify | `@astrojs/netlify` | `dist/` (SSG) ou função serverless (SSR) | `netlify deploy --dir=dist --prod` (SSG) |
| Cloudflare Pages | `@astrojs/cloudflare` | `dist/` | `wrangler pages deploy dist --project-name=nome` |

```bash
# Vercel — zero-config ou com adapter explícito
npm i -g vercel
vercel login
vercel link
vercel --prod

# Netlify — output estático (SSG)
npm i -g netlify-cli
npm i @astrojs/netlify
netlify login
netlify init
netlify deploy --dir=dist --prod

# Cloudflare Pages
npm i -g wrangler
npm i @astrojs/cloudflare
wrangler pages deploy dist --project-name=nome-projeto
```

```js
// astro.config.mjs
import { defineConfig } from 'astro/config'
import vercel from '@astrojs/vercel' // ou netlify / cloudflare, conforme a plataforma

export default defineConfig({
  site: 'https://exemplo.pt', // obrigatório — sitemap e canonical dependem disso
  output: 'static',           // default — tudo pré-renderizado (SSG)
  adapter: vercel(),          // só necessário quando output: 'server' ou SSR seletivo por rota
})
```

Não existe mais um modo `'hybrid'` separado nas versões atuais do Astro. Todos os três adapters suportam
SSR total (`output: 'server'`) e SSR seletivo por rota — que é `output: 'static'` (o modo padrão) mais
`export const prerender = false` dentro da página/endpoint específico que precisa rodar por request. Ou
seja, "híbrido" hoje é uma flag por página dentro do modo `static`, não uma opção separada de `output`.

## GitHub Actions (CI/CD)

```yaml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci && npm run build && npm test
```

## Convenção de branches

```
main      → produção
develop   → staging/preview
feat/*    → features
fix/*     → bug fixes
```
