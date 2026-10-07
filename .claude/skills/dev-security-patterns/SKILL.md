---
name: dev-security-patterns
description: "Padrões de segurança para software complexo — autenticação, autorização, RLS, OWASP top 10, validação de input, secrets management e a varredura das armadilhas de código gerado por IA (segredo no cliente, RLS aberta, auth por user_metadata, prompt injection)."
version: "1.2"
updated: "2026-10-07"
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

-- Admin vê tudo — papel vem de app_metadata (só o servidor escreve)
CREATE POLICY "admin_all_orders" ON orders
  FOR ALL USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
```

**RLS é a última linha de defesa — aplicar em todas as tabelas com dados de usuário.**

- `auth.jwt() ->> 'role'` (claim de topo) é o papel do Postgres (`authenticated`/`anon`), não o papel da aplicação — política escrita assim nunca casa.
- **Nunca autorizar por `user_metadata`** (`raw_user_meta_data`): o próprio usuário edita esse campo pela API de auth e se dá qualquer papel. Papel de aplicação mora em `app_metadata` ou numa tabela de papéis.
- "RLS ativo" não prova nada: RLS ligado **sem policy** nega tudo; RLS com `USING (true)` libera tudo. Leia a policy.
- Bucket do Storage é tabela também (`storage.objects`) — `USING (true)` ali expõe todos os arquivos.

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
- Prefixo público (`NEXT_PUBLIC_`, `VITE_`, `PUBLIC_`, `EXPO_PUBLIC_`) **vai para o navegador por definição** — só chave publicável usa esse prefixo
- **Segredo que vazou já está queimado:** apagar do código não basta. A correção só termina com a chave **rotacionada no provedor**

## Varredura de código gerado por IA

Assistentes de código otimizam para a demo rodar. Os cinco erros abaixo são os que mais escapam em projetos Next.js + Supabase + LLM. Rode a varredura na raiz do projeto, leia cada ocorrência e classifique. **Busca é triagem, não veredicto** — toda ocorrência é conferida no arquivo antes de virar achado.

```bash
# Funciona em bash e zsh. Rode da raiz do projeto.

# 1. Segredo atrás de prefixo público
grep -rnE "(NEXT_PUBLIC|VITE|PUBLIC|EXPO_PUBLIC)_[A-Z0-9_]*(SECRET|SERVICE_ROLE|PRIVATE|TOKEN|PASSWORD|API_KEY)" \
  --include='*.[jt]s' --include='*.[jt]sx' --include='*.mjs' --include='*.astro' --include='*.vue' --include='*.svelte' --include='.env*' \
  --exclude-dir={node_modules,.next,.git,dist,build} .

# 2. Chave literal no código (OpenAI/Anthropic, Stripe live, JWT, AWS, chave privada)
grep -rnE "sk-(proj-|ant-)?[A-Za-z0-9_-]{20,}|sk_live_[A-Za-z0-9]{10,}|eyJhbGciOi[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY" \
  --exclude-dir={node_modules,.next,.git,dist,build} .

# 3. service_role fora do servidor
grep -rnE "service_role|SERVICE_ROLE" \
  --include='*.[jt]s' --include='*.[jt]sx' --include='*.mjs' --include='*.astro' --include='*.vue' --include='*.svelte' \
  --exclude-dir={node_modules,.next,.git,dist,build} .

# 4. RLS aberta e autorização por user_metadata
grep -rniE "using[[:space:]]*\([[:space:]]*true[[:space:]]*\)|with check[[:space:]]*\([[:space:]]*true[[:space:]]*\)|user_metadata|raw_user_meta_data" \
  --include='*.sql' --include='*.[jt]s' --include='*.[jt]sx' \
  --exclude-dir={node_modules,.next,.git,dist,build} .

