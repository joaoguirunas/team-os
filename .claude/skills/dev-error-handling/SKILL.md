---
name: dev-error-handling
description: Padrões de resilência e error handling para software complexo — retry, circuit breaker, timeouts, error boundaries, logging estruturado.
version: "1.1"
updated: "2026-04-21"
---

# Error Handling & Resilience — Software Complexo

## Princípio fundamental

**Falha é inevitável. Design para falha, não apenas para sucesso.**

Todo código que interage com: banco de dados, APIs externas, filesystem, serviços de terceiros — deve ter error handling explícito.

## Retry com Exponential Backoff

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  options: { maxAttempts?: number; baseDelay?: number } = {}
): Promise<T> {
  const { maxAttempts = 3, baseDelay = 300 } = options

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn()
    } catch (error) {
      if (attempt === maxAttempts) throw error
      // Não fazer retry em erros 4xx (erro do cliente, não transitório)
      if (error.status >= 400 && error.status < 500) throw error

      const delay = baseDelay * Math.pow(2, attempt - 1)  // 300ms, 600ms, 1200ms
      const jitter = Math.random() * 100
      await sleep(delay + jitter)
    }
  }
}

// Uso
const user = await withRetry(() => externalApi.getUser(id), { maxAttempts: 3 })
```

## Timeout Explícito

```typescript
async function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  const timeout = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error(`Timeout after ${ms}ms`)), ms)
  )
  return Promise.race([promise, timeout])
}

// Uso — nunca deixar chamada externa sem timeout
const result = await withTimeout(
  externalApi.processPayment(data),
  5000  // 5 segundos máximo
)
```

## Circuit Breaker

Evita cascata de falhas — para de tentar quando serviço está claramente down.

```typescript
class CircuitBreaker {
  private failures = 0
  private lastFailure?: Date
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED'

  constructor(
    private readonly threshold = 5,     // abrir após 5 falhas
    private readonly timeout = 60000    // tentar novamente após 60s
  ) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      const elapsed = Date.now() - this.lastFailure!.getTime()
      if (elapsed < this.timeout) {
        throw new Error('Circuit breaker is OPEN — service unavailable')
      }
      this.state = 'HALF_OPEN'
    }

    try {
      const result = await fn()
      this.onSuccess()
      return result
    } catch (error) {
      this.onFailure()
      throw error
    }
  }

  private onSuccess() { this.failures = 0; this.state = 'CLOSED' }
  private onFailure() {
    this.failures++
    this.lastFailure = new Date()
    if (this.failures >= this.threshold) this.state = 'OPEN'
  }
}
```

## Error Classes Tipadas

```typescript
// Base
export class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    public readonly details?: unknown
  ) {
    super(message)
    this.name = this.constructor.name
  }
}

// Específicos
export class ValidationError extends AppError {
  constructor(details: { field: string; message: string }[]) {
    super('Validation failed', 'VALIDATION_ERROR', 400, details)
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string) {
    super(`${resource} not found`, 'NOT_FOUND', 404)
  }
}

export class ExternalServiceError extends AppError {
  constructor(service: string, cause: Error) {
    super(`${service} failed`, 'EXTERNAL_SERVICE_ERROR', 502)
    this.cause = cause
  }
}
```

## Error Boundary em Express

```typescript
// Handler global — sempre o último middleware
app.use((error: Error, req: Request, res: Response, next: NextFunction) => {
  // Logar com contexto — requestId sempre presente para rastreabilidade
  logger.error({
    err: error,
    requestId: req.requestId,  // gerado pelo middleware de entrada (dev-api-design)
    path: req.path,
    method: req.method,
    userId: req.user?.id,
  }, 'Unhandled error')

  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      error: {
        code: error.code,
        message: error.message,
        details: error.details,
        requestId: req.requestId,  // sempre incluir na resposta
      }
    })
  }

  // Erro desconhecido — não vazar detalhes internos
  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
      requestId: req.requestId,
    }
  })
})
```

## Logging Estruturado

```typescript
import pino from 'pino'

const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  formatters: { level: (label) => ({ level: label }) },
})

// ✅ Correto — requestId sempre presente, contexto rico, sem dados sensíveis
logger.error({
  requestId: req.requestId,  // rastreabilidade end-to-end (ver dev-api-design)
  err: error,
  userId: user.id,
  action: 'payment_process',
  orderId: order.id,
}, 'Payment processing failed')

// ❌ Errado — sem requestId, sem contexto, pode vazar dados sensíveis
console.error('Error:', error)
```

## Graceful Degradation

Quando serviço dependente falha, degradar graciosamente em vez de falhar tudo:

```typescript
async function getUserWithPreferences(userId: string, requestId: string) {
  const user = await db.user.findUnique({ where: { id: userId } })  // crítico
  if (!user) throw new NotFoundError('User')

  // Feature não-crítica — falha silenciosa com fallback
  let preferences = DEFAULT_PREFERENCES
  try {
    preferences = await preferencesService.get(userId)
  } catch (error) {
    logger.warn({
      requestId,      // manter rastreabilidade mesmo no fallback
      userId,
      err: error.message,
    }, 'Failed to load preferences, using defaults')
  }

  return { ...user, preferences }
}
```

## Regras absolutas

- Nunca `catch (e) {}` vazio — sempre logar ou relançar com contexto
- Nunca expor stack traces em respostas de API
- Sempre timeout em chamadas a serviços externos
- Retry apenas em erros transitórios (5xx, network) — nunca em 4xx
- **`requestId` em todos os logs e respostas de erro** — rastreabilidade end-to-end
- Erros devem ter contexto suficiente para debug sem reprodução
