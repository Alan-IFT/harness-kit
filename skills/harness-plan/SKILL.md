---
name: harness-plan
description: Design-only mode of the Harness pipeline — runs Requirement Analyst → Solution Architect → Gate Reviewer and stops. Produces 01_REQUIREMENT_ANALYSIS.md, 02_SOLUTION_DESIGN.md, 03_GATE_REVIEW.md with a verdict, but does NOT enter Developer. Use when you want a vetted design before committing engineering time.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite, Task
---

# /harness-plan

Run only the **design half** of the Harness 7-agent pipeline. Stop after Gate Review with a verdict. No code, no tests.

## When to invoke

- You have a feature idea and want to validate the design before building it
- You need an architecture review for someone else's proposal (paste their idea as input)
- You're scoping a quarter / sprint and want N designs ready to pick from
- Engineering time is expensive and you've been burned by half-baked designs before

## When NOT to invoke

- The task is small enough that design overhead exceeds implementation (use direct edit)
- The acceptance criteria are obvious (just run `/harness` full pipeline)
- You want code (use `/harness` full pipeline)

## Procedure

The PM Orchestrator (you or a dispatched sub-agent) dispatches **only stages 1-3** of the 7-agent pipeline. The Developer / Code Reviewer / QA Tester stages do not run.

1. **Create the task entry** in `docs/tasks.md` with `mode: plan` and `stage: planning`.
2. **Create the task directory** `docs/features/<task-slug>/` and `PM_LOG.md`.
3. **Dispatch Requirement Analyst** via Task tool. Output: `01_REQUIREMENT_ANALYSIS.md`.
4. **Dispatch Solution Architect** via Task tool. Output: `02_SOLUTION_DESIGN.md`.
5. **Dispatch Gate Reviewer** via Task tool. Output: `03_GATE_REVIEW.md` with one of:
   - `APPROVED FOR DEVELOPMENT` — the design is sound; user can later run `/harness` to continue from Dev with the existing 01-03 docs
   - `CHANGES REQUIRED` — list of changes needed; user iterates manually or re-runs `/harness-plan`
   - `REJECTED` — design unviable; explain why
6. **Update tasks.md** `stage: planning-done`.
7. **Report to user**: which verdict, where the documents are, what's the next move.

The plan-mode output is **resumable**: if the user decides to build it later, running `/harness` on the same task slug will detect existing 01-03 docs and skip those stages, jumping to Development. **The PM must record this mode choice in `PM_LOG.md`** so the full pipeline knows.

## Output

```
docs/features/<task-slug>/
  01_REQUIREMENT_ANALYSIS.md
  02_SOLUTION_DESIGN.md
  03_GATE_REVIEW.md
  PM_LOG.md                 (one entry per stage)
```

No 04-07 documents in plan mode.

## Cost vs full pipeline

`harness-plan` is ~30-40% of the time and context cost of the full 7-stage pipeline. Use it freely for any decision that needs vetting but isn't committed work yet.

## Anti-patterns

- **Do not** invoke the Developer or downstream stages. If you find yourself wanting to "just write a bit of code to validate the design", that's `/harness-explore`, not `/harness-plan`.
- **Do not** skip Gate Review. The verdict is the whole point — design without a gate is just a doc.
- **Do not** mutate this skill's procedure to add code-writing stages. If you need code, switch to `/harness`.