# 4. Tabelas criadas sem "enable row level security" (a saída é a lista de suspeitas)
comm -23 \
  <(grep -rhoiE "create table( if not exists)? [a-z_.\"]+" --include='*.sql' --exclude-dir=node_modules --exclude-dir=.git . | tr A-Z a-z | awk '{print $NF}' | sort -u) \
  <(grep -rhoiE "alter table( only)? [a-z_.\"]+ enable row level security" --include='*.sql' --exclude-dir=node_modules --exclude-dir=.git . | tr A-Z a-z | awk '{print $(NF-4)}' | sort -u)

# 5. Prompt de sistema montado com dado da requisição
grep -rnE "role:[[:space:]]*[\"']system[\"']|system:[[:space:]]*\`" \
  --include='*.[jt]s' --include='*.[jt]sx' --include='*.mjs' \
  --exclude-dir={node_modules,.next,.git,dist,build} .
```

Sem migrations SQL no repositório (schema só no painel do Supabase)? A busca 4 não enxerga nada — rode no SQL Editor: `select tablename, rowsecurity from pg_tables where schemaname = 'public';` e `select * from pg_policies where schemaname in ('public','storage');`. Sem esse acesso, o item vira **NÃO VERIFICÁVEL**, nunca "ok".

| # | Achado | Quando é achado | Severidade |
|---|---|---|---|
| 1 | Segredo com prefixo público | Valor não publicável (chave de API privada, service_role, token) | **CRITICAL** |
| 2 | Chave literal no código | Qualquer chave privada no repositório. JWT literal: decodifique o payload — `"role":"service_role"` é CRITICAL; `"role":"anon"` não é achado | **CRITICAL** |
| 3 | `service_role` alcançável pelo cliente | Arquivo com `"use client"`, componente, hook ou módulo importado por eles | **CRITICAL** |
| 4a | Tabela com dado de usuário sem RLS, ou com `USING (true)` / `WITH CHECK (true)` | Dado não é público por desenho. Sem RLS, ou `UPDATE`/`DELETE`/`ALL` aberto: **CRITICAL**. `SELECT` aberto (qualquer um lê): **HIGH**. `INSERT` aberto fora de formulário público: **HIGH** | ver coluna ao lado |
| 4b | Autorização por `user_metadata` | Policy, middleware ou checagem de papel lê `user_metadata` | **HIGH** |
| 4c | Bucket do Storage aberto | Policy `USING (true)` em `storage.objects` de bucket com arquivo privado | **HIGH** |
| 5a | Entrada da requisição no prompt de sistema **e** chamada com tools | `req.body`/query/form chega ao `system` numa chamada com `tools` | **HIGH** |
| 5b | Entrada da requisição no prompt de sistema, sem tools | Idem, sem tools — heurístico, conferir à mão | **MEDIUM** |

**Não é achado (não acusar):** anon key do Supabase e `NEXT_PUBLIC_SUPABASE_ANON_KEY` (a RLS é o portão); chave publicável do Stripe (`pk_`); chave de projeto de analytics (PostHog, GA); `USING (true)` só para `SELECT` em tabela pública por desenho (catálogo, posts publicados) e documentada como tal; `INSERT ... WITH CHECK (true)` em tabela de **formulário público** (lead, contato, newsletter) **sem** policy de `SELECT`/`UPDATE`/`DELETE` para `anon` — é o desenho normal de formulário (no máximo uma recomendação: limitar formato e tamanho no `WITH CHECK` ou inserir por rota de servidor com rate limit); entrada do usuário numa mensagem `role: "user"` separada, sem tools. Acusar o padrão seguro ensina o time a ignorar o QA.

**Como reportar cada achado:** linha (`arquivo:linha`) → o risco em uma frase ("vai para o navegador de todo visitante") → a correção em um commit. Para segredo: **tipo e local, nunca o valor** (mostre no máximo os 4 primeiros caracteres), e a correção sempre inclui **rotacionar no provedor**.

**Correção só vale com nova varredura.** Depois do fix, rode a varredura de novo e compare: resolvido, ainda presente, novo. Segredo só sai da lista com a rotação confirmada pelo usuário — remover do código não basta.

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
