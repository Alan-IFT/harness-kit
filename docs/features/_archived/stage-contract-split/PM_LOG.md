# PM_LOG — T-18 `stage-contract-split`

- Mode: **full** (7 stages)
- Dispatched from: `/harness-stream` drain (deferred-human mode: defer, do not ask)
- Developer mode: **single** (`.harness/agents/dev-*.md` → none found)
- Baseline gate before dispatch: `verify_all` bash **PASS 32 / WARN 0 / FAIL 0**

## Goal

Split every pipeline stage's output into (a) a structured **contract** section carrying only what
downstream stages consume and (b) a free-form **rationale** section carrying reasoning that only the
gate and reviewer read; make each downstream stage consume the contract alone. Structural change,
not prohibitions.

## Pre-dispatch checks

- `.harness/intervention.md` — **absent** at task start, and re-checked absent at **every** stage
  boundary since (12 checks). No intervention has ever been pending on this task.
- `.harness/insight-index.md` — read (30 lines); applicable entries surfaced into stage-1/2 dispatch
  prompts (T-14 totality + precedence, T-05 single-source, T-09 read-trigger, T-16 provenance,
  T-03 decoy set, guard-cmd-chain WARN-is-a-gate, T-15 one-physical-line insight bullets).
- `docs/tasks.md` — read. Related history: T-13/T-14/T-15/T-16/T-17 (the five measured siblings),
  T-05, T-08, T-11b. Task row added with `mode: full`.

## Compacted stages 1–3 (2026-08-01)

Compacted by PM at the stage-5→6 boundary under `.harness/rules/70-doc-size.md` Rule 2 (the log had
reached 443/500 with two stages still to log). Stages 4 and 5 below are kept full and chronological.
Nothing is lost that a stage doc does not carry: each stage's own contract is current-state, and the
round records preserved below are the only place the diff narrative lives.

- **Stage 1 — requirement-analyst — READY.** `01_REQUIREMENT_ANALYSIS.md` 481L. Measured all 40
  archived stage docs; ingest amplification **2.5–3.1×**; per-stage consumption table derived from
  cross-reference counts; the developer historically cited only **3–9 of 12–20** design sections.
  11 FRs, 14 ACs labelled `[S]`/`[B]`, 14 BCs, 9 OQs each with a binding `Recommended:` answer.
  PM advanced — no BLOCKED marker, no rollback request.
- **Stage 2 — solution-architect, three rounds.**
  - *Round 1 (READY)*: the existing stage-doc filename **is** the contract, rationale goes to a new
    optional `0N_RATIONALE.md` sibling; **OQ-2 overridden with evidence** (the analyst's premise that
    rule fragments are not distributed is false, but its recommendation also fails — a plugin-native
    agent has no project-relative path in a generated project); `## Adversarial tests` found to be
    **byte-frozen** by four generated-project gates. Blocked by the gate.
  - *Round 2 (READY)* — round record: chose a **third path** on gate F-1 rather than either option
    the gate offered (new §2 row 4, normative-text exception structurally unable to match code);
    made the rule total **as a system** via new row 2 (declared §3 shape → contract); row 5 dropped
    the "named later stage" qualifier; stage-2 schema gained `## Migration & edit sequence` +
    `## Out of scope`; the false closure claim was **withdrawn** and the provenance table rebuilt to
    12 rows; `04a_DEVELOPMENT_<partition>.md` found to be a **phantom with no producer**; ledger grew
    21→28 rows / 33 files; F-9 recorded as risk R8 with a named disposition. Approved with conditions.
  - *Round 3 (READY)* — round record: replaced the classification unit with a **six-step ordered
    ladder** (fence/blockquote are one unit; a paragraph is never a unit) and re-walked the three
    disputed units to one destination each · QA-1 · added the **byte-form exclusion** to row 2 · QA-2 ·
    row 6 now **inherits** row 5's definition and names a destination + ledger-gap instruction · QA-3 ·
    corrected §3's stage-7 rows from `(kept)` to `(new)` and added ledger row **E29** · QA-4, QA-6 ·
    added the narrow identifier trigger T5.4/T7.3 and declined the broad ambiguity trigger with the
    reason recorded in `rejected-decisions.md` · QA-5 · **re-graded §13** to strong-for-fenced-and-
    quoted / medium-for-unmarked-prose and named the compliance the fix rests on.
