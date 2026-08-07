# PM Log — T-14 `hook-truth-status`

- Mode: **full** (stages 1-7)
- Dispatched from: `/harness-stream` drain of `docs/batches/default/BATCH_PLAN.md`
- deferred-human mode: **defer, do not ask**
- Baseline gate: `verify_all` bash **PASS 32 / WARN 0 / FAIL 0** (captured immediately before dispatch)
- Working tree carries T-13's delivered-but-uncommitted changes — expected.

## Pre-stage checks

- `.harness/intervention.md`: **absent** (checked before stage-1 dispatch) — nothing to consume.
- `.harness/insight-index.md`: read. Applicable lines surfaced into dispatch prompts:
  - 2026-06-11 · `skills/harness-status/SKILL.md` asset rows are structurally pinned by `test-supervisor.{ps1,sh}` doc fan-out asserts — update asserts, never delete (evidence: T-020 dev round 1).
  - 2026-06-09 · Prefer eliminating duplication by composition/single-sourcing over adding a verify_all check; T-016 held the count at 32 that way.
  - 2026-06-05 · A count claim is pinned to the version it became true in — a count move needs a version bump (G.4).
  - 2026-06-21 / 2026-07-31 · PowerShell is agent-unexecutable here; `.ps1` twins are green-by-symmetry only, and a cross-shell hand-off must be complete in both shells.
  - 2026-07-31 · Cross-check any reported tally against the artifact that produced it, not against arithmetic.
