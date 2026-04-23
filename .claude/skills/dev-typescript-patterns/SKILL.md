---
name: dev-typescript-patterns
description: Padrões idiomáticos de TypeScript para software complexo — types vs interfaces, generics, discriminated unions, utility types, patterns de domínio.
version: "1.1"
updated: "2026-04-21"
---

# TypeScript Patterns — Software Complexo

## Types vs Interfaces

```typescript
// Interface: para objetos públicos e extensíveis (podem ser merged via declaration merging)
interface User {
  id: string
  email: string
  name: string
}

// Type: para unions, intersections, mapped types, e aliases
type UserRole = 'admin' | 'member' | 'viewer'
type UserWithRole = User & { role: UserRole }
type PartialUser = Partial<User>
```

**Regra geral:** Interface para contratos de API e objetos de domínio. Type para unions, aliases e tipos compostos.

## Discriminated Unions

```typescript
// ✅ Modelar resultados com discriminated union
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E }

// Uso
function parseUser(raw: unknown): Result<User> {
  const parsed = userSchema.safeParse(raw)
  if (!parsed.success) return { success: false, error: parsed.error }
  return { success: true, data: parsed.data }
}

// Type narrowing automático
const result = parseUser(rawData)
if (result.success) {
  console.log(result.data.email)   // TypeScript sabe que data existe
} else {
  console.log(result.error.message) // TypeScript sabe que error existe
}
```

## Branded Types (IDs seguros)

```typescript
// Evitar confundir UserId com OrderId
type UserId = string & { readonly _brand: 'UserId' }
type OrderId = string & { readonly _brand: 'OrderId' }

function createUserId(id: string): UserId {
  return id as UserId
}

// Agora TypeScript recusa UserId onde OrderId é esperado
function getOrder(id: OrderId) { ... }
getOrder(userId)  // ✅ Erro de compilação — catching bug em compile time
```

## Generics com Constraints

```typescript
// Generic para Repository pattern
interface Repository<T extends { id: string }> {
  findById(id: string): Promise<T | null>
  findAll(filters?: Partial<T>): Promise<T[]>
  create(data: Omit<T, 'id' | 'createdAt'>): Promise<T>
  update(id: string, data: Partial<Omit<T, 'id'>>): Promise<T>
  delete(id: string): Promise<void>
}

// Generic utilitário
type PaginatedResult<T> = {
  data: T[]
  pagination: { page: number; perPage: number; total: number; hasNext: boolean }
}
```

## Utility Types — Os mais úteis

```typescript
type User = { id: string; email: string; name: string; password: string }

// Remover campos sensíveis
type PublicUser = Omit<User, 'password'>

// Todos campos opcionais (para PATCH)
type UpdateUser = Partial<Omit<User, 'id'>>

// Apenas campos específicos (para query params)
type UserFilter = Pick<User, 'email' | 'name'>

// Tornar todos readonly (para props de UI)
type ReadonlyUser = Readonly<User>

// Record tipado
type UsersByRole = Record<UserRole, User[]>
```

## satisfies — Validação sem perda de tipo

```typescript
const config = {
  db: { url: process.env.DATABASE_URL!, pool: 5 },
  auth: { secret: process.env.JWT_SECRET!, expiresIn: '15m' },
} satisfies Record<string, Record<string, string | number>>

// config.db.pool ainda é inferido como number, não string | number
config.db.pool.toFixed(2)  // ✅ TypeScript sabe que é number
```

## Zod — Validação em runtime com tipos

```typescript
import { z } from 'zod'

const createUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100).trim(),
  role: z.enum(['admin', 'member', 'viewer']).default('member'),
})

// Inferir tipo a partir do schema — única fonte da verdade
type CreateUserInput = z.infer<typeof createUserSchema>

// Usar em handler
const handler = async (req: Request) => {
  const input = createUserSchema.parse(req.body)  // throws se inválido
  // input é do tipo CreateUserInput — TypeScript sabe
}
```

## Async Patterns

```typescript
// ✅ Promise.all para paralelo — todos devem ter sucesso
const [user, orders, permissions] = await Promise.all([
  db.user.findUnique({ where: { id } }),
  db.order.findMany({ where: { userId: id } }),
  permissionsService.getForUser(id),
])

// ✅ Promise.allSettled — falha parcial aceitável, tipagem correta
const results = await Promise.allSettled([
  criticalService.fetch(),
  optionalService.fetch(),
])

// Tipar resultado de allSettled corretamente
results.forEach((result) => {
  if (result.status === 'fulfilled') {
    const value = result.value  // TypeScript infere o tipo correto
  }
  if (result.status === 'rejected') {
    logger.warn({ err: result.reason }, 'Optional service failed')
  }
})
```

## Type Guards

```typescript
// Narrown de unknown para tipo conhecido
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value &&
    typeof (value as User).email === 'string'
  )
}

// Uso
if (isUser(data)) {
  console.log(data.email)  // TypeScript sabe que é User aqui
}
```

## Tipando Mocks em Testes

```typescript
import { jest } from '@jest/globals'

// ✅ Mock tipado — TypeScript valida que mock tem mesma assinatura
const mockUserService = {
  findById: jest.fn<() => Promise<User | null>>(),
  create: jest.fn<(data: CreateUserInput) => Promise<User>>(),
}

// ✅ Mock de módulo com tipo preservado
jest.mock('../services/stripe')
const mockStripe = jest.mocked(stripe)
mockStripe.createPayment.mockResolvedValue({ id: 'pay_123', status: 'succeeded' })
// TypeScript valida que o mock retorna o tipo correto
```

## Regras de qualidade TypeScript

- `strict: true` sempre no tsconfig — sem exceções
- Nunca `any` — usar `unknown` e narrown, ou tipos específicos
- Tipos inferidos quando óbvios, explícitos quando necessário para legibilidade
- Schema Zod como fonte de verdade dos tipos de input/output de API
- Branded types para IDs de entidades diferentes
- `as` (type assertion) apenas quando você tem certeza absoluta e documenta por quê
- Mocks em testes sempre tipados com `jest.fn<ReturnType>()` ou `jest.mocked()`