- **Stage 3 — gate-reviewer, three rounds** (read-only by contract; PM persisted each review verbatim).
  - *Round 1 — **BLOCKED ON DESIGN*** (9 MAJOR, 7 MINOR): the design breached its own flagship rule in
    its flagship edit; the rule was total as a table and non-total as a system, with `## Insight`
    misrouting in the **false-green** direction; the "renames no heading / no other file changes"
    closure was false. **PM rollback #1 → stage 2.** `01` explicitly cleared, so not routed to the
    analyst.
  - *Round 2 — APPROVED WITH CONDITIONS*: all nine MAJORs closed on their merits; F-1's adjudication
    upheld after the gate walked the flagship 115-line body through all 14 rows to `no home`; the
    design's unreproducible "row 4 matches **zero units**" claim carried as **C-8** rather than
    blocking, with the gate stating why a third stage-2 rollback would not have been the truthful
    reading. C-5/C-6 discharged.
  - *Round 3 — APPROVED WITH CONDITIONS* (5 PASS / 3 WARN / 0 FAIL) — round record: re-approved the
    rewritten normative rows after **independently walking all three disputed units before reading the
    architect's answer**, re-running QA-3's smuggle and five new ladder attacks; closed F-17/F-18/
    F-19/F-21/F-23/F-24, superseded F-20 into E29/V-12; opened F-25 (MAJOR, carried as **C-13** — the
    corrected wording already existed in `02` §2, so the developer **transcribes rather than authors**)
    plus F-26…F-34; discharged C-9/C-10; added C-13/C-14/C-15. **First live use of the split**: the
    gate wrote in the new stage-3 schema and returned a non-empty rationale portion, so PM persisted
    both `03_GATE_REVIEW.md` and **`03_RATIONALE.md`** — the first `0N_RATIONALE.md` in this repo.
- **Stage 4 — developer, rounds 1 and 2** (round 3 kept in full below).
  - *Round 1 — READY FOR REVIEW*: `verify_all` baseline and post-edit both `PASS 32 / WARN 0 / FAIL 0`;
    33 files (32 edited + `AC9_RECONSTRUCTION.md` created); five drifts D-1…D-5, incl. the design's
    unreproducible "zero units" clause **deliberately not shipped**, and the AC-9 reduction published
    at the **smaller** measured figure. C-11 surfaced one genuinely reachable AP-2 threshold. The
    developer pre-recorded its C-8 classifications **before** QA's pass so a disagreement could not be
    reconciled away — which is exactly what later happened.
  - *Round 2 — READY FOR REVIEW* — round record: CR-1 fixed (PM's own input list + T7.1/T7.2 into
    `pm-orchestrator.md:74-80`, closing the last unmet AC-4 clause) · CR-2 fixed **not excused** (the
    changelog bullet rephrased **by class** so the release note no longer re-seeds the token it
    retires) · CR-3 fixed (AC-9 38.6%→**37.7%**, so the figure agrees with the artifact's own
    under-reporting claim) · CR-4, CR-6 fixed · CR-5 left as a design call, CR-7 left as PM-owned ·
    `verify_all` PASS 32 / WARN 0 / FAIL 0.
- **Stage 5 — code-reviewer, rounds 1 and 2** (round 3 kept in full below). *Round 1 — CHANGES
  REQUIRED (1 MAJOR)*: AC-4 unmet for stage 7. **PM rollback #2 → stage 4** (implementation omission,
  not a design gap — the text to ship already existed in `02` §5). *Round 2 — APPROVED*: CR-1 closed
  by shipped bytes; **CR-5 adjudicated with the reviewer ruling its own round-1 proposed fix
  directionally wrong** and upholding the developer's disposition; both axes clean.
- **Stage 6 — qa-tester, round 1 — CHANGES REQUIRED (1 CRITICAL, 3 MAJOR, 2 MINOR).** QA ran
  `verify_all` ×3 (`PASS 32 / WARN 0 / FAIL 0`, 32 step lines read from the run) and left **zero
  footprint**. **QA-1 (CRITICAL)**: the shipped classification unit had no precedence among its five
  candidates, so one unit had two lawful destinations — AC-1 failing on its own probe; two of three
  C-8 verdicts differed from the developer's pre-recorded ones and were **reported, not reconciled**.
  **QA-2**: the row-2 guard was sound only for fenced bytes — ~18 `stmt` shapes admitted prose; QA
  **sized** the class the gate's F-19 could not, at 27 of 38 archived designs. **QA-3**: RES-2/F-21
  demonstrated exploitable. **QA-4**: `pm-orchestrator.md:190` declared stage-7 sections the authoring
  template lacked; 40/40 archived deliveries lacked them; minimum conforming stage-7 = **15 = the
  threshold**, margin 0. Held under attack: AC-2, AC-4…AC-14, and C-3's byte-freeze **proven
  load-bearing by mutating the artifact**. **PM rollback #3 → stage 2**: QA-1/2/3 are defects in
  normative rule text, which gate Q-8 placed outside the developer's authority and which the developer
  and reviewer had both already declined to author for that reason; Hard rule 2 governs over the
  rollback table's "QA finds bug → developer". Because the design's normative rows changed, stage 3
  re-approved before stage 4 — my own stage gate.

