---
name: dev-api-design
description: Design de APIs para software complexo — REST, tRPC, contratos, versionamento e error responses padronizadas.
version: "1.1"
updated: "2026-04-21"
---

# API Design — Software Complexo

## REST — Nomenclatura

```
GET    /users              → listar
GET    /users/:id          → buscar por ID
POST   /users              → criar
PUT    /users/:id          → substituir completo
PATCH  /users/:id          → atualizar parcial
DELETE /users/:id          → remover

# Ações não-CRUD (POST + verbo explícito)
POST   /users/:id/deactivate
POST   /auth/refresh
POST   /payments/:id/refund
```

Regras: plural sempre (`/users`), nunca verbos em recursos, máx 2 níveis de aninhamento.

## Responses

### Sucesso
```json
{
  "data": { "id": "usr_123", "email": "user@example.com" },
  "meta": { "requestId": "req_abc" }
}
```

### Lista paginada
```json
{
  "data": [...],
  "pagination": { "page": 1, "perPage": 20, "total": 150, "hasNext": true }
}
```

### Erro — padrão obrigatório
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": [{ "field": "email", "message": "Must be a valid email" }],
    "requestId": "req_abc"
  }
}
```

**`requestId` obrigatório em todas as respostas** — sucesso e erro. Gerado no middleware de entrada e propagado pelo sistema. Usar o mesmo `requestId` nos logs (ver `dev-security-patterns`) para rastrear requests end-to-end.

**Nunca expor:** stack traces, mensagens de banco, lógica interna.

## HTTP Status + Códigos de Erro

| HTTP | Code | Quando |
|---|---|---|
| 200 | — | GET, PATCH, PUT ok |
| 201 | — | POST criou recurso |
| 204 | — | DELETE ou ação sem body |
| 400 | `VALIDATION_ERROR` | Input inválido |
| 401 | `UNAUTHORIZED` | Não autenticado |
| 403 | `FORBIDDEN` | Sem permissão |
| 404 | `NOT_FOUND` | Não existe |
| 409 | `CONFLICT` | Estado conflitante |
| 429 | `RATE_LIMITED` | Rate limit |
| 500 | `INTERNAL_ERROR` | Erro interno |

## requestId — Geração e Propagação

```typescript
// Middleware de entrada — gerar requestId único
app.use((req, res, next) => {
  req.requestId = req.headers['x-request-id'] as string
    ?? `req_${crypto.randomUUID().replace(/-/g, '').slice(0, 12)}`
  res.setHeader('x-request-id', req.requestId)
  next()
})

// Passar requestId para logs e serviços downstream
logger.info('Request received', { requestId: req.requestId, path: req.path })
```

## tRPC (TypeScript full-stack)

```typescript
export const userRouter = router({
  getById: publicProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ input, ctx }) => {
      return ctx.db.user.findUnique({ where: { id: input.id } })
    }),
  create: protectedProcedure
    .input(createUserSchema)
    .mutation(async ({ input, ctx }) => {
      return ctx.db.user.create({ data: input })
    }),
})
```

Usar tRPC: Next.js + TypeScript, type-safety end-to-end.
Usar REST: API pública para terceiros ou linguagens mistas.

## Versionamento

URL path: `/api/v1/users` → `/api/v2/users`
- Bump de versão apenas em breaking changes
- Manter versão anterior 3+ meses
- Header `Sunset: {date}` na versão sendo descontinuada

## Contrato de API

Documentar em `docs/api/{resource}.md` ao criar/modificar endpoint:

```markdown
## POST /users
**Auth:** Bearer token | **Rate limit:** 10/min

### Request
\`{ "email": "string", "name": "string" }\`

### Response 201
\`{ "data": { "id": "string" }, "meta": { "requestId": "string" } }\`

### Erros: 409 CONFLICT (email duplicado), 400 VALIDATION_ERROR
```

## Regras absolutas

- IDs opacos: `usr_abc123`, nunca `123`
- PUT e DELETE sempre idempotentes
- Rate limiting em todos os endpoints públicos
- Timeout explícito em todas as chamadas a externos
- `requestId` em todas as respostas — sucesso e erro, sem exceção
- Breaking change = bump de versão, sem exceção
