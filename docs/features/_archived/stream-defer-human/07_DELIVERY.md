# Delivery Summary

- Task: T-022 `stream-defer-human` — `/harness-stream` now DEFERS a task that needs human assistance instead of halting the whole drain: the task is set aside (new `needs-human` status, its exact ask recorded), only its `Depends on` descendants are blocked, the stream keeps draining every other runnable task, and at stream end all human-asks are surfaced together (a FIRST `## Needs your input` section in STREAM_REPORT.md + the exit chat message leads with the digest). The three hard-safety stops (verify_all FAIL / intervention STOP / guard-rm block) are UNCHANGED.
- Mode: full
- Stages traversed: 1 (RA, READY FOR DESIGN) → 2 (SA, READY FOR GATE) → 3 (Gate, APPROVED, 0 blocking / 4 advisory) → 4 (Dev, READY FOR REVIEW) → 5 (CR, APPROVED, 0 blocking / 0 major) → 6 (QA, PASS — RELEASABLE, 0 defects) → 7 (this doc). All on 2026-06-13.
- Rollbacks: 0
- Final verify_all result: **PASS** — 32/0/0 BOTH shells (bash + pwsh, QA-captured real runs; PM re-ran post-archive)
- Baseline changes: none of the counts moved (checks 32, skills 15). Regression drivers green & equal to baseline: test-init 270/308, test-real-project 90/90, test-supervisor 45/49.
- Outstanding risks:
  - m-1 (minor, **pre-existing**, not a T-022 regression): the STREAM_REPORT per-task row wording points at the archived path, but an unfinished `needs-human`/`failed`/`blocked` row isn't archived yet (archive-task runs only on delivery). Harmless — the row still renders; same gap already applied to failed/blocked rows. Optional future wording tweak.
  - DEFECT-1 from T-021 (MINOR, still backlog): `ambient-prompt.ps1` emits pre-existing non-ASCII punctuation (em-dash, `≡`) as GBK mojibake under zh-CN Windows. This task deliberately did NOT touch those chars (its new ambiguity sentence is ASCII-only) — the backlog `[Console]::OutputEncoding` fix remains the right closure.
- Files changed: 14 + this doc folder. `skills/harness-stream/SKILL.md` (199L: allowed-tools drops `AskUserQuestion`; ambient step 1 + Procedure 3a ambiguity → record-and-drain; step g third arm `BLOCKED: NEEDS-HUMAN`→`needs-human`; step d `deferred-human mode` dispatch signal; report + exit-msg lead with `## Needs your input`; Stop conditions (c)/(d) bright line; Deferred-human queue formats; Hard rule), `agents/pm-orchestrator.md` (206L: stream-aware "stop and ask" branch + new Hard rule 6), `docs/batches/_template/BATCH_PLAN.md` (Status enum +`needs-human`), `docs/batches/README.md`, `README.md` + `README.zh-CN.md` (bullet + badge + roadmap), `CHANGELOG.md` (`[0.33.0]`), `.claude-plugin/plugin.json` + `marketplace.json` (0.32.0→0.33.0), 4× `ambient-prompt.{ps1,sh}` (dogfood + template, ASCII-only ambiguity sentence, lockstep), `docs/tasks.md`, `baseline.json` (last_verify only).
- Next steps for user: optional release (tag v0.33.0 + push, then `/plugin` to update the local marketplace cache); T-021 DEFECT-1 console-encoding fix remains a good small backlog item.

## Insight

(omitted — nothing surfaced that beats a reasonable prior or isn't derivable from the codebase in <10 minutes; the needs-human/defer design reused existing best-effort + resume + lockstep mechanisms without a new failure-mode discovery)