**Rollback ledger**: #1 gate→architect (design gap), #2 reviewer→developer (implementation omission),
#3 QA→architect (normative-text defect). Consecutive rollbacks at any one stage never exceeded **2 of
3**; the counter reset each time the stage was re-approved. No stop-and-escalate was reached.

---

## Stage transitions (kept full)

### Stage 4 — developer (round 3) — DISPATCHED 2026-08-01

**Returned: READY FOR REVIEW.** `04_DEVELOPMENT.md` corrected in place (143L), no `## Round 3`
section. **`verify_all` baseline and post-edit runs are byte-identical** — `PASS 32 / WARN 0 / FAIL 0`,
exit 0, 32 step lines; `diff` of the two stdouts is empty.

**Round record — round 3 · developer** (verbatim):

> Transcribed `02` §2's rewritten normative constructs into `70-doc-size.md` and its template twin —
> the six-step ordered classification ladder, the "Not units" clause, the self-contained "Verbatim
> byte-form" definition, row 2's byte-form exclusion, row 5's "or a blockquote", row 6's inheritance
> + destination + gap instruction (E1/E2, section spliced programmatically so the twin is
> byte-identical; V-4 shows exactly the five pre-existing divergences and zero inside the section).
> Added T5.4 (E7) and T7.3 (E9), worded identically. Implemented E29: `## Summary` and `## Verdict`
> inside `pm-orchestrator.md`'s stage-7 authoring template with `## Verdict` after `## Insight`, and
> `:192` "three declared shapes" → "four". Reconciled the two prose sentences the amendment falsified
> (C-13) plus a third the gate did not name. · **why**: QA-1 CRITICAL + QA-2/QA-3/QA-4/QA-6, gate
> round-3 conditions C-13/C-14/C-15, C-7/C-11/C-12 travelling. · **finding ids**: QA-1, QA-2, QA-3,
> QA-4, QA-6 fixed; QA-5 fixed via T5.4/T7.3; C-13, C-14, C-15 discharged; F-22/F-26/F-27/F-29/F-31/
> F-32/F-33/F-34 dispositioned (one addressed, seven deliberately left); F-30 left with a stated
> reason. Drift D-6 (C-13 overrides §2's byte-identical instruction for one sentence), D-7 (T5.4/T7.3
> person-shift), D-8 (`pm-orchestrator` measured 291 vs the 287–289 projection; below E29's own >295
> contingency trigger), D-9 (CHANGELOG trigger enumeration). `verify_all` PASS 32 / WARN 0 / FAIL 0.

Three things the developer flagged that I am carrying forward:
- **C-13 had a third instance the gate did not name** — `CHANGELOG.md:14`'s `T5.1–T5.3` enumeration,
  falsified by E7's T5.4 and never listing stage 7. Found and corrected (drift D-9).
- **V-12's published answer is unfavourable and was not tuned**: the minimum schema-conforming
  `07_DELIVERY.md` built from the *edited* template is **still exactly 15 = AP-2's threshold, margin
  0**. E29 fixes the heading clause (the WARN that fired on 40/40 archived deliveries), not the line
  clause. `agents/supervisor.md:93-101` byte-unchanged, per C-11. Publishing an unfavourable
  measurement rather than tuning the threshold is the correct call and I am recording it as such.
- **C-15 leaves one residual open by instruction**: `harness-batch/SKILL.md:81`'s fallback is an `OR`,
  so a delivery with `## Verdict: FAILED` but `verify_all PASS` is still marked done — and E29 makes
  that an authored form for the first time. No skill file touched (correct; not in the ledger).

`wc -l`: `70-doc-size.md` **174/200**, twin 173, `pm-orchestrator` **291/300**, `supervisor` 287
(untouched), `code-reviewer` 166. No cap breached.

