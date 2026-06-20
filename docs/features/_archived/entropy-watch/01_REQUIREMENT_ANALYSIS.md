# 01 — Requirement Analysis: entropy-watch (T-11)

> Mode: **full** · Stage 1 (Requirement Analyst) · deferred-human mode: defer, do not ask.
> Inputs (read-only): `docs/features/entropy-watch/INPUT.md`, `AI-GUIDE.md`, the live `supervisor`/`harness-stream`/`harness-supervise`/`harness-goal`/`harness` contracts, `.harness/insight-index.md`, `docs/tasks.md`, `.harness/rejected-decisions.md`, the mattpocock `improve-codebase-architecture` + `codebase-design/DEEPENING.md` reference clone.

## 1. Goal

Make the harness automatically and periodically scan the whole codebase for accumulated entropy and, without the human having to remember, surface where the problems are at a natural boundary — then run the reduction only on explicit user authorization (machine reminds → user authorizes → machine executes), never blocking delivery or drain.

## 2. In-scope behaviors

The feature is decomposed into vertical slices (see §7). The behaviors below are the union of all slices; each behavior is tagged with the slice that owns it. Slice T-11a is the recommended thinnest end-to-end first ship.

**The scan (T-11a)**

1. A read-only entropy scan exists that walks the codebase and classifies findings using the T-07 deep-module vocabulary only: `shallow module` (interface ≈ implementation), `cross-seam leakage`, `coupling cluster`, `deepening candidate`. Each finding applies the deletion test (would deleting concentrate complexity or merely move it).
2. Each finding names WHERE: the specific file(s) or module(s) involved, stated behaviorally (the named artifact path is the subject of the finding — this is descriptive output, not a forward-looking build instruction).
3. Each finding carries a recommendation strength drawn from the fixed set `Strong` / `Worth exploring` / `Speculative`.
4. The scan emits a deterministic findings set for an unchanged tree: given the same codebase state, the structured finding list (artifact + classification + strength) is identical across runs; narrative prose may vary.
5. The scan writes nothing outside its own findings artifact and reads no file it is not permitted to read; it never edits an upstream document, never dispatches an agent, never runs a refactor. (It is observer-only.)
6. The scan emits a final single-line verdict drawn from a fixed set so an automated reader can detect "findings present" without parsing the body.

**The auto-reminder at a natural boundary (T-11a for stream; T-11b adds the `/harness` surface)**

7. A single shared "remind-if-due" check decides, from the persisted cadence state, whether the entropy reminder is due on the current boundary. Both `/harness-stream` (pool drained) and `/harness` (task delivered) call this same check — the due-logic and counter are defined in exactly one place.
8. When the check reports "due" at a `/harness-stream` pool drain, the stream runs the scan once and surfaces the findings as an `## Entropy watch` section in `STREAM_REPORT.md` and leads the exit message with a one-line entropy digest, mirroring the T-022 `## Needs your input` end-of-drain surfacing pattern (the entropy digest and the needs-input digest are distinct sections; ordering between them is fixed by the design stage).
9. When the check reports "due" at a `/harness` stage-7 delivery, the same scan runs and the findings surface in the delivery summary as an `## Entropy watch` block.
10. When the check reports "not due", neither surface runs the scan and neither emits an entropy section; the only cost on a not-due boundary is reading the one-line cadence state.
11. The reminder is non-blocking on both surfaces: it never gates, halts, fails, or defers a delivery or a drain. A drained pool with a due entropy reminder still exits normally; a delivered task with a due entropy reminder still reports DELIVERED. The reminder is informational output, not a guard and not a `verify_all` check.

**Cadence / throttle (T-11a)**

12. A persistent cadence counter records the number of delivered tasks since the last entropy sweep. It is incremented by one each time a task reaches DELIVERED (on both the `/harness` and `/harness-stream` delivery paths).
13. The "remind-if-due" check reports "due" when EITHER (a) the delivered-tasks-since-last-sweep counter is `>= N` (default `N = 5`, see Open Question 1), OR (b) it is the first stream pool-drain of the current session and at least one task has been delivered since the last sweep.
14. When a scan actually runs (the user reaches the reminder), the counter resets to zero and the last-sweep marker updates, so the same boundary does not re-trigger immediately.
15. The cadence state lives in a single one-line/one-record `.harness/` state file (recommended `.harness/entropy-watch.state`, see Open Question 2) alongside the existing `.harness/` memory/state files — NOT a new `verify_all` guard, NOT a column the gate validates.
16. The scan never runs on every drain: a drain whose counter is below `N` and which is not a qualifying first-of-session drain produces no scan and no entropy section.

