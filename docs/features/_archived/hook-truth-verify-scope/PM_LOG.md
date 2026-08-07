# PM_LOG — T-15 `hook-truth-verify-scope`

- Mode: **full** (7-stage), dispatched from a `/harness-stream` drain
- deferred-human mode: **defer, do not ask**
- Started: 2026-08-01

## Goal

Narrow the `verify_all` guard-wiring check to repository-answerable assertions (guard script
pairs present; distributed settings template carries the guard placeholder + its pre-tool hook
block) and remove its dependence on an untracked machine-local settings file — so a clean
checkout does not fail the gate on an environment condition. All remaining assertions stay at
FAIL severity; total check count unchanged.

**ASSESS FIRST**: the row's original motivation was materially weakened by T-13 (installer now
bootstraps the machine-local settings file from the single source) and T-14 (project-health
report now owns the machine dimension). Stage 1 must re-evaluate honestly and may recommend
**DECLINE** (build nothing, record in `.harness/rejected-decisions.md`).

## Pre-flight

- `.harness/intervention.md`: **absent** at task start (checked before stage 1 dispatch).
- Partition agents `.harness/agents/dev-*.md`: **none** → single-Developer mode (`harness-kit:developer`).
- `.harness/insight-index.md`: read. Entries surfaced to downstream dispatches:
  - 2026-08-01 · `verify_all` exits 1 on `warns > 0` — a WARN is a hard release gate, not advisory;
    the 200-line rule-fragment cap is therefore a gate (guard-cmd-chain gate R2.6).
  - 2026-08-01 · editing a live fail-closed `PreToolUse` hook has one safe sequence (stage in the
    unwired template copy, syntax-check, promote via `sync-self`).
  - 2026-06-20 · a `verify_all` gate that checks ARTIFACT PRESENCE is load-bearing only against a
    missing artifact, not against a stale entry in its own hardcoded name array — a mutation test
    proving such a gate is real must mutate the ARTIFACT (T-11a QA).
  - 2026-07-31 · a reported tally must be cross-checked against the artifact that produced it,
    never re-derived arithmetically (T-13 rework 1).
  - 2026-07-31 · read a baseline key's NAME as part of its value before comparing (T-14 CR MAJOR-1).
  - 2026-06-21 / 2026-07-31 · PowerShell is agent-unexecutable here; a `.ps1` change is
    green-by-symmetry only and ships broken in ways a `.sh` run never surfaces.

## Related history

- T-13 `hook-truth-spec` (v0.45.0) — `hook-spec` single source; `install-hooks` bootstraps a
  missing `.claude/settings.local.json`.
- T-14 `hook-truth-status` (unreleased v0.45.0) — `/harness-status` `§0 Effective hook source`;
  machine dimension owned and named. Recorded "**T-15 now unblocked**".
- T-17 `guard-cmd-chain` (unreleased v0.46.0) — rewrote both guard scripts; regression driver
  17 → 87 rows, now pinned in `baseline.json`; rule doc `75-safety-hook.md` at 200/200 lines.
- T-10 `planning-decision-map` — precedent for a **delivered decline** with no code.

## Stage transitions

| # | Stage | Agent | Decision | Timestamp |
|---|---|---|---|---|
| 1 | Requirement analysis (ASSESS FIRST) | harness-kit:requirement-analyst | **PROCEED**, verdict READY → advance | 2026-08-01 |
| 2 | Solution design | harness-kit:solution-architect | verdict READY → advance | 2026-08-01 |
| 3 | Gate review (r1) | harness-kit:gate-reviewer | APPROVED WITH CONDITIONS (C-1..C-10); 1 CRITICAL + 4 MAJOR route to SA → **rollback to stage 2** | 2026-08-01 |
| 2 | Solution design (r2) | harness-kit:solution-architect | READY (r2) — all 10 conditions folded, 0 disputed | 2026-08-01 |
| 3 | Gate review (r2) | harness-kit:gate-reviewer | **APPROVED FOR DEVELOPMENT** — all 10 conditions discharged | 2026-08-01 |
| 4 | Development | harness-kit:developer | READY FOR REVIEW — `verify_all` **PASSED** 32/0/0 | 2026-08-01 |
| 5 | Code review | harness-kit:code-reviewer | **APPROVED** — 0 CRITICAL, 0 MAJOR, 7 MINOR, 6 NIT | 2026-08-01 |
| 4 | Development (r2, doc fix-forward) | harness-kit:developer | complete — gate re-run **32/0/0** | 2026-08-01 |
| 2 | Solution design (r3, doc-only) | harness-kit:solution-architect | complete — 0 disputed, no code file opened | 2026-08-01 |
| 6 | QA | harness-kit:qa-tester | **APPROVED FOR DELIVERY** — 0 blocking, 2 MINOR doc-only | 2026-08-01 |
| 4 | Development (r3, one-line doc) | harness-kit:developer | complete — gate re-run **32/0/0** | 2026-08-01 |
| 2 | Solution design (r4, doc-only) | harness-kit:solution-architect | complete — 0 disputed, no code file opened | 2026-08-01 |
| 7 | Delivery | (PM) | **DELIVERED** | 2026-08-01 |

