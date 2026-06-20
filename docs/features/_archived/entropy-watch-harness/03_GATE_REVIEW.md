# 03 — Gate Review · T-11b entropy-watch-harness

> Stage 3 (Gate Reviewer). Mode: full. deferred-human: defer. Persisted by PM (gate-reviewer read-only).
> Upstream: 01 READY · 02 READY. Verify-don't-trust; live files read.

## Audit (8 dims)
1 Requirement completeness PASS · 2 Design completeness PASS (insertion point pm-orchestrator L193-194 → before L196 verified) · 3 Reuse correctness PASS (entropy-cadence pair, supervisor entropy mode, references/entropy-scan.md verdict-line spec L56-58, stream `### Entropy watch` shape — all exist + correctly characterized) · 4 Risk coverage **WARN** (design §9 missed 2 doc-drift surfaces → F-1/F-2) · 5 Migration safety PASS · 6 Boundary handling PASS · 7 Test feasibility PASS · 8 Out-of-scope clarity PASS.

## Targeted checks
1. **DRY — CONFIRMED.** One home (pm-orchestrator stage-7); harness SKILL step 10 = pointer only (no dup prose); scan single-sourced via references/entropy-scan.md (not forked); cadence/N=5 single-sourced in entropy-cadence (not restated). Both edited prose files carry NO count claims → no count-flip risk. AC-5 grep-verifiable.
2. **Goal-mode guard — CONFIRMED UNAMBIGUOUS.** stage-7 reached by full+goal (live modes table L42-45); design guards to `full` ONLY, guard = FIRST sentence of §6a, reads the `mode` PM already holds. Goal exit skips, full exit fires.
3. **Call sequence — CONFIRMED.** delivered → plain check (NO --first-of-session) → if DUE: supervisor scan + `## Entropy watch` to 07_DELIVERY + swept; placed BEFORE archive-task (section archived). Non-blocking/fail-open; existing gates untouched.
4. **No regression/scope — CONFIRMED.** No new script/skill/state. 0.41.0→0.42.0 verified live at plugin.json L4 / marketplace.json L17 / README.md L5 / README.zh-CN.md L5 / CHANGELOG [0.41.0] L8. No count flip (edited files have no 17/8/32 claims). No new check (G.4 last, untouched). pm-orchestrator 209→~239 ≤300.
5. **I.6 clean** (banned list = CLAUDE.md-composition/zh-policy only; new prose none; stage docs in exempt dir). **Cross-shell n/a** (entropy-cadence pair untouched).

## Findings (2 WARN — non-blocking doc-accuracy conditions, fold into dev)
- **F-1:** `agents/supervisor.md` enumerates entropy-mode dispatchers as exactly two ("invoked **only** via /harness-deflate or a due /harness-stream drain" — L23/L134/L137). This slice adds a 3rd (/harness single-task delivery). NOT gate-enforced (test-supervisor asserts AP-ids/severity/tools/≤300, not the dispatcher enumeration). **Condition:** update supervisor.md L23/L134/L137 to name the /harness delivery boundary as a 3rd dispatcher (~3-token edit).
- **F-2:** `docs/dev-map.md` L174 (and L103) say the cadence is "called by `/harness-stream` (and later `/harness`)" — "(and later)" goes stale on ship. **Condition:** drop "(and later …)" so the map reflects shipped state.
Both = the same "sweep all surfaces that enumerate the dispatcher set" discipline (the design §2 affected-modules table omitted them). Neither trips verify_all/test-supervisor → coding proceeds; dev folds both in, PM confirms at delivery.

## Verdict
**APPROVED FOR DEVELOPMENT** (with conditions F-1, F-2). Sound, DRY, correctly scoped: one home + one pointer, scan+cadence reused, goal-guard unambiguous, sequence correct + pre-archive, non-blocking, 0.42.0 ×4 + CHANGELOG, no count flip, no new check, ≤300, I.6 clean. Fold F-1/F-2 (both ~3-token doc edits) into this slice.
