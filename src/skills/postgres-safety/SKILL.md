---
name: postgres-safety
description: Work with PostgreSQL safely and efficiently. Use for schema inspection, EXPLAIN plans, index design, migrations, and any query touching production data.
---

# PostgreSQL safety

## Read-only by default

- Allowed without approval: `SELECT`, `EXPLAIN`, `EXPLAIN (ANALYZE, BUFFERS)`
  on staging, catalog queries, `pg_stat_*` views.
- Requires explicit approval: `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, DDL,
  `VACUUM FULL`, `REINDEX`, role/permission changes.
- Production: never run `EXPLAIN (ANALYZE)` on writes; use `EXPLAIN` only.

## Investigation order

1. Get table sizes and row estimates (`pg_class`, `pg_stat_user_tables`).
2. Run `EXPLAIN (ANALYZE, BUFFERS)` and compare estimated vs actual rows.
3. Find the true cost: seq scan, bad estimate, missing/unused index, sort/hash
   spill, lock contention, ORM N+1.
4. Fix the smallest thing first: query shape → index → schema/statistics.

## Index rules

- Index for the exact filter + order; note column order.
- Check whether an existing index already covers it.
- Every index costs writes and storage; say so.
- Use `CONCURRENTLY` for production index creation and never inside a
  transaction.
- Consider partial indexes for status/soft-delete filters.

## Migrations

- Add columns as nullable or with a safe default; backfill separately.
- Avoid long locks: `lock_timeout`, `statement_timeout`, batched updates.
- Make migrations reversible or provide an explicit rollback plan.
- Test on a production-like dataset when the table is large.