**Stage gate before stage 5: PASSED** (`verify_all` PASSED in the development doc).
`.harness/intervention.md` re-checked — still absent.

**PM decision: ADVANCE to stage 5 (code review, round 3).**

### Stage 5 — code-reviewer (round 3) — DISPATCHED 2026-08-01

**Returned: APPROVED (0 CRITICAL, 0 MAJOR; 6 MINOR, 3 NIT as notes).** PM persisted **both portions**
verbatim — `05_CODE_REVIEW.md` (contract) and `05_RATIONALE.md`. Second stage to produce a rationale
sibling; the reviewer stated why (row 12 sends measurement narrative there, so the `## Findings` rows
stay self-contained and QA does not need the rationale to re-test a finding).

- **The three constructs ship byte-identical to `02` §2.** The reviewer re-walked AC-2 **with the
  row-2 guard removed** and QA-3's smuggle against the shipped bytes — both close at row 9. "The belt
  and the braces each hold alone."
- C-7's four load-bearing clauses and E4's two guards **read directly**, not taken on report.
- C-13's three sites all transcribe from the authorised source; the reviewer re-ran the sweeps
  independently and found **zero survivors** of the falsified class. The developer's third instance
  (`CHANGELOG.md:14`) is real.
- **E29's `## Verdict` provably bounds `archive-task`'s awk harvest** — checked against the script,
  since a mis-placed heading changes what is harvested silently at exit 0.
- Caps re-measured: `70-doc-size.md` 174/200, twin 173, **`pm-orchestrator` 291/300 — 9 lines, the
  repo's tightest** — `code-reviewer` 166. D-8 publishes the projection miss rather than tuning it.
- CR-10 independently reproduces the **margin-0** stage-7 measurement and **falsifies the gate's
  dimension-5 basis** for it; the cheapest true fix is the FR-9 header `02` §3 already mandates and
  E29 does not ledger.
- **Ten residuals travel** (RES-1, RES-3…RES-10). Round 2's RES-2 is **closed in the shipped bytes**.
  RES-5 flagged this log at 443/500 — see the compaction above.
- **No finding routes back to stage 4**: five are design- or driver-owned and travel; CR-5 is
  adjudicated non-blocking; CR-7 is mine at delivery; CR-8/CR-13 are one-number corrections in `04`.

`.harness/intervention.md` re-checked — still absent.

**PM decision: ADVANCE to stage 6 (QA, round 2)** for independent re-verification of AC-1, AC-6 and
the byte-diffs (RES-4) — the three things the reviewer could not execute.

### Stage 6 — qa-tester (round 2) — DISPATCHED 2026-08-01

**Returned: CHANGES REQUIRED (0 CRITICAL, 2 MAJOR, 4 MINOR).** `06_TEST_REPORT.md` rewritten in place
(133L), `## Adversarial tests` unsuffixed, no `## Round 2` section, zero footprint (13 fixtures
created outside the repo and deleted).

**Round record — round 2 · qa-tester** (verbatim):

> re-ran the 25-unit totality probe against the round-3 ladder recording every matching step and row
> (C-14), re-walked the three C-8 units to full agreement, and ran the three byte-diffs and the
> verify_all the reviewer could not; found the hole had moved from "which row" to "which unit" (QA-7,
> QA-8) and sized RES-10 (QA-11) · why · QA-1/2/3/4/5/6 closed, C-5/C-8/C-11/C-14/RES-4 discharged,
> new QA-7…QA-12

- **`verify_all` ×3 + once after the write: `PASS 32 / WARN 0 / FAIL 0`, exit 0, count 32 read from
  the run; stdout byte-identical across runs.** No flakes. `baseline.json` untouched.
- **Round 1's four defects are dead in the shipped bytes** — QA re-ran each attack. **C-8: full
  agreement** with the developer's pre-recorded classifications on all nine units.
- **RES-4 discharged in all three parts** — the things nobody else could run: `git diff HEAD --
  agents/supervisor.md` = 3 hunks, +4/−2, **no minimum-line column moved**; E1/E2 whole-file diff =
  exactly the five standing divergences, **0 inside the inserted section**; the row-4 bound
  token-identical and at `:93-99`, confirming CR-13a by diff rather than by reading.
- **C-11/V-12 confirmed, not refuted**: minimum conforming `07_DELIVERY.md` = **15 = the threshold,
  margin 0**. No threshold touched. Three independent parties now agree on this measurement.
