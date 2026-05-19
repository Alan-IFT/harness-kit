# 02 — Solution Design · sample-task

Synthetic fixture. Above AP-2 minimum (40 lines).

## Overview

Deterministic fixture used by `/harness-supervise` regression. Mirrors the canonical shape of a clean 7-stage task folder.

## Architecture / Module decomposition

| Unit | Kind | Responsibility |
|---|---|---|
| `PM_LOG.md` | fixture | Zero rollbacks; 6 intervention checks |
| `01..07_*.md` | fixture | Minimal-but-valid stage docs |

## Decisions log

| # | Decision | Rationale |
|---|---|---|
| F-1 | Keep each doc just above the AP-2 minimum | Tests the floor, not the ceiling |
| F-2 | Zero rollbacks | Negative control for AP-1 / AP-1b |
| F-3 | Six intervention checks | Negative control for AP-3 |

## File-level change set

| Status | Path | Note |
|---|---|---|
| A | `PM_LOG.md` | HEALTHY baseline |
| A | `01..07_*.md` | Stage stubs |

## Reuse audit

Reuses the schema documented in `.harness/agents/supervisor.md` §"Anti-pattern catalog". No production code referenced.

## Detailed flow

The supervisor reads this folder, runs AP-1..AP-4, finds nothing, emits `Verdict: HEALTHY`.

## Data shapes / file contracts

None — fixture is read-only.

## Error handling / fallback

If supervisor cannot read this folder, the test fixture is broken — not a supervisor bug.

## Verdict

READY FOR GATE REVIEW.