### Final rounds → delivery

Both closing rounds landed clean and the gate re-ran **32 / 0 / 0** after the last edit.

The architect's round 4 is worth recording because it did more than accept QA's two findings — it
followed both to consequences QA had not reached, and reported them against itself:

- Rather than bump "exactly two deviations" to three (a count that would go stale again), it replaced
  the closed list with the **two root-cause axes** that generate the class, so a fourth member no
  longer falsifies the section.
- While correcting it, the architect found that its own round-2 sentence "T-15 neither introduces nor
  widens these deviations" was **false for one axis**: no pre-change pattern contained a whitespace
  class at all, so two of the three deviations exist *because* this task anchored the assertion. It
  recorded that as an **accepted cost of the anchor, explicitly not a reason to revisit it** — the
  anchor is binding, its benefit is measured, and the stricter shell is not weakened by any member.
- On QA's coverage finding it went further in the same direction: QA measured the case-insensitivity
  backstop on the **bash** side, and the architect found that on the **PowerShell** side the schema
  check's membership test is itself case-insensitive — so that backstop does not exist in the shell
  where the deviation actually occurs. Net: **none of the three deviations has a backstop inside the
  PowerShell gate**, now written down rather than implied. This is modelled, not executed, and is
  labelled as such.
- It deliberately left its own round-2 changelog section saying "two deviations", on the grounds that
  a changelog is a historical record of what that round did — the same freeze discipline applied to
  the historical entries in the shipped changelog. Correct call.

Total rollbacks: **1** (stage 2, gate-driven). Four additional fix-forward rounds, none a rollback:
two after code review and two after QA, each doc-only, each on disjoint files, none touching shipped
code logic. No stage rolled back twice, so the three-consecutive-rollback stop never came into play.
No `BLOCKED: NEEDS-HUMAN` arose at any stage.

`.harness/intervention.md` checked at **every** stage boundary throughout — absent each time.

### Stage 7 — archive-time incident and PM repair

`archive-task` exited **0** having silently **truncated all four harvested insights to their first
physical line**, destroying every `· evidence:` pointer. Caught only because I asked the executing
agent to verify the rotation by re-reading the artifact rather than trusting the script's own success
output — which is the same discipline this repo adopted after archiving a fabricated tally, and it
paid out immediately.

Root cause: the harvester emits only bullet-marker lines, so a *wrapped* bullet loses its
continuations. It is invisible three ways at once — exit 0, a console echo that reprints the same
truncated lines so the output looks right, and `I.4` counting bullet **lines** rather than content.
The gate was green at 32/0/0 with the project's memory corrupted. Contributing cause on my side: the
index header's "one per line" is a hard input contract and this delivery's `## Insight` section
violated it.

