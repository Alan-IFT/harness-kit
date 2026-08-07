# PM_LOG — T-22 `stage-model-tiering`

- Mode: **full** (7 stages)
- Dispatched from: `/harness-stream` drain (final row in pool)
- deferred-human mode: **defer, do not ask** — a human-reserved point returns
  `BLOCKED: NEEDS-HUMAN — …` rather than an interactive ask.
- Gate baseline captured immediately before dispatch: **PASS 32 / WARN 0 / FAIL 0** (bash).
- Working tree carries eight siblings' delivered-but-uncommitted changes — expected.

## Stage 0 — PM setup (2026-08-01)

- `.harness/intervention.md`: **absent** (no pending intervention).
- `.harness/agents/dev-*.md`: **none** → single Developer mode; stage 4 dispatches
  `harness-kit:developer`.
- `.harness/insight-index.md` read. Entries surfaced to downstream dispatches:
  - **verify_all exits 1 on `warns > 0`** — a doc-size WARN is a hard release gate, not
    advisory. Relevant because the 300-line agent cap is enforced as `I.*` WARN.
    (evidence: guard-cmd-chain gate R2.6)
  - **The wrapped-insight harvester defect is FIXED and the fix is proven** (index entry
    dated 2026-08-01, T-20: it SUPERSEDES the "one physical line per insight" contract —
    a wrapped entry survives harvest and rotation whole, and the cap counts entries, not
    physical lines). PM therefore authorizes wrapped insight bullets for this task and
    says so in the delivery, per the dispatch's conditional clause.
  - **A decline is a first-class delivery in this repo** — T-10 `planning-decision-map`
    delivered as DECLINED with no code, 0 rollbacks, and recorded the decline in
    `.harness/rejected-decisions.md`. That precedent is live and applicable here.
- `.harness/rejected-decisions.md` read — no existing record covers model tiering.
  If the outcome is a decline, a new record is required.
- `docs/tasks.md` read. Related history: **T-21 `stage-cost-attribution`** (the sibling
  measurement row, delivered as `docs/proposals/cost-attribution-2026-08.md`, operator-
  authored, not a pipeline run) and **T-18 `stage-contract-split`** (the context reduction
  that already landed 37.7% / 52.9% / 51.7%).
- Task row added to `docs/tasks.md` Active tasks with `mode: full`.

### ASSESS-FIRST framing carried into stage 1 (see below for stage records)

`docs/proposals/cost-attribution-2026-08.md` post-dates the pool row that created this
task and **downgraded the premise**: 78% of spend is cache traffic, not model
intelligence; ~128k cached tokens read per call against ~1,272 output tokens (≈100:1).
Tiering remains a proportional discount (cache reads/writes are priced off the model's
input rate) but is no longer the primary lever. **Both build and DECLINE are legitimate
outcomes.** PM does not pre-judge which.

## Stage 1 — requirement-analyst (complete)

- Output: `01_REQUIREMENT_ANALYSIS.md` (contract) + `01_RATIONALE.md` (rationale sibling).
- Verdict: **READY — recommendation: DECLINE the model-swap lever, DEFER the
  reasoning-effort lever.** Nothing wired; no `agents/*.md` edited.
- Delegated-share finding: band **6.7% – 45%** (best-supported 25–45%), confidence **LOW**;
  the decisive component (sub-agent share of cache traffic = the 78%) declared
  **not derivable in-repo**, with the reason. The report's ~$36 figure used ONLY as a
  floor, not as "what sub-agents cost" — the trap named in the dispatch was avoided.
- Load-bearing argument: the break-even is **independent** of the delegated share (both the
  saving and the risk cost scale with it), landing at ≈0.34 extra rollbacks per task
  (≈11% relative) against an observed mean of 3.0 (n=6) — a delta this project has no
  instrument to detect. Plus Finding D: framework agents are plugin-native, so a tier
  propagates to every installed project with **no per-consumer override**.
- 5 open questions, all with recommended answers; **none blocking for this task**
  (OQ-4's pool-row filing is operator-reserved and was correctly NOT self-authorized).

### PM routing decision after stage 1: ADVANCE to stage 2

Rationale for continuing the full pipeline despite a decline recommendation: a decline is
a *decision resting on an analysis*, and the analysis is exactly what needs independent
adversarial scrutiny before it becomes permanent memory. T-10's precedent ran RA + Gate
independently before declining. Stages 4-6 are not empty here — the decline has a real
file deliverable (`.harness/rejected-decisions.md`), a freeze claim to prove on a dirty
tree, and a gate run to keep green.

### PM observations carried to stage 2 (not rulings)

- `01_REQUIREMENT_ANALYSIS.md` §4.1's **bolded heading asserts the opposite of its own body**
  ("already carries a `stage-model-tiering` record" vs "Verified absent at analysis time").
  PM does not judge materiality — stage 2 reports whether it is material, and PM routes
  back to stage 1 if it is.
- PM-surfaced environmental datum for OQ-1 (a fact available to PM's runtime, NOT a design
  opinion): this orchestrator's own runtime documentation states that an agent type's
  "model, reasoning effort, and tools come from its definition (`.claude/agents/*.md`
  frontmatter or SDK `agents`)". Stage 2 weighs whether that is sufficient to close OQ-1
  or whether it still needs upstream-schema confirmation it cannot perform without network.

