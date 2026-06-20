---
name: harness-batch
description: Run a list of tasks (T-01...T-NN) through the 7-stage pipeline in sequence. Reads docs/batches/<batch-id>/BATCH_PLAN.md and dispatches pm-orchestrator per task via the Task tool, so each task gets its own isolated context and the batch orchestrator itself only accumulates per-task summaries. Use when you have multiple tasks (from /harness-plan decomposition, an accumulated backlog, post-checkup integrations, or an external list) and want fire-and-forget execution instead of /harness × N. Stops on strong signals only: verify_all FAIL, pm-orchestrator FAIL verdict, 3 same-stage rollbacks, intervention.md STOP, safety hook block.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite, Task
---

# /harness-batch

Run a list of tasks through the full 7-stage pipeline back-to-back, one task at a time, each in its own sub-agent context. This is **fire-and-forget batch mode** — it stops only on strong failure signals.

## When to invoke

- A `/harness-plan` decomposition produced T-01…T-NN and you want them executed without re-typing `/harness` for each.
- You have an accumulated backlog of small independent bugs / chores and want them swept in one go.
- A `verify_all` WARN sweep, security-review, or technical-debt list produced a batch of post-checkup fixes.
- You've imported a list (Linear / Jira / hand-curated) into `docs/batches/<batch-id>/BATCH_PLAN.md` and want it run.

The hallmark: more than one distinct task, each shippable on its own, and the user prefers "fully autonomous, stop only when something actually breaks" over per-task supervision.

## When NOT to invoke

| Symptom | Use this instead |
|---|---|
| Exactly one task | `/harness` (full 7-stage) |
| Iterate one goal until a measurable criterion is met | `/harness-goal` |
| "Vet a design before writing code" | `/harness-plan` |
| "Can we even do X?" / research | `/harness-explore` |
| Course-correct a running pipeline | `/harness-intervene` |

## Required input

A single argument: `<batch-id>` — the folder name under `docs/batches/`. The folder must contain `BATCH_PLAN.md`.

If the folder or the plan file is missing, point the user at `docs/batches/_template/BATCH_PLAN.md` and ask them to copy it to `docs/batches/<batch-id>/BATCH_PLAN.md`, fill in the task table, then re-invoke.

When you author the rows, make each one a tracer-bullet vertical slice that fits the smart zone — see `harness-plan` → "Task-decomposition discipline".

## Procedure

1. **Argument validation.** Confirm `docs/batches/<batch-id>/BATCH_PLAN.md` exists. If not, surface the template path and stop.

2. **Pre-flight checks** (once, at batch start):
   - `.harness/intervention.md` — if present, consume it per `.harness/rules/65-intervention.md` BEFORE starting any task. A STOP keyword aborts the batch entirely.
   - `.harness/scripts/verify_all` baseline — run once, capture PASS/WARN/FAIL counts. If the repo is already at FAIL, **refuse to start** the batch (a broken baseline makes per-task regression detection impossible). Surface the failure and exit.
   - `.harness/insight-index.md` — read once; surface relevant lines into each task's pm-orchestrator dispatch prompt.

3. **Parse `BATCH_PLAN.md`**: extract the task table (columns `ID | Slug | Goal | Mode | Depends on | Status`). Validate:
   - Required columns present (refuse to start on schema drift).
   - No cycle in `Depends on` (refuse to start, point at the cycle).
   - Slugs unique within the batch.
   - At least one task with `Status: pending` (or whose `07_DELIVERY.md` is absent). Build a topological order honoring `Depends on`. Tasks marked `Status: done`, OR whose `docs/features/<slug>/07_DELIVERY.md` already exists with a `DELIVERED` verdict (primary check) — falling back to any line matching `Final verify_all result: PASS` (secondary, for format-tolerance) — are treated as **already done** and skipped (free resume).

4. **Per-task loop** (sequential, in topological order):
   - **a.** Mark the task `in-progress` in `BATCH_PLAN.md`.
   - **b.** Append to `docs/batches/<batch-id>/BATCH_LOG.md`: `<ISO-8601 UTC> · <task-id> · dispatching pm-orchestrator · slug=<slug> · mode=<mode>`.
   - **c.** **Dispatch `harness-kit:pm-orchestrator` via the `Task` tool.** The prompt includes: task slug, the one-sentence goal, the mode (`full` / `plan` / `goal`), any `insight-index.md` lines that match the task topic, plus the standard instruction "run /harness for this task; produce the 7 stage docs under `docs/features/<slug>/`; archive at the end". The sub-agent runs in its OWN context — the batch skill never sees the full stage docs, only the return summary.
   - **d.** Read the sub-agent's return summary line. Expected fields: verdict (`DELIVERED` / `BLOCKED` / `FAILED`), path to `07_DELIVERY.md`, files-changed count, final `verify_all` status. Append a one-line summary to `BATCH_LOG.md`.
   - **e.** **Run `.harness/scripts/verify_all` after each task.** If it returns FAIL (exit code 2), the task caused a regression — stop the batch immediately (strong signal).
   - **f.** Update the task's `Status` in `BATCH_PLAN.md`: `done` / `failed` / `blocked`.
   - **g.** Check `.harness/intervention.md` between tasks; consume + act per `.harness/rules/65-intervention.md`.
   - **h.** If the task `FAILED`, mark every task whose `Depends on` chain includes it as `blocked` (skip without dispatching), then stop the batch (do not auto-continue after a failure).

