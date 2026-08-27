---
name: testing-playwright-e2e
description: Melhores práticas de testes E2E com Playwright — locators resilientes, auto-waiting, isolamento de testes, fixtures, autenticação, mocking de rede, prevenção de flakiness e CI. Use ao escrever, revisar ou debugar testes Playwright, ao investigar testes flaky, ao configurar playwright.config, ou ao montar suíte E2E para webapps.
version: "1.0"
updated: "2026-08-26"
---

# Playwright E2E Best Practices

Skill de testes end-to-end destilada do playwright-best-practices da Currents.dev. Usada por **dev-qa e sites-qa** (test design, gates de qualidade), **dev-dev-delta e sites-dev-delta** (hardening, caça a flakiness) e pelos implementers ao entregar testes junto com stories. Complementa `dev-testing-strategy` (pirâmide de testes) — esta skill cobre a camada E2E.

## 1. Locators (a fundação)

**1.1 — Priority order:** `getByRole` > `getByLabel` > `getByPlaceholder` > `getByText` > `getByTestId` > CSS/XPath (last resort).

```ts
// ❌ brittle — breaks on any DOM/style refactor
page.locator('.btn-primary > span')
page.locator('div:nth-child(3) button')

// ✅ resilient — tied to user-visible semantics
page.getByRole('button', { name: 'Submit order' })
page.getByLabel('Email address')
page.getByTestId('checkout-total') // when semantics don't identify it
```

**1.2 — Locators are lazy and auto-retrying.** Define once, reuse; never cache element handles (`elementHandle` is a legacy API).

**1.3 — Filter and chain instead of complex selectors:**

```ts
page.getByRole('listitem').filter({ hasText: 'Product A' }).getByRole('button', { name: 'Add' })
```

## 2. Assertions & Waiting (a causa nº 1 de flakiness)

**2.1 — Use web-first assertions — they auto-wait and retry:**

```ts
// ❌ reads state once, races the app
expect(await page.locator('.status').textContent()).toBe('Done')
// ✅ retries until timeout
await expect(page.getByTestId('status')).toHaveText('Done')
```

**2.2 — NEVER `page.waitForTimeout()`.** Hard sleeps are the top flakiness source and slow the suite. Wait for a condition instead:

```ts
// ❌ await page.waitForTimeout(3000)
// ✅
await expect(page.getByRole('alert')).toBeVisible()
await page.waitForURL('**/dashboard')
await page.waitForResponse(r => r.url().includes('/api/orders') && r.ok())
```

**2.3 — Assert user-visible outcomes, not implementation** (URL, visible text, enabled state — not internal store values).

**2.4 — Signal-then-act:** when a click triggers a request you need to await, register `waitForResponse` BEFORE the click:

```ts
const done = page.waitForResponse('**/api/save')
await page.getByRole('button', { name: 'Save' }).click()
await done
```

## 3. Test Isolation & State

**3.1 — Every test runs from scratch:** own data, own storage state. Never depend on execution order or on data created by another test (breaks `--repeat-each`, sharding, retries).

**3.2 — Seed via API/DB, assert via UI.** Setup through the UI is slow and fragile:

```ts
test('edit a project', async ({ page, request }) => {
  const project = await request.post('/api/projects', { data: factory.project() })
  await page.goto(`/projects/${(await project.json()).id}`)
  // ... UI assertions
})
```

**3.3 — Unique test data per run** (`faker`/timestamp suffix) so parallel workers don't collide.

**3.4 — Clean up in fixtures, not in test bodies** — teardown runs even when the test fails.

## 4. Authentication

**4.1 — Log in once per role in a setup project; reuse `storageState`:**