**PM repair, and why it is mine to make:** rule 05 puts the insight append at task end on the PM, and
gate C-8 explicitly reserved index rotation for me. I rewrote **only my own four lines** (never
another task's), restored their full text and evidence, and added a fifth recording the harvester
defect. That would have left the index at **31 of 30** — precisely the WARN-exits-1 hazard C-8 warned
about — so I hand-rotated the single oldest entry to `insight-history.md` under a labelled heading,
using the script's own oldest-first mechanism. I caught the 31st-line problem myself immediately after
introducing it, before verification.

I then had it **independently verified**, not self-attested: gate 32/0/0 exit 0 with `I.4`/`I.5` PASS,
index exactly 30, 5/5 T-15 bullets complete and evidence-bearing, the rotated entry present exactly
once in history and zero times in the index (moved, not duplicated or dropped), rule fragment still
200 lines, all 8 stage docs archived, and the guard scripts + machine-local settings file frozen by
mtime ordering.

**Deliberately NOT fixed:** the harvester itself, its PowerShell mirror, and the two distributed
template copies. That is a new defect class in a different tool — repairing it here would be scope
expansion (red line 3), which Mode 2 does not permit autonomously. Surfaced to the stream as a
recommended new pool row instead.

### Stage 6 → delivery decision

QA verdict **APPROVED FOR DELIVERY** (0 BLOCKER / 0 CRITICAL / 0 MAJOR, 2 MINOR doc-only, 2 NIT, 1
observation). **Stage-7 gate satisfied**: stages 5 and 6 both PASS. Tree left green and byte-identical
to its pre-QA state. Report carries the required `## Adversarial tests` section and follows the
design's new appendix pattern (184-line body + mandated-evidence appendix).

QA did not merely re-run the developer's plan — it went past it in four places:

- **It built a *stronger* clean state than the developer's** by staging the overlay inside the linked
  worktree, so the index matched the overlaid content. That removes the "stale index" limitation the
  gate had forced into the record as an honest concession, and the git-enumerating checks then saw the
  real file list. It then ran the **real pre-change script** and the shipped one over the same bytes:
  pre-change FAILs with the three retired wiring tokens, shipped PASSes 32/0/0. The headline claim is
  established by differential measurement.
- **It probed the three assertions nobody had mutated**, safely (the forbidden live paths are
  forbidden because the fail-closed hook points at the *live* copy; in a scratch tree they are safe),
  and confirmed the mirrored-source co-fire for all four rather than the one the design predicted.
- **It ran the accumulation cases nobody had run** — multi-problem inputs yield one message with all
  tokens, with the two template assertions correctly suppressed behind the template-presence one. The
  check does not stop at the first problem.
- **It attacked the anchoring**, this task's signature fix, and got the cleanest possible result: with
  the entire hook block deleted, the **real pre-change gate emitted no hook-block token at all** — it
  still believed the template was wired. That is the vacuity, reproduced against the committed script
  rather than argued. QA also obtained the isolated single-token proof stage 4 could not.
- **It confirmed the declined-scope residual empirically** — two constructed templates pass the gate
  under a label reading "wiring present", one of them in precisely the state that caused the original
  defect. Delivery can now state this from measurement instead of inference.

Every driver printed a summary line (QA treated absence as a failure signal per the fabricated-tally
insight). Guard driver pin held at 87. Frozen list verified independently, including the 200-line rule
fragment at exactly 200 with its mtime **predating** this task's first write, and its unrelated stale
claim left unrepaired as instructed.

**QA's observation on the supervisor driver is correctly NOT a defect**: the driver returned 46 against
a baseline key of 45, but the key names the *no-python3* variant and python3 is present. This is the
exact trap recorded in insight-index (2026-07-31) — a design that quotes such a key as its run
expectation manufactures a phantom stale baseline. QA read the key's name as part of its value and
did not "reconcile" a correct frozen count. No action.

**Final fix-forward round dispatched (again NOT a rollback, disjoint files):** QA's two remaining
accuracy defects are both claims-about-claims, and this task's whole subject is a verification surface
that asserted something untrue — shipping its own documents with inaccurate claims would be the same
defect class in the description of the fix.

- **Developer** → the live `CHANGELOG.md` entry enumerates 4+2 assertions but totals seven; the
  template-presence assertion is unlisted. This is the identical under-enumeration that produced the
  original "six" miscount, which the architect traced to the design's own summary and closed this
  round. The changelog is the last copy.
- **Architect** → §3.3 claims "exactly two accepted deviations" between the shells, but QA found a
  **third** by execution (the PS regex engine matches Unicode whitespace the POSIX bracket expression
  does not). More substantively, the two deviations are given a **shared** rationale while QA proved
  they are not equally covered: the case-insensitive one has a real backstop elsewhere in the gate,
  the newline-split one has **none**, because the mutated file is still valid JSON. The acceptance
  argument survives; the coverage claim must be stated honestly and separately.

Both are doc-only; neither touches shipped code, and neither can change the gate result.

### Stage 5 → fix-forward decision (NOT a rollback)

CR verdict **APPROVED** on both axes; neither axis carries an unaddressed CRITICAL or MAJOR, so the
aggregate is MINOR and nothing blocks merge. The CR is persisted verbatim (it too runs read-only).

I dispatched two **parallel doc-only fix-forward rounds** rather than counting a rollback, because no
finding touches shipped code logic and the two rounds write **disjoint files** (developer:
`CHANGELOG.md` + `04_DEVELOPMENT.md`; architect: `02_SOLUTION_DESIGN.md`). Parallel is normally
avoided, but disjointness is explicit here and I told each round the other was running.

Routing follows ownership, per hard rule 2 — the developer cannot fix a design-text defect and the
architect cannot fix the implementation record:

- **Developer** — the freeze-claim overstatement (see below), one omitted frozen sibling, one
  fidelity wording fix, and the live `CHANGELOG.md` miscount (a code-ledger artifact, hence the
  developer's).
- **Architect** — the design-internal miscount that the CHANGELOG *inherited*, the unsatisfiable
  verification recipe, a stated evidence budget for the rule collision below, and the residual
  coverage note for the follow-up row.

**The finding that most justified the extra round:** the developer's freeze evidence claimed a
filename set-difference was the sound substitute for the unsatisfiable "absent from the diff" check.
The reviewer showed it is **not sound alone** — a difference over *names* is blind to a content edit
inside a file that was already dirty, and it enumerated the frozen-list files that were in fact
already dirty from the three uncommitted sibling rows, so the exposure is real rather than
hypothetical. The claim holds only because the developer had *also* bolted on an mtime table, which
does move on such an edit. This had to be corrected before delivery because that sentence was queued
for `.harness/insight-index.md` as **permanent memory** — the developer's own insight bullet already
stated the correct two-part form, so only the prose was wrong.

Notable CR verifications I am relying on at delivery:

- The anti-vacuity proof for the anchored assertion is **direct, not substituted**: the real gate run
  emitted a token no other code path can produce, against a genuinely mutated artifact, at FAIL
  severity — and the old-versus-new pattern comparison is a faithful re-execution of the old
  predicate, so the anchoring itself is proven load-bearing. This matters because anchoring is the
  one thing the gate insisted on (C-9) and the vacuity it closes is this task's signature finding.
- The reviewer **independently checked the other consumer of a machine-local file** and confirmed it
  already skips a missing target in both shells — so the clean-checkout goal is genuinely closed on
  both shells, not just the one that was executed.
- The tally cross-check went beyond arithmetic: the pasted runs reproduce the script's actual
  non-obvious check ordering and a two-space indentation quirk unique to the real emitter. This is
  the discipline this repo adopted after archiving a fabricated tally whose value happened to be
  correct.
- One acceptance criterion's **recipe** was defective while the criterion itself was satisfied; the
  developer refused to trim a comment to make the number look right. That refusal was correct — the
  comment's whole value is naming the files the check no longer reads.

**Deliberately not fixed** (declined scope, recorded for delivery + the follow-up row): the two
template assertions test presence independently and never **containment**, so a template with the
placeholder inside a different hook and an empty pre-tool block would pass while the label says
"wiring present". Widening belongs to T-16.

### Stage 4 → 5 decision

**Stage-5 gate satisfied**: `04_DEVELOPMENT.md` records `verify_all` PASSED at `PASS: 32 / WARN: 0 /
FAIL: 0`, `exit=0`, pasted from the run (confirmed by PM in the doc, not taken from the return
message alone — this repo has archived a fabricated tally that survived a full pipeline *because its
value happened to be correct*). `test-guard-rm` pinned count held at 87/0. Live guard scripts and the
machine-local settings file were never touched (mtimes unchanged).

The developer reported **four discrepancies rather than papering over them** — the behaviour this
pipeline is trying to buy, so I am routing them to review rather than resolving them myself:

1. One mutation's expected *detail* was mis-predicted: the guard placeholder lives **inside** the
   hook block, so deleting the container necessarily kills both assertions. The design's
   check-level prediction was still right, which is exactly what makes the mis-prediction easy to
   miss. The developer did **not** invent a substitute mutation and instead discharged the assertion
   by a read-only old-vs-new pattern comparison on the same mutated file. **Code review must rule on
   whether that substitute is sound** — a weaker anti-vacuity proof would undermine the one finding
   this task exists to fix.
2. "Absent from `git diff --name-only`" is **unsatisfiable on this tree**: S0 measured 37 already-
   modified files, so the environment's "clean" claim is false and most of the frozen list was
   *already* dirty from the three uncommitted sibling rows. The developer substituted an S0→S11
   dirty-set **difference** (T-15 newly dirtied exactly one path) and labelled the substitution as
   its own. Review must confirm the substitute actually protects the frozen list.
3. One acceptance criterion's "zero occurrences" recipe is self-inconsistent, because the design's
   own prescribed comment names the very paths being counted. The developer **did not trim the
   comment to make the number look right** — it measured on code lines instead and reported both.
4. A template file's mtime moved from the mutate/restore cycle; content byte-identical.

PM rulings on the three items the developer routed to me:

- **Stage doc length (755 lines vs the 500-line soft cap).** Accepted as-is. The overage is
  mandated verbatim evidence (full status capture, both differential runs, four mutations, the
  gate's quoted derivation), and the developer trimmed prose rather than runs — the correct
  trade. Per insight-index, stage docs under `docs/features/` are unmeasured by the `I.*` gate
  group, so no check fires; the doc is archived at delivery. Cutting mandated pastes to hit a soft
  cap would trade real evidence for a cosmetic number.
- **Filename drift.** `04_DEVELOPMENT.md` is correct — it matches the canonical 7-stage pipeline
  contract. The design ledger's alternative name is the drift; harmless, noted, no rework.
- **Insight candidates** staged by the developer: carried to my stage-7 consolidation. The index is
  still at 30/30 and the developer correctly did **not** trim it (gate C-8 reserves that for me).

### Stage 3 (r2) → stage 4 decision

Gate r2 verdict: **APPROVED FOR DEVELOPMENT** — stage gate satisfied (explicit approval on record
before any code is written). All ten conditions ruled **genuinely discharged, not merely mentioned**,
each verified at the location the architect's round-2 changelog claimed, with the factual claims
re-checked against code. The gate specifically re-tested the two it expected to find softened
(the safety prohibition's prominence, and whether the rejected unanchored variant was really struck
rather than merely deprecated) and the one it expected to find hand-waved (the new mutation's
co-failure-freedom, which the architect re-derived rather than inherited).

Gate r2 found four **new** MINOR/INFO items introduced by the round-2 edits — all accuracy defects in
*rationale attached to prohibitions that remain correct*, none altering an expected output, mutation
target or safety outcome, so none is a gating condition. Two are notable because they correct
**upstream reviewers rather than the architect**: the round-2 danger-block mechanism was escalated
too far (a copy from a missing source cannot clobber the live guard — and a developer who wrongly
believes it did might hand-repair a 900-line security script, which *would* be the destructive act),
and the PowerShell hazard's illustrative example is wrong in a way inherited from the gate's own
round-1 wording (the gate said so explicitly: "I am correcting my predecessor as much as the
architect"). The prohibitions stand; only the explanations were wrong. Both are carried into stage 4
as notes, with the explicit instruction that proving the example false must not downgrade the rule.

Rollback count so far: **1** (stage 2, gate-driven). No stage has rolled back twice; the
three-consecutive-rollback stop is not in play.

Six residual items handed to the developer (recorded in `04`, not by editing `02`): the two corrected
mechanisms above, the mutation rename-suffix note, a stale neighbouring line to leave alone, a
one-line check that a run-appended log is genuinely untracked, and the gate's own exhaustiveness
derivation for the first mutation's two-FAIL expectation (which lives in the review, not the design).

PM-carried, confirmed by gate r2 and already on my stage-7 checklist: **C-8** (insight index
re-measured at exactly 30/30 — the harvest must rotate, not append) and the task-board/pool status
ledger row. The gate explicitly instructs that the **developer must not pre-emptively trim the
insight index** — that is mine at delivery.

### Stage 1 → 2 decision

RA returned **PROCEED** (not decline), verdict `READY`, no `BLOCKED: NEEDS-HUMAN`. Advancing.
The assessment was grounded in the live check rather than the goal sentence, and it tested both
decline arguments rather than asserting the build:

- E-1: the clean-checkout FAIL is reproducible in **both** shells — the machine-local settings
  file is gitignored, so the check falls back to the committed settings file which has carried an
  empty hooks object since T-12; all three wiring assertions then fail at FAIL severity.
- E-2: the check's own in-code justification ("a user project that keeps hooks in the committed
  file is still validated") does not hold — this 32-check gate is dogfood-only; generated projects
  get the type-overlay gate, which contains zero occurrences of the guard/hook tokens. Dropping the
  machine read removes **zero** user-facing coverage.
- E-3: the cheap middle path (assert-only-if-present) is **unsound**, because the documented
  durable opt-out for the safety hook is precisely a *present* machine-local file with an empty
  hooks object. A present-implies-wired assertion at FAIL severity would turn the documented
  disable path into a gate failure.
- The T-10 decline precedent was tested and rejected on a real distinction: T-10 had **no defect
  left**; here a reproducible FAIL remains, and this change *removes* surface rather than adding it.

**PM decision (Mode 2, autonomous, logged per `25-decision-policy.md`):** OQ-1 asked whether
narrowing a safety-adjacent check is a red-line-5 (security-sensitive) escalation. **Not escalated.**
Basis: the dispatching brief explicitly enumerated this narrowing as one of two legitimate outcomes
and supplied its acceptance criteria, so the change class is operator-pre-authorized; and no runtime
safety behavior changes (NFR-1 freezes every guard script, hook command and settings file). Recorded
here for operator spot-check, as OQ-1(b) recommends.

RA's other recommended answers adopted as binding for stage 2: OQ-2(b) drop rather than
conditionalize, OQ-3(b) relabel, OQ-4(a) fold into unreleased 0.46.0, OQ-5(b) separate tree state
(mutating live `.claude/` is **forbidden** — it disarms the live fail-closed guard), OQ-6(b) no
widening (T-16 territory), OQ-7(b) confirm by execution, no new driver.

### Stage 2 → 3 decision

SA verdict **READY**; requirement doc untouched, no rollback requested. Advancing to the gate.

Notable: SA verified the change ledger by its own tree-wide searches rather than inheriting the
RA's, and found one live-false surface the RA missed (AI-GUIDE's script-index line) plus one
**name collision** worth freezing (the type-overlay templates also have an `F.2`, but theirs is
the rule-fragment size check — editing it would be a wrong-target change).

SA autonomous calls (Mode 2, logged): D-1 anchor the template hook-block assertion to the JSON key
form; D-2 restructure the PS branch to accumulate-then-throw (today's PS throws on the first
problem, which violates B-9/FR-7); D-3 relabel; D-4 fix the AI-GUIDE line; D-5 treat the migration
doc's already-stale count as a decoy; D-6 put the new operator PS item in this task's own stage doc
(the standing list is materialized per-task in archived docs, which are frozen); D-7 keep the two
memory-layer appends.

**Flagged for the gate as the first thing to scrutinize (R-1/D-1):** SA reports that today's
assertion is an unanchored whole-file match, and the distributed template carries the hook-block
token inside a documentation string — so deleting the entire hook block reportedly still PASSes
today, i.e. one boundary condition is currently vacuous. SA's fix anchors to the key form. This is
the only place the design changes fail-inputs beyond pure deletion, so the gate must rule on
whether it is in scope or scope creep. Gate dispatched with this as an explicit review target.

### Stage 3 (r1) → stage 2 (r2) decision — **ROLLBACK #1 at stage 2**

Gate verdict: **APPROVED WITH CONDITIONS** (C-1..C-10). The gate reviewer has no write tool, so it
returned the review as its response; PM persisted it **verbatim** to `03_GATE_REVIEW.md` and
authored none of it. Nothing routed back to the requirement-analyst.

**Why I am not proceeding straight to development despite the gate's "may proceed":** the gate's own
findings route **1 CRITICAL and 4 MAJORs to solution-architect**, and every one of them is a defect
*in the design document* — the verification plan, the hazard checklist, a frozen-row basis label,
and a symmetry claim. Hard rule 2 says downstream cannot edit upstream documents, so a developer
cannot absorb these; carrying them only in a dispatch prompt would leave the design doc stale and
make the implementation answer to my prompt rather than to the approved design, which is precisely
the drift class this pipeline exists to prevent. One cheap design round is the correct route.
Precedent in this repo: T-14 and T-17 both took a gate-driven design r2.

The decisive finding is **F-2 (CRITICAL)**: the verification plan never *forbids* mutating the two
live guard-script assertions, and one of them is the live fail-closed `PreToolUse` hook. Renaming
or deleting it seizes the entire Bash toolchain, and recovery is Read+Write only because `mv` and
`git checkout` are themselves Bash calls. The plan happens to pick a safe mutation target but never
says the dangerous ones are off-limits — and the "audit every sibling" discipline this task is
running under actively pushes a conscientious developer to generalise the mutation to all four.
That must be a written prohibition in the design, not a hope.

Gate findings I judged worth the round, beyond F-2:

- **F-1 (MAJOR)** — the recorded expected output for the first mutation is unmeetable: the mirrored
  template pair means the sync check co-fires, so the true expectation is two FAILs, not one. A
  developer trusting the stated expectation might "repair" the sync while a guard source is renamed
  away — touching the live guard path. Wrong expectations are how a false-green gets normalised.
- **F-3 (MAJOR)** — one assertion branch has no falsification step at all, so the design closes the
  single vacuity finding it discovered instead of auditing the class. The gate verified the missing
  mutation is cheap and co-failure-free.
- **F-4 (MAJOR)** — an unlisted PowerShell hazard: the step harness decides WARN from the
  scriptblock's pipeline output, so any stray emitting statement array-filters into a spurious WARN,
  and a WARN exits 1. This is a new member of the agent-unexecutable-PS family and belongs on the
  hazard list the developer will actually use. The gate confirmed the rest of the PS restructure is
  sound against all three previously-shipped instances and that the hand-off is complete in both
  shells.
- **F-7 (MAJOR)** — the scratch-tree summaries are predicted rather than derived, and the gate found
  a real inconsistency between the recorded HEAD and the version files that the plan never measures.

**Gate rulings I accept as settled, and which stage 2 must not reopen:** R-1/D-1 anchoring is
**correct and in scope**, and the design's own unanchored fallback is **rejected** (C-9) — the gate
verified by reading both the template and both check bodies that the current assertion is vacuous,
and gave a stronger argument than the architect's own: unanchored, the check's new label would be
live-false at birth. The change ledger is complete, the frozen/decoy list is right (including the
three-way check-id name collision), the count and FAIL-severity invariants hold, the 200/200 rule
fragment is genuinely untouched, and the clean-state procedure is guard-legal without any override.

**C-8 is addressed to me, not the architect:** `.harness/insight-index.md` is at exactly 30/30 and a
WARN exits 1, so the stage-7 harvest must **rotate, not merely append**. Carried to my stage-7
checklist below.

### PM stage-7 carry-forward (do not lose)

- **C-8** — insight-index at 30/30; `archive-task` must rotate. Verify the gate is still green after
  archival, since a 31st line would WARN and a WARN exits 1.
- **C-6** — the delivery must correct the mis-stated protection basis for one frozen row
  (review-protected, not gate-protected) without editing that file.
- **AC-12** — the delivery must state plainly that behavioural guard coverage is **unchanged** and
  that the machine dimension **moved** to the health report rather than disappearing.
- Do **not** claim the delivery reconciled the standing operator PS note about the two shells'
  differing settings parsing; the narrowing retires that asymmetry as a side effect, but the note
  lives on a frozen surface and is out of scope.
