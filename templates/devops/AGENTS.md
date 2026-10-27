# DevOps / infrastructure project rules

## Scope

Docker/Compose, Kamal, GitHub Actions, GitLab CI. No Kubernetes or Terraform
unless the project explicitly adds them.

## Commands

- Compose config: `docker compose config`
- Compose up: `docker compose up -d --build`
- Logs: `docker compose logs -f --tail=200 <service>`
- CI lint: `actionlint` (GitHub) or `gitlab-ci-lint` / project script
- Kamal: `kamal deploy`, `kamal rollback`, `kamal app logs`

## Safety

- Never run `docker compose down -v`, `docker system prune`, `kamal setup`,
  `terraform apply`, or `kubectl delete` without explicit confirmation.
- Production deploys require explicit approval, green CI, and a rollback plan.
- Secrets only through env/CI secret stores; never echo or commit them.
- Pin image and action versions; use least-privilege CI permissions.

## Skills

- `devops-runbook` (global) for the release checklist.
- `docker-compose-patterns`, `docker-build-strategies` for containers.
- `github-actions`, `github-actions-hardening`, `gitlab-ci-patterns` for CI.
