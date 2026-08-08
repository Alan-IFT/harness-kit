# Playbook — Supervisor (observer-only, not in the 7-stage routing)

Read by `harness-kit:supervisor` as its first action. The agent contract carries the safety rules
that must hold when this file is missing; everything below is the anti-pattern catalog, the report
schema, and the boundary table.

## Severity scheme (fixed)

| Level | Meaning |
|---|---|
| `INFO` | Observation; no action implied. Pipeline friction at normal levels. |
| `WARN` | Review recommended; potential rot signal. |
| `ALERT` | Project-level rot likely; intervention recommended. |

Distinct from `verify_all`'s `PASS/WARN/FAIL` — `ALERT` describes process rot, not script failure.

## Anti-pattern catalog

### AP-1 — Rollback rate (same stage)

For each completed task stage, count the rollbacks landing inside that stage. Walk `PM_LOG.md`
line by line: a line matching `^### Stage (\d+)` sets the current stage; a line matching
`^### Rollback` increments that stage's counter. Emit a finding for each stage whose counter is ≥2.

| Same-stage rollbacks | Severity |
|---|---|
| 0–1 | (no finding) |
| 2 | WARN |
| ≥3 | ALERT (matches the PM hard-stop threshold) |

### AP-1b — Rollback tally (cross-stage)

Orthogonal to AP-1: sum every rollback event across the entire task regardless of stage. A task with
2 rollbacks in different stages emits AP-1b INFO but no AP-1 finding.

| Total rollbacks | Severity |
|---|---|
| 0–1 | (no finding) |
| 2 | INFO (normal pipeline friction) |
| 3 | WARN (project rot signal) |
| ≥4 | ALERT (severe; warrants pausing the pipeline) |

### AP-2 — Stage-doc thinness

For each stage doc present, check both the required `## ` heading set and a stage-specific minimum
line count. This table is the single source of truth for both:

| Stage | File | Minimum lines | Required headings (must all be present) |
|---|---|---|---|
| 1 | `01_REQUIREMENT_ANALYSIS.md` | 30 | `## Goal`, `## In-scope behaviors`, `## Acceptance criteria`, `## Verdict` |
| 2 | `02_SOLUTION_DESIGN.md` | 40 | `## Overview` **or** `## Architecture summary`; `## File-level change set` **or** `## Change ledger`; `## Verdict` (architect headings vary across versions; use partial match) |
| 3 | `03_GATE_REVIEW.md` | 20 | `## Findings`, `## Verdict` |
| 4 | `04_DEVELOPMENT.md` | 30 | `## Summary`, `## Files changed`, `## verify_all result`, `## Verdict` |
| 5 | `05_CODE_REVIEW.md` | 20 | `## Findings`, `## Verdict` |
| 6 | `06_TEST_REPORT.md` | 30 | `## Adversarial tests`, `## Verdict` |
| 7 | `07_DELIVERY.md` | 15 | `## Summary`, `## Verdict` |

| Condition | Severity |
|---|---|
| Required heading missing | WARN |
| Line count below minimum | WARN |
| Both | ALERT |

A stage's optional `0N_RATIONALE.md` sibling is **outside AP-2**: you do not read it, do not count
its lines, and its absence is never a thinness signal.

### AP-3 — Missing intervention checks

`PM_LOG.md` MUST contain an "Intervention check" entry between every pair of completed stage-to-stage
transitions, per `.harness/rules/65-intervention.md` read-points.

**Scope rule (binding):** the audit operates on stage-to-stage transitions only (e.g.
`Stage 4 → Stage 5`). Round-to-round events within a single stage are explicitly NOT audited and
never count as a missing intervention check.

| Missing intervention-check entries | Severity |
|---|---|
| 0 | (no finding) |
| 1–2 | WARN |
| ≥3 | ALERT |
| `PM_LOG.md` absent or malformed | INFO only — never WARN/ALERT (prevents T-000-style false positives) |

### AP-4 — Missing archive call

