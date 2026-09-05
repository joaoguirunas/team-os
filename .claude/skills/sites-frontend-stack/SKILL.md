---
name: sites-frontend-stack
description: Stack frontend padrão para websites — Next.js App Router, Tailwind v4 (@theme), shadcn/ui e Motion. Use ao iniciar projeto de site, criar componentes/seções, definir tokens de design, configurar tema shadcn ou implementar animações e layout responsivo.
version: "1.0"
updated: "2026-09-04"
---

# Sites Frontend Stack — Next.js + Tailwind v4 + shadcn/ui

Stack padrão, estrutura de projeto, tokens de design (definidos UMA vez), padrões de componente e composição shadcn/ui.

## Stack padrão

```
Next.js (App Router) + TypeScript
Tailwind CSS v4 (@theme CSS-first)
shadcn/ui (componentes base)
Motion — pacote `motion`, import de `motion/react` (ex-Framer Motion)
Lucide React (ícones)
next/font (tipografia)
```

## Estrutura de projeto

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

## Design tokens — Tailwind v4 (@theme, CSS-first)

Os tokens vivem **uma vez só** no `globals.css`. No Tailwind v4 não há `tailwind.config.ts` por padrão — o tema é declarado em CSS e cada token vira utility automaticamente (`bg-primary`, `text-foreground`, `rounded-lg`...).

```css
/* globals.css */
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

> **Nota (legado v3):** em projetos ainda no Tailwind v3, os mesmos tokens vão em `:root` como custom properties e são mapeados em `theme.extend` no `tailwind.config.ts` (`primary: 'hsl(var(--primary))'`). Ao migrar para v4, mover tudo para o bloco `@theme` e remover o config.

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

## Padrão de componente

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

## Responsivo (mobile-first)

```tsx
<div className="
  grid grid-cols-1        /* mobile */
  md:grid-cols-2          /* tablet */
  lg:grid-cols-3          /* desktop */
  gap-4 md:gap-6 lg:gap-8
">
```

## shadcn/ui

### Instalação e setup

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

### Composição de componentes

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

### Regra de customização
Preferir a prop `className` para overrides pontuais. Para variações sistemáticas, usar `cva()`. **Nunca modificar arquivos em `components/ui/` diretamente** — criar wrapper.

## Animações — Motion (`motion/react`)

O sucessor do Framer Motion é o pacote **`motion`**; em React o import é `motion/react` (API compatível com `framer-motion`).

```tsx
import { motion } from 'motion/react'

// Fade in up
<motion.div initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4 }}>

// Scroll-triggered nativo (substitui useInView manual)
<motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true, amount: 0.1 }} />
```

Componentes com Motion precisam de `"use client"` no App Router. Respeitar `prefers-reduced-motion` (ver skill `sites-ux-interaction`).