5. **Strong-signal stop conditions** (any one → stop the batch, write `BATCH_REPORT.md`, surface to user):
   - The dispatched pm-orchestrator returns `FAILED` verdict (the externally-visible form of pm-orchestrator's "3 same-stage rollbacks → STOP" hard rule — either signal alone triggers stop).
   - `.harness/scripts/verify_all` returns FAIL after a task — the change broke the baseline.
   - `.harness/intervention.md` contains `STOP` between tasks.
   - The safety hook (`.harness/scripts/guard-rm`) blocked a destructive Bash call inside a task — the sub-agent will surface the block in its return summary.

6. **Soft-signal NOTE / SKIP** between tasks (per `.harness/rules/65-intervention.md`):
   - `NOTE — <text>` → attach the text to the **next** task's pm-orchestrator dispatch prompt, then delete the file. Batch continues.
   - `SKIP <task-id> — <reason>` → mark `<task-id>` as `skipped` in `BATCH_PLAN.md`, delete the intervention file, continue with the rest.
   - `REDIRECT <task-id>` → reject (REDIRECT is for stages, not tasks). Convert to a STOP keyword and ask the user.
   - `ADD <slug> — <goal>` → reject for a batch: a batch plan is **frozen** at start (see anti-patterns), and `ADD` is a `/harness-stream` feature. Tell the user to either update `BATCH_PLAN.md` and re-invoke this batch, or switch to `/harness-stream <batch-id>` to drain the same pool as a living stream.

## Resume semantics

`/harness-kit:harness-batch <batch-id>` is idempotent on completed work. Re-invoking with the same batch-id picks up where it left off:

- `Status: done` in `BATCH_PLAN.md` → skip without re-evaluation.
- `Status: pending` | `in-progress` | `failed` | `blocked` → re-evaluate:
  - If `docs/features/<slug>/07_DELIVERY.md` exists AND parses as `DELIVERED` (primary) OR contains `Final verify_all result: PASS` (secondary fallback for format-tolerance) → mark `done`, skip.
  - Else → run as if pending.

Verdict-parsing rule is intentionally tolerant; keep the dual check if the delivery doc format evolves.

## On batch completion

When the loop exits (all done, or stopped early), write `docs/batches/<batch-id>/BATCH_REPORT.md` with:

- Per-task row: `<task-id> | <slug> | <verdict> | link to docs/features/_archived/<slug>/ (or docs/features/<slug>/ if not yet archived)`.
- Aggregate stats: tasks done, failed, blocked, elapsed wall time, final `verify_all` summary.
- Stop reason if applicable (which strong signal fired).

Per-task stage docs ARE archived by each task's own pm-orchestrator (it calls `.harness/scripts/archive-task` at delivery). The batch artifacts (`BATCH_PLAN.md`, `BATCH_LOG.md`, `BATCH_REPORT.md`) stay in `docs/batches/<batch-id>/` for user reference — they are **not** auto-archived.

## Hard rules

- **Never bypass pm-orchestrator.** The batch skill is a thin loop; all per-task routing happens inside pm-orchestrator. Do not directly dispatch RA/SA/Dev/etc. from this skill.
- **Never auto-retry a failed task.** If a task fails, the batch stops. The user reviews, fixes, manually re-invokes.
- **Never run more than one task in parallel.** Sequential only in v0.19.0; parallel is a future feature.
- **Never modify another task's `docs/features/<slug>/`** from the batch skill — that's the task's pm-orchestrator's territory.
- **Always pre-flight `verify_all`.** A batch that starts on a broken baseline cannot tell its own regressions apart from inherited ones.
- **Always run `verify_all` after each task.** Catches per-task regressions before they pile up.

## Anti-patterns

- **Do not** invoke for a single task — use `/harness`. The batch wrapper adds no value and costs an extra log file.
- **Do not** silently widen the batch (add tasks not in `BATCH_PLAN.md`). If new work appears during execution, stop the batch, update the plan, re-invoke.
- **Do not** suppress `verify_all` FAIL to keep the batch running. That is exactly the signal the batch is supposed to honor.
- **Do not** put rules / insights / project-level decisions in `BATCH_REPORT.md`. Those belong in `.harness/rules/` or `.harness/insight-index.md` and are surfaced by each task's own delivery doc.

## Cost

Roughly N × (full 7-stage cost) plus a fixed batch overhead of ~5 lines/task in `BATCH_LOG.md` and one `verify_all` run per task. The savings over `/harness × N` come from:

- One-shot user invocation instead of N.
- One-shot pre-flight (`insight-index.md` read, baseline `verify_all`) instead of N.
- Each task's pm-orchestrator runs in its own context, so the batch orchestrator's context grows by ~one summary line per task, not by N × per-task stage docs.
