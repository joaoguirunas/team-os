---
name: sites-frontend-stack
description: "Stack frontend para websites — Next.js App Router OU Astro (Content Collections, ilhas), Tailwind v4 (@theme), shadcn/ui e Motion. Use ao iniciar projeto de site em qualquer uma das duas stacks, criar componentes/seções, definir tokens de design ou implementar animações."
version: "1.0"
updated: "2026-09-20"
---

# Sites Frontend Stack — Next.js e Astro + Tailwind v4 + shadcn/ui

Stack padrão das duas trilhas suportadas pela squad `sites`, estrutura de projeto, tokens de design (definidos UMA vez, compartilhados), padrões de componente em cada stack e composição shadcn/ui.

## 1. Escolha de stack

A decisão entre Next.js, Astro ou Híbrido é responsabilidade exclusiva do `sites-architect` (workflow "Escolher stack — Next.js / Astro / Híbrido", registrado como ADR em `docs/smart-memory/decisions/ADR-{N}-stack-choice.md`). Esta skill não repete os critérios de decisão — ela cobre a implementação de cada stack já decidida. Resumo de quando cada uma costuma entrar:

- **Next.js** — área autenticada complexa, painel com muito estado no cliente, infraestrutura de API pesada (webhooks, filas, jobs).
- **Astro** — site majoritariamente de conteúdo (institucional, landing page, blog, documentação, portfólio) com SEO/Core Web Vitals como prioridade dura.
- **Híbrido** (de ilha — um projeto Astro com ilhas React pontuais — ou separado — dois deploys, conteúdo em Astro e app autenticado em Next.js) — quando o projeto tem as duas necessidades ao mesmo tempo.

Ver o corpo do `sites-architect` para a tabela completa de critérios e o formato do ADR antes de escolher a stack de um projeto novo.

## 2. Stack Next.js

```
Next.js (App Router) + TypeScript
Tailwind CSS v4 (@theme CSS-first)
shadcn/ui (componentes base)
Motion — pacote `motion`, import de `motion/react` (ex-Framer Motion)
Lucide React (ícones)
next/font (tipografia)
```

### Estrutura de projeto (Next.js)

```
src/
├── app/
│   ├── layout.tsx        # Root layout
│   ├── page.tsx          # Home
│   ├── globals.css       # Tailwind + @theme (tokens)
│   └── [route]/
│       └── page.tsx
├── components/
│   ├── ui/               # shadcn components (nunca editar direto)
│   ├── sections/         # Seções de página (Hero, Features, CTA)
│   └── layout/           # Header, Footer
└── lib/
    └── utils.ts          # cn() e utilities
```

### Responsivo (mobile-first)

```tsx
<div className="
  grid grid-cols-1        /* mobile */
  md:grid-cols-2          /* tablet */
  lg:grid-cols-3          /* desktop */
  gap-4 md:gap-6 lg:gap-8
">
```

Mesmas classes utilitárias do Tailwind v4 valem para a trilha Astro — só troca `className` por `class` (ver §3).

### shadcn/ui

#### Instalação e setup

```bash
npx shadcn@latest init

# UI base
npx shadcn@latest add button input label textarea select

# Layout e conteúdo
npx shadcn@latest add card separator badge avatar

# Navegação
npx shadcn@latest add navigation-menu dropdown-menu sheet

# Feedback
npx shadcn@latest add sonner dialog alert-dialog

# Formulários — o componente form usa react-hook-form + zod
npx shadcn@latest add form
npm install react-hook-form zod @hookform/resolvers
```

#### Composição de componentes

```tsx
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'

export function ProductCard({ title, price, badge }: ProductCardProps) {
  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader>
        <Badge variant="secondary">{badge}</Badge>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>...</CardContent>
      <CardFooter>
        <Button className="w-full">{price} — Comprar</Button>
      </CardFooter>
    </Card>
  )
}
```