**Authorize → execute (T-11c)**

17. The reminder lists each open finding with a stable identifier so the user can authorize a specific finding (or all).
18. On explicit user authorization of a finding, the harness runs the deepening reduction by reusing `/harness-goal` (Developer + QA loop) with the success criterion "the named deepening lands and `verify_all` is green", OR the normal `/harness` pipeline — the execute step is an ordinary authorized run, not the observer.
19. The harness NEVER runs any refactor without explicit user authorization. Absent authorization, a finding stays open and is only re-surfaced per the persistence rules.
20. A finding the user explicitly declines is recorded as a `.harness/rejected-decisions.md` (T-09) entry and is not re-surfaced by the reminder.

**Findings persistence (T-11c)**

21. Open (unfixed, un-declined) findings persist across sweeps and re-surface on the next due boundary, so the reminder does not forget a real problem.
22. A finding whose reduction has been authorized and reached `verify_all` green is marked fixed and is not re-surfaced.
23. A declined finding (per behavior 20) is not re-surfaced.
24. Persistence reuses existing memory where it fits (declines → `.harness/rejected-decisions.md`); any open-findings store is minimal (a single light log file under `.harness/` or `docs/`), introduces no new `verify_all` check, and does not overload `.harness/insight-index.md` (≤30-line cap).

**Skill surface (T-11a)**

