# 02 — Solution Design

## Chosen approach: 方案 A — new skill, no new agent

Three approaches were brainstormed; the user selected this one.

| Approach | Verdict | Reason |
|---|---|---|
| A: new `harness-batch` skill, no new agent | **CHOSEN** | minimal contract surface, fully reuses pm-orchestrator, dogfood-symmetric with existing `/harness-goal`/`/harness-plan`/`/harness-explore` |
| B: new `program-manager` sub-agent + skill | rejected | new agent contract to write/test/maintain; requires 3-level Task-tool nesting (unverified); over-engineered for "fully autonomous, stop on strong signals" policy |
| C: extend `/harness` to accept multiple tasks | rejected | bloats pm-orchestrator (it becomes both per-task router and batch orchestrator); breaks single-responsibility; persistence story is worse |

## Module decomposition

```
NEW
  skills/harness-batch/SKILL.md                  ← the skill (~180 lines, allowed-tools includes Task)
  docs/batches/README.md                         ← lifecycle explainer + worked example (~80 lines)
  docs/batches/_template/BATCH_PLAN.md           ← copy-paste template for users

MODIFIED
  scripts/verify_all.sh                          ← C.1 + G.1 + G.2 hardcoded skill arrays: add 'harness-batch'
  scripts/verify_all.ps1                         ← same three arrays (script symmetry rule F.1)
  AI-GUIDE.md                                    ← Workflow-entry table: new row for /harness-batch
  README.md                                      ← skill count 10→11; new bullet under Pipeline skills; badge bump
  README.zh-CN.md                                ← same edits, Chinese
  CHANGELOG.md                                   ← new [0.19.0] entry
  .claude-plugin/plugin.json                     ← version 0.18.2 → 0.19.0
  .claude-plugin/marketplace.json                ← version 0.18.2 → 0.19.0
  docs/tasks.md                                  ← add T-006 row
```