## Stage 2 — solution-architect (complete)

- Output: `02_SOLUTION_DESIGN.md` (contract, 403 lines) + `02_RATIONALE.md` (316 lines).
- Verdict: **READY** — the decline **survived falsification, on a corrected argument**.
  No rollback requested.
- The architect **falsified stage 1's central claim** (FL-1): the break-even is NOT
  independent of the delegated share as stated — `S` cancels only if the non-delegated
  remainder of a rollback round costs nothing, which is false (PM orchestration, drain
  shell, `verify_all` runs, operator turns). Corrected form
  `f = a(1−r) / [c_d + c_o·(1−S)/S]`, monotonically increasing in `S`.
  **FL-2: the correction STRENGTHENS the decline** — the corrected bar sits at or below
  stage 1's at every point of the band.
- FL-3: stage 1 measured the rollback cost on the wrong stage set — a stage-1/2 defect
  routes to 1 or 2, not 4, so the re-run is 2→3→4→5→6 (80.3%) when caught late, not 44.5%.
- FL-4: corrected detection surface **0.6%–13.9% relative (central ≈5%)** vs stage 1's
  11.2% — every point still below this project's detection threshold.
- FL-5: PM's proxy-bias reasoning verified algebraically — the document-line proxy biases
  toward BUILD, so the decline survives its own proxy error.
- FL-6/7: the 6.7% floor is valid (and loose); **the 45% "ceiling" is NOT a ceiling** but
  an argued judgement — ruled non-material because `f` rises with `S` only to 11.2%.
- FL-8: Finding D holds and is now proven, not assumed — `.claude/agents/` is empty and
  the PM dispatches the **namespaced** `harness-kit:<name>`, so a local bare-named file
  **cannot shadow** a plugin agent. No per-consumer override exists.
- Reported three adjustments in the **BUILD** direction against its own conclusion
  (document proxy; the n=6 rollback mean being a *selected* sub-series — n=10 gives 1.9,
  scaling every relative bar by 1.58×; an unsourced `1−r = 0.4`). None overturns it.

### Disposition of PM's two carried observations

1. §4.1 contradiction ruled **cosmetic, not material** (§2.6 + AC-5 fix the build
   unambiguously). **But the architect found stage 1's "eighteen records" is wrong — the
   file carries 23**, and §4.3's "~one screen" claim is already false of the current file.
   Plus a fourth item PM did not flag: `cost-attribution-2026-08.md:81-84` says T-22 is
   "still worth doing", and stage 1 never engages that line. All four dispositioned
   in-design (§16 U-1…U-5) rather than by rollback.
2. OQ-1 **partially closed**, disposition unchanged — the datum names two surfaces,
   neither of which is where plugin-native `agents/*.md` lives; key name, value set and
   effect size stay unverified. Correctly did NOT over-close it.

### PM routing decision after stage 2: ADVANCE to stage 3 (gate-reviewer)

PM does **not** rule on whether stage 1's two factual errors warrant a rollback — that is
the gate's independent call, and the gate is the stage whose job is to distrust upstream.
PM carries all four items to it explicitly rather than letting the architect's "immaterial"
ruling stand unexamined.

## Stage 3 — gate-reviewer, round 1 (complete)

- Output: `03_GATE_REVIEW.md`. **PM had to persist it** — see the provenance note at the top
  of that file: `harness-kit:gate-reviewer` is defined with tools `Read, Glob, Grep` and has
  **no `Write` tool**, so it cannot create the stage document its own contract names.
  PM transcribed the returned body verbatim and authored none of it.
  (`harness-kit:code-reviewer` has the same tool set — same problem awaits stage 5.)
  Recorded as an out-of-band framework finding; **out of scope for T-22.**
- Verdict: **BLOCKED ON DESIGN** → stage 2. Explicitly **not** stage 1.
- The decline **survived** a third independent pass, including a **compound** BUILD case
  stage 2 never assembled (all three self-reported BUILD adjustments at their most
  BUILD-favourable defensible values simultaneously → `f = 0.834` extra rollbacks/task,
  27.8% n=6 / 43.9% n=10). It survives for **rate-free** reasons: no rollback-attribution
  instrument exists at any resolution over a ten-task history, and Findings C and D are
  independent of every parameter in the model.
