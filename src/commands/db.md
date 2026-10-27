---
description: Analyze a slow PostgreSQL query
agent: db-optimizer
---

Use the `postgres-safety` skill.

Query or symptom: $ARGUMENTS

If a database is reachable, run `EXPLAIN (ANALYZE, BUFFERS)` via `psql` (read-only).
Otherwise inspect the schema/migrations and reason from indexes.

Report: bottleneck, evidence, proposed index or rewrite, expected improvement,
and write/storage cost. No DDL or writes without explicit approval.
