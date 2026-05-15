---
name: harness-status
description: Show the current Harness health of this project - which assets are present, the baseline state, the last verify result, and recent task progress. Use to get a quick snapshot.
allowed-tools: Read, Glob, Bash, PowerShell
---

# /harness-status

A one-page snapshot of Harness state in the current project.

## Procedure

Check each of these and report concisely:

### 1. Required assets

| Asset | Path | Present? |
|---|---|---|
| Project rules | `CLAUDE.md` | ? |
| Workflow definition | `docs/workflow.md` | ? |
| Task board | `docs/tasks.md` | ? |
| Dev map | `docs/dev-map.md` | ? |
| Spec folder | `docs/spec/` | ? |
| All 7 agents | `.claude/agents/{pm,req,sol,gate,dev,review,qa}*.md` | ? |
| Build skill | `.claude/skills/build/SKILL.md` | ? |
| Test skill | `.claude/skills/test/SKILL.md` | ? |
| Verify skill | `.claude/skills/verify/SKILL.md` | ? |
| verify_all script | `scripts/verify_all.ps1` or `.sh` | ? |
| Baseline | `scripts/baseline.json` | ? |
| Golden tasks | `evals/golden-tasks.md` | ? |

### 2. Baseline state

If `scripts/baseline.json` exists, print:

```
Baseline:
  version:        1
  created:        2026-05-15
  test_count:     369
  passing_count:  369
  last_updated:   2026-06-01
```

### 3. Last verify result

If `scripts/verification_history.log` exists, show the most recent entry:

```
Last verify: 2026-06-01T14:32:11Z
  PASS: 11
  WARN: 1
  FAIL: 0
  Result: PASSED WITH WARNINGS
```

### 4. Active tasks

Read `docs/tasks.md` and list any task whose stage is not `done` or `delivery`:

```
Active tasks:
  T-007  csv-export-orders       stage=dev
  T-008  fix-login-redirect      stage=review
```

### 5. Recently completed (last 5)

From `docs/tasks.md`, list the last 5 `done` tasks with date.

### 6. Health score

Compute a quick score:

- All 12 required assets present → +6 health points
- Baseline exists and is recent (< 30 days) → +2
- Last verify PASS → +2
- No active tasks blocked > 3 days → +1
- Total possible: 11

Report as e.g. `Health: 9/11 — minor gaps in dev-map and evals.`

### 7. Suggestions

If anything is missing, list concrete next steps:

```
Recommendations:
  - docs/dev-map.md is missing; run /harness-init or write one manually.
  - Last verify was 14 days ago; run /harness-verify.
  - Task T-007 has been at 'dev' for 5 days; PM should check in.
```

## Anti-patterns

- Don't run verify_all here; this is read-only status. Use `/harness-verify` if you want a fresh run.
- Don't suggest changes to assets; just report state and gaps.
- Don't fabricate counts if files are missing — report "missing", not "0".
