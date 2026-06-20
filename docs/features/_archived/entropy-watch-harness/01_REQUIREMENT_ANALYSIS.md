# 01 — Requirement Analysis · T-11b `entropy-watch-harness`

- Task: Wire the anti-entropy cadence reminder into the `/harness` single-task delivery boundary, reusing the entire T-11a core.
- Mode: full
- Verdict: **READY**
- Depends on: T-11a (DELIVERED v0.41.0 — `entropy-cadence.{ps1,sh}`, the read-only supervisor entropy lens, `references/entropy-scan.md`, and the `## Entropy watch` surfacing shape all exist).

---

## 1. Goal

Make the cadenced anti-entropy reminder fire at the end of a single-task `/harness` run (in addition to `/harness-stream`, already wired in T-11a) by calling the SAME shared `entropy-cadence` remind-if-due unit at the stage-7 delivery boundary, surfacing a `## Entropy watch` section in the delivery summary when the sweep is due.

---

## 2. In-scope behaviors (numbered, testable)

1. At the `/harness` stage-7 delivery boundary, after the task reaches a DELIVERED outcome (stage 6 passed, `07_DELIVERY.md` written, final `verify_all` is not FAIL), the cadence counter is incremented by exactly one call to `.harness/scripts/entropy-cadence delivered`. Exactly one increment per delivered single task.
2. Immediately after the increment, the boundary calls `.harness/scripts/entropy-cadence check` (the plain counter form, WITHOUT `--first-of-session`) and reads the one-line stdout `DUE` or `NOT-DUE`.
3. On `NOT-DUE` (or any error / missing output — fail-open per the cadence contract), the delivery proceeds unchanged: no supervisor scan runs, no `## Entropy watch` section is written, no entropy digest is added to the delivery report. The run is otherwise identical to today's `/harness`.
4. On `DUE`, the boundary dispatches the read-only supervisor entropy lens ONCE via the Task tool in entropy mode, with the dispatch prompt naming the shared scan source `skills/harness-deflate/references/entropy-scan.md` and the artifact path `docs/features/_supervision/entropy-<ISO-date>.md` — identical scan dispatch to the one `/harness-stream` and `/harness-deflate` use (the scan methodology + artifact schema are NOT restated at this boundary; they remain single-sourced in `references/entropy-scan.md`).
5. On `DUE`, after the scan artifact is produced, a `## Entropy watch` section is appended to `07_DELIVERY.md`: the findings table (or `None.` when the artifact's verdict line reads `CLEAN`), a link to the entropy artifact, and a note that deepening a finding is opt-in via `/harness-deflate` (authorize → `/harness-goal`). The `/harness` delivery itself never runs a refactor.
6. On `DUE`, after the section is written, the cadence is reset by exactly one call to `.harness/scripts/entropy-cadence swept` (resets the counter to 0 and stamps last-sweep), so the same delivery boundary does not re-trigger.
7. The entropy watch at the `/harness` boundary is NON-BLOCKING: it never changes the task's delivery verdict, never gates or halts the pipeline, and never converts an informational sweep into a stop. The existing stage gates and hard-stops (stage-3 gate, the stage-5/6 pass-before-delivery gate, `verify_all` PASS-before-done, `guard-rm`) are unchanged.
8. The cadence call sequence and `## Entropy watch` surfacing prose for the `/harness` boundary live in exactly ONE authoritative home (see §6 wiring decision); the OTHER surface that needs a touch carries only a one-line REFERENCE pointing at that home — no second divergent copy of the call-sequence or surfacing prose is created.
9. The shared `.harness/entropy-watch.state` is the same single state file both `/harness` and `/harness-stream` read and write, so the deliveries-since-sweep counter is unified across the two surfaces (a delivery via either surface advances the same counter; a sweep via either resets it).
10. The version is bumped `0.41.0` → `0.42.0` (editing distributed skill/agent content). No skill / agent / check count changes: 17 skills, 8 agents, 32 checks stay; the count claims are NOT flipped.

---

## 3. Out-of-scope (explicitly NOT in this iteration)

1. A new scan engine, new skill, or new state file — all reused from T-11a.
2. Changing the cadence formula, the threshold literal (N=5), or the fail-open contract — these are single-sourced in `entropy-cadence` and not touched.
3. Using `--first-of-session` at the `/harness` boundary — that flag is the stream's drain-boundary trigger; `/harness` uses the plain counter `check` (confirmed in §5 / OQ-1).
4. Findings persistence, decline-tracking, or any wiring to `.harness/rejected-decisions.md` — that is T-11c.
5. Any new `verify_all` check, and any change to the existing 32 checks' logic.
6. Wiring the surface into the lighter modes (`/harness-plan`, `/harness-explore`, `/harness-goal`, `/harness-batch`) — out of scope; this slice is the single-task `/harness` delivery boundary only. (`/harness-goal` ends at stage 7 too; whether it shares the boundary is OQ-3, defer-recommended NO.)
7. Re-running or modifying the stream's existing T-11a entropy-watch block — it stays exactly as shipped.

---

## 4. Boundary conditions

- **Counter at 0 / fresh state file absent:** `delivered` creates/initializes the state (fail-open); after the increment the count is ≥1. With plain `check` (no `--first-of-session`), a single delivery brings the count to 1, which is below N=5, so `check` returns `NOT-DUE` — the first few single-task deliveries do NOT trigger a sweep (correct: the plain check is counter-only).
- **State file malformed / unreadable / unwritable / no repo root:** the cadence unit fails open — `check` resolves to `NOT-DUE`, `delivered`/`swept` emit a stderr note and exit 0. The `/harness` delivery proceeds normally; no sweep, no section.
- **Count exactly at threshold (count reaches N=5 after the increment):** `check` returns `DUE`; the sweep runs once, the section is written, `swept` resets to 0.
- **Task does NOT reach DELIVERED (blocked / failed / needs-human, or stages 5/6 did not both pass):** no `delivered` increment, no `check`, no sweep — the cadence boundary only fires on a delivered single task (mirrors the stream, which counts only `DELIVERED`).
- **Scan artifact missing or unreadable on a `DUE` run (supervisor produced nothing):** non-blocking — the `## Entropy watch` section is omitted or notes the scan was unavailable, and `swept` still resets so the boundary does not wedge; the delivery verdict is unchanged. (Exact degraded-section text is a design choice for SA.)
- **Concurrency:** single-task `/harness` is one sequential pipeline; the boundary fires once at the end of one task. Cross-surface concurrency (a `/harness-stream` running simultaneously) is out of scope — the shared state file is last-writer-wins and fail-open, consistent with T-11a's existing behavior; this slice introduces no new concurrency requirement.
- **Empty findings (`CLEAN`):** the section reads `None.` (plus the artifact link), exactly as the stream's `CLEAN` path.

---

## 5. Acceptance criteria (verifiable)

- **AC-1:** On a `/harness` delivery with the shared counter below threshold, no supervisor scan is dispatched and `07_DELIVERY.md` contains no `## Entropy watch` section. (Behavioral: deliver one task from a fresh/low state; assert absence.)
- **AC-2:** On a `/harness` delivery where the increment brings the shared counter to ≥ N, a single supervisor entropy-mode dispatch occurs, exactly one entropy artifact is produced, `07_DELIVERY.md` gains a `## Entropy watch` section (findings table or `None.` + artifact link + opt-in `/harness-deflate` note), and `swept` resets the counter to 0. (Behavioral: prime the shared state to N-1, deliver one task, assert the section + reset.)
- **AC-3:** The `/harness` boundary calls `entropy-cadence check` WITHOUT `--first-of-session` (the plain counter check), distinct from the stream's `check --first-of-session`. (Verifiable by reading the authoritative wiring home: the invocation carries no `--first-of-session`.)
- **AC-4:** The entropy watch never changes the delivery verdict and never halts the pipeline — a `DUE` sweep on a delivered task still reports DELIVERED; a fail-open cadence error still delivers. (Behavioral: force a cadence error / a `DUE` with findings; assert the delivery completes unchanged.)
- **AC-5 (DRY):** The cadence call-sequence + `## Entropy watch` surfacing prose for `/harness` exist in exactly ONE home; the other touched surface contains only a single referencing line and zero duplicated call-sequence/surfacing text. (Verifiable by grep: the 3-step call sequence and the section-format prose appear once; the second surface's mention is a pointer.)
- **AC-6 (counts + version):** `.claude-plugin/plugin.json` reads `0.42.0`; the 17-skills / 8-agents / 32-checks claims are unchanged anywhere; no new `verify_all` check is added; `verify_all` PASSes (32/32) on both shells. (Verifiable: version diff + count-claim grep + `verify_all` run.)
- **AC-7:** The shared counter is unified — a delivery via `/harness` advances the same `.harness/entropy-watch.state` that `/harness-stream` reads, and a sweep via either resets it. (Behavioral: deliver via `/harness`, read state, confirm the count advanced in the one shared file.)

---

## 6. Wiring decision (the single cleanest, DRY home)

**Recommended authoritative home: `agents/pm-orchestrator.md`, the "What to write at delivery (stage 7)" section.**

Rationale (behavioral, no design prescription):
- Stage 7 is owned by the PM in BOTH `/harness` SKILL.md (step 10: "PM does this directly") and `pm-orchestrator.md` ("What to write at delivery (stage 7)"). The pm-orchestrator already owns the delivery mechanics that this slice extends — composing `07_DELIVERY.md`, updating `docs/tasks.md`, running `archive-task`. The entropy-watch call sequence belongs next to those steps, at the same boundary, in the agent that actually executes them.
- `/harness` SKILL.md step 10 is the thinner, user-facing restatement of the same delivery; it gets ONE referencing line ("at delivery, the PM also runs the cadenced entropy watch — see `pm-orchestrator.md` stage 7") and no duplicated prose. This satisfies the DRY rule (in-scope #8 / AC-5): one authoritative home, one pointer.
- The supervisor scan dispatch (methodology + artifact schema) continues to point at the shared `skills/harness-deflate/references/entropy-scan.md`, exactly as the stream and `/harness-deflate` already do — so the SCAN definition is not forked either. The only NEW prose is the 3-step cadence call sequence (`delivered` → `check` → if DUE: scan + `## Entropy watch` + `swept`) plus the section-format description, written once in pm-orchestrator stage 7.
- This keeps the change inside the I.3 size cap: pm-orchestrator.md (~209 lines) is well under the 300 cap; a compact stage-7 addition + a one-line SKILL.md pointer fits.

The stream's existing `### Entropy watch (cadenced, non-blocking)` block in `skills/harness-stream/SKILL.md` is NOT a verbatim-reusable single source for `/harness` (it is bound to `STREAM_REPORT.md`, the needs-input lead-ordering, and `--first-of-session`). The genuinely shared single sources are: (a) the `entropy-cadence` pair for cadence logic, and (b) `references/entropy-scan.md` for the scan — both already reused. The `/harness` boundary's own prose is therefore minimal and new, homed in pm-orchestrator stage 7.

---

## 7. Non-functional requirements (only the material ones)

- **NFR-1 (non-blocking / fail-open):** No cadence I/O or scan dispatch may block, gate, or alter a `/harness` delivery. Any cadence error resolves to NOT-DUE; a `DUE` sweep is informational only. (Inherits the T-11a fail-open contract.)
- **NFR-2 (cross-shell symmetry):** The boundary invokes `.harness/scripts/entropy-cadence` via the existing shell-agnostic launcher pattern (the `.ps1`/`.sh` pair is already byte-symmetric); no shell-specific behavior is introduced at the wiring layer.
- **NFR-3 (size cap):** pm-orchestrator.md stays ≤ 300 lines (I.3); the addition is compact.

---

## 8. Related tasks

- **T-11a `entropy-watch`** (DELIVERED v0.41.0, `docs/features/_archived/entropy-watch/`) — built the entire core this slice reuses: the `entropy-cadence` pair, the supervisor entropy lens, `references/entropy-scan.md`, and the `## Entropy watch` surfacing pattern wired into the stream. This slice mirrors that shape for `/harness`.
- **T-11c (queued)** — findings persistence / decline-tracking; explicitly out of scope here.
- **T-03 `harness-grill`** (`docs/features/_archived/harness-grill/`) — the 16→17 skill fan-out + the decoy-set discipline; relevant because this slice must confirm NO count flip (17/8/32 stay).
- **T-05 `durable-brief`** (`docs/features/_archived/durable-brief/`) — the forward-only behavioral-brief rule this spec follows (no forward file:line in the requirement).

---

## 9. Open questions (each with a recommended answer; deferred-human mode — recommend, do not block)

1. **`--first-of-session` at the `/harness` boundary?**
   (a) Use the plain `check` (counter-only) — RECOMMENDED. `--first-of-session` exists to make a long-idle STREAM pool with ≥1 delivery due at the start of a drain; a single-task `/harness` run has no "session-drain" semantics, so the plain counter is the correct trigger. This is the INPUT's stated default and matches the cadence-unit comments.
   (b) Use `check --first-of-session` so any first `/harness` run after an idle period with ≥1 prior delivery surfaces a sweep. Rejected: would surface a sweep on nearly every isolated `/harness` invocation, defeating the cadence's "every N deliveries" intent.
   **Recommended: (a).**

2. **Authoritative wiring home: pm-orchestrator stage 7 vs `/harness` SKILL.md step 10?**
   (a) Home in `pm-orchestrator.md` stage 7; SKILL.md step 10 references it — RECOMMENDED (see §6). The PM agent owns the delivery mechanics this extends.
   (b) Home in `/harness` SKILL.md step 10; pm-orchestrator references it. Rejected: the SKILL.md is the thin user-facing restatement; the executable delivery steps (07_DELIVERY, tasks.md, archive-task) live in pm-orchestrator, so the call sequence is more natural there and less likely to drift.
   **Recommended: (a).**

3. **Does `/harness-goal` (which also ends at stage 7) share this boundary?**
   (a) NO — scope this slice to `/harness` (full mode) only; `/harness-goal` is out of scope per the INPUT — RECOMMENDED. Keeps the slice minimal; goal mode's loop semantics can be evaluated separately if desired.
   (b) YES — wire goal-mode stage-7 delivery too, since it shares pm-orchestrator stage 7. Rejected for this slice: widens scope beyond the INPUT's "/harness single-task delivery surface"; if the home is pm-orchestrator stage 7 and goal mode also exits there, a future task can opt it in by reference without re-homing.
   **Recommended: (a).** Note: if the home naturally fires for any pm-orchestrator stage-7 exit, SA should state explicitly whether goal mode is included or guarded out, so the scope boundary is unambiguous.

4. **Degraded-section behavior when a `DUE` scan produces no readable artifact?**
   (a) Omit the `## Entropy watch` section but still call `swept` (non-blocking, no wedge) — RECOMMENDED.
   (b) Write a `## Entropy watch` section noting the scan was unavailable, still call `swept`.
   **Recommended: (a)** (simplest non-blocking path); SA may choose (b) for observability — either satisfies NFR-1.

No open question blocks progress: every one carries a recommended answer and the recommendations are mutually consistent. Per deferred-human mode, these are surfaced for the operator's awareness, not as a halt.

---

## 10. Verdict

**READY.** All ambiguities are captured as OQs with recommended, mutually-consistent answers (defer, do not ask). The slice is pure wiring over the T-11a core; the authoritative DRY home is pm-orchestrator stage 7 with a one-line SKILL.md pointer; the boundary uses the plain `check`; non-blocking and fail-open throughout; version `0.41.0` → `0.42.0`; counts 17/8/32 unchanged; no new check.
