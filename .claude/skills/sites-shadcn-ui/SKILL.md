---
name: sites-shadcn-ui
description: Padrões de uso de shadcn/ui — instalação, customização e composição de componentes. Injectado em EROS (sites-ux-alpha).
---

# Sites shadcn/ui — Padrões de Uso

## Instalação e setup

```bash
npx shadcn@latest init
npx shadcn@latest add button card input form dialog
```

## Componentes mais usados em sites

```bash
# UI base
npx shadcn@latest add button input label textarea select

# Layout e conteúdo
npx shadcn@latest add card separator badge avatar

# Navegação
npx shadcn@latest add navigation-menu dropdown-menu sheet

# Feedback
npx shadcn@latest add toast dialog alert-dialog

# Formulários
npx shadcn@latest add form (react-hook-form + zod)
```

## Customização de tema (tailwind.config.ts)

```ts
theme: {
  extend: {
    colors: {
      primary: { DEFAULT: 'hsl(var(--primary))', foreground: 'hsl(var(--primary-foreground))' },
      // Adicionar cores da marca aqui
    },
    borderRadius: {
      lg: 'var(--radius)',
      md: 'calc(var(--radius) - 2px)',
      sm: 'calc(var(--radius) - 4px)',
    },
  }
}
```

## Composição de componentes

```tsx
// Card de produto composto
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card'
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

## Regra de customização
Preferir `className` prop para overrides pontuais. Para variações sistemáticas, usar `cva()`. Nunca modificar ficheiros em `components/ui/` directamente — criar wrapper.
