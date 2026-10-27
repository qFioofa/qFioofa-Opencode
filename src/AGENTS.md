# Global opencode rules

## Workflow

- For non-trivial work use the `plan` agent or `/think` first; do not start editing
  until the approach and tradeoffs are clear.
- Read the project's `AGENTS.md` and follow its build/lint/test commands before
  inventing new ones.
- Prefer small, verifiable steps. Run the relevant tests after changes.
- Never commit, push, deploy, or run migrations on production unless the user
  explicitly asks for that exact action.

## Safety

- Never print or commit secrets (`.env`, keys, tokens, credentials).
- Destructive commands (`rm -rf`, `git push`, `kamal setup`, `terraform apply`,
  `kubectl delete`) require explicit user confirmation.
- Database work is read-only by default: `SELECT`/`EXPLAIN` only. Any DDL or
  `UPDATE`/`DELETE` needs a dry-run and explicit approval.

## Stacks

- Backend: Ruby on Rails, PostgreSQL.
- Frontend: SvelteKit.
- DevOps: Docker/Compose, Kamal, GitHub Actions, GitLab CI.

## Tooling

- Keep tool output small: use `rg` with paths/globs, limit logs, avoid dumping
  whole files unless necessary.
- Load a skill with the `skill` tool when the task matches its description
  instead of guessing conventions.
