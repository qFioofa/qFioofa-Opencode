# opencode config

Персональная конфигурация [opencode](https://opencode.ai) для разработки
Backend (Ruby on Rails, PostgreSQL), DevOps (Docker/Compose, Kamal, GitHub
Actions, GitLab CI) и Frontend (SvelteKit).

Репозиторий — source of truth. `src/` разворачивается в `~/.config/opencode`
симлинком (по умолчанию) или копией.

## Быстрый старт

```bash
git clone <repo> ~/qf/opencode
cd ~/qf/opencode
bash scripts/deploy.sh -b
```

`deploy.sh`:

| Флаг | Действие |
| --- | --- |
| `-b`, `--backup` | сохранить текущий `~/.config/opencode` в `.backup.<timestamp>` |
| `-r`, `--remove` | удалить текущий конфиг |
| `-c`, `--copy` | копировать вместо симлинка |
| `-d`, `--deps` | выполнить `npm install --omit=dev` в целевом каталоге |
| `-t DIR` | другой target |
| `-n` | dry-run |
| `-h` | справка |

Windows:

```bat
scripts\deploy.bat -b
```

Если `mklink` недоступен (нет Developer Mode/прав), скрипт автоматически
перейдёт в copy-режим.

После деплоя **перезапусти opencode** — конфиг читается один раз при старте.

## NixOS / Home Manager

```nix
{
  inputs.qfioofa-opencode.url = "github:qFioofa/opencode";

  # home-manager
  imports = [ inputs.qfioofa-opencode.homeManagerModules.default ];
  programs.qfioofa-opencode.enable = true;
  # programs.qfioofa-opencode.package = pkgs.opencode; # опционально
}
```

Модуль симлинкует `src/` в `~/.config/opencode`. Каталог только для чтения:
для `opencode plugin -g` используй `scripts/deploy.sh --copy`.

## Структура

```
src/                     # -> ~/.config/opencode
├── opencode.jsonc       # провайдеры, модели, права, compaction, MCP
├── tui.json             # тема
├── AGENTS.md            # глобальные правила
├── agents/              # architect, ui-designer, reviewer, db-optimizer
├── commands/            # /think /ui /gems /db /review /deploy-check
├── skills/              # глобальные скиллы + кастомные
└── themes/              # yugen-ash

templates/
├── rails/               # Rails + PostgreSQL + Kamal
├── svelte/              # SvelteKit + официальный плагин
└── devops/              # Docker/Compose + GitHub Actions + GitLab CI

nix/hm-module.nix        # Home Manager module
scripts/deploy.sh|.bat   # установка
```

## Глобальные скиллы

Процесс/мышление:

- `brainstorming`, `systematic-debugging`, `requesting-code-review`
- `improve-codebase-architecture`
- `frontend-design`, `web-design-guidelines`

Кастомные:

- `rails-gem-selection` — выбор гемов/UI-стека для Rails
- `postgres-safety` — read-only, EXPLAIN, индексы, миграции
- `devops-runbook` — деплой, секреты, rollback, CI

`write-project-readme` перенесён из старого конфига без изменений
(`src/skills/skills/`).

## Шаблоны проектов

Скопируй содержимое шаблона в корень проекта:

```bash
cp -a ~/qf/opencode/templates/rails/. /path/to/project/
cp -a ~/qf/opencode/templates/svelte/. /path/to/project/
cp -a ~/qf/opencode/templates/devops/. /path/to/project/
```

Шаблон содержит `opencode.json`, `AGENTS.md` и `.opencode/skills/`.
Проектный конфиг переопределяет глобальный; включённые MCP видны только в этом
проекте.

### Rails

- MCP: `rails-mcp-server` (gem, выключен по умолчанию), `pg-docs`,
  `postgres-mcp` (выключен, `--access-mode=restricted`).
- Skills: `rails-expert`, `rails-patterns`, `rails-hotwire`,
  `viewcomponent-coder`, `rspec`, `kamal-deployment`, `postgres`,
  `schema-exploration`, `design-postgres-tables`,
  `postgres-database-migration`, `postgresql-optimization`.
- Агент `rails-dev`.

Перед использованием Rails MCP:

```bash
gem install rails-mcp-server
rails-mcp-config
```

Затем выставь `"rails": { "enabled": true }` в проектном `opencode.json`.

### SvelteKit

- Плагин `@sveltejs/opencode` даёт Svelte MCP, autofixer и
  `svelte-file-editor`.
- Skills: `svelte-core-bestpractices`, `svelte-code-writer`.
- MCP `playwright` выключен; включай для визуальной проверки.

### DevOps

- Skills: `docker-compose-patterns`, `docker-build-strategies`,
  `github-actions`, `github-actions-hardening`, `gitlab-ci-patterns`,
  `devops-engineer`.
- Права: destructive-команды (`kamal setup`, `terraform apply`,
  `kubectl delete`, `docker system prune`) заблокированы или требуют
  подтверждения.

## Проверка

```bash
opencode debug config
opencode debug skill
opencode agent list
opencode mcp list
opencode stats
```

## Заметки

- **MCP стоит контекста.** Глобально включены только `context7` и `pg-docs`;
  Rails/Postgres/Svelte MCP — в проектных конфигах.
- **`@tarquinen/opencode-dcp`** (прунинг tool-output) добавлен комментарием в
  `src/opencode.jsonc`. Включи после проверки совместимости с твоей версией.
- **Секреты** — только env/CI secret store; в конфиге их нет.
- **Версии:** конфиг проверен на opencode 1.18.11. Скиллы ставятся через
  `npx skills` (Node >= 22.20).
- Если добавляешь custom tools в `src/tools/`, под Home Manager нужен
  writable-режим (`deploy.sh --copy`) или отдельный `node_modules`.