NO changes to: `.harness/agents/*` (no agent contract changes), `templates/common/*` (skills are not in templates — they ship via the Claude Code Plugin manifest, the `skills/` field of plugin.json), `scripts/harness-sync*` (no new sync targets), `scripts/sync-self*` (no template-agent changes), `.harness/rules/*` (the new skill doesn't introduce a new project-level rule).

## Skill contract — `skills/harness-batch/SKILL.md`

### Frontmatter

```yaml
---
name: harness-batch
description: Run a list of tasks (T-01...T-NN) through the 7-stage pipeline in sequence. Reads docs/batches/<batch-id>/BATCH_PLAN.md and dispatches pm-orchestrator per task via the Task tool, so each task gets its own isolated context and the batch orchestrator itself only accumulates per-task summaries. Use when you have multiple tasks (from /harness-plan decomposition, an accumulated backlog, post-checkup integrations, or an external list) and want fire-and-forget execution instead of /harness × N. Stops on strong signals only: verify_all FAIL, pm-orchestrator FAIL verdict, 3 same-stage rollbacks, intervention.md STOP, safety hook block.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite, Task
---
```

### Procedure (the SKILL.md body)

1. **Argument**: a single `<batch-id>` (folder name). Validate `docs/batches/<batch-id>/BATCH_PLAN.md` exists; else ask the user to create one from `docs/batches/_template/BATCH_PLAN.md`.

2. **Pre-flight checks** (run once at batch start):
   - `.harness/intervention.md` not present (else consume per `.harness/rules/65-intervention.md` and act).
   - `scripts/verify_all` baseline run — capture PASS/WARN/FAIL counts; if FAIL, refuse to start batch ("repo is already broken; fix baseline first").
   - Read `.harness/insight-index.md` once — keep in skill context for dispatch hints to each task's pm-orchestrator.

3. **Parse BATCH_PLAN.md**: extract the task table, build a topological order honoring the `Depends on` column. Tasks with `Status: done` (or whose `docs/features/<slug>/07_DELIVERY.md` already exists) are skipped — this gives free resume.

4. **Per-task loop** (sequential):
   a. Mark task `in-progress` in BATCH_PLAN.md.
   b. Append a line to `BATCH_LOG.md`: `<timestamp> · T-NN · dispatching pm-orchestrator · slug=<slug> · mode=<mode>`.
   c. **Use the `Task` tool** to dispatch `pm-orchestrator` sub-agent. Prompt includes: task slug, one-sentence goal, mode (full / plan / goal), any insight-index lines that applied to the task topic, and the standard "run /harness, write 7 stage docs under docs/features/<slug>/" instruction.
   d. Wait for sub-agent return. Read its summary line (the sub-agent should return: verdict (`DELIVERED` / `BLOCKED` / `FAILED`), 07_DELIVERY.md path, files-changed count). Append to BATCH_LOG.md.
   e. Run `scripts/verify_all` once after each task; if FAIL → stop the batch (strong signal).
   f. Update task `Status` in BATCH_PLAN.md: `done` / `failed` / `blocked`.
   g. Check `.harness/intervention.md` between tasks; consume + act if present.
   h. If task FAILED, mark its dependents as `blocked` and skip them. Then stop the batch (strong signal: don't auto-continue after a failure).

5. **Strong-signal stop conditions** (any → stop, write BATCH_REPORT.md, surface to user):
   - Task's pm-orchestrator returns `FAILED` verdict (sub-agent reports it gave up after 3 same-stage rollbacks).
   - `scripts/verify_all` FAIL after any task (the change broke baseline).
   - `.harness/intervention.md` STOP keyword consumed between tasks.
   - Safety hook (`scripts/guard-rm`) blocked a Bash call inside a task (sub-agent will report this back).

6. **Soft-signal NOTE / SKIP** in `intervention.md` between tasks: apply per `.harness/rules/65-intervention.md` (NOTE → attach to next task's pm-orchestrator dispatch prompt; SKIP `<task-id>` → skip that task and continue).

7. **On batch completion** (all tasks done, or stopped early):
   a. Write `docs/batches/<batch-id>/BATCH_REPORT.md`: per-task row with verdict + link to `docs/features/_archived/<slug>/`, plus aggregate stats (X done, Y failed, Z blocked, elapsed).
   b. **NOT auto-archived.** The batch artifacts (BATCH_PLAN.md, BATCH_LOG.md, BATCH_REPORT.md) stay in `docs/batches/<batch-id>/` for user reference. Per-task stage docs ARE archived by each task's own pm-orchestrator (calling `scripts/archive-task` at delivery).

### Hard rules (in the SKILL.md)

- **Never bypass pm-orchestrator.** The batch skill is a thin loop; all per-task routing happens inside pm-orchestrator. Do not directly dispatch RA/SA/Dev/etc. from the batch skill.
- **Never auto-retry a failed task.** If a task fails, batch stops. User reviews, fixes, manually re-invokes.
- **Never run more than one task in parallel.** Sequential only in v0.19.0.
- **Never modify another task's `docs/features/<slug>/`** from the batch skill — that's the task's pm-orchestrator's territory.
- **Always pre-flight `verify_all`.** A batch that starts on a broken baseline cannot tell its own failures apart from inherited ones.

## BATCH_PLAN.md format

```markdown
# Batch Plan — <batch-id>

> Created: YYYY-MM-DD
> Default mode: full
> Stop policy: strong-signal-only

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-01 | add-csv-export | Add CSV export button to /orders page | full | — | pending |
| T-02 | fix-payment-retry | Race condition in payment retry; add idempotency key | full | — | pending |
| T-03 | refactor-auth-mw | Extract auth middleware into packages/auth | full | T-01 | pending |

## Notes (optional)

- T-03 must wait for T-01 because both touch the same `apps/web/middleware.ts` file.
- T-02 is independent and can run anytime in the queue.
```

Column semantics:
- **ID**: stable batch-local identifier (`T-NN`); does NOT collide with `docs/tasks.md` ID space (those are repo-wide `T-001`, `T-002`).
- **Slug**: kebab-case; becomes the `docs/features/<slug>/` folder name. Must be unique within the batch.
- **Goal**: one sentence; becomes pm-orchestrator's task-description input.
- **Mode**: `full` (default) | `plan` | `goal` (passed through to pm-orchestrator).
- **Depends on**: comma-separated list of `T-NN` IDs in the same batch, or `—` for none.
- **Status**: `pending` (initial) | `in-progress` | `done` | `failed` | `blocked` (predecessor failed). The skill writes; the user reads.

## BATCH_LOG.md format

Append-only event log, one line per event:

```
2026-05-23T10:00:00Z · batch-start · 3 pending tasks
2026-05-23T10:00:01Z · T-01 · dispatching pm-orchestrator · slug=add-csv-export
2026-05-23T10:15:32Z · T-01 · returned DELIVERED · 4 files changed · verify_all 31/31 PASS
2026-05-23T10:15:33Z · T-02 · dispatching pm-orchestrator · slug=fix-payment-retry
2026-05-23T10:38:11Z · T-02 · returned FAILED · 3 same-stage rollbacks at code-review · batch-stop triggered
2026-05-23T10:38:12Z · T-03 · skipped · depends on T-01 (done) — would run, but batch stopped
2026-05-23T10:38:13Z · batch-stop · reason: T-02 FAILED
```

PM Orchestrator's own logs live in each task's `docs/features/<slug>/PM_LOG.md`; batch log is a thin summary.

## Stop-signal semantics

| Signal | Detector | Action |
|---|---|---|
| pm-orchestrator returns `FAILED` verdict | sub-agent return summary | stop batch; mark task `failed`; dependents `blocked` |
| `verify_all` FAIL after a task | direct exit code | stop batch; mark task `failed` (caused regression) |
| 3 same-stage rollbacks within a task | pm-orchestrator's own contract (rule "Hard rule 3"); surfaces via sub-agent return | stop batch; same as `FAILED` |
| `intervention.md` contains STOP between tasks | skill reads file before each task | consume per rule 65; stop batch |
| Safety hook (`guard-rm`) blocked a Bash call | sub-agent return includes error | stop batch |

Soft signals (continue):
| Signal | Action |
|---|---|
| `intervention.md` NOTE | attach to next task's dispatch prompt |
| `intervention.md` SKIP `<task-id>` | skip the named task; continue with the rest |
| `intervention.md` REDIRECT `<task-id>` | reject — REDIRECT is for stages, not tasks; convert to STOP and ask user |

## Resume semantics

`/harness-kit:harness-batch <batch-id>` is idempotent on `done` tasks:
- A task whose `Status: done` in BATCH_PLAN.md → skip.
- A task whose `Status: pending|in-progress|failed|blocked` in BATCH_PLAN.md → re-evaluate:
  - If `docs/features/<slug>/07_DELIVERY.md` exists AND is from a `DELIVERED` verdict → mark `done`, skip.
  - Else → run as if pending.

This means: user can re-invoke `/harness-batch` after fixing whatever broke; only the remaining tasks run.

## Failure modes considered

- **BATCH_PLAN.md schema drift**: the skill should validate column headers; if missing required columns, refuse to start with a clear error.
- **Slug collision with existing `docs/features/<slug>/`**: skill warns and asks user to disambiguate (a slug already-archived elsewhere is fine — slug uniqueness is per active task, not per repo history).
- **Cycle in `Depends on`**: refuse to start, point at the cycle.
- **Empty BATCH_PLAN.md**: refuse with "no tasks to run".
- **Batch interrupted mid-task**: re-run picks up the interrupted task fresh (the task's pm-orchestrator handles its own resume per task; if 07_DELIVERY.md is partial, sub-agent will re-do the missing stages).

## Test plan for QA

- **Adversarial test 1** (AC-1): construct a 2-task BATCH_PLAN.md, invoke skill, verify both tasks' pm-orchestrators get dispatched in order, BATCH_REPORT.md is written.
- **Adversarial test 2** (AC-2): inspect BATCH_LOG.md after a multi-task run — verify it contains only summary lines, not full stage doc content.
- **Adversarial test 3** (AC-3): inject a forced `verify_all` FAIL between tasks; verify batch stops immediately and writes BATCH_REPORT.md with the stop reason.
- **Adversarial test 4** (AC-4): kill a batch after task 1 completes; re-invoke; verify task 1 is skipped and task 2 runs.
- **Adversarial test 5** (AC-5): construct a plan with `T-02 Depends on T-01`; force T-01 to fail; verify T-02 is marked `blocked`, not run.
- **Adversarial test 6** (AC-7): grep all four version locations and assert they're identical; grep `verify_all.{ps1,sh}` for the harness-batch literal in C.1, G.1, G.2 arrays.
- **Adversarial test 7** (AC-10): grep CHANGELOG.md for `harness-batch` literal in the `[0.19.0]` block.

## Risks for Developer attention

- **Insight L1** — Edit reports SUCCESS without applying: after every Edit to `verify_all.{ps1,sh}`, AI-GUIDE.md, README.md, README.zh-CN.md, CHANGELOG.md, do a follow-up Grep for `harness-batch` (or the post-edit text) to confirm the change landed.
- **Insight L5 + L21** — releases miss CHANGELOG / version stamps: this change MUST update plugin.json, marketplace.json, README.md badge, README.zh-CN.md badge ALL to `0.19.0` simultaneously (G.3 enforces; failing G.3 is an instant verify_all FAIL).
- **Insight L13** — `set -u` + `declare -a foo` bash bug: not applicable; the skill is markdown only, no new bash arrays in scripts.
- **F.1 script symmetry** — every edit to `verify_all.sh` must be mirrored in `verify_all.ps1` and vice versa. C.1, G.1, G.2 lists exist in both shells; update all six locations.
