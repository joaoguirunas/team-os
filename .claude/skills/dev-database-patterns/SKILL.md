---
name: dev-database-patterns
description: Padrões de banco de dados para software complexo — migrations seguras, indexing strategy, N+1 detection, soft deletes, connection pooling.
version: "1.1"
updated: "2026-04-21"
---

# Database Patterns — Software Complexo

## Migration Safety Protocol

**Nunca aplicar migration sem este protocolo:**

```bash
# 1. Snapshot — estado antes
pg_dump $DATABASE_URL --schema-only > backups/schema-$(date +%Y%m%d-%H%M%S).sql

# 2. Dry-run — verificar sem commitar (BEGIN + ROLLBACK)
psql $DATABASE_URL <<'EOF'
BEGIN;
\i migrations/001_add_users_table.sql
-- Verificar resultado sem commitar
SELECT COUNT(*) FROM users;
\d users
ROLLBACK;  -- Desfaz tudo — apenas verificação
EOF

# 3. Apply — executar de verdade
psql $DATABASE_URL -f migrations/001_add_users_table.sql

# 4. Smoke test — verificar integridade após apply real
psql $DATABASE_URL -c "SELECT COUNT(*) FROM users;"
psql $DATABASE_URL -c "\d users"

# 5. Rollback disponível (executar se smoke test falhar)
psql $DATABASE_URL -f migrations/001_add_users_table.rollback.sql
```

> **Nota:** PostgreSQL não tem flag `--dry-run` nativo. O dry-run correto é sempre via `BEGIN/ROLLBACK` — executa a migration em transação e faz rollback sem commitar.

## Migration Structure

Cada migration tem arquivo de rollback correspondente:

```
migrations/
├── 001_create_users.sql
├── 001_create_users.rollback.sql
├── 002_add_user_roles.sql
└── 002_add_user_roles.rollback.sql
```

### Template de migration

```sql
-- migrations/001_create_users.sql
-- Migration: create users table
-- Author: dev-data-engineer
-- Date: 2026-04-21

BEGIN;

CREATE TABLE users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       VARCHAR(255) NOT NULL UNIQUE,
  name        VARCHAR(100) NOT NULL,
  role        VARCHAR(50) NOT NULL DEFAULT 'member',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at  TIMESTAMPTZ  -- soft delete
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role) WHERE deleted_at IS NULL;

COMMENT ON TABLE users IS 'Core user accounts';

COMMIT;
```

```sql
-- migrations/001_create_users.rollback.sql
BEGIN;
DROP TABLE IF EXISTS users;
COMMIT;
```

## Indexing Strategy

```sql
-- Index para lookup mais comum
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Index composto para queries frequentes
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Index parcial — apenas registros ativos (muito mais eficiente)
CREATE INDEX idx_users_active ON users(email) WHERE deleted_at IS NULL;

-- Index para full-text search
CREATE INDEX idx_products_search ON products
  USING GIN(to_tsvector('english', name || ' ' || description));
```

**Regras de indexing:**
- Todo campo usado em `WHERE`, `JOIN ON`, `ORDER BY` frequentemente deve ter index
- Índices compostos: ordem importa (campo mais seletivo primeiro)
- Índices parciais para tabelas com flag de soft delete
- Executar `EXPLAIN ANALYZE` antes de criar index em tabela grande

## N+1 Detection e Prevenção

```typescript
// ❌ N+1 — um query por usuário
const users = await db.user.findMany()
for (const user of users) {
  const orders = await db.order.findMany({ where: { userId: user.id } })
  // N queries para N usuários = N+1 total
}

// ✅ Sem N+1 — include para eager loading
const users = await db.user.findMany({
  include: { orders: true }
})

// ✅ Para casos complexos — query única com JOIN
const usersWithOrders = await db.$queryRaw`
  SELECT u.*, json_agg(o.*) as orders
  FROM users u
  LEFT JOIN orders o ON o.user_id = u.id
  GROUP BY u.id
`
```

**Detectar N+1:** Logar queries em desenvolvimento com `prisma.$on('query', ...)` ou usar `pg_stat_statements`.

## Soft Deletes

```sql
-- Coluna de soft delete
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;

-- Deletar (soft)
UPDATE users SET deleted_at = NOW() WHERE id = $1;

-- Queries devem filtrar deletados
SELECT * FROM users WHERE deleted_at IS NULL;

-- View para simplificar
CREATE VIEW active_users AS
  SELECT * FROM users WHERE deleted_at IS NULL;
```

```typescript
// Prisma — middleware para soft delete automático
prisma.$use(async (params, next) => {
  if (params.model === 'User') {
    if (params.action === 'delete') {
      params.action = 'update'
      params.args.data = { deletedAt: new Date() }
    }
    if (['findMany', 'findFirst', 'count'].includes(params.action)) {
      params.args.where = { ...params.args.where, deletedAt: null }
    }
  }
  return next(params)
})
```

## Connection Pooling

```typescript
// Supabase / Postgres — configurar pool adequadamente
const db = new PrismaClient({
  datasources: {
    db: { url: process.env.DATABASE_URL }
  },
  log: process.env.NODE_ENV === 'development' ? ['query'] : ['error'],
})
```

**Para Supabase:**
- Transaction pooler (porta 6543) → serverless functions (sem estado de sessão)
- Session pooler (porta 5432) → aplicações persistentes (com estado de sessão)
- `pool_max=10` para produção, `pool_min=2` para manter conexões aquecidas

## RLS com Supabase

```sql
-- Habilitar RLS em todas as tabelas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Política básica de isolamento
CREATE POLICY "users_own_data" ON users
  FOR ALL USING (auth.uid() = id);

-- Política com role
CREATE POLICY "admin_full_access" ON users
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Política de insert com check
CREATE POLICY "users_insert_own" ON orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

**Testar RLS:**
```sql
-- Simular como usuário específico
SET LOCAL role = authenticated;
SET LOCAL request.jwt.claims = '{"sub": "user-uuid-here"}';
SELECT * FROM orders;  -- Deve retornar apenas os pedidos do usuário
```

## Query Performance

```sql
-- Analisar query lenta
EXPLAIN ANALYZE
SELECT u.*, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.deleted_at IS NULL
GROUP BY u.id
ORDER BY order_count DESC
LIMIT 20;
```

Interpretar:
- `Seq Scan` em tabela grande → precisa de index
- `Hash Join` → geralmente ok
- `Nested Loop` com muitas iterações → possível N+1

## Regras absolutas

- Nunca `DROP` sem backup confirmado
- Nunca migration sem rollback correspondente
- **Dry-run via `BEGIN/ROLLBACK`** — PostgreSQL não tem `--dry-run` nativo
- Nunca `SELECT *` em produção — selecionar colunas necessárias
- Nunca joins sem index nas colunas de join
- Sempre RLS em tabelas com dados de usuário
- Migrations são imutáveis após aplicação — criar nova migration para corrigir
