---
description: Review the current diff before committing
agent: reviewer
---

Use the `requesting-code-review` skill.

Review the current changes (git diff, staged and unstaged) plus the surrounding
code. Focus on correctness, security, DB/data risks, and missing tests. Report
findings as file:line with a concrete fix. Do not modify files.