Em projeto Astro, os mesmos componentes shadcn/ui funcionam **via ilha React** — mesma instalação acima, componente importado dentro de um `.astro` e hidratado com a diretiva `client:*` adequada (ver §3.4). Não há um "shadcn para Astro" separado: é o mesmo pacote React, só que hidratado seletivamente em vez de rodar a árvore inteira no cliente.

#### Regra de customização
Preferir a prop `className` para overrides pontuais. Para variações sistemáticas, usar `cva()`. **Nunca modificar arquivos em `components/ui/` diretamente** — criar wrapper.

### Animações — Motion (`motion/react`)

O sucessor do Framer Motion é o pacote **`motion`**; em React o import é `motion/react` (API compatível com `framer-motion`).

```tsx
import { motion } from 'motion/react'

// Fade in up
<motion.div initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4 }}>

// Scroll-triggered nativo (substitui useInView manual)
<motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true, amount: 0.1 }} />
```

Componentes com Motion precisam de `"use client"` no App Router. Respeitar `prefers-reduced-motion` (ver skill `sites-ux-interaction`).

## 3. Stack Astro

```
Astro (SSG por padrão, SSR seletivo por rota) + TypeScript
Tailwind CSS v4 (@theme CSS-first — mesmo bloco da trilha Next, ver §4)
Content Collections (Content Layer API) para conteúdo versionado em repo
astro:assets para imagens e fontes
Ilhas React/Vue/Svelte via diretivas `client:*` — só onde há interatividade real
View Transitions nativa (astro:transitions) para navegação entre páginas
```

### Estrutura de projeto (Astro)

```
src/
├── pages/                  # roteamento por arquivo — cada .astro/.md vira uma rota
│   ├── index.astro
│   ├── sobre.astro
│   └── blog/
│       ├── index.astro     # listagem
│       └── [slug].astro    # rota dinâmica — getStaticPaths() para SSG
├── content/                # Content Collections (Content Layer API, Astro 5+)
│   └── blog/
│       └── *.md | *.mdx
├── content.config.ts       # defineCollection + schema Zod (fora de src/content/config.ts nas versões novas)
├── components/
│   ├── ui/                 # componentes .astro (ou ilhas React em components/react/)
│   └── sections/
├── layouts/
│   └── Layout.astro        # <head> + <slot />
└── styles/
    └── global.css          # Tailwind v4 (@theme) — mesma seção da trilha Next
```

### Componente `.astro` (sem framework, HTML por padrão)

```astro
---
// frontmatter = roda no servidor/build, nunca no navegador
interface Props {
  title: string
  variant?: 'default' | 'secondary'
}
const { title, variant = 'default' } = Astro.props
---
<div class:list={['card', variant]}>
  <h3>{title}</h3>
  <slot />
</div>

<style>
  .card { padding: 1rem; }
</style>
```

Sem `"use client"`, sem hook, sem re-render — o frontmatter roda uma vez, no build/servidor. Interatividade só entra via `<script>` (client-side, escopado automaticamente ao componente — ver `sites-ux-interaction`) ou via ilha de framework.

### Content Collections (Content Layer API, Astro 5+)

```ts
// src/content.config.ts
import { defineCollection, z } from 'astro:content'
import { glob } from 'astro/loaders'

const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    pubDate: z.coerce.date(),
    image: z.string().optional(),
  }),
})

export const collections = { blog }
```

```astro
---
// src/pages/blog/[slug].astro
import { getCollection, render } from 'astro:content'
export async function getStaticPaths() {
  const posts = await getCollection('blog')
  return posts.map(post => ({ params: { slug: post.id }, props: { post } }))
}
const { post } = Astro.props
const { Content } = await render(post)
---
<Content />
```

Substitui CMS leve para blog/docs/portfólio quando o conteúdo vive em arquivos do repositório. Para CMS externo (Contentful/Sanity/Strapi), a Content Layer API também aceita loaders customizados que buscam de API — mesmo papel que o `sites-dev-beta` já cobre na trilha Next.

