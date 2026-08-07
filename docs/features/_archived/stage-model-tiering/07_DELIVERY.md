# Delivery Summary

- **Task:** T-22 `stage-model-tiering` — wire the per-agent model / reasoning-effort declarations
  the agent definition format already supports, *if* the evidence still supports doing so after
  T-21's cost attribution downgraded tiering from the primary lever to a secondary one.
- **Mode:** full (7 stages)
- **Outcome: DELIVERED AS A DECLINE.** Nothing was wired. No `agents/*.md` file was edited.
  The model-swap lever is **declined**; the reasoning-effort lever is **deferred (not now)**.

---

## Stages traversed

Dispatched `2026-08-01T13:30:45Z` from a `/harness-stream` drain (`STREAM_LOG.md:88`), as the
final row in the pool. Delivered `2026-08-02`.

| # | Stage | Rounds | Outcome |
|---|---|---|---|
| 0 | PM setup | 1 | No intervention pending; single-developer mode (no `dev-*` partitions) |
| 1 | requirement-analyst | 1 | READY — recommends DECLINE + DEFER |
| 2 | solution-architect | **2** | READY — decline survived falsification, on a corrected argument |
| 3 | gate-reviewer | **2** | r1 BLOCKED ON DESIGN (4 MAJOR) → r2 **APPROVED FOR DEVELOPMENT** + C-1…C-5 |
| 4 | developer | **2** | READY FOR REVIEW — record appended, freeze proof executed |
| 5 | code-reviewer | **2** | r1 CHANGES REQUIRED (1 MAJOR) → r2 **APPROVED WITH NITS** |
| 6 | qa-tester | 1 | **APPROVED FOR DELIVERY** (0 BLOCKER, 0 CRITICAL) |
| 7 | PM | 1 | This document |

## Rollbacks: 2

1. **Stage 3 → stage 2** (gate, round 1). 4 MAJOR, all erring in the **decline-favourable
   direction** and each refuted inside the design's own rationale: a record claiming
   stress-testing "only lowered the bar"; a headline range traceable to no computation; an
   inadequately-discharged rebuttal of the operator's own build row; and two universal
   over-claims whose counterexample the same document already stated.
2. **Stage 5 → stage 4** (reviewer, round 1). 1 MAJOR: a mutation row in the freeze proof's
   non-vacuity table that could not be produced by the method the table declared.

Neither stage approached the 3-consecutive-rollback hard stop. **No `BLOCKED: NEEDS-HUMAN` was
returned** — see "The one point that was nearly escalated" below.

## Final `verify_all` result: **PASS**

```
PASS: 32   WARN: 0   FAIL: 0   exit=0
```

Run by stage 4 (×2) and independently re-run by stage 6 (×4) — **no flakes**, all identical.
Asserted on `echo $?` **and** the summary line (condition C-5); a WARN exits 1 and would have
failed this task. Pre-dispatch baseline was identical, and the check-by-check diff is
byte-identical.

## Baseline changes: **none**

- Check count **32**, unchanged. No check added, removed or renamed (`01` §3.3 barred it).
- `baseline.json` `verify_all_checks: 32` unchanged; **no driver assertion count moved**
  (`test_guard_rm_bash_assertions` 87, `test_archive_task_bash_assertions` 186).
- 0 tests added — none was admissible. Baseline preserved, never lowered.
- Counts held: 17 skills / 8 agents / 32 checks. No version bump, no CHANGELOG entry.

## Files changed

The production change is **one file, +23 −0**:

