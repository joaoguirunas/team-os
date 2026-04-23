---
name: sites-seo-technical
description: SEO técnico para websites Next.js — meta tags, schema.org, sitemap, robots.txt, Core Web Vitals. Injectado em NEXUS (sites-seo).
---

# Sites SEO Técnico — Next.js

## Metadata API (App Router)

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

## Schema.org (JSON-LD)

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

## Sitemap automático (Next.js)

```ts
// app/sitemap.ts
export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: 'https://exemplo.pt', lastModified: new Date(), changeFrequency: 'monthly', priority: 1 },
    { url: 'https://exemplo.pt/sobre', lastModified: new Date(), changeFrequency: 'monthly', priority: 0.8 },
  ]
}
```

## Core Web Vitals — otimizações

```tsx
// LCP: priorizar hero image
<Image src="/hero.jpg" alt="..." priority fill sizes="100vw" />

// CLS: reservar espaço para imagens
<div className="relative aspect-video">
  <Image src="..." alt="..." fill />
</div>

// FID/INP: evitar JS pesado no main thread
// Usar dynamic imports para componentes pesados
const HeavyChart = dynamic(() => import('./HeavyChart'), { ssr: false })
```
