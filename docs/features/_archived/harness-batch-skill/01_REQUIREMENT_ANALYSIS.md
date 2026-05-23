# 01 — Requirement Analysis

## Problem statement

The current harness-kit pipeline (10 skills, 7-stage agent flow) only handles **one task per `/harness` invocation**. When a user has a list of tasks — e.g. `T-01` through `T-09` produced by `/harness-plan`, a backlog of accumulated small bugs, the multi-row WARN output from `verify_all`, or imported Linear/Jira tickets — they must invoke `/harness` nine times by hand. Each invocation re-loads `AI-GUIDE.md`, re-reads `.harness/insight-index.md`, re-checks `intervention.md`, etc. This is friction (user must remain present to type the next `/harness`) and waste (the cross-task setup work repeats).

There is also a stated concern about **context bloat** when nine tasks run back-to-back in one session. Today, single-task PM Orchestrator dispatches each stage as a Task-tool sub-agent (independent context), so single-task context use is bounded. But there is no upstream layer that bounds the batch-level context — naive sequential `/harness × 9` would accumulate PM-level routing logs, insight-index reads, and tasks.md updates in the main conversation context, ballooning over the course of the batch.

## Goals

1. **Single entry point for "run this list of tasks".** User invokes one slash command with one batch identifier; AI runs to completion.
2. **Context isolation between tasks.** Each task's pm-orchestrator + all 7 stage agents run in sub-agent contexts. The batch orchestrator itself sees only per-task summaries, not full stage docs.
3. **Strong-signal-only stop policy.** Batch is fully autonomous until: verify_all FAIL after a task, pm-orchestrator returns explicit FAIL verdict, 3 rollbacks in same stage of any task, intervention.md STOP, or safety hook block.
4. **Resumable.** If the batch is interrupted (machine reboot, rate-limit, user Ctrl-C), re-invoking with the same batch-id picks up where it left off — completed tasks are skipped, pending ones continue.
5. **Self-contained reporting.** A single `BATCH_REPORT.md` summarizes all task outcomes in one file.

## Non-goals

- **NOT an agent**; this is a skill. Adding a `program-manager` sub-agent on top of `pm-orchestrator` was considered (方案 B) and rejected — adds a contract surface, would require 3-level Task-tool nesting (untested in Claude Code), high-firepower-for-no-benefit per the user's "fully autonomous, stop only on strong signals" choice.
- **NOT a redesign of pm-orchestrator**. pm-orchestrator continues to handle exactly one task at a time, unchanged.
- **NOT a goal-loop**. `/harness-goal` already covers "iterate on one goal until criterion met". Batch is a list of distinct tasks.
- **NOT parallel by default.** Tasks run sequentially. Parallel dispatch is a future option; the user has not asked for it.
- **NOT a ticket-system integration.** Importing from Linear/Jira/GitHub issues is out of scope — the input is a markdown file the user (or an upstream skill) wrote.

## Sources of T-01~T-NN

The user confirmed (multi-select) that batches arise from four sources:

1. **Decomposition from `/harness-plan`** — Architect output split into sequential tasks; tasks may have dependencies (DB → API → UI).
2. **Accumulated independent small needs/bugs** — order-independent, can be reshuffled.
3. **Post-checkup batch fixes** — `verify_all` WARN list, security-review findings, technical-debt list; independent but homogeneous.
4. **External list import** — copied from Linear/Jira; dependency hints may or may not be present.

Implication: the batch plan format must support **both** dependency-free and dependency-having tasks. Default to sequential order in the plan file; allow an optional `Depends on` column for explicit predecessors.

## Acceptance criteria

| ID | Criterion |
|---|---|
| AC-1 | A new `/harness-kit:harness-batch <batch-id>` skill exists; invoking it on a folder `docs/batches/<batch-id>/BATCH_PLAN.md` runs each pending task through pm-orchestrator via the Task tool. |
| AC-2 | Each task's pm-orchestrator runs in a separate Task-tool sub-agent context. The batch skill never accumulates more than per-task summaries in the main context. |
| AC-3 | Batch stops automatically on any of: verify_all FAIL, pm-orchestrator FAIL verdict, 3 same-stage rollbacks reported by pm-orchestrator, `.harness/intervention.md` containing STOP, safety hook block. On stop, batch writes a `BATCH_REPORT.md` with the stop reason and task status, then surfaces to user. |
| AC-4 | Re-invoking with the same `<batch-id>` resumes — completed tasks (those with `docs/features/<slug>/07_DELIVERY.md` present, OR explicitly marked `done` in BATCH_PLAN.md) are skipped; remaining are run. |
| AC-5 | The BATCH_PLAN.md template includes columns: `ID`, `Slug`, `Goal`, `Mode`, `Depends on`, `Status`. Dependency-aware ordering: a task whose `Depends on` predecessor failed is marked `blocked` and skipped, not crashed. |
| AC-6 | `docs/batches/README.md` explains the batch lifecycle in ≤80 lines, with one worked example. |
| AC-7 | `verify_all` C.1 / G.1 / G.2 hardcoded skill lists are updated from 10 to 11 in BOTH `verify_all.ps1` AND `verify_all.sh` (script symmetry rule F.1). Skill count claim in README.md / README.zh-CN.md / AI-GUIDE.md is updated. |
| AC-8 | Plugin manifest version bumped (this is the first new skill since v0.18.x): plugin.json + marketplace.json + README.md badge + README.zh-CN.md badge all match (G.3 enforces). Decision: v0.18.2 → **v0.19.0** (semver MINOR — new feature, no breaking changes). |
| AC-9 | `verify_all` (both shells) PASSes. baseline.json updated if check count changes (it does not here — we add no new checks). |
| AC-10 | New CHANGELOG.md entry under `[0.19.0]` documenting the new skill, the version bump, and the rationale. Mentions harness-batch alongside the existing 10 names so G.2 still PASSes (G.2 will need to be updated to include harness-batch too — that's covered by AC-7). |

## Out of scope (deferred)

- Auto-import from Linear / Jira / GitHub issues — user can hand-craft BATCH_PLAN.md or use future converters.
- Parallel task dispatch — sequential is safer and matches single-task semantics; parallel can be a v0.20+ feature once batch stability is proven.
- Batch-level retry policy — if a task fails, batch stops; user reviews and re-runs. No silent retry.
- Auto-generation of BATCH_PLAN.md from `/harness-plan` output — could be a future enhancement of `/harness-plan` to optionally emit a batch plan.