| path | change |
|---|---|
| `.harness/rejected-decisions.md` | +23 −0 · 255 → 278 lines · 23 → 24 records. One `## stage-model-tiering` record appended at end. Byte-identical to design §6 (`cmp` IDENTICAL, both digest `072fe7404e85121a…`). No existing record reflowed (0 deleted lines, `head -255` digest stable). |
| `docs/tasks.md` | PM lifecycle only (active row → completed row) |
| `docs/features/stage-model-tiering/` | 13 stage documents (this task's own record) |

Corroborated by a whole-tree scan QA ran over **all 499 tracked files**: exactly **4** were
written after dispatch — `BATCH_PLAN.md` and `STREAM_LOG.md` (the dispatch write itself),
`docs/tasks.md` (PM lifecycle), and `.harness/rejected-decisions.md`. **No `agents/`, no
`skills/`, no `.harness/scripts/`, no `.claude-plugin/`, no `CHANGELOG.md`**, and zero untracked
creations outside the task folder.

---

## The answer the row was dispatched to get

### Delegated share of spend: **6.7% – 45%, confidence LOW** — and the decisive component is not derivable in-repo

| statement | value | confidence |
|---|---|---|
| Directly-attributed sub-agent **output** cost as a share of the project bill | 6.7% ($36 of ≈$540) | MODERATE |
| That figure is a strict **floor** (delegated spend is at least its own output component) | ≥6.7% | HIGH |
| Sub-agent share of project **output tokens** | ≈31% | LOW |
| **Sub-agent share of cache read+write traffic — the 78% of the bill that decides the answer** | **not derivable** | — |
| Published band | **6.7% – 45%** | LOW |

**The non-derivability is the finding, not a gap in the work.** Converting an output-token share
into a cache share requires per-call context volume × sub-agent call count; neither is measured
anywhere, and the two structural effects pull in opposite directions (a sub-agent makes many calls
per dispatch; the orchestrating loop re-reads a monotonically accumulating context on every one of
*its* calls). The proposal document names the missing instrument itself.

**The trap named in the dispatch was avoided.** The external report's ≈$36 per-agent figure tracks
sub-agent *output* and excludes the cached context each sub-agent reads per call. It is used here
**only** as the floor — never as "what sub-agents cost".

The gate later ruled the **45% ceiling is not a real ceiling** but an argued judgement, and the
architect published that against its own interest.

### Projected saving of what was wired: **zero, deliberately**

Nothing was wired, so nothing is saved. The decline rests on **two rate-free legs**, both of which
survived direct attack at three independent stages:

1. **No instrument.** Detecting whether a downgrade pays needs a per-originating-stage rollback
   rate. QA computed the requirement from the live series (n=10, var 2.690, sd 1.640): **≈30
   tasks per arm at α-only, ≈61 at 80% power** — against a ten-task total history.
2. **No per-consumer reversibility.** Framework agents are plugin-native; a tier set here
   propagates to **every installed project** with no override. QA attacked this four ways
   (absent `.claude/agents/`; agent mappings removed from `sync-self` at v0.30.0; no `model` /
   `agents` / `reasoning*` key in `settings.json` or `plugin.json`; a planted local override
   yields a **bare-named** agent that nothing dispatches, because every call site is namespaced
   `harness-kit:<name>`). It survived all four.

The addressable role set reduces to **requirement-analyst + solution-architect** — the two roles
whose errors have the longest propagation path in this repo's recorded history. The three
verification roles were held at full depth per the dispatch constraint; developer, PM and
supervisor were excluded on positive evidence, not on absence of objection. The supervisor was
evaluated as the best *structural* candidate (it cannot cause a rollback) and rejected on
magnitude: it runs once per ≥5 delivered tasks.

The break-even surface, as finally published: **0.02 – 0.83 extra rollbacks per task
(0.6% – 44% relative)**. QA reproduced both endpoints and all 16 cells of the parameter table
exactly. Every point on it is below what this project can measure.

### What would reverse this decline

Three named, falsifiable re-surface preconditions travel in the record: **F-1** a per-call
context-volume measurement resolving the cache-share gap; **F-2** a rollback-attribution
instrument resolving the published surface per originating stage; **F-3** a per-project tier
override, so a downgrade is reversible by the consumer that experiences it.

**The operator's build row is not closed by this task.** `BATCH_PLAN.md:37` remains `in-progress`;
closing it is the operator's act. The record names and answers both operator statements it bears
on — `:37` (overridden, by its own two conditions returning against it) and `:41` (**qualified,
not overridden** — "this is unused wiring, not a missing mechanism" is true as stated and nothing
in the decline contradicts it).

---

## Outstanding risks

| id | Risk | Severity |
|---|---|---|
| **RES-QA1** | **The record contains one falsified clause.** `.harness/rejected-decisions.md:265` asserts that nothing here "attributes a rollback to the stage that caused it, **at any resolution**". QA falsified it: **19 of 19** rollbacks in the ten-task window *are* attributed to an originating stage in `PM_LOG.md`, two under an explicit `### Rollback ledger` heading. **The decline survives** — no instrument *aggregates* them (three incompatible shapes, no baseline, no structured field), which is the claim that actually carries the argument, and the design states it correctly at `02:39` / `:494`. The record inherited the wrong verb. **Recommended repair if §6 is ever legitimately re-opened: replace "attributes a rollback to the stage that caused it" with "measures a per-stage rollback rate".** Reserved for the operator. | MAJOR, non-blocking |
| **RES-1** *(as narrowed by QA-2/QA-3)* | AC-6 holds but is **not airtight**. Uncovered: (a) a content edit to an `agents/*.md` during stages 0–3 that preserved the mtime — narrowed by three independent in-record anchors to "line-count-preserving, non-`model:`, backdated, stage 0 or 1"; (b) an edit-and-revert **that also restored the mtime** (QA measured that without mtime restoration, FZ-3 fires — so the residual is *narrower* than the record's own account). Note the mtime-backdating technique is demonstrated inside this task, so "no such operation occurred" is testimony, not a predicate. | MINOR |
| **RES-8 / CR-11** | **Upstream defect in `02` §10.2 item 1**, reported not corrected: it instructs the tester to run FZ-1 against a scratch-*directory* copy, which `git status --porcelain -- agents/` cannot see. Run literally it yields a **spurious negative** on the highest-value AC-6 item, not a vacuous pass. Bound as a correction into stage 6, which executed the corrected form. Anyone re-running `02` §10.2 must apply it. | MINOR |
| **RES-5 / RES-7** | The eight `agents/*.md` carry **288 insertions / 130 deletions** of uncommitted work against `cb0ed57`. Two consequences: any future freeze argument leaning on `agents/` being clean is **wrong** while this wave stays uncommitted; and the M-b fixture that validates this task's freeze proof becomes unreproducible (control collapses to 0/0) once the wave is committed. QA observed and recorded the tree state: `HEAD = cb0ed57`, all eight still uncommitted at 288/130. | INFO |
| **CR-10 / QA-4** | `04_DEVELOPMENT.md:204`'s Verdict says "**Every** predicate has been shown to fire on a mutation". Measured and inaccurate. **Authoritative form, recorded here:** *every predicate except FZ-1's ` M` form fires; FZ-1's ` M` form does not fire on any content edit, and that non-firing is itself the measured result* — corroborated on real data by FZ-4's null. Not propagated into this document. | NIT |
| **QA-5** | The "≈30 attributed tasks" figure in `02` and the record is the α-only (≈50% power) per-arm `n`; 80% power needs ≈61. The error runs **against** the author — the instrument gap is larger than claimed — so it strengthens the decline. | NIT |
| **G-11** | `02`'s D-5 cites "T-13's I.6 self-trip"; the real event is **T-013**, a different task from an earlier batch. Substance and decision correct, ID wrong, never reaches the frozen record. Ruled not worth a round by the gate and upheld by the reviewer. | NIT |
| **Framework** | **`harness-kit:gate-reviewer` and `harness-kit:code-reviewer` are defined with tools `Read, Glob, Grep` and have no `Write` tool**, so neither can create the stage document its own contract names. PM transcribed `03_GATE_REVIEW.md`, `05_CODE_REVIEW.md` and `05_RATIONALE.md` verbatim on their behalf. Surfaced out-of-band; **out of scope for T-22** and needs its own row. | MAJOR (framework) |

## The one point that was nearly escalated

The gate drafted a `BLOCKED: NEEDS-HUMAN` asking whether a `declined` record may be written
against a still-open operator-authored build row, having reasoned that the ASSESS-FIRST framing
came from PM rather than the operator.

**PM did not escalate**, because that premise was false and PM owned the evidence: the framing is
recorded at the dispatch boundary in `STREAM_LOG.md:88` (`ASSESS-FIRST (T-21 downgraded this from
primary to secondary lever)`) before any stage ran, the dispatch brief pre-authorised the outcome
verbatim ("recommend DECLINE and build nothing … Record the decline in the rejected-decisions
memory so it is not re-litigated"), and `BATCH_PLAN.md:42` — operator-authored — had already made
T-22 conditional on T-21's answer ("Do not skip to T-22.").

**The gate then verified all three itself and withdrew the point without reservation**, ruling
PM's non-escalation correct. Recorded because the failure mode it guards against — an agent
self-resolving a human-reserved decision to avoid blocking — is real, and the discipline here was
to produce the authorization rather than assume it.

## Where stages corrected each other

Worth recording, because it is what a decline this consequential needs:

- The **architect falsified stage 1's central claim** (that the break-even is independent of the
  delegated share) and found the correction **strengthened** the decline — then published **six
  movements toward BUILD** against its own conclusion, including tripling its own published
  ceiling and conceding that every relative percentage is a framing rather than a measurement.
- The **gate assembled the compound BUILD-favourable case the architect had never assembled**
  (all three self-reported adjustments at their most favourable values simultaneously) and
  confirmed the decline survives it for rate-free reasons.
- The **gate withdrew its own round-1 error** on the record, and ruled **against PM and for the
  architect** on the `:41` distinction.
- The **developer confirmed the reviewer's MAJOR against its own interest** rather than invoking
  the falsifier the reviewer had bound itself to, then took the more expensive of the two offered
  fixes and volunteered corroborating evidence it had no obligation to report.
- The **reviewer corrected PM's framing** of the `02` §10.2 defect: PM called it a vacuous pass;
  it is the opposite and worse — a spurious *negative* on the highest-value item.
- **QA falsified a clause the gate had weighed and passed**, finding a counterexample far stronger
  than the one the gate had considered, and still ruled the decline sound.

## Next steps for the user

1. **Rule on RES-QA1** — one line. Either accept the record as shipped (the substance is intact
   and independently verified) or authorize a §6 re-open to change one verb. PM's read: the
   substance is sound and the archive now carries the counter-evidence, so a full 2→3→4→5→6
   round for one clause is not obviously worth it — but the call is yours, because it is
   permanent memory.
2. **Close or withdraw `BATCH_PLAN.md:37`** — T-22's row is still `in-progress` and this task
   deliberately did not touch it.
3. **Consider filing F-1** (a per-call context-volume measurement, measurement-only, in T-21's
   shape). It is the precondition that would let context reduction be *verified* rather than
   projected, and it is the single highest-value follow-up this analysis surfaced. Stage 1
   recommended filing it and correctly did not self-authorize a new pool row.
4. **File the framework `Write`-tool defect** — the two review agents cannot write their own
   stage documents.
5. PowerShell remains operator-pending as usual; **this task created no PS surface**, so there is
   nothing new to run.

## Insight

> Authored as **wrapped** bullets. Relying on T-20's harvester fix, which is proven: the index's
> own superseding entry records that a wrapped entry survives harvest and rotation whole and that
> the cap counts entries rather than physical lines, backed by the `test-archive-task` driver at
> 186/0. Checked against all fourteen I.6 banned anchor sets (paraphrased, never quoted, per D-5's
> travel discipline): zero matches, zero CJK characters, no anchor set can complete.

- 2026-08-02 · A `git status` snapshot carried in an agent's **session context is elided
  mid-list** and cannot be used to prove a path is *absent* from the dirty set — the eight
  `agents/*.md` entries vanish between `README.zh-CN.md` and `docs/`, and **three independent
  stages** certified that directory clean off it by sort-order reasoning while the live
  `git status --porcelain -- agents/` returns eight modified files. A negative taken off a
  context-carried snapshot is unsound; only a stage with a shell can establish it, and the
  inference built on it may be perfectly valid while its premise is false.
  · evidence: T-22, `04_RATIONALE.md` §R4 vs `03_GATE_REVIEW.md` §3.1 and round 2 §3
- 2026-08-02 · An **in-hunk, line-count-preserving** in-place edit is invisible to
  `git status --porcelain`, to `git diff --numstat` (bit-for-bit identical) **and** to `wc -l`
  simultaneously — only a content digest moves. So a freeze proof assembled from status +
  numstat + line count collapses to a **single** effective predicate for that class, and the
  blindness is bounded rather than uniform: the same edit on a *context* line does move numstat.
  Measured, not argued — a review had asserted the blind spot and no fixture instantiated it.
  · evidence: T-22, QA mutation M2a vs M2b, `06_TEST_REPORT.md` Adversarial rows 5-6
- 2026-08-02 · The framework's two review roles are declared with `Read, Glob, Grep` and have
  **no `Write` tool**, so `gate-reviewer` and `code-reviewer` are structurally unable to create
  the stage documents their own contracts name as their output — the orchestrator must transcribe
  their returned bodies verbatim, and a pipeline run that assumes those files appear by themselves
  will silently lose the stage record. Latent for as long as both contracts have named an output
  they cannot produce.
  · evidence: T-22, three documents PM persisted on their behalf (`03_GATE_REVIEW.md`,
  `05_CODE_REVIEW.md`, `05_RATIONALE.md`)
- 2026-08-02 · A **universal negative** written into permanent memory must be attacked with the
  strongest counterexample available, not the first one weighed: a gate considered a single prose
  note against "nothing attributes a rollback to its originating stage" and ruled it survivable,
  while the actual counter-evidence was 19 of 19 rollbacks attributed across the whole history,
  twice under an explicit ledger heading. The decision still held — because the load-bearing claim
  was that nothing **measures** a per-stage rate, not that nothing **attributes** one — which is
  why the verb in such a clause is load-bearing and a near-synonym silently ships a false claim.
  · evidence: T-22, QA-1 vs gate G-12, `.harness/rejected-decisions.md:265`