25. A thin new user-facing skill entry exists (the operator's requested "新增功能") whose logic leans on existing agents: its scan delegates to the extended `supervisor` lens, its execute delegates to `/harness-goal` (or `/harness`), and its reminder reuses the STREAM_REPORT surfacing. The skill adds orchestration + the cadence check, not a new heavy engine. (This is the 16→17 skill add — see §6 NFR-4 fan-out flag.)

## 3. Out-of-scope (NOT this iteration)

1. Auto-refactoring without authorization (explicitly forbidden by behavior 19).
2. Any new `verify_all` check, gate, or guard for entropy (feedback_design_over_guards: this is "make the design better", not "add a check that blocks").
3. Blocking, gating, or deferring delivery/drain on entropy findings (the reminder is opt-in).
4. A new heavyweight scan engine separate from the supervisor (reuse mandate).
5. Real-time / streaming / background scanning, ML trend extrapolation, or alert delivery (email/webhook). On-demand-at-boundary only.
6. Scanning on every drain or every delivery (cadence forbids it).
7. Visual HTML entropy report (the mattpocock reference renders HTML; this iteration's surfaces are the existing markdown report + delivery summary). Candidate follow-up, not committed here.
8. A standing background `/loop` that scans while the user is away (ambient-mode idle progress is a separate concern).
9. Cross-repo / multi-project entropy aggregation.
10. Re-deriving or re-litigating per-task design fidelity that the Gate/CR/QA stages already enforce — this is the HOLISTIC periodic sweep, not a per-task check.

## 4. Boundary conditions

| Condition | Required behavior |
|---|---|
| Cadence state file absent (first ever run) | Treat as counter = 0, no last-sweep; the first-of-session drain after ≥1 delivery is due, or the counter path becomes due once it reaches N. File is created on first write. Absence is never an error. |
| Cadence state file malformed/unreadable | Fail-open to "not due" (never block, never crash a drain or delivery); the next clean write self-heals. Mirrors the ambient-hook fail-open contract. |
| Scan finds zero entropy findings | The `## Entropy watch` section reads `None.` (or the surface omits it cleanly); the sweep still counts as performed and resets the counter. |
| Empty / near-empty codebase | Scan returns zero findings; no crash; counter resets on the performed sweep. |
| Counter exactly equals N | Due (the `>= N` boundary is inclusive). |
| Both due-triggers fire on the same drain (first-of-session AND counter ≥ N) | Single scan runs once; no double-surfacing. |
| User authorizes a finding that no longer reproduces (tree changed since scan) | The execute run finds nothing to do and reports cleanly; the finding is marked fixed/stale, not re-surfaced as open. |
| User declines, then the same shape recurs later | The `rejected-decisions.md` record suppresses re-surfacing; a genuinely new instance with a load-bearing distinction is a new finding (parity with rejected-decisions one-record-per-concept rule). |
| Scan runs but `verify_all` is already FAIL at the boundary | The reminder still surfaces informationally; it does not itself act. (The stream's existing baseline-FAIL hard stop is unchanged and orthogonal.) |
| Two delivery boundaries in one session both due | The first performs the sweep and resets; the second sees counter = 0 and is not due (no nag-twice-in-a-row). |
| Concurrency (two boundaries racing the counter) | Out of scope — the harness is serial (one task at a time; ambient is serial). No locking required; documented as a non-concern. |
| Max findings (very large entropy backlog) | The surfaced section respects the report doc-size cap (≤200 lines for SUPERVISION_REPORT-class output); overflow is noted with a truncation line, findings are not silently dropped. |

## 5. Acceptance criteria

Each criterion is verifiable by inspection, a regression run, or observable behavior.

1. **AC-1 (scan output):** A scan over a fixture tree produces, for each finding, an artifact path + a classification from the fixed vocabulary set + a strength from `{Strong, Worth exploring, Speculative}` + a deletion-test note; re-running over the unchanged fixture yields an identical structured finding list. (Behaviors 1-4.)
2. **AC-2 (observer boundary):** The scan component is structurally read-only — its tool surface excludes `Edit`/`Bash`/`PowerShell`/`Task` (the supervisor's enforceable frontmatter boundary, insight 2026-05-19). A word-boundary check over its contract confirms it. (Behavior 5.)
3. **AC-3 (shared due-check, single source):** Exactly one definition of the "remind-if-due" logic and the cadence counter exists; both `/harness-stream` and `/harness` reference it by name, neither restates the threshold. A grep proves the threshold literal appears in one place. (Behaviors 7, 13.)
4. **AC-4 (stream surface):** With the cadence forced due, a `/harness-stream` drain produces an `## Entropy watch` section in `STREAM_REPORT.md` and an exit message that leads with the entropy digest; with cadence not due, neither appears and the scan does not run. (Behaviors 8, 10, 16.)
5. **AC-5 (harness surface):** With the cadence forced due, a `/harness` stage-7 delivery surfaces an `## Entropy watch` block in the delivery summary; not-due delivery does not. (Behaviors 9, 10.)
6. **AC-6 (non-blocking):** A due entropy reminder does not change the drain's exit verdict or the task's DELIVERED verdict; a forced "many findings" scan still lets the drain exit normally and the task deliver. No new `verify_all` check is added (count stays 16 skills' gate-array aside; check count unchanged). (Behavior 11, Out-of-scope 2-3.)
7. **AC-7 (cadence):** The counter increments by one per DELIVERED task on both paths, reports due at `>= N` (default 5) and on a qualifying first-of-session drain, and resets to zero when a sweep runs. A scripted sequence of N-1 deliveries stays not-due; the Nth delivery's next boundary is due; after the sweep the next boundary is not-due. (Behaviors 12-14, 16.)
8. **AC-8 (cadence-state location):** The cadence state is a single `.harness/` state record, not a `verify_all` column and not a new gate. Removing/garbling it fails open to not-due, never crashing a drain. (Behaviors 15, boundary row 2.)
9. **AC-9 (authorize→execute):** No refactor runs without explicit authorization; on authorization, a `/harness-goal` (or `/harness`) run executes the deepening to `verify_all` green. A probe that reaches a finding without authorizing confirms zero edits occurred. (Behaviors 17-19.)
10. **AC-10 (persistence):** An open finding re-surfaces on the next due boundary; a fixed finding does not; a declined finding is recorded in `.harness/rejected-decisions.md` and does not re-surface. Insight-index stays ≤30 lines; no new check. (Behaviors 20-24.)
11. **AC-11 (skill fan-out ledger):** The 16→17 skill add updates every live surface (Architect owns the full ledger; this RA flags the surfaces in §6 NFR-4) and flips the hardcoded C.1/G.1/G.2 name arrays + labels in BOTH shells; QA mutation-tests both a missed live flip and a wrongly-flipped frozen decoy (insight 2026-06-19 / T-03). (Behavior 25.)
12. **AC-12 (gate):** `.harness/scripts/verify_all` PASSes (both shells per the cross-shell-parity discipline; PS may be operator-pending per the deny rule) and the QA report carries an `## Adversarial tests` section.

## 6. Non-functional requirements (material only)

- **NFR-1 — Cost / token discipline:** The scan runs only on a due boundary; a not-due boundary costs one cadence-file read. The default cadence (`N = 5`) is chosen so the holistic scan amortizes across several deliveries rather than per task. (feedback_lightweight.)
- **NFR-2 — Observer read-only safety:** The scan obeys the supervisor's read-only-plus-one-write contract; the EXECUTE step is a separate authorized run with write tools, never the observer. (insight 2026-05-19; INPUT constraint.)
- **NFR-3 — Cross-shell parity:** Any cadence-state read/write touching a shell pair must be byte-identical across `.ps1`/`.sh` (newline + console-encoding + line-split discipline — insights 2026-06-08 ×3, 2026-06-12, 2026-06-08 split-bug). PS-emitting hooks write UTF-8 bytes (T-021 fix).
- **NFR-4 — Skill-count fan-out (16→17):** A new skill flips the count everywhere it is HARDCODED. Live surfaces to update (Architect produces the exhaustive ledger): README ×2, CHANGELOG `[Unreleased]`, AI-GUIDE Workflow-entry table, `docs/getting-started.md`, manual-e2e test, `.harness/rules/40-locations.md`, `docs/dev-map.md`, and the `verify_all` C.1/G.1/G.2 HARDCODED name arrays + labels in BOTH `.ps1` and `.sh` (insight 2026-06-19). DO-NOT-TOUCH frozen decoys (must NOT flip): historical `## [x.y.z]` CHANGELOG entries, `docs/tasks.md` delivery rows, `docs/proposals/*` HTML, historical `.harness/insight-index.md` lines, and the harness-status "14 required assets" HEALTH denominator. Plugin version bump required (a new skill is version-worthy). QA mutates both directions.
- **NFR-5 — Doc-size caps:** Entropy findings output respects the SUPERVISION_REPORT-class ≤200-line cap with a truncation note rather than silent drop; insight-index stays ≤30 lines; any new doc honors the rule-70 caps.
- **NFR-6 — Determinism:** The structured findings set is reproducible for an unchanged tree (parity with supervisor NFR-5), so the reminder is stable and re-surfacing is honest.

## 7. Decomposition (T-06 vertical slices)

This exceeds one smart-zone task (it spans a supervisor-agent extension, a shared cadence check wired into two skills, a new skill entry with full 16→17 fan-out, an authorize→execute integration, and a persistence store). It is decomposed into three vertical slices, each independently verifiable; **T-11a is the recommended thinnest end-to-end first ship** (scan → remind-at-drain → authorized execute path proven end to end).

| Slice | Scope | Behaviors | Independently verifiable by |
|---|---|---|---|
| **T-11a (ship first)** | Supervisor entropy lens (the scan) + the shared "remind-if-due" cadence check + cadence-state file + the `/harness-stream` `## Entropy watch` surface + the thin new skill entry (16→17 fan-out) + a minimal authorize→execute path that hands an authorized finding to `/harness-goal`. The thinnest working machine-reminds→user-authorizes→machine-executes loop. | 1-8, 10-19, 25 | AC-1..AC-4, AC-6..AC-9, AC-11, AC-12 |
| **T-11b (follow-up)** | Add the `/harness` stage-7 delivery surface to the same shared check (second boundary). | 9 | AC-5 |
| **T-11c (follow-up)** | Findings persistence store + decline→`rejected-decisions.md` wiring + open/fixed/declined re-surfacing rules, hardening the authorize→execute richness. | 20-24 | AC-10 |

(If the Architect judges T-11a still too large for one smart zone, the new-skill fan-out — NFR-4 — is the natural sub-split point, since the ledger work is mechanical and orthogonal to the scan logic.)

## 8. Related tasks

- **T-07 (`sa-design-vocab`, `docs/features/_archived/sa-design-vocab/`)** — source of the deep-module vocabulary (module / interface / depth / seam / adapter / leverage / locality + deletion test + "interface is the test surface") the scan classifies with. Already adopted as an optional Architect lens; this task makes it the scan's classification grammar.
- **T-09 (`rejected-decisions-memory`, `docs/features/_archived/rejected-decisions-memory/`)** — the `.harness/rejected-decisions.md` memory layer a declined entropy finding records into (behavior 20); read/append habit single-sourced in `25-decision-policy.md`.
- **T-022 (`stream-defer-human`, `docs/features/_archived/stream-defer-human/`)** — the `## Needs your input` end-of-drain surfacing pattern (FIRST section in STREAM_REPORT + exit message leading with the digest) that the `## Entropy watch` reminder mirrors (behavior 8).
- **T-003 (`supervisor-agent`, `docs/features/_archived/supervisor-agent/`)** — the read-only observer being extended with the entropy lens; established the enforceable read-only frontmatter boundary (AC-2).
- **T-03 (`harness-grill`, `docs/features/_archived/harness-grill/`)** — the most recent skill-count fan-out (15→16); its ledger discipline and C.1/G.1/G.2 hardcoded-array catch are the template for this task's 16→17 add (NFR-4, AC-11).
- **T-10 (`planning-decision-map`, `docs/features/_archived/planning-decision-map/`)** — precedent for honestly assessing reuse-vs-new and declining a parallel mechanism; relevant to the "extend supervisor, don't build a new engine" decision.
- **Reference (read-only clone):** `c:\Programs\_research\mattpocock-skills\skills\engineering\improve-codebase-architecture\SKILL.md` (scan-for-deepening + recommendation-strength badge + top-recommendation idea) and `codebase-design/DEEPENING.md` (dependency categories + seam discipline for the execute step).

## 9. Open questions for the user

Per standing rule, each carries a recommended answer. **deferred-human mode is active: these are recorded with recommendations and the pipeline proceeds on the recommended defaults; they are NOT interactive asks.** None blocks the verdict.

1. **Default cadence threshold N (deliveries between sweeps).**
   - (a) `N = 5` — sweep roughly every 5 delivered tasks. **Recommended.** Balances "don't nag" against "don't let entropy accumulate unseen"; at this repo's ~1-task-per-session cadence it surfaces every few sessions, which matches the holistic-periodic intent without per-task cost.
   - (b) `N = 3` — more frequent; higher nag/token cost.
   - (c) `N = 10` — rarer; risks letting rot accumulate between sweeps.
   - *Recommended: (a) N = 5, combined with the first-of-session-drain trigger (behavior 13b) so a long-idle project still gets one timely reminder.*

2. **Where the cadence counter / sweep marker lives.**
   - (a) A dedicated one-record `.harness/entropy-watch.state` file (delivered-since-sweep count + last-sweep marker + open-findings pointer). **Recommended.** Single-purpose, fail-open, sits with the existing `.harness/` state/memory files (ambient.flag, insight-index, rejected-decisions), no coupling to `tasks.md` parsing, no new gate.
   - (b) A field in the `docs/tasks.md` header — couples cadence to the task-board format and risks the count-decoy/parse fragility the project has been bitten by.
   - (c) Reuse an existing file — none has the right single-purpose shape.
   - *Recommended: (a) `.harness/entropy-watch.state`.*

3. **Execute mechanism for an authorized finding.**
   - (a) Reuse `/harness-goal` with success criterion "the deepening lands and `verify_all` is green". **Recommended.** A deepening refactor is an open-ended improve-until-green loop with Dev+QA — exactly `/harness-goal`'s shape; reuses the existing loop with no new pipeline.
   - (b) Reuse the full `/harness` 7-stage pipeline — heavier; warranted only when the deepening is a defined feature-shaped change rather than an iterate-to-green refactor.
   - (c) Both, chosen per finding strength (`Strong` → `/harness`, others → `/harness-goal`).
   - *Recommended: (a) `/harness-goal` as the default, with (c) as a later refinement if findings prove to need it.*

4. **Open-findings persistence store shape (T-11c).**
   - (a) A single light log file `.harness/entropy-findings.md` (or a section in the state file), open findings only, declines delegated to `rejected-decisions.md`. **Recommended.** Minimal; no new check; reuses the existing decline memory.
   - (b) Per-finding files — heavier, issue-tracker-shaped (the project already declined issue-tracker machinery, `rejected-decisions.md#issue-tracker-dedup`).
   - *Recommended: (a) the single light log, decline → `rejected-decisions.md`.*

## Verdict

**READY.**

Rationale: every behavior is testable; boundary conditions cover absent/malformed state, zero/empty/max findings, not-due paths, race/concurrency (out of scope, documented), and stale authorization. The four open questions are recorded with recommended defaults and, under the active deferred-human mode, the pipeline proceeds on those recommendations rather than blocking — so this stage is not BLOCKED ON USER. The reuse decision, concrete cadence default (N = 5 + first-of-session), cadence-state location (`.harness/entropy-watch.state`), and the three-slice decomposition (ship T-11a first) are all pinned. The Architect owns the exhaustive 16→17 fan-out ledger; this stage flags every known surface in NFR-4.
