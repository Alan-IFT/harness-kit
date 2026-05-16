# 05 — Cross-task insight index (harness-kit dogfood)

## What this is

`.harness/insight-index.md` is a **≤30-line append-only file** capturing truths about the harness-kit project itself that were hard to discover — facts the AI (or human) would otherwise rediscover the hard way every new task.

For this repo specifically, valid insight examples are things like:
- "Edit tool occasionally reports SUCCESS but doesn't apply the change — re-Read to verify (seen 2026-05-16 during v0.9.1 verify_all whitelist edit)"
- "`{{...}}` placeholders in any new .tmpl file MUST be added to verify_all's whitelist (D.2) OR the test fails — easy to miss for new template files"
- "PowerShell `Get-FileHash` differs from Bash `cmp -s` on line endings; tests/fixtures behave differently on Windows vs Linux"

## When to read this

**Before starting any non-trivial task in this repo.** Skim it; if an entry applies, you save a wrong assumption. Skip for typo fixes / comment cleanup.

## When to write to this

After completing a task, if you uncovered a non-obvious truth that the next person (or AI) would hit again, append one line at the bottom:

```markdown
- YYYY-MM-DD · <one-sentence fact> · evidence: <commit-sha or task-slug>
```

Rules:
- Max 30 lines total. If full, archive oldest to `docs/features/_archived/insight-history.md` (use `scripts/archive-task` which handles rotation).
- One line, one fact. Need a paragraph → not insight, just documentation.
- Always include evidence so future readers can verify.
- **Adversarial test**: ask "would someone reasonable, reading the repo fresh, derive this in <10 min?" If yes, don't write.

## What does NOT belong here

- Bug reports (those go in `docs/tasks.md`)
- Rules / conventions (those go in another `.harness/rules/*.md` fragment)
- Best-practice claims (the code or other rule fragments are the place)
- Task summaries (those go in `docs/features/<task>/`)

Insight = **evidence-backed discovery that beat a reasonable prior**, not "we decided X" and not "X is documented".
