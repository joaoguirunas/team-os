---
name: sites-deployment
description: Deploy de sites Next.js — Vercel, Netlify, Cloudflare Pages. CI/CD, variáveis de ambiente e processo de release.
---

# Sites Deployment — Plataformas e Processo

## Checklist pré-deploy

```
[ ] npm run build — sem erros
[ ] npm run lint — sem warnings críticos
[ ] npm run typecheck — sem erros de tipo
[ ] Variáveis de ambiente verificadas (.env.example actualizado)
[ ] Images optimizadas (next/image em todos os casos)
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
