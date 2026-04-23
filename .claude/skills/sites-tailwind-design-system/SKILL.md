---
name: sites-tailwind-design-system
description: Design system com Tailwind CSS — tokens, escala tipográfica, paleta e spacing. Injectado em EROS (sites-ux-alpha).
---

# Sites Tailwind Design System

## Paleta de cores (padrão)

```css
/* globals.css */
:root {
  /* Brand */
  --color-primary: 220 90% 56%;
  --color-primary-foreground: 0 0% 100%;
  --color-secondary: 220 14% 96%;
  --color-accent: 262 80% 60%;

  /* Semânticas */
  --color-success: 142 71% 45%;
  --color-warning: 38 92% 50%;
  --color-error: 0 84% 60%;

  /* Neutros */
  --color-background: 0 0% 100%;
  --color-foreground: 222 47% 11%;
  --color-muted: 210 40% 96%;
  --color-border: 214 32% 91%;
}
```

## Escala tipográfica

```
text-xs    — 12px — labels, badges
text-sm    — 14px — body pequeno, captions
text-base  — 16px — body padrão
text-lg    — 18px — body grande, intro
text-xl    — 20px — h4
text-2xl   — 24px — h3
text-3xl   — 30px — h2
text-4xl   — 36px — h1 mobile
text-5xl   — 48px — h1 tablet
text-6xl   — 60px — h1 desktop
text-7xl   — 72px — hero grande
```

## Spacing scale (rem base 4px)

```
space-1   — 4px
space-2   — 8px
space-4   — 16px
space-6   — 24px
space-8   — 32px
space-12  — 48px
space-16  — 64px
space-24  — 96px
space-32  — 128px
```

## Classes utilitárias custom

```css
@layer utilities {
  .container-site {
    @apply mx-auto max-w-7xl px-4 sm:px-6 lg:px-8;
  }
  .section-padding {
    @apply py-16 md:py-24 lg:py-32;
  }
  .heading-display {
    @apply text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight;
  }
}
```
