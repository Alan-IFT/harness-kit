---
name: harness-supervise
description: Manually-invoked observer skill. Reads an in-flight or archived 7-stage task folder (or last-N archived tasks) and emits a SUPERVISION_REPORT.md flagging anti-patterns with INFO/WARN/ALERT severity and a final HEALTHY/WATCH/INTERVENE verdict. Never edits upstream docs.
allowed-tools: Read, Write, Glob, Grep
---

# /harness-supervise

A manually-invoked, observer-only skill that runs the **supervisor agent** (defined at `.harness/agents/supervisor.md`) against one or more task folders and writes a single `SUPERVISION_REPORT.md`. Detects four anti-patterns (AP-1 same-stage rollbacks, AP-1b cross-stage rollback tally, AP-2 stage-doc thinness, AP-3 missing intervention checks, AP-4 missing archive call) with fixed thresholds; emits `Verdict: HEALTHY | WATCH | INTERVENE` on the last non-blank line of the report.

This is **purely informational** — the PM never auto-acts on findings. Supervisor is **not** part of the canonical 7-stage routing.

## Argument shapes

| Shape | Meaning |
|---|---|
| `/harness-supervise <task-slug>` | Single-task mode. Resolve `<slug>` at `docs/features/<slug>/`; fall back to `docs/features/_archived/<slug>/`. |
| `/harness-supervise --recent <N>` | Cross-task mode. Run on the last N archived tasks (by mtime of `07_DELIVERY.md`). N clamped to `[1, archived-count]`. |
| `/harness-supervise --all` | Cross-task mode for every archived task. Use sparingly on large projects (NFR-2). |

## Tools

`allowed-tools: Read, Write, Glob, Grep` — `Edit`, `Bash`, `PowerShell`, `Task`, `AskUserQuestion` are physically excluded (NFR-4). The skill physically cannot edit upstream docs, run scripts, dispatch other agents, or prompt the user.

## Procedure

### Step 1 — Adopt the supervisor role

Read `.harness/agents/supervisor.md`. Follow its workflow, hard rules, and report schema verbatim.

### Step 2 — Resolve the target(s)

**Single-task mode** (`<task-slug>` argument):

1. Test for `docs/features/<slug>/`. If present → active path.
2. Else test for `docs/features/_archived/<slug>/`. If present → archived path.
3. If neither exists → print `BLOCKED — task folder not found: <slug>`. Exit without writing.

**Cross-task mode** (`--recent <N>` or `--all`):

1. Glob `docs/features/_archived/*/07_DELIVERY.md`, sort by mtime descending.
2. `--recent N`: take the first N entries. If N > available, clamp to `archived-count` and emit an INFO finding noting the clamp. If N ≤ 0, clamp to 1.
3. `--all`: use every archived task.

### Step 3 — Mock-fixture shortcut (CI / dry-run)

If env var `HARNESS_SUPERVISOR_MOCK` is set:

1. Test the path is readable. If not, log `[MOCK-FALLBACK] unreadable: <path>` to stdout and proceed with live detection.
2. If readable, parse as JSON; extract the `report_md` string field.
3. Write `report_md` verbatim to the destination path. Re-Read to confirm. Exit.

This path bypasses all anti-pattern detection. Used by `.harness/scripts/test-supervisor` for offline regression coverage.

### Step 4 — Read inputs

For each target task folder, read **only**:

- `PM_LOG.md`
- `0[1-7]_*.md` (each if present)
- `.harness/insight-index.md`
- `docs/tasks.md`
- `.harness/rules/65-intervention.md`
- `.harness/rules/70-doc-size.md`

In cross-task mode, read **only** `07_DELIVERY.md` + `PM_LOG.md` per task (NFR-2 token budget). Do NOT read production source code, other tasks' stage docs, or any file outside this whitelist.

### Step 5 — Run anti-pattern detectors

Per the contract in `supervisor.md` §"Anti-pattern catalog":

