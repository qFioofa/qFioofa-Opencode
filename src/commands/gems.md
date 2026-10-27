---
description: Compare gems/libraries for a Rails task
agent: architect
---

Use the `rails-gem-selection` skill. If the Context7 MCP server is available,
fetch current documentation for each candidate gem instead of relying on memory.

Decision needed: $ARGUMENTS

Return a table: candidate, what it solves, maintenance/activity, integration
cost, lock-in, and when NOT to use it. Then recommend one option and state the
migration/exit path. Do not add gems to the project.
