---
name: data-supabase-patterns
description: Melhores práticas de Postgres e Supabase — indexação, RLS performática, connection pooling, schema design, locking e diagnóstico com EXPLAIN. Use ao escrever queries SQL, criar migrations, desenhar schema, implementar políticas RLS, otimizar queries lentas ou investigar timeouts e problemas de conexão em projetos Supabase/Postgres.
version: "1.0"
updated: "2026-09-04"
---

# Supabase / Postgres Patterns

Skill de banco de dados destilada do guia oficial supabase-postgres-best-practices (8 categorias priorizadas por impacto). Usada por **dev-data-engineer, sites-data** (schema, migrations, RLS) e **dev-bi** (queries analíticas), com **dev-qa/sites-qa** em review de migrations. Segue o protocolo de segurança da squad: snapshot → dry-run → apply → smoke-test.

## 1. Query Performance (CRITICAL)

**1.1 — Index every column used in WHERE, JOIN, and ORDER BY of hot queries.** Missing indexes are the #1 cause of slow queries.

```sql
-- ❌ seq scan on 1M rows
SELECT * FROM orders WHERE customer_id = $1;
-- ✅
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
```

**1.2 — Composite indexes: equality columns first, then range/sort.**

```sql
-- query: WHERE status = 'paid' AND created_at > now() - interval '30 days'
CREATE INDEX idx_orders_status_created ON orders (status, created_at);
```

**1.3 — Partial indexes for skewed data** (e.g., only 2% of rows are `pending`):

```sql
CREATE INDEX idx_orders_pending ON orders (created_at) WHERE status = 'pending';
```

**1.4 — Never wrap an indexed column in a function** — it disables the index. Index the expression instead:

```sql
-- ❌ WHERE lower(email) = $1  (index on email unused)
CREATE INDEX idx_users_email_lower ON users (lower(email)); -- ✅
```

**1.5 — Covering indexes (`INCLUDE`)** for index-only scans on hot read paths.

**1.6 — Keyset pagination, not OFFSET**, for deep pages:

```sql
-- ❌ OFFSET 100000 scans and discards 100k rows
-- ✅ WHERE (created_at, id) < ($last_created_at, $last_id) ORDER BY created_at DESC, id DESC LIMIT 20
```

**1.7 — SELECT only needed columns** — `SELECT *` breaks index-only scans and inflates payloads (especially over PostgREST).

**1.8 — Always `EXPLAIN (ANALYZE, BUFFERS)` before and after optimizing.** Look for `Seq Scan` on large tables, misestimated rows, and high buffer reads.

## 2. Connection Management (CRITICAL)

**2.1 — Serverless/edge functions MUST use the transaction-mode pooler** (Supavisor, port 6543), never direct connections — each lambda invocation would otherwise hold a Postgres backend.

**2.2 — Transaction mode does not support session state:** no prepared statements at protocol level (disable in the client, e.g. `pgbouncer=true` / `prepare: false`), no `SET` without `LOCAL`, no advisory locks held across transactions.

**2.3 — Long-lived servers:** direct connection (5432) with a small app-side pool. Rule of thumb: pool size ≈ cores × 2–4, not hundreds.

**2.4 — Set statement timeouts** (`statement_timeout`, `idle_in_transaction_session_timeout`) so runaway queries and abandoned transactions don't exhaust the pool.

## 3. Security & RLS (CRITICAL)

**3.1 — Enable RLS on every table in exposed schemas** (`public` is exposed via PostgREST):

```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
```

**3.2 — Wrap auth functions in a subselect so they're evaluated once per query, not per row** — the single biggest RLS performance fix:

```sql
-- ❌ auth.uid() re-evaluated for every row
CREATE POLICY p ON documents USING (auth.uid() = user_id);
-- ✅ initPlan: evaluated once
CREATE POLICY p ON documents USING ((SELECT auth.uid()) = user_id);
```

**3.3 — Index the columns referenced by policies** (`user_id`, `org_id`, `team_id`). RLS turns every query into a filtered query.

**3.4 — Specify the role in policies** (`TO authenticated`) so anon traffic short-circuits without evaluating the expression.

**3.5 — Avoid joins inside policies;** prefer a `SECURITY DEFINER` helper function (e.g. `private.user_org_ids()`) with a stable result, and keep it in a non-exposed schema.