If `docs/tasks.md` marks `<slug>` as Completed AND stage docs still live under
`docs/features/<slug>/` (NOT `_archived/<slug>/`), per `.harness/rules/70-doc-size.md` Rule 4.

Severity: **ALERT** (single severity — a clearly-defined rule violation). In-flight rows
(gate-review/dev/etc) never trigger AP-4.

## Entropy lens (EP-*) — a separate invocation mode

Runs ONLY when dispatched in **entropy mode** by `/harness-deflate`, by `/harness-stream` at a due
cadence boundary, or by `/harness` at a due single-task delivery boundary. The AP-* task-folder audit
is unchanged and never triggers this lens.

**What it does:** classify whole-codebase structural entropy with the deep-module vocabulary —
**EP-1 shallow module · EP-2 cross-seam leakage · EP-3 coupling cluster · EP-4 deepening candidate** —
run the deletion test on each candidate, attach a fixed strength badge
(`Strong | Worth exploring | Speculative`), and write **exactly one** artifact:
`docs/features/_supervision/entropy-<ISO-date>.md` ending in the machine-readable last line
`Entropy-verdict: FINDINGS-PRESENT | CLEAN`.

**Read-set in entropy mode (scoped widening):** you MAY Glob/Grep/Read production source read-only to
classify structure, plus the whitelisted `.harness/rejected-decisions.md` (for the decline filter);
you still write exactly one file, still have NO Edit/Bash/Task, never refactor, never dispatch, never
edit an upstream doc.

**Decline filter:** before writing the artifact, suppress any finding the user already declined per
the `## Decline filter` rule in `skills/harness-deflate/references/entropy-scan.md` (read it for the
key + match + fail-open contract — do not restate it here).

**Full method + artifact schema:** see `skills/harness-deflate/references/entropy-scan.md` (EP
classification grammar, deletion test, strength badge, the exact findings-artifact schema, determinism
+ caps, the Entropy-verdict line spec). Follow it exactly in entropy mode.

## Report schema (fixed; do not deviate)

```markdown
# Supervision Report — <slug>

> Generated <ISO-timestamp> by /harness-supervise
> Target: docs/features/<slug>/ (or _archived/<slug>/)

## Summary
- Task: <slug>
- Mode: full | plan | explore | goal
- Stages present: <list>
- Rollbacks observed: <count by stage>
- Findings: <N INFO, M WARN, K ALERT>

## Findings
| AP | Severity | Where | Detail |
|---|---|---|---|
| AP-1b | INFO | task-wide | 2 total rollbacks across different stages |

## Anti-pattern detail
### AP-1 rollback-rate (same-stage)
<paragraph + bullet list with PM_LOG.md citations>

### AP-1b rollback-rate (cross-stage)
<paragraph>

### AP-2 stage-doc-thinness
<per-stage table>

### AP-3 missing-intervention-checks
<list (if findings exist)>

### AP-4 missing-archive-call
<line (if finding exists)>

## Cross-references
- Rule fragments consulted: .harness/rules/65-intervention.md, .harness/rules/70-doc-size.md
- Insight-index entries possibly relevant: <file:line list>

## Methodology notes
<2-4 lines: what supervisor did and did not read; assumptions>

Verdict: HEALTHY | WATCH | INTERVENE
```

The verdict line is the **last non-blank line** of the file, exact regex
`^Verdict: (HEALTHY|WATCH|INTERVENE)$`. `verify_all I.7` greps for this without parsing the file.

| Findings present | Verdict |
|---|---|
| Zero WARN, zero ALERT | `HEALTHY` |
| ≥1 WARN, zero ALERT | `WATCH` |
| ≥1 ALERT | `INTERVENE` |

INFO findings alone do NOT promote the verdict above HEALTHY.

## Where to write

- Single-task active: `docs/features/<slug>/SUPERVISION_REPORT.md`
- Single-task archived: `docs/features/_archived/<slug>/SUPERVISION_REPORT.md`
- Cross-task: `docs/features/_supervision/cross-task-<ISO-date>.md` (create the folder if absent)

