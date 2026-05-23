# docs/batches/

Holding area for **batch runs** dispatched by `/harness-kit:harness-batch`. Each batch is one folder under `docs/batches/<batch-id>/` and groups a list of tasks that run back-to-back through the 7-stage pipeline.

## What a batch folder looks like

```
docs/batches/<batch-id>/
├── BATCH_PLAN.md      ← input: table of tasks (you write this)
├── BATCH_LOG.md       ← append-only event log (skill writes during run)
└── BATCH_REPORT.md    ← terminal summary (skill writes at end / on stop)
```

Per-task stage docs do NOT live here — they live in `docs/features/<slug>/` (and are archived by each task's own pm-orchestrator to `docs/features/_archived/<slug>/` at delivery). The batch folder only holds the **batch-level** artifacts.

## Lifecycle

1. **Create the folder** by copying `docs/batches/_template/` to `docs/batches/<your-batch-id>/`.
2. **Edit `BATCH_PLAN.md`** — fill in the task table (one row per task; columns `ID | Slug | Goal | Mode | Depends on | Status`).
3. **Invoke** `/harness-kit:harness-batch <your-batch-id>`. The skill runs each pending task through `pm-orchestrator` in its own sub-agent context.
4. **Resume** at any time by re-invoking with the same batch-id — completed tasks are detected (via `Status: done` or the presence of a `DELIVERED` `07_DELIVERY.md`) and skipped.
5. **Read `BATCH_REPORT.md`** when the batch ends (all done, or stopped on a strong signal).

The batch is not auto-archived; the three batch-level files stay in place for user reference.

## Worked example

You decompose a sprint goal into 3 tasks via `/harness-plan`, then write:

```
docs/batches/sprint-7-csv-export/BATCH_PLAN.md
```

```markdown
# Batch Plan — sprint-7-csv-export

> Created: 2026-05-23
> Default mode: full
> Stop policy: strong-signal-only

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-01 | add-csv-export-endpoint | Add `GET /orders.csv` backend endpoint with pagination | full | — | pending |
| T-02 | add-csv-export-button | Add CSV export button on /orders page wired to T-01 endpoint | full | T-01 | pending |
| T-03 | csv-export-e2e-test | Cypress e2e test that drives the button and asserts file download | full | T-02 | pending |
```

You invoke:

```
/harness-kit:harness-batch sprint-7-csv-export
```

The skill runs T-01, waits for its `pm-orchestrator` sub-agent to return `DELIVERED`, runs `verify_all` (PASS), runs T-02, waits, `verify_all` PASS, runs T-03, waits, `verify_all` PASS. It then writes `BATCH_REPORT.md` summarizing all three deliveries with links to each `docs/features/_archived/<slug>/`.

If T-02 had failed, the batch would have stopped immediately, marked T-03 as `blocked` (since `Depends on: T-02`), and surfaced `BATCH_REPORT.md` with the failure reason and a clear "T-01 done, T-02 failed, T-03 blocked" stop summary.

See `skills/harness-batch/SKILL.md` for the full procedure, hard rules, and stop-signal semantics.
