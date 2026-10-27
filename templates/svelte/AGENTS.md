# SvelteKit project rules

## Commands

- Install: `pnpm install`
- Dev: `pnpm dev`
- Build: `pnpm build`
- Types: `pnpm check` (`svelte-check`)
- Lint/format: `pnpm lint` / `pnpm format`
- Unit tests: `pnpm test` (vitest)
- E2E: `pnpm test:e2e` (playwright)

Run `pnpm check` and the relevant tests before proposing a commit.

## Conventions

- Svelte 5 runes (`$state`, `$derived`, `$effect`) over legacy stores for local
  component state.
- Server-only code stays in `+page.server.ts` / `+server.ts`; never import
  secrets into client components.
- Use `load` functions and form actions instead of ad-hoc fetch in components.
- Prefer semantic HTML and scoped CSS before adding a UI dependency.
- Keep accessibility: labels, focus states, keyboard paths, reduced motion.

## UI work

- Use the `frontend-design` and `web-design-guidelines` skills for new screens.
- Propose 2-3 directions and a recommendation before implementing a redesign.
- Verify with the Playwright MCP when it is enabled.

## Agents and skills

- Use `ui-designer` for visual direction and `reviewer` before merging.
- The official `@sveltejs/opencode` plugin provides the Svelte MCP server,
  autofixer, and `svelte-file-editor` subagent.
