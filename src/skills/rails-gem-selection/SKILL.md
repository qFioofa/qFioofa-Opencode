---
name: rails-gem-selection
description: Choose Rails gems and UI stack deliberately. Use when deciding between Hotwire, ViewComponent, Phlex, Inertia, Sidekiq, Solid Queue, or any new gem, and when asked "which gems should we use".
---

# Rails gem selection

Answer with a decision, not a list of everything popular.

## 1. Start from constraints

- Team familiarity and long-term maintenance.
- Does Rails already solve it? (Action Mailer, Active Job, Turbo, Stimulus,
  Solid Queue/Cache/Cable are built in.)
- Cost of another runtime dependency (background worker, JS build, service).
- Exit path: how hard is it to remove this gem later?

## 2. UI stack decision tree

1. Is the UI mostly server-rendered CRUD/interactive pages?
   - Yes → **Hotwire** (Turbo + Stimulus). Default choice, no SPA build.
2. Do you need reusable, tested view components in Ruby?
   - Yes → **ViewComponent** (with Hotwire).
   - Prefer pure Ruby templates and performance → **Phlex** (smaller ecosystem;
     only if the team accepts it).
3. Do you need a SPA with an existing JS component ecosystem?
   - SvelteKit is the house standard → **Inertia** only if the app must stay
     Rails-first with a Svelte frontend. Otherwise keep a separate SvelteKit app
     and a JSON API.
4. Styling: **Tailwind** unless the project already has a design system.
   Component library only if it replaces, not adds to, custom CSS.
5. Do not combine Inertia + Svelte + ViewComponent + Phlex in one app.

## 3. Background / data

- Default: **Solid Queue** if the app is small and already on Rails 8.
- Use **Sidekiq** when you need throughput, mature observability, or existing
  Redis infrastructure.
- Never add a queue gem before there is a real async workload.

## 4. Evaluation checklist for any new gem

| Question | Reject if |
|---|---|
| Last release / open issues | abandoned or unmaintained |
| Does it patch Rails internals? | fragile upgrade path |
| Runtime dependency weight | pulls a second server/DB without need |
| Test/maintenance cost | team cannot own it |
| Exit path | data locked in a proprietary format |

## 5. Output format

Return: decision, reason, rejected alternatives with one-line reasons, and the
migration/removal path. Use Context7 (or official docs) for current versions;
never invent gem APIs.