- `docs/tasks.md`: related history — T-13 `hook-truth-spec` (delivered, archived, established `hook-spec.{sh,ps1}`); T-12 `resilient-hooks` (moved dogfood hooks to gitignored `.claude/settings.local.json`, the relocation this task's consumer missed).
- `docs/dev-map.md`: relevant rows — `skills/harness-status/SKILL.md`, `.harness/scripts/hook-spec.{ps1,sh}`, `.harness/scripts/install-hooks.{ps1,sh}`, `.claude/settings.local.json`.

## Stage transitions

| # | Stage | Agent | Decision | Timestamp |
|---|---|---|---|---|
| 1 | Requirement analysis | harness-kit:requirement-analyst | **ADVANCE** — verdict `READY`; 20 FRs, 20 boundary rows, 12 ACs, 6 NFRs, 10 OQs each with a binding `Recommended:` answer, none human-reserved | 2026-07-31 |
| 2 | Solution design | harness-kit:solution-architect | **ADVANCE** — verdict `READY`; all 10 OQ recommendations adopted verbatim, no rollback requested | 2026-07-31 |
| 3 | Gate review | harness-kit:gate-reviewer | **ROLLBACK → stage 2** — verdict `BLOCKED ON DESIGN`; 1 FAIL (F-1 false-green path), 6 WARN, 1 INFO. Rollback #1. | 2026-07-31 |
| 2r | Solution design (round 2) | harness-kit:solution-architect | **ADVANCE** — verdict `READY`; all 7 findings closed in place (F-1 closed with set quantifiers + P-6b/P-6c; F-6 relabelled accepted deviation), new §14 delta table, edit ledger byte-identical to round 1 | 2026-07-31 |
| 3r | Gate review (round 2) | harness-kit:gate-reviewer | **ADVANCE** — verdict `APPROVED FOR DEVELOPMENT`; F-1 confirmed closed, F-2…F-8 closed, 3 new WARN (F-9/F-10/F-11) + 2 INFO carried as delivery conditions | 2026-07-31 |
| 4 | Development | harness-kit:developer | **ADVANCE** — `READY FOR REVIEW`; `verify_all` **PASS 32 / WARN 0 / FAIL 0** (pasted from the run), `test-supervisor` 46/0 pre-edit and 46/0 post-edit, tree delta = 1 tracked file | 2026-07-31 |
| 5 | Code review | harness-kit:code-reviewer | **ROLLBACK → stage 4** — `CHANGES REQUIRED` (0 CRITICAL, 1 MAJOR). Product code approved as-is; MAJOR-1 is confined to `04_IMPLEMENTATION.md`. Rollback #2. | 2026-07-31 |
| 4r | Development (round 2) | harness-kit:developer | **ADVANCE** — `READY FOR REVIEW`; MAJOR-1 corrected at all 3 surfaces, doc now 499 lines, re-ran both drivers this round (`verify_all` 32/0/0, `test-supervisor` 46/0), `SKILL.md`/`CHANGELOG.md` byte-unchanged | 2026-07-31 |
| 5r | Code review (round 2) | harness-kit:code-reviewer | **ADVANCE** — verdict `APPROVED` (0 CRITICAL, 0 MAJOR); MAJOR-1 closed at all 3 surfaces, NIT-1 closed, product byte-unchanged | 2026-07-31 |
| 6 | QA test | harness-kit:qa-tester | **ROLLBACK → stage 4** — `CHANGES REQUIRED` (2 MAJOR, 4 MINOR, 1 NIT). All 12 ACs pass with captured evidence; the 2 MAJORs are one-clause defects in the shipped skill text. Rollback #3 (2nd at stage 4). | 2026-07-31 |
| 4rr | Development (round 3) | harness-kit:developer | **ADVANCE** — `READY FOR REVIEW`; both QA MAJORs fixed, totality proven over 13 inputs, repo verdict byte-identical, `verify_all` 32/0/0 ×3 and `test-supervisor` 46/0 ×3 | 2026-07-31 |
| 5rr | Code review (round 3) | harness-kit:code-reviewer | **PASS** — `APPROVED` (0 CRITICAL, 0 MAJOR); both QA MAJORs closed with independently re-derived proofs; §3c pointer extension adjudicated **in ledger** | 2026-07-31 |
| 6r | QA (round 2) | harness-kit:qa-tester | **PASS** — `APPROVED FOR DELIVERY`; 28-input totality prober (0 unclassified, 0 moved), all 6 §7 branches reachable, 38-root regression sweep 0 changed | 2026-07-31 |
| 7 | Delivery | (PM) | **DELIVERED** — `07_DELIVERY.md` written, `docs/tasks.md` updated, `archive-task` run | 2026-07-31 |

### Stage 1 → 2 decision notes

- Intervention check after stage 1: `.harness/intervention.md` **absent**. No directive to apply.
- RA scope expansion accepted: OQ-2 pulls the per-event congruence section (§3c) in, because it reads the
  same hardcoded path and is false in the same way on this repo — fixing only the guard verdict would ship a
  self-contradicting report. This stays inside the pool row's stated goal (read wiring from where it lives).
- RA also touched `CONTEXT.md` (added *Effective hook source*, *Health report*) under its glossary-maintenance
  habit. Allowed; noted so CR/QA see it in the diff.
- OQ recommendations are carried to the Architect as **binding defaults** (deferred-human mode: no operator
  override is available mid-stream; none of the ten is human-reserved by RA's own assessment, and PM concurs —
  none weakens the guard, edits a red-line file, or changes permission config).
- OQ-6 tripwire (version treatment) carried forward: fold into the unreleased `0.45.0` unless that version has
  been tagged by delivery time.

### Stage 2 → 3 decision notes

- Intervention check after stage 2: `.harness/intervention.md` **absent**.
- Design shape: one new `§0 Effective hook source` resolve-once module inside `skills/harness-status/SKILL.md`
  with a six-field interface; §1/§3b/§3c/§6/§7 all read it and no section re-reads a settings path (that
  prohibition is the reviewable property). Spec coupling is a pinned 7-query plan; `command` never invoked.
- Constraint compliance claimed by SA and to be verified by the Gate: check count stays 32, no `.ps1` touched,
  F.2 untouched, edit ledger = `skills/harness-status/SKILL.md` + `CHANGELOG.md` only, frozen decoys enumerated.
- Two interpretation notes flagged rather than silently applied (D-1: FR-14 `UNKNOWN` is a precondition gate on
  FR-5's three states, not a fourth; D-2: NFR-4's invocation budget read as O(1)-per-id). Gate must adjudicate
  whether these are deviations requiring an RA rollback.

### Stage 3 → 2 decision notes (ROLLBACK #1)

- Intervention check after stage 3: `.harness/intervention.md` **absent**.
- The gate-reviewer agent contract carries **no `Write` tool** (Read/Glob/Grep only), so it returned the review
  as text; **PM persisted it verbatim** to `03_GATE_REVIEW.md` with a note saying so. PM made no content edits —
  routing only. (Recorded because it is a reusable process fact about this stage.)
- Verdict `BLOCKED ON DESIGN` → routed to `harness-kit:solution-architect` per the rollback table ("Gate finds
  design gap → solution-architect; only the designer can fix the design"). Explicitly **not** routed to the
  requirement-analyst: the Gate states "No requirement gap was found".
- Blocking finding **F-1**: §3.3's rows 6-8 admit `INSTALLED AND WIRED` on a guard that would not run (multi-path
  hook command with the guard script missing; and detection-by-substring not requiring the *tested* path to be
  the guard's). That is the NFR-1 hard-reject direction and an FR-18 determinism breach — PM does not waive it
  into development as a condition, since it is the exact defect class the task exists to remove.
- Interpretation notes adjudicated by the Gate: **D-1 faithful, accept**; **D-2 faithful in intent but a literal
  NFR-4 breach → relabel as an accepted recorded deviation (F-6)**. Neither routes to the requirement-analyst.
- **F-8 is INFO and deliberately NOT folded into T-14**: `AI-GUIDE.md:110`, `docs/getting-started.md:180-182`,
  `.harness/rules/60-tool-handoff.md:72-74` each still say the Stop hook lives in `.claude/settings.json` —
  further consumers of the same T-12 relocation, but none states where the *health report* reads hook wiring
  from, so FR-20 does not reach them. PM surfaces this to the stream as a backlog candidate rather than widening
  an in-flight row (scope discipline).

### Stage 3r → 4 decision notes (gate PASSED)

- Intervention check after stage 3r: `.harness/intervention.md` **absent**.
- **Stage gate satisfied**: stage 3 produced an explicit `APPROVED FOR DEVELOPMENT` verdict. Round-2 review
  persisted verbatim under `## Round 2` in `03_GATE_REVIEW.md` (again PM-persisted; agent has no Write tool).
- **Developer routing**: `.harness/agents/dev-*.md` → **none found** ⇒ single-developer mode; dispatching the
  plugin agent `harness-kit:developer`. This matches design §11.
- Four gate conditions (§R2-8) carried into the stage-4 dispatch as required statements in
  `04_IMPLEMENTATION.md`: F-9 bound, F-10 row-4 matcher choice, F-11 fail-closed derivation + the `N+3` count,
  and the two preconditions (pre-edit `git status` baseline for AC-11; never hand-edit `insight-index.md` for
  AC-9's WARN 0).
- PM notes for the record that the gate's F-9 residual (an extractable guard path in a non-executing command
  position could still reach row 8) is **accepted**: it is not reachable through any wiring the harness
  generates, and closing it would need shell-grammar analysis that FR-11/FR-18 do not authorize. Recorded here
  rather than silently absorbed.

### Stage 4 → 5 decision notes

- Intervention check after stage 4: `.harness/intervention.md` **absent**.
- **Stage gate satisfied**: stage 4 shows `verify_all` PASS (32/0/0) pasted from the run, so stage 5 may open.
- Two items the Developer self-reported that PM is routing to the Code Reviewer as **explicit adjudication
  items** rather than accepting on the Developer's own word:
  1. **`test-supervisor` reports 46, not the 45 the design expected from `baseline.json:16`.** The Developer
     reports 46 both pre-edit and post-edit on an unmodified driver, and attributes the gap to a stale baseline
     key (driver last committed at `f3586bc`, key last written at `02c25bf`), noting no `verify_all` check reads
     it and `baseline.json` is OUT of the ledger. PM does not adjudicate correctness — but this repo has twice
     shipped a fabricated tally (insight 2026-07-31), so the CR must confirm 46 came from the artifact and that
     leaving the stale key is the right call rather than a silent baseline drift.
  2. **Self-declared design drift**: §3c's `DANGLING`/`MALFORMED` fix lines were re-pointed at §7's conditional
     fix table (8 lines) although design §3.4 neither lists them as kept nor changed. The Developer's stated
     reason is that leaving them would ship a blanket `/harness-upgrade` instruction that cannot reach a
     machine-local source — an FR-8 violation inside the document that fixes that very class. CR owns the
     call: fidelity-to-design vs requirement-correctness. If CR finds it out of ledger, the Developer has
     already named the clean 8-line revert.
- PM did not silently bless either item; both are named in the stage-5 dispatch.

### Stage 5 → 4 decision notes (ROLLBACK #2)

- Intervention check after stage 5: `.harness/intervention.md` **absent**.
- Code review persisted verbatim by PM (`05_CODE_REVIEW.md`) — third stage in a row whose agent contract has no
  `Write` tool. Recorded as a standing process fact for this pipeline.
- **Both PM-routed adjudications came back with substance:**
  1. **Tally**: the 46 is real (CR reconstructed 46 assert call-sites statically from the driver source, i.e.
     cross-checked against the artifact, per insight 2026-07-31). **But the Developer's diagnosis was wrong** —
     `baseline.json:16`'s key is `test_supervisor_bash_no_python3_assertions`, and AC-7.3 is python3-gated with
     no `else`, so 45 is the *correct* no-python3 value and 46 is the python3-present value. Leaving the key
     untouched is right, for the opposite reason to the one recorded.
  2. **§3c drift**: adjudicated **correct and in ledger** — FR-8's reachability sentence is report-wide, not
     §3b-scoped, so leaving the blanket `/harness-upgrade` line would have shipped an FR-8 violation inside the
     document that fixes that class. The Developer's offered 8-line revert is explicitly **not** to be taken.
- **MAJOR-1 routing**: to the **Developer**, per the rollback table ("Reviewer finds code defect → developer").
  The defect is in `04_IMPLEMENTATION.md` (the implementer's own document): a false causal claim, routed as an
  action item, and queued for harvest into `.harness/insight-index.md`. PM treats this as blocking because
  `archive-task` would plant it in a 30-line always-loaded memory at stage 7 — the exact failure mode
  `.harness/rules/05-insight-index.md` exists to prevent. **No `SKILL.md` / `CHANGELOG.md` byte change.**
- **PM hand-off 1 (to QA at stage 6)**: the corrected `test-supervisor` expectation is **46/0 on a python3-present
  host, 45/0 without python3**; `baseline.json:16` is **out of bounds** — QA must not "reconcile" it. The design's
  §10.1 step 3 / §10.2 `(45/0)` carry the same mis-derivation and are superseded by this note.
- **PM hand-off 2 (backlog, not T-14)**: CR MINOR-2 (§3c interpreter WARN still points at `settings.json` for the
  `_doc_sync_hook`/`_ambient_hook` notes, and names only `pwsh`/`bash` so it can never fire on this repo's
  `sh`-prefixed commands — design-frozen, so not drift) and MINOR-4 (a non-canonical matcher such as `Write`
  still earns row 8 + the health point; FR-9-mandated, same family as gate F-9). Surfaced to the stream
  alongside gate F-8. Not folded into this in-flight row.

### Stage 5r → 6 decision notes (code review PASSED)

- Intervention check after stage 5r: `.harness/intervention.md` **absent**.
- Round-2 review persisted verbatim under `## Round 2` in `05_CODE_REVIEW.md`.
- **Three CR hand-offs PM now owns**, all carried into the stage-6 dispatch or held for stage 7:
  1. **QA expectation correction** (into the stage-6 dispatch): `test-supervisor` is **46/0 on a python3-present
     host, 45/0 without python3**; `baseline.json:16` is **out of bounds in either direction**. Three design
     surfaces quote the superseded `45` — §10.1 step 3, §10.2, and risk **R-1** (`02_SOLUTION_DESIGN.md:566`) —
     all superseded by this note.
  2. **Stage-7 insight formatting (MINOR-5)** — held by PM for stage 7: `archive-task.sh:51` harvests only
     physical lines beginning with `- `, so the insight must enter `07_DELIVERY.md` as **one physical
     `- `-prefixed line** or its `· evidence:` clause is silently dropped into permanent memory. The index is at
     30/30, so the append rotates the oldest line into `insight-history.md` — handled by the script, I.4 stays
     green.
  3. **Backlog (MINOR-2, MINOR-4)** — PM's ledger, since `04_IMPLEMENTATION.md` records MINOR-2 only and MINOR-4
     nowhere. Surfaced to the stream with gate F-8.

### Stage 6 → 4 decision notes (ROLLBACK #3 — 2nd at stage 4)

- Intervention check after stage 6: `.harness/intervention.md` **absent**.
- **Rollback-limit check**: PM's hard rule stops the pipeline at *three consecutive rollbacks at the same
  stage*. The ledger is: #1 at stage 2 (Gate → SA), #2 at stage 4 (CR → Dev), #3 at stage 4 (QA → Dev). That is
  **two** at stage 4, not three. Pipeline continues; the next stage-4 rollback would hit the limit and PM would
  stop and surface instead.
- QA's routing is correct per the rollback table ("QA finds bug → developer, not the tester"). Both MAJORs are
  one-clause documentation fixes inside the existing edit ledger (`skills/harness-status/SKILL.md`):
  - **QA MAJOR-1** — §0 Step 0.1 is **not total**: a settings file that parses as a JSON object whose `hooks`
    value is an *array* (`{"hooks": []}`) matches none of `absent`/`unreadable`/`empty`/`present`. Two
    defensible readings give opposite verdicts on one input, and one of them is the false-green direction OQ-5
    rejected. This is the same defect class as gate F-1 (a non-total table), found in a different table — which
    is why PM is not waiving it.
  - **QA MAJOR-2** — §7's fix-line table has **overlapping keys and no precedence rule**: in the P-11/B-7 state
    (`MACHINE_STATE = unknown` ∧ `SOURCE_KIND = committed`) two rows match, and the shipped text selects the
    `/harness-upgrade` repair for a report that just named the *machine-local* file unparseable — the exact FR-8
    prohibition this task exists to enforce, reachable from shipped text.
- **QA's non-vacuity proof accepted**: the pre-edit procedure on unchanged repo state yields
  `DISABLED — .claude/settings.json has no PreToolUse for Bash` and four `not wired`, while the post-edit
  procedure yields `installed and wired`. That is the live symptom in the pool row, closed and measured.
- QA independently validated the `baseline.json:16` adjudication by shimming a failing `python3` onto PATH and
  capturing `PASS: 45 / FAIL: 0` — confirming CR's diagnosis empirically rather than by argument. No baseline or
  insight-index edit was made.
- **Two design-doc defects QA found and worked around** (recorded, not routed — the design is not re-opened at
  this depth for a probe-spec issue): design **P-20's fixture as specified was vacuous** (its two entries were
  indistinguishable because `guard-rm-missing.sh` does not contain the detection substring) — QA rebuilt it; and
  **P-21's "no rewrite proposal anywhere" assertion contradicts §3c's design-frozen interpreter WARN**. Both
  belong in the delivery's outstanding-risks section, not in another design round.

### PM decision on QA's out-of-band CRITICAL (guard-rm segment parsing)

QA reported, with captured exit codes, that `.harness/scripts/guard-rm.sh` inspects only the first verb of each
top-level **pipe** segment — so `rm <outside-path>` is blocked (exit 2) while `echo hi && rm <outside-path>`,
`true; rm <outside-path>` and an `xargs`-mediated form all pass (exit 0).

PM ruling: **out of scope for T-14, surfaced as a high-priority new task row.** Reasons, stated so this is not
read as a silent absorption:
- T-14 changes no hook script and QA confirms the finding is **pre-existing**, not introduced here.
- FR-5's `installed and wired` is a claim about *wiring*, which is genuinely present — the health report is not
  lying about the thing it reports.
- Widening an in-flight row to a guard-semantics fix would be exactly the scope creep this wave's row boundaries
  exist to prevent, and it would put a safety-critical change through a pipeline whose requirement, design and
  gate never examined it.
PM authorizes nothing and changes nothing about the guard. QA correctly used `HARNESS_ALLOW_OUTSIDE_RM=1` only
on individual teardown calls with the block/override lines pasted. This is carried in the return summary to the
stream operator as the single most important non-T-14 finding of this task.

### Stage 4rr → 5rr + 6r decision notes

- Intervention check after stage 4rr: `.harness/intervention.md` **absent**.
- **Both stage 5 and stage 6 must re-run.** Stage 5's `APPROVED` was issued against product bytes that have
  since changed (round 3 edited `skills/harness-status/SKILL.md`), and stage 6's ACs were measured against the
  pre-fix bytes. The pre-stage-7 gate requires stages 5 and 6 to PASS **on the delivered bytes**, so PM does not
  carry either verdict forward.
- **Dispatched in parallel** — the two stages read the same files and answer independent questions (fidelity vs
  behavior), and neither writes to the other's surface. Accepted risk, stated: if CR requires a byte change, QA's
  round-2 run is invalidated and must be re-run. PM judged the probability low enough (two one-clause fixes with
  a self-proved totality argument) to be worth the wall-clock saving.
- One item routed to CR for adjudication: the Developer **extended fix 2 to a second pointer** (§3c's `DANGLING`
  fix line at `:287-291`, which still read "keyed on §0's `SOURCE_KIND`" and would have routed the same P-11
  state to `/harness-upgrade`). The Developer disclosed it as an in-scope extension rather than new scope. PM
  does not rule on that — CR owns it, exactly as it owned the round-1 §3c adjudication.

### Stage 5rr + 6r → 7 decision notes (pre-delivery gate satisfied)

- Intervention check after both parallel stages: `.harness/intervention.md` **absent**.
- **Pre-stage-7 gate**: stages 5 and 6 both PASS **on the delivered bytes** — CR round 3 `APPROVED`, QA round 2
  `APPROVED FOR DELIVERY`. The parallel-dispatch risk PM accepted did not materialize: CR required no byte
  change, so QA's round-2 run remains valid for the delivered bytes.
- CR round 3 persisted verbatim under `## Round 3` in `05_CODE_REVIEW.md`; QA appended its own `## Round 2`
  (with an `## R2-7 Adversarial tests` subsection) to `06_TEST_REPORT.md` directly — QA has a Write tool.
- The two stages converged independently on the same conclusions from different methods (CR: structural
  derivation over the state algebra; QA: a 28-input executable prober plus a 38-root regression sweep). QA found
  **two more** previously-unclassified inputs than the Developer's 13-input sample, all landing strict.
- **CR MINOR-6 accepted by PM as an archive-time record, not a design round**: `02_SOLUTION_DESIGN.md` §3.1's
  state table and §5.3's fix table are now **superseded by the shipped text** — QA's two MAJORs were inherited
  *design* defects, and the product is deliberately stricter than the design's literal rows in the NFR-1-safe
  direction the design itself mandates. PM does not reopen stage 2 to retro-fit a design doc to a delivered
  correction; the supersession is recorded in `07_DELIVERY.md`'s outstanding risks so a future re-derivation
  from the design cannot silently re-introduce both MAJORs.
- **CR MINOR-5 honored at delivery**: the `## Insight` entries are written as **single physical `- `-prefixed
  lines**, because `archive-task.sh:51` harvests only lines matching `^[[:space:]]*-[[:space:]]` and would
  silently drop a wrapped line's `· evidence:` clause into permanent memory.
- QA's own disclosures accepted as-is: a self-corrected measurement error (a check-row grep printed 31 because
  `[E.4b]` carries a letter suffix; the real count is 32, enumerated in full), a disclosed tool gap closed
  analytically rather than by claiming an execution it did not perform, and `06_TEST_REPORT.md` standing at 1289
  lines against the 500-line soft cap. PM's call on the last one: **do not delete round-1 evidence to hit a soft
  cap** — the cap is a WARN-level guideline with no gate check on stage docs, and the file archives out of the
  live tree at this delivery. Recorded as an outstanding item, not remediated by deletion.

### Stage 7 — delivery (closed)

- Final intervention check before delivery: `.harness/intervention.md` **absent**. Over the whole task the file
  was checked at every stage boundary (11 checks) and was never present — nothing to consume, nothing to delete.
- `07_DELIVERY.md` written. Its three `## Insight` entries were authored as **single physical `- `-prefixed
  lines** per CR MINOR-5.
- `docs/tasks.md`: T-14 moved out of Active and appended to Completed with the delivery outcome.
- **`archive-task` executed** — PM has no `Bash` tool, so the script was run by a dispatched agent under a
  strictly mechanical brief (run the script, paste both captures, verify the harvest, hand-edit nothing). Result:
  3 insights harvested, 3 oldest rotated to `docs/features/_archived/insight-history.md`, index back to exactly
  30 data lines, all 8 stage docs moved. **Post-archive `verify_all`: PASS 32 / WARN 0 / FAIL 0**, I.4 green on
  its own without any hand-edit.
- **Harvest integrity confirmed**: the three landed lines are byte-identical to the delivery's bullets and each
  retains its trailing `· evidence:` clause — CR MINOR-5's truncation hazard did not fire. Rotation was lossless
  (27 retained + 3 rotated = the 30 pre-run lines, zero duplicates).
- One auditing note recorded by the executing agent, worth keeping: **`git diff` against `HEAD` is not a valid
  check on `.harness/insight-index.md` while a prior task's archive sits uncommitted** — T-12's uncommitted
  archive had already rotated 4 lines, so `HEAD` lags the true pre-run file and the diff shows a phantom
  mismatch. Snapshot the working file before invoking the script instead.
- Entropy-watch cadence **deliberately not run** — this task came from a `/harness-stream` drain, which owns
  that boundary; running it here would double-increment the shared counter.

**Final state: DELIVERED.** 3 rollbacks (stage 3→2 once, stage 5→4 once, stage 6→4 once); the
three-consecutive-rollbacks-at-one-stage hard stop never fired. No human-reserved decision arose, so no
`BLOCKED: NEEDS-HUMAN` verdict was returned.
