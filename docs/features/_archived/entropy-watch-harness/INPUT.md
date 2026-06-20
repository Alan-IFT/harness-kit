# Task Input — entropy-watch-harness (T-11b)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** T-11a (DELIVERED — the entropy-cadence pair, supervisor entropy lens, and `## Entropy watch` surfacing pattern already exist).

## Goal (one sentence)

Add the `/harness` single-task **delivery-boundary** surface that calls the SAME shared `entropy-cadence` remind-if-due check T-11a built — so the anti-entropy reminder fires from BOTH `/harness-stream` (already done in T-11a) AND `/harness` (this slice), completing the operator's "harness 和 harness-stream 中自动定期巡检".

## Origin & rationale

T-11a shipped the anti-entropy watch core but wired the auto-surface only into `/harness-stream`'s pool-drain boundary. The operator explicitly wants it in BOTH `/harness` and `/harness-stream`. This slice is pure WIRING — it reuses everything T-11a built (the `entropy-cadence.{ps1,sh}` pair, the read-only supervisor entropy lens, the `## Entropy watch` surfacing shape). No new scan engine, no new skill, no new state.

## Scope guidance (for the analyst — REUSE, keep DRY, lightweight)

In scope: wire the shared remind-if-due check into the `/harness` single-task completion boundary — at stage-7 Delivery, increment the cadence counter (`entropy-cadence delivered`), then `entropy-cadence check`; if DUE, run the supervisor entropy scan and surface a `## Entropy watch` reminder in the delivery summary + `entropy-cadence swept`. Determine the single cleanest wiring point so it stays DRY (the `/harness` SKILL.md delivery section and/or `agents/pm-orchestrator.md` stage-7 — pick ONE authoritative home; if both need a line, one must reference, not duplicate, the other). Non-blocking (never gates/halts delivery).

Out of scope (unless analyst argues with evidence): a new scan engine / skill / state file (all reused from T-11a); changing the cadence formula or threshold (shared, single-source in entropy-cadence); the `--first-of-session` flag (that is the stream-drain trigger; `/harness` single-task uses the plain counter `check`, but the analyst confirms); findings persistence (that is T-11c); any new verify_all check.

## Insights to honor (verify before relying)

- The shared check is `entropy-cadence.{ps1,sh}` (CLI `check`/`delivered`/`swept`, fail-open). REUSE it — do not re-implement cadence logic. Both surfaces share `.harness/entropy-watch.state`, so the counter is unified across `/harness` and `/harness-stream`.
- DRY / single-source-of-truth (T-04 handle): the `## Entropy watch` surfacing prose + the cadence-call sequence should live in ONE place both the stream and harness point at, OR be a tight repeated 2-line call (the surfacing TEXT format already defined in T-11a's stream wiring / the harness-deflate references) — do not fork a second divergent description.
- Editing distributed skill/agent content → version bump (current 0.41.0 → likely 0.42.0); NO count flip (no new skill; 17 skills / 8 agents / 32 checks stay). Confirm.
- I.3 caps: pm-orchestrator.md (~209 after T-05) ≤300; harness SKILL.md cap n/a but keep terse. Non-blocking — the harness pipeline's hard-stops/gates are unchanged.
- I.6 guard; PS denied to sub-agents (PM runs PS-side).
- Read the live T-11a wiring in `skills/harness-stream/SKILL.md` (`## On stream completion` / `## Entropy watch`) to mirror the shape exactly for the `/harness` path.
