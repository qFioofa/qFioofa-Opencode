---
name: write-project-readme
description: Use when the user wants to document, describe, rewrite, or polish a README for a finished project or a backend/portfolio project, when they want to present a project's achievements/architecture/stack in a resume-worthy way, or when they reference a project README, project structure, "оформить проект", "сделать README", "структура проекта", "продать проект", "оформить проект для резюме". 
---

# Write a resume-worthy project README

Generate/open/polish a `README.md` for a completed project. Two inputs drive it:

- **`README.md` (this repo)** — the structural template: sections, order, tone,
  formatting conventions. Reproduce this structure.
- **`RESUME-NOTES.md` (this repo)** — how to phrase achievements so they read
  well for recruiters/ATS: quantified impact, contribution-language, keyword
  placement. Apply this phrasing.

## Goal

A README that is both a technical document and a *sales pitch*: a reviewer
should grasp what was built, the architecture, the stack, and why it is
impressive — within seconds, top part first.

## Diagrams: author them in PlantUML (source of truth)

Every image in the README must ship as an editable PlantUML source, not just a
static picture. Follow this workflow so diagrams stay consistent with each
other and are trivial to tweak:

1. Create one `.puml` file per diagram in `diagrams/` (e.g.
   `architecture.puml`, `stack.puml`, `structure.puml`, `services.puml`,
   `api.puml`).
2. Give every diagram a shared visual theme by `!include`-ing a common
   `diagrams/theme.puml` with `skinparam` + `<style>` blocks (consistent
   background, accent colors, fonts). Reuse the same accent palette across all
   files for a cohesive look.
3. Use the right plantuml element per diagram:
   - **architecture** — `left to right direction` pipeline with `actor` (client)
     → `node` (entry point) → grouped `package`/`rectangle` (write vs read
     tiers) → `database`; keep the flow horizontal so labels don't overlap.
   - **services / addresses** — one node per endpoint/port; if there are >4–5
     nodes, lay them out on **two rows** with hidden arrows
     (`A -[hidden]right-> B`, `B -[hidden]down-> C`) instead of one long strip.
   - **stack** — grouped `package` layers of `component` items.
   - **structure** — nested `package`/`rectangle` of the project's main dirs
     with `ctrl --> svc`-style dependency arrows.
   - **api** — `class`-boxes grouped by controller, one line per HTTP verb.
4. Per-diagram `skinparam` overrides (colors/sizes) live in the `.puml` file
   itself. Mind the quirks: use `skinparam arrowFontColor` (NOT `arrowLabelColor`,
   which renders black) to color arrow labels; on a dark theme a plain `actor`
   silhouette is invisible — enable `skinparam actorStyle awesome` plus a bright
   `actorBorderColor`/`actorBackgroundColor`.
5. Labels must stay readable: light text (`#F5F7FA`-range) on the dark canvas,
   `\n` to split long node names over two lines, short arrow labels.
