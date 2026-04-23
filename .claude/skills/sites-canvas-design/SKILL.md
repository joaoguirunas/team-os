---
name: sites-canvas-design
description: Design de componentes visuais complexos com Canvas HTML5 e SVG — gráficos, ilustrações e elementos custom.
---

# Sites Canvas Design — HTML5 Canvas e SVG

## Quando usar Canvas vs SVG

| Canvas | SVG |
|---|---|
| Gráficos dinâmicos (dados em tempo real) | Ícones e ilustrações estáticas |
| Efeitos de partículas | Animações CSS/SMIL |
| Jogos e simulações | Logos e elementos de marca |
| Processamento de imagem | Diagramas e infográficos |

## SVG optimizado para web

```tsx
export function Icon({ className }: { className?: string }) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      className={cn("h-6 w-6", className)}
      aria-hidden="true"
    >
      <path ... />
    </svg>
  )
}
```

## Backgrounds CSS avançados

```css
/* Grid background */
.bg-grid {
  background-image: linear-gradient(to right, #e5e7eb 1px, transparent 1px),
                    linear-gradient(to bottom, #e5e7eb 1px, transparent 1px);
  background-size: 32px 32px;
}

/* Gradient mesh */
.bg-mesh {
  background: radial-gradient(at 40% 20%, hsl(220, 90%, 80%) 0px, transparent 50%),
              radial-gradient(at 80% 0%, hsl(262, 80%, 85%) 0px, transparent 50%),
              radial-gradient(at 0% 50%, hsl(355, 85%, 80%) 0px, transparent 50%);
}

/* Noise texture */
.bg-noise::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,...");
  opacity: 0.04;
}
```

## Canvas — animação de partículas simples

```tsx
useEffect(() => {
  const canvas = canvasRef.current
  const ctx = canvas.getContext('2d')
  const animate = () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    particles.forEach(p => { p.update(); p.draw(ctx) })
    requestAnimationFrame(animate)
  }
  animate()
}, [])
```
