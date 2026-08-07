# 02 — Rationale: stage-model-tiering (T-22)

> Rationale portion for `02_SOLUTION_DESIGN.md`. Non-binding. Carries the falsification
> derivations behind §2's FL-* findings, the parameter surface, the evidence spot-checks, the
> option arguments behind D-1…D-15, and the reasoning behind §16's materiality rulings.
>
> **Round 2 (gate G-1…G-7, G-9).** §R2.4 is now the **single** authoritative parameterisation and
> carries the compound BUILD corner (`f = 0.834`) the gate assembled; §R2.5, §R4.2, §R4.3 and §R6
> are corrected. Two round-1 claims are **withdrawn**: "every correction lowers the bar" and
> "the pool row itself is an ASSESS-FIRST row". Routing history: `PM_LOG.md`.

---

## R1 — Method: how the upstream analysis was attacked

The dispatch named the attack surface: stage 1's "the break-even is independent of the delegated
share" is a *provably-safe* argument, and `.harness/insight-index.md` (guard-cmd-chain CR2-2)
records that such arguments are exactly where the counterexample hides. Two questions drove the
work, in this order:

1. **What would have produced the opposite verdict?** If no measurement inside the published
   evidence could have yielded BUILD, the analysis did not discriminate and its agreement with the
   dispatch's prior is worthless. Answered in §R2.6 / design FL-11.
2. **Where does the model, not the arithmetic, fail?** Stage 1's algebra is correct. Its *modelling*
   carries three unstated assumptions, and two of them are false.

Before touching the model, every citation load-bearing for the recommendation was spot-checked
against its source. Nine of nine resolved correctly:

| Cited in `01` | Claim | Verified |
|---|---|---|
| `cost-attribution-2026-08.md:19-30` | component split, $1570.15 bill, 1.6% deviation | yes |
| `…:36-40` | 127,993 cache-read / 1,272 output tokens per call, ≈100:1 | yes |
| `…:45-54` | the $36 is sub-agent **output**, reconciled at ≈$37.5 | yes |
| `…:56-63` | T-18's 37.7% stage-4 read cut ⇒ ≈16% of total spend | yes (see R4.3 — the figure is optimistic) |
| `…:73-76` | verification roles are the last place to economise | yes |
| `…:85-87` | nothing measures per-call context volume | yes |
| `BATCH_PLAN.md:42` | ≈$36 for six roles against ≈$540 project total | yes |
| `BATCH_PLAN.md:46` | the T-13 PM-invented-constraint rollback | yes |
| `STREAM_LOG.md:72-86` | 4/3/4/1/2/4 → mean 3.0, range 1–4, n=6 | yes |

The citation layer is sound. What follows attacks the model built on top of it.

---

## R2 — The break-even, re-derived (design FL-1 … FL-4, FL-11)

### R2.1 Stage 1's model, restated

`01_RATIONALE.md` §R2.1 sets saving `= S·A·(1−r)` and cost `= f·S·C`, so `S` cancels and
`f = A(1−r)/C`. With `A = 0.373`, `1−r = 0.4`, `C = 0.445` this yields `f = 0.335`, which
reproduces exactly. The arithmetic is not in dispute.

### R2.2 First failure — the cost of a rollback is not wholly delegated

The cancellation requires that **everything** an extra rollback round costs sits inside the
delegated set. It does not. A rollback round is: PM writes a ruling, re-dispatches three stages,
ingests three returns — each turn re-reading an orchestrator context that accumulates monotonically
across the whole task (`01_RATIONALE.md` §R1.2 step 4 makes this argument itself, in the other
direction). `docs/batches/default/BATCH_PLAN.md:58` states the PM shell runs in the main thread.
Even under the competing reading (`skills/harness-stream/SKILL.md:122`, PM dispatched as a
sub-agent), a non-delegated remainder survives: the drain shell, the `verify_all` runs, the
operator's own turns. So the honest form is

```
saving/task = S · a · (1−r)
cost/task   = f · [ S·c_d + (1−S)·c_o ]
⇒  f = a(1−r) / [ c_d + c_o·(1−S)/S ]
```

with `a` = stages 1+2 as a share of **delegated** spend, `c_d` = extra delegated work per induced
rollback as a fraction of baseline delegated spend, `c_o` = the same for orchestrator spend.
Stage 1's formula is the special case `c_o = 0`. Since `c_o > 0`, **`S` does not cancel**, and `f`
is monotonically increasing in `S`: the smaller the delegated share, the *tighter* the bar.

