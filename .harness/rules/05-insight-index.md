# 05 — Cross-task insight index (harness-kit dogfood)

## What this is

`.harness/insight-index.md` is a **≤30-entry append-only file** — an *entry* is one bullet line plus every line wrapped under it — capturing truths about the harness-kit project itself that were hard to discover — facts the AI (or human) would otherwise rediscover the hard way every new task.

For this repo specifically, valid insight examples are things like:
- "Edit tool occasionally reports SUCCESS but doesn't apply the change — re-Read to verify (seen 2026-05-16 during v0.9.1 verify_all whitelist edit)"
- "`{{...}}` placeholders in any new .tmpl file MUST be added to verify_all's whitelist (D.2) OR the test fails — easy to miss for new template files"
- "PowerShell `Get-FileHash` differs from Bash `cmp -s` on line endings; tests/fixtures behave differently on Windows vs Linux"

## When to read this

**Before starting any non-trivial task in this repo.** Skim it; if an entry applies, you save a wrong assumption. Skip for typo fixes / comment cleanup.

## How to search it — never a whole-file read, never an unscoped search

**If you hold `Bash`** (developer, qa-tester):

```bash
node .harness/scripts/doc-query.js --in memory <term>
```

**If you do not** (requirement-analyst, solution-architect, gate-reviewer, code-reviewer,
pm-orchestrator, supervisor) — five of the eight agents cannot run any script, which is why
the whole-file read became habit. Use the `Grep` tool with an **explicit `path`**:

```
Grep(pattern: <term>, path: ".harness/insight-index.md", output_mode: "content", -C: 10)
```

The explicit `path` is what matters. Without it the tool is ripgrep-backed and skips
dot-directories, so it returns **nothing** from any store in this project.

Both forms return the match in context instead of the file. The properties were measured,
not assumed (`evals/run-mem-baseline.sh`, 12 items):

- A repo-wide search scores **0 of 12** and returns **zero bytes**, so it reads as "no
  results" rather than "wrong search". Every store lives under `.harness/`, and ripgrep —
  which Claude Code's Grep tool is built on — skips dot-directories by default.
- A scoped search at ±2 lines scores 8/12 and at ±10 lines 10/12, because one fact is one
  long wrapped paragraph: a line window either truncates the fact or drags in its neighbour.
- `doc-query` scores **11/12 at 18× fewer tokens than reading the documents**. The one
  miss is an item whose answer lives in `verify_all.sh`, not in a store at all.

The corollary for writing: an entry is the retrieval unit, so **keep one fact in one
entry**. A fact split across two entries is returned halved.

## When to write to this

After completing a task, if you uncovered a non-obvious truth that the next person (or AI) would hit again, append one line at the bottom:

```markdown
- YYYY-MM-DD · <one-sentence fact> · evidence: <commit-sha or task-slug>
```

Rules:
- Max 30 entries (header lines are free; a wrapped entry still counts as one). If full, archive oldest to `docs/features/_archived/insight-history.md` (use `.harness/scripts/archive-task` which handles rotation — it moves whole entries, all their lines together).
- One line, one fact. Need a paragraph → not insight, just documentation.
- Always include evidence so future readers can verify.
- **Adversarial test**: ask "would someone reasonable, reading the repo fresh, derive this in <10 min?" If yes, don't write.

## What does NOT belong here

- Bug reports (those go in `docs/tasks.md`)
- Rules / conventions (those go in another `.harness/rules/*.md` fragment)
- Best-practice claims (the code or other rule fragments are the place)
- Task summaries (those go in `docs/features/<task>/`)

Insight = **evidence-backed discovery that beat a reasonable prior**, not "we decided X" and not "X is documented".