### Ilhas — hidratação seletiva (Islands Architecture)

5 diretivas oficiais, cada componente de framework (React/Vue/Svelte/Preact) precisa de uma:

| Diretiva | Quando hidrata | Uso típico |
|---|---|---|
| `client:load` | Imediatamente após o HTML carregar | Componente crítico acima da dobra (ex.: um seletor de idioma no header) |
| `client:idle` | Quando o navegador fica ocioso (`requestIdleCallback`) | Componente importante mas não urgente |
| `client:visible` | Quando entra na viewport (IntersectionObserver) | **Padrão recomendado** para qualquer coisa abaixo da dobra — carrossel, FAQ, formulário no meio da página |
| `client:media={query}` | Quando uma media query bate | Componente só relevante em certo breakpoint (ex.: menu mobile) |
| `client:only={framework}` | Sem SSR — só client, precisa dizer o framework (`client:only="react"`) | Componente que depende de API só de navegador (mapa, player) |

**Regra de ouro de performance:** cada `client:load` que não precisa ser `client:load` é JS que o usuário baixa à toa — o oposto do que SEO/CWV pede. Padrão é `client:visible`/`client:idle`; `client:load` só com justificativa (o `sites-qa` cobra isso no checklist).

### Imagens e fontes — `astro:assets`

```astro
---
import { Image, Picture } from 'astro:assets'
import heroImg from '../assets/hero.jpg'
---
<Image src={heroImg} alt="…" width={1200} height={630} loading="eager" fetchpriority="high" />
<!-- responsivo com formatos modernos -->
<Picture src={heroImg} alt="…" formats={['avif', 'webp']} widths={[400, 800, 1200]} sizes="100vw" />
```

Otimiza formato/tamanho no build, injeta `width`/`height` automaticamente (zero CLS por design — mesmo objetivo do `next/image`, execução diferente). Fonte: usar `@fontsource/*` (self-hosted, sem request externo) ou o font helper de `astro:assets` — ambos evitam o layout shift de fonte carregada via `<link>` do Google Fonts.

### View Transitions e Server Islands (Astro 5+)

- **View Transitions API nativa** (`<ClientRouter />` em `astro:transitions`): navegação com transição suave entre páginas sem virar SPA — mantém o modelo multi-page (bom para SEO: cada página continua sendo uma URL real, indexável).
- **Server Islands**: parte da página fica em cache estático (CDN) e um componente específico renderiza sob demanda no servidor a cada request — útil para personalização (ex.: "olá, {nome}") sem perder o cache da página inteira. Diferente de uma ilha de cliente: essa hidrata no servidor, não no navegador.

### API server-side — Astro Actions e endpoints

```ts
// src/actions/index.ts — Astro Actions: função tipada, chamável do client sem fetch manual
import { defineAction } from 'astro:actions'
import { z } from 'astro:schema'

export const server = {
  subscribeNewsletter: defineAction({
    input: z.object({ email: z.string().email() }),
    handler: async (input) => {
      // validação já garantida pelo schema Zod — mesma disciplina da trilha Next (dev-beta)
      return { success: true }
    },
  }),
}
```

```ts
// src/pages/api/contact.ts — endpoint tradicional, equivalente ao Route Handler do Next
export async function POST({ request }: APIContext) {
  const data = await request.json()
  return new Response(JSON.stringify({ ok: true }), { status: 200 })
}
```

Astro Actions = paralelo direto do Server Action do Next (função tipada chamada do client, sem escrever fetch). Endpoint em `pages/api/*.ts` = paralelo do Route Handler. Exigem `output: 'server'` ou `output: 'static'` com `export const prerender = false` na rota específica (SSR seletivo).

### Renderização — output modes

