---
name: nextjs-react-best-practices
description: Melhores práticas de performance para React e Next.js (App Router) — eliminar waterfalls, reduzir bundle, otimizar Server Components, data fetching, re-renders e Core Web Vitals. Use ao escrever ou revisar componentes React, páginas Next.js, data fetching (server ou client), ou ao investigar bundle size, hydration e lentidão de render.
version: "1.0"
updated: "2026-08-26"
---

# Next.js + React Best Practices

Skill de performance para código React/Next.js, destilada das regras da engenharia da Vercel (70 regras em 8 categorias, priorizadas por impacto). Usada pelos implementers frontend e fullstack — **dev-dev-alpha, dev-dev-gamma, sites-dev-alpha, sites-dev-beta, sites-dev-gamma** — e pelos reviewers **dev-qa / sites-qa** em code review. Aplique na escrita de componentes novos, em refactors e em auditorias de bundle/render.

## 1. Eliminating Waterfalls (CRITICAL)

**1.1 — Parallelize independent async operations with `Promise.all()`.**

```tsx
// ❌ Sequential — 3 round trips
const user = await getUser(id)
const posts = await getPosts(id)
const stats = await getStats(id)

// ✅ Parallel — 1 round trip window
const [user, posts, stats] = await Promise.all([
  getUser(id), getPosts(id), getStats(id),
])
```

**1.2 — Check cheap conditions before awaiting.** Don't pay for a fetch you might discard.

```tsx
// ❌ fetch always runs
const data = await fetchExpensive()
if (!flag.enabled) return null

// ✅ bail out first
if (!flag.enabled) return null
const data = await fetchExpensive()
```

**1.3 — Move `await` into the branch that needs it.** If only one code path consumes the promise, await it there — start the promise early, await late.

**1.4 — Stream with Suspense instead of blocking the whole page.** Fetch fast data in the page; wrap slow sections in `<Suspense fallback={...}>` and let them stream in.

```tsx
export default async function Page() {
  const header = await getHeader() // fast
  return (
    <>
      <Header data={header} />
      <Suspense fallback={<Skeleton />}>
        <SlowSection /> {/* awaits inside, streams later */}
      </Suspense>
    </>
  )
}
```

**1.5 — Pass promises down, await in the leaf.** Start fetches high in the tree, pass the promise as prop, resolve with `use()` or `await` inside the Suspense boundary.

## 2. Bundle Size (CRITICAL)

**2.1 — Import directly, never through barrel files.**

```ts
// ❌ pulls the whole library through the barrel
import { Button } from '@/components'
// ✅ pulls one module
import { Button } from '@/components/button'
```

**2.2 — `next/dynamic` for heavy, conditionally-shown components** (charts, editors, modals, maps): `const Chart = dynamic(() => import('./chart'), { ssr: false })`.

**2.3 — Load third-party scripts after hydration** with `next/script` (`strategy="lazyOnload"` or `afterInteractive`). Never a raw `<script>` blocking render.

**2.4 — Defer modules until the feature activates** — dynamic `import()` inside the event handler that needs it (e.g., load the export-to-PDF lib on click).

**2.5 — Keep client boundaries small.** `"use client"` marks the top of a client subtree — everything it imports ships to the browser. Push `"use client"` down to the leaf interactive components; keep pages and layouts as Server Components.

## 3. Server-Side Performance (HIGH)

**3.1 — Authenticate Server Actions like API routes.** Every `"use server"` function is a public endpoint. Validate session + input inside the action, never only in the calling UI.

**3.2 — `React.cache()` for per-request deduplication** of repeated reads (e.g., `getCurrentUser()` called by layout + page + components).

```ts
export const getCurrentUser = cache(async () => {
  const session = await auth()
  return session ? db.user.findUnique({ where: { id: session.userId } }) : null
})
```

**3.3 — Cross-request caching:** `unstable_cache`/`"use cache"` or an LRU for data shared between users; always define revalidation (`revalidateTag`/`revalidatePath`) at write time.

**3.4 — `after()` for non-blocking work** — logging, analytics, notifications run after the response is sent.

