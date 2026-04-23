---
name: dev-security-patterns
description: Padrões de segurança para software complexo — autenticação, autorização, RLS, OWASP top 10, validação de input, secrets management.
version: "1.1"
updated: "2026-04-21"
---

# Security Patterns — Software Complexo

## JWT — Autenticação

```typescript
// Geração
const accessToken = jwt.sign(
  { userId: user.id, role: user.role },
  process.env.JWT_SECRET!,
  { expiresIn: '15m' }   // curto
)
const refreshToken = jwt.sign(
  { userId: user.id },
  process.env.JWT_REFRESH_SECRET!,
  { expiresIn: '7d' }
)

// Validação em middleware
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1]
  if (!token) return res.status(401).json({ error: { code: 'UNAUTHORIZED', requestId: req.requestId } })
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET!)
    next()
  } catch {
    return res.status(401).json({ error: { code: 'UNAUTHORIZED', requestId: req.requestId } })
  }
}
```

**Regras:** Access token 15min. Refresh token 7 dias com rotação. Nunca localStorage — usar httpOnly cookie. Secret mínimo 256 bits.

## Autorização — RBAC

```typescript
const requireRole = (...roles: string[]) => (req, res, next) => {
  if (!roles.includes(req.user.role)) {
    return res.status(403).json({ error: { code: 'FORBIDDEN', requestId: req.requestId } })
  }
  next()
}

// Uso
router.delete('/users/:id', verifyToken, requireRole('admin'), deleteUser)
```

## Row Level Security (RLS — Supabase/Postgres)

```sql
-- Habilitar RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Usuário vê apenas seus dados
CREATE POLICY "user_own_orders" ON orders
  FOR ALL USING (auth.uid() = user_id);

-- Admin vê tudo
CREATE POLICY "admin_all_orders" ON orders
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

**RLS é a última linha de defesa — aplicar em todas as tabelas com dados de usuário.**

## Validação de Input

```typescript
const createUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100).trim(),
})

// Middleware
const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.body)
  if (!result.success) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        details: result.error.errors,
        requestId: req.requestId,  // sempre incluir requestId
      }
    })
  }
  req.body = result.data  // dados sanitizados
  next()
}
```

**Nunca confiar em input do cliente. Validar e sanitizar tudo que vem do exterior.**

## OWASP Top 10 — Checklist

| Risco | Mitigação |
|---|---|
| SQL Injection | ORM/query builder, nunca concatenar queries |
| Broken Auth | JWT curto, refresh rotation, httpOnly cookies |
| Sensitive Data Exposure | HTTPS, nunca logar dados sensíveis |
| Broken Access Control | RBAC + RLS obrigatórios |
| Security Misconfiguration | Env vars para secrets, nada hardcoded |
| XSS | Sanitizar output, Content-Security-Policy |
| Vulnerable Dependencies | `npm audit` em CI |
| Insufficient Logging | Logar autenticações e acessos negados com requestId |

## Secrets Management

```bash
# ✅ Variáveis de ambiente
DATABASE_URL=postgresql://...
JWT_SECRET=super-secret-256-bits

# ❌ Nunca hardcoded
const JWT_SECRET = "minha-chave"
```

Regras:
- `.env` no `.gitignore` — nunca commitar
- `.env.example` com chaves sem valores — commitar
- Em produção: secret manager (AWS Secrets Manager, Vercel env vars)

## Rate Limiting

```typescript
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,   // 10 tentativas em 15 min
  message: { error: { code: 'RATE_LIMITED', requestId: 'see-x-request-id-header' } },
})

app.use('/auth', authLimiter)
app.use('/api', rateLimit({ windowMs: 60000, max: 100 }))
```

## Password Hashing

```typescript
const hash = await bcrypt.hash(password, 12)    // custo 12 mínimo
const valid = await bcrypt.compare(input, hash)
```

**Nunca MD5 ou SHA1 para passwords. Nunca plain text.**

## Logging Estruturado Seguro

O `requestId` gerado no middleware de entrada (ver `dev-api-design`) deve estar presente em **todos os logs** — é o fio que conecta request → serviços → banco → resposta no debugging.

```typescript
// ✅ Correto — contexto rico com requestId, dado sensível ausente
logger.info({
  requestId: req.requestId,  // sempre — rastreabilidade end-to-end
  userId: user.id,
  action: 'login_attempt',
  ip: req.ip,
  success: true,
}, 'User authenticated')

logger.error({
  requestId: req.requestId,
  userId: user.id,
  action: 'payment_process',
  orderId: order.id,
  err: error,
}, 'Payment processing failed')

// ❌ Errado — sem requestId, sem contexto, pode vazar dados
console.error('Error:', error)
logger.info('Login', { password: body.password, token: jwt })
```

**Nunca logar:** passwords, tokens JWT, dados de cartão, CPF/SSN, qualquer PII desnecessário.
**Sempre logar:** requestId, userId (não email), action, resultado (success/fail), IP em auth events.
