---
name: sites-ux-interaction
description: Padrões de UX e interacção para websites — navegação, micro-interacções, animações e scroll behaviour. Injectado em LUMEN (sites-ux-beta).
---

# Sites UX Interaction — Padrões de Interacção

## Navegação

### Header sticky
```tsx
const [scrolled, setScrolled] = useState(false)
useEffect(() => {
  const handleScroll = () => setScrolled(window.scrollY > 20)
  window.addEventListener('scroll', handleScroll, { passive: true })
  return () => window.removeEventListener('scroll', handleScroll)
}, [])

<header className={cn(
  "fixed top-0 w-full z-50 transition-all duration-300",
  scrolled ? "bg-white/95 backdrop-blur shadow-sm" : "bg-transparent"
)}>
```

### Mobile nav (Sheet)
```tsx
<Sheet>
  <SheetTrigger asChild>
    <Button variant="ghost" size="icon" aria-label="Menu">
      <Menu className="h-5 w-5" />
    </Button>
  </SheetTrigger>
  <SheetContent side="right">...</SheetContent>
</Sheet>
```

## Animações com Framer Motion

### Enter animations
```tsx
// Fade in up (elemento)
<motion.div initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4 }}>

// Stagger em lista
<motion.div variants={{ animate: { transition: { staggerChildren: 0.1 } } }} initial="initial" animate="animate">
  {items.map(item => <motion.div key={item} variants={fadeInUp}>{item}</motion.div>)}
</motion.div>
```

### Scroll-triggered (Intersection Observer)
```tsx
const { ref, inView } = useInView({ threshold: 0.1, triggerOnce: true })
<motion.div ref={ref} initial={{ opacity: 0 }} animate={inView ? { opacity: 1 } : {}} />
```

## Micro-interacções

```css
/* Hover em card */
.card { @apply transition-all duration-200 hover:-translate-y-1 hover:shadow-lg; }

/* Button press */
.btn { @apply active:scale-95 transition-transform duration-100; }

/* Link underline animado */
.link { @apply relative after:absolute after:bottom-0 after:left-0 after:h-0.5 after:w-0 after:bg-current hover:after:w-full after:transition-all after:duration-300; }
```

## Reduced motion
```tsx
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
const transition = prefersReducedMotion ? { duration: 0 } : { duration: 0.4 }
```