This is why OQ-2 — which stage 1 classified NON-BLOCKING because the PM is excluded on independent
grounds — turns out to be load-bearing somewhere else entirely. It does not change the disposition
(`c_o > 0` under both readings), but it is the reason the independence claim cannot stand.

### R2.3 Second failure — a stage-1/2 defect does not cause a stage-4 rollback

`01_RATIONALE.md` §R2.2 defines `C` as "stages 4 + 5 + 6 … A rollback returns the task to stage 4".
That is the cost of a **developer-originated** defect. The defects a downgraded analyst or architect
would induce are requirement and design defects, and `agents/pm-orchestrator.md:125-130` routes them
by origin: *Gate finds requirement gap → requirement-analyst*; *Gate finds design gap →
solution-architect*; *Reviewer finds design drift → solution-architect*; *QA finds untested
requirement → requirement-analyst*. The re-run therefore starts at stage 1 or 2, and everything
built on the wrong contract is discarded.

Recomputing on T-20's volumes (total 4051 lines; `01_RATIONALE.md` §R2.2's table):

| Where the induced defect is caught | Work redone | Lines | Share of a run |
|---|---|---:|---:|
| Gate (stage 3) | 2 + 3 | 1452 | **35.8%** |
| Gate, routed to stage 1 | 1 + 2 + 3 | 1948 | 48.1% |
| Code review / QA (5 or 6) | 2 + 3 + 4 + 5 + 6 | 3254 | **80.3%** |
| Code review / QA, routed to stage 1 | 1 … 6 | 3950 | 97.5% |
| *(stage 1's assumption)* | 4 + 5 + 6 | 1802 | *44.5%* |

Let `p` be the fraction of induced defects the gate catches. `c_d = 0.358p + 0.803(1−p)`, and
`c_d = 0.445` requires **`p = 0.80`**. The record contradicts that: stage-1/2 defects escaping the
gate are the dominant shape in `.harness/insight-index.md` — a design that mis-predicted its own
mutation outcome reached QA (T-15); the sub-part classification defect reached QA round 2 and an
operator ruling (T-18 QA-7/QA-8); a design drift reached code-review round 2 (T-16); a
PM-invented constraint reached QA (T-13). The one clean gate catch on record is the
WARN-is-advisory assumption (guard-cmd-chain gate R2.6). A central `p = 0.5` gives
**`c_d = 0.58`**; `p = 0.33` gives 0.66.

### R2.4 The corrected parameter surface — the single authoritative parameterisation

**Every `f` and every relative percentage in `02_SOLUTION_DESIGN.md` and in the §6 record comes
from this subsection.** Round 1 restated the surface in three places in three parameterisations,
which is how the gate's G-4 got in; nothing else now restates it.

`f = a(1−r)/[c_d + c_o·(1−S)/S]`, `a = 0.373` throughout, `k = c_o/c_d`.

**(a) At `1−r = 0.4` (stage 1's unsourced rate) and `c_d = 0.58` (`p = 0.5`)** ⇒ numerator `0.1492`:

| `S` | `k = 0` | `k = 0.25` | `k = 1` |
|---|---:|---:|---:|
| 0.45 (band top) | f = 0.257 → **8.6%** | 0.197 → 6.6% | 0.116 → 3.9% |
| 0.25 (band middle) | 0.257 → 8.6% | 0.147 → **4.9%** | 0.064 → 2.1% |
| 0.067 (band floor) | 0.257 → 8.6% | 0.057 → 1.9% | 0.017 → **0.6%** |

Percentages here are against the n=6 mean of 3.0. Stage 1's `M1`, 0.335 → 11.2%, sits above every
cell of (a).

**(b) The two parameters (a) holds fixed.** `1−r = 0.4` is unsourced (R4.3) and n=6 is a selected
sub-series (R4.2). Both are BUILD-direction adjustments, so (a) is not "the full surface" — the
label round 1 shipped. Releasing them, with `k = 0` and `S→1` (so `f → a(1−r)/c_d`):

| corner | `1−r` | `c_d` (`p`) | `f` | vs n=6 (3.0) | vs n=10 (1.9) |
|---|---:|---:|---:|---:|---:|
| (a)'s supremum | 0.4 | 0.58 (0.5) | 0.257 | 8.6% | 13.5% |
| gate-caught only | 0.4 | 0.358 (1.0) | **0.417** | 13.9% | 21.9% |
| cheap tier | 0.8 | 0.58 (0.5) | 0.514 | 17.1% | 27.1% |
| **compound** | 0.8 | 0.358 (1.0) | **0.834** | **27.8%** | **43.9%** |

**Surface: `f = 0.017 … 0.834`, 0.6% … 43.9% relative** — the two extremes each taken against
their own baseline (0.6% is n=6; 43.9% is n=10). On a single n=6 base the range is 0.6%–27.8%; on
a single n=10 base it is 0.9%–43.9%. The 0.417 row is also the FL-2
counterexample: it exceeds stage 1's 0.335, so the corrections do **not** all run one way. The
compound row was assembled by the stage-3 gate, not by round 1 of this stage, and is adopted here
verbatim; it is the most BUILD-favourable *defensible* value of each of the three self-reported
adjustments taken simultaneously.

**Why the decline holds anyway, without appeal to any cell.** Two rate-free reasons: (i) nothing in
this repo attributes a rollback to its originating stage at **any** resolution — the recorded
history is ten tasks with counts of mixed shape, so even the 0.834 corner needs ≈30 attributed
tasks to resolve, which is the F-2 precondition restated rather than a claim about magnitude;
(ii) Finding C and Finding D contain no rate parameter. The operative claim is *this project cannot
measure the delta the payoff hinges on* — and that is a statement about instruments, which is why
widening the surface by 3× does not touch it. Stating it as "every correction lowers the bar", as
round 1 did, was both false and weaker.

### R2.5 A units caveat that does not change direction

`f` is expressed in "one rollback round" units derived from a re-run of a stage set, while the
observed means (3.0 at n=6, 1.9 at n=10) count rollbacks of mixed shape (gate, code-review, QA)
recorded in `STREAM_LOG.md`. The two units are not identical, so **every** relative percentage on
R2.4's surface — stage 1's 11.2% included — is a framing rather than a measurement. This is a
second, independent reason the decision cannot rest on any cell of the table, and it is why the
record leads with the absolute quantity (`0.02–0.83` extra rollbacks per task) and carries the
relative range as a parenthetical.

### R2.6 What measurement would have produced BUILD

Asked directly, because a derivation that can only produce the expected verdict has proved nothing.
BUILD requires the break-even to be **both** high enough to be plausibly clearable and low-risk
enough to be worth clearing — i.e. `S` near 1 (so the orchestrator term vanishes), `p` near 1 (so
induced defects never escape the gate), a cheap tier (`1−r` near 0.8), and an instrument able to
resolve the resulting shift — 27.8%–43.9%, the R2.4(b) compound row, not the ~14% round 1 named.
Those are exactly F-1 (which resolves `S`), F-2 (which resolves both `p` and the detection) and
F-3 (which makes being wrong survivable). Stage 1's evidence **could** have produced BUILD: had the
$36 attribution come back at, say, $300 of $540, the floor alone would have put `S` near the top of
the band and F-1 would be largely discharged. It did not. The evidence discriminates.

---

## R3 — Finding D re-verified independently (design FL-8)

Four checks, none of them a re-read of `01`:

1. `agents/*.md` holds exactly eight files (`pm-orchestrator`, `requirement-analyst`,
   `solution-architect`, `gate-reviewer`, `developer`, `code-reviewer`, `qa-tester`, `supervisor`).
   `AI-GUIDE.md:13` names this the single source, "no sync"; `:57` states they are **not**
   materialized into a generated project since v0.30; `docs/dev-map.md:64-66,150-152` agrees, and
   `sync-self.sh:58-60` carries the removed-agent-mapping comment as live evidence of the cutover.
2. `.claude/agents/` in this repo is **empty** (glob returns nothing), consistent with
   `docs/dev-map.md:111`.
3. The PM dispatches the **namespaced** `harness-kit:<name>`
   (`agents/pm-orchestrator.md:135-143`); only project-local partition agents are dispatched by
   bare name. A consumer dropping `.claude/agents/solution-architect.md` into their project would
   create a *different agent* (bare `solution-architect`) that nothing in the pipeline dispatches —
   it cannot shadow `harness-kit:solution-architect`. So the shadowing escape hatch PM asked about
   does not exist, and Finding D does not weaken.
4. The only consumer-side lever is refusing the plugin update wholesale — all-or-nothing, and it
   forfeits every unrelated fix. That is not a per-decision opt-out.

**One sharpening worth carrying:** a project-local agent override surface *does* already exist, for
partition `dev-*` agents (`.harness/agents/dev-*.md` → `.claude/` via `harness-sync`). That is the
natural shape F-3 would take, which is why the design's reuse audit names it. It does not cover any
of the eight framework roles, so it changes nothing about the present decision.

---

## R4 — The three adjustments that favour BUILD

Reported because a one-sided falsification is not a falsification.

### R4.1 The document-volume proxy (design FL-5)

`A = 1512/4051 = 37.3%` and `C = 1802/4051 = 44.5%` are computed from written-document lines, which
under-count stages 4 and 6 (code edits, repeated `verify_all` runs, T-20's 186-case driver). Add
`δ ≥ 0` to those stages:

- `A' = 1512/(4051+δ)` — strictly **decreasing** in δ.
- `C' = (1802+δ)/(4051+δ)` — strictly **increasing** in δ, because 1802/4051 < 1 and adding δ to
  both terms moves the ratio toward 1.
- `f = A(1−r)/C` therefore **over-states** the break-even, for any δ > 0.

PM's proposed reasoning is verified: the proxy biases toward BUILD, so the decline survives its own
proxy error. Worked example — if stage 4 truly costs 2× its document proxy and stage 6 1.5×
(δ = 1047, total 5098): `A' = 29.7%`, and the late-catch `c_d` becomes 4301/5098 = 84.4%, giving
`f = 0.141` → 4.7%. Lower again.

### R4.2 The rollback baseline is a selected sub-series (design FL-9)

`STREAM_LOG.md:72-86` (n=6, mean 3.0) excludes the four earlier tasks at **`:53-70`** — T-11a = 1
(`:53`, "1 design rollback"), T-11b = 0 (`:58`), T-11c = 0 (`:61`), T-12 = 0 (`:68`). Round 1 cited
this range as `:58-70`, which is short by one record; the values were right, the range was not
(gate G-9). On n=10 the mean is 1.9 and every relative bar scales by 3.0/1.9 ≈ 1.58×, which is the
right-hand column of R2.4(b).

One further precision the window needs: `:86` records T-20's delivery with **no** rollback count at
all. So the n=6 series is "tasks in the window *with a recorded count*", not "tasks in the window" —
the same log that supplies the baseline also demonstrates that the count is not reliably recorded,
which is a small, direct instance of the F-2 gap.

The exclusion is defensible (different log format, pre-T-13 era, pre-contract-split pipeline) but
stage 1 did not state it as a selection. Two containments, neither of which cancels the adjustment:
the n=10 top end still rests on the `p = 1` corner refuted in R2.3, and a series containing four
zeros has a variance that makes establishing a mean shift harder, not easier — which argues the
instrument gap, not a smaller effect.

### R4.3 `1−r = 0.4` is unsourced, and the ≈16% comparator is optimistic

`01_RATIONALE.md` §R2.3 chooses `1−r = 0.4` from "the shape of the currently-published mid tier"
while explicitly declining to read a rate. `f` is linear in `(1−r)`, so a genuinely cheap tier at
`1−r = 0.8` **doubles every cell** of R2.4(a) — this is the adjustment R2.4(b) releases, and it is
half of the compound corner's 0.834. Two things contain it, and neither removes it: a larger
capability delta raises the induced-defect rate alongside the saving (the two are not independent,
so `f` and the achieved rate move together), and Finding C is rate-free.

Separately, the ≈16% comparator: it applies T-18's *stage-read* reduction to the **whole** 43.3%
cache-read line, including main-loop reads T-18 did not touch, so it is an **upper bound, not a
realised or banked saving**. Round 1's record said context reduction "already **banks** a
double-digit cut", which asserts realisation — exactly the disclaimed part (gate G-5). The corrected
record makes no quantitative claim for it at all: it says only that "context reduction is the safer
lever", which rests on the qualitative half (no capability trade-off) that is not in doubt. What
*is* measured is the stage-read cut itself — 37.7% at stage 4 (`STREAM_LOG.md:84`) — not its share
of total spend.

None of the three overturns the result. Together they are the reason the design publishes a
**surface** (R2.4) rather than a second point estimate to replace stage 1's — and, after round 2,
the reason that surface is stated with the compound corner in it rather than at two fixed
parameters.

---

## R5 — Option arguments behind the design decisions

**D-2, three fields vs four.** A `- **Re-surface:**` field would read better, but all 23 existing
records carry exactly three (record lengths run 5–22 lines, median 9), and two of them
(`byte-form-subpart-classification:219-220`,
`shared-insight-parse-module:254`) already fold a re-surface precondition into `Why`. The decision
rubric's "match existing conventions" line settles it; a new field in a memory file read by every
future decide-point is a format change disguised as a formatting choice.

**D-4, which path the `Origin` cites.** Three candidates: (a) the pre-archive path
`docs/features/stage-model-tiering/…`; (b) the post-archive path; (c) no path at all. (a) is what
both existing precedents did and both are **now dangling**, because `archive-task` moved those
tasks — a live, checkable instance of the defect in the very file being edited. (c) is safe but
strips the record of its evidence pointer, which is the thing that makes a memory record worth
re-reading. (b) is correct at rest and wrong only during the ~one stage between the developer's
write and stage 7's archive; the cost of that window is one QA false-positive, which the design
pre-empts by naming it. (b) chosen.

**D-9/D-10, append-only.** Considered and rejected: inserting the record in slug-alphabetical order
or grouping it with the other T-18/T-20-era records. Both would reflow the file and destroy the
`+N -0` diff property, which is the code reviewer's cheapest handle on "nothing else changed" — and
on this working tree, cheap handles on "nothing else changed" are exactly what is scarce.

**D-11, not compacting the file.** The header invites compaction past ~one screen and the file is
25× that. Rejected for this task on three grounds: it is not in `01` §2; per-record merge/obsolete
judgement on 23 records is a task, not a step; and it would take the diff from `+23 -0` to a
whole-file rewrite in the same commit as a freeze claim. Recorded as an observation for whoever
next has a reason to touch the file.

**§8, why five predicates instead of the insight's two.** The insight index prescribes dirty-set
difference **plus** mtime ordering. On this tree the dirty-set half degenerates: the one file being
edited is *already* dirty, so the set does not change at all (FZ-4's expected result is "no
difference"). Leaving that as the only structural leg would hand stage 5 a null result to interpret.
FZ-1 (path-scoped cleanliness, which is a content-identity statement precisely because `agents/`
starts outside the dirty set) and FZ-2 (digests, which survive a HEAD move) are added so that three
independent legs carry AC-6 and FZ-4 can be reported as the null it is.

**§10.2 item 1, why the mutation test is the highest-value QA item.** This repo has shipped
green-and-vacuous checks twice on record: an unanchored whole-file `grep` that passed with the
entire hook array deleted (T-15 E-6/E-8), and a spec-vs-spec oracle that would have gone green
measuring nothing (T-16). A freeze proof that has never been observed to fail belongs to the same
family. The mutation costs a temp directory and one command.

---

## R6 — Materiality reasoning for §16

**U-1 (the §4.1 contradiction).** The test applied was: *is there any reading of the contract under
which a developer builds something different?* §2.6 says "Append one `## stage-model-tiering`
record"; AC-5 says the file must afterwards contain "exactly one". Both are unambiguous, mutually
consistent, and consistent with §4.1's body sentence. Only the bolded lead disagrees, and it
disagrees by asserting a state of the world (a pre-existing record) that AC-5's verification step
("confirm a single occurrence") would immediately refute. Nothing downstream branches on it.
Cosmetic.

**U-2 (eighteen vs 23).** Counted directly: `^## ` headings at lines 12, 19, 25, 32, 39, 45, 52,
59, 66, 73, 92, 101, 112, 128, 137, 148, 162, 176, 191, 201, 224, 234, 245 — 23 records in a
255-line file. Eighteen is wrong by five. It is nevertheless immaterial: no acceptance criterion or
build step reads the count, and the co-located claim that matters (no `stage-model-tiering` record
exists) is correct. Reported because two errors in one paragraph is a signal about that paragraph,
not about the verdict.

**U-5 (the operator statements the decline overrides).** Round 1 got both halves of this wrong and
both are replaced.

*Which text is the contrary position.* Not `docs/proposals/cost-attribution-2026-08.md:81-84`. Read
in place, that line sits inside a **"Recommended disposition"** list of pool rows (`:78`), parallel
to "T-21 — complete" and "A new candidate, not scheduled", and it corrects T-22's *priority* — "from
'primary cost lever' to 'secondary, after context reduction'" — while reinforcing its existing
constraint. `:72` reads "then **consider** tiering for roles whose defect-catching record shows they
can afford it". On the strongest available reading the proposal said *run the row at secondary
priority*, which is what happened, and took no position on the outcome. Claiming to "supersede" it
would send a future reader to a priority note and leave the record looking like it mis-cited its own
source. Withdrawn. What the decline actually overrides is `BATCH_PLAN.md:37`, the imperative
"**Wire** …" row, status `in-progress`; `:41` it does not contradict but qualifies. Both are quoted
verbatim and answered in `02_SOLUTION_DESIGN.md` §16.1, which the record's `Origin` cites — the
distinction between the two is itself part of the rebuttal and is stated there, not blurred.

*Why it is not a red-line-4 conflict.* Round 1's stated ground — "the pool row itself is an
ASSESS-FIRST row" — is **false**, and a true conclusion resting on a false premise is still a
defect. `BATCH_PLAN.md:37` carries none of the assess-first language the rows that genuinely have it
carry. `BATCH_PLAN.md:55` is what a genuine one looks like: it marks T-10 "ASSESS-FIRST — decline
if redundant with the existing pool/frontier/stream" and adds that the RA stage "must honestly
assess value+overlap and descope or recommend decline where appropriate rather than force-build".
T-22's row has neither clause. The correct grounds are three, all on disk and none of them an
agent's own framing:

1. **The dispatch is recorded as assess-first at the dispatch boundary.**
   `docs/batches/default/STREAM_LOG.md:88` — `2026-08-01T13:30:45Z · T-22 · dispatching
   pm-orchestrator · slug=stage-model-tiering · mode=full · ASSESS-FIRST (T-21 downgraded this from
   primary to secondary lever)`. That is the stream's record of what was dispatched, written before
   any stage ran.
2. **The dispatch brief pre-authorised this outcome verbatim**, under a heading "ASSESS FIRST — the
   premise changed after this row was written": *"Both outcomes are legitimate. … If it shows the
   remaining saving is small and concentrated on roles that cannot afford it, **recommend DECLINE
   and build nothing** … **Record the decline in the rejected-decisions memory so it is not
   re-litigated.**"* Quoted in full in `PM_LOG.md`, "PM ruling on HR-1". The decline and the record
   are the commissioned deliverable, not a substitution for one.
3. **Corroborated in operator-authored text**, so the conclusion does not rest on the dispatch
   channel alone: `BATCH_PLAN.md:42` makes T-22 conditional on T-21's answer — "The answer
   determines whether model tiering is a 7% lever or a majority one. **Do not skip to T-22.**" T-21
   answered, and the answer was unfavourable. The operator's own note is what put the row's premise
   in question.

Not blocking, then, on evidence rather than on a mis-read row. But a decline that silently overrides
an operator-authored *build* row invites exactly the re-litigation this memory file exists to
prevent — which is why the mitigation is no longer four words in `Origin` but a quoted, answered
rebuttal in §16.1 that `Origin` points at. **What the decline does not do is close the row**: `:37`
stays `in-progress` and `docs/proposals/` stays unedited (design §15); disposing of the row is the
operator's act.

---

## R7 — What was deliberately not done

**No second point estimate.** Replacing stage 1's 0.335 with a corrected single figure would repeat
its error at one remove — round 1 came close by publishing a "central ≈5%" alongside the surface,
and the gate's G-2 shows what a floating headline number costs once it reaches permanent memory.
The design publishes a surface (R2.4) with the assumptions labelled on every axis, because the
honest statement is that four of the five parameters are unmeasured here.

**No rollback request.** Falsifying an upstream claim is not automatically a rollback: the test is
whether a binding statement or an acceptance criterion changes. None does — every correction moves
the number in the direction the verdict already points. Requesting a rollback to re-word a
derivation whose conclusion survives would be the "pure process friction, zero yield" shape recorded
at `docs/batches/default/BATCH_PLAN.md:46`.

**No glossary edit.** `CONTEXT.md` names modules, files and symbols the pipeline uses. This task
creates none, and "delegated share" / "break-even" belong to an assessment that will live in
`docs/features/_archived/`. Seeding terms nothing references would add maintenance surface to a file
whose value is that every entry is live.

**No second rejected-decisions record.** The options declined inside this design (a fourth record
field, alphabetical insertion, file compaction, a `verify_all` freeze check) are either already
barred by `01` §3 or are formatting calls internal to one edit. None is a concept a future proposer
would re-raise by name, which is the bar the file's header sets.