```js
// astro.config.mjs
export default defineConfig({
  output: 'static',   // default — tudo pré-renderizado (SSG). Rota específica pode virar SSR com:
  // export const prerender = false  (dentro da própria página/endpoint)
  // ou output: 'server' — tudo sob demanda, precisa de adapter
})
```

`static` é o ponto de partida certo para o cenário de "SEO em primeiro lugar" (páginas viram HTML no build, servidas por CDN, sem cold start). `server` só quando a maior parte do site depende de dado por request.

## 4. Compartilhado entre as duas — Design tokens Tailwind v4 (@theme, CSS-first)

Os tokens vivem **uma vez só** — em `app/globals.css` (Next.js) ou `src/styles/global.css` (Astro), mesmo bloco `@theme`. No Tailwind v4 não há `tailwind.config.ts` por padrão — o tema é declarado em CSS e cada token vira utility automaticamente (`bg-primary`, `text-foreground`, `rounded-lg`...).

```css
/* globals.css (Next.js) ou global.css (Astro) */
@import "tailwindcss";

@theme {
  /* Brand */
  --color-primary: oklch(0.55 0.2 262);
  --color-primary-foreground: oklch(0.98 0 0);
  --color-secondary: oklch(0.96 0.01 250);
  --color-accent: oklch(0.6 0.19 290);

  /* Semânticas */
  --color-success: oklch(0.63 0.17 150);
  --color-warning: oklch(0.75 0.16 75);
  --color-error: oklch(0.6 0.21 25);

  /* Neutros */
  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.2 0.02 260);
  --color-muted: oklch(0.96 0.01 250);
  --color-border: oklch(0.92 0.01 250);

  /* Tipografia e raio */
  --font-sans: 'Inter', system-ui, sans-serif;
  --radius-lg: 0.5rem;
  --radius-md: calc(0.5rem - 2px);
  --radius-sm: calc(0.5rem - 4px);
}
```

> **Nota (legado v3):** em projetos ainda no Tailwind v3, os mesmos tokens vão em `:root` como custom properties e são mapeados em `theme.extend` no `tailwind.config.ts` (`primary: 'hsl(var(--primary))'`). Ao migrar para v4, mover tudo para o bloco `@theme` e remover o config. Vale para as duas stacks.

### Escala tipográfica (referência)

```
text-xs 12px labels/badges · text-sm 14px captions · text-base 16px body
text-lg 18px intro · text-xl 20px h4 · text-2xl 24px h3 · text-3xl 30px h2
text-4xl 36px h1 mobile · text-5xl 48px h1 tablet · text-6xl 60px h1 desktop · text-7xl 72px hero
```

### Spacing (base 4px)
Usar a escala padrão (`p-4` = 16px, `py-16/24/32` para seções). Ritmo vertical de seção: `py-16 md:py-24 lg:py-32`.

### Utilities custom

```css
@utility container-site {
  margin-inline: auto;
  max-width: var(--container-7xl);
  padding-inline: 1rem;
}
```

(No v3: `@layer utilities { .container-site { @apply mx-auto max-w-7xl px-4 sm:px-6 lg:px-8; } }`)

## 5. Padrão de componente

### React function component (Next.js)

```tsx
interface ComponentProps {
  variant?: 'default' | 'secondary'
  className?: string
  children: React.ReactNode
}

export function Component({ variant = 'default', className, children }: ComponentProps) {
  return (
    <div className={cn(componentVariants({ variant }), className)}>
      {children}
    </div>
  )
}
```

### Componente `.astro` (Astro)

```astro
---
interface Props {
  variant?: 'default' | 'secondary'
  class?: string
}
const { variant = 'default', class: className } = Astro.props
---
<div class:list={['component', variant, className]}>
  <slot />
</div>
```

Mesma disciplina de props tipadas e variantes das duas stacks — a diferença é que o componente `.astro` não recebe `children` como prop: usa `<slot />` nativo, e a composição de classes usa `class:list` em vez de `cn()`.