- AP-1 same-stage rollback ladder (0–1 none / 2 WARN / ≥3 ALERT)
- AP-1b cross-stage tally (2 INFO / 3 WARN / ≥4 ALERT)
- AP-2 stage-doc thinness (missing heading / under min lines → WARN; both → ALERT)
- AP-3 missing intervention checks (1–2 WARN / ≥3 ALERT; absent PM_LOG → INFO only)
- AP-4 missing archive call (single ALERT)

Findings are deterministic given the same inputs (NFR-5).

### Step 6 — Compose the report

Use the schema declared in `supervisor.md` §"Report schema". The verdict line is the last non-blank line:

| Findings | Verdict |
|---|---|
| 0 WARN, 0 ALERT | `Verdict: HEALTHY` |
| ≥1 WARN, 0 ALERT | `Verdict: WATCH` |
| ≥1 ALERT | `Verdict: INTERVENE` |

INFO findings alone do NOT promote the verdict above HEALTHY.

### Step 7 — Write the report

**Exactly one Write call.**

- Single-task active: `docs/features/<slug>/SUPERVISION_REPORT.md`
- Single-task archived: `docs/features/_archived/<slug>/SUPERVISION_REPORT.md`
- Cross-task: `docs/features/_supervision/cross-task-<ISO-date>.md` (create folder if missing)

After Write, Re-Read the file to verify the contents landed (per insight-index L10 — Edit tool occasionally reports SUCCESS without applying the change). If the re-Read mismatches, retry the Write once; if still failing, report a BLOCKED state.

### Step 8 — Print summary

Print 3 short lines to stdout:

```
report:  <path>
verdict: <HEALTHY|WATCH|INTERVENE>
findings: <N INFO, M WARN, K ALERT>
```

## Doc-size caps

- Single-task `SUPERVISION_REPORT.md` ≤ 200 lines (matches rule-fragment cap).
- Cross-task `cross-task-<date>.md` ≤ 300 lines (matches per-task stage-doc cap).

If you cannot fit findings under the cap, emit a single `(report truncated: 200-line cap hit)` note in `## Methodology notes` rather than dropping findings silently.

## Boundary conditions

| Situation | Behavior |
|---|---|
| Task folder absent in both active + archived | BLOCKED; no report written |
| Empty task folder | Report `Verdict: HEALTHY`; one INFO "pipeline has not started" |
| Mid-pipeline (some stage docs absent) | Absence is not a finding unless `docs/tasks.md` marks the stage completed |
| Slug present in both active and archived | Prefer active; INFO finding about duplicate |
| `PM_LOG.md` absent / malformed | AP-1, AP-1b, AP-3 emit INFO only; AP-2, AP-4 still run |
| Concurrent supervisor runs on same slug | Second invocation overwrites first's report; documented behavior |
| Cross-task with 0 archived tasks | Write one-line report `Verdict: HEALTHY` + INFO "no archived tasks" |

## Anti-patterns (in skill use)

- **Don't auto-run from PM.** The supervisor is on-demand only in v0.17.0; auto-dispatch is reserved for v0.18+ once false-positive budget is proven against ≥10 real tasks.
- **Don't read production code.** NFR-2 caps the read set. If a finding needs deeper analysis, surface it as a methodology note pointing the human at the right file, do not read it yourself.
- **Don't write to any path other than the destination report.** No edits to upstream docs, no `.harness/intervention.md`, no `docs/tasks.md` updates.
- **Don't promote findings above their ladder.** INFO does not become WARN because it "feels worse"; thresholds are fixed in `supervisor.md`.
- **Don't omit the verdict line.** `verify_all I.7` reads the last 5 lines for `^Verdict: (HEALTHY|WATCH|INTERVENE)$`. A missing or malformed verdict line breaks the passive guard.

## Relationship to verify_all I.7

`.harness/scripts/verify_all` gained a passive guard (`I.7`) in v0.17.0: it Globs every `docs/features/<slug>/SUPERVISION_REPORT.md`, reads the last 5 lines, and emits a WARN if `Verdict: INTERVENE` appears AND the task is still listed as Active in `docs/tasks.md` AND the file mtime is > 48h old. This catches "user ran supervisor, got ALERT, ignored it" rot.

The supervisor itself does not trigger or interact with `I.7`; it just writes the file that `I.7` later observes.