- **QA-7 (MAJOR)** — the byte-form exclusion is **defeated by nesting**: ladder step 1 makes the
  containing declared-shape row the unit and states "sub-parts are never classified separately", so
  row 2 tests the container and never the byte-form in its cell. Live and shipped: `02` §6 does this
  ten times. Explicitly **not** an AC-1 or AC-2 failure — it falsifies the *unqualified* form of §13's
  structural grade.
- **QA-8 (MAJOR)** — two ladder steps name the FR-9 header line with different spans and different
  destinations ({2,14} vs {14}). **An AC-1 failure, reported not settled** per C-8/C-14. Observed
  misroutes: **0**, which is why it is MAJOR and not CRITICAL. C-14's "record every match" is what
  surfaced it as data rather than as a disagreement.
- QA-9…QA-12 (MINOR): row 2's parenthetical is wrong about its own table; **starvation demonstrated**
  on live fail-closed guard bytes; RES-10 sized (E29 moves the batch driver's false-`done` rate from
  an incidental 12.5% to the **authored default**); two partition templates omit the FR-9 header.
- QA's answer to the dominating question: **"nowhere to go if and only if it needs more than one
  line."** The multi-line class — the class the task was launched against — is genuinely homeless,
  structurally. Below one line the rule is a **size filter, not a kind filter**, and row 4's
  never-matches-source-code bound is never reached.

---

## PM decision at the stage-6 boundary: **BLOCKED: NEEDS-HUMAN** — pipeline stopped cleanly

`.harness/intervention.md` re-checked — absent (13th check; none has ever been pending).

**Why this is not a fourth dispatch.** QA routes QA-7 and QA-8 to the architect and then states the
choice explicitly: a fourth design round, **or** publish both as travelling residuals *provided* `02`
§13's structural grade and the delivery narrative are corrected to "structural for multi-line forms,
compliance for anything that fits on one line". Both routes are admissible; choosing between them is
not mine, for three converging reasons.

1. **Hard rule 3 is met.** This would be the **third rollback routed to stage 2** (gate round 1, QA
   round 1, now QA round 2). The rule says stop and surface rather than loop.
2. **The remaining choice is an acceptance-bar decision.** QA-8 is an AC-1 failure. AC-1 is the
   criterion the operator wrote as the measure of this task, and accepting delivery against an unmet
   acceptance criterion — even one with zero observed misroutes — is the operator's call, not the
   router's. Hard rule 6 forbids me deciding a reserved point to avoid blocking.
3. **The two candidate fixes are in tension with the fix that closed the CRITICAL.** QA-7's corrective
   is to make row 2 see sub-parts; step 1's "sub-parts are never classified separately" clause is
   precisely what was added to close QA-1's determinism defect. So a fourth round is not self-evidently
   a safe one-clause edit — it trades gating against determinism on the same construct QA has now
   falsified twice. Neither QA nor I can assert it converges rather than oscillates.

**State of the working tree**: the change is shipped and functional — 33 files, `verify_all` bash
**32/0/0** verified by QA on the current tree, no cap breached, no script/`baseline.json`/version stamp
/PowerShell surface touched, frozen set intact, nothing committed. Stages 1–5 are complete and stage 5
is APPROVED. **No `07_DELIVERY.md` was written** (the stage gate requires stages 5 *and* 6 to PASS)
and **`archive-task` was not run** — the task is not delivered.

Task row in `docs/tasks.md` updated to `6 — QA (blocked: needs human)`.

---

## Operator ruling received — pipeline resumed 2026-08-01

The human ruled: **accept the measured narrower guarantee with the corrected grade; do not open a
fourth stage-2 round; proceed to stage 7.** Reasoning recorded so it is not re-litigated: QA-7's
corrective requires the rule to see sub-parts, and "sub-parts are never classified separately" exists
to close QA-1's determinism demand, so fixing one reopens the other — the non-convergent shape the
three-rollback rule exists to stop. The class the task was launched against (design documents
embedding large verbatim implementation blocks) **is** structurally homeless; the surviving class is a
different one and was not what cost 250–420 KB per task. Forcing it closed would ask structure to
perform a semantic judgement and would buy a few percent by introducing misclassification: **"the
honest boundary is better than a false total."** Four requirements attached — corrected grade in
QA's exact words, residuals published unsoftened, the container-dependence finding harvested as an
insight, and the real-defect MINORs discharged — plus: do not touch `pm-orchestrator.md` further
(291/300).

