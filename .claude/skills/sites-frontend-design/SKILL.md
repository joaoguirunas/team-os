---
name: sites-frontend-design
description: Padrões de design e implementação frontend para websites — componentes React, Tailwind CSS, Next.js App Router. Injectado em EROS (sites-ux-alpha) e LUMEN (sites-ux-beta).
---

# Sites Frontend Design — Padrões e Componentes

## Stack standard

```
Next.js (App Router) + TypeScript
Tailwind CSS + CSS custom properties
shadcn/ui (componentes base)
Framer Motion (animações)
Lucide React (ícones)
next/font (tipografia)
```

## Estrutura de projecto

```
src/
├── app/
│   ├── layout.tsx        # Root layout
│   ├── page.tsx          # Home
│   └── [route]/
│       └── page.tsx
├── components/
│   ├── ui/               # shadcn components
│   ├── sections/         # Page sections
│   └── layout/           # Header, Footer
├── lib/
│   └── utils.ts          # cn() e utilities
└── styles/
    └── globals.css        # Tailwind + custom props
```

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

## Design tokens (globals.css)

```css
:root {
  --color-primary: 220 90% 56%;
  --color-background: 0 0% 100%;
  --radius: 0.5rem;
  --font-sans: 'Inter', system-ui, sans-serif;
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