```ts
// auth.setup.ts
setup('authenticate', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill(process.env.E2E_USER!)
  await page.getByLabel('Password').fill(process.env.E2E_PASS!)
  await page.getByRole('button', { name: 'Sign in' }).click()
  await page.waitForURL('**/dashboard')
  await page.context().storageState({ path: 'playwright/.auth/user.json' })
})
// playwright.config.ts → project { name: 'chromium', use: { storageState: 'playwright/.auth/user.json' }, dependencies: ['setup'] }
```

**4.2 — Multiple roles = multiple storage states**; multi-user collaboration tests use two `browser.newContext()` in the same test.

**4.3 — Credenciais SEMPRE via env vars/secrets** — nunca hardcoded no repo.

## 5. Fixtures & Page Objects

**5.1 — Prefer fixtures over classic POM herança.** Fixtures compõem, fazem setup/teardown e tipam:

```ts
export const test = base.extend<{ dashboard: DashboardPage }>({
  dashboard: async ({ page }, use) => {
    const d = new DashboardPage(page)
    await d.goto()
    await use(d)
  },
})
```

**5.2 — Page objects leves:** encapsulam locators e ações, NUNCA assertions (assertions ficam no teste, visíveis).

**5.3 — Extraia setup comum para fixtures**, não para `beforeEach` gigantes copiados entre arquivos.

## 6. Network Mocking

- **E2E crítico (checkout, auth): serviços reais.** Integrações de terceiros (payment, email, OAuth externo): mock.
- `page.route()` para stub de respostas; teste também os caminhos de erro:

```ts
await page.route('**/api/orders', route =>
  route.fulfill({ status: 500, json: { error: 'internal' } }))
await expect(page.getByRole('alert')).toContainText('Something went wrong')
```

- Teste offline/latência: `context.setOffline(true)`, `route` com delay.
- HAR recording (`recordHar`) para congelar respostas complexas de terceiros.

## 7. Configuration & CI

```ts
export default defineConfig({
  fullyParallel: true,
  forbidOnly: !!process.env.CI,      // test.only não passa no CI
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? '50%' : undefined,
  reporter: [['html'], ['list']],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  webServer: { command: 'npm run start', url: 'http://localhost:3000', reuseExistingServer: !process.env.CI },
})
```

- **Trace on-first-retry** é o padrão certo: barato e dá diagnóstico completo (`npx playwright show-trace`).
- Sharding em CI para suítes grandes: `--shard=1/4`.
- Timeouts: aumente o específico (`expect.configure`, `test.slow()`), nunca o global como band-aid.

## 8. Debugging & Anti-Flakiness Loop

Loop de validação obrigatório antes de dar um teste como pronto:

1. `npx playwright test --reporter=list` — rodar tudo.
2. Falhou? Ler o erro + trace (`show-trace`), corrigir locator/wait/assertion — não adicionar sleep.
3. Repetir até verde.
4. **Provar estabilidade: `npx playwright test <spec> --repeat-each=5`** (e `--workers=4` para expor colisão de dados).
5. Só então marcar a story/gate como concluída.

Red flags de review: `waitForTimeout`, seletores CSS posicionais, `networkidle`, testes dependentes de ordem, assertions sem `await`, dados compartilhados entre testes.

## Checklist de review (QA gate)

- [ ] Locators por role/label/testid — zero seletores posicionais
- [ ] Zero `waitForTimeout`; web-first assertions em tudo
- [ ] Testes independentes e paralelizáveis (`fullyParallel` verde)
- [ ] Auth via storageState em setup project
- [ ] Setup de dados via API/factory, não via UI
- [ ] Caminhos de erro e loading testados, não só happy path
- [ ] `--repeat-each=5` verde nos testes novos
- [ ] Trace/screenshot configurados para falhas em CI

---

Adaptado de currents-dev/playwright-best-practices-skill (skills.sh) — 2026-08-26. O SKILL.md fonte é um roteador para ~40 arquivos de referência; as regras acima destilam as categorias core (locators, assertions/waiting, isolation, fixtures, auth, mocking, CI, debugging) com exemplos próprios.
