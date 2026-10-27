# Rails project rules

## Commands

- Setup: `bin/setup`
- Dev server: `bin/dev`
- Tests: `bundle exec rspec`
- Single test: `bundle exec rspec path/to/spec.rb:LINE`
- Lint: `bundle exec rubocop`
- Security: `bundle exec brakeman`
- Console: `bin/rails console`
- DB: `bin/rails db:migrate`, `bin/rails db:rollback`

Run tests and `rubocop` on changed files before proposing a commit.

## Conventions

- Keep controllers thin; business logic in `app/services` or model concerns.
- Use strong parameters; never mass-assign user input.
- Prefer Hotwire (Turbo + Stimulus) for interactive UI unless the project
  already uses a different stack.
- Use ViewComponent for reusable UI; avoid helper-heavy views.
- Migrations must be reversible and safe on large tables (no long locks).
- Never commit secrets; use Rails credentials or environment variables.
- Database work is read-only unless the user asks for a change.

## Deploy

- Kamal is the deploy path. `kamal deploy` to staging is allowed after CI;
  production requires explicit approval.
- Before deploy: migrations are backwards-compatible, env vars exist, rollback
  command (`kamal rollback`) is known.

## Agents and skills

- Use `rails-dev` for implementation and `db-optimizer` for slow queries.
- Load `rails-gem-selection` before adding a gem; load `rails-*` skills for
  framework-specific tasks.
