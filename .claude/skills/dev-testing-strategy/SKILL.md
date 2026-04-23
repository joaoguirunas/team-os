---
name: dev-testing-strategy
description: Estratégia de testes para software complexo — pirâmide de testes, cobertura mínima, unit vs integration vs E2E, mocking strategy.
version: "1.1"
updated: "2026-04-21"
---

# Testing Strategy — Software Complexo

## Pirâmide de Testes

```
      /E2E\           → poucos, lentos, fluxos completos
     /------\
    / Integr.\        → moderados, módulos integrados
   /----------\
  /    Unit    \      → muitos, rápidos, funções isoladas
```

| Tipo | Proporção | Ferramenta |
|---|---|---|
| Unit | ~70% | Jest / Vitest |
| Integration | ~20% | Jest + supertest |
| E2E | ~10% | Playwright |

## Unit Tests

Testam uma função em isolamento, sem dependências externas reais.

```typescript
describe('calculateDiscount', () => {
  it('should apply 10% for premium users', () => {
    expect(calculateDiscount({ price: 100, tier: 'premium' })).toBe(90)
  })

  it('should not apply discount for free users', () => {
    expect(calculateDiscount({ price: 100, tier: 'free' })).toBe(100)
  })

  it('should throw for negative price', () => {
    expect(() => calculateDiscount({ price: -10, tier: 'free' }))
      .toThrow('Price must be positive')
  })
})
```

**Regras:** Um `describe` por função. Um comportamento por `it`. Testar: happy path + edge cases + erros. Sem banco, sem API externa.

## Integration Tests

Testam módulos integrados — endpoint + middleware + banco real de teste.

```typescript
describe('POST /users', () => {
  it('should create user and return 201', async () => {
    const res = await request(app)
      .post('/users')
      .send({ email: 'test@test.com', name: 'Test' })

    expect(res.status).toBe(201)
    expect(res.body.data).toMatchObject({ email: 'test@test.com' })
    expect(res.body.meta.requestId).toBeDefined()  // requestId obrigatório
  })

  it('should return 409 when email exists', async () => {
    await createUser({ email: 'existing@test.com' })
    const res = await request(app)
      .post('/users').send({ email: 'existing@test.com', name: 'Other' })

    expect(res.status).toBe(409)
    expect(res.body.error.code).toBe('CONFLICT')
    expect(res.body.error.requestId).toBeDefined()
  })
})
```

**Para software complexo:** Usar banco real em teste — mocks de banco escondem problemas de query e migração.

## E2E Tests

```typescript
test('user completes onboarding', async ({ page }) => {
  await page.goto('/signup')
  await page.fill('[name=email]', 'user@test.com')
  await page.fill('[name=password]', 'SecurePass123!')
  await page.click('[type=submit]')
  await expect(page).toHaveURL('/dashboard')
})
```

## Mocking Strategy

| Mockar | Não mockar |
|---|---|
| Serviços externos (Stripe, SendGrid) | Banco de dados em integration tests |
| Relógio / `Date.now()` | Lógica de negócio própria |
| Valores aleatórios | Módulos internos que você controla |

```typescript
// Mock de serviço externo — sempre tipado (ver dev-typescript-patterns)
jest.mock('../services/stripe')
const mockStripe = jest.mocked(stripe)
mockStripe.createPayment.mockResolvedValue({ id: 'pay_123', status: 'succeeded' })

// Mock de relógio para testes de expiração de token
jest.useFakeTimers()
jest.setSystemTime(new Date('2026-04-21T10:00:00Z'))
// ... teste ...
jest.useRealTimers()
```

**Atenção:** Mocks devem ser tipados com `jest.mocked()` ou `jest.fn<ReturnType>()` — ver `dev-typescript-patterns` para exemplos. Mock sem tipo é um bug esperando acontecer.

## Cobertura Mínima (QA Gate)

| Tipo de código | Mínimo |
|---|---|
| Business logic (services, utils) | 90% |
| API handlers | 80% |
| UI components com lógica | 70% |
| Scripts de migração | Smoke test obrigatório |

## Test Setup

```typescript
beforeAll(async () => { await db.migrate.latest() })
afterEach(async () => { await db.truncate(['users', 'orders']) })
afterAll(async () => { await db.destroy() })
```

## Estrutura de arquivos

```
src/services/
├── user.service.ts
└── user.service.test.ts    ← unit junto ao arquivo

tests/
└── e2e/
    └── onboarding.spec.ts  ← E2E separados
```

## Testes adversariais (Kron / dev-dev-delta)

Para código de hardening, testar explicitamente os cenários de falha:

```typescript
describe('withRetry', () => {
  it('should retry 3x on 500 and then throw', async () => {
    const fn = jest.fn().mockRejectedValue({ status: 500 })
    await expect(withRetry(fn, { maxAttempts: 3 })).rejects.toThrow()
    expect(fn).toHaveBeenCalledTimes(3)
  })

  it('should NOT retry on 400 (client error)', async () => {
    const fn = jest.fn().mockRejectedValue({ status: 400 })
    await expect(withRetry(fn)).rejects.toThrow()
    expect(fn).toHaveBeenCalledTimes(1)  // sem retry
  })

  it('should throw TimeoutError after threshold', async () => {
    const slowFn = () => new Promise(res => setTimeout(res, 10000))
    await expect(withTimeout(slowFn(), 100)).rejects.toThrow('Timeout')
  })
})
```

## Regras absolutas

- Testes devem passar antes de qualquer commit
- Novo código sem teste = FAIL no QA gate
- Testes não dependem de ordem de execução
- Testes limpam estado após si mesmos
- Flaky tests são bugs — corrigir imediatamente
- Descrições legíveis: "should {comportamento} when {condição}"
- Mocks sempre tipados — nunca `jest.fn()` sem tipo em TypeScript