**3.6 — Functions: pin `search_path`** (`SET search_path = ''`, use schema-qualified names) and grant `EXECUTE` deliberately. Never put `SECURITY DEFINER` functions in exposed schemas without need.

**3.7 — Never string-interpolate SQL** — parameterized queries only, including inside `plpgsql` (`format()` + `%I`/`%L` when dynamic SQL is unavoidable).

## 4. Schema Design (HIGH)

- **`bigint GENERATED ALWAYS AS IDENTITY`** (ou UUIDv7) para PKs; evite UUIDv4 como PK clusterizada de tabelas gigantes (index bloat / cache locality).
- **`text` em vez de `varchar(n)`** + `CHECK` constraint quando precisar de limite — mesmo desempenho, migração mais fácil.
- **`timestamptz` sempre**, nunca `timestamp`.
- **FKs sempre indexadas** — Postgres não cria índice em FK automaticamente; deletes/updates no pai fazem seq scan no filho sem ele.
- **`NOT NULL` + defaults** em tudo que a regra de negócio permitir; constraints são documentação executável.
- **Enum de domínio:** prefira tabela de lookup ou `CHECK` a `CREATE TYPE enum` quando os valores mudam com frequência.

## 5. Migrations seguras (HIGH)

**5.1 — Zero-downtime playbook:**

```sql
-- Adicionar coluna NOT NULL em tabela grande: 3 passos
ALTER TABLE t ADD COLUMN c text;                      -- 1. nullable, instantâneo
UPDATE t SET c = '...' WHERE c IS NULL;               -- 2. backfill em batches
ALTER TABLE t ALTER COLUMN c SET NOT NULL;            -- 3. depois de validado
```

**5.2 — `CREATE INDEX CONCURRENTLY`** em tabelas em produção (fora de transaction block).

**5.3 — Constraints em duas fases:** `ADD CONSTRAINT ... NOT VALID` seguido de `VALIDATE CONSTRAINT` — valida sem lock longo.

**5.4 — Nunca `DROP COLUMN`/`RENAME` no mesmo deploy que o código** — expand/contract: adicionar novo → migrar código → remover velho.

## 6. Concurrency & Locking (MEDIUM-HIGH)

- **Transações curtas.** Nunca segure uma transação aberta durante chamadas de rede/API externa.
- **`SELECT ... FOR UPDATE SKIP LOCKED`** para filas e workers concorrentes.
- **Ordene updates multi-linha por chave estável** para evitar deadlocks entre transações concorrentes.
- **`lock_timeout` curto em DDL** (`SET LOCAL lock_timeout = '2s'`) — melhor falhar e repetir do que enfileirar atrás de um lock e travar o sistema.

## 7. Diagnóstico (quando algo está lento)

1. `pg_stat_statements` — top queries por `total_exec_time` e `mean_exec_time`.
2. `EXPLAIN (ANALYZE, BUFFERS)` na query suspeita.
3. `pg_stat_activity` — conexões `idle in transaction`, queries longas, waits.
4. `pg_stat_user_indexes` — índices nunca usados (candidatos a drop: cada índice custa em escrita).
5. Em Supabase: Query Performance report + Index Advisor no dashboard; `supabase inspect db` na CLI.

## Checklist de review (migrations/queries)

- [ ] Toda tabela nova em schema exposto tem RLS habilitada + policies com `(SELECT auth.uid())`
- [ ] Colunas de policy e FKs indexadas
- [ ] Índices criados com `CONCURRENTLY` em produção
- [ ] Sem `SELECT *` em código de aplicação
- [ ] Paginação keyset em listagens profundas
- [ ] `timestamptz`, `text`, identity PKs
- [ ] Plano testado com `EXPLAIN (ANALYZE, BUFFERS)` antes do merge

---

Adaptado de supabase/agent-skills → supabase-postgres-best-practices (skills.sh) — 2026-08-26. O SKILL.md fonte é um índice de ~50 regras em arquivos de referência; as regras acima foram destiladas das categorias oficiais (query/conn/security/schema/lock/data/monitor) complementadas com conhecimento próprio dos mesmos tópicos.

## Skill relacionada
- Otimização SQL genérica (EXPLAIN profundo, indexing, HA, multi-plataforma) → [../data-sql-optimization/SKILL.md](../data-sql-optimization/SKILL.md).