6. Render to PNG for the README:
   ```
   plantuml -tpng diagrams/*.puml
   ```
   Re-run it after any change so the committed `.png` matches the `.puml`.
   (If `plantuml` is the user's tool, invoke `plantuml` in the repo root.)
   Prefer keeping both the `.puml` source and the rendered `.png` in `diagrams/`.

## Output structure (mirror the template `README.md`)

Produce, in this exact order:

1. **Title + shield badges** (tech stack, license). Under the title, a one-line
   stack summary: `**Стек:** ...`.
2. **Achievements / key points** — a bulleted list. **Every bullet = one
   contribution expressed as impact.** Use the formulas below.
3. **Architecture** — PlantUML diagram (`diagrams/architecture.puml` → `.png`) + 1–3 sentences of the idea/how it works.
4. **Технологический стек** — PlantUML diagram (`diagrams/stack.puml` → `.png`).
5. **Структура проекта** — PlantUML diagram (`diagrams/structure.puml` → `.png`) + short tree of the main dirs.
6. **Технические команды** — `bash` block of the runnable commands (include the `plantuml -tpng diagrams/*.puml` render step).
7. **Сервисы** — PlantUML diagram (`diagrams/services.puml` → `.png`) + note on hosts/ports.
8. **API обзор** — PlantUML diagram (`diagrams/api.puml` → `.png`), pointer to Swagger/OpenAPI.
9. **Лицензия** — license line.

### Every project differs — adapt

The template is the *skeleton*, not a straitjacket. Inspect the actual codebase
and fill in real numbers and real components:
- count real REST endpoints (search `@GetMapping`/`@PostMapping`/`@RequestMapping`
  etc.);
- count real Flyway/Liquibase migrations, Docker services, NRE/read-replicas;
- note real pivot details: pagination, validation, error handling, auth, file
  upload, caching, HTTPS, load balancing, healthchecks.
Use scripts/Glob/Grep on the project first. Never invent numbers that are not
verifiable in the repo; prefer conservative "30+" over fabricated precision.

## Achievement-bullet formula (from `RESUME-NOTES.md` §5.2)

> **Глагол-действие + Что сделал + Чем (инструмент/технология) + Результат (цифра, метрика)**

Strong verbs: *Спроектировал, реализовал, внедрил, автоматизировал,
оптимизировал, разбил, зашифровал, документировал, поднял.*

Avoid duty-speak (no numbers): "Разрабатывал REST API на Spring Boot". Prefer
impact-speak: "Спроектировал и реализовал REST API на Spring Boot (30+
эндпоинтов) для интернет-магазина".

Recommendations for each bullet:
- add a concrete count where honest (endpoints, migrations, instances, layers);
- mention the tool that enabled the result (Flyway, Docker, Nginx, record DTOs);
- keep each bullet to one idea; ~10–21 bullets top.

### Example bullets (adapt, don't copy verbatim)

- Спроектировал и реализовал REST API интернет-магазина на Java 21 + Spring Boot: 29 REST-эндпоинтов для clients/suppliers/products/images с семантическими PUT/PATCH, пагинацией через PageRequest и поиском — единый контракт на базовом пути /api/v1.
- Построил вертикальную слоистую архитектуру controller → service → mapper → dao (JPA) с DTO на Java record и сущностями, отделёнными от транспорта.
- Внедрил единый конвейер валидации и обработки ошибок: Bean Validation + ErrorResponse через @RestControllerAdvice.
- Автоматизировал схему БД миграциями Flyway: N версий (схема, сид-данные, ...) — развёртывание воспроизводимо.
- Разделил нагрузку на запись и чтение: 2 read-only инстанса под ролью БД readonly (только SELECT, SPRING_FLYWAY_ENABLED=false).
- Настроил Nginx как entry point: HTTPS (TLS 1.2/1.3), gzip, кэширование GET, балансировка.
- Поднял всю инфраструктуру одной командой: Docker Compose (PostgreSQL + pgAdmin + N бэкендов + Nginx), healthcheck'и, отдельная подсеть, Makefile-обёртка.

## Style rules

- Russian is the default for narration (matching the template). Keep code,
  command names, and technical identifiers in English.
- Keep it compact: short lines, one sentence per bullet.
- Commands go in ` ```bash ` blocks; paths/code in inline backticks.
- Commands go in ` ```bash ` blocks; paths/code in inline backticks. Keep the
  `plantuml -tpng diagrams/*.puml` render command among them.
- Diagrams: source them in `diagrams/<name>.puml` and render to
  `diagrams/<name>.png` with plantuml (see the "Diagrams" section). Never leave
  a dead placeholder — if you author a diagram, create the `.puml` AND run the
  render so the `.png` is real.
- Shield badges: `https://img.shields.io/badge/<Label>-<Value>-<color>`.
- If the user asked for English (or the project is non-RU), mirror the same
  structure in English instead — do not mix.

## Handoff

- Never overwrite an existing README silently: if `README.md` exists, ask or
  write to a new file / summarize diff first.
- Package numbers as conservative counts with `+` (e.g. "30+") unless exact.
- After writing, report the file path and a short list of the assumptions made
  about metrics so the user can correct anything.