- What did **not** survive: the byte-form of the one artifact this task ships. 4 MAJOR
  (G-1…G-4), 3 MINOR/NOTE (G-5…G-7), all four MAJORs erring in the **decline-favourable**
  direction and each refuted by the design's own rationale. G-4 is the guard-cmd-chain
  CR2-2 shape again — a universal claim that fails exactly at the point that matters, with
  the counterexample stated in the same document (FL-11's `0.417 > 0.335`).
- Upstream rulings: U-a/U-b/U-c confirmed **immaterial** (no stage-1 rollback); the gate
  independently counted **23** records, matching stage 2 and confirming stage 1's
  "eighteen" wrong. U-d ruled **inadequately discharged** → G-3.

### PM ruling on HR-1 (the gate's deferred human-reserved point) — **NOT escalated**

The gate deferred, correctly per its contract, the question of whether a `declined` record
may be written against a still-open operator-authored build row, and drafted a
`BLOCKED: NEEDS-HUMAN` for PM to surface. **PM does not surface it, because the point is
already ruled by the operator channel — and PM owns the provenance evidence the gate could
not see.**

The gate's G-3(a) premise is **factually wrong on one point**: it states "the ASSESS-FIRST
framing was conferred **by PM at stage 0** (`PM_LOG.md:41-42`), which is an agent's framing,
not the operator's." It was not conferred by PM. It arrived in the stream's dispatch brief
and is recorded on disk at the dispatch boundary:

> `STREAM_LOG.md:88` — `2026-08-01T13:30:45Z · T-22 · dispatching pm-orchestrator ·
> slug=stage-model-tiering · mode=full · **ASSESS-FIRST (T-21 downgraded this from primary
> to secondary lever)**`

The dispatch brief PM received carried it as a section heading, **"ASSESS FIRST — the
premise changed after this row was written"**, and pre-authorized the outcome verbatim:

> "Both outcomes are legitimate. If the analysis shows a worthwhile saving on roles that
> can afford it, wire it. If it shows the remaining saving is small and concentrated on
> roles that cannot afford it, **recommend DECLINE and build nothing** — this repo has a
> precedent where a proposed feature was assessed as not worth its cost and delivered as a
> decline with no code, and that was the right outcome. **Record the decline in the
> rejected-decisions memory so it is not re-litigated.**"

and again under Gate ("if the outcome is a decline, the gate must still be green and the
delivery must record the assessment and its reasoning") and under Return summary ("a
delivered-as-decline is a legitimate `DELIVERED`").

**Corroborated in operator-authored text**, not only in the dispatch: `BATCH_PLAN.md:42`
makes T-22 explicitly conditional on T-21's answer — "The answer determines whether model
tiering is a 7% lever or a majority one. **Do not skip to T-22.**" T-21 answered, and the
answer was unfavourable. The operator's own note is what put T-22's premise in question.

Escalating a point the dispatch ruled on in advance would be exactly the failure mode
`BATCH_PLAN.md:46` records at cost — a dispatching PM inventing a constraint, "pure process
friction, zero yield", with the note adding that "the stream operator's own dispatch briefs
carry the same risk and are in scope for the rule". **No `BLOCKED: NEEDS-HUMAN` is returned.**

**But the gate's G-3 conclusion stands in full, and PM does not soften it:**
- G-3(a) — `02_RATIONALE` §R6's *stated* justification ("the pool row itself is an
  ASSESS-FIRST row") is **false**: `BATCH_PLAN.md:37` is an imperative "Wire …" row, status
  `in-progress`. R6 must be re-grounded on the **correct** evidence (STREAM_LOG:88, the
  dispatch brief, BATCH_PLAN:42's conditionality) — a true conclusion resting on a false
  premise is still a defect, and this repo has rolled back for exactly that before.
- G-3(b) — stands **entirely**. The record's `Origin` must stop claiming to supersede
  `cost-attribution-2026-08.md:81-84` (a *priority* correction inside a pool-row disposition
  list) and must instead name and rebut what the decline actually overrides:
  `BATCH_PLAN.md:37` and `:41`.

### PM routing decision after stage 3: ROLLBACK to stage 2 (rollback #1)

Rollback count at stage 2: **1**. Threshold for a hard stop is 3 consecutive at one stage.
Routing is per the standing table — *Gate finds design gap → solution-architect*.

## Stage 2 — solution-architect, round 2 (complete)

- Verdict: **READY.** `02_SOLUTION_DESIGN.md` (499) and `02_RATIONALE.md` (406) corrected in
  place; both under the 500-line stage-doc cap. Record now **22 lines**, equal to the file's
  longest existing record.
- All eight gate findings dispositioned as **Fixed** (G-1…G-7, G-9).
- G-2: the untraceable "0.15–0.34 / ≈3–11%" is replaced by **0.02–0.83 extra rollbacks/task
  (0.6%–44% relative)** — the actual endpoints of §R2.4, which is now the **sole
  authoritative parameterisation** (the triple-restatement that produced G-4 is gone).
- G-3(a): re-grounded on PM's provenance evidence; the false "the pool row is an ASSESS-FIRST
  row" premise is **stated as false and withdrawn**, not quietly dropped. The gate's
  PM-attribution is not repeated.
- G-3(b): new **§16.1** quotes `BATCH_PLAN.md:37` and `:41` verbatim and answers each.
  **The architect corrected PM's own framing here and reported it**: `:41` ("this is unused
  wiring, not a missing mechanism") is **true as stated and not contradicted** — the decline
  *overrides* `:37` and only *qualifies* `:41`. Record, §16 U-5 and §R6 all carry that
  distinction rather than flattening both into "overrides". PM accepts the correction.
- G-4: "full parameter surface" retired; FL-10 states plainly that round 1's label was wrong.
  **The architect also found and fixed U-4, which carried the same defect and which the gate
  did not list.**
- **Six self-reported movements toward BUILD**, published against its own conclusion —
  including the surface top going 13.9% → 43.9% (≈3×), and §R2.5 now conceding that *every*
  relative percentage (stage 1's 11.2% included) is a framing rather than a measurement,
  which removes an argument round 1 leaned on. None touches the two rate-free legs the
  decline now rests on.
- D-5 now **paraphrases** the I.6 banned anchors rather than quoting them — a deliberate
  guard against T-13's delivery-stage self-trip, where quoted anchors travelled out of an
  exempt file.

### PM routing decision: RE-GATE (stage 3, round 2)

The gate scoped its own re-gate narrowly. PM honours that scope rather than commissioning a
fresh full review — re-reviewing passed sections invites new findings on unchanged text.

## Stage 3 — gate-reviewer, round 2 (complete)

- Verdict: **APPROVED FOR DEVELOPMENT** (with conditions). Appended verbatim to
  `03_GATE_REVIEW.md` as `## Round 2 — re-gate`; PM persisted it for the same
  no-`Write`-tool reason.
- **Stage gate for stage 4 is satisfied: an explicit PASS verdict exists.**
- All 9 round-1 findings **FIXED**. The gate re-derived all sixteen figures of §R2.4
  independently and every one reproduces — the QA failure it predicted no longer exists.
- **The gate withdrew its own round-1 error without reservation**: "my round-1 attribution
  was wrong. I withdraw it." It read `STREAM_LOG.md:88` and `BATCH_PLAN.md:42` itself and
  confirmed the ASSESS-FIRST framing was recorded at the dispatch boundary before any stage
  ran.
- **HR-1 WITHDRAWN by the gate — no operator ruling required.** Its red-line-6 framing
  rested on the false premise that the assess-first framing was an agent's. PM's
  non-escalation ruling is confirmed by the stage whose job is to distrust PM.
  **No `BLOCKED: NEEDS-HUMAN` is returned for this task.**
- The gate ruled **against PM and for the architect** on the `:41` question, and said so:
  "Stage 2 caught that and PM did not; I record it as the correct call." PM accepts.
- Both remaining load-bearing legs re-verified by direct attack: the gate went looking for a
  rollback-attribution instrument and found only one prose note in ten log entries
  (`STREAM_LOG.md:53`), which is not an instrument by the record's own F-2 standard.
- **Doc-size ruling, stated plainly**: no `verify_all` check measures `docs/features/` stage
  doc size (I.1–I.5 + I.7 enumerated with line numbers). 499 lines carries **zero exit-code
  exposure** — it is policy, not a gate risk. Constrains stage 4's own docs, not stage 2's.
- 6 new NOTES/MINOR (G-11…G-16), none blocking. G-11: the design cites "T-13's I.6 self-trip"
  when the real event is **T-013**, a different task from an earlier batch — the gate ruled
  a rollback to fix three characters would be the `BATCH_PLAN.md:46` "pure process friction,
  zero yield" shape, and instructed stage 5 **not** to escalate it.
- The gate pre-ruled **five likely downstream false positives** so stages 5/6 do not spend a
  round on them, and pointed QA at `STREAM_LOG.md:53` so item 7's attack is real rather than
  notional.

### PM routing decision: ADVANCE to stage 4 (`harness-kit:developer`)

Single-developer mode confirmed at stage 0 (`.harness/agents/dev-*.md` empty). Conditions
C-1…C-5 are carried into the dispatch as binding.

## Stage 4 — developer (complete)

- Verdict: **READY FOR REVIEW**, with two self-reported `DESIGN DRIFT` flags.
- Output: `04_DEVELOPMENT.md` (248) + `04_RATIONALE.md` (422) — both under the 500 cap.
- Production change: `.harness/rejected-decisions.md` **+23 −0**, 255→278 lines, 23→24
  records. Nothing else touched.
- **`verify_all` (bash): PASS 32 / WARN 0 / FAIL 0, exit 0** — matching the pre-dispatch
  baseline, with a byte-identical check-by-check diff. C-5 satisfied (summary line and
  `echo $?` agree). I.6 confirmed **non-vacuous**: the file is returned by `git ls-files`
  and is in neither exemption list, so the check genuinely ran over the appended text.
- C-2 character identity made a **property of the method**, not a promise: the record was
  extracted with `sed -n '108,129p'` from the design rather than retyped, and
  `sha256(tail -n 22) == sha256(§6 extraction) == 072fe740…5117`. Bytes 1…255 unchanged
  by digest.
- Freeze proof: FZ-2 **8/8**, FZ-3 **8/8**, FZ-5 **8/8 exact** (total 1376, ±1 tolerance not
  needed), FZ-4 **NULL as expected and recorded, not manufactured**. Mutation-tested on a
  scratch copy with `model: haiku` appended — FZ-2/FZ-3/FZ-5 and the new FZ-1′ each **fire**.
  The proof is demonstrated non-vacuous, not asserted.

### DESIGN DRIFT 1 — the load-bearing finding of this stage

**`agents/` IS in the dirty set** (8 files, 288+/130−). The design's FZ-1, the gate's round-1
§3.1 **and** its round-2 §3 all assert the opposite. Root cause: all three read the
**session-context `git status` snapshot, which is truncated** — it jumps from
`README.zh-CN.md` straight to `docs/batches/default/BATCH_PLAN.md`, silently eliding the
eight `agents/` lines at exactly the point the sort-order argument depended on. Live
`git status --porcelain` shows them at lines 36–43.

PM notes this is the **third distinct appearance in this task of the same hazard class** —
a claim that looked verified because the evidence *appeared* to support it, where the
evidence was actually absent (I.6's vacuous grep, the round-1 over-claims, now a truncated
snapshot). Only the stage with a shell could see it. This is the T-18 insight — a stage that
cannot execute substitutes a content-read for a byte-diff — reproduced live.

The developer did not stop (§8.2 says record and continue) and rebuilt stages-0–3 coverage
on **FZ-3 against `T_dispatch` = 1785591045** taken from `STREAM_LOG.md:88`: every agent file
was last written ≥3 h 08 m before T-22 was dispatched. It also noted that `01` §4.5 had
declined to rely on dirty-set membership at all — **§8's FZ-1 refined an upstream document
into a premise the upstream had deliberately avoided**, which is how the error entered.

### DESIGN DRIFT 2

D-9's acceptance test measures the wrong baseline: `git diff --stat` vs `HEAD` shows
`+179 −0`, not `+23 −0`, because the target file was already dirty — which the same design
states in FZ-4. D-9's *substance* (append-only, 23 added, 0 deleted) holds; its stated
command does not produce its stated number. Both measured.

- C-1 satisfied (`H0` predates the task by 41.3 days) **but recorded as moot** — it existed
  to underwrite FZ-1's coverage transfer, and FZ-1's other premise failed.

### PM routing decision: ADVANCE to stage 5 (`harness-kit:code-reviewer`)

Stage gate satisfied — stage 4 shows `verify_all` PASSED. PM does **not** pre-rule on whether
the two drifts require a design correction; that is the code reviewer's call, and the routing
table sends design drift to the architect if it does.

## Stage 5 — code-reviewer, round 1 (complete)

- Verdict: **CHANGES REQUIRED (0 CRITICAL, 1 MAJOR)** → routes to **stage 4 only**, not stage 2.
- Output: `05_CODE_REVIEW.md` + `05_RATIONALE.md`. **PM persisted both** — `harness-kit:code-reviewer`
  also carries only `Read, Glob, Grep` and has no `Write` tool, the same framework defect
  already recorded for the gate.

### Rulings on the two drifts (the questions PM referred to this stage)

- **DRIFT 1 — adequately handled, no rollback to stage 2.** §8.2's contingency fired and was
  executed exactly. Decisive reason: **a rollback cannot manufacture the missing evidence** —
  FZ-1's strength was content identity over `[H0, S-A]`, S-A has passed, and no pre-task
  baseline was ever captured. AC-6 holds on FZ-2 + FZ-3 + FZ-5.
- **DRIFT 2 — adequately handled, MINOR against the design**, reported not corrected (stage 4
  may not edit `02`). The reviewer checked whether `+23` is load-bearing downstream **before**
  ruling, and stated a falsifier.

### The MAJOR neither drift flagged — CR-1

`04_RATIONALE.md:377`'s FZ-1′ mutation row (`156/0 → 179/0`) **cannot be produced by the method
its own table declares**: a one-line append moves `git diff --numstat -- agents/` by +1, and an
untracked scratch file is invisible to that command. The reviewer traced the two cells to a
different experiment — the pre/post numstat of `.harness/rejected-decisions.md` itself
(179 − 23 = 156, both zero-deletion) — by enumerating and excluding five candidate readings.
The property is real; the row's `FIRES ✔` is unearned **as printed**, so stage 6 cannot
reproduce it. Not CRITICAL because AC-6 rests on FZ-2/FZ-3/FZ-5, all three genuinely
mutation-tested with control values matching captures A4/A5/A6.

This is the **fourth** appearance in this task of one hazard class: evidence that looks like it
supports a claim while actually measuring something else (vacuous I.6 grep → round-1
over-claims → truncated `git status` → now a mis-attributed mutation row).

### Corrections the reviewer made against other stages

- **In the developer's favour** (`➕`): degraded FZ-1 is *not* wholly dead — it retains full
  strength for the "new untracked file under `agents/`" mode. Stage 4 under-claimed.
- **Against stage 4's own correction**: `04`'s "open issue 1" claims `02`/gate C-5's
  `verify_all.sh:932-934` citation is off by one. The reviewer read the live file — 932/933/934
  are exact, and **stage 4's correction is itself the error**. Ordered withdrawn (CR-6, RES-6)
  specifically because leaving it invites stage 6/7 to break a correct citation.
- Ruled the design's §11 substantive check **passed**: `04`'s freeze section *supports* AC-6
  rather than asserting it, the decisive signal being its disclosure that FZ-1's `git status`
  form does **not** fire — a self-damaging result with every incentive to omit.
- Filed **none** of the six gate-pre-ruled false positives, and did not escalate G-11.
- Published **RES-1**, naming the two uncovered members of the admissible class precisely
  (M3: a line-count-preserving, non-`model:` content edit in stage 0/1 with a backdated mtime;
  M4: edit-and-revert inside `[S-A, S-B]`) rather than declaring AC-6 airtight — and noted that
  the mtime-backdating technique is demonstrated *inside this task*, so "no such operation
  occurred" is testimony, not a predicate.

### PM routing decision: ROLLBACK to stage 4 (rollback #2 overall; #1 at stage 4)

Per the standing table — *Reviewer finds code defect → developer*. Consecutive rollbacks at
stage 4: **1**. Stage 2 stays at 1. Neither approaches the 3-strike hard stop.

## Stage 4 — developer, round 2 (complete)

- Verdict: **READY FOR REVIEW.** No production file touched this round — only `04_*`.
- **CR-1 CONFIRMED, not falsified — by the developer, against its own interest.** It
  reproduced the reviewer's reading (e) exactly: `git diff --no-index --numstat` of the
  `H0` blob against the pre- and post-append copies of `.harness/rejected-decisions.md`
  yields `156 0` and `179 0`. The reviewer's stated falsifier is **not met**; CR-1 stands.
- It then took **fix option 1 *and* the provenance note**, rather than the cheaper relabel:
  a real FZ-1′ re-run in a scratch git repo whose HEAD carries the eight
  `git show cb0ed57:agents/*.md` blobs and whose work tree carries the live files — because
  a path-scoped git command cannot see a scratch-directory copy and mutating the real tree
  is what AC-6 forbids. Control reproduces the real tree **per file exactly**
  (40/13 · 27/39 · 41/16 · 47/4 · 33/9 · 45/21 · 51/26 · 4/2 = 288/130); after
  `model: haiku`: **289/130 — delta +1, exactly as CR-1 predicted.**
- Corroboration it did not have to volunteer: the scratch mutated digest came out
  `3ada48b2…dc79`, **matching the round-1 FZ-2 mutated cell** — independently confirming
  that row's provenance was sound even though FZ-1′'s was not.
- All of CR-2, CR-4, CR-5, CR-6, CR-7, CR-9, RES-1, RES-2 accepted and fixed. CR-8 left
  alone per the reviewer's own ruling. CR-3 carried as drift row DR-2 (upstream, reported
  not corrected).
- **Open issue 1 withdrawn** and both citations corrected after reading `verify_all.sh`
  live — a new open issue 2 now records that `932-934` is correct and must **not** be
  renumbered, carrying RES-6 forward as a guard against a future "fix".
- **➕ under-claim fixed and strengthened**: FZ-1 is now "PARTLY DEGRADED" with its `??` leg
  **mutation-tested** — adding `agents/sneaky.md` yields `?? agents/sneaky.md` while FZ-1′
  stays at 288/130 (untracked files contribute no diff).
- `verify_all` (bash): **PASS 32 / WARN 0 / FAIL 0, exit 0** — pasted from a real run.
- Sizes: `04_DEVELOPMENT.md` **207**, `04_RATIONALE.md` **500** (exactly at the policy cap;
  the gate established this cap has no `verify_all` mechanism, so it is not a gate risk).

### New finding the developer owed upward (reported, not corrected)

`02` §10.2 item 1 (`02:314-316`) instructs the tester to run **FZ-1** against a mutated copy
**in a scratch directory**. FZ-1 is `git status --porcelain -- agents/`, which cannot see a
file outside the work tree — run literally, that row is **guaranteed not to fire for reasons
unrelated to the predicate's power**, i.e. it would produce a vacuous pass. Filed as open
issue 4 / DR-4. This directly conditions RES-3 and must reach QA.

### PM routing decision: RE-REVIEW (stage 5, round 2), narrowly scoped

The MAJOR was an evidence-provenance defect; a claim that it is fixed is exactly the kind of
claim that needs the independent check rather than the author's word — and the reviewer bound
itself to a falsifier it must now adjudicate.

## Stage 5 — code-reviewer, round 2 (complete)

- Verdict: **APPROVED WITH NITS (0 CRITICAL, 0 MAJOR, 2 MINOR, 3 NIT).** Both axes clear of
  blocking findings; the masking invariant is satisfied. Appended verbatim to
  `05_CODE_REVIEW.md` as `## Round 2 — re-review`.
- **CR-1 adjudicated: falsifier tested and NOT met → upheld as filed, then CLOSED by the fix.**
  The reviewer judged M-b (the scratch git repo) a **sound** instrument, on the ground that its
  fidelity is established **empirically** — the control reproduces the real tree **per file,
  all eight** — rather than argued from construction, and noted that per-file reporting is what
  makes it auditable where a total-only match would have been far weaker.
- The reviewer was **careful not to over-credit the volunteered digest match**: it corroborates
  consistency, not correctness; same author, same session, no independent party; it excludes
  inconsistency between runs but not common-mode error. CR-1's closure rests on the re-run and
  its per-file control, **not** on the digest.
- It also re-derived the per-file arithmetic itself (288/130 both ways) and stated plainly that
  it has **no Bash tool** so the digests are "reported, not re-run by me" — declaring the limit
  of its own evidence rather than inheriting a claim.

### The reviewer corrected PM's framing of the new finding — and PM was wrong

PM summarised open issue 4 as "a vacuous pass". The reviewer ruled it **the opposite and worse**:
`02` §10.2 demands "each must fire", and the prescribed scratch-*directory* fixture guarantees
FZ-1 **cannot** fire — so literal execution yields a **spurious NEGATIVE** on the highest-value
AC-6 item, which a conscientious QA agent could read as the freeze proof *failing*. PM accepts
the correction and carries the reviewer's framing, not its own, into the stage-6 dispatch.

Ruling: **binding correction to QA (RES-8), no rollback to stage 2** — with four reasons given
and the counter-argument acknowledged (unlike DRIFT 1, `02` pre-wrote no contingency here).

### Residuals to stage 6

RES-1, RES-2, RES-4, RES-5, RES-6 carry unchanged. **RES-3 is spent** (its falsifier is
adjudicated) and superseded by **RES-3′**. New: **RES-7** (M-b's reproducibility is
time-bounded — if the T-13…T-21 wave is committed before QA runs, the control collapses to 0/0
and every M-b row becomes unreproducible through no fault of the record), **RES-8** (binding),
**RES-9** (the reviewer closed the `.gitignore` half itself by reading the file; two shell-only
checks remain).

### PM note on CR-10 — carried, not routed

CR-10 (an over-claim in `04_DEVELOPMENT.md:204`'s Verdict paragraph — "**Every** predicate has
been shown to fire", when FZ-1's ` M` form demonstrably does not) is rated MINOR and
non-blocking. PM does **not** open a third stage-4 round for one clause — that is the
`BATCH_PLAN.md:46` zero-yield shape the reviewer itself invoked twice. It is carried to QA for
independent measurement, and **PM will not propagate the over-claim into `07_DELIVERY.md`**.

### PM note on document headroom

The reviewer flagged that `04_RATIONALE.md` sits at **exactly 500/500** — zero headroom for a
further round. Noted; PM will not commission work requiring new rationale lines there.

### PM routing decision: ADVANCE to stage 6 (`harness-kit:qa-tester`)

Stage gate satisfied — stage 5 PASSES (APPROVED WITH NITS, no blocking finding on either axis).

## Stage 6 — qa-tester (complete)

- Verdict: **APPROVED FOR DELIVERY** (0 BLOCKER, 0 CRITICAL, 1 MAJOR non-blocking, 1 MINOR,
  4 NIT). `06_TEST_REPORT.md` (146) + `06_RATIONALE.md` (401). `## Adversarial tests` present
  with 18 rows — the hard declare-done gate is satisfied.
- Every measurement produced by QA's own commands; nothing inherited from stage 4. It built
  its **own** M-b rather than reusing the developer's, and RES-3′ reproduced exactly (control
  per file `40/13 · 27/39 · 41/16 · 47/4 · 33/9 · 45/21 · 51/26 · 4/2` = 288/130; mutated
  289/130). RES-8 confirmed, RES-9 **closed** with the two shell-only checks.
- `verify_all` ×4: **PASS 32 / WARN 0 / FAIL 0, exit 0**, no flakes. Baseline preserved.
- **QA-1 (MAJOR, non-blocking)** — the record's universal negative at
  `.harness/rejected-decisions.md:265` is **FALSIFIED**, and far more strongly than the gate's
  G-12 anticipated: the gate weighed one prose note and ruled it survivable; QA found
  **19 of 19** rollbacks stage-attributed across the window, twice under an explicit
  `### Rollback ledger` heading. **The decline survives** — no instrument *aggregates* them,
  and QA computed the detection requirement from the live series: ≈30 tasks/arm at α-only,
  **≈61 at 80% power**, against a ten-task history. The design carries the defensible
  *instrument* wording; the record inherited the *attribution* wording, which does not hold.
- Two classes nobody had run: **QA-3**, an in-hunk line-count-preserving edit defeats
  `git status`, `numstat` **and** `wc -l` simultaneously (only FZ-2's digest moves) — turning
  CR-13's asserted blind spot into a measured one and giving RES-1(a) a constructive existence
  proof; and a **whole-tree write scan over all 499 tracked files**, finding exactly 4 written
  post-dispatch and none under `agents/`, `skills/` or `.harness/scripts/`.
- **QA-2 corrected a residual against its own stage's interest**: RES-1(b) as written
  over-states — an edit-and-revert *without* mtime restoration IS caught by FZ-3. The true
  uncovered class is narrower than the record's own account of it.
- Zero footprint: both scratch trees removed, agents roll-up digest unchanged.

### PM decision on QA-1: DELIVER, publish unsoftened, reserve the call for the operator

QA explicitly did **not** request a rollback, and PM does not open one. Repairing `:265` means
re-opening a §6 frozen by C-2/D-1 — a full 2→3→4→5→6 round (the design's own measured 80.3%)
for one verb, changing nothing built. Three specialist stages independently invoked the
`BATCH_PLAN.md:46` zero-yield test on smaller items; PM applies it consistently here.

This is **not** PM auto-deciding a human-reserved point: the artifact is sound and delivered,
the counter-evidence is published unsoftened as the **first** outstanding risk in
`07_DELIVERY.md`, the one-verb repair is specified, and the archive now carries the correction
so a future reader meets it rather than concluding the record was careless. The call on whether
to spend a round is surfaced to the operator in the return summary.

## Stage 7 — PM delivery (complete)

- `07_DELIVERY.md` written (252 lines). `docs/tasks.md` active row removed and a completed row
  added — closing **QA-6**, which correctly flagged the row as stale at stage 6.
- **Entropy-watch cadence deliberately NOT run** — the dispatch reserved that boundary to the
  stream, which runs it when the pool drains.
- `archive-task` run (PM has no Bash; dispatched a mechanical runner). `--dry-run` first,
  exit 0, then the real run, exit 0.
  - **All four WRAPPED insight bullets survived harvest intact**, every `· evidence:` pointer
    present, including the one that wraps across two continuation lines. PM relied on T-20's
    fix and said so in the delivery; **the reliance was correct and is now empirically
    confirmed a second time**.
  - Index held at **30** entries (4 added, 4 rotated to `insight-history.md`, cap respected).
  - **R-1 discharged**: the record's deliberate forward reference now resolves —
    `docs/features/_archived/stage-model-tiering/02_SOLUTION_DESIGN.md` exists and carries
    `### 16.1` at line 424.
  - Post-archive gate: **PASS 32 / WARN 0 / FAIL 0, exit 0**, with I.4 and I.6 both explicitly
    green — **no delivery-stage I.6 self-trip** (the T-013 failure mode D-5's paraphrase
    discipline was guarding against).
  - `agents/` still exactly 8 ` M` and nothing new; `docs/features/` now contains only
    `_archived`.

### Final rollback ledger

| # | Route | Trigger |
|---|---|---|
| 1 | stage 3 → stage 2 | Gate found 4 MAJOR, all decline-favourable, each refuted inside the design's own rationale |
| 2 | stage 5 → stage 4 | Reviewer found a freeze-proof mutation row unproducible by its declared method |

Consecutive rollbacks: stage 2 = 1, stage 4 = 1. The 3-strike hard stop was never approached.
**No `BLOCKED: NEEDS-HUMAN` returned** — the one candidate (gate HR-1) was withdrawn by the gate
itself after it verified PM's provenance evidence.

