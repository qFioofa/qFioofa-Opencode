---
name: devops-runbook
description: Deploy and operate the stack safely. Use for Docker/Compose, Kamal, GitHub Actions, GitLab CI, environment/secrets, release checks, and rollback planning.
---

# DevOps runbook

## Environments

- `dev` — local Docker Compose; no production secrets.
- `staging` — production-like; deploy freely after CI passes.
- `prod` — requires explicit user approval, green CI, and a rollback plan.

Never copy production secrets into local files or logs.

## Pre-deploy checklist

1. Identify the artifact: image tag/commit, migrations, env var changes.
2. CI is green on the exact commit being deployed.
3. Migrations: are they backwards-compatible? Locking? Backfill separated?
4. Secrets exist in the target environment (names only, never values).
5. Health endpoint and smoke test are known.
6. Rollback command is written down before deploying.

## Docker / Compose

- Multi-stage build; pin base image versions; run as non-root.
- One service per concern; healthchecks for stateful services.
- Config via env, not baked into the image.
- `docker compose config` before `up`; use profiles for optional services.

## Kamal (Rails)

- `kamal deploy` only to staging without approval.
- Check `config/deploy.yml` for image, servers, env, and accessories.
- Rollback: previous image tag via `kamal rollback`.
- Destructive commands (`kamal setup`, `kamal server bootstrap`,
  `kamal accessory reboot`) require approval.

## GitHub Actions / GitLab CI

- Pin action/image versions; least-privilege `permissions`.
- Cache dependencies; fail fast on lint/typecheck before tests.
- Secrets only via CI secret store; never echo them.
- Protect production jobs with manual approval / protected environments.
- Separate build from deploy; deploy the exact artifact that was tested.

## Incident response

1. Stop the bleeding: rollback or disable the feature flag.
2. Confirm blast radius (which users/envs).
3. Capture logs/metrics before cleanup.
4. Write a short postmortem: cause, fix, prevention.