**PM decision: two scoped dispatches in parallel** (disjoint files, so parallel is safe), explicitly
**not** a fourth design round — neither was permitted to attempt QA-7/QA-8.

### Stage 2 — solution-architect (scoped correction) — round 4

**Returned: READY.** `02_SOLUTION_DESIGN.md` **499 → 498** (condensed by rewrapping only; no normative
row, ledger row, verification step or frozen-set entry dropped). Shipped grade, verbatim in §13 and
§17: *"the guarantee is structural for multi-line forms, compliance for anything that fits on one
line"*, with §17 adding **"No other wording of the grade is authorised, here or in
`07_DELIVERY.md`."** New §13 row grades the one-line-byte-form-in-a-cell class **Compliance only**;
the unmarked-prose row moved Medium → Compliance, so the document names **both** stopping points.
New `### Residuals travelling` publishes **RES-QA7** unsoftened and **RES-QA8**. Grade propagated to
§1/§2/§3/§9-R9/§11.1-V-2/§12/§14/§17 so no surface contradicts another. **The property QA found that
nobody had written down is now stated once** in §3: every declared shape is line-shaped, so a
multi-line body has no container to hide in — that, not the rule table alone, is what carries AC-2.
Decline recorded at `.harness/rejected-decisions.md` (199 → 222) under `byte-form-subpart-classification`
with a re-surface condition; ledger row E19 updated so the presence check stays total.

### Stage 4 — developer (scoped fix) — round 4

**Returned: READY FOR REVIEW.** `verify_all` baseline and final **byte-identical**, PASS 32 / WARN 0 /
FAIL 0, exit 0, count 32. **QA-12 fixed** — the two partition templates gained the FR-9 header
instruction in `dev-api.md.tmpl:65`'s **existing** wording (no new coinage); header sweep **4/6 → 6/6**.
QA-9/QA-10/QA-11 dispositioned as left with one reason each. Three stale citations in `04`'s own prose
corrected from QA's byte-diff findings, and the developer **conceded** its own understated QA-11
population rather than defending it. `pm-orchestrator.md` untouched at 291/300, per the operator.

### Stage 6 — qa-tester (round 3) — DISPATCHED 2026-08-01

**Returned: APPROVED FOR DELIVERY — with named travelling residuals.** 0 BLOCKER / 0 CRITICAL /
0 MAJOR / 2 MINOR (both new, both documentation-accuracy).

**Round record — round 3 · qa-tester** (verbatim):

> re-verified the two scoped changes after the operator's accepted-residuals ruling; QA-12 confirmed
> fixed 6/6 with the sibling's exact wording; the corrected grade confirmed present, verbatim on
> §13/§17 and faithfully qualified on the other seven surfaces, 0 unqualified structural claims
> surviving; RES-QA7 confirmed unsoftened with both artifacts live; decline record confirmed durable
> under `byte-form-subpart-classification`; normative surface confirmed byte-frozen by change-set
> enumeration; verdict moved CHANGES REQUIRED → APPROVED FOR DELIVERY · why: the two scoped edits are
> correct and the change-set since round 2 is exactly 8 files, none of them normative · findings:
> QA-12 closed, QA-7/QA-8 converted to accepted residuals, QA-13 and QA-14 opened (MINOR)

- **`verify_all` ×3 + once after the write: PASS 32 / WARN 0 / FAIL 0, exit 0, count 32 read from the
  run; stdout md5-identical across all three.**
- **Normative surface proven byte-frozen** by change-set enumeration + md5, not by reading:
  `70-doc-size.md` md5 `d80ba08b…` at 174L, twin `35157e64…` at 173L, the inserted section md5-identical
  from both sides. Change-set since round 2 is **exactly 8 files, none normative**.
- **QA-13 / QA-14 (MINOR)**: the 499→498 edit orphaned four `499L` citations, and one RES-QA8 sentence
  says six contracts where five is right; V-2 mislabels RES-QA7 as a determinism exception when it is a
  defect of *kind* — an error in the **conservative** direction that does not soften the grade.
- **QA corrected its own round-2 instrument**: the developer's "12 files / 14 surfaces" is right and
  QA's single-line grep was what was wrong — three copies wrap across a line break.

**Stage gate before stage 7: PASSED** — stage 5 APPROVED and stage 6 APPROVED FOR DELIVERY.
`.harness/intervention.md` re-checked — absent (16th and final check).

**PM decision: ADVANCE to stage 7 (delivery).** Entropy-watch cadence **not** run — the stream owns
that boundary and the operator reiterated it.
