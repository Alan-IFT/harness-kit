---
name: harness-goal
description: Open-ended goal mode. Runs Developer + QA in a loop within a stated budget (time or iteration count) until a success criterion is met or the budget is exhausted. Use for "keep refactoring until verify_all passes", "improve test coverage to 80%", "reduce build time below 30s" — tasks without a clean single-shot definition.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite, Task
---

# /harness-goal

Run Developer + QA Tester in a bounded loop. Each iteration improves toward a stated goal until the success criterion is met or the budget runs out.

## When to invoke

- "Keep refactoring this module until cyclomatic complexity < 10"
- "Improve test coverage from 60% to 80% on the `payments/` package"
- "Reduce verify_all WARN count from 5 to 0"
- "Search for and fix the flaky test in `tests/integration/` (budget: 1 hour)"

The hallmark: there's a measurable target and an open path to reach it.

## When NOT to invoke

- You want a specific feature added (use `/harness` full pipeline)
- The success criterion isn't measurable (sharpen it first via `/harness-explore`)
- The work is exploratory with no target (use `/harness-explore`)
- You'd want a Gate Review (use `/harness-plan` first, then loop)

## Required input

Before invoking, the user (or upstream task) must specify:

1. **Goal statement** — one sentence, measurable. "Reduce flakiness in `tests/integration/` below 1% per run."
2. **Success criterion** — a script or command whose exit code / output measures progress. "verify_all reports zero `tests/integration/*` failures over 10 consecutive runs."
3. **Budget** — one of:
   - `max-iterations: N` (default: 10)
   - `max-minutes: N` (default: 60)
4. **(Optional) Stop conditions** — any side-condition that should abort the loop (e.g. "if any file outside `tests/integration/` is modified, stop and ask the user").

If any of 1-3 is missing, the skill asks the user before running.

## Procedure

1. **Create the task entry** in `docs/tasks.md` with `mode: goal`, `stage: looping`, `budget: ...`.
2. **Create the task directory** `docs/features/<task-slug>/` with `goal_state.json`:
   ```json
   {
     "goal": "...",
     "success_criterion_cmd": "...",
     "budget": {"max_iterations": 10},
     "iterations_used": 0,
     "history": []
   }
   ```
3. **Run the success criterion command once** to capture baseline. Record in goal_state.json.
4. **Loop until budget exhausted or criterion met**:
   a. Dispatch Developer via Task tool with input = current state + history (3 most recent iterations max, to keep context manageable). The Developer makes one improvement.
   b. Run `.harness/scripts/verify_all`. If FAIL, the Developer's change broke something — revert and record in history as a regression, do not increment iteration count.
   c. Run the success criterion command. Append `(iteration_n, measurement, change_summary)` to goal_state.json's history.
   d. If criterion met → break out, write 07_DELIVERY.md with verdict `GOAL ACHIEVED`.
   e. If `iterations_used >= max_iterations` (or time elapsed) → break out, write 07_DELIVERY.md with verdict `BUDGET EXHAUSTED` and current state.
5. **Dispatch QA Tester** at the end (only once, on the final state) with the **adversarial verification contract** (`## Adversarial tests` section required, see `qa-tester.md`).
6. **Update tasks.md** `stage: goal-done` and report to user.

## Output

```
docs/features/<task-slug>/
  goal_state.json          (the live state during the loop)
  04_DEVELOPMENT.md        (accumulated dev log, one section per iteration)
  06_TEST_REPORT.md        (final QA with adversarial tests)
  07_DELIVERY.md           (verdict + final measurement)
  PM_LOG.md
```

No 01-03 (no requirement / design / gate — the goal IS the requirement).
No 05 (no code review — Developer self-reviews each iteration; QA does the final review).

## Context discipline

Each iteration's Developer dispatch receives **at most the 3 most recent iterations**. Older iterations are summarized in goal_state.json (one-line per iteration). This bounds the context growth.

## Anti-patterns

- **Do not** run without a measurable success criterion. "Make it better" is not a goal.
- **Do not** disable the verify_all gate. Each iteration must keep `verify_all` green.
- **Do not** silently extend the budget. If the budget runs out and the goal isn't met, **stop and report**; don't sneak in more iterations.
- **Do not** modify files outside the scope implied by the goal. If the goal is "refactor `payments/`", changes outside `payments/` are off-scope.
- **Do not** harvest insights from a `BUDGET EXHAUSTED` run unless the failure mode itself is the insight (record it as such, with evidence).