Always **one Write call**, then re-Read to verify (per insight-index L10 on Edit-tool false-success).

## Workflow — single-task mode

1. Resolve `<slug>` — try `docs/features/<slug>/`; if absent, try `docs/features/_archived/<slug>/`;
   if neither exists → write nothing, print `BLOCKED — task folder not found: <slug>`.
2. If `HARNESS_SUPERVISOR_MOCK` is set to a readable JSON file → load it; its `report_md` field IS the
   report body. Write it verbatim to the destination, re-Read, exit. (CI / dry-run path.)
3. Read the present files: `PM_LOG.md`, `0[1-7]_*.md` **excluding `*_RATIONALE.md`**, `docs/tasks.md`,
   `.harness/rules/65-intervention.md`, `.harness/rules/70-doc-size.md`. **Query**
   `.harness/insight-index.md` with `Grep` and an explicit `path` rather than reading it whole. No
   other reads.
4. Run the AP-1, AP-1b, AP-2, AP-3, AP-4 detectors. Collect findings with severity.
5. Compose the report per the schema. Write once. Re-Read to confirm.
6. Print a 3-line summary: report path, verdict, finding count.

## Workflow — cross-task mode

1. Glob `docs/features/_archived/*/07_DELIVERY.md`, sort by mtime descending.
2. `--recent N` takes the first N (clamp `[1, available]`; INFO-log the clamp).
3. `--all` is equivalent to N = count of archived tasks.
4. For each task, read ONLY `07_DELIVERY.md` + `PM_LOG.md` — not all 7 stage docs.
5. Run AP-1..AP-4 per task; aggregate.
6. Aggregate rule: any AP-N appearing in ≥3 of N tasks → an ALERT-level aggregate row.
7. Write to `docs/features/_supervision/cross-task-<ISO-date>.md`. Cap 300 lines.

## Boundary conditions

| Situation | Behavior |
|---|---|
| Task folder absent (both paths) | `BLOCKED — task folder not found`; no report written; exit 0 |
| Empty task folder | Report with `Verdict: HEALTHY` and one INFO finding "pipeline has not started" |
| Mid-pipeline (some stage docs absent) | Absence of a doc is NOT itself a finding unless `docs/tasks.md` marks the stage completed |
| Slug exists in both active and archived | Prefer active; INFO finding about the duplicate |
| `PM_LOG.md` absent or malformed | AP-1, AP-1b, AP-3 emit `INFO — PM_LOG.md absent or unparseable` only; AP-2, AP-4 still run |
| `HARNESS_SUPERVISOR_MOCK` set but unreadable | Fall back to live detection; log `[MOCK-FALLBACK] unreadable: <path>` to stdout |
| Cross-task `N=0` or `archived-count == 0` | One-line report `Verdict: HEALTHY` + INFO "no archived tasks"; no clamp |
| Cross-task `N > archived-count` (with `archived-count >= 1`) | Clamp `N` down to `archived-count`; INFO-log the clamp |
| Report exceeds 200 lines | Include a `(report truncated: 200-line cap hit)` note in `## Methodology notes`; do NOT fail |

## Out of scope

- Editing any `0[1-7]_*.md`, `PM_LOG.md`, production code, agent contracts, rule fragments,
  `docs/tasks.md`.
- Calling any agent, dispatching any sub-task, writing `.harness/intervention.md`.
- Auto-rollback, auto-advance, or modifying PM routing.
- Real-time / streaming observation. You run on demand only.
- ML / trend extrapolation. Thresholds are static, declared above.
- Alert delivery (email, webhook). File-on-disk only.

## Calibration

Findings reference exact line numbers in `PM_LOG.md` or the stage docs. INFO/WARN/ALERT are used per
the ladder, not by mood. The verdict matches the findings — no `WATCH` while an ALERT stands. The
report stays ≤200 lines and its methodology notes are honest about what was and was not read.
