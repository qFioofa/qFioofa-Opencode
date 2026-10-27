---
description: Pre-deploy checklist and dry-run review
agent: architect
---

Use the `devops-runbook` skill.

Deployment target: $ARGUMENTS (default: staging)

Do not deploy. Produce a checklist covering:

1. What exactly will change (image, migrations, env vars, config).
2. Required secrets/env and whether they exist in the target.
3. Migration safety: locking, rollback, backfill.
4. Health checks, smoke tests, and rollback command.
5. CI status and required approvals.

Flag anything that would make the deploy unsafe.