**3.5 — Never fetch your own API routes from Server Components.** Call the data layer (DB/service) directly; the HTTP hop to yourself is pure overhead.

## 4. Client-Side Data Fetching (MEDIUM-HIGH)

**4.1 — Use SWR (or React Query) instead of `useEffect` + `fetch`.** Automatic dedupe, cache, revalidation, race-condition safety.

```tsx
// ❌ manual effect fetch: no dedupe, races, no cache
useEffect(() => { fetch('/api/user').then(...) }, [])
// ✅
const { data, error, isLoading } = useSWR('/api/user', fetcher)
```

**4.2 — Deduplicate global listeners** — one `resize`/`scroll` listener shared via a small store or context, not one per component instance.

**4.3 — Passive listeners for scroll/touch:** `addEventListener('scroll', fn, { passive: true })`.

**4.4 — Version localStorage payloads** (`{ v: 2, data }`) and handle both parse failure and stale versions on read.

## 5. Re-render Optimization (MEDIUM)

**5.1 — Never define components inside components.** The inner component remounts on every render, losing state and DOM.

**5.2 — Hoist non-primitive default props** (`const EMPTY: Item[] = []`) outside the component — inline `[]`/`{}`/`() => {}` defeats memoization.

**5.3 — Extract expensive subtrees into `memo()` components** and pass primitive props; prefer restructuring (move state down, pass children) over sprinkling `useMemo` everywhere.

**5.4 — Effects should depend on primitives:** `useEffect(fn, [user.id])`, not `[user]`.

**5.5 — `startTransition` for non-urgent updates** (filtering large lists, tab switches) so typing stays responsive.

## 6. Rendering Performance (MEDIUM)

**6.1 — `content-visibility: auto` for long lists**, or virtualize (`react-window`/`virtua`) above ~200 rows.

**6.2 — Prefer ternaries over `&&`** for conditional JSX — `{count && <X/>}` renders a literal `0`.

**6.3 — Extract static JSX** outside the component so it's created once.

**6.4 — Animate a wrapper `<div>` with CSS transforms, not SVG internals**; keep animations on `transform`/`opacity` (compositor-only).

**6.5 — Expected hydration mismatches** (timestamps, locale) → `suppressHydrationWarning` on that node, or render client-only via `useEffect`-gated state.

## 7. JavaScript Micro-Performance (LOW-MEDIUM)

- Use `Map`/`Set` for repeated lookups instead of `array.find`/`includes` in loops (O(1) vs O(n)).
- Combine chained `filter().map()` into one pass when the list is large and hot.
- Batch DOM writes; toggle classes instead of many inline style mutations.
- `requestIdleCallback` for non-critical deferred work.

## 8. Next.js App Router Essentials

- **`generateMetadata`** for SEO; **`next/image`** always (never raw `<img>` for content images); **`next/font`** for zero-layout-shift fonts.
- **Route handlers e páginas dinâmicas:** declare `export const dynamic`/`revalidate` explicitly quando o default implícito não for óbvio.
- **`loading.tsx` + `error.tsx`** em toda rota com fetch — streaming UX e error boundary por segmento.
- **Server Components por padrão**; client components apenas onde há interatividade real.
- **Mutations via Server Actions** com `revalidatePath`/`revalidateTag` — não faça mutate + `router.refresh()` manual quando a action resolve.

## Checklist de review (QA)

- [ ] Nenhum `await` sequencial de operações independentes
- [ ] Nenhum barrel import de libs de UI/ícones
- [ ] `"use client"` apenas em folhas interativas
- [ ] Server Actions autenticam e validam input
- [ ] Fetch client-side via SWR/React Query, não `useEffect` cru
- [ ] Nenhum componente definido dentro de componente
- [ ] Imagens via `next/image`, fontes via `next/font`
- [ ] Listas longas virtualizadas ou com `content-visibility`

---

Adaptado de vercel-labs/agent-skills → react-best-practices (skills.sh) — 2026-08-26. Seção 8 (Next.js) baseada em conhecimento próprio: a skill next-best-practices foi descontinuada (vercel-labs/next-skills arquivado; docs agora embutidas no framework).
