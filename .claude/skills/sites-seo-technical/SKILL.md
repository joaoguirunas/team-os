---
name: sites-seo-technical
description: SEO técnico para websites — Next.js ou Astro: meta tags, schema.org, sitemap, robots.txt e Core Web Vitals. Use ao implementar ou auditar SEO on-page, configurar metadata e dados estruturados, gerar sitemap e robots ou otimizar Core Web Vitals para ranking, em qualquer uma das duas stacks.
version: "1.1"
updated: "2026-09-20"
---

# Sites SEO Técnico — Next.js e Astro

## 1. Metadata

### Next.js — Metadata API (App Router)

```tsx
// layout.tsx — metadata base
export const metadata: Metadata = {
  metadataBase: new URL('https://exemplo.pt'),
  title: { default: 'Marca', template: '%s | Marca' },
  description: 'Descrição base do site',
  openGraph: {
    type: 'website',
    locale: 'pt_PT',
    siteName: 'Marca',
  },
  twitter: { card: 'summary_large_image', creator: '@handle' },
  robots: { index: true, follow: true },
}

// page.tsx — metadata específica
export const metadata: Metadata = {
  title: 'Keyword Primária',
  description: 'Descrição optimizada com keyword e proposta de valor. Max 160 chars.',
  alternates: { canonical: '/path' },
}
```

### Astro — `<head>` / Layout

```astro
---
// src/layouts/Layout.astro
interface Props { title: string; description: string; canonical?: string; ogImage?: string }
const { title, description, canonical, ogImage } = Astro.props
const canonicalURL = canonical ?? new URL(Astro.url.pathname, Astro.site)
---
<html lang="pt">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{title}</title>
  <meta name="description" content={description} />
  <link rel="canonical" href={canonicalURL} />
  <meta property="og:type" content="website" />
  <meta property="og:title" content={title} />
  <meta property="og:description" content={description} />
  {ogImage && <meta property="og:image" content={new URL(ogImage, Astro.site)} />}
  <meta name="twitter:card" content="summary_large_image" />
  <slot name="head" />
</head>
<body><slot /></body>
</html>
```

Astro faz merge automático de `<head>` de layouts aninhados (tags duplicadas por `rel`+`href` ou por nome do meta são deduplicadas, a última declaração vence) — não precisa de uma "Metadata API" própria como o Next; o `<head>` é HTML de verdade, definido no layout e sobrescrito por slot quando a página precisa de algo específico. `Astro.site` vem de `site:` no `astro.config.mjs` — configurar sempre (ver §3).

## 2. Schema.org (JSON-LD)

Mesmo objeto de schema nas duas stacks — muda só a sintaxe de injeção no HTML.

### Next.js — `dangerouslySetInnerHTML`

```tsx
// Organization
const schema = {
  '@context': 'https://schema.org',
  '@type': 'Organization',
  name: 'Marca',
  url: 'https://exemplo.pt',
  logo: 'https://exemplo.pt/logo.png',
  sameAs: ['https://instagram.com/marca', 'https://linkedin.com/company/marca'],
}

// FAQ
const faqSchema = {
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  mainEntity: faqs.map(faq => ({
    '@type': 'Question',
    name: faq.question,
    acceptedAnswer: { '@type': 'Answer', text: faq.answer }
  }))
}

// Adicionar ao layout
<script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }} />
```

### Astro — `set:html`

```astro
---
const schema = {
  '@context': 'https://schema.org',
  '@type': 'Organization',
  name: 'Marca',
  url: Astro.site,
}
---
<script type="application/ld+json" set:html={JSON.stringify(schema)} />
```

`set:html` é a diretiva Astro equivalente ao `dangerouslySetInnerHTML` do React — injeta a string sem escapar. O objeto de schema em si é idêntico ao da trilha Next (mesma modelagem schema.org, mesmos tipos Organization/FAQPage/o que for necessário) — só a forma de colocar o JSON no HTML muda.

## 3. Sitemap

### Next.js — `app/sitemap.ts`

```ts
// app/sitemap.ts
export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: 'https://exemplo.pt', lastModified: new Date(), changeFrequency: 'monthly', priority: 1 },
    { url: 'https://exemplo.pt/sobre', lastModified: new Date(), changeFrequency: 'monthly', priority: 0.8 },
  ]
}
```

### Astro — `@astrojs/sitemap`

```js
// astro.config.mjs
import { defineConfig } from 'astro/config'
import sitemap from '@astrojs/sitemap'

export default defineConfig({
  site: 'https://exemplo.pt',       // obrigatório — sem isso a integração falha
  integrations: [sitemap()],
})
```

Gera `sitemap-index.xml` + `sitemap-0.xml` no build a partir das rotas reais (inclusive Content Collections) — não precisa listar página por página como no `app/sitemap.ts` do Next. Opção `customSitemaps` para apontar sitemaps externos (ex.: um CMS que já gera o seu).

### robots.txt (Astro)

`robots.txt` é um arquivo estático em `public/robots.txt` (ou um endpoint `src/pages/robots.txt.ts` se precisar ser dinâmico) — apontar para `{site}/sitemap-index.xml`.

## 4. Core Web Vitals

### Next.js — otimizações

```tsx
// LCP: priorizar hero image
<Image src="/hero.jpg" alt="..." priority fill sizes="100vw" />

// CLS: reservar espaço para imagens
<div className="relative aspect-video">
  <Image src="..." alt="..." fill />
</div>

// INP: evitar JS pesado no main thread (FID foi removido do CrUX/PageSpeed em set/2024 — INP é a única métrica de interatividade)
// Usar dynamic imports para componentes pesados
const HeavyChart = dynamic(() => import('./HeavyChart'), { ssr: false })
```

### Astro — a vantagem estrutural (zero-JS por padrão)

- **LCP:** zero JS por padrão já reduz o Time to Interactive; usar `<Image loading="eager" fetchpriority="high">` na imagem do hero (equivalente ao `priority` do `next/image`).
- **CLS:** `astro:assets` sempre injeta `width`/`height` — reservar o espaço é automático quando a imagem passa pelo componente `<Image>`/`<Picture>` (nunca usar `<img>` cru para imagem de conteúdo).
- **INP:** a arquitetura de ilhas já ataca a causa raiz (menos JS = menos trabalho de main thread) — a única forma de piorar isso é abusar de `client:load` onde `client:visible`/`client:idle` bastaria. Não existe "dynamic import ssr:false" à la Next — a ilha já é isso por natureza.

Isso não dispensa disciplina — só dá uma base melhor de largada. A tabela de diretivas de hidratação (detalhada em `sites-frontend-stack` §3) resume onde cada JS de ilha entra:

| Diretiva | Quando hidrata | Impacto em CWV |
|---|---|---|
| `client:load` | Imediatamente | Só para crítico acima da dobra — cada uso injustificado é regressão de INP |
| `client:idle` | Navegador ocioso | Seguro para importante-mas-não-urgente |
| `client:visible` | Entra na viewport | Padrão recomendado para tudo abaixo da dobra |
| `client:media={query}` | Media query bate | Só carrega JS no breakpoint relevante |
| `client:only={framework}` | Sem SSR, só client | Aceitável quando depende de API só de navegador |

`client:load` generalizado é FAIL de performance no checklist do `sites-qa`, não CONCERNS — contradiz o motivo de o projeto ter escolhido Astro.
