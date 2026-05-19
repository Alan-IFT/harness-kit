# 01 — Requirement Analysis · sample-task

Synthetic fixture. Demonstrates a HEALTHY task: every required section is present and the line count exceeds the AP-2 minimum (30).

## Goal

Provide a deterministic, anti-pattern-free task folder for `/harness-supervise` regression testing.

## User stories

1. As a test, I want the supervisor to emit `Verdict: HEALTHY` on this folder so I can pin the negative-control fixture.

## In-scope behaviors

- All seven stage docs present.
- PM_LOG has zero rollbacks and an intervention-check entry between every pair of completed stages.
- No archive drift (this fixture is intentionally NOT marked Completed in any tasks.md).

## Out-of-scope (explicit non-goals)

- Real semantic content.
- Cross-task aggregation; covered by separate fixtures.

## Boundary conditions

- Task is fictitious; supervisor must not consult production code.

## Acceptance criteria

- **AC-fix-1**: supervisor emits `Verdict: HEALTHY` against this folder.
- **AC-fix-2**: zero WARN, zero ALERT findings.

## Non-functional requirements

- Fixture stays ≤ 200 lines.

## Risks

- None — this is a static fixture.

## Verdict

READY.